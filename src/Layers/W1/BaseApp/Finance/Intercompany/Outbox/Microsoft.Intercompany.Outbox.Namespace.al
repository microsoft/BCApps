/// <summary>
/// Provides intercompany outbox functionality for managing outbound transactions to partner companies in Business Central.
/// Enables transaction staging, export, transmission, and status management for intercompany business processes.
/// </summary>
/// <remarks>
/// <para>
/// <b>Architecture:</b>
/// The intercompany outbox system manages outbound transaction flow through staging tables, export processing, 
/// and partner communication with support for both internal and external partner relationships.
/// </para>
/// <para>
/// <b>Key Workflows:</b>
/// </para>
/// <list type="number">
/// <item>
/// <term><b>Transaction Staging:</b></term>
/// <description>Stage outbound transactions from sales, purchase, and journal documents with partner validation and document type classification</description>
/// </item>
/// <item>
/// <term><b>Export and Transmission:</b></term>
/// <description>Export transactions to XML format and transmit to partners via file system, email, or direct internal transfer</description>
/// </item>
/// <item>
/// <term><b>Status Management:</b></term>
/// <description>Track transaction status, handle partner responses, and manage transaction lifecycle from creation to completion</description>
/// </item>
/// </list>
/// <para>
/// <b>Integration Points:</b>
/// Integrates with Intercompany Partner setup, Sales/Purchase document processing, General Journal operations, 
/// and file/email systems for transaction transmission. Uses Data Exchange Framework for XML processing.
/// </para>
/// <para>
/// <b>Extensibility:</b>
/// Key extension points include custom export formats via integration events, partner communication methods through 
/// OnBeforeSend events, and transaction validation through custom processing hooks in export and transmission workflows.
/// </para>
/// </remarks>
namespace Microsoft.Intercompany.Outbox;
