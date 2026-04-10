codeunit 134928 "ERM MIR Reports"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [ERM] [Fin. Charge Memo] [Multiple Interest Rates]
    end;

    var
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibraryFinanceChargeMemo: Codeunit "Library - Finance Charge Memo";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        WrongRowErr: Label 'Line should be hidden.';
        IsInitialized: Boolean;
        AmountNotFoundErr: Label 'Amount not found.';

    [Test]
    [HandlerFunctions('FinChargeMemoRequestHandler')]
    [Scope('OnPrem')]
    procedure VerifyTotalWithMultipleInterestRates()
    begin
        // [SCENARIO] Multiple interest rates lines should be printed in report Finance Charge Memo when parameter "Show MIR Detail" = TRUE
        // [GIVEN] Issued Finance Charge Memo which contains multiple interest rates lines
        // [WHEN] Invoke report "Finance Charge Memo" with "Show MIR Detail" = TRUE
        // [THEN] Multiple interest rates lines printed
        ExportFinChargeMemoAndVerify(true);
    end;

    [Test]
    [HandlerFunctions('FinChargeMemoRequestHandler')]
    [Scope('OnPrem')]
    procedure VerifyTotalWithoutMultipleInterestRates()
    begin
        // [SCENARIO] Multiple interest rates lines should not be printed in report Finance Charge Memo when parameter "Show MIR Detail" = TRUE
        // [GIVEN] Issued Finance Charge Memo which contains multiple interest rates lines
        // [WHEN] Invoke report "Finance Charge Memo" with "Show MIR Detail" = FALSE
        // [THEN] Multiple interest rates lines not printed
        ExportFinChargeMemoAndVerify(false);
    end;

    [Test]
    [HandlerFunctions('ReminderTestReqHandler')]
    [Scope('OnPrem')]
    procedure ReminderCheckTotalWithMIR()
    var
        TotalAmount: Decimal;
        ReminderNo: Code[20];
        AmountLine: array[5] of Decimal;
        AmountMIRLine: array[5] of Decimal;
    begin
        // [SCENARIO] Total sum should be correct in report Reminder - Test when parameter "Show MIR Detail" = TRUE
        Initialize();

        // [GIVEN] Finance Charge Memo Lines with "MIR Entry" = FALSE of amount = "X"
        // [GIVEN] Finance Charge Memo Lines with "MIR Entry" = TRUE of amount = "Y"
        TotalAmount := CreateReminder(ReminderNo, 5, AmountLine, AmountMIRLine);
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());

        // [WHEN] Invoke report "Reminder - Test" with "Show MIR Detail" = TRUE
        RunReminderTestReport(ReminderNo, true);

        // [THEN] Total in report is equal "X"
        VerifyAmountsWithMIREntry(TotalAmount, AmountLine, AmountMIRLine);
    end;

    [Test]
    [HandlerFunctions('ReminderTestReqHandler')]
    [Scope('OnPrem')]
    procedure ReminderCheckTotalWithoutMIR()
    var
        TotalAmount: Decimal;
        ReminderNo: Code[20];
        AmountLine: array[5] of Decimal;
        AmountMIRLine: array[5] of Decimal;
    begin
        // [SCENARIO] Total sum should be correct in report Reminder - Test when parameter "Show MIR Detail" = FALSE
        Initialize();

        // [GIVEN] Finance Charge Memo Lines with "MIR Entry" = FALSE of amount = "X"
        // [GIVEN] Finance Charge Memo Lines with "MIR Entry" = TRUE of amount = "Y"
        TotalAmount := CreateReminder(ReminderNo, 5, AmountLine, AmountMIRLine);
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());

        // [WHEN] Invoke report "Reminder - Test" with "Show MIR Detail" = FALSE
        RunReminderTestReport(ReminderNo, false);

        // [THEN] Total in report is equal "X"
        // [THEN] Multiple interest rates lines not printed
        VerifyAmountsWithoutMIREntry(TotalAmount, AmountLine, AmountMIRLine);
    end;

    [HandlerFunctions('ReminderReqHandler')]
    [Scope('OnPrem')]
    procedure IssuedReminderCheckTotalWithMIR()
    var
        TotalAmount: Decimal;
        ReminderNo: Code[20];
        AmountLine: array[5] of Decimal;
        AmountMIRLine: array[5] of Decimal;
    begin
        // [SCENARIO] Total sum should be correct in report Reminder when parameter "Show MIR Detail" = TRUE
        Initialize();

        // [GIVEN] Finance Charge Memo Lines with "MIR Entry" = FALSE of amount = "X"
        // [GIVEN] Finance Charge Memo Lines with "MIR Entry" = TRUE of amount = "Y"
        TotalAmount := CreateIssuedReminder(ReminderNo, 5, AmountLine, AmountMIRLine);
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());

        // [WHEN] Invoke report "Reminder" with "Show MIR Detail" = TRUE
        RunReminderReport(ReminderNo, true);

        // [THEN] Total in report is equal "X"
        VerifyAmountsWithMIREntry(TotalAmount, AmountLine, AmountMIRLine);
    end;

    [HandlerFunctions('ReminderReqHandler')]
    [Scope('OnPrem')]
    procedure IssuedReminderCheckTotalWithoutMIR()
    var
        TotalAmount: Decimal;
        ReminderNo: Code[20];
        AmountLine: array[5] of Decimal;
        AmountMIRLine: array[5] of Decimal;
    begin
        // [SCENARIO] Total sum should be correct in report Reminder when parameter "Show MIR Detail" = FALSE
        Initialize();

        // [GIVEN] Finance Charge Memo Lines with "MIR Entry" = FALSE of amount = "X"
        // [GIVEN] Finance Charge Memo Lines with "MIR Entry" = TRUE of amount = "Y"
        TotalAmount := CreateIssuedReminder(ReminderNo, 5, AmountLine, AmountMIRLine);
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());

        // [WHEN] Invoke report "Reminder" with "Show MIR Detail" = FALSE
        RunReminderReport(ReminderNo, false);

        // [THEN] Total in report is equal "X"
        // [THEN] Multiple interest rates lines not printed
        VerifyAmountsWithoutMIREntry(TotalAmount, AmountLine, AmountMIRLine);
    end;

    [Test]
    [HandlerFunctions('FinChargeMemoTestReqHandler')]
    [Scope('OnPrem')]
    procedure FinanceChargeMemoCheckTotalWithMIR()
    var
        TotalAmount: Decimal;
        FinChargeMemoNo: Code[20];
        AmountLine: array[5] of Decimal;
        AmountMIRLine: array[5] of Decimal;
    begin
        // [SCENARIO] Total sum should be correct in report Finance Charge Memo - Test when parameter "Show MIR Detail" = TRUE
        Initialize();

        // [GIVEN] Finance Charge Memo Lines with "MIR Entry" = FALSE of amount = "X"
        // [GIVEN] Finance Charge Memo Lines with "MIR Entry" = TRUE of amount = "Y"
        TotalAmount := CreateFinanceChargeMemo(FinChargeMemoNo, 5, AmountLine, AmountMIRLine);
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());

        // [WHEN] Invoke report "Finance Charge Memo" with "Show MIR Detail" = TRUE
        RunFinChargeMemoTestReport(FinChargeMemoNo, true);

        // [THEN] Total in report is equal "X"
        VerifyAmountsWithMIREntry(TotalAmount, AmountLine, AmountMIRLine);
    end;

    [Test]
    [HandlerFunctions('FinChargeMemoTestReqHandler')]
    [Scope('OnPrem')]
    procedure FinanceChargeMemoCheckTotalWithoutMIR()
    var
        TotalAmount: Decimal;
        FinChargeMemoNo: Code[20];
        AmountLine: array[5] of Decimal;
        AmountMIRLine: array[5] of Decimal;
    begin
        // [SCENARIO] Total sum should be correct in report Finance Charge Memo - Test when parameter "Show MIR Detail" = FALSE
        Initialize();

        // [GIVEN] Finance Charge Memo Lines with "MIR Entry" = FALSE of amount = "X"
        // [GIVEN] Finance Charge Memo Lines with "MIR Entry" = TRUE of amount = "Y"
        TotalAmount := CreateFinanceChargeMemo(FinChargeMemoNo, 5, AmountLine, AmountMIRLine);
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());

        // [WHEN] Invoke report "Finance Charge Memo" with "Show MIR Detail" = FALSE
        RunFinChargeMemoTestReport(FinChargeMemoNo, false);

        // [THEN] Total in report is equal "X"
        // [THEN] Multiple interest rates lines not printed
        VerifyAmountsWithoutMIREntry(TotalAmount, AmountLine, AmountMIRLine);
    end;

    [Test]
    [HandlerFunctions('FinChargeMemoReqHandler')]
    [Scope('OnPrem')]
    procedure IssuedFinanceChargeMemoCheckTotalWithMIR()
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
    procedure IssuedFinanceChargeMemoCheckTotalWithoutMIR()
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
        // [THEN] Multiple interest rates lines not printed
        VerifyAmountsWithoutMIREntry(TotalAmount, AmountLine, AmountMIRLine);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM MIR Reports");
        LibraryVariableStorage.Clear();
        Clear(LibraryReportDataset);
        Clear(LibraryReportValidation);

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM MIR Reports");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        IsInitialized := true;

        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM MIR Reports");
    end;

    local procedure CreateFinanceChargeMemo(var FinChargeMemoNo: Code[20]; CountOfLines: Integer; var AmountLine: array[5] of Decimal; var AmountMIRLine: array[5] of Decimal) TotalAmountOfLines: Decimal
    var
        Customer: Record Customer;
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        FinanceChargeTerms: Record "Finance Charge Terms";
        I: Integer;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryFinanceChargeMemo.CreateFinanceChargeTermAndText(FinanceChargeTerms);
        Customer.Validate("Fin. Charge Terms Code", FinanceChargeTerms.Code);
        Customer.Modify(true);
        LibraryERM.CreateFinanceChargeMemoHeader(FinanceChargeMemoHeader, Customer."No.");
        FinChargeMemoNo := FinanceChargeMemoHeader."No.";
        for I := 1 to CountOfLines do begin
            AmountLine[I] := CreateFinChargeMemoLine(FinanceChargeMemoHeader."No.", false);
            TotalAmountOfLines += AmountLine[I];
            AmountMIRLine[I] := CreateFinChargeMemoLine(FinanceChargeMemoHeader."No.", true);
        end;
    end;

    local procedure CreateFinChargeMemoLine(FinChargeMemoNo: Code[20]; MIREntry: Boolean): Decimal
    var
        FinanceChargeMemoLine: Record "Finance Charge Memo Line";
    begin
        LibraryERM.CreateFinanceChargeMemoLine(
          FinanceChargeMemoLine, FinChargeMemoNo, FinanceChargeMemoLine.Type::"Customer Ledger Entry");
        FinanceChargeMemoLine.Validate("Detailed Interest Rates Entry", MIREntry);
        FinanceChargeMemoLine.Validate(Amount, LibraryRandom.RandDecInRange(1000, 5000, 2));
        FinanceChargeMemoLine.Modify(true);
        exit(FinanceChargeMemoLine.Amount);
    end;

    local procedure CreateIssuedFinanceChargeMemo(var IssuedFinChargeMemoNo: Code[20]; CountOfLines: Integer; var AmountLine: array[5] of Decimal; var AmountMIRLine: array[5] of Decimal) TotalAmountOfLines: Decimal
    var
        Customer: Record Customer;
        VATPostingSetup: Record "VAT Posting Setup";
        IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header";
        I: Integer;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");

        IssuedFinChargeMemoNo :=
          CreateIssuedFinChargeMemoHeader(IssuedFinChargeMemoHeader, Customer, VATPostingSetup."VAT Bus. Posting Group");

        for I := 1 to CountOfLines do begin
            AmountLine[I] :=
              CreateIssuedFinChargeMemoLine(IssuedFinChargeMemoHeader."No.", VATPostingSetup."VAT Prod. Posting Group", false);
            TotalAmountOfLines += AmountLine[I];
            AmountMIRLine[I] :=
              CreateIssuedFinChargeMemoLine(IssuedFinChargeMemoHeader."No.", VATPostingSetup."VAT Prod. Posting Group", true);
        end;
    end;

    local procedure CreateIssuedFinChargeMemoHeader(var IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header"; Customer: Record Customer; VATBusPostingGroupCode: Code[20]): Code[20]
    begin
        IssuedFinChargeMemoHeader.Init();
        IssuedFinChargeMemoHeader.Validate("No.", LibraryUtility.GenerateRandomCode(IssuedFinChargeMemoHeader.FieldNo("No."), DATABASE::"Issued Fin. Charge Memo Header"));
        IssuedFinChargeMemoHeader.Validate("Customer No.", Customer."No.");
        IssuedFinChargeMemoHeader.Validate("Customer Posting Group", Customer."Customer Posting Group");
        IssuedFinChargeMemoHeader.Validate("VAT Bus. Posting Group", VATBusPostingGroupCode);
        IssuedFinChargeMemoHeader.Insert(true);
        exit(IssuedFinChargeMemoHeader."No.");
    end;

    local procedure CreateIssuedFinChargeMemoLine(IssuedFinChargeMemoNo: Code[20]; VATProdPostingGroupCode: Code[20]; MIREntry: Boolean): Decimal
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
        IssuedFinChargeMemoLine.Validate("VAT Prod. Posting Group", VATProdPostingGroupCode);
        IssuedFinChargeMemoLine.Validate(Amount, LibraryRandom.RandDecInRange(1000, 5000, 2));
        IssuedFinChargeMemoLine.Modify(true);
        exit(IssuedFinChargeMemoLine.Amount);
    end;

    local procedure CreateReminder(var ReminderNo: Code[20]; CountOfLines: Integer; var AmountLine: array[5] of Decimal; var AmountMIRLine: array[5] of Decimal) TotalAmountOfLines: Decimal
    var
        Customer: Record Customer;
        ReminderHeader: Record "Reminder Header";
        FinanceChargeTerms: Record "Finance Charge Terms";
        I: Integer;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryFinanceChargeMemo.CreateFinanceChargeTermAndText(FinanceChargeTerms);
        Customer.Validate("Fin. Charge Terms Code", FinanceChargeTerms.Code);
        Customer.Modify(true);
        LibraryERM.CreateReminderHeader(ReminderHeader);
        ReminderHeader.Validate("Customer No.", Customer."No.");
        ReminderHeader.Modify(true);
        ReminderNo := ReminderHeader."No.";
        for I := 1 to CountOfLines do begin
            AmountLine[I] := CreateReminderLine(ReminderNo, false);
            TotalAmountOfLines += AmountLine[I];
            AmountMIRLine[I] := CreateReminderLine(ReminderNo, true);
        end;
    end;

    local procedure CreateReminderLine(ReminderNo: Code[20]; MIREntry: Boolean): Decimal
    var
        ReminderLine: Record "Reminder Line";
    begin
        LibraryERM.CreateReminderLine(
          ReminderLine, ReminderNo, ReminderLine.Type::"Customer Ledger Entry");
        ReminderLine.Validate("Detailed Interest Rates Entry", MIREntry);
        ReminderLine.Validate("Remaining Amount", LibraryRandom.RandDecInRange(1000, 5000, 2));
        ReminderLine.Modify(true);
        exit(ReminderLine."Remaining Amount");
    end;

    local procedure CreateIssuedReminder(var ReminderNo: Code[20]; CountOfLines: Integer; var AmountLine: array[5] of Decimal; var AmountMIRLine: array[5] of Decimal) TotalAmountOfLines: Decimal
    var
        Customer: Record Customer;
        IssuedReminderHeader: Record "Issued Reminder Header";
        FinanceChargeTerms: Record "Finance Charge Terms";
        I: Integer;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryFinanceChargeMemo.CreateFinanceChargeTermAndText(FinanceChargeTerms);
        Customer.Validate("Fin. Charge Terms Code", FinanceChargeTerms.Code);
        Customer.Modify(true);
        ReminderNo := CreateIssuedReminderHeader(IssuedReminderHeader, Customer);
        for I := 1 to CountOfLines do begin
            AmountLine[I] := CreateIssuedReminderLine(ReminderNo, false);
            TotalAmountOfLines += AmountLine[I];
            AmountMIRLine[I] := CreateIssuedReminderLine(ReminderNo, true);
        end;
    end;

    local procedure CreateIssuedReminderHeader(var IssuedReminderHeader: Record "Issued Reminder Header"; Customer: Record Customer): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        IssuedReminderHeader.Init();
        IssuedReminderHeader.Validate("No.", LibraryUtility.GenerateRandomCode(IssuedReminderHeader.FieldNo("No."), DATABASE::"Issued Reminder Header"));
        IssuedReminderHeader.Validate("Customer No.", Customer."No.");
        IssuedReminderHeader.Validate("Customer Posting Group", Customer."Customer Posting Group");

        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        IssuedReminderHeader.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        IssuedReminderHeader.Insert(true);
        exit(IssuedReminderHeader."No.");
    end;

    local procedure CreateIssuedReminderLine(ReminderNo: Code[20]; MIREntry: Boolean): Decimal
    var
        IssuedReminderLine: Record "Issued Reminder Line";
        RecRef: RecordRef;
    begin
        IssuedReminderLine.Init();
        IssuedReminderLine.Validate("Reminder No.", ReminderNo);
        RecRef.GetTable(IssuedReminderLine);
        IssuedReminderLine.Validate("Line No.", LibraryUtility.GetNewLineNo(RecRef, IssuedReminderLine.FieldNo("Line No.")));
        IssuedReminderLine.Insert(true);
        IssuedReminderLine.Validate(Type, IssuedReminderLine.Type::"Customer Ledger Entry");
        IssuedReminderLine.Validate("Detailed Interest Rates Entry", MIREntry);
        IssuedReminderLine.Validate("Remaining Amount", LibraryRandom.RandDecInRange(1000, 5000, 2));
        IssuedReminderLine.Validate("No. of Reminders", 1);
        IssuedReminderLine.Modify(true);
        exit(IssuedReminderLine."Remaining Amount");
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

    local procedure RunFinChargeMemoTestReport(FinChargeMemoNo: Code[20]; ShowMIRDetail: Boolean)
    begin
        LibraryVariableStorage.Enqueue(FinChargeMemoNo);
        LibraryVariableStorage.Enqueue(ShowMIRDetail);

        Commit();
        REPORT.Run(REPORT::"Finance Charge Memo - Test");
    end;

    local procedure RunReminderTestReport(ReminderNo: Code[20]; ShowMIRDetail: Boolean)
    begin
        LibraryVariableStorage.Enqueue(ReminderNo);
        LibraryVariableStorage.Enqueue(ShowMIRDetail);

        Commit();
        REPORT.Run(REPORT::"Reminder - Test");
    end;

    local procedure RunReminderReport(ReminderNo: Code[20]; ShowMIRDetail: Boolean)
    begin
        LibraryVariableStorage.Enqueue(ReminderNo);
        LibraryVariableStorage.Enqueue(ShowMIRDetail);

        Commit();
        REPORT.Run(REPORT::Reminder);
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
            Assert.IsTrue(LibraryReportValidation.CheckIfDecimalValueExists(AmountLine[i]), AmountNotFoundErr);
            Assert.IsTrue(LibraryReportValidation.CheckIfDecimalValueExists(AmountMIRLine[i]), AmountNotFoundErr);
        end;
        Assert.IsTrue(LibraryReportValidation.CheckIfDecimalValueExists(TotalAmount), AmountNotFoundErr);
    end;

    local procedure VerifyAmountsWithoutMIREntry(TotalAmount: Decimal; AmountLine: array[5] of Decimal; AmountMIRLine: array[5] of Decimal)
    var
        i: Integer;
    begin
        LibraryReportValidation.OpenExcelFile();
        for i := 1 to ArrayLen(AmountLine) do begin
            Assert.IsTrue(LibraryReportValidation.CheckIfDecimalValueExists(AmountLine[i]), AmountNotFoundErr);
            Assert.IsFalse(LibraryReportValidation.CheckIfDecimalValueExists(AmountMIRLine[i]), WrongRowErr);
        end;
        Assert.IsTrue(LibraryReportValidation.CheckIfDecimalValueExists(TotalAmount), AmountNotFoundErr);
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

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure FinChargeMemoTestReqHandler(var FinanceChargeMemoTest: TestRequestPage "Finance Charge Memo - Test")
    begin
        FinanceChargeMemoTest."Finance Charge Memo Header".SetFilter("No.", LibraryVariableStorage.DequeueText());
        FinanceChargeMemoTest.ShowMIR.SetValue(LibraryVariableStorage.DequeueBoolean());
        FinanceChargeMemoTest.SaveAsExcel(LibraryReportValidation.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReminderTestReqHandler(var ReminderTest: TestRequestPage "Reminder - Test")
    begin
        ReminderTest."Reminder Header".SetFilter("No.", LibraryVariableStorage.DequeueText());
        ReminderTest.ShowMIR.SetValue(LibraryVariableStorage.DequeueBoolean());
        ReminderTest.SaveAsExcel(LibraryReportValidation.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReminderReqHandler(var Reminder: TestRequestPage Reminder)
    begin
        Reminder."Issued Reminder Header".SetFilter("No.", LibraryVariableStorage.DequeueText());
        Reminder.ShowMIR.SetValue(LibraryVariableStorage.DequeueBoolean());
        Reminder.SaveAsExcel(LibraryReportValidation.GetFileName());
    end;
}

