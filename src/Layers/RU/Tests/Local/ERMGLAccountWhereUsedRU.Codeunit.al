codeunit 144544 "ERM G/L Account Where-Used RU"
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
    procedure CheckFACharge()
    var
        FACharge: Record "FA Charge";
    begin
        // [SCENARIO 263861] FA Charge should be shown on Where-Used page
        Initialize();

        // [GIVEN] FA Charge with "G/L Acc. for Released FA" = "G"
        CreateFACharge(FACharge);

        // [WHEN] Run Where-Used function for G/L Accoun "G"
        CalcGLAccWhereUsed.CheckGLAcc(FACharge."G/L Acc. for Released FA");

        // [THEN] G/L Account "G" is shown on "G/L Account Where-Used List"
        ValidateWhereUsedRecord(
          FACharge.TableCaption(),
          FACharge.FieldCaption("G/L Acc. for Released FA"),
          StrSubstNo('%1=%2', FACharge.FieldCaption("No."), FACharge."No."));
    end;

    [Test]
    [HandlerFunctions('WhereUsedShowDetailsHandler')]
    [Scope('OnPrem')]
    procedure ShowDetailsWhereUsedFACharge()
    var
        FACharge: Record "FA Charge";
        FAChargeList: TestPage "FA Charge List";
    begin
        // [SCENARIO 263861] FA Charge List page should be open on Show Details action from Where-Used page
        Initialize();

        // [GIVEN] FA Charge "FC" with "G/L Acc. for Released FA" = "G"
        CreateFACharge(FACharge);

        // [WHEN] Run Where-Used function for G/L Accoun "G" and choose Show Details action
        FAChargeList.Trap();
        CalcGLAccWhereUsed.CheckGLAcc(FACharge."G/L Acc. for Released FA");

        // [THEN] FA Charge List opened with "No." = "FC"
        FAChargeList."No.".AssertEquals(FACharge."No.");
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
        if isInitialized then
            exit;

        isInitialized := true;
    end;

    local procedure CreateFACharge(var FACharge: Record "FA Charge")
    begin
        FACharge.Init();
        FACharge."No." := LibraryUtility.GenerateRandomCode(FACharge.FieldNo("No."), DATABASE::"FA Charge");
        FACharge."G/L Acc. for Released FA" := LibraryERM.CreateGLAccountNo();
        FACharge.Insert();
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

