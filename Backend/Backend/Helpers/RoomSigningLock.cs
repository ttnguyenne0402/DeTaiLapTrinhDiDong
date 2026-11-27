using Backend.Models;
using Microsoft.EntityFrameworkCore;

namespace Backend.Helpers;

public static class RoomSigningLock
{
    // Khóa tồn tại đến khi giao dịch hiện tại kết thúc.
    public static Task AcquireAsync(QuanLyPhongTroContext context, string roomId, CancellationToken cancellationToken)
    {
        var resource = $"room-signing:{roomId.ToUpperInvariant()}";
        return context.Database.ExecuteSqlInterpolatedAsync($"""
            DECLARE @result INT;
            EXEC @result = sys.sp_getapplock @Resource = {resource},
                @LockMode = 'Exclusive', @LockOwner = 'Transaction', @LockTimeout = 5000;
            IF @result < 0 THROW 50002, 'Unable to lock room signing workflow.', 1;
            """, cancellationToken);
    }
}
