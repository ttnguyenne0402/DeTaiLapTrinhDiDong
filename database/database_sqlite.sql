-- ============================================================
-- SCRIPT CƠ SỞ DỮ LIỆU SQLITE: QUẢN LÝ PHÒNG TRỌ (CHO MÔN LTDD)
-- Tương thích SQLite 3, DB Browser for SQLite, sqflite trên Flutter hoặc SQLite Backend
-- ============================================================

PRAGMA foreign_keys = ON;

-- 1. Bảng users
CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    password TEXT NOT NULL,
    phone TEXT,
    avatar TEXT,
    role TEXT NOT NULL CHECK (role IN ('admin', 'owner', 'tenant')),
    status TEXT NOT NULL CHECK (status IN ('active', 'inactive', 'blocked')),
    email_verified_at TEXT,
    google_id TEXT,
    zalo_id TEXT,
    created_at TEXT DEFAULT (datetime('now')),
    updated_at TEXT DEFAULT (datetime('now'))
);

-- 2. Bảng properties (Khu trọ / Bất động sản)
CREATE TABLE IF NOT EXISTS properties (
    id TEXT PRIMARY KEY,
    owner_id TEXT NOT NULL,
    name TEXT NOT NULL,
    type TEXT NOT NULL DEFAULT 'rooming_house',
    address TEXT NOT NULL,
    district TEXT NOT NULL,
    ward TEXT NOT NULL,
    description TEXT,
    status TEXT NOT NULL DEFAULT 'active',
    created_at TEXT DEFAULT (datetime('now')),
    updated_at TEXT DEFAULT (datetime('now')),
    FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE CASCADE
);

-- 3. Bảng rooms (Phòng trọ)
CREATE TABLE IF NOT EXISTS rooms (
    id TEXT PRIMARY KEY,
    property_id TEXT NOT NULL,
    name TEXT NOT NULL,
    area REAL NOT NULL,
    price REAL NOT NULL,
    deposit REAL NOT NULL DEFAULT 0,
    max_people INTEGER NOT NULL DEFAULT 2,
    floor INTEGER DEFAULT 1,
    description TEXT,
    images TEXT,
    status TEXT NOT NULL DEFAULT 'available', -- available, rented, maintenance
    created_at TEXT DEFAULT (datetime('now')),
    updated_at TEXT DEFAULT (datetime('now')),
    FOREIGN KEY (property_id) REFERENCES properties(id) ON DELETE CASCADE
);

-- 4. Bảng rental_posts (Tin đăng cho thuê)
CREATE TABLE IF NOT EXISTS rental_posts (
    id TEXT PRIMARY KEY,
    room_id TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    status TEXT NOT NULL DEFAULT 'pending', -- active, pending, draft, rejected, hidden
    rejection_reason TEXT,
    published_at TEXT,
    expired_at TEXT,
    created_at TEXT DEFAULT (datetime('now')),
    updated_at TEXT DEFAULT (datetime('now')),
    FOREIGN KEY (room_id) REFERENCES rooms(id) ON DELETE CASCADE
);

-- 5. Bảng rental_post_images (Ảnh tin đăng)
CREATE TABLE IF NOT EXISTS rental_post_images (
    id TEXT PRIMARY KEY,
    rental_post_id TEXT NOT NULL,
    image_path TEXT NOT NULL,
    is_thumbnail INTEGER DEFAULT 0,
    sort_order INTEGER DEFAULT 0,
    created_at TEXT DEFAULT (datetime('now')),
    updated_at TEXT DEFAULT (datetime('now')),
    FOREIGN KEY (rental_post_id) REFERENCES rental_posts(id) ON DELETE CASCADE
);

-- 6. Bảng viewing_appointments (Lịch hẹn xem phòng)
CREATE TABLE IF NOT EXISTS viewing_appointments (
    id TEXT PRIMARY KEY,
    room_id TEXT NOT NULL,
    tenant_id TEXT NOT NULL,
    appointment_date TEXT NOT NULL,
    appointment_time TEXT NOT NULL,
    phone TEXT NOT NULL,
    message TEXT,
    status TEXT NOT NULL DEFAULT 'pending', -- pending, confirmed, completed, cancelled
    owner_note TEXT,
    confirmed_at TEXT,
    completed_at TEXT,
    cancelled_at TEXT,
    created_at TEXT DEFAULT (datetime('now')),
    updated_at TEXT DEFAULT (datetime('now')),
    FOREIGN KEY (room_id) REFERENCES rooms(id) ON DELETE CASCADE,
    FOREIGN KEY (tenant_id) REFERENCES users(id) ON DELETE CASCADE
);

-- 7. Bảng services (Dịch vụ & Tiện ích cục bộ / SQLite)
CREATE TABLE IF NOT EXISTS services (
    id TEXT PRIMARY KEY,
    owner_id TEXT,
    name TEXT NOT NULL,
    description TEXT,
    unit TEXT NOT NULL DEFAULT 'kWh',
    status TEXT NOT NULL DEFAULT 'active', -- active, inactive
    created_at TEXT DEFAULT (datetime('now')),
    updated_at TEXT DEFAULT (datetime('now')),
    FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE SET NULL
);

-- 8. Bảng property_services (Đơn giá dịch vụ theo khu trọ)
CREATE TABLE IF NOT EXISTS property_services (
    id TEXT PRIMARY KEY,
    property_id TEXT NOT NULL,
    service_id TEXT NOT NULL,
    price REAL NOT NULL,
    status TEXT NOT NULL DEFAULT 'active',
    created_at TEXT DEFAULT (datetime('now')),
    updated_at TEXT DEFAULT (datetime('now')),
    FOREIGN KEY (property_id) REFERENCES properties(id) ON DELETE CASCADE,
    FOREIGN KEY (service_id) REFERENCES services(id) ON DELETE CASCADE
);

-- ============================================================
-- DỮ LIỆU MẪU (SEED DATA CHO SQLITE)
-- ============================================================

-- Chủ trọ & người thuê mẫu
INSERT OR IGNORE INTO users (id, name, email, password, phone, role, status) VALUES 
('USER_OWNER_01', 'Nguyễn Văn Chủ Trọ', 'owner@demo.com', '123456', '0901234567', 'owner', 'active'),
('USER_TENANT_01', 'Trần Thị Khách', 'tenant@demo.com', '123456', '0987654321', 'tenant', 'active');

-- Bất động sản mẫu
INSERT OR IGNORE INTO properties (id, owner_id, name, type, address, district, ward, description, status) VALUES
('PROP_01', 'USER_OWNER_01', 'Chung cư Mini Q7', 'apartment', '123 Huỳnh Tấn Phát', 'Quận 7', 'Tân Phú', 'Tòa nhà mới xây 5 tầng, camera 24/7', 'active'),
('PROP_02', 'USER_OWNER_01', 'Dãy trọ Lê Văn Sỹ', 'rooming_house', '456 Lê Văn Sỹ', 'Quận 3', 'Phường 12', 'Phòng trọ yên tĩnh, giờ giấc tự do', 'active');

-- Phòng trọ mẫu
INSERT OR IGNORE INTO rooms (id, property_id, name, area, price, deposit, max_people, floor, status, images) VALUES
('ROOM_01', 'PROP_01', 'Phòng 201', 25.0, 4000000, 4000000, 2, 2, 'rented', 'frontend/assets/images/anhPhongDemo.jpg'),
('ROOM_02', 'PROP_01', 'Phòng 202', 25.0, 4500000, 4500000, 2, 2, 'available', 'frontend/assets/images/anhPhongDemo.jpg'),
('ROOM_03', 'PROP_01', 'Phòng 301', 30.0, 5000000, 5000000, 3, 3, 'rented', 'frontend/assets/images/anhPhongDemo.jpg'),
('ROOM_04', 'PROP_02', 'Phòng 101', 20.0, 3500000, 3500000, 2, 1, 'available', 'frontend/assets/images/anhPhongDemo.jpg');

-- Dịch vụ mẫu (SQLite)
INSERT OR IGNORE INTO services (id, owner_id, name, description, unit, status) VALUES
('SRV_01', 'USER_OWNER_01', 'Điện sinh hoạt', 'Tính theo chỉ số đồng hồ hàng tháng.', 'kWh', 'active'),
('SRV_02', 'USER_OWNER_01', 'Nước sinh hoạt', 'Tính khoán theo số lượng người ở thực tế.', 'người/tháng', 'active'),
('SRV_03', 'USER_OWNER_01', 'Internet / Wifi tốc độ cao', 'Gói cước băng thông 150Mbps.', 'phòng/tháng', 'active'),
('SRV_04', 'USER_OWNER_01', 'Phí vệ sinh & Rác thải', 'Thu gom rác hàng ngày và lau dọn hành lang.', 'phòng/tháng', 'active'),
('SRV_05', 'USER_OWNER_01', 'Phí bảo trì Thang máy', 'Áp dụng cho các tầng từ tầng 2 trở lên.', 'người/tháng', 'inactive');

-- Đơn giá dịch vụ theo khu trọ
INSERT OR IGNORE INTO property_services (id, property_id, service_id, price, status) VALUES
('PSRV_01', 'PROP_01', 'SRV_01', 3500, 'active'),
('PSRV_02', 'PROP_01', 'SRV_02', 100000, 'active'),
('PSRV_03', 'PROP_01', 'SRV_03', 100000, 'active'),
('PSRV_04', 'PROP_01', 'SRV_04', 50000, 'active'),
('PSRV_05', 'PROP_01', 'SRV_05', 50000, 'inactive');

-- Lịch hẹn mẫu
INSERT OR IGNORE INTO viewing_appointments (id, room_id, tenant_id, appointment_date, appointment_time, phone, message, status) VALUES
('APPT_01', 'ROOM_02', 'USER_TENANT_01', '2026-11-10', '10:00', '0901234567', 'Hẹn gặp tại cổng chính, khách xin xem thêm chỗ để xe.', 'confirmed');

-- Tin đăng mẫu
INSERT OR IGNORE INTO rental_posts (id, room_id, title, description, status) VALUES
('POST_01', 'ROOM_02', 'Cho thuê phòng trọ có gác xép, full nội thất', 'Phòng thoáng mát, gần trạm xe buýt, an ninh tốt.', 'active');

