/// <summary>
/// Provides intercompany journal functionality for managing transactions between related companies in Business Central.
/// Enables intercompany general journal operations with specialized validation, posting, and reconciliation capabilities.
/// </summary>
/// <remarks>
/// <para>
/// <b>Architecture:</b>
/// The intercompany journal system extends standard general journal functionality with intercompany partner integration, 
/// specialized account type validation, and transaction document type classification for intercompany operations.
/// </para>
/// <para>
/// <b>Key Workflows:</b>
/// </para>
/// <list type="number">
/// <item>
/// <term><b>Journal Entry Creation:</b></term>
/// <description>Create intercompany journal entries with partner validation, account mapping, and document type classification</description>
/// </item>
/// <item>
/// <term><b>Transaction Processing:</b></term>
/// <description>Post intercompany transactions with automatic G/L integration, dimension handling, and approval workflows</description>
/// </item>
/// <item>
/// <term><b>Reconciliation:</b></term>
/// <description>Reconcile intercompany balances and verify transaction consistency between partner companies</description>
/// </item>
/// </list>
/// <para>
/// <b>Integration Points:</b>
/// Integrates with General Ledger posting, Intercompany Partner setup, dimension management, and approval workflow systems. 
/// Uses standard journal templates with intercompany-specific validation and account type restrictions.
/// </para>
/// <para>
/// <b>Extensibility:</b>
/// Key extension points include custom document types via enum extensions, validation events for intercompany rules, 
/// and page extensions for additional intercompany fields and partner-specific functionality.
/// </para>
/// </remarks>
namespace Microsoft.Intercompany.Journal;
