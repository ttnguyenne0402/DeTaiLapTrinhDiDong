namespace Backend.DT0s
{
    public class PropertyDto
    {
        public string Id { get; set; } = string.Empty;
        public string Name { get; set; } = string.Empty;
        public string Address { get; set; } = string.Empty;
        public int TotalRooms { get; set; }
        public int RentedRooms { get; set; }
        public int EmptyRooms { get; set; }
        public string Status { get; set; } = string.Empty;
        public string Image { get; set; } = string.Empty;
    }

    public class CreatePropertyDto
    {
        public string OwnerId { get; set; } = string.Empty;
        public string Name { get; set; } = string.Empty;
        public string Type { get; set; } = "rooming_house"; // rooming_house, apartment, house
        public string Address { get; set; } = string.Empty;
        public string District { get; set; } = string.Empty;
        public string Ward { get; set; } = string.Empty;
        public int TotalRooms { get; set; }
        public string Status { get; set; } = "active";
        public string Description { get; set; } = string.Empty;
        public string Image { get; set; } = string.Empty;
    }
}