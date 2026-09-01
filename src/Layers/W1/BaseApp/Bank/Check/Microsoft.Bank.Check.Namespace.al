/// <summary>
/// Manages the complete lifecycle of physical and electronic checks within Business Central's banking system.
/// Provides comprehensive check processing functionality including check creation, printing, voiding, financial reconciliation, and positive pay export capabilities.
/// </summary>
/// <remarks>
/// <para>
/// <b>Architecture:</b>
/// The check management system is built on an event-driven architecture with the following key components:
/// </para>
/// <para>
/// <i>Core Transaction Processing:</i>
/// </para>
/// <list type="bullet">
/// <item><description><b>Check Ledger Entry:</b> Central transaction record maintaining complete check audit trail</description></item>
/// <item><description><b>Check Management:</b> Business logic codeunit orchestrating all check operations</description></item>
/// <item><description><b>Check Report:</b> Formatted output generation with security features and void processing</description></item>
/// </list>
/// <para>
/// <i>User Interface Components:</i>
/// </para>
/// <list type="bullet">
/// <item><description><b>Check Ledger Entries:</b> Comprehensive transaction history and lookup interface</description></item>
/// <item><description><b>Apply Check Ledger Entries:</b> Payment application and reconciliation interface</description></item>
/// <item><description><b>Check Preview:</b> Visual verification before printing or processing</description></item>
/// </list>
/// <para>
/// <i>Administrative Tools:</i>
/// </para>
/// <list type="bullet">
/// <item><description><b>Confirm Financial Void:</b> Secure void operation confirmation interface</description></item>
/// <item><description><b>Delete Check Ledger Entries:</b> Maintenance utility for entry cleanup</description></item>
/// <item><description><b>Void/Transmit Electronic Payments:</b> Electronic payment processing interface</description></item>
/// </list>
/// <para>
/// <b>Key Workflows:</b>
/// </para>
/// <list type="number">
/// <item>
/// <term><b>Check Creation and Printing:</b></term>
/// <description>Create payment journal entries with check payment methods, assign sequential check numbers, generate formatted check documents with security features</description>
/// </item>
/// <item>
/// <term><b>Check Voiding Operations:</b></term>
/// <description>Perform void operations (simple, financial, or transmit electronic), update check ledger status, handle reversing entries for financial voids</description>
/// </item>
/// <item>
/// <term><b>Check Application and Reconciliation:</b></term>
/// <description>Apply checks to invoices and payments, match bank statement entries to check ledger records, validate check clearing and settlement</description>
/// </item>
/// </list>
/// <para>
/// <b>Integration Points:</b>
/// Integrates with General Journal for payment entry creation, Bank Account management for check number sequencing, 
/// Purchase/Sales systems for payment application, and Positive Pay systems for fraud prevention and security validation.
/// </para>
/// <para>
/// <b>Extensibility:</b>
/// Key extension points include <c>OnBeforeFinancialVoidCheck</c> for custom void validation, <c>OnAfterInsertCheck</c> for check creation hooks, 
/// and <c>OnBeforeCheckReport</c> for custom check formatting. Supports positive pay integration through <c>OnAfterExportPositivePay</c>.
/// </para>
/// <para>
/// <b>Dependencies:</b><br/>
/// <i>Required:</i> <c>Microsoft.Bank.BankAccount</c>, <c>Microsoft.Finance.GeneralLedger.Journal</c><br/>
/// <i>Optional:</i> <c>Microsoft.Bank.PositivePay</c>, <c>Microsoft.Purchases.Payables</c>, <c>Microsoft.Bank.Reconciliation</c>
/// </para>
/// </remarks>
namespace Microsoft.Bank.Check;
