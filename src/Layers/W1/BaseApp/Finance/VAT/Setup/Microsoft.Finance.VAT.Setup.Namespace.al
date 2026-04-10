/// <summary>
/// VAT setup and configuration components providing comprehensive VAT management capabilities in Business Central.
/// Enables configuration of VAT posting groups, VAT posting setups, VAT rates, account assignments, and non-deductible VAT functionality.
/// </summary>
/// <remarks>
/// <para>
/// <b>Architecture:</b>
/// The VAT Setup system is built on a two-dimensional posting group structure where VAT Business Posting Groups (customers/vendors) 
/// combine with VAT Product Posting Groups (items/services) to create VAT Posting Setups that define calculation rules and G/L account assignments.
/// </para>
/// <para>
/// <b>Key Workflows:</b>
/// </para>
/// <list type="number">
/// <item>
/// <term><b>VAT Setup Configuration:</b></term>
/// <description>Create VAT business and product posting groups, configure VAT posting setups with rates and accounts, enable advanced features like non-deductible VAT</description>
/// </item>
/// <item>
/// <term><b>VAT Calculation Processing:</b></term>
/// <description>Calculate VAT amounts based on posting group combinations, handle unrealized VAT scenarios, process reverse charge transactions, manage non-deductible VAT portions</description>
/// </item>
/// <item>
/// <term><b>VAT Account Assignment:</b></term>
/// <description>Map VAT amounts to appropriate G/L accounts for sales, purchase, unrealized, and reverse charge scenarios based on VAT posting setup configuration</description>
/// </item>
/// </list>
/// <para>
/// <b>Integration Points:</b>
/// Integrates with General Ledger for account assignments and posting, Sales/Purchase documents for VAT calculation, 
/// VAT reporting for return preparation, and Customer/Vendor/Item master data for VAT posting group assignments.
/// </para>
/// <para>
/// <b>Extensibility:</b>
/// Key extension points include VAT calculation customization events, VAT posting setup validation hooks, 
/// custom VAT caption handling, and template-based setup automation. Supports country-specific VAT requirements through extension patterns.
/// </para>
/// </remarks>
namespace Microsoft.Finance.VAT.Setup;
