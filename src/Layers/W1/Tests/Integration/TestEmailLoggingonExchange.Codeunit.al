codeunit 139025 "Test Email Logging on Exchange"
{
    // Tests Logging of Email Interactions directly against our corporate Exchange Server.
    // Has a dependency on Active Directory, test accounts and Exchange.
    // The tests in this codeunit are therefore not sufficiently reliable to run in SNAP.

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [INT] [Exchange Web Services Client]
    end;

    var
        Assert: Codeunit Assert;

    local procedure TryInitializeEWS(var ExchangeWebServicesClient: Codeunit "Exchange Web Services Client"): Boolean
    begin
        // This function returns TRUE, only if the current test environment allows for successful EWS autodetection with the email address below
        exit(ExchangeWebServicesClient.InitializeOnClient('vlabtest@microsoft.com', 'https://outlook.office365.com/EWS/Exchange.asmx'));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestExchangeWebServicesInvalidateService()
    var
        ExchangeWebServicesClient: Codeunit "Exchange Web Services Client";
    begin
        ExchangeWebServicesClient.InvalidateService();
        // Expect no run-time errors whatsoever
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestExchangeWebServicesInitializeOk()
    var
        ExchangeWebServicesClient: Codeunit "Exchange Web Services Client";
        Status: Boolean;
    begin
        Status := TryInitializeEWS(ExchangeWebServicesClient);
        Assert.IsTrue(Status, 'Initialization of ExchangeWebServicesClient failed upon 1st init attempt');

        Status := TryInitializeEWS(ExchangeWebServicesClient);
        Assert.IsTrue(Status, 'Initialization of ExchangeWebServicesClient failed upon 2nd init attempt');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestExchangeWebServicesReadBuffer()
    var
        ExchangeFolder: Record "Exchange Folder";
        ExchangeWebServicesClient: Codeunit "Exchange Web Services Client";
        Status: Boolean;
    begin
        Status := TryInitializeEWS(ExchangeWebServicesClient);
        Assert.IsTrue(Status, 'Initialization of ExchangeWebServicesClient failed');

        ExchangeFolder.Init();
        Status := ExchangeWebServicesClient.ReadBuffer(ExchangeFolder);
        Assert.IsFalse(Status, 'ReadBuffer is not supposed to return TRUE with empty ExchangeFolder');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestExchangeWebServicesGetPublicFolders()
    var
        ExchangeFolder: Record "Exchange Folder";
        ExchangeWebServicesClient: Codeunit "Exchange Web Services Client";
        Status: Boolean;
    begin
        Status := TryInitializeEWS(ExchangeWebServicesClient);
        Assert.IsTrue(Status, 'Initialization of ExchangeWebServicesClient failed');

        ExchangeFolder.Init();
        ExchangeFolder.Cached := true;
        Status := ExchangeWebServicesClient.GetPublicFolders(ExchangeFolder);
        Assert.IsFalse(Status, 'GetPublicFolders with cached folder should not fail');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestExchangeWebServicesFolderExistsInvalidated()
    var
        ExchangeWebServicesClient: Codeunit "Exchange Web Services Client";
    begin
        ExchangeWebServicesClient.InvalidateService();

        asserterror ExchangeWebServicesClient.FolderExists('AAABBBBCCCC==');
        Assert.ExpectedError('Connection to the Exchange server failed.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestExchangeWebServicesGetPublicFoldersInvalidated()
    var
        ExchangeFolder: Record "Exchange Folder";
        ExchangeWebServicesClient: Codeunit "Exchange Web Services Client";
    begin
        ExchangeWebServicesClient.InvalidateService();

        ExchangeFolder.Init();
        asserterror ExchangeWebServicesClient.GetPublicFolders(ExchangeFolder);
        Assert.ExpectedError('Connection to the Exchange server failed.');
    end;
}

