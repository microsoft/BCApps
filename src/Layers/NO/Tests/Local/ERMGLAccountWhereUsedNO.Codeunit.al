codeunit 144544 "ERM G/L Account Where-Used NO"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [G/L Account Where-Used]
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        CalcGLAccWhereUsed: Codeunit "Calc. G/L Acc. Where-Used";
        isInitialized: Boolean;
        InvalidTableCaptionErr: Label 'Invalid table caption.';
        InvalidFieldCaptionErr: Label 'Invalid field caption.';
        InvalidLineValueErr: Label 'Invalid Line value.';

    [Test]
    [HandlerFunctions('WhereUsedHandler')]
    [Scope('OnPrem')]
    procedure CheckOCRSetup()
    var
        OCRSetup: Record "OCR Setup";
    begin
        // [SCENARIO 263861] OCR Setup should be shown on Where-Used page
        Initialize();

        // [GIVEN] OCR Setup with "Divergence Account No." = "G"
        OCRSetup.Get();
        OCRSetup.Validate("Divergence Account No.", LibraryERM.CreateGLAccountWithSalesSetup());
        OCRSetup.Modify();

        // [WHEN] Run Where-Used function for G/L Accoun "G"
        CalcGLAccWhereUsed.CheckGLAcc(OCRSetup."Divergence Account No.");

        // [THEN] G/L Account "G" is shown on "G/L Account Where-Used List"
        ValidateWhereUsedRecord(
          OCRSetup.TableCaption(),
          OCRSetup.FieldCaption("Divergence Account No."),
          StrSubstNo('%1=%2', OCRSetup.FieldCaption("Primary Key"), OCRSetup."Primary Key"));
    end;

    [Test]
    [HandlerFunctions('WhereUsedShowDetailsHandler')]
    [Scope('OnPrem')]
    procedure ShowDetailsWhereUsedOCRSetup()
    var
        OCRSetup: Record "OCR Setup";
        OCRSetupPage: TestPage "OCR Setup";
    begin
        // [SCENARIO 263861] OCR Setup page should be open on Show Details action from Where-Used page
        Initialize();

        // [GIVEN] OCR Setup with "Divergence Account No." = "G"
        OCRSetup.Get();
        OCRSetup.Validate("Divergence Account No.", LibraryERM.CreateGLAccountWithSalesSetup());
        OCRSetup.Modify();

        // [WHEN] Run Where-Used function for G/L Accoun "G" and choose Show Details action
        OCRSetupPage.Trap();
        CalcGLAccWhereUsed.CheckGLAcc(OCRSetup."Divergence Account No.");

        // [THEN] OCR Setup page opened
        OCRSetupPage.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('WhereUsedHandler')]
    [Scope('OnPrem')]
    procedure CheckRemittanceAccount()
    var
        RemittanceAccount: Record "Remittance Account";
    begin
        // [SCENARIO 263861] Remittance Account should be shown on Where-Used page
        Initialize();

        // [GIVEN] Remittance Account with "Round off/Divergence Acc. No." = "G"
        CreateRemittanceAccount(RemittanceAccount);

        // [WHEN] Run Where-Used function for G/L Accoun "G"
        CalcGLAccWhereUsed.CheckGLAcc(RemittanceAccount."Round off/Divergence Acc. No.");

        // [THEN] G/L Account "G" is shown on "G/L Account Where-Used List"
        ValidateWhereUsedRecord(
          RemittanceAccount.TableCaption(),
          RemittanceAccount.FieldCaption("Round off/Divergence Acc. No."),
          StrSubstNo('%1=%2', RemittanceAccount.FieldCaption(Code), RemittanceAccount.Code));
    end;

    [Test]
    [HandlerFunctions('WhereUsedShowDetailsHandler')]
    [Scope('OnPrem')]
    procedure ShowDetailsWhereUsedRemittanceAccount()
    var
        RemittanceAccount: Record "Remittance Account";
        RemittanceAccountOverview: TestPage "Remittance Account Overview";
    begin
        // [SCENARIO 263861] Remittance Account Overview page should be open on Show Details action from Where-Used page
        Initialize();

        // [GIVEN] Remittance Account Code = "RA" with "Round off/Divergence Acc. No." = "G"
        CreateRemittanceAccount(RemittanceAccount);

        // [WHEN] Run Where-Used function for G/L Accoun "G" and choose Show Details action
        RemittanceAccountOverview.Trap();
        CalcGLAccWhereUsed.CheckGLAcc(RemittanceAccount."Round off/Divergence Acc. No.");

        // [THEN] Remittance Account Overview page opened with Code = "RA"
        RemittanceAccountOverview.Code.AssertEquals(RemittanceAccount.Code);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
        if isInitialized then
            exit;

        isInitialized := true;
    end;

    local procedure CreateRemittanceAccount(var RemittanceAccount: Record "Remittance Account")
    begin
        RemittanceAccount.Init();
        RemittanceAccount.Code := LibraryUtility.GenerateRandomCode(RemittanceAccount.FieldNo(Code), DATABASE::"Remittance Account");
        RemittanceAccount."Round off/Divergence Acc. No." := LibraryERM.CreateGLAccountNo();
        RemittanceAccount.Insert();
    end;

    local procedure ValidateWhereUsedRecord(ExpectedTableCaption: Text; ExpectedFieldCaption: Text; ExpectedLineValue: Text)
    begin
        Assert.AreEqual(ExpectedTableCaption, LibraryVariableStorage.DequeueText(), InvalidTableCaptionErr);
        Assert.AreEqual(ExpectedFieldCaption, LibraryVariableStorage.DequeueText(), InvalidFieldCaptionErr);
        Assert.AreEqual(ExpectedLineValue, LibraryVariableStorage.DequeueText(), InvalidLineValueErr);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WhereUsedHandler(var GLAccountWhereUsedList: TestPage "G/L Account Where-Used List")
    begin
        GLAccountWhereUsedList.First();
        LibraryVariableStorage.Enqueue(GLAccountWhereUsedList."Table Name".Value);
        LibraryVariableStorage.Enqueue(GLAccountWhereUsedList."Field Name".Value);
        LibraryVariableStorage.Enqueue(GLAccountWhereUsedList.Line.Value);
        GLAccountWhereUsedList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WhereUsedShowDetailsHandler(var GLAccountWhereUsedList: TestPage "G/L Account Where-Used List")
    begin
        GLAccountWhereUsedList.First();
        GLAccountWhereUsedList.ShowDetails.Invoke();
    end;
}

