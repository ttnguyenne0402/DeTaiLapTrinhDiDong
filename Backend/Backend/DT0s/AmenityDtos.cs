using System.Collections.Generic;

namespace Backend.DT0s
{
    public class AmenityDto
    {
        public string Id { get; set; } = null!;
        public string? OwnerId { get; set; }
        public string Name { get; set; } = null!;
        public string? Description { get; set; }
        public string Icon { get; set; } = "check_circle";
        public bool Status { get; set; } = true;
        public string StatusCode { get; set; } = "active";
        public bool IsAssigned { get; set; } = false;
        public string? PropertyId { get; set; }
    }

    public class CreateAmenityDto
    {
        public string? OwnerId { get; set; }
        public string Name { get; set; } = null!;
        public string? Description { get; set; }
        public string? Icon { get; set; }
        public bool Status { get; set; } = true;
        public string? PropertyId { get; set; }
    }

    public class UpdateAmenityDto
    {
        public string? Name { get; set; }
        public string? Description { get; set; }
        public string? Icon { get; set; }
        public bool Status { get; set; } = true;
    }

    public class AssignPropertyAmenitiesDto
    {
        public string PropertyId { get; set; } = null!;
        public List<string> AmenityIds { get; set; } = new();
    }
}
