codeunit 144721 "ERM Tax Register Report"
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
        StdRepMgt: Codeunit "Local Report Management";
        Assert: Codeunit Assert;
        isInitialized: Boolean;
        ValueNotExistErr: Label 'Value not exist in worksheet no. %1', Comment = '%1 - row % 2 - column';

    [Test]
    [Scope('OnPrem')]
    procedure TaxRegisterWithMultipleAccumLines()
    var
        TaxRegister: Record "Tax Register";
        TaxRegtemEntry: Record "Tax Register Item Entry";
        TotalAmount: Decimal;
        i: Integer;
    begin
        Initialize();

        MockTaxRegister(TaxRegister);
        for i := 1 to LibraryRandom.RandIntInRange(3, 5) do
            TotalAmount += MockTaxRegAccumLine(TaxRegister);
        MockTaxRegisterEntries(TaxRegtemEntry, TaxRegister, TotalAmount);
        RunTaxRegisterReport(TaxRegister);
        VerifyReportValues(TaxRegister, TaxRegtemEntry);
    end;

    local procedure Initialize()
    begin
        Clear(LibraryReportValidation);

        if isInitialized then
            exit;

        isInitialized := true;
    end;

    local procedure MockTaxRegSection(): Code[10]
    var
        TaxRegSection: Record "Tax Register Section";
    begin
        TaxRegSection.Init();
        TaxRegSection.Code := LibraryUtility.GenerateGUID();
        TaxRegSection.Insert();
        exit(TaxRegSection.Code);
    end;

    local procedure MockTaxRegister(var TaxRegister: Record "Tax Register")
    begin
        TaxRegister.Init();
        TaxRegister."Section Code" := MockTaxRegSection();
        TaxRegister."No." := LibraryUtility.GenerateGUID();
        TaxRegister.Description := TaxRegister."No.";
        TaxRegister."Table ID" := DATABASE::"Tax Register Item Entry";
        TaxRegister.Insert();
    end;

    local procedure MockTaxRegAccumLine(TaxRegister: Record "Tax Register"): Decimal
    var
        TaxRegAccum: Record "Tax Register Accumulation";
        RecRef: RecordRef;
    begin
        TaxRegAccum.Init();
        RecRef.GetTable(TaxRegAccum);
        TaxRegAccum."Entry No." := LibraryUtility.GetNewLineNo(RecRef, TaxRegAccum.FieldNo("Entry No."));
        TaxRegAccum."Section Code" := TaxRegister."Section Code";
        TaxRegAccum."Tax Register No." := TaxRegister."No.";
        TaxRegAccum."Starting Date" := WorkDate();
        TaxRegAccum."Ending Date" := CalcDate('<1D>', TaxRegAccum."Starting Date");
        TaxRegAccum.Description := LibraryUtility.GenerateGUID();
        TaxRegAccum.Amount := LibraryRandom.RandDec(100, 2);
        TaxRegAccum.Insert();
        exit(TaxRegAccum.Amount);
    end;

    local procedure MockTaxRegisterEntries(var TaxRegtemEntry: Record "Tax Register Item Entry"; TaxRegister: Record "Tax Register"; TotalAmount: Decimal)
    var
        RecRef: RecordRef;
    begin
        TaxRegtemEntry.Init();
        RecRef.GetTable(TaxRegtemEntry);
        TaxRegtemEntry."Entry No." := LibraryUtility.GetNewLineNo(RecRef, TaxRegtemEntry.FieldNo("Entry No."));
        TaxRegtemEntry."Section Code" := TaxRegister."Section Code";
        TaxRegtemEntry."Where Used Register IDs" := TaxRegister."No.";
        // Outside of period entry that should not be print.
        TaxRegtemEntry."Starting Date" := CalcDate('<CM+1M>', WorkDate());
        TaxRegtemEntry."Ending Date" := CalcDate('<1D>', TaxRegtemEntry."Starting Date");
        TaxRegtemEntry."Amount (Document)" := TotalAmount;
        TaxRegtemEntry."Document No." := LibraryUtility.GenerateGUID();
        TaxRegtemEntry.Insert();
        // Inside of period.
        TaxRegtemEntry."Entry No." := LibraryUtility.GetNewLineNo(RecRef, TaxRegtemEntry.FieldNo("Entry No."));
        TaxRegtemEntry."Starting Date" := WorkDate();
        TaxRegtemEntry."Ending Date" := CalcDate('<1D>', TaxRegtemEntry."Starting Date");
        TaxRegtemEntry.Insert();
    end;

    local procedure RunTaxRegisterReport(var TaxRegister: Record "Tax Register")
    var
        TaxRegisterRep: Report "Tax Register";
    begin
        TaxRegister.SetRecFilter();
        TaxRegister.SetFilter(
          "Date Filter", '%1..%2', CalcDate('<-CM>', WorkDate()), CalcDate('<CM>', WorkDate()));

        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());
        TaxRegisterRep.SetFileNameSilent(LibraryReportValidation.GetFileName());
        TaxRegisterRep.InitializeRequest(true);
        TaxRegisterRep.SetTableView(TaxRegister);
        TaxRegisterRep.UseRequestPage(false);
        TaxRegisterRep.Run();
    end;

    local procedure VerifyReportValues(var TaxRegister: Record "Tax Register"; TaxRegisterEntry: Record "Tax Register Item Entry")
    var
        TaxRegAccum: Record "Tax Register Accumulation";
        i: Integer;
    begin
        LibraryReportValidation.VerifyCellValue(4, 1, TaxRegister.Description);
        LibraryReportValidation.VerifyCellValue(2, 2, Format(TaxRegister.GetFilter("Date Filter")));

        TaxRegAccum.SetRange("Section Code", TaxRegister."Section Code");
        TaxRegAccum.SetRange("Tax Register No.", TaxRegister."No.");
        TaxRegAccum.FindSet();
        repeat
            VerifyLineValue(i, TaxRegAccum.Description, StdRepMgt.FormatReportValue(TaxRegAccum.Amount, 2));
            i += 1;
        until TaxRegAccum.Next() = 0;
        // Verify Footer
        LibraryReportValidation.VerifyCellValue(7 + i, 4, StdRepMgt.FormatReportValue(TaxRegisterEntry."Amount (Document)", 2));
        VerifyDetails(TaxRegisterEntry);
    end;

    local procedure VerifyLineValue(RowShift: Integer; Description: Text; Amount: Text)
    var
        LineRowId: Integer;
    begin
        LineRowId := 7 + RowShift;
        LibraryReportValidation.VerifyCellValue(LineRowId, 1, Format(RowShift + 1));
        LibraryReportValidation.VerifyCellValue(LineRowId, 2, Description);
        LibraryReportValidation.VerifyCellValue(LineRowId, 4, Amount);
    end;

    local procedure VerifyDetails(TaxRegisterEntry: Record "Tax Register Item Entry")
    begin
        CheckIfValueExistsOnSpecificWorksheet(Format(TaxRegisterEntry."Entry No."));
        CheckIfValueExistsOnSpecificWorksheet(TaxRegisterEntry."Section Code");
        CheckIfValueExistsOnSpecificWorksheet(TaxRegisterEntry."Where Used Register IDs");
        CheckIfValueExistsOnSpecificWorksheet(Format(TaxRegisterEntry."Amount (Document)"));
        CheckIfValueExistsOnSpecificWorksheet(TaxRegisterEntry."Document No.");
    end;

    local procedure CheckIfValueExistsOnSpecificWorksheet(Value: Text)
    var
        WorksheetNo: Integer;
    begin
        WorksheetNo := 2;
        Assert.IsTrue(
          LibraryReportValidation.CheckIfValueExistsOnSpecifiedWorksheet(WorksheetNo, Value),
          StrSubstNo(ValueNotExistErr, WorksheetNo));
    end;
}

