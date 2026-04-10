codeunit 134780 "Test OAuth 2.0 UT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [OAuth 2.0] [UT]
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;
        TheURIIsNotSecureErr: Label 'The URI is not secure.';
        AuthRequiredNotificationMsg: Label 'Choose the Request Authorization Code action to complete the authorization process.';
        EncryptionIsNotActivatedQst: Label 'Data encryption is not activated. It is recommended that you encrypt data. \Do you want to open the Data Encryption Management window?';
        RequestAuthCodeTxt: Label 'Request authorization code.', Locked = true;
        ConfirmDeletingEntriesQst: Label 'Are you sure that you want to delete log entries?';
        DeletedMsg: Label 'The entries were deleted from the log.';

    [Scope('OnPrem')]
    procedure VerifyRemovedTokensAfterRecordDelete()
    var
        DummyOAuth20Setup: Record "OAuth 2.0 Setup";
    begin
        // [SCENARIO 258181] Verify tokens are removed from IsolatedStorage after delete record 1140 "OAuth 2.0 Setup"
        Initialize();

        VerifyRemovedTokensAfterRecordDeleteForTokenScope(DummyOAuth20Setup."Token DataScope"::Company);
        VerifyRemovedTokensAfterRecordDeleteForTokenScope(DummyOAuth20Setup."Token DataScope"::Module);
        VerifyRemovedTokensAfterRecordDeleteForTokenScope(DummyOAuth20Setup."Token DataScope"::User);
        VerifyRemovedTokensAfterRecordDeleteForTokenScope(DummyOAuth20Setup."Token DataScope"::UserAndCompany);
    end;

    [Test]
    [Scope('OnPrem')]
    [NonDebuggable]
    procedure GetAuthorizationURL()
    var
        OAuth20Setup: Record "OAuth 2.0 Setup";
        OAuth20Mgt: Codeunit "OAuth 2.0 Mgt.";
    begin
        // [FEATURE] [Authorization]
        // [SCENARIO 258181] COD 1140 "OAuth 2.0 Mgt.".GetAuthorizationURL()
        Initialize();
        CreateOAuthSetup(OAuth20Setup);

        Assert.AreEqual(
          GetAuthorizationURLString(OAuth20Setup),
          OAuth20Mgt.GetAuthorizationURLAsSecretText(OAuth20Setup, OAuth20Setup.GetTokenAsSecretText(OAuth20Setup."Client ID").Unwrap()).Unwrap(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    [NonDebuggable]
    procedure HttpLog_GetAuthorizationURL()
    var
        OAuth20Setup: Record "OAuth 2.0 Setup";
        OAuth20Mgt: Codeunit "OAuth 2.0 Mgt.";
    begin
        // [FEATURE] [Http Log] [Authorization]
        // [SCENARIO 258181] COD 1140 "OAuth 2.0 Mgt.".GetAuthorizationURL() with a success result in Http Log
        Initialize();
        CreateOAuthSetup(OAuth20Setup);

        OAuth20Mgt.GetAuthorizationURLAsSecretText(OAuth20Setup, OAuth20Setup.GetTokenAsSecretText((OAuth20Setup."Client ID")).Unwrap());

        VerifyHttpLog(OAuth20Setup, true, RequestAuthCodeTxt, '');
        VerifyHttpLogWithBlankedDetails(OAuth20Setup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SecureServiceURL()
    var
        OAuth20Setup: Record "OAuth 2.0 Setup";
    begin
        // [SCENARIO 258181] TAB 1140 "OAuth 2.0 Setup" validation of "Service URL" verifies secure URL
        Initialize();
        CreateOAuthSetup(OAuth20Setup);

        asserterror OAuth20Setup.Validate("Service URL", 'http://test');

        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(TheURIIsNotSecureErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AppendPath_Authorization()
    var
        OAuth20Setup: Record "OAuth 2.0 Setup";
    begin
        // [SCENARIO 258181] TAB 1140 "OAuth 2.0 Setup" validation of "Authorization URL Path" appends slash
        Initialize();
        CreateOAuthSetup(OAuth20Setup);

        OAuth20Setup.Validate("Authorization URL Path", 'test1');
        Assert.AreEqual('/test1', OAuth20Setup."Authorization URL Path", '');

        OAuth20Setup.Validate("Authorization URL Path", '/test2');
        Assert.AreEqual('/test2', OAuth20Setup."Authorization URL Path", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AppendPath_AccessToken()
    var
        OAuth20Setup: Record "OAuth 2.0 Setup";
    begin
        // [SCENARIO 258181] TAB 1140 "OAuth 2.0 Setup" validation of "Access Token URL Path" appends slash
        Initialize();
        CreateOAuthSetup(OAuth20Setup);

        OAuth20Setup.Validate("Access Token URL Path", 'test1');
        Assert.AreEqual('/test1', OAuth20Setup."Access Token URL Path", '');

        OAuth20Setup.Validate("Access Token URL Path", '/test2');
        Assert.AreEqual('/test2', OAuth20Setup."Access Token URL Path", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AppendPath_RefreshToken()
    var
        OAuth20Setup: Record "OAuth 2.0 Setup";
    begin
        // [SCENARIO 258181] TAB 1140 "OAuth 2.0 Setup" validation of "Refresh Token URL Path" appends slash
        Initialize();
        CreateOAuthSetup(OAuth20Setup);

        OAuth20Setup.Validate("Refresh Token URL Path", 'test1');
        Assert.AreEqual('/test1', OAuth20Setup."Refresh Token URL Path", '');

        OAuth20Setup.Validate("Refresh Token URL Path", '/test2');
        Assert.AreEqual('/test2', OAuth20Setup."Refresh Token URL Path", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UI_FieldsAndActionsVisibility_OnPrem()
    var
        OAuth20Setup: Record "OAuth 2.0 Setup";
        OAuth20SetupPage: TestPage "OAuth 2.0 Setup";
    begin
        // [FEATURE] [UI] [OnPrem]
        // [SCENARIO 258181] PAG 1140 "OAuth 2.0 Setup" fields and actions visibility in case of OnPrem
        Initialize();
        CreateOAuthSetup(OAuth20Setup);

        OpenOAuthSetupPage(OAuth20SetupPage, OAuth20Setup);
        Assert.IsTrue(OAuth20SetupPage."Service URL".Visible(), 'Service URL should be visible for OnPrem');
        Assert.IsTrue(OAuth20SetupPage.Description.Visible(), 'Description should be visible for OnPrem');
        Assert.IsTrue(OAuth20SetupPage."Redirect URL".Visible(), 'Redirect URL should be visible for OnPrem');
        Assert.IsTrue(OAuth20SetupPage.Scope.Visible(), 'Scope should be visible for OnPrem');
        Assert.IsTrue(OAuth20SetupPage."Authorization URL Path".Visible(), 'Authorization URL Path should be visible for OnPrem');
        Assert.IsTrue(OAuth20SetupPage."Access Token URL Path".Visible(), 'Access Token URL Path should be visible for OnPrem');
        Assert.IsTrue(OAuth20SetupPage."Refresh Token URL Path".Visible(), 'Refresh Token URL Path should be visible for OnPrem');
        Assert.IsTrue(OAuth20SetupPage.EncryptionManagement.Visible(), 'Encryption Management should be visible for OnPrem');
        Assert.IsTrue(OAuth20SetupPage.RequestAuthorizationCode.Visible(), 'Request Authorization Code should be visible for OnPrem');
        Assert.IsTrue(OAuth20SetupPage.RefreshAccessToken.Visible(), 'Refresh Access Token should be visible for OnPrem');
        Assert.IsTrue(OAuth20SetupPage.HttpLog.Visible(), 'Http Log should be visible for OnPrem');
        OAuth20SetupPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UI_FieldsAndActionsVisibility_SaaS()
    var
        OAuth20Setup: Record "OAuth 2.0 Setup";
        OAuth20SetupPage: TestPage "OAuth 2.0 Setup";
    begin
        // [FEATURE] [UI] [SaaS]
        // [SCENARIO 258181] PAG 1140 "OAuth 2.0 Setup" fields and actions visibility in case of SaaS
        Initialize();
        EnableSaaS(true);

        CreateOAuthSetup(OAuth20Setup);
        OpenOAuthSetupPage(OAuth20SetupPage, OAuth20Setup);
        Assert.IsTrue(OAuth20SetupPage."Service URL".Visible(), 'Service URL should be visible for SaaS');
        Assert.IsTrue(OAuth20SetupPage.Description.Visible(), 'Description should be visible for SaaS');
        Assert.IsTrue(OAuth20SetupPage."Redirect URL".Visible(), 'Redirect URL should be visible for SaaS');
        Assert.IsTrue(OAuth20SetupPage.Scope.Visible(), 'Scope should be visible for SaaS');
        Assert.IsTrue(OAuth20SetupPage."Authorization URL Path".Visible(), 'Authorization URL Path should be visible for SaaS');
        Assert.IsTrue(OAuth20SetupPage."Access Token URL Path".Visible(), 'Access Token URL Path should be visible for SaaS');
        Assert.IsTrue(OAuth20SetupPage."Refresh Token URL Path".Visible(), 'Refresh Token URL Path should be visible for SaaS');
        Assert.IsFalse(OAuth20SetupPage.EncryptionManagement.Visible(), 'Encryption Management should not be visible for SaaS');
        Assert.IsTrue(OAuth20SetupPage.RequestAuthorizationCode.Visible(), 'Request Authorization Code should be visible for SaaS');
        Assert.IsTrue(OAuth20SetupPage.RefreshAccessToken.Visible(), 'Refresh Access Token should be visible for SaaS');
        Assert.IsTrue(OAuth20SetupPage.HttpLog.Visible(), 'Http Log should be visible for SaaS');
        OAuth20SetupPage.Close();
        EnableSaaS(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UI_EnterAuthorizationCodeIsNotVisibleForEnabledSetup()
    var
        OAuth20Setup: Record "OAuth 2.0 Setup";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 258181] PAG 1140 "OAuth 2.0 Setup" field "Enter Authorization Code" should not be visible in case of Status = [Enabled, Connected, <blanked>]
        Initialize();

        CreateCustomOAuthSetup(OAuth20Setup, OAuth20Setup.Status::" ");
        VerifyPageFieldEnterAuthorizationCodeIsNotVisible(OAuth20Setup);

        CreateCustomOAuthSetup(OAuth20Setup, OAuth20Setup.Status::Enabled);
        VerifyPageFieldEnterAuthorizationCodeIsNotVisible(OAuth20Setup);

        CreateCustomOAuthSetup(OAuth20Setup, OAuth20Setup.Status::Connected);
        VerifyPageFieldEnterAuthorizationCodeIsNotVisible(OAuth20Setup);
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler')]
    [Scope('OnPrem')]
    procedure UI_EnterAuthorizationCodeAndNotificationAreVisibleForDisabledSetup()
    var
        OAuth20Setup: Record "OAuth 2.0 Setup";
    begin
        // [FEATURE] [UI] [Notification]
        // [SCENARIO 258181] PAG 1140 "OAuth 2.0 Setup" field "Enter Authorization Code" should be visible in case of Status = Disabled,
        // [SCENARIO 258181] notification about required authorization is shown
        Initialize();

        CreateCustomOAuthSetup(OAuth20Setup, OAuth20Setup.Status::Disabled);
        VerifyPageFieldEnterAuthorizationCodeIsVisible(OAuth20Setup);

        Assert.ExpectedMessage(AuthRequiredNotificationMsg, LibraryVariableStorage.DequeueText()); // Notification message
        Assert.ExpectedMessage(OAuth20Setup.Code, LibraryVariableStorage.DequeueText()); // Notification data
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler')]
    [Scope('OnPrem')]
    procedure UI_EnterAuthorizationCodeAndNotificationAreVisibleForErrorSetup()
    var
        OAuth20Setup: Record "OAuth 2.0 Setup";
    begin
        // [FEATURE] [UI] [Notification]
        // [SCENARIO 258181] PAG 1140 "OAuth 2.0 Setup" field "Enter Authorization Code" should be visible in case of Status = Error,
        // [SCENARIO 258181] notification about required authorization is shown
        Initialize();

        CreateCustomOAuthSetup(OAuth20Setup, OAuth20Setup.Status::Error);
        VerifyPageFieldEnterAuthorizationCodeIsVisible(OAuth20Setup);

        Assert.ExpectedMessage(AuthRequiredNotificationMsg, LibraryVariableStorage.DequeueText()); // Notification message
        Assert.ExpectedMessage(OAuth20Setup.Code, LibraryVariableStorage.DequeueText()); // Notification data
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,HyperlinkHandler')]
    [Scope('OnPrem')]
    procedure UI_RequestAuthCodeForEnabledSetup_OnPem_EncryptionConfirmNo()
    var
        OAuth20Setup: Record "OAuth 2.0 Setup";
        OAuth20SetupPage: TestPage "OAuth 2.0 Setup";
    begin
        // [FEATURE] [UI] [OnPrem]
        // [SCENARIO 258181] PAG 1140 "OAuth 2.0 Setup" action "Request Authorization Code" for Enabled setup in case of OnPrem
        // [SCENARIO 258181] suggest to open "Encryption Management" (deny open), shows "Enter Authorization Code", opens hyperlink
        Initialize();
        CreateOAuthSetup(OAuth20Setup);
        OpenOAuthSetupPage(OAuth20SetupPage, OAuth20Setup);

        LibraryVariableStorage.Enqueue(false); // Deny open Encryption Management
        OAuth20SetupPage.RequestAuthorizationCode.Invoke();

        Assert.IsTrue(
          OAuth20SetupPage."Enter Authorization Code".Visible(),
          'Enter Authorization Code should be visible for Enabled setup after invoke Request Authorization Code');
        OAuth20SetupPage.Close();

        Assert.ExpectedMessage(EncryptionIsNotActivatedQst, LibraryVariableStorage.DequeueText()); // suggest to open "Encryption Management"
        Assert.ExpectedMessage(GetAuthorizationURLString(OAuth20Setup), LibraryVariableStorage.DequeueText()); // hyperlink
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,DataEncryptionManagement_MPH,HyperlinkHandler')]
    [Scope('OnPrem')]
    procedure UI_RequestAuthCodeForEnabledSetup_OnPem_EncryptionConfirmYes()
    var
        OAuth20Setup: Record "OAuth 2.0 Setup";
        OAuth20SetupPage: TestPage "OAuth 2.0 Setup";
    begin
        // [FEATURE] [UI] [OnPrem]
        // [SCENARIO 258181] PAG 1140 "OAuth 2.0 Setup" action "Request Authorization Code" for Enabled setup in case of OnPrem
        // [SCENARIO 258181] suggest to open "Encryption Management" (accept open), shows "Enter Authorization Code", opens hyperlink
        Initialize();
        CreateOAuthSetup(OAuth20Setup);
        OpenOAuthSetupPage(OAuth20SetupPage, OAuth20Setup);

        LibraryVariableStorage.Enqueue(true); // Accept open Encryption Management
        OAuth20SetupPage.RequestAuthorizationCode.Invoke();

        Assert.IsTrue(
          OAuth20SetupPage."Enter Authorization Code".Visible(),
          'Enter Authorization Code should be visible for Enabled setup after invoke Request Authorization Code');
        OAuth20SetupPage.Close();

        Assert.ExpectedMessage(EncryptionIsNotActivatedQst, LibraryVariableStorage.DequeueText()); // suggest to open "Encryption Management"
        Assert.ExpectedMessage(GetAuthorizationURLString(OAuth20Setup), LibraryVariableStorage.DequeueText()); // hyperlink
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('HyperlinkHandler')]
    [Scope('OnPrem')]
    procedure UI_RequestAuthCodeForEnabledSetup_SaaS()
    var
        OAuth20Setup: Record "OAuth 2.0 Setup";
        OAuth20SetupPage: TestPage "OAuth 2.0 Setup";
    begin
        // [FEATURE] [UI] [SaaS]
        // [SCENARIO 258181] PAG 1140 "OAuth 2.0 Setup" action "Request Authorization Code" for Enabled setup in case of SaaS
        // [SCENARIO 258181] shows "Enter Authorization Code", opens hyperlink
        Initialize();
        EnableSaaS(true);
        CreateOAuthSetup(OAuth20Setup);
        OpenOAuthSetupPage(OAuth20SetupPage, OAuth20Setup);

        OAuth20SetupPage.RequestAuthorizationCode.Invoke();

        Assert.IsTrue(
          OAuth20SetupPage."Enter Authorization Code".Visible(),
          'Enter Authorization Code should be visible for Enabled setup after invoke Request Authorization Code');
        OAuth20SetupPage.Close();

        Assert.ExpectedMessage(GetAuthorizationURLString(OAuth20Setup), LibraryVariableStorage.DequeueText()); // hyperlink
        LibraryVariableStorage.AssertEmpty();
        EnableSaaS(false);
    end;

    [Test]
    [HandlerFunctions('HttpLog_MPH')]
    [Scope('OnPrem')]
    [NonDebuggable]
    procedure UI_HttpLog()
    var
        OAuth20Setup: Record "OAuth 2.0 Setup";
        OAuth20Mgt: Codeunit "OAuth 2.0 Mgt.";
        OAuth20SetupPage: TestPage "OAuth 2.0 Setup";
    begin
        // [FEATURE] [UI] [Http Log]
        // [SCENARIO 258181] PAG 1140 "OAuth 2.0 Setup" action "Http Log" opens Activity Log page for the current OAuth Setup
        Initialize();
        CreateOAuthSetup(OAuth20Setup);
        OAuth20Mgt.GetAuthorizationURLAsSecretText(OAuth20Setup, OAuth20Setup.GetTokenAsSecretText((OAuth20Setup."Client ID")).Unwrap());

        OpenOAuthSetupPage(OAuth20SetupPage, OAuth20Setup);
        OAuth20SetupPage.HttpLog.Invoke();
        OAuth20SetupPage.Close();

        Assert.AreEqual(Format(OAuth20Setup.RecordId()), LibraryVariableStorage.DequeueText(), ''); // Record ID filter
        Assert.AreEqual(StrSubstNo('OAuth 2.0 %1', OAuth20Setup.Code), LibraryVariableStorage.DequeueText(), ''); // Context
        Assert.AreEqual(RequestAuthCodeTxt, LibraryVariableStorage.DequeueText(), ''); // Description
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UI_PageIsNotEditable()
    var
        OAuth20Setup: Record "OAuth 2.0 Setup";
        OAuth20SetupPage: TestPage "OAuth 2.0 Setup";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 316966] PAG 1140 "OAuth 2.0 Setup" fields are not Editable() by default
        Initialize();
        CreateOAuthSetup(OAuth20Setup);
        OpenOAuthSetupPage(OAuth20SetupPage, OAuth20Setup);
        Assert.IsFalse(OAuth20SetupPage.Description.Editable(), 'Description field should be not Editable()');
        Assert.IsFalse(OAuth20SetupPage."Service URL".Editable(), 'Service URL field should be not Editable()');
        Assert.IsFalse(OAuth20SetupPage."Redirect URL".Editable(), 'Redirect URL field should be not Editable()');
        Assert.IsFalse(OAuth20SetupPage."Authorization URL Path".Editable(), 'Authorization URL Path field should be not Editable()');
        Assert.IsFalse(OAuth20SetupPage."Access Token URL Path".Editable(), 'Access Token URL Path field should be not Editable()');
        Assert.IsFalse(OAuth20SetupPage."Refresh Token URL Path".Editable(), 'Refresh Token URL Path field should be not Editable()');
        Assert.IsFalse(OAuth20SetupPage.Scope.Editable(), 'Scope field should be not Editable()');
        OAuth20SetupPage.Close();
    end;

    [Test]
    [HandlerFunctions('HttpLogDelete7_MPH,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure HttpLogConfirmDeleteEntriesOlderThan7Days()
    var
        OAuth20Setup: Record "OAuth 2.0 Setup";
        ActivityLog: Record "Activity Log";
        OAuth20SetupPage: TestPage "OAuth 2.0 Setup";
    begin
        // [FEATURE] [UI] [Http Log]
        // [SCENARIO 316966] Http Log entries confirm "Delete Entries Older Than 7 Days" action
        Initialize();
        CreateOAuthSetup(OAuth20Setup);
        MockHttpLogEntries(OAuth20Setup, Today());
        LibraryVariableStorage.Enqueue(true); // confirm delete log entries

        OpenOAuthSetupPage(OAuth20SetupPage, OAuth20Setup);
        OAuth20SetupPage.HttpLog.Invoke();
        OAuth20SetupPage.Close();

        Assert.ExpectedMessage(ConfirmDeletingEntriesQst, LibraryVariableStorage.DequeueText());
        Assert.ExpectedMessage(DeletedMsg, LibraryVariableStorage.DequeueText());
        ActivityLog.SetRange("Record ID", OAuth20Setup.RecordId());
        Assert.RecordCount(ActivityLog, 1);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('HttpLogDelete0_MPH,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure HttpLogConfirmDeleteAllEntries()
    var
        OAuth20Setup: Record "OAuth 2.0 Setup";
        ActivityLog: Record "Activity Log";
        OAuth20SetupPage: TestPage "OAuth 2.0 Setup";
    begin
        // [FEATURE] [UI] [Http Log]
        // [SCENARIO 316966] Http Log entries confirm "Delete All Entries" action
        Initialize();
        CreateOAuthSetup(OAuth20Setup);
        MockHttpLogEntries(OAuth20Setup, Today());
        LibraryVariableStorage.Enqueue(true); // confirm delete log entries

        OpenOAuthSetupPage(OAuth20SetupPage, OAuth20Setup);
        OAuth20SetupPage.HttpLog.Invoke();
        OAuth20SetupPage.Close();

        Assert.ExpectedMessage(ConfirmDeletingEntriesQst, LibraryVariableStorage.DequeueText());
        Assert.ExpectedMessage(DeletedMsg, LibraryVariableStorage.DequeueText());
        ActivityLog.SetRange("Record ID", OAuth20Setup.RecordId());
        Assert.RecordCount(ActivityLog, 0);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('HttpLogDelete7_MPH,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure HttpLogDenyDeleteEntriesOlderThan7Days()
    var
        OAuth20Setup: Record "OAuth 2.0 Setup";
        ActivityLog: Record "Activity Log";
        OAuth20SetupPage: TestPage "OAuth 2.0 Setup";
    begin
        // [FEATURE] [UI] [Http Log]
        // [SCENARIO 316966] Http Log entries deny "Delete Entries Older Than 7 Days" action
        Initialize();
        CreateOAuthSetup(OAuth20Setup);
        MockHttpLogEntries(OAuth20Setup, Today());
        LibraryVariableStorage.Enqueue(false); // deny delete log entries

        OpenOAuthSetupPage(OAuth20SetupPage, OAuth20Setup);
        OAuth20SetupPage.HttpLog.Invoke();
        OAuth20SetupPage.Close();

        Assert.ExpectedMessage(ConfirmDeletingEntriesQst, LibraryVariableStorage.DequeueText());
        ActivityLog.SetRange("Record ID", OAuth20Setup.RecordId());
        Assert.RecordCount(ActivityLog, 2);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('HttpLogDelete0_MPH,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure HttpLogDenyDeleteAllEntries()
    var
        OAuth20Setup: Record "OAuth 2.0 Setup";
        ActivityLog: Record "Activity Log";
        OAuth20SetupPage: TestPage "OAuth 2.0 Setup";
    begin
        // [FEATURE] [UI] [Http Log]
        // [SCENARIO 316966] Http Log entries dney "Delete All Entries" action
        Initialize();
        CreateOAuthSetup(OAuth20Setup);
        MockHttpLogEntries(OAuth20Setup, Today());
        LibraryVariableStorage.Enqueue(false); // deny delete log entries

        OpenOAuthSetupPage(OAuth20SetupPage, OAuth20Setup);
        OAuth20SetupPage.HttpLog.Invoke();
        OAuth20SetupPage.Close();

        Assert.ExpectedMessage(ConfirmDeletingEntriesQst, LibraryVariableStorage.DequeueText());
        ActivityLog.SetRange("Record ID", OAuth20Setup.RecordId());
        Assert.RecordCount(ActivityLog, 2);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [NonDebuggable]
    [Scope('OnPrem')]
    procedure GetAuthorizationURLWithCodeChallenge()
    var
        OAuth20Setup: Record "OAuth 2.0 Setup";
        OAuth20Mgt: Codeunit "OAuth 2.0 Mgt.";
        ActualURL: Text;
    begin
        // [FEATURE] [Authorization]
        // [SCENARIO 498271] Authorization URL contains a code challenge
        Initialize();
        CreateOAuthSetup(OAuth20Setup);
        OAuth20Setup.Validate("Code Challenge Method", OAuth20Setup."Code Challenge Method"::S256);
        OAuth20Setup.Modify(true);

        ActualURL := OAuth20Mgt.GetAuthorizationURLAsSecretText(OAuth20Setup, OAuth20Setup.GetTokenAsSecretText(OAuth20Setup."Client ID").Unwrap()).Unwrap();
        Assert.IsTrue(StrPos(ActualURL, 'code_challenge_method=S256') > 0, 'Url does not contain a code challenge');
        OAuth20Setup.Find();
        Assert.IsTrue(OAuth20Setup.GetTokenAsSecretText(OAuth20Setup."Code Verifier").Unwrap() <> '', 'Code verifier is empty');
    end;

    [Test]
    [NonDebuggable]
    [Scope('OnPrem')]
    procedure GetAuthorizationURLWithNonce()
    var
        OAuth20Setup: Record "OAuth 2.0 Setup";
        OAuth20Mgt: Codeunit "OAuth 2.0 Mgt.";
        ActualURL: Text;
    begin
        // [FEATURE] [Authorization]
        // [SCENARIO 498271] Authorization URL contains a nonce
        Initialize();
        CreateOAuthSetup(OAuth20Setup);
        OAuth20Setup.Validate("Use Nonce", true);
        OAuth20Setup.Modify(true);

        ActualURL := OAuth20Mgt.GetAuthorizationURLAsSecretText(OAuth20Setup, OAuth20Setup.GetTokenAsSecretText(OAuth20Setup."Client ID").Unwrap()).Unwrap();
        Assert.IsTrue(StrPos(ActualURL, 'nonce=') > 0, 'Url does not contain a nonce');
    end;

    local procedure Initialize()
    begin
        EnableSaaS(false);
        LibraryVariableStorage.Clear();

        if IsInitialized then
            exit;
        IsInitialized := true;
    end;

    local procedure EnableSaaS(IsSaaS: Boolean)
    var
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
    begin
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(IsSaaS);
    end;

    local procedure CreateOAuthSetup(var OAuth20Setup: Record "OAuth 2.0 Setup")
    begin
        CreateCustomOAuthSetup(OAuth20Setup, OAuth20Setup.Status::Enabled);
    end;

    local procedure CreateCustomOAuthSetup(var OAuth20Setup: Record "OAuth 2.0 Setup"; NewStatus: Option)
    begin
        OAuth20Setup.Code := LibraryUtility.GenerateGUID();
        OAuth20Setup.Status := NewStatus;
        OAuth20Setup.Description := LibraryUtility.GenerateGUID();
        OAuth20Setup."Service URL" := 'https://TestServiceURL';
        OAuth20Setup."Redirect URL" := 'https://TestRedirectURL';
        OAuth20Setup.Scope := LibraryUtility.GenerateGUID();
        OAuth20Setup."Authorization URL Path" := '/TestAuthorizationURLPath';
        OAuth20Setup."Access Token URL Path" := '/TestAccessTokenURLPath';
        OAuth20Setup."Refresh Token URL Path" := '/TestRefreshTokenURLPath';
        OAuth20Setup."Authorization Response Type" := LibraryUtility.GenerateGUID();
        OAuth20Setup."Token DataScope" := OAuth20Setup."Token DataScope"::Company;
        SetOAuthSetupTestTokens(OAuth20Setup);
        OAuth20Setup.Insert();
    end;

    local procedure CreateCustomOAuthSetupWithTokenScope(var OAuth20Setup: Record "OAuth 2.0 Setup"; NewTokenDataScope: Option)
    begin
        OAuth20Setup.Code := LibraryUtility.GenerateGUID();
        OAuth20Setup."Token DataScope" := NewTokenDataScope;
        SetOAuthSetupTestTokens(OAuth20Setup);
        OAuth20Setup.Insert();
    end;

    local procedure MockHttpLogEntries(OAuth20Setup: Record "OAuth 2.0 Setup"; CurrentDate: Date);
    begin
        MockActivityLogEntry(OAuth20Setup, CreateDateTime(CurrentDate, 0T));
        MockActivityLogEntry(OAuth20Setup, CreateDateTime(CurrentDate - 8, 0T));
    end;

    local procedure MockActivityLogEntry(OAuth20Setup: Record "OAuth 2.0 Setup"; LogDateTime: DateTime);
    VAR
        ActivityLog: Record "Activity Log";
    begin
        ActivityLog.LogActivity(OAuth20Setup, ActivityLog.Status::Success, 'Context', 'Description', 'Message');
        ActivityLog."Activity Date" := LogDateTime;
        ActivityLog.Modify();
    end;

    local procedure OpenOAuthSetupPage(var OAuth20SetupPage: TestPage "OAuth 2.0 Setup"; OAuth20Setup: Record "OAuth 2.0 Setup")
    begin
        OAuth20SetupPage.Trap();
        Page.Run(Page::"OAuth 2.0 Setup", OAuth20Setup);
    end;

    [NonDebuggable]
    local procedure GetAuthorizationURLString(OAuth20Setup: Record "OAuth 2.0 Setup"): Text
    begin
        exit(
              StrSubstNo(
                '%1%2?response_type=%3&client_id=%4&scope=%5&redirect_uri=%6',
                OAuth20Setup."Service URL", OAuth20Setup."Authorization URL Path", OAuth20Setup."Authorization Response Type",
                OAuth20Setup.GetTokenAsSecretText(OAuth20Setup."Client ID").Unwrap(), OAuth20Setup.Scope, OAuth20Setup."Redirect URL"));
    end;

    local procedure SetOAuthSetupTestTokens(var OAuth20Setup: Record "OAuth 2.0 Setup")
    var
        ClientID: Text;
        ClientSecret: Text;
        AccessToken: Text;
        RefreshToken: Text;
    begin
        ClientID := 'Dummy Test Client ID';
        ClientSecret := 'Dummy Test Client Secret';
        AccessToken := 'Dummy Test Access Token';
        RefreshToken := 'Dummy Test Refresh Token';

        OAuth20Setup.SetToken(OAuth20Setup."Client ID", ClientID);
        OAuth20Setup.SetToken(OAuth20Setup."Client Secret", ClientSecret);
        OAuth20Setup.SetToken(OAuth20Setup."Access Token", AccessToken);
        OAuth20Setup.SetToken(OAuth20Setup."Refresh Token", RefreshToken);
    end;

    local procedure VerifyRemovedTokensAfterRecordDeleteForTokenScope(OAuthSetupTokenDataScope: Option)
    var
        OAuth20Setup: Record "OAuth 2.0 Setup";
        TokenDataScope: DataScope;
    begin
        CreateCustomOAuthSetupWithTokenScope(OAuth20Setup, OAuthSetupTokenDataScope);

        TokenDataScope := OAuth20Setup.GetTokenDataScope();
        Assert.IsTrue(ISOLATEDSTORAGE.Contains(OAuth20Setup."Client ID", TokenDataScope), '');
        Assert.IsTrue(ISOLATEDSTORAGE.Contains(OAuth20Setup."Client Secret", TokenDataScope), '');
        Assert.IsTrue(ISOLATEDSTORAGE.Contains(OAuth20Setup."Access Token", TokenDataScope), '');
        Assert.IsTrue(ISOLATEDSTORAGE.Contains(OAuth20Setup."Refresh Token", TokenDataScope), '');

        OAuth20Setup.Delete(true);

        Assert.IsFalse(ISOLATEDSTORAGE.Contains(OAuth20Setup."Client ID", TokenDataScope), '');
        Assert.IsFalse(ISOLATEDSTORAGE.Contains(OAuth20Setup."Client Secret", TokenDataScope), '');
        Assert.IsFalse(ISOLATEDSTORAGE.Contains(OAuth20Setup."Access Token", TokenDataScope), '');
        Assert.IsFalse(ISOLATEDSTORAGE.Contains(OAuth20Setup."Refresh Token", TokenDataScope), '');
    end;

    local procedure VerifyPageFieldEnterAuthorizationCodeIsNotVisible(OAuth20Setup: Record "OAuth 2.0 Setup")
    var
        OAuth20SetupPage: TestPage "OAuth 2.0 Setup";
    begin
        OpenOAuthSetupPage(OAuth20SetupPage, OAuth20Setup);
        Assert.IsFalse(
          OAuth20SetupPage."Enter Authorization Code".Visible(),
          'Enter Authorization Code should not be visible in case of Status = [Enabled, Connected, <blanked>]');
        OAuth20SetupPage.Close();
    end;

    local procedure VerifyPageFieldEnterAuthorizationCodeIsVisible(OAuth20Setup: Record "OAuth 2.0 Setup")
    var
        OAuth20SetupPage: TestPage "OAuth 2.0 Setup";
    begin
        OpenOAuthSetupPage(OAuth20SetupPage, OAuth20Setup);
        Assert.IsTrue(
          OAuth20SetupPage."Enter Authorization Code".Visible(),
          'Enter Authorization Code should be visible in case of Status = [Disabled, Error]');
        OAuth20SetupPage.Close();
    end;

    local procedure VerifyHttpLog(OAuth20Setup: Record "OAuth 2.0 Setup"; ExpectedStatusBool: Boolean; ExpectedDescription: Text[250]; ExpectedActivityMessage: Text[250])
    var
        ActivityLog: Record "Activity Log";
        ExpectedStatusOption: Option;
    begin
        OAuth20Setup.Find();
        if ExpectedStatusBool then
            ExpectedStatusOption := ActivityLog.Status::Success
        else
            ExpectedStatusOption := ActivityLog.Status::Failed;

        ActivityLog.Get(OAuth20Setup."Activity Log ID");
        ActivityLog.TestField(Status, ExpectedStatusOption);
        ActivityLog.TestField(Context, StrSubstNo('OAuth 2.0 %1', OAuth20Setup.Code));
        ActivityLog.TestField(Description, ExpectedDescription);
        ActivityLog.TestField("Activity Message", ExpectedActivityMessage);
    end;

    local procedure VerifyHttpLogWithBlankedDetails(OAuth20Setup: Record "OAuth 2.0 Setup")
    var
        ActivityLog: Record "Activity Log";
    begin
        OAuth20Setup.Find();
        ActivityLog.Get(OAuth20Setup."Activity Log ID");
        ActivityLog.CalcFields("Detailed Info");
        Assert.IsFalse(ActivityLog."Detailed Info".HasValue(), '');
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SendNotificationHandler(var TheNotification: Notification): Boolean
    var
        DummyOAuth20Setup: Record "OAuth 2.0 Setup";
    begin
        LibraryVariableStorage.Enqueue(TheNotification.Message());
        LibraryVariableStorage.Enqueue(TheNotification.GetData(DummyOAuth20Setup.FieldName(Code)));
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        LibraryVariableStorage.Enqueue(Message);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := LibraryVariableStorage.DequeueBoolean();
        LibraryVariableStorage.Enqueue(Question);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DataEncryptionManagement_MPH(var DataEncryptionMgt: TestPage "Data Encryption Management")
    begin
    end;

    [HyperlinkHandler]
    [Scope('OnPrem')]
    procedure HyperlinkHandler(Message: Text[1024])
    begin
        LibraryVariableStorage.Enqueue(Message);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure HttpLog_MPH(var ActivityLog: TestPage "Activity Log")
    begin
        LibraryVariableStorage.Enqueue(ActivityLog.Filter.GetFilter("Record ID"));
        LibraryVariableStorage.Enqueue(ActivityLog.Context.Value());
        LibraryVariableStorage.Enqueue(ActivityLog.Description.Value());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure HttpLogDelete7_MPH(var ActivityLog: TestPage "Activity Log")
    begin
        ActivityLog.Delete7days.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure HttpLogDelete0_MPH(var ActivityLog: TestPage "Activity Log")
    begin
        ActivityLog.Delete0days.Invoke();
    end;
}

