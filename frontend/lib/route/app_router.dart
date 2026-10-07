import 'package:flutter/material.dart';
import 'app_routes.dart';

// Import màn hình từ frontend/lib/screens/
import '../screens/admin/admin_dashboard.dart';
// import '../screens/admin/admin_stats.dart';
import '../screens/admin/users_manage.dart';
import '../screens/admin/rewview_new.dart';
import '../screens/admin/content_moderation.dart';

import '../screens/owner/contracts_manage.dart';
import '../screens/owner/contract_form.dart';
import '../screens/owner/contract_detail_owner.dart';
import '../screens/owner/contract_members.dart';
import '../screens/owner/termination_screen.dart';
import '../screens/owner/invoices_manage..dart';
import '../screens/owner/invoice_form.dart';
import '../screens/owner/invoice_detail_owner.dart';
import '../screens/owner/utility_readings.dart';
import '../screens/owner/utility_history.dart';
import '../screens/owner/maintenance_manage.dart';
import '../screens/owner/maintenance_detail.dart';

import '../screens/tenant/booking_screen.dart' as tenant_booking;
import '../screens/tenant/booking_history_screen.dart' as tenant_booking_history;
import '../screens/tenant/my_contracts_screen.dart' as tenant_contracts;
import '../screens/tenant/contract_detail_screen.dart' as tenant_contract_detail;
import '../screens/tenant/my_invoices_screen.dart' as tenant_invoices;
import '../screens/tenant/invoice_detail_screen.dart' as tenant_invoice_detail;
import '../screens/tenant/payment_screen.dart' as tenant_payment;
import '../screens/tenant/notifications_screen.dart' as tenant_notifications;
class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
      case AppRoutes.adminDashboard:
        return MaterialPageRoute(builder: (_) => const AdminDashboard());
      // case AppRoutes.adminStats:
      //   return MaterialPageRoute(builder: (_) => const AdminStatsScreen());
      case AppRoutes.usersManage:
        return MaterialPageRoute(builder: (_) => const User());
      case AppRoutes.maintenanceManage:
        return MaterialPageRoute(builder: (_) => const MaintenanceManageScreen());
      case AppRoutes.rewview:
        return MaterialPageRoute(builder: (_)=> const review());

      case AppRoutes.contractsManage:
        return MaterialPageRoute(builder: (_) => const Contracts_manager());
      case AppRoutes.contractForm:
        return MaterialPageRoute(builder: (_) => Contract_form()); // địa chỉ
      case AppRoutes.invoicesManage:
        return MaterialPageRoute(builder: (_) => const Invoice_mana());
      case AppRoutes.invoiceForm:
        return MaterialPageRoute(builder: (_) => Invoice_form()); //địa chỉ

      case AppRoutes.utilityReadings:
        return MaterialPageRoute(builder: (_) => const InvoiceCreateScreen());
      case AppRoutes.utilityHistory:
        return MaterialPageRoute(builder: (_) => const LandlordUtilityScreen());
      case AppRoutes.termination:
        return MaterialPageRoute(builder: (_) => ContractLiquidationScreen()); // id
      case AppRoutes.maintenanceDetail:
        return MaterialPageRoute(builder: (_) => MaintenanceDetailScreen()); // id
      case AppRoutes.contentModeration:
        return MaterialPageRoute(builder: (_) => const RoomApprovalDetailScreen());
      case AppRoutes.contractDetailOwner:
        return MaterialPageRoute(builder: (_) => ContractDetailScreen());// id
      case AppRoutes.contractMembers:
        return MaterialPageRoute(builder: (_) => TenantManagementScreen());// id
      case AppRoutes.invoiceDetailOwner:
        return MaterialPageRoute(builder: (_) => InvoiceDetailScreen());// id

      // ROUTE CỦA TV2 (NGƯỜI THUÊ - Dùng bí danh)
      case AppRoutes.tenantBooking:
        return MaterialPageRoute(builder: (_) => const tenant_booking.booking_screen());
      case AppRoutes.tenantBookingHistory:
        return MaterialPageRoute(builder: (_) => const tenant_booking_history.booking_history_screen());
      case AppRoutes.tenantContracts:
        return MaterialPageRoute(builder: (_) => const tenant_contracts.MyContractsScreen());
      case AppRoutes.tenantContractDetail:
        return MaterialPageRoute(builder: (_) => const tenant_contract_detail.ContractDetailScreen());
      case AppRoutes.tenantInvoices:
        return MaterialPageRoute(builder: (_) => const tenant_invoices.MyInvoicesScreen());
      case AppRoutes.tenantInvoiceDetail:
        return MaterialPageRoute(builder: (_) => tenant_invoice_detail.InvoiceDetailScreen());
      case AppRoutes.tenantPayment:
        return MaterialPageRoute(builder: (_) => const tenant_payment.PaymentScreen());
      case AppRoutes.tenantNotifications:
        return MaterialPageRoute(builder: (_) => const tenant_notifications.NotificationsScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Lỗi Route')),
            body: Center(child: Text('Không tìm thấy trang: ${settings.name}')),
          ),
        );
    }
  }
}