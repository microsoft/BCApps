codeunit 144544 "ERM G/L Account Where-Used NL"
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
        CalcGLAccWhereUsed: Codeunit "Calc. G/L Acc. Where-Used";
        isInitialized: Boolean;
        InvalidTableCaptionErr: Label 'Invalid table caption.';
        InvalidFieldCaptionErr: Label 'Invalid field caption.';
        InvalidLineValueErr: Label 'Invalid Line value.';

    [Test]
    [HandlerFunctions('WhereUsedHandler')]
    [Scope('OnPrem')]
    procedure CheckTransactionMode()
    var
        TransactionMode: Record "Transaction Mode";
    begin
        // [SCENARIO 263861] Transaction Mode should be shown on Where-Used page
        Initialize();

        // [GIVEN] Transaction Mode with "Acc. No. Pmt./Rcpt. in Process" = "G"
        TransactionMode.Init();
        TransactionMode.Code := LibraryUTUtility.GetNewCode();
        TransactionMode."Acc. No. Pmt./Rcpt. in Process" := LibraryERM.CreateGLAccountNo();
        TransactionMode.Insert();

        // [WHEN] Run Where-Used function for G/L Accoun "G"
        CalcGLAccWhereUsed.CheckGLAcc(TransactionMode."Acc. No. Pmt./Rcpt. in Process");

        // [THEN] Transaction Mode is shown on "G/L Account Where-Used List"
        ValidateWhereUsedRecord(
          TransactionMode.TableCaption(),
          TransactionMode.FieldCaption("Acc. No. Pmt./Rcpt. in Process"),
          StrSubstNo(
            '%1=%2, %3=%4',
            TransactionMode.FieldCaption("Account Type"),
            TransactionMode."Account Type",
            TransactionMode.FieldCaption(Code),
            TransactionMode.Code));
    end;

    [Test]
    [HandlerFunctions('WhereUsedShowDetailsHandler')]
    [Scope('OnPrem')]
    procedure ShowDetailsWhereUsedTransactionMode()
    var
        TransactionMode: Record "Transaction Mode";
        TransactionModeList: TestPage "Transaction Mode List";
    begin
        // [SCENARIO 263861] Transaction Mode List page should be open on Show Details action from Where-Used page
        Initialize();

        // [GIVEN] Transaction Mode "TM" with "Acc. No. Pmt./Rcpt. in Process" = "G"
        TransactionMode.Init();
        TransactionMode.Code := LibraryUTUtility.GetNewCode();
        TransactionMode."Acc. No. Pmt./Rcpt. in Process" := LibraryERM.CreateGLAccountNo();
        TransactionMode.Insert();

        // [WHEN] Run Where-Used function for G/L Accoun "G" and choose Show Details action
        TransactionModeList.Trap();
        CalcGLAccWhereUsed.CheckGLAcc(TransactionMode."Acc. No. Pmt./Rcpt. in Process");

        // [THEN] Transaction Mode List page opened with Code = "TM"
        TransactionModeList.Code.AssertEquals(TransactionMode.Code);
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

