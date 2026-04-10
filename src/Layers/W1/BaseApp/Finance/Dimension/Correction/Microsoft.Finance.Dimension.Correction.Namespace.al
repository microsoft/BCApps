/// <summary>
/// Provides comprehensive dimension correction functionality for Business Central.
/// Enables retroactive modification of dimension values on posted G/L entries with full validation and integrity controls.
/// </summary>
/// <remarks>
/// <para>
/// <b>Architecture:</b>
/// The dimension correction system uses a template-driven approach where dimension correction records define transformation rules,
/// selection criteria manage G/L entry filtering, and correction changes specify dimension value mappings with comprehensive validation workflows.
/// </para>
/// <para>
/// <b>Key Workflows:</b>
/// </para>
/// <list type="number">
/// <item>
/// <term><b>Correction Setup:</b></term>
/// <description>Define correction parameters, selection criteria for G/L entries, and specify dimension value transformations</description>
/// </item>
/// <item>
/// <term><b>Validation and Preview:</b></term>
/// <description>Validate correction rules against G/L entries, preview affected records, and identify potential conflicts</description>
/// </item>
/// <item>
/// <term><b>Execution and Monitoring:</b></term>
/// <description>Execute corrections through job queue processing, track progress, and provide undo capabilities for completed corrections</description>
/// </item>
/// </list>
/// <para>
/// <b>Integration Points:</b>
/// Integrates with G/L Entry management for data modification, Analysis Views for refresh operations, 
/// Job Queue for background processing, and Dimension Management for validation and integrity checks.
/// </para>
/// <para>
/// <b>Extensibility:</b>
/// Key extension points include validation events for custom business rules, correction processing hooks for additional logic,
/// and analysis view update customization through OnAfterShouldUpdateAnalysisView and OnAfterUpdateGLEntry events.
/// </para>
/// </remarks>
namespace Microsoft.Finance.Dimension.Correction;
