codeunit 142074 "UT REP Reminder"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        StartLineNoCap: Label 'StartLineNo';

    [Test]
    [HandlerFunctions('ReminderTestRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemReminderLineReminderTest()
    var
        ReminderLineNo: Integer;
    begin
        // Purpose of the test is to validate ReminderLine - OnPreDataItem of Report ID - 122 Reminder - Test.
        // Setup.
        Initialize();
        ReminderLineNo := CreateReminderLine();

        // Exercise.
        REPORT.Run(REPORT::"Reminder - Test");  // Opens ReminderTestRequestPageHandler.

        // Verify: Verify Type and Line No of Reminder Line is updated on Report Reminder - Test.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('TypeNo', 2);  // 2 for Type - Customer Ledger Entry.
        LibraryReportDataset.AssertElementWithValueExists(StartLineNoCap, ReminderLineNo);
    end;

    [Test]
    [HandlerFunctions('ReminderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnPreDataItemIssuedReminderLineReminder()
    var
        IssuedReminderLine: Record "Issued Reminder Line";
    begin
        // Purpose of the test is to validate IssuedReminderLine - OnPreDataItem of Report ID - 117 Reminder.
        // Setup.
        Initialize();
        CreateIssuedReminderLine(IssuedReminderLine, IssuedReminderLine."Line Type"::"Reminder Line");
        Commit();  // Commit Required, Because Explicit commit is called by IncrNoPrinted function of Codeunit ID - 393 Reminder - Issue.

        // Exercise.
        LibraryVariableStorage.Enqueue(true);  // ShowNotDueAmounts = TRUE, required inside ReminderRequestPageHandler.
        REPORT.Run(REPORT::Reminder);  // Opens ReminderRequestPageHandler.

        // Verify: Verify Line No, VAT Amount and Remaining Amount of Issued Reminder Line is updated on Report Reminder.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(StartLineNoCap, IssuedReminderLine."Line No.");
        LibraryReportDataset.AssertElementWithValueExists('NNCVATAmount', IssuedReminderLine."VAT Amount");
        LibraryReportDataset.AssertElementWithValueExists('RemAmt_IssuedReminderLine', IssuedReminderLine."Remaining Amount");
    end;

    [Test]
    [HandlerFunctions('ReminderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnPreDataItemIssuedReminderLineTypeNotDueReminder()
    var
        IssuedReminderLine: Record "Issued Reminder Line";
    begin
        // Purpose of the test is to validate IssuedReminderLine2 - OnPreDataItem of Report ID - 117 Reminder.

        // Setup: Create Reminder Line for Line Type Not Due to verify description on report Reminder.
        Initialize();
        OnPreDataItemIssuedReminderLineTypeReminder(IssuedReminderLine."Line Type"::"Not Due");
    end;

    [Test]
    [HandlerFunctions('ReminderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnPreDataItemIssuedReminderLineEndingTextReminder()
    var
        IssuedReminderLine: Record "Issued Reminder Line";
    begin
        // Purpose of the test is to validate IssuedReminderLine2 - OnPreDataItem of Report ID - 117 Reminder.

        // Setup: Create Reminder Line for Line Type Ending Text to verify description on report Reminder.
        Initialize();
        OnPreDataItemIssuedReminderLineTypeReminder(IssuedReminderLine."Line Type"::"Ending Text");
    end;

    local procedure OnPreDataItemIssuedReminderLineTypeReminder(LineType: Enum "Reminder Line Type")
    var
        IssuedReminderLine: Record "Issued Reminder Line";
    begin
        // Create Reminder Line for Different Line Type.
        CreateIssuedReminderLine(IssuedReminderLine, LineType);
        Commit();  // Commit Required, Because Explicit commit is called by IncrNoPrinted function of Codeunit ID - 393 Reminder - Issue.

        // Exercise.
        LibraryVariableStorage.Enqueue(false);  // ShowNotDueAmounts = FALS, required inside ReminderRequestPageHandler.
        REPORT.Run(REPORT::Reminder);  // Opens ReminderRequestPageHandler.

        // Verify: Verify Description of Issued Reminder Line for different Line Type is updated on Report Reminder.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Description_IssuedReminderLine2', IssuedReminderLine.Description);
    end;

    // [Test]
    [HandlerFunctions('IssuedFinChargeMemoLineRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnPreDataItemIssuedFinChargeMemoLineFinanceChargeMemo()
    var
        IssuedFinChargeMemoLine: Record "Issued Fin. Charge Memo Line";
    begin
        // Purpose of the test is to validate IssuedFinChargeMemoLine - OnPreDataItem of Report ID - 118 Finance Charge Memo.
        // Setup.
        Initialize();
        CreateIssuedFinChargeMemoLine(IssuedFinChargeMemoLine);
        UpdateIssuedFinChargeMemoLineAmount(IssuedFinChargeMemoLine);
        Commit();  // Commit Required, Because Explicit commit is called by IncrNoPrinted function of Codeunit ID - 395 FinChrgMemo-Issue.

        // Exercise.
        REPORT.Run(REPORT::"Finance Charge Memo");  // Opens FinanceChargeMemoRequestPageHandler.

        // Verify: Verify Line No, Amount and VAT Amount of Issued Finance Charge Memo Line is updated on Report Finance Charge Memo.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(StartLineNoCap, IssuedFinChargeMemoLine."Line No.");
        LibraryReportDataset.AssertElementWithValueExists('Amt_IssuedFinChrgMemoLine', IssuedFinChargeMemoLine.Amount);
        LibraryReportDataset.AssertElementWithValueExists('VatAmt_IssuFinChrgMemoLine', IssuedFinChargeMemoLine."VAT Amount");
    end;

    // [Test]
    [HandlerFunctions('IssuedFinChargeMemoLineRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordVATCounterFinanceChargeMemo()
    var
        IssuedFinChargeMemoLine: Record "Issued Fin. Charge Memo Line";
        VATBaseValue: Decimal;
    begin
        // Purpose of the test is to validate VATCounter - OnAfterGetRecord of Report ID - 118 Finance Charge Memo.
        // Setup.
        Initialize();
        CreateIssuedFinChargeMemoLine(IssuedFinChargeMemoLine);
        UpdateIssuedFinChargeMemoLine(IssuedFinChargeMemoLine);
        Commit();  // Commit Required, Because Explicit commit is called by IncrNoPrinted function of Codeunit ID - 395 FinChrgMemo-Issue.

        // Exercise.
        REPORT.Run(REPORT::"Finance Charge Memo");  // Opens FinanceChargeMemoRequestPageHandler.

        // Verify: Verify VALVATBase and VALVATAmount is updated on Report Finance Charge Memo. Calculation is on the basis of trigger VATCounter - OnAfterGetRecord of Report ID - 118 Finance Charge Memo.
        LibraryReportDataset.LoadDataSetFile();
        VATBaseValue := (IssuedFinChargeMemoLine."VAT Amount" + IssuedFinChargeMemoLine.Amount) / (1 + IssuedFinChargeMemoLine."VAT %" / 100);
        LibraryReportDataset.AssertElementWithValueExists('VALVATBase', VATBaseValue);
        LibraryReportDataset.AssertElementWithValueExists('VALVATAmount', IssuedFinChargeMemoLine."VAT Amount" + IssuedFinChargeMemoLine.Amount - VATBaseValue);
    end;

    // [Test]
    [HandlerFunctions('IssuedFinChargeMemoLineRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordVATCounterLCYFinanceChargeMemo()
    var
        IssuedFinChargeMemoLine: Record "Issued Fin. Charge Memo Line";
        VATBaseValue: Decimal;
        ExchangeRateAmount: Decimal;
        OldPrintVATSpecificationLCY: Boolean;
    begin
        // Purpose of the test is to validate VATCounter - OnAfterGetRecord of Report ID - 118 Finance Charge Memo.
        // Setup.
        Initialize();
        UpdateGeneralLedgerSetup(OldPrintVATSpecificationLCY, true);

        ExchangeRateAmount := CreateIssuedFinChargeMemoLine(IssuedFinChargeMemoLine);
        UpdateIssuedFinChargeMemoLine(IssuedFinChargeMemoLine);
        Commit();  // Commit Required, Because Explicit commit is called by IncrNoPrinted function of Codeunit ID - 395 FinChrgMemo-Issue.

        // Exercise.
        REPORT.Run(REPORT::"Finance Charge Memo");  // Opens FinanceChargeMemoRequestPageHandler.

        // Verify: Verify VALVATBaseLCY and NewVALVATAmountLCY is updated on Report Finance Charge Memo. Calculation is on the basis of trigger VATCounterLCY - OnAfterGetRecord of Report ID - 118 Finance Charge Memo.
        LibraryReportDataset.LoadDataSetFile();
        VATBaseValue := (IssuedFinChargeMemoLine."VAT Amount" + IssuedFinChargeMemoLine.Amount) / (1 + IssuedFinChargeMemoLine."VAT %" / 100);
        LibraryReportDataset.AssertElementWithValueExists('VALVATBaseLCY', Round(VATBaseValue / ExchangeRateAmount));
        LibraryReportDataset.AssertElementWithValueExists('NewVALVATAmountLCY', Round((IssuedFinChargeMemoLine."VAT Amount" + IssuedFinChargeMemoLine.Amount - VATBaseValue) / ExchangeRateAmount));

        // Teardown.
        UpdateGeneralLedgerSetup(OldPrintVATSpecificationLCY, OldPrintVATSpecificationLCY);
    end;

    local procedure Initialize()
    var
        FeatureKey: Record "Feature Key";
        FeatureKeyUpdateStatus: Record "Feature Data Update Status";
    begin
        if FeatureKey.Get('ReminderTermsCommunicationTexts') then begin
            FeatureKey.Enabled := FeatureKey.Enabled::None;
            FeatureKey.Modify();
        end;
        if FeatureKeyUpdateStatus.Get('ReminderTermsCommunicationTexts', CompanyName()) then begin
            FeatureKeyUpdateStatus."Feature Status" := FeatureKeyUpdateStatus."Feature Status"::Disabled;
            FeatureKeyUpdateStatus.Modify();
        end;
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateCustomerPostingGroup(var CustomerPostingGroup: Record "Customer Posting Group")
    begin
        CustomerPostingGroup.Code := LibraryUTUtility.GetNewCode10();
        CustomerPostingGroup.Insert();
    end;

    local procedure CreateReminderHeader(): Code[20]
    var
        CustomerPostingGroup: Record "Customer Posting Group";
        ReminderHeader: Record "Reminder Header";
    begin
        CreateCustomerPostingGroup(CustomerPostingGroup);
        ReminderHeader."No." := LibraryUTUtility.GetNewCode();
        ReminderHeader."Customer Posting Group" := CustomerPostingGroup.Code;
        ReminderHeader.Insert();
        exit(ReminderHeader."No.");
    end;

    local procedure CreateReminderLine(): Integer
    var
        ReminderLine: Record "Reminder Line";
    begin
        ReminderLine."Reminder No." := CreateReminderHeader();
        ReminderLine."Line No." := 1;
        ReminderLine."Line Type" := ReminderLine."Line Type"::"Reminder Line";
        ReminderLine.Type := ReminderLine.Type::"Customer Ledger Entry";
        ReminderLine.Insert();
        LibraryVariableStorage.Enqueue(ReminderLine."Reminder No.");  // Required inside ReminderTestRequestPageHandler.
        LibraryVariableStorage.Enqueue(false);  // ShowNotDueAmounts = FALSE, required inside ReminderRequestPageHandler.
        exit(ReminderLine."Line No.")
    end;

    local procedure CreateIssuedReminderHeader(): Code[20]
    var
        CustomerPostingGroup: Record "Customer Posting Group";
        IssuedReminderHeader: Record "Issued Reminder Header";
    begin
        CreateCustomerPostingGroup(CustomerPostingGroup);
        IssuedReminderHeader."No." := LibraryUTUtility.GetNewCode();
        IssuedReminderHeader."Customer Posting Group" := CustomerPostingGroup.Code;
        IssuedReminderHeader.Insert();
        exit(IssuedReminderHeader."No.");
    end;

    local procedure CreateIssuedReminderLine(var IssuedReminderLine: Record "Issued Reminder Line"; LineType: Enum "Reminder Line Type")
    begin
        IssuedReminderLine."Reminder No." := CreateIssuedReminderHeader();
        IssuedReminderLine."Line No." := 1;
        IssuedReminderLine.Description := 'Description';
        IssuedReminderLine."Line Type" := LineType;
        IssuedReminderLine.Type := IssuedReminderLine.Type::"Customer Ledger Entry";
        IssuedReminderLine."Remaining Amount" := LibraryRandom.RandDec(10, 2);
        IssuedReminderLine."VAT Amount" := LibraryRandom.RandDec(10, 2);
        IssuedReminderLine.Insert();
        LibraryVariableStorage.Enqueue(IssuedReminderLine."Reminder No.");  // Required inside ReminderRequestPageHandler.
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
    begin
        VATPostingSetup.FindFirst();
        GLAccount."No." := LibraryUTUtility.GetNewCode();
        GLAccount."VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";
        GLAccount."VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";
        GLAccount.Insert();
        exit(GLAccount."No.");
    end;

    local procedure CreateIssuedFinChargeMemoHeader(var CurrencyExchangeRate: Record "Currency Exchange Rate"): Code[20]
    var
        CustomerPostingGroup: Record "Customer Posting Group";
        IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header";
        GLAccountNo: Code[20];
    begin
        CurrencyExchangeRate.FindFirst();
        GLAccountNo := CreateGLAccount();
        ;
        CreateCustomerPostingGroup(CustomerPostingGroup);
        CustomerPostingGroup."Additional Fee Account" := GLAccountNo;
        CustomerPostingGroup."Interest Account" := GLAccountNo;
        CustomerPostingGroup.Modify();

        IssuedFinChargeMemoHeader."No." := LibraryUTUtility.GetNewCode();
        IssuedFinChargeMemoHeader."Customer Posting Group" := CustomerPostingGroup.Code;
        IssuedFinChargeMemoHeader."Currency Code" := CurrencyExchangeRate."Currency Code";
        IssuedFinChargeMemoHeader."Posting Date" := CurrencyExchangeRate."Starting Date";
        IssuedFinChargeMemoHeader.Insert();
        exit(IssuedFinChargeMemoHeader."No.")
    end;

    local procedure CreateIssuedFinChargeMemoLine(var IssuedFinChargeMemoLine: Record "Issued Fin. Charge Memo Line"): Decimal
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        IssuedFinChargeMemoLine."Finance Charge Memo No." := CreateIssuedFinChargeMemoHeader(CurrencyExchangeRate);
        IssuedFinChargeMemoLine."Line No." := 1;
        IssuedFinChargeMemoLine.Type := IssuedFinChargeMemoLine.Type::"Customer Ledger Entry";
        IssuedFinChargeMemoLine.Insert();
        LibraryVariableStorage.Enqueue(IssuedFinChargeMemoLine."Finance Charge Memo No.");  // Required inside FinanceChargeMemoRequestPageHandler.
        exit(CurrencyExchangeRate."Exchange Rate Amount" / CurrencyExchangeRate."Relational Exch. Rate Amount");
    end;

    local procedure UpdateIssuedFinChargeMemoLine(var IssuedFinChargeMemoLine: Record "Issued Fin. Charge Memo Line")
    begin
        IssuedFinChargeMemoLine."VAT Identifier" := LibraryUTUtility.GetNewCode10();
        IssuedFinChargeMemoLine."VAT Calculation Type" := IssuedFinChargeMemoLine."VAT Calculation Type"::"Normal VAT";
        IssuedFinChargeMemoLine."Tax Group Code" := LibraryUTUtility.GetNewCode10();
        IssuedFinChargeMemoLine."VAT %" := LibraryRandom.RandDec(10, 2);
        UpdateIssuedFinChargeMemoLineAmount(IssuedFinChargeMemoLine);
    end;

    local procedure UpdateIssuedFinChargeMemoLineAmount(var IssuedFinChargeMemoLine: Record "Issued Fin. Charge Memo Line")
    begin
        IssuedFinChargeMemoLine.Amount := LibraryRandom.RandDec(10, 2);
        IssuedFinChargeMemoLine."VAT Amount" := LibraryRandom.RandDec(10, 2);
        IssuedFinChargeMemoLine.Modify();
    end;

    local procedure UpdateGeneralLedgerSetup(var OldPrintVATSpecificatioInLCY: Boolean; NewPrintVATSpecificatioInLCY: Boolean)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        OldPrintVATSpecificatioInLCY := GeneralLedgerSetup."Print VAT specification in LCY";
        GeneralLedgerSetup."Print VAT specification in LCY" := NewPrintVATSpecificatioInLCY;
        GeneralLedgerSetup.Modify();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReminderTestRequestPageHandler(var ReminderTest: TestRequestPage "Reminder - Test")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        ReminderTest."Reminder Header".SetFilter("No.", No);
        ReminderTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReminderRequestPageHandler(var Reminder: TestRequestPage Reminder)
    var
        No: Variant;
        ShowNotDueAmounts: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(ShowNotDueAmounts);
        Reminder."Issued Reminder Header".SetFilter("No.", No);
        Reminder.ShowNotDueAmounts.SetValue(ShowNotDueAmounts);
        Reminder.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure IssuedFinChargeMemoLineRequestPageHandler(var FinanceChargeMemo: TestRequestPage "Finance Charge Memo")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        FinanceChargeMemo."Issued Fin. Charge Memo Header".SetFilter("No.", No);
        FinanceChargeMemo.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

