/// <summary>
/// Provides comprehensive functionality for managing deferred revenue and expense recognition in Business Central.
/// Handles creation, calculation, posting, and archiving of deferral schedules that distribute amounts across multiple accounting periods.
/// </summary>
/// <remarks>
/// <para>
/// <b>Architecture:</b>
/// The deferral system uses a template-driven approach where deferral templates define calculation methods and G/L account mappings, 
/// deferral schedules manage period-by-period distributions, and archive tables maintain historical records.
/// </para>
/// <para>
/// <b>Key Workflows:</b>
/// </para>
/// <list type="number">
/// <item>
/// <term><b>Template Setup:</b></term>
/// <description>Configure deferral templates with calculation methods (straight-line, equal per period, days per period, user-defined), period parameters, and G/L account assignments</description>
/// </item>
/// <item>
/// <term><b>Schedule Generation:</b></term>
/// <description>Create deferral schedules from sales/purchase documents, apply template calculations to distribute amounts across periods, and generate recognition entries</description>
/// </item>
/// <item>
/// <term><b>Period Processing:</b></term>
/// <description>Post period recognition entries through G/L integration, update schedule status, and archive completed schedules for audit trail</description>
/// </item>
/// </list>
/// <para>
/// <b>Integration Points:</b>
/// Integrates with General Ledger for posting and account validation, Sales/Purchase documents for revenue/expense deferrals, 
/// and Foundation Period Management for schedule calculations. Supports multi-currency operations through Currency integration.
/// </para>
/// <para>
/// <b>Extensibility:</b>
/// Key extension points include calculation method customization through <c>OnBeforeCalculate</c> events, schedule creation hooks via <c>OnBeforeCreateDeferralSchedule</c>, 
/// and posting validation through <c>OnBeforePostedDeferralHeaderInsert</c>. Supports custom calculation methods and template validation.
/// </para>
/// <para>
/// <b>Dependencies:</b><br/>
/// <i>Required:</i> <c>Microsoft.Finance.GeneralLedger</c>, <c>Microsoft.Foundation.Period</c>, <c>Microsoft.Finance.Currency</c><br/>
/// <i>Optional:</i> <c>Microsoft.Sales</c>, <c>Microsoft.Purchases</c>, <c>Microsoft.Inventory.Item</c>, <c>Microsoft.Projects.Resources.Resource</c>
/// </para>
/// </remarks>
namespace Microsoft.Finance.Deferral;
