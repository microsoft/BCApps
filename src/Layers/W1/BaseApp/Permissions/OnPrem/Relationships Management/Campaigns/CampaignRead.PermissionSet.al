namespace System.Security.AccessControl;

using Microsoft.CRM.Campaign;
using Microsoft.CRM.Segment;
using Microsoft.CRM.Comment;
using Microsoft.CRM.Task;

permissionset 9598 "Campaign - Read"
{
    Access = Public;
    Assignable = false;
    Caption = 'Read campaigns and segments';
    Permissions = tabledata Campaign = R,
                  tabledata "Campaign Entry" = R,
                  tabledata "Campaign Status" = R,
                  tabledata "Campaign Target Group" = R,
                  tabledata "Logged Segment" = R,
                  tabledata "Rlshp. Mgt. Comment Line" = R,
                  tabledata "Segment Criteria Line" = R,
                  tabledata "Segment Header" = R,
                  tabledata "Segment Interaction Language" = R,
                  tabledata "Segment Line" = R,
                  tabledata "To-do Interaction Language" = R;
}
