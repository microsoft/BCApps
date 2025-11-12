namespace System.Security.User;

using System.Security.AccessControl;
using System.EMail;

pageextension 9808 "User Card Customization" extends "User Card"
{
    actions
    {
        addafter(Authentication)
        {
            group(Action39)
            {
                Caption = 'Permissions';
                action("Effective Permissions")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Effective Permissions';
                    Image = Permission;
                    ToolTip = 'View this user''s actual permissions for all objects per assigned permission set, and edit the user''s permissions in permission sets of type User-Defined.';

                    trigger OnAction()
                    var
                        EffectivePermissionsMgt: Codeunit "Effective Permissions Mgt.";
                    begin
                        EffectivePermissionsMgt.OpenPageForUser(Rec."User Security ID");
                    end;
                }
            }
            action(Email)
            {
                ApplicationArea = All;
                Caption = 'Send Email';
                Image = Email;
                ToolTip = 'Send an email to this user.';

                trigger OnAction()
                var
                    TempEmailItem: Record "Email Item" temporary;
                    EmailScenario: Enum "Email Scenario";
                begin
                    TempEmailItem.AddSourceDocument(Database::User, Rec.SystemId);
                    TempEmailItem."Send to" := Rec."Contact Email";
                    TempEmailItem.Send(false, EmailScenario::Default);
                end;
            }
        }

        addfirst(Category_Process)
        {
            actionref("Effective Permissions_Promoted"; "Effective Permissions")
            {
            }
        }
        addafter(ChangePassword_Promoted)
        {
            actionref(Email_Promoted; Email)
            {
            }
        }
    }
}
