namespace System.Security.AccessControl;

using Microsoft.CRM.Task;
using Microsoft.CRM.Opportunity;
using Microsoft.CRM.Contact;
using Microsoft.CRM.Interaction;
using Microsoft.CRM.Comment;
using Microsoft.CRM.Analysis;
using Microsoft.CRM.Team;

permissionset 950 "Opportunity - Edit"
{
    Access = Public;
    Assignable = false;
    Caption = 'Edit opportunities';

    Permissions = tabledata Activity = R,
                  tabledata "Activity Step" = R,
                  tabledata "Close Opportunity Code" = R,
                  tabledata Contact = R,
                  tabledata "Interaction Template Setup" = R,
                  tabledata Opportunity = RIM,
                  tabledata "Opportunity Entry" = RIM,
                  tabledata "Rlshp. Mgt. Comment Line" = RIMD,
                  tabledata "RM Matrix Management" = R,
                  tabledata "Sales Cycle" = R,
                  tabledata "Sales Cycle Stage" = R,
                  tabledata "Salesperson/Purchaser" = R,
                  tabledata "To-do" = RIM,
                  tabledata "To-do Interaction Language" = RIMD;
}
