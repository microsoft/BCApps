/// <summary>
/// Provides comprehensive financial reporting infrastructure for Business Central including account schedules, trial balance, and standard financial statements.
/// Enables creation of customizable financial reports with multi-dimensional analysis, budgeting integration, and flexible formatting options for regulatory and management reporting requirements.
/// </summary>
/// <remarks>
/// <para>
/// <b>Architecture:</b>
/// The financial reporting system is built on a template-driven approach where Account Schedule Names define row structures, Column Layout Names define column calculations,
/// and Financial Reports combine both elements with filters and formatting options. The system supports G/L accounts, cost accounting, cash flow forecasting, and multi-dimensional analysis.
/// </para>
/// <para>
/// <b>Key Workflows:</b>
/// </para>
/// <list type="number">
/// <item>
/// <term><b>Report Template Creation:</b></term>
/// <description>Configure row definitions (Account Schedules) with totaling formulas, column layouts with calculation methods, and combine into Financial Reports</description>
/// </item>
/// <item>
/// <term><b>Financial Statement Generation:</b></term>
/// <description>Execute financial reports with period filters, dimensions, and business unit selections to produce Balance Sheet, Income Statement, Trial Balance, and Cash Flow statements</description>
/// </item>
/// <item>
/// <term><b>Analysis and Drill-Down:</b></term>
/// <description>Navigate from summary reports to detailed ledger entries, perform period-over-period analysis, and export to Excel for extended analysis</description>
/// </item>
/// <item>
/// <term><b>KPI and Dashboard Integration:</b></term>
/// <description>Configure KPI web services, create chart visualizations, and integrate with role centers for management dashboard displays</description>
/// </item>
/// </list>
/// <para>
/// <b>Integration Points:</b>
/// Integrates with General Ledger for account balances, Analysis Views for dimensional reporting, G/L Budget for variance analysis, Cost Accounting for management reporting,
/// Cash Flow forecasting for liquidity analysis, and Data Exchange Framework for template import/export. Supports Excel integration and web service publishing for external systems.
/// </para>
/// <para>
/// <b>Extensibility:</b>
/// Key extension points include calculation formula customization through OnBeforeCalcCell events, report formatting via OnBeforeFormatCell events, and data source expansion
/// through OnAfterGetRecord events. Custom account schedule line types, column layout calculations, and KPI metrics can be added through table extensions and event subscribers.
/// </para>
/// </remarks>
namespace Microsoft.Finance.FinancialReports;
