codeunit 144544 "ERM G/L Account Where-Used CH"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [G/L Account Where-Used]
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        CalcGLAccWhereUsed: Codeunit "Calc. G/L Acc. Where-Used";
        isInitialized: Boolean;
        InvalidTableCaptionErr: Label 'Invalid table caption.';
        InvalidFieldCaptionErr: Label 'Invalid field caption.';
        InvalidLineValueErr: Label 'Invalid Line value.';

    [Test]
    [HandlerFunctions('WhereUsedHandler')]
    [Scope('OnPrem')]
    procedure CheckVendorBankAccount()
    var
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        // [SCENARIO 263861] Vendor Bank Account should be shown on Where-Used page
        Initialize();

        // [GIVEN] Vendor Bank Account with "Balance Account No." = "G"
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, LibraryPurchase.CreateVendorNo());
        VendorBankAccount.Validate("Balance Account No.", LibraryERM.CreateGLAccountNo());
        VendorBankAccount.Modify();

        // [WHEN] Run Where-Used function for G/L Accoun "G"
        CalcGLAccWhereUsed.CheckGLAcc(VendorBankAccount."Balance Account No.");

        // [THEN] Vendor Bank Account is shown on "G/L Account Where-Used List"
        ValidateWhereUsedRecord(
          VendorBankAccount.TableCaption(),
          VendorBankAccount.FieldCaption("Balance Account No."),
          StrSubstNo(
            '%1=%2, %3=%4',
            VendorBankAccount.FieldCaption("Vendor No."),
            VendorBankAccount."Vendor No.",
            VendorBankAccount.FieldCaption(Code),
            VendorBankAccount.Code));
    end;

    [Test]
    [HandlerFunctions('WhereUsedShowDetailsHandler')]
    [Scope('OnPrem')]
    procedure ShowDetailsWhereUsedVendorBankAccount()
    var
        VendorBankAccount: Record "Vendor Bank Account";
        VendorBankAccountList: TestPage "Vendor Bank Account List";
    begin
        // [SCENARIO 263861] Vendor Bank Account List page should be open on Show Details action from Where-Used page
        Initialize();

        // [GIVEN] Vendor Bank Account "Vendor No." = "V", Code = "VBA" with "Balance Account No." = "G"
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, LibraryPurchase.CreateVendorNo());
        VendorBankAccount.Validate("Balance Account No.", LibraryERM.CreateGLAccountNo());
        VendorBankAccount.Modify();

        // [WHEN] Run Where-Used function for G/L Accoun "G" and choose Show Details action
        VendorBankAccountList.Trap();
        CalcGLAccWhereUsed.CheckGLAcc(VendorBankAccount."Balance Account No.");

        // [THEN] Vendor Bank Account List page opened with "Vendor No." = "V", Code = "VBA"
        VendorBankAccountList.Code.AssertEquals(VendorBankAccount.Code);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
        if isInitialized then
            exit;

        isInitialized := true;
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

