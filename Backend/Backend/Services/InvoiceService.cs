using Backend.DTOs;
using Backend.Repositories;
using Backend.Helpers;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace Backend.Services
{
    public class InvoiceService : IInvoiceService
    {
        private readonly IInvoiceRepository _repository;

        public InvoiceService(IInvoiceRepository repository)
        {
            _repository = repository;
        }

        public async Task<IEnumerable<InvoiceResponseDTO>> GetTenantInvoicesAsync(string tenantId)
        {
            var invoices = await _repository.GetByTenantIdAsync(tenantId);
            return invoices.Select(i => new InvoiceResponseDTO
            {
                Id = i.Id,
                InvoiceCode = i.InvoiceCode,
                BillingMonth = i.BillingMonth.ToString("MM/yyyy"), 
                IssueDate = i.IssueDate.ToString("dd/MM/yyyy"),
                DueDate = i.DueDate.ToString("dd/MM/yyyy"),
                Subtotal = i.Subtotal,
                Discount = i.Discount ?? 0,
                Total = i.Total,
                Status = i.Status
            });
        }

        public async Task<InvoiceResponseDTO?> GetInvoiceDetailAsync(string id)
        {
            var invoice = await _repository.GetByIdAsync(id);
            if (invoice == null) return null;

            var bank = invoice.BankAccount;
            var bankBelongsToOwner = bank != null && invoice.Contract != null &&
                OwnerHelper.ResolveOwnerIds(bank.UserId).Contains(invoice.Contract.OwnerId, StringComparer.OrdinalIgnoreCase);

            return new InvoiceResponseDTO
            {
                Id = invoice.Id,
                InvoiceCode = invoice.InvoiceCode,
                BillingMonth = invoice.BillingMonth.ToString("MM/yyyy"),
                IssueDate = invoice.IssueDate.ToString("dd/MM/yyyy"),
                DueDate = invoice.DueDate.ToString("dd/MM/yyyy"),
                Subtotal = invoice.Subtotal,
                Discount = invoice.Discount ?? 0,
                Total = invoice.Total,
                Status = invoice.Status,
                BankAccount = bankBelongsToOwner && bank != null ? new BankAccountInfoDto
                {
                    BankCode = bank.BankCode,
                    BankName = bank.BankName,
                    AccountNumber = bank.AccountNumber,
                    AccountHolder = bank.AccountHolder
                } : null,
                Items = invoice.InvoiceItems.Select(item => new InvoiceItemDTO
                {
                    Type = item.Type,
                    Description = item.Description,
                    Quantity = item.Quantity ?? 1,
                    UnitPrice = item.UnitPrice,
                    Amount = item.Amount
                }).ToList()
            };
        }
    }
}
