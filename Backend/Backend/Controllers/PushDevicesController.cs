using System.ComponentModel.DataAnnotations;
using System.Security.Claims;
using Backend.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Backend.Controllers;

[ApiController]
[Authorize]
[Route("api/notifications/devices")]
public sealed class PushDevicesController(FirebasePushService push) : ControllerBase
{
    public sealed record DeviceRequest([Required, MaxLength(2048)] string Token);

    [HttpPut]
    public async Task<IActionResult> Register(DeviceRequest request, CancellationToken cancellationToken)
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrEmpty(userId)) return Unauthorized();
        if (!push.Enabled) return StatusCode(StatusCodes.Status503ServiceUnavailable);

        await push.RegisterAsync(userId, request.Token, cancellationToken);
        return NoContent();
    }

    [HttpDelete]
    public async Task<IActionResult> Unregister(DeviceRequest request, CancellationToken cancellationToken)
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrEmpty(userId)) return Unauthorized();
        await push.UnregisterAsync(userId, request.Token, cancellationToken);
        return NoContent();
    }
}
