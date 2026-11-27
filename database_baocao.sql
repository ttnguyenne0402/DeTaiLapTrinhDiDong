-- ============================================================================
-- SCRIPT CƠ SỞ DỮ LIỆU DEMO BÁO CÁO ĐỒ ÁN: QUẢN LÝ PHÒNG TRỌ (SQL SERVER)
-- File: database_baocao.sql
-- Tương thích 100% với Backend ASP.NET Core & Flutter Frontend
-- ============================================================================
--
-- HƯỚNG DẪN CHẠY NHANH:
--   Mở file này bằng SQL Server Management Studio (SSMS) và nhấn F5 (Execute).
--   Script sẽ xóa (nếu đã tồn tại) và tạo mới sạch sẽ CSDL [QuanLyPhongTro]
--   với đầy đủ 27 bảng, trigger thông báo push và dữ liệu demo đồng bộ.
--
-- ============================================================================
-- DANH SÁCH TÀI KHOẢN DEMO BÁO CÁO (Mật khẩu chung: 123456)
-- ============================================================================
-- 1. Quản trị viên (Admin):
--    - admin@phongtro.vn             | Mật khẩu: 123456 | Duyệt tin đăng, thống kê hệ thống
--
-- 2. Chủ trọ (Owner):
--    - an.nguyen@gmail.com           | Mật khẩu: 123456 | Chủ trọ 1 (3 khu trọ, 8 phòng, 2 HĐ hiệu lực, 1 HĐ chờ ký)
--    - owner@quanlyphongtro.vn       | Mật khẩu: 123456 | Tài khoản chủ trọ dự phòng (cùng dữ liệu Chủ trọ 1)
--    - mai.tran@gmail.com            | Mật khẩu: 123456 | Chủ trọ 2 (Chung Cư Mini Tân Bình)
--
-- 3. Khách thuê (Tenant):
--    - viet.le@gmail.com             | Mật khẩu: 123456 | Đang thuê Phòng 101 (HĐ HD-2026-001, có 1 hóa đơn chưa thanh toán)
--    - tuan.pham@gmail.com           | Mật khẩu: 123456 | Đang thuê Studio A1 (HĐ HD-2026-002, có 1 hóa đơn quá hạn)
--    - yen.do@gmail.com              | Mật khẩu: 123456 | Có HĐ chờ ký HD-2026-003 (Phòng 202) & lịch hẹn xem phòng
--    - trong.hoang@gmail.com         | Mật khẩu: 123456 | Khách thuê đang tìm phòng (tìm kiếm, yêu thích, đặt lịch)
-- ============================================================================

USE master;
GO

IF EXISTS (SELECT name FROM sys.databases WHERE name = N'QuanLyPhongTro')
BEGIN
    ALTER DATABASE QuanLyPhongTro SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE QuanLyPhongTro;
END
GO

CREATE DATABASE QuanLyPhongTro;
GO

USE QuanLyPhongTro;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

-- ============================================================================
-- PHẦN 1: KHỞI TẠO CẤU TRÚC BẢNG (27 BẢNG - THEO THỨ TỰ KHÓA NGOẠI)
-- ============================================================================

-- 1. Bảng users: Tài khoản người dùng
CREATE TABLE dbo.users (
    id NVARCHAR(50) NOT NULL PRIMARY KEY,
    name NVARCHAR(100) NOT NULL,
    email NVARCHAR(255) NOT NULL UNIQUE,
    password NVARCHAR(255) NOT NULL,
    phone NVARCHAR(20) NULL,
    avatar NVARCHAR(255) NULL,
    role NVARCHAR(50) NOT NULL CHECK (role IN ('admin', 'owner', 'tenant')),
    status NVARCHAR(50) NOT NULL CHECK (status IN ('active', 'inactive', 'blocked')),
    email_verified_at DATETIME2 NULL,
    google_id VARCHAR(255) NULL,
    zalo_id VARCHAR(255) NULL,
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2 DEFAULT GETDATE()
);
CREATE UNIQUE INDEX UQ_users_google_id ON dbo.users (google_id) WHERE google_id IS NOT NULL;
CREATE UNIQUE INDEX UX_users_zalo_id ON dbo.users (zalo_id) WHERE zalo_id IS NOT NULL;
GO

-- 2. Bảng email_otps: Mã xác thực OTP qua email
CREATE TABLE dbo.email_otps (
    id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_email_otps PRIMARY KEY,
    user_id NVARCHAR(50) NOT NULL,
    purpose VARCHAR(30) NOT NULL,
    code_hash VARCHAR(64) NOT NULL,
    created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    expires_at DATETIME2 NOT NULL,
    used_at DATETIME2 NULL,
    attempts INT NOT NULL DEFAULT 0,
    CONSTRAINT FK_email_otps_users FOREIGN KEY (user_id) REFERENCES dbo.users(id) ON DELETE CASCADE
);
CREATE INDEX IX_email_otps_user_id_purpose_created_at
    ON dbo.email_otps (user_id, purpose, created_at);
GO

-- 3. Bảng bank_accounts: Tài khoản ngân hàng nhận thanh toán (VietQR)
CREATE TABLE dbo.bank_accounts (
    id NVARCHAR(50) NOT NULL PRIMARY KEY,
    user_id NVARCHAR(50) NOT NULL,
    bank_code NVARCHAR(20) NOT NULL,
    bank_name NVARCHAR(100) NULL,
    account_number NVARCHAR(30) NOT NULL,
    account_holder NVARCHAR(100) NOT NULL,
    is_default BIT NOT NULL DEFAULT 0,
    status NVARCHAR(50) NOT NULL CHECK (status IN ('active', 'inactive')),
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_bank_accounts_users FOREIGN KEY (user_id) REFERENCES dbo.users(id)
);
GO

-- 4. Bảng properties: Bất động sản / Khu trọ / Tòa nhà
CREATE TABLE dbo.properties (
    id NVARCHAR(50) NOT NULL PRIMARY KEY,
    owner_id NVARCHAR(50) NOT NULL,
    name NVARCHAR(150) NOT NULL,
    image NVARCHAR(255) NULL,
    type NVARCHAR(50) NOT NULL CHECK (type IN ('rooming_house', 'apartment', 'house')),
    address NVARCHAR(255) NOT NULL,
    district NVARCHAR(100) NOT NULL,
    ward NVARCHAR(100) NOT NULL,
    latitude DECIMAL(10,7) NULL,
    longitude DECIMAL(10,7) NULL,
    description NVARCHAR(MAX) NULL,
    status NVARCHAR(50) NOT NULL CHECK (status IN ('active', 'inactive')),
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_properties_users FOREIGN KEY (owner_id) REFERENCES dbo.users(id)
);
GO

-- 5. Bảng rooms: Phòng / Căn hộ
CREATE TABLE dbo.rooms (
    id NVARCHAR(50) NOT NULL PRIMARY KEY,
    property_id NVARCHAR(50) NOT NULL,
    name NVARCHAR(100) NOT NULL,
    area DECIMAL(8,2) NOT NULL,
    price DECIMAL(15,2) NOT NULL,
    deposit DECIMAL(15,2) NOT NULL,
    max_people INT NOT NULL,
    floor INT NULL,
    description NVARCHAR(MAX) NULL,
    images NVARCHAR(MAX) NULL,
    status NVARCHAR(50) NOT NULL CHECK (status IN ('available', 'pending', 'rented', 'maintenance', 'hidden')),
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_rooms_properties FOREIGN KEY (property_id) REFERENCES dbo.properties(id)
);
GO

-- 6. Bảng amenities: Danh mục tiện ích
CREATE TABLE dbo.amenities (
    id NVARCHAR(50) NOT NULL PRIMARY KEY,
    owner_id NVARCHAR(50) NULL,
    name NVARCHAR(100) NOT NULL UNIQUE,
    description NVARCHAR(MAX) NULL,
    icon NVARCHAR(50) NULL DEFAULT 'check_circle',
    status NVARCHAR(50) NOT NULL CHECK (status IN ('active', 'inactive')),
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_amenities_users FOREIGN KEY (owner_id) REFERENCES dbo.users(id)
);
GO

-- 7. Bảng property_amenities: Tiện ích theo từng bất động sản
CREATE TABLE dbo.property_amenities (
    id NVARCHAR(50) NOT NULL PRIMARY KEY,
    property_id NVARCHAR(50) NOT NULL,
    amenity_id NVARCHAR(50) NOT NULL,
    status NVARCHAR(50) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive')),
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_property_amenities_properties FOREIGN KEY (property_id) REFERENCES dbo.properties(id),
    CONSTRAINT FK_property_amenities_amenities FOREIGN KEY (amenity_id) REFERENCES dbo.amenities(id)
);
GO

-- 8. Bảng room_amenities: Tiện ích riêng từng phòng
CREATE TABLE dbo.room_amenities (
    id NVARCHAR(50) NOT NULL PRIMARY KEY,
    room_id NVARCHAR(50) NOT NULL,
    amenity_id NVARCHAR(50) NOT NULL,
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_room_amenities_rooms FOREIGN KEY (room_id) REFERENCES dbo.rooms(id),
    CONSTRAINT FK_room_amenities_amenities FOREIGN KEY (amenity_id) REFERENCES dbo.amenities(id)
);
GO

-- 9. Bảng services: Danh mục dịch vụ tính phí
CREATE TABLE dbo.services (
    id NVARCHAR(50) NOT NULL PRIMARY KEY,
    owner_id NVARCHAR(50) NULL,
    name NVARCHAR(100) NOT NULL,
    description NVARCHAR(MAX) NULL,
    price DECIMAL(15,2) NOT NULL DEFAULT 0,
    unit NVARCHAR(50) NOT NULL,
    is_mandatory BIT NOT NULL DEFAULT 0,
    icon NVARCHAR(50) NULL DEFAULT 'bolt',
    status NVARCHAR(50) NOT NULL CHECK (status IN ('active', 'inactive')),
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_services_users FOREIGN KEY (owner_id) REFERENCES dbo.users(id)
);
GO

-- 10. Bảng property_services: Cấu hình giá dịch vụ theo khu trọ
CREATE TABLE dbo.property_services (
    id NVARCHAR(50) NOT NULL PRIMARY KEY,
    property_id NVARCHAR(50) NOT NULL,
    service_id NVARCHAR(50) NOT NULL,
    price DECIMAL(15,2) NOT NULL,
    status NVARCHAR(50) NOT NULL CHECK (status IN ('active', 'inactive')),
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_property_services_properties FOREIGN KEY (property_id) REFERENCES dbo.properties(id),
    CONSTRAINT FK_property_services_services FOREIGN KEY (service_id) REFERENCES dbo.services(id)
);
GO

-- 11. Bảng room_services: Dịch vụ áp dụng riêng cho từng phòng
CREATE TABLE dbo.room_services (
    id NVARCHAR(50) NOT NULL PRIMARY KEY,
    room_id NVARCHAR(50) NOT NULL,
    service_id NVARCHAR(50) NOT NULL,
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_room_services_rooms FOREIGN KEY (room_id) REFERENCES dbo.rooms(id),
    CONSTRAINT FK_room_services_services FOREIGN KEY (service_id) REFERENCES dbo.services(id)
);
GO

-- 12. Bảng rental_posts: Tin đăng cho thuê
CREATE TABLE dbo.rental_posts (
    id NVARCHAR(50) NOT NULL PRIMARY KEY,
    room_id NVARCHAR(50) NOT NULL,
    title NVARCHAR(200) NOT NULL,
    description NVARCHAR(MAX) NOT NULL,
    price DECIMAL(15,2) NULL,
    amenities NVARCHAR(MAX) NULL,
    views INT NOT NULL DEFAULT 0,
    submit_note NVARCHAR(MAX) NULL,
    status NVARCHAR(50) NOT NULL CHECK (status IN ('draft', 'pending', 'published', 'rejected', 'hidden')),
    rejection_reason NVARCHAR(MAX) NULL,
    published_at DATETIME2 NULL,
    expired_at DATETIME2 NULL,
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_rental_posts_rooms FOREIGN KEY (room_id) REFERENCES dbo.rooms(id)
);
GO

-- 13. Bảng rental_post_images: Hình ảnh tin đăng
CREATE TABLE dbo.rental_post_images (
    id NVARCHAR(50) NOT NULL PRIMARY KEY,
    rental_post_id NVARCHAR(50) NOT NULL,
    image_path NVARCHAR(255) NOT NULL,
    is_thumbnail BIT DEFAULT 0,
    sort_order INT DEFAULT 0,
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_rental_post_images_posts FOREIGN KEY (rental_post_id) REFERENCES dbo.rental_posts(id)
);
GO

-- 14. Bảng viewing_appointments: Lịch hẹn xem phòng
CREATE TABLE dbo.viewing_appointments (
    id NVARCHAR(50) NOT NULL PRIMARY KEY,
    room_id NVARCHAR(50) NOT NULL,
    tenant_id NVARCHAR(50) NOT NULL,
    appointment_date DATE NOT NULL,
    appointment_time TIME NOT NULL,
    phone NVARCHAR(20) NOT NULL,
    message NVARCHAR(MAX) NULL,
    status NVARCHAR(50) NOT NULL CHECK (status IN ('pending', 'confirmed', 'rescheduled', 'rejected', 'cancelled', 'completed')),
    owner_note NVARCHAR(MAX) NULL,
    confirmed_at DATETIME2 NULL,
    completed_at DATETIME2 NULL,
    cancelled_at DATETIME2 NULL,
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_viewing_appointments_rooms FOREIGN KEY (room_id) REFERENCES dbo.rooms(id),
    CONSTRAINT FK_viewing_appointments_users FOREIGN KEY (tenant_id) REFERENCES dbo.users(id)
);
GO

-- 15. Bảng contracts: Hợp đồng thuê phòng
CREATE TABLE dbo.contracts (
    id NVARCHAR(50) NOT NULL PRIMARY KEY,
    contract_code NVARCHAR(50) NOT NULL UNIQUE,
    viewing_appointment_id NVARCHAR(50) NULL,
    room_id NVARCHAR(50) NOT NULL,
    owner_id NVARCHAR(50) NOT NULL,
    tenant_id NVARCHAR(50) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    rent DECIMAL(15,2) NOT NULL,
    deposit DECIMAL(15,2) NOT NULL,
    payment_cycle NVARCHAR(50) NOT NULL CHECK (payment_cycle IN ('monthly', 'quarterly')),
    terms NVARCHAR(MAX) NULL,
    status NVARCHAR(50) NOT NULL CONSTRAINT CK_contracts_status
        CHECK (status IN ('draft', 'pending', 'active', 'expired', 'terminated', 'rejected', 'withdrawn')),
    signed_at DATETIME2 NULL,
    signing_closed_at DATETIME2 NULL,
    signing_close_reason NVARCHAR(500) NULL,
    terminated_at DATETIME2 NULL,
    initial_electricity_reading DECIMAL(10,2) NOT NULL DEFAULT 0,
    initial_water_reading DECIMAL(10,2) NOT NULL DEFAULT 0,
    owner_signature NVARCHAR(MAX) NULL,
    tenant_signature NVARCHAR(MAX) NULL,
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_contracts_appointments FOREIGN KEY (viewing_appointment_id) REFERENCES dbo.viewing_appointments(id),
    CONSTRAINT FK_contracts_rooms FOREIGN KEY (room_id) REFERENCES dbo.rooms(id),
    CONSTRAINT FK_contracts_owner FOREIGN KEY (owner_id) REFERENCES dbo.users(id),
    CONSTRAINT FK_contracts_tenant FOREIGN KEY (tenant_id) REFERENCES dbo.users(id)
);
GO

-- 16. Bảng contract_services: Dịch vụ áp dụng theo hợp đồng
CREATE TABLE dbo.contract_services (
    id NVARCHAR(50) NOT NULL PRIMARY KEY,
    contract_id NVARCHAR(50) NOT NULL,
    service_id NVARCHAR(50) NOT NULL,
    quantity DECIMAL(10,2) DEFAULT 1,
    unit_price DECIMAL(15,2) NOT NULL,
    status NVARCHAR(50) NOT NULL CHECK (status IN ('active', 'inactive')),
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_contract_services_contracts FOREIGN KEY (contract_id) REFERENCES dbo.contracts(id),
    CONSTRAINT FK_contract_services_services FOREIGN KEY (service_id) REFERENCES dbo.services(id)
);
GO

-- 17. Bảng contract_members: Thành viên ở cùng phòng
CREATE TABLE dbo.contract_members (
    id NVARCHAR(50) NOT NULL PRIMARY KEY,
    contract_id NVARCHAR(50) NOT NULL,
    name NVARCHAR(100) NOT NULL,
    identity_card NVARCHAR(20) NOT NULL,
    phone NVARCHAR(20) NULL,
    relationship NVARCHAR(50) NULL,
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_contract_members_contracts FOREIGN KEY (contract_id) REFERENCES dbo.contracts(id)
);
GO

-- 18. Bảng contract_terminations: Thanh lý & quyết toán tiền cọc
CREATE TABLE dbo.contract_terminations (
    id NVARCHAR(50) NOT NULL PRIMARY KEY,
    contract_id NVARCHAR(50) NOT NULL,
    deposit_amount DECIMAL(15,2) NOT NULL,
    deduction_amount DECIMAL(15,2) DEFAULT 0,
    deduction_reason NVARCHAR(MAX) NULL,
    refund_amount DECIMAL(15,2) NOT NULL,
    return_date DATE NOT NULL,
    note NVARCHAR(MAX) NULL,
    CONSTRAINT FK_terminations_contracts FOREIGN KEY (contract_id) REFERENCES dbo.contracts(id)
);
GO

-- 19. Bảng utility_readings: Chỉ số điện nước hàng tháng
CREATE TABLE dbo.utility_readings (
    id NVARCHAR(50) NOT NULL PRIMARY KEY,
    room_id NVARCHAR(50) NOT NULL,
    month DATE NOT NULL,
    electricity_old DECIMAL(10,2) NOT NULL,
    electricity_new DECIMAL(10,2) NOT NULL,
    electricity_price DECIMAL(15,2) NOT NULL,
    water_old DECIMAL(10,2) NOT NULL,
    water_new DECIMAL(10,2) NOT NULL,
    water_price DECIMAL(15,2) NOT NULL,
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_utility_readings_rooms FOREIGN KEY (room_id) REFERENCES dbo.rooms(id)
);
GO

-- 20. Bảng invoices: Hóa đơn tiền phòng & dịch vụ
CREATE TABLE dbo.invoices (
    id NVARCHAR(50) NOT NULL PRIMARY KEY,
    invoice_code NVARCHAR(50) NOT NULL UNIQUE,
    contract_id NVARCHAR(50) NOT NULL,
    utility_reading_id NVARCHAR(50) NULL,
    bank_account_id NVARCHAR(50) NULL,
    billing_month DATE NOT NULL,
    issue_date DATE NOT NULL,
    due_date DATE NOT NULL,
    subtotal DECIMAL(15,2) NOT NULL,
    discount DECIMAL(15,2) DEFAULT 0,
    total DECIMAL(15,2) NOT NULL,
    status NVARCHAR(50) NOT NULL CHECK (status IN ('unpaid', 'pending', 'paid', 'overdue', 'cancelled')),
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_invoices_contracts FOREIGN KEY (contract_id) REFERENCES dbo.contracts(id),
    CONSTRAINT FK_invoices_readings FOREIGN KEY (utility_reading_id) REFERENCES dbo.utility_readings(id),
    CONSTRAINT FK_invoices_bank_accounts FOREIGN KEY (bank_account_id) REFERENCES dbo.bank_accounts(id)
);
GO

-- 21. Bảng invoice_items: Chi tiết các khoản thu trong hóa đơn
CREATE TABLE dbo.invoice_items (
    id NVARCHAR(50) NOT NULL PRIMARY KEY,
    invoice_id NVARCHAR(50) NOT NULL,
    type NVARCHAR(50) NOT NULL CHECK (type IN ('rent', 'electricity', 'water', 'service', 'other')),
    description NVARCHAR(255) NULL,
    quantity DECIMAL(10,2) DEFAULT 1,
    unit_price DECIMAL(15,2) NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    service_id NVARCHAR(50) NULL,
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_invoice_items_invoices FOREIGN KEY (invoice_id) REFERENCES dbo.invoices(id),
    CONSTRAINT FK_invoice_items_services FOREIGN KEY (service_id) REFERENCES dbo.services(id)
);
GO

-- 22. Bảng payments: Lịch sử giao dịch thanh toán
CREATE TABLE dbo.payments (
    id NVARCHAR(50) NOT NULL PRIMARY KEY,
    payment_code NVARCHAR(50) NOT NULL UNIQUE,
    invoice_id NVARCHAR(50) NOT NULL,
    payer_id NVARCHAR(50) NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    method NVARCHAR(50) NOT NULL CHECK (method IN ('cash', 'bank_transfer', 'qr', 'online')),
    transaction_code NVARCHAR(100) NULL,
    paid_at DATETIME2 NULL,
    status NVARCHAR(50) NOT NULL CHECK (status IN ('pending', 'success', 'failed', 'cancelled')),
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_payments_invoices FOREIGN KEY (invoice_id) REFERENCES dbo.invoices(id),
    CONSTRAINT FK_payments_users FOREIGN KEY (payer_id) REFERENCES dbo.users(id)
);
GO

-- 23. Bảng maintenance_requests: Yêu cầu sửa chữa / bảo trì sự cố
CREATE TABLE dbo.maintenance_requests (
    id NVARCHAR(50) NOT NULL PRIMARY KEY,
    room_id NVARCHAR(50) NOT NULL,
    tenant_id NVARCHAR(50) NOT NULL,
    title NVARCHAR(200) NOT NULL,
    description NVARCHAR(MAX) NOT NULL,
    priority NVARCHAR(50) NOT NULL CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
    status NVARCHAR(50) NOT NULL CHECK (status IN ('pending', 'processing', 'completed', 'rejected')),
    image VARCHAR(MAX) NULL,
    owner_note NVARCHAR(MAX) NULL,
    completed_at DATETIME2 NULL,
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_maintenance_rooms FOREIGN KEY (room_id) REFERENCES dbo.rooms(id),
    CONSTRAINT FK_maintenance_users FOREIGN KEY (tenant_id) REFERENCES dbo.users(id)
);
GO

-- 24. Bảng reviews: Đánh giá của khách thuê
CREATE TABLE dbo.reviews (
    id NVARCHAR(50) NOT NULL PRIMARY KEY,
    room_id NVARCHAR(50) NOT NULL,
    tenant_id NVARCHAR(50) NOT NULL,
    rating TINYINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment NVARCHAR(MAX) NULL,
    status NVARCHAR(50) NOT NULL CHECK (status IN ('visible', 'hidden')),
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_reviews_rooms FOREIGN KEY (room_id) REFERENCES dbo.rooms(id),
    CONSTRAINT FK_reviews_users FOREIGN KEY (tenant_id) REFERENCES dbo.users(id)
);
GO

-- 25. Bảng favorites: Danh sách phòng yêu thích (thả tim)
CREATE TABLE dbo.favorites (
    id NVARCHAR(50) NOT NULL PRIMARY KEY,
    user_id NVARCHAR(50) NOT NULL,
    room_id NVARCHAR(50) NOT NULL,
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_favorites_users FOREIGN KEY (user_id) REFERENCES dbo.users(id),
    CONSTRAINT FK_favorites_rooms FOREIGN KEY (room_id) REFERENCES dbo.rooms(id)
);
GO

-- 26. Bảng notifications: Thông báo trong ứng dụng
CREATE TABLE dbo.notifications (
    id NVARCHAR(50) NOT NULL PRIMARY KEY,
    user_id NVARCHAR(50) NOT NULL,
    title NVARCHAR(200) NOT NULL,
    message NVARCHAR(MAX) NOT NULL,
    type NVARCHAR(50) NOT NULL,
    reference_id NVARCHAR(50) NULL,
    reference_type NVARCHAR(50) NULL,
    read_at DATETIME2 NULL,
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_notifications_users FOREIGN KEY (user_id) REFERENCES dbo.users(id)
);
GO

-- 27. Bảng push_devices & push_deliveries + Trigger đẩy thông báo Firebase
CREATE TABLE dbo.push_devices (
    token_hash BINARY(32) NOT NULL PRIMARY KEY,
    token NVARCHAR(2048) NOT NULL,
    user_id NVARCHAR(50) NOT NULL REFERENCES dbo.users(id) ON DELETE CASCADE
);
CREATE INDEX IX_push_devices_user_id ON dbo.push_devices(user_id);
GO

CREATE TABLE dbo.push_deliveries (
    id BIGINT IDENTITY PRIMARY KEY,
    notification_id NVARCHAR(50) NOT NULL REFERENCES dbo.notifications(id) ON DELETE CASCADE,
    token_hash BINARY(32) NOT NULL,
    created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    available_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    attempt_count INT NOT NULL DEFAULT 0,
    lease_id UNIQUEIDENTIFIER NULL
);
CREATE INDEX IX_push_deliveries_available_at ON dbo.push_deliveries(available_at, id);
CREATE INDEX IX_push_deliveries_notification_id ON dbo.push_deliveries(notification_id);
GO


-- ============================================================================
-- PHẦN 2: DỮ LIỆU MẪU DEMO BÁO CÁO (ĐỒNG BỘ TOÀN HỆ THỐNG)
-- ============================================================================

-- 1. Tài khoản người dùng (Admin, Chủ trọ, Khách thuê)
INSERT INTO dbo.users (id, name, email, password, phone, avatar, role, status, email_verified_at, created_at, updated_at) VALUES
('usr_admin',     N'Quản trị viên Hệ thống', 'admin@phongtro.vn',       '123456', '0901234567', 'https://i.pravatar.cc/150?img=1', 'admin',  'active', GETDATE(), DATEADD(day, -60, GETDATE()), GETDATE()),
('usr_owner1',    N'Nguyễn Văn An',           'an.nguyen@gmail.com',     '123456', '0912345678', 'https://i.pravatar.cc/150?img=2', 'owner',  'active', GETDATE(), DATEADD(day, -45, GETDATE()), GETDATE()),
('USER_OWNER_01', N'Nguyễn Văn An',           'owner@quanlyphongtro.vn', '123456', '0901234568', 'https://i.pravatar.cc/150?img=2', 'owner',  'active', GETDATE(), DATEADD(day, -45, GETDATE()), GETDATE()),
('usr_owner2',    N'Trần Thị Mai',            'mai.tran@gmail.com',      '123456', '0987654321', 'https://i.pravatar.cc/150?img=3', 'owner',  'active', GETDATE(), DATEADD(day, -40, GETDATE()), GETDATE()),
('usr_tenant1',   N'Lê Quốc Việt',            'viet.le@gmail.com',       '123456', '0933112233', 'https://i.pravatar.cc/150?img=4', 'tenant', 'active', GETDATE(), DATEADD(day, -30, GETDATE()), GETDATE()),
('usr_tenant2',   N'Phạm Minh Tuấn',          'tuan.pham@gmail.com',     '123456', '0944223344', 'https://i.pravatar.cc/150?img=5', 'tenant', 'active', GETDATE(), DATEADD(day, -25, GETDATE()), GETDATE()),
('usr_tenant3',   N'Đỗ Hoàng Yến',            'yen.do@gmail.com',        '123456', '0966554433', 'https://i.pravatar.cc/150?img=6', 'tenant', 'active', GETDATE(), DATEADD(day, -15, GETDATE()), GETDATE()),
('usr_tenant4',   N'Hoàng Đức Trọng',         'trong.hoang@gmail.com',   '123456', '0977889900', 'https://i.pravatar.cc/150?img=7', 'tenant', 'active', GETDATE(), DATEADD(day, -10, GETDATE()), GETDATE());
GO

-- 2. Tài khoản ngân hàng (VietQR)
INSERT INTO dbo.bank_accounts (id, user_id, bank_code, bank_name, account_number, account_holder, is_default, status, created_at, updated_at) VALUES
('bank_01', 'usr_owner1', 'MB',  N'MB Bank',     '0912345678',   N'NGUYEN VAN AN', 1, 'active', GETDATE(), GETDATE()),
('bank_02', 'usr_owner2', 'TCB', N'Techcombank', '190334888291', N'TRAN THI MAI',  1, 'active', GETDATE(), GETDATE());
GO

-- 3. Bất động sản / Khu trọ (prop_04 ở trạng thái inactive = Bảo trì để demo chặn đăng tin)
INSERT INTO dbo.properties (id, owner_id, name, image, type, address, district, ward, latitude, longitude, description, status, created_at, updated_at) VALUES
('prop_01', 'usr_owner1', N'Nhà Trọ An Khang',        'https://images.unsplash.com/photo-1555854877-bab0e564b8d5', 'rooming_house', N'123 Đường Tây Thạnh', N'Tân Phú',  N'Tây Thạnh', 10.812345, 106.634567, N'Dãy trọ an ninh, camera 24/7, khóa vân tay, giờ giấc tự do.',       'active',   DATEADD(day, -40, GETDATE()), GETDATE()),
('prop_02', 'usr_owner1', N'Căn Hộ Mini Xanh',        'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00', 'apartment',     N'45/6 Lê Trọng Tấn',   N'Tân Phú',  N'Sơn Kỳ',    10.805566, 106.628899, N'Căn hộ dịch vụ đầy đủ nội thất, có thang máy và hầm xe rộng rãi.', 'active',   DATEADD(day, -35, GETDATE()), GETDATE()),
('prop_03', 'usr_owner2', N'Chung Cư Mini Tân Bình',  'https://images.unsplash.com/photo-1512917774080-9991f1c4c750', 'house',         N'78 Cộng Hòa',         N'Tân Bình', N'Phường 13', 10.801234, 106.645678, N'Gần Etown Cộng Hòa, thuận tiện di chuyển ra sân bay Tân Sơn Nhất.', 'active',   DATEADD(day, -25, GETDATE()), GETDATE()),
('prop_04', 'usr_owner1', N'Nhà Trọ Bình An',         'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab', 'rooming_house', N'88 Kênh Tân Hóa',     N'Tân Phú',  N'Hòa Thạnh', 10.778899, 106.631122, N'Khu trọ đang nâng cấp hệ thống PCCC và sơn sửa lại toàn bộ.',      'inactive', DATEADD(day, -20, GETDATE()), GETDATE());
GO

-- 4. Danh sách Phòng (9 phòng phủ đủ trạng thái available, rented, maintenance)
INSERT INTO dbo.rooms (id, property_id, name, area, price, deposit, max_people, floor, description, images, status, created_at, updated_at) VALUES
('room_101', 'prop_01', N'Phòng 101',   25.0, 3200000, 3200000, 2, 1, N'Phòng tầng trệt, có gác lửng cao, kệ bếp riêng.',                    'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267', 'rented',      DATEADD(day, -38, GETDATE()), GETDATE()),
('room_102', 'prop_01', N'Phòng 102',   28.0, 3500000, 3500000, 3, 1, N'Phòng rộng thoáng có cửa sổ lớn và ban công phơi đồ.',               'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688', 'available',   DATEADD(day, -38, GETDATE()), GETDATE()),
('room_201', 'prop_01', N'Phòng 201',   22.0, 2900000, 2900000, 2, 2, N'Phòng lầu 2 yên tĩnh, giá sinh viên, gần ĐH Công Thương.',           'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2', 'available',   DATEADD(day, -30, GETDATE()), GETDATE()),
('room_202', 'prop_01', N'Phòng 202',   24.0, 3100000, 3100000, 2, 2, N'Phòng sạch sẽ, sẵn máy lạnh và wifi tốc độ cao.',                    'https://images.unsplash.com/photo-1513694203232-719a280e022f', 'available',   DATEADD(day, -22, GETDATE()), GETDATE()),
('room_a1',  'prop_02', N'Studio A1',   35.0, 5200000, 5200000, 2, 2, N'Full nội thất cao cấp: máy lạnh, tủ lạnh, giường nệm, bàn làm việc.', 'https://images.unsplash.com/photo-1493809842364-78817add7ffb', 'rented',      DATEADD(day, -28, GETDATE()), GETDATE()),
('room_a2',  'prop_02', N'Studio A2',   32.0, 4800000, 4800000, 2, 2, N'Nội thất cơ bản, ban công riêng view thoáng mát.',                   'https://images.unsplash.com/photo-1536376072261-38c75010e6c9', 'available',   DATEADD(day, -18, GETDATE()), GETDATE()),
('room_a3',  'prop_02', N'Studio A3',   30.0, 4900000, 4900000, 2, 3, N'Đang bảo trì hệ thống ống nước nhà vệ sinh.',                        'https://images.unsplash.com/photo-1554995207-c18c203602cb', 'maintenance', DATEADD(day, -12, GETDATE()), GETDATE()),
('room_b1',  'prop_03', N'Phòng VIP 1', 40.0, 6000000, 6000000, 4, 3, N'Căn hộ 1 phòng ngủ riêng biệt, bếp tách riêng, khóa từ an toàn.',    'https://images.unsplash.com/photo-1505691938895-1758d7feb511', 'available',   DATEADD(day, -10, GETDATE()), GETDATE()),
('room_c1',  'prop_04', N'Phòng C1',    20.0, 2800000, 2800000, 2, 1, N'Phòng thuộc Nhà Trọ Bình An (hiện đang bảo trì tòa nhà).',           'https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af', 'available',   DATEADD(day, -8,  GETDATE()), GETDATE());
GO

-- 5. Tiện ích chung, tiện ích tòa nhà & tiện ích phòng
INSERT INTO dbo.amenities (id, owner_id, name, description, icon, status, created_at, updated_at) VALUES
('amn_wifi',   NULL, N'Wifi tốc độ cao',        N'Đường truyền cáp quang riêng từng tầng',          'wifi',                  'active', GETDATE(), GETDATE()),
('amn_ac',     NULL, N'Máy lạnh',               N'Máy lạnh Inverter tiết kiệm điện',                'ac_unit',               'active', GETDATE(), GETDATE()),
('amn_wm',     NULL, N'Máy giặt chung',         N'Khu giặt phơi sân thượng thoáng mát',             'local_laundry_service', 'active', GETDATE(), GETDATE()),
('amn_park',   NULL, N'Chỗ để xe máy',          N'Hầm giữ xe có thẻ từ và bảo vệ 24/7',             'two_wheeler',           'active', GETDATE(), GETDATE()),
('amn_cam',    NULL, N'Camera an ninh',         N'Giám sát hành lang & cổng ra vào 24/7',           'videocam',              'active', GETDATE(), GETDATE()),
('amn_fridge', NULL, N'Tủ lạnh riêng',          N'Tủ lạnh ngăn đá riêng trong phòng',               'kitchen',               'active', GETDATE(), GETDATE()),
('amn_elev',   NULL, N'Thang máy',              N'Thang máy tải trọng lớn, bảo trì định kỳ',        'elevator',              'active', GETDATE(), GETDATE()),
('amn_time',   NULL, N'Giờ giấc tự do',         N'Ra vào tự do 24/24, không chung chủ',             'access_time',           'active', GETDATE(), GETDATE()),
('amn_loft',   NULL, N'Gác lửng cao',           N'Gác lửng đúc kiên cố, rộng rãi',                  'stairs',                'active', GETDATE(), GETDATE()),
('amn_balc',   NULL, N'Ban công / Cửa sổ',      N'Ban công riêng đón ánh sáng tự nhiên',            'balcony',               'active', GETDATE(), GETDATE()),
('amn_finger', NULL, N'Khóa vân tay / Thẻ từ',  N'Kiểm soát ra vào bằng vân tay / thẻ từ',          'fingerprint',           'active', GETDATE(), GETDATE()),
('amn_fire',   NULL, N'Hệ thống PCCC',          N'Trang bị bình chữa cháy và báo khói hành lang',   'fire_extinguisher',     'active', GETDATE(), GETDATE());
GO

INSERT INTO dbo.property_amenities (id, property_id, amenity_id, status) VALUES
('pa_01_01', 'prop_01', 'amn_wifi',   'active'),
('pa_01_02', 'prop_01', 'amn_park',   'active'),
('pa_01_03', 'prop_01', 'amn_cam',    'active'),
('pa_01_04', 'prop_01', 'amn_time',   'active'),
('pa_01_05', 'prop_01', 'amn_finger', 'active'),
('pa_01_06', 'prop_01', 'amn_fire',   'active'),
('pa_02_01', 'prop_02', 'amn_wifi',   'active'),
('pa_02_02', 'prop_02', 'amn_ac',     'active'),
('pa_02_03', 'prop_02', 'amn_fridge', 'active'),
('pa_02_04', 'prop_02', 'amn_elev',   'active'),
('pa_02_05', 'prop_02', 'amn_wm',     'active'),
('pa_02_06', 'prop_02', 'amn_cam',    'active'),
('pa_02_07', 'prop_02', 'amn_finger', 'active'),
('pa_03_01', 'prop_03', 'amn_wifi',   'active'),
('pa_03_02', 'prop_03', 'amn_elev',   'active'),
('pa_03_03', 'prop_03', 'amn_park',   'active'),
('pa_03_04', 'prop_03', 'amn_fire',   'active');
GO

INSERT INTO dbo.room_amenities (id, room_id, amenity_id, created_at, updated_at) VALUES
('ra_01', 'room_101', 'amn_wifi',   GETDATE(), GETDATE()),
('ra_02', 'room_101', 'amn_park',   GETDATE(), GETDATE()),
('ra_03', 'room_101', 'amn_loft',   GETDATE(), GETDATE()),
('ra_04', 'room_102', 'amn_wifi',   GETDATE(), GETDATE()),
('ra_05', 'room_102', 'amn_balc',   GETDATE(), GETDATE()),
('ra_06', 'room_201', 'amn_wifi',   GETDATE(), GETDATE()),
('ra_07', 'room_201', 'amn_time',   GETDATE(), GETDATE()),
('ra_08', 'room_a1',  'amn_wifi',   GETDATE(), GETDATE()),
('ra_09', 'room_a1',  'amn_ac',     GETDATE(), GETDATE()),
('ra_10', 'room_a1',  'amn_fridge', GETDATE(), GETDATE()),
('ra_11', 'room_a2',  'amn_wifi',   GETDATE(), GETDATE()),
('ra_12', 'room_a2',  'amn_balc',   GETDATE(), GETDATE()),
('ra_13', 'room_b1',  'amn_ac',     GETDATE(), GETDATE()),
('ra_14', 'room_b1',  'amn_elev',   GETDATE(), GETDATE());
GO

-- 6. Dịch vụ & Biểu phí dịch vụ theo khu trọ / phòng
INSERT INTO dbo.services (id, owner_id, name, description, price, unit, is_mandatory, icon, status, created_at, updated_at) VALUES
('srv_elec',    NULL, N'Điện sinh hoạt',       N'Tính theo đồng hồ riêng từng phòng',       3500,   N'kWh',         1, 'bolt',              'active', GETDATE(), GETDATE()),
('srv_water',   NULL, N'Nước máy',             N'Tính theo khối nước sạch thực tế',         20000,  N'm3',          1, 'water_drop',        'active', GETDATE(), GETDATE()),
('srv_garbage', NULL, N'Rác & Vệ sinh chung',  N'Thu gom rác & dọn vệ sinh hành lang',       50000,  N'phòng/tháng', 1, 'cleaning_services', 'active', GETDATE(), GETDATE()),
('srv_wifi',    NULL, N'Internet / Wifi',      N'Wifi tốc độ cao từng tầng',                100000, N'phòng/tháng', 0, 'wifi',              'active', GETDATE(), GETDATE()),
('srv_parking', NULL, N'Gửi xe máy',           N'Giữ xe trong nhà / hầm xe có camera',      100000, N'xe/tháng',    0, 'two_wheeler',       'active', GETDATE(), GETDATE());
GO

INSERT INTO dbo.property_services (id, property_id, service_id, price, status, created_at, updated_at) VALUES
('ps_01', 'prop_01', 'srv_elec',    3500,   'active', GETDATE(), GETDATE()),
('ps_02', 'prop_01', 'srv_water',   20000,  'active', GETDATE(), GETDATE()),
('ps_03', 'prop_01', 'srv_garbage', 50000,  'active', GETDATE(), GETDATE()),
('ps_04', 'prop_01', 'srv_wifi',    100000, 'active', GETDATE(), GETDATE()),
('ps_05', 'prop_01', 'srv_parking', 100000, 'active', GETDATE(), GETDATE()),
('ps_06', 'prop_02', 'srv_elec',    3800,   'active', GETDATE(), GETDATE()),
('ps_07', 'prop_02', 'srv_water',   22000,  'active', GETDATE(), GETDATE()),
('ps_08', 'prop_02', 'srv_garbage', 60000,  'active', GETDATE(), GETDATE()),
('ps_09', 'prop_02', 'srv_wifi',    120000, 'active', GETDATE(), GETDATE()),
('ps_10', 'prop_03', 'srv_elec',    4000,   'active', GETDATE(), GETDATE()),
('ps_11', 'prop_03', 'srv_water',   25000,  'active', GETDATE(), GETDATE());
GO

INSERT INTO dbo.room_services (id, room_id, service_id, created_at, updated_at) VALUES
('rs_01', 'room_101', 'srv_elec',    GETDATE(), GETDATE()),
('rs_02', 'room_101', 'srv_water',   GETDATE(), GETDATE()),
('rs_03', 'room_101', 'srv_garbage', GETDATE(), GETDATE()),
('rs_04', 'room_101', 'srv_wifi',    GETDATE(), GETDATE()),
('rs_05', 'room_102', 'srv_elec',    GETDATE(), GETDATE()),
('rs_06', 'room_102', 'srv_water',   GETDATE(), GETDATE()),
('rs_07', 'room_a1',  'srv_elec',    GETDATE(), GETDATE()),
('rs_08', 'room_a1',  'srv_water',   GETDATE(), GETDATE()),
('rs_09', 'room_a1',  'srv_wifi',    GETDATE(), GETDATE());
GO

-- 7. Tin đăng cho thuê & Ảnh tin đăng (đủ published, pending cho Admin duyệt, rejected)
INSERT INTO dbo.rental_posts (id, room_id, title, description, price, amenities, views, submit_note, status, rejection_reason, published_at, expired_at, created_at, updated_at) VALUES
('post_01', 'room_101', N'Cho thuê phòng trọ khép kín Tân Phú giá tốt',      N'Phòng sạch sẽ, giờ giấc tự do, không chung chủ, có gác lửng cao.',          3200000, N'Wifi tốc độ cao,Chỗ để xe máy,Gác lửng cao,Giờ giấc tự do', 214, N'Đã bổ sung giấy kiểm định PCCC',    'published', NULL, DATEADD(day, -35, GETDATE()), DATEADD(day, 25, GETDATE()), DATEADD(day, -35, GETDATE()), GETDATE()),
('post_02', 'room_102', N'Phòng trọ ban công thoáng mát gần ĐH Công Thương',  N'Phù hợp cho sinh viên và nhân viên văn phòng, bảo vệ an ninh 24/7.',       3500000, N'Wifi tốc độ cao,Chỗ để xe máy,Ban công / Cửa sổ,Camera an ninh', 158, N'Đăng tin phòng giá sinh viên', 'published', NULL, DATEADD(day, -20, GETDATE()), DATEADD(day, 40, GETDATE()), DATEADD(day, -20, GETDATE()), GETDATE()),
('post_03', 'room_201', N'Phòng lầu 2 yên tĩnh dưới 3 triệu, view cây xanh',  N'Gần chợ Tây Thạnh, đường rộng thoáng, giờ giấc tự do 24/24.',              2900000, N'Wifi tốc độ cao,Giờ giấc tự do,Khóa vân tay / Thẻ từ',        95,  NULL,                                'published', NULL, DATEADD(day, -10, GETDATE()), DATEADD(day, 50, GETDATE()), DATEADD(day, -10, GETDATE()), GETDATE()),
('post_04', 'room_a1',  N'Studio cao cấp full nội thất Sơn Kỳ',               N'Chỉ cần xách vali vào ở, máy lạnh Inverter, tủ lạnh, bàn làm việc.',       5200000, N'Wifi tốc độ cao,Máy lạnh,Máy giặt chung,Tủ lạnh riêng,Thang máy', 312, NULL,                              'published', NULL, DATEADD(day, -25, GETDATE()), DATEADD(day, 35, GETDATE()), DATEADD(day, -25, GETDATE()), GETDATE()),
('post_05', 'room_a2',  N'Căn hộ dịch vụ Studio A2 ban công rộng',            N'Căn hộ mới bàn giao, ban công lớn đón gió tự nhiên, tòa nhà có thang máy.', 4800000, N'Wifi tốc độ cao,Thang máy,Ban công / Cửa sổ',                45,  N'Đang chờ Admin thẩm định tiêu chuẩn', 'pending',  NULL, NULL,                         NULL,                        DATEADD(day, -2,  GETDATE()), GETDATE()),
('post_06', 'room_202', N'Phòng trọ 202 gần khu công nghiệp Tân Bình',        N'Phòng mát mẻ, tiện đi làm khu vực Tân Phú - Tân Bình.',                    3100000, N'Wifi tốc độ cao,Máy lạnh',                                     12,  N'Xin duyệt lại tin',                 'rejected',  N'Hình ảnh phòng chưa rõ nét và thiếu thông tin chi phí dịch vụ', NULL, NULL, DATEADD(day, -3, GETDATE()), GETDATE()),
('post_07', 'room_b1',  N'Cho thuê căn hộ 1PN VIP Cộng Hòa, Tân Bình',        N'Căn hộ cao cấp ngay mặt tiền Cộng Hòa, full nội thất sang trọng.',         6000000, N'Máy lạnh,Thang máy,Chỗ để xe máy,Hệ thống PCCC',             18,  N'Đã đính kèm đầy đủ ảnh thực tế',    'pending',   NULL, NULL,                         NULL,                        DATEADD(day, -1,  GETDATE()), GETDATE());
GO

INSERT INTO dbo.rental_post_images (id, rental_post_id, image_path, is_thumbnail, sort_order, created_at, updated_at) VALUES
('img_01', 'post_01', 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267', 1, 0, GETDATE(), GETDATE()),
('img_02', 'post_02', 'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688', 1, 0, GETDATE(), GETDATE()),
('img_03', 'post_03', 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2', 1, 0, GETDATE(), GETDATE()),
('img_04', 'post_04', 'https://images.unsplash.com/photo-1493809842364-78817add7ffb', 1, 0, GETDATE(), GETDATE()),
('img_05', 'post_05', 'https://images.unsplash.com/photo-1536376072261-38c75010e6c9', 1, 0, GETDATE(), GETDATE()),
('img_06', 'post_06', 'https://images.unsplash.com/photo-1513694203232-719a280e022f', 1, 0, GETDATE(), GETDATE()),
('img_07', 'post_07', 'https://images.unsplash.com/photo-1505691938895-1758d7feb511', 1, 0, GETDATE(), GETDATE());
GO

-- 8. Lịch hẹn xem phòng
INSERT INTO dbo.viewing_appointments (id, room_id, tenant_id, appointment_date, appointment_time, phone, message, status, owner_note, confirmed_at, completed_at, created_at, updated_at) VALUES
('apt_01', 'room_102', 'usr_tenant4', CAST(GETDATE() AS DATE),                 '15:00:00', '0977889900', N'Tôi muốn xem Phòng 102 lúc 3h chiều nay.',          'confirmed', N'Đã hẹn gặp tại cổng chính', GETDATE(),                    NULL,                       DATEADD(day, -1,  GETDATE()), GETDATE()),
('apt_02', 'room_a2',  'usr_tenant3', DATEADD(day, 1, CAST(GETDATE() AS DATE)), '09:30:00', '0966554433', N'Cho em xin lịch hẹn xem căn Studio A2 sáng mai.',   'pending',   NULL,                         NULL,                         NULL,                       GETDATE(),                    GETDATE()),
('apt_03', 'room_201', 'usr_tenant4', DATEADD(day, 2, CAST(GETDATE() AS DATE)), '16:00:00', '0977889900', N'Muốn xem thêm Phòng 201 để so sánh giá.',           'confirmed', N'OK, gặp tại sảnh tầng 1',   GETDATE(),                    NULL,                       DATEADD(day, -2,  GETDATE()), GETDATE()),
('apt_04', 'room_101', 'usr_tenant1', DATEADD(day, -32, CAST(GETDATE() AS DATE)), '10:00:00', '0933112233', N'Hẹn xem Phòng 101 trước khi ký hợp đồng.',         'completed', N'Khách đã chốt thuê',        DATEADD(day, -32, GETDATE()), DATEADD(day, -31, GETDATE()), DATEADD(day, -33, GETDATE()), GETDATE()),
('apt_05', 'room_202', 'usr_tenant3', DATEADD(day, -1, CAST(GETDATE() AS DATE)),  '14:00:00', '0966554433', N'Xem Phòng 202, dự kiến dọn vào đầu tháng.',        'completed', N'Đã gửi hợp đồng chờ ký',    DATEADD(day, -2,  GETDATE()), DATEADD(day, -1,  GETDATE()), DATEADD(day, -3,  GETDATE()), GETDATE());
GO

-- 9. Hợp đồng (2 Đang hiệu lực, 1 Chờ ký, 1 Đã thanh lý)
INSERT INTO dbo.contracts (id, contract_code, viewing_appointment_id, room_id, owner_id, tenant_id, start_date, end_date, rent, deposit, payment_cycle, terms, status, signed_at, terminated_at, initial_electricity_reading, initial_water_reading, owner_signature, created_at, updated_at) VALUES
('ctr_01', 'HD-2026-001', 'apt_04', 'room_101', 'usr_owner1', 'usr_tenant1', DATEADD(day, -30, CAST(GETDATE() AS DATE)), DATEADD(day, 335, CAST(GETDATE() AS DATE)), 3200000, 3200000, 'monthly', N'CCCD:079099001122|IssueDate:12/04/2021|IssuePlace:Cục CSQLHC về TTXH', 'active',     DATEADD(day, -30, GETDATE()), NULL,                       1200, 50,  NULL, DATEADD(day, -30, GETDATE()), GETDATE()),
('ctr_02', 'HD-2026-002', NULL,     'room_a1',  'usr_owner1', 'usr_tenant2', DATEADD(day, -20, CAST(GETDATE() AS DATE)), DATEADD(day, 160, CAST(GETDATE() AS DATE)), 5200000, 5200000, 'monthly', N'CCCD:079098002233|IssueDate:20/08/2022|IssuePlace:Cục CSQLHC về TTXH', 'active',     DATEADD(day, -20, GETDATE()), NULL,                       450,  20,  NULL, DATEADD(day, -20, GETDATE()), GETDATE()),
('ctr_03', 'HD-2026-003', 'apt_05', 'room_202', 'usr_owner1', 'usr_tenant3', CAST(GETDATE() AS DATE),                  DATEADD(day, 365, CAST(GETDATE() AS DATE)), 3100000, 3100000, 'monthly', N'CCCD:079199003344|IssueDate:10/01/2023|IssuePlace:Cục CSQLHC về TTXH', 'pending',    NULL,                         NULL,                       100,  10,  NULL, DATEADD(hour, -5,  GETDATE()), GETDATE()),
('ctr_04', 'HD-2025-099', NULL,     'room_102', 'usr_owner1', 'usr_tenant4', DATEADD(day, -200, CAST(GETDATE() AS DATE)), DATEADD(day, -15, CAST(GETDATE() AS DATE)), 3500000, 3500000, 'monthly', N'CCCD:079097004455|IssueDate:05/05/2020|IssuePlace:Cục CSQLHC về TTXH', 'terminated', DATEADD(day, -200, GETDATE()), DATEADD(day, -15, GETDATE()), 800, 30, NULL, DATEADD(day, -200, GETDATE()), DATEADD(day, -15, GETDATE()));
GO

-- Dịch vụ trong hợp đồng
INSERT INTO dbo.contract_services (id, contract_id, service_id, quantity, unit_price, status, created_at, updated_at) VALUES
('cs_01', 'ctr_01', 'srv_elec',    1, 3500,   'active', GETDATE(), GETDATE()),
('cs_02', 'ctr_01', 'srv_water',   1, 20000,  'active', GETDATE(), GETDATE()),
('cs_03', 'ctr_01', 'srv_garbage', 1, 50000,  'active', GETDATE(), GETDATE()),
('cs_04', 'ctr_01', 'srv_wifi',    1, 100000, 'active', GETDATE(), GETDATE()),
('cs_05', 'ctr_02', 'srv_elec',    1, 3800,   'active', GETDATE(), GETDATE()),
('cs_06', 'ctr_02', 'srv_water',   1, 22000,  'active', GETDATE(), GETDATE()),
('cs_07', 'ctr_02', 'srv_garbage', 1, 60000,  'active', GETDATE(), GETDATE()),
('cs_08', 'ctr_02', 'srv_wifi',    1, 120000, 'active', GETDATE(), GETDATE()),
('cs_09', 'ctr_03', 'srv_elec',    1, 3500,   'active', GETDATE(), GETDATE()),
('cs_10', 'ctr_03', 'srv_water',   1, 20000,  'active', GETDATE(), GETDATE());
GO

-- Thành viên ở cùng phòng
INSERT INTO dbo.contract_members (id, contract_id, name, identity_card, phone, relationship, created_at, updated_at) VALUES
('mem_01', 'ctr_01', N'Lê Minh Quân',      '079201009988', '0933998877', N'Em trai', GETDATE(), GETDATE()),
('mem_02', 'ctr_02', N'Nguyễn Thảo Vy',    '079300007766', '0944776655', N'Bạn ở ghép', GETDATE(), GETDATE());
GO

-- Lịch sử thanh lý hợp đồng cũ ctr_04
INSERT INTO dbo.contract_terminations (id, contract_id, deposit_amount, deduction_amount, deduction_reason, refund_amount, return_date, note) VALUES
('term_01', 'ctr_04', 3500000, 150000, N'Khấu trừ phí vệ sinh trả phòng', 3350000, DATEADD(day, -15, CAST(GETDATE() AS DATE)), N'Đã chuyển khoản hoàn cọc đầy đủ cho khách.');
GO

-- 10. Chỉ số điện nước (2 tháng liên tiếp cho Phòng 101 và Studio A1)
INSERT INTO dbo.utility_readings (id, room_id, month, electricity_old, electricity_new, electricity_price, water_old, water_new, water_price, created_at, updated_at) VALUES
('ur_01', 'room_101', DATEADD(month, -1, DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)), 1200, 1280, 3500, 50, 55, 20000, DATEADD(day, -28, GETDATE()), GETDATE()),
('ur_02', 'room_101', DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1),                     1280, 1360, 3500, 55, 60, 20000, GETDATE(),                    GETDATE()),
('ur_03', 'room_a1',  DATEADD(month, -1, DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)), 450,  550,  3800, 20, 26, 22000, DATEADD(day, -28, GETDATE()), GETDATE()),
('ur_04', 'room_a1',  DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1),                     550,  660,  3800, 26, 32, 22000, GETDATE(),                    GETDATE());
GO

-- 11. Hóa đơn (2 đã thanh toán, 1 chưa thanh toán cho VietQR, 1 quá hạn) & Chi tiết + Thanh toán
INSERT INTO dbo.invoices (id, invoice_code, contract_id, utility_reading_id, bank_account_id, billing_month, issue_date, due_date, subtotal, discount, total, status, created_at, updated_at) VALUES
('inv_01', 'INV-2026-001', 'ctr_01', 'ur_01', 'bank_01', DATEADD(month, -1, DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)), DATEADD(day, -30, CAST(GETDATE() AS DATE)), DATEADD(day, -25, CAST(GETDATE() AS DATE)), 3730000, 0, 3730000, 'paid',    DATEADD(day, -30, GETDATE()), GETDATE()),
('inv_02', 'INV-2026-002', 'ctr_01', 'ur_02', 'bank_01', DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1),                     CAST(GETDATE() AS DATE),                  DATEADD(day, 5, CAST(GETDATE() AS DATE)),   3730000, 0, 3730000, 'unpaid',  GETDATE(),                    GETDATE()),
('inv_03', 'INV-2026-003', 'ctr_02', 'ur_03', 'bank_01', DATEADD(month, -1, DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)), DATEADD(day, -28, CAST(GETDATE() AS DATE)), DATEADD(day, -23, CAST(GETDATE() AS DATE)), 5892000, 0, 5892000, 'paid',    DATEADD(day, -28, GETDATE()), GETDATE()),
('inv_04', 'INV-2026-004', 'ctr_02', 'ur_04', 'bank_01', DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1),                     DATEADD(day, -10, CAST(GETDATE() AS DATE)), DATEADD(day, -2, CAST(GETDATE() AS DATE)),  5930000, 0, 5930000, 'overdue', DATEADD(day, -10, GETDATE()), GETDATE());
GO

INSERT INTO dbo.invoice_items (id, invoice_id, type, description, quantity, unit_price, amount, service_id, created_at, updated_at) VALUES
-- inv_01
('item_01', 'inv_01', 'rent',        N'Tiền thuê phòng 101',              1,  3200000, 3200000, NULL,          GETDATE(), GETDATE()),
('item_02', 'inv_01', 'electricity', N'Tiền điện (1280 - 1200 = 80 kWh)', 80, 3500,    280000,  'srv_elec',    GETDATE(), GETDATE()),
('item_03', 'inv_01', 'water',       N'Tiền nước (55 - 50 = 5 m³)',       5,  20000,   100000,  'srv_water',   GETDATE(), GETDATE()),
('item_04', 'inv_01', 'service',     N'Rác & Vệ sinh chung',              1,  50000,   50000,   'srv_garbage', GETDATE(), GETDATE()),
('item_05', 'inv_01', 'service',     N'Internet / Wifi',                  1,  100000,  100000,  'srv_wifi',    GETDATE(), GETDATE()),
-- inv_02 (chưa thanh toán - khách Lê Quốc Việt demo thanh toán)
('item_06', 'inv_02', 'rent',        N'Tiền thuê phòng 101',              1,  3200000, 3200000, NULL,          GETDATE(), GETDATE()),
('item_07', 'inv_02', 'electricity', N'Tiền điện (1360 - 1280 = 80 kWh)', 80, 3500,    280000,  'srv_elec',    GETDATE(), GETDATE()),
('item_08', 'inv_02', 'water',       N'Tiền nước (60 - 55 = 5 m³)',       5,  20000,   100000,  'srv_water',   GETDATE(), GETDATE()),
('item_09', 'inv_02', 'service',     N'Rác & Vệ sinh chung',              1,  50000,   50000,   'srv_garbage', GETDATE(), GETDATE()),
('item_10', 'inv_02', 'service',     N'Internet / Wifi',                  1,  100000,  100000,  'srv_wifi',    GETDATE(), GETDATE()),
-- inv_03
('item_11', 'inv_03', 'rent',        N'Tiền thuê Studio A1',              1,   5200000, 5200000, NULL,          GETDATE(), GETDATE()),
('item_12', 'inv_03', 'electricity', N'Tiền điện (550 - 450 = 100 kWh)',  100, 3800,    380000,  'srv_elec',    GETDATE(), GETDATE()),
('item_13', 'inv_03', 'water',       N'Tiền nước (26 - 20 = 6 m³)',       6,   22000,   132000,  'srv_water',   GETDATE(), GETDATE()),
('item_14', 'inv_03', 'service',     N'Rác & Vệ sinh chung',              1,   60000,   60000,   'srv_garbage', GETDATE(), GETDATE()),
('item_15', 'inv_03', 'service',     N'Internet / Wifi',                  1,   120000,  120000,  'srv_wifi',    GETDATE(), GETDATE()),
-- inv_04 (quá hạn - khách Phạm Minh Tuấn)
('item_16', 'inv_04', 'rent',        N'Tiền thuê Studio A1',              1,   5200000, 5200000, NULL,          GETDATE(), GETDATE()),
('item_17', 'inv_04', 'electricity', N'Tiền điện (660 - 550 = 110 kWh)',  110, 3800,    418000,  'srv_elec',    GETDATE(), GETDATE()),
('item_18', 'inv_04', 'water',       N'Tiền nước (32 - 26 = 6 m³)',       6,   22000,   132000,  'srv_water',   GETDATE(), GETDATE()),
('item_19', 'inv_04', 'service',     N'Rác & Vệ sinh chung',              1,   60000,   60000,   'srv_garbage', GETDATE(), GETDATE()),
('item_20', 'inv_04', 'service',     N'Internet / Wifi',                  1,   120000,  120000,  'srv_wifi',    GETDATE(), GETDATE());
GO

INSERT INTO dbo.payments (id, payment_code, invoice_id, payer_id, amount, method, transaction_code, paid_at, status, created_at, updated_at) VALUES
('pay_01', 'PAY-2026-001', 'inv_01', 'usr_tenant1', 3730000, 'qr',            'MBVCB09128811', DATEADD(day, -26, GETDATE()), 'success', DATEADD(day, -26, GETDATE()), GETDATE()),
('pay_02', 'PAY-2026-002', 'inv_03', 'usr_tenant2', 5892000, 'bank_transfer', 'MBVCB09129922', DATEADD(day, -24, GETDATE()), 'success', DATEADD(day, -24, GETDATE()), GETDATE());
GO

-- 12. Yêu cầu bảo trì / sửa chữa
INSERT INTO dbo.maintenance_requests (id, room_id, tenant_id, title, description, priority, status, image, owner_note, completed_at, created_at, updated_at) VALUES
('mnt_01', 'room_101', 'usr_tenant1', N'Máy lạnh không mát và chảy nước',   N'Dàn lạnh có tiếng ồn lớn và nhỏ giọt nước xuống tường.',     'high',   'pending',    NULL, NULL,                                      NULL,                      DATEADD(hour, -3, GETDATE()), GETDATE()),
('mnt_02', 'room_a1',  'usr_tenant2', N'Vòi nước bồn rửa chén bị rỉ nhẹ',   N'Khớp nối dưới bồn rửa có rò rỉ nước nhỏ giọt.',            'medium', 'processing', NULL, N'Đã gọi thợ nước hẹn chiều nay qua thay.', NULL,                      DATEADD(day, -1,  GETDATE()), GETDATE()),
('mnt_03', 'room_101', 'usr_tenant1', N'Thay bóng đèn hành lang trước cửa', N'Bóng đèn tuýp trước cửa phòng 101 bị chập chờn.',          'low',    'completed',  NULL, N'Đã thay bóng LED mới.',                   DATEADD(day, -5, GETDATE()), DATEADD(day, -6, GETDATE()),  GETDATE());
GO

-- 13. Yêu thích & Đánh giá
INSERT INTO dbo.favorites (id, user_id, room_id, created_at, updated_at) VALUES
('fav_01', 'usr_tenant1', 'room_101', DATEADD(day, -1,  GETDATE()), GETDATE()),
('fav_02', 'usr_tenant2', 'room_102', DATEADD(day, -2,  GETDATE()), GETDATE()),
('fav_03', 'usr_tenant3', 'room_a1',  DATEADD(day, -2,  GETDATE()), GETDATE()),
('fav_04', 'usr_tenant4', 'room_a2',  DATEADD(day, -5,  GETDATE()), GETDATE()),
('fav_05', 'usr_tenant1', 'room_201', DATEADD(day, -7,  GETDATE()), GETDATE()),
('fav_06', 'usr_tenant4', 'room_b1',  DATEADD(day, -12, GETDATE()), GETDATE());
GO

INSERT INTO dbo.reviews (id, room_id, tenant_id, rating, comment, status, created_at, updated_at) VALUES
('rev_01', 'room_101', 'usr_tenant1', 5, N'Chủ nhà thân thiện, phòng sạch sẽ và rất thoáng mát!',               'visible', DATEADD(day, -10, GETDATE()), GETDATE()),
('rev_02', 'room_a1',  'usr_tenant2', 4, N'Nội thất xịn đầy đủ tiện nghi, thang máy êm, bảo vệ nhiệt tình.',   'visible', DATEADD(day, -5,  GETDATE()), GETDATE()),
('rev_03', 'room_102', 'usr_tenant4', 5, N'Phòng rộng, ban công nhiều ánh sáng, giá hợp lý khu vực Tân Phú.',  'visible', DATEADD(day, -16, GETDATE()), GETDATE());
GO

-- 14. Thông báo hệ thống (Admin, Owner, Tenant)
INSERT INTO dbo.notifications (id, user_id, title, message, type, reference_id, reference_type, created_at, updated_at) VALUES
('notif_01',     'usr_admin',   N'Tin đăng mới chờ duyệt',              N'Chủ trọ Nguyễn Văn An vừa đăng tin cho căn Studio A2 và Phòng VIP 1 đang chờ duyệt.',                                     'post_approval',         'post_05', 'rental_post',         DATEADD(minute, -10, GETDATE()), GETDATE()),
('notif_02',     'usr_admin',   N'Tin đăng VIP cần kiểm duyệt',         N'Chủ trọ Trần Thị Mai vừa gửi duyệt tin [Cho thuê căn hộ 1PN VIP Cộng Hòa, Tân Bình].',                                   'post_approval',         'post_07', 'rental_post',         DATEADD(hour, -1,    GETDATE()), GETDATE()),
('notif_own_01', 'usr_owner1',  N'Khách đặt lịch xem phòng mới',        N'Khách Đỗ Hoàng Yến (0966554433) vừa đặt lịch xem Studio A2 - Căn Hộ Mini Xanh vào 09:30 ngày mai.',                      'appointment',           'apt_02',  'viewing_appointment', DATEADD(minute, -15, GETDATE()), GETDATE()),
('notif_own_02', 'usr_owner1',  N'Admin từ chối bài đăng',              N'Tin đăng [Phòng trọ 202 gần khu công nghiệp Tân Bình] bị từ chối. Lý do: Hình ảnh phòng chưa rõ nét.',                   'post_rejected',         'post_06', 'rental_post',         DATEADD(hour, -1,    GETDATE()), GETDATE()),
('notif_own_03', 'usr_owner1',  N'Khách báo hỏng / bảo trì phòng',      N'Khách Lê Quốc Việt (Phòng 101 - Nhà Trọ An Khang) báo sự cố: Máy lạnh không mát và chảy nước.',                          'maintenance',           'mnt_01',  'maintenance',         DATEADD(hour, -3,    GETDATE()), GETDATE()),
('notif_own_04', 'usr_owner1',  N'Hóa đơn tháng trước đã thanh toán',   N'Khách Lê Quốc Việt (Phòng 101) đã thanh toán hóa đơn INV-2026-001 số tiền 3.730.000đ.',                                  'invoice',               'inv_01',  'invoice',             DATEADD(day, -2,     GETDATE()), GETDATE()),
('notif_own2_01','usr_owner2',  N'Tin đăng đang chờ duyệt',             N'Tin [Cho thuê căn hộ 1PN VIP Cộng Hòa, Tân Bình] đã được gửi lên Admin kiểm duyệt.',                                     'post',                  'post_07', 'rental_post',         DATEADD(hour, -2,    GETDATE()), GETDATE()),
('notif_ten_01', 'usr_tenant1', N'Bạn có hóa đơn tiền phòng mới',       N'Hóa đơn tháng hiện tại INV-2026-002 (Phòng 101) số tiền 3.730.000đ đã phát hành. Vui lòng thanh toán trước hạn.',       'invoice_new',           'inv_02',  'invoice',             DATEADD(minute, -30, GETDATE()), GETDATE()),
('notif_ten_02', 'usr_tenant2', N'Nhắc nhở hóa đơn quá hạn',            N'Hóa đơn INV-2026-004 (Studio A1) số tiền 5.930.000đ đã quá hạn thanh toán.',                                             'invoice_overdue',       'inv_04',  'invoice',             DATEADD(hour, -4,    GETDATE()), GETDATE()),
('notif_ten_03', 'usr_tenant3', N'Bạn có hợp đồng thuê phòng cần ký!',  N'Chủ trọ Nguyễn Văn An vừa gửi hợp đồng HD-2026-003 (Phòng 202) cho bạn. Vui lòng kiểm tra và ký xác nhận.',             'contract_pending',      'ctr_03',  'contract',            DATEADD(hour, -5,    GETDATE()), GETDATE());
GO

-- Trigger tự động xếp hàng gửi Firebase Push Notification khi có thông báo mới
CREATE OR ALTER TRIGGER dbo.QueueFirebasePush ON dbo.notifications
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT dbo.push_deliveries (notification_id, token_hash)
    SELECT n.id, d.token_hash
    FROM inserted n
    INNER JOIN dbo.push_devices d ON d.user_id = n.user_id
    WHERE n.read_at IS NULL;
END;
GO

-- ============================================================================
-- PHẦN 3: KIỂM TRA SỐ LƯỢNG BẢN GHI SAU KHI KHỞI TẠO
-- ============================================================================
SELECT N'users' AS Bang, COUNT(*) AS SoBanGhi FROM dbo.users
UNION ALL SELECT N'properties', COUNT(*) FROM dbo.properties
UNION ALL SELECT N'rooms', COUNT(*) FROM dbo.rooms
UNION ALL SELECT N'amenities', COUNT(*) FROM dbo.amenities
UNION ALL SELECT N'services', COUNT(*) FROM dbo.services
UNION ALL SELECT N'rental_posts', COUNT(*) FROM dbo.rental_posts
UNION ALL SELECT N'rental_post_images', COUNT(*) FROM dbo.rental_post_images
UNION ALL SELECT N'viewing_appointments', COUNT(*) FROM dbo.viewing_appointments
UNION ALL SELECT N'contracts', COUNT(*) FROM dbo.contracts
UNION ALL SELECT N'contract_members', COUNT(*) FROM dbo.contract_members
UNION ALL SELECT N'utility_readings', COUNT(*) FROM dbo.utility_readings
UNION ALL SELECT N'invoices', COUNT(*) FROM dbo.invoices
UNION ALL SELECT N'payments', COUNT(*) FROM dbo.payments
UNION ALL SELECT N'maintenance_requests', COUNT(*) FROM dbo.maintenance_requests
UNION ALL SELECT N'favorites', COUNT(*) FROM dbo.favorites
UNION ALL SELECT N'reviews', COUNT(*) FROM dbo.reviews
UNION ALL SELECT N'notifications', COUNT(*) FROM dbo.notifications;
GO
