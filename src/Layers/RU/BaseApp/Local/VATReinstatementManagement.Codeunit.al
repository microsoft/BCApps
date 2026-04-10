#pragma warning disable AA0247
codeunit 12418 "VAT Reinstatement Management"
{

    trigger OnRun()
    begin
    end;

    var
        VATDocEntryBuffer: Record "VAT Document Entry Buffer";
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text002: Label 'The %1 must not be more than %2 in %3.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text003: Label 'The %1 must not be less than %2 in %3.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text004: Label 'VAT has been already reinstated for %1 %2=%3.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        GLSetup: Record "General Ledger Setup";

    [Scope('OnPrem')]
    procedure CreateVATReinstFromFAWriteOff(FAWriteOffActNo: Code[20])
    var
        VATEntry: Record "VAT Entry";
        GenJnlLine: Record "Gen. Journal Line";
        FALedgerEntry: Record "FA Ledger Entry";
        PostedFADocHeader: Record "Posted FA Doc. Header";
        PostedFADocLine: Record "Posted FA Doc. Line";
        VATReinstJnlForm: Page "VAT Reinstatement Journal";
        AcqCostAmount: Decimal;
        BookValueAmount: Decimal;
    begin
        VATEntry.SetCurrentKey(Type, "Object Type", "Object No.");

        PostedFADocHeader.Get(PostedFADocHeader."Document Type"::Writeoff, FAWriteOffActNo);
        PostedFADocLine.SetRange("Document Type", PostedFADocLine."Document Type"::Writeoff);
        PostedFADocLine.SetRange("Document No.", FAWriteOffActNo);
        if PostedFADocLine.FindSet() then
            repeat
                FALedgerEntry.Reset();
                FALedgerEntry.SetCurrentKey("FA No.", "Depreciation Book Code", "FA Posting Category");
                FALedgerEntry.SetRange("FA No.", PostedFADocLine."FA No.");
                FALedgerEntry.SetRange("Depreciation Book Code", PostedFADocLine."Depreciation Book Code");
                FALedgerEntry.SetRange("FA Posting Category", FALedgerEntry."FA Posting Category"::" ");
                FALedgerEntry.SetRange("Part of Book Value", true);
                FALedgerEntry.SetRange("FA Posting Type", FALedgerEntry."FA Posting Type"::"Acquisition Cost");
                FALedgerEntry.CalcSums(Amount);
                AcqCostAmount := FALedgerEntry.Amount;

                FALedgerEntry.SetRange("FA Posting Type");
                FALedgerEntry.SetFilter("FA Posting Date", '..%1', PostedFADocHeader."Posting Date");
                FALedgerEntry.CalcSums(Amount);
                BookValueAmount := FALedgerEntry.Amount;

                VATEntry.SetRange(Type, VATEntry.Type::Purchase);
                VATEntry.SetRange("Object Type", VATEntry."Object Type"::"Fixed Asset");
                VATEntry.SetRange("Object No.", PostedFADocLine."FA No.");
                VATEntry.SetFilter(Base, '<>0');
                VATEntry.SetRange("Prepmt. Diff.", false);
                if VATEntry.FindSet() then
                    repeat
                        CreateVATReinstatementJnlLine(
                          GenJnlLine,
                          VATEntry,
                          PostedFADocHeader."Posting Date",
                          Round(VATEntry.Amount * BookValueAmount / AcqCostAmount));
                    until VATEntry.Next() = 0;
            until PostedFADocLine.Next() = 0;

        VATReinstJnlForm.Run();
    end;

    [Scope('OnPrem')]
    procedure CreateVATReinstatementJnlLine(var GenJnlLine: Record "Gen. Journal Line"; VATEntry: Record "VAT Entry"; PostingDate: Date; Amount: Decimal)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        LineNo: Integer;
    begin
        VATPostingSetup.Get(VATEntry."VAT Bus. Posting Group", VATEntry."VAT Prod. Posting Group");
        VATPostingSetup.TestField("VAT Reinstatement Template");
        VATPostingSetup.TestField("VAT Reinstatement Batch");

        GLSetup.Get();

        GenJnlLine.SetRange("Journal Template Name", VATPostingSetup."VAT Reinstatement Template");
        GenJnlLine.SetRange("Journal Batch Name", VATPostingSetup."VAT Reinstatement Batch");
        if GenJnlLine.FindLast() then;
        LineNo := GenJnlLine."Line No." + 10000;

        GenJnlLine.Init();
        GenJnlLine."Journal Template Name" := VATPostingSetup."VAT Reinstatement Template";
        GenJnlLine."Journal Batch Name" := VATPostingSetup."VAT Reinstatement Batch";
        GenJnlLine."Line No." := LineNo;
        GenJnlLine.Validate("Reinstatement VAT Entry No.", VATEntry."Entry No.");
        GenJnlLine.Validate("Posting Date", PostingDate);
        GenJnlLine.Validate(Amount, Amount);
        GenJnlLine.Validate(Correction,
          GLSetup."Red Storno VAT Reinstatement" xor ((GenJnlLine.Amount < 0) and VATEntry."Prepmt. Diff."));
        VendorLedgerEntry.Get(VATEntry."CV Ledg. Entry No.");
        GenJnlLine."Shortcut Dimension 1 Code" := VendorLedgerEntry."Global Dimension 1 Code";
        GenJnlLine."Shortcut Dimension 2 Code" := VendorLedgerEntry."Global Dimension 2 Code";
        GenJnlLine."Dimension Set ID" := VendorLedgerEntry."Dimension Set ID";
        GenJnlLine.Insert();
    end;

    [Scope('OnPrem')]
    procedure Generate(var TempVATDocBuf: Record "VAT Document Entry Buffer" temporary; DateFilter: Text[30]; VATBusPostingGroupFilter: Text[250]; VATProdPostingGroupFilter: Text[250])
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        VATEntry: Record "VAT Entry";
        Vend: Record Vendor;
        VATPostingSetup: Record "VAT Posting Setup";
        Window: Dialog;
        VATCount: Integer;
        I: Integer;
        CVEntryNo: Integer;
        PostingDate: Date;
        CVEntryType: Option " ",Purchase,Sale;
    begin
        VATDocEntryBuffer.CopyFilters(TempVATDocBuf);
        TempVATDocBuf.DeleteAll();
        Window.Open('@1@@@@@@@@@@@@@@@');

        VATEntry.Reset();
        VATEntry.SetRange(Type, VATEntry.Type::Purchase);
        VATEntry.SetRange(Reversed, false);
        VATEntry.SetFilter(Amount, '<>0');
        if DateFilter <> '' then
            VATEntry.SetFilter("Posting Date", DateFilter);
        if VATBusPostingGroupFilter <> '' then
            VATEntry.SetFilter("VAT Bus. Posting Group", VATBusPostingGroupFilter);
        if VATProdPostingGroupFilter <> '' then
            VATEntry.SetFilter("VAT Prod. Posting Group", VATProdPostingGroupFilter);
        VATEntry.SetFilter("Unrealized VAT Entry No.", '<>0');

        I := 0;
        VATCount := VATEntry.Count();// APPROX;
        if VATEntry.FindSet() then
            repeat
                I += 1;
                Window.Update(1, Round(I / VATCount * 10000, 1));
                if DateFilter <> '' then begin
                    TempVATDocBuf.SetFilter("Date Filter", DateFilter);
                    PostingDate := TempVATDocBuf.GetRangeMax("Date Filter");
                end else
                    PostingDate := WorkDate();
                if VATPostingSetup.Get(VATEntry."VAT Bus. Posting Group", VATEntry."VAT Prod. Posting Group") then
#pragma warning disable AL0603
                    if VATEntry.FindCVEntry(CVEntryType, CVEntryNo) and
#pragma warning restore AL0603
                       IsAllowedVATCalcTypeForReinstatement(VATEntry.Base, VATPostingSetup."VAT Calculation Type")
                    then begin
                        VendLedgEntry.Get(CVEntryNo);
                        VendLedgEntry.CalcFields("Amount (LCY)", "Remaining Amt. (LCY)");
                        TempVATDocBuf.TransferFields(VendLedgEntry);
                        TempVATDocBuf."Entry Type" := "General Posting Type".FromInteger(CVEntryType);
                        TempVATDocBuf.CalcFields("Realized VAT Amount");
                        if TempVATDocBuf."Realized VAT Amount" <> 0 then begin
                            TempVATDocBuf."Amount (LCY)" := VendLedgEntry."Amount (LCY)";
                            TempVATDocBuf."Remaining Amt. (LCY)" := VendLedgEntry."Remaining Amt. (LCY)";
                            TempVATDocBuf."Table ID" := DATABASE::"Vendor Ledger Entry";
                            Vend.Get(VendLedgEntry."Vendor No.");
                            TempVATDocBuf."CV Name" := Vend.Name;
                            TempVATDocBuf."Document Date" := TempVATDocBuf."Posting Date";
                            if PostingDate > TempVATDocBuf."Posting Date" then
                                TempVATDocBuf."Posting Date" := PostingDate;
                            if TempVATDocBuf.Insert() then;
                        end;
                    end;
            until VATEntry.Next() = 0;
        Window.Close();
    end;

    [Scope('OnPrem')]
    procedure CopyToJnl(var LineToCopy: Record "VAT Document Entry Buffer" temporary; var VATEntry: Record "VAT Entry"; VATAmountFactor: Decimal; PostingDate: Date; PostingDescription: Text[50])
    var
        GenJnlLine: Record "Gen. Journal Line";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        VATReinstJnlForm: Page "VAT Reinstatement Journal";
        IsCorrection: Boolean;
    begin
        VATDocEntryBuffer.CopyFilters(LineToCopy);
        LineToCopy.FindSet();
        repeat
            IsCorrection := false;
            if LineToCopy."Document Type" = LineToCopy."Document Type"::"Credit Memo" then
                case LineToCopy."Entry Type" of
                    LineToCopy."Entry Type"::Purchase:
                        if PurchCrMemoHeader.Get(LineToCopy."Document No.") then
                            IsCorrection := PurchCrMemoHeader.Correction;
                    LineToCopy."Entry Type"::Sale:
                        if SalesCrMemoHeader.Get(LineToCopy."Document No.") then
                            IsCorrection := SalesCrMemoHeader.Correction;
                end;
            CreateVATReinstJnlLinesExclDuplicatedEntriesByUnrealVATEntryNo(
              GenJnlLine, VATEntry, LineToCopy."Entry No.", PostingDate, VATAmountFactor, PostingDescription);
        until LineToCopy.Next() = 0;

        VATReinstJnlForm.Run();
    end;

    [Scope('OnPrem')]
    procedure CheckAmount(GenJournalLine: Record "Gen. Journal Line")
    var
        VATEntry: Record "VAT Entry";
        UnrealizedVATEntry: Record "VAT Entry";
        AvailableAmount: Decimal;
    begin
        VATEntry.Get(GenJournalLine."Reinstatement VAT Entry No.");
        GenJournalLine.TestField(Amount);

        if Abs(GenJournalLine.Amount) > Abs(VATEntry.Amount) then
            Error(Text002, GenJournalLine.FieldCaption(Amount), VATEntry.Amount, GetJnlLineDescription(GenJournalLine));
        UnrealizedVATEntry.Get(VATEntry."Unrealized VAT Entry No.");
        if Abs(GenJournalLine.Amount) > Abs(UnrealizedVATEntry."Unrealized Amount") then
            Error(Text002, GenJournalLine.FieldCaption(Amount), UnrealizedVATEntry."Unrealized Amount", GetJnlLineDescription(GenJournalLine));
        if UnrealizedVATEntry."Unrealized Amount" = UnrealizedVATEntry."Remaining Unrealized Amount" then
            Error(
              Text004,
              UnrealizedVATEntry.TableCaption(),
              UnrealizedVATEntry.FieldCaption("Entry No."),
              UnrealizedVATEntry."Entry No.");
        AvailableAmount := UnrealizedVATEntry."Unrealized Amount" - UnrealizedVATEntry."Remaining Unrealized Amount";
        if Abs(GenJournalLine.Amount) > Abs(AvailableAmount) then
            Error(Text002, GenJournalLine.FieldCaption(Amount), AvailableAmount, GetJnlLineDescription(GenJournalLine));
    end;

    [Scope('OnPrem')]
    procedure CheckPostingDate(GenJournalLine: Record "Gen. Journal Line")
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.Get(GenJournalLine."Reinstatement VAT Entry No.");
        if GenJournalLine."Posting Date" < VATEntry."Posting Date" then
            Error(Text003, GenJournalLine.FieldCaption("Posting Date"), VATEntry."Posting Date", GetJnlLineDescription(GenJournalLine));
    end;

    local procedure GetJnlLineDescription(GenJournalLine: Record "Gen. Journal Line"): Text[250]
    begin
        exit(
          StrSubstNo('%1 %2=''%3'',%4=''%5'',%6=''%7''',
            GenJournalLine.TableCaption(),
            GenJournalLine.FieldCaption("Journal Template Name"),
            GenJournalLine."Journal Template Name",
            GenJournalLine.FieldCaption("Journal Batch Name"),
            GenJournalLine."Journal Batch Name",
            GenJournalLine.FieldCaption("Line No."),
            GenJournalLine."Line No."));
    end;

    local procedure IsAllowedVATCalcTypeForReinstatement(VATBase: Decimal; VATCalculationType: Enum "Tax Calculation Type"): Boolean
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        exit(
          (VATCalculationType = VATPostingSetup."VAT Calculation Type"::"Normal VAT") or
          ((VATBase = 0) and (VATCalculationType = VATPostingSetup."VAT Calculation Type"::"Full VAT")));
    end;

    local procedure CreateVATReinstJnlLinesExclDuplicatedEntriesByUnrealVATEntryNo(var GenJnlLine: Record "Gen. Journal Line"; var VATEntry: Record "VAT Entry"; EntryNo: Integer; PostingDate: Date; VATAmountFactor: Decimal; PostingDescription: Text[50])
    var
        TempVATEntry: Record "VAT Entry" temporary;
    begin
        VATEntry.SetCurrentKey(Type, "CV Ledg. Entry No.");
        VATEntry.SetRange("CV Ledg. Entry No.", EntryNo);
        VATEntry.SetFilter("Unrealized VAT Entry No.", '<>0');
        VATEntry.SetRange("Manual VAT Settlement", true);
        VATEntry.SetRange(Reversed, false);
        VATEntry.SetRange("VAT Reinstatement", false);
        VATEntry.SetRange("VAT Allocation Type", VATEntry."VAT Allocation Type"::VAT);
        if not VATEntry.FindSet() then
            exit;

        repeat
            TempVATEntry.SetRange("Unrealized VAT Entry No.", VATEntry."Unrealized VAT Entry No.");
            if TempVATEntry.FindFirst() then
                TempVATEntry.Delete();
            TempVATEntry := VATEntry;
            TempVATEntry.Insert();
        until VATEntry.Next() = 0;
        TempVATEntry.SetRange("Unrealized VAT Entry No.");

        if TempVATEntry.FindSet() then
            repeat
                CreateVATReinstatementJnlLine(
                  GenJnlLine,
                  TempVATEntry,
                  PostingDate,
                  Round(TempVATEntry.Amount * VATAmountFactor));
                if PostingDescription <> '' then begin
                    GenJnlLine.Description := PostingDescription;
                    GenJnlLine.Modify();
                end;
            until TempVATEntry.Next() = 0;
    end;
}

