namespace System.Security.AccessControl;

using System.Apps;
using Microsoft.CRM.Campaign;
using System.Environment;
using Microsoft.Foundation.Company;
using Microsoft.CRM.Contact;
using Microsoft.CRM.BusinessRelation;
using Microsoft.Integration.Dataverse;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Customer;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Sales.FinanceCharge;
using Microsoft.Sales.History;
using Microsoft.Sales.Pricing;
using Microsoft.Sales.Document;
using System.Security.User;

permissionset 2911 "D365 ACCOUNTANTS"
{
    Access = Public;
    Assignable = true;
    Caption = 'Dynamics 365 for Accountants';

    IncludedPermissionSets = "LOGIN",
                             "Metadata - Read",
                             "User Personalization - Edit",
                             "Webhook - Edit";

    Permissions = tabledata "NAV App Tenant Add-In" = R,
                  tabledata "Campaign Target Group" = R,
                  tabledata Company = R,
                  tabledata "Company Information" = RM,
                  tabledata Contact = RIMD,
                  tabledata "Contact Business Relation" = RIMD,
                  tabledata "CRM Integration Record" = R,
                  tabledata "Cust. Ledger Entry" = R,
                  tabledata Customer = RIMD,
                  tabledata "Customer Bank Account" = RD,
                  tabledata "Customer Templ." = RIMD,
                  tabledata "Item Reference" = RD,
                  tabledata "Reminder/Fin. Charge Entry" = Rm,
                  tabledata "Sales Cr.Memo Header" = R,
                  tabledata "Sales Discount Access" = Rimd,
                  tabledata "Sales Invoice Header" = R,
                  tabledata "Sales Line Discount" = Rimd,
                  tabledata "Sales Prepayment %" = D,
                  tabledata "Sales Shipment Header" = R,
                  tabledata "Standard Customer Sales Code" = RD,
                  tabledata "User Setup" = RIM;
}
