// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Check;
using Microsoft.Bank.Ledger;
using Microsoft.CostAccounting.Setup;
using Microsoft.CRM.BusinessRelation;
using Microsoft.CRM.Contact;
using Microsoft.CRM.Outlook;
using Microsoft.CRM.Team;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Reversal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Registration;
using Microsoft.Finance.VAT.Reporting;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Attachment;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Foundation.Period;
using Microsoft.Foundation.UOM;
using Microsoft.HumanResources.Employee;
using Microsoft.HumanResources.Payables;
using Microsoft.HumanResources.Setup;
using Microsoft.Integration.Entity;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Setup;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Journal;
using Microsoft.Projects.Project.Ledger;
using Microsoft.Projects.Project.Planning;
using Microsoft.Projects.Project.WIP;
using Microsoft.Projects.Resources.Ledger;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Archive;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Setup;
using Microsoft.Utilities;
using System.Agents;
using System.Apps;
using System.Automation;
using System.Environment;
using System.Environment.Configuration;
using System.Security.AccessControl;
using System.Security.User;

/// <summary>
/// Table data permissions for external dependencies required by Expense Agent.
/// </summary>
permissionset 6955 "Expense Agent - Data Depen."
{
    Access = Internal;
    Assignable = false;
    Caption = 'Expense Agent - Data Dependencies';

    Permissions =
                  tabledata "Payment Terms" = R,
                  tabledata "Currency" = R,
                  tabledata "Country/Region" = R,
                  tabledata "Salesperson/Purchaser" = R,
                  tabledata "G/L Account" = R,
                  tabledata "G/L Entry" = Ri,
                  tabledata "Customer" = R,
                  tabledata "Cust. Ledger Entry" = R,
                  tabledata "Vendor" = R,
                  tabledata "Vendor Ledger Entry" = R,
                  tabledata "Sales Header" = Rim,
                  tabledata "Sales Line" = Rim,
                  tabledata "Purchase Header" = R,
                  tabledata "G/L Register" = ri,
                  tabledata "Accounting Period" = r,
                  tabledata "Company Information" = R,
                  tabledata "Gen. Journal Line" = R,
                  tabledata "User Setup" = R,
                  tabledata "Customer Posting Group" = R,
                  tabledata "General Ledger Setup" = R,
                  tabledata "Purch. Inv. Header" = R,
                  tabledata "Purch. Inv. Line" = R,
                  tabledata "Resource" = R,
                  tabledata "Job" = R,
                  tabledata "Job Ledger Entry" = Ri,
                  tabledata "Standard Customer Sales Code" = R,
                  tabledata "Reversal Entry" = m,
                  tabledata "Posted Gen. Journal Line" = Rm,
                  tabledata "VAT Setup" = R,
                  tabledata "Res. Ledger Entry" = R,
                  tabledata "Alt. Cust. VAT Reg." = R,
                  tabledata "Gen. Jnl. Allocation" = r,
                  tabledata "Post Code" = R,
                  tabledata "Source Code Setup" = R,
                  tabledata "VAT Entry" = R,
                  tabledata "Bank Account" = r,
                  tabledata "Bank Account Ledger Entry" = Ri,
                  tabledata "Check Ledger Entry" = R,
                  tabledata "Payment Method" = R,
                  tabledata "No. Series" = R,
                  tabledata "No. Series Line" = rm,
                  tabledata "Sales & Receivables Setup" = R,
                  tabledata "Inventory Setup" = R,
                  tabledata "Tax Area" = R,
                  tabledata "Tax Area Line" = R,
                  tabledata "Tax Jurisdiction" = R,
                  tabledata "Tax Detail" = R,
                  tabledata "VAT Posting Setup" = R,
                  tabledata "Currency Exchange Rate" = R,
                  tabledata "Unit of Measure" = R,
                  tabledata Dimension = R,
                  tabledata "Dimension Value" = R,
                  tabledata "Default Dimension" = R,
                  tabledata "Detailed Cust. Ledg. Entry" = R,
                  tabledata "Detailed Vendor Ledg. Entry" = R,
                  tabledata "VAT Registration No. Format" = R,
                  tabledata "Approval Entry" = r,
                  tabledata "Dimension Set Entry" = Ri,
                  tabledata "Dimension Set Tree Node" = rim,
                  tabledata "G/L Account Source Currency" = RIM,
                  tabledata "VAT Return Period" = R,
                  tabledata "Job Task" = R,
                  tabledata "Job Planning Line" = Rimd,
                  tabledata "Job WIP Entry" = R,
                  tabledata "Job WIP G/L Entry" = R,
                  tabledata "Job Entry No." = Rim,
                  tabledata "Cost Accounting Setup" = R,
                  tabledata "Document Attachment" = RIMD,
                  tabledata "My Notifications" = r,
                  tabledata "Office Add-in Setup" = R,
                  tabledata "Cancelled Document" = R,
                  tabledata "Feature Data Update Status" = r,
                  tabledata Contact = R,
                  tabledata "Contact Business Relation" = R,
                  tabledata "Sales Header Archive" = r,
                  tabledata Employee = R,
                  tabledata "Human Resources Setup" = R,
                  tabledata "Employee Posting Group" = R,
                  tabledata "Employee Ledger Entry" = Rimd,
                  tabledata "Detailed Employee Ledger Entry" = Rimd,
                  tabledata "Payable Employee Ledger Entry" = m,
                  tabledata "Employee Payment Buffer" = m,
                  tabledata "Sales Invoice Entity Aggregate" = rimd,
                  tabledata "Value Entry" = R,
                  tabledata "Post Value Entry to G/L" = I,
                  tabledata Agent = r,
                  tabledata "Application User Settings" = r,
                  tabledata Company = R,
                  tabledata "Record Link" = R,
                  tabledata "User Personalization" = R,
                  tabledata "Page Data Personalization" = RI,
                  tabledata User = R,
                  tabledata "Tenant Profile" = R,
                  tabledata "Tenant Media" = RI,
                  tabledata "Tenant Profile Page Metadata" = R,
                  tabledata "User Page Metadata" = RI,
                  tabledata "Page Documentation" = R,
                  tabledata "Application Object Metadata" = R,
                  tabledata "Page Usage State" = RI;
}
