// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#pragma warning disable AA0247

codeunit 6700 "O365 Sync. Management"
{
    trigger OnRun()
    var
        IsHandled: Boolean;
    begin
        OnBeforeOnRun(IsHandled);
        if IsHandled then
            exit;

        CODEUNIT.Run(CODEUNIT::"Exchange Contact Sync.");
        CODEUNIT.Run(CODEUNIT::"Booking Customer Sync.");
        CODEUNIT.Run(CODEUNIT::"Booking Service Sync.");
    end;

    var
        IsolatedStorageManagement: Codeunit "Isolated Storage Management";
        ProgressWindow: Dialog;
        BookingsConnectionID: Text;
        ConnectionErr: Label '%1 is unable to connect to Exchange. This may be due to a service outage or invalid credentials.', Comment = '%1 = User who cannot connect';
        LoggingConstTxt: Label 'Contact synchronization.';
        O365RecordMissingErr: Label 'The Office 365 synchronization setup record is not configured correctly.';
        ExchangeConnectionID: Text;
        RegisterConnectionTxt: Label 'Register connection.';
        SetupO365Qst: Label 'Would you like to configure your connection to Office 365 now?';
        BookingsConnectionString: SecretText;
        ExchangeConnectionString: SecretText;
        GettingContactsTxt: Label 'Getting Exchange contacts.';
        GettingBookingCustomersTxt: Label 'Getting Booking customers.';
        GettingBookingServicesTxt: Label 'Getting Booking services.';
        NoUserAccessErr: Label 'Could not connect to %1. Verify that %2 is an administrator in the Bookings mailbox.', Comment = '%1 = The Bookings company; %2 = The user';
        JobQueueEntryDescTxt: Label 'Auto-created for retrieval of new data from Outlook and Bookings. Can be deleted if not used. Will be recreated when the feature is activated.';

    [TryFunction]
    [Scope('OnPrem')]
    procedure GetBookingMailboxes(BookingSync: Record "Booking Sync"; var TempBookingMailbox: Record "Booking Mailbox" temporary; MailboxName: Text)
    var
        BookingMailbox: Record "Booking Mailbox";
    begin
        BookingSync."Booking Mailbox Address" := CopyStr(MailboxName, 1, 80);
        RegisterBookingsConnection(BookingSync);
        TempBookingMailbox.Reset();
        TempBookingMailbox.DeleteAll();
        if BookingMailbox.FindSet() then
            repeat
                TempBookingMailbox.Init();
                TempBookingMailbox.TransferFields(BookingMailbox);
                TempBookingMailbox.Insert();
            until BookingMailbox.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure CreateExchangeConnection(var ExchangeSync: Record "Exchange Sync") Valid: Boolean
    var
        User: Record User;
        AuthenticationEmail: Text[250];
    begin
        IsO365Setup(false);
        if GetUser(User, ExchangeSync."User ID") then begin
            AuthenticationEmail := User."Authentication Email";
            Valid := ValidateExchangeConnection(AuthenticationEmail, ExchangeSync);
        end;
    end;

    [Scope('OnPrem')]
    procedure IsO365Setup(AddOnTheFly: Boolean): Boolean
    var
        User: Record User;
        LocalExchangeSync: Record "Exchange Sync";
        AuthenticationEmail: Text[250];
        Password: SecretText;
        Token: SecretText;
    begin
        if GetUser(User, UserId()) then
            AuthenticationEmail := User."Authentication Email";

        if not LocalExchangeSync.Get(UserId) or
            (AuthenticationEmail = '') or (LocalExchangeSync."Folder ID" = '') or not GetPasswordOrToken(LocalExchangeSync, Password, Token)
        then
            if AddOnTheFly then begin
                if not OpenSetupWindow() then
                    Error(O365RecordMissingErr)
            end else
                Error(O365RecordMissingErr);

        exit(true);
    end;

    procedure OpenSetupWindow(): Boolean
    var
        ExchangeSyncSetup: Page "Exchange Sync. Setup";
    begin
        if Confirm(SetupO365Qst, true) then
            exit(ExchangeSyncSetup.RunModal() = ACTION::OK);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company-Initialize", 'OnCompanyInitialize', '', false, false)]
    local procedure SetupContactSyncJobQueue()
    var
        JobQueueEntry: Record "Job Queue Entry";
        TwentyFourHours: Integer;
    begin
        if TASKSCHEDULER.CanCreateTask() then begin
            JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
            JobQueueEntry.SetRange("Object ID to Run", CODEUNIT::"O365 Sync. Management");
            if JobQueueEntry.IsEmpty() then begin
                TwentyFourHours := 24 * 60;
                JobQueueEntry.InitRecurringJob(TwentyFourHours);
                JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
                JobQueueEntry."Object ID to Run" := CODEUNIT::"O365 Sync. Management";
                JobQueueEntry.Description := CopyStr(JobQueueEntryDescTxt, 1, MaxStrLen(JobQueueEntry.Description));
                CODEUNIT.Run(CODEUNIT::"Job Queue - Enqueue", JobQueueEntry);
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure SyncBookingCustomers(var BookingSync: Record "Booking Sync")
    var
        BookingCustomerSync: Codeunit "Booking Customer Sync.";
    begin
        Session.LogMessage('0000ACP', 'Syncing Bookings Customers', Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TraceCategory());
        CheckUserAccess(BookingSync);
        ShowProgress(GettingBookingCustomersTxt);
        RegisterBookingsConnection(BookingSync);
        CloseProgress();
        BookingCustomerSync.SyncRecords(BookingSync);
    end;

    [Scope('OnPrem')]
    procedure SyncBookingServices(var BookingSync: Record "Booking Sync")
    var
        BookingServiceSync: Codeunit "Booking Service Sync.";
    begin
        Session.LogMessage('0000ACQ', 'Syncing Bookings Services', Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TraceCategory());
        CheckUserAccess(BookingSync);
        ShowProgress(GettingBookingServicesTxt);
        RegisterBookingsConnection(BookingSync);
        CloseProgress();
        BookingServiceSync.SyncRecords(BookingSync);
    end;

    [Scope('OnPrem')]
    procedure SyncExchangeContacts(ExchangeSync: Record "Exchange Sync"; FullSync: Boolean)
    var
        ExchangeContactSync: Codeunit "Exchange Contact Sync.";
    begin
        Session.LogMessage('0000ACR', 'Syncing Exchange Contacts', Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TraceCategory());
        ShowProgress(GettingContactsTxt);
        RegisterExchangeConnection(ExchangeSync);
        CloseProgress();
        ExchangeContactSync.SyncRecords(ExchangeSync, FullSync);
    end;

    procedure LogActivityFailed(RecordID: Variant; UserID: Code[50]; ActivityDescription: Text; ActivityMessage: Text)
    var
        ActivityLog: Record "Activity Log";
    begin
        ActivityMessage := GetLastErrorText + ' ' + ActivityMessage;
        ClearLastError();

        ActivityLog.LogActivityForUser(RecordID, ActivityLog.Status::Failed, CopyStr(LoggingConstTxt, 1, 30),
          ActivityDescription, ActivityMessage, UserID);
    end;

#if not CLEAN25
    [Obsolete('Replaced by BuildBookingsConnectionStringAsSecretText', '25.0')]
    [NonDebuggable]
    [Scope('OnPrem')]
    procedure BuildBookingsConnectionString(var BookingSync: Record "Booking Sync") ConnectionString: Text
    begin
        exit(BuildBookingsConnectionStringAsSecretText(BookingSync).Unwrap());
    end;
#endif

    [Scope('OnPrem')]
    procedure BuildBookingsConnectionStringAsSecretText(var BookingSync: Record "Booking Sync") ConnectionString: SecretText
    var
        User: Record User;
        ExchangeSync: Record "Exchange Sync";
        Password: SecretText;
        Token: SecretText;
    begin
        // Example connection string
        // {UserName}="user@user.onmicrosoft.com";{Password}="1234";{FolderID}="Dynamics NAV";{Uri}=https://outlook.office365.com/EWS/Exchange.asmx
        ExchangeSync.Get(BookingSync."User ID");
        if (not GetUser(User, BookingSync."User ID")) or
           (User."Authentication Email" = '') or
           (not GetPasswordOrToken(ExchangeSync, Password, Token))
        then
            Error(O365RecordMissingErr);

        ConnectionString :=
          SecretStrSubstNo(
            '{UserName}=%1;{Password}=%2;{Token}=%3;{Mailbox}=%4;',
            User."Authentication Email",
            Password,
            Token,
            BookingSync."Booking Mailbox Address");

        if not Token.IsEmpty() then
            ConnectionString := SecretStrSubstNo('%1;{Uri}=%2', ConnectionString, ExchangeSync.GetExchangeEndpoint());
    end;

#if not CLEAN25
    [Obsolete('Replaced by BuildExchangeConnectionStringAsSecretText', '25.0')]
    [NonDebuggable]
    [Scope('OnPrem')]
    procedure BuildExchangeConnectionString(var ExchangeSync: Record "Exchange Sync") ConnectionString: Text
    begin
        exit(BuildExchangeConnectionStringAsSecretText(ExchangeSync).Unwrap());
    end;
#endif

    [Scope('OnPrem')]
    procedure BuildExchangeConnectionStringAsSecretText(var ExchangeSync: Record "Exchange Sync") ConnectionString: SecretText
    var
        User: Record User;
        Token: SecretText;
        Password: SecretText;
    begin
        // Example connection string
        // {UserName}="user@user.onmicrosoft.com";{Password}="1234";{FolderID}="Dynamics NAV";{Uri}=https://outlook.office365.com/EWS/Exchange.asmx
        if (not GetUser(User, ExchangeSync."User ID")) or
           (User."Authentication Email" = '') or
           (ExchangeSync."Folder ID" = '') or (not GetPasswordOrToken(ExchangeSync, Password, Token))
        then
            Error(O365RecordMissingErr);

        ConnectionString :=
          SecretStrSubstNo(
            '{UserName}=%1;{Password}=%2;{Token}=%3;{FolderID}=%4;',
            User."Authentication Email",
            Password,
            Token,
            ExchangeSync."Folder ID");

        if not Token.IsEmpty() then
            ConnectionString := SecretStrSubstNo('%1;{Uri}=%2', ConnectionString, ExchangeSync.GetExchangeEndpoint());
    end;

    [Scope('OnPrem')]
    procedure RegisterBookingsConnection(BookingSync: Record "Booking Sync")
    var
        ExchangeSync: Record "Exchange Sync";
    begin
        if ExchangeConnectionID <> '' then
            UnregisterConnection(ExchangeConnectionID);

        if BookingsConnectionReady(BookingSync) then
            exit;

        if BookingsConnectionID <> '' then
            UnregisterConnection(BookingsConnectionID);

        ExchangeSync.Get(BookingSync."User ID");
        BookingsConnectionID := CreateGuid();

        if RegisterConnection(ExchangeSync, BookingsConnectionID, BookingsConnectionString) then
            SetConnection(ExchangeSync, BookingsConnectionID);
    end;

    [Scope('OnPrem')]
    procedure RegisterExchangeConnection(ExchangeSync: Record "Exchange Sync")
    begin
        if BookingsConnectionID <> '' then
            UnregisterConnection(BookingsConnectionID);

        if ExchangeConnectionReady(ExchangeSync) then
            exit;

        if ExchangeConnectionID <> '' then
            UnregisterConnection(ExchangeConnectionID);

        ExchangeConnectionID := CreateGuid();
        if RegisterConnection(ExchangeSync, ExchangeConnectionID, ExchangeConnectionString) then
            SetConnection(ExchangeSync, ExchangeConnectionID);
    end;

    procedure TraceCategory(): Text
    begin
        exit('ExchangeSync');
    end;

    [TryFunction]
    [NonDebuggable]
    local procedure TryRegisterConnection(ConnectionID: Guid; ConnectionString: SecretText)
    begin
        // Using a try function, as these may throw an exception under certain circumstances (improper credentials, broken connection)
        RegisterTableConnection(TABLECONNECTIONTYPE::Exchange, ConnectionID, ConnectionString.Unwrap());
    end;

    local procedure RegisterConnection(ExchangeSync: Record "Exchange Sync"; ConnectionID: Guid; ConnectionString: SecretText) Success: Boolean
    begin
        Success := TryRegisterConnection(ConnectionID, ConnectionString);
        if not Success then
            ConnectionFailure(ExchangeSync);
    end;

    [TryFunction]
    local procedure TrySetConnection(ConnectionID: Guid)
    begin
        // Using a try function, as these may throw an exception under certain circumstances (improper credentials, broken connection)
        SetDefaultTableConnection(TABLECONNECTIONTYPE::Exchange, ConnectionID);
    end;

    local procedure SetConnection(ExchangeSync: Record "Exchange Sync"; ConnectionID: Guid) Success: Boolean
    begin
        Success := TrySetConnection(ConnectionID);
        if not Success then
            ConnectionFailure(ExchangeSync);
    end;

    [TryFunction]
    local procedure UnregisterConnection(var ConnectionID: Text)
    begin
        UnregisterTableConnection(TABLECONNECTIONTYPE::Exchange, ConnectionID);
        ConnectionID := '';
    end;

    local procedure ConnectionFailure(ExchangeSync: Record "Exchange Sync")
    begin
        LogActivityFailed(
            ExchangeSync.RecordId, RegisterConnectionTxt, StrSubstNo(ConnectionErr, ExchangeSync."User ID"), ExchangeSync."User ID");
        if GuiAllowed() then begin
            CloseProgress();
            Error(ConnectionErr, ExchangeSync."User ID");
        end;
    end;

    [Scope('OnPrem')]
    procedure ValidateExchangeConnection(AuthenticationEmail: Text[250]; var ExchangeSync: Record "Exchange Sync") Valid: Boolean
    var
        ExchangeWebServicesServer: Codeunit "Exchange Web Services Server";
        Credentials: DotNet ExchangeCredentials;
        Endpoint: Text[250];
    begin
        CreateExchangeAccountCredentials(ExchangeSync, Credentials);
        Endpoint := ExchangeSync."Exchange Service URI";
        Valid := ExchangeWebServicesServer.InitializeAndValidate(AuthenticationEmail, Endpoint, Credentials);
        if Valid and (Endpoint <> ExchangeSync."Exchange Service URI") then begin
            ExchangeSync.Validate("Exchange Service URI", Endpoint);
            ExchangeSync.Modify();
        end;
    end;

    [NonDebuggable]
    local procedure CreateExchangeAccountCredentials(var ExchangeSync: Record "Exchange Sync"; var Credentials: DotNet ExchangeCredentials)
    var
        User: Record User;
        WebCredentials: DotNet WebCredentials;
        OAuthCredentials: DotNet OAuthCredentials;
        AuthenticationEmail: Text[250];
        Token: SecretText;
        Password: SecretText;
    begin
        if GetUser(User, ExchangeSync."User ID") then
            AuthenticationEmail := User."Authentication Email";
        if AuthenticationEmail = '' then
            Error(O365RecordMissingErr);
        if not GetPasswordOrToken(ExchangeSync, Password, Token) then
            Error(O365RecordMissingErr);

        if not Token.IsEmpty() then
            Credentials := OAuthCredentials.OAuthCredentials(Token.Unwrap())
        else
            Credentials := WebCredentials.WebCredentials(AuthenticationEmail, Password.Unwrap());
    end;

    local procedure GetUser(var User: Record User; UserID: Text[50]): Boolean
    begin
        User.SetRange("User Name", UserID);
        exit(User.FindFirst());
    end;

    procedure ShowProgress(Message: Text)
    begin
        if GuiAllowed then begin
            CloseProgress();
            ProgressWindow.Open(Message);
        end;
    end;

    procedure CloseProgress()
    begin
        if GuiAllowed then
            if TryCloseProgress() then;
    end;

    [TryFunction]
    local procedure TryCloseProgress()
    begin
        ProgressWindow.Close();
    end;

    [NonDebuggable]
    local procedure ConnectionStringChanged(Before: SecretText; After: SecretText): Boolean
    begin
        exit(Before.Unwrap() <> After.Unwrap());
    end;

    local procedure BookingsConnectionReady(BookingSync: Record "Booking Sync") Ready: Boolean
    var
        NewConnectionString: SecretText;
    begin
        NewConnectionString := BuildBookingsConnectionStringAsSecretText(BookingSync);
        Ready := (BookingsConnectionID <> '') and (not ConnectionStringChanged(BookingsConnectionString, NewConnectionString));
        BookingsConnectionString := NewConnectionString;
    end;

    local procedure ExchangeConnectionReady(ExchangeSync: Record "Exchange Sync") Ready: Boolean
    var
        NewConnectionString: SecretText;
    begin
        NewConnectionString := BuildExchangeConnectionStringAsSecretText(ExchangeSync);
        Ready := (ExchangeConnectionID <> '') and (not ConnectionStringChanged(ExchangeConnectionString, NewConnectionString));
        ExchangeConnectionString := NewConnectionString;
    end;

    [Scope('OnPrem')]
    local procedure GetPasswordOrToken(ExchangeSync: Record "Exchange Sync"; var Password: SecretText; var Token: SecretText): Boolean
    var
        AzureADMgt: Codeunit "Azure AD Mgt.";
        Value: SecretText;
    begin
        Token := AzureADMgt.GetAccessTokenAsSecretText(AzureADMgt.GetO365Resource(), AzureADMgt.GetO365ResourceName(), false);
        if Token.IsEmpty() and not IsNullGuid(ExchangeSync."Exchange Account Password Key") then
            if IsolatedStorageManagement.Get(ExchangeSync."Exchange Account Password Key", DATASCOPE::Company, Value) then
                Password := Value;

        exit((not Token.IsEmpty()) or (not Password.IsEmpty()));
    end;

    local procedure CheckUserAccess(BookingSync: Record "Booking Sync")
    var
        ExchangeSync: Record "Exchange Sync";
        Credentials: DotNet ExchangeCredentials;
        ExchangeServiceFactory: DotNet ServiceWrapperFactory;
        ExchangeService: DotNet ExchangeServiceWrapper;
    begin
        ExchangeSync.Get(BookingSync."User ID");
        ExchangeService := ExchangeServiceFactory.CreateServiceWrapper2013();
        CreateExchangeAccountCredentials(ExchangeSync, Credentials);
        ExchangeService.SetNetworkCredential(Credentials);
        ExchangeService.ExchangeServiceUrl := ExchangeSync.GetExchangeEndpoint();

        if not ExchangeService.CanAccessBookingMailbox(BookingSync."Booking Mailbox Address") then
            Error(NoUserAccessErr, BookingSync."Booking Mailbox Name", BookingSync."User ID");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var IsHandled: Boolean)
    begin
    end;
}
