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
        public async Task<object> GetContractDetailAsync(string contractId)
        {
            var contract = await _repository.GetByIdAsync(contractId);

            if (contract == null) return null;

            return new
            {
                id = contract.Id,
                contractCode = contract.ContractCode,
                roomId = contract.RoomId,
                roomName = contract.Room != null ? contract.Room.Name : "Phòng trọ",
                status = contract.Status,
                startDate = contract.StartDate.ToString("dd/MM/yyyy"),
                endDate = contract.EndDate.ToString("dd/MM/yyyy"),
                rent = contract.Rent,
                deposit = contract.Deposit,
                paymentCycle = contract.PaymentCycle,
                initialElectricityReading = contract.InitialElectricityReading,
                initialWaterReading = contract.InitialWaterReading,
                ownerName = contract.Owner != null ? contract.Owner.Name : "Đang cập nhật",
                ownerPhone = contract.Owner != null ? contract.Owner.Phone : "Đang cập nhật",

           
                services = contract.ContractServices.Select(cs => new
                {
                    name = cs.Service != null ? cs.Service.Name : "Dịch vụ",
                    price = cs.UnitPrice,
                    unit = cs.Service != null ? cs.Service.Unit : "tháng"
                }).ToList()
            };
        }
    }
}