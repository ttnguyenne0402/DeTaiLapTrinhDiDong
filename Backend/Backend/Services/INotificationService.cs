using Backend.DTOs;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace Backend.Services
{
    public interface INotificationService
    {
        Task<IEnumerable<NotificationResponseDTO>> GetUserNotificationsAsync(string userId);
        Task<bool> MarkAsReadAsync(string id);
    }
}