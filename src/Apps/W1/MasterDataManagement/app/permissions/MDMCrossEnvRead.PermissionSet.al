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

/// <summary>
/// Assigned to the customer-registered Entra app on the SOURCE (Microsoft Entra Application Card) to grant
/// cross-environment, read-only access to master data. Deliberately NOT part of "Master Data Mgt. - Objects":
/// only this set grants execute on the ODataV4 source API, so local users cannot invoke it.
/// Grants read on the master-data tables synchronized by the default configuration, so cross-environment sync
/// works read-only out of the box. For custom or additional tables, a tenant admin extends this set (or assigns
/// a second, narrowly scoped set alongside it) - which keeps least privilege instead of reaching for SUPER.
/// </summary>
permissionset 7242 "MDM Cross-Env Read"
{
    Assignable = true;
    Access = Public;
    Caption = 'Master Data Mgt. - Cross Environment';

    Permissions = codeunit "MDM Cross-Env Source API" = X,
                  tabledata "Salesperson/Purchaser" = R,
                  tabledata Customer = R,
                  tabledata Vendor = R,
                  tabledata Contact = R,
                  tabledata "Business Relation" = R,
                  tabledata "Country/Region" = R,
                  tabledata "Post Code" = R,
                  tabledata Currency = R,
                  tabledata "Currency Exchange Rate" = R,
                  tabledata "Payment Terms" = R,
                  tabledata "Shipment Method" = R,
                  tabledata "Shipping Agent" = R,
                  tabledata "Sales & Receivables Setup" = R,
                  tabledata "Purchases & Payables Setup" = R,
                  tabledata "Marketing Setup" = R,
                  tabledata "No. Series" = R,
                  tabledata "No. Series Line" = R,
                  tabledata "G/L Account" = R,
                  tabledata Dimension = R,
                  tabledata "Dimension Value" = R,
                  tabledata "Gen. Business Posting Group" = R,
                  tabledata "Gen. Product Posting Group" = R,
                  tabledata "Customer Posting Group" = R,
                  tabledata "Vendor Posting Group" = R,
                  tabledata "VAT Business Posting Group" = R,
                  tabledata "VAT Product Posting Group" = R,
                  tabledata "VAT Posting Setup" = R,
                  tabledata "Tax Area" = R,
                  tabledata "Tax Group" = R,
                  tabledata "Tax Jurisdiction" = R,
                  tabledata "Tenant Media" = R;
}
