namespace System.Security.AccessControl;

using Microsoft.CRM.Opportunity;
using Microsoft.CRM.Comment;
using Microsoft.CRM.Analysis;
using Microsoft.CRM.Task;
using Microsoft.CRM.Team;

permissionset 4788 "Opportunity - Read"
{
    Access = Public;
    Assignable = false;
    Caption = 'Read opportunities';

    Permissions = tabledata "Close Opportunity Code" = R,
                  tabledata Opportunity = R,
                  tabledata "Opportunity Entry" = R,
                  tabledata "Rlshp. Mgt. Comment Line" = R,
                  tabledata "RM Matrix Management" = R,
                  tabledata "Salesperson/Purchaser" = R,
                  tabledata "To-do Interaction Language" = R;
}
