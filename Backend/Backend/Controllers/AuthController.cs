using Backend.DT0s;
using Backend.DTOs;
using Backend.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Google.Apis.Auth;
using System.Security.Cryptography;
using System.Text.Json;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Microsoft.IdentityModel.Tokens;
using System.Net;
using System.Text;
using MailKit.Security;
using MimeKit;

namespace Backend.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AuthController : ControllerBase
    {
        private readonly QuanLyPhongTroContext _context;
        private readonly IHttpClientFactory _httpClientFactory;
        private readonly IConfiguration _configuration;
        private readonly ILogger<AuthController> _logger;

        public AuthController(
    QuanLyPhongTroContext context,
    IHttpClientFactory httpClientFactory,
    IConfiguration configuration,
    ILogger<AuthController> logger)
        {
            _context = context;
            _httpClientFactory = httpClientFactory;
            _configuration = configuration;
            _logger = logger;
        }

        // 1. Tạo tài khoản bằng email, không yêu cầu xác minh email.
        // POST /api/Auth/register
        [HttpPost("register")]
        public async Task<IActionResult> Register(
            [FromBody] RegisterRequestDTO model)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(model.FullName) ||
                    string.IsNullOrWhiteSpace(model.Email) ||
                    string.IsNullOrWhiteSpace(model.Phone) ||
                    string.IsNullOrWhiteSpace(model.Password))
                {
                    return BadRequest(new
                    {
                        message = "Vui lòng nhập đầy đủ thông tin."
                    });
                }

                string email = model.Email.Trim().ToLowerInvariant();
                string phone = model.Phone.Trim();

                bool existingUser = await _context.Users.AnyAsync(u =>
                    u.Email.ToLower() == email || u.Phone == phone);

                if (existingUser)
                {
                    return Conflict(new
                    {
                        message = "Email hoặc số điện thoại đã được sử dụng."
                    });
                }

                string role = NormalizeRole(model.Role);

                if (role == null)
                {
                    return BadRequest(new
                    {
                        message = "Vai trò tài khoản không hợp lệ."
                    });
                }

                var newUser = new User
                {
                    Id = "USER_" + Guid.NewGuid().ToString("N")[..8],
                    Name = model.FullName.Trim(),
                    Email = email,
                    Phone = phone,
                    Password = model.Password,
                    Role = role,
                    Status = "active",
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };

                _context.Users.Add(newUser);
                await _context.SaveChangesAsync();

                return Ok(new
                {
                    message = "Đăng ký thành công. Bạn có thể đăng nhập.",
                    data = new
                    {
                        newUser.Id,
                        newUser.Name,
                        newUser.Email,
                        newUser.Phone,
                        newUser.Role,
                        newUser.Avatar,
                        emailVerified = newUser.EmailVerifiedAt != null
                    }
                });
            }
            catch (DbUpdateException)
            {
                return Conflict(new
                {
                    message = "Email hoặc số điện thoại đã được sử dụng."
                });
            }
            catch (Exception)
            {
                return StatusCode(500, new
                {
                    message = "Không thể xử lý đăng ký lúc này."
                });
            }
        }

        // 2. ĐĂNG NHẬP BẰNG EMAIL/SỐ ĐIỆN THOẠI
        // POST /api/Auth/login
        [HttpPost("login")]
        public async Task<IActionResult> Login(
            [FromBody] LoginRequestDTO model)
        {
            try
            {
                var user = await _context.Users.FirstOrDefaultAsync(u =>
                    (u.Email == model.EmailOrPhone ||
                     u.Phone == model.EmailOrPhone) &&
                    u.Password == model.Password);

                if (user == null)
                {
                    return Unauthorized(new
                    {
                        message =
                            "Email/Số điện thoại hoặc mật khẩu không chính xác."
                    });
                }

                if (user.Status != "active")
                {
                    return Unauthorized(new
                    {
                        message = "Tài khoản của bạn đang bị khóa."
                    });
                }

                return Ok(new
                {
                    message = "Đăng nhập thành công!",
                    data = new
                    {
                        user.Id,
                        user.Name,
                        user.Email,
                        user.Phone,
                        user.Role,
                        user.Avatar,

                        accessToken = GenerateJwtToken(user),
                        tokenType = "Bearer"
                    }
                });
            }
            catch (Exception)
            {
                return StatusCode(500, new
                {
                    message = "Không thể xử lý đăng nhập lúc này."
                });
            }
        }

        [HttpPost("forgot-password")]
        public async Task<IActionResult> ForgotPassword(
            [FromBody] ForgotPasswordRequestDTO model,
            CancellationToken cancellationToken)
        {
            if (!IsSmtpConfigured()) return SmtpNotConfigured();

            var email = model.Email.Trim();
            var genericResponse = new
            {
                message = "Nếu email thuộc tài khoản hợp lệ, mã khôi phục sẽ được gửi tới hộp thư."
            };
            var user = await _context.Users.FirstOrDefaultAsync(
                u => u.Email.ToLower() == email.ToLower(), cancellationToken);
            if (user == null || IsInternalEmail(user.Email))
                return Ok(genericResponse);

            var status = await SendOtpEmailAsync(user, "password_reset", cancellationToken);
            return status == OtpSendStatus.Failed
                ? SmtpUnavailable()
                : Ok(genericResponse);
        }

        [HttpPost("reset-password")]
        public async Task<IActionResult> ResetPassword(
            [FromBody] ResetPasswordRequestDTO model,
            CancellationToken cancellationToken)
        {
            var email = model.Email.Trim();
            var user = await _context.Users.FirstOrDefaultAsync(
                u => u.Email.ToLower() == email.ToLower(), cancellationToken);
            if (user == null || IsInternalEmail(user.Email))
                return InvalidOtp();

            var now = DateTime.UtcNow;
            var otp = await FindOtpAsync(user.Id, "password_reset", now, cancellationToken);
            if (otp == null || !VerifyOtpHash(user.Id, "password_reset", model.Code, otp.CodeHash))
            {
                if (otp != null)
                {
                    otp.Attempts++;
                    if (otp.Attempts >= 5) otp.UsedAt = now;
                    await _context.SaveChangesAsync(cancellationToken);
                }
                return InvalidOtp();
            }

            await using var transaction = await _context.Database
                .BeginTransactionAsync(cancellationToken);
            var claimed = await _context.EmailOtps
                .Where(c => c.Id == otp.Id && c.Purpose == "password_reset" &&
                            c.UsedAt == null && c.ExpiresAt > now && c.Attempts < 5)
                .ExecuteUpdateAsync(update => update.SetProperty(c => c.UsedAt, now),
                    cancellationToken);
            if (claimed != 1)
            {
                await transaction.RollbackAsync(cancellationToken);
                return InvalidOtp();
            }

            user.Password = model.NewPassword;
            user.EmailVerifiedAt ??= now;
            user.UpdatedAt = now;
            await _context.SaveChangesAsync(cancellationToken);
            await transaction.CommitAsync(cancellationToken);
            return Ok(new { message = "Đặt lại mật khẩu thành công. Hãy đăng nhập bằng mật khẩu mới." });
        }

        // 3. ĐĂNG NHẬP BẰNG GOOGLE
        // POST /api/Auth/google-login
        [HttpPost("google-login")]
        public async Task<IActionResult> GoogleLogin(
            [FromBody] GoogleLoginRequestDTO model)
        {
            if (string.IsNullOrWhiteSpace(model.IdToken))
            {
                return BadRequest(new
                {
                    message = "Thiếu Google ID token."
                });
            }

            try
            {
                var payload = await ValidateGoogleToken(model.IdToken);

                if (string.IsNullOrWhiteSpace(payload.Subject) ||
                    string.IsNullOrWhiteSpace(payload.Email) ||
                    payload.EmailVerified != true)
                {
                    return Unauthorized(new
                    {
                        message = "Tài khoản Google chưa được xác minh."
                    });
                }

                var user = await _context.Users.FirstOrDefaultAsync(
                    u => u.GoogleId == payload.Subject);

                if (user == null)
                {
                    return NotFound(new
                    {
                        message =
                            "Chưa có tài khoản Google trên Trọ Ơi. " +
                            "Vui lòng đăng ký trước."
                    });
                }

                if (user.Status != "active")
                {
                    return Unauthorized(new
                    {
                        message = "Tài khoản của bạn đang bị khóa."
                    });
                }

                return Ok(new
                {
                    message = "Đăng nhập Google thành công!",
                    isNewUser = false,
                    data = new
                    {
                        user.Id,
                        user.Name,
                        user.Email,
                        user.Phone,
                        user.Role,
                        user.Avatar,
                        accessToken = GenerateJwtToken(user),
                        tokenType = "Bearer"
                    }
                });
            }
            catch (InvalidJwtException)
            {
                return Unauthorized(new
                {
                    message = "Google ID token không hợp lệ hoặc đã hết hạn."
                });
            }
            catch (Exception)
            {
                return StatusCode(500, new
                {
                    message = "Không thể xử lý đăng nhập Google lúc này."
                });
            }
        }

        // 4. ĐĂNG KÝ BẰNG GOOGLE
        // POST /api/Auth/google-register
        [HttpPost("google-register")]
        public async Task<IActionResult> GoogleRegister(
            [FromBody] GoogleLoginRequestDTO model)
        {
            if (string.IsNullOrWhiteSpace(model.IdToken))
            {
                return BadRequest(new
                {
                    message = "Thiếu Google ID token."
                });
            }

            try
            {
                var payload = await ValidateGoogleToken(model.IdToken);

                if (string.IsNullOrWhiteSpace(payload.Subject) ||
                    string.IsNullOrWhiteSpace(payload.Email) ||
                    payload.EmailVerified != true)
                {
                    return Unauthorized(new
                    {
                        message = "Tài khoản Google chưa được xác minh."
                    });
                }

                string googleId = payload.Subject;
                string email = payload.Email.Trim().ToLowerInvariant();

                if (await _context.Users.AnyAsync(
                    u => u.GoogleId == googleId))
                {
                    return Conflict(new
                    {
                        message =
                            "Tài khoản Google này đã đăng ký. " +
                            "Vui lòng đăng nhập."
                    });
                }

                if (await _context.Users.AnyAsync(
                    u => u.Email.ToLower() == email))
                {
                    return Conflict(new
                    {
                        message =
                            "Email này đã có tài khoản Trọ Ơi. " +
                            "Vui lòng đăng nhập bằng tài khoản hiện tại."
                    });
                }

                string role = NormalizeRole(model.Role);

                if (role == null)
                {
                    return BadRequest(new
                    {
                        message = "Vai trò tài khoản không hợp lệ."
                    });
                }

                var newUser = new User
                {
                    Id = "USER_" + Guid.NewGuid().ToString("N")[..8],
                    Name = string.IsNullOrWhiteSpace(payload.Name)
                        ? email.Split('@')[0]
                        : payload.Name,
                    Email = email,
                    GoogleId = googleId,
                    Password = Convert.ToHexString(
                        RandomNumberGenerator.GetBytes(32)),
                    Avatar = payload.Picture,
                    Role = role,
                    Status = "active",
                    EmailVerifiedAt = DateTime.UtcNow,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };

                _context.Users.Add(newUser);
                await _context.SaveChangesAsync();

                return Ok(new
                {
                    message = "Đăng ký Google thành công!",
                    isNewUser = true,
                    data = new
                    {
                        newUser.Id,
                        newUser.Name,
                        newUser.Email,
                        newUser.Phone,
                        newUser.Role,
                        newUser.Avatar
                    }
                });
            }
            catch (InvalidJwtException)
            {
                return Unauthorized(new
                {
                    message = "Google ID token không hợp lệ hoặc đã hết hạn."
                });
            }
            catch (DbUpdateException)
            {
                return Conflict(new
                {
                    message =
                        "Email hoặc tài khoản Google đã được đăng ký."
                });
            }
            catch (Exception)
            {
                return StatusCode(500, new
                {
                    message = "Không thể xử lý đăng ký Google lúc này."
                });
            }
        }

        // 5. ĐĂNG KÝ BẰNG ZALO
        // POST /api/Auth/zalo-register
        [HttpPost("zalo-register")]
        public async Task<IActionResult> ZaloRegister(
            [FromBody] ZaloRegisterRequestDTO model)
        {
            if (string.IsNullOrWhiteSpace(model.AccessToken))
            {
                return BadRequest(new
                {
                    message = "Thiếu Zalo Access Token."
                });
            }

            string role = NormalizeRole(model.Role);

            if (role == null)
            {
                return BadRequest(new
                {
                    message = "Vai trò tài khoản không hợp lệ."
                });
            }

            try
            {
                // Gọi Zalo Social API để xác minh token và lấy hồ sơ.
                var client = _httpClientFactory.CreateClient();

                var profileUri = new UriBuilder(
                    "https://graph.zalo.me/v2.0/me");

                var query = System.Web.HttpUtility.ParseQueryString(
                    string.Empty);

                query["access_token"] = model.AccessToken;
                query["fields"] = "id,name,picture";
                profileUri.Query = query.ToString();

                using var response = await client.GetAsync(
                    profileUri.Uri);

                if (!response.IsSuccessStatusCode)
                {
                    return Unauthorized(new
                    {
                        message =
                            "Không xác minh được tài khoản Zalo. " +
                            "Vui lòng đăng nhập Zalo lại."
                    });
                }

                using var document = JsonDocument.Parse(
                    await response.Content.ReadAsStringAsync());

                var root = document.RootElement;

                if (root.TryGetProperty("error", out var errorElement) &&
                    errorElement.ToString() != "0")
                {
                    return Unauthorized(new
                    {
                        message = "Zalo không xác nhận được Access Token."
                    });
                }

                string? zaloId = root.TryGetProperty("id", out var idElement)
                    ? idElement.ToString()
                    : null;

                string? name = root.TryGetProperty("name", out var nameElement)
                    ? nameElement.GetString()
                    : null;

                string? avatar = null;

                if (root.TryGetProperty("picture", out var picture) &&
                    picture.ValueKind == JsonValueKind.Object &&
                    picture.TryGetProperty("data", out var pictureData) &&
                    pictureData.ValueKind == JsonValueKind.Object &&
                    pictureData.TryGetProperty("url", out var pictureUrl))
                {
                    avatar = pictureUrl.GetString();
                }

                if (string.IsNullOrWhiteSpace(zaloId))
                {
                    return Unauthorized(new
                    {
                        message = "Không lấy được ID tài khoản Zalo."
                    });
                }

                bool zaloExists = await _context.Users.AnyAsync(
                    u => u.ZaloId == zaloId);

                if (zaloExists)
                {
                    return Conflict(new
                    {
                        message =
                            "Tài khoản Zalo này đã đăng ký Trọ Ơi. " +
                            "Vui lòng đăng nhập bằng tài khoản hiện tại."
                    });
                }

                // Zalo Social API không nhất thiết trả về email.
                // Tạo email nội bộ để đáp ứng cột email bắt buộc.
                string email = $"zalo_{zaloId}@zalo.local";

                if (await _context.Users.AnyAsync(
                    u => u.Email == email))
                {
                    return Conflict(new
                    {
                        message = "Email nội bộ của tài khoản đã tồn tại."
                    });
                }

                if (avatar?.Length > 255)
                {
                    avatar = null;
                }

                var newUser = new User
                {
                    Id = "USER_" + Guid.NewGuid().ToString("N")[..8],
                    Name = string.IsNullOrWhiteSpace(name)
                        ? "Người dùng Zalo"
                        : name.Trim(),
                    Email = email,
                    ZaloId = zaloId,
                    Password = Convert.ToHexString(
                        RandomNumberGenerator.GetBytes(32)),
                    Avatar = avatar,
                    Role = role,
                    Status = "active",
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };

                _context.Users.Add(newUser);
                await _context.SaveChangesAsync();

                return Ok(new
                {
                    message = "Đăng ký Zalo thành công!",
                    isNewUser = true,
                    data = new
                    {
                        newUser.Id,
                        newUser.Name,
                        newUser.Email,
                        newUser.Phone,
                        newUser.Role,
                        newUser.Avatar
                    }
                });
            }
            catch (JsonException)
            {
                return Unauthorized(new
                {
                    message = "Dữ liệu hồ sơ trả về từ Zalo không hợp lệ."
                });
            }
            catch (HttpRequestException)
            {
                return StatusCode(503, new
                {
                    message = "Hiện không thể kết nối tới Zalo."
                });
            }
            catch (DbUpdateException)
            {
                return Conflict(new
                {
                    message =
                        "Tài khoản Zalo hoặc email đã được đăng ký."
                });
            }
            catch (Exception)
            {
                return StatusCode(500, new
                {
                    message = "Không thể xử lý đăng ký Zalo lúc này."
                });
            }
        }


        // 6. ĐĂNG NHẬP BẰNG ZALO
        // POST /api/Auth/zalo-login
        [HttpPost("zalo-login")]
        public async Task<IActionResult> ZaloLogin(
            [FromBody] ZaloLoginRequestDTO model)
        {
            if (string.IsNullOrWhiteSpace(model.AccessToken))
            {
                return BadRequest(new
                {
                    message = "Thiếu Zalo Access Token."
                });
            }

            try
            {
                // 1. Xác minh access token với Zalo
                var client = _httpClientFactory.CreateClient();

                var profileUri = new UriBuilder(
                    "https://graph.zalo.me/v2.0/me");

                var query = System.Web.HttpUtility.ParseQueryString(
                    string.Empty);

                query["access_token"] = model.AccessToken;
                query["fields"] = "id,name,picture";
                profileUri.Query = query.ToString();

                using var response = await client.GetAsync(
                    profileUri.Uri);

                if (!response.IsSuccessStatusCode)
                {
                    return Unauthorized(new
                    {
                        message =
                            "Không xác minh được tài khoản Zalo. " +
                            "Vui lòng đăng nhập Zalo lại."
                    });
                }

                var responseBody =
                    await response.Content.ReadAsStringAsync();

                using var document = JsonDocument.Parse(responseBody);
                var root = document.RootElement;

                if (root.TryGetProperty("error", out var errorElement) &&
                    errorElement.ToString() != "0")
                {
                    return Unauthorized(new
                    {
                        message = "Zalo không xác nhận được Access Token."
                    });
                }

                // 2. Lấy Zalo ID từ hồ sơ đã xác minh
                string? zaloId =
                    root.TryGetProperty("id", out var idElement)
                        ? idElement.ToString()
                        : null;

                if (string.IsNullOrWhiteSpace(zaloId))
                {
                    return Unauthorized(new
                    {
                        message = "Không lấy được ID tài khoản Zalo."
                    });
                }

                // 3. Tìm tài khoản Zalo đã đăng ký trước đó
                var user = await _context.Users.FirstOrDefaultAsync(
                    u => u.ZaloId == zaloId);

                if (user == null)
                {
                    return NotFound(new
                    {
                        message =
                            "Tài khoản Zalo chưa đăng ký Trọ Ơi. " +
                            "Vui lòng đăng ký trước."
                    });
                }

                // 4. Kiểm tra trạng thái tài khoản
                if (user.Status != "active")
                {
                    return Unauthorized(new
                    {
                        message = "Tài khoản của bạn đang bị khóa."
                    });
                }

                // 5. Trả dữ liệu cho Flutter
                return Ok(new
                {
                    message = "Đăng nhập Zalo thành công!",
                    isNewUser = false,
                    data = new
                    {
                        user.Id,
                        user.Name,
                        user.Email,
                        user.Phone,
                        user.Role,
                        user.Avatar,
                        accessToken = GenerateJwtToken(user),
                        tokenType = "Bearer"
                    }
                });
            }
            catch (JsonException)
            {
                return Unauthorized(new
                {
                    message = "Dữ liệu hồ sơ trả về từ Zalo không hợp lệ."
                });
            }
            catch (HttpRequestException)
            {
                return StatusCode(503, new
                {
                    message = "Hiện không thể kết nối tới Zalo."
                });
            }
            catch (DbUpdateException)
            {
                return StatusCode(500, new
                {
                    message = "Không thể truy vấn tài khoản Zalo."
                });
            }
            catch (Exception)
            {
                return StatusCode(500, new
                {
                    message = "Không thể xử lý đăng nhập Zalo lúc này."
                });
            }
        }

        private enum OtpSendStatus { Sent, RateLimited, Failed }

        private bool IsSmtpConfigured() =>
            !string.IsNullOrWhiteSpace(_configuration["GmailSmtp:Username"]) &&
            !string.IsNullOrWhiteSpace(_configuration["GmailSmtp:AppPassword"]);

        private IActionResult SmtpNotConfigured() =>
            StatusCode(StatusCodes.Status503ServiceUnavailable, new
            {
                message = "Backend chưa cấu hình Gmail SMTP."
            });

        private IActionResult SmtpUnavailable() =>
            StatusCode(StatusCodes.Status503ServiceUnavailable, new
            {
                message = "Không gửi được email lúc này. Hãy kiểm tra Gmail SMTP và App Password."
            });

        private IActionResult InvalidOtp() =>
            BadRequest(new
            {
                message = "Email hoặc mã xác nhận không hợp lệ, đã hết hạn hoặc đã được sử dụng."
            });

        private static bool IsInternalEmail(string email) =>
            email.EndsWith("@phone.com", StringComparison.OrdinalIgnoreCase) ||
            email.EndsWith("@zalo.local", StringComparison.OrdinalIgnoreCase) ||
            email.EndsWith("@tenant.local", StringComparison.OrdinalIgnoreCase);

        private async Task<OtpSendStatus> SendOtpEmailAsync(
            User user,
            string purpose,
            CancellationToken cancellationToken)
        {
            var now = DateTime.UtcNow;
            var hasRecentRequest = await _context.EmailOtps.AnyAsync(
                otp => otp.UserId == user.Id && otp.Purpose == purpose &&
                       otp.CreatedAt > now.AddSeconds(-60),
                cancellationToken);
            if (hasRecentRequest) return OtpSendStatus.RateLimited;

            var oldOtps = await _context.EmailOtps
                .Where(otp => otp.UserId == user.Id && otp.Purpose == purpose &&
                              otp.UsedAt == null)
                .ToListAsync(cancellationToken);
            foreach (var oldOtp in oldOtps) oldOtp.UsedAt = now;

            var code = RandomNumberGenerator.GetInt32(0, 1_000_000).ToString("D6");
            var codeHash = Convert.ToHexString(SHA256.HashData(
                Encoding.UTF8.GetBytes($"{user.Id}:{purpose}:{code}")));
            var otp = new EmailOtp
            {
                UserId = user.Id,
                Purpose = purpose,
                CodeHash = codeHash,
                CreatedAt = now,
                ExpiresAt = now.AddMinutes(10),
                Attempts = 0
            };
            _context.EmailOtps.Add(otp);
            await _context.SaveChangesAsync(cancellationToken);

            var safeName = WebUtility.HtmlEncode(user.Name);
            var html = $"""
                <div style="font-family:Arial,sans-serif;line-height:1.6;color:#24312b">
                  <h2>Khôi phục mật khẩu Trọ Ơi</h2>
                  <p>Xin chào {safeName},</p>
                  <p>Mã đặt lại mật khẩu của bạn là:</p>
                  <p style="font-size:28px;font-weight:bold;letter-spacing:6px">{code}</p>
                  <p>Mã có hiệu lực trong 10 phút. Nếu bạn không yêu cầu, hãy bỏ qua email này.</p>
                </div>
                """;

            try
            {
                var message = new MimeMessage();
                var username = _configuration["GmailSmtp:Username"]!;
                var appPassword = string.Concat(
                    _configuration["GmailSmtp:AppPassword"]!.Where(
                        character => !char.IsWhiteSpace(character)));
                message.From.Add(new MailboxAddress(
                    _configuration["GmailSmtp:FromName"] ?? "Tro Oi", username));
                message.To.Add(MailboxAddress.Parse(user.Email));
                message.Subject = "Mã khôi phục mật khẩu Trọ Ơi";
                message.Body = new BodyBuilder { HtmlBody = html }.ToMessageBody();

                using var smtp = new MailKit.Net.Smtp.SmtpClient
                {
                    Timeout = 15_000
                };
                var host = _configuration["GmailSmtp:Host"] ?? "smtp.gmail.com";
                var port = int.TryParse(_configuration["GmailSmtp:Port"], out var configuredPort)
                    ? configuredPort
                    : 587;
                await smtp.ConnectAsync(
                    host, port, SecureSocketOptions.StartTls, cancellationToken);
                await smtp.AuthenticateAsync(
                    username,
                    appPassword,
                    cancellationToken);
                await smtp.SendAsync(message, cancellationToken);
                await smtp.DisconnectAsync(true, cancellationToken);
                return OtpSendStatus.Sent;
            }
            catch (OperationCanceledException) when (cancellationToken.IsCancellationRequested)
            {
                throw;
            }
            catch (Exception exception)
            {
                _logger.LogError(exception, "Could not send {Purpose} email through Gmail SMTP.", purpose);
            }

            otp.UsedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync(cancellationToken);
            return OtpSendStatus.Failed;
        }

        private async Task<EmailOtp?> FindOtpAsync(
            string userId,
            string purpose,
            DateTime now,
            CancellationToken cancellationToken) =>
            await _context.EmailOtps
                .Where(otp => otp.UserId == userId && otp.Purpose == purpose &&
                              otp.UsedAt == null && otp.ExpiresAt > now &&
                              otp.Attempts < 5)
                .OrderByDescending(otp => otp.CreatedAt)
                .FirstOrDefaultAsync(cancellationToken);

        private static bool VerifyOtpHash(
            string userId,
            string purpose,
            string code,
            string storedHash)
        {
            var submittedHash = SHA256.HashData(Encoding.UTF8.GetBytes(
                $"{userId}:{purpose}:{code}"));
            return CryptographicOperations.FixedTimeEquals(
                submittedHash, Convert.FromHexString(storedHash));
        }

        // HÀM DÙNG CHUNG: TẠO JWT
        private string GenerateJwtToken(User user)
        {
            var jwtKey = _configuration["Jwt:Key"];
            var jwtIssuer = _configuration["Jwt:Issuer"];
            var jwtAudience = _configuration["Jwt:Audience"];

            if (string.IsNullOrWhiteSpace(jwtKey) ||
                string.IsNullOrWhiteSpace(jwtIssuer) ||
                string.IsNullOrWhiteSpace(jwtAudience))
            {
                throw new InvalidOperationException(
                    "Thiếu cấu hình JWT.");
            }

            var key = new SymmetricSecurityKey(
                System.Text.Encoding.UTF8.GetBytes(jwtKey));

            var credentials = new SigningCredentials(
                key,
                SecurityAlgorithms.HmacSha256);

            var claims = new[]
            {
        new Claim(ClaimTypes.NameIdentifier, user.Id),
        new Claim(ClaimTypes.Role, user.Role),
        new Claim(ClaimTypes.Name, user.Name ?? "")
    };

            int expireMinutes = int.TryParse(
                _configuration["Jwt:ExpireMinutes"],
                out int minutes)
                    ? minutes
                    : 60;

            var token = new JwtSecurityToken(
                issuer: jwtIssuer,
                audience: jwtAudience,
                claims: claims,
                expires: DateTime.UtcNow.AddMinutes(expireMinutes),
                signingCredentials: credentials
            );

            return new JwtSecurityTokenHandler().WriteToken(token);
        }


        // HÀM DÙNG CHUNG: XÁC MINH GOOGLE ID TOKEN
        private static async Task<GoogleJsonWebSignature.Payload>
            ValidateGoogleToken(string idToken)
        {
            const string webClientId =
                "843670435307-mngs2e74rvnfc3rb7044alb5m60fs2ea.apps.googleusercontent.com";

            return await GoogleJsonWebSignature.ValidateAsync(
                idToken,
                new GoogleJsonWebSignature.ValidationSettings
                {
                    Audience = new[] { webClientId }
                });
        }

        // HÀM DÙNG CHUNG: CHUẨN HÓA VAI TRÒ
        private static string? NormalizeRole(string? input)
        {
            string role = input?.Trim().ToLowerInvariant() ?? "tenant";

            if (role == "landlord")
            {
                role = "owner";
            }

            return role == "tenant" || role == "owner"
                ? role
                : null;
        }
    }
}
