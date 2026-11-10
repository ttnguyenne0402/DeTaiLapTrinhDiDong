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

namespace Backend.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AuthController : ControllerBase
    {
        private readonly QuanLyPhongTroContext _context;
        private readonly IHttpClientFactory _httpClientFactory;
        private readonly IConfiguration _configuration;

        public AuthController(
    QuanLyPhongTroContext context,
    IHttpClientFactory httpClientFactory,
    IConfiguration configuration)
        {
            _context = context;
            _httpClientFactory = httpClientFactory;
            _configuration = configuration;
        }

        // 1. ĐĂNG KÝ BẰNG EMAIL/SỐ ĐIỆN THOẠI
        // POST /api/Auth/register
        [HttpPost("register")]
        public async Task<IActionResult> Register(
            [FromBody] RegisterRequestDTO model)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(model.FullName) ||
                    string.IsNullOrWhiteSpace(model.EmailOrPhone) ||
                    string.IsNullOrWhiteSpace(model.Password))
                {
                    return BadRequest(new
                    {
                        message = "Vui lòng nhập đầy đủ thông tin."
                    });
                }

                string emailOrPhone = model.EmailOrPhone.Trim();

                bool existingUser = await _context.Users.AnyAsync(u =>
                    u.Email == emailOrPhone ||
                    u.Phone == emailOrPhone);

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

                string email = emailOrPhone.Contains("@")
                    ? emailOrPhone
                    : $"{Guid.NewGuid():N}@phone.com";

                var newUser = new User
                {
                    Id = "USER_" + Guid.NewGuid().ToString("N")[..8],
                    Name = model.FullName.Trim(),
                    Email = email,
                    Phone = emailOrPhone.Contains("@")
                        ? null
                        : emailOrPhone,
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
                    message = "Đăng ký tài khoản thành công!",
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
