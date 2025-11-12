namespace System.Security.User;

using System.Security.AccessControl;
using System.Reflection;
using System.Environment;
using System.Utilities;

codeunit 9800 User
{
    var
        UserRenameConfirmationQst: Label 'You are renaming an existing user. This will also update all related records. Are you sure that you want to rename the user?';
        UserAccountAlreadyExistsErr: Label 'The account %1 already exists.', Comment = '%1 username';
        CurrentUserQst: Label 'You are signed in with the %1 account. Changing the account will refresh your session. Do you want to continue?', Comment = '%1 = user id';
        TablePermissionDeniedErr: Label 'You do not have permissions for this action on the table %1.', Comment = '%1 table name';
        DisableUserMsg: Label 'To permanently disable a user, go to your Microsoft 365 admin center. Disabling the user in Business Central will only be effective until the next user synchronization with Microsoft 365.';

    procedure ValidateUserName(NewUser: Record User; OldUser: Record User; WindowsUserName: Text)
    var
        User: Record User;
        ConfirmManagement: Codeunit "Confirm Management";
        CheckForWindowsUserName: Boolean;
    begin
        if NewUser."User Name" <> OldUser."User Name" then begin
            User.SetRange("User Name", NewUser."User Name");
            User.SetFilter("User Security ID", '<>%1', OldUser."User Security ID");
            if not User.IsEmpty() then
                Error(UserAccountAlreadyExistsErr, NewUser."User Name");

            CheckForWindowsUserName := NewUser."Windows Security ID" <> '';
            OnValidateUserNameOnAfterCalcCheckForWindowsUserName(NewUser, WindowsUserName, CheckForWindowsUserName);
            if CheckForWindowsUserName then
                NewUser.TestField("User Name", WindowsUserName);

            if OldUser."User Name" <> '' then
                if ConfirmManagement.GetResponseOrDefault(UserRenameConfirmationQst, false) then
                    RenameUser(OldUser."User Name", NewUser."User Name")
                else
                    Error('');
        end;
    end;

    procedure RenameUser(OldUserName: Code[50]; NewUserName: Code[50])
    var
        User: Record User;
        "Field": Record Field;
        TableInformation: Record "Table Information";
        Company: Record Company;
        RecRef: RecordRef;
        FieldRef: FieldRef;
        FieldRef2: FieldRef;
        SessionSetting: SessionSettings;
        NumberOfPrimaryKeyFields: Integer;
        IsHandled: Boolean;
    begin
        OnBeforeRenameUser(OldUserName, NewUserName);

        if OldUserName = UserID then
            if not confirm(CurrentUserQst, true, UserID) then
                error('');

        Field.SetFilter(ObsoleteState, '<>%1', Field.ObsoleteState::Removed);
        Field.SetRange(RelationTableNo, DATABASE::User);
        Field.SetRange(RelationFieldNo, User.FieldNo("User Name"));
        Field.SetFilter(Type, '%1|%2', Field.Type::Code, Field.Type::Text);
        if Field.FindSet() then
            repeat
                Company.FindSet();
                repeat
                    IsHandled := false;
                    OnRenameUserOnBeforeProcessField(Field.TableNo, Field."No.", OldUserName, NewUserName, Company.Name, IsHandled);
                    if not IsHandled then begin
                        RecRef.Open(Field.TableNo, false, Company.Name);
                        if RecRef.ReadPermission then begin
                            FieldRef := RecRef.Field(Field."No.");
                            FieldRef.SetRange(CopyStr(OldUserName, 1, Field.Len));
                            if RecRef.FindSet(true) then
                                repeat
                                    if IsPrimaryKeyField(Field.TableNo, Field."No.", NumberOfPrimaryKeyFields) then
                                        RenameRecord(RecRef, Field.TableNo, NumberOfPrimaryKeyFields, NewUserName, Company.Name)
                                    else begin
                                        FieldRef2 := RecRef.Field(Field."No.");
                                        FieldRef2.Value := CopyStr(NewUserName, 1, Field.Len);
                                        RecRef.Modify();
                                    end;
                                until RecRef.Next() = 0;
                        end else begin
                            TableInformation.SetFilter("Company Name", '%1|%2', '', Company.Name);
                            TableInformation.SetRange("Table No.", Field.TableNo);
                            if TableInformation.FindFirst() then
                                if TableInformation."No. of Records" > 0 then
#pragma warning disable AA0448
                                    Error(TablePermissionDeniedErr, Field.TableName);
#pragma warning restore AA0448
                        end;
                        RecRef.Close();
                    end;
                until Company.Next() = 0;
            until Field.Next() = 0;

        if OldUserName = UserId then begin
            SessionSetting.Init();
            SessionSetting.RequestSessionUpdate(false);
        end;

        OnAfterRenameUser(OldUserName, NewUserName);
    end;

    procedure ValidateState(var Rec: Record User; var xRec: Record User);
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        if not EnvironmentInformation.IsSaaS() then
            exit;

        if (xRec.State <> Rec.State) and (Rec.State = Rec.State::Disabled) then
            Message(DisableUserMsg);
    end;

    local procedure IsPrimaryKeyField(TableID: Integer; FieldID: Integer; var NumberOfPrimaryKeyFields: Integer): Boolean
    var
        RecRef: RecordRef;
        KeyRef: KeyRef;
    begin
        RecRef.Open(TableID);
        KeyRef := RecRef.KeyIndex(1);
        NumberOfPrimaryKeyFields := KeyRef.FieldCount;
        exit(IsKeyField(TableID, FieldID));
    end;

    local procedure IsKeyField(TableID: Integer; FieldID: Integer): Boolean
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
        KeyRef: KeyRef;
        KeyFieldCount: Integer;
    begin
        RecRef.Open(TableID);
        KeyRef := RecRef.KeyIndex(1);
        for KeyFieldCount := 1 to KeyRef.FieldCount do begin
            FieldRef := KeyRef.FieldIndex(KeyFieldCount);
            if FieldRef.Number = FieldID then
                exit(true);
        end;

        exit(false);
    end;

    local procedure RenameRecord(var RecRef: RecordRef; TableNo: Integer; NumberOfPrimaryKeyFields: Integer; UserName: Code[50]; Company: Text[30])
    begin
        if NumberOfPrimaryKeyFields = 1 then
            RecRef.Rename(UserName);

        OnAfterRenameRecord(RecRef, TableNo, NumberOfPrimaryKeyFields, UserName, Company);
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterRenameRecord(var RecRef: RecordRef; TableNo: Integer; NumberOfPrimaryKeyFields: Integer; UserName: Code[50]; Company: Text[30])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRenameUser(OldUserName: Code[50]; NewUserName: Code[50])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRenameUser(OldUserName: Code[50]; NewUserName: Code[50])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRenameUserOnBeforeProcessField(TableID: Integer; FieldID: Integer; OldUserName: Code[50]; NewUserName: Code[50]; CompanyName: Text[30]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateUserNameOnAfterCalcCheckForWindowsUserName(NewUser: Record User; WindowsUserName: Text; var CheckForWindowsUserName: Boolean)
    begin
    end;
}