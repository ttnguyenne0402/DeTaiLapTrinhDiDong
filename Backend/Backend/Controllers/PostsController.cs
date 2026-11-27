using Backend.DT0s;
using Backend.Helpers;
using Backend.Models;
using Backend.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using System.Text.Json;

namespace Backend.Controllers
{
    [Route("api/owner/posts")]
    [ApiController]
    public class PostsController : ControllerBase
    {
        private readonly QuanLyPhongTroContext _context;
        private readonly PostImageStorage _imageStorage;
        private static readonly JsonSerializerOptions FormJsonOptions = new(JsonSerializerDefaults.Web);

        public PostsController(QuanLyPhongTroContext context, PostImageStorage imageStorage)
        {
            _context = context;
            _imageStorage = imageStorage;
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
                    var firstImg = p.RentalPostImages?.OrderByDescending(i => i.IsThumbnail)
                                       .ThenBy(i => i.SortOrder).ThenBy(i => i.Id).FirstOrDefault()?.ImagePath
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
                        Views = p.Views,
                        Likes = likes,
                        Date = (p.CreatedAt ?? DateTime.Now).ToString("dd/MM/yyyy"),
                        Status = normalizedStatus,
                        SubmitNote = !string.IsNullOrEmpty(p.SubmitNote) ? p.SubmitNote : (normalizedStatus == "pending" ? "Đang chờ Quản trị viên thẩm định tiêu chuẩn & PCCC" : null),
                        RejectReason = p.RejectionReason,
                        Image = firstImg,
                        Images = p.RentalPostImages?.OrderByDescending(i => i.IsThumbnail)
                            .ThenBy(i => i.SortOrder).ThenBy(i => i.Id).Select(i => i.ImagePath).ToList() ?? new List<string>()
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
        public async Task<IActionResult> GetPostDetail(string id, [FromQuery] string? viewerRole)
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

                // 1. Chỉ tăng lượt xem nếu là khách hàng (viewerRole == "customer" hoặc "tenant")
                // Khi chủ trọ xem bài đăng của mình thì không tự tăng lượt xem
                if (!string.IsNullOrEmpty(viewerRole) &&
                    (viewerRole.Equals("customer", StringComparison.OrdinalIgnoreCase) ||
                     viewerRole.Equals("tenant", StringComparison.OrdinalIgnoreCase)))
                {
                    p.Views += 1;
                    try
                    {
                        await _context.SaveChangesAsync();
                    }
                    catch
                    {
                        // Tránh chặn luồng xem bài nếu có tranh chấp ghi dữ liệu
                    }
                }

                // 2. Đếm số lượng yêu thích (thả tim) thực tế từ bảng Favorites
                int likesCount = 0;
                if (!string.IsNullOrEmpty(p.RoomId))
                {
                    likesCount = await _context.Favorites.CountAsync(f => f.RoomId == p.RoomId);
                }

                var firstImg = p.RentalPostImages?.OrderByDescending(i => i.IsThumbnail)
                               .ThenBy(i => i.SortOrder).ThenBy(i => i.Id).FirstOrDefault()?.ImagePath
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
                    Views = p.Views,
                    Likes = likesCount,
                    Date = (p.CreatedAt ?? DateTime.Now).ToString("dd/MM/yyyy"),
                    Status = normalizedStatus,
                    SubmitNote = !string.IsNullOrEmpty(p.SubmitNote) ? p.SubmitNote : (normalizedStatus == "pending" ? "Đang chờ Quản trị viên thẩm định tiêu chuẩn & PCCC" : null),
                    RejectReason = p.RejectionReason,
                    Image = firstImg,
                    Images = p.RentalPostImages?.OrderByDescending(i => i.IsThumbnail)
                        .ThenBy(i => i.SortOrder).ThenBy(i => i.Id).Select(i => i.ImagePath).ToList() ?? new List<string>()
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
        public Task<IActionResult> CreatePost([FromBody] CreatePostDto dto) => CreatePostAsync(dto, null);

        [HttpPost("with-images")]
        [Authorize(Roles = "owner,landlord")]
        [Consumes("multipart/form-data")]
        [RequestSizeLimit(PostImageStorage.MaxRequestBytes)]
        public Task<IActionResult> CreatePostWithImages([FromForm] PostUploadForm form, CancellationToken cancellationToken) =>
            SaveFormAsync<CreatePostDto>(form, CreatePostAsync, cancellationToken);

        private async Task<IActionResult> CreatePostAsync(CreatePostDto dto, string? ownerId)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(dto.RoomId) || string.IsNullOrWhiteSpace(dto.Title))
                {
                    return BadRequest(new { message = "Mã phòng và tiêu đề không được để trống." });
                }

                var room = await _context.Rooms
                    .Include(r => r.Property)
                    .FirstOrDefaultAsync(r => r.Id == dto.RoomId || r.Id.ToLower() == dto.RoomId.ToLower());
                if (room == null && ownerId == null)
                {
                    room = await _context.Rooms
                        .Include(r => r.Property)
                        .FirstOrDefaultAsync(r => r.Name.Contains(dto.RoomId));
                }

                if (room == null)
                {
                    return BadRequest(new { message = "Không tìm thấy phòng phù hợp để tạo tin đăng." });
                }

                // Kiểm tra trạng thái bất động sản: Nếu đang bảo trì thì KHÔNG cho đăng tin
                if (room.Property != null && (room.Property.Status == "inactive" || room.Property.Status.ToLower() == "maintenance"))
                {
                    return BadRequest(new { message = $"Bất động sản '{room.Property.Name}' đang trong trạng thái bảo trì, không thể tạo tin đăng." });
                }

                if (ownerId != null && !OwnsRoom(room, ownerId)) return Forbid();
                if (!ValidImageReferences(dto.Images))
                    return BadRequest(new { message = "Ảnh tin đăng chưa tải lên hoặc vượt quá 6 ảnh." });

                string validRoomId = room.Id;

                string status = string.IsNullOrEmpty(dto.Status) ? "pending" : dto.Status.ToLower();
                if (status == "active") status = "published"; // database.sql check constraint
                if (ownerId != null) status = "pending";

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

                if (dto.Images != null) ReplaceImages(post, dto.Images);

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
        public Task<IActionResult> UpdatePost(string id, [FromBody] UpdatePostDto dto) => UpdatePostAsync(id, dto, null);

        [HttpPut("{id}/with-images")]
        [Authorize(Roles = "owner,landlord")]
        [Consumes("multipart/form-data")]
        [RequestSizeLimit(PostImageStorage.MaxRequestBytes)]
        public Task<IActionResult> UpdatePostWithImages(string id, [FromForm] PostUploadForm form, CancellationToken cancellationToken) =>
            SaveFormAsync<UpdatePostDto>(form, (dto, ownerId) => UpdatePostAsync(id, dto, ownerId), cancellationToken);

        private async Task<IActionResult> UpdatePostAsync(string id, UpdatePostDto dto, string? ownerId)
        {
            try
            {
                var post = await _context.RentalPosts
                    .Include(p => p.Room)
                        .ThenInclude(r => r.Property)
                    .Include(p => p.RentalPostImages)
                    .FirstOrDefaultAsync(p => p.Id == id || p.Id.ToLower() == id.ToLower());

                if (post == null)
                {
                    return NotFound(new { message = "Không tìm thấy bài đăng cần cập nhật." });
                }

                if (ownerId != null)
                {
                    if (!OwnsRoom(post.Room, ownerId)) return Forbid();
                    if (!string.IsNullOrWhiteSpace(dto.RoomId) && dto.RoomId != post.RoomId)
                    {
                        var room = await _context.Rooms.Include(r => r.Property).FirstOrDefaultAsync(r => r.Id == dto.RoomId);
                        if (room == null) return NotFound(new { message = "Không tìm thấy phòng." });
                        if (!OwnsRoom(room, ownerId)) return Forbid();
                    }
                }

                // Kiểm tra nếu bất động sản đang bảo trì thì không cho xuất bản tin
                var targetRoomId = !string.IsNullOrWhiteSpace(dto.RoomId) ? dto.RoomId : post.RoomId;
                var targetRoom = await _context.Rooms.Include(r => r.Property).FirstOrDefaultAsync(r => r.Id == targetRoomId);
                if (targetRoom?.Property != null && (targetRoom.Property.Status == "inactive" || targetRoom.Property.Status.ToLower() == "maintenance"))
                {
                    string targetStatus = (dto.Status ?? post.Status).ToLower();
                    if (targetStatus == "published" || targetStatus == "active")
                    {
                        return BadRequest(new { message = $"Bất động sản '{targetRoom.Property.Name}' đang bảo trì, không thể xuất bản tin đăng." });
                    }
                }

                if (!ValidImageReferences(dto.Images))
                    return BadRequest(new { message = "Ảnh tin đăng chưa tải lên hoặc vượt quá 6 ảnh." });

                var imagesChanged = dto.Images != null && !post.RentalPostImages
                    .OrderByDescending(i => i.IsThumbnail).ThenBy(i => i.SortOrder).ThenBy(i => i.Id)
                    .Select(i => i.ImagePath).SequenceEqual(dto.Images);

                if (!string.IsNullOrWhiteSpace(dto.RoomId)) post.RoomId = dto.RoomId;
                if (!string.IsNullOrWhiteSpace(dto.Title)) post.Title = dto.Title;
                if (dto.Description != null) post.Description = dto.Description;
                if (dto.Price.HasValue && dto.Price.Value > 0) post.Price = dto.Price.Value;
                if (dto.Amenities != null) post.Amenities = string.Join(",", dto.Amenities);
                if (!string.IsNullOrWhiteSpace(dto.SubmitNote)) post.SubmitNote = dto.SubmitNote;

                if (ownerId != null)
                {
                    if (dto.Status == "pending" || (post.Status == "published" && imagesChanged))
                        post.Status = "pending";
                }
                else if (!string.IsNullOrWhiteSpace(dto.Status))
                {
                    string s = dto.Status.ToLower();
                    post.Status = s == "active" ? "published" : s;
                }

                if (imagesChanged) ReplaceImages(post, dto.Images!);
                post.UpdatedAt = DateTime.Now;

                await _context.SaveChangesAsync();
                return Ok(new { message = "Cập nhật bài đăng thành công" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi khi cập nhật bài đăng", error = ex.Message });
            }
        }

        private static bool OwnsRoom(Room room, string ownerId) =>
            OwnerHelper.ResolveOwnerIds(ownerId).Contains(room.Property?.OwnerId, StringComparer.OrdinalIgnoreCase);

        private static bool ValidImageReferences(List<string>? images) =>
            images == null || (images.Count <= PostImageStorage.MaxImages && images.All(PostImageStorage.IsSharedReference));

        private void ReplaceImages(RentalPost post, List<string> images)
        {
            _context.RentalPostImages.RemoveRange(post.RentalPostImages.ToArray());
            for (var index = 0; index < images.Count; index++)
            {
                _context.RentalPostImages.Add(new RentalPostImage
                {
                    Id = "IMG_" + Guid.NewGuid().ToString("N"),
                    RentalPostId = post.Id,
                    ImagePath = images[index],
                    IsThumbnail = index == 0,
                    SortOrder = index,
                    CreatedAt = DateTime.UtcNow
                });
            }
        }

        private async Task<IActionResult> SaveFormAsync<T>(
            PostUploadForm form,
            Func<T, string, Task<IActionResult>> save,
            CancellationToken cancellationToken) where T : class, IPostImageRequest
        {
            var ownerId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(ownerId)) return Unauthorized();

            var stored = new List<string>();
            var saved = false;
            try
            {
                var post = JsonSerializer.Deserialize<T>(form.Post, FormJsonOptions);
                if (post?.Images == null || post.Images.Count > PostImageStorage.MaxImages ||
                    form.Files.Count > PostImageStorage.MaxImages)
                    return BadRequest(new { message = "Mỗi tin đăng có thể chứa tối đa 6 ảnh." });

                var filesUsed = new HashSet<int>();
                foreach (var (reference, position) in post.Images.Select((reference, position) => (reference, position)).ToArray())
                {
                    if (reference?.StartsWith("upload:", StringComparison.Ordinal) != true) continue;
                    if (!int.TryParse(reference.AsSpan(7), out var index) || index < 0 ||
                        index >= form.Files.Count || !filesUsed.Add(index))
                        return BadRequest(new { message = "Danh sách ảnh tải lên không hợp lệ." });

                    var path = await _imageStorage.SaveAsync(form.Files[index], cancellationToken);
                    stored.Add(path);
                    post.Images[position] = path;
                }
                if (filesUsed.Count != form.Files.Count)
                    return BadRequest(new { message = "Danh sách ảnh tải lên không đầy đủ." });

                var result = await save(post, ownerId);
                saved = result is OkObjectResult;
                return result;
            }
            catch (JsonException)
            {
                return BadRequest(new { message = "Dữ liệu tin đăng không hợp lệ." });
            }
            catch (InvalidDataException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
            finally
            {
                if (!saved)
                    foreach (var path in stored) _imageStorage.DeleteNewImage(path);
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
