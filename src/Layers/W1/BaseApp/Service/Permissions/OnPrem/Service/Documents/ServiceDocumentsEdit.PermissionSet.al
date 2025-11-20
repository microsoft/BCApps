// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Security.AccessControl;

using Microsoft.Utilities;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.CRM.Team;
using Microsoft.Projects.Project.Job;
using Microsoft.Inventory.Location;
using Microsoft.Foundation.Reporting;
using Microsoft.Finance.VAT.Reporting;
using Microsoft.Projects.Project.Ledger;
using Microsoft.Projects.Project.Planning;
using Microsoft.Projects.Project.Posting;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.UOM;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Finance.VAT.RateChange;
using Microsoft.Warehouse.Structure;
using Microsoft.Inventory.BOM;
using Microsoft.CRM.Campaign;
using Microsoft.Foundation.Comment;
using Microsoft.CRM.Contact;
using Microsoft.Service.Archive;
using Microsoft.Service.Contract;
using Microsoft.Foundation.Address;
using Microsoft.Finance.Currency;
using Microsoft.Sales.Receivables;
using Microsoft.Finance.Dimension;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.Inventory.Tracking;
using Microsoft.Foundation.ExtendedText;
using Microsoft.Service.Maintenance;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.CRM.Interaction;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Item.Substitution;
using Microsoft.Service.Loaner;
using Microsoft.Bank.BankAccount;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Inventory.Planning;
using Microsoft.Pricing.Asset;
using Microsoft.Pricing.Source;
using Microsoft.Pricing.Worksheet;
using Microsoft.Purchases.Document;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Projects.Resources.Pricing;
using Microsoft.Service.Resources;
using Microsoft.Sales.History;
using Microsoft.Sales.Pricing;
using Microsoft.CRM.Segment;
using Microsoft.Service.Pricing;
using Microsoft.Service.Comment;
using Microsoft.Service.Document;
using Microsoft.Service.Email;
using Microsoft.Service.History;
using Microsoft.Service.Item;
using Microsoft.Service.Ledger;
using Microsoft.Service.Setup;
using Microsoft.Finance.SalesTax;
using Microsoft.Inventory.Transfer;
using System.Security.User;

permissionset 8611 "Service Documents - Edit"
{
    Access = Public;
    Assignable = false;
    Caption = 'Create orders,quotes,etc.';

    Permissions = tabledata "Alt. Customer Posting Group" = R,
                  tabledata Bin = R,
                  tabledata "BOM Component" = r,
                  tabledata Campaign = R,
                  tabledata "Comment Line" = R,
                  tabledata Contact = R,
                  tabledata "Contact Alt. Addr. Date Range" = R,
                  tabledata "Contact Job Responsibility" = R,
                  tabledata "Contract Group" = R,
                  tabledata "Country/Region" = R,
                  tabledata Currency = R,
                  tabledata "Currency Exchange Rate" = R,
                  tabledata "Cust. Invoice Disc." = R,
                  tabledata "Cust. Ledger Entry" = R,
                  tabledata Customer = R,
                  tabledata "Customer Bank Account" = R,
                  tabledata "Customer Posting Group" = R,
                  tabledata "Customer Price Group" = R,
                  tabledata "Default Dimension" = R,
                  tabledata "Default Dimension Priority" = R,
                  tabledata "Detailed Cust. Ledg. Entry" = R,
                  tabledata "Dtld. Price Calculation Setup" = R,
                  tabledata "Duplicate Price Line" = R,
                  tabledata "Entry Summary" = RIMD,
                  tabledata "Extended Text Header" = R,
                  tabledata "Extended Text Line" = R,
                  tabledata "Fault Area" = R,
                  tabledata "Fault Code" = R,
                  tabledata "Fault Reason Code" = R,
                  tabledata "Fault/Resol. Cod. Relationship" = RIMD,
                  tabledata "G/L Account" = R,
                  tabledata "Gen. Business Posting Group" = R,
                  tabledata "Gen. Product Posting Group" = R,
                  tabledata "General Ledger Setup" = rm,
                  tabledata "General Posting Setup" = R,
                  tabledata "Interaction Log Entry" = RIMD,
                  tabledata "Interaction Template" = R,
                  tabledata "Interaction Tmpl. Language" = R,
                  tabledata "Inventory Posting Group" = R,
                  tabledata "Inventory Posting Setup" = R,
                  tabledata Item = R,
                  tabledata "Item Application Entry" = Ri,
                  tabledata "Item Category" = RIMD,
                  tabledata "Item Journal Line" = R,
                  tabledata "Item Ledger Entry" = Rm,
                  tabledata "Item Substitution" = r,
                  tabledata "Item Tracking Code" = R,
                  tabledata "Item Tracking Comment" = RIMD,
                  tabledata "Item Translation" = R,
                  tabledata "Item Unit of Measure" = RI,
                  tabledata "Item Variant" = R,
                  tabledata Job = R,
                  tabledata "Job Ledger Entry" = Rm,
                  tabledata "Job Planning Line - Calendar" = R,
                  tabledata "Job Planning Line" = R,
                  tabledata "Job Posting Buffer" = RIMD,
                  tabledata Loaner = Rm,
                  tabledata "Loaner Entry" = RIMD,
                  tabledata Location = R,
                  tabledata "Lot No. Information" = RIMD,
                  tabledata "Package No. Information" = RIMD,
                  tabledata "Payment Method" = R,
                  tabledata "Payment Terms" = R,
                  tabledata "Planning Assignment" = RIMD,
                  tabledata "Post Code" = Ri,
                  tabledata "Price Asset" = R,
                  tabledata "Price Calculation Buffer" = R,
                  tabledata "Price Calculation Setup" = R,
                  tabledata "Price Line Filters" = R,
                  tabledata "Price List Header" = R,
                  tabledata "Price List Line" = R,
                  tabledata "Price Source" = R,
                  tabledata "Price Worksheet Line" = R,
                  tabledata "Purchase Line" = R,
                  tabledata "Reason Code" = R,
                  tabledata "Repair Status" = RIMD,
                  tabledata "Report Selections" = R,
                  tabledata "Reservation Entry" = Rimd,
                  tabledata "Resolution Code" = R,
                  tabledata Resource = R,
                  tabledata "Resource Cost" = R,
                  tabledata "Resource Price" = R,
                  tabledata "Resource Skill" = R,
                  tabledata "Resource Unit of Measure" = R,
                  tabledata "Responsibility Center" = R,
                  tabledata "Return Receipt Header" = R,
                  tabledata "Sales Discount Access" = R,
                  tabledata "Sales Line" = R,
                  tabledata "Sales Line Discount" = R,
                  tabledata "Sales Price" = R,
                  tabledata "Sales Price Access" = R,
                  tabledata "Salesperson/Purchaser" = R,
                  tabledata "Segment Header" = R,
                  tabledata "Serial No. Information" = RIMD,
                  tabledata "Serv. Price Adjustment Detail" = R,
                  tabledata "Serv. Price Group Setup" = R,
                  tabledata "Service Comment Line" = RIMD,
                  tabledata "Service Contract Header" = Rm,
                  tabledata "Service Contract Line" = R,
                  tabledata "Service Cost" = R,
                  tabledata "Service Document Log" = RIMD,
                  tabledata "Service Email Queue" = RIMD,
                  tabledata "Service Header" = RIMD,
                  tabledata "Service Header Archive" = RIMD,
                  tabledata "Service Hour" = R,
                  tabledata "Service Invoice Header" = R,
                  tabledata "Service Invoice Line" = R,
                  tabledata "Service Item" = RIM,
                  tabledata "Service Item Component" = RIMD,
                  tabledata "Service Item Group" = R,
                  tabledata "Service Item Line" = RIMD,
                  tabledata "Service Item Line Archive" = RIMD,
                  tabledata "Service Item Log" = RI,
                  tabledata "Service Ledger Entry" = R,
                  tabledata "Service Line" = RIMD,
                  tabledata "Service Line Archive" = RIMD,
                  tabledata "Service Line Price Adjmt." = RIMD,
                  tabledata "Service Mgt. Setup" = R,
                  tabledata "Service Order Allocation" = RID,
                  tabledata "Service Order Allocat. Archive" = RID,
                  tabledata "Service Order Type" = R,
                  tabledata "Service Price Adjustment Group" = R,
                  tabledata "Service Price Group" = R,
                  tabledata "Service Register" = R,
                  tabledata "Service Shipment Header" = R,
                  tabledata "Service Shipment Item Line" = R,
                  tabledata "Service Shipment Line" = R,
                  tabledata "Service Zone" = R,
                  tabledata "Ship-to Address" = R,
                  tabledata "Source Code" = R,
                  tabledata "Source Code Setup" = R,
                  tabledata "Stockkeeping Unit" = R,
                  tabledata "Substitution Condition" = R,
                  tabledata "Symptom Code" = R,
                  tabledata "Tax Area" = R,
                  tabledata "Tax Area Line" = R,
                  tabledata "Tax Detail" = R,
                  tabledata "Tax Group" = R,
                  tabledata "Tax Jurisdiction" = R,
                  tabledata "Tracking Specification" = Rimd,
                  tabledata "Transfer Line" = R,
                  tabledata "Troubleshooting Header" = R,
                  tabledata "Troubleshooting Line" = R,
                  tabledata "Troubleshooting Setup" = R,
                  tabledata "Unit of Measure" = R,
                  tabledata "Unit of Measure Translation" = R,
                  tabledata "User Setup" = r,
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
                  tabledata "VAT Setup" = R,
                  tabledata "VAT Posting Parameters" = R,
                  tabledata "Warranty Ledger Entry" = R,
                  tabledata "Work Type" = R;
}
