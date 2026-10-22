
﻿using Microsoft.EntityFrameworkCore;
using Backend.Models;// Namespace chứa QuanLyPhongTroContext
var builder = WebApplication.CreateBuilder(args);
// Add services to the container.

builder.Services.AddDbContext<QuanLyPhongTroContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));
// ----------------------------------------

builder.Services.AddControllers();
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// 1. ĐĂNG KÝ DATABASE CONTEXT 
builder.Services.AddDbContext<Backend.Models.QuanLyPhongTroContext>();


// 2. Đăng ký Repositories Đặt lịch và hợp đồng
builder.Services.AddScoped<Backend.Repositories.IViewingAppointmentRepository, Backend.Repositories.ViewingAppointmentRepository>();
builder.Services.AddScoped<Backend.Repositories.IContractRepository, Backend.Repositories.ContractRepository>();

// 3. Đăng ký Services Đặt lịch và hợp đồng
builder.Services.AddScoped<Backend.Services.IViewingAppointmentService, Backend.Services.ViewingAppointmentService>();
builder.Services.AddScoped<Backend.Services.IContractService, Backend.Services.ContractService>();

// Đăng ký Repositories Hóa đơn và thanh toán
builder.Services.AddScoped<Backend.Repositories.IInvoiceRepository, Backend.Repositories.InvoiceRepository>();
builder.Services.AddScoped<Backend.Repositories.IPaymentRepository, Backend.Repositories.PaymentRepository>();

// Đăng ký Services Hóa đơn và thanh toán
builder.Services.AddScoped<Backend.Services.IInvoiceService, Backend.Services.InvoiceService>();
builder.Services.AddScoped<Backend.Services.IPaymentService, Backend.Services.PaymentService>();

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

//app.UseHttpsRedirection();

app.UseAuthorization();

app.MapControllers();

app.Run();