using Backend.DTOs;
using Backend.Repositories;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace Backend.Services
{
    public class NotificationService : INotificationService
    {
        private readonly INotificationRepository _repository;

        public NotificationService(INotificationRepository repository)
        {
            _repository = repository;
        }

        public async Task<IEnumerable<NotificationResponseDTO>> GetUserNotificationsAsync(string userId)
        {
            var notifs = await _repository.GetByUserIdAsync(userId);
            return notifs.Select(n => new NotificationResponseDTO
            {
                Id = n.Id,
                Title = n.Title,
                Message = n.Message,
                Type = n.Type,
                IsRead = n.ReadAt != null,
                CreatedAt = n.CreatedAt?.ToString("dd/MM/yyyy HH:mm") ?? ""
            });
        }

        public async Task<bool> MarkAsReadAsync(string id)
        {
            var notif = await _repository.GetByIdAsync(id);
            if (notif == null) return false;

            notif.ReadAt = DateTime.Now;
            notif.UpdatedAt = DateTime.Now;
            await _repository.UpdateAsync(notif);
            return true;
        }
    }
}