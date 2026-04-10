namespace System.Azure.Identity;

using System.Security.User;

pageextension 9207 "Plan Configuration List Ext." extends "Plan Configuration List"
{
    actions
    {
        addfirst(Navigate)
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