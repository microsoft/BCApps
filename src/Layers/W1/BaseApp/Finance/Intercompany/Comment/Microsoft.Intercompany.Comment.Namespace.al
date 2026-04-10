/// <summary>
/// Provides commenting and annotation functionality for intercompany transactions between partner companies.
/// Enables collaborative communication and audit trail maintenance throughout the intercompany transaction lifecycle.
/// </summary>
/// <remarks>
/// <para>
/// <b>Architecture:</b>
/// The intercompany comment system uses a line-based approach where comments are stored as individual records
/// linked to specific transactions, enabling multiple annotations per transaction with proper tracking of authorship and timing.
/// </para>
/// <para>
/// <b>Key Workflows:</b>
/// </para>
/// <list type="number">
/// <item>
/// <term><b>Transaction Annotation:</b></term>
/// <description>Add comments to inbox, outbox, and handled intercompany transactions for communication and documentation</description>
/// </item>
/// <item>
/// <term><b>Collaborative Review:</b></term>
/// <description>Enable multiple partners to add comments with proper authorship tracking and date stamping</description>
/// </item>
/// <item>
/// <term><b>Audit Trail:</b></term>
/// <description>Maintain historical record of transaction discussions and decision-making process</description>
/// </item>
/// </list>
/// <para>
/// <b>Integration Points:</b>
/// Integrates with intercompany transaction tables for comment attachment, partner management for authorship tracking,
/// and IC setup for default partner identification. Comments are accessible from transaction pages and provide context for transaction processing.
/// </para>
/// <para>
/// <b>Extensibility:</b>
/// Key extension points include comment initialization events, custom comment validation rules, and integration with external
/// communication systems. Supports field extensions for additional comment metadata and custom workflow integration.
/// </para>
/// </remarks>
namespace Microsoft.Intercompany.Comment;
