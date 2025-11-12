namespace System.Security.AccessControl;

using Microsoft.CRM.Interaction;
using Microsoft.CRM.Campaign;
using Microsoft.CRM.Duplicates;
using Microsoft.CRM.Contact;
using Microsoft.CRM.Profiling;
using Microsoft.CRM.Outlook;
using Microsoft.CRM.Opportunity;
using Microsoft.CRM.Task;

permissionset 2398 "Relationship Mgt - Edit"
{
    Access = Public;
    Assignable = false;
    Caption = 'RM periodic activities';

    Permissions = tabledata Attachment = RD,
                  tabledata "Campaign Entry" = RD,
                  tabledata "Cont. Duplicate Search String" = RIMD,
                  tabledata Contact = RI,
                  tabledata "Contact Dupl. Details Buffer" = RIMD,
                  tabledata "Contact Duplicate" = RIMD,
                  tabledata "Contact Profile Answer" = RIMD,
                  tabledata "Contact Value" = RIMD,
                  tabledata "Duplicate Search String Setup" = R,
                  tabledata "Exchange Folder" = RIMD,
                  tabledata "Inter. Log Entry Comment Line" = RD,
                  tabledata "Interaction Log Entry" = RD,
                  tabledata "Interaction Template Setup" = R,
                  tabledata Opportunity = RD,
                  tabledata "Opportunity Entry" = RD,
                  tabledata "Profile Questionnaire Header" = R,
                  tabledata "Profile Questionnaire Line" = R,
                  tabledata Rating = R,
                  tabledata "To-do" = RD;
}
