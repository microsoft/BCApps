namespace System.Security.AccessControl;

using System.Security.User;

pageextension 9866 "Sec. Group Members Drilldown" extends "Security Group Members Part"
{
    layout
    {
        modify("User Name")
        {
            DrillDownPageId = "User Card";
        }
    }
}