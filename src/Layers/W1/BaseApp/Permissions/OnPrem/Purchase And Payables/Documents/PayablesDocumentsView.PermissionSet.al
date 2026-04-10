namespace System.Security.AccessControl;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.RateChange;
using Microsoft.Finance.VAT.Reporting;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Reporting;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Tracking;
using Microsoft.Purchases.Comment;
using Microsoft.Purchases.History;
using System.Security.User;

permissionset 5951 "Payables Documents - View"
{
    Access = Public;
    Assignable = false;
    Caption = 'Read posted receipts etc.';

    Permissions = tabledata "Detailed Matched Order Line" = R,
                  tabledata "General Posting Setup" = r,
                  tabledata "Item Reference" = R,
                  tabledata "Item Tracking Code" = R,
                  tabledata "Matched Order Line" = R,
                  tabledata "Posted Matched Order Line" = R,
                  tabledata "Purch. Comment Line" = RIMD,
                  tabledata "Purch. Cr. Memo Hdr." = Rm,
                  tabledata "Purch. Cr. Memo Line" = R,
                  tabledata "Purch. Inv. Header" = Rm,
                  tabledata "Purch. Inv. Line" = R,
                  tabledata "Purch. Rcpt. Header" = Rm,
                  tabledata "Purch. Rcpt. Line" = R,
                  tabledata "Report Selections" = R,
                  tabledata "Return Shipment Header" = Rm,
                  tabledata "Return Shipment Line" = R,
                  tabledata "Tax Area" = R,
                  tabledata "Tax Area Line" = R,
                  tabledata "Tax Detail" = R,
                  tabledata "Tax Group" = R,
                  tabledata "Tax Jurisdiction" = R,
                  tabledata "User Setup" = r,
                  tabledata "VAT Assisted Setup Bus. Grp." = R,
                  tabledata "VAT Assisted Setup Templates" = R,
                  tabledata "VAT Posting Setup" = R,
                  tabledata "VAT Rate Change Setup" = R,
                  tabledata "VAT Reporting Code" = R,
                  tabledata "VAT Setup Posting Groups" = R;
}
