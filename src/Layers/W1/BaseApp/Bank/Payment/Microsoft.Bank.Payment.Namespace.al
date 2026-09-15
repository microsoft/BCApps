/// <summary>
/// Provides comprehensive payment processing functionality for Microsoft Dynamics 365 Business Central.
/// Enables payment registration, export, credit transfers, and document matching with extensive banking integration capabilities.
/// </summary>
/// <remarks>
/// <para>
/// <b>Architecture:</b>
/// The payment system uses a multi-layered approach with setup tables for configuration, buffer tables for workspace operations,
/// export management for banking integration, and register-based tracking for audit trails and batch processing.
/// </para>
/// <para>
/// <b>Key Workflows:</b>
/// </para>
/// <list type="number">
/// <item>
/// <term><b>Payment Registration:</b></term>
/// <description>Quick customer payment entry using workspace interface with automatic posting and tolerance handling</description>
/// </item>
/// <item>
/// <term><b>Payment Export:</b></term>
/// <description>Generate bank-specific payment files with validation, remittance text, and error tracking for various banking formats</description>
/// </item>
/// <item>
/// <term><b>Credit Transfer Processing:</b></term>
/// <description>Batch credit transfers with register management, re-export capabilities, and multi-account-type support</description>
/// </item>
/// </list>
/// <para>
/// <b>Integration Points:</b>
/// Integrates with General Ledger for posting operations, Customer/Vendor ledgers for payment applications, Bank Account management for export configurations,
/// and Data Exchange Framework for banking file formats. Supports multiple currencies and payment tolerance calculations.
/// </para>
/// <para>
/// <b>Extensibility:</b>
/// Key extension points include payment registration workflow events, export format customization hooks, and credit transfer processing events.
/// Supports custom validation through integration events and enables third-party banking system integration through data exchange framework extensions.
/// </para>
/// <para>
/// <b>Dependencies:</b><br/>
/// <i>Required:</i> <c>Microsoft.Finance.GeneralLedger</c>, <c>Microsoft.Sales.Customer</c>, <c>Microsoft.Purchases.Vendor</c>, <c>Microsoft.Bank.BankAccount</c><br/>
/// <i>Optional:</i> <c>Microsoft.HumanResources.Employee</c>, <c>Microsoft.Foundation.Navigate</c>, <c>System.IO</c>
/// </para>
/// </remarks>
namespace Microsoft.Bank.Payment;
