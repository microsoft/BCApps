codeunit 139325 "Document Service Mock Tests"
{
    // PRECONDITION: Most tests will require Mock services to be started using the following enlistment command
    //   Start-AMCMockService -Configuration release -Secure
    // If you need to change any of the mock test values or logic, you have to rebuild it
    //   cd .\test\App\MockService\
    //   msbuild /t:clean
    //   msbuild /p:configuration=release
    // You might also need to rebuild some dependency
    //   cd .\test\App\MS.Nav.Test.App.Certificates\
    //   msbuild /p:configuration=release

    Subtype = Test;
    TestPermissions = Restrictive;
    EventSubscriberInstance = Manual;
    Permissions = TableData "Document Service" = rimd;

    [Test]
    [Scope('OnPrem')]
    procedure DocumentService_OnPremNoSetup_NoLink()
    var
        UserSettings: TestPage "User Settings";
    begin
        // Initialize
        Initialize(false);
        UserSettings.OpenEdit();

        LibraryLowerPermissions.SetO365Basic();
        Assert.AreEqual(false, UserSettings.OpenOnedriveBCFolder.Visible(), 'Link is visible but should not.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DocumentService_OnPremSetup_ShowsLink()
    var
        UserSettings: TestPage "User Settings";
    begin
        // Initialize
        Initialize(false);
        CreateDocumentServiceSetup();

        LibraryLowerPermissions.SetO365Basic();
        UserSettings.OpenEdit();
        Assert.AreEqual(true, UserSettings.OpenOnedriveBCFolder.Visible(), 'Link is not visible but should be.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DocumentService_SaasNoSetup_ShowsLink()
    var
        UserSettings: TestPage "User Settings";
    begin
        // Initialize
        Initialize(true);

        LibraryLowerPermissions.SetO365Basic();
        UserSettings.OpenEdit();
        Assert.AreEqual(true, UserSettings.OpenOnedriveBCFolder.Visible(), 'Link is not visible but should be.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DocumentService_SaasSetup_ShowsLink()
    var
        UserSettings: TestPage "User Settings";
    begin
        // Initialize
        Initialize(true);
        CreateDocumentServiceSetup();

        LibraryLowerPermissions.SetO365Basic();
        UserSettings.OpenEdit();
        Assert.AreEqual(true, UserSettings.OpenOnedriveBCFolder.Visible(), 'Link is not visible but should be.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DocumentService_SaasSetup_CorrectLink()
    var
        DocumentServiceManagement: Codeunit "Document Service Management";
    begin
        // Initialize
        Initialize(true);
        LibraryLowerPermissions.SetO365Full();
        CreateDocumentServiceSetup();
        SubscriberDocumentServiceMockTests.EnqueueToken('MockServicePacket456'); // Drive root
        SubscriberDocumentServiceMockTests.EnqueueToken('CompanyFolderToken'); // Current Company folder
        SubscriberDocumentServiceMockTests.SetForceOnPremAfterTokenGen(true);

        LibraryLowerPermissions.SetO365Basic();
        Assert.AreEqual('https://contosoorganization-my.sharepoint.com/personal/meganb_contosoorganization_onmicrosoft_com/Documents/CustomFolder', DocumentServiceManagement.GetMyBusinessCentralFilesLink(),
                    'Unexpected link generated.');

        SubscriberDocumentServiceMockTests.AssertEmptyStorage();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DocumentService_SaasNoSetup_CorrectLink()
    var
        DocumentServiceManagement: Codeunit "Document Service Management";
    begin
        // Initialize
        Initialize(true);
        LibraryLowerPermissions.SetO365Full();
        SubscriberDocumentServiceMockTests.EnqueueToken('MockServicePacket456'); // Drive root
        SubscriberDocumentServiceMockTests.EnqueueToken('CompanyFolderToken'); // Current Company folder
        SubscriberDocumentServiceMockTests.SetForceOnPremAfterTokenGen(true);
        SubscriberDocumentServiceMockTests.SetForceSaasAfterWebRequest(true);

        LibraryLowerPermissions.SetO365Basic();
        Assert.AreEqual('https://contosoorganization-my.sharepoint.com/personal/meganb_contosoorganization_onmicrosoft_com/Documents/CompanyFolder', DocumentServiceManagement.GetMyBusinessCentralFilesLink(),
                    'Unexpected link generated.');

        SubscriberDocumentServiceMockTests.AssertEmptyStorage();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DocumentService_OnPremSetup_CorrectLink()
    var
        DocumentServiceManagement: Codeunit "Document Service Management";
    begin
        // Initialize
        Initialize(false);
        LibraryLowerPermissions.SetO365Full();
        CreateDocumentServiceSetup();
        SubscriberDocumentServiceMockTests.EnqueueToken('MockServicePacket456'); // Drive root
        SubscriberDocumentServiceMockTests.EnqueueToken('CompanyFolderToken'); // Current Company folder

        LibraryLowerPermissions.SetO365Basic();
        Assert.AreEqual('https://contosoorganization-my.sharepoint.com/personal/meganb_contosoorganization_onmicrosoft_com/Documents/CustomFolder', DocumentServiceManagement.GetMyBusinessCentralFilesLink(),
                    'Unexpected link generated.');

        SubscriberDocumentServiceMockTests.AssertEmptyStorage();
    end;

    // Local functions

    local procedure CreateDocumentServiceSetup()
    var
        DocumentService: Record "Document Service";
        IsolatedStorageManagement: Codeunit "Isolated Storage Management";
    begin
        DocumentService.Init();
        DocumentService."Service ID" := 'TESTMOCK';
        DocumentService.Location := 'https://beavers-my.sharepoint.com/';
        DocumentService.Folder := 'CustomValue';
        DocumentService.Insert();

        DocumentService."Client Id" := CreateGuid();
        DocumentService."Authentication Type" := DocumentService."Authentication Type"::OAuth2;
        DocumentService."Client Secret Key" := CreateGuid();
        DocumentService.Modify();
        IsolatedStorageManagement.Set(DocumentService."Client Secret Key", CreateGuid(), DATASCOPE::Company);
    end;

    local procedure Initialize(SaaS: Boolean)
    var
        AzureADMgtSetup: Record "Azure AD Mgt. Setup";
        AzureADAppSetup: Record "Azure AD App Setup";
        DocumentService: Record "Document Service";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        PrivacyNotice: Codeunit "Privacy Notice";
        PrivacyNoticeRegistrations: Codeunit "Privacy Notice Registrations";
    begin
        PrivacyNotice.SetApprovalState(PrivacyNoticeRegistrations.GetOneDrivePrivacyNoticeId(), "Privacy Notice Approval State"::Agreed);
        LibraryVariableStorage.AssertEmpty();
        DocumentService.DeleteAll();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(SaaS);
        SubscriberDocumentServiceMockTests.AssertEmptyStorage();
        SubscriberDocumentServiceMockTests.SetForceOnPremAfterTokenGen(false);
        SubscriberDocumentServiceMockTests.SetForceSaasAfterWebRequest(false);

        if IsInitialized then
            exit;

        if not AzureADMgtSetup.Get() then begin
            AzureADMgtSetup.Init();
            AzureADMgtSetup.Insert();
        end;
        if not AzureADAppSetup.FindFirst() then begin
            AzureADAppSetup.Init();
            AzureADAppSetup.Insert();
        end;

        AzureADMgtSetup."Auth Flow Codeunit ID" := 0;
        AzureADMgtSetup.Modify();
        if BindSubscription(SubscriberDocumentServiceMockTests) then;

        Isinitialized := true;
    end;

    // Event subscribers and related functions

    [Scope('OnPrem')]
    procedure EnqueueToken(NewMockServiceToken: Text)
    begin
        LibraryVariableStorage.Enqueue(NewMockServiceToken);
    end;

    [Scope('OnPrem')]
    procedure SetForceOnPremAfterTokenGen(NewForceOnPrem: Boolean)
    begin
        ForceOnPrem := NewForceOnPrem;
    end;

    [Scope('OnPrem')]
    procedure SetForceSaasAfterWebRequest(NewForceSaas: Boolean)
    begin
        ForceSaas := NewForceSaas;
    end;

    [Scope('OnPrem')]
    procedure AssertEmptyStorage()
    begin
        LibraryVariableStorage.AssertEmpty();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Azure AD Auth Flow", 'OnAcquireTokenFromCache', '', false, false)]
    local procedure InjectAccessTokenCache(ResourceName: Text; var AccessToken: Text)
    var
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
    begin
        if ResourceName <> 'https://graph.microsoft.com' then
            Error('Unexpected resource name.');

        if LibraryVariableStorage.Length() = 0 then
            Error('Detect string is not set.');

        if ForceOnPrem then // Web Request Management allows overwriting the base URL only in OnPrem
            EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);

        AccessToken := StrSubstNo('thistokenissecure_%1_extremelysecure', LibraryVariableStorage.DequeueText());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Azure AD Auth Flow", 'OnAcquireTokenFromCacheWithCredentials', '', false, false)]
    local procedure InjectAccessTokenCacheOnPrem(ClientID: Text; AppKey: Text; ResourceName: Text; var AccessToken: Text)
    begin
        if ResourceName <> 'https://graph.microsoft.com' then
            Error('Unexpected resource name.');

        if LibraryVariableStorage.Length() = 0 then
            Error('Detect string is not set.');

        AccessToken := StrSubstNo('thistokenissecure_%1_extremelysecure', LibraryVariableStorage.DequeueText());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Azure AD Auth Flow", 'OnCheckProvider', '', false, false)]
    local procedure CheckProvider(var Result: Boolean)
    begin
        Result := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Http Web Request Mgt.", 'OnOverrideUrl', '', false, false)]
    local procedure OverrideUrl(var Url: Text)
    var
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        Uri: Codeunit Uri;
        UriBuilder: Codeunit "Uri Builder";
    begin
        UriBuilder.Init(Url);
        if DelChr(UriBuilder.GetHost(), '>', '/') <> 'graph.microsoft.com' then
            exit;

        UriBuilder.SetScheme('https');
        UriBuilder.SetHost('localhost');
        UriBuilder.SetPort(8080);

        UriBuilder.GetUri(Uri);
        Url := Uri.GetAbsoluteUri();

        if ForceSaas then // Web Request Management allows overwriting the base URL only in OnPrem
            EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
    end;

    var
        Assert: Codeunit Assert;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        SubscriberDocumentServiceMockTests: Codeunit "Document Service Mock Tests";
        IsInitialized: Boolean;
        ForceOnPrem: Boolean;
        ForceSaas: Boolean;
}