namespace System.Security.AccessControl;

using Microsoft.CRM.Interaction;
using Microsoft.CRM.BusinessRelation;
using Microsoft.CRM.Contact;
using Microsoft.CRM.Profiling;
using Microsoft.Foundation.Address;
using Microsoft.CRM.Setup;
using Microsoft.Purchases.Archive;
using Microsoft.CRM.Comment;
using Microsoft.Sales.Archive;
using Microsoft.CRM.Task;
using Microsoft.CRM.Team;

permissionset 4462 "Contact - View"
{
    Access = Public;
    Assignable = false;
    Caption = 'Read contacts, entries, etc.';

    Permissions = tabledata Attachment = RI,
                  tabledata "Business Relation" = R,
                  tabledata Contact = R,
                  tabledata "Contact Alt. Addr. Date Range" = R,
                  tabledata "Contact Alt. Address" = R,
                  tabledata "Contact Business Relation" = R,
                  tabledata "Contact Industry Group" = R,
                  tabledata "Contact Job Responsibility" = R,
                  tabledata "Contact Mailing Group" = R,
                  tabledata "Contact Profile Answer" = R,
                  tabledata "Contact Web Source" = R,
                  tabledata "Country/Region" = R,
                  tabledata "Industry Group" = R,
                  tabledata "Inter. Log Entry Comment Line" = RIMD,
                  tabledata "Interaction Group" = R,
                  tabledata "Interaction Log Entry" = RIM,
                  tabledata "Interaction Template" = R,
                  tabledata "Interaction Tmpl. Language" = R,
                  tabledata "Job Responsibility" = R,
                  tabledata "Mailing Group" = R,
                  tabledata "Organizational Level" = R,
                  tabledata "Profile Questionnaire Header" = R,
                  tabledata "Profile Questionnaire Line" = R,
                  tabledata "Purchase Header Archive" = R,
                  tabledata "Purchase Line Archive" = R,
                  tabledata Rating = R,
                  tabledata "Rlshp. Mgt. Comment Line" = R,
                  tabledata "Sales Header Archive" = R,
                  tabledata "Sales Line Archive" = R,
                  tabledata "Salesperson/Purchaser" = R,
                  tabledata Salutation = R,
                  tabledata "Salutation Formula" = R,
                  tabledata "To-do Interaction Language" = R,
                  tabledata "Web Source" = R;
}
