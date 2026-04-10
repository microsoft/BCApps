/// <summary>
/// Provides comprehensive consolidation functionality for multi-company financial reporting in Business Central.
/// Supports subsidiary company data integration through database connections, API endpoints, and file imports with currency translation capabilities.
/// </summary>
/// <remarks>
/// <para>
/// <b>Architecture:</b>
/// The consolidation system uses a business unit-driven approach where business units define subsidiary companies, 
/// currency exchange rates manage foreign currency translation, and consolidation engines process data through General Ledger posting.
/// </para>
/// <para>
/// <b>Key Workflows:</b>
/// </para>
/// <list type="number">
/// <item>
/// <term><b>Business Unit Setup:</b></term>
/// <description>Configure subsidiary companies with currency settings, exchange rate accounts, and data import methods</description>
/// </item>
/// <item>
/// <term><b>Data Import and Processing:</b></term>
/// <description>Import G/L entries, accounts, and dimensions from subsidiaries via database, API, or file sources with validation</description>
/// </item>
/// <item>
/// <term><b>Currency Translation:</b></term>
/// <description>Convert foreign currency amounts using income and balance currency factors with exchange rate gain/loss posting</description>
/// </item>
/// <item>
/// <term><b>Consolidation Posting:</b></term>
/// <description>Create consolidated G/L entries with dimension mapping and residual amount handling through General Journal processing</description>
/// </item>
/// </list>
/// <para>
/// <b>Integration Points:</b>
/// Integrates with General Ledger for posting consolidated entries, Currency Exchange Rates for foreign currency translation, 
/// Dimension Management for consolidation dimension mapping, and General Journal systems for entry creation and validation.
/// </para>
/// <para>
/// <b>Extensibility:</b>
/// Key extension points include consolidation processing events for custom validation and transformation logic, 
/// currency translation customization through exchange rate factor calculation events, and dimension mapping extensions through dimension buffer processing events.
/// </para>
/// </remarks>
namespace Microsoft.Finance.Consolidation;
