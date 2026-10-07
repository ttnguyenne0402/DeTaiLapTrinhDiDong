using System;
using System.Collections.Generic;
using Microsoft.EntityFrameworkCore;

namespace Backend.Models;

public partial class QuanLyPhongTroContext : DbContext
{
    public QuanLyPhongTroContext()
    {
    }

    public QuanLyPhongTroContext(DbContextOptions<QuanLyPhongTroContext> options)
        : base(options)
    {
    }

    public virtual DbSet<Amenity> Amenities { get; set; }

    public virtual DbSet<BankAccount> BankAccounts { get; set; }

    public virtual DbSet<Contract> Contracts { get; set; }

    public virtual DbSet<ContractMember> ContractMembers { get; set; }

    public virtual DbSet<ContractService> ContractServices { get; set; }

    public virtual DbSet<ContractTermination> ContractTerminations { get; set; }

    public virtual DbSet<Favorite> Favorites { get; set; }

    public virtual DbSet<Invoice> Invoices { get; set; }

    public virtual DbSet<InvoiceItem> InvoiceItems { get; set; }

    public virtual DbSet<MaintenanceRequest> MaintenanceRequests { get; set; }

    public virtual DbSet<Notification> Notifications { get; set; }

    public virtual DbSet<Payment> Payments { get; set; }

    public virtual DbSet<Property> Properties { get; set; }

    public virtual DbSet<PropertyService> PropertyServices { get; set; }

    public virtual DbSet<RentalPost> RentalPosts { get; set; }

    public virtual DbSet<RentalPostImage> RentalPostImages { get; set; }

    public virtual DbSet<Review> Reviews { get; set; }

    public virtual DbSet<Room> Rooms { get; set; }

    public virtual DbSet<RoomAmenity> RoomAmenities { get; set; }

    public virtual DbSet<Service> Services { get; set; }

    public virtual DbSet<User> Users { get; set; }

    public virtual DbSet<UtilityReading> UtilityReadings { get; set; }

    public virtual DbSet<ViewingAppointment> ViewingAppointments { get; set; }

    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
#warning To protect potentially sensitive information in your connection string, you should move it out of source code. You can avoid scaffolding the connection string by using the Name= syntax to read it from configuration - see https://go.microsoft.com/fwlink/?linkid=2131148. For more guidance on storing connection strings, see https://go.microsoft.com/fwlink/?LinkId=723263.
        => optionsBuilder.UseSqlServer("Server=localhost;Database=QuanLyPhongTro;User Id=sa;Password=123;TrustServerCertificate=True;");

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Amenity>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__amenitie__3213E83F85201038");

            entity.ToTable("amenities");

            entity.HasIndex(e => e.Name, "UQ__amenitie__72E12F1B40057EC4").IsUnique();

            entity.Property(e => e.Id)
                .HasMaxLength(50)
                .HasColumnName("id");
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnName("created_at");
            entity.Property(e => e.Description).HasColumnName("description");
            entity.Property(e => e.Name)
                .HasMaxLength(100)
                .HasColumnName("name");
            entity.Property(e => e.Status)
                .HasMaxLength(50)
                .HasColumnName("status");
            entity.Property(e => e.UpdatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnName("updated_at");
        });

        modelBuilder.Entity<BankAccount>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__bank_acc__3213E83F2ABB9E3B");

            entity.ToTable("bank_accounts");

            entity.Property(e => e.Id)
                .HasMaxLength(50)
                .HasColumnName("id");
            entity.Property(e => e.AccountHolder)
                .HasMaxLength(100)
                .HasColumnName("account_holder");
            entity.Property(e => e.AccountNumber)
                .HasMaxLength(30)
                .HasColumnName("account_number");
            entity.Property(e => e.BankCode)
                .HasMaxLength(20)
                .HasColumnName("bank_code");
            entity.Property(e => e.BankName)
                .HasMaxLength(100)
                .HasColumnName("bank_name");
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnName("created_at");
            entity.Property(e => e.IsDefault).HasColumnName("is_default");
            entity.Property(e => e.Status)
                .HasMaxLength(50)
                .HasColumnName("status");
            entity.Property(e => e.UpdatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnName("updated_at");
            entity.Property(e => e.UserId)
                .HasMaxLength(50)
                .HasColumnName("user_id");

            entity.HasOne(d => d.User).WithMany(p => p.BankAccounts)
                .HasForeignKey(d => d.UserId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_bank_accounts_users");
        });

        modelBuilder.Entity<Contract>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__contract__3213E83FF803B7CF");

            entity.ToTable("contracts");

            entity.HasIndex(e => e.ContractCode, "UQ__contract__68CFBDBAFDFFCBE5").IsUnique();

            entity.Property(e => e.Id)
                .HasMaxLength(50)
                .HasColumnName("id");
            entity.Property(e => e.ContractCode)
                .HasMaxLength(50)
                .HasColumnName("contract_code");
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnName("created_at");
            entity.Property(e => e.Deposit)
                .HasColumnType("decimal(15, 2)")
                .HasColumnName("deposit");
            entity.Property(e => e.EndDate).HasColumnName("end_date");
            entity.Property(e => e.InitialElectricityReading)
                .HasColumnType("decimal(10, 2)")
                .HasColumnName("initial_electricity_reading");
            entity.Property(e => e.InitialWaterReading)
                .HasColumnType("decimal(10, 2)")
                .HasColumnName("initial_water_reading");
            entity.Property(e => e.OwnerId)
                .HasMaxLength(50)
                .HasColumnName("owner_id");
            entity.Property(e => e.PaymentCycle)
                .HasMaxLength(50)
                .HasColumnName("payment_cycle");
            entity.Property(e => e.Rent)
                .HasColumnType("decimal(15, 2)")
                .HasColumnName("rent");
            entity.Property(e => e.RoomId)
                .HasMaxLength(50)
                .HasColumnName("room_id");
            entity.Property(e => e.SignedAt).HasColumnName("signed_at");
            entity.Property(e => e.StartDate).HasColumnName("start_date");
            entity.Property(e => e.Status)
                .HasMaxLength(50)
                .HasColumnName("status");
            entity.Property(e => e.TenantId)
                .HasMaxLength(50)
                .HasColumnName("tenant_id");
            entity.Property(e => e.TerminatedAt).HasColumnName("terminated_at");
            entity.Property(e => e.Terms).HasColumnName("terms");
            entity.Property(e => e.UpdatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnName("updated_at");
            entity.Property(e => e.ViewingAppointmentId)
                .HasMaxLength(50)
                .HasColumnName("viewing_appointment_id");

            entity.HasOne(d => d.Owner).WithMany(p => p.ContractOwners)
                .HasForeignKey(d => d.OwnerId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_contracts_owner");

            entity.HasOne(d => d.Room).WithMany(p => p.Contracts)
                .HasForeignKey(d => d.RoomId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_contracts_rooms");

            entity.HasOne(d => d.Tenant).WithMany(p => p.ContractTenants)
                .HasForeignKey(d => d.TenantId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_contracts_tenant");

            entity.HasOne(d => d.ViewingAppointment).WithMany(p => p.Contracts)
                .HasForeignKey(d => d.ViewingAppointmentId)
                .HasConstraintName("FK_contracts_appointments");
        });

        modelBuilder.Entity<ContractMember>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__contract__3213E83FD19CD238");

            entity.ToTable("contract_members");

            entity.Property(e => e.Id)
                .HasMaxLength(50)
                .HasColumnName("id");
            entity.Property(e => e.ContractId)
                .HasMaxLength(50)
                .HasColumnName("contract_id");
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnName("created_at");
            entity.Property(e => e.IdentityCard)
                .HasMaxLength(20)
                .HasColumnName("identity_card");
            entity.Property(e => e.Name)
                .HasMaxLength(100)
                .HasColumnName("name");
            entity.Property(e => e.Phone)
                .HasMaxLength(20)
                .HasColumnName("phone");
            entity.Property(e => e.Relationship)
                .HasMaxLength(50)
                .HasColumnName("relationship");
            entity.Property(e => e.UpdatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnName("updated_at");

            entity.HasOne(d => d.Contract).WithMany(p => p.ContractMembers)
                .HasForeignKey(d => d.ContractId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_contract_members_contracts");
        });

        modelBuilder.Entity<ContractService>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__contract__3213E83F9F4FEE70");

            entity.ToTable("contract_services");

            entity.Property(e => e.Id)
                .HasMaxLength(50)
                .HasColumnName("id");
            entity.Property(e => e.ContractId)
                .HasMaxLength(50)
                .HasColumnName("contract_id");
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnName("created_at");
            entity.Property(e => e.Quantity)
                .HasDefaultValue(1m)
                .HasColumnType("decimal(10, 2)")
                .HasColumnName("quantity");
            entity.Property(e => e.ServiceId)
                .HasMaxLength(50)
                .HasColumnName("service_id");
            entity.Property(e => e.Status)
                .HasMaxLength(50)
                .HasColumnName("status");
            entity.Property(e => e.UnitPrice)
                .HasColumnType("decimal(15, 2)")
                .HasColumnName("unit_price");
            entity.Property(e => e.UpdatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnName("updated_at");

            entity.HasOne(d => d.Contract).WithMany(p => p.ContractServices)
                .HasForeignKey(d => d.ContractId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_contract_services_contracts");

            entity.HasOne(d => d.Service).WithMany(p => p.ContractServices)
                .HasForeignKey(d => d.ServiceId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_contract_services_services");
        });

        modelBuilder.Entity<ContractTermination>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__contract__3213E83F8868A1F0");

            entity.ToTable("contract_terminations");

            entity.Property(e => e.Id)
                .HasMaxLength(50)
                .HasColumnName("id");
            entity.Property(e => e.ContractId)
                .HasMaxLength(50)
                .HasColumnName("contract_id");
            entity.Property(e => e.DeductionAmount)
                .HasDefaultValue(0m)
                .HasColumnType("decimal(15, 2)")
                .HasColumnName("deduction_amount");
            entity.Property(e => e.DeductionReason).HasColumnName("deduction_reason");
            entity.Property(e => e.DepositAmount)
                .HasColumnType("decimal(15, 2)")
                .HasColumnName("deposit_amount");
            entity.Property(e => e.Note).HasColumnName("note");
            entity.Property(e => e.RefundAmount)
                .HasColumnType("decimal(15, 2)")
                .HasColumnName("refund_amount");
            entity.Property(e => e.ReturnDate).HasColumnName("return_date");

            entity.HasOne(d => d.Contract).WithMany(p => p.ContractTerminations)
                .HasForeignKey(d => d.ContractId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_terminations_contracts");
        });

        modelBuilder.Entity<Favorite>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__favorite__3213E83FEB8CD865");

            entity.ToTable("favorites");

            entity.Property(e => e.Id)
                .HasMaxLength(50)
                .HasColumnName("id");
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnName("created_at");
            entity.Property(e => e.RoomId)
                .HasMaxLength(50)
                .HasColumnName("room_id");
            entity.Property(e => e.UpdatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnName("updated_at");
            entity.Property(e => e.UserId)
                .HasMaxLength(50)
                .HasColumnName("user_id");

            entity.HasOne(d => d.Room).WithMany(p => p.Favorites)
                .HasForeignKey(d => d.RoomId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_favorites_rooms");

            entity.HasOne(d => d.User).WithMany(p => p.Favorites)
                .HasForeignKey(d => d.UserId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_favorites_users");
        });

        modelBuilder.Entity<Invoice>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__invoices__3213E83F8296A1A4");

            entity.ToTable("invoices");

            entity.HasIndex(e => e.InvoiceCode, "UQ__invoices__5ED70A3517DF05F6").IsUnique();

            entity.Property(e => e.Id)
                .HasMaxLength(50)
                .HasColumnName("id");
            entity.Property(e => e.BillingMonth).HasColumnName("billing_month");
            entity.Property(e => e.ContractId)
                .HasMaxLength(50)
                .HasColumnName("contract_id");
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnName("created_at");
            entity.Property(e => e.Discount)
                .HasDefaultValue(0m)
                .HasColumnType("decimal(15, 2)")
                .HasColumnName("discount");
            entity.Property(e => e.DueDate).HasColumnName("due_date");
            entity.Property(e => e.InvoiceCode)
                .HasMaxLength(50)
                .HasColumnName("invoice_code");
            entity.Property(e => e.IssueDate).HasColumnName("issue_date");
            entity.Property(e => e.Status)
                .HasMaxLength(50)
                .HasColumnName("status");
            entity.Property(e => e.Subtotal)
                .HasColumnType("decimal(15, 2)")
                .HasColumnName("subtotal");
            entity.Property(e => e.Total)
                .HasColumnType("decimal(15, 2)")
                .HasColumnName("total");
            entity.Property(e => e.UpdatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnName("updated_at");
            entity.Property(e => e.UtilityReadingId)
                .HasMaxLength(50)
                .HasColumnName("utility_reading_id");

            entity.HasOne(d => d.Contract).WithMany(p => p.Invoices)
                .HasForeignKey(d => d.ContractId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_invoices_contracts");

            entity.HasOne(d => d.UtilityReading).WithMany(p => p.Invoices)
                .HasForeignKey(d => d.UtilityReadingId)
                .HasConstraintName("FK_invoices_readings");
        });

        modelBuilder.Entity<InvoiceItem>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__invoice___3213E83F55F30A73");

            entity.ToTable("invoice_items");

            entity.Property(e => e.Id)
                .HasMaxLength(50)
                .HasColumnName("id");
            entity.Property(e => e.Amount)
                .HasColumnType("decimal(15, 2)")
                .HasColumnName("amount");
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnName("created_at");
            entity.Property(e => e.Description)
                .HasMaxLength(255)
                .HasColumnName("description");
            entity.Property(e => e.InvoiceId)
                .HasMaxLength(50)
                .HasColumnName("invoice_id");
            entity.Property(e => e.Quantity)
                .HasDefaultValue(1m)
                .HasColumnType("decimal(10, 2)")
                .HasColumnName("quantity");
            entity.Property(e => e.ServiceId)
                .HasMaxLength(50)
                .HasColumnName("service_id");
            entity.Property(e => e.Type)
                .HasMaxLength(50)
                .HasColumnName("type");
            entity.Property(e => e.UnitPrice)
                .HasColumnType("decimal(15, 2)")
                .HasColumnName("unit_price");
            entity.Property(e => e.UpdatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnName("updated_at");

            entity.HasOne(d => d.Invoice).WithMany(p => p.InvoiceItems)
                .HasForeignKey(d => d.InvoiceId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_invoice_items_invoices");

            entity.HasOne(d => d.Service).WithMany(p => p.InvoiceItems)
                .HasForeignKey(d => d.ServiceId)
                .HasConstraintName("FK_invoice_items_services");
        });

        modelBuilder.Entity<MaintenanceRequest>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__maintena__3213E83F7E8317F9");

            entity.ToTable("maintenance_requests");

            entity.Property(e => e.Id)
                .HasMaxLength(50)
                .HasColumnName("id");
            entity.Property(e => e.CompletedAt).HasColumnName("completed_at");
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnName("created_at");
            entity.Property(e => e.Description).HasColumnName("description");
            entity.Property(e => e.Image)
                .HasMaxLength(255)
                .HasColumnName("image");
            entity.Property(e => e.OwnerNote).HasColumnName("owner_note");
            entity.Property(e => e.Priority)
                .HasMaxLength(50)
                .HasColumnName("priority");
            entity.Property(e => e.RoomId)
                .HasMaxLength(50)
                .HasColumnName("room_id");
            entity.Property(e => e.Status)
                .HasMaxLength(50)
                .HasColumnName("status");
            entity.Property(e => e.TenantId)
                .HasMaxLength(50)
                .HasColumnName("tenant_id");
            entity.Property(e => e.Title)
                .HasMaxLength(200)
                .HasColumnName("title");
            entity.Property(e => e.UpdatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnName("updated_at");

            entity.HasOne(d => d.Room).WithMany(p => p.MaintenanceRequests)
                .HasForeignKey(d => d.RoomId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_maintenance_rooms");

            entity.HasOne(d => d.Tenant).WithMany(p => p.MaintenanceRequests)
                .HasForeignKey(d => d.TenantId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_maintenance_users");
        });

        modelBuilder.Entity<Notification>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__notifica__3213E83F6DBA477B");

            entity.ToTable("notifications");

            entity.Property(e => e.Id)
                .HasMaxLength(50)
                .HasColumnName("id");
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnName("created_at");
            entity.Property(e => e.Message).HasColumnName("message");
            entity.Property(e => e.ReadAt).HasColumnName("read_at");
            entity.Property(e => e.ReferenceId)
                .HasMaxLength(50)
                .HasColumnName("reference_id");
            entity.Property(e => e.ReferenceType)
                .HasMaxLength(50)
                .HasColumnName("reference_type");
            entity.Property(e => e.Title)
                .HasMaxLength(200)
                .HasColumnName("title");
            entity.Property(e => e.Type)
                .HasMaxLength(50)
                .HasColumnName("type");
            entity.Property(e => e.UpdatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnName("updated_at");
            entity.Property(e => e.UserId)
                .HasMaxLength(50)
                .HasColumnName("user_id");

            entity.HasOne(d => d.User).WithMany(p => p.Notifications)
                .HasForeignKey(d => d.UserId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_notifications_users");
        });

        modelBuilder.Entity<Payment>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__payments__3213E83F4B093E61");

            entity.ToTable("payments");

            entity.HasIndex(e => e.PaymentCode, "UQ__payments__7234C6E3DB927A26").IsUnique();

            entity.Property(e => e.Id)
                .HasMaxLength(50)
                .HasColumnName("id");
            entity.Property(e => e.Amount)
                .HasColumnType("decimal(15, 2)")
                .HasColumnName("amount");
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnName("created_at");
            entity.Property(e => e.InvoiceId)
                .HasMaxLength(50)
                .HasColumnName("invoice_id");
            entity.Property(e => e.Method)
                .HasMaxLength(50)
                .HasColumnName("method");
            entity.Property(e => e.PaidAt).HasColumnName("paid_at");
            entity.Property(e => e.PayerId)
                .HasMaxLength(50)
                .HasColumnName("payer_id");
            entity.Property(e => e.PaymentCode)
                .HasMaxLength(50)
                .HasColumnName("payment_code");
            entity.Property(e => e.Status)
                .HasMaxLength(50)
                .HasColumnName("status");
            entity.Property(e => e.TransactionCode)
                .HasMaxLength(100)
                .HasColumnName("transaction_code");
            entity.Property(e => e.UpdatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnName("updated_at");

            entity.HasOne(d => d.Invoice).WithMany(p => p.Payments)
                .HasForeignKey(d => d.InvoiceId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_payments_invoices");

            entity.HasOne(d => d.Payer).WithMany(p => p.Payments)
                .HasForeignKey(d => d.PayerId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_payments_users");
        });

        modelBuilder.Entity<Property>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__properti__3213E83FA2B3631B");

            entity.ToTable("properties");

            entity.Property(e => e.Id)
                .HasMaxLength(50)
                .HasColumnName("id");
            entity.Property(e => e.Address)
                .HasMaxLength(255)
                .HasColumnName("address");
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnName("created_at");
            entity.Property(e => e.Description).HasColumnName("description");
            entity.Property(e => e.District)
                .HasMaxLength(100)
                .HasColumnName("district");
            entity.Property(e => e.Latitude)
                .HasColumnType("decimal(10, 7)")
                .HasColumnName("latitude");
            entity.Property(e => e.Longitude)
                .HasColumnType("decimal(10, 7)")
                .HasColumnName("longitude");
            entity.Property(e => e.Name)
                .HasMaxLength(150)
                .HasColumnName("name");
            entity.Property(e => e.OwnerId)
                .HasMaxLength(50)
                .HasColumnName("owner_id");
            entity.Property(e => e.Status)
                .HasMaxLength(50)
                .HasColumnName("status");
            entity.Property(e => e.Type)
                .HasMaxLength(50)
                .HasColumnName("type");
            entity.Property(e => e.UpdatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnName("updated_at");
            entity.Property(e => e.Ward)
                .HasMaxLength(100)
                .HasColumnName("ward");

            entity.HasOne(d => d.Owner).WithMany(p => p.Properties)
                .HasForeignKey(d => d.OwnerId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_properties_users");
        });

        modelBuilder.Entity<PropertyService>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__property__3213E83F5D07EB91");

            entity.ToTable("property_services");

            entity.Property(e => e.Id)
                .HasMaxLength(50)
                .HasColumnName("id");
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnName("created_at");
            entity.Property(e => e.Price)
                .HasColumnType("decimal(15, 2)")
                .HasColumnName("price");
            entity.Property(e => e.PropertyId)
                .HasMaxLength(50)
                .HasColumnName("property_id");
            entity.Property(e => e.ServiceId)
                .HasMaxLength(50)
                .HasColumnName("service_id");
            entity.Property(e => e.Status)
                .HasMaxLength(50)
                .HasColumnName("status");
            entity.Property(e => e.UpdatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnName("updated_at");

            entity.HasOne(d => d.Property).WithMany(p => p.PropertyServices)
                .HasForeignKey(d => d.PropertyId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_property_services_properties");

            entity.HasOne(d => d.Service).WithMany(p => p.PropertyServices)
                .HasForeignKey(d => d.ServiceId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_property_services_services");
        });

        modelBuilder.Entity<RentalPost>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__rental_p__3213E83FA1BF58AF");

            entity.ToTable("rental_posts");

            entity.Property(e => e.Id)
                .HasMaxLength(50)
                .HasColumnName("id");
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnName("created_at");
            entity.Property(e => e.Description).HasColumnName("description");
            entity.Property(e => e.ExpiredAt).HasColumnName("expired_at");
            entity.Property(e => e.PublishedAt).HasColumnName("published_at");
            entity.Property(e => e.RejectionReason).HasColumnName("rejection_reason");
            entity.Property(e => e.RoomId)
                .HasMaxLength(50)
                .HasColumnName("room_id");
            entity.Property(e => e.Status)
                .HasMaxLength(50)
                .HasColumnName("status");
            entity.Property(e => e.Title)
                .HasMaxLength(200)
                .HasColumnName("title");
            entity.Property(e => e.UpdatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnName("updated_at");

            entity.HasOne(d => d.Room).WithMany(p => p.RentalPosts)
                .HasForeignKey(d => d.RoomId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_rental_posts_rooms");
        });

        modelBuilder.Entity<RentalPostImage>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__rental_p__3213E83F0897CD3D");

            entity.ToTable("rental_post_images");

            entity.Property(e => e.Id)
                .HasMaxLength(50)
                .HasColumnName("id");
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnName("created_at");
            entity.Property(e => e.ImagePath)
                .HasMaxLength(255)
                .HasColumnName("image_path");
            entity.Property(e => e.IsThumbnail)
                .HasDefaultValue(false)
                .HasColumnName("is_thumbnail");
            entity.Property(e => e.RentalPostId)
                .HasMaxLength(50)
                .HasColumnName("rental_post_id");
            entity.Property(e => e.SortOrder)
                .HasDefaultValue(0)
                .HasColumnName("sort_order");
            entity.Property(e => e.UpdatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnName("updated_at");

            entity.HasOne(d => d.RentalPost).WithMany(p => p.RentalPostImages)
                .HasForeignKey(d => d.RentalPostId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_rental_post_images_posts");
        });

        modelBuilder.Entity<Review>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__reviews__3213E83F350D0BAF");

            entity.ToTable("reviews");

            entity.Property(e => e.Id)
                .HasMaxLength(50)
                .HasColumnName("id");
            entity.Property(e => e.Comment).HasColumnName("comment");
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnName("created_at");
            entity.Property(e => e.Rating).HasColumnName("rating");
            entity.Property(e => e.RoomId)
                .HasMaxLength(50)
                .HasColumnName("room_id");
            entity.Property(e => e.Status)
                .HasMaxLength(50)
                .HasColumnName("status");
            entity.Property(e => e.TenantId)
                .HasMaxLength(50)
                .HasColumnName("tenant_id");
            entity.Property(e => e.UpdatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnName("updated_at");

            entity.HasOne(d => d.Room).WithMany(p => p.Reviews)
                .HasForeignKey(d => d.RoomId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_reviews_rooms");

            entity.HasOne(d => d.Tenant).WithMany(p => p.Reviews)
                .HasForeignKey(d => d.TenantId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_reviews_users");
        });

        modelBuilder.Entity<Room>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__rooms__3213E83FFCF25C40");

            entity.ToTable("rooms");

            entity.Property(e => e.Id)
                .HasMaxLength(50)
                .HasColumnName("id");
            entity.Property(e => e.Area)
                .HasColumnType("decimal(8, 2)")
                .HasColumnName("area");
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnName("created_at");
            entity.Property(e => e.Deposit)
                .HasColumnType("decimal(15, 2)")
                .HasColumnName("deposit");
            entity.Property(e => e.Description).HasColumnName("description");
            entity.Property(e => e.Floor).HasColumnName("floor");
            entity.Property(e => e.Images).HasColumnName("images");
            entity.Property(e => e.MaxPeople).HasColumnName("max_people");
            entity.Property(e => e.Name)
                .HasMaxLength(100)
                .IsUnicode(false)
                .HasColumnName("name");
            entity.Property(e => e.Price)
                .HasColumnType("decimal(15, 2)")
                .HasColumnName("price");
            entity.Property(e => e.PropertyId)
                .HasMaxLength(50)
                .HasColumnName("property_id");
            entity.Property(e => e.Status)
                .HasMaxLength(50)
                .HasColumnName("status");
            entity.Property(e => e.UpdatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnName("updated_at");

            entity.HasOne(d => d.Property).WithMany(p => p.Rooms)
                .HasForeignKey(d => d.PropertyId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_rooms_properties");
        });

        modelBuilder.Entity<RoomAmenity>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__room_ame__3213E83F3843B1CF");

            entity.ToTable("room_amenities");

            entity.Property(e => e.Id)
                .HasMaxLength(50)
                .HasColumnName("id");
            entity.Property(e => e.AmenityId)
                .HasMaxLength(50)
                .HasColumnName("amenity_id");
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnName("created_at");
            entity.Property(e => e.RoomId)
                .HasMaxLength(50)
                .HasColumnName("room_id");
            entity.Property(e => e.UpdatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnName("updated_at");

            entity.HasOne(d => d.Amenity).WithMany(p => p.RoomAmenities)
                .HasForeignKey(d => d.AmenityId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_room_amenities_amenities");

            entity.HasOne(d => d.Room).WithMany(p => p.RoomAmenities)
                .HasForeignKey(d => d.RoomId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_room_amenities_rooms");
        });

        modelBuilder.Entity<Service>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__services__3213E83FF29ADA37");

            entity.ToTable("services");

            entity.Property(e => e.Id)
                .HasMaxLength(50)
                .HasColumnName("id");
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnName("created_at");
            entity.Property(e => e.Description).HasColumnName("description");
            entity.Property(e => e.Name)
                .HasMaxLength(100)
                .HasColumnName("name");
            entity.Property(e => e.OwnerId)
                .HasMaxLength(50)
                .HasColumnName("owner_id");
            entity.Property(e => e.Status)
                .HasMaxLength(50)
                .HasColumnName("status");
            entity.Property(e => e.Unit)
                .HasMaxLength(50)
                .HasColumnName("unit");
            entity.Property(e => e.UpdatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnName("updated_at");

            entity.HasOne(d => d.Owner).WithMany(p => p.Services)
                .HasForeignKey(d => d.OwnerId)
                .HasConstraintName("FK_services_users");
        });

        modelBuilder.Entity<User>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__users__3213E83FC21DE11F");

            entity.ToTable("users");

            entity.HasIndex(e => e.Email, "UQ__users__AB6E61641DC58E5B").IsUnique();

            entity.Property(e => e.Id)
                .HasMaxLength(50)
                .HasColumnName("id");
            entity.Property(e => e.Avatar)
                .HasMaxLength(255)
                .HasColumnName("avatar");
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnName("created_at");
            entity.Property(e => e.Email)
                .HasMaxLength(255)
                .HasColumnName("email");
            entity.Property(e => e.EmailVerifiedAt).HasColumnName("email_verified_at");
            entity.Property(e => e.Name)
                .HasMaxLength(100)
                .HasColumnName("name");
            entity.Property(e => e.Password)
                .HasMaxLength(255)
                .HasColumnName("password");
            entity.Property(e => e.Phone)
                .HasMaxLength(20)
                .HasColumnName("phone");
            entity.Property(e => e.Role)
                .HasMaxLength(50)
                .HasColumnName("role");
            entity.Property(e => e.Status)
                .HasMaxLength(50)
                .HasColumnName("status");
            entity.Property(e => e.UpdatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnName("updated_at");
        });

        modelBuilder.Entity<UtilityReading>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__utility___3213E83F54D08D77");

            entity.ToTable("utility_readings");

            entity.Property(e => e.Id)
                .HasMaxLength(50)
                .HasColumnName("id");
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnName("created_at");
            entity.Property(e => e.ElectricityNew)
                .HasColumnType("decimal(10, 2)")
                .HasColumnName("electricity_new");
            entity.Property(e => e.ElectricityOld)
                .HasColumnType("decimal(10, 2)")
                .HasColumnName("electricity_old");
            entity.Property(e => e.ElectricityPrice)
                .HasColumnType("decimal(15, 2)")
                .HasColumnName("electricity_price");
            entity.Property(e => e.Month).HasColumnName("month");
            entity.Property(e => e.RoomId)
                .HasMaxLength(50)
                .HasColumnName("room_id");
            entity.Property(e => e.UpdatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnName("updated_at");
            entity.Property(e => e.WaterNew)
                .HasColumnType("decimal(10, 2)")
                .HasColumnName("water_new");
            entity.Property(e => e.WaterOld)
                .HasColumnType("decimal(10, 2)")
                .HasColumnName("water_old");
            entity.Property(e => e.WaterPrice)
                .HasColumnType("decimal(15, 2)")
                .HasColumnName("water_price");

            entity.HasOne(d => d.Room).WithMany(p => p.UtilityReadings)
                .HasForeignKey(d => d.RoomId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_utility_readings_rooms");
        });

        modelBuilder.Entity<ViewingAppointment>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__viewing___3213E83F97580B0F");

            entity.ToTable("viewing_appointments");

            entity.Property(e => e.Id)
                .HasMaxLength(50)
                .HasColumnName("id");
            entity.Property(e => e.AppointmentDate).HasColumnName("appointment_date");
            entity.Property(e => e.AppointmentTime).HasColumnName("appointment_time");
            entity.Property(e => e.CancelledAt).HasColumnName("cancelled_at");
            entity.Property(e => e.CompletedAt).HasColumnName("completed_at");
            entity.Property(e => e.ConfirmedAt).HasColumnName("confirmed_at");
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnName("created_at");
            entity.Property(e => e.Message).HasColumnName("message");
            entity.Property(e => e.OwnerNote).HasColumnName("owner_note");
            entity.Property(e => e.Phone)
                .HasMaxLength(20)
                .HasColumnName("phone");
            entity.Property(e => e.RoomId)
                .HasMaxLength(50)
                .HasColumnName("room_id");
            entity.Property(e => e.Status)
                .HasMaxLength(50)
                .HasColumnName("status");
            entity.Property(e => e.TenantId)
                .HasMaxLength(50)
                .HasColumnName("tenant_id");
            entity.Property(e => e.UpdatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnName("updated_at");

            entity.HasOne(d => d.Room).WithMany(p => p.ViewingAppointments)
                .HasForeignKey(d => d.RoomId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_viewing_appointments_rooms");

            entity.HasOne(d => d.Tenant).WithMany(p => p.ViewingAppointments)
                .HasForeignKey(d => d.TenantId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_viewing_appointments_users");
        });

        OnModelCreatingPartial(modelBuilder);
    }

    partial void OnModelCreatingPartial(ModelBuilder modelBuilder);
}
