codeunit 134415 "Test OCR Service Setup"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [OCR Service]
    end;

    var
        Assert: Codeunit Assert;
        InvalidUriErr: Label 'The URL is not valid.';
        LibraryVariableStorage: Codeunit "Library - Variable Storage";

    [Test]
    [Scope('OnPrem')]
    procedure TestOcrSetupServiceUrlBlank()
    var
        OCRServiceSetup: Record "OCR Service Setup";
    begin
        // Init
        OCRServiceSetup.Init();

        // Execute
        OCRServiceSetup.Validate("Service URL", '');

        // Validate
        Assert.AreEqual('', OCRServiceSetup."Service URL", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOcrSetupServiceUrlInvalidUrl()
    var
        OCRServiceSetup: Record "OCR Service Setup";
    begin
        // Init
        OCRServiceSetup.Init();

        // Execute
        asserterror OCRServiceSetup.Validate("Service URL", 'http://this is an invalid url');

        // Validate
        Assert.ExpectedError(InvalidUriErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOcrSetupServiceUrlPositive()
    var
        OCRServiceSetup: Record "OCR Service Setup";
    begin
        // Init
        OCRServiceSetup.Init();

        // Execute
        OCRServiceSetup.Validate("Service URL", 'https://microsoft.com/');

        // Validate
        Assert.AreEqual('https://microsoft.com', OCRServiceSetup."Service URL", '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure TestOcrSetupServiceInsertDefault()
    var
        OCRServiceSetup: Record "OCR Service Setup";
        OCRServiceSetupCard: TestPage "OCR Service Setup";
    begin
        // Init
        if OCRServiceSetup.Get() then
            OCRServiceSetup.Delete(true);

        // Exectute
        OCRServiceSetupCard.OpenEdit();
        Assert.AreNotEqual('', OCRServiceSetupCard."Service URL".Value, '');
        OCRServiceSetupCard.SetURLsToDefault.Invoke();
        OCRServiceSetupCard.Close();

        // Validate
        OCRServiceSetup.Get();
        Assert.AreNotEqual('', OCRServiceSetup."Service URL", '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse')]
    [Scope('OnPrem')]
    procedure TestOcrSetupPagePassword()
    var
        OCRServiceSetup: Record "OCR Service Setup";
        OCRServiceSetupCard: TestPage "OCR Service Setup";
        PasswordTxt: Text;
        AuthTxt: Text;
    begin
        // Init
        if OCRServiceSetup.Get() then
            OCRServiceSetup.Delete(true);
        Assert.IsTrue(OCRServiceSetup.IsEmpty, '');
        PasswordTxt := Format(CreateGuid());
        AuthTxt := Format(CreateGuid());

        // Execute
        OCRServiceSetupCard.OpenEdit();
        OCRServiceSetupCard."User Name".Value := 'username';
        OCRServiceSetupCard.Password.Value := PasswordTxt;
        OCRServiceSetupCard.AuthorizationKey.VALUE := PasswordTxt; // To provoke an update of the Isolated Storage
        OCRServiceSetupCard.AuthorizationKey.Value := AuthTxt;    // ..
        OCRServiceSetupCard.Close();

        // Verify
        OCRServiceSetup.Get();
        Assert.IsTrue(OCRServiceSetup.HasPassword(OCRServiceSetup."Password Key"), '');
        Assert.IsTrue(OCRServiceSetup.HasPassword(OCRServiceSetup."Authorization Key"), '');
        AssertSecret(PasswordTxt, OCRServiceSetup.GetPasswordAsSecretText(OCRServiceSetup."Password Key"), '');
        AssertSecret(AuthTxt, OCRServiceSetup.GetPasswordAsSecretText(OCRServiceSetup."Authorization Key"), '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse')]
    [Scope('OnPrem')]
    procedure TestOcrSetupPagePasswordClear()
    var
        OCRServiceSetup: Record "OCR Service Setup";
        OCRServiceSetupCard: TestPage "OCR Service Setup";
        PasswordTxt: Text;
        AuthTxt: Text;
    begin
        // Init
        if OCRServiceSetup.Get() then
            OCRServiceSetup.Delete(true);
        Assert.IsTrue(OCRServiceSetup.IsEmpty, '');
        PasswordTxt := Format(CreateGuid());
        AuthTxt := Format(CreateGuid());

        // Execute
        OCRServiceSetupCard.OpenEdit();
        OCRServiceSetupCard."User Name".Value := 'username';
        OCRServiceSetupCard.Password.Value := PasswordTxt;
        OCRServiceSetupCard.Password.Value := '';
        OCRServiceSetupCard.AuthorizationKey.Value := AuthTxt;
        OCRServiceSetupCard.AuthorizationKey.Value := '';
        OCRServiceSetupCard.Close();

        // Verify
        OCRServiceSetup.Get();
        Assert.IsFalse(OCRServiceSetup.HasPassword(OCRServiceSetup."Password Key"), '');
        Assert.IsFalse(OCRServiceSetup.HasPassword(OCRServiceSetup."Authorization Key"), '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,PageHandlerOcrServiceSetup')]
    [Scope('OnPrem')]
    procedure TestOcrServiceMgtCheckCredentials()
    var
        OCRServiceSetup: Record "OCR Service Setup";
        OCRServiceMgt: Codeunit "OCR Service Mgt.";
    begin
        // Init
        if OCRServiceSetup.Delete(true) then;
        OCRServiceSetup.Init();
        OCRServiceSetup.Insert(true);

        // Execute
        asserterror OCRServiceMgt.CheckCredentials(); // triggers a confirm and page.runmodal

        // Verify
        Assert.AreEqual(OCRServiceMgt.GetCredentialsErrText(), GetLastErrorText, '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse')]
    [Scope('OnPrem')]
    procedure TestOcrServiceMgtCheckCredentialsMissing()
    var
        OCRServiceSetup: Record "OCR Service Setup";
        OCRServiceMgt: Codeunit "OCR Service Mgt.";
    begin
        // Init
        if OCRServiceSetup.Get() then
            OCRServiceSetup.Delete(true);

        // Execute
        asserterror OCRServiceMgt.CheckCredentials();  // triggers a confirm

        // Verify
        Assert.AreEqual(OCRServiceMgt.GetCredentialsErrText(), GetLastErrorText, '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalseWithTextValidation')]
    [Scope('OnPrem')]
    procedure TestOCRTextConstantsWhenNotConfirmed()
    var
        IncomingDocument: Record "Incoming Document";
        OCRServiceSetup: Record "OCR Service Setup";
        SendIncomingDocumentToOCR: Codeunit "Send Incoming Document to OCR";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 223653]

        if OCRServiceSetup.Delete(true) then;
        OCRServiceSetup.Init();
        OCRServiceSetup.Insert(true);

        LibraryVariableStorage.Enqueue('The OCR service is not enabled.\\Do you want to open the OCR Service Setup window?');
        SendIncomingDocumentToOCR.SendDocToOCR(IncomingDocument);
    end;

    [Test]
    [HandlerFunctions('PageHandlerOcrServiceSetup,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure TestOCRTextConstantsWhenConfirmed()
    var
        IncomingDocument: Record "Incoming Document";
        OCRServiceSetup: Record "OCR Service Setup";
        SendIncomingDocumentToOCR: Codeunit "Send Incoming Document to OCR";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 223653]

        if OCRServiceSetup.Delete(true) then;
        OCRServiceSetup.Init();
        OCRServiceSetup.Insert(true);

        asserterror SendIncomingDocumentToOCR.SendDocToOCR(IncomingDocument);
        Assert.ExpectedError('The OCR service is not enabled.');
    end;

    [NonDebuggable]
    local procedure AssertSecret(Expected: Text; Actual: SecretText; Message: Text)
    begin
        Assert.AreEqual(Expected, Actual.Unwrap(), Message);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerFalse(Question: Text[1024]; var Answer: Boolean)
    begin
        Answer := false;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerFalseWithTextValidation(Question: Text[1024]; var Answer: Boolean)
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Question);
        Answer := false;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Question: Text[1024]; var Answer: Boolean)
    begin
        Answer := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PageHandlerOcrServiceSetup(var OCRServiceSetup: TestPage "OCR Service Setup")
    begin
        OCRServiceSetup.OK().Invoke();
    end;
}

