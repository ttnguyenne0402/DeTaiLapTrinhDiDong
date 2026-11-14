using System.ComponentModel.DataAnnotations;

namespace Backend.DTOs
{
    public class PaymentRequestDTO
    {
        [Required]
        public string InvoiceId { get; set; } = null!;

        [Required]
        public string PayerId { get; set; } = null!; 

        [Required]
        public decimal Amount { get; set; }

        [Required]
        public string Method { get; set; } = null!; 
    }
}