namespace Backend.DTOs
{
    public class ContractListItemDto
    {
        public string Id { get; set; } = null!;
        public string Code { get; set; } = null!;

        public string? RoomId { get; set; }
        public string? ViewingAppointmentId { get; set; }
        public string Room { get; set; } = null!;
        public string Address { get; set; } = null!;
        public string Status { get; set; } = null!; // "Đang hiệu lực", "Sắp hết hạn", "Chờ ký", "Bản nháp", "Đã thanh lý"
        public string TimeText { get; set; } = null!;
        public string TenantName { get; set; } = null!;
        public string TenantPhone { get; set; } = null!;
        public string RentPrice { get; set; } = null!;
        public string DepositPrice { get; set; } = null!;
        public string Duration { get; set; } = null!;
        public string CycleText { get; set; } = null!;
        public string NoteText { get; set; } = null!;
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
    }

    public class ContractSummaryDto
    {
        public int ActiveCount { get; set; }
        public decimal ExpectedRevenue { get; set; }
        public List<ContractListItemDto> Contracts { get; set; } = new();
    }

    public class ContractServiceItemDto
    {
        public string? ServiceId { get; set; }
        public string? Name { get; set; }
        public string? Unit { get; set; }
        public decimal Price { get; set; }
    }

    public class CreateContractRequest
    {
        public string? ViewingAppointmentId { get; set; }
        public string? RoomId { get; set; }
        public string? TenantName { get; set; }
        public string? TenantPhone { get; set; }
        public string? Cccd { get; set; }
        public string? IssueDate { get; set; }
        public string? IssuePlace { get; set; }
        public string? StartDate { get; set; }
        public string? EndDate { get; set; }
        public decimal RentPrice { get; set; }
        public decimal DepositPrice { get; set; }
        public int ElectricIndex { get; set; }
        public int WaterIndex { get; set; }
        public string Status { get; set; } = "draft"; // "draft" hoặc "pending"

        // Bổ sung để nhận danh sách dịch vụ gửi từ Flutter
        public List<ContractServiceItemDto>? Services { get; set; } = new();

        // Nhận danh sách thành viên ở cùng
        public List<ContractMemberItemDto>? Members { get; set; } = new();
    }

    public class SignContractRequest
    {
        public string OwnerSignature { get; set; } = null!;
        public string TenantSignature { get; set; } = null!;
    }

    public class AvailableRoomDto
    {
        public string RoomId { get; set; } = null!;
        public string RoomName { get; set; } = null!;
        public string PropertyName { get; set; } = null!;
        public decimal Price { get; set; }
        public decimal Deposit { get; set; }
        public double Area { get; set; }
        public int? Floor { get; set; }
        public string DisplayText => $"{RoomName} - {PropertyName} ({Price:N0}đ/th)";
    }

    public class AppointmentOptionDto
    {
        public string Id { get; set; } = null!;
        public string TenantName { get; set; } = null!;
        public string TenantPhone { get; set; } = null!;
        public string RoomId { get; set; } = null!;
        public string RoomName { get; set; } = null!;
        public string DisplayText => $"#{Id[..Math.Min(8, Id.Length)]} - {TenantName} ({TenantPhone}) - {RoomName}";
    }


    public class ContractMemberItemDto
    {
        public string FullName { get; set; } = null!;
        public string? Phone { get; set; }
        public string? Cccd { get; set; }
        public string? Relationship { get; set; }
    }
}