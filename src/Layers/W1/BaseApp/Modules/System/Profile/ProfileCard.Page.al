namespace System.Environment.Configuration;

using System.Agents;
using System.Environment;
using System.Reflection;

page 9170 "Profile Card"
{
    Caption = 'Profile (Role)';
    DataCaptionExpression = Rec.Caption;
    PageType = Card;
    SourceTable = "All Profile";
    DelayedInsert = true;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                Editable = IsProfileEditable;

                field(ScopeField; Rec.Scope)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Scope';
                    Enabled = false;
                    Visible = false;
                    ToolTip = 'Specifies if the profile is specific to your tenant or generally available in the system.';
                }
                field(ProfileIdField; Rec."Profile ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Profile ID';
                    Editable = IsUserCreatedProfile;
                    ToolTip = 'Specifies an ID that is used to identify the profile (role). There can be more than one profile with the same ID if they come from different extensions. Avoid using spaces in the profile ID to make it easier to create URLs linking to a specific profile.';
                    NotBlank = true;

                    trigger OnValidate()
                    var
                        AllProfile: Record "All Profile";
                    begin
                        AllProfile.SetRange("Profile ID", Rec."Profile ID");

                        // Platform inserts the record before validation, hence this filter is needed to enable the desired behaviour
                        AllProfile.SetFilter("App ID", '<>%1', Rec."App ID");

                        if not AllProfile.IsEmpty() then
                            Error(ProfileIdAlreadyExistErr, Rec."Profile ID");

                        if xRec."Profile ID" <> '' then
                            if not Confirm(RenamingWillDisruptExistingSessionsQst) then
                                Error('');
                    end;
                }
                field(AppNameField; Rec."App Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Source';
                    Enabled = false;
                    ToolTip = 'Specifies the origin of this profile, which can be either an extension, shown by its name, or a custom profile created by a user.';
                }
                field(CaptionField; Rec.Caption)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Display Name';
                    ToolTip = 'Specifies the name of the organizational role as displayed in the user interface.​';
                    NotBlank = true;
                    ShowMandatory = true;
                }
                field(DescriptionField; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Description';
                    ToolTip = 'Specifies additional information about the profile, such as its purpose. This information may be shown to users.';
                    MultiLine = true;
                }
                field(RoleCenterIdField; Rec."Role Center ID")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    Caption = 'Role Center ID';
                    ToolTip = 'Specifies the home page that users will see when they have signed in. This is the ID of a page object of type Role Center.';
                    NotBlank = true;
                    ShowMandatory = true;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        AllObjWithCaption: Record AllObjWithCaption;
                        AllObjectsWithCaptionPage: Page "All Objects with Caption";
                    begin
                        AllObjWithCaption.FilterGroup(2);
                        AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Page);
                        AllObjWithCaption.SetRange("Object Subtype", RoleCenterSubtypeTxt);
                        AllObjWithCaption.FilterGroup(0);

                        AllObjectsWithCaptionPage.Caption := AvailableRoleCentersPageCaptionLbl;
                        AllObjectsWithCaptionPage.IsObjectTypeVisible(false);
                        AllObjectsWithCaptionPage.SetTableView(AllObjWithCaption);

                        if AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Page, Rec."Role Center ID") then
                            AllObjectsWithCaptionPage.SetRecord(AllObjWithCaption);

                        AllObjectsWithCaptionPage.LookupMode := true;
                        if AllObjectsWithCaptionPage.RunModal() = ACTION::LookupOK then begin
                            AllObjectsWithCaptionPage.GetRecord(AllObjWithCaption);
                            Rec.Validate("Role Center ID", AllObjWithCaption."Object ID");
                        end;
                        ValidateRoleCenterIdExists();
                    end;

                    trigger OnValidate()
                    begin
                        ValidateRoleCenterIdExists();
                    end;
                }
                field(EnabledField; Rec.Enabled)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Enabled';
                    ToolTip = 'Specifies whether the profile is available in the list of roles that users can select from. Note: Users that are assigned this profile can continue to sign in even when the profile is not enabled.';

                    trigger OnValidate()
                    begin
                        if not Rec.Enabled then
                            ConfPersonalizationMgt.ValidateDisableProfile(Rec);
                    end;
                }
                field(PromotedField; Rec.Promoted)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show in Role Explorer';
                    ToolTip = 'Specifies whether the display name and available business features of this profile are shown in the Role Explorer. The profile must also be enabled.';
                }
            }
            group(ProfileSettings)
            {
                Caption = 'Additional Settings';
                Editable = IsProfileEditable;

                field(DefaultRoleCenterField; Rec."Default Role Center")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Use as default profile';
                    ToolTip = 'Specifies if this profile is used for all users that are not assigned a role. Only one profile can be set as the default.';
                    AccessByPermission = tabledata "All Profile" = M;

                    trigger OnValidate()
                    begin
                        Rec.TestField("Profile ID");
                        Rec.TestField("Role Center ID");

                        if not Rec.Enabled then
                            Error(ProfileMustBeEnabledInOrderToSetItAsDefaultErr);
                    end;
                }
                field(DisablePersonalizationField; Rec."Disable Personalization")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Disable personalization';
                    ToolTip = 'Specifies whether personalization is disabled for users of the profile.';
                }
            }
        }
        area(factboxes)
        {
            systempart(LinksFactboxPart; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(NotesFactboxPart; Notes)
            {
                ApplicationArea = Notes;
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(ShowProfileExtensions)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Profile Extensions';
                Image = SetupList;
                ToolTip = 'View a list of profile extensions that extend this profile.';
                RunObject = page "Profile Extension List";
                RunPageLink = "Profile App ID" = field("App ID"), "Profile ID" = field("Profile ID");
            }
            action(ShowProfilePageCustomization)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Manage customized pages';
                Image = SetupList;
                ToolTip = 'View the list of pages have been customized for this profile.';
                RunObject = page "Profile Customization List";
                RunPageLink = "Profile App ID" = field("App ID"), "Profile ID" = field("Profile ID");
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";

                action(CopyProfileAction)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Copy profile';
                    Ellipsis = true;
                    Image = Copy;
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
                    Visible = IsWebClient;
                    Enabled = IsProfileEditable;
                    ToolTip = 'Change the user interface for this profile to fit the unique needs of the role (opens in a new tab). The changes that you make only apply to users that are assigned this profile.';
                    AccessByPermission = tabledata "All Profile" = M;

                    trigger OnAction()
                    begin
                        Hyperlink(ConfPersonalizationMgt.GetProfileConfigurationUrlForWeb(Rec));
                    end;
                }
                action(ClearCustomizedPagesAction)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'C&lear customized pages';
                    Image = Cancel;
                    ToolTip = 'Delete all customizations that are made for the profile.';
                    AccessByPermission = tabledata "All Profile Page Metadata" = D;
                    Enabled = HasCustomizedPages;

                    trigger OnAction()
                    begin
                        ConfPersonalizationMgt.ClearProfileConfiguration(Rec);
                        UpdateHasCustomizedPages();
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(CustomizeRoleAction_Promoted; CustomizeRoleAction)
                {
                }
                actionref(CopyProfileAction_Promoted; CopyProfileAction)
                {
                }
                actionref(ClearCustomizedPagesAction_Promoted; ClearCustomizedPagesAction)
                {
                }
            }
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

    trigger OnAfterGetCurrRecord()
    begin
        UpdateHasCustomizedPages();

        RefreshEditability();

        ShowOrRecallDuplicateProfileIDNotification();
    end;

    local procedure UpdateHasCustomizedPages()
    var
        TenantProfilePageMetadata: Record "Tenant Profile Page Metadata";
    begin
        TenantProfilePageMetadata.SetRange("Profile ID", Rec."Profile ID");
        TenantProfilePageMetadata.SetRange("App ID", Rec."App ID");
        TenantProfilePageMetadata.SetRange(Owner, TenantProfilePageMetadata.Owner::Tenant);
        HasCustomizedPages := not TenantProfilePageMetadata.IsEmpty();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.Scope := Rec.Scope::Tenant;
        Rec."Role Center ID" := ConfPersonalizationMgt.DefaultRoleCenterID();
        Rec.Enabled := true;
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Rec.TestField(Caption);
        Rec.TestField("Role Center ID");
        ValidateRoleCenterIdExists();

        if Rec."Default Role Center" then
            ConfPersonalizationMgt.ChangeDefaultRoleCenter(Rec);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Rec.TestField(Caption);
        Rec.TestField("Role Center ID");

        if Rec."Default Role Center" then
            ConfPersonalizationMgt.ChangeDefaultRoleCenter(Rec);
    end;

    trigger OnDeleteRecord() Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnDeleteRecord(Rec, Result, IsHandled);
        if IsHandled then
            exit(Result);

        ConfPersonalizationMgt.ValidateDeleteProfile(Rec);

        if not ConfPersonalizationMgt.CanDeleteProfile(Rec) then begin
            if not Rec.Enabled then begin
                Message(CannotDeleteProfileAlreadyMarkedAsDisabledMsg, Rec."Profile ID", Rec."App Name");
                Error('');
            end;

            if Confirm(CannotDeleteProfileMarkAsDisabledQst, false, Rec."Profile ID", Rec."App Name") then begin
                Rec.Enabled := false;
                Rec.Modify(true);
                exit(false);
            end;
            Error('');
        end;

        exit(true);
    end;

    local procedure ValidateRoleCenterIdExists()
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        if Rec."Default Role Center" then
            Rec.TestField("Role Center ID");

        AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Page, Rec."Role Center ID");
        AllObjWithCaption.TestField("Object Subtype", RoleCenterSubtypeTxt);
    end;

    local procedure RefreshEditability()
    begin
        IsUserCreatedProfile := IsNullGuid(Rec."App ID");

        IsProfileEditable := not ConfPersonalizationMgt.IsProfileIdAmbiguous(Rec);
    end;

    local procedure ShowOrRecallDuplicateProfileIDNotification()
    var
        DummyAllProfile: Record "All Profile";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        NotificationToShow: Notification;
    begin
        NotificationToShow.Id := DuplicateIDNotificationIDTxt;
        NotificationToShow.Message := ThereAreProfilesWithDuplicateIdMsg;

        if ConfPersonalizationMgt.IsProfileIdAmbiguous(Rec) then
            // This will send a generic notification for the table and not for the record, and hence make the recall logic easier
            NotificationLifecycleMgt.SendNotification(NotificationToShow, DummyAllProfile.RecordId)
        else
            NotificationLifecycleMgt.RecallNotificationsForRecord(DummyAllProfile.RecordId, true);
    end;

    var
        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
        ClientTypeManagement: Codeunit "Client Type Management";
        RoleCenterSubtypeTxt: Label 'RoleCenter', Locked = true;
        DuplicateIDNotificationIDTxt: Label 'ffbf8d52-e612-4e2e-9adc-d15b863d94ff', Locked = true;
        RenamingWillDisruptExistingSessionsQst: Label 'If any user is logged in with this profile, they will need to log in again. Do you want to continue?';
        CannotDeleteProfileMarkAsDisabledQst: Label 'The profile "%1" is provided by the extension %2 . You cannot delete the profile, unless you uninstall the extension. Do you want to mark the profile as Disabled instead?', Comment = '%1 = the ID of the profile the user is trying to delete; %2 = the extension (app) that owns the profile.';
        CannotDeleteProfileAlreadyMarkedAsDisabledMsg: Label 'The profile "%1" is provided by the extension %2 . You cannot delete the profile, unless you uninstall the extension. The profile has already been marked as disabled.', Comment = '%1 = the ID of the profile the user is trying to delete; %2 = the extension (app) that owns the profile.';
        AvailableRoleCentersPageCaptionLbl: Label 'Available Role Centers', Comment = 'When the user triggers LookUp of the Role Center ID field, this will be the caption of the lookup page';
        ProfileIdAlreadyExistErr: Label 'A profile with Profile ID "%1" already exist, please provide another Profile ID.', Comment = '%1 = Profile ID';
        ProfileMustBeEnabledInOrderToSetItAsDefaultErr: Label 'The profile must be enabled in order to set it as the default profile.';
        ThereAreProfilesWithDuplicateIdMsg: Label 'Another profile has the same ID as this one. This can cause ambiguity in the system. Give this or the other profile another ID before you customize them. Contact your Microsoft partner for further assistance.';
        IsUserCreatedProfile: Boolean;
        IsProfileEditable: Boolean;
        IsWebClient: Boolean;
        HasCustomizedPages: Boolean;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnDeleteRecord(var AllProfile: Record "All Profile"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;
}

