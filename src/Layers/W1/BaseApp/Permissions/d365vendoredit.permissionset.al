namespace System.Security.AccessControl;

using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.RateChange;
using Microsoft.Finance.VAT.Registration;
using Microsoft.Bank.Ledger;
using Microsoft.Bank.Check;
using Microsoft.CRM.Duplicates;
using Microsoft.CRM.Contact;
using Microsoft.CRM.BusinessRelation;
using Microsoft.Finance.Currency;
using Microsoft.Sales.Receivables;
using Microsoft.Purchases.Payables;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.CRM.Interaction;
using Microsoft.Inventory.Analysis;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.CRM.Opportunity;
using Microsoft.Purchases.Vendor;
using Microsoft.Bank.BankAccount;
using Microsoft.Pricing.Asset;
using Microsoft.Pricing.Source;
using Microsoft.Pricing.Worksheet;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Pricing;
using Microsoft.Purchases.Archive;
using Microsoft.Purchases.Setup;
using Microsoft.Warehouse.Activity.History;
using Microsoft.Purchases.Remittance;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Sales.History;
using Microsoft.Sales.Customer;
using Microsoft.Purchases.Document;
using Microsoft.CRM.Task;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.Worksheet;
using Microsoft.Finance.Analysis;

permissionset 9921 "D365 VENDOR, EDIT"
{
    Assignable = true;
    Caption = 'Dynamics 365 Create vendors';

    IncludedPermissionSets = "D365 VENDOR, VIEW";

    Permissions = tabledata "Bank Account Ledger Entry" = rm,
                  tabledata "Check Ledger Entry" = r,
                  tabledata "Cont. Duplicate Search String" = RIMD,
                  tabledata Contact = RIM,
                  tabledata "Contact Business Relation" = RImD,
                  tabledata "Contact Duplicate" = Rd,
                  tabledata "Company Size" = rimd,
                  tabledata Currency = RM,
                  tabledata "Cust. Ledger Entry" = r,
                  tabledata "Detailed Vendor Ledg. Entry" = Rimd,
                  tabledata "Dtld. Price Calculation Setup" = RIMD,
                  tabledata "Duplicate Price Line" = RIMD,
                  tabledata "Duplicate Search String Setup" = R,
                  tabledata "G/L Entry - VAT Entry Link" = rm,
                  tabledata "G/L Entry" = rm,
                  tabledata "Interaction Log Entry" = R,
                  tabledata "Item Analysis View Budg. Entry" = r,
                  tabledata "Item Analysis View Entry" = rid,
                  tabledata "Item Budget Entry" = r,
                  tabledata "Item Reference" = IMD,
                  tabledata "Item Vendor" = Rid,
                  tabledata "Nonstock Item" = rm,
                  tabledata Opportunity = R,
                  tabledata "Order Address" = RIMD,
                  tabledata "Payment Method" = R,
                  tabledata "Price Asset" = RIMD,
                  tabledata "Price Calculation Buffer" = RIMD,
                  tabledata "Price Calculation Setup" = RIMD,
                  tabledata "Price Line Filters" = RIMD,
                  tabledata "Price List Header" = RIMD,
                  tabledata "Price List Line" = RIMD,
                  tabledata "Price Source" = RIMD,
                  tabledata "Price Worksheet Line" = RIMD,
                  tabledata "Purch. Cr. Memo Hdr." = rm,
                  tabledata "Purch. Cr. Memo Line" = rm,
                  tabledata "Purch. Inv. Header" = rm,
                  tabledata "Purch. Inv. Line" = rm,
                  tabledata "Purch. Rcpt. Header" = rm,
                  tabledata "Purch. Rcpt. Line" = rm,
                  tabledata "Purchase Discount Access" = RIMD,
                  tabledata "Purchase Header Archive" = r,
#if not CLEAN25
                  tabledata "Purchase Line Discount" = RIMD,
                  tabledata "Purchase Price" = RIMD,
#endif
                  tabledata "Purchase Price Access" = RIMD,
                  tabledata "Purchases & Payables Setup" = M,
                  tabledata "Registered Whse. Activity Line" = rm,
                  tabledata "Remit Address" = RIMD,
                  tabledata "Res. Capacity Entry" = RIMD,
                  tabledata "Return Receipt Header" = rm,
                  tabledata "Return Receipt Line" = rm,
                  tabledata "Return Shipment Header" = Rm,
                  tabledata "Return Shipment Line" = rm,
                  tabledata "Ship-to Address" = RIMD,
                  tabledata "Standard Purchase Code" = RIMD,
                  tabledata "Standard Purchase Line" = RIMD,
                  tabledata "Standard Vendor Purchase Code" = RIMD,
                  tabledata "To-do" = R,
                  tabledata "VAT Entry" = Rm,
                  tabledata "VAT Rate Change Log Entry" = Ri,
                  tabledata "VAT Rate Change Setup" = R,
                  tabledata "VAT Reg. No. Srv Config" = RIMD,
                  tabledata "VAT Reg. No. Srv. Template" = RIMD,
                  tabledata "VAT Registration Log Details" = RIMD,
                  tabledata "VAT Registration No. Format" = RIMD,
                  tabledata Vendor = RIMD,
                  tabledata "Vendor Bank Account" = IMD,
                  tabledata "Vendor Invoice Disc." = IMD,
                  tabledata "Vendor Ledger Entry" = M,
                  tabledata "Warehouse Activity Header" = r,
                  tabledata "Warehouse Activity Line" = r,
                  tabledata "Warehouse Reason Code" = r,
                  tabledata "Warehouse Request" = rm,
                  tabledata "Warehouse Shipment Line" = rm,
                  tabledata "Whse. Worksheet Line" = r;
}
