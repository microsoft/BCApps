/// <summary>
/// Provides intercompany reporting functionality for analyzing and reconciling transactions between related companies.
/// Generates comprehensive reports showing G/L entries, customer ledger entries, and vendor ledger transactions for intercompany partners.
/// </summary>
/// <remarks>
/// <para>
/// <b>Architecture:</b>
/// The intercompany reporting system leverages existing ledger entry tables with IC Partner filtering to provide
/// consolidated views of intercompany activity. Reports include detailed transaction listings with running balances and period comparisons.
/// </para>
/// <para>
/// <b>Key Workflows:</b>
/// </para>
/// <list type="number">
/// <item>
/// <term><b>Transaction Analysis:</b></term>
/// <description>Generate detailed listings of intercompany transactions across G/L, customer, and vendor ledgers</description>
/// </item>
/// <item>
/// <term><b>Balance Reconciliation:</b></term>
/// <description>Calculate beginning balances, period activity, and ending balances for intercompany accounts</description>
/// </item>
/// <item>
/// <term><b>Partner Comparison:</b></term>
/// <description>Compare transaction activity across multiple intercompany partners for consolidation preparation</description>
/// </item>
/// </list>
/// <para>
/// <b>Integration Points:</b>
/// Integrates with G/L Entry, Customer Ledger Entry, and Vendor Ledger Entry tables for comprehensive transaction coverage.
/// Uses IC Partner filtering to isolate intercompany-specific activity and supports date range filtering for period analysis.
/// </para>
/// <para>
/// <b>Extensibility:</b>
/// Key extension points include custom report layouts, additional data filtering, and supplementary calculation logic.
/// Reports can be extended with additional ledger entry types and custom intercompany analysis requirements.
/// </para>
/// </remarks>
namespace Microsoft.Intercompany.Reports;
