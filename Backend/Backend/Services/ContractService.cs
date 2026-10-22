using Backend.DTOs;
using Backend.Repositories;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace Backend.Services
{
    public class ContractService : IContractService
    {
        private readonly IContractRepository _repository;

        public ContractService(IContractRepository repository)
        {
            _repository = repository;
        }

        public async Task<IEnumerable<ContractResponseDTO>> GetTenantContractsAsync(string tenantId)
        {
            var contracts = await _repository.GetByTenantIdAsync(tenantId);

            return contracts.Select(c => new ContractResponseDTO
            {
                Id = c.Id,
                ContractCode = c.ContractCode,

                // Ghép Tên Phòng và Tên Khu trọ thành 1 Title duy nhất (Giống giao diện Flutter của bạn)
                Title = c.Room?.Property != null
                        ? $"Phòng {c.Room.Name} - {c.Room.Property.Name}"
                        : "Hợp đồng phòng trọ",

                Status = c.Status,

                // Định dạng ngày tháng
                StartDate = c.StartDate.ToString("dd/MM/yyyy"),
                EndDate = c.EndDate.ToString("dd/MM/yyyy"),

                RentPrice = c.Rent,
                Deposit = c.Deposit,

                // Dịch chu kỳ thanh toán sang tiếng Việt
                PaymentCycle = c.PaymentCycle == "monthly" ? "Hàng tháng" :
                               c.PaymentCycle == "quarterly" ? "Hàng quý" : c.PaymentCycle
            });
        }
    }
}