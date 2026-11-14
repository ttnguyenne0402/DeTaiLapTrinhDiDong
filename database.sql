-- ============================================================
-- SCRIPT CƠ SỞ DỮ LIỆU ĐẦY ĐỦ: QUẢN LÝ PHÒNG TRỌ (SQL SERVER)
-- TỔNG HỢP TOÀN BỘ CẤU TRÚC (DDL), KHÓA NGOẠI, CẬP NHẬT MỚI & DỮ LIỆU MẪU (DML)
-- ============================================================

USE master;
GO

IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'QuanLyPhongTro')
BEGIN
    CREATE DATABASE QuanLyPhongTro;
END
GO

USE QuanLyPhongTro;
GO

-- ============================================================
-- PHẦN 1: TẠO CẤU TRÚC BẢNG (TABLE SCHEMA)
-- ============================================================

-- 1. Bảng users: Tài khoản người dùng (bao gồm google_id, zalo_id)
IF OBJECT_ID('dbo.users', 'U') IS NULL
BEGIN
    CREATE TABLE users (
        id NVARCHAR(50) PRIMARY KEY,
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

    CREATE UNIQUE INDEX UQ_users_google_id ON users (google_id) WHERE google_id IS NOT NULL;
    CREATE UNIQUE INDEX UX_users_zalo_id ON users (zalo_id) WHERE zalo_id IS NOT NULL;
END
GO

-- 2. Bảng properties: Bất động sản / Khu trọ (bao gồm image)
IF OBJECT_ID('dbo.properties', 'U') IS NULL
BEGIN
    CREATE TABLE properties (
        id NVARCHAR(50) PRIMARY KEY,
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
        CONSTRAINT FK_properties_users FOREIGN KEY (owner_id) REFERENCES users(id)
    );
END
GO

-- 3. Bảng rooms: Phòng / Căn hộ
IF OBJECT_ID('dbo.rooms', 'U') IS NULL
BEGIN
    CREATE TABLE rooms (
        id NVARCHAR(50) PRIMARY KEY,
        property_id NVARCHAR(50) NOT NULL,
        name VARCHAR(100) NOT NULL,
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
        CONSTRAINT FK_rooms_properties FOREIGN KEY (property_id) REFERENCES properties(id)
    );
END
GO

-- 4. Bảng amenities: Danh mục tiện nghi
IF OBJECT_ID('dbo.amenities', 'U') IS NULL
BEGIN
    CREATE TABLE amenities (
        id NVARCHAR(50) PRIMARY KEY,
        name NVARCHAR(100) NOT NULL UNIQUE,
        description NVARCHAR(MAX) NULL,
        status NVARCHAR(50) NOT NULL CHECK (status IN ('active', 'inactive')),
        created_at DATETIME2 DEFAULT GETDATE(),
        updated_at DATETIME2 DEFAULT GETDATE()
    );
END
GO

-- 5. Bảng room_amenities: Liên kết Phòng - Tiện nghi
IF OBJECT_ID('dbo.room_amenities', 'U') IS NULL
BEGIN
    CREATE TABLE room_amenities (
        id NVARCHAR(50) PRIMARY KEY,
        room_id NVARCHAR(50) NOT NULL,
        amenity_id NVARCHAR(50) NOT NULL,
        created_at DATETIME2 DEFAULT GETDATE(),
        updated_at DATETIME2 DEFAULT GETDATE(),
        CONSTRAINT FK_room_amenities_rooms FOREIGN KEY (room_id) REFERENCES rooms(id),
        CONSTRAINT FK_room_amenities_amenities FOREIGN KEY (amenity_id) REFERENCES amenities(id)
    );
END
GO

-- 6. Bảng rental_posts: Tin đăng cho thuê (bao gồm price, amenities, views, submit_note)
IF OBJECT_ID('dbo.rental_posts', 'U') IS NULL
BEGIN
    CREATE TABLE rental_posts (
        id NVARCHAR(50) PRIMARY KEY,
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
        created_at DATETIME2 DEFAULT GETDATE(),
        updated_at DATETIME2 DEFAULT GETDATE(),
        CONSTRAINT FK_rental_posts_rooms FOREIGN KEY (room_id) REFERENCES rooms(id)
    );
END
ELSE
BEGIN
    IF COL_LENGTH('dbo.rental_posts', 'price') IS NULL
        ALTER TABLE dbo.rental_posts ADD price DECIMAL(15,2) NULL;
    IF COL_LENGTH('dbo.rental_posts', 'amenities') IS NULL
        ALTER TABLE dbo.rental_posts ADD amenities NVARCHAR(MAX) NULL;
    IF COL_LENGTH('dbo.rental_posts', 'expired_at') IS NOT NULL
        ALTER TABLE dbo.rental_posts DROP COLUMN expired_at;
END
GO

-- 7. Bảng rental_post_images: Ảnh của tin đăng
IF OBJECT_ID('dbo.rental_post_images', 'U') IS NULL
BEGIN
    CREATE TABLE rental_post_images (
        id NVARCHAR(50) PRIMARY KEY,
        rental_post_id NVARCHAR(50) NOT NULL,
        image_path NVARCHAR(255) NOT NULL,
        is_thumbnail BIT DEFAULT 0,
        sort_order INT DEFAULT 0,
        created_at DATETIME2 DEFAULT GETDATE(),
        updated_at DATETIME2 DEFAULT GETDATE(),
        CONSTRAINT FK_rental_post_images_posts FOREIGN KEY (rental_post_id) REFERENCES rental_posts(id)
    );
END
GO

-- 8. Bảng viewing_appointments: Đặt lịch xem phòng
IF OBJECT_ID('dbo.viewing_appointments', 'U') IS NULL
BEGIN
    CREATE TABLE viewing_appointments (
        id NVARCHAR(50) PRIMARY KEY,
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
        CONSTRAINT FK_viewing_appointments_rooms FOREIGN KEY (room_id) REFERENCES rooms(id),
        CONSTRAINT FK_viewing_appointments_users FOREIGN KEY (tenant_id) REFERENCES users(id)
    );
END
GO

-- 9. Bảng contracts: Hợp đồng thuê phòng (bao gồm chữ ký điện tử owner/tenant)
IF OBJECT_ID('dbo.contracts', 'U') IS NULL
BEGIN
    CREATE TABLE contracts (
        id NVARCHAR(50) PRIMARY KEY,
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
        status NVARCHAR(50) NOT NULL CHECK (status IN ('draft', 'active', 'expired', 'terminated')),
        signed_at DATETIME2 NULL,
        terminated_at DATETIME2 NULL,
        initial_electricity_reading DECIMAL(10,2) NOT NULL DEFAULT 0,
        initial_water_reading DECIMAL(10,2) NOT NULL DEFAULT 0,
        owner_signature NVARCHAR(MAX) NULL,
        tenant_signature NVARCHAR(MAX) NULL,
        created_at DATETIME2 DEFAULT GETDATE(),
        updated_at DATETIME2 DEFAULT GETDATE(),
        CONSTRAINT FK_contracts_appointments FOREIGN KEY (viewing_appointment_id) REFERENCES viewing_appointments(id),
        CONSTRAINT FK_contracts_rooms FOREIGN KEY (room_id) REFERENCES rooms(id),
        CONSTRAINT FK_contracts_owner FOREIGN KEY (owner_id) REFERENCES users(id),
        CONSTRAINT FK_contracts_tenant FOREIGN KEY (tenant_id) REFERENCES users(id)
    );
END
GO

-- 10. Bảng services: Dịch vụ chung/chủ nhà tự tạo (bao gồm price, is_mandatory, icon)
IF OBJECT_ID('dbo.services', 'U') IS NULL
BEGIN
    CREATE TABLE services (
        id NVARCHAR(50) PRIMARY KEY,
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
        CONSTRAINT FK_services_users FOREIGN KEY (owner_id) REFERENCES users(id)
    );
END
GO

-- 11. Bảng property_services: Dịch vụ cấu hình theo từng khu trọ
IF OBJECT_ID('dbo.property_services', 'U') IS NULL
BEGIN
    CREATE TABLE property_services (
        id NVARCHAR(50) PRIMARY KEY,
        property_id NVARCHAR(50) NOT NULL,
        service_id NVARCHAR(50) NOT NULL,
        price DECIMAL(15,2) NOT NULL,
        status NVARCHAR(50) NOT NULL CHECK (status IN ('active', 'inactive')),
        created_at DATETIME2 DEFAULT GETDATE(),
        updated_at DATETIME2 DEFAULT GETDATE(),
        CONSTRAINT FK_property_services_properties FOREIGN KEY (property_id) REFERENCES properties(id),
        CONSTRAINT FK_property_services_services FOREIGN KEY (service_id) REFERENCES services(id)
    );
END
GO

-- 12. Bảng contract_services: Dịch vụ áp dụng trong Hợp đồng
IF OBJECT_ID('dbo.contract_services', 'U') IS NULL
BEGIN
    CREATE TABLE contract_services (
        id NVARCHAR(50) PRIMARY KEY,
        contract_id NVARCHAR(50) NOT NULL,
        service_id NVARCHAR(50) NOT NULL,
        quantity DECIMAL(10,2) DEFAULT 1,
        unit_price DECIMAL(15,2) NOT NULL,
        status NVARCHAR(50) NOT NULL CHECK (status IN ('active', 'inactive')),
        created_at DATETIME2 DEFAULT GETDATE(),
        updated_at DATETIME2 DEFAULT GETDATE(),
        CONSTRAINT FK_contract_services_contracts FOREIGN KEY (contract_id) REFERENCES contracts(id),
        CONSTRAINT FK_contract_services_services FOREIGN KEY (service_id) REFERENCES services(id)
    );
END
GO

-- 13. Bảng utility_readings: Chỉ số điện/nước hàng tháng
IF OBJECT_ID('dbo.utility_readings', 'U') IS NULL
BEGIN
    CREATE TABLE utility_readings (
        id NVARCHAR(50) PRIMARY KEY,
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
        CONSTRAINT FK_utility_readings_rooms FOREIGN KEY (room_id) REFERENCES rooms(id)
    );
END
GO

-- 14. Bảng bank_accounts: Tài khoản ngân hàng (VietQR / Quyết toán)
IF OBJECT_ID('dbo.bank_accounts', 'U') IS NULL
BEGIN
    CREATE TABLE bank_accounts (
        id NVARCHAR(50) PRIMARY KEY,
        user_id NVARCHAR(50) NOT NULL,
        bank_code NVARCHAR(20) NOT NULL,
        bank_name NVARCHAR(100) NULL,
        account_number NVARCHAR(30) NOT NULL,
        account_holder NVARCHAR(100) NOT NULL,
        is_default BIT NOT NULL DEFAULT 0,
        status NVARCHAR(50) NOT NULL CHECK (status IN ('active', 'inactive')),
        created_at DATETIME2 DEFAULT GETDATE(),
        updated_at DATETIME2 DEFAULT GETDATE(),
        CONSTRAINT FK_bank_accounts_users FOREIGN KEY (user_id) REFERENCES users(id)
    );
END
GO

-- 15. Bảng invoices: Hóa đơn thanh toán (đã có bank_account_id)
IF OBJECT_ID('dbo.invoices', 'U') IS NULL
BEGIN
    CREATE TABLE invoices (
        id NVARCHAR(50) PRIMARY KEY,
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
        CONSTRAINT FK_invoices_contracts FOREIGN KEY (contract_id) REFERENCES contracts(id),
        CONSTRAINT FK_invoices_readings FOREIGN KEY (utility_reading_id) REFERENCES utility_readings(id),
        CONSTRAINT FK_invoices_bank_accounts FOREIGN KEY (bank_account_id) REFERENCES bank_accounts(id)
    );
END
GO

-- 16. Bảng invoice_items: Chi tiết khoản thu trên hóa đơn
IF OBJECT_ID('dbo.invoice_items', 'U') IS NULL
BEGIN
    CREATE TABLE invoice_items (
        id NVARCHAR(50) PRIMARY KEY,
        invoice_id NVARCHAR(50) NOT NULL,
        type NVARCHAR(50) NOT NULL CHECK (type IN ('rent', 'electricity', 'water', 'service', 'other')),
        description NVARCHAR(255) NULL,
        quantity DECIMAL(10,2) DEFAULT 1,
        unit_price DECIMAL(15,2) NOT NULL,
        amount DECIMAL(15,2) NOT NULL,
        service_id NVARCHAR(50) NULL,
        created_at DATETIME2 DEFAULT GETDATE(),
        updated_at DATETIME2 DEFAULT GETDATE(),
        CONSTRAINT FK_invoice_items_invoices FOREIGN KEY (invoice_id) REFERENCES invoices(id),
        CONSTRAINT FK_invoice_items_services FOREIGN KEY (service_id) REFERENCES services(id)
    );
END
GO

-- 17. Bảng payments: Giao dịch thanh toán
IF OBJECT_ID('dbo.payments', 'U') IS NULL
BEGIN
    CREATE TABLE payments (
        id NVARCHAR(50) PRIMARY KEY,
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
        CONSTRAINT FK_payments_invoices FOREIGN KEY (invoice_id) REFERENCES invoices(id),
        CONSTRAINT FK_payments_users FOREIGN KEY (payer_id) REFERENCES users(id)
    );
END
GO

-- 18. Bảng maintenance_requests: Yêu cầu sửa chữa (image VARCHAR(MAX))
IF OBJECT_ID('dbo.maintenance_requests', 'U') IS NULL
BEGIN
    CREATE TABLE maintenance_requests (
        id NVARCHAR(50) PRIMARY KEY,
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
        CONSTRAINT FK_maintenance_rooms FOREIGN KEY (room_id) REFERENCES rooms(id),
        CONSTRAINT FK_maintenance_users FOREIGN KEY (tenant_id) REFERENCES users(id)
    );
END
GO

-- 19. Bảng reviews: Đánh giá chất lượng phòng
IF OBJECT_ID('dbo.reviews', 'U') IS NULL
BEGIN
    CREATE TABLE reviews (
        id NVARCHAR(50) PRIMARY KEY,
        room_id NVARCHAR(50) NOT NULL,
        tenant_id NVARCHAR(50) NOT NULL,
        rating TINYINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
        comment NVARCHAR(MAX) NULL,
        status NVARCHAR(50) NOT NULL CHECK (status IN ('visible', 'hidden')),
        created_at DATETIME2 DEFAULT GETDATE(),
        updated_at DATETIME2 DEFAULT GETDATE(),
        CONSTRAINT FK_reviews_rooms FOREIGN KEY (room_id) REFERENCES rooms(id),
        CONSTRAINT FK_reviews_users FOREIGN KEY (tenant_id) REFERENCES users(id)
    );
END
GO

-- 20. Bảng favorites: Phòng yêu thích
IF OBJECT_ID('dbo.favorites', 'U') IS NULL
BEGIN
    CREATE TABLE favorites (
        id NVARCHAR(50) PRIMARY KEY,
        user_id NVARCHAR(50) NOT NULL,
        room_id NVARCHAR(50) NOT NULL,
        created_at DATETIME2 DEFAULT GETDATE(),
        updated_at DATETIME2 DEFAULT GETDATE(),
        CONSTRAINT FK_favorites_users FOREIGN KEY (user_id) REFERENCES users(id),
        CONSTRAINT FK_favorites_rooms FOREIGN KEY (room_id) REFERENCES rooms(id)
    );
END
GO

-- 21. Bảng notifications: Thông báo hệ thống
IF OBJECT_ID('dbo.notifications', 'U') IS NULL
BEGIN
    CREATE TABLE notifications (
        id NVARCHAR(50) PRIMARY KEY,
        user_id NVARCHAR(50) NOT NULL,
        title NVARCHAR(200) NOT NULL,
        message NVARCHAR(MAX) NOT NULL,
        type NVARCHAR(50) NOT NULL,
        reference_id NVARCHAR(50) NULL,
        reference_type NVARCHAR(50) NULL,
        read_at DATETIME2 NULL,
        created_at DATETIME2 DEFAULT GETDATE(),
        updated_at DATETIME2 DEFAULT GETDATE(),
        CONSTRAINT FK_notifications_users FOREIGN KEY (user_id) REFERENCES users(id)
    );
END
GO

-- 22. Bảng contract_members: Danh sách người ở cùng
IF OBJECT_ID('dbo.contract_members', 'U') IS NULL
BEGIN
    CREATE TABLE contract_members (
        id NVARCHAR(50) PRIMARY KEY,
        contract_id NVARCHAR(50) NOT NULL,
        name NVARCHAR(100) NOT NULL,
        identity_card NVARCHAR(20) NOT NULL,
        phone NVARCHAR(20) NULL,
        relationship NVARCHAR(50) NULL,
        created_at DATETIME2 DEFAULT GETDATE(),
        updated_at DATETIME2 DEFAULT GETDATE(),
        CONSTRAINT FK_contract_members_contracts FOREIGN KEY (contract_id) REFERENCES contracts(id)
    );
END
GO

-- 23. Bảng contract_terminations: Thanh lý & Quyết toán cọc
IF OBJECT_ID('dbo.contract_terminations', 'U') IS NULL
BEGIN
    CREATE TABLE contract_terminations (
        id NVARCHAR(50) PRIMARY KEY,
        contract_id NVARCHAR(50) NOT NULL,
        deposit_amount DECIMAL(15,2) NOT NULL,
        deduction_amount DECIMAL(15,2) DEFAULT 0,
        deduction_reason NVARCHAR(MAX) NULL,
        refund_amount DECIMAL(15,2) NOT NULL,
        return_date DATE NOT NULL,
        note NVARCHAR(MAX) NULL,
        CONSTRAINT FK_terminations_contracts FOREIGN KEY (contract_id) REFERENCES contracts(id)
    );
END
GO

-- ============================================================
-- PHẦN 2: DỮ LIỆU MẪU ĐỒNG BỘ (SAMPLE SEED DATA)
-- ============================================================

-- 1. Users
IF NOT EXISTS (SELECT 1 FROM users WHERE id = 'usr_admin')
BEGIN
    INSERT INTO users (id, name, email, password, phone, avatar, role, status, email_verified_at, created_at, updated_at) VALUES
    ('usr_admin', N'Quản trị viên Hệ thống', 'admin@phongtro.vn', '123456', '0901234567', 'https://i.pravatar.cc/150?img=1', 'admin', 'active', GETDATE(), DATEADD(day, -60, GETDATE()), GETDATE()),
    ('usr_owner1', N'Nguyễn Văn An', 'an.nguyen@gmail.com', '123456', '0912345678', 'https://i.pravatar.cc/150?img=2', 'owner', 'active', GETDATE(), DATEADD(day, -45, GETDATE()), GETDATE()),
    ('USER_OWNER_01', N'Nguyễn Văn An', 'owner@quanlyphongtro.vn', '123456', '0901234567', 'https://i.pravatar.cc/150?img=2', 'owner', 'active', GETDATE(), DATEADD(day, -45, GETDATE()), GETDATE()),
    ('usr_owner2', N'Trần Thị Mai', 'mai.tran@gmail.com', '123456', '0987654321', 'https://i.pravatar.cc/150?img=3', 'owner', 'active', GETDATE(), DATEADD(day, -40, GETDATE()), GETDATE()),
    ('usr_tenant1', N'Lê Quốc Việt', 'viet.le@gmail.com', '123456', '0933112233', 'https://i.pravatar.cc/150?img=4', 'tenant', 'active', GETDATE(), DATEADD(day, -30, GETDATE()), GETDATE()),
    ('usr_tenant2', N'Phạm Minh Tuấn', 'tuan.pham@gmail.com', '123456', '0944223344', 'https://i.pravatar.cc/150?img=5', 'tenant', 'active', GETDATE(), DATEADD(day, -25, GETDATE()), GETDATE()),
    ('usr_tenant3', N'Đỗ Hoàng Yến', 'yen.do@gmail.com', '123456', '0966554433', 'https://i.pravatar.cc/150?img=6', 'tenant', 'active', GETDATE(), DATEADD(day, -10, GETDATE()), GETDATE()),
    ('usr_tenant4', N'Hoàng Đức Trọng', 'trong.hoang@gmail.com', '123456', '0977889900', 'https://i.pravatar.cc/150?img=7', 'tenant', 'active', GETDATE(), DATEADD(day, -5, GETDATE()), GETDATE());
END
GO

-- 2. Bank Accounts (Tài khoản ngân hàng của chủ trọ)
IF NOT EXISTS (SELECT 1 FROM bank_accounts WHERE id = 'bank_01')
BEGIN
    INSERT INTO bank_accounts (id, user_id, bank_code, bank_name, account_number, account_holder, is_default, status, created_at, updated_at) VALUES
    ('bank_01', 'usr_owner1', 'MB', N'MB Bank', '0912345678', N'NGUYEN VAN AN', 1, 'active', GETDATE(), GETDATE()),
    ('bank_02', 'usr_owner2', 'TCB', N'Techcombank', '190334888291', N'TRAN THI MAI', 1, 'active', GETDATE(), GETDATE());
END
GO

-- 3. Properties
IF NOT EXISTS (SELECT 1 FROM properties WHERE id = 'prop_01')
BEGIN
    INSERT INTO properties (id, owner_id, name, image, type, address, district, ward, latitude, longitude, description, status, created_at, updated_at) VALUES
    ('prop_01', 'usr_owner1', N'Nhà Trọ An Khang', 'https://images.unsplash.com/photo-1555854877-bab0e564b8d5', 'rooming_house', N'123 Đường Tây Thạnh', N'Tân Phú', N'Tây Thạnh', 10.812345, 106.634567, N'Dãy trọ an ninh, camera 24/7, giờ giấc tự do.', 'active', DATEADD(day, -40, GETDATE()), GETDATE()),
    ('prop_02', 'usr_owner1', N'Căn Hộ Mini Xanh', 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00', 'apartment', N'45/6 Lê Trọng Tấn', N'Tân Phú', N'Sơn Kỳ', 10.805566, 106.628899, N'Căn hộ dịch vụ đầy đủ nội thất, có thang máy và hầm xe.', 'active', DATEADD(day, -35, GETDATE()), GETDATE()),
    ('prop_03', 'usr_owner2', N'Chung Cư Mini Tân Bình', 'https://images.unsplash.com/photo-1512917774080-9991f1c4c750', 'house', N'78 Cộng Hòa', N'Tân Bình', N'Phường 13', 10.801234, 106.645678, N'Gần Etown Cộng Hòa, thuận tiện đi lại sân bay.', 'active', DATEADD(day, -20, GETDATE()), GETDATE());
END
GO

-- 4. Rooms
IF NOT EXISTS (SELECT 1 FROM rooms WHERE id = 'room_101')
BEGIN
    INSERT INTO rooms (id, property_id, name, area, price, deposit, max_people, floor, description, images, status, created_at, updated_at) VALUES
    ('room_101', 'prop_01', 'Phòng 101', 25.0, 3200000, 3200000, 2, 1, N'Phòng tầng trệt, có gác lửng cao, bếp riêng.', 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267', 'rented', DATEADD(day, -38, GETDATE()), GETDATE()),
    ('room_102', 'prop_01', 'Phòng 102', 28.0, 3500000, 3500000, 3, 1, N'Phòng rộng có ban công thoáng mát.', 'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688', 'available', DATEADD(day, -38, GETDATE()), GETDATE()),
    ('room_201', 'prop_01', 'Phòng 201', 22.0, 2900000, 2900000, 2, 2, N'Phòng lầu 1 yên tĩnh, có cửa sổ lớn.', 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2', 'available', DATEADD(day, -30, GETDATE()), GETDATE()),
    ('room_a1',  'prop_02', 'Studio A1',  35.0, 5200000, 5200000, 2, 2, N'Full nội thất cao cấp: máy lạnh, tủ lạnh, giường nệm.', 'https://images.unsplash.com/photo-1493809842364-78817add7ffb', 'rented', DATEADD(day, -28, GETDATE()), GETDATE()),
    ('room_a2',  'prop_02', 'Studio A2',  32.0, 4800000, 4800000, 2, 2, N'Nội thất cơ bản, có ban công riêng view thoáng.', 'https://images.unsplash.com/photo-1536376072261-38c75010e6c9', 'available', DATEADD(day, -15, GETDATE()), GETDATE()),
    ('room_b1',  'prop_03', 'Phòng VIP 1', 40.0, 6000000, 6000000, 4, 3, N'Căn hộ 1 phòng ngủ riêng biệt, bếp tách riêng.', 'https://images.unsplash.com/photo-1505691938895-1758d7feb511', 'pending', DATEADD(day, -5, GETDATE()), GETDATE());
END
GO

-- 5. Amenities & Room Amenities
IF NOT EXISTS (SELECT 1 FROM amenities WHERE id = 'amn_wifi')
BEGIN
    INSERT INTO amenities (id, name, description, status, created_at, updated_at) VALUES
    ('amn_wifi', N'Wifi tốc độ cao', N'Đường truyền cáp quang riêng từng tầng', 'active', GETDATE(), GETDATE()),
    ('amn_ac', N'Máy lạnh', N'Inverter tiết kiệm điện', 'active', GETDATE(), GETDATE()),
    ('amn_wm', N'Máy giặt chung', N'Khu giặt phơi sân thượng', 'active', GETDATE(), GETDATE()),
    ('amn_park', N'Chỗ để xe máy', N'Hầm giữ xe có thẻ từ và bảo vệ', 'active', GETDATE(), GETDATE()),
    ('amn_cam', N'Camera an ninh', N'Giám sát hành lang 24/7', 'active', GETDATE(), GETDATE());

    INSERT INTO room_amenities (id, room_id, amenity_id, created_at, updated_at) VALUES
    ('ra_01', 'room_101', 'amn_wifi', GETDATE(), GETDATE()),
    ('ra_02', 'room_101', 'amn_park', GETDATE(), GETDATE()),
    ('ra_03', 'room_a1',  'amn_wifi', GETDATE(), GETDATE()),
    ('ra_04', 'room_a1',  'amn_ac', GETDATE(), GETDATE()),
    ('ra_05', 'room_a1',  'amn_wm', GETDATE(), GETDATE());
END
GO

-- 6. Rental Posts & Images
IF NOT EXISTS (SELECT 1 FROM rental_posts WHERE id = 'post_01')
BEGIN
    INSERT INTO rental_posts (id, room_id, title, description, price, amenities, views, submit_note, status, rejection_reason, published_at, created_at, updated_at) VALUES
    ('post_01', 'room_101', N'Cho thuê phòng trọ khép kín Tân Phú giá tốt', N'Phòng sạch sẽ, giờ giấc tự do, không chung chủ, có gác lửng.', 3300000, N'Wifi,Điều hòa,Chỗ để xe,Giờ giấc tự do', 214, N'Đã bổ sung giấy kiểm định PCCC', 'published', NULL, DATEADD(day, -35, GETDATE()), DATEADD(day, -35, GETDATE()), GETDATE()),
    ('post_02', 'room_102', N'Phòng trọ ban công thoáng mát gần ĐH Công Thương', N'Phù hợp cho sinh viên, bảo vệ an ninh nghiêm ngặt.', 3500000, N'Wifi,Điều hòa,Chỗ để xe,An ninh 24/7', 158, N'Đăng tin phòng giá sinh viên', 'published', NULL, DATEADD(day, -20, GETDATE()), DATEADD(day, -20, GETDATE()), GETDATE()),
    ('post_03', 'room_201', N'Phòng lầu 1 yên tĩnh, view cây xanh mát mẻ', N'Gần chợ Tây Thạnh, đường rộng ô tô đỗ tận cửa.', 2900000, N'Wifi,Chỗ để xe,Giờ giấc tự do', 95, NULL, 'published', NULL, DATEADD(day, -10, GETDATE()), DATEADD(day, -10, GETDATE()), GETDATE()),
    ('post_04', 'room_a1',  N'Studio cao cấp full nội thất Sơn Kỳ', N'Chỉ cần xách vali vào ở, máy lạnh, tủ lạnh, bàn làm việc.', 5200000, N'Wifi,Điều hòa,Máy giặt,Tủ lạnh,An ninh 24/7', 312, NULL, 'published', NULL, DATEADD(day, -25, GETDATE()), DATEADD(day, -25, GETDATE()), GETDATE()),
    ('post_05', 'room_a2',  N'Căn hộ dịch vụ Studio hiện đại', N'Căn hộ ban công lớn đón gió tự nhiên, tòa nhà có thang máy.', 4800000, N'Wifi,Điều hòa,Máy giặt,Chỗ để xe', 45, N'Đang chờ phê duyệt tiêu chuẩn', 'pending', NULL, NULL, DATEADD(day, -2, GETDATE()), GETDATE()),
    ('post_06', 'room_b1',  N'Cho thuê căn hộ 1PN VIP Cộng Hòa', N'Giá thuê bao gồm phí quản lý, bảo vệ 24/7.', 6000000, N'Wifi,Điều hòa,Tủ lạnh,An ninh 24/7', 12, NULL, 'rejected', N'Hình ảnh phòng mờ và thiếu thông tin chi phí dịch vụ', NULL, DATEADD(day, -1, GETDATE()), GETDATE());

    INSERT INTO rental_post_images (id, rental_post_id, image_path, is_thumbnail, sort_order, created_at, updated_at) VALUES
    ('img_01', 'post_01', 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267', 1, 0, GETDATE(), GETDATE()),
    ('img_02', 'post_02', 'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688', 1, 0, GETDATE(), GETDATE()),
    ('img_03', 'post_04', 'https://images.unsplash.com/photo-1493809842364-78817add7ffb', 1, 0, GETDATE(), GETDATE());
END
GO

-- 7. Viewing Appointments
IF NOT EXISTS (SELECT 1 FROM viewing_appointments WHERE id = 'apt_01')
BEGIN
    INSERT INTO viewing_appointments (id, room_id, tenant_id, appointment_date, appointment_time, phone, message, status, owner_note, confirmed_at, created_at, updated_at) VALUES
    ('apt_01', 'room_102', 'usr_tenant2', CAST(GETDATE() AS DATE), '15:00:00', '0944223344', N'Tôi muốn xem phòng lúc 3h chiều nay.', 'confirmed', N'Đã hẹn gặp tại cổng', GETDATE(), DATEADD(day, -1, GETDATE()), GETDATE()),
    ('apt_02', 'room_a2',  'usr_tenant3', DATEADD(day, 1, CAST(GETDATE() AS DATE)), '09:30:00', '0966554433', N'Cho em xin lịch hẹn xem căn Studio.', 'confirmed', NULL, NULL, GETDATE(), GETDATE()),
    ('apt_03', 'room_101', 'usr_tenant1', CAST(GETDATE() AS DATE), '10:00:00', '0933112233', N'Hẹn xem phòng', 'confirmed', NULL, GETDATE(), DATEADD(day, -1, GETDATE()), GETDATE()),
    ('apt_04', 'room_a1',  'usr_tenant2', CAST(GETDATE() AS DATE), '14:00:00', '0944223344', N'Xem căn hộ Studio', 'pending', NULL, NULL, DATEADD(day, -2, GETDATE()), GETDATE()),
    ('apt_05', 'room_201', 'usr_tenant4', CAST(GETDATE() AS DATE), '16:00:00', '0977889900', N'Xem phòng lầu 1', 'confirmed', NULL, GETDATE(), DATEADD(day, -6, GETDATE()), GETDATE());
END
GO

-- 8. Contracts
IF NOT EXISTS (SELECT 1 FROM contracts WHERE id = 'ctr_01')
BEGIN
    INSERT INTO contracts (id, contract_code, viewing_appointment_id, room_id, owner_id, tenant_id, start_date, end_date, rent, deposit, payment_cycle, terms, status, signed_at, initial_electricity_reading, initial_water_reading, created_at, updated_at) VALUES
    ('ctr_01', 'HD-2026-001', NULL, 'room_101', 'usr_owner1', 'usr_tenant1', DATEADD(day, -30, CAST(GETDATE() AS DATE)), DATEADD(day, 335, CAST(GETDATE() AS DATE)), 3200000, 3200000, 'monthly', N'Quy định chung cư cư xử văn minh, giữ gìn tài sản.', 'active', DATEADD(day, -30, GETDATE()), 125, 18, DATEADD(day, -30, GETDATE()), GETDATE()),
    ('ctr_02', 'HD-2026-002', NULL, 'room_a1',  'usr_owner1', 'usr_tenant2', DATEADD(day, -20, CAST(GETDATE() AS DATE)), DATEADD(day, 160, CAST(GETDATE() AS DATE)), 5200000, 5200000, 'monthly', N'Hợp đồng 6 tháng cọc 1 tháng.', 'active', DATEADD(day, -20, GETDATE()), 0, 0, DATEADD(day, -20, GETDATE()), GETDATE());
END
GO

-- 9. Services & Property Services
IF NOT EXISTS (SELECT 1 FROM services WHERE id = 'srv_elec')
BEGIN
    INSERT INTO services (id, owner_id, name, description, price, unit, is_mandatory, icon, status, created_at, updated_at) VALUES
    ('srv_elec', NULL, N'Điện sinh hoạt', N'Tính theo đồng hồ riêng', 3500, N'kWh', 1, 'bolt', 'active', GETDATE(), GETDATE()),
    ('srv_water', NULL, N'Nước máy', N'Tính theo khối nước sạch', 20000, N'm3', 1, 'water_drop', 'active', GETDATE(), GETDATE()),
    ('srv_garbage', NULL, N'Rác & Vệ sinh chung', N'Thu theo đầu người hoặc phòng', 50000, N'phòng/tháng', 1, 'cleaning_services', 'active', GETDATE(), GETDATE()),
    ('srv_wifi', NULL, N'Internet / Wifi', N'Wifi tốc độ cao từng phòng', 100000, N'phòng/tháng', 0, 'wifi', 'active', GETDATE(), GETDATE());

    INSERT INTO property_services (id, property_id, service_id, price, status, created_at, updated_at) VALUES
    ('ps_01', 'prop_01', 'srv_elec', 3500, 'active', GETDATE(), GETDATE()),
    ('ps_02', 'prop_01', 'srv_water', 20000, 'active', GETDATE(), GETDATE()),
    ('ps_03', 'prop_01', 'srv_garbage', 50000, 'active', GETDATE(), GETDATE()),
    ('ps_04', 'prop_01', 'srv_wifi', 100000, 'active', GETDATE(), GETDATE());
END
GO

-- 10. Contract Services (Gán dịch vụ vào Hợp đồng ctr_01)
IF NOT EXISTS (SELECT 1 FROM contract_services WHERE contract_id = 'ctr_01')
BEGIN
    INSERT INTO contract_services (id, contract_id, service_id, quantity, unit_price, status, created_at, updated_at) VALUES
    ('cs_01', 'ctr_01', 'srv_elec', 1, 3500, 'active', GETDATE(), GETDATE()),
    ('cs_02', 'ctr_01', 'srv_water', 1, 20000, 'active', GETDATE(), GETDATE()),
    ('cs_03', 'ctr_01', 'srv_garbage', 1, 50000, 'active', GETDATE(), GETDATE()),
    ('cs_04', 'ctr_01', 'srv_wifi', 1, 100000, 'active', GETDATE(), GETDATE());
END
GO

-- 11. Utility Readings (Chỉ số điện nước)
IF NOT EXISTS (SELECT 1 FROM utility_readings WHERE id = 'ur_01')
BEGIN
    INSERT INTO utility_readings (id, room_id, month, electricity_old, electricity_new, electricity_price, water_old, water_new, water_price, created_at, updated_at) VALUES
    ('ur_01', 'room_101', DATEADD(month, -1, CAST(GETDATE() AS DATE)), 1200, 1280, 3500, 50, 55, 20000, DATEADD(day, -28, GETDATE()), GETDATE()),
    ('ur_02', 'room_101', CAST(GETDATE() AS DATE), 1280, 1360, 3500, 55, 60, 20000, GETDATE(), GETDATE());
END
GO

-- 12. Invoices & Invoice Items (Kèm bank_account_id)
IF NOT EXISTS (SELECT 1 FROM invoices WHERE id = 'inv_01')
BEGIN
    INSERT INTO invoices (id, invoice_code, contract_id, utility_reading_id, bank_account_id, billing_month, issue_date, due_date, subtotal, discount, total, status, created_at, updated_at) VALUES
    ('inv_01', 'INV-2026-001', 'ctr_01', 'ur_01', 'bank_01', DATEADD(month, -1, CAST(GETDATE() AS DATE)), DATEADD(day, -28, CAST(GETDATE() AS DATE)), DATEADD(day, -23, CAST(GETDATE() AS DATE)), 3550000, 0, 3550000, 'paid', DATEADD(day, -28, GETDATE()), GETDATE()),
    ('inv_02', 'INV-2026-002', 'ctr_01', 'ur_02', 'bank_01', CAST(GETDATE() AS DATE), CAST(GETDATE() AS DATE), DATEADD(day, 5, CAST(GETDATE() AS DATE)), 3730000, 0, 3730000, 'paid', GETDATE(), GETDATE());

    INSERT INTO invoice_items (id, invoice_id, type, description, quantity, unit_price, amount, service_id, created_at, updated_at) VALUES
    ('item_01', 'inv_02', 'rent', N'Tiền thuê phòng', 1, 3200000, 3200000, NULL, GETDATE(), GETDATE()),
    ('item_02', 'inv_02', 'electricity', N'Tiền điện (1360 - 1280 = 80 kWh)', 80, 3500, 280000, 'srv_elec', GETDATE(), GETDATE()),
    ('item_03', 'inv_02', 'water', N'Tiền nước (60 - 55 = 5 m³)', 5, 20000, 100000, 'srv_water', GETDATE(), GETDATE()),
    ('item_04', 'inv_02', 'service', N'Phí rác & vệ sinh', 1, 50000, 50000, 'srv_garbage', GETDATE(), GETDATE()),
    ('item_05', 'inv_02', 'service', N'Internet Wifi cáp quang', 1, 100000, 100000, 'srv_wifi', GETDATE(), GETDATE());
END
GO

-- 13. Favorites
IF NOT EXISTS (SELECT 1 FROM favorites WHERE id = 'fav_01')
BEGIN
    INSERT INTO favorites (id, user_id, room_id, created_at, updated_at) VALUES
    ('fav_01', 'usr_tenant1', 'room_101', DATEADD(day, -1, GETDATE()), GETDATE()),
    ('fav_02', 'usr_tenant2', 'room_102', DATEADD(day, -2, GETDATE()), GETDATE()),
    ('fav_03', 'usr_tenant3', 'room_a1',  DATEADD(day, -2, GETDATE()), GETDATE()),
    ('fav_04', 'usr_tenant4', 'room_a2',  DATEADD(day, -5, GETDATE()), GETDATE()),
    ('fav_05', 'usr_tenant1', 'room_201', DATEADD(day, -7, GETDATE()), GETDATE()),
    ('fav_06', 'usr_tenant2', 'room_b1',  DATEADD(day, -12, GETDATE()), GETDATE());
END
GO

-- 14. Reviews & Notifications
IF NOT EXISTS (SELECT 1 FROM reviews WHERE id = 'rev_01')
BEGIN
    INSERT INTO reviews (id, room_id, tenant_id, rating, comment, status, created_at, updated_at) VALUES
    ('rev_01', 'room_101', 'usr_tenant1', 5, N'Chủ nhà thân thiện, phòng sạch sẽ và rất thoáng mát!', 'visible', DATEADD(day, -10, GETDATE()), GETDATE()),
    ('rev_02', 'room_a1',  'usr_tenant2', 4, N'Nội thất xịn, mỗi tội đường giờ cao điểm hơi đông xe.', 'visible', DATEADD(day, -5, GETDATE()), GETDATE());

    INSERT INTO notifications (id, user_id, title, message, type, reference_id, reference_type, read_at, created_at, updated_at) VALUES
    ('notif_01', 'usr_admin', N'Tin đăng mới chờ duyệt', N'Chủ trọ Nguyễn Văn An vừa đăng tin cho phòng Studio A2', 'post_approval', 'post_05', 'rental_post', NULL, DATEADD(minute, -10, GETDATE()), GETDATE()),
    ('notif_02', 'usr_admin', N'Lịch hẹn mới', N'Có khách hẹn xem phòng tại Nhà Trọ An Khang', 'appointment', 'apt_01', 'viewing_appointment', NULL, DATEADD(hour, -2, GETDATE()), GETDATE()),
    ('notif_own_01', 'usr_owner1', N'Khách đặt lịch xem phòng mới', N'Khách Đỗ Hoàng Yến (0966554433) vừa đặt lịch xem Phòng Studio A2 - Căn Hộ Mini Xanh vào lúc 09:30 ngày mai.', 'appointment_new', 'apt_02', 'viewing_appointment', NULL, DATEADD(minute, -15, GETDATE()), GETDATE()),
    ('notif_own_02', 'usr_owner1', N'Admin từ chối bài đăng', N'Tin đăng [Cho thuê căn hộ 1PN VIP Cộng Hòa] bị từ chối. Lý do: Hình ảnh phòng mờ và thiếu thông tin chi phí dịch vụ.', 'post_rejected', 'post_06', 'rental_post', NULL, DATEADD(hour, -1, GETDATE()), GETDATE()),
    ('notif_own_03', 'usr_owner1', N'Khách báo hỏng / bảo trì phòng', N'Khách Lê Quốc Việt (Phòng 101 - Nhà Trọ An Khang) báo sự cố: Máy lạnh không mát và bị chảy nước ở dàn lạnh.', 'maintenance_request', 'room_101', 'maintenance', NULL, DATEADD(hour, -3, GETDATE()), GETDATE()),
    ('notif_own_04', 'usr_owner1', N'Khách thanh toán hóa đơn', N'Khách Lê Quốc Việt (Phòng 101) đã chuyển khoản thanh toán hóa đơn kỳ Tháng 11/2026 (INV-2026-002) số tiền 3.730.000đ.', 'invoice_payment', 'inv_02', 'invoice', NULL, DATEADD(hour, -5, GETDATE()), GETDATE()),
    ('notif_own_05', 'usr_owner1', N'Khách hủy lịch hẹn xem phòng', N'Khách Phạm Minh Tuấn đã báo hủy lịch hẹn xem Phòng Studio A1 ngày 10/11/2026 lúc 14:00 do bận đột xuất.', 'appointment_cancelled', 'apt_04', 'viewing_appointment', NULL, DATEADD(day, -1, GETDATE()), GETDATE()),
    ('notif_own_06', 'usr_owner1', N'Bài đăng đã được Admin duyệt', N'Tin đăng [Cho thuê phòng trọ khép kín Tân Phú giá tốt] (Phòng 101 - Nhà Trọ An Khang) đã được duyệt và hiển thị.', 'post_approved', 'post_01', 'rental_post', GETDATE(), DATEADD(day, -2, GETDATE()), GETDATE());
END
GO