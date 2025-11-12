namespace System.Security.User;

using System.Environment.Configuration;

pageextension 9206 "User Personalization" extends "User Personalization"
{
    actions
    {
        addfirst(navigation)
        {
            action(PersonalizedPages)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Personalized Pages';
                Image = Link;
                ToolTip = 'View the list of pages that the user has personalized.';

                trigger OnAction()
                var
                    PersonalizedPages: page "Personalized Pages";
                begin
                    PersonalizedPages.SetUserID(Rec."User SID");
                    PersonalizedPages.RunModal();
                end;
            }
            action(CustomizedPages)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Customized Pages';
                Image = Link;
                ToolTip = 'View the list of pages that have been customized for the user role.';
                trigger OnAction()
                var
                    AllProfilePageMetadata: Record "All Profile Page Metadata";
                begin
                    AllProfilePageMetadata.SetFilter("Profile ID", Rec."Profile ID");
                    Page.RunModal(Page::"Profile Customization List", AllProfilePageMetadata);
                end;
            }
        }

        addfirst(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("C&lear Personalized Pages")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'C&lear Personalized Pages';
                    Image = Cancel;
                    ToolTip = 'Delete all personalizations made by the specified user across display targets.';

                    trigger OnAction()
                    begin
                        ConfPersonalizationMgt.ClearPersonalizedPagesForUser(Rec."User SID");
                    end;
                }
            }
        }
        addlast(Category_Process)
        {
            actionref("C&lear Personalized Pages_Promoted"; "C&lear Personalized Pages")
            {
            }
        }
    }

    var
        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
}