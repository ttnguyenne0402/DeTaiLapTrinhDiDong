using System;
using Backend.DTOs;
using Backend.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Backend.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AdminPostsController : ControllerBase
    {
        private readonly QuanLyPhongTroContext _context;

        public AdminPostsController(QuanLyPhongTroContext context)
        {
            _context = context;
        }

        // 1. GET: /api/AdminPosts?status=pending (hoặc published, rejected)
        [HttpGet]
        public async Task<IActionResult> GetPosts([FromQuery] string? status = "pending")
        {
            try
            {
                var query = _context.RentalPosts
                    .Include(p => p.Room)
                        .ThenInclude(r => r.Property)
                            .ThenInclude(prop => prop.Owner)
                    .Include(p => p.RentalPostImages)
                    .AsQueryable();

                if (!string.IsNullOrEmpty(status))
                {
                    query = query.Where(p => p.Status.ToLower() == status.ToLower());
                }

                var list = await query
                    .OrderByDescending(p => p.CreatedAt)
                    .Select(p => new AdminPostListItemDto
                    {
                        Id = p.Id,
                        Title = p.Title,
                        Price = p.Room != null ? p.Room.Price : 0,
                        Address = p.Room != null && p.Room.Property != null
                            ? $"{p.Room.Property.Address}, {p.Room.Property.Ward}, {p.Room.Property.District}"
                            : "Chưa cập nhật",
                        OwnerName = p.Room != null && p.Room.Property != null && p.Room.Property.Owner != null
                            ? p.Room.Property.Owner.Name
                            : "Ẩn danh",
                        Status = p.Status,
                        Thumbnail = p.RentalPostImages
                            .OrderByDescending(img => img.IsThumbnail)
                            .Select(img => img.ImagePath)
                            .FirstOrDefault() ?? (p.Room != null ? p.Room.Images : null),
                        CreatedAt = p.CreatedAt
                    })
                    .ToListAsync();

                return Ok(list);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi lấy danh sách bài đăng", error = ex.Message });
            }
        }

        // 2. GET: /api/AdminPosts/{id} (Chi tiết tin)
        [HttpGet("{id}")]
        public async Task<IActionResult> GetPostDetail(string id)
        {
            try
            {
                var post = await _context.RentalPosts
                    .Include(p => p.RentalPostImages)
                    .Include(p => p.Room)
                        .ThenInclude(r => r.Property)
                            .ThenInclude(prop => prop.Owner)
                    .Include(p => p.Room)
                        .ThenInclude(r => r.RoomAmenities)
                            .ThenInclude(ra => ra.Amenity)
                    .FirstOrDefaultAsync(p => p.Id == id);

                if (post == null)
                {
                    return NotFound(new { message = "Không tìm thấy tin đăng này." });
                }

                var detail = new AdminPostDetailDto
                {
                    Id = post.Id,
                    RoomId = post.RoomId,
                    Title = post.Title,
                    Description = post.Description,
                    Status = post.Status,
                    RejectionReason = post.RejectionReason,
                    CreatedAt = post.CreatedAt,
                    OwnerName = post.Room?.Property?.Owner?.Name ?? "Ẩn danh",
                    OwnerPhone = post.Room?.Property?.Owner?.Phone,
                    PropertyName = post.Room?.Property?.Name ?? "Chưa rõ tòa nhà",
                    Address = post.Room?.Property != null
                        ? $"{post.Room.Property.Address}, {post.Room.Property.Ward}, {post.Room.Property.District}"
                        : "Chưa có địa chỉ",
                    Price = post.Room?.Price ?? 0,
                    Deposit = post.Room?.Deposit ?? 0,
                    Area = post.Room?.Area ?? 0,
                    MaxPeople = post.Room?.MaxPeople ?? 0,
                    Floor = post.Room?.Floor,
                    Images = post.RentalPostImages.Select(i => i.ImagePath).ToList(),
                    Amenities = post.Room?.RoomAmenities
                        .Where(ra => ra.Amenity != null)
                        .Select(ra => ra.Amenity!.Name)
                        .ToList() ?? new List<string>()
                };

                return Ok(detail);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi khi lấy chi tiết bài đăng", error = ex.Message });
            }
        }

        // 3. PUT: /api/AdminPosts/{id}/moderate (Duyệt hoặc từ chối)
        [HttpPut("{id}/moderate")]
        public async Task<IActionResult> ModeratePost(string id, [FromBody] ModeratePostRequest request)
        {
            try
            {
                var post = await _context.RentalPosts
                    .Include(p => p.Room)
                        .ThenInclude(r => r.Property)
                    .FirstOrDefaultAsync(p => p.Id == id);

                if (post == null)
                {
                    return NotFound(new { message = "Không tìm thấy tin đăng." });
                }

                if (request.Action.ToLower() == "approve")
                {
                    post.Status = "published";
                    post.PublishedAt = DateTime.UtcNow;
                    post.RejectionReason = null;

                    // Cập nhật trạng thái phòng thành sẵn sàng thuê nếu đang trống
                    if (post.Room != null && post.Room.Status == "pending")
                    {
                        post.Room.Status = "available";
                    }

                    // Tùy chọn: Thêm thông báo vào bảng Notifications cho chủ trọ
                    if (post.Room?.Property?.OwnerId != null)
                    {
                        _context.Notifications.Add(new Models.Notification
                        {
                            Id = Guid.NewGuid().ToString(),
                            UserId = post.Room.Property.OwnerId,
                            Title = "Tin đăng của bạn đã được duyệt",
                            Message = $"Bài đăng '{post.Title}' đã được quản trị viên duyệt và xuất bản.",
                            Type = "post_approved",
                            ReferenceId = post.Id,
                            ReferenceType = "rental_post",
                            CreatedAt = DateTime.UtcNow,
                            UpdatedAt = DateTime.UtcNow
                        });
                    }
                }
                else if (request.Action.ToLower() == "reject")
                {
                    post.Status = "rejected";
                    post.RejectionReason = string.IsNullOrWhiteSpace(request.RejectionReason)
                        ? "Không đáp ứng tiêu chuẩn kiểm duyệt của hệ thống."
                        : request.RejectionReason;

                    // Thêm thông báo lý do từ chối cho chủ trọ
                    if (post.Room?.Property?.OwnerId != null)
                    {
                        _context.Notifications.Add(new Models.Notification
                        {
                            Id = Guid.NewGuid().ToString(),
                            UserId = post.Room.Property.OwnerId,
                            Title = "Tin đăng bị từ chối phê duyệt",
                            Message = $"Bài đăng '{post.Title}' bị từ chối với lý do: {post.RejectionReason}",
                            Type = "post_rejected",
                            ReferenceId = post.Id,
                            ReferenceType = "rental_post",
                            CreatedAt = DateTime.UtcNow,
                            UpdatedAt = DateTime.UtcNow
                        });
                    }
                }
                else
                {
                    return BadRequest(new { message = "Hành động không hợp lệ (chỉ chấp nhận 'approve' hoặc 'reject')." });
                }

                post.UpdatedAt = DateTime.UtcNow;
                await _context.SaveChangesAsync();

                return Ok(new { message = "Cập nhật trạng thái kiểm duyệt thành công!", status = post.Status });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi xử lý kiểm duyệt", error = ex.Message });
            }
        }
    }
}