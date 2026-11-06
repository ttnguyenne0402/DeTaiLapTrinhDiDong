using System;
using System.Collections.Generic;
using System.Net;
using System.Security.Cryptography;
using System.Text;

namespace Backend.Utils
{
    public class VnPayHelper
    {
        public static string GenerateUrl(string tmnCode, string hashSecret, string vnpUrl, string returnUrl, string txnRef, decimal amount, string info, string ipAddress)
        {
            // Đóng gói các tham số bắt buộc của VNPay
            var vnp_Params = new SortedDictionary<string, string>
            {
                { "vnp_Version", "2.1.0" },
                { "vnp_Command", "pay" },
                { "vnp_TmnCode", tmnCode },
                { "vnp_Amount", ((long)(amount * 100)).ToString() }, 
                { "vnp_CreateDate", DateTime.Now.ToString("yyyyMMddHHmmss") },
                { "vnp_CurrCode", "VND" },
                { "vnp_IpAddr", ipAddress },
                { "vnp_Locale", "vn" },
                { "vnp_OrderInfo", info },
                { "vnp_OrderType", "other" },
                { "vnp_ReturnUrl", returnUrl },
                { "vnp_TxnRef", txnRef }
            };

            // Nối chuỗi
            var queryString = new StringBuilder();
            foreach (var kv in vnp_Params)
            {
                if (queryString.Length > 0) queryString.Append('&');
                queryString.Append(WebUtility.UrlEncode(kv.Key) + "=" + WebUtility.UrlEncode(kv.Value));
            }

            // Băm chữ ký bảo mật bằng HashSecret
            var signData = queryString.ToString();
            var vnp_SecureHash = HmacSHA512(hashSecret, signData);

            return vnpUrl + "?" + signData + "&vnp_SecureHash=" + vnp_SecureHash;
        }

        private static string HmacSHA512(string key, string inputData)
        {
            var hash = new StringBuilder();
            byte[] keyBytes = Encoding.UTF8.GetBytes(key);
            byte[] inputBytes = Encoding.UTF8.GetBytes(inputData);
            using (var hmac = new HMACSHA512(keyBytes))
            {
                byte[] hashValue = hmac.ComputeHash(inputBytes);
                foreach (var theByte in hashValue)
                {
                    hash.Append(theByte.ToString("x2")); 
                }
            }
            return hash.ToString();
        }
    }
}