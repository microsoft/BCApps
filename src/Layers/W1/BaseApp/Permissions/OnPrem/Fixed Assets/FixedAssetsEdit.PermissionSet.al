namespace System.Security.AccessControl;

using Microsoft.Bank.Ledger;
using Microsoft.Warehouse.Structure;
using Microsoft.Bank.Check;
using Microsoft.Foundation.Comment;
using Microsoft.Finance.Currency;
using Microsoft.Sales.Receivables;
using Microsoft.Finance.Dimension;
using Microsoft.FixedAssets.Depreciation;
using Microsoft.HumanResources.Employee;
using Microsoft.HumanResources.Payables;
using Microsoft.FixedAssets.Setup;
using Microsoft.FixedAssets.Ledger;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.HumanResources.Comment;
using Microsoft.FixedAssets.Insurance;
using Microsoft.Inventory.Location;
using Microsoft.FixedAssets.Maintenance;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Document;
using Microsoft.Purchases.Vendor;
using Microsoft.Purchases.Payables;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Finance.VAT.RateChange;

permissionset 3846 "Fixed Assets - Edit"
{
    Access = Public;
    Assignable = false;
    Caption = 'Edit fixed assets';

    Permissions = tabledata "Bank Account Ledger Entry" = r,
                  tabledata Bin = R,
                  tabledata "Check Ledger Entry" = r,
                  tabledata "Comment Line" = RIMD,
                  tabledata Currency = R,
                  tabledata "Currency Exchange Rate" = R,
                  tabledata "Cust. Ledger Entry" = r,
                  tabledata "Default Dimension" = RIMD,
                  tabledata "Depreciation Table Header" = RIMD,
                  tabledata "Depreciation Table Line" = RIMD,
                  tabledata Employee = R,
                  tabledata "Employee Ledger Entry" = r,
                  tabledata "FA Class" = RIMD,
                  tabledata "FA Depreciation Book" = RIMD,
                  tabledata "FA Ledger Entry" = Rm,
                  tabledata "FA Location" = RIMD,
                  tabledata "FA Posting Group" = R,
                  tabledata "FA Subclass" = RIMD,
                  tabledata "Fixed Asset" = RIMD,
                  tabledata "G/L Account" = R,
                  tabledata "G/L Entry" = rm,
                  tabledata "Gen. Journal Batch" = r,
                  tabledata "Gen. Journal Line" = r,
                  tabledata "Gen. Journal Template" = r,
                  tabledata "Gen. Product Posting Group" = R,
                  tabledata "Human Resource Comment Line" = r,
                  tabledata "Ins. Coverage Ledger Entry" = rm,
                  tabledata Insurance = rm,
                  tabledata Location = R,
                  tabledata "Main Asset Component" = RIMD,
                  tabledata Maintenance = RIMD,
                  tabledata "Maintenance Ledger Entry" = Rm,
                  tabledata "Maintenance Registration" = RIMD,
                  tabledata "Purch. Cr. Memo Line" = r,
                  tabledata "Purch. Inv. Line" = rm,
                  tabledata "Purch. Rcpt. Line" = rm,
                  tabledata "Purchase Line" = r,
                  tabledata "Return Receipt Line" = r,
                  tabledata "Return Shipment Line" = r,
                  tabledata "Sales Cr.Memo Line" = r,
                  tabledata "Sales Invoice Line" = r,
                  tabledata "Sales Line" = r,
                  tabledata "Sales Shipment Line" = r,
                  tabledata "Standard General Journal" = r,
                  tabledata "Standard General Journal Line" = r,
                  tabledata "Standard Purchase Line" = r,
                  tabledata "Standard Sales Line" = r,
                  tabledata "VAT Product Posting Group" = R,
                  tabledata "VAT Rate Change Conversion" = R,
                  tabledata Vendor = R,
                  tabledata "Vendor Ledger Entry" = r;
}
