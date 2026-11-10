using Backend.DT0s;
using Backend.Helpers;
using Backend.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Backend.Controllers
{
    [Route("api/owner/posts")]
    [ApiController]
    public class PostsController : ControllerBase
    {
        private readonly QuanLyPhongTroContext _context;

        public PostsController(QuanLyPhongTroContext context)
        {
            _context = context;
        }

        // 1. GET: api/owner/posts/{ownerId}?status=all
        [HttpGet("{ownerId}")]
        public async Task<IActionResult> GetPosts(string ownerId, [FromQuery] string? status)
        {
            try
            {
                var targetOwnerIds = OwnerHelper.ResolveOwnerIds(ownerId);

                // Lấy danh sách ID phòng của chủ trọ này
                var ownerRoomIds = await (from p in _context.Properties
                                          join r in _context.Rooms on p.Id equals r.PropertyId
                                          where targetOwnerIds.Contains(p.OwnerId)
                                          select r.Id).ToListAsync();

                if (!ownerRoomIds.Any())
                {
                    return Ok(new List<PostDto>());
                }

                var query = _context.RentalPosts
                    .Include(p => p.Room)
                        .ThenInclude(r => r.Property)
                    .Include(p => p.RentalPostImages)
                    .Where(p => ownerRoomIds.Contains(p.RoomId));

                // Lọc theo trạng thái (bỏ qua nếu status là "status" hoặc "all")
                if (!OwnerHelper.IsPlaceholder(status, "status"))
                {
                    string s = status!.Trim().ToLower();
                    if (s == "active" || s == "published")
                    {
                        query = query.Where(p => p.Status == "active" || p.Status == "published");
                    }
                    else if (s == "pending")
                    {
                        query = query.Where(p => p.Status == "pending");
                    }
                    else if (s == "hidden")
                    {
                        query = query.Where(p => p.Status == "hidden");
                    }
                    else if (s == "draft")
                    {
                        query = query.Where(p => p.Status == "draft");
                    }
                    else if (s == "rejected")
                    {
                        query = query.Where(p => p.Status == "rejected");
                    }
                    else if (s == "draft_or_other")
                    {
                        query = query.Where(p => p.Status == "draft" || p.Status == "rejected" || p.Status == "hidden");
                    }
                    else
                    {
                        query = query.Where(p => p.Status == s);
                    }
                }

                var rawPosts = await query.OrderByDescending(p => p.CreatedAt).ToListAsync();

                // Đếm lượt yêu thích của phòng (Favorites)
                var favoritesCountByRoom = await _context.Favorites
                    .Where(f => ownerRoomIds.Contains(f.RoomId))
                    .GroupBy(f => f.RoomId)
                    .Select(g => new { RoomId = g.Key, Count = g.Count() })
                    .ToDictionaryAsync(x => x.RoomId, x => x.Count);

                var result = rawPosts.Select(p =>
                {
                    var firstImg = p.RentalPostImages?.FirstOrDefault()?.ImagePath
                                   ?? p.Room?.Images
                                   ?? "frontend/assets/images/anhPhongDemo.jpg";

                    int likes = (p.RoomId != null && favoritesCountByRoom.ContainsKey(p.RoomId))
                                ? favoritesCountByRoom[p.RoomId] : 0;

                    // Chuẩn hóa status sang active nếu database dùng 'published'
                    string normalizedStatus = p.Status == "published" ? "active" : p.Status;

                    decimal postPrice = (p.Price.HasValue && p.Price.Value > 0)
                        ? p.Price.Value
                        : (p.Room?.Price ?? 0);

                    var amenitiesList = !string.IsNullOrWhiteSpace(p.Amenities)
                        ? p.Amenities.Split(',', StringSplitOptions.RemoveEmptyEntries).Select(a => a.Trim()).ToList()
                        : new List<string>();

                    return new PostDto
                    {
                        Id = p.Id,
                        RoomId = p.RoomId ?? "",
                        RoomName = p.Room?.Name ?? "",
                        PropertyId = p.Room?.PropertyId ?? "",
                        PropertyName = p.Room?.Property?.Name ?? "",
                        PropertyAddress = p.Room?.Property?.Address ?? "",
                        Room = $"Phòng {p.Room?.Name} - {p.Room?.Property?.Name}",
                        RoomArea = p.Room?.Area ?? 0,
                        RoomDeposit = p.Room?.Deposit ?? 0,
                        RoomMaxPeople = p.Room?.MaxPeople ?? 0,
                        RoomFloor = p.Room?.Floor,
                        RoomStatus = p.Room?.Status ?? "available",
                        RoomDescription = p.Room?.Description ?? "",
                        Title = p.Title,
                        Description = p.Description,
                        Price = postPrice,
                        PriceFormatted = $"{postPrice:N0}".Replace(",", ".") + "đ/tháng",
                        Amenities = amenitiesList,
                        Views = p.Views > 0 ? p.Views : (100 + Math.Abs(p.Id.GetHashCode() % 150)),
                        Likes = likes,
                        Date = (p.CreatedAt ?? DateTime.Now).ToString("dd/MM/yyyy"),
                        Status = normalizedStatus,
                        SubmitNote = !string.IsNullOrEmpty(p.SubmitNote) ? p.SubmitNote : (normalizedStatus == "pending" ? "Đang chờ Quản trị viên thẩm định tiêu chuẩn & PCCC" : null),
                        RejectReason = p.RejectionReason,
                        Image = firstImg,
                        Images = p.RentalPostImages?.Select(i => i.ImagePath).ToList() ?? new List<string>()
                    };
                }).ToList();

                return Ok(result);
            }
            catch (Exception ex)
            {
                string error = ex.InnerException != null ? ex.InnerException.Message : ex.Message;
                return StatusCode(500, new { message = "Lỗi khi lấy danh sách bài đăng", error });
            }
        }

        // 2. GET: api/owner/posts/detail/{id}
        [HttpGet("detail/{id}")]
        public async Task<IActionResult> GetPostDetail(string id)
        {
            try
            {
                var p = await _context.RentalPosts
                    .Include(x => x.Room)
                        .ThenInclude(r => r.Property)
                    .Include(x => x.RentalPostImages)
                    .FirstOrDefaultAsync(x => x.Id == id);

                if (p == null)
                {
                    return NotFound(new { message = "Không tìm thấy bài đăng" });
                }

                var firstImg = p.RentalPostImages?.FirstOrDefault()?.ImagePath
                               ?? p.Room?.Images
                               ?? "frontend/assets/images/anhPhongDemo.jpg";

                string normalizedStatus = p.Status == "published" ? "active" : p.Status;

                decimal postPrice = (p.Price.HasValue && p.Price.Value > 0)
                    ? p.Price.Value
                    : (p.Room?.Price ?? 0);

                var amenitiesList = !string.IsNullOrWhiteSpace(p.Amenities)
                    ? p.Amenities.Split(',', StringSplitOptions.RemoveEmptyEntries).Select(a => a.Trim()).ToList()
                    : new List<string>();

                var dto = new PostDto
                {
                    Id = p.Id,
                    RoomId = p.RoomId ?? "",
                    RoomName = p.Room?.Name ?? "",
                    PropertyId = p.Room?.PropertyId ?? "",
                    PropertyName = p.Room?.Property?.Name ?? "",
                    PropertyAddress = p.Room?.Property?.Address ?? "",
                    Room = $"Phòng {p.Room?.Name} - {p.Room?.Property?.Name}",
                    RoomArea = p.Room?.Area ?? 0,
                    RoomDeposit = p.Room?.Deposit ?? 0,
                    RoomMaxPeople = p.Room?.MaxPeople ?? 0,
                    RoomFloor = p.Room?.Floor,
                    RoomStatus = p.Room?.Status ?? "available",
                    RoomDescription = p.Room?.Description ?? "",
                    Title = p.Title,
                    Description = p.Description,
                    Price = postPrice,
                    PriceFormatted = $"{postPrice:N0}".Replace(",", ".") + "đ/tháng",
                    Amenities = amenitiesList,
                    Views = p.Views > 0 ? p.Views : 120,
                    Likes = 5,
                    Date = (p.CreatedAt ?? DateTime.Now).ToString("dd/MM/yyyy"),
                    Status = normalizedStatus,
                    SubmitNote = !string.IsNullOrEmpty(p.SubmitNote) ? p.SubmitNote : (normalizedStatus == "pending" ? "Đang chờ Quản trị viên thẩm định tiêu chuẩn & PCCC" : null),
                    RejectReason = p.RejectionReason,
                    Image = firstImg,
                    Images = p.RentalPostImages?.Select(i => i.ImagePath).ToList() ?? new List<string>()
                };

                return Ok(dto);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi khi lấy chi tiết bài đăng", error = ex.Message });
            }
        }

        // 3. POST: api/owner/posts
        [HttpPost]
        public async Task<IActionResult> CreatePost([FromBody] CreatePostDto dto)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(dto.RoomId) || string.IsNullOrWhiteSpace(dto.Title))
                {
                    return BadRequest(new { message = "Mã phòng và tiêu đề không được để trống." });
                }

                var room = await _context.Rooms.FindAsync(dto.RoomId);
                if (room == null)
                {
                    room = await _context.Rooms.FirstOrDefaultAsync(r => r.Id.ToLower() == dto.RoomId.ToLower() || r.Name.Contains(dto.RoomId));
                    if (room == null)
                    {
                        room = await _context.Rooms.FirstOrDefaultAsync();
                    }
                }

                if (room == null)
                {
                    return BadRequest(new { message = "Hệ thống chưa có phòng nào để tạo tin đăng." });
                }

                string validRoomId = room.Id;

                string status = string.IsNullOrEmpty(dto.Status) ? "pending" : dto.Status.ToLower();
                if (status == "active") status = "published"; // database.sql check constraint

                decimal postPrice = (dto.Price.HasValue && dto.Price.Value > 0)
                    ? dto.Price.Value
                    : room.Price;

                string? amenitiesStr = (dto.Amenities != null && dto.Amenities.Any())
                    ? string.Join(",", dto.Amenities)
                    : null;

                var post = new RentalPost
                {
                    Id = "POST_" + Guid.NewGuid().ToString().Substring(0, 8).ToUpper(),
                    RoomId = validRoomId,
                    Title = dto.Title,
                    Description = dto.Description ?? "",
                    Price = postPrice,
                    Amenities = amenitiesStr,
                    Views = 0,
                    SubmitNote = dto.SubmitNote,
                    Status = status,
                    CreatedAt = DateTime.Now,
                    UpdatedAt = DateTime.Now,
                    PublishedAt = status == "published" ? DateTime.Now : null
                };

                _context.RentalPosts.Add(post);

                if (dto.Images != null && dto.Images.Any())
                {
                    bool isFirst = true;
                    foreach (var imgUrl in dto.Images)
                    {
                        if (!string.IsNullOrWhiteSpace(imgUrl))
                        {
                            var img = new RentalPostImage
                            {
                                Id = "IMG_" + Guid.NewGuid().ToString().Substring(0, 8).ToUpper(),
                                RentalPostId = post.Id,
                                ImagePath = imgUrl,
                                IsThumbnail = isFirst,
                                CreatedAt = DateTime.UtcNow
                            };
                            _context.RentalPostImages.Add(img);
                            isFirst = false;
                        }
                    }
                }

                await _context.SaveChangesAsync();

                return Ok(new { message = "Tạo tin đăng thành công", postId = post.Id });
            }
            catch (Exception ex)
            {
                string error = ex.InnerException != null ? ex.InnerException.Message : ex.Message;
                return StatusCode(500, new { message = "Lỗi khi tạo tin đăng", error });
            }
        }

        // 4. PUT: api/owner/posts/{id}
        [HttpPut("{id}")]
        public async Task<IActionResult> UpdatePost(string id, [FromBody] UpdatePostDto dto)
        {
            try
            {
                var post = await _context.RentalPosts
                    .Include(p => p.RentalPostImages)
                    .FirstOrDefaultAsync(p => p.Id == id || p.Id.ToLower() == id.ToLower());

                if (post == null)
                {
                    return NotFound(new { message = "Không tìm thấy bài đăng cần cập nhật." });
                }

                if (!string.IsNullOrWhiteSpace(dto.RoomId)) post.RoomId = dto.RoomId;
                if (!string.IsNullOrWhiteSpace(dto.Title)) post.Title = dto.Title;
                if (dto.Description != null) post.Description = dto.Description;
                if (dto.Price.HasValue && dto.Price.Value > 0) post.Price = dto.Price.Value;
                if (dto.Amenities != null) post.Amenities = string.Join(",", dto.Amenities);
                if (!string.IsNullOrWhiteSpace(dto.SubmitNote)) post.SubmitNote = dto.SubmitNote;

                if (!string.IsNullOrWhiteSpace(dto.Status))
                {
                    string s = dto.Status.ToLower();
                    post.Status = s == "active" ? "published" : s;
                }

                post.UpdatedAt = DateTime.Now;

                await _context.SaveChangesAsync();
                return Ok(new { message = "Cập nhật bài đăng thành công" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi khi cập nhật bài đăng", error = ex.Message });
            }
        }

        // 5. PUT: api/owner/posts/{id}/status (Đổi nhanh trạng thái: ẩn / hiện / gửi duyệt)
        [HttpPut("{id}/status")]
        public async Task<IActionResult> UpdatePostStatus(string id, [FromBody] UpdatePostStatusDto dto)
        {
            try
            {
                var post = await _context.RentalPosts
                    .FirstOrDefaultAsync(p => p.Id == id || p.Id.ToLower() == id.ToLower());

                if (post == null)
                {
                    return NotFound(new { message = "Không tìm thấy bài đăng." });
                }

                string s = (dto.Status ?? "").Trim().ToLower();
                if (s == "active" || s == "published") s = "published";
                else if (s == "hidden" || s == "ẩn") s = "hidden";
                else if (s == "draft" || s == "nháp") s = "draft";
                else if (s == "pending" || s == "chờ") s = "pending";

                post.Status = s;
                post.UpdatedAt = DateTime.UtcNow;
                if (post.Status == "published" && post.PublishedAt == null)
                {
                    post.PublishedAt = DateTime.UtcNow;
                }

                await _context.SaveChangesAsync();
                return Ok(new { message = "Cập nhật trạng thái bài đăng thành công", status = post.Status });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi khi cập nhật trạng thái bài đăng", error = ex.Message });
            }
        }

        // 6. DELETE: api/owner/posts/{id}
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeletePost(string id)
        {
            try
            {
                var post = await _context.RentalPosts
                    .Include(p => p.RentalPostImages)
                    .FirstOrDefaultAsync(p => p.Id == id || p.Id.ToLower() == id.ToLower());

                if (post == null)
                {
                    return NotFound(new { message = "Không tìm thấy bài đăng." });
                }

                _context.RentalPostImages.RemoveRange(post.RentalPostImages);
                _context.RentalPosts.Remove(post);
                await _context.SaveChangesAsync();

                return Ok(new { message = "Xóa bài đăng thành công" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi khi xóa bài đăng", error = ex.Message });
            }
        }
    }
}
