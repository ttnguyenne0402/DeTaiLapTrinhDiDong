namespace Backend.Helpers
{
    public static class OwnerHelper
    {
        /// <summary>
        /// Chuẩn hóa và mở rộng danh sách OwnerId tương thích giữa dữ liệu database.sql (usr_owner1) 
        /// và dữ liệu gốc (USER_OWNER_01), đảm bảo truy vấn luôn tìm thấy dữ liệu.
        /// </summary>
        public static List<string> ResolveOwnerIds(string ownerId)
        {
            var ids = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            if (!string.IsNullOrWhiteSpace(ownerId))
            {
                ids.Add(ownerId.Trim());

                if (ownerId.Equals("usr_owner1", StringComparison.OrdinalIgnoreCase))
                {
                    ids.Add("USER_OWNER_01");
                }
                else if (ownerId.Equals("USER_OWNER_01", StringComparison.OrdinalIgnoreCase))
                {
                    ids.Add("usr_owner1");
                }
                else if (ownerId.Equals("usr_owner2", StringComparison.OrdinalIgnoreCase))
                {
                    ids.Add("USER_OWNER_02");
                }
            }
            return ids.ToList();
        }

        /// <summary>
        /// Kiểm tra xem giá trị truyền từ Swagger/Client có phải là placeholder mặc định không.
        /// </summary>
        public static bool IsPlaceholder(string? value, string placeholderName)
        {
            if (string.IsNullOrWhiteSpace(value)) return true;
            string trimmed = value.Trim();
            return trimmed.Equals("all", StringComparison.OrdinalIgnoreCase)
                || trimmed.Equals(placeholderName, StringComparison.OrdinalIgnoreCase);
        }
    }
}

