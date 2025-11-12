namespace System.Security.AccessControl;

using Microsoft.Bank.Ledger;
using Microsoft.Bank.Check;
using Microsoft.Foundation.Comment;
using Microsoft.CRM.Duplicates;
using Microsoft.CRM.Contact;
using Microsoft.CRM.BusinessRelation;
using Microsoft.Foundation.Address;
using Microsoft.Finance.Currency;
using Microsoft.Sales.Receivables;
using Microsoft.Finance.Dimension;
using Microsoft.Purchases.Payables;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.HumanResources.Payables;
using Microsoft.HumanResources.Employee;
using Microsoft.FixedAssets.Ledger;
using Microsoft.Sales.FinanceCharge;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Intercompany.BankAccount;
using Microsoft.Intercompany.Partner;
using Microsoft.FixedAssets.Insurance;
using Microsoft.CRM.Interaction;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Analysis;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Location;
using Microsoft.FixedAssets.Maintenance;
using Microsoft.Purchases.Vendor;
using Microsoft.CRM.Opportunity;
using Microsoft.Bank.BankAccount;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Pricing.Asset;
using Microsoft.Pricing.Source;
using Microsoft.Pricing.Worksheet;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Pricing;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Archive;
using Microsoft.Warehouse.Activity.History;
using Microsoft.Purchases.Remittance;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Sales.History;
using Microsoft.Finance.SalesTax;
using Microsoft.CRM.Task;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.Worksheet;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.CRM.Team;
using Microsoft.Foundation.Shipping;
using Microsoft.Inventory.Intrastat;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Finance.VAT.RateChange;
using Microsoft.Finance.VAT.Registration;
using Microsoft.Finance.VAT.Reporting;

permissionset 7371 "Vendor - Edit"
{
    Access = Public;
    Assignable = false;
    Caption = 'Edit vendors';

    Permissions = tabledata "Bank Account Ledger Entry" = rm,
                  tabledata "Check Ledger Entry" = r,
                  tabledata "Comment Line" = RIMD,
                  tabledata "Cont. Duplicate Search String" = RIMD,
                  tabledata Contact = RIM,
                  tabledata "Contact Business Relation" = ImD,
                  tabledata "Contact Duplicate" = R,
                  tabledata "Country/Region" = R,
                  tabledata Currency = R,
                  tabledata "Cust. Ledger Entry" = r,
                  tabledata "Default Dimension" = RIMD,
                  tabledata "Detailed Vendor Ledg. Entry" = Rim,
                  tabledata "Dtld. Price Calculation Setup" = Rid,
                  tabledata "Duplicate Price Line" = Rid,
                  tabledata "Duplicate Search String Setup" = R,
                  tabledata "Employee Ledger Entry" = Rm,
                  tabledata "Employee Posting Group" = R,
                  tabledata "FA Ledger Entry" = rm,
                  tabledata "Finance Charge Terms" = R,
                  tabledata "Fixed Asset" = rm,
                  tabledata "G/L Account" = R,
                  tabledata "G/L Entry - VAT Entry Link" = rm,
                  tabledata "G/L Entry" = rm,
                  tabledata "Gen. Business Posting Group" = R,
                  tabledata "Gen. Journal Batch" = r,
                  tabledata "Gen. Journal Line" = r,
                  tabledata "Gen. Journal Template" = r,
                  tabledata "IC Bank Account" = Rm,
                  tabledata "IC Partner" = Rm,
                  tabledata Insurance = r,
                  tabledata "Interaction Log Entry" = R,
                  tabledata Item = Rm,
                  tabledata "Item Analysis View Budg. Entry" = r,
                  tabledata "Item Analysis View Entry" = rid,
                  tabledata "Item Budget Entry" = r,
                  tabledata "Item Journal Line" = r,
                  tabledata "Item Ledger Entry" = rm,
                  tabledata "Item Reference" = RIMD,
                  tabledata "Item Vendor" = Rid,
                  tabledata Location = R,
                  tabledata "Maintenance Ledger Entry" = rm,
                  tabledata "Maintenance Registration" = rm,
                  tabledata "My Vendor" = RIMD,
                  tabledata "Nonstock Item" = rm,
                  tabledata Opportunity = R,
                  tabledata "Order Address" = RIMD,
                  tabledata "Payment Method" = R,
                  tabledata "Payment Terms" = R,
                  tabledata "Price Asset" = Rid,
                  tabledata "Price Calculation Buffer" = Rid,
                  tabledata "Price Calculation Setup" = Rid,
                  tabledata "Price Line Filters" = Rid,
                  tabledata "Price List Header" = Rid,
                  tabledata "Price List Line" = Rid,
                  tabledata "Price Source" = Rid,
                  tabledata "Price Worksheet Line" = Rid,
                  tabledata "Purch. Cr. Memo Hdr." = rm,
                  tabledata "Purch. Cr. Memo Line" = rm,
                  tabledata "Purch. Inv. Header" = rm,
                  tabledata "Purch. Inv. Line" = rm,
                  tabledata "Purch. Rcpt. Header" = rm,
                  tabledata "Purch. Rcpt. Line" = rm,
                  tabledata "Purchase Discount Access" = Rid,
                  tabledata "Purchase Header" = rm,
                  tabledata "Purchase Header Archive" = r,
                  tabledata "Purchase Line" = Rm,
                  tabledata "Purchase Line Discount" = Rid,
                  tabledata "Purchase Price" = Rid,
                  tabledata "Purchase Price Access" = Rid,
                  tabledata "Registered Whse. Activity Line" = rm,
                  tabledata "Remit Address" = RIMD,
                  tabledata "Res. Capacity Entry" = RIMD,
                  tabledata Resource = rm,
                  tabledata "Responsibility Center" = R,
                  tabledata "Return Receipt Header" = rm,
                  tabledata "Return Receipt Line" = rm,
                  tabledata "Return Shipment Header" = rm,
                  tabledata "Return Shipment Line" = rm,
                  tabledata "Salesperson/Purchaser" = R,
                  tabledata "Shipment Method" = R,
                  tabledata "Standard General Journal" = r,
                  tabledata "Standard General Journal Line" = r,
                  tabledata "Standard Vendor Purchase Code" = rid,
                  tabledata "Tax Area" = R,
                  tabledata Territory = R,
                  tabledata "To-do" = R,
                  tabledata "Value Entry" = rm,
                  tabledata "VAT Assisted Setup Bus. Grp." = R,
                  tabledata "VAT Assisted Setup Templates" = R,
                  tabledata "VAT Business Posting Group" = R,
                  tabledata "VAT Entry" = rm,
                  tabledata "VAT Posting Setup" = R,
                  tabledata "VAT Rate Change Log Entry" = Ri,
                  tabledata "VAT Rate Change Setup" = R,
                  tabledata "VAT Registration No. Format" = R,
                  tabledata "VAT Reporting Code" = R,
                  tabledata "VAT Setup Posting Groups" = R,
                  tabledata Vendor = RIMD,
                  tabledata "Vendor Bank Account" = RIMD,
                  tabledata "Vendor Invoice Disc." = R,
                  tabledata "Vendor Ledger Entry" = Rm,
                  tabledata "Vendor Posting Group" = R,
                  tabledata "Warehouse Activity Header" = r,
                  tabledata "Warehouse Activity Line" = r,
                  tabledata "Warehouse Reason Code" = r,
                  tabledata "Warehouse Request" = rm,
                  tabledata "Warehouse Shipment Line" = rm,
                  tabledata "Whse. Worksheet Line" = r;
}
