namespace System.IO;

using System.Environment.Configuration;
using System.Reflection;
using System.Security.User;

page 8638 "Configuration Completion"
{
    Caption = 'Configuration Completion';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = Card;
    ShowFilter = false;
    SourceTable = "Config. Setup";

    layout
    {
        area(content)
        {
            group("Complete Setup")
            {
                Caption = 'Complete Setup';
                group(Control6)
                {
                    ShowCaption = false;
                    label(BeforeSetupCloseMessage)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'If you have finished setting up the company, select the profile that you want to use as your default, and then choose the OK button to close the page. Then restart the Business Central client to apply the changes.';
                        ToolTip = 'Specifies how to finish setting up your company.';
                    }
                    field("Your Profile Code"; YourProfileCode)
                    {
                        ApplicationArea = Basic, Suite;
                        DrillDown = false;
                        Editable = false;
                        ToolTip = 'Specifies the profile code for your configuration solution and package.';

                        trigger OnAssistEdit()
                        var
                            AllProfileTable: Record "All Profile";
                            Roles: Page Roles;
                        begin
                            Roles.Initialize();
                            Roles.LookupMode(true);
                            if Roles.RunModal() = Action::LookupOK then begin
                                Roles.GetRecord(AllProfileTable);
                                YourProfileCode := AllProfileTable."Profile ID";
                                Rec."Your Profile Code" := AllProfileTable."Profile ID";
                                Rec."Your Profile App ID" := AllProfileTable."App ID";
                                Rec."Your Profile Scope" := AllProfileTable.Scope;
                            end;
                        end;
                    }
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group(Setup)
            {
                Caption = 'Setup';
            }
            action(Users)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Users';
                Image = User;
                RunObject = Page Users;
                ToolTip = 'View or edit users that will be configured in the database.';
            }
            action("Users Personalization")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Users Settings';
                Image = UserSetup;
                RunObject = Page "User Settings List";
                ToolTip = 'View or edit UI changes that will be configured in the database.';
            }
        }
        area(Promoted)
        {
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
            group(Category_Category4)
            {
                Caption = 'Setup', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(Users_Promoted; Users)
                {
                }
                actionref("Users Personalization_Promoted"; "Users Personalization")
                {
                }
            }
        }
    }

    trigger OnClosePage()
    begin
        Rec.SelectDefaultRoleCenter(Rec."Your Profile Code", Rec."Your Profile App ID", Rec."Your Profile Scope");
    end;

    trigger OnInit()
    begin
        YourProfileCode := Rec."Your Profile Code";
    end;

    var
        YourProfileCode: Code[30];
}

