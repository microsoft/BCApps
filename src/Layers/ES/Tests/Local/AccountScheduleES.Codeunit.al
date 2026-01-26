codeunit 144003 "Account Schedule - ES"
{
    // -----------------------------------------------------------------------------------------------------
    // Test Function Name                                                                          TFS ID
    // -----------------------------------------------------------------------------------------------------
    // ReverseCellValue,PositiveOnlyCellValue,ReverseAndPositiveOnlyCellValue                      59540

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryAccSchedule: Codeunit "Library - Account Schedule";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        WrongCellValueErr: Label 'Wrong cell value.';

    [Test]
    [Scope('OnPrem')]
    procedure ReverseCellValue()
    var
        Amount: Decimal;
    begin
        Amount := LibraryRandom.RandDec(10, 2);
        TestCellValue(true, false, Amount, -Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PositiveOnlyCellValue()
    var
        Amount: Decimal;
    begin
        Amount := -LibraryRandom.RandDec(10, 2);
        TestCellValue(false, true, Amount, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReverseAndPositiveOnlyCellValue()
    var
        Amount: Decimal;
    begin
        Amount := LibraryRandom.RandDec(10, 2);
        TestCellValue(true, true, Amount, 0);
    end;

    local procedure TestCellValue(ReverseSign: Boolean; PositiveOnly: Boolean; Amount: Decimal; ExpectedAmount: Decimal)
    var
        GLAccount: Record "G/L Account";
        Vendor: Record Vendor;
        ColumnLayout: Record "Column Layout";
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryERM.CreateGLAccount(GLAccount);
        CreateColumnLayout(ColumnLayout);
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        CreateAccountSchedulePosting(AccScheduleLine, AccScheduleName.Name, GLAccount."No.", ReverseSign, PositiveOnly);

        CreateAndPostJournal(Vendor."No.", GLAccount."No.", Amount);
        AccScheduleLine.SetRange("Date Filter", WorkDate());
        Assert.AreEqual(ExpectedAmount, LibraryAccSchedule.CalcCell(AccScheduleLine, ColumnLayout, false, false), WrongCellValueErr);
    end;

    local procedure CreateAccountSchedulePosting(var AccScheduleLine: Record "Acc. Schedule Line"; ScheduleName: Code[10]; Totaling: Text[250]; ReverseSign: Boolean; PositiveOnly: Boolean)
    begin
        LibraryERM.CreateAccScheduleLine(AccScheduleLine, ScheduleName);
        AccScheduleLine.Validate(Totaling, Totaling);
        AccScheduleLine.Validate("Reverse Sign", ReverseSign);
        AccScheduleLine.Validate("Positive Only", PositiveOnly);
        AccScheduleLine.Modify(true);
    end;

    local procedure CreateColumnLayout(var ColumnLayout: Record "Column Layout")
    var
        ColumnLayoutName: Record "Column Layout Name";
    begin
        LibraryERM.CreateColumnLayoutName(ColumnLayoutName);
        LibraryERM.CreateColumnLayout(ColumnLayout, ColumnLayoutName.Name);
    end;

    local procedure CreateAndPostJournal(AccountNo: Code[20]; BalanceAccountNo: Code[20]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GetDocType(Amount), GenJournalLine."Account Type"::Vendor, AccountNo, -Amount);
        UpdateGenJournalLine(GenJournalLine, BalanceAccountNo);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure UpdateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; BalAccountNo: Code[20])
    begin
        GenJournalLine.Validate("Bal. Account No.", BalAccountNo);
        GenJournalLine.Modify(true);
    end;

    local procedure GetDocType(Amount: Decimal): Enum "Gen. Journal Document Type"
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        if Amount > 0 then
            exit(GenJnlLine."Document Type"::Invoice);
        exit(GenJnlLine."Document Type"::"Credit Memo");
    end;
}

