using Backend.Helpers;
using Backend.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Backend.Controllers
{
    [Route("api/owner/notifications")]
    [ApiController]
    public class OwnerNotificationsController : ControllerBase
    {
        private readonly QuanLyPhongTroContext _context;

        public OwnerNotificationsController(QuanLyPhongTroContext context)
        {
            _context = context;
        }

        // 1. GET: api/owner/notifications/{ownerId}
        [HttpGet("{ownerId}")]
        public async Task<IActionResult> GetOwnerNotifications(string ownerId)
        {
            try
            {
                var targetOwnerIds = OwnerHelper.ResolveOwnerIds(ownerId);

                var list = await _context.Notifications
                    .Where(n => targetOwnerIds.Contains(n.UserId))
                    .OrderByDescending(n => n.CreatedAt)
                    .ToListAsync();

                var now = DateTime.Now;

                var result = list.Select(n =>
                {
                    var created = n.CreatedAt ?? now;
                    string timeAgo;
                    var diff = now - created;

                    if (diff.TotalMinutes < 1)
                        timeAgo = "Vừa xong";
                    else if (diff.TotalMinutes < 60)
                        timeAgo = $"{(int)diff.TotalMinutes} phút trước";
                    else if (diff.TotalHours < 24)
                        timeAgo = $"{(int)diff.TotalHours} giờ trước";
                    else
                        timeAgo = created.ToString("HH:mm - dd/MM/yyyy");

                    return new
                    {
                        id = n.Id,
                        userId = n.UserId,
                        title = n.Title,
                        message = n.Message,
                        type = n.Type,
                        referenceId = n.ReferenceId,
                        referenceType = n.ReferenceType,
                        isRead = n.ReadAt.HasValue,
                        readAt = n.ReadAt?.ToString("dd/MM/yyyy HH:mm"),
                        time = timeAgo,
                        createdAt = created.ToString("dd/MM/yyyy HH:mm")
                    };
                }).ToList();

                return Ok(result);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi khi tải danh sách thông báo", error = ex.Message });
            }
        }

        // 2. PUT: api/owner/notifications/{id}/read
        [HttpPut("{id}/read")]
        public async Task<IActionResult> MarkAsRead(string id)
        {
            try
            {
                var notif = await _context.Notifications
                    .FirstOrDefaultAsync(n => n.Id == id || n.Id.ToLower() == id.ToLower());

                if (notif == null)
                {
                    return NotFound(new { message = "Không tìm thấy thông báo." });
                }

                if (!notif.ReadAt.HasValue)
                {
                    notif.ReadAt = DateTime.Now;
                    notif.UpdatedAt = DateTime.Now;
                    await _context.SaveChangesAsync();
                }

                return Ok(new { message = "Đã đánh dấu đã đọc" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi khi cập nhật thông báo", error = ex.Message });
            }
        }

        // 3. PUT: api/owner/notifications/read-all/{ownerId}
        [HttpPut("read-all/{ownerId}")]
        public async Task<IActionResult> MarkAllAsRead(string ownerId)
        {
            try
            {
                var targetOwnerIds = OwnerHelper.ResolveOwnerIds(ownerId);

                var unreadList = await _context.Notifications
                    .Where(n => targetOwnerIds.Contains(n.UserId) && n.ReadAt == null)
                    .ToListAsync();

                var now = DateTime.Now;
                foreach (var n in unreadList)
                {
                    n.ReadAt = now;
                    n.UpdatedAt = now;
                }

                await _context.SaveChangesAsync();
                return Ok(new { message = "Đã đánh dấu đọc tất cả thông báo" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi khi cập nhật thông báo", error = ex.Message });
            }
        }

        // 4. DELETE: api/owner/notifications/{id}
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteNotification(string id)
        {
            try
            {
                var notif = await _context.Notifications
                    .FirstOrDefaultAsync(n => n.Id == id || n.Id.ToLower() == id.ToLower());

                if (notif == null)
                {
                    return NotFound(new { message = "Không tìm thấy thông báo." });
                }

                _context.Notifications.Remove(notif);
                await _context.SaveChangesAsync();
                return Ok(new { message = "Xóa thông báo thành công" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi khi xóa thông báo", error = ex.Message });
            }
        }
    }
}

