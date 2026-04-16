/// Banking GenUI Components
///
/// A Flutter package providing banking-specific UI components for GenUI/A2UI
/// integration, enabling AI agents to generate dynamic banking interfaces.
///
/// ## Features
///
/// - **AccountSummary**: Display account cards with balance information
/// - **QuickTransfer**: Transfer form for moving money between accounts
/// - **TransactionItem**: Individual transaction display
/// - **TransactionList**: List of transactions with header
///
/// ## Usage
///
/// ```dart
/// import 'package:banking_genui_components/banking_genui_components.dart';
/// import 'package:genui/genui.dart';
///
/// // Use the banking catalog with GenUI
/// final controller = SurfaceController(
///   catalogs: [BankingCatalog.asCatalog()],
/// );
/// ```
library;

// Catalog
export 'src/catalog/banking_catalog.dart';

// Widgets
export 'src/widgets/account_summary.dart';
export 'src/widgets/quick_transfer.dart';
export 'src/widgets/transaction_item.dart';
