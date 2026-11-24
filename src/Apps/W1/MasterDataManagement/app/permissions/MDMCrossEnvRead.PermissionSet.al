namespace Microsoft.Integration.MDM;

using Microsoft.CRM.BusinessRelation;
using Microsoft.CRM.Contact;
using Microsoft.CRM.Setup;
using Microsoft.CRM.Team;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Foundation.Shipping;
using Microsoft.Purchases.Setup;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Setup;
using System.Environment;
using System.Privacy;

/// <summary>
/// Assigned to the customer-registered Entra app on the SOURCE (Microsoft Entra Application Card) to grant
/// cross-environment, read-only access to master data. Deliberately NOT part of "Master Data Mgt. - Objects":
/// only this set grants execute on the ODataV4 source API, so local users cannot invoke it.
/// Grants INDIRECT read (r) on the master-data tables synchronized by the default configuration, so the app can read
/// them only through the "MDM Cross-Env Source API" codeunit (which holds the matching Permissions property), not
/// through standard API pages or other web services. Keep this list in sync with that codeunit's Permissions property.
/// For custom or additional tables, a tenant admin grants DIRECT read (R) in a second, narrowly scoped permission set
/// assigned alongside this one, because the codeunit's Permissions property can't be extended. That keeps least
/// privilege instead of reaching for SUPER.
/// </summary>
permissionset 7242 "MDM Cross-Env Read"
{
    Assignable = true;
    Access = Public;
    Caption = 'Master Data Mgt. - Cross Environment';

    Permissions = codeunit "MDM Cross-Env Source API" = X,
                  tabledata "Salesperson/Purchaser" = r,
                  tabledata Customer = r,
                  tabledata Vendor = r,
                  tabledata Contact = r,
                  tabledata "Business Relation" = r,
                  tabledata "Contact Business Relation" = r,
                  tabledata "Country/Region" = r,
                  tabledata "Post Code" = r,
                  tabledata Currency = r,
                  tabledata "Currency Exchange Rate" = r,
                  tabledata "Payment Terms" = r,
                  tabledata "Shipment Method" = r,
                  tabledata "Shipping Agent" = r,
                  tabledata "Sales & Receivables Setup" = r,
                  tabledata "Purchases & Payables Setup" = r,
                  tabledata "Marketing Setup" = r,
                  tabledata "No. Series" = r,
                  tabledata "No. Series Line" = r,
                  tabledata "G/L Account" = r,
                  tabledata Dimension = r,
                  tabledata "Dimension Value" = r,
                  tabledata "Gen. Business Posting Group" = r,
                  tabledata "Gen. Product Posting Group" = r,
                  tabledata "Customer Posting Group" = r,
                  tabledata "Vendor Posting Group" = r,
                  tabledata "VAT Business Posting Group" = r,
                  tabledata "VAT Product Posting Group" = r,
                  tabledata "VAT Posting Setup" = r,
                  tabledata "Tax Area" = r,
                  tabledata "Tax Group" = r,
                  tabledata "Tax Jurisdiction" = r,
                  tabledata "Tenant Media" = r,
                  // Read the consent tables so the source can answer "not consented" as a structured signal instead of throwing a permission error (surfaced as a bare HTTP 403).
                  tabledata "Privacy Notice" = R,
                  tabledata "Privacy Notice Approval" = R;
}
