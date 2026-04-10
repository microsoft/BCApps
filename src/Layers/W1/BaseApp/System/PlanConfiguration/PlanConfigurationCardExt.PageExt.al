namespace System.Azure.Identity;

using System.Security.User;

pageextension 9208 "Plan Configuration Card Ext." extends "Plan Configuration Card"
{
    actions
    {
        addfirst(Promoted)
        {
            actionref(Users_Promoted; Users)
            {
            }
        }

        addfirst(Navigation)
        {
            action(Users)
            {
                ApplicationArea = All;
                Caption = 'Users';
                ToolTip = 'Manage permissions for users that are already tracked in Business Central, and update user information from Microsoft 365.', Comment = 'Do not translate ''Business Central'' and ''Microsoft 365''';
                Image = Users;
                RunObject = Page "Users";
            }
        }
    }
}