codeunit 144042 "UT TAB Due Date"
{
    //  1. Purpose of the test is to validate Payment Day - OnValidate Trigger of Page 10700 - Payment Day for Domestic Customer.
    //  2. Purpose of the test is to validate Payment Day - OnValidate Trigger of Page 10700 - Payment Day for EU Customer.
    //  3. Purpose of the test is to validate Payment Day - OnValidate Trigger of Page 10700 - Payment Day for Domestic Vendor.
    //  4. Purpose of the test is to validate Payment Day - OnValidate Trigger of Page 10700 - Payment Day for EU Vendor.
    //  5. Purpose of the test is to validate Payment Day - OnValidate Trigger of Page 10700 - Payment Day for Company Information.
    //  6. Purpose of the test is to validate Payment Day - OnValidate Trigger of Page 10701 - Non - Payment Periods for Domestic Customer.
    //  7. Purpose of the test is to validate Payment Day - OnValidate Trigger of Page 10701 - Non - Payment Periods for EU Customer.
    //  8. Purpose of the test is to validate Payment Day - OnValidate Trigger of Page 10701 - Non - Payment Periods for Domestic Vendor.
    //  9. Purpose of the test is to validate Payment Day - OnValidate Trigger of Page 10701 - Non - Payment Periods for EU Vendor.
    // 10. Purpose of the test is to validate Payment Day - OnValidate Trigger of Page 10701 - Non - Payment Periods for Company Information.
    // 
    // Covers Test Cases for WI - 351128.
    // -----------------------------------------------------------------------------
    // Test Function Name                                                   TFS ID
    // -----------------------------------------------------------------------------
    // OnInsertPaymentDayForDomesticCustomer                                152318
    // OnInsertPaymentDayForEUCustomer                                      152317
    // OnInsertPaymentDayForDomesticVendor                                  152315
    // OnInsertPaymentDayForEUVendor                                        152314
    // OnInsertPaymentDayForCompanyInformation                              152322
    // OnInsertNonPaymentPeriodForDomesticCustomer                          152316
    // OnInsertNonPaymentPeriodForEUCustomer                                152317
    // OnInsertNonPaymentPeriodForDomesticVendor                            152313
    // OnInsertNonPaymentPeriodForEUVendor                                  152314
    // OnInsertNonPaymentPeriodForCompanyInformation                        152322

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryRandom: Codeunit "Library - Random";
        RecordMustBeExistMsg: Label 'Record must be Exist.';
        LibraryVariableStorage: Codeunit "Library - Variable Storage";

    [Test]
    [HandlerFunctions('PaymentDaysModalPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnInsertPaymentDayForDomesticCustomer()
    var
        PaymentDay: Record "Payment Day";
    begin
        // Purpose of the test is to validate Payment Day - OnValidate Trigger of Page 10700 - Payment Day for Domestic Customer.

        // Setup: Create Domestic Customer.
        Initialize();
        OnInsertPaymentDay(PaymentDay."Table Name"::Customer, CreateCustomer('', ''));  // Blank - Country/Region Code and VAT Registration Number.
    end;

    [Test]
    [HandlerFunctions('PaymentDaysModalPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnInsertPaymentDayForEUCustomer()
    var
        PaymentDay: Record "Payment Day";
    begin
        // Purpose of the test is to validate Payment Day - OnValidate Trigger of Page 10700 - Payment Day for EU Customer.

        // Setup: Create EU Customer.
        Initialize();
        OnInsertPaymentDay(PaymentDay."Table Name"::Customer, CreateCustomer(CreateCountryRegion(), LibraryUTUtility.GetNewCode()));  // Generate VAT Registration Number.
    end;

    [Test]
    [HandlerFunctions('PaymentDaysModalPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnInsertPaymentDayForDomesticVendor()
    var
        PaymentDay: Record "Payment Day";
    begin
        // Purpose of the test is to validate Payment Day - OnValidate Trigger of Page 10700 - Payment Day for Domestic Vendor.

        // Setup: Create Domestic Vendor.
        Initialize();
        OnInsertPaymentDay(PaymentDay."Table Name"::Vendor, CreateVendor('', ''));  // Blank - Country/Region Code and VAT Registration Number.
    end;

    [Test]
    [HandlerFunctions('PaymentDaysModalPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnInsertPaymentDayForEUVendor()
    var
        PaymentDay: Record "Payment Day";
    begin
        // Purpose of the test is to validate Payment Day - OnValidate Trigger of Page 10700 - Payment Day for EU Vendor.

        // Setup: Create EU Vendor.
        Initialize();
        OnInsertPaymentDay(PaymentDay."Table Name"::Vendor, CreateVendor(CreateCountryRegion(), LibraryUTUtility.GetNewCode()));  // Generate VAT Registration Number.
    end;

    [Test]
    [HandlerFunctions('PaymentDaysModalPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnInsertPaymentDayForCompanyInformation()
    var
        PaymentDay: Record "Payment Day";
    begin
        // Purpose of the test is to validate Payment Day - OnValidate Trigger of Page 10700 - Payment Day for Company Information.

        // Setup: Update Company Information - Payment Days Code.
        Initialize();
        OnInsertPaymentDay(PaymentDay."Table Name"::"Company Information", UpdateCompanyInformation());
    end;

    local procedure OnInsertPaymentDay(TableName: Option; Number: Code[20])
    begin
        // Exercise.
        OpenPaymentDay(TableName, Number);  // Opens handler - PaymentDaysModalPageHandler.

        // Verify: Verify Payments Day exist for Table Name and Number and Code on Record - Payment Day.
        VerifyPaymentDay(TableName, Number);
    end;

    [Test]
    [HandlerFunctions('NonPaymentPeriodsModalPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnInsertNonPaymentPeriodForDomesticEUCustomer()
    var
        NonPaymentPeriod: Record "Non-Payment Period";
    begin
        // Purpose of the test is to validate Payment Day - OnValidate Trigger of Page 10701 - Non - Payment Periods for Domestic Customer.

        // Setup: Create Domestic Customer.
        Initialize();
        OnInsertNonPaymentPeriod(NonPaymentPeriod."Table Name"::Customer, CreateCustomer('', ''));  // Blank - Country/Region Code and VAT Registration Number.
    end;

    [Test]
    [HandlerFunctions('NonPaymentPeriodsModalPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnInsertNonPaymentPeriodForEUCustomer()
    var
        NonPaymentPeriod: Record "Non-Payment Period";
    begin
        // Purpose of the test is to validate Payment Day - OnValidate Trigger of Page 10701 - Non - Payment Periods for EU Customer.

        // Setup: Create EU Customer.
        Initialize();
        OnInsertNonPaymentPeriod(
          NonPaymentPeriod."Table Name"::Customer, CreateCustomer(CreateCountryRegion(), LibraryUTUtility.GetNewCode()));  // Generate VAT Registration Number.
    end;

    [Test]
    [HandlerFunctions('NonPaymentPeriodsModalPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnInsertNonPaymentPeriodForDomesticEUVendor()
    var
        NonPaymentPeriod: Record "Non-Payment Period";
    begin
        // Purpose of the test is to validate Payment Day - OnValidate Trigger of Page 10701 - Non - Payment Periods for Domestic Vendor.

        // Setup: Create Domestic Vendor.
        Initialize();
        OnInsertNonPaymentPeriod(NonPaymentPeriod."Table Name"::Vendor, CreateVendor('', ''));  // Blank - Country/Region Code and VAT Registration Number.
    end;

    [Test]
    [HandlerFunctions('NonPaymentPeriodsModalPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnInsertNonPaymentPeriodForEUVendor()
    var
        NonPaymentPeriod: Record "Non-Payment Period";
    begin
        // Purpose of the test is to validate Payment Day - OnValidate Trigger of Page 10701 - Non - Payment Periods for EU Vendor.

        // Setup: Create EU Vendor.
        Initialize();
        OnInsertNonPaymentPeriod(NonPaymentPeriod."Table Name"::Vendor, CreateVendor(CreateCountryRegion(), LibraryUTUtility.GetNewCode()));  // Generate VAT Registration Number.
    end;

    [Test]
    [HandlerFunctions('NonPaymentPeriodsModalPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnInsertNonPaymentPeriodForCompanyInformation()
    var
        NonPaymentPeriod: Record "Non-Payment Period";
    begin
        // Purpose of the test is to validate Payment Day - OnValidate Trigger of Page 10701 - Non - Payment Periods for Company Information.

        // Setup: Update Company Information - Non-Paymt. Periods Code.
        Initialize();
        OnInsertNonPaymentPeriod(NonPaymentPeriod."Table Name"::"Company Information", UpdateCompanyInformation());
    end;

    local procedure OnInsertNonPaymentPeriod(TableName: Option; Number: Code[20])
    begin
        // Exercise.
        OpenNonPaymentPeriodDay(TableName, Number);  // Opens handler - NonPaymentPeriodsModalPageHandler.

        // Verify: Verify Non Payment Period exist for Table Name, Number, From Date and To Date on Record - Non Payment Period.
        VerifyNonPaymentPeriod(TableName, Number);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateCountryRegion(): Code[10]
    var
        CountryRegion: Record "Country/Region";
    begin
        CountryRegion.Code := LibraryUTUtility.GetNewCode10();
        CountryRegion.Insert();
        exit(CountryRegion.Code);
    end;

    local procedure CreateCustomer(CountryRegionCode: Code[10]; VATRegistrationNo: Code[20]): Code[20]
    var
        Customer: Record Customer;
    begin
        Customer."No." := LibraryUTUtility.GetNewCode();
        Customer."Customer Posting Group" := LibraryUTUtility.GetNewCode10();
        Customer."Gen. Bus. Posting Group" := LibraryUTUtility.GetNewCode10();
        Customer."Country/Region Code" := CountryRegionCode;
        Customer."Payment Terms Code" := CreatePaymentTerms();
        Customer."Payment Days Code" := Customer."No.";
        Customer."Non-Paymt. Periods Code" := Customer."Payment Days Code";
        Customer."VAT Registration No." := VATRegistrationNo;
        Customer.Insert();
        exit(Customer."No.");
    end;

    local procedure CreatePaymentTerms(): Code[10]
    var
        PaymentTerms: Record "Payment Terms";
    begin
        PaymentTerms.Code := LibraryUTUtility.GetNewCode10();
        Evaluate(PaymentTerms."Due Date Calculation", Format(LibraryRandom.RandIntInRange(10, 50)) + 'D>');  // Random - Due Date Calculation Period.
        PaymentTerms."VAT distribution" := PaymentTerms."VAT distribution"::Proportional;
        PaymentTerms.Insert();
        exit(PaymentTerms.Code);
    end;

    local procedure CreateVendor(CountryRegionCode: Code[10]; VATRegistrationNo: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        Vendor."No." := LibraryUTUtility.GetNewCode();
        Vendor."Vendor Posting Group" := LibraryUTUtility.GetNewCode10();
        Vendor."Gen. Bus. Posting Group" := LibraryUTUtility.GetNewCode10();
        Vendor."Country/Region Code" := CountryRegionCode;
        Vendor."Payment Terms Code" := CreatePaymentTerms();
        Vendor."Payment Days Code" := Vendor."No.";
        Vendor."Non-Paymt. Periods Code" := Vendor."Payment Days Code";
        Vendor."VAT Registration No." := VATRegistrationNo;
        Vendor.Insert();
        exit(Vendor."No.");
    end;

    local procedure OpenNonPaymentPeriodDay(TableName: Option; "Code": Code[20])
    var
        NonPaymentPeriod: Record "Non-Payment Period";
    begin
        NonPaymentPeriod.SetRange("Table Name", TableName);
        NonPaymentPeriod.SetRange(Code, Code);
        PAGE.RunModal(PAGE::"Non-Payment Periods", NonPaymentPeriod);  // Opens handler - NonPaymentPeriodsModalPageHandler.
    end;

    local procedure OpenPaymentDay(TableName: Option; "Code": Code[20])
    var
        PaymentDay: Record "Payment Day";
    begin
        PaymentDay.SetRange("Table Name", TableName);
        PaymentDay.SetRange(Code, Code);
        PAGE.RunModal(PAGE::"Payment Days", PaymentDay);  // Opens handler - PaymentDaysModalPageHandler.
    end;

    local procedure UpdateCompanyInformation(): Code[10]
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation."Non-Paymt. Periods Code" := LibraryUTUtility.GetNewCode10();
        CompanyInformation."Payment Days Code" := CompanyInformation."Non-Paymt. Periods Code";
        CompanyInformation.Modify();
        exit(CompanyInformation."Non-Paymt. Periods Code");
    end;

    local procedure VerifyNonPaymentPeriod(TableName: Option; "Code": Code[20])
    var
        NonPaymentPeriod: Record "Non-Payment Period";
    begin
        Assert.IsTrue(NonPaymentPeriod.Get(TableName, Code, WorkDate()), RecordMustBeExistMsg);  // WORKDATE as FromDate,
        NonPaymentPeriod.TestField("To Date", WorkDate());
    end;

    local procedure VerifyPaymentDay(TableName: Option; CustomerNo: Code[20])
    var
        PaymentDay: Record "Payment Day";
        PaymentsDay: Variant;
    begin
        LibraryVariableStorage.Dequeue(PaymentsDay);
        Assert.IsTrue(PaymentDay.Get(TableName, CustomerNo, PaymentsDay), RecordMustBeExistMsg);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure NonPaymentPeriodsModalPageHandler(var NonPaymentPeriods: TestPage "Non-Payment Periods")
    begin
        NonPaymentPeriods."From Date".SetValue(WorkDate());
        NonPaymentPeriods."To Date".SetValue(WorkDate());
        NonPaymentPeriods.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PaymentDaysModalPageHandler(var PaymentDays: TestPage "Payment Days")
    begin
        PaymentDays."Day of the month".SetValue(LibraryRandom.RandIntInRange(10, 20));
        LibraryVariableStorage.Enqueue(PaymentDays."Day of the month".AsInteger());
        PaymentDays.OK().Invoke();
    end;
}

