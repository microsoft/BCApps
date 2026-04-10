codeunit 139470 "SaaS Login Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [SaaS] [Login]
    end;

    var
        Assert: Codeunit Assert;
        CanNotOpenCompanyFromDevicelMsg: Label 'Sorry, you can''t create a %1 from this device.', Comment = '%1 = Company Name';
        LibraryUtility: Codeunit "Library - Utility";
        EvalCompanyName: Text[30];
        Initialized: Boolean;

    local procedure Initialize()
    var
        TermsAndConditions: Record "Terms And Conditions";
        TermsAndConditionsState: Record "Terms And Conditions State";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
    begin
        TermsAndConditions.DeleteAll();
        TermsAndConditionsState.DeleteAll();

        if Initialized then
            exit;
        Initialized := true;

        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);

        CreateEvalCompany();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTrialDialogIsNotShownWhenOpeningAEvalCompany()
    var
        LogInManagement: Codeunit LogInManagement;
    begin
        // [SCENARIO 174427] When the user opens an evaluation company in SaaS, no dialog is shown

        // [GIVEN] A newly created evaluation company in SaaS
        Initialize();
        SetCompanyToEvaluation(true);

        // [WHEN] The user logs in
        LogInManagement.CompanyOpen();

        // [THEN] Loging accepted without a dialog
        // No ModalPageHandler needed
    end;

    [Test]
    [HandlerFunctions('ThirtyDayTrialDialogModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestTrialDialogIsShownWhenOpeningANonEvalCompany()
    var
        LogInManagement: Codeunit LogInManagement;
    begin
        // [SCENARIO 174427] When the user selects a non evaluation company as company in his/her settings in SaaS,
        // [SCENARIO] a dialog is shown informing him/her that a trial period will start

        // [GIVEN] A newly created company in SaaS
        Initialize();
        SetCompanyToEvaluation(false);

        // [WHEN] The user logs in
        LogInManagement.CompanyOpen();

        // [THEN] The 30 days trial dialog is shown
        // Handled through ModalPageHandler
    end;

    [Test]
    [HandlerFunctions('SessionSettingsHandler,OpeningCompMessageHandler,ChangeSessionSettingsConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestTrialDialogIsNotShownWhenOpeningANonEvalCompanyOnPhone()
    var
        LogInManagement: Codeunit LogInManagement;
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
    begin
        // [SCENARIO] When the user selects a non evaluation company as company in his/her settings in SaaS,
        // [SCENARIO] on a PHONE an error is shown and the user is moved back to a eval comp

        // [GIVEN] A newly created company in SaaS
        Initialize();
        SetCompanyToEvaluation(false);

        // [GIVEN] a phone client
        BindSubscription(TestClientTypeSubscriber);
        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Phone);

        // [WHEN] The user logs in
        asserterror LogInManagement.CompanyOpen();
        Assert.ExpectedError('');

        // [THEN] A message shown
        // Handled through MessageHandler
        // [THEN] The session is changed to the first eval company
        // Handled through SessionSettingsHandler
    end;

    [Test]
    [HandlerFunctions('SessionSettingsHandler,OpeningCompMessageHandler,ChangeSessionSettingsConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestTrialDialogIsNotShownWhenOpeningANonEvalCompanyOnTablet()
    var
        LogInManagement: Codeunit LogInManagement;
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
    begin
        // [SCENARIO] When the user selects a non evaluation company as company in his/her settings in SaaS,
        // [SCENARIO] on a TABLET an error is shown and the user is moved back to a eval comp

        // [GIVEN] A newly created company in SaaS
        Initialize();
        SetCompanyToEvaluation(false);

        // [GIVEN] a tablet client
        BindSubscription(TestClientTypeSubscriber);
        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Tablet);

        // [WHEN] The user logs in
        asserterror LogInManagement.CompanyOpen();
        Assert.ExpectedError('');

        // [THEN] A message shown
        // Handled through MessageHandler
        // [THEN] The session is changed to the first eval company
        // Handled through SessionSettingsHandler
    end;

    local procedure SetCompanyToEvaluation(IsEvaluationCompany: Boolean)
    var
        Company: Record Company;
    begin
        Company.Get(CompanyName);
        Company."Evaluation Company" := IsEvaluationCompany;
        Company.Modify();
    end;

    local procedure CreateEvalCompany()
    var
        Company: Record Company;
    begin
        EvalCompanyName := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Company.Name)), 1, MaxStrLen(Company.Name));
        Company.Name := EvalCompanyName;
        Company."Evaluation Company" := true;
        Company.Insert(true);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ThirtyDayTrialDialogModalPageHandler(var ThirtyDayTrialDialog: TestPage "Thirty Day Trial Dialog")
    begin
        ThirtyDayTrialDialog.ActionNext.Invoke();
        ThirtyDayTrialDialog.TermsAndConditionsCheckBox.SetValue(true);
        ThirtyDayTrialDialog.ActionStartTrial.Invoke();
    end;

    [SessionSettingsHandler]
    [Scope('OnPrem')]
    procedure SessionSettingsHandler(var TestSessionSettings: SessionSettings): Boolean
    begin
        Assert.AreEqual(EvalCompanyName, TestSessionSettings.Company, 'Wrong Company selected');
        exit(false);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure OpeningCompMessageHandler(Message: Text[1024])
    begin
        Assert.AreEqual(StrSubstNo(CanNotOpenCompanyFromDevicelMsg, CompanyName), Message, 'Unexpected Message');
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ChangeSessionSettingsConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

