codeunit 144183 "MIR Fin. Charge Memo"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Fin. Charge Memo] [Multiple Interest Rates]
    end;

    var
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        Assert: Codeunit Assert;
        WrongRowErr: Label 'Line should be hidden.';

    [Test]
    [HandlerFunctions('FinChargeMemoRequestHandler')]
    [Scope('OnPrem')]
    procedure VerifyTotalWithMultipleInterestRates()
    begin
        ExportFinChargeMemoAndVerify(true);
    end;

    [Test]
    [HandlerFunctions('FinChargeMemoRequestHandler')]
    [Scope('OnPrem')]
    procedure VerifyTotalWithoutMultipleInterestRates()
    begin
        ExportFinChargeMemoAndVerify(false);
    end;

    [Test]
    [HandlerFunctions('FinChargeMemoReqHandler')]
    [Scope('OnPrem')]
    procedure CheckTotalWithMultipleInterestRates()
    var
        TotalAmount: Decimal;
        FinChargeMemoNo: Code[20];
        AmountLine: array[5] of Decimal;
        AmountMIRLine: array[5] of Decimal;
    begin
        // [SCENARIO 377597] Total sum should be correct in report Finance Charge Memo when parameter "Show MIR Detail" = TRUE
        Initialize();

        // [GIVEN] Issued Finance Charge Memo Lines with "MIR Entry" = FALSE of amount = "X"
        // [GIVEN] Issued Finance Charge Memo Lines with "MIR Entry" = TRUE of amount = "Y"
        TotalAmount := CreateIssuedFinanceChargeMemo(FinChargeMemoNo, 5, AmountLine, AmountMIRLine);
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());

        // [WHEN] Invoke report "Finance Charge Memo" with "Show MIR Detail" = TRUE
        RunFinChargeMemoReport(FinChargeMemoNo, true);

        // [THEN] Total in report is equal "X"
        VerifyAmountsWithMIREntry(TotalAmount, AmountLine, AmountMIRLine);
    end;

    [Test]
    [HandlerFunctions('FinChargeMemoReqHandler')]
    [Scope('OnPrem')]
    procedure CheckTotalWithoutMultipleInterestRates()
    var
        TotalAmount: Decimal;
        FinChargeMemoNo: Code[20];
        AmountLine: array[5] of Decimal;
        AmountMIRLine: array[5] of Decimal;
    begin
        // [SCENARIO 377597] Total sum should be correct in report Finance Charge Memo when parameter "Show MIR Detail" = FALSE
        Initialize();

        // [GIVEN] Issued Finance Charge Memo Lines with "MIR Entry" = FALSE of amount = "X"
        // [GIVEN] Issued Finance Charge Memo Lines with "MIR Entry" = TRUE of amount = "Y"
        TotalAmount := CreateIssuedFinanceChargeMemo(FinChargeMemoNo, 5, AmountLine, AmountMIRLine);
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());

        // [WHEN] Invoke report "Finance Charge Memo" with "Show MIR Detail" = FALSE
        RunFinChargeMemoReport(FinChargeMemoNo, false);

        // [THEN] Total in report is equal "X"
        VerifyAmountsWithoutMIREntry(TotalAmount, AmountLine, AmountMIRLine);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
        Clear(LibraryReportDataset);
        Clear(LibraryReportValidation);
    end;

    local procedure CreateIssuedFinanceChargeMemo(var IssuedFinChargeMemoNo: Code[20]; CountOfLines: Integer; var AmountLine: array[5] of Decimal; var AmountMIRLine: array[5] of Decimal) TotalAmountOfLines: Decimal
    var
        Customer: Record Customer;
        IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header";
        I: Integer;
    begin
        LibrarySales.CreateCustomer(Customer);
        IssuedFinChargeMemoNo := CreateIssuedFinChargeMemoHeader(IssuedFinChargeMemoHeader, Customer);

        for I := 1 to CountOfLines do begin
            AmountLine[I] := CreateIssuedFinChargeMemoLine(IssuedFinChargeMemoHeader."No.", false);
            TotalAmountOfLines += AmountLine[I];
            AmountMIRLine[I] := CreateIssuedFinChargeMemoLine(IssuedFinChargeMemoHeader."No.", true);
        end;
    end;

    local procedure CreateIssuedFinChargeMemoHeader(var IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header"; Customer: Record Customer): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        IssuedFinChargeMemoHeader.Init();
        IssuedFinChargeMemoHeader.Validate("No.", LibraryUtility.GenerateRandomCode(IssuedFinChargeMemoHeader.FieldNo("No."), DATABASE::"Issued Fin. Charge Memo Header"));
        IssuedFinChargeMemoHeader.Validate("Customer No.", Customer."No.");
        IssuedFinChargeMemoHeader.Validate("Customer Posting Group", Customer."Customer Posting Group");

        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        IssuedFinChargeMemoHeader.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        IssuedFinChargeMemoHeader.Insert(true);
        exit(IssuedFinChargeMemoHeader."No.");
    end;

    local procedure CreateIssuedFinChargeMemoLine(IssuedFinChargeMemoNo: Code[20]; MIREntry: Boolean): Decimal
    var
        IssuedFinChargeMemoLine: Record "Issued Fin. Charge Memo Line";
        RecRef: RecordRef;
    begin
        IssuedFinChargeMemoLine.Init();
        IssuedFinChargeMemoLine.Validate("Finance Charge Memo No.", IssuedFinChargeMemoNo);
        RecRef.GetTable(IssuedFinChargeMemoLine);
        IssuedFinChargeMemoLine.Validate("Line No.", LibraryUtility.GetNewLineNo(RecRef, IssuedFinChargeMemoLine.FieldNo("Line No.")));
        IssuedFinChargeMemoLine.Insert(true);

        IssuedFinChargeMemoLine.Validate(Type, IssuedFinChargeMemoLine.Type::"G/L Account");
        IssuedFinChargeMemoLine.Validate("Detailed Interest Rates Entry", MIREntry);
        IssuedFinChargeMemoLine.Validate(Amount, LibraryRandom.RandDecInRange(1000, 5000, 2));
        IssuedFinChargeMemoLine.Modify(true);
        exit(IssuedFinChargeMemoLine.Amount);
    end;

    local procedure ExportFinChargeMemoAndVerify(ShowMIRDetail: Boolean)
    var
        FinChargeMemoNo: Code[20];
        AmountLineDummy: array[5] of Decimal;
        AmountMIRLineDummy: array[5] of Decimal;
    begin
        Initialize();

        CreateIssuedFinanceChargeMemo(FinChargeMemoNo, LibraryRandom.RandIntInRange(2, 5), AmountLineDummy, AmountMIRLineDummy);
        RunFinChargeMemoReport(FinChargeMemoNo, ShowMIRDetail);
        VerifyFinChargeMemoAmount(FinChargeMemoNo, ShowMIRDetail);
    end;

    local procedure RunFinChargeMemoReport(FinChargeMemoNo: Code[20]; ShowMIRDetail: Boolean)
    begin
        LibraryVariableStorage.Enqueue(FinChargeMemoNo);
        LibraryVariableStorage.Enqueue(ShowMIRDetail);

        Commit();
        REPORT.Run(REPORT::"Finance Charge Memo");
    end;

    local procedure VerifyFinChargeMemoAmount(IssuedFinChargeMemoNo: Code[20]; ShowMIRDetail: Boolean)
    var
        IssuedFinChargeMemoLine: Record "Issued Fin. Charge Memo Line";
    begin
        LibraryReportDataset.LoadDataSetFile();

        IssuedFinChargeMemoLine.SetRange("Finance Charge Memo No.", IssuedFinChargeMemoNo);
        IssuedFinChargeMemoLine.FindSet();
        repeat
            if ShowMIRDetail or not IssuedFinChargeMemoLine."Detailed Interest Rates Entry" then
                LibraryReportDataset.AssertElementWithValueExists('LineNo_IssuFinChrgMemoLine', IssuedFinChargeMemoLine."Line No.")
            else
                LibraryReportDataset.AssertElementWithValueNotExist('LineNo_IssuFinChrgMemoLine', IssuedFinChargeMemoLine."Line No.")
        until IssuedFinChargeMemoLine.Next() = 0;
    end;

    local procedure VerifyAmountsWithMIREntry(TotalAmount: Decimal; AmountLine: array[5] of Decimal; AmountMIRLine: array[5] of Decimal)
    var
        i: Integer;
    begin
        LibraryReportValidation.OpenExcelFile();
        for i := 1 to ArrayLen(AmountLine) do begin
            LibraryReportValidation.VerifyCellValueOnWorksheet(
              63 + 2 * i, 13, LibraryReportValidation.FormatDecimalValue(AmountLine[i]), '1');
            LibraryReportValidation.VerifyCellValueOnWorksheet(
              64 + 2 * i, 13, LibraryReportValidation.FormatDecimalValue(AmountMIRLine[i]), '1');
        end;

        LibraryReportValidation.VerifyCellValueOnWorksheet(77, 13, LibraryReportValidation.FormatDecimalValue(TotalAmount), '1');
    end;

    local procedure VerifyAmountsWithoutMIREntry(TotalAmount: Decimal; AmountLine: array[5] of Decimal; AmountMIRLine: array[5] of Decimal)
    var
        i: Integer;
    begin
        LibraryReportValidation.OpenExcelFile();
        for i := 1 to ArrayLen(AmountLine) do begin
            LibraryReportValidation.VerifyCellValueOnWorksheet(64 + i, 13, LibraryReportValidation.FormatDecimalValue(AmountLine[i]), '1');
            Assert.IsFalse(LibraryReportValidation.CheckIfDecimalValueExists(AmountMIRLine[i]), WrongRowErr);
        end;

        LibraryReportValidation.VerifyCellValueOnWorksheet(72, 13, LibraryReportValidation.FormatDecimalValue(TotalAmount), '1');
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure FinChargeMemoRequestHandler(var FinChargeMemoReport: TestRequestPage "Finance Charge Memo")
    begin
        FinChargeMemoReport."Issued Fin. Charge Memo Header".SetFilter("No.", LibraryVariableStorage.DequeueText());
        FinChargeMemoReport.ShowInternalInformation.SetValue(false);
        FinChargeMemoReport.LogInteraction.SetValue(false);
        FinChargeMemoReport.ShowMIR.SetValue(LibraryVariableStorage.DequeueBoolean());
        FinChargeMemoReport.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure FinChargeMemoReqHandler(var FinChargeMemoReport: TestRequestPage "Finance Charge Memo")
    begin
        FinChargeMemoReport."Issued Fin. Charge Memo Header".SetFilter("No.", LibraryVariableStorage.DequeueText());
        FinChargeMemoReport.ShowMIR.SetValue(LibraryVariableStorage.DequeueBoolean());
        FinChargeMemoReport.SaveAsExcel(LibraryReportValidation.GetFileName());
    end;
}

