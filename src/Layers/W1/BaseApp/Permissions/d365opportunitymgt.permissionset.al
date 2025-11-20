namespace System.Security.AccessControl;

using Microsoft.CRM.Task;
using System.Automation;
using Microsoft.CRM.Interaction;
using Microsoft.CRM.Campaign;
using Microsoft.CRM.Opportunity;
using Microsoft.CRM.Contact;
using Microsoft.CRM.Duplicates;
using Microsoft.CRM.BusinessRelation;
using Microsoft.CRM.Profiling;
using Microsoft.Finance.Currency;
using Microsoft.Sales.Customer;
using Microsoft.CRM.Outlook;
using Microsoft.CRM.Setup;
using System.Threading;
using System.Environment.Configuration;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Archive;
using Microsoft.Sales.History;
using Microsoft.CRM.Comment;
using Microsoft.CRM.Analysis;
using Microsoft.Sales.Archive;
using Microsoft.CRM.Segment;
using Microsoft.Projects.TimeSheet;
using Microsoft.Foundation.Task;
using Microsoft.Finance.VAT.Registration;

permissionset 3100 "D365 OPPORTUNITY MGT"
{
    Assignable = true;

    Caption = 'Dynamics 365 Opportunity Mgt.';
    Permissions = tabledata Activity = R,
                  tabledata "Activity Step" = R,
                  tabledata "Approval Workflow Wizard" = RIMD,
                  tabledata Attachment = RI,
                  tabledata Attendee = r,
                  tabledata "Campaign Entry" = RD,
                  tabledata "Campaign Target Group" = RIMD,
                  tabledata "Close Opportunity Code" = R,
                  tabledata "Communication Method" = RIMD,
                  tabledata "Cont. Duplicate Search String" = RIMD,
                  tabledata Contact = RIMD,
                  tabledata "Contact Business Relation" = RIMD,
                  tabledata "Contact Duplicate" = RIMD,
                  tabledata "Contact Industry Group" = RIMD,
                  tabledata "Contact Job Responsibility" = RIMD,
                  tabledata "Contact Mailing Group" = RIMD,
                  tabledata "Contact Profile Answer" = RIMD,
                  tabledata "Contact Value" = RIMD,
                  tabledata "Contact Web Source" = RIMD,
                  tabledata Currency = Rm,
                  tabledata Customer = RM,
                  tabledata "Delivery Sorter" = RIMD,
                  tabledata "Duplicate Search String Setup" = R,
                  tabledata "Exchange Folder" = RIMD,
                  tabledata "Industry Group" = R,
                  tabledata "Inter. Log Entry Comment Line" = RIMD,
                  tabledata "Interaction Group" = R,
                  tabledata "Interaction Log Entry" = RIMD,
                  tabledata "Interaction Template" = R,
                  tabledata "Interaction Tmpl. Language" = R,
                  tabledata "Job Queue Category" = RIMD,
                  tabledata "Job Responsibility" = R,
                  tabledata "Mailing Group" = R,
                  tabledata "Notification Entry" = RIMD,
                  tabledata Opportunity = RIMD,
                  tabledata "Opportunity Entry" = RIMD,
                  tabledata "Organizational Level" = R,
                  tabledata "Profile Questionnaire Header" = R,
                  tabledata "Profile Questionnaire Line" = R,
                  tabledata "Purch. Inv. Header" = r,
                  tabledata "Purchase Header Archive" = R,
                  tabledata "Purchase Line Archive" = R,
                  tabledata Rating = R,
                  tabledata "Restricted Record" = RIMD,
                  tabledata "Return Receipt Header" = r,
                  tabledata "Rlshp. Mgt. Comment Line" = RIMD,
                  tabledata "RM Matrix Management" = R,
                  tabledata "Sales Cr.Memo Header" = r,
                  tabledata "Sales Cycle" = R,
                  tabledata "Sales Cycle Stage" = R,
                  tabledata "Sales Header Archive" = R,
                  tabledata "Sales Line Archive" = R,
                  tabledata "Sales Shipment Header" = rm,
                  tabledata Salutation = R,
                  tabledata "Salutation Formula" = R,
                  tabledata "Segment History" = rm,
                  tabledata "Segment Line" = RM,
                  tabledata "Time Sheet Chart Setup" = RIMD,
                  tabledata "Time Sheet Comment Line" = RIMD,
                  tabledata "Time Sheet Detail" = RIMD,
                  tabledata "Time Sheet Header" = RIMD,
                  tabledata "Time Sheet Line" = RIMD,
                  tabledata "Time Sheet Posting Entry" = RIMD,
                  tabledata "To-do" = RIM,
                  tabledata "To-do Interaction Language" = RIMD,
                  tabledata "User Task Group" = RIMD,
                  tabledata "User Task Group Member" = RIMD,
                  tabledata "VAT Registration No. Format" = R,
                  tabledata "Web Source" = R,
                  tabledata "Workflow - Table Relation" = RIMD,
                  tabledata Workflow = RIMD,
                  tabledata "Workflow Event" = RIMD,
                  tabledata "Workflow Event Queue" = RIMD,
                  tabledata "Workflow Response" = RIMD,
                  tabledata "Workflow Rule" = RIMD,
                  tabledata "Workflow Step" = RIMD,
                  tabledata "Workflow Step Argument" = RIMD,
                  tabledata "Workflow Step Instance" = RIMD,
                  tabledata "Workflow Table Relation Value" = RIMD,
                  tabledata "Workflow User Group" = RIMD,
                  tabledata "Workflow User Group Member" = RIMD;
}
