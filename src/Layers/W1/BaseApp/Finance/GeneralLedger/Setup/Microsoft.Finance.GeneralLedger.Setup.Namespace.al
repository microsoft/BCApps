/// <summary>
/// Provides setup and configuration objects for General Ledger operations.
/// Covers posting groups, ledger parameters, fiscal controls, and reporting defaults used across finance features.
/// </summary>
/// <remarks>
/// <para>
/// <b>Architecture:</b>
/// Centralized setup tables (for example, General Ledger Setup and General Posting Setup) expose validated parameters and events.
/// Pages provide admin UIs, while reports perform batch updates and recalculations (for example, closing income statement and ARC adjustments).
/// </para>
/// <para>
/// <b>Key Workflows:</b>
/// </para>
/// <list type="number">
/// <item>
/// <term><b>Posting Configuration:</b></term>
/// <description>Define business and product posting groups and map them to G/L accounts for sales, purchases, inventory, and manufacturing flows.</description>
/// </item>
/// <item>
/// <term><b>Fiscal Period Control:</b></term>
/// <description>Manage allowed posting ranges and VAT date usage; close income statement and validate period boundaries.</description>
/// </item>
/// <item>
/// <term><b>Currency and Rounding:</b></term>
/// <description>Enable additional reporting currency, run adjustment jobs, and set rounding precision and types for amounts and invoices.</description>
/// </item>
/// </list>
/// <para>
/// <b>Integration Points:</b>
/// Interacts with G/L Account, G/L Entry, VAT Posting Setup, Analysis View, Inventory and Job ledgers, and No. Series for numbering.
/// </para>
/// <para>
/// <b>Extensibility:</b>
/// Key events exist on setup tables and batch reports (for example, account suggestion and ARC adjustment hooks).
/// Interface "Documents - Retention Period" enables country-specific retention logic through enum-based implementations.
/// </para>
/// </remarks>
namespace Microsoft.Finance.GeneralLedger.Setup;
