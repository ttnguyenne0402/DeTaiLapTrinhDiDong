namespace Backend.DTOs
{
    // DTO cho danh sách tin đăng ở màn hình review
    public class AdminPostListItemDto
    {
        public string Id { get; set; } = null!;
        public string Title { get; set; } = null!;
        public decimal Price { get; set; }
        public string Address { get; set; } = null!;
        public string OwnerName { get; set; } = null!;
        public string Status { get; set; } = null!; // "pending", "published", "rejected"
        public string? Thumbnail { get; set; }
        public DateTime? CreatedAt { get; set; }
    }

    // DTO cho màn hình chi tiết thẩm định RoomApprovalDetailScreen
    public class AdminPostDetailDto
    {
        public string Id { get; set; } = null!;
        public string RoomId { get; set; } = null!;
        public string Title { get; set; } = null!;
        public string Description { get; set; } = null!;
        public string Status { get; set; } = null!;
        public string? RejectionReason { get; set; }
        public DateTime? CreatedAt { get; set; }

        // Thông tin người đăng (Owner)
        public string OwnerName { get; set; } = null!;
        public string? OwnerPhone { get; set; }

        // Thông tin phòng & bất động sản
        public string PropertyName { get; set; } = null!;
        public string Address { get; set; } = null!;
        public decimal Price { get; set; }
        public decimal Deposit { get; set; }
        public decimal Area { get; set; }
        public int MaxPeople { get; set; }
        public int? Floor { get; set; }

        // Danh sách ảnh & danh mục tiện nghi
        public List<string> Images { get; set; } = new();
        public List<string> Amenities { get; set; } = new();
    }

    // DTO nhận dữ liệu gửi lên khi Duyệt / Từ chối
    public class ModeratePostRequest
    {
        public string Action { get; set; } = null!; // "approve" hoặc "reject"
        public string? RejectionReason { get; set; }
    }
}