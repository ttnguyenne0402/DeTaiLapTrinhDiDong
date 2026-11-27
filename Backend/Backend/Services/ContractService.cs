using Backend.DTOs;
using Backend.Models;
using Backend.Repositories;
using Microsoft.EntityFrameworkCore;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace Backend.Services
{
    public class ContractService : IContractService
    {
        private readonly IContractRepository _repository;
        private readonly QuanLyPhongTroContext _context;

        public ContractService(IContractRepository repository, QuanLyPhongTroContext context)
        {
            _repository = repository;
            _context = context;
        }

        public async Task<IEnumerable<ContractResponseDTO>> GetTenantContractsAsync(string tenantId)
        {
            var contracts = await _repository.GetByTenantIdAsync(tenantId);

            return contracts.Select(c => new ContractResponseDTO
            {
                Id = c.Id,
                ContractCode = c.ContractCode,

                // Ghép Tên Phòng và Tên Khu trọ thành 1 Title duy nhất 
                Title = c.Room?.Property != null
                        ? $"Phòng {c.Room.Name} - {c.Room.Property.Name}"
                        : "Hợp đồng phòng trọ",

                Status = c.Status,

               
                StartDate = c.StartDate.ToString("dd/MM/yyyy"),
                EndDate = c.EndDate.ToString("dd/MM/yyyy"),

                RentPrice = c.Rent,
                Deposit = c.Deposit,

               
                PaymentCycle = c.PaymentCycle == "monthly" ? "Hàng tháng" :
                               c.PaymentCycle == "quarterly" ? "Hàng quý" : c.PaymentCycle
            });
        }
        public async Task<object?> GetContractDetailAsync(string contractId, string tenantId)
        {
            var contract = await _repository.GetByIdAsync(contractId);

            if (contract == null || !string.Equals(contract.TenantId, tenantId, StringComparison.OrdinalIgnoreCase))
                return null;

            List<string> amenities = new List<string>();
            if (contract.Room != null && !string.IsNullOrEmpty(contract.Room.PropertyId))
            {
                amenities = await _context.PropertyAmenities
                    .Include(pa => pa.Amenity)
                    .Where(pa => pa.PropertyId == contract.Room.PropertyId && pa.Status == "active")
                    .Select(pa => pa.Amenity.Name)
                    .ToListAsync();
            }

            if (!amenities.Any())
            {
                amenities = new List<string> { "Máy lạnh", "Tủ lạnh", "Giường nệm", "Ban công", "WC riêng", "Giờ giấc tự do", "Wifi tốc độ cao" };
            }

            return new
            {
                id = contract.Id,
                contractCode = contract.ContractCode,
                roomId = contract.RoomId,
                roomName = contract.Room != null ? contract.Room.Name : "Phòng trọ",
                status = contract.Status,
                signingClosedAt = contract.SigningClosedAt.HasValue
                    ? DateTime.SpecifyKind(contract.SigningClosedAt.Value, DateTimeKind.Utc) : (DateTime?)null,
                signingCloseReason = contract.SigningCloseReason,
                startDate = contract.StartDate.ToString("dd/MM/yyyy"),
                endDate = contract.EndDate.ToString("dd/MM/yyyy"),
                rent = contract.Rent,
                deposit = contract.Deposit,
                paymentCycle = contract.PaymentCycle,
                initialElectricityReading = contract.InitialElectricityReading,
                initialWaterReading = contract.InitialWaterReading,
                ownerName = contract.Owner != null ? contract.Owner.Name : "Đang cập nhật",
                ownerPhone = contract.Owner != null ? contract.Owner.Phone : "Đang cập nhật",
                ownerSignature = contract.OwnerSignature,
                tenantSignature = contract.TenantSignature,
                pdfUrl = !string.IsNullOrWhiteSpace(contract.Terms) && contract.Terms.Contains("PdfUrl:")
                    ? contract.Terms.Split('|').FirstOrDefault(p => p.StartsWith("PdfUrl:"))?.Replace("PdfUrl:", "")
                    : "http://10.0.2.2:5093/uploads/contracts/sample_contract.pdf",

                services = contract.ContractServices.Select(cs => new
                {
                    name = cs.Service != null ? cs.Service.Name : "Dịch vụ",
                    price = cs.UnitPrice,
                    unit = cs.Service != null ? cs.Service.Unit : "tháng"
                }).ToList(),

                amenities = amenities
            };
        }
    }
}
