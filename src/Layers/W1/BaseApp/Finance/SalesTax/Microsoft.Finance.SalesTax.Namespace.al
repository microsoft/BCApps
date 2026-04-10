/// <summary>
/// Provides comprehensive sales tax functionality for Business Central with multi-jurisdictional support.
/// Handles tax calculation, jurisdiction management, tax area configuration, and detailed tax reporting for US sales tax scenarios.
/// </summary>
/// <remarks>
/// <para>
/// <b>Architecture:</b>
/// The SalesTax system uses a hierarchical approach where Tax Areas contain multiple Tax Jurisdictions,
/// each with Tax Details defining specific rates and rules, enabling complex multi-tier tax calculations.
/// </para>
/// <para>
/// <b>Key Workflows:</b>
/// </para>
/// <list type="number">
/// <item>
/// <term><b>Tax Configuration:</b></term>
/// <description>Set up tax areas, jurisdictions, groups, and detailed tax rates with effective dates and thresholds</description>
/// </item>
/// <item>
/// <term><b>Tax Calculation:</b></term>
/// <description>Calculate sales tax amounts on transactions using jurisdiction-specific rates and tax-on-tax rules</description>
/// </item>
/// <item>
/// <term><b>Tax Reporting:</b></term>
/// <description>Generate sales tax collection reports with jurisdiction breakdowns and detailed transaction analysis</description>
/// </item>
/// </list>
/// <para>
/// <b>Integration Points:</b>
/// Integrates with General Ledger for account posting, Sales and Purchase processes for tax calculation,
/// and VAT Entry system for detailed tax tracking and reporting. Uses Multi-language support for localized descriptions.
/// </para>
/// <para>
/// <b>Extensibility:</b>
/// Key extension points include tax calculation events for custom logic integration, jurisdiction setup for additional tax types,
/// and reporting extensibility for specialized tax reporting requirements.
/// </para>
/// </remarks>
namespace Microsoft.Finance.SalesTax;
