using Backend.DTOs;
using Backend.Models;
using Backend.Repositories;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace Backend.Services
{
    public class MaintenanceService : IMaintenanceService
    {
        private readonly IMaintenanceRequestRepository _repository;

        public MaintenanceService(IMaintenanceRequestRepository repository)
        {
            _repository = repository;
        }

        public async Task<MaintenanceResponseDTO> CreateRequestAsync(MaintenanceRequestDTO request)
        {
            var newRequest = new MaintenanceRequest
            {
                Id = "MR" + DateTime.Now.ToString("yyyyMMddHHmmss"),
                RoomId = request.RoomId,
                TenantId = request.TenantId,
                Title = request.Title,
                Description = request.Description,
                Priority = request.Priority,
                Status = "pending", 
                Image = request.Image,
                CreatedAt = DateTime.Now,
                UpdatedAt = DateTime.Now
            };

            await _repository.AddAsync(newRequest);

            return new MaintenanceResponseDTO
            {
                Id = newRequest.Id,
                Title = newRequest.Title,
                Description = newRequest.Description,
                Priority = newRequest.Priority,
                Status = newRequest.Status,
                CreatedAt = newRequest.CreatedAt?.ToString("dd/MM/yyyy") ?? ""
            };
        }

        public async Task<IEnumerable<MaintenanceResponseDTO>> GetTenantRequestsAsync(string tenantId)
        {
            var requests = await _repository.GetByTenantIdAsync(tenantId);
            return requests.Select(r => new MaintenanceResponseDTO
            {
                Id = r.Id,
                Title = r.Title,
                Description = r.Description,
                Priority = r.Priority,
                Status = r.Status,
                CreatedAt = r.CreatedAt?.ToString("dd/MM/yyyy") ?? ""
            });
        }
    }
}