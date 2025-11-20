namespace System.Security.AccessControl;

using Microsoft.CRM.Task;
using Microsoft.CRM.BusinessRelation;
using Microsoft.CRM.Contact;
using Microsoft.CRM.Duplicates;
using Microsoft.CRM.Profiling;
using Microsoft.Foundation.Address;
using Microsoft.Finance.Currency;
using Microsoft.Sales.Customer;
using Microsoft.CRM.Interaction;
using Microsoft.CRM.Setup;
using Microsoft.CRM.Opportunity;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Archive;
using Microsoft.Sales.History;
using Microsoft.CRM.Comment;
using Microsoft.Sales.Document;
using Microsoft.Sales.Archive;
using Microsoft.CRM.Segment;
using Microsoft.Purchases.Vendor;
using Microsoft.CRM.Team;
using Microsoft.Inventory.Intrastat;
using Microsoft.Finance.VAT.Registration;

permissionset 257 "Contact - Edit"
{
    Access = Public;
    Assignable = false;
    Caption = 'Edit contacts';

    Permissions = tabledata Attendee = r,
                  tabledata "Business Relation" = R,
                  tabledata "Communication Method" = RIMD,
                  tabledata "Cont. Duplicate Search String" = RIMD,
                  tabledata Contact = RIMD,
                  tabledata "Contact Alt. Addr. Date Range" = RIMD,
                  tabledata "Contact Alt. Address" = RIMD,
                  tabledata "Contact Business Relation" = RIMD,
                  tabledata "Contact Dupl. Details Buffer" = RIMD,
                  tabledata "Contact Duplicate" = RIMD,
                  tabledata "Contact Industry Group" = RIMD,
                  tabledata "Contact Job Responsibility" = RIMD,
                  tabledata "Contact Mailing Group" = RIMD,
                  tabledata "Contact Profile Answer" = RIMD,
                  tabledata "Contact Web Source" = RIMD,
                  tabledata "Country/Region" = R,
                  tabledata Currency = Rm,
                  tabledata Customer = RM,
                  tabledata "Delivery Sorter" = RIMD,
                  tabledata "Duplicate Search String Setup" = R,
                  tabledata "Industry Group" = R,
                  tabledata "Inter. Log Entry Comment Line" = RIMD,
                  tabledata "Interaction Group" = R,
                  tabledata "Interaction Log Entry" = RIM,
                  tabledata "Interaction Template" = R,
                  tabledata "Interaction Template Setup" = R,
                  tabledata "Interaction Tmpl. Language" = R,
                  tabledata "Job Responsibility" = R,
                  tabledata "Mailing Group" = R,
                  tabledata Opportunity = RM,
                  tabledata "Opportunity Entry" = rm,
                  tabledata "Organizational Level" = R,
                  tabledata "Profile Questionnaire Header" = R,
                  tabledata "Profile Questionnaire Line" = R,
                  tabledata "Purch. Inv. Header" = r,
                  tabledata "Purchase Header" = r,
                  tabledata "Purchase Header Archive" = R,
                  tabledata "Purchase Line Archive" = R,
                  tabledata Rating = R,
                  tabledata "Return Receipt Header" = r,
                  tabledata "Rlshp. Mgt. Comment Line" = RIMD,
                  tabledata "Sales Cr.Memo Header" = r,
                  tabledata "Sales Header" = Rm,
                  tabledata "Sales Header Archive" = R,
                  tabledata "Sales Invoice Header" = rm,
                  tabledata "Sales Line Archive" = R,
                  tabledata "Sales Shipment Header" = rm,
                  tabledata "Salesperson/Purchaser" = R,
                  tabledata Salutation = R,
                  tabledata "Salutation Formula" = R,
                  tabledata "Segment History" = rm,
                  tabledata "Segment Line" = RM,
                  tabledata Territory = R,
                  tabledata "To-do" = RM,
                  tabledata "To-do Interaction Language" = RIMD,
                  tabledata "VAT Registration No. Format" = R,
                  tabledata Vendor = R,
                  tabledata "Web Source" = R;
}
