using System;
using Backend.DTOs;
using Backend.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Backend.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AdminUsersController : ControllerBase
    {
        private readonly QuanLyPhongTroContext _context;
        private readonly IConfiguration _config;

        public AdminUsersController(QuanLyPhongTroContext context, IConfiguration config)
        {
            _context = context;
            _config = config;
        }

        // 1. GET: /api/AdminUsers?role=tenant&search=viet
        [HttpGet]
        public async Task<IActionResult> GetUsers([FromQuery] string? role, [FromQuery] string? search)
        {
            try
            {
                var query = _context.Users.AsQueryable();

                // Lọc theo role (trừ role admin để tránh admin tự khóa mình)
                if (!string.IsNullOrEmpty(role) && role.ToLower() != "all")
                {
                    query = query.Where(u => u.Role.ToLower() == role.ToLower());
                }

                // Tìm kiếm theo tên, email hoặc số điện thoại
                if (!string.IsNullOrWhiteSpace(search))
                {
                    var keyword = search.Trim().ToLower();
                    query = query.Where(u => u.Name.ToLower().Contains(keyword) ||
                                             u.Email.ToLower().Contains(keyword) ||
                                             (u.Phone != null && u.Phone.Contains(keyword)));
                }

                var list = await query
                    .OrderByDescending(u => u.CreatedAt)
                    .Select(u => new AdminUserListItemDto
                    {
                        Id = u.Id,
                        Name = u.Name,
                        Email = u.Email,
                        Phone = u.Phone,
                        Avatar = u.Avatar,
                        Role = u.Role,
                        Status = u.Status,
                        CreatedAt = u.CreatedAt
                    })
                    .ToListAsync();

                return Ok(list);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi khi lấy danh sách tài khoản", error = ex.Message });
            }
        }

        // 2. PUT: /api/AdminUsers/{id}/status (Khóa hoặc Kích hoạt tài khoản)
        [HttpPut("{id}/status")]
        public async Task<IActionResult> UpdateStatus(string id, [FromBody] UpdateUserStatusRequest request)
        {
            try
            {
                var user = await _context.Users.FindAsync(id);
                if (user == null)
                {
                    return NotFound(new { message = "Không tìm thấy người dùng." });
                }

                if (user.Role.ToLower() == "admin")
                {
                    return BadRequest(new { message = "Không thể thay đổi trạng thái của tài khoản Admin." });
                }

                var newStatus = request.Status.ToLower();
                if (newStatus != "active" && newStatus != "blocked")
                {
                    return BadRequest(new { message = "Trạng thái không hợp lệ. Chỉ chấp nhận 'active' hoặc 'blocked'." });
                }

                user.Status = newStatus;
                user.UpdatedAt = DateTime.UtcNow;

                await _context.SaveChangesAsync();


                if (newStatus == "blocked")
                {
                    string subject = "[Quản Lý Phòng Trọ] Thông báo tạm khóa tài khoản";
                    string htmlContent = $@"
                        <h3>Chào {user.Name},</h3>
                        <p>Tài khoản <b>{user.Email}</b> của bạn đã bị <b>Quản trị viên tạm khóa</b> do vi phạm chính sách sử dụng.</p>
                        <p>Nếu bạn muốn yêu cầu hỗ trợ xem xét mở lại tài khoản, vui lòng liên hệ Admin qua:</p>
                        <ul>
                            <li><b>Số điện thoại / Zalo:</b> 0909 123 456</li>
                            <li><b>Email hỗ trợ:</b> admin@phongtro.vn</li>
                        </ul>
                        <p>Trân trọng,<br>Ban Quản Trị Hệ Thống</p>";

                     await SendEmailAsync(user.Email, user.Name, subject, htmlContent);
                }
                else if (newStatus == "active")
                {
                    string subject = "[Quản Lý Phòng Trọ] Tài khoản của bạn đã được mở khóa! 🎉";
                    string htmlContent = $@"
                        <h3>Chào {user.Name},</h3>
                        <p>Quản trị viên đã xem xét và <b>kích hoạt lại tài khoản {user.Email}</b> của bạn.</p>
                        <p>Hiện tại bạn đã có thể mở ứng dụng và đăng nhập lại bình thường.</p>
                        <p>Chúc bạn có trải nghiệm tuyệt vời!</p>";

                    await SendEmailAsync(user.Email, user.Name, subject, htmlContent);
                }

                return Ok(new { message = "Cập nhật trạng thái thành công!", status = user.Status });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi khi cập nhật trạng thái", error = ex.Message });
            }
        }


        private async Task SendEmailAsync(string toEmail, string name, string subject, string htmlContent)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(toEmail) || !toEmail.Contains("@") || toEmail.EndsWith(".local")) return;

                var senderEmail = _config["EmailSettings:SenderEmail"];
                var senderName = _config["EmailSettings:SenderName"] ?? "Quản Lý Phòng Trọ";
                var appPassword = _config["EmailSettings:AppPassword"];

                if (string.IsNullOrWhiteSpace(senderEmail) || string.IsNullOrWhiteSpace(appPassword))
                {
                    Console.WriteLine("[GMAIL SMTP ERROR]: Chưa cấu hình EmailSettings trong appsettings.json");
                    return;
                }

                using var message = new System.Net.Mail.MailMessage();
                message.From = new System.Net.Mail.MailAddress(senderEmail, senderName);
                message.To.Add(new System.Net.Mail.MailAddress(toEmail, name));
                message.Subject = subject;
                message.Body = htmlContent;
                message.IsBodyHtml = true;

                using var smtp = new System.Net.Mail.SmtpClient("smtp.gmail.com", 587)
                {
                    DeliveryMethod = System.Net.Mail.SmtpDeliveryMethod.Network,
                    UseDefaultCredentials = false,
                    Credentials = new System.Net.NetworkCredential(senderEmail, appPassword),
                    EnableSsl = true
                };

                await smtp.SendMailAsync(message);
                Console.WriteLine($"[GMAIL SMTP SUCCESS]: Đã gửi email tới {toEmail}");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[GMAIL SMTP ERROR]: {ex}");
            }
        }
    }
}