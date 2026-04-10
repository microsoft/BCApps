namespace System.Security.User;

pageextension 775 "BaseApp User Details" extends "User Details"
{
    layout
    {
        modify("User Name")
        {
            DrillDownPageId = "User Card";
        }
    }
}