codeunit 144117 "UT VAT Communication"
{
    // 1-2.   Purpose of the test is to verify error on Prepmt. CM Refers to Period of Purchase Line and Sales Line table.
    // 3-14.  Purpose of the test is to verify error when Individual Person Type True or False and Resident type Resident or Non - Resident on General Journal - Test,Sales Document - Test,Purchase Document - Test and Service Document - Test report.
    // 15-20. Purpose of the test is to verify Prepmt. CM Refers To Period field with option blank,Current,Current Calendar Year and Previous Calendar Year on Sales Line.
    // 20-24. Purpose of the test is to verify Prepmt. CM Refers To Period field with option blank,Current,Current Calendar Year and Previous Calendar Year on Purchase Line.
    // 25-27. Purpose of the test is to verify VAT Entry Type Resident, Type Sale or Purchase for Tax Representative Type Contact on VAT Transaction report.
    // 
    // Covers Test Cases for WI - 345416
    // -------------------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                                TFS ID
    // -------------------------------------------------------------------------------------------------------------------------
    // OnValidatePrepmtCMRefersToPeriodPurchaseLineError, OnValidatePrepmtCMRefersToPeriodSalesLineError                266448
    // OnAfterGetRecIndividualPersonFalseGenJournalTest, OnAfterGetRecIndividualPersonTrueGenJournalTest                265942
    // OnAfterGetRecTypeNonResidentGenJournalTest, OnAfterGetRecIndividualPersonFalseSalesDocumentTest                  265865
    // OnAfterGetRecIndividualPersonTrueSalesDocumentTest, OnAfterGetRecTypeNonResidentSalesDocumentTest                266271
    // OnAfterGetRecIndividualPersonFalsePurchaseDocumentTest, OnAfterGetRecIndividualPersonTruePurchaseDocumentTest    266450
    // OnAfterGetRecTypeNonResidentPurchaseDocumentTest, OnAfterGetRecIndividualPersonFalseServiceDocumentTest          266449
    // OnAfterGetRecIndividualPersonTrueServiceDocumentTest, OnAfterGetRecTypeNonResidentServiceDocumentTest
    // 
    // Covers Test Cases for WI - 345256
    // -------------------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                                TFS ID
    // -------------------------------------------------------------------------------------------------------------------------
    // OnValidatePrepmtCMRefersToPeriodBlankSalesLn, OnValidatePrepmtCMRefersToPeriodCrntSalesLn                         266482
    // OnValidatePrepmtCMRefersToPeriodCrntCalYearSalesLn, OnValidatePrepmtCMRefersToPeriodPreviousCalYearSalesLn        266473
    // OnValidatePrepmtCMRefersToPeriodSalesHeaderError,                                                                 266173
    // OnValidatePrepmtCMRefersToPeriodBlankPurchLn, OnValidatePrepmtCMRefersToPeriodCurrentPurchLn                      266048
    // OnValidatePrepmtCMRefersToPeriodCrntCalYearPurchLn, OnValidatePrepmtCMRefersToPeriodPreviousCalYearPurchLn        266036
    // OnValidatePrepmtCMRefersToPeriodPurchaseHeaderError                                                               266150
    // OnAfterGetRecordTypeSaleContactVATTransaction,OnAfterGetRecordTypeSaleCustomerVATTransaction
    // OnAfterGetRecordTypePurchaseVATTransaction

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
        LibrarySales: Codeunit "Library - Sales";
        DialogErr: Label 'Dialog';
        ErrorTextNumberCap: Label 'ErrorText_Number_';
        FiscalCodeWarningTxt: Label 'You must specify a value for the Fiscal Code field in the document header when the Individual Person field is selected and the Resident field is set to Resident.';
        GenJournalCountryRegionTxt: Label 'You must specify a value for the Country/Region Code field when the Resident field is set to Non-Resident.';
        GenJournalErrorTextNumberCap: Label 'ErrorTextNumber';
        GenJournalFiscalCodeTxt: Label 'You must specify a value for the Fiscal Code field when the Individual Person field is selected and the Resident field is set to Resident.';
        GenJournalVATRegistrationTxt: Label 'You must specify a value for the VAT Registration No. field when the Individual Person field is not selected.';
        MessageNotMatchMsg: Label 'Message must be same.';
        PurchaseMsg: Label 'You have changed Prepmt. CM Refers to Period on the purchase header, but it has not been changed on the existing purchase lines.';
        SalesMsg: Label 'You have changed Prepmt. CM Refers to Period on the sales header, but it has not been changed on the existing sales lines.';
        PurchaseDocumentCountryRegionTxt: Label 'You must specify a value for the Buy-from Country/Region Code field in the document header when the Resident field is set to Non-Resident.';
        SalesDocumentCountryRegionTxt: Label 'You must specify a value for the Sell-to Country/Region Code field in the document header when the Resident field is set to Non-Resident.';
        ServiceDocumentCountryRegionTxt: Label 'You must specify a value for the Country/Region Code field in the document header when the Resident field is set to Non-Resident.';
        VATEntryOperationOccurredDateCap: Label 'VAT_Entry__Operation_Occurred_Date_';
        VATEntryVATRegistrationNoCap: Label 'VAT_Entry__VAT_Entry___VAT_Registration_No__';
        VATRegistrationNoWarningTxt: Label 'You must specify a value for the VAT Registration No. field in the document header when the Individual Person field is not selected.';
        VATRegNoOperationOccurredDateCap: Label 'VATRegNo__Operation_Occurred_Date_';
        VATRegistrationNoCap: Label 'VATRegNo__VAT_Registration_No__';
        WarningCap: Label 'WarningCaption';
        WarningErrorTextNumberCap: Label 'ErrorText_Number_Caption';
        WarningTxt: Label 'Warning!';

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidatePrepmtCMRefersToPeriodPurchaseLineError()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Purpose of the test is to verify error on Prepmt. CM Refers to Period of Table - 39 Purchase Line.
        // Setup.
        Initialize();
        CreatePurchaseOrder(PurchaseLine, true, PurchaseHeader.Resident::Resident, PurchaseLine."Prepmt. CM Refers to Period"::Current);  // Using value True for Individual Person.

        // Exercise.
        asserterror PurchaseLine.Validate("Prepmt. CM Refers to Period", PurchaseLine."Prepmt. CM Refers to Period"::" ");

        // Verify: Verify Error Code. Actual error is "The Prepmt. CM Refers to Period field can only be blank when Prepmt. Line Amount Excl. VAT = 0".
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidatePrepmtCMRefersToPeriodSalesLineError()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Purpose of the test is to verify error on Prepmt. CM Refers to Period of Table - 37 Sales Line.
        // Setup.
        Initialize();
        CreateSalesOrder(SalesLine, true, SalesHeader.Resident::Resident, SalesLine."Prepmt. CM Refers to Period"::Current);  // Using value True for Individual Person.

        // Exercise.
        asserterror SalesLine.Validate("Prepmt. CM Refers to Period", SalesLine."Prepmt. CM Refers to Period"::" ");

        // Verify: Verify Error Code. Actual error is "The Prepmt. CM Refers to Period field can only be blank when Prepmt. Line Amount Excl. VAT = 0".
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [HandlerFunctions('GeneralJournalTestRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecIndividualPersonFalseGenJournalTest()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Purpose of the test is to verify error on General Journal - Test Report ID - 2 when Individual Person Type False and Resident type Resident.
        GeneralJournalTestWithResident(false, GenJournalLine.Resident::Resident, GenJournalVATRegistrationTxt);  // Using value False for Individual Person.
    end;

    [Test]
    [HandlerFunctions('GeneralJournalTestRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecIndividualPersonTrueGenJournalTest()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Purpose of the test is to verify error on General Journal - Test Report ID - 2 when Individual Person Type True and Resident type Resident.
        GeneralJournalTestWithResident(true, GenJournalLine.Resident::Resident, GenJournalFiscalCodeTxt);  // Using value True for Individual Person.
    end;

    [Test]
    [HandlerFunctions('GeneralJournalTestRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecTypeNonResidentGenJournalTest()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Purpose of the test is to verify error on General Journal - Test Report ID - 2 when Individual Person Type True and Resident type Non - Resident.
        GeneralJournalTestWithResident(true, GenJournalLine.Resident::"Non-Resident", GenJournalCountryRegionTxt);  // Using value True for Individual Person.
    end;

    local procedure GeneralJournalTestWithResident(IndividualPerson: Boolean; Resident: Option; ErrorTextNumber: Text)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Setup.
        Initialize();
        CreateGeneralJournalLine(GenJournalLine, IndividualPerson, Resident);

        // Enqueue value for Request Page Handler - GeneralJournalTestRequestPageHandler.
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Batch Name");

        // Exercise & Verify.
        RunAndVerifyWarningOnReport(GenJournalErrorTextNumberCap, WarningCap, ErrorTextNumber, REPORT::"General Journal - Test");
    end;

    [Test]
    [HandlerFunctions('SalesDocumentTestRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecIndividualPersonFalseSalesDocumentTest()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Purpose of the test is to verify error on Sales Document - Test Report ID - 202 when Individual Person Type False and Resident type Resident.
        SalesDocumentTestWithResident(false, SalesHeader.Resident::Resident, VATRegistrationNoWarningTxt);  // Using value False for Individual Person.
    end;

    [Test]
    [HandlerFunctions('SalesDocumentTestRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecIndividualPersonTrueSalesDocumentTest()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Purpose of the test is to verify error on Sales Document - Test Report ID - 202 when Individual Person Type True and Resident type Resident.
        SalesDocumentTestWithResident(true, SalesHeader.Resident::Resident, FiscalCodeWarningTxt);  // Using value True for Individual Person.
    end;

    [Test]
    [HandlerFunctions('SalesDocumentTestRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecTypeNonResidentSalesDocumentTest()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Purpose of the test is to verify error on Sales Document - Test Report ID - 202 when Individual Person Type True and Resident type Non - Resident.
        SalesDocumentTestWithResident(true, SalesHeader.Resident::"Non-Resident", SalesDocumentCountryRegionTxt);  // Using value True for Individual Person.
    end;

    local procedure SalesDocumentTestWithResident(IndividualPerson: Boolean; Resident: Option; ErrorTextNumber: Text)
    var
        SalesLine: Record "Sales Line";
    begin
        // Setup.
        Initialize();
        CreateSalesOrder(SalesLine, IndividualPerson, Resident, SalesLine."Prepmt. CM Refers to Period"::Current);
        LibraryVariableStorage.Enqueue(SalesLine."Document No.");  // Enqueue value for Request Page Handler - SalesDocumentTestRequestPageHandler.

        // Exercise & Verify.
        RunAndVerifyWarningOnReport(ErrorTextNumberCap, WarningErrorTextNumberCap, ErrorTextNumber, REPORT::"Sales Document - Test");
    end;

    [Test]
    [HandlerFunctions('PurchaseDocumentTestRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecIndividualPersonFalsePurchaseDocumentTest()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Purpose of the test is to verify error on Purchase Document - Test Report ID - 402 when Individual Person Type False and Resident type Resident.
        PurchaseDocumentTestWithResident(false, PurchaseHeader.Resident::Resident, VATRegistrationNoWarningTxt);  // Using value False for Individual Person.
    end;

    [Test]
    [HandlerFunctions('PurchaseDocumentTestRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecIndividualPersonTruePurchaseDocumentTest()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Purpose of the test is to verify error on Purchase Document - Test Report ID - 402 when Individual Person Type True and Resident type Resident.
        PurchaseDocumentTestWithResident(true, PurchaseHeader.Resident::Resident, FiscalCodeWarningTxt);  // Using value True for Individual Person.
    end;

    [Test]
    [HandlerFunctions('PurchaseDocumentTestRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecTypeNonResidentPurchaseDocumentTest()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Purpose of the test is to verify error on Purchase Document - Test Report ID - 402 when Individual Person Type True and Resident type Non - Resident.
        PurchaseDocumentTestWithResident(true, PurchaseHeader.Resident::"Non-Resident", PurchaseDocumentCountryRegionTxt);  // Using value True for Individual Person.
    end;

    local procedure PurchaseDocumentTestWithResident(IndividualPerson: Boolean; Resident: Option; ErrorTextNumber: Text)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // Setup.
        Initialize();
        CreatePurchaseOrder(PurchaseLine, IndividualPerson, Resident, PurchaseLine."Prepmt. CM Refers to Period"::Current);
        LibraryVariableStorage.Enqueue(PurchaseLine."Document No.");  // Enqueue value for Request Page Handler - PurchaseDocumentTestRequestPageHandler.

        // Exercise & Verify.
        RunAndVerifyWarningOnReport(ErrorTextNumberCap, WarningErrorTextNumberCap, ErrorTextNumber, REPORT::"Purchase Document - Test");
    end;

    [Test]
    [HandlerFunctions('ServiceDocumentTestRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecIndividualPersonFalseServiceDocumentTest()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Purpose of the test is to verify error on Service Document - Test Report ID - 5915 when Individual Person Type False and Resident type Resident.
        ServiceDocumentTestWithResident(false, ServiceHeader.Resident::Resident, VATRegistrationNoWarningTxt);  // Using value False for Individual Person.
    end;

    [Test]
    [HandlerFunctions('ServiceDocumentTestRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecIndividualPersonTrueServiceDocumentTest()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Purpose of the test is to verify error on Service Document - Test Report ID - 5915 when Individual Person Type True and Resident type Resident.
        ServiceDocumentTestWithResident(true, ServiceHeader.Resident::Resident, FiscalCodeWarningTxt);  // Using value True for Individual Person.
    end;

    [Test]
    [HandlerFunctions('ServiceDocumentTestRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecTypeNonResidentServiceDocumentTest()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Purpose of the test is to verify error on Service Document - Test Report ID - 5915 when Individual Person Type True and Resident type Non - Resident.
        ServiceDocumentTestWithResident(true, ServiceHeader.Resident::"Non-Resident", ServiceDocumentCountryRegionTxt);  // Using value True for Individual Person.
    end;

    local procedure ServiceDocumentTestWithResident(IndividualPerson: Boolean; Resident: Option; ErrorTextNumber: Text)
    var
        ServiceLine: Record "Service Line";
    begin
        // Setup.
        Initialize();
        CreateServiceOrder(ServiceLine, IndividualPerson, Resident);
        LibraryVariableStorage.Enqueue(ServiceLine."Document No.");  // Enqueue value for Request Page Handler - ServiceDocumentTestRequestPageHandler.

        // Exercise & Verify.
        RunAndVerifyWarningOnReport(ErrorTextNumberCap, WarningErrorTextNumberCap, ErrorTextNumber, REPORT::"Service Document - Test");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidatePrepmtCMRefersToPeriodBlankSalesLn()
    var
        SalesLine: Record "Sales Line";
    begin
        // Purpose of the test is to verify Prepmt. CM Refers To Period field with option blank on Table - 37 Sales Line.
        SalesOrderWithPrepmtCMRefersToPeriod(SalesLine."Prepmt. CM Refers to Period"::" ");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidatePrepmtCMRefersToPeriodCrntSalesLn()
    var
        SalesLine: Record "Sales Line";
    begin
        // Purpose of the test is to verify Prepmt. CM Refers To Period field with option Current on Table - 37 Sales Line.
        SalesOrderWithPrepmtCMRefersToPeriod(SalesLine."Prepmt. CM Refers to Period"::Current);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidatePrepmtCMRefersToPeriodCrntCalYearSalesLn()
    var
        SalesLine: Record "Sales Line";
    begin
        // Purpose of the test is to verify Prepmt. CM Refers To Period field with option Current Calendar Year on Table - 37 Sales Line.
        SalesOrderWithPrepmtCMRefersToPeriod(SalesLine."Prepmt. CM Refers to Period"::"Current Calendar Year");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidatePrepmtCMRefersToPeriodPreviousCalYearSalesLn()
    var
        SalesLine: Record "Sales Line";
    begin
        // Purpose of the test is to verify Prepmt. CM Refers To Period field with option Previous Calendar Year on Table - 37 Sales Line.
        SalesOrderWithPrepmtCMRefersToPeriod(SalesLine."Prepmt. CM Refers to Period"::"Previous Calendar Year");
    end;

    local procedure SalesOrderWithPrepmtCMRefersToPeriod(PrepmtCMRefersToPeriod: Option)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
    begin
        // Setup.
        Initialize();

        // Exercise.
        CreateSalesOrder(SalesLine, true, SalesHeader.Resident::Resident, PrepmtCMRefersToPeriod);  // Using value True for Individual Person.

        // Verify: Verify Prepmt. CM Refers To Period on Sales Order.
        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("No.", SalesLine."Document No.");
        SalesOrder.SalesLines."Prepmt. CM Refers to Period".AssertEquals(PrepmtCMRefersToPeriod);
        SalesOrder.Close();
    end;

    [Test]
    [HandlerFunctions('PrepmtCMRefersToPeriodMessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidatePrepmtCMRefersToPeriodSalesHeaderError()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Purpose of the test is to verify error on Prepmt. CM Refers to Period of Table - 36 Sales Header.
        // Setup.
        Initialize();
        CreateSalesOrder(SalesLine, true, SalesHeader.Resident::Resident, SalesLine."Prepmt. CM Refers to Period"::Current);  // Using value True for Individual Person.
        SalesHeader.Get(SalesLine."Document Type"::Order, SalesLine."Document No.");
        LibraryVariableStorage.Enqueue(SalesMsg);  // Enqueue message for PrepmtCMRefersToPeriodMessageHandler.

        // Exercise.
        SalesHeader.Validate(
          "Prepmt. CM Refers to Period", SalesHeader."Prepmt. CM Refers to Period"::"Current Calendar Year");

        // Verify: Verify Message in PrepmtCMRefersToPeriodMessageHandler.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidatePrepmtCMRefersToPeriodBlankPurchLn()
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // Purpose of the test is to verify Prepmt. CM Refers To Period field with option blank on Table - 39 Purchase Line.
        PurchaseOrderWithPrepmtCMRefersToPeriod(PurchaseLine."Prepmt. CM Refers to Period"::" ");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidatePrepmtCMRefersToPeriodCurrentPurchLn()
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // Purpose of the test is to verify Prepmt. CM Refers To Period field with option Current on Table - 39 Purchase Line.
        PurchaseOrderWithPrepmtCMRefersToPeriod(PurchaseLine."Prepmt. CM Refers to Period"::Current);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidatePrepmtCMRefersToPeriodCrntCalYearPurchLn()
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // Purpose of the test is to verify Prepmt. CM Refers To Period field with option Current Calendar Year on Table - 39 Purchase Line.
        PurchaseOrderWithPrepmtCMRefersToPeriod(PurchaseLine."Prepmt. CM Refers to Period"::"Current Calendar Year");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidatePrepmtCMRefersToPeriodPreviousCalYearPurchLn()
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // Purpose of the test is to verify Prepmt. CM Refers To Period field with option Previous Calendar Year on Table - 39 Purchase Line.
        PurchaseOrderWithPrepmtCMRefersToPeriod(PurchaseLine."Prepmt. CM Refers to Period"::"Previous Calendar Year");
    end;

    local procedure PurchaseOrderWithPrepmtCMRefersToPeriod(PrepmtCMRefersToPeriod: Option)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // Setup.
        Initialize();

        // Exercise.
        CreatePurchaseOrder(PurchaseLine, true, PurchaseHeader.Resident::Resident, PrepmtCMRefersToPeriod);  // Using value True for Individual Person.

        // Verify: Verify Prepmt. CM Refers To Period on Purchase Order.
        PurchaseOrder.OpenEdit();
        PurchaseOrder.FILTER.SetFilter("No.", PurchaseLine."Document No.");
        PurchaseOrder.PurchLines."Prepmt. CM Refers to Period".AssertEquals(PrepmtCMRefersToPeriod);
        PurchaseOrder.Close();
    end;

    [Test]
    [HandlerFunctions('PrepmtCMRefersToPeriodMessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidatePrepmtCMRefersToPeriodPurchaseHeaderError()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Purpose of the test is to verify error on Prepmt. CM Refers to Period of Table - 38 Purchase Header.
        // Setup.
        Initialize();
        CreatePurchaseOrder(PurchaseLine, true, PurchaseHeader.Resident::Resident, PurchaseLine."Prepmt. CM Refers to Period"::Current);  // Using value True for Individual Person.
        PurchaseHeader.Get(PurchaseLine."Document Type"::Order, PurchaseLine."Document No.");
        LibraryVariableStorage.Enqueue(PurchaseMsg);  // Enqueue message for PrepmtCMRefersToPeriodMessageHandler.

        // Exercise.
        PurchaseHeader.Validate(
          "Prepmt. CM Refers to Period", PurchaseHeader."Prepmt. CM Refers to Period"::"Current Calendar Year");

        // Verify: Verify Message in PrepmtCMRefersToPeriodMessageHandler.
    end;

    [Test]
    [HandlerFunctions('VATTransactionRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordTypeSaleContactVATTransaction()
    var
        Customer: Record Customer;
        VATEntry: Record "VAT Entry";
    begin
        // Purpose of the test is to verify VAT Entry Type Resident, Type Sale for Tax Representative Type Contact on Report ID - 12191 VAT Transaction.
        RunVATTransaction(
          VATEntry.Resident::"Non-Resident", VATEntry.Type::Sale, Customer."Tax Representative Type"::Contact, true,
          VATEntryOperationOccurredDateCap, VATEntryVATRegistrationNoCap);  // Using EU Service True.
    end;

    [Test]
    [HandlerFunctions('VATTransactionRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordTypeSaleCustomerVATTransaction()
    var
        Customer: Record Customer;
        VATEntry: Record "VAT Entry";
    begin
        // Purpose of the test is to verify VAT Entry Type Resident, Type Sale for Tax Representative Type Customer on Report ID - 12191 VAT Transaction.
        RunVATTransaction(
          VATEntry.Resident::"Non-Resident", VATEntry.Type::Sale, Customer."Tax Representative Type"::Customer, true,
          VATEntryOperationOccurredDateCap, VATEntryVATRegistrationNoCap);  // Using EU Service True.
    end;

    [Test]
    [HandlerFunctions('VATTransactionRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordTypePurchaseVATTransaction()
    var
        Customer: Record Customer;
        VATEntry: Record "VAT Entry";
    begin
        // Purpose of the test is to verify VAT Entry Type Resident, Type Purchase for Tax Representative Type Blank on Report ID - 12191 VAT Transaction.
        RunVATTransaction(
          VATEntry.Resident::Resident, VATEntry.Type::Purchase, Customer."Tax Representative Type"::" ", false,
          VATRegNoOperationOccurredDateCap, VATRegistrationNoCap);  // Using EU Service False and blank Tax Representative Type.
    end;

    local procedure RunVATTransaction(Resident: Option; Type: Enum "General Posting Type"; TaxRepresentativeType: Option; EUService: Boolean; OperationOccurredDate: Text; VATRegistrationNo: Text)
    var
        VATEntry: Record "VAT Entry";
    begin
        // Setup.
        Initialize();
        CreateVATEntry(VATEntry, Type, TaxRepresentativeType, Resident, EUService);
        LibraryVariableStorage.Enqueue(VATEntry."Operation Occurred Date");  // Enqueue value for VATTransactionRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"VAT Transaction");

        // Verify.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(OperationOccurredDate, Format(VATEntry."Operation Occurred Date"));
        LibraryReportDataset.AssertElementWithValueExists(VATRegistrationNo, VATEntry."VAT Registration No.");
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
        LibrarySales.DisableWarningOnCloseUnpostedDoc();
    end;

    local procedure CreateCustomer(TaxRepresentativeType: Option): Code[20]
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        CustomerPostingGroup.FindFirst();
        Customer."No." := LibraryUTUtility.GetNewCode();
        Customer.Name := Customer."No.";
        Customer."Tax Representative Type" := TaxRepresentativeType;
        Customer."Tax Representative No." := LibraryUTUtility.GetNewCode();
        Customer."Customer Posting Group" := CustomerPostingGroup.Code;
        Customer.Insert();
        exit(Customer."No.");
    end;

    local procedure CreateGeneralJournalBatch(JournalTemplateName: Code[10]): Code[10]
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        GenJournalBatch."Journal Template Name" := JournalTemplateName;
        GenJournalBatch.Name := LibraryUTUtility.GetNewCode10();
        GenJournalBatch.Insert();
        exit(GenJournalBatch.Name);
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; IndividualPerson: Boolean; Resident: Option)
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        CreateVATPostingSetup(VATPostingSetup);
        GenJournalLine."Journal Template Name" := CreateGeneralJournalTemplate();
        GenJournalLine."Journal Batch Name" := CreateGeneralJournalBatch(GenJournalLine."Journal Template Name");
        GenJournalLine."Account Type" := GenJournalLine."Account Type"::Customer;
        GenJournalLine."Document No." := LibraryUTUtility.GetNewCode();
        GenJournalLine."Bal. Gen. Posting Type" := GenJournalLine."Bal. Gen. Posting Type"::Sale;
        GenJournalLine."Bal. VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";
        GenJournalLine."Bal. VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";
        GenJournalLine."Include in VAT Transac. Rep." := true;
        GenJournalLine."Individual Person" := IndividualPerson;
        GenJournalLine.Resident := Resident;
        GenJournalLine.Insert();
    end;

    local procedure CreateGeneralJournalTemplate(): Code[10]
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.Name := LibraryUTUtility.GetNewCode10();
        GenJournalTemplate.Insert();
        exit(GenJournalTemplate.Name);
    end;

    local procedure CreatePurchaseOrder(var PurchaseLine: Record "Purchase Line"; IndividualPerson: Boolean; Resident: Option; PrepmtCMRefersToPeriod: Option)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader."No." := LibraryUTUtility.GetNewCode();
        PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::Order;
        PurchaseHeader."Prepmt. CM Refers to Period" := PrepmtCMRefersToPeriod;
        PurchaseHeader."Individual Person" := IndividualPerson;
        PurchaseHeader.Resident := Resident;
        PurchaseHeader.Insert();
        PurchaseLine."Document Type" := PurchaseHeader."Document Type";
        PurchaseLine."Document No." := PurchaseHeader."No.";
        PurchaseLine.Quantity := LibraryRandom.RandDec(10, 2);
        PurchaseLine."Qty. to Invoice" := PurchaseLine.Quantity;
        PurchaseLine."Prepmt. Line Amount" := LibraryRandom.RandInt(10);
        PurchaseLine."Prepmt. CM Refers to Period" := PurchaseHeader."Prepmt. CM Refers to Period";
        PurchaseLine."Include in VAT Transac. Rep." := true;
        PurchaseLine.Insert();
    end;

    local procedure CreateSalesOrder(var SalesLine: Record "Sales Line"; IndividualPerson: Boolean; Resident: Option; PrepmtCMRefersToPeriod: Option)
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader."No." := LibraryUTUtility.GetNewCode();
        SalesHeader."Document Type" := SalesHeader."Document Type"::Order;
        SalesHeader."Prepmt. CM Refers to Period" := PrepmtCMRefersToPeriod;
        SalesHeader."Individual Person" := IndividualPerson;
        SalesHeader.Resident := Resident;
        SalesHeader.Insert();
        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        SalesLine.Quantity := LibraryRandom.RandDec(10, 2);
        SalesLine."Qty. to Invoice" := SalesLine.Quantity;
        SalesLine."Prepmt. Line Amount" := LibraryRandom.RandInt(10);
        SalesLine."Prepmt. CM Refers to Period" := SalesHeader."Prepmt. CM Refers to Period";
        SalesLine."Include in VAT Transac. Rep." := true;
        SalesLine.Insert();
    end;

    local procedure CreateServiceOrder(var ServiceLine: Record "Service Line"; IndividualPerson: Boolean; Resident: Option)
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
    begin
        ServiceHeader."No." := LibraryUTUtility.GetNewCode();
        ServiceHeader."Document Type" := ServiceHeader."Document Type"::Order;
        ServiceHeader."Bill-to Customer No." := CreateCustomer(Customer."Tax Representative Type"::" ");
        ServiceHeader."Individual Person" := IndividualPerson;
        ServiceHeader.Resident := Resident;
        ServiceHeader.Insert();
        ServiceItemLine."Document Type" := ServiceHeader."Document Type";
        ServiceItemLine."Document No." := ServiceHeader."No.";
        ServiceItemLine.Insert();
        ServiceLine."Document Type" := ServiceItemLine."Document Type";
        ServiceLine."Document No." := ServiceItemLine."Document No.";
        ServiceLine.Quantity := LibraryRandom.RandDec(10, 2);
        ServiceLine."Qty. to Invoice" := ServiceLine.Quantity;
        ServiceLine."Include in VAT Transac. Rep." := true;
        ServiceLine.Insert();
    end;

    local procedure CreateVATEntry(var VATEntry: Record "VAT Entry"; Type: Enum "General Posting Type"; TaxRepresentativeType: Option; Resident: Option; EUService: Boolean)
    var
        VATEntry2: Record "VAT Entry";
    begin
        VATEntry2.FindLast();
        VATEntry."Entry No." := VATEntry2."Entry No." + 1;
        VATEntry.Type := Type;
        VATEntry."Posting Date" := WorkDate();
        VATEntry."Operation Occurred Date" := VATEntry."Posting Date";
        VATEntry."Fiscal Code" := LibraryUTUtility.GetNewCode();
        VATEntry."Include in VAT Transac. Rep." := true;
        VATEntry."Individual Person" := false;
        VATEntry.Resident := Resident;
        VATEntry."VAT Registration No." := LibraryUTUtility.GetNewCode10();
        VATEntry."Bill-to/Pay-to No." := CreateCustomer(TaxRepresentativeType);
        VATEntry."EU Service" := EUService;
        VATEntry.Insert();
    end;

    local procedure CreateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        VATPostingSetup."VAT Bus. Posting Group" := LibraryUTUtility.GetNewCode10();
        VATPostingSetup."VAT Prod. Posting Group" := LibraryUTUtility.GetNewCode10();
        VATPostingSetup."Include in VAT Transac. Rep." := true;
        VATPostingSetup.Insert();
    end;

    local procedure RunAndVerifyWarningOnReport(ErrorTextNumberCap: Text; WarningErrorTextNumberCap: Text; ErrorTextNumber: Text; ReportID: Integer)
    begin
        // Exercise.
        REPORT.Run(ReportID);  // Opens GeneralJournalTestRequestPageHandler, SalesDocumentTestRequestPageHandler, PurchaseDocumentTestRequestPageHandler and ServiceDocumentTestRequestPageHandler.

        // Verify: Verify Error Text Number and Warning Error on Report General Journal - Test, Sales Document - Test, Purchase Document - Test and Service Document - Test.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(ErrorTextNumberCap, ErrorTextNumber);
        LibraryReportDataset.AssertElementWithValueExists(WarningErrorTextNumberCap, StrSubstNo(WarningTxt));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GeneralJournalTestRequestPageHandler(var GeneralJournalTest: TestRequestPage "General Journal - Test")
    var
        JournalBatchName: Variant;
        JournalTemplateName: Variant;
    begin
        LibraryVariableStorage.Dequeue(JournalTemplateName);
        LibraryVariableStorage.Dequeue(JournalBatchName);
        GeneralJournalTest."Gen. Journal Line".SetFilter("Journal Template Name", JournalTemplateName);
        GeneralJournalTest."Gen. Journal Line".SetFilter("Journal Batch Name", JournalBatchName);
        GeneralJournalTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesDocumentTestRequestPageHandler(var SalesDocumentTest: TestRequestPage "Sales Document - Test")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        SalesDocumentTest."Sales Header".SetFilter("No.", No);
        SalesDocumentTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseDocumentTestRequestPageHandler(var PurchaseDocumentTest: TestRequestPage "Purchase Document - Test")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        PurchaseDocumentTest."Purchase Header".SetFilter("No.", No);
        PurchaseDocumentTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ServiceDocumentTestRequestPageHandler(var ServiceDocumentTest: TestRequestPage "Service Document - Test")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        ServiceDocumentTest."Service Header".SetFilter("No.", No);
        ServiceDocumentTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VATTransactionRequestPageHandler(var VATTransaction: TestRequestPage "VAT Transaction")
    var
        OperationOccurredDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(OperationOccurredDate);
        VATTransaction.FiscalCode.SetFilter("Operation Occurred Date", Format(OperationOccurredDate));
        VATTransaction.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure PrepmtCMRefersToPeriodMessageHandler(Message: Text)
    var
        PrepmtMsg: Variant;
    begin
        LibraryVariableStorage.Dequeue(PrepmtMsg);
        Assert.IsTrue(StrPos(Message, PrepmtMsg) > 0, MessageNotMatchMsg);
    end;
}

