# Gmail SMTP setup

1. Use a dedicated Gmail sender account for the project. Turn on 2-Step Verification and create a Google App Password for the backend. Use that App Password, not the account's normal password.
2. From the repository root, store the sender account and App Password in backend user secrets:

   ```powershell
   dotnet user-secrets set "GmailSmtp:Username" "xacthucemailtrooi@gmail.com" --project Backend/Backend/Backend.csproj
   dotnet user-secrets set "GmailSmtp:AppPassword" "YOUR_16_CHARACTER_APP_PASSWORD" --project Backend/Backend/Backend.csproj
   ```

3. In the `QuanLyPhongTro` SQL Server database, run `Backend/Backend/Data/EmailOtps.sql` once.

The backend sends mail through `smtp.gmail.com` on port `587` with STARTTLS. The App Password stays in local .NET user secrets; do not put it in Flutter, `appsettings.json`, or source control.

Registration requires a name, email, phone number, and password. It creates the account immediately without sending a verification email, and the user can log in right away. Gmail SMTP is used only for password recovery.

Password recovery sends a code to a registered email address, whether or not it was verified during registration. A successful reset also marks that address as verified because the user demonstrated access to its inbox. OTPs expire after 10 minutes, are single-use, allow five attempts, and are limited to one send per minute. Google and Zalo sign-in stay separate from this password flow.

Gmail SMTP quotas still apply.
