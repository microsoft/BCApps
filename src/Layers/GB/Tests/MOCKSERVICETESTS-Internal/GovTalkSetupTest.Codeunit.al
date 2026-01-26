#if not CLEAN27
codeunit 144523 "GovTalk Setup Test"
{
    Subtype = Test;
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to GovTalk app';
    ObsoleteTag = '27.0';

    trigger OnRun()
    begin
    end;

    var
        GovTalkSetupTok: Label 'GovTalk Setup', Locked = true;
        Assert: Codeunit Assert;
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        ThirdPartyNoticeMsg: Label 'You are accessing a third-party website and service. You should review the third-party''''s terms and privacy policy.';
        NoVatNoMsg: Label 'GovTalk needs to know which company the documents are for. Before you can submit documents, you must enter your company''s VAT registration number on the Company Information page.';
        LibraryVariableStorage: Codeunit "Library - Variable Storage";

    [Test]
    [Scope('OnPrem')]
    procedure TestRegisteredInAssistedSetup()
    var
        ServiceConnection: Record "Service Connection";
        GovTalkSetup: Record "GovTalk Setup";
    begin
        // [GIVEN] No GovTalk Setup record exists, user has configuration permissions
        LibraryLowerPermissions.SetO365Setup();
        GovTalkSetup.DeleteAll();

        // [WHEN] All services for Service Connections page are gathered
        ServiceConnection.OnRegisterServiceConnection(ServiceConnection);
        ServiceConnection.SetRange(Name, GovTalkSetupTok);

        // [THEN] GovTalk Setup exists there
        Assert.RecordCount(ServiceConnection, 1);
        ServiceConnection.DeleteAll(); // Cleanup
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestSetupPageSaveWithoutVATRegNo()
    var
        CompanyInformation: Record "Company Information";
        GovTalkSetup: TestPage "GovTalk Setup";
    begin
        // [GIVEN] GovTalk Setup record exists and company does not have VAT setup up
        LibraryLowerPermissions.SetO365Setup();
        LibraryVariableStorage.Enqueue(NoVatNoMsg);
        LibraryVariableStorage.Enqueue(ThirdPartyNoticeMsg);
        Initialize();

        CompanyInformation."VAT Registration No." := '';
        CompanyInformation.Modify();

        // [WHEN] GovTalk Setup page is edited
        GovTalkSetup.OpenEdit();
        GovTalkSetup.Username.Value('Username');
        GovTalkSetup.Password.Value('PWD');
        GovTalkSetup.OK().Invoke();

        // [THEN] message is shown to also add VAT Reg. No. in Company Information.
        // If not, there is an error because of unused handler
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetupPageCancelWithoutVATRegNo()
    var
        CompanyInformation: Record "Company Information";
        GovTalkSetup: TestPage "GovTalk Setup";
    begin
        // [GIVEN] GovTalk Setup record exists and company does not have VAT setup up
        LibraryLowerPermissions.SetO365Setup();
        Initialize();

        CompanyInformation."VAT Registration No." := '';
        CompanyInformation.Modify();

        // [WHEN] GovTalk Setup page is edited
        GovTalkSetup.OpenEdit();
        GovTalkSetup.Username.Value('Username');
        GovTalkSetup.Password.Value('PWD');
        GovTalkSetup.Cancel().Invoke();

        // [THEN] page closes, no warnings or errors
        // If not, there is an error because of unused handler
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestSetupPageSaveRecordIsValid()
    var
        GovTalkSetupRecord: Record "GovTalk Setup";
        GovTalkSetup: TestPage "GovTalk Setup";
    begin
        // [GIVEN] GovTalk Setup record exists and company does not have VAT setup up
        LibraryLowerPermissions.SetO365Setup();
        LibraryVariableStorage.Enqueue(ThirdPartyNoticeMsg);
        Initialize();

        // [WHEN] GovTalk Setup page is edited
        GovTalkSetup.OpenEdit();
        GovTalkSetup.Username.Value('Username');
        GovTalkSetup.Password.Value('PWD');
        GovTalkSetup.OK().Invoke();

        // [THEN] All values are stored successfully, 3rd party notice message is shown.
        GovTalkSetupRecord.FindFirst();
        Assert.AreEqual('Username', GovTalkSetupRecord.Username, 'Username is not set correctly');
        Assert.AreEqual('PWD', GovTalkSetupRecord.GetPassword(), 'Password is not set correctly');
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text)
    begin
        Assert.AreEqual(LibraryVariableStorage.DequeueText(), Message, 'Invalid message text.');
    end;

    local procedure Initialize()
    var
        GovTalkSetup: Record "GovTalk Setup";
        CompanyInformation: Record "Company Information";
    begin
        // Always recreate GovTalk Setup entry, to have clear values
        GovTalkSetup.DeleteAll();
        GovTalkSetup.Init();
        GovTalkSetup.Insert();

        CompanyInformation.DeleteAll();
        CompanyInformation.Init();
        CompanyInformation."VAT Registration No." := 'VAT NO';
        CompanyInformation.Insert();
    end;
}
#endif

