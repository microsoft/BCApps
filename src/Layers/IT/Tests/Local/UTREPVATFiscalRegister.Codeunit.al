codeunit 144160 "UT REP VAT Fiscal Register"
{
    // 1. Purpose of the test is to validate OnPreReport Trigger of Report - 12120 VAT Register - Print when Ending Date is earlier than Starting Date.
    // 2. Purpose of the test is to validate Unrealized VAT - OnAfterGetRecord Trigger of Report - 12120 VAT Register Print for Purchase.
    // 3. Purpose of the test is to validate Unrealized VAT - OnAfterGetRecord Trigger of Report - 12120 VAT Register Print for Sales.
    // 4. Purpose of the test is to validate VAT Registration No. and Customer Name in Unrealized VAT section of Report - 12120 VAT Register Print for Sales.
    // 5. Purpose of the test is to validate VAT Registration No. and Vendor Name in Unrealized VAT section of Report - 12120 VAT Register Print for Purchase.
    // 
    // Covers Test Cases for WI - 346393
    // ----------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                        TFS ID
    // ----------------------------------------------------------------------------------------------------------------
    // OnPreReportDateVATRegisterPrintError,OnAfterGetRecordUnrealizedVATVATRegisterPrintPurch                   289808
    // OnAfterGetRecordUnrealizedVATVATRegisterPrintSale                                                  289616,289604
    // 
    // Covers Test Cases for WI - 105575
    // ----------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                        TFS ID
    // ----------------------------------------------------------------------------------------------------------------
    // VATRegisterPrintSalesPaymentWithUnrealizedVAT,VATRegisterPrintPurchasePaymentWithUnrealizedVAT

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        DialogErr: Label 'Dialog';
        IOCap: Label 'I.O.';
        PrintLegendCap: Label 'PrintLegend';
        SignumUnrealizedAmountCap: Label 'Signum____Unrealized_Amount_';
        UnrealizedVATSellToBuyFromNoCap: Label 'UnrealizedVAT__Sell_to_Buy_from_No__';
        UnrealizedVATEntryNoCap: Label 'UnrealizedVAT_UnrealizedVAT__Entry_No__';
        UnrealizedVATIntraCap: Label 'UnrealizedVAT_IntraC';
        PrintingType: Option Test,Final,Reprint;
        UnrealizedVATNameCap: Label 'UnrealizedVAT_Name';
        UnrealizedVATVATRegCap: Label 'UnrealizedVAT_VATReg';

    [Test]
    [HandlerFunctions('VATRegisterPrintRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportDateVATRegisterPrintError()
    var
        NoSeries: Record "No. Series";
    begin
        // Purpose of the test is to validate OnPreReport Trigger of Report - 12120 VAT Register - Print when Ending Date is earlier than Starting Date.
        // Setup.
        Initialize();
        UpdateCompanyInformationRegisterCompanyNumber();
        CreateNumberSeries(NoSeries);
        EnqueueValuesForVATRegisterPrintRequestPageHandler(
          NoSeries."VAT Register", PrintingType::Final, CalcDate('<' + Format(-LibraryRandom.RandInt(10)) + 'D>', WorkDate()));  // Enqueue earlier Ending Date than Starting Date for handler - VATRegisterPrintRequestPageHandler.

        // Exercise.
        asserterror REPORT.Run(REPORT::"VAT Register - Print");  // Opens handler - VATRegisterPrintRequestPageHandler.

        // Verify: Verify Error Code. Actual error message: Start Date and End Date do not correspond to begin\end of period.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [HandlerFunctions('VATRegisterPrintRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordUnrealizedVATVATRegisterPrintPurch()
    var
        VATBookEntry: Record "VAT Book Entry";
    begin
        // Purpose of the test is to validate Unrealized VAT - OnAfterGetRecord Trigger of Report - 12120 VAT Register Print for Purchase.
        // Setup & Exercise.
        Initialize();
        VATPrintRegisterWithVATBookEntry(
          VATBookEntry, CreateVendor(), VATBookEntry.Type::Purchase, VATBookEntry."VAT Calculation Type"::"Normal VAT",
          VATBookEntry."Document Type"::Invoice);

        // Verify: Verify values on XML of Report - VAT Register - Print.
        VerifyValuesOnVATRegisterPrintReport(
          '', VATBookEntry."Sell-to/Buy-from No.", false, VATBookEntry."Entry No.", VATBookEntry."Unrealized Amount");  // Using blank for Intra text and FALSE for PrintLegend.
    end;

    [Test]
    [HandlerFunctions('VATRegisterPrintRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordUnrealizedVATVATRegisterPrintSale()
    var
        VATBookEntry: Record "VAT Book Entry";
    begin
        // Purpose of the test is to validate Unrealized VAT - OnAfterGetRecord Trigger of Report - 12120 VAT Register Print for Sales.
        // Setup & Exercise.
        Initialize();
        VATPrintRegisterWithVATBookEntry(
          VATBookEntry, CreateCustomer(), VATBookEntry.Type::Sale, VATBookEntry."VAT Calculation Type"::"Reverse Charge VAT",
          VATBookEntry."Document Type"::"Credit Memo");

        // Verify: Verify values on XML of Report - VAT Register - Print.
        VerifyValuesOnVATRegisterPrintReport(
          Format(IOCap), VATBookEntry."Sell-to/Buy-from No.", true, VATBookEntry."Entry No.", -VATBookEntry."Unrealized Amount");  // Using TRUE for PrintLegend.
    end;

    [Test]
    [HandlerFunctions('VATRegisterPrintRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VATRegisterPrintSalesPaymentWithUnrealizedVAT()
    var
        VATBookEntry: Record "VAT Book Entry";
        NoSeries: Record "No. Series";
        Customer: Record Customer;
    begin
        // Purpose of the test is to validate VAT Registration No. and Customer Name in Unrealized VAT section of Report - 12120 VAT Register Print for Sales.

        // Setup: Create a VAT Book Entry of Payment Document Type with Unrealized VAT for Sales.
        Initialize();
        UpdateCompanyInformationRegisterCompanyNumber();
        CreateNumberSeries(NoSeries);
        CreateVATBookEntry(
          VATBookEntry, CreateCustomerWithNameAndVATReg(Customer), NoSeries.Code, VATBookEntry.Type::Sale,
          VATBookEntry."VAT Calculation Type"::"Normal VAT", VATBookEntry."Document Type"::Payment);

        // Exercise: Run report "VAT Register - Print".
        // Verify: Verify UnrealizedVAT_Name and UnrealizedVAT_VATReg on XML of Report - VAT Register - Print.
        RunReportVATRegisterPrintAndVerifyUnrealizedSection(NoSeries."VAT Register", Customer.Name, Customer."VAT Registration No.");
    end;

    [Test]
    [HandlerFunctions('VATRegisterPrintRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VATRegisterPrintPurchasePaymentWithUnrealizedVAT()
    var
        VATBookEntry: Record "VAT Book Entry";
        NoSeries: Record "No. Series";
        Vendor: Record Vendor;
    begin
        // Purpose of the test is to validate VAT Registration No. and Vendor Name in Unrealized VAT section of Report - 12120 VAT Register Print for Purchase.

        // Setup: Create a VAT Book Entry of Payment Document Type with Unrealized VAT for Purchase.
        Initialize();
        UpdateCompanyInformationRegisterCompanyNumber();
        CreateNumberSeries(NoSeries);
        CreateVATBookEntry(
          VATBookEntry, CreateVendorWithNameAndVATReg(Vendor), NoSeries.Code, VATBookEntry.Type::Purchase,
          VATBookEntry."VAT Calculation Type"::"Normal VAT", VATBookEntry."Document Type"::Payment);

        // Exercise: Run report "VAT Register - Print".
        // Verify: Verify UnrealizedVAT_Name and UnrealizedVAT_VATReg on XML of Report - VAT Register - Print.
        RunReportVATRegisterPrintAndVerifyUnrealizedSection(NoSeries."VAT Register", Vendor.Name, Vendor."VAT Registration No.");
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateVATBookEntry(var VATBookEntry: Record "VAT Book Entry"; SellToBuyFromNo: Code[20]; NoSeries: Code[20]; Type: Enum "General Posting Type"; VATCalculationType: Enum "Tax Calculation Type"; DocumentType: Enum "Gen. Journal Document Type")
    var
        VATBookEntry2: Record "VAT Book Entry";
    begin
        VATBookEntry2.FindLast();
        VATBookEntry."Entry No." := VATBookEntry2."Entry No." + 1;
        VATBookEntry.Type := Type;
        VATBookEntry."No. Series" := NoSeries;
        VATBookEntry."Posting Date" := WorkDate();
        VATBookEntry."Sell-to/Buy-from No." := SellToBuyFromNo;
        VATBookEntry."Document No." := LibraryUTUtility.GetNewCode();
        VATBookEntry."VAT Identifier" := CreateVATIdentifier();
        VATBookEntry."Unrealized VAT" := true;
        VATBookEntry."VAT Calculation Type" := VATCalculationType;
        VATBookEntry."Unrealized Amount" := LibraryRandom.RandDec(10, 2);
        VATBookEntry."Unrealized Base" := VATBookEntry."Unrealized Amount";
        VATBookEntry."Unrealized VAT Entry No." := CreateVATEntry(VATBookEntry, DocumentType);
        VATBookEntry.Insert();
    end;

    local procedure CreateVATEntry(VATBookEntry: Record "VAT Book Entry"; DocumentType: Enum "Gen. Journal Document Type"): Integer
    var
        VATEntry: Record "VAT Entry";
        VATEntry2: Record "VAT Entry";
    begin
        VATEntry2.FindLast();
        VATEntry."Entry No." := VATEntry2."Entry No." + 1;
        VATEntry.Type := VATBookEntry.Type;
        VATEntry."No. Series" := VATBookEntry."No. Series";
        VATEntry."Posting Date" := WorkDate();
        VATEntry."Document No." := VATBookEntry."Document No.";
        VATEntry."Bill-to/Pay-to No." := VATBookEntry."Sell-to/Buy-from No.";
        VATEntry."VAT Identifier" := VATBookEntry."VAT Identifier";
        VATEntry."Document Type" := DocumentType;
        VATEntry."VAT Calculation Type" := VATBookEntry."VAT Calculation Type";
        VATEntry."Unrealized VAT Entry No." := VATEntry."Entry No.";
        VATEntry."Unrealized Amount" := VATBookEntry."Unrealized Amount";
        VATEntry."Unrealized Base" := VATBookEntry."Unrealized Base";
        VATEntry.Insert();
        exit(VATEntry."Entry No.");
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        Customer."No." := LibraryUTUtility.GetNewCode();
        Customer.Insert();
        exit(Customer."No.");
    end;

    local procedure CreateCustomerWithNameAndVATReg(var Customer: Record Customer): Code[20]
    begin
        Customer.Get(CreateCustomer());
        Customer.Validate(Name, Customer."No.");
        Customer.Validate("VAT Registration No.", CreateVATRegister());
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateNumberSeries(var NoSeries: Record "No. Series")
    begin
        NoSeries.Code := LibraryUTUtility.GetNewCode10();
        NoSeries."VAT Register" := CreateVATRegister();
        NoSeries.Insert();
    end;

    local procedure CreateVATIdentifier(): Code[20]
    var
        VATIdentifier: Record "VAT Identifier";
    begin
        VATIdentifier.Code := LibraryUTUtility.GetNewCode10();
        VATIdentifier.Insert();
        exit(VATIdentifier.Code);
    end;

    local procedure CreateVATRegister(): Code[10]
    var
        VATRegister: Record "VAT Register";
    begin
        VATRegister.Code := LibraryUTUtility.GetNewCode10();
        VATRegister.Insert();
        exit(VATRegister.Code);
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        Vendor."No." := LibraryUTUtility.GetNewCode();
        Vendor.Insert();
        exit(Vendor."No.");
    end;

    local procedure CreateVendorWithNameAndVATReg(var Vendor: Record Vendor): Code[20]
    begin
        Vendor.Get(CreateVendor());
        Vendor.Validate(Name, Vendor."No.");
        Vendor.Validate("VAT Registration No.", CreateVATRegister());
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure EnqueueValuesForVATRegisterPrintRequestPageHandler(VATRegisterCode: Code[10]; PrintingTypeLocal: Option; PeriodEndingDate: Date)
    begin
        LibraryVariableStorage.Enqueue(VATRegisterCode);
        LibraryVariableStorage.Enqueue(PrintingTypeLocal);
        LibraryVariableStorage.Enqueue(PeriodEndingDate);
    end;

    local procedure RunReportVATRegisterPrint(VATRegister: Code[10]; PrintType: Option)
    begin
        EnqueueValuesForVATRegisterPrintRequestPageHandler(VATRegister, PrintType, WorkDate()); // Enqueue WORKDATE as PeriodEndingDate for handler - VATRegisterPrintRequestPageHandler.
        REPORT.Run(REPORT::"VAT Register - Print"); // Opens handler - VATRegisterPrintRequestPageHandler.
    end;

    local procedure RunReportVATRegisterPrintAndVerifyUnrealizedSection(VATRegister: Code[10]; Name: Text[100]; VATRegistrationNo: Code[20])
    begin
        RunReportVATRegisterPrint(VATRegister, PrintingType::Test);
        VerifyUnrealizedSectionOnVATRegisterPrintReport(Name, VATRegistrationNo);
    end;

    local procedure UpdateCompanyInformationRegisterCompanyNumber()
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation."Register Company No." := LibraryUTUtility.GetNewCode();
        CompanyInformation.Modify();
    end;

    local procedure VATPrintRegisterWithVATBookEntry(var VATBookEntry: Record "VAT Book Entry"; SellToBuyFromNo: Code[20]; Type: Enum "General Posting Type"; VATCalculationType: Enum "Tax Calculation Type"; DocumentType: Enum "Gen. Journal Document Type")
    var
        NoSeries: Record "No. Series";
    begin
        // Setup.
        UpdateCompanyInformationRegisterCompanyNumber();
        CreateNumberSeries(NoSeries);
        CreateVATBookEntry(VATBookEntry, SellToBuyFromNo, NoSeries.Code, Type, VATCalculationType, DocumentType);

        // Exercise: Run report "VAT Register - Print".
        RunReportVATRegisterPrint(NoSeries."VAT Register", PrintingType::Test);
    end;

    local procedure VerifyValuesOnVATRegisterPrintReport(IntraText: Text; SellToBuyFromNo: Code[20]; PrintLegend: Boolean; EntryNo: Integer; ExpectedAmount: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(UnrealizedVATSellToBuyFromNoCap, SellToBuyFromNo);
        LibraryReportDataset.AssertElementWithValueExists(UnrealizedVATEntryNoCap, EntryNo);
        LibraryReportDataset.AssertElementWithValueExists(SignumUnrealizedAmountCap, ExpectedAmount);
        LibraryReportDataset.AssertElementWithValueExists(PrintLegendCap, PrintLegend);
        LibraryReportDataset.AssertElementWithValueExists(UnrealizedVATIntraCap, IntraText);
    end;

    local procedure VerifyUnrealizedSectionOnVATRegisterPrintReport(Name: Text[100]; VATRegNo: Code[20])
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(UnrealizedVATNameCap, Name);
        LibraryReportDataset.AssertElementWithValueExists(UnrealizedVATVATRegCap, VATRegNo);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VATRegisterPrintRequestPageHandler(var VATRegisterPrint: TestRequestPage "VAT Register - Print")
    var
        VATRegister: Variant;
        PrintingTypeVariant: Variant;
        PeriodEndingDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(VATRegister);
        LibraryVariableStorage.Dequeue(PrintingTypeVariant);
        LibraryVariableStorage.Dequeue(PeriodEndingDate);
        VATRegisterPrint.VATRegister.SetValue(VATRegister);
        VATRegisterPrint.PeriodStartingDate.SetValue(WorkDate());
        VATRegisterPrint.PeriodEndingDate.SetValue(PeriodEndingDate);
        VATRegisterPrint.PrintingType.SetValue(PrintingTypeVariant);
        VATRegisterPrint.FiscalCode.SetValue(LibraryUTUtility.GetNewCode());
        VATRegisterPrint.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

