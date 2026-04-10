/// <summary>
/// Provides comprehensive VAT rate change conversion functionality for Business Central.
/// Enables systematic updating of VAT and general product posting groups across all master data, journals, and document types.
/// </summary>
/// <remarks>
/// <para>
/// <b>Architecture:</b>
/// The VAT rate change system uses a configuration-driven approach where conversion mappings define old-to-new posting group relationships,
/// setup records control which entities to update, and a processing engine applies changes with comprehensive logging and validation.
/// </para>
/// <para>
/// <b>Key Workflows:</b>
/// </para>
/// <list type="number">
/// <item>
/// <term><b>Conversion Setup:</b></term>
/// <description>Configure conversion mappings, select entities to update, and define filters for targeted conversion scope</description>
/// </item>
/// <item>
/// <term><b>Validation and Preview:</b></term>
/// <description>Run conversion in preview mode to identify potential issues and generate log entries without modifying data</description>
/// </item>
/// <item>
/// <term><b>Data Conversion:</b></term>
/// <description>Execute conversion with data modification, handle complex document scenarios, and create comprehensive audit logs</description>
/// </item>
/// </list>
/// <para>
/// <b>Integration Points:</b>
/// Integrates with master data tables (Items, Resources, G/L Accounts), all journal types, sales and purchase documents, 
/// and VAT posting setup. Uses posting group validation and supports filtered conversions for targeted scenarios.
/// </para>
/// <para>
/// <b>Extensibility:</b>
/// Key extension points include OnBeforeConvert and OnAfterConvert events for custom processing, table-specific update events,
/// and integration events for handling special document types. Supports custom validation through document status checking events.
/// </para>
/// </remarks>
namespace Microsoft.Finance.VAT.RateChange;
