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

        public AdminUsersController(QuanLyPhongTroContext context)
        {
            _context = context;
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

                return Ok(new { message = "Cập nhật trạng thái thành công!", status = user.Status });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi khi cập nhật trạng thái", error = ex.Message });
            }
        }
    }
}