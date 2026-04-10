codeunit 144710 "ERM INV-18 Report"
{
    TestPermissions = NonRestrictive;
    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        AmountType: Option " ",QtyPlus,AmountPlus,QtyMinus,AmountMinus;
        isInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure INV18_MultipleLinesWithDiffSign()
    var
        FixedAsset: Record "Fixed Asset";
        TempFAJournalLine: Record "FA Journal Line" temporary;
    begin
        Initialize();
        MockFixedAsset(FixedAsset);
        MockFAJournalLines(TempFAJournalLine, FixedAsset."No.");
        RunINV18Report();
        VerifyReportValuesFromBuffer(TempFAJournalLine);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        Clear(LibraryReportValidation);

        if isInitialized then
            exit;

        LibraryERMCountryData.UpdateGeneralPostingSetup();

        isInitialized := true;
        Commit();
    end;

    local procedure MockFixedAsset(var FixedAsset: Record "Fixed Asset")
    begin
        FixedAsset.Init();
        FixedAsset."No." := '';
        FixedAsset.Insert(true);
        FixedAsset."Manufacturing Year" := Format(Date2DMY(WorkDate(), 3));
        FixedAsset."Inventory Number" := LibraryUtility.GenerateGUID();
        FixedAsset."Factory No." := LibraryUtility.GenerateGUID();
        FixedAsset."Passport No." := LibraryUtility.GenerateGUID();
        FixedAsset.Modify();
    end;

    local procedure MockFAJournalLines(var TempFAJournalLine: Record "FA Journal Line"; FANo: Code[20])
    var
        FAJournalLine: Record "FA Journal Line";
        Qty: Decimal;
        Amount: Decimal;
        Factor: Integer;
        i: Integer;
    begin
        FilterFAJournalLineWithEmptyBatch(FAJournalLine);
        FAJournalLine.DeleteAll();
        Qty := LibraryRandom.RandDec(100, 2);
        Amount := LibraryRandom.RandDec(100, 2);
        Factor := LibraryRandom.RandIntInRange(3, 5);
        // Should not print because calc. value equal to actual value.
        MockFAJournalLine(TempFAJournalLine, FANo, Qty, Qty, Amount, Amount, false);
        for i := 1 to 2 do begin
            // Should print with minus quantity/amount values
            MockFAJournalLine(TempFAJournalLine, FANo, Qty, Round(Qty * Factor), Amount, Round(Amount * Factor), true);
            // Should print with plus quantity/amount values
            MockFAJournalLine(TempFAJournalLine, FANo, Round(Qty * Factor), Qty, Round(Amount * Factor), Amount, true);
        end;
    end;

    local procedure MockFAJournalLine(var TempFAJournalLine: Record "FA Journal Line"; FANo: Code[20]; CalcQty: Decimal; ActualQty: Decimal; CalcAmount: Decimal; ActualAmount: Decimal; AddLineToBuffer: Boolean)
    var
        FAJournalLine: Record "FA Journal Line";
        RecRef: RecordRef;
    begin
        FAJournalLine.Init();
        FAJournalLine."Journal Template Name" := '';
        FAJournalLine."Journal Batch Name" := '';
        RecRef.GetTable(FAJournalLine);
        FAJournalLine."Line No." := LibraryUtility.GetNewLineNo(RecRef, FAJournalLine.FieldNo("Line No."));
        FAJournalLine."FA No." := FANo;
        FAJournalLine.Description := LibraryUtility.GenerateGUID();
        FAJournalLine."Calc. Quantity" := CalcQty;
        FAJournalLine."Actual Quantity" := ActualQty;
        FAJournalLine."Calc. Amount" := CalcAmount;
        FAJournalLine."Actual Amount" := ActualAmount;
        FAJournalLine.Insert();
        if AddLineToBuffer then begin
            TempFAJournalLine := FAJournalLine;
            TempFAJournalLine.Insert();
        end;
    end;

    local procedure RunINV18Report()
    var
        FAJournalLine: Record "FA Journal Line";
        INV18Rep: Report "FA Comparative Sheet INV-18";
    begin
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());
        FilterFAJournalLineWithEmptyBatch(FAJournalLine);
        INV18Rep.SetFileNameSilent(LibraryReportValidation.GetFileName());
        INV18Rep.SetTableView(FAJournalLine);
        INV18Rep.UseRequestPage(false);
        INV18Rep.Run();
    end;

    local procedure FilterFAJournalLineWithEmptyBatch(var FAJournalLine: Record "FA Journal Line")
    begin
        FAJournalLine.SetRange("Journal Template Name", '');
        FAJournalLine.SetRange("Journal Batch Name", '');
    end;

    local procedure VerifyReportValuesFromBuffer(var TempFAJournalLine: Record "FA Journal Line" temporary)
    var
        FixedAsset: Record "Fixed Asset";
        RowShift: Integer;
        ValueArray: array[2, 4] of Decimal;
        i: Integer;
    begin
        RowShift := 0;
        TempFAJournalLine.FindSet();
        FixedAsset.Get(TempFAJournalLine."FA No.");
        repeat
            for i := 1 to ArrayLen(ValueArray, 2) do
                ValueArray[1, i] := 0;
            if TempFAJournalLine."Calc. Quantity" > TempFAJournalLine."Actual Quantity" then begin
                ValueArray[1, AmountType::AmountMinus] := TempFAJournalLine."Calc. Amount" - TempFAJournalLine."Actual Amount";
                ValueArray[1, AmountType::QtyMinus] := TempFAJournalLine."Calc. Quantity" - TempFAJournalLine."Actual Quantity";
            end else begin
                ValueArray[1, AmountType::AmountPlus] := TempFAJournalLine."Actual Amount" - TempFAJournalLine."Calc. Amount";
                ValueArray[1, AmountType::QtyPlus] := TempFAJournalLine."Actual Quantity" - TempFAJournalLine."Calc. Quantity";
            end;
            for i := 1 to ArrayLen(ValueArray, 2) do
                ValueArray[2, i] += ValueArray[1, i];
            VerifyLineValue(
              RowShift, TempFAJournalLine.Description, FixedAsset."Manufacturing Year", FixedAsset."Inventory Number", FixedAsset."Factory No.",
              FixedAsset."Passport No.", ValueArray[1], false);
            RowShift += 1;
        until TempFAJournalLine.Next() = 0;
        // Verify Footer
        VerifyLineValue(
          RowShift, '', '', '', '', '', ValueArray[2], true);
    end;

    local procedure VerifyLineValue(RowShift: Integer; Description: Text; ManufYear: Text; InventoryNumber: Text; FactoryNo: Text; PassportNo: Text; ValueArray: array[4] of Decimal; CheckTotalsOnly: Boolean)
    var
        LineRowId: Integer;
    begin
        LineRowId := 32 + RowShift;
        if not CheckTotalsOnly then begin
            LibraryReportValidation.VerifyCellValue(LineRowId, 1, Format(RowShift + 1));
            LibraryReportValidation.VerifyCellValue(LineRowId, 2, Description);
            LibraryReportValidation.VerifyCellValue(LineRowId, 6, ManufYear);
            LibraryReportValidation.VerifyCellValue(LineRowId, 9, InventoryNumber);
            LibraryReportValidation.VerifyCellValue(LineRowId, 11, FactoryNo);
            LibraryReportValidation.VerifyCellValue(LineRowId, 12, PassportNo);
        end;

        LibraryReportValidation.VerifyCellValue(LineRowId, 14, Format(ValueArray[AmountType::QtyPlus]));
        LibraryReportValidation.VerifyCellValue(LineRowId, 15, Format(ValueArray[AmountType::AmountPlus]));
        LibraryReportValidation.VerifyCellValue(LineRowId, 19, Format(ValueArray[AmountType::QtyMinus]));
        LibraryReportValidation.VerifyCellValue(LineRowId, 22, Format(ValueArray[AmountType::AmountMinus]));
    end;
}

