namespace System.Security.AccessControl;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Warehouse.Structure;
using Microsoft.Finance.Dimension;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Planning;
using Microsoft.Manufacturing.Document;
using Microsoft.Purchases.Document;
using Microsoft.Inventory.Requisition;
using Microsoft.Sales.Document;
using System.Security.User;
using Microsoft.Foundation.Period;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.UOM;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Finance.VAT.RateChange;
using Microsoft.Finance.VAT.Reporting;

permissionset 3691 "Consumption Journals - Post"
{
    Access = Public;
    Assignable = false;
    Caption = 'Post Cons. Jnl.';

    Permissions = tabledata "Accounting Period" = R,
                  tabledata Bin = R,
                  tabledata "Dimension Combination" = R,
                  tabledata "Dimension Value Combination" = R,
                  tabledata "Entry Summary" = RIMD,
                  tabledata "Gen. Business Posting Group" = R,
                  tabledata "Gen. Product Posting Group" = R,
                  tabledata "General Ledger Setup" = R,
                  tabledata "General Posting Setup" = R,
                  tabledata "Inventory Posting Group" = R,
                  tabledata "Inventory Posting Setup" = R,
                  tabledata Item = Rm,
                  tabledata "Item Journal Batch" = RID,
                  tabledata "Item Journal Line" = Rm,
                  tabledata "Item Journal Template" = RI,
                  tabledata "Item Ledger Entry" = Rim,
                  tabledata "Item Register" = Rim,
                  tabledata "Item Tracking Code" = R,
                  tabledata "Item Tracking Comment" = RIMD,
                  tabledata "Item Unit of Measure" = R,
                  tabledata "Item Variant" = R,
                  tabledata "Lot No. Information" = R,
                  tabledata "Package No. Information" = R,
                  tabledata "Planning Component" = Rm,
                  tabledata "Prod. Order Component" = Rm,
                  tabledata "Prod. Order Line" = Rm,
                  tabledata "Production Order" = R,
                  tabledata "Purchase Line" = Rm,
                  tabledata "Reason Code" = R,
                  tabledata "Requisition Line" = Rim,
                  tabledata "Reservation Entry" = Rimd,
                  tabledata "Sales Line" = Rm,
                  tabledata "Serial No. Information" = R,
                  tabledata "Source Code Setup" = R,
                  tabledata "Tracking Specification" = Rimd,
                  tabledata "Unit of Measure" = R,
                  tabledata "User Setup" = R,
                  tabledata "Value Entry" = Rm,
                  tabledata "VAT Assisted Setup Bus. Grp." = R,
                  tabledata "VAT Assisted Setup Templates" = R,
                  tabledata "VAT Business Posting Group" = R,
                  tabledata "VAT Posting Setup" = R,
                  tabledata "VAT Product Posting Group" = R,
                  tabledata "VAT Rate Change Conversion" = R,
                  tabledata "VAT Rate Change Log Entry" = Ri,
                  tabledata "VAT Rate Change Setup" = R,
                  tabledata "VAT Reporting Code" = R,
                  tabledata "VAT Setup Posting Groups" = R,
                  tabledata "VAT Setup" = R;
}
