namespace Backend.DT0s
{
    public class ServiceDto
    {
        public string Id { get; set; } = string.Empty;
        public string? OwnerId { get; set; }
        public string Name { get; set; } = string.Empty;
        public decimal Price { get; set; }
        public string PriceFormatted { get; set; } = string.Empty; // "3.500"
        public string Unit { get; set; } = string.Empty; // kWh, người/tháng, phòng/tháng, v.v.
        public bool IsMandatory { get; set; }
        public bool Status { get; set; } // true: đang kích hoạt, false: tạm ngừng
        public string StatusCode { get; set; } = "active";
        public string Description { get; set; } = string.Empty;
        public string Icon { get; set; } = "bolt"; // bolt, water_drop, wifi, cleaning_services, elevator, two_wheeler, security, local_laundry_service
    }

    public class CreateServiceDto
    {
        public string? OwnerId { get; set; }
        public string? PropertyId { get; set; }
        public string Name { get; set; } = string.Empty;
        public decimal Price { get; set; }
        public string Unit { get; set; } = "kWh";
        public bool IsMandatory { get; set; }
        public string? Description { get; set; }
        public string? Icon { get; set; } = "bolt";
        public bool Status { get; set; } = true;
    }

    public class UpdateServiceDto
    {
        public string Name { get; set; } = string.Empty;
        public decimal Price { get; set; }
        public string Unit { get; set; } = "kWh";
        public bool IsMandatory { get; set; }
        public string? Description { get; set; }
        public string? Icon { get; set; }
        public bool Status { get; set; } = true;
    }
}

