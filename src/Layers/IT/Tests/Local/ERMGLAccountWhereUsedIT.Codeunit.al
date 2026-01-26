codeunit 144563 "ERM G/L Account Where-Used IT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [G/L Account Where-Used]
    end;

    var
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryERM: Codeunit "Library - ERM";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        LibraryITLocalization: Codeunit "Library - IT Localization";
        CalcGLAccWhereUsed: Codeunit "Calc. G/L Acc. Where-Used";
        isInitialized: Boolean;
        InvalidTableCaptionErr: Label 'Invalid table caption.';
        InvalidFieldCaptionErr: Label 'Invalid field caption.';
        InvalidLineValueErr: Label 'Invalid Line value.';

    [Test]
    [HandlerFunctions('WhereUsedHandler')]
    [Scope('OnPrem')]
    procedure CheckWithholdCode()
    var
        WithholdCode: Record "Withhold Code";
    begin
        // [SCENARIO 263861] Withhold Code should be shown on Where-Used page
        Initialize();

        // [GIVEN] Withhold Code with "Withholding Taxes Payable Acc." = "G"
        WithholdCode.Init();
        WithholdCode.Code := LibraryUTUtility.GetNewCode();
        WithholdCode."Withholding Taxes Payable Acc." := LibraryERM.CreateGLAccountNo();
        WithholdCode.Insert();

        // [WHEN] Run Where-Used function for G/L Accoun "G"
        CalcGLAccWhereUsed.CheckGLAcc(WithholdCode."Withholding Taxes Payable Acc.");

        // [THEN] Withhold Code is shown on "G/L Account Where-Used List"
        ValidateWhereUsedRecord(
          WithholdCode.TableCaption(),
          WithholdCode.FieldCaption("Withholding Taxes Payable Acc."),
          StrSubstNo('%1=%2', WithholdCode.FieldCaption(Code), WithholdCode.Code));
    end;

    [Test]
    [HandlerFunctions('WhereUsedShowDetailsHandler')]
    [Scope('OnPrem')]
    procedure ShowDetailsWhereUsedWithholdCode()
    var
        WithholdCode: Record "Withhold Code";
        WithholdCodes: TestPage "Withhold Codes";
    begin
        // [SCENARIO 263861] Withhold Codes page should be open on Show Details action from Where-Used page
        Initialize();

        // [GIVEN] Withhold Code "W" with "Withholding Taxes Payable Acc." = "G"
        WithholdCode.Init();
        WithholdCode.Code := LibraryUTUtility.GetNewCode();
        WithholdCode."Withholding Taxes Payable Acc." := LibraryERM.CreateGLAccountNo();
        WithholdCode.Insert();

        // [WHEN] Run Where-Used function for G/L Accoun "G" and choose Show Details action
        WithholdCodes.Trap();
        CalcGLAccWhereUsed.CheckGLAcc(WithholdCode."Withholding Taxes Payable Acc.");

        // [THEN] Withhold Code page opened with "Code" = "W"
        WithholdCodes.Code.AssertEquals(WithholdCode.Code);
    end;

    [Test]
    [HandlerFunctions('WhereUsedHandler')]
    [Scope('OnPrem')]
    procedure CheckContributionCode()
    var
        ContributionCode: Record "Contribution Code";
    begin
        // [SCENARIO 263861] Contribution Code should be shown on Where-Used page
        Initialize();

        // [GIVEN] Contribution Code with "Social Security Payable Acc." = "G"
        LibraryITLocalization.CreateContributionCode(ContributionCode, ContributionCode."Contribution Type"::INAIL);
        ContributionCode.Validate("Social Security Payable Acc.", LibraryERM.CreateGLAccountNo());
        ContributionCode.Modify();

        // [WHEN] Run Where-Used function for G/L Accoun "G"
        CalcGLAccWhereUsed.CheckGLAcc(ContributionCode."Social Security Payable Acc.");

        // [THEN] Contribution Code is shown on "G/L Account Where-Used List"
        ValidateWhereUsedRecord(
          ContributionCode.TableCaption(),
          ContributionCode.FieldCaption("Social Security Payable Acc."),
          StrSubstNo(
            '%1=%2, %3=%4',
            ContributionCode.FieldCaption(Code),
            ContributionCode.Code,
            ContributionCode.FieldCaption("Contribution Type"),
            ContributionCode."Contribution Type"));
    end;

    [Test]
    [HandlerFunctions('WhereUsedShowDetailsHandler')]
    [Scope('OnPrem')]
    procedure ShowDetailsWhereUsedContributionCodeINPS()
    var
        ContributionCode: Record "Contribution Code";
        ContributionCodesINPS: TestPage "Contribution Codes-INPS";
    begin
        // [SCENARIO 263861] Contribution Codes-INPS page should be open on Show Details action from Where-Used page
        Initialize();

        // [GIVEN] Contribution Code "Code" = "CINPS", "Contribution Type" = "INPS" with "Social Security Payable Acc." = "G"
        LibraryITLocalization.CreateContributionCode(ContributionCode, ContributionCode."Contribution Type"::INPS);
        ContributionCode.Validate("Social Security Payable Acc.", LibraryERM.CreateGLAccountNo());
        ContributionCode.Modify();

        // [WHEN] Run Where-Used function for G/L Accoun "G" and choose Show Details action
        ContributionCodesINPS.Trap();
        CalcGLAccWhereUsed.CheckGLAcc(ContributionCode."Social Security Payable Acc.");

        // [THEN] Contribution Codes-INPS page opened with "Code" = "CINPS"
        ContributionCodesINPS.Code.AssertEquals(ContributionCode.Code);
    end;

    [Test]
    [HandlerFunctions('WhereUsedShowDetailsHandler')]
    [Scope('OnPrem')]
    procedure ShowDetailsWhereUsedContributionCodeINAIL()
    var
        ContributionCode: Record "Contribution Code";
        ContributionCodesINAIL: TestPage "Contribution Codes-INAIL";
    begin
        // [SCENARIO 263861] Contribution Codes-INAIL page should be open on Show Details action from Where-Used page
        Initialize();

        // [GIVEN] Contribution Code "Code" = "CINAIL", "Contribution Type" = "INAIL" with "Social Security Payable Acc." = "G"
        LibraryITLocalization.CreateContributionCode(ContributionCode, ContributionCode."Contribution Type"::INAIL);
        ContributionCode.Validate("Social Security Payable Acc.", LibraryERM.CreateGLAccountNo());
        ContributionCode.Modify();

        // [WHEN] Run Where-Used function for G/L Accoun "G" and choose Show Details action
        ContributionCodesINAIL.Trap();
        CalcGLAccWhereUsed.CheckGLAcc(ContributionCode."Social Security Payable Acc.");

        // [THEN] Contribution Codes-INAIL page opened with "Code" = "CINAIL"
        ContributionCodesINAIL.Code.AssertEquals(ContributionCode.Code);
    end;

    [Test]
    [HandlerFunctions('WhereUsedHandler')]
    [Scope('OnPrem')]
    procedure CheckBillPostingGroup()
    var
        PaymentMethod: Record "Payment Method";
        BillPostingGroup: Record "Bill Posting Group";
    begin
        // [SCENARIO 263861] Bill Posting Group should be shown on Where-Used page
        Initialize();

        // [GIVEN] Bill Posting Group with "Bills For Collection Acc. No." = "G"
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        LibraryITLocalization.CreateBillPostingGroup(
          BillPostingGroup,
          LibraryERM.CreateBankAccountNo(),
          PaymentMethod.Code);
        BillPostingGroup.Validate("Bills For Collection Acc. No.", LibraryERM.CreateGLAccountNo());
        BillPostingGroup.Modify();

        // [WHEN] Run Where-Used function for G/L Accoun "G"
        CalcGLAccWhereUsed.CheckGLAcc(BillPostingGroup."Bills For Collection Acc. No.");

        // [THEN] Bill Posting Group is shown on "G/L Account Where-Used List"
        ValidateWhereUsedRecord(
          BillPostingGroup.TableCaption(),
          BillPostingGroup.FieldCaption("Bills For Collection Acc. No."),
          StrSubstNo(
            '%1=%2, %3=%4',
            BillPostingGroup.FieldCaption("No."),
            BillPostingGroup."No.",
            BillPostingGroup.FieldCaption("Payment Method"),
            BillPostingGroup."Payment Method"));
    end;

    [Test]
    [HandlerFunctions('WhereUsedShowDetailsHandler')]
    [Scope('OnPrem')]
    procedure WhereUsedBillPostingGroup()
    var
        PaymentMethod: Record "Payment Method";
        BillPostingGroup: Record "Bill Posting Group";
        BillPostingGroupPage: TestPage "Bill Posting Group";
    begin
        // [SCENARIO 263861] Bill Posting Group page should be open on Show Details action from Where-Used page
        Initialize();

        // [GIVEN] Bill Posting Group with "Payment Method" = "PM", "Bills For Collection Acc. No." = "G"
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        LibraryITLocalization.CreateBillPostingGroup(
          BillPostingGroup,
          LibraryERM.CreateBankAccountNo(),
          PaymentMethod.Code);
        BillPostingGroup.Validate("Bills For Collection Acc. No.", LibraryERM.CreateGLAccountNo());
        BillPostingGroup.Modify();

        // [WHEN] Run Where-Used function for G/L Accoun "G" and choose Show Details action
        BillPostingGroupPage.Trap();
        CalcGLAccWhereUsed.CheckGLAcc(BillPostingGroup."Bills For Collection Acc. No.");

        // [THEN] Bill Posting Group page opened with with "Payment Method" = "PM"
        BillPostingGroupPage."Payment Method".AssertEquals(PaymentMethod.Code);
    end;

    [Test]
    [HandlerFunctions('WhereUsedHandler')]
    [Scope('OnPrem')]
    procedure CheckBill()
    var
        Bill: Record Bill;
    begin
        // [SCENARIO 263861] Bill should be shown on Where-Used page
        Initialize();

        // [GIVEN] Bill with "Bills for Coll. Temp. Acc. No." = "G"
        LibraryITLocalization.CreateBill(Bill);
        Bill.Validate("Bills for Coll. Temp. Acc. No.", LibraryERM.CreateGLAccountNo());
        Bill.Modify();

        // [WHEN] Run Where-Used function for G/L Accoun "G"
        CalcGLAccWhereUsed.CheckGLAcc(Bill."Bills for Coll. Temp. Acc. No.");

        // [THEN] Bill is shown on "G/L Account Where-Used List"
        ValidateWhereUsedRecord(
          Bill.TableCaption(),
          Bill.FieldCaption("Bills for Coll. Temp. Acc. No."),
          StrSubstNo('%1=%2', Bill.FieldCaption(Code), Bill.Code));
    end;

    [Test]
    [HandlerFunctions('WhereUsedShowDetailsHandler')]
    [Scope('OnPrem')]
    procedure WhereUsedBill()
    var
        Bill: Record Bill;
        BillPage: TestPage Bill;
    begin
        // [SCENARIO 263861] Bill page should be open on Show Details action from Where-Used page
        Initialize();

        // [GIVEN] Bill "Code" = "B" with "Bills for Coll. Temp. Acc. No." = "G"
        LibraryITLocalization.CreateBill(Bill);
        Bill.Validate("Bills for Coll. Temp. Acc. No.", LibraryERM.CreateGLAccountNo());
        Bill.Modify();

        // [WHEN] Run Where-Used function for G/L Accoun "G" and choose Show Details action
        BillPage.Trap();
        CalcGLAccWhereUsed.CheckGLAcc(Bill."Bills for Coll. Temp. Acc. No.");

        // [THEN] Bill page opened with "Code" = "B"
        BillPage.Code.AssertEquals(Bill.Code);
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

