namespace System.Security.AccessControl;

using Microsoft.CRM.Task;
using Microsoft.CRM.Interaction;
using Microsoft.CRM.Comment;
using Microsoft.CRM.Analysis;
using Microsoft.CRM.Team;

permissionset 4522 "Todo - Edit"
{
    Access = Public;
    Assignable = false;
    Caption = 'Edit to-dos';

    Permissions = tabledata Activity = R,
                  tabledata "Activity Step" = R,
                  tabledata Attendee = RIMD,
                  tabledata "Interaction Template Setup" = R,
                  tabledata "Rlshp. Mgt. Comment Line" = RIMD,
                  tabledata "RM Matrix Management" = R,
                  tabledata "Salesperson/Purchaser" = R,
                  tabledata Team = R,
                  tabledata "Team Salesperson" = R,
                  tabledata "To-do" = RIM,
                  tabledata "To-do Interaction Language" = RIMD;
}
