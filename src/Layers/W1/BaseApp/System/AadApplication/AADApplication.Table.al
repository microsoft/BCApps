namespace System.Environment.Configuration;

using System.Apps;
using System.Security.AccessControl;
using System.Security.User;
using System.Utilities;
using System;

table 9012 "AAD Application"
{
    Caption = 'Microsoft Entra Application';
    DataPerCompany = false;
    ReplicateData = false;
    DataCaptionFields = Description;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Client Id"; Guid)
        {
            Caption = 'Client Id';
        }
        field(2; State; Option)
        {
            Caption = 'State';
            OptionCaption = 'Enabled,Disabled';
            OptionMembers = Enabled,Disabled;
            InitValue = Disabled;
            trigger OnValidate()
            var
                User: Record User;
                UserPermission: codeunit "User Permissions";
                ConfirmManagement: Codeunit "Confirm Management";
                ErrorTxt: Text;
                ConfirmQuestion: Text;
            begin
                if xRec.State = state then
                    exit;
                if not UserExists() and (Rec.State = Rec.State::Enabled) then begin
                    Rec.TestField(Description);
                    ConfirmQuestion := StrSubstNo(UserNameCannotbeChangedQst, Rec.Description);

                    if ("Client Id" in [AADApplicationSetup.GetD365BCForVEAppId(),
                                        AADApplicationSetup.GetPowerPagesAnonymousAppId(),
                                        AADApplicationSetup.GetPowerPagesAuthenticatedAppId()]) then
                        CreateUserFromAADApplication()
                    else
                        if ConfirmManagement.GetResponseOrDefault(ConfirmQuestion, true) then
                            CreateUserFromAADApplication()
                        else
                            error('');
                end;
                User.Get("User Id");
                ErrorTxt := StrSubstNo(NoPermissionToChangeUserErr, SuperPermissionSetTxt, SECURITYPermissionSetTxt);
                if not UserPermission.CanManageUsersOnTenant(UserSecurityId()) then
                    Error(ErrorTxt);
                if State = State::Enabled then
                    User.State := User.State::Enabled
                else
                    User.State := User.State::Disabled;
                User.Modify()
            end;
        }
        field(5; "App ID"; Guid)
        {
            Caption = 'App ID';
            trigger OnLookup()
            var
                PublishedApplication: Record "Published Application";
            begin
                if PAGE.RunModal(PAGE::"Extension Management", PublishedApplication) = ACTION::LookupOK then begin
                    "App ID" := PublishedApplication."Package ID";
                    "App Name" := PublishedApplication.Name;
                    exit
                end;
            end;

            trigger OnValidate()
            begin
                if IsNullGuid("App ID") then
                    "App Name" := '';
            end;

        }
        field(6; "App Name"; Text[250])
        {
            Caption = 'App Name';
            Editable = false;
        }
        field(10; Description; Text[50])
        {
            Caption = 'Description';
        }
        field(11; "Contact Information"; Text[50])
        {
            Caption = 'Contact Information';
        }
        field(12; "Permission Granted"; Boolean)
        {
            Caption = 'Permission Granted';
        }
        field(20; "User ID"; Guid)
        {
            Caption = 'User Id';
        }

    }

    keys
    {
        key(Key1; "Client Id")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    [Scope('OnPrem')]
    procedure CreateUserFromAADApplication()
    var
        User: Record User;
        NavUserAccountHelper: DotNet NavUserAccountHelper;
        ErrText: Text;
    begin
        Rec.TestField(Description);
        if UserExists() then begin
            User.Get("User Id");
            User.State := User.State::Enabled;
            User.Modify();
            exit;
        end;
        // The "AAD Application" have been removed earlier and id being recreated now
        User.SetRange("License Type", User."License Type"::"Full User");
        User.SetRange(State, User.State::Enabled);
        if User.IsEmpty() then begin
            ErrText := StrSubstNo(UserMustExistErr, Rec.TableCaption());
            Error(ErrText);
        end;

        "User Id" := NavUserAccountHelper.CreateApplicationRegistration(Description, "Client Id");
        Modify();
        if UserExists() then begin
            User.Get("User Id");
            User.State := Rec.State;
            User.Modify();
            exit;
        end;
    end;


    [Scope('OnPrem')]
    procedure UserExists(): Boolean;
    var
        User: Record User;
    begin
        User.SetRange("User Security ID", "User ID");
        if not User.IsEmpty() then
            exit(true);

        User.SetRange("User Security ID");
        user.SetRange("Application ID", "Client Id");
        User.SetRange("License Type", User."License Type"::Application);
        if User.FindFirst() then begin
            Rec."User ID" := User."User Security ID";
            Rec.Modify();
            exit(true);
        end;

        exit(false);
    end;


    [Scope('OnPrem')]
    procedure RemoveUser()
    var
        User: Record User;
    begin
        if not UserExists() then
            exit;
        User.Get("User Id");
        User.Delete();
    end;

    trigger OnInsert()
    begin
        TestField("Client Id");
    end;

    trigger OnDelete()
    begin
        RemoveUser();
    end;

    trigger OnRename()
    begin
        Error(CannotRenameErr, TableCaption);
    end;

    var
        AADApplicationSetup: Codeunit "AAD Application Setup";
        CannotRenameErr: Label 'You cannot rename a %1.', Comment = '%1 Table name';
        UserMustExistErr: Label 'Register a user before enabling the %1', Comment = '%1 Table AAD Application';
        NoPermissionToChangeUserErr: Label 'You need to have either %1 or %2 privileges in the user permission set to update the state.', Comment = '%1 = SUPER; %2 = SECURITY';
        SECURITYPermissionSetTxt: Label 'SECURITY', Locked = true;
        SuperPermissionSetTxt: Label 'SECURITY', Locked = true;
        UserNameCannotbeChangedQst: Label 'A user named %1 will be created. Do you want to continue?', Comment = '%1 a user name eq. xxx yyyyyy';
}


