namespace Backend.DT0s
{
    public class OwnerAppointmentDto
    {
        public string Id { get; set; } = string.Empty;
        public string TenantId { get; set; } = string.Empty;
        public string Name { get; set; } = string.Empty; // Tên khách thuê
        public string Phone { get; set; } = string.Empty;
        public string RoomId { get; set; } = string.Empty;
        public string RoomName { get; set; } = string.Empty;
        public string PropertyId { get; set; } = string.Empty;
        public string PropertyName { get; set; } = string.Empty;
        public string PropertyAddress { get; set; } = string.Empty;
        public decimal RoomPrice { get; set; }
        public decimal RoomDeposit { get; set; }
        public decimal RoomArea { get; set; }
        public string RoomInfo { get; set; } = string.Empty; // "Phòng 202 - Chung cư Mini Q7"
        public string Time { get; set; } = string.Empty; // "10:00 - Hôm nay" hoặc "10:00, 09/10/2026"
        public string RawTime { get; set; } = string.Empty; // "10:00"
        public string Date { get; set; } = string.Empty; // "09/10/2026"
        public string Status { get; set; } = string.Empty; // pending, confirmed, rescheduled, rejected, completed, cancelled
        public string? Note { get; set; } // Ghi chú của khách hoặc chủ nhà
        public string? OwnerNote { get; set; }
        public string Avatar { get; set; } = "frontend/assets/images/avatarDemo.jpg";
    }

    public class UpdateAppointmentStatusDto
    {
        public string Status { get; set; } = string.Empty; // confirmed, completed, cancelled, rejected, rescheduled
        public string? OwnerNote { get; set; }
        public string? NewDate { get; set; } // yyyy-MM-dd hoặc dd/MM/yyyy
        public string? NewTime { get; set; } // HH:mm
    }
}

