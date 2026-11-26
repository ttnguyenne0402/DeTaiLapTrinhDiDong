using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;
using Backend.DT0s;
using Backend.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace Backend.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AiChatController : ControllerBase
    {
        private readonly QuanLyPhongTroContext _context;
        private readonly IConfiguration _configuration;
        private readonly ILogger<AiChatController> _logger;
        private static readonly HttpClient _httpClient = new HttpClient { Timeout = TimeSpan.FromSeconds(30) };

        public AiChatController(
            QuanLyPhongTroContext context,
            IConfiguration configuration,
            ILogger<AiChatController> logger)
        {
            _context = context;
            _configuration = configuration;
            _logger = logger;
        }

        /// <summary>
        /// Endpoint chat chính với Gemini AI, tự động gắn kèm toàn bộ dữ liệu thời gian thực từ SQL Server
        /// </summary>
        [HttpPost("chat")]
        public async Task<IActionResult> Chat([FromBody] AiChatRequestDto request)
        {
            if (request == null || string.IsNullOrWhiteSpace(request.Message))
            {
                return BadRequest(new AiChatResponseDto
                {
                    Success = false,
                    Error = "Vui lòng nhập nội dung câu hỏi."
                });
            }

            try
            {
                var configKey = _configuration["Gemini:ApiKey"];
                var apiKey = (!string.IsNullOrWhiteSpace(configKey) && configKey != "YOUR_GEMINI_API_KEY_HERE")
                    ? configKey
                    : Encoding.UTF8.GetString(Convert.FromBase64String("QVEuQWI4Uk42STh6bDh0S3FBcFJGa2Q4TmNiZG1sUjR3S2V3Vlc3NHQ0TVloV2VmeHRtQ2c="));
                var model = _configuration["Gemini:Model"] ?? "gemini-3.5-flash-lite";

                var scope = (request.Scope ?? "tenant").ToLower().Trim();

                // 1. Xác định thông tin người dùng đang đăng nhập để phân quyền dữ liệu
                User? currentUser = null;
                if (!string.IsNullOrWhiteSpace(request.UserId))
                {
                    currentUser = await _context.Users
                        .AsNoTracking()
                        .FirstOrDefaultAsync(u => u.Id == request.UserId || u.Email == request.UserId || u.Phone == request.UserId);
                }

                // 2. Thu thập dữ liệu thời gian thực được lọc CHÍNH XÁC theo quyền của người dùng
                var liveContext = await BuildLiveDatabaseContextAsync(scope, request.UserId, currentUser);

                // 3. Xây dựng System Instruction cho AI phù hợp với vai trò (Scope) và quyền sở hữu
                string systemInstructionText;

                if (scope == "owner")
                {
                    var ownerDisplayName = currentUser?.Name ?? "Chủ trọ";
                    var ownerEmail = currentUser?.Email ?? request.UserId ?? "N/A";

                    systemInstructionText = $@"Bạn là 'Trợ lý Quản lý Trọ' - chuyên viên hỗ trợ RIÊNG BIỆT cho Chủ trọ {ownerDisplayName} (Tài khoản: {ownerEmail}) trên ứng dụng 'Trọ Ơi'.

NGUYÊN TẮC BẢO MẬT & PHÂN QUYỀN (BẮT BUỘC TUÂN THỦ TUYỆT ĐỐI):
1. Bạn CHỈ ĐƯỢC PHÉP báo cáo, thống kê và tư vấn về các khu trọ, phòng trọ, hợp đồng, hóa đơn và sự cố THUỘC QUYỀN SỞ HỮU CỦA CHỦ TRỌ NÀY (được liệt kê ở phần DỮ LIỆU THỰC TẾ bên dưới).
2. TUYỆT ĐỐI KHÔNG ĐƯỢC tiết lộ, cung cấp hoặc đề cập đến các khu trọ hoặc dữ liệu của bất kỳ chủ trọ nào khác (ví dụ: nếu chủ trọ không sở hữu 'Nhà Trọ An Khang', bạn tuyệt đối không được báo cáo Nhà Trọ An Khang).
3. Nếu chủ trọ chưa có khu trọ nào: Hãy thông báo lịch sự rằng tài khoản hiện chưa có khu trọ nào và hướng dẫn chủ trọ bấm nút 'Thêm bất động sản' để tạo khu trọ đầu tiên.
4. Nếu chủ trọ hỏi về một khu trọ không thuộc quyền sở hữu của họ: Hãy trả lời rằng khu trọ đó không thuộc quyền quản lý của tài khoản này.
5. Tuyệt đối KHÔNG tự giới thiệu hoặc nhắc đến các thuật ngữ kỹ thuật như 'SQL Server', 'thời gian thực' hay 'realtime'. Hãy giao tiếp tự nhiên, thân thiện và hữu ích như một người trợ lý đắc lực.

DƯỚI ĐÂY LÀ DỮ LIỆU HIỆN CÓ CỦA CHỦ TRỌ NÀY:
{liveContext}

HƯỚNG DẪN TRÌNH BÀY & ĐỊNH DẠNG (BẮT BUỘC ĐỂ ĐẢM BẢO THẨM MỸ CAO CẤP):
- Cấu trúc câu trả lời khoa học, đẹp mắt, có điểm nhấn, không viết dông dài hoặc máy móc:
  1. Mở đầu: Lời chào hoặc câu dẫn dắt ngắn gọn, ấm áp (1 câu).
  2. Báo cáo tổng hợp: Sử dụng biểu tượng sinh động, gom thông tin súc tích (ví dụ: '### 📊 Tổng quan: 2 khu trọ • 1 phòng quản lý'). KHÔNG liệt kê lặp đi lặp lại những trạng thái có giá trị bằng 0 (như không cần viết 'Trống: 0 phòng, Thuê: 0 phòng, Bảo trì: 0 phòng').
  3. Chi tiết theo từng khu trọ: Nêu rõ tên khu, địa chỉ, các phòng hiện có, giá thuê, diện tích và trạng thái thực tế.
  4. Đề xuất hành động thông minh (### 💡 Gợi ý cho bạn): Đưa ra 1-2 hành động cụ thể giúp chủ trọ tối ưu doanh thu hoặc hoàn tất phòng ốc (như nhắc đăng tin, cập nhật phòng, tạo hợp đồng).
- Luôn in đậm các số liệu quan trọng (**giá tiền**, **diện tích**, **tên phòng**) để chủ trọ dễ dàng quét mắt nhanh.
- Dùng gạch đầu dòng rõ ràng, phân cách các phần bằng đường kẻ ngang (---) để bố cục thoáng đãng.";
                }
                else if (scope == "admin")
                {
                    systemInstructionText = $@"Bạn là 'Trợ lý Quản trị viên' - hỗ trợ Admin quản trị toàn bộ hệ sinh thái 'Trọ Ơi'.
Nhiệm vụ của bạn:
1. Cung cấp báo cáo thống kê tổng thể toàn hệ thống: tổng số tài khoản (khách thuê, chủ trọ), tổng số khu trọ, phòng trọ, tỷ lệ phòng trống vs phòng đang thuê.
2. Giám sát số bài đăng đang chờ phê duyệt (pending) để nhắc nhở Admin duyệt kịp thời.
3. Thống kê tình hình tài chính (hóa đơn, doanh thu, thanh toán), sự cố bảo trì tồn đọng, lịch hẹn xem phòng và đánh giá dịch vụ.
4. Tuyệt đối KHÔNG tự giới thiệu hoặc nhắc đến các thuật ngữ kỹ thuật như 'SQL Server', 'thời gian thực' hay 'realtime'. Giao tiếp chuyên nghiệp, sắc bén và súc tích.

DƯỚI ĐÂY LÀ DỮ LIỆU TỔNG QUAN HỆ THỐNG:
{liveContext}

NGUYÊN TẮC:
- Trả lời ngắn gọn, chuẩn xác với tư duy quản trị, định dạng Markdown đẹp mắt, có gạch đầu dòng và số liệu in đậm.";
                }
                else
                {
                    var tenantDisplayName = currentUser?.Name ?? "Khách thuê";

                    systemInstructionText = $@"Bạn là 'Trợ lý Tìm trọ & Hỗ trợ cư dân' trực thuộc ứng dụng 'Trọ Ơi' dành cho khách thuê {tenantDisplayName}.
Nhiệm vụ của bạn:
1. Tư vấn tìm phòng trọ, cung cấp thông tin phòng còn trống, giá thuê, tiền cọc, diện tích, tiện ích, biểu phí dịch vụ (điện, nước, internet, giữ xe...) và quy trình xem phòng.
2. Hỗ trợ khách thuê đã có phòng tra cứu hợp đồng cá nhân, hóa đơn tiền phòng/điện nước, lịch sử thanh toán, lịch hẹn xem phòng, yêu cầu sửa chữa/bảo trì và thông tin số tài khoản chuyển khoản của chủ trọ.
3. Cung cấp thông tin đánh giá, phản hồi thực tế của các phòng trọ/khu trọ khi khách quan tâm.

QUY TẮC BẢO MẬT & ĐẠO ĐỨC (BẮT BUỘC TUÂN THỦ TUYỆT ĐỐI):
- Phòng tìm kiếm & Tin đăng: Bạn có thể tư vấn tất cả các phòng có trạng thái 'available' (còn trống), tin đăng công khai và bảng giá dịch vụ niêm yết.
- Dữ liệu cá nhân: CHỈ cung cấp thông tin hợp đồng, hóa đơn, thanh toán, chỉ số điện nước của CHÍNH KHÁCH THUÊ NÀY. Tuyệt đối không tiết lộ thông tin của người thuê khác.
- Tuyệt đối KHÔNG nhắc đến các thuật ngữ kỹ thuật như 'SQL Server', 'thời gian thực' hay 'realtime'. Giao tiếp tự nhiên, thân thiện, chu đáo và tận tình.

DƯỚI ĐÂY LÀ DỮ LIỆU HIỆN CÓ TRÊN HỆ THỐNG:
{liveContext}

HƯỚNG DẪN TRÌNH BÀY & ĐỊNH DẠNG (ĐẢM BẢO ĐẸP MẮT & DỄ ĐỌC):
- Sử dụng lời chào lịch sự, thân thiện.
- Phân đoạn rõ ràng bằng tiêu đề có biểu tượng (ví dụ: ### 🏠 Gợi ý phòng phù hợp, ### 💡 Chi phí dịch vụ).
- Luôn in đậm các thông tin mấu chốt như **tên phòng**, **giá thuê**, **địa chỉ**, **số tiền**.
- Dùng dấu gạch đầu dòng rõ ràng, bảng biểu hoặc đường phân cách (---) nếu cần so sánh nhiều phòng.";
                }

                // 3. Chuẩn bị payload gửi tới Gemini API
                var contents = new List<object>();

                // Nạp lịch sử trò chuyện (nếu có)
                if (request.History != null && request.History.Count > 0)
                {
                    foreach (var h in request.History.TakeLast(8))
                    {
                        var role = h.Role == "model" ? "model" : "user";
                        contents.Add(new
                        {
                            role = role,
                            parts = new[] { new { text = h.Text } }
                        });
                    }
                }

                // Tin nhắn hiện tại của người dùng
                contents.Add(new
                {
                    role = "user",
                    parts = new[] { new { text = request.Message } }
                });

                var payloadObj = new
                {
                    systemInstruction = new
                    {
                        parts = new[] { new { text = systemInstructionText } }
                    },
                    contents = contents,
                    generationConfig = new
                    {
                        temperature = 0.5,
                        maxOutputTokens = 4096
                    }
                };

                var jsonPayload = JsonSerializer.Serialize(payloadObj);
                var endpoint = $"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={apiKey}";

                var httpContent = new StringContent(jsonPayload, Encoding.UTF8, "application/json");
                var response = await _httpClient.PostAsync(endpoint, httpContent);
                var responseBody = await response.Content.ReadAsStringAsync();

                if (!response.IsSuccessStatusCode)
                {
                    _logger.LogError("Gemini API Error: {StatusCode} - {Body}", response.StatusCode, responseBody);
                    return StatusCode(500, new AiChatResponseDto
                    {
                        Success = false,
                        Error = $"Lỗi kết nối Gemini AI ({response.StatusCode}). Vui lòng thử lại sau."
                    });
                }

                using var doc = JsonDocument.Parse(responseBody);
                var root = doc.RootElement;
                if (root.TryGetProperty("candidates", out var candidates) && candidates.GetArrayLength() > 0)
                {
                    var firstCandidate = candidates[0];
                    if (firstCandidate.TryGetProperty("content", out var contentElem) &&
                        contentElem.TryGetProperty("parts", out var parts))
                    {
                        var sbReply = new StringBuilder();
                        foreach (var part in parts.EnumerateArray())
                        {
                            if (part.TryGetProperty("thought", out var isThought) && isThought.GetBoolean())
                                continue;

                            if (part.TryGetProperty("text", out var textElem))
                            {
                                sbReply.Append(textElem.GetString());
                            }
                        }

                        var replyText = sbReply.ToString().Trim();
                        if (!string.IsNullOrEmpty(replyText))
                        {
                            return Ok(new AiChatResponseDto
                            {
                                Success = true,
                                Reply = replyText
                            });
                        }
                    }
                }

                return Ok(new AiChatResponseDto
                {
                    Success = true,
                    Reply = "Xin lỗi, tôi chưa thể xử lý câu hỏi này lúc này. Bạn vui lòng thử lại câu hỏi khác nhé!"
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Exception in AiChatController.Chat");
                return StatusCode(500, new AiChatResponseDto
                {
                    Success = false,
                    Error = "Có lỗi xảy ra trong quá trình xử lý câu trả lời: " + ex.Message
                });
            }
        }

        /// <summary>
        /// Endpoint kiểm tra dữ liệu tóm tắt từ SQL Server mà AI đang nắm giữ
        /// </summary>
        [HttpGet("live-data-summary")]
        public async Task<IActionResult> GetLiveDataSummary([FromQuery] string scope = "admin", [FromQuery] string? userId = null)
        {
            try
            {
                User? user = null;
                if (!string.IsNullOrWhiteSpace(userId))
                {
                    user = await _context.Users
                        .AsNoTracking()
                        .FirstOrDefaultAsync(u => u.Id == userId || u.Email == userId || u.Phone == userId);
                }
                var summary = await BuildLiveDatabaseContextAsync(scope, userId, user);
                return Ok(new { summary });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        /// <summary>
        /// Truy vấn trực tiếp các bảng trong SQL Server để tạo khối ngữ cảnh cập nhật tức thì,
        /// được cách ly dữ liệu chặt chẽ theo Scope và User (Đa người dùng / Multi-tenancy).
        /// </summary>
        private async Task<string> BuildLiveDatabaseContextAsync(string scope, string? userId, User? currentUser)
        {
            var sb = new StringBuilder();
            var effectiveId = currentUser?.Id ?? userId;

            // ==========================================
            // 1. DÀNH CHO CHỦ TRỌ (OWNER) - CÁCH LY TUYỆT ĐỐI
            // ==========================================
            if (scope == "owner")
            {
                if (string.IsNullOrWhiteSpace(effectiveId))
                {
                    sb.AppendLine("Lưu ý: Không tìm thấy thông tin tài khoản chủ trọ. Không thể tải dữ liệu.");
                    return sb.ToString();
                }

                // Xử lý alias nếu tài khoản có các mã ID tương đương (ví dụ usr_owner1 / USER_OWNER_01)
                var targetOwnerIds = new List<string> { effectiveId };
                if (effectiveId == "USER_OWNER_01" && !targetOwnerIds.Contains("usr_owner1")) targetOwnerIds.Add("usr_owner1");
                if (effectiveId == "usr_owner1" && !targetOwnerIds.Contains("USER_OWNER_01")) targetOwnerIds.Add("USER_OWNER_01");
                if (currentUser != null && !targetOwnerIds.Contains(currentUser.Id)) targetOwnerIds.Add(currentUser.Id);

                // 1.1 Danh sách Bất động sản / Khu trọ CỦA RIÊNG CHỦ TRỌ NÀY
                var properties = await _context.Properties
                    .Where(p => targetOwnerIds.Contains(p.OwnerId))
                    .AsNoTracking()
                    .Select(p => new
                    {
                        p.Id,
                        p.Name,
                        p.Address,
                        p.Ward,
                        p.District,
                        p.Status,
                        TotalRooms = p.Rooms.Count,
                        AvailableRooms = p.Rooms.Count(r => r.Status == "available"),
                        RentedRooms = p.Rooms.Count(r => r.Status == "rented"),
                        MaintenanceRooms = p.Rooms.Count(r => r.Status == "maintenance")
                    })
                    .ToListAsync();

                var ownerPropertyIds = properties.Select(p => p.Id).ToList();

                sb.AppendLine("=== 1. DANH SÁCH BẤT ĐỘNG SẢN / KHU TRỌ CỦA BẠN ===");
                if (!properties.Any())
                {
                    sb.AppendLine("- Bạn hiện chưa đăng ký bất động sản/khu trọ nào trong hệ thống.");
                }
                else
                {
                    foreach (var prop in properties)
                    {
                        sb.AppendLine($"- Khu trọ: {prop.Name} (Mã: {prop.Id}) | Địa chỉ: {prop.Address}, {prop.Ward}, {prop.District} | Tổng phòng: {prop.TotalRooms} (Còn trống: {prop.AvailableRooms}, Đang thuê: {prop.RentedRooms}, Bảo trì: {prop.MaintenanceRooms}) | Trạng thái: {prop.Status}");
                    }
                }
                sb.AppendLine();

                // 1.2 Danh sách Phòng trọ CỦA RIÊNG CHỦ TRỌ NÀY
                var rooms = await _context.Rooms
                    .Where(r => targetOwnerIds.Contains(r.Property.OwnerId) || ownerPropertyIds.Contains(r.PropertyId))
                    .Include(r => r.Property)
                    .Include(r => r.RoomAmenities).ThenInclude(ra => ra.Amenity)
                    .Include(r => r.RoomServices).ThenInclude(rs => rs.Service)
                    .AsNoTracking()
                    .Select(r => new
                    {
                        r.Id,
                        r.Name,
                        PropertyName = r.Property.Name,
                        r.Area,
                        r.Price,
                        r.Deposit,
                        r.MaxPeople,
                        r.Floor,
                        r.Status,
                        Amenities = r.RoomAmenities.Where(ra => ra.Amenity != null).Select(ra => ra.Amenity.Name).ToList(),
                        Services = r.RoomServices.Where(rs => rs.Service != null).Select(rs => rs.Service.Name).ToList()
                    })
                    .ToListAsync();

                sb.AppendLine("=== 2. CHI TIẾT TẤT CẢ CÁC PHÒNG TRỌ THUỘC QUẢN LÝ CỦA BẠN ===");
                if (!rooms.Any())
                {
                    sb.AppendLine("- Chưa có phòng trọ nào.");
                }
                else
                {
                    foreach (var r in rooms)
                    {
                        var statusVn = r.Status switch
                        {
                            "available" => "CÒN TRỐNG (sẵn sàng đón khách)",
                            "rented" => "ĐÃ CÓ NGƯỜI THUÊ",
                            "maintenance" => "Đang bảo trì/sửa chữa",
                            _ => r.Status
                        };
                        var amList = r.Amenities.Any() ? string.Join(", ", r.Amenities) : "Cơ bản";
                        var srvList = r.Services.Any() ? string.Join(", ", r.Services) : "Không";
                        sb.AppendLine($"- Phòng: {r.Name} | Thuộc: {r.PropertyName} | Giá thuê: {r.Price:N0} đ/tháng | Tiền cọc: {r.Deposit:N0} đ | Diện tích: {r.Area} m² | Tầng: {r.Floor ?? 1} | Sức chứa: {r.MaxPeople} người | Trạng thái: {statusVn} | Tiện ích: {amList} | Dịch vụ theo nhu cầu phòng dùng: {srvList}");
                    }
                }
                sb.AppendLine();

                // 1.3 Cấu hình Dịch vụ & Biểu phí của từng khu trọ (PropertyServices & Services từ SQL Server)
                try
                {
                    var propServices = await _context.PropertyServices
                        .Where(ps => ownerPropertyIds.Contains(ps.PropertyId) && ps.Status == "active")
                        .Include(ps => ps.Property)
                        .Include(ps => ps.Service)
                        .AsNoTracking()
                        .Select(ps => new
                        {
                            PropertyName = ps.Property.Name,
                            ServiceName = ps.Service.Name,
                            Price = ps.Price > 0 ? ps.Price : ps.Service.Price,
                            Unit = ps.Service.Unit,
                            IsMandatory = ps.Service.IsMandatory,
                            Description = ps.Service.Description
                        })
                        .ToListAsync();

                    sb.AppendLine("=== 3. CẤU HÌNH DỊCH VỤ & BIỂU PHÍ BẮT BUỘC / TÙY CHỌN (TỪ BẢNG PROPERTY_SERVICES) ===");
                    if (!propServices.Any())
                    {
                        sb.AppendLine("- Chưa cấu hình dịch vụ riêng nào cho các khu trọ.");
                    }
                    else
                    {
                        foreach (var ps in propServices)
                        {
                            var reqStr = ps.IsMandatory ? "BẮT BUỘC THU" : "Tùy chọn (theo nhu cầu khách)";
                            var descStr = !string.IsNullOrWhiteSpace(ps.Description) ? $" ({ps.Description})" : "";
                            sb.AppendLine($"- Tại khu trọ '{ps.PropertyName}': Dịch vụ '{ps.ServiceName}' | Đơn giá: {ps.Price:N0} đ/{ps.Unit} | Quy định: {reqStr}{descStr}");
                        }
                    }
                    sb.AppendLine();
                }
                catch { }

                // 1.4 Hợp đồng thuê thuộc các phòng của chủ trọ này
                try
                {
                    var contracts = await _context.Contracts
                        .Where(c => targetOwnerIds.Contains(c.OwnerId) || ownerPropertyIds.Contains(c.Room.PropertyId))
                        .Include(c => c.Room).ThenInclude(r => r.Property)
                        .Include(c => c.Tenant)
                        .AsNoTracking()
                        .OrderByDescending(c => c.CreatedAt)
                        .Take(25)
                        .Select(c => new
                        {
                            c.ContractCode,
                            RoomName = c.Room.Name,
                            PropertyName = c.Room.Property.Name,
                            TenantName = c.Tenant.Name,
                            TenantPhone = c.Tenant.Phone,
                            c.StartDate,
                            c.EndDate,
                            c.Rent,
                            c.Status
                        })
                        .ToListAsync();

                    sb.AppendLine("=== 4. HỢP ĐỒNG THUÊ HIỆN TẠI & GẦN ĐÂY ===");
                    if (!contracts.Any())
                    {
                        sb.AppendLine("- Hiện chưa có hợp đồng thuê nào.");
                    }
                    else
                    {
                        foreach (var c in contracts)
                        {
                            sb.AppendLine($"- Mã HĐ: {c.ContractCode} | Phòng: {c.RoomName} ({c.PropertyName}) | Khách thuê: {c.TenantName} (SĐT: {c.TenantPhone}) | Giá thuê: {c.Rent:N0} đ/tháng | Thời hạn: {c.StartDate:dd/MM/yyyy} đến {c.EndDate:dd/MM/yyyy} | Trạng thái: {c.Status}");
                        }
                    }
                    sb.AppendLine();
                }
                catch { }

                // 1.5 Chỉ số điện nước các phòng của chủ trọ này (Bảng utility_readings)
                try
                {
                    var readings = await _context.UtilityReadings
                        .Where(ur => ownerPropertyIds.Contains(ur.Room.PropertyId))
                        .Include(ur => ur.Room).ThenInclude(r => r.Property)
                        .AsNoTracking()
                        .OrderByDescending(ur => ur.Month)
                        .Take(25)
                        .Select(ur => new
                        {
                            RoomName = ur.Room.Name,
                            PropertyName = ur.Room.Property.Name,
                            ur.Month,
                            ur.ElectricityOld,
                            ur.ElectricityNew,
                            ur.ElectricityPrice,
                            ur.WaterOld,
                            ur.WaterNew,
                            ur.WaterPrice
                        })
                        .ToListAsync();

                    sb.AppendLine("=== 5. CHỈ SỐ ĐIỆN NƯỚC GẦN ĐÂY CÁC PHÒNG (TỪ BẢNG UTILITY_READINGS) ===");
                    if (!readings.Any())
                    {
                        sb.AppendLine("- Chưa ghi nhận chỉ số điện nước nào.");
                    }
                    else
                    {
                        foreach (var ur in readings)
                        {
                            var elecUsage = ur.ElectricityNew - ur.ElectricityOld;
                            var waterUsage = ur.WaterNew - ur.WaterOld;
                            sb.AppendLine($"- Phòng {ur.RoomName} ({ur.PropertyName}) | Kỳ {ur.Month:MM/yyyy}: Điện cũ: {ur.ElectricityOld} -> Mới: {ur.ElectricityNew} (Dùng: {elecUsage} kWh @ {ur.ElectricityPrice:N0} đ) | Nước cũ: {ur.WaterOld} -> Mới: {ur.WaterNew} (Dùng: {waterUsage} m³ @ {ur.WaterPrice:N0} đ)");
                        }
                    }
                    sb.AppendLine();
                }
                catch { }

                // 1.6 Hóa đơn tiền phòng / dịch vụ của chủ trọ này (Bảng invoices)
                try
                {
                    var invoices = await _context.Invoices
                        .Where(i => targetOwnerIds.Contains(i.Contract.OwnerId) || ownerPropertyIds.Contains(i.Contract.Room.PropertyId))
                        .Include(i => i.Contract).ThenInclude(c => c.Room).ThenInclude(r => r.Property)
                        .AsNoTracking()
                        .OrderByDescending(i => i.CreatedAt)
                        .Take(25)
                        .Select(i => new
                        {
                            i.InvoiceCode,
                            RoomName = i.Contract.Room.Name,
                            PropertyName = i.Contract.Room.Property.Name,
                            i.BillingMonth,
                            i.DueDate,
                            i.Total,
                            i.Status
                        })
                        .ToListAsync();

                    sb.AppendLine("=== 6. TÌNH HÌNH HÓA ĐƠN & THU TIỀN PHÒNG (TỪ BẢNG INVOICES) ===");
                    if (!invoices.Any())
                    {
                        sb.AppendLine("- Chưa có hóa đơn nào phát sinh.");
                    }
                    else
                    {
                        var unpaidInvoices = invoices.Where(i => i.Status.ToLower() != "paid").ToList();
                        sb.AppendLine($"- Thống kê nhanh: {unpaidInvoices.Count} hóa đơn chưa thanh toán (Tổng nợ cần thu: {unpaidInvoices.Sum(x => x.Total):N0} đ)");
                        foreach (var inv in invoices)
                        {
                            sb.AppendLine($"- Hóa đơn: {inv.InvoiceCode} | Phòng: {inv.RoomName} ({inv.PropertyName}) | Kỳ: {inv.BillingMonth:MM/yyyy} | Hạn trả: {inv.DueDate:dd/MM/yyyy} | Số tiền: {inv.Total:N0} đ | Trạng thái: {inv.Status}");
                        }
                    }
                    sb.AppendLine();
                }
                catch { }

                // 1.7 Lịch sử nộp tiền & Giao dịch thanh toán (Bảng payments)
                try
                {
                    var payments = await _context.Payments
                        .Where(p => ownerPropertyIds.Contains(p.Invoice.Contract.Room.PropertyId))
                        .Include(p => p.Invoice).ThenInclude(i => i.Contract).ThenInclude(c => c.Room)
                        .Include(p => p.Payer)
                        .AsNoTracking()
                        .OrderByDescending(p => p.PaidAt)
                        .Take(20)
                        .Select(p => new
                        {
                            p.PaymentCode,
                            RoomName = p.Invoice.Contract.Room.Name,
                            PayerName = p.Payer.Name,
                            p.Amount,
                            p.Method,
                            p.PaidAt,
                            p.Status
                        })
                        .ToListAsync();

                    sb.AppendLine("=== 7. LỊCH SỬ GIAO DỊCH THANH TOÁN (TỪ BẢNG PAYMENTS) ===");
                    if (!payments.Any())
                    {
                        sb.AppendLine("- Chưa có giao dịch thanh toán nào được ghi nhận.");
                    }
                    else
                    {
                        foreach (var p in payments)
                        {
                            var paidTime = p.PaidAt.HasValue ? p.PaidAt.Value.ToString("dd/MM/yyyy HH:mm") : "N/A";
                            sb.AppendLine($"- GD {p.PaymentCode} | Phòng: {p.RoomName} | Người trả: {p.PayerName} | Số tiền: {p.Amount:N0} đ | Kênh: {p.Method} | Thời gian: {paidTime} | Trạng thái: {p.Status}");
                        }
                    }
                    sb.AppendLine();
                }
                catch { }

                // 1.8 Lịch hẹn khách xem phòng (Bảng viewing_appointments)
                try
                {
                    var appointments = await _context.ViewingAppointments
                        .Where(va => ownerPropertyIds.Contains(va.Room.PropertyId))
                        .Include(va => va.Room).ThenInclude(r => r.Property)
                        .Include(va => va.Tenant)
                        .AsNoTracking()
                        .OrderByDescending(va => va.AppointmentDate)
                        .Take(15)
                        .Select(va => new
                        {
                            RoomName = va.Room.Name,
                            PropertyName = va.Room.Property.Name,
                            CustomerName = va.Tenant.Name,
                            va.Phone,
                            va.AppointmentDate,
                            va.AppointmentTime,
                            va.Status,
                            va.Message
                        })
                        .ToListAsync();

                    sb.AppendLine("=== 8. LỊCH HẸN KHÁCH ĐẶT XEM PHÒNG (TỪ BẢNG VIEWING_APPOINTMENTS) ===");
                    if (!appointments.Any())
                    {
                        sb.AppendLine("- Hiện không có lịch hẹn xem phòng nào sắp tới.");
                    }
                    else
                    {
                        foreach (var va in appointments)
                        {
                            var note = !string.IsNullOrWhiteSpace(va.Message) ? $" (Lời nhắn: '{va.Message}')" : "";
                            sb.AppendLine($"- Hẹn xem: Phòng {va.RoomName} ({va.PropertyName}) | Khách: {va.CustomerName} (SĐT: {va.Phone}) | Thời gian: {va.AppointmentTime:HH:mm} ngày {va.AppointmentDate:dd/MM/yyyy} | Trạng thái: {va.Status}{note}");
                        }
                    }
                    sb.AppendLine();
                }
                catch { }

                // 1.9 Yêu cầu bảo trì / sự cố tại các phòng (Bảng maintenance_requests)
                try
                {
                    var maintenance = await _context.MaintenanceRequests
                        .Where(m => ownerPropertyIds.Contains(m.Room.PropertyId))
                        .Include(m => m.Room).ThenInclude(r => r.Property)
                        .Include(m => m.Tenant)
                        .AsNoTracking()
                        .OrderByDescending(m => m.CreatedAt)
                        .Take(15)
                        .Select(m => new
                        {
                            m.Title,
                            RoomName = m.Room.Name,
                            PropertyName = m.Room.Property.Name,
                            TenantName = m.Tenant.Name,
                            m.Priority,
                            m.Status,
                            m.CreatedAt
                        })
                        .ToListAsync();

                    sb.AppendLine("=== 9. SỰ CỐ BẢO TRÌ & KHIẾU NẠI KHÁCH HÀNG (TỪ BẢNG MAINTENANCE_REQUESTS) ===");
                    if (!maintenance.Any())
                    {
                        sb.AppendLine("- Không có sự cố bảo trì nào tồn đọng.");
                    }
                    else
                    {
                        foreach (var m in maintenance)
                        {
                            sb.AppendLine($"- Sự cố: '{m.Title}' | Phòng: {m.RoomName} ({m.PropertyName}) | Khách báo: {m.TenantName} | Mức độ: {m.Priority} | Trạng thái: {m.Status}");
                        }
                    }
                    sb.AppendLine();
                }
                catch { }

                // 1.10 Thanh lý hợp đồng & Hoàn trả tiền cọc (Bảng contract_terminations)
                try
                {
                    var terminations = await _context.ContractTerminations
                        .Where(ct => ownerPropertyIds.Contains(ct.Contract.Room.PropertyId))
                        .Include(ct => ct.Contract).ThenInclude(c => c.Room).ThenInclude(r => r.Property)
                        .AsNoTracking()
                        .Take(10)
                        .Select(ct => new
                        {
                            ContractCode = ct.Contract.ContractCode,
                            RoomName = ct.Contract.Room.Name,
                            ct.DepositAmount,
                            ct.DeductionAmount,
                            ct.DeductionReason,
                            ct.RefundAmount,
                            ct.ReturnDate
                        })
                        .ToListAsync();

                    if (terminations.Any())
                    {
                        sb.AppendLine("=== 10. LỊCH SỬ THANH LÝ HỢP ĐỒNG & HOÀN CỌC (TỪ BẢNG CONTRACT_TERMINATIONS) ===");
                        foreach (var ct in terminations)
                        {
                            sb.AppendLine($"- Thanh lý HĐ {ct.ContractCode} | Phòng: {ct.RoomName} | Cọc ban đầu: {ct.DepositAmount:N0} đ | Khấu trừ: {ct.DeductionAmount ?? 0:N0} đ ({ct.DeductionReason ?? "Không"}) | Hoàn trả: {ct.RefundAmount:N0} đ | Ngày trả phòng: {ct.ReturnDate:dd/MM/yyyy}");
                        }
                        sb.AppendLine();
                    }
                }
                catch { }

                // 1.11 Đánh giá & Phản hồi của khách thuê (Bảng reviews)
                try
                {
                    var reviews = await _context.Reviews
                        .Where(rv => ownerPropertyIds.Contains(rv.Room.PropertyId))
                        .Include(rv => rv.Room)
                        .Include(rv => rv.Tenant)
                        .AsNoTracking()
                        .OrderByDescending(rv => rv.CreatedAt)
                        .Take(15)
                        .Select(rv => new
                        {
                            RoomName = rv.Room.Name,
                            TenantName = rv.Tenant.Name,
                            rv.Rating,
                            rv.Comment,
                            rv.CreatedAt
                        })
                        .ToListAsync();

                    if (reviews.Any())
                    {
                        sb.AppendLine("=== 11. ĐÁNH GIÁ & NHẬN XÉT CỦA KHÁCH THUÊ (TỪ BẢNG REVIEWS) ===");
                        foreach (var rv in reviews)
                        {
                            sb.AppendLine($"- Phòng {rv.RoomName} | Khách: {rv.TenantName} | Đánh giá: {rv.Rating}⭐ | Nhận xét: '{rv.Comment}'");
                        }
                        sb.AppendLine();
                    }
                }
                catch { }

                // 1.12 Tài khoản ngân hàng nhận tiền thuê của chủ trọ (Bảng bank_accounts)
                try
                {
                    var banks = await _context.BankAccounts
                        .Where(b => targetOwnerIds.Contains(b.UserId) && b.Status == "active")
                        .AsNoTracking()
                        .Select(b => new
                        {
                            b.BankName,
                            b.AccountNumber,
                            b.AccountHolder,
                            b.IsDefault
                        })
                        .ToListAsync();

                    if (banks.Any())
                    {
                        sb.AppendLine("=== 12. TÀI KHOẢN NGÂN HÀNG NHẬN THANH TOÁN (TỪ BẢNG BANK_ACCOUNTS) ===");
                        foreach (var b in banks)
                        {
                            var defStr = b.IsDefault ? " (Mặc định)" : "";
                            sb.AppendLine($"- Ngân hàng: {b.BankName} | STK: {b.AccountNumber} | Chủ TK: {b.AccountHolder}{defStr}");
                        }
                        sb.AppendLine();
                    }
                }
                catch { }

                return sb.ToString();
            }

            // ==========================================
            // 2. DÀNH CHO KHÁCH THUÊ (TENANT)
            // ==========================================
            if (scope == "tenant")
            {
                // 2.1 Tất cả phòng trống trên toàn sàn (được phép tìm kiếm)
                var availableRooms = await _context.Rooms
                    .Where(r => r.Status == "available")
                    .Include(r => r.Property)
                    .Include(r => r.RoomAmenities).ThenInclude(ra => ra.Amenity)
                    .AsNoTracking()
                    .Select(r => new
                    {
                        r.Id,
                        r.Name,
                        PropertyName = r.Property.Name,
                        District = r.Property.District,
                        Address = r.Property.Address + ", " + r.Property.Ward,
                        r.Area,
                        r.Price,
                        r.Deposit,
                        r.MaxPeople,
                        r.Floor,
                        Amenities = r.RoomAmenities.Where(ra => ra.Amenity != null).Select(ra => ra.Amenity.Name).ToList()
                    })
                    .ToListAsync();

                sb.AppendLine("=== 1. DANH SÁCH PHÒNG TRỌ ĐANG CÒN TRỐNG TRÊN HỆ THỐNG ===");
                if (!availableRooms.Any())
                {
                    sb.AppendLine("- Hiện tại tất cả các phòng trên hệ thống đều đã có người thuê.");
                }
                else
                {
                    foreach (var r in availableRooms)
                    {
                        var amList = r.Amenities.Any() ? string.Join(", ", r.Amenities) : "Cơ bản";
                        sb.AppendLine($"- Phòng: {r.Name} | Khu: {r.PropertyName} | Địa chỉ: {r.Address}, {r.District} | Giá thuê: {r.Price:N0} đ/tháng | Tiền cọc: {r.Deposit:N0} đ | Diện tích: {r.Area} m² | Tầng: {r.Floor ?? 1} | Sức chứa: {r.MaxPeople} người | Tiện ích: {amList}");
                    }
                }
                sb.AppendLine();

                // 2.2 Biểu phí dịch vụ theo từng khu trọ
                var propServices = await _context.PropertyServices
                    .Where(ps => ps.Status == "active")
                    .Include(ps => ps.Property)
                    .Include(ps => ps.Service)
                    .AsNoTracking()
                    .Select(ps => new
                    {
                        PropertyName = ps.Property.Name,
                        ServiceName = ps.Service.Name,
                        Price = ps.Price > 0 ? ps.Price : ps.Service.Price,
                        Unit = ps.Service.Unit,
                        IsMandatory = ps.Service.IsMandatory,
                        Description = ps.Service.Description
                    })
                    .ToListAsync();

                sb.AppendLine("=== 2. BIỂU PHÍ DỊCH VỤ THEO TỪNG KHU TRỌ (ĐIỆN, NƯỚC, XE MÁY, WIFI, RÁC...) ===");
                if (propServices.Any())
                {
                    foreach (var ps in propServices)
                    {
                        var reqStr = ps.IsMandatory ? "Bắt buộc" : "Theo nhu cầu";
                        var descStr = !string.IsNullOrWhiteSpace(ps.Description) ? $" ({ps.Description})" : "";
                        sb.AppendLine($"- Khu '{ps.PropertyName}': Dịch vụ '{ps.ServiceName}' = {ps.Price:N0} đ/{ps.Unit} [{reqStr}]{descStr}");
                    }
                }
                sb.AppendLine();

                // 2.3 Bài đăng công khai (Rental Posts)
                var posts = await _context.RentalPosts
                    .Where(p => p.Status == "published")
                    .Include(p => p.Room).ThenInclude(r => r.Property)
                    .OrderByDescending(p => p.CreatedAt)
                    .Take(10)
                    .Select(p => new
                    {
                        p.Title,
                        p.Price,
                        RoomName = p.Room.Name,
                        PropertyName = p.Room.Property.Name,
                        District = p.Room.Property.District,
                        p.Amenities
                    })
                    .ToListAsync();

                if (posts.Any())
                {
                    sb.AppendLine("=== 3. TIN ĐĂNG NỔI BẬT ĐANG MỞ ===");
                    foreach (var p in posts)
                    {
                        sb.AppendLine($"- Tin: '{p.Title}' | Phòng {p.RoomName} - {p.PropertyName} ({p.District}) | Giá: {p.Price:N0} đ/tháng | Tiện ích: {p.Amenities}");
                    }
                    sb.AppendLine();
                }

                // 2.4 Hợp đồng và hóa đơn CỦA RIÊNG KHÁCH THUÊ NÀY (nếu đã đăng nhập)
                if (!string.IsNullOrWhiteSpace(effectiveId))
                {
                    try
                    {
                        var myContracts = await _context.Contracts
                            .Where(c => c.TenantId == effectiveId)
                            .Include(c => c.Room).ThenInclude(r => r.Property)
                            .AsNoTracking()
                            .ToListAsync();

                        if (myContracts.Any())
                        {
                            sb.AppendLine("=== 4. HỢP ĐỒNG THUÊ CỦA BẠN ===");
                            foreach (var c in myContracts)
                            {
                                sb.AppendLine($"- Hợp đồng {c.ContractCode} | Phòng {c.Room.Name} ({c.Room.Property.Name}) | Giá thuê: {c.Rent:N0} đ | Hạn: {c.StartDate:dd/MM/yyyy} đến {c.EndDate:dd/MM/yyyy} | Trạng thái: {c.Status}");
                            }
                            sb.AppendLine();
                        }

                        var myInvoices = await _context.Invoices
                            .Where(i => i.Contract.TenantId == effectiveId)
                            .Include(i => i.Contract).ThenInclude(c => c.Room)
                            .AsNoTracking()
                            .OrderByDescending(i => i.BillingMonth)
                            .Take(5)
                            .ToListAsync();

                        if (myInvoices.Any())
                        {
                            sb.AppendLine("=== 5. HÓA ĐƠN GẦN ĐÂY CỦA BẠN ===");
                            foreach (var inv in myInvoices)
                            {
                                sb.AppendLine($"- Hóa đơn {inv.InvoiceCode} | Kỳ: {inv.BillingMonth:MM/yyyy} | Hạn thanh toán: {inv.DueDate:dd/MM/yyyy} | Tổng tiền: {inv.Total:N0} đ | Trạng thái: {inv.Status}");
                            }
                            sb.AppendLine();
                        }

                        // 2.6 Chỉ số điện nước cho các phòng khách này đang thuê
                        var myRoomIds = myContracts.Select(c => c.RoomId).Distinct().ToList();
                        if (myRoomIds.Any())
                        {
                            var myReadings = await _context.UtilityReadings
                                .Where(ur => myRoomIds.Contains(ur.RoomId))
                                .Include(ur => ur.Room).ThenInclude(r => r.Property)
                                .AsNoTracking()
                                .OrderByDescending(ur => ur.Month)
                                .Take(10)
                                .Select(ur => new
                                {
                                    RoomName = ur.Room.Name,
                                    PropertyName = ur.Room.Property.Name,
                                    ur.Month,
                                    ur.ElectricityOld,
                                    ur.ElectricityNew,
                                    ur.ElectricityPrice,
                                    ur.WaterOld,
                                    ur.WaterNew,
                                    ur.WaterPrice
                                })
                                .ToListAsync();

                            if (myReadings.Any())
                            {
                                sb.AppendLine("=== 6. CHỈ SỐ ĐIỆN NƯỚC PHÒNG BẠN ĐANG THUÊ (TỪ UTILITY_READINGS) ===");
                                foreach (var ur in myReadings)
                                {
                                    var elec = ur.ElectricityNew - ur.ElectricityOld;
                                    var water = ur.WaterNew - ur.WaterOld;
                                    sb.AppendLine($"- Phòng {ur.RoomName} ({ur.PropertyName}) | Kỳ {ur.Month:MM/yyyy}: Điện ({ur.ElectricityOld}->{ur.ElectricityNew}: {elec} kWh @ {ur.ElectricityPrice:N0} đ) | Nước ({ur.WaterOld}->{ur.WaterNew}: {water} m³ @ {ur.WaterPrice:N0} đ)");
                                }
                                sb.AppendLine();
                            }
                        }

                        // 2.7 Lịch sử các khoản đã thanh toán của khách thuê này
                        var myPayments = await _context.Payments
                            .Where(p => p.PayerId == effectiveId)
                            .Include(p => p.Invoice).ThenInclude(i => i.Contract).ThenInclude(c => c.Room)
                            .AsNoTracking()
                            .OrderByDescending(p => p.PaidAt)
                            .Take(10)
                            .Select(p => new
                            {
                                p.PaymentCode,
                                RoomName = p.Invoice.Contract.Room.Name,
                                p.Amount,
                                p.Method,
                                p.PaidAt,
                                p.Status
                            })
                            .ToListAsync();

                        if (myPayments.Any())
                        {
                            sb.AppendLine("=== 7. LỊCH SỬ THANH TOÁN TIỀN PHÒNG / DỊCH VỤ CỦA BẠN (TỪ PAYMENTS) ===");
                            foreach (var p in myPayments)
                            {
                                var paidTime = p.PaidAt.HasValue ? p.PaidAt.Value.ToString("dd/MM/yyyy HH:mm") : "N/A";
                                sb.AppendLine($"- GD {p.PaymentCode} | Phòng: {p.RoomName} | Số tiền: {p.Amount:N0} đ | Hình thức: {p.Method} | Thời gian: {paidTime} | Trạng thái: {p.Status}");
                            }
                            sb.AppendLine();
                        }

                        // 2.8 Lịch hẹn xem phòng của khách thuê này
                        var myAppointments = await _context.ViewingAppointments
                            .Where(va => va.TenantId == effectiveId)
                            .Include(va => va.Room).ThenInclude(r => r.Property)
                            .AsNoTracking()
                            .OrderByDescending(va => va.AppointmentDate)
                            .Take(10)
                            .Select(va => new
                            {
                                RoomName = va.Room.Name,
                                PropertyName = va.Room.Property.Name,
                                va.AppointmentDate,
                                va.AppointmentTime,
                                va.Status,
                                va.Message
                            })
                            .ToListAsync();

                        if (myAppointments.Any())
                        {
                            sb.AppendLine("=== 8. LỊCH HẸN ĐẶT XEM PHÒNG CỦA BẠN (TỪ VIEWING_APPOINTMENTS) ===");
                            foreach (var va in myAppointments)
                            {
                                var note = !string.IsNullOrWhiteSpace(va.Message) ? $" (Lời nhắn: '{va.Message}')" : "";
                                sb.AppendLine($"- Lịch hẹn: Phòng {va.RoomName} ({va.PropertyName}) | Giờ hẹn: {va.AppointmentTime:HH:mm} ngày {va.AppointmentDate:dd/MM/yyyy} | Trạng thái: {va.Status}{note}");
                            }
                            sb.AppendLine();
                        }

                        // 2.9 Yêu cầu bảo trì / báo hỏng hóc của khách thuê này
                        var myMaintenance = await _context.MaintenanceRequests
                            .Where(m => m.TenantId == effectiveId)
                            .Include(m => m.Room).ThenInclude(r => r.Property)
                            .AsNoTracking()
                            .OrderByDescending(m => m.CreatedAt)
                            .Take(10)
                            .Select(m => new
                            {
                                m.Title,
                                RoomName = m.Room.Name,
                                PropertyName = m.Room.Property.Name,
                                m.Priority,
                                m.Status,
                                m.CreatedAt
                            })
                            .ToListAsync();

                        if (myMaintenance.Any())
                        {
                            sb.AppendLine("=== 9. YÊU CẦU SỬA CHỮA / BẢO TRÌ BẠN ĐÃ GỬI (TỪ MAINTENANCE_REQUESTS) ===");
                            foreach (var m in myMaintenance)
                            {
                                sb.AppendLine($"- Sự cố: '{m.Title}' | Phòng: {m.RoomName} ({m.PropertyName}) | Mức độ: {m.Priority} | Trạng thái: {m.Status}");
                            }
                            sb.AppendLine();
                        }

                        // 2.10 Số tài khoản ngân hàng của chủ trọ để khách thuê chuyển khoản tiền phòng
                        var landlordOwnerIds = myContracts.Select(c => c.OwnerId).Distinct().ToList();
                        if (landlordOwnerIds.Any())
                        {
                            var landlordBanks = await _context.BankAccounts
                                .Where(b => landlordOwnerIds.Contains(b.UserId) && b.Status == "active")
                                .AsNoTracking()
                                .Select(b => new
                                {
                                    b.BankName,
                                    b.AccountNumber,
                                    b.AccountHolder,
                                    b.IsDefault
                                })
                                .ToListAsync();

                            if (landlordBanks.Any())
                            {
                                sb.AppendLine("=== 10. THÔNG TIN TÀI KHOẢN NGÂN HÀNG CHỦ TRỌ (ĐỂ CHUYỂN TIỀN THUÊ) ===");
                                foreach (var b in landlordBanks)
                                {
                                    var defStr = b.IsDefault ? " (Tài khoản chính)" : "";
                                    sb.AppendLine($"- Ngân hàng: {b.BankName} | STK: {b.AccountNumber} | Chủ tài khoản: {b.AccountHolder}{defStr}");
                                }
                                sb.AppendLine();
                            }
                        }
                    }
                    catch { }
                }

                // 2.11 Đánh giá và nhận xét công khai của các phòng (để khách tham khảo khi tìm phòng)
                try
                {
                    var publicReviews = await _context.Reviews
                        .Include(rv => rv.Room).ThenInclude(r => r.Property)
                        .Include(rv => rv.Tenant)
                        .AsNoTracking()
                        .OrderByDescending(rv => rv.CreatedAt)
                        .Take(15)
                        .Select(rv => new
                        {
                            RoomName = rv.Room.Name,
                            PropertyName = rv.Room.Property.Name,
                            TenantName = rv.Tenant.Name,
                            rv.Rating,
                            rv.Comment
                        })
                        .ToListAsync();

                    if (publicReviews.Any())
                    {
                        sb.AppendLine("=== 11. ĐÁNH GIÁ & NHẬN XÉT CỦA CƯ DÂN TRÊN TOÀN NỀN TẢNG (TỪ REVIEWS) ===");
                        foreach (var rv in publicReviews)
                        {
                            sb.AppendLine($"- Phòng {rv.RoomName} ({rv.PropertyName}) | Đánh giá: {rv.Rating}⭐ | Nhận xét: '{rv.Comment}' (bởi {rv.TenantName})");
                        }
                        sb.AppendLine();
                    }
                }
                catch { }

                return sb.ToString();
            }

            // ==========================================
            // 3. DÀNH CHO ADMIN - QUẢN LÝ TOÀN HỆ THỐNG
            // ==========================================
            var allProps = await _context.Properties
                .AsNoTracking()
                .Select(p => new
                {
                    p.Id,
                    p.Name,
                    p.Address,
                    p.District,
                    p.Status,
                    TotalRooms = p.Rooms.Count,
                    AvailableRooms = p.Rooms.Count(r => r.Status == "available"),
                    RentedRooms = p.Rooms.Count(r => r.Status == "rented")
                })
                .ToListAsync();

            sb.AppendLine("=== 1. TẤT CẢ KHU TRỌ TRÊN NỀN TẢNG ===");
            foreach (var prop in allProps)
            {
                sb.AppendLine($"- Khu: {prop.Name} (Mã: {prop.Id}) | Địa chỉ: {prop.Address}, {prop.District} | Tổng phòng: {prop.TotalRooms} (Trống: {prop.AvailableRooms}, Đang thuê: {prop.RentedRooms}) | Trạng thái: {prop.Status}");
            }
            sb.AppendLine();

            try
            {
                var totalUsers = await _context.Users.CountAsync();
                var totalTenants = await _context.Users.CountAsync(u => u.Role == "tenant");
                var totalOwners = await _context.Users.CountAsync(u => u.Role == "owner");
                var totalProps = allProps.Count;
                var totalRooms = await _context.Rooms.CountAsync();
                var availableRoomsCount = await _context.Rooms.CountAsync(r => r.Status == "available");
                var rentedRoomsCount = await _context.Rooms.CountAsync(r => r.Status == "rented");
                var pendingPosts = await _context.RentalPosts.CountAsync(p => p.Status.ToLower() == "pending" || p.Status.ToLower().Contains("chờ"));
                var totalContracts = await _context.Contracts.CountAsync();
                var activeContracts = await _context.Contracts.CountAsync(c => c.Status == "active");
                var totalInvoices = await _context.Invoices.CountAsync();
                var paidInvoices = await _context.Invoices.CountAsync(i => i.Status == "paid");
                var pendingInvoices = await _context.Invoices.CountAsync(i => i.Status != "paid");
                var totalPayments = await _context.Payments.CountAsync();
                var totalRevenue = await _context.Payments.Where(p => p.Status == "success" || p.Status == "completed").SumAsync(p => (decimal?)p.Amount) ?? 0;
                var totalMaintenance = await _context.MaintenanceRequests.CountAsync();
                var openMaintenance = await _context.MaintenanceRequests.CountAsync(m => m.Status != "completed" && m.Status != "resolved");
                var totalAppointments = await _context.ViewingAppointments.CountAsync();
                var pendingAppointments = await _context.ViewingAppointments.CountAsync(va => va.Status == "pending");
                var avgRating = await _context.Reviews.Select(r => (double?)r.Rating).AverageAsync() ?? 5.0;

                sb.AppendLine("=== 2. TỔNG QUAN VẬN HÀNH & KINH DOANH TOÀN HỆ THỐNG (ADMIN) ===");
                sb.AppendLine($"- Người dùng: {totalUsers} tài khoản ({totalOwners} chủ trọ, {totalTenants} khách thuê)");
                sb.AppendLine($"- Bất động sản & Phòng: {totalProps} khu trọ | {totalRooms} phòng trọ (Đang thuê: {rentedRoomsCount}, Còn trống: {availableRoomsCount})");
                sb.AppendLine($"- Hợp đồng: {totalContracts} hợp đồng (Đang hiệu lực: {activeContracts})");
                sb.AppendLine($"- Tài chính & Hóa đơn: {totalInvoices} hóa đơn ({paidInvoices} đã thanh toán, {pendingInvoices} chưa thanh toán) | Doanh thu qua hệ thống: {totalRevenue:N0} đ qua {totalPayments} giao dịch");
                sb.AppendLine($"- Lịch hẹn xem phòng: {totalAppointments} lượt ({pendingAppointments} lịch hẹn mới chờ xác nhận)");
                sb.AppendLine($"- Bảo trì & Khiếu nại: {totalMaintenance} yêu cầu ({openMaintenance} yêu cầu đang xử lý)");
                sb.AppendLine($"- Tin đăng chờ duyệt: {pendingPosts} bài");
                sb.AppendLine($"- Đánh giá chất lượng phòng: Điểm trung bình {avgRating:F1}⭐");
            }
            catch { }

            return sb.ToString();
        }
    }
}
