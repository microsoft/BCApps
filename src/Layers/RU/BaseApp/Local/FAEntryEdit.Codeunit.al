#pragma warning disable AA0247
codeunit 17308 "FA Entry - Edit"
{
    Permissions = TableData "FA Ledger Entry" = imd;
    TableNo = "FA Ledger Entry";

    trigger OnRun()
    begin
        FALedgerEntry := Rec;
        FALedgerEntry.LockTable();
        FALedgerEntry.Find();

        if FALedgerEntry."Tax Difference Code" <> Rec."Tax Difference Code" then
            CheckTaxDifference(FALedgerEntry, Rec."Tax Difference Code");

        FALedgerEntry."Depr. Bonus" := Rec."Depr. Bonus";
        FALedgerEntry."Tax Difference Code" := Rec."Tax Difference Code";
        FALedgerEntry.Modify();
        Rec := FALedgerEntry;
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label '%1 cannot be changed.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        FALedgerEntry: Record "FA Ledger Entry";
        DepreciationBook: Record "Depreciation Book";
        TaxRegisterSetup: Record "Tax Register Setup";

    [Scope('OnPrem')]
    procedure CheckTaxDifference(OldFALedgerEntry: Record "FA Ledger Entry"; NewTaxDiffCode: Code[10])
    var
        FixedAsset: Record "Fixed Asset";
        TaxDiffLedgerEntry: Record "Tax Diff. Ledger Entry";
    begin
        DepreciationBook.Get(OldFALedgerEntry."Depreciation Book Code");
        DepreciationBook.TestField("Control FA Acquis. Cost", true);

        TaxRegisterSetup.Get();
        FixedAsset.Get(OldFALedgerEntry."FA No.");

        OldFALedgerEntry.TestField(Reversed, false);
        OldFALedgerEntry.TestField("Canceled from FA No.", '');

        if NewTaxDiffCode = TaxRegisterSetup."Default FA TD Code" then
            exit;

        TaxDiffLedgerEntry.SetCurrentKey("Tax Diff. Code", "Source Type", "Source No.", "Posting Date");
        TaxDiffLedgerEntry.SetRange("Source Type", FixedAsset.GetTDESourceType());
        TaxDiffLedgerEntry.SetRange("Source No.", OldFALedgerEntry."FA No.");
        TaxDiffLedgerEntry.SetFilter("Tax Diff. Code", OldFALedgerEntry."Tax Difference Code");
        TaxDiffLedgerEntry.CalcSums(Difference);
        if TaxDiffLedgerEntry.Difference <> 0 then
            Error(Text001, FALedgerEntry.FieldCaption("Tax Difference Code"));
    end;
}

