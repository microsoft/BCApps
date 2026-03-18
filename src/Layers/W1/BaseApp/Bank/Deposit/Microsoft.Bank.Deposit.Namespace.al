/// <summary>
/// Provides extensible navigation components for bank deposit functionality in Microsoft Dynamics 365 Business Central.
/// Serves as a bridge layer that delegates deposit page and report access to extension implementations, primarily the Bank Deposits extension.
/// </summary>
/// <remarks>
/// <para>
/// <b>Architecture:</b>
/// The Bank.Deposit system is built on an extension delegation pattern with the following key components:
/// </para>
/// <para>
/// <i>Navigation Components:</i>
/// </para>
/// <list type="bullet">
/// <item><description><b>Page Launchers:</b> Codeunits that trigger deposit page opening through integration events</description></item>
/// <item><description><b>Report Launchers:</b> Codeunits that execute deposit reports via extensible events</description></item>
/// <item><description><b>Setup Infrastructure:</b> Configuration components for deposit page mapping (obsolete)</description></item>
/// </list>
/// <para>
/// <i>Extensibility Layer:</i>
/// </para>
/// <list type="bullet">
/// <item><description><b>Integration Events:</b> Local event publishers that enable extension-based functionality</description></item>
/// <item><description><b>Page Type Mapping:</b> Enumeration for categorizing different deposit workflow components</description></item>
/// </list>
/// <para>
/// <b>Core Components:</b>
/// </para>
/// <para>
/// <i>Tables:</i>
/// </para>
/// <list type="bullet">
/// <item><description><c>Deposits Page Setup (Table 500)</c>: Previously configured mapping between deposit page types and object IDs (obsolete in version 27.0)</description></item>
/// </list>
/// <para>
/// <i>Enumerations:</i>
/// </para>
/// <list type="bullet">
/// <item><description><c>Deposits Page Setup Key (Enum 500)</c>: DepositsPage, DepositPage, DepositListPage, DepositReport, DepositTestReport, PostedBankDepositListPage</description></item>
/// </list>
/// <para>
/// <i>Codeunits:</i>
/// </para>
/// <list type="bullet">
/// <item><description><c>Open Deposits Page (Codeunit 1500)</c>: Navigation launcher for main deposits overview page</description></item>
/// <item><description><c>Open Deposit Page (Codeunit 1505)</c>: Navigation launcher for individual deposit document pages</description></item>
/// <item><description><c>Open Deposit List Page (Codeunit 1506)</c>: Navigation launcher for deposit collection views</description></item>
/// <item><description><c>Open Deposit Report (Codeunit 1507)</c>: Report execution launcher for deposit documentation</description></item>
/// </list>
/// <para>
/// <b>Key Workflows:</b>
/// </para>
/// <list type="number">
/// <item>
/// <term><b>Deposit Navigation:</b></term>
/// <description>Extension-based page launching through integration events enables flexible deposit functionality without hard-coded dependencies</description>
/// </item>
/// <item>
/// <term><b>Report Generation:</b></term>
/// <description>Extensible report execution allows for custom deposit reporting implementations while maintaining consistent navigation patterns</description>
/// </item>
/// </list>
/// <para>
/// <b>Integration Points:</b>
/// Designed for integration with Bank Deposits extension, which provides actual deposit functionality. 
/// Uses event-driven architecture to enable modular deposit features without creating dependencies in base application.
/// </para>
/// <para>
/// <b>Extensibility:</b>
/// All functionality is provided through integration events including <c>OnOpenDepositsPage</c>, <c>OnOpenDepositPage</c>, 
/// <c>OnOpenDepositListPage</c>, and <c>OnOpenDepositReport</c>. Extensions subscribe to these events to provide deposit functionality.
/// </para>
/// <para>
/// <b>Dependencies:</b><br/>
/// <i>Required:</i> None (base navigation framework only)<br/>
/// <i>Optional:</i> <c>Microsoft.Bank.Deposits</c> (extension), <c>Microsoft.Foundation.Reporting</c>
/// </para>
/// </remarks>
namespace Microsoft.Bank.Deposit;
