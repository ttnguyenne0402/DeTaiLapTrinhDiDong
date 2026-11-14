
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using System.Text;
using Backend.Models;
using Microsoft.OpenApi.Models;

var builder = WebApplication.CreateBuilder(args);

// 1. Đăng ký Database
builder.Services.AddDbContext<QuanLyPhongTroContext>(options =>
    options.UseSqlServer(
        builder.Configuration.GetConnectionString("DefaultConnection")));

// 2. Đăng ký Repositories Đặt lịch và Hợp đồng
builder.Services.AddScoped<Backend.Repositories.IViewingAppointmentRepository,
    Backend.Repositories.ViewingAppointmentRepository>();

builder.Services.AddScoped<Backend.Repositories.IContractRepository,
    Backend.Repositories.ContractRepository>();

// 3. Đăng ký Services Đặt lịch và Hợp đồng
builder.Services.AddScoped<Backend.Services.IViewingAppointmentService,
    Backend.Services.ViewingAppointmentService>();

builder.Services.AddScoped<Backend.Services.IContractService,
    Backend.Services.ContractService>();

// 4. Đăng ký Repositories Hóa đơn và Thanh toán
builder.Services.AddScoped<Backend.Repositories.IInvoiceRepository,
    Backend.Repositories.InvoiceRepository>();

builder.Services.AddScoped<Backend.Repositories.IPaymentRepository,
    Backend.Repositories.PaymentRepository>();

// 5. Đăng ký Services Hóa đơn và Thanh toán
builder.Services.AddScoped<Backend.Services.IInvoiceService,
    Backend.Services.InvoiceService>();

builder.Services.AddScoped<Backend.Services.IPaymentService,
    Backend.Services.PaymentService>();

// 6. Đăng ký Repositories Thông báo và Sửa chữa
builder.Services.AddScoped<Backend.Repositories.INotificationRepository,
    Backend.Repositories.NotificationRepository>();

builder.Services.AddScoped<Backend.Repositories.IMaintenanceRequestRepository,
    Backend.Repositories.MaintenanceRequestRepository>();

// 7. Đăng ký Services Thông báo và Sửa chữa
builder.Services.AddScoped<Backend.Services.INotificationService,
    Backend.Services.NotificationService>();

builder.Services.AddScoped<Backend.Services.IMaintenanceService,
    Backend.Services.MaintenanceService>();

// 8. Đăng ký HttpClient
builder.Services.AddHttpClient();

// 9. Cấu hình JWT
var jwtKey = builder.Configuration["Jwt:Key"];
var jwtIssuer = builder.Configuration["Jwt:Issuer"];
var jwtAudience = builder.Configuration["Jwt:Audience"];

if (string.IsNullOrWhiteSpace(jwtKey) ||
    Encoding.UTF8.GetByteCount(jwtKey) < 32 ||
    string.IsNullOrWhiteSpace(jwtIssuer) ||
    string.IsNullOrWhiteSpace(jwtAudience))
{
    throw new InvalidOperationException(
        "Cấu hình JWT không hợp lệ. Kiểm tra Jwt:Key, Jwt:Issuer và Jwt:Audience trong cấu hình.");
}

builder.Services
    .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidIssuer = jwtIssuer,

            ValidateAudience = true,
            ValidAudience = jwtAudience,

            ValidateLifetime = true,

            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new SymmetricSecurityKey(
                Encoding.UTF8.GetBytes(jwtKey)),

            ClockSkew = TimeSpan.FromSeconds(30)
        };
    });

// 10. Đăng ký Authorization
builder.Services.AddAuthorization();

// 11. Cấu hình CORS
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

// 12. Đăng ký Controllers và Swagger
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();

builder.Services.AddSwaggerGen(options =>
{
    options.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = SecuritySchemeType.Http,
        Scheme = "bearer",
        BearerFormat = "JWT",
        In = ParameterLocation.Header,
        Description = "Nhập JWT token để xác thực."
    });

    options.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            Array.Empty<string>()
        }
    });
});

var app = builder.Build();

// 13. Cấu hình Swagger
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

// app.UseHttpsRedirection();

// 14. Middleware CORS
app.UseCors("AllowAll");

// 15. Xác thực JWT và phân quyền
app.UseAuthentication();
app.UseAuthorization();

// 16. Map Controllers
app.MapControllers();

app.Run();
