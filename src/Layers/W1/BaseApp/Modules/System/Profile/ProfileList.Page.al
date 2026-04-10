namespace System.Environment.Configuration;

using System.Agents;
using System.Environment;
using System.Reflection;
using System.Security.User;

page 9171 "Profile List"
{
    AdditionalSearchTerms = 'users,roles,role centers,personalization,customization';
    ApplicationArea = Basic, Suite;
    Caption = 'Profiles (Roles)';
    CardPageID = "Profile Card";
    Editable = false;
    PageType = List;
    AboutTitle = 'About Profiles (Roles)';
    AboutText = 'Create and manage user profiles that define business roles, control user access, and customize page layouts to ensure users have a tailored and efficient experience in Business Central.';
    RefreshOnActivate = true;
    SourceTable = "All Profile";
    UsageCategory = Lists;
    DeleteAllowed = false;
    InsertAllowed = false;
    SourceTableView = sorting(Caption);

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(ProfileIdField; Rec."Profile ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Profile ID';
                    ToolTip = 'Specifies an ID that is used to identify the profile (role). There can be more than one profile with the same ID if they come from different extensions. Avoid using spaces in the profile ID to make it easier to create URLs linking to a specific profile.';
                }
                field(CaptionField; Rec.Caption)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Display Name';
                    ToolTip = 'Specifies the name of the organizational role as displayed in the user interface.';
                }
                field(AppNameField; Rec."App Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Source';
                    ToolTip = 'Specifies the origin of this profile, which can be either an extension, shown by its name, or a custom profile created by a user.';
                }
                field(RoleCenterIdField; Rec."Role Center ID")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    Caption = 'Role Center ID';
                    Lookup = false;
                    ToolTip = 'Specifies the ID of the Role Center associated with the profile.';
                }
                field(EnabledField; Rec.Enabled)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Enabled';
                    ToolTip = 'Specifies whether the profile is available in the list of roles that users can select from. Note: Users that are assigned this profile can continue to sign in even when the profile is not enabled.';
                }
                field(DefaultRoleCenterField; Rec."Default Role Center")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Use as default profile';
                    ToolTip = 'Specifies if this profile is used for all users that are not assigned a role. Only one profile can be set as the default.';
                }
                field(PromotedField; Rec.Promoted)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show in Role Explorer';
                    ToolTip = 'Specifies whether the display name and available business features of this profile are shown in the Role Explorer. The profile must also be enabled.';
                }
            }
        }
        area(factboxes)
        {
            systempart(LinksFactbox; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(NotesFactbox; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            action(ShowUserList)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'User List';
                Image = "List";
                ToolTip = 'Open the list of users for the system.';
                RunObject = page "Users";
            }
            action(ShowUserPersonalizationList)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'User Personalization List';
                Image = "List";
                ToolTip = 'Specify the list of user personalizations for users of the system.';
                RunObject = page "User Settings List";
            }
            action(ManageCustomizedPages)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Manage customized pages';
                Image = "List";
                ToolTip = 'View the list of pages that have been customized for the selected profile.';
                RunObject = page "Profile Customization List";
                RunPageLink = "App ID" = field("App ID"), "Profile ID" = field("Profile ID");
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";

                action(SetDefaultRoleCenterAction)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Use as default profile';
                    Image = Default;
                    Scope = "Repeater";
                    ToolTip = 'Set the selected profile as the one that is used for all users that are not assigned a role. Only one profile can be set as the default.​';
                    Enabled = Rec.Enabled;
                    AccessByPermission = tabledata "Tenant Profile Setting" = M;

                    trigger OnAction()
                    begin
                        Rec.TestField("Profile ID");
                        Rec.TestField("Role Center ID");
                        Rec.Validate("Default Role Center", true);
                        Rec.Modify();
                        ConfPersonalizationMgt.ChangeDefaultRoleCenter(Rec);
                    end;
                }
                action(CopyProfileAction)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Copy profile';
                    Ellipsis = true;
                    Image = Copy;
                    Scope = "Repeater";
                    ToolTip = 'Create a copy of this profile including any page customizations made by users for this profile.';
                    AccessByPermission = tabledata "All Profile" = I;

                    trigger OnAction()
                    var
                        AllProfile: Record "All Profile";
                    begin
                        ConfPersonalizationMgt.CopyProfileWithUserInput(Rec, AllProfile);
                        if Rec.Get(AllProfile.Scope, AllProfile."App ID", AllProfile."Profile ID") then;
                    end;
                }
                action(CustomizeRoleAction)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Customize pages';
                    Image = SetupColumns;
                    Scope = "Repeater";
                    Visible = IsWebClient;
                    ToolTip = 'Change the user interface for this profile to fit the unique needs of the role (opens in a new tab). The changes that you make only apply to users that are assigned this profile.';
                    AccessByPermission = tabledata "All Profile" = M;

                    trigger OnAction()
                    begin
                        ConfPersonalizationMgt.OpenProfileCustomizationUrl(Rec);
                    end;
                }
                action(ExportProfiles)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Export Profiles';
                    Image = Export;
                    Scope = Page;
                    Visible = IsWebClient;
                    ToolTip = 'Export to a profile package all changes done by users to this list. This may include new profiles, modified profiles and page customizations.';

                    trigger OnAction()
                    begin
                        ConfPersonalizationMgt.DownloadProfileConfigurationPackage();
                    end;
                }
                action(ImportProfiles)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Import Profiles';
                    Image = Import;
                    Scope = Page;
                    AccessByPermission = TableData "Profile Designer Diagnostic" = I;
                    Visible = IsWebClient;
                    ToolTip = 'Import a profile package that adds or replaces profiles in this list. This may include new profiles, modified profiles and page customizations.';
                    RunPageMode = Edit;
                    RunObject = page "Profile Import Wizard";
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(SetDefaultRoleCenterAction_Promoted; SetDefaultRoleCenterAction)
                {
                }
                actionref(CopyProfileAction_Promoted; CopyProfileAction)
                {
                }
                actionref(CustomizeRoleAction_Promoted; CustomizeRoleAction)
                {
                }
                actionref(ExportProfiles_Promoted; ExportProfiles)
                {
                }
                actionref(ImportProfiles_Promoted; ImportProfiles)
                {
                }
            }
        }
    }

    views
    {
        view(OnlyEnabled)
        {
            Caption = 'Enabled';
            Filters = where(Enabled = const(true));
        }
        view(OnlyPromotedAndEnabled)
        {
            Caption = 'Shown in Role Explorer';
            Filters = where(Enabled = const(true), Promoted = const(true));
        }
    }

    trigger OnInit()
    begin
        IsWebClient := ClientTypeManagement.GetCurrentClientType() = ClientType::Web;
    end;

    trigger OnOpenPage()
    var
        AgentUtilities: Codeunit "Agent Utilities";
    begin
        AgentUtilities.BlockPageFromBeingOpenedByAgent();
    end;

    var
        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
        ClientTypeManagement: Codeunit "Client Type Management";
        IsWebClient: Boolean;
}
