namespace System.Security.AccessControl;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Warehouse.Structure;
using Microsoft.Foundation.Comment;
using Microsoft.Foundation.Address;
using Microsoft.Finance.Dimension;
using Microsoft.Inventory.Counting.Tracking;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Counting.Journal;
using Microsoft.Inventory.Counting.Comment;
using Microsoft.Inventory.Counting.Document;
using Microsoft.Inventory.Counting.Recording;
using Microsoft.Inventory.Counting.History;
using System.Security.User;
using Microsoft.Foundation.Period;
using Microsoft.Foundation.AuditCodes;
using Microsoft.CRM.Team;
using Microsoft.Inventory.Intrastat;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Finance.VAT.RateChange;
using Microsoft.Finance.VAT.Reporting;
using Microsoft.Finance.VAT.Calculation;

permissionset 4736 "Physical Invt Journals - Edit"
{
    Access = Public;
    Assignable = false;
    Caption = 'Taking a physical inventory';

    Permissions = tabledata "Accounting Period" = R,
                  tabledata Bin = R,
                  tabledata "Comment Line" = R,
                  tabledata "Country/Region" = R,
                  tabledata "Default Dimension" = R,
                  tabledata "Default Dimension Priority" = R,
                  tabledata "Exp. Invt. Order Tracking" = RIMD,
                  tabledata "Gen. Business Posting Group" = R,
                  tabledata "Gen. Product Posting Group" = R,
                  tabledata "General Ledger Setup" = R,
                  tabledata "General Posting Setup" = R,
                  tabledata "Inventory Posting Group" = R,
                  tabledata "Inventory Posting Setup" = R,
                  tabledata Item = Rm,
                  tabledata "Item Application Entry" = Ri,
                  tabledata "Item Journal Batch" = RI,
                  tabledata "Item Journal Line" = RIM,
                  tabledata "Item Journal Template" = RI,
                  tabledata "Item Ledger Entry" = Rim,
                  tabledata "Item Register" = Rim,
                  tabledata "Item Variant" = R,
                  tabledata Location = R,
                  tabledata "Phys. Inventory Ledger Entry" = im,
                  tabledata "Phys. Invt. Comment Line" = RIMD,
                  tabledata "Phys. Invt. Count Buffer" = RIMD,
                  tabledata "Phys. Invt. Order Header" = RIMD,
                  tabledata "Phys. Invt. Order Line" = RIMD,
                  tabledata "Phys. Invt. Record Header" = RIMD,
                  tabledata "Phys. Invt. Record Line" = RIMD,
                  tabledata "Invt. Order Tracking" = RIMD,
                  tabledata "Pstd.Exp.Invt.Order.Tracking" = RIMD,
                  tabledata "Pstd. Phys. Invt. Order Hdr" = RIMD,
                  tabledata "Pstd. Phys. Invt. Order Line" = RIMD,
                  tabledata "Pstd. Phys. Invt. Record Hdr" = RIMD,
                  tabledata "Pstd. Phys. Invt. Record Line" = RIMD,
                  tabledata "Pstd. Phys. Invt. Tracking" = RIMD,
                  tabledata "Reason Code" = R,
                  tabledata "Salesperson/Purchaser" = R,
                  tabledata "Source Code Setup" = R,
                  tabledata "Stockkeeping Unit" = R,
                  tabledata "Stockkeeping Unit Comment Line" = R,
                  tabledata "Transaction Type" = R,
                  tabledata "Transport Method" = R,
                  tabledata "User Setup" = R,
                  tabledata "Value Entry" = Rim,
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
                  tabledata "VAT Setup" = R,
                  tabledata "VAT Posting Parameters" = R;
}
