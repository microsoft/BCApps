codeunit 134993 "Reminder - Line Fee on Reports"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [ERM] [Reminder] [Additional Fee]
    end;

    var
        Language: Codeunit Language;
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        FCYCode: Code[10];
        AddFeeDueDate: Date;

    [Test]
    [HandlerFunctions('RHServiceInvoice')]
    [Scope('OnPrem')]
    procedure PrintServiceInvoiceWithAddFeePerLine()
    var
        CustomerNo: Code[20];
        AddFeePerLine: Decimal;
        ReminderTermsCode: Code[10];
        InvoiceNo: Code[20];
    begin
        // [SCENARIO 107048] A service invoice contains Add. Fee per Line note with the amount picked up from the Reminder Terms
        //  as the selected reminder terms has a Add. Fee per Line > 0
        Initialize();

        // [GIVEN] A Reminder Term X with level 1 having Add. Fee per Line = A, where A > 0
        AddFeePerLine := LibraryRandom.RandDec(100, 2);
        CreateCustomerWithReminderTermsAddFeePerLine(CustomerNo, ReminderTermsCode, true, '', AddFeePerLine); // WithLump = TRUE
        InvoiceNo := PostServiceInvoice(CustomerNo, WorkDate());

        // [WHEN] The invoice is printed
        ExportServiceInvoice(CustomerNo);

        // [THEN] The Add. Fee per Line note on report with amount A is printed
        ValidateInvoiceAddFeePerLine(ReminderTermsCode, 1, InvoiceNo, AddFeePerLine, '', Language.GetUserLanguageCode());
    end;

    [Test]
    [HandlerFunctions('RHServiceInvoice')]
    [Scope('OnPrem')]
    procedure PrintServiceInvoiceWithoutAddFeePerLine()
    var
        CustomerNo: Code[20];
        InvoiceNo: Code[20];
        ReminderTermsCode: Code[10];
    begin
        // [SCENARIO 107048] A service invoice does not contain Add. Fee per Line text
        // as the selected reminder terms has a Add. Fee per Line = 0
        Initialize();

        // [GIVEN] A Reminder Term X with level 1 having Add. Fee per Line = A, where A = 0
        CreateCustomerWithReminderTermsAddFeePerLine(CustomerNo, ReminderTermsCode, true, '', 0); // WithLump = TRUE, AddFeePerLine = 0

        // [GIVEN] A posted service invoice for customer with Reminder Term = X
        InvoiceNo := PostServiceInvoice(CustomerNo, WorkDate());

        // [WHEN] The invoice is printed
        ExportServiceInvoice(CustomerNo);

        // [THEN] The Add. Fee per Line note is not shown on the report
        ValidateInvoiceAddFeePerLine(ReminderTermsCode, 1, InvoiceNo, 0, '', Language.GetUserLanguageCode());
    end;

    [Test]
    [HandlerFunctions('RHServiceInvoice')]
    [Scope('OnPrem')]
    procedure PrintServiceInvoiceWithMultipleAddFeePerLine()
    var
        CustomerNo: Code[20];
        InvoiceNo: Code[20];
        ReminderTermsCode: Code[10];
        AddFeePerLine1: Decimal;
        AddFeePerLine2: Decimal;
    begin
        // [SCENARIO 107048] A service invoice contains multiple add. fee notes
        // as the selected reminder terms has two reminder levels with line fee defined
        Initialize();

        // [GIVEN] A Reminder Term X with level 1 having Add. Fee per Line = A, where A > 0
        AddFeePerLine1 := LibraryRandom.RandDec(100, 2);
        CreateCustomerWithReminderTermsAddFeePerLine(CustomerNo, ReminderTermsCode, true, '', AddFeePerLine1); // WithLump = TRUE

        // [GIVEN] A Reminder Term X with level 2 having Add. Fee per Line = A, where A > 0
        AddFeePerLine2 := LibraryRandom.RandDec(100, 2);
        CreateReminderTermsLevel(ReminderTermsCode,
          LibraryRandom.RandInt(10),// DueDateDays
          0,// Grace
                  '',// CurrencyCode
          0,// AdditionalFee
          AddFeePerLine2,
          false,// CalculateInterest
          2);    // Level

        // [GIVEN] A posted service invoice for customer with Reminder Term = X
        InvoiceNo := PostServiceInvoice(CustomerNo, WorkDate());

        // [WHEN] The invoice is printed
        ExportServiceInvoice(CustomerNo);

        // [THEN] Multiple Add. Fee per Line notes are shown on the report
        ValidateInvoiceAddFeePerLine(ReminderTermsCode, 1, InvoiceNo, AddFeePerLine1, '', Language.GetUserLanguageCode());
        ValidateInvoiceAddFeePerLine(ReminderTermsCode, 2, InvoiceNo, AddFeePerLine2, '', Language.GetUserLanguageCode());
    end;

    [Test]
    [HandlerFunctions('RHServiceInvoice')]
    [Scope('OnPrem')]
    procedure PrintServiceInvoiceWithFCYAddFeePerLine()
    var
        CustomerNo: Code[20];
        InvoiceNo: Code[20];
        ReminderTermsCode: Code[10];
        AddFeePerLine: Decimal;
    begin
        // [SCENARIO 107048] A service invoice report has Add. Fee per Line note with FCY amount as
        // the selected reminder terms has a Add. Fee per Line defined in FCY
        Initialize();

        // [GIVEN] A Reminder Term X with level 1 having Add. Fee per Line = A, where A > 0
        AddFeePerLine := LibraryRandom.RandDec(100, 2);
        CreateCustomerWithReminderTermsAddFeePerLine(CustomerNo, ReminderTermsCode, true, FCYCode, AddFeePerLine); // WithLump = TRUE

        // [GIVEN] A posted service invoice for customer with Reminder Term = X
        InvoiceNo := PostServiceInvoiceFCY(CustomerNo, WorkDate(), FCYCode);

        // [WHEN] The invoice is printed
        ExportServiceInvoice(CustomerNo);

        // [THEN] The Add. Fee per Line text on report is not shown on the report
        ValidateInvoiceAddFeePerLine(ReminderTermsCode, 1, InvoiceNo, AddFeePerLine, FCYCode, Language.GetUserLanguageCode());
    end;

    [Test]
    [HandlerFunctions('RHServiceInvoice')]
    [Scope('OnPrem')]
    procedure PrintServiceInvoiceWithMarginalPerc()
    var
        CustomerNo: Code[20];
        ReminderTermsCode: Code[10];
        InvoiceNo: Code[20];
        AddFeePerLine: Decimal;
    begin
        // [SCENARIO 107048] A service invoice report contains Add. Fee per Line note with Marginal Percentage shown
        // as the selected reminder terms has a Add. Fee per Line > 0  and Calc. Type is not Fixed
        Initialize();

        // [GIVEN] A Reminder Term X, with level 1 with Add. Fee per Line = A, where A > 0, with Add. Fee Setup created
        AddFeePerLine := LibraryRandom.RandDec(1000, 2);
        CreateCustomerWithReminderTermsAddFeePerLine(CustomerNo, ReminderTermsCode, true, '', AddFeePerLine);
        CreateAdditionalFeeSetup(ReminderTermsCode, 1, '', 0, AddFeePerLine);

        // [GIVEN] A posted sales invoice for customer with Reminder Term = X
        InvoiceNo := PostServiceInvoice(CustomerNo, WorkDate());

        // [WHEN] The invoice is printed
        ExportServiceInvoice(CustomerNo);

        // [THEN] The Add. Fee per Line note on report with Marginal Percentage shown
        ValidateInvoiceAddFeePerLine(ReminderTermsCode, 1, InvoiceNo, AddFeePerLine, '', Language.GetUserLanguageCode());
    end;

    [Test]
    [HandlerFunctions('RHServiceInvoice')]
    [Scope('OnPrem')]
    procedure PrintServiceInvoiceTextonInvoiceTranslated()
    var
        ReminderTermsTranslation: Record "Reminder Terms Translation";
        AddFeePerLine: Decimal;
        CustomerNo: Code[20];
        InvoiceNo: Code[20];
        ReminderTermsCode: Code[10];
    begin
        // [SCENARIO 107048] A service invoice report contains translated Add. Fee Note
        // as selected Reminder Terms contain Translated text on Report and Customer Country is set to use specific lang.
        Initialize();

        // [GIVEN] A Reminder Term X, with level 1 with Add. Fee per Line = A, where A > 0, with Text on Report
        // defined in other language and Customer Language set to that language
        AddFeePerLine := LibraryRandom.RandDec(1000, 2);
        CreateCustomerWithReminderTermsAddFeePerLine(CustomerNo, ReminderTermsCode, true, '', AddFeePerLine);
        CreateReminderTermsTranslationEntry(ReminderTermsTranslation, ReminderTermsCode);
        UpdateCustomerLangCode(CustomerNo, ReminderTermsTranslation."Language Code");

        // [GIVEN] A posted service invoice for customer with Reminder Term = X
        InvoiceNo := PostServiceInvoice(CustomerNo, WorkDate());

        // [WHEN] The invoice is printed
        ExportServiceInvoice(CustomerNo);

        // [THEN] The Add. Fee per Line note on report is printed on language defined in Reminder Terms Translation table
        ValidateInvoiceAddFeePerLine(
          ReminderTermsCode, 1, InvoiceNo, AddFeePerLine, '', ReminderTermsTranslation."Language Code");
    end;

    local procedure Initialize()
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Reminder - Line Fee on Reports");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Reminder - Line Fee on Reports");

        IsInitialized := true;

        CustomerPostingGroup.FindFirst();
        CustomerPostingGroup.ModifyAll("Add. Fee per Line Account", CustomerPostingGroup."Additional Fee Account");

        FCYCode := LibraryERM.CreateCurrencyWithRandomExchRates();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Reminder - Line Fee on Reports");
    end;

    local procedure CreateAdditionalFeeSetup(ReminderTermsCode: Code[10]; LevelNo: Integer; CurrencyCode: Code[10]; ThresholdAmount: Decimal; AdditionalFee: Decimal)
    var
        AdditionalFeeSetup: Record "Additional Fee Setup";
        ReminderLevel: Record "Reminder Level";
    begin
        ReminderLevel.Get(ReminderTermsCode, LevelNo);
        ReminderLevel.Validate("Add. Fee Calculation Type", ReminderLevel."Add. Fee Calculation Type"::"Accumulated Dynamic");
        ReminderLevel.Modify(true);

        AdditionalFeeSetup.Init();
        AdditionalFeeSetup.Validate("Reminder Terms Code", ReminderTermsCode);
        AdditionalFeeSetup.Validate("Reminder Level No.", LevelNo);
        AdditionalFeeSetup.Validate("Currency Code", CurrencyCode);
        AdditionalFeeSetup.Validate("Threshold Remaining Amount", ThresholdAmount);
        AdditionalFeeSetup.Validate("Additional Fee Amount", AdditionalFee);
        AdditionalFeeSetup.Validate("Charge Per Line", true);
        AdditionalFeeSetup.Insert(true);
    end;

    local procedure CreateCurrencyforReminderLevel(ReminderTermsCode: Code[10]; Level: Integer; CurrencyCode: Code[10]; AdditionalFee: Decimal; LineFee: Decimal)
    var
        CurrencyForReminderLevel: Record "Currency for Reminder Level";
    begin
        CurrencyForReminderLevel.Init();
        CurrencyForReminderLevel.Validate("Reminder Terms Code", ReminderTermsCode);
        CurrencyForReminderLevel.Validate("No.", Level);
        CurrencyForReminderLevel.Validate("Currency Code", CurrencyCode);
        CurrencyForReminderLevel.Validate("Additional Fee", AdditionalFee);
        CurrencyForReminderLevel.Validate("Add. Fee per Line", LineFee);
        CurrencyForReminderLevel.Insert(true);
    end;

    local procedure CreateCustomerWithReminderTermsAddFeePerLine(var CustNo: Code[20]; var ReminderTermCode: Code[10]; WithLineFee: Boolean; CurrencyCode: Code[10]; LineFee: Decimal)
    var
        PaymentTermsCode: Code[10];
    begin
        PaymentTermsCode := CreatePaymentTerms(1);
        ReminderTermCode := CreateReminderTerms(true, false, true);
        if WithLineFee then
            CreateReminderTermsLevel(ReminderTermCode, 1, 1, CurrencyCode, 0, LineFee, false, 1)
        else
            CreateReminderTermsLevel(ReminderTermCode, 1, 1, '', 0, 0, false, 1);

        CustNo := CreateCustomerWithReminderAndPaymentTerms(ReminderTermCode, PaymentTermsCode);
    end;

    local procedure CreateCustomerWithReminderAndPaymentTerms(ReminderTermsCode: Code[10]; PaymentTermsCode: Code[10]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Reminder Terms Code", ReminderTermsCode);
        Customer.Validate("Payment Terms Code", PaymentTermsCode);
        Customer.Modify(true);
        exit(Customer."No.")
    end;

    local procedure CreatePaymentTerms(DueDateDays: Integer): Code[10]
    var
        PaymentTerms: Record "Payment Terms";
        DueDateCalcFormula: DateFormula;
    begin
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        Evaluate(DueDateCalcFormula, '<+' + Format(DueDateDays) + 'D>');
        PaymentTerms.Validate("Due Date Calculation", DueDateCalcFormula);
        PaymentTerms.Modify(true);
        exit(PaymentTerms.Code)
    end;

    local procedure CreateReminderTerms(PostLineFee: Boolean; PostInterest: Boolean; PostAddFee: Boolean): Code[10]
    var
        ReminderTerms: Record "Reminder Terms";
    begin
        LibraryERM.CreateReminderTerms(ReminderTerms);
        ReminderTerms.Validate("Post Interest", PostInterest);
        ReminderTerms.Validate("Post Add. Fee per Line", PostLineFee);
        ReminderTerms.Validate("Post Additional Fee", PostAddFee);
        ReminderTerms.Validate("Note About Line Fee on Report", '%1 %2 %3 %4');
        ReminderTerms.Modify(true);
        exit(ReminderTerms.Code)
    end;

    local procedure CreateReminderTermsLevel(ReminderTermsCode: Code[10]; DueDateDays: Integer; GracePeriodDays: Integer; CurrencyCode: Code[10]; AdditionalFee: Decimal; LineFee: Decimal; CalculateInterest: Boolean; Level: Integer)
    var
        ReminderLevel: Record "Reminder Level";
        DueDateCalcFormula: DateFormula;
        GracePeriodCalcFormula: DateFormula;
    begin
        LibraryERM.CreateReminderLevel(ReminderLevel, ReminderTermsCode);
        Evaluate(DueDateCalcFormula, '<+' + Format(DueDateDays) + 'D>');
        Evaluate(GracePeriodCalcFormula, '<+' + Format(GracePeriodDays) + 'D>');
        ReminderLevel.Validate("No.", Level);
        ReminderLevel.Validate("Due Date Calculation", DueDateCalcFormula);
        ReminderLevel.Validate("Grace Period", GracePeriodCalcFormula);
        ReminderLevel.Validate("Calculate Interest", CalculateInterest);
        ReminderLevel.Validate("Add. Fee per Line Description",
          LibraryUtility.GenerateRandomCode(ReminderLevel.FieldNo("Add. Fee per Line Description"), DATABASE::"Reminder Level"));
        if CurrencyCode <> '' then
            CreateCurrencyforReminderLevel(ReminderTermsCode, Level, CurrencyCode, AdditionalFee, LineFee)
        else begin
            ReminderLevel.Validate("Add. Fee per Line Amount (LCY)", LineFee);
            ReminderLevel.Validate("Additional Fee (LCY)", AdditionalFee);
        end;
        ReminderLevel.Modify(true);
    end;

    local procedure CreateReminderTermsTranslationEntry(var ReminderTermsTranslation: Record "Reminder Terms Translation"; ReminderTermsCode: Code[10])
    var
        Language: Record Language;
    begin
        Language.FindFirst();
        ReminderTermsTranslation.Init();
        ReminderTermsTranslation.Validate("Reminder Terms Code", ReminderTermsCode);
        ReminderTermsTranslation.Validate("Language Code", Language.Code);
        ReminderTermsTranslation.Insert(true);
        ReminderTermsTranslation.Validate("Note About Line Fee on Report", '%1 %2 %3 %4');
        ReminderTermsTranslation.Modify(true);
    end;

    local procedure ExportServiceInvoice(CustomerNo: Code[20])
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceInvoice: Report "Service - Invoice";
    begin
        Clear(ServiceInvoice);
        ServiceInvoiceHeader.SetRange("Bill-to Customer No.", CustomerNo);
        ServiceInvoice.SetTableView(ServiceInvoiceHeader);
        Commit();
        ServiceInvoice.Run();
    end;

    local procedure PostServiceInvoice(CustomerNo: Code[20]; PostingDate: Date): Code[20]
    var
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceLine: Record "Service Line";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, CustomerNo);
        ServiceHeader.Validate("Posting Date", PostingDate);
        ServiceHeader.Modify(true);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItemNo());
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(100));
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDec(10, 2));
        ServiceLine.Modify(true);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true); // Ship, Consume, Invoice

        ServiceInvoiceHeader.SetRange("Customer No.", CustomerNo);
        ServiceInvoiceHeader.FindFirst();
        exit(ServiceInvoiceHeader."No.");
    end;

    local procedure PostServiceInvoiceFCY(CustomerNo: Code[20]; PostingDate: Date; CurrencyCode: Code[10]): Code[20]
    var
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceLine: Record "Service Line";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, CustomerNo);
        ServiceHeader.Validate("Posting Date", PostingDate);
        ServiceHeader.Validate("Currency Code", CurrencyCode);
        ServiceHeader.Modify(true);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItemNo());
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(100));
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDec(10, 2));
        ServiceLine.Modify(true);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true); // Ship, Consume, Invoice

        ServiceInvoiceHeader.SetRange("Customer No.", CustomerNo);
        ServiceInvoiceHeader.FindFirst();
        exit(ServiceInvoiceHeader."No.");
    end;

    local procedure UpdateCustomerLangCode(CustomerNo: Code[20]; LangCode: Code[10])
    var
        Customer: Record Customer;
    begin
        Customer.Get(CustomerNo);
        Customer.Validate("Language Code", LangCode);
        Customer.Modify(true);
    end;

    local procedure ValidateInvoiceAddFeePerLine(ReminderTermsCode: Code[10]; LevelNo: Integer; InvoiceHeaderNo: Code[20]; AddFeePerLine: Decimal; CurrencyCode: Code[10]; LanguageCode: Code[10])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
        ReminderLevel: Record "Reminder Level";
        ReminderTerms: Record "Reminder Terms";
        ReminderTermsTranslation: Record "Reminder Terms Translation";
        ElementExpectedValue: Text;
        MarginalPerc: Decimal;
        TextOnReportExpected: Text[150];
    begin
        ReminderTerms.Get(ReminderTermsCode);

        ReminderLevel.Get(ReminderTermsCode, LevelNo);
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
        CustLedgerEntry.SetRange("Document No.", InvoiceHeaderNo);
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.CalcFields("Original Amount");

        if LevelNo = 1 then
            AddFeeDueDate := CalcDate(ReminderLevel."Grace Period", CustLedgerEntry."Due Date")
        else
            AddFeeDueDate := CalcDate(ReminderLevel."Grace Period", AddFeeDueDate);

        MarginalPerc := Round(AddFeePerLine * 100 / CustLedgerEntry."Original Amount", 0.01);

        if CurrencyCode = '' then begin
            GeneralLedgerSetup.Get();
            CurrencyCode := GeneralLedgerSetup."LCY Code";
        end;

        // expected result
        if LanguageCode <> Language.GetUserLanguageCode() then begin
            ReminderTermsTranslation.Get(ReminderTerms.Code, LanguageCode);
            TextOnReportExpected := ReminderTermsTranslation."Note About Line Fee on Report"
        end else
            TextOnReportExpected := ReminderTerms."Note About Line Fee on Report";

        ElementExpectedValue := StrSubstNo(TextOnReportExpected, Format(AddFeePerLine, 0, 9),
            CurrencyCode, AddFeeDueDate, Format(MarginalPerc, 0, 9));

        if LevelNo = 1 then
            LibraryReportDataset.LoadDataSetFile();

        if AddFeePerLine > 0 then
            LibraryReportDataset.AssertElementWithValueExists('LineFeeCaptionLbl', ElementExpectedValue)
        else
            asserterror LibraryReportDataset.AssertElementWithValueExists('LineFeeCaptionLbl', ElementExpectedValue);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHServiceInvoice(var ServiceInvoice: TestRequestPage "Service - Invoice")
    begin
        ServiceInvoice.DisplayAdditionalFeeNote.SetValue(true);
        ServiceInvoice.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName())
    end;
}
