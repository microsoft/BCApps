/// <summary>
/// Provides payroll integration functionality for Business Central, enabling import and processing of payroll data from external payroll systems.
/// Supports extensible payroll service registration, file-based data import, and automated mapping to General Ledger accounts.
/// </summary>
/// <remarks>
/// <para>
/// <b>Architecture:</b>
/// The payroll system uses an extensible service-oriented architecture where payroll service providers register through events, 
/// data is imported via Data Exchange Framework, and account mappings are maintained persistently for automated G/L entry creation.
/// </para>
/// <para>
/// <b>Key Workflows:</b>
/// </para>
/// <list type="number">
/// <item>
/// <term><b>Service Registration:</b></term>
/// <description>Payroll service providers register through <c>OnRegisterPayrollService</c> events, enabling guided setup and service discovery</description>
/// </item>
/// <item>
/// <term><b>Data Import:</b></term>
/// <description>Users select registered services, import payroll files through Data Exchange Framework, and map external accounts to G/L accounts</description>
/// </item>
/// <item>
/// <term><b>Journal Processing:</b></term>
/// <description>System creates General Journal entries from mapped payroll data, validates accounts, and enables posting to General Ledger</description>
/// </item>
/// </list>
/// <para>
/// <b>Integration Points:</b>
/// Integrates with Data Exchange Framework for file processing, Service Connection framework for provider registration, 
/// and General Ledger system for journal creation and posting. Uses assisted setup for guided service configuration.
/// </para>
/// <para>
/// <b>Extensibility:</b>
/// Key extension points include <c>OnRegisterPayrollService</c> for service provider registration, <c>OnImportPayroll</c> for custom import logic, 
/// and <c>OnBeforeGetFileName</c> for specialized file selection scenarios.
/// </para>
/// <para>
/// <b>Dependencies:</b><br/>
/// <i>Required:</i> <c>Microsoft.Finance.GeneralLedger.Journal</c>, <c>Microsoft.Finance.GeneralLedger.Account</c><br/>
/// <i>Optional:</i> <c>Microsoft.Utilities</c>, <c>System.IO</c>, <c>Microsoft.EServices.EDocument</c>
/// </para>
/// </remarks>
namespace Microsoft.Finance.Payroll;
