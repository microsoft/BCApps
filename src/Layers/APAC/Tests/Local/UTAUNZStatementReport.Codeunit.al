codeunit 141041 "UT AUNZ Statement Report"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Report] [AU/NZ Statement]
    end;

    var
        Assert: Codeunit Assert;
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        AgingAmountCap: Label 'AgingAmount_1__Control1000000003';
        DialogErr: Label 'Dialog';
        TestValidationErr: Label 'TestValidation';
        AccountNoTxt: Label 'Account No.';
        CompanyInformationGiroNoCap: Label 'CompanyInformation__Giro_No__';
        CompanyInformationPhoneNoCap: Label 'CompanyInformation__Phone_No__';
        DateFilterTxt: Label '%1..%2';
        GIRONoTxt: Label 'GIRO No.';
        PhoneNoTxt: Label 'Phone No.';
        AccountNoCap: Label 'AccountNo';
        BalanceToPrintLCYCap: Label 'Testdec_Control1000000001';
        CustLedgerEntryCustomerNoCap: Label 'CustLedgerEntry3_Customer_No_';
        CustLedgerEntryNumberCap: Label 'CustLedgerEntry3_Entry_No_';
        CustomerNoCap: Label 'Customer_No_';
        DebitBalanceCap: Label 'DebitBalance';
        GiroNoCap: Label 'GiroNo';
        OpenDebitBalanceCap: Label 'OpenDrBal';
        OpenDebitBalanceLCYCap: Label 'OpenDrBalLCY';
        PhoneNoCap: Label 'PhoneNo';
        ValueMustBeEqualMsg: Label 'Value must be Equal.';

    [Test]
    [HandlerFunctions('PeriodCalculationFalseAUNZStatementRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportAgingMethodNoneAUNZStatementError()
    var
        AgingMethod: Option "None","Due Date","Trans Date","Doc Date";
    begin
        // [SCENARIO] validate OnPreReport Trigger of Report ID - 17110 AU/NZ Statement and Test to verify error - You must select either All with Entries or All with Balance.
        OnPreReportAgingMethodAUNZStatement(AgingMethod::None, DialogErr);
    end;

    [Test]
    [HandlerFunctions('PeriodCalculationFalseAUNZStatementRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportAgingMethodDueDateAUNZStatementError()
    var
        AgingMethod: Option "None","Due Date","Trans Date","Doc Date";
    begin
        // [SCENARIO] validate OnPreReport Trigger of Report ID - 17110 AU/NZ Statement and Test to verify error - You must enter a Length of Aging Periods if you select aging.
        OnPreReportAgingMethodAUNZStatement(AgingMethod::"Due Date", TestValidationErr);
    end;

    local procedure OnPreReportAgingMethodAUNZStatement(AgingMethod: Option; ExpectedError: Text[30])
    var
        StatementStyle: Option "Open Item",Balance;
    begin
        // Setup.
        Initialize();
        EnqueueValuesForAUNZStatement(StatementStyle::"Open Item", AgingMethod, '', '');  // Enqueue blank - Length of Aging Periods and Customer Number for PeriodCalculationFalseAUNZStatementRequestPageHandler.

        // Exercise.
        asserterror REPORT.Run(REPORT::"AU/NZ Statement");  // Opens handler - PeriodCalculationFalseAUNZStatementRequestPageHandler.

        // [THEN] Verify expected error code, Actual error message: You must select either All with Entries or All with Balance or You must enter a Length of Aging Periods if you select aging.
        Assert.ExpectedErrorCode(ExpectedError);
    end;

    [Test]
    [HandlerFunctions('PrintLCYTrueAUNZStatementRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportPrintCompanyTrueAUNZStatement()
    var
        CompanyInformation: Record "Company Information";
    begin
        // [SCENARIO] validate OnPreReport Trigger of Report ID - 17110 AU/NZ Statement.
        CompanyInformation.Get();
        OnPreReportPrintCompanyAUNZStatement(
          PhoneNoTxt, GIRONoTxt, AccountNoTxt, CompanyInformation."Phone No.", CompanyInformation."Giro No.");
    end;

    [Test]
    [HandlerFunctions('PeriodCalculationTrueAUNZStatementRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportPrintCompanyFalseAUNZStatement()
    begin
        // [SCENARIO] validate OnPreReport Trigger of Report ID - 17110 AU/NZ Statement.
        OnPreReportPrintCompanyAUNZStatement('', '', '', '', '');  // Blank Caption - Phone Number, Giro Number, Account Number, Company Information - Phone Number, Giro Number.
    end;

    local procedure OnPreReportPrintCompanyAUNZStatement(PhoneNo: Text[50]; GiroNo: Text[50]; AccountNo: Text[50]; PhoneNoValue: Text[30]; GiroNoValue: Text[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        AgingMethod: Option "None","Due Date","Trans Date","Doc Date";
        StatementStyle: Option "Open Item",Balance;
    begin
        // [GIVEN] Create Customer Ledger Entry and Enqueue Values For PrintLCYTrueAUNZStatementRequestPageHandler or PeriodCalculationTrueAUNZStatementRequestPageHandler.
        Initialize();
        CreateCustomerLedgerEntries(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice);
        EnqueueValuesForAUNZStatement(StatementStyle::"Open Item", AgingMethod::None, '', CustLedgerEntry."Customer No.");  // Blank - Length of Aging Periods.

        // Exercise.
        REPORT.Run(REPORT::"AU/NZ Statement");  // Opens handler - PrintLCYTrueAUNZStatementRequestPageHandler or PeriodCalculationTrueAUNZStatementRequestPageHandler.

        // [THEN] Verify Caption - Phone Number, Giro Number, Account Number and Company Information - Phone Number, Giro Number on generated XML of Report - AU/NZ Statement.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(PhoneNoCap, PhoneNo);
        LibraryReportDataset.AssertElementWithValueExists(GiroNoCap, GiroNo);
        LibraryReportDataset.AssertElementWithValueExists(AccountNoCap, AccountNo);
        LibraryReportDataset.AssertElementWithValueExists(CompanyInformationPhoneNoCap, PhoneNoValue);
        LibraryReportDataset.AssertElementWithValueExists(CompanyInformationGiroNoCap, GiroNoValue);
    end;

    [Test]
    [HandlerFunctions('PrintLCYFalseAUNZStatementRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordTransDatePrintLCYFalseAUNZStatement()
    var
        AgingMethod: Option "None","Due Date","Trans Date","Doc Date";
    begin
        // [SCENARIO] validate AgingCust. Ledger Entry - OnAfterGetRecord Trigger of Report ID - 17110 AU/NZ Statement.
        OnAfterGetRecordAgingMethodPrintLCYAUNZStatement(AgingMethod::"Trans Date", false);  // PrintLCY as False.
    end;

    [Test]
    [HandlerFunctions('PrintLCYFalseAUNZStatementRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordDocDatePrintLCYFalseAUNZStatement()
    var
        AgingMethod: Option "None","Due Date","Trans Date","Doc Date";
    begin
        // [SCENARIO] validate AgingCust. Ledger Entry - OnAfterGetRecord Trigger of Report ID - 17110 AU/NZ Statement.
        OnAfterGetRecordAgingMethodPrintLCYAUNZStatement(AgingMethod::"Doc Date", false);  // PrintLCY as False.
    end;

    [Test]
    [HandlerFunctions('PrintLCYFalseAUNZStatementRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordDueDatePrintLCYFalseAUNZStatement()
    var
        AgingMethod: Option "None","Due Date","Trans Date","Doc Date";
    begin
        // [SCENARIO] validate AgingCust. Ledger Entry - OnAfterGetRecord Trigger of Report ID - 17110 AU/NZ Statement.
        OnAfterGetRecordAgingMethodPrintLCYAUNZStatement(AgingMethod::"Due Date", false);  // PrintLCY as False.
    end;

    [Test]
    [HandlerFunctions('PrintLCYTrueAUNZStatementRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordTransDatePrintLCYTrueAUNZStatement()
    var
        AgingMethod: Option "None","Due Date","Trans Date","Doc Date";
    begin
        // [SCENARIO] validate AgingCust. Ledger Entry - OnAfterGetRecord Trigger of Report ID - 17110 AU/NZ Statement.
        OnAfterGetRecordAgingMethodPrintLCYAUNZStatement(AgingMethod::"Trans Date", true);  // PrintLCY as True.
    end;

    [Test]
    [HandlerFunctions('PrintLCYTrueAUNZStatementRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordDocDatePrintLCYTrueAUNZStatement()
    var
        AgingMethod: Option "None","Due Date","Trans Date","Doc Date";
    begin
        // [SCENARIO] validate AgingCust. Ledger Entry - OnAfterGetRecord Trigger of Report ID - 17110 AU/NZ Statement.
        OnAfterGetRecordAgingMethodPrintLCYAUNZStatement(AgingMethod::"Doc Date", true);  // PrintLCY as True.
    end;

    [Test]
    [HandlerFunctions('PrintLCYTrueAUNZStatementRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordDueDatePrintLCYTrueAUNZStatement()
    var
        AgingMethod: Option "None","Due Date","Trans Date","Doc Date";
    begin
        // [SCENARIO] validate AgingCust. Ledger Entry - OnAfterGetRecord Trigger of Report ID - 17110 AU/NZ Statement.
        OnAfterGetRecordAgingMethodPrintLCYAUNZStatement(AgingMethod::"Due Date", true);  // PrintLCY as True.
    end;

    local procedure OnAfterGetRecordAgingMethodPrintLCYAUNZStatement(AgingMethod: Option; PrintLCY: Boolean)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        StatementStyle: Option "Open Item",Balance;
    begin
        // [GIVEN] Create Customer Ledger Entry and Enqueue Values for PrintLCYFalseAUNZStatementRequestPageHandler or PrintLCYTrueAUNZStatementRequestPageHandler.
        Initialize();
        CreateCustomerLedgerEntries(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice);
        EnqueueValuesForAUNZStatement(StatementStyle::"Open Item", AgingMethod,
          Format(LibraryRandom.RandInt(10)) + '<D>', CustLedgerEntry."Customer No.");  // Random - Length of Aging Periods as Day.

        // Exercise.
        REPORT.Run(REPORT::"AU/NZ Statement");  // Opens handler - PrintLCYFalseAUNZStatementRequestPageHandler or PrintLCYtrueAUNZStatementRequestPageHandler.

        // [THEN] Verify Customer Ledger - Entry Number, Customer Number, Remaining Amount and Remaining Amount LCY on generated XML of Report - AU/NZ Statement.
        // [THEN] 'StatementBalance' is printed for both options PrintLCY = false and true (TFS 404013)
        VerifyCustLedgerEntryRemainingAmtOnReportAUNZStatement(CustLedgerEntry, PrintLCY);
    end;

    [Test]
    [HandlerFunctions('PrintLCYTrueAUNZStatementRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordBalTransDatePrintLCYTrueAUNZStatement()
    var
        AgingMethod: Option "None","Due Date","Trans Date","Doc Date";
    begin
        // [SCENARIO] validate AgingCust. Ledger Entry - OnAfterGetRecord Trigger of Report ID - 17110 AU/NZ Statement.
        OnAfterGetRecordAgingMethodBalancePrintLCYAUNZStatement(AgingMethod::"Trans Date", true, BalanceToPrintLCYCap);  // PrintLCY as True.
    end;

    [Test]
    [HandlerFunctions('PrintLCYTrueAUNZStatementRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordBalDocDatePrintLCYTrueAUNZStatement()
    var
        AgingMethod: Option "None","Due Date","Trans Date","Doc Date";
    begin
        // [SCENARIO] validate AgingCust. Ledger Entry - OnAfterGetRecord Trigger of Report ID - 17110 AU/NZ Statement.
        OnAfterGetRecordAgingMethodBalancePrintLCYAUNZStatement(AgingMethod::"Doc Date", true, AgingAmountCap);  // PrintLCY as True.
    end;

    [Test]
    [HandlerFunctions('PrintLCYTrueAUNZStatementRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordBalDueDatePrintLCYTrueAUNZStatement()
    var
        AgingMethod: Option "None","Due Date","Trans Date","Doc Date";
    begin
        // [SCENARIO] validate AgingCust. Ledger Entry - OnAfterGetRecord Trigger of Report ID - 17110 AU/NZ Statement.
        OnAfterGetRecordAgingMethodBalancePrintLCYAUNZStatement(AgingMethod::"Due Date", true, AgingAmountCap);  // PrintLCY as True.
    end;

    [Test]
    [HandlerFunctions('PrintLCYFalseAUNZStatementRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordBalTransDatePrintLCYFalseAUNZStatement()
    var
        AgingMethod: Option "None","Due Date","Trans Date","Doc Date";
    begin
        // [SCENARIO] validate AgingCust. Ledger Entry - OnAfterGetRecord Trigger of Report ID - 17110 AU/NZ Statement.
        OnAfterGetRecordAgingMethodBalancePrintLCYAUNZStatement(AgingMethod::"Trans Date", false, BalanceToPrintLCYCap);  // PrintLCY as False.
    end;

    [Test]
    [HandlerFunctions('PrintLCYFalseAUNZStatementRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordBalDocDatePrintLCYFalseAUNZStatement()
    var
        AgingMethod: Option "None","Due Date","Trans Date","Doc Date";
    begin
        // [SCENARIO] validate AgingCust. Ledger Entry - OnAfterGetRecord Trigger of Report ID - 17110 AU/NZ Statement.
        OnAfterGetRecordAgingMethodBalancePrintLCYAUNZStatement(AgingMethod::"Doc Date", false, AgingAmountCap);  // PrintLCY as False.
    end;

    [Test]
    [HandlerFunctions('PrintLCYFalseAUNZStatementRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordBalDueDatePrintLCYFalseAUNZStatement()
    var
        AgingMethod: Option "None","Due Date","Trans Date","Doc Date";
    begin
        // [SCENARIO] validate AgingCust. Ledger Entry - OnAfterGetRecord Trigger of Report ID - 17110 AU/NZ Statement.
        OnAfterGetRecordAgingMethodBalancePrintLCYAUNZStatement(AgingMethod::"Due Date", false, AgingAmountCap);  // PrintLCY as False.
    end;

    local procedure OnAfterGetRecordAgingMethodBalancePrintLCYAUNZStatement(AgingMethod: Option; PrintLCY: Boolean; CustLedgerAmountCap: Text[100])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        StatementStyle: Option "Open Item",Balance;
    begin
        // [SCENARIO] validate AgingCust. Ledger Entry - OnAfterGetRecord Trigger of Report ID - 17110 AU/NZ Statement.

        // [GIVEN] Create Customer Ledger Entries and Enqueue Value for PrintLCYTrueAUNZStatementRequestPageHandler or PrintLCYFalseAUNZStatementRequestPageHandler.
        Initialize();
        CreateCustomerLedgerEntries(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice);
        EnqueueValuesForAUNZStatement(
          StatementStyle::Balance, AgingMethod, Format(LibraryRandom.RandInt(10)) + '<D>', CustLedgerEntry."Customer No.");  // Random - Length of Aging Periods as Day.

        // Exercise.
        REPORT.Run(REPORT::"AU/NZ Statement");  // Opens handler - PrintLCYTrueAUNZStatementRequestPageHandler or PrintLCYFalseAUNZStatementRequestPageHandler.

        // [THEN] Verify Detailed Customer Ledger Entry Number, Customer Number, Amount and Amount (LCY) on generated XML of Report - AU/NZ Statement.
        VerifyDetailCustLedgerEntryAmountOnReportAUNZStatement(CustLedgerEntry."Customer No.", PrintLCY, CustLedgerAmountCap);
    end;

    [Test]
    [HandlerFunctions('UpdateStatementNumberAUNZStatementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordLastStatementNoAUNZStatement()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        OldLastStatementNo: Integer;
        AgingMethod: Option "None","Due Date","Trans Date","Doc Date";
        StatementStyle: Option "Open Item",Balance;
    begin
        // [SCENARIO] validate End Of Customer - OnAfterGetRecord Trigger of Report ID - 17110 AU/NZ Statement.

        // [GIVEN] Create Customer Ledger Entries and Enqueue Values for UpdateStatementNumberAUNZStatementRequestPageHandler.
        Initialize();
        CreateCustomerLedgerEntries(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice);
        EnqueueValuesForAUNZStatement(
          StatementStyle::Balance, AgingMethod::"Trans Date",
          Format(LibraryRandom.RandInt(10)) + '<D>', CustLedgerEntry."Customer No.");  // Random - Length of Aging Periods as Day.
        Customer.Get(CustLedgerEntry."Customer No.");
        OldLastStatementNo := Customer."Last Statement No.";
        Commit();  // Transaction Model Type Auto Commit is required as Commit is explicitly using on End Of Customer - OnAfterGetRecord Trigger of Report ID - 17110 AU/NZ Statement.

        // Exercise.
        REPORT.Run(REPORT::"AU/NZ Statement");  // Opens handler - UpdateStatementNumberAUNZStatementRequestPageHandler.

        // [THEN] Verify after running Report - AU/NZ Statement Customer - Last Statement Number incremented by one.
        Customer.Get(Customer."No.");
        Customer.TestField("Last Statement No.", OldLastStatementNo + 1);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure GetTermsStringBlankDescriptionAUNZStatement()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // [SCENARIO] validate GetTermsString function of Report ID - 17110 AU/NZ Statement.
        GetTermsStringDocumentTypeDescriptionAUNZStatement(CustLedgerEntry."Document Type", '');  // Document Type Option - default value, blank Payment Term Description.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure GetTermsStringSalesInvoiceDescriptionAUNZStatement()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // [SCENARIO] validate GetTermsString function of Report ID - 17110 AU/NZ Statement.
        GetTermsStringDocumentTypeDescriptionAUNZStatement(CustLedgerEntry."Document Type"::Invoice, LibraryUTUtility.GetNewCode());  // Payment Term Description.
    end;

    local procedure GetTermsStringDocumentTypeDescriptionAUNZStatement(DocumentType: Enum "Gen. Journal Document Type"; Description: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        AUNZStatement: Report "AU/NZ Statement";
    begin
        // [GIVEN] Create Customer Ledger Entries and Sales Invoice Header.
        Initialize();
        CreateCustomerLedgerEntries(CustLedgerEntry, DocumentType);
        CreateSalesInvoice(CustLedgerEntry."Document No.", CreatePaymentTerms(Description));

        // Execute function - GetTermsString and Verify Description.
        Assert.AreEqual(Description, AUNZStatement.GetTermsString(CustLedgerEntry), ValueMustBeEqualMsg);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure GetTermsStringBlankPaymentTermsDescriptionAUNZStatement()
    begin
        // [SCENARIO] validate GetTermsString function of Report ID - 17110 AU/NZ Statement.
        GetTermsStringPaymentTermsCodeAUNZStatement(CreatePaymentTerms(''));  // Blank Description.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure GetTermsStringWithoutPaymentTermsCodeAUNZStatement()
    begin
        // [SCENARIO] validate GetTermsString function of Report ID - 17110 AU/NZ Statement.
        GetTermsStringPaymentTermsCodeAUNZStatement(LibraryUTUtility.GetNewCode10());  // Payment Term Code.
    end;

    local procedure GetTermsStringPaymentTermsCodeAUNZStatement(PaymentTermsCode: Code[10])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        AUNZStatement: Report "AU/NZ Statement";
    begin
        // [GIVEN] Create Customer Ledger Entries and Sales Invoice Header.
        Initialize();
        CreateCustomerLedgerEntries(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice);
        CreateSalesInvoice(CustLedgerEntry."Document No.", PaymentTermsCode);

        // Execute function - GetTermsString and Verify Payment Terms Code on Sales Invoice Header.
        Assert.AreEqual(PaymentTermsCode, AUNZStatement.GetTermsString(CustLedgerEntry), ValueMustBeEqualMsg);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        Customer."No." := LibraryUTUtility.GetNewCode();
        Customer.Insert();
        exit(Customer."No.");
    end;

    local procedure CreateCustomerLedgerEntries(var CustLedgerEntry: Record "Cust. Ledger Entry"; DocumentType: Enum "Gen. Journal Document Type")
    var
        CustLedgerEntry2: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry2.FindLast();
        CustLedgerEntry."Entry No." := CustLedgerEntry2."Entry No." + 1;
        CustLedgerEntry."Document Type" := DocumentType;
        CustLedgerEntry."Document No." := LibraryUTUtility.GetNewCode();
        CustLedgerEntry."Customer No." := CreateCustomer();
        CustLedgerEntry."Posting Date" := WorkDate();
        CustLedgerEntry.Insert();
        CreateDetailedCustomerLedgerEntry(CustLedgerEntry."Customer No.", CustLedgerEntry."Entry No.");
    end;

    local procedure CreateDetailedCustomerLedgerEntry(CustomerNo: Code[20]; EntryNo: Integer)
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        DetailedCustLedgEntry2: Record "Detailed Cust. Ledg. Entry";
    begin
        DetailedCustLedgEntry2.FindLast();
        DetailedCustLedgEntry."Entry No." := DetailedCustLedgEntry2."Entry No." + 1;
        DetailedCustLedgEntry."Customer No." := CustomerNo;
        DetailedCustLedgEntry."Cust. Ledger Entry No." := EntryNo;
        DetailedCustLedgEntry."Posting Date" := WorkDate();
        DetailedCustLedgEntry.Amount := LibraryRandom.RandDec(10, 2);
        DetailedCustLedgEntry."Amount (LCY)" := DetailedCustLedgEntry.Amount;
        DetailedCustLedgEntry.Insert(true);
    end;

    local procedure CreatePaymentTerms(Description: Text[50]): Code[10]
    var
        PaymentTerms: Record "Payment Terms";
    begin
        PaymentTerms.Code := LibraryUTUtility.GetNewCode10();
        PaymentTerms.Description := Description;
        PaymentTerms.Insert();
        exit(PaymentTerms.Code);
    end;

    local procedure CreateSalesInvoice(No: Code[20]; PaymentTermsCode: Code[10])
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader."No." := No;
        SalesInvoiceHeader."Payment Terms Code" := PaymentTermsCode;
        SalesInvoiceHeader.Insert();
    end;

    local procedure EnqueueValuesForAUNZStatement(StatementStyle: Option; AgingMethod: Option; PeriodCalculation: Code[10]; CustomerNo: Code[20])
    begin
        LibraryVariableStorage.Enqueue(StatementStyle);
        LibraryVariableStorage.Enqueue(AgingMethod);
        LibraryVariableStorage.Enqueue(PeriodCalculation);
        LibraryVariableStorage.Enqueue(CustomerNo);
    end;

    local procedure FindCustomerLedgerEntryAmount(Amount: Decimal; PrintLCY: Boolean): Decimal
    begin
        if PrintLCY then
            exit(0);
        exit(Amount);
    end;

    local procedure FindCustomerLedgerEntryAmountLCY(AmountLCY: Decimal; PrintLCY: Boolean): Decimal
    begin
        if PrintLCY then
            exit(AmountLCY);
        exit(0);
    end;

    local procedure SetValuesAndSaveAsXMLAUNZStatementReport(var AUNZStatement: TestRequestPage "AU/NZ Statement"; PrintInLCY: Boolean; PrintAllWithBalance: Boolean; PrintAllWithEntries: Boolean; PrintCompanyAddress: Boolean; UpdateStatementNo: Boolean)
    var
        StatementStyle: Variant;
        AgingMethod: Variant;
        LengthOfAgingPeriods: Variant;
        CustomerNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(StatementStyle);
        LibraryVariableStorage.Dequeue(AgingMethod);
        LibraryVariableStorage.Dequeue(LengthOfAgingPeriods);
        LibraryVariableStorage.Dequeue(CustomerNo);
        AUNZStatement.PrintInLCY.SetValue(PrintInLCY);
        AUNZStatement.PrintAllWithBalance.SetValue(PrintAllWithBalance);
        AUNZStatement.PrintAllWithEntries.SetValue(PrintAllWithEntries);
        AUNZStatement.PrintCompanyAddress.SetValue(PrintCompanyAddress);
        AUNZStatement.UpdateStatementNo.SetValue(UpdateStatementNo);
        AUNZStatement.StatementStyle.SetValue(StatementStyle);
        AUNZStatement.AgedBy.SetValue(AgingMethod);
        AUNZStatement.LengthOfAgingPeriods.SetValue(LengthOfAgingPeriods);
        AUNZStatement.Customer.SetFilter("No.", CustomerNo);
        AUNZStatement.Customer.SetFilter(
          "Date Filter", StrSubstNo(DateFilterTxt, Format(WorkDate()),
            CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'D>', WorkDate())));  // Random - Value for To Date.
        AUNZStatement.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    local procedure VerifyCustLedgerEntryRemainingAmtOnReportAUNZStatement(CustLedgerEntry: Record "Cust. Ledger Entry"; PrintLCY: Boolean)
    begin
        CustLedgerEntry.CalcFields("Remaining Amount", "Remaining Amt. (LCY)");
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(CustLedgerEntryNumberCap, CustLedgerEntry."Entry No.");
        LibraryReportDataset.AssertElementWithValueExists(CustLedgerEntryCustomerNoCap, CustLedgerEntry."Customer No.");
        LibraryReportDataset.AssertElementWithValueExists(
          OpenDebitBalanceCap, FindCustomerLedgerEntryAmount(CustLedgerEntry."Remaining Amount", PrintLCY));
        LibraryReportDataset.AssertElementWithValueExists(
          OpenDebitBalanceLCYCap, FindCustomerLedgerEntryAmountLCY(CustLedgerEntry."Remaining Amt. (LCY)", PrintLCY));
        LibraryReportDataset.AssertElementWithValueExists(
            'StatementBalance', FindCustomerLedgerEntryAmountLCY(CustLedgerEntry."Remaining Amt. (LCY)", PrintLCY));

    end;

    local procedure VerifyDetailCustLedgerEntryAmountOnReportAUNZStatement(CustomerNo: Code[20]; PrintLCY: Boolean; CustLedgEntryAmountCap: Text[100])
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgEntry.SetRange("Customer No.", CustomerNo);
        CustLedgEntry.FindFirst();
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(
          DebitBalanceCap, FindCustomerLedgerEntryAmount(CustLedgEntry.Amount, PrintLCY));
        LibraryReportDataset.AssertElementWithValueExists(
          CustLedgEntryAmountCap, FindCustomerLedgerEntryAmountLCY(CustLedgEntry."Amount (LCY)", PrintLCY));
        LibraryReportDataset.AssertElementWithValueExists(CustomerNoCap, CustLedgEntry."Customer No.");
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PeriodCalculationFalseAUNZStatementRequestPageHandler(var AUNZStatement: TestRequestPage "AU/NZ Statement")
    begin
        SetValuesAndSaveAsXMLAUNZStatementReport(AUNZStatement, true, false, false, false, false);  // PrintLCY as True and AllHavingBalance, AllHavingEntries, PrintCompany, UpdateStatementNo as False.
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PrintLCYTrueAUNZStatementRequestPageHandler(var AUNZStatement: TestRequestPage "AU/NZ Statement")
    begin
        SetValuesAndSaveAsXMLAUNZStatementReport(AUNZStatement, true, true, true, true, false);  // PrintLCY, AllHavingBalance, AllHavingEntries, PrintCompany as True and UpdateStatementNo as False.
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PeriodCalculationTrueAUNZStatementRequestPageHandler(var AUNZStatement: TestRequestPage "AU/NZ Statement")
    begin
        SetValuesAndSaveAsXMLAUNZStatementReport(AUNZStatement, true, true, true, false, false);  // PrintLCY, AllHavingBalance, AllHavingEntries as True and PrintCompany, UpdateStatementNo as False.
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PrintLCYFalseAUNZStatementRequestPageHandler(var AUNZStatement: TestRequestPage "AU/NZ Statement")
    begin
        SetValuesAndSaveAsXMLAUNZStatementReport(AUNZStatement, false, true, true, true, false);  // PrintLCY, UpdateStatementNo as False and AllHavingBalance, AllHavingEntries, PrintCompany as True.
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure UpdateStatementNumberAUNZStatementRequestPageHandler(var AUNZStatement: TestRequestPage "AU/NZ Statement")
    begin
        SetValuesAndSaveAsXMLAUNZStatementReport(AUNZStatement, false, true, true, true, true);  // PrintLCY as False and AllHavingBalance, AllHavingEntries, PrintCompany, UpdateStatementNo as True.
    end;
}

