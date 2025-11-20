namespace System.Security.AccessControl;

using Microsoft.CRM.Interaction;
using Microsoft.CRM.BusinessRelation;
using Microsoft.CRM.Campaign;
using Microsoft.CRM.Contact;
using Microsoft.CRM.Profiling;
using Microsoft.CRM.Setup;
using Microsoft.CRM.Segment;
using Microsoft.Purchases.Archive;
using Microsoft.CRM.Comment;
using Microsoft.Sales.Archive;
using Microsoft.CRM.Task;
using Microsoft.CRM.Team;

permissionset 3125 "Campaign - Edit"
{
    Access = Public;
    Assignable = false;
    Caption = 'Edit campaigns and segments';

    Permissions = tabledata Attachment = RIMD,
                  tabledata "Business Relation" = R,
                  tabledata Campaign = RIMD,
                  tabledata "Campaign Entry" = RIM,
                  tabledata "Campaign Status" = RIMD,
                  tabledata "Campaign Target Group" = RIMD,
                  tabledata Contact = R,
                  tabledata "Contact Alt. Addr. Date Range" = R,
                  tabledata "Contact Alt. Address" = R,
                  tabledata "Contact Business Relation" = R,
                  tabledata "Contact Industry Group" = R,
                  tabledata "Contact Job Responsibility" = R,
                  tabledata "Contact Mailing Group" = R,
                  tabledata "Contact Profile Answer" = R,
                  tabledata "Delivery Sorter" = RIMD,
                  tabledata "Industry Group" = R,
                  tabledata "Inter. Log Entry Comment Line" = RIMD,
                  tabledata "Interaction Group" = RIMD,
                  tabledata "Interaction Log Entry" = RIM,
                  tabledata "Interaction Template" = RIMD,
                  tabledata "Interaction Template Setup" = R,
                  tabledata "Interaction Tmpl. Language" = RIMD,
                  tabledata "Job Responsibility" = RIM,
                  tabledata "Logged Segment" = RIM,
                  tabledata "Mailing Group" = R,
                  tabledata "Profile Questionnaire Header" = R,
                  tabledata "Profile Questionnaire Line" = R,
                  tabledata "Purchase Header Archive" = R,
                  tabledata "Purchase Line Archive" = R,
                  tabledata Rating = R,
                  tabledata "Rlshp. Mgt. Comment Line" = RIMD,
                  tabledata "Sales Header Archive" = R,
                  tabledata "Sales Line Archive" = R,
                  tabledata "Salesperson/Purchaser" = R,
                  tabledata Salutation = R,
                  tabledata "Salutation Formula" = R,
                  tabledata "Saved Segment Criteria" = R,
                  tabledata "Saved Segment Criteria Line" = R,
                  tabledata "Segment Criteria Line" = RIMD,
                  tabledata "Segment Header" = RIMD,
                  tabledata "Segment History" = RID,
                  tabledata "Segment Interaction Language" = RIMD,
                  tabledata "Segment Line" = RIMD,
                  tabledata "Segment Wizard Filter" = RIMD,
                  tabledata "To-do Interaction Language" = RIMD;
}
