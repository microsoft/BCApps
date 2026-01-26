codeunit 141144 "ERM G/L Account WhereUsed APAC"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [G/L Account Where-Used]
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryAPACLocalization: Codeunit "Library - APAC Localization";
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
    procedure CheckWHTPostingSetup()
    var
        WHTBusinessPostingGroup: Record "WHT Business Posting Group";
        WHTProductPostingGroup: Record "WHT Product Posting Group";
        WHTPostingSetup: Record "WHT Posting Setup";
    begin
        // [SCENARIO 263861] WHT Posting Setup should be shown on Where-Used page
        Initialize();

        // [GIVEN] WHT Posting Setup with "Sales WHT Adj. Account No." = "G"
        LibraryAPACLocalization.CreateWHTBusinessPostingGroup(WHTBusinessPostingGroup);
        LibraryAPACLocalization.CreateWHTProductPostingGroup(WHTProductPostingGroup);
        LibraryAPACLocalization.CreateWHTPostingSetup(WHTPostingSetup, WHTBusinessPostingGroup.Code, WHTProductPostingGroup.Code);
        WHTPostingSetup.Validate("Sales WHT Adj. Account No.", LibraryERM.CreateGLAccountNo());
        WHTPostingSetup.Modify();

        // [WHEN] Run Where-Used function for G/L Accoun "G"
        CalcGLAccWhereUsed.CheckGLAcc(WHTPostingSetup."Sales WHT Adj. Account No.");

        // [THEN] G/L Account "G" is shown on "G/L Account Where-Used List"
        ValidateWhereUsedRecord(
          WHTPostingSetup.TableCaption(),
          WHTPostingSetup.FieldCaption("Sales WHT Adj. Account No."),
          StrSubstNo(
            '%1=%2, %3=%4',
            WHTPostingSetup.FieldCaption("WHT Business Posting Group"),
            WHTPostingSetup."WHT Business Posting Group",
            WHTPostingSetup.FieldCaption("WHT Product Posting Group"),
            WHTPostingSetup."WHT Product Posting Group"));
    end;

    [Test]
    [HandlerFunctions('WhereUsedShowDetailsHandler')]
    [Scope('OnPrem')]
    procedure ShowDetailsWhereUsedWHTPostingSetup()
    var
        WHTBusinessPostingGroup: Record "WHT Business Posting Group";
        WHTProductPostingGroup: Record "WHT Product Posting Group";
        WHTPostingSetup: Record "WHT Posting Setup";
        WHTPostingSetupPage: TestPage "WHT Posting Setup";
    begin
        // [SCENARIO 263861] WHT Posting Setup page should be open on Show Details action from Where-Used page
        Initialize();

        // [GIVEN] WHT Posting Setup "WHT Business Posting Group" = "BP", "WHT Product Posting Group" = "PP" with "Sales WHT Adj. Account No." = "G"
        LibraryAPACLocalization.CreateWHTBusinessPostingGroup(WHTBusinessPostingGroup);
        LibraryAPACLocalization.CreateWHTProductPostingGroup(WHTProductPostingGroup);
        LibraryAPACLocalization.CreateWHTPostingSetup(WHTPostingSetup, WHTBusinessPostingGroup.Code, WHTProductPostingGroup.Code);
        WHTPostingSetup.Validate("Sales WHT Adj. Account No.", LibraryERM.CreateGLAccountNo());
        WHTPostingSetup.Modify();

        // [WHEN] Run Where-Used function for G/L Accoun "G" and choose Show Details action
        WHTPostingSetupPage.Trap();
        CalcGLAccWhereUsed.CheckGLAcc(WHTPostingSetup."Sales WHT Adj. Account No.");

        // [THEN] WHT Posting Setup page opened with "WHT Business Posting Group" = "BP", "WHT Product Posting Group" = "PP"
        WHTPostingSetupPage."WHT Business Posting Group".AssertEquals(WHTBusinessPostingGroup.Code);
        WHTPostingSetupPage."WHT Product Posting Group".AssertEquals(WHTProductPostingGroup.Code);
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

