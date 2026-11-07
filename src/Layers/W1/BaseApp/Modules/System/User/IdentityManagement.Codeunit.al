namespace System.Security.AccessControl;

using System;

codeunit 9801 "Identity Management"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    begin
    end;

    var
        UserAccountHelper: DotNet NavUserAccountHelper;

    [Scope('OnPrem')]
    procedure SetAuthenticationKey(UserSecurityID: Guid; "Key": Text[80])
    begin
        if not UserAccountHelper.TrySetAuthenticationKey(UserSecurityID, Key) then
            Error(GetLastErrorText);
    end;

    [Scope('OnPrem')]
    procedure GetAuthenticationKey(UserSecurityID: Guid) "Key": Text[80]
    begin
        if not UserAccountHelper.TryGetAuthenticationKey(UserSecurityID, Key) then
            Key := Format(GetLastErrorText, 80);
    end;

    [Scope('OnPrem')]
    procedure GetNameIdentifier(UserSecurityID: Guid) NameID: Text[250]
    begin
        if not UserAccountHelper.TryGetNameIdentifier(UserSecurityID, NameID) then
            NameID := Format(GetLastErrorText, 250);
    end;

    [Scope('OnPrem')]
    procedure GetObjectId(UserSecurityID: Guid) ObjectID: Text[250]
    begin
        if not UserAccountHelper.TryGetAuthenticationObjectId(UserSecurityID, ObjectID) then
            ObjectID := Format(GetLastErrorText, 250);
    end;

    [Scope('OnPrem')]
    procedure CreateWebServicesKey(UserSecurityID: Guid; ExpiryDate: DateTime) "Key": Text[80]
    begin
        if not UserAccountHelper.TryCreateWebServicesKey(UserSecurityID, ExpiryDate, Key) then
            Error(GetLastErrorText);
    end;

    [Scope('OnPrem')]
    procedure GetPuid(): Text
    begin
        exit(UserAccountHelper.GetPuid());
    end;

    [Scope('OnPrem')]
    procedure CreateWebServicesKeyNoExpiry(UserSecurityID: Guid) "Key": Text[80]
    var
        ExpiryDate: DateTime;
    begin
        ExpiryDate := 0DT;
        if not UserAccountHelper.TryCreateWebServicesKey(UserSecurityID, ExpiryDate, Key) then
            Error(GetLastErrorText);
    end;

    [Scope('OnPrem')]
    procedure ClearWebServicesKey(UserSecurityID: Guid)
    begin
        if not UserAccountHelper.TryClearWebServicesKey(UserSecurityID) then
            Error(GetLastErrorText);
    end;

    [Scope('OnPrem')]
    procedure GetWebServicesKey(UserSecurityID: Guid) "Key": Text[80]
    var
        ExpiryDate: DateTime;
    begin
        if not UserAccountHelper.TryGetWebServicesKey(UserSecurityID, Key, ExpiryDate) then
            Key := Format(GetLastErrorText, 80);
    end;

    [Scope('OnPrem')]
    procedure IsAzure() Ok: Boolean
    begin
        Ok := UserAccountHelper.IsAzure();
    end;

    [Scope('OnPrem')]
    procedure GetWebServiceExpiryDate(UserSecurityID: Guid) ExpiryDate: DateTime
    var
        "Key": Text[80];
    begin
        if not UserAccountHelper.TryGetWebServicesKey(UserSecurityID, Key, ExpiryDate) then
            ExpiryDate := CurrentDateTime;
    end;

    [Scope('OnPrem')]
    procedure GetACSStatus(UserSecurityID: Guid) ACSStatus: Integer
    var
        ACSStatusOption: Option Disabled,Pending,Registered,Unknown;
        "Key": Text[80];
        NameID: Text[250];
    begin
        // Determines the status as follows:
        // If neither Nameidentifier, nor authentication key then Disabled
        // If authentiation key then Pending
        // If NameIdentifier then Registered
        // If no permission: Unknown

        if not UserAccountHelper.TryGetAuthenticationKey(UserSecurityID, Key) then begin
            ACSStatusOption := ACSStatusOption::Unknown;
            ACSStatus := ACSStatusOption;
            exit;
        end;

        if not UserAccountHelper.TryGetNameIdentifier(UserSecurityID, NameID) then begin
            ACSStatusOption := ACSStatusOption::Unknown;
            ACSStatus := ACSStatusOption;
            exit;
        end;

        if NameID = '' then begin
            if Key = '' then
                ACSStatusOption := ACSStatusOption::Disabled
            else
                ACSStatusOption := ACSStatusOption::Pending;
        end else
            ACSStatusOption := ACSStatusOption::Registered;

        ACSStatus := ACSStatusOption;
    end;

    [Scope('OnPrem')]
    procedure IsUserPasswordSet(UserSecurityID: Guid): Boolean
    begin
        exit(UserAccountHelper.IsPasswordSet(UserSecurityID));
    end;

    [Scope('OnPrem')]
    procedure IsWindowsAuthentication() Ok: Boolean
    begin
        Ok := UserAccountHelper.IsWindowsAuthentication();
    end;

    procedure IsUserNamePasswordAuthentication() Ok: Boolean
    begin
        Ok := UserAccountHelper.IsUserNamePasswordAuthentication();
    end;

    [Scope('OnPrem')]
    procedure IsAccessControlServiceAuthentication() Ok: Boolean
    begin
        Ok := UserAccountHelper.IsAccessControlServiceAuthentication();
    end;

    [Scope('OnPrem')]
    procedure UserName(Sid: Text): Text[208]
    begin
        if Sid = '' then
            exit('');

        exit(UserAccountHelper.UserName(Sid));
    end;

    [Scope('OnPrem')]
    procedure SetAuthenticationEmail(UserSecurityId: Guid; AuthenticationEmail: Text[250])
    begin
        ClearLastError();
        if not UserAccountHelper.TrySetAuthenticationEmail(UserSecurityId, AuthenticationEmail) then
            Error(GetLastErrorText);
    end;

    procedure IsUserDelegatedAdmin(): Boolean
    begin
        exit(UserAccountHelper.IsUserDelegatedAdmin());
    end;

    procedure GetAuthenticationStatus(UserSecurityId: Guid) O365AuthStatus: Integer
    begin
        O365AuthStatus := UserAccountHelper.GetAuthenticationStatus(UserSecurityId);
    end;
}

