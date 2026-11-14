
using Backend.DTOs;
using Backend.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using System.ComponentModel.DataAnnotations;

namespace Backend.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class ProfileController : ControllerBase
    {
        private readonly QuanLyPhongTroContext _context;

        public ProfileController(QuanLyPhongTroContext context)
        {
            _context = context;
        }

        // GET: api/Profile
        // Lấy thông tin cá nhân và danh sách tài khoản ngân hàng
        [HttpGet]
        public async Task<IActionResult> GetProfile()
        {
            try
            {
                // Lấy ID người dùng từ JWT
                string? userId = User.FindFirstValue(
                    ClaimTypes.NameIdentifier);

                if (string.IsNullOrWhiteSpace(userId))
                {
                    return Unauthorized(new
                    {
                        message = "Không xác định được người dùng."
                    });
                }

                // Tìm người dùng và tài khoản ngân hàng
                var user = await _context.Users
                    .Include(u => u.BankAccounts)
                    .FirstOrDefaultAsync(u => u.Id == userId);

                if (user == null)
                {
                    return NotFound(new
                    {
                        message = "Không tìm thấy thông tin người dùng."
                    });
                }

                // Chuyển dữ liệu sang DTO
                var result = new ProfileResponseDTO
                {
                    Id = user.Id,
                    Name = user.Name,
                    Email = user.Email,
                    Phone = user.Phone,
                    Avatar = user.Avatar,
                    Role = user.Role,

                    BankAccounts = user.BankAccounts
                        .Select(bank => new BankAccountDTO
                        {
                            Id = bank.Id,
                            BankCode = bank.BankCode,
                            BankName = bank.BankName,
                            AccountNumber = bank.AccountNumber,
                            AccountHolder = bank.AccountHolder,
                            IsDefault = bank.IsDefault,
                            Status = bank.Status
                        })
                        .ToList()
                };

                return Ok(new
                {
                    message = "Lấy thông tin cá nhân thành công.",
                    data = result
                });
            }
            catch (Exception)
            {
                return StatusCode(500, new
                {
                    message = "Không thể lấy thông tin cá nhân lúc này."
                });
            }
        }

        [HttpPut]
        public async Task<IActionResult> UpdateProfile(
         [FromBody] UpdateProfileRequestDTO request)
        {
            string? userId = User.FindFirstValue(ClaimTypes.NameIdentifier);

            if (string.IsNullOrWhiteSpace(userId))
                return Unauthorized(new { message = "Không xác định được người dùng." });

            if (string.IsNullOrWhiteSpace(request.Name) ||
                string.IsNullOrWhiteSpace(request.Email))
            {
                return BadRequest(new
                {
                    message = "Họ tên và email không được để trống."
                });
            }

            var user = await _context.Users
                .FirstOrDefaultAsync(u => u.Id == userId);

            if (user == null)
                return NotFound(new { message = "Không tìm thấy người dùng." });

            string email = request.Email.Trim();
            if (!new EmailAddressAttribute().IsValid(email))
                return BadRequest(new { message = "Email không hợp lệ." });

            bool emailExists = await _context.Users.AnyAsync(u =>
                u.Email == email && u.Id != userId);

            if (emailExists)
                return Conflict(new { message = "Email này đã được sử dụng." });

            var emailChanged = !string.Equals(
                user.Email, email, StringComparison.OrdinalIgnoreCase);
            user.Name = request.Name.Trim();
            user.Email = email;
            if (emailChanged)
                user.EmailVerifiedAt = null;
            user.Phone = string.IsNullOrWhiteSpace(request.Phone)
                ? null
                : request.Phone.Trim();
            user.UpdatedAt = DateTime.Now;

            await _context.SaveChangesAsync();

            return Ok(new
            {
                message = "Cập nhật thông tin cá nhân thành công.",
                data = new
                {
                    user.Id,
                    user.Name,
                    user.Email,
                    user.Phone
                }
            });
        }


        [HttpPost("bank-accounts")]
        public async Task<IActionResult> AddBankAccount(
    [FromBody] BankAccountRequestDTO request)
        {
            string? userId = User.FindFirstValue(ClaimTypes.NameIdentifier);

            if (string.IsNullOrWhiteSpace(userId))
                return Unauthorized(new { message = "Không xác định được người dùng." });

            if (string.IsNullOrWhiteSpace(request.AccountNumber) ||
                string.IsNullOrWhiteSpace(request.AccountHolder) ||
                string.IsNullOrWhiteSpace(request.BankName))
            {
                return BadRequest(new
                {
                    message = "Vui lòng nhập đầy đủ thông tin ngân hàng."
                });
            }

            var userExists = await _context.Users.AnyAsync(u => u.Id == userId);

            if (!userExists)
                return NotFound(new { message = "Không tìm thấy người dùng." });

            // BankCode là trường bắt buộc trong database.
            // Nếu Flutter chưa gửi mã ngân hàng thì tạm dùng tên ngân hàng
            // đã chuẩn hóa làm giá trị thay thế.
            string bankCode = string.IsNullOrWhiteSpace(request.BankCode)
                ? request.BankName.Trim().ToUpperInvariant()
                : request.BankCode.Trim();

            if (bankCode.Length > 20 ||
                request.BankName.Trim().Length > 100 ||
                request.AccountNumber.Trim().Length > 30 ||
                request.AccountHolder.Trim().Length > 100)
            {
                return BadRequest(new
                {
                    message = "Một hoặc nhiều thông tin vượt quá độ dài cho phép."
                });
            }

            var bankAccount = new BankAccount
            {
                Id = Guid.NewGuid().ToString(),
                UserId = userId,
                BankCode = bankCode,
                BankName = request.BankName.Trim(),
                AccountNumber = request.AccountNumber.Trim(),
                AccountHolder = request.AccountHolder.Trim(),
                IsDefault = !await _context.BankAccounts
                    .AnyAsync(b => b.UserId == userId),
                Status = "active",
                CreatedAt = DateTime.Now,
                UpdatedAt = DateTime.Now
            };

            _context.BankAccounts.Add(bankAccount);

            await _context.SaveChangesAsync();

            var result = new BankAccountDTO
            {
                Id = bankAccount.Id,
                BankCode = bankAccount.BankCode,
                BankName = bankAccount.BankName,
                AccountNumber = bankAccount.AccountNumber,
                AccountHolder = bankAccount.AccountHolder,
                IsDefault = bankAccount.IsDefault,
                Status = bankAccount.Status
            };

            return Ok(new
            {
                message = "Thêm tài khoản ngân hàng thành công.",
                data = result
            });
        }

        [HttpPut("bank-accounts/{id}")]
        public async Task<IActionResult> UpdateBankAccount(
    string id,
    [FromBody] BankAccountRequestDTO request)
        {
            string? userId = User.FindFirstValue(ClaimTypes.NameIdentifier);

            if (string.IsNullOrWhiteSpace(userId))
                return Unauthorized(new { message = "Không xác định được người dùng." });

            if (string.IsNullOrWhiteSpace(request.AccountNumber) ||
                string.IsNullOrWhiteSpace(request.AccountHolder) ||
                string.IsNullOrWhiteSpace(request.BankName))
            {
                return BadRequest(new
                {
                    message = "Vui lòng nhập đầy đủ thông tin ngân hàng."
                });
            }

            var bankAccount = await _context.BankAccounts
                .FirstOrDefaultAsync(b => b.Id == id && b.UserId == userId);

            if (bankAccount == null)
                return NotFound(new
                {
                    message = "Không tìm thấy tài khoản ngân hàng."
                });

            string bankCode = string.IsNullOrWhiteSpace(request.BankCode)
                ? request.BankName.Trim().ToUpperInvariant()
                : request.BankCode.Trim();

            if (bankCode.Length > 20 ||
                request.BankName.Trim().Length > 100 ||
                request.AccountNumber.Trim().Length > 30 ||
                request.AccountHolder.Trim().Length > 100)
            {
                return BadRequest(new
                {
                    message = "Một hoặc nhiều thông tin vượt quá độ dài cho phép."
                });
            }

            bankAccount.BankCode = bankCode;
            bankAccount.BankName = request.BankName.Trim();
            bankAccount.AccountNumber = request.AccountNumber.Trim();
            bankAccount.AccountHolder = request.AccountHolder.Trim();
            bankAccount.UpdatedAt = DateTime.Now;

            await _context.SaveChangesAsync();

            return Ok(new
            {
                message = "Cập nhật tài khoản ngân hàng thành công.",
                data = new BankAccountDTO
                {
                    Id = bankAccount.Id,
                    BankCode = bankAccount.BankCode,
                    BankName = bankAccount.BankName,
                    AccountNumber = bankAccount.AccountNumber,
                    AccountHolder = bankAccount.AccountHolder,
                    IsDefault = bankAccount.IsDefault,
                    Status = bankAccount.Status
                }
            });
        }
    }
}
