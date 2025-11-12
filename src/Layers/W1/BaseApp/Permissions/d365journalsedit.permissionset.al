namespace System.Security.AccessControl;

using Microsoft.Finance.AllocationAccount;
using Microsoft.Bank.BankAccount;
using Microsoft.Warehouse.Structure;
using Microsoft.Bank.Check;
using Microsoft.Sales.Receivables;
using Microsoft.HumanResources.Payables;
using Microsoft.Purchases.Payables;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Counting.Journal;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Ledger;
using Microsoft.Purchases.Vendor;
using Microsoft.Warehouse.Ledger;
using Microsoft.Inventory.Intrastat;
using Microsoft.Inventory.Item;
using Microsoft.Finance.VAT.RateChange;
using Microsoft.Finance.VAT.Registration;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Finance.VAT.Reporting;
using System.IO;

permissionset 242 "D365 JOURNALS, EDIT"
{
    Assignable = true;

    Caption = 'Dynamics 365 Edit journals';
    Permissions =
                  tabledata "Alloc. Acc. Manual Override" = RIMD,
                  tabledata "Alloc. Account Distribution" = RIMD,
                  tabledata "Allocation Account" = RIMD,
                  tabledata "Allocation Line" = RIMD,
                  tabledata "Bank Account" = R,
                  tabledata Bin = R,
                  tabledata "Check Ledger Entry" = Rimd,
                  tabledata "Cust. Ledger Entry" = Rm,
                  tabledata "Detailed Cust. Ledg. Entry" = Rm,
                  tabledata "Detailed Employee Ledger Entry" = Rm,
                  tabledata "Detailed Vendor Ledg. Entry" = Rm,
                  tabledata "Employee Ledger Entry" = Rm,
                  tabledata "G/L Account" = R,
                  tabledata "G/L Register" = Rimd,
                  tabledata "Gen. Journal Line" = RIMD,
                  tabledata "Item Entry Relation" = R,
                  tabledata "Item Journal Line" = RIMD,
                  tabledata "Item Tracing Buffer" = Rimd,
                  tabledata "Item Tracing History Buffer" = Rimd,
                  tabledata "Item Tracking Code" = R,
                  tabledata "Lot No. Information" = RIMD,
                  tabledata "Package No. Information" = RIMD,
                  tabledata "Phys. Invt. Counting Period" = RIMD,
                  tabledata "Phys. Invt. Item Selection" = RIMD,
                  tabledata "Planning Component" = Rm,
                  tabledata "Post Value Entry to G/L" = i,
                  tabledata "Record Buffer" = Rimd,
                  tabledata "Serial No. Information" = RIMD,
                  tabledata "Standard General Journal Line" = RIMD,
                  tabledata "Standard Item Journal" = RIMD,
                  tabledata "Standard Item Journal Line" = RIMD,
                  tabledata "Stockkeeping Unit" = R,
                  tabledata "Tracking Specification" = Rimd,
                  tabledata "Transaction Type" = R,
                  tabledata "Transport Method" = R,
                  tabledata "Value Entry Relation" = R,
                  tabledata "VAT Rate Change Conversion" = R,
                  tabledata "VAT Rate Change Log Entry" = Ri,
                  tabledata "VAT Rate Change Setup" = R,
                  tabledata "VAT Registration No. Format" = R,
                  tabledata "VAT Setup" = R,
                  tabledata "VAT Posting Parameters" = R,
                  tabledata "VAT Reporting Code" = R,
                  tabledata "Vendor Invoice Disc." = R,
                  tabledata "Vendor Ledger Entry" = Rm,
                  tabledata "Whse. Item Entry Relation" = R;
}
