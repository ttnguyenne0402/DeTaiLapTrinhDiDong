var builder = WebApplication.CreateBuilder(args);

// Add services to the container.

builder.Services.AddControllers();
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// 1. ĐĂNG KÝ DATABASE CONTEXT 
builder.Services.AddDbContext<Backend.Models.QuanLyPhongTroContext>();


// 2. Đăng ký Repositories
builder.Services.AddScoped<Backend.Repositories.IViewingAppointmentRepository, Backend.Repositories.ViewingAppointmentRepository>();
builder.Services.AddScoped<Backend.Repositories.IContractRepository, Backend.Repositories.ContractRepository>();

// 3. Đăng ký Services
builder.Services.AddScoped<Backend.Services.IViewingAppointmentService, Backend.Services.ViewingAppointmentService>();
builder.Services.AddScoped<Backend.Services.IContractService, Backend.Services.ContractService>();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

app.UseAuthorization();

app.MapControllers();

app.Run();
