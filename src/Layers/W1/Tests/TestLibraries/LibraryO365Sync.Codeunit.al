codeunit 131013 "Library - O365 Sync"
{

    trigger OnRun()
    begin
    end;

    var
        PasswordTxt: Label 'TFS72928!';
        AuthenticationEmailTxt: Label 'navtest@M365B409112.onmicrosoft.com';
        User: Record User;
        LibraryUtility: Codeunit "Library - Utility";
        FolderId: Text[30];
        BookingsMailboxTxt: Label 'M365B409112bookings@M365B409112.onmicrosoft.com';
        O365Email1emailcomNoSyncTxt: Label 'O365EmailNoSync1@email.com';

    procedure SetupBookingsSync(var BookingSync: Record "Booking Sync")
    begin
        BookingSync.DeleteAll();

        BookingSync.Validate("Booking Mailbox Address", BookingsMailboxTxt);
        BookingSync.Validate("User ID", UserId);
        BookingSync.Insert();
    end;

    [Normal]
    procedure SetupExchangeSync(var ExchangeSync: Record "Exchange Sync")
    begin
        if ExchangeSync.Get(UserId) then
            ExchangeSync.Delete();

        // Create a random folder id, but keep it consistent for the entire run.
        if FolderId = '' then
            FolderId := CopyStr(LibraryUtility.GenerateRandomText(30), 1, 30);

        ExchangeSync.Init();
        ExchangeSync."User ID" := UserId;
        ExchangeSync.SetExchangeAccountPassword(PasswordTxt);
        ExchangeSync."Folder ID" := FolderId;
        SetExchangeIncrementedSyncTime(ExchangeSync);
        ExchangeSync.Enabled := true;
        ExchangeSync.Insert();
    end;

    [NonDebuggable]
    procedure SetupExchangeTableConnection(var ExchangeSync: Record "Exchange Sync"; var LocalConnectionID: Guid)
    var
        O365SyncManagement: Codeunit "O365 Sync. Management";
        LocalConnectionString: SecretText;
    begin
        LocalConnectionID := CreateGuid();
        LocalConnectionString := O365SyncManagement.BuildExchangeConnectionStringAsSecretText(ExchangeSync);
        RegisterTableConnection(TABLECONNECTIONTYPE::Exchange, LocalConnectionID, LocalConnectionString.Unwrap());
        SetDefaultTableConnection(TABLECONNECTIONTYPE::Exchange, LocalConnectionID);
    end;

    [NonDebuggable]
    procedure SetupBookingTableConnection(var BookingSync: Record "Booking Sync"; var LocalConnectionID: Guid)
    var
        O365SyncManagement: Codeunit "O365 Sync. Management";
        LocalConnectionString: SecretText;
    begin
        LocalConnectionID := CreateGuid();
        LocalConnectionString := O365SyncManagement.BuildBookingsConnectionStringAsSecretText(BookingSync);
        RegisterTableConnection(TABLECONNECTIONTYPE::Exchange, LocalConnectionID, LocalConnectionString.Unwrap());
        SetDefaultTableConnection(TABLECONNECTIONTYPE::Exchange, LocalConnectionID);
    end;

    procedure SetupNavUser()
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        // Sets up the user if it doesn't exist (e.g. we're using Windows Auth and have no users defined)
        User.SetRange("User Name", UserId);
        if not User.FindFirst() then begin
            User.Init();
            User."User Security ID" := CreateGuid();
            User."User Name" := UserId;
            User."Full Name" := User."User Name";
            if not EnvironmentInformation.IsSaaSInfrastructure() then
                User."Windows Security ID" := Sid(User."User Name");
            User.Insert(true);
        end;

        User."Authentication Email" := AuthenticationEmailTxt;
        User.Modify(true);
    end;

    [Normal]
    procedure SetExchangeIncrementedSyncTime(var ExchangeSync: Record "Exchange Sync")
    var
        ExchangeContact: Record "Exchange Contact";
        ConnectionGUID: Guid;
        SyncTime: DateTime;
        CurrentDateTime: DateTime;
        IncrementTime: Duration;
    begin
        // Gets the modified time of the 'no sync' contact and returns a date time that is more recent.
        // Defaulting to current-1Day if that record does not exist.
        // This allows us to use a consistent sync date that should always exclude this contact, while allowing
        // all of the others to sync properly.

        // Increment the sync time by one minute:
        IncrementTime := 60 * 1000;

        SetupExchangeTableConnection(ExchangeSync, ConnectionGUID);

        if ExchangeContact.Get(O365Email1emailcomNoSyncTxt) then begin
            SyncTime := ExchangeContact.LastModifiedTime;
            SyncTime := CreateDateTime(DT2Date(SyncTime), (DT2Time(SyncTime) + IncrementTime));
        end else
            SyncTime := CreateDateTime(CalcDate('<CD-1D>', Today), Time);

        // If, for any reason, the sync time is in the future, wait until that time has passed
        // This ensures that the 'no sync' record's modified time is older than the sync time.
        CurrentDateTime := CreateDateTime(Today, Time);
        if CurrentDateTime < SyncTime then
            Sleep(SyncTime - CurrentDateTime + (IncrementTime * 5));

        ExchangeSync."Last Sync Date Time" := SyncTime;

        UnregisterTableConnection(TABLECONNECTIONTYPE::Exchange, ConnectionGUID);
    end;
}

