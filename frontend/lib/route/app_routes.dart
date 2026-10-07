abstract class AppRoutes {
  //admin và bảo trì
  static const String adminDashboard = '/admin/dashboard';
  static const String adminStats = '/admin/stats';
  static const String usersManage = '/admin/users';
  static const String rewview = '/admin/rev';
  static const String maintenanceManage = '/maintenance/manage';

  //hợp động với hóa đơn
  static const String contractsManage = '/owner/contracts';
  static const String contractForm = '/owner/contracts/form';
  static const String invoicesManage = '/owner/invoices';
  static const String invoiceForm = '/owner/invoices/form';

  static const String utilityReadings = '/owner/utility/readings';
  static const String utilityHistory = '/owner/utility/history';
  static const String termination = '/owner/contracts/terminate';
  static const String maintenanceDetail = '/maintenance/detail';
  static const String contentModeration = '/admin/content-moderation';
  static const String contractDetailOwner = '/owner/contracts/detail';
  static const String contractMembers = '/owner/contracts/members';
  static const String invoiceDetailOwner = '/owner/invoices/detail';

  // --- TV2: NGƯỜI THUÊ (TENANT) ---
  static const String tenantBooking = '/tenant/booking';
  static const String tenantBookingHistory = '/tenant/booking-history';
  static const String tenantContracts = '/tenant/contracts';
  static const String tenantContractDetail = '/tenant/contracts/detail';
  static const String tenantInvoices = '/tenant/invoices';
  static const String tenantInvoiceDetail = '/tenant/invoices/detail';
  static const String tenantPayment = '/tenant/payment';
  static const String tenantNotifications = '/tenant/notifications';
  static const String home = '/home';
  static const String roomDetail = '/room-detail';
}