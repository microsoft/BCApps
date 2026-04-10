/// <summary>
/// Provides VAT ledger functionality for recording, managing, and analyzing VAT transaction entries in Business Central.
/// Enables comprehensive VAT tracking with unrealized VAT support, non-deductible VAT processing, and G/L integration for audit and compliance reporting.
/// </summary>
/// <remarks>
/// <para>
/// <b>Architecture:</b>
/// The VAT ledger system is built on a transactional ledger pattern where VAT Entry serves as the central transaction store, 
/// G/L Entry-VAT Entry Link maintains accounting relationships, and specialized pages provide analysis and maintenance capabilities.
/// </para>
/// <para>
/// <b>Key Workflows:</b>
/// </para>
/// <list type="number">
/// <item>
/// <term><b>VAT Entry Creation:</b></term>
/// <description>Generate VAT entries during document posting, copy posting groups and amounts from source documents, and establish G/L account relationships</description>
/// </item>
/// <item>
/// <term><b>Unrealized VAT Processing:</b></term>
/// <description>Calculate unrealized VAT portions based on payment percentages, manage settlement entries, and process realization during payment application</description>
/// </item>
/// <item>
/// <term><b>VAT Settlement and Analysis:</b></term>
/// <description>Close VAT entries through settlement processing, maintain reversal relationships, and provide reporting for VAT returns and audits</description>
/// </item>
/// </list>
/// <para>
/// <b>Integration Points:</b>
/// Integrates with General Ledger for posting and account relationships, Sales/Purchase documents for transaction origination, 
/// VAT Setup for calculation rules and posting groups, and Foundation Currency for multi-currency VAT processing. 
/// Supports VAT Return reporting and regulatory compliance requirements.
/// </para>
/// <para>
/// <b>Extensibility:</b>
/// Key extension points include VAT entry creation events through OnAfterCopyFromGenJnlLine, G/L account adjustment processing through OnBeforeSetGLAccountNo, 
/// and unrealized VAT calculation customization. Supports non-deductible VAT extensions and custom VAT date validation through VAT Reporting Date Management.
/// </para>
/// </remarks>
namespace Microsoft.Finance.VAT.Ledger;
