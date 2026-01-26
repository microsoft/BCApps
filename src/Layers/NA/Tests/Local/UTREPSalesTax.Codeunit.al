codeunit 142066 "UT REP Sales Tax"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Sales Tax] [Reports]
    end;

    var
        Assert: Codeunit Assert;
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryService: Codeunit "Library - Service";
        AreaFiltersCap: Label 'AreaFilters';
        CompanyAddressCap: Label 'CompanyAddress1';
        CopyNoCap: Label 'CopyNo';
        CopyTextCap: Label 'CopyTxt';
        CopyTxt: Label 'COPY';
        DialogErr: Label 'Dialog';
        FilterValuesTxt: Label '%1: %2';
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        GeneralPostingSetupMsg: Label 'General Posting Setup %1 does not exist.';
        QuoteUnitPriceCap: Label 'AmountExclInvDisc_PurchLine';
        ServiceOrderUnitPriceCap: Label 'UnitPrice_ServLine';
        ServiceQuoteUnitPriceCap: Label 'Service_Line__Unit_Price_';
        TaxAmountCap: Label 'TaxAmount';
        TempServInvoiceLineNoCap: Label 'TempServInvoiceLineNo';
        TempServCrMemoLineNoCap: Label 'TempServCrMemoLineNo';
        TotalCap: Label 'Total %1';
        TotalSalesTaxTxt: Label 'Total Sales Tax';
        TotalTaxLabelCap: Label 'TotalTaxLabel';
        TotalTaxTxt: Label 'Total Tax';
        TotalTextCap: Label 'TotalText';
        UnitPriceCap: Label 'AmountExclInvDisc';
        QtyErr: Label 'Quantity is not correct in %1';
        AmountIncludingVATErr: Label 'Amount Including VAT is not correct in %1';
        IncorrectLineCountErr: Label 'Service Invoice-Sales Tax report prints incorrect entries';
        TaxAmountNotEqualTotalErr: Label 'Tax Amount is not equal to Total in Test Report';

    [Test]
    [HandlerFunctions('SalesTaxesCollectedRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportWithIncludeSalesSalesTaxesCollected()
    begin
        // Purpose of the test is to validate Trigger OnPreReport with Include Sales of REP24.
        Initialize();

        // Parameters used for TaxJurisdictionCode, IncludeSales,IncludePurchases,IncludeUseTax.
        OnPreReportTaxInclusionsSalesTaxesCollected('Includes Taxes Collected From Sales Only', true, false, false);
    end;

    [Test]
    [HandlerFunctions('SalesTaxesCollectedRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportWithIncludeSalesPurchUseTaxSalesTaxesCollected()
    begin
        // Purpose of the test is to validate Trigger OnPreReport with Include Sales,Include Purchases and Include Use Tax of REP24.
        Initialize();
        OnPreReportTaxInclusionsSalesTaxesCollected('Includes Taxes Collected, Recoverable Taxes Paid, and Use Taxes', true, true, true);
    end;

    [Test]
    [HandlerFunctions('SalesTaxesCollectedRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportWithIncludeSalesPurchSalesTaxesCollected()
    begin
        // Purpose of the test is to validate Trigger OnPreReport with Include Sales and Include Purchases of REP24.
        Initialize();
        OnPreReportTaxInclusionsSalesTaxesCollected('Includes Taxes Collected and Recoverable Taxes Paid', true, true, false);
    end;

    [Test]
    [HandlerFunctions('SalesTaxesCollectedRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportWithIncludeSalesUseTaxSalesTaxesCollected()
    begin
        // Purpose of the test is to validate Trigger OnPreReport with Include Sales and Include Use Tax of REP24.
        Initialize();
        OnPreReportTaxInclusionsSalesTaxesCollected('Includes Taxes Collected From Sales and Use Taxes', true, false, true);
    end;

    [Test]
    [HandlerFunctions('SalesTaxesCollectedRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportWithIncludePurchUseTaxSalesTaxesCollected()
    begin
        // Purpose of the test is to validate Trigger OnPreReport with Include Purchases and Include Use Tax of REP24.
        Initialize();
        OnPreReportTaxInclusionsSalesTaxesCollected('Includes Recoverable Taxes Paid On Purchases and Use Taxes', false, true, true);
    end;

    [Test]
    [HandlerFunctions('SalesTaxesCollectedRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportWithIncludePurchSalesTaxesCollected()
    begin
        // Purpose of the test is to validate Trigger OnPreReport with Include Purchase of REP24.
        Initialize();
        OnPreReportTaxInclusionsSalesTaxesCollected('Includes Recoverable Taxes Paid On Purchases Only', false, true, false);
    end;

    [Test]
    [HandlerFunctions('SalesTaxesCollectedRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportWithIncludeUseTaxSalesTaxesCollected()
    begin
        // Purpose of the test is to validate Trigger OnPreReport with Include Use Tax of REP24.
        Initialize();
        OnPreReportTaxInclusionsSalesTaxesCollected('Includes Use Taxes Only', false, false, true);
    end;

    local procedure OnPreReportTaxInclusionsSalesTaxesCollected(ExpectedText: Text[100]; IncludeSales: Boolean; IncludePurchases: Boolean; IncludeUseTax: Boolean)
    var
        TaxJurisdictionCode: Code[10];
    begin
        // Setup.
        TaxJurisdictionCode := MockTaxJurisdiction();
        EnqueueValuesForSalesTaxesCollected(TaxJurisdictionCode, IncludeSales, IncludePurchases, IncludeUseTax);

        // Exercise.
        REPORT.Run(REPORT::"Sales Taxes Collected");

        // Verify: Verifying Sales Taxes Collected Report using different filter.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('TaxInclusions', ExpectedText);
    end;

    [Test]
    [HandlerFunctions('SalesTaxesCollectedRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportWithoutTaxInclusionsSalesTaxesCollectedError()
    var
        TaxJurisdictionCode: Code[10];
    begin
        // Purpose of the test is to validate Trigger OnPreReport without Tax Inclusions of REP24.

        // Setup.
        Initialize();
        TaxJurisdictionCode := MockTaxJurisdiction();
        EnqueueValuesForSalesTaxesCollected(TaxJurisdictionCode, false, false, false);

        // Exercise.
        asserterror REPORT.Run(REPORT::"Sales Taxes Collected");

        // Verify: Verify the error thrown without Tax Inclusions.
        Assert.ExpectedError('You must check at least one of the check boxes labeled Include...');
    end;

    [Test]
    [HandlerFunctions('SalesTaxJurisdictionListRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportSalesTaxJurisdictionList()
    var
        TaxJurisdictionCode: Code[10];
    begin
        // Purpose of the test is to validate Trigger OnPreReport of REP10325.

        // Setup.
        Initialize();
        TaxJurisdictionCode := MockTaxJurisdiction();
        LibraryVariableStorage.Enqueue(TaxJurisdictionCode);  // Enqueue value for SalesTaxJurisdictionListRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Sales Tax Jurisdiction List");

        // Verify: Verifying Filters and Group Data values on Sales Tax Jurisdiction List Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('JurisFilters', StrSubstNo('Code: %1', TaxJurisdictionCode));
        LibraryReportDataset.AssertElementWithValueExists('GroupData', false);
    end;

    [Test]
    [HandlerFunctions('SalesTaxAreaListRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportSalesTaxAreaList()
    var
        TaxArea: Record "Tax Area";
        TaxAreaCode: Code[20];
    begin
        // Purpose of the test is to validate Trigger OnPreReport of Report 10321.

        // Setup.
        Initialize();
        TaxAreaCode := MockTaxArea();

        // Exercise.
        REPORT.Run(REPORT::"Sales Tax Area List");

        // Verify: Verifying filter values on Sales Tax Area List Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(
          AreaFiltersCap, StrSubstNo(FilterValuesTxt, TaxArea.FieldCaption(Code), TaxAreaCode));
    end;

    [Test]
    [HandlerFunctions('SalesTaxDetailByAreaRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportSalesTaxDetailByArea()
    var
        TaxArea: Record "Tax Area";
        TaxDetail: Record "Tax Detail";
        TaxAreaCode: Code[20];
    begin
        // Purpose of the test is to validate Trigger OnPreReport of Report 10322.

        // Setup.
        Initialize();
        TaxAreaCode := MockTaxArea();
        CreateTaxDetailWithJurisdiction(TaxDetail);
        LibraryVariableStorage.Enqueue(TaxDetail."Tax Group Code");  // Enqueue value to use in SalesTaxesCollectedRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Sales Tax Detail by Area");

        // Verify: Verifying filter values on Sales Tax Detail by Area Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(
          AreaFiltersCap, StrSubstNo(FilterValuesTxt, TaxArea.FieldCaption(Code), TaxAreaCode));
        LibraryReportDataset.AssertElementWithValueExists(
          'DetailsFilters', StrSubstNo(FilterValuesTxt, TaxDetail.FieldCaption("Tax Group Code"), TaxDetail."Tax Group Code"));
    end;

    [Test]
    [HandlerFunctions('SalesTaxDetailListRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordSalesTaxDetailList()
    var
        TaxJurisdiction: Record "Tax Jurisdiction";
    begin
        // Purpose of the test is to validate Tax Jurisdiction - OnAfterGetRecord trigger of Report ID - 10323.
        // Setup: Create Tax Jurisdiction.
        Initialize();
        TaxJurisdiction.Get(MockTaxJurisdiction());

        // Enqueue required for SalesTaxDetailListRequestPageHandler.
        LibraryVariableStorage.Enqueue(TaxJurisdiction.Code);

        // Exercise.
        REPORT.Run(REPORT::"Sales Tax Detail List");  // Opens SalesTaxDetailListRequestPageHandler.

        // Verify: Verify Report to Jurisdiction after report generation.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(
          'Tax_Jurisdiction_Report_to_Jurisdiction', TaxJurisdiction."Report-to Jurisdiction");
    end;

    [Test]
    [HandlerFunctions('SalesTaxGroupListRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportSalesTaxGroupList()
    var
        TaxGroup: Record "Tax Group";
        TaxGroupCode: Code[20];
    begin
        // Purpose of the test is to validate Tax Group - OnPreReport trigger of Report ID - 10324.
        // Setup: Create Tax Group.
        Initialize();
        TaxGroupCode := MockTaxGroup();

        // Exercise.
        REPORT.Run(REPORT::"Sales Tax Group List");  // Opens SalesTaxGroupListRequestPageHandler.

        // Verify: Verify Filters that Tax Group is updated on Report Sales Tax Group List.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(
          'TaxGroupFilters', StrSubstNo(FilterValuesTxt, TaxGroup.FieldCaption(Code), TaxGroupCode));
    end;

    [Test]
    [HandlerFunctions('ServiceOrderRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordServiceLineWithCurrencyForOrder()
    var
        ServiceLine: Record "Service Line";
    begin
        // Purpose of the test is to validate Service Line - OnAftergetRecord trigger of Report ID - 5900.
        // Setup: Create Service Order with Currency and Currency Factor.
        CreateServiceDocument(ServiceLine, CreateCurrencyAndExchangeRate(), ServiceLine."Document Type"::Order, 1);

        // Exercise.
        REPORT.Run(REPORT::"Service Order");  // Opens ServiceOrderRequestPageHandler.

        // Verify: Verify Unit Price after report generation.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(ServiceOrderUnitPriceCap, ServiceLine."Unit Price");
    end;

    [Test]
    [HandlerFunctions('ServiceOrderRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordServiceLineWithoutCurrencyForOrder()
    var
        ServiceLine: Record "Service Line";
    begin
        // Purpose of the test is to validate Service Line - OnAftergetRecord trigger of Report ID - 5900.
        // Setup: Create Service Order without Currency and Currency Factor.
        CreateServiceDocument(ServiceLine, '', ServiceLine."Document Type"::Order, 0);

        // Exercise.
        REPORT.Run(REPORT::"Service Order");  // Opens ServiceOrderRequestPageHandler.

        // Verify: Verify Unit Price after report generation.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(ServiceOrderUnitPriceCap, ServiceLine."Unit Price");
    end;

    [Test]
    [HandlerFunctions('ServiceQuoteRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordServiceLineWithCurrencyForQuote()
    var
        ServiceLine: Record "Service Line";
    begin
        // Purpose of the test is to validate Service Line - OnAftergetRecord trigger of Report ID - 5902.
        // Setup: Create Service Quote with Currency and Currency Factor.
        CreateServiceDocument(ServiceLine, CreateCurrencyAndExchangeRate(), ServiceLine."Document Type"::Quote, 1);
        Commit();  // Codeunit 5905 Service-Printed OnRun Calls commit.

        // Exercise.
        REPORT.Run(REPORT::"Service Quote");  // Opens ServiceOrderRequestPageHandler.

        // Verify: Verify Unit Price after report generation.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(ServiceQuoteUnitPriceCap, ServiceLine."Unit Price");
    end;

    [Test]
    [HandlerFunctions('ServiceQuoteRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordServiceLineWithoutCurrencyForQuote()
    var
        ServiceLine: Record "Service Line";
    begin
        // Purpose of the test is to validate Service Line - OnAftergetRecord trigger of Report ID - 5902.
        // Setup: Create Service Quote without Currency and Currency Factor.
        CreateServiceDocument(ServiceLine, '', ServiceLine."Document Type"::Quote, 0);
        Commit();  // Codeunit 5905 Service-Printed OnRun Calls commit.

        // Exercise.
        REPORT.Run(REPORT::"Service Quote");  // Opens ServiceOrderRequestPageHandler.

        // Verify: Verify Unit Price after report generation.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(ServiceQuoteUnitPriceCap, ServiceLine."Unit Price");
    end;

    [Test]
    [HandlerFunctions('PurchaseDocumentTestRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPurchaseHeaderPurchaseDocumentTest()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Purpose of the test is to validate Purchase Header - OnAfterGetRecord of Report ID - 402 Purchase Document - Test.

        // Setup.
        Initialize();
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateAndUpdateCurrency(), '', '');  // Tax Area Code and Tax Group Code as blank.

        // Exercise.
        REPORT.Run(REPORT::"Purchase Document - Test");  // Opens PurchaseDocumentTestReqPageHandler;

        // Verify.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(TotalTextCap, StrSubstNo(TotalCap, PurchaseHeader."Currency Code"));
    end;

    [Test]
    [HandlerFunctions('PurchaseDocumentTestRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordRoundLoopPurchaseDocumentTest()
    var
        PurchaseHeader: Record "Purchase Header";
        TaxArea: Record "Tax Area";
        TaxGroupCode: Code[20];
        LCYCode: Code[10];
    begin
        // Purpose of the test is to validate RoundLoop - OnAfterGetRecord of Report ID - 402 Purchase Document - Test.

        // Setup.
        Initialize();
        LCYCode := UpdateVATInUseOnGLSetup();
        TaxGroupCode := CreateTaxAreaWithTaxAreaLine(TaxArea, false);
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order, '', TaxArea.Code, TaxGroupCode);  // Currency Code as blank.

        // Exercise.
        REPORT.Run(REPORT::"Purchase Document - Test");  // Opens PurchaseDocumentTestReqPageHandler;

        // Verify.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(TotalTextCap, StrSubstNo(TotalCap, LCYCode));
        LibraryReportDataset.AssertElementWithValueExists('ErrorText_Number__Control103', StrSubstNo(GeneralPostingSetupMsg, ' '));  // Using blank value to make the string as expected message string.
    end;

    [Test]
    [HandlerFunctions('ServiceInvoiceSalesTaxRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnPreDataItemServInvHdrServInvSalesTax()
    var
        ResponsibilityCenter: Record "Responsibility Center";
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        // Purpose of the test is to validate OnPreDataItem Trigger of Service Invoice Header of Report 10474 - Service Invoice-Sales Tax.

        // Setup: Create Service Invoice Header.
        Initialize();
        CreatePostedServiceInvoice(ServiceInvoiceHeader, '');
        EnqueueValuesForServiceInvoiceAndCreditMemo(ServiceInvoiceHeader."No.", true, 0);
        ResponsibilityCenter.Get(ServiceInvoiceHeader."Responsibility Center");
        Commit();  // Commit required since explicit Commit used on OnRun Trigger of COD5902: Service Inv.-Printed.

        // Exercise.
        REPORT.Run(REPORT::"Service Invoice-Sales Tax");  // Set Print Company Address as TRUE on handler - ServiceInvoiceSalesTaxRequestPageHandler.

        // Verify: Verify Company Address on Report Service Invoice-Sales Tax.
        VerifyDataOnReport('No_ServiceInvoiceHeader', ServiceInvoiceHeader."No.");
        LibraryReportDataset.AssertElementWithValueExists(CompanyAddressCap, ResponsibilityCenter.Name);
    end;

    [Test]
    [HandlerFunctions('ServiceInvoiceSalesTaxRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecServInvHdrTaxAreaUSServInvSalesTax()
    var
        TaxArea: Record "Tax Area";
    begin
        // Purpose of the test is to validate OnAfterGetRecord of Service Invoice Header of Report 10474 - Service Invoice-Sales Tax.

        // Setup: Create Service Invoice Header with Tax Area Country US.
        Initialize();
        OnAfterGetRecordServInvHeaderTaxArea(TaxArea."Country/Region"::US, TotalSalesTaxTxt);
    end;

    [Test]
    [HandlerFunctions('ServiceInvoiceSalesTaxRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecServInvHdrTaxAreaCAServInvSalesTax()
    var
        TaxArea: Record "Tax Area";
    begin
        // Purpose of the test is to validate OnAfterGetRecord of Service Invoice Header of Report 10474 - Service Invoice-Sales Tax.

        // Setup: Create Service Invoice Header with Tax Area Country CA.
        Initialize();
        OnAfterGetRecordServInvHeaderTaxArea(TaxArea."Country/Region"::CA, TotalTaxTxt);
    end;

    local procedure OnAfterGetRecordServInvHeaderTaxArea(Country: Option; ExpectedValue: Text)
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        // Create Service Invoice.
        CreatePostedServiceInvoice(ServiceInvoiceHeader, '');
        EnqueueValuesForServiceInvoiceAndCreditMemo(ServiceInvoiceHeader."No.", false, 0);
        ServiceInvoiceHeader."Tax Area Code" := CreateTaxAreaWithCountry(Country);
        ServiceInvoiceHeader.Modify();
        Commit();  // Commit required since explicit Commit used on OnRun Trigger of COD5902: Service Inv.-Printed.

        // Exercise.
        REPORT.Run(REPORT::"Service Invoice-Sales Tax");  // Opens handler - ServiceInvoiceSalesTaxRequestPageHandler.

        // Verify: Verify Total Tax Label on Report  Service Invoice-Sales Tax.
        VerifyDataOnReport(TotalTaxLabelCap, ExpectedValue + ':');    // Not able to pass Symbol ':' as part of constant so used here.
    end;

    [Test]
    [HandlerFunctions('ServiceInvoiceSalesTaxRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordCopyLoopServiceInvoiceSalesTax()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        NumberOfCopies: Integer;
    begin
        // Purpose of the test is to validate OnAfterGetRecord Trigger of CopyLoop Service Invoice Header of Report 10474 - Service Invoice-Sales Tax.

        // Setup: Create Service Invoice.
        Initialize();
        NumberOfCopies := LibraryRandom.RandInt(10);
        CreatePostedServiceInvoice(ServiceInvoiceHeader, '');
        EnqueueValuesForServiceInvoiceAndCreditMemo(ServiceInvoiceHeader."No.", false, NumberOfCopies);
        Commit();  // Commit required since explicit Commit used on OnRun Trigger of COD5902: Service Inv.-Printed.

        // Exercise.
        REPORT.Run(REPORT::"Service Invoice-Sales Tax");  // Enqueue value for ServiceInvoiceSalesTaxRequestPageHandler.

        // Verify: Verify Copy Caption and total number of copies on Report Service Invoice-Sales Tax.
        VerifyDataOnReport(CopyTextCap, Format(CopyTxt));
        LibraryReportDataset.AssertElementWithValueExists(CopyNoCap, NumberOfCopies + 1);
    end;

    [Test]
    [HandlerFunctions('ServiceInvoiceSalesTaxRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordServInvLineItemServInvSalesTax()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ItemNo: Code[20];
    begin
        // Purpose of the test is to validate OnAfterGetRecord Trigger of Service Invoice Line of Report 10474 - Service Invoice-Sales Tax.

        // Setup: Create Service Invoice with Type - Item.
        Initialize();
        CreatePostedServiceInvoice(ServiceInvoiceHeader, '');
        EnqueueValuesForServiceInvoiceAndCreditMemo(ServiceInvoiceHeader."No.", false, 0);
        ItemNo := UpdateItemInServiceInvoiceLine(ServiceInvoiceHeader."No.");
        Commit();  // Commit required since explicit Commit used on OnRun Trigger of COD5902: Service Inv.-Printed.

        // Exercise.
        REPORT.Run(REPORT::"Service Invoice-Sales Tax");  // Opens handler - ServiceInvoiceSalesTaxRequestPageHandler.

        // Verify: Verify Item number on Report Service Invoice-Sales Tax.
        VerifyDataOnReport(TempServInvoiceLineNoCap, ItemNo);
    end;

    [Test]
    [HandlerFunctions('ServiceCreditMemoSalesTaxRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnPreDataItemServCrMemoHdrServCrMemoSalesTax()
    var
        ResponsibilityCenter: Record "Responsibility Center";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        // Purpose of the test is to validate OnPreDataItem Trigger of Service Credit Memo Header of Report 10173 - Service Credit Memo-Sales Tax

        // Setup: Create Service Credit Memo.
        Initialize();
        CreatePostedServiceCreditMemo(ServiceCrMemoHeader, '');
        EnqueueValuesForServiceInvoiceAndCreditMemo(ServiceCrMemoHeader."No.", true, 0);
        ResponsibilityCenter.Get(ServiceCrMemoHeader."Responsibility Center");
        Commit();  // Commit required since explicit Commit used on OnRun Trigger of COD5902: Service Inv.-Printed.

        // Exercise.
        REPORT.Run(REPORT::"Service Credit Memo-Sales Tax");  // Set Print Company Address as TRUE on handler -  ServiceCreditMemoSalesTaxRequestPageHandler.

        // Verify: Verify Service Credit Memo No and Company Address on Report - Service Credit Memo-Sales Tax
        VerifyDataOnReport('No_ServCrMemoHeader', ServiceCrMemoHeader."No.");
        LibraryReportDataset.AssertElementWithValueExists(CompanyAddressCap, ResponsibilityCenter.Name);
    end;

    [Test]
    [HandlerFunctions('ServiceCreditMemoSalesTaxRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecServCrMemoHdrTaxAreaUSServCrMemoSalesTax()
    var
        TaxArea: Record "Tax Area";
    begin
        // Purpose of the test is to validate OnAfterGetRecord of Service Credit Memo Header of Report 10173 - Service Credit Memo-Sales Tax

        // Setup: Create Service Credit Memo Header Invoice Header with Tax Area Country US.
        Initialize();
        OnAfterGetRecordServCrMemoHeaderTaxArea(TaxArea."Country/Region"::US, TotalSalesTaxTxt);
    end;

    [Test]
    [HandlerFunctions('ServiceCreditMemoSalesTaxRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecServCrMemoHdrTaxAreaCAServCrMemoSalesTax()
    var
        TaxArea: Record "Tax Area";
    begin
        // Purpose of the test is to validate OnAfterGetRecord of Service Credit Memo Header of Report 10173 - Service Credit Memo-Sales Tax

        // Setup: Create Service Credit Memo Header with Tax Area Country CA.
        Initialize();
        OnAfterGetRecordServCrMemoHeaderTaxArea(TaxArea."Country/Region"::CA, TotalTaxTxt);
    end;

    local procedure OnAfterGetRecordServCrMemoHeaderTaxArea(Country: Option; ExpectedValue: Text)
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        // Create Service Credit Memo.
        CreatePostedServiceCreditMemo(ServiceCrMemoHeader, '');
        EnqueueValuesForServiceInvoiceAndCreditMemo(ServiceCrMemoHeader."No.", false, 0);
        ServiceCrMemoHeader."Tax Area Code" := CreateTaxAreaWithCountry(Country);
        ServiceCrMemoHeader.Modify();
        Commit();  // Commit required since explicit Commit used on OnRun Trigger of COD5902: Service Inv.-Printed.

        // Exercise.
        REPORT.Run(REPORT::"Service Credit Memo-Sales Tax");  // Opens handler - ServiceCreditMemoSalesTaxRequestPageHandler.

        // Verify: Verify Total Tax Label on Report  Service Credit Memo-Sales Tax.
        VerifyDataOnReport(TotalTaxLabelCap, ExpectedValue + ':');  // Not able to pass Symbol - : as part of constant so used here.
    end;

    [Test]
    [HandlerFunctions('ServiceCreditMemoSalesTaxRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordCopyLoopServCrMemoSalesTax()
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        NumberOfCopies: Integer;
    begin
        // Purpose of the test is to validate OnAfterGetRecord Trigger of CopyLoop Service Credit Memo Header of Report 10173 - Service Credit Memo-Sales Tax.

        // Setup: Create Service Credit Memo.
        Initialize();
        NumberOfCopies := LibraryRandom.RandInt(10);
        CreatePostedServiceCreditMemo(ServiceCrMemoHeader, '');
        EnqueueValuesForServiceInvoiceAndCreditMemo(ServiceCrMemoHeader."No.", false, NumberOfCopies);
        Commit();  // Commit required since explicit Commit used on OnRun Trigger of COD5902: Service Inv.-Printed.

        // Exercise.
        REPORT.Run(REPORT::"Service Credit Memo-Sales Tax");  // Enqueue value for ServiceCreditMemoSalesTaxRequestPageHandler

        // Verify: Verify Copy Caption and total number of copies on Report Service Credit Memo-Sales Tax.
        VerifyDataOnReport(CopyTextCap, Format(CopyTxt));
        LibraryReportDataset.AssertElementWithValueExists(CopyNoCap, NumberOfCopies + 1);
    end;

    [Test]
    [HandlerFunctions('ServiceCreditMemoSalesTaxRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecServCrMemoLnItemSerCrMemoSalesTax()
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ItemNo: Code[20];
    begin
        // Purpose of the test is to validate OnAfterGetRecord Trigger of Service Credit Memo Header of Report 10173 - Service Credit Memo-Sales Tax.

        // Setup: Create Service Credit Memo with Type - Item.
        Initialize();
        CreatePostedServiceCreditMemo(ServiceCrMemoHeader, '');
        EnqueueValuesForServiceInvoiceAndCreditMemo(ServiceCrMemoHeader."No.", false, 0);
        ItemNo := UpdateItemInServiceCreditMemoLine(ServiceCrMemoHeader."No.");
        Commit();  // Commit required since explicit Commit used on OnRun Trigger of COD5902: Service Inv.-Printed.

        // Exercise.
        REPORT.Run(REPORT::"Service Credit Memo-Sales Tax");  // Opens handler - ServiceCreditMemoSalesTaxRequestPageHandler.

        // Verify: Verify Item number on Report Service Credit Memo-Sales Tax.
        VerifyDataOnReport(TempServCrMemoLineNoCap, ItemNo);
    end;

    [Test]
    [HandlerFunctions('SalesQuoteTestRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordSalesHeaderSalesQuote()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Purpose of the test is to validate OnAfterGetRecord Trigger of Sales Header of Report 10076 - Sales Quote.
        Initialize();
        OnAfterGetRecordSalesHeaderSalesDocument(SalesHeader."Document Type"::Quote, REPORT::"Sales Quote NA");
    end;

    [Test]
    [HandlerFunctions('SalesOrderTestRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordSalesHeaderSalesOrder()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Purpose of the test is to validate OnAfterGetRecord Trigger of Sales Header of Report 10075 - Sales Order.
        Initialize();
        OnAfterGetRecordSalesHeaderSalesDocument(SalesHeader."Document Type"::Order, REPORT::"Sales Order");
    end;

    [Test]
    [HandlerFunctions('SalesBlanketOrderRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordSalesHeaderSalesBlanketOrder()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Purpose of the test is to validate OnAfterGetRecord Trigger of Sales Header of Report 10069 - Sales Blanket Order.
        Initialize();
        OnAfterGetRecordSalesHeaderSalesDocument(SalesHeader."Document Type"::"Blanket Order", REPORT::"Sales Blanket Order");
    end;

    local procedure OnAfterGetRecordSalesHeaderSalesDocument(DocumentType: Enum "Sales Document Type"; ReportID: Option)
    var
        SalesHeader: Record "Sales Header";
        TaxArea: Record "Tax Area";
        TaxGroupCode: Code[20];
    begin
        // Setup: Create Tax Area With External Tax Engines, Create Sales Document according to the Document Type provided in parameter.
        TaxGroupCode := CreateTaxAreaWithTaxAreaLine(TaxArea, true);
        CreateSalesDocument(SalesHeader, DocumentType, TaxArea.Code, TaxGroupCode, '');

        // Exercise.
        asserterror REPORT.Run(ReportID);  // Opens SalesOrderTestRequestPageHandler,SalesQuoteTestRequestPageHandler,SalesBlanketOrderRequestPageHandler.

        // Verify: Verify Actual Error - "Invalid function call. Function reserved for external tax engines only".
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [HandlerFunctions('SalesQuoteTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordSalesLineSalesQuote()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Purpose of the test is to validate OnAfterGetRecord Trigger of Sales Line of Report 10076 - Sales Quote.
        Initialize();
        OnAfterGetRecordSalesLineSalesDocument(SalesHeader."Document Type"::Quote, REPORT::"Sales Quote NA");
    end;

    [Test]
    [HandlerFunctions('SalesOrderTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordSalesLineSalesOrder()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Purpose of the test is to validate OnAfterGetRecord Trigger of Sales Line of  Report 10075 - Sales Order.
        Initialize();
        OnAfterGetRecordSalesLineSalesDocument(SalesHeader."Document Type"::Order, REPORT::"Sales Order");
    end;

    [Test]
    [HandlerFunctions('SalesBlanketOrderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordSalesLineSalesBlanketOrder()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Purpose of the test is to validate OnAfterGetRecord Trigger of Sales Line of Report 10069 - Sales Blanket Order.
        Initialize();
        OnAfterGetRecordSalesLineSalesDocument(SalesHeader."Document Type"::"Blanket Order", REPORT::"Sales Blanket Order");
    end;

    local procedure OnAfterGetRecordSalesLineSalesDocument(DocumentType: Enum "Sales Document Type"; ReportID: Option)
    var
        SalesHeader: Record "Sales Header";
        TaxArea: Record "Tax Area";
        TaxGroupCode: Code[20];
        TaxAmount: Decimal;
    begin
        // Setup: Create Tax Area Without External Tax Engines, Create Sales Document according to the Document Type provided in parameter.
        TaxGroupCode := CreateTaxAreaWithTaxAreaLine(TaxArea, false);
        CreateSalesDocument(SalesHeader, DocumentType, TaxArea.Code, TaxGroupCode, '');
        TaxAmount :=
          UpdateUnitPriceOnSalesLine(
            SalesHeader."Document Type", SalesHeader."No.", TaxGroupCode, LibraryRandom.RandDec(10, 2));

        Commit();  // Commit required since explicit Commit used on OnRun Trigger of COD313: Sales-Printed.

        // Exercise.
        REPORT.Run(ReportID);  // Opens SalesOrderTestRequestPageHandler,SalesQuoteTestRequestPageHandler,SalesBlanketOrderRequestPageHandler.

        // Verify: Verify Tax Amount on Report - Sales Order, Sales Quote, Sales Blanket Order.
        VerifyDataOnReport(TaxAmountCap, TaxAmount);
    end;

    [Test]
    [HandlerFunctions('SalesCreditMemoRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecSalesCrMemoHdrWithTaxEngineSalesCrMemo()
    var
        TaxArea: Record "Tax Area";
        TaxGroupCode: Code[20];
    begin
        // Purpose of the test is to validate OnAfterGetRecord Trigger of Sales Cr. Memo Header of Report 10073 - Sales Credit Memo with external tax engines on Tax Area.

        // Setup: Create Tax Area With External Tax Engines, Create Sales Credit Memo.
        Initialize();
        TaxGroupCode := CreateTaxAreaWithTaxAreaLine(TaxArea, true);
        CreatePostedSalesCreditMemo(TaxArea.Code, TaxGroupCode);

        // Exercise.
        asserterror REPORT.Run(REPORT::"Sales Credit Memo NA");  // Open SalesCreditMemoRequestPageHandler.

        // Verify: Verify Actual Error - "Invalid function call. Function reserved for external tax engines only".
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [HandlerFunctions('SalesCreditMemoRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecSalesCrMemoHdrWithoutTaxEngineSalesCrMemo()
    var
        TaxArea: Record "Tax Area";
        ItemNo: Code[20];
        TaxGroupCode: Code[20];
    begin
        // Purpose of the test is to validate OnAfterGetRecord Trigger of Sales Cr. Memo Header of Report 10073 - Sales Credit Memo without external tax engine on Tax Area.

        // Setup: Create Tax Area Without External Tax Engines, Create Sales Credit Memo.
        Initialize();
        TaxGroupCode := CreateTaxAreaWithTaxAreaLine(TaxArea, false);
        ItemNo := CreatePostedSalesCreditMemo(TaxArea.Code, TaxGroupCode);
        Commit();  // Commit required since explicit Commit used on OnRun Trigger of COD316: Sales Cr. Memo-Printed.

        // Exercise.
        REPORT.Run(REPORT::"Sales Credit Memo NA");  // Open SalesCreditMemoRequestPageHandler.

        // Verify: Verify TempSalesCrMemoLineNo on Report - Sales Credit Memo.
        VerifyDataOnReport('TempSalesCrMemoLineNo', ItemNo);
    end;

    [Test]
    [HandlerFunctions('SalesInvoiceTestRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecSalesInvHdrWithTaxEngineSalesInv()
    var
        TaxArea: Record "Tax Area";
        TaxGroupCode: Code[20];
    begin
        // Purpose of the test is to validate OnAfterGetRecord Trigger of Sales Invoice Header of Report 10074 - Sales Invoice with external tax engines on Tax Area.

        // Setup: Create Tax Area With External Tax Engines, Create Sales Invoice.
        Initialize();
        TaxGroupCode := CreateTaxAreaWithTaxAreaLine(TaxArea, true);
        CreatePostedSalesInvoice(TaxArea.Code, TaxGroupCode);

        // Exercise.
        asserterror REPORT.Run(REPORT::"Sales Invoice NA");  // Open SalesInvoiceTestRequestPageHandler.

        // Verify: Verify Actual Error - "Invalid function call. Function reserved for external tax engines only".
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [HandlerFunctions('SalesInvoiceTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecSalesInvHdrWithoutTaxEngineSalesInv()
    var
        TaxArea: Record "Tax Area";
        ItemNo: Code[20];
        TaxGroupCode: Code[20];
    begin
        // Purpose of the test is to validate OnAfterGetRecord Trigger of Sales Invoice Header of Report 10074 - Sales Invoice without external tax engine on Tax Area.

        // Setup: Create Tax Area Without External Tax Engines. Create Sales Invoice.
        Initialize();
        TaxGroupCode := CreateTaxAreaWithTaxAreaLine(TaxArea, false);
        ItemNo := CreatePostedSalesInvoice(TaxArea.Code, TaxGroupCode);
        Commit();  // Commit required since explicit Commit used on OnRun Trigger of COD315: Sales Inv.-Printed.

        // Exercise.
        REPORT.Run(REPORT::"Sales Invoice NA");  // Open SalesInvoiceTestRequestPageHandler.

        // Verify: Verify TempSalesInvoiceLineNo on Report - Sales Invoice.
        VerifyDataOnReport('TempSalesInvoiceLineNo', ItemNo);
    end;

    [Test]
    [HandlerFunctions('SalesDocumentTestRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordSalesHeaderSalesDocumentTest()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Purpose of the test is to validate Sales Header - OnAfterGetRecord of Report ID - 202 Sales Document - Test.

        // Setup.
        Initialize();
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice, '', '', CreateAndUpdateCurrency());

        // Exercise.
        REPORT.Run(REPORT::"Sales Document - Test");  // Open SalesDocumentTestRequestPageHandler.

        // Verify.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(TotalTextCap, StrSubstNo(TotalCap, SalesHeader."Currency Code"));
    end;

    [Test]
    [HandlerFunctions('SalesDocumentTestRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordCopyLoopSalesDocumentTest()
    var
        SalesHeader: Record "Sales Header";
        TaxArea: Record "Tax Area";
        TaxGroupCode: Code[20];
        LCYCode: Code[10];
    begin
        // Purpose of the test is to validate Copy Loop - OnAfterGetRecord of Report ID - 202 Sales Document - Test.

        // Setup:
        Initialize();
        LCYCode := UpdateVATInUseOnGLSetup();
        TaxGroupCode := CreateTaxAreaWithTaxAreaLine(TaxArea, false);
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice, TaxArea.Code, TaxGroupCode, '');

        // Exercise.
        REPORT.Run(REPORT::"Sales Document - Test");  // Open SalesDocumentTestRequestPageHandler.

        // Verify.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(TotalTextCap, StrSubstNo(TotalCap, LCYCode));
        LibraryReportDataset.AssertElementWithValueExists('ErrorText_Number__Control97', StrSubstNo(GeneralPostingSetupMsg, ' '));  // Using blank value to make the string as expected message string.
    end;

    [Test]
    [HandlerFunctions('SalesDocumentTestRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordRoundLoopSalesDocumentTest()
    var
        SalesHeader: Record "Sales Header";
        TaxArea: Record "Tax Area";
        TaxGroupCode: Code[20];
    begin
        // Purpose of the test is to validate Round Loop - OnAfterGetRecord of Report ID - 202 Sales Document - Test.

        // Setup.
        Initialize();
        UpdateVATInUseOnGLSetup();
        TaxGroupCode := CreateTaxAreaWithTaxAreaLine(TaxArea, true);
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice, TaxArea.Code, TaxGroupCode, '');

        // Exercise.
        asserterror REPORT.Run(REPORT::"Sales Document - Test");  // Open SalesDocumentTestRequestPageHandler.

        // Verify: Verify Actual Error - "Invalid function call. Function reserved for external tax engines only".
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [HandlerFunctions('PurchaseInvoiceRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecPurchInvHdrWithTaxEnginePurchaseInv()
    var
        TaxArea: Record "Tax Area";
        TaxGroupCode: Code[20];
    begin
        // Purpose of the test is to validate OnAfterGetRecord Trigger of Purch. Inv. Header of Report 10121 - Purchase Invoice with external tax engines on Tax Area.

        // Setup: Create Tax Area With External Tax Engines, Create Purchase Invoice.
        Initialize();
        TaxGroupCode := CreateTaxAreaWithTaxAreaLine(TaxArea, true);
        CreatePostedPurchaseInvoice(TaxArea.Code, TaxGroupCode);

        // Exercise.
        asserterror REPORT.Run(REPORT::"Purchase Invoice NA");  // Open PurchaseInvoiceTestRequestPageHandler.

        // Verify: Verify Actual Error - "Invalid function call. Function reserved for external tax engines only".
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [HandlerFunctions('PurchaseInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecPurchInvHdrWithoutTaxEnginePurchaseInv()
    var
        TaxArea: Record "Tax Area";
        No: Code[20];
        TaxGroupCode: Code[20];
    begin
        // Purpose of the test is to validate OnAfterGetRecord Trigger of Purch. Inv. Header of Report 10121 - Purchase Invoice without external tax engine on Tax Area.

        // Setup: Create Tax Area Without External Tax Engines. Create Purchase Invoice.
        Initialize();
        TaxGroupCode := CreateTaxAreaWithTaxAreaLine(TaxArea, false);
        No := CreatePostedPurchaseInvoice(TaxArea.Code, TaxGroupCode);
        Commit();  // Codeunit 319 (Purch. Inv.-Printed) OnRun calls commit.

        // Exercise.
        REPORT.Run(REPORT::"Purchase Invoice NA");  // Open PurchaseInvoiceTestRequestPageHandler.

        // Verify: Verify No_PurchInvHeader on Report - Purchase Invoice.
        VerifyDataOnReport('ItemNumberToPrint', No);
    end;

    [Test]
    [HandlerFunctions('PurchaseOrderRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPurchaseHeaderPurchaseOrder()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Purpose of the test is to validate OnAfterGetRecord Trigger of Purchase Header of Report 10122 - Purchase Order.
        OnAfterGetRecordPurchaseHeaderPurchaseDocument(PurchaseHeader."Document Type"::Order, REPORT::"Purchase Order");
    end;

    [Test]
    [HandlerFunctions('PurchaseOrderPrePrintedRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPurchaseHeaderPurchaseOrderPrePrinted()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Purpose of the test is to validate OnAfterGetRecord Trigger of Purchase Header of Report 10125 - Purchase Order (Pre-Printed).
        OnAfterGetRecordPurchaseHeaderPurchaseDocument(PurchaseHeader."Document Type"::Order, REPORT::"Purchase Order (Pre-Printed)");
    end;

    local procedure OnAfterGetRecordPurchaseHeaderPurchaseDocument(DocumentType: Enum "Purchase Document Type"; ReportID: Option)
    var
        PurchaseHeader: Record "Purchase Header";
        TaxArea: Record "Tax Area";
        TaxGroupCode: Code[20];
    begin
        // Setup: Create Tax Area With External Tax Engines, Create Purchase Document.
        Initialize();
        TaxGroupCode := CreateTaxAreaWithTaxAreaLine(TaxArea, true);
        CreatePurchaseDocument(PurchaseHeader, DocumentType, '', TaxArea.Code, TaxGroupCode);  // Use blank for Currency.

        // Exercise.
        asserterror REPORT.Run(ReportID);  // Opens PurchaseOrderRequestPageHandler,PurchaseOrderPrePrintedRequestPageHandler.

        // Verify: Verify Actual Error - "Invalid function call. Function reserved for external tax engines only".
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [HandlerFunctions('PurchaseOrderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPurchaseLinePurchaseOrder()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Purpose of the test is to validate OnAfterGetRecord Trigger of Purchase Line of  Report 10122 - Purchase Order.
        OnAfterGetRecordPurchaseLinePurchaseDocument(PurchaseHeader."Document Type"::Order, REPORT::"Purchase Order", UnitPriceCap);
    end;

    [Test]
    [HandlerFunctions('PurchaseQuoteRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPurchaseLinePurchaseQuote()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Purpose of the test is to validate OnAfterGetRecord Trigger of Sales Line of Report 10123 - Purchase Quote.
        OnAfterGetRecordPurchaseLinePurchaseDocument(PurchaseHeader."Document Type"::Quote, REPORT::"Purchase Quote NA", QuoteUnitPriceCap);
    end;

    [Test]
    [HandlerFunctions('PurchaseOrderPrePrintedRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPurchaseLinePurchaseOrderPrePrinted()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Purpose of the test is to validate OnAfterGetRecord Trigger of Purchase Line of  Report 10125 - Purchase Order (Pre-Printed).
        OnAfterGetRecordPurchaseLinePurchaseDocument(
          PurchaseHeader."Document Type"::Order, REPORT::"Purchase Order (Pre-Printed)", UnitPriceCap);
    end;

    local procedure OnAfterGetRecordPurchaseLinePurchaseDocument(DocumentType: Enum "Purchase Document Type"; ReportID: Option; AmountCaption: Text[30])
    var
        PurchaseHeader: Record "Purchase Header";
        TaxArea: Record "Tax Area";
        TaxGroupCode: Code[20];
        AmountExcludingDiscount: Decimal;
    begin
        // Setup: Create Tax Area Without External Tax Engines, Create Purchase Document.
        Initialize();
        TaxGroupCode := CreateTaxAreaWithTaxAreaLine(TaxArea, false);
        AmountExcludingDiscount := CreatePurchaseDocument(PurchaseHeader, DocumentType, '', TaxArea.Code, TaxGroupCode);  // Use blank for Currency.
        Commit();  // Codeunit 317 Purch.Header - Printed OnRUN calls commit.

        // Exercise.
        REPORT.Run(ReportID);  // Opens PurchaseOrderRequestPageHandler,PurchaseQuoteRequestPageHandler,PurchaseOrderPrePrintedRequestPageHandler.

        // Verify: Verify Amount on Report - Purchase Order, Purchase Quote, Purchase Order (Pre-Printed).
        VerifyDataOnReport(AmountCaption, AmountExcludingDiscount);
    end;

    [Test]
    [HandlerFunctions('SalesInvoicePrePrintedRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordSalesInvHeaderSalesInvPrePrinted()
    var
        TaxArea: Record "Tax Area";
        TaxGroupCode: Code[20];
    begin
        // Purpose of the test is to validate Sales Invoice Header OnAfterGetRecord of Report 10070 - Sales Invoice with external tax engines on Tax Area.

        // Setup: Create Tax Area With External Tax Engines, Create Sales Invoice.
        TaxGroupCode := CreateTaxAreaWithTaxAreaLine(TaxArea, true);
        CreatePostedSalesInvoice(TaxArea.Code, TaxGroupCode);
        Commit();  // Codeunit 315 Sales Inv.-Printed OnRUN calls commit.

        // Exercise.
        asserterror REPORT.Run(REPORT::"Sales Invoice (Pre-Printed)");  // Open SalesInvoicePrePrintedRequestPageHandler.

        // Verify: Verify Actual Error - "Invalid function call. Function reserved for external tax engines only".
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [HandlerFunctions('PurchaseCreditMemoRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecPurchCrMemoHdrWithTaxEnginePurchaseCreditMemo()
    var
        TaxArea: Record "Tax Area";
        TaxGroupCode: Code[20];
    begin
        // Purpose of the test is to validate Purchase Cr. Memo Header OnAfterGetRecord of Report 10120 - Purchase Credit Memo with external tax engines on Tax Area.

        // Setup: Create Tax Area With External Tax Engines, Create Purchase Credit Memo.
        Initialize();
        TaxGroupCode := CreateTaxAreaWithTaxAreaLine(TaxArea, true);
        CreatePostedPurchaseCreditMemo(TaxArea.Code, TaxGroupCode);

        // Exercise.
        asserterror REPORT.Run(REPORT::"Purchase Credit Memo NA");  // Open PurchaseCreditMemoRequestPageHandler.

        // Verify: Verify Actual Error - "Invalid function call. Function reserved for external tax engines only".
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [HandlerFunctions('PurchaseBlanketOrderRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoCommit)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordCopyLoopWithTaxAreaUSPurchaseBlanketOrder()
    var
        TaxArea: Record "Tax Area";
    begin
        // Purpose of the test is to validate CopyLoop - OnAfterGetRecord of Report ID - 10119 Purchase Blanket Orderwhen Tax Area Country is US.
        OnAfterGetRecordPurchaseBlanketOrder(TaxArea."Country/Region"::US, 'Total Sales Tax:');
    end;

    [Test]
    [HandlerFunctions('PurchaseBlanketOrderRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoCommit)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordCopyLoopWithTaxAreaCAPurchaseBlanketOrder()
    var
        TaxArea: Record "Tax Area";
    begin
        // Purpose of the test is to validate CopyLoop - OnAfterGetRecord of Report ID - 10119 Purchase Blanket Order when Tax Area Country is CA.
        OnAfterGetRecordPurchaseBlanketOrder(TaxArea."Country/Region"::CA, 'Total Tax:');
    end;

    local procedure OnAfterGetRecordPurchaseBlanketOrder(Country: Option; TotalTaxLabelValue: Text[250])
    var
        PurchaseHeader: Record "Purchase Header";
        TaxArea: Record "Tax Area";
        TaxGroupCode: Code[20];
    begin
        // Setup: Create Tax Area and Purchase Blanket Order.
        Initialize();
        TaxGroupCode := CreateTaxAreaWithTaxAreaLine(TaxArea, false);
        TaxArea."Country/Region" := Country;
        TaxArea.Modify();
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Blanket Order", '', TaxArea.Code, TaxGroupCode);  // Currrency Code as blank.
        Commit();  // Codeunit 317 (Purch.Header - Printed) Calls commit.

        // Exercise.
        REPORT.Run(REPORT::"Purchase Blanket Order");  // Opens PurchaseBlanketOrderRequestPageHandler;

        // Verify: Verify Total Tax on report.
        VerifyDataOnReport(TotalTaxLabelCap, TotalTaxLabelValue);
    end;

    [Test]
    [HandlerFunctions('PurchaseBlanketOrderRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoCommit)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordCopyLoopWithoutTaxAreaPurchaseBlanketOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        TaxArea: Record "Tax Area";
    begin
        // Purpose of the test is to validate CopyLoop - OnAfterGetRecord of Report ID - 10119 Purchase Blanket Order when Tax Area Code is Blank.

        // Setup: Create Purchase Blanket Order.
        Initialize();
        CreatePurchaseDocument(
          PurchaseHeader, PurchaseHeader."Document Type"::"Blanket Order", '', TaxArea.Code, LibraryUTUtility.GetNewCode10());  // Currrency Code as blank.
        Commit();  // Codeunit 317 (Purch.Header - Printed) Calls commit.

        // Exercise.
        REPORT.Run(REPORT::"Purchase Blanket Order");  // Opens PurchaseBlanketOrderRequestPageHandler;

        // Verify: Verify Total Tax on report.
        VerifyDataOnReport(TotalTaxLabelCap, 'Tax:');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesInvoiceWithZeroLineAmountExclTaxAndTaxDetail()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TaxAreacode: Code[20];
        TaxGroupCode: Code[20];
        DocumentNo: Code[20];
        TaxBelowMaximum: Decimal;
    begin
        // Verify Sales Invoice can be post successfully with a tax detail when Line Amount Excl. Tax on Sales Line is 0.

        // Setup: Create a Sales Order with a tax detail, and set Unit Price.
        Initialize();
        UpdateMissingVATPostingSetup(); // VAT Bus. Posting Group and VAT Prod. Posting Group must be blank when Sales Liable is TRUE

        TaxBelowMaximum := CreateTaxAreaSetup(TaxAreacode, TaxGroupCode);
        CreateSalesDocumentWithTaxAreaSetup(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, TaxAreacode, TaxGroupCode,
          LibraryRandom.RandInt(10), LibraryRandom.RandInt(10) * 0.0001); // 0.0001 is for making sure (Qty * Unit Price) can be rounded to zero

        // Exercise: Post Sales Order
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify Sales Invoice can be post successfully and Posted Invoice is correct.
        VerifyPostedSalesInvoice(
          DocumentNo, SalesLine.Type::Item, SalesLine.Quantity,
          Round(SalesLine.Quantity * TaxBelowMaximum, LibraryERM.GetAmountRoundingPrecision()));
    end;

    [Test]
    [HandlerFunctions('SalesDocumentTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesDocumentTestReportSalesTaxAmountLine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
    begin
        // [SCENARIO 122253] "Sales Document - Test" report prints several Sales Tax Amount lines with "Tax %" = "Tax Detail"."Tax Below Maximum"
        Initialize();
        UpdateMissingVATPostingSetup();

        // [GIVEN] Tax Area with several "Tax Detail" where "Tax Detail"."Tax Below Maximum" <> 0
        CreateTaxAreaMultipleSetup(TaxAreaCode, TaxGroupCode);

        // [GIVEN] Sales Order with a Tax Area
        CreateSalesDocumentWithTaxAreaSetup(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, TaxAreaCode, TaxGroupCode,
          LibraryRandom.RandDec(100, 2), LibraryRandom.RandDec(100, 2));

        // [WHEN] Run report "Sales Document - Test"
        RunSalesDocumentTestReport(SalesHeader."No.");

        // [THEN] Report has several Tax Amount lines with "Tax %" = "Tax Detail"."Tax Below Maximum"
        VerifyDocumentTestReportSalesTaxAmountLinePct(TaxGroupCode);
    end;

    [Test]
    [HandlerFunctions('PurchaseDocumentTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchDocumentTestReportSalesTaxAmountLine()
    var
        DocumentNo: Code[20];
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
    begin
        // [SCENARIO 122253] "Purchase Document - Test" report prints several Sales Tax Amount lines with "Tax %" = "Tax Detail"."Tax Below Maximum"
        Initialize();
        UpdateMissingVATPostingSetup();

        // [GIVEN] Tax Area with several "Tax Detail" where "Tax Detail"."Tax Below Maximum" <> 0
        CreateTaxAreaMultipleSetup(TaxAreaCode, TaxGroupCode);

        // [GIVEN] Purchase Order with a Tax Area
        DocumentNo := CreatePurchaseDocumentWithTaxAreaSetup(TaxAreaCode, TaxGroupCode);

        // [WHEN] Run report "Purchase Document - Test"
        RunPurchaseDocumentTestReport(DocumentNo);

        // [THEN] Report has several Tax Amount lines with "Tax %" = "Tax Detail"."Tax Below Maximum"
        VerifyDocumentTestReportSalesTaxAmountLinePct(TaxGroupCode);
    end;

    [Test]
    [HandlerFunctions('RHStandardPurchaseOrder')]
    [Scope('OnPrem')]
    procedure StandardPurchaseOrderAdditionalFields()
    var
        PurchaseHeader: Record "Purchase Header";
        TaxArea: Record "Tax Area";
        TaxGroupCode: Code[20];
    begin
        // [SCENARIO] Run report Standard Purchase - Order to verify additional fields are added in NA environment.
        Initialize();
        TaxGroupCode := CreateTaxAreaWithTaxAreaLine(TaxArea, false);

        // [GIVEN] A purchase header and lines
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order, '', TaxArea.Code, TaxGroupCode);

        // [WHEN] Run report "Standard Purchase - Order"
        PurchaseHeader.SetRange("No.", PurchaseHeader."No.");
        Commit();
        REPORT.Run(REPORT::"Standard Purchase - Order", true, false, PurchaseHeader);

        // [THEN] Report has fields added to W1 that are specific to NA.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementTagExists('TotalTaxLabel');
        LibraryReportDataset.AssertElementTagExists('TaxAmount');
        LibraryReportDataset.AssertElementTagExists('BreakdownTitle');
    end;

    [Test]
    [HandlerFunctions('RHStandardPurchaseOrder')]
    [Scope('OnPrem')]
    procedure StandardPurchaseOrderTotals()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TaxDetail: Record "Tax Detail";
        TaxJurisdiction: Record "Tax Jurisdiction";
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
    begin
        // [SCENARIO] Run report Standard Purchase - Order to verify total fields are correct in NA environment.
        Initialize();
        UpdateMissingVATPostingSetup();

        TaxJurisdiction.Init();
        TaxJurisdiction.Code := 'Code1';
        TaxJurisdiction.Insert();

        TaxGroupCode := CreateTaxGroup();
        LibraryERM.CreateTaxDetail(
          TaxDetail, TaxJurisdiction.Code, TaxGroupCode, TaxDetail."Tax Type"::"Sales and Use Tax", WorkDate());
        TaxDetail.Validate("Tax Below Maximum", 7.0);
        TaxDetail.Modify(true);

        TaxAreaCode := CreateTaxArea();
        CreateTaxAreaLine(TaxAreaCode, TaxJurisdiction.Code);

        // [GIVEN] A purchase header and line
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateVendorWithTaxAreaSetup(TaxAreaCode));
        PurchaseHeader.Validate("Tax Area Code", TaxAreaCode);
        PurchaseHeader.Validate("Tax Liable", true);
        PurchaseHeader.Validate("Currency Code", '');
        PurchaseHeader.Validate("Currency Factor", 2);
        PurchaseHeader.Modify(true);

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item,
          CreateItemWithTaxGroupCode(TaxGroupCode), 10.0);
        PurchaseLine.Validate("Direct Unit Cost", 26.0);
        PurchaseLine.Validate("Tax Area Code", TaxAreaCode);
        PurchaseLine.Validate("Tax Group Code", TaxGroupCode);
        PurchaseLine.Validate("Tax Liable", true);
        PurchaseLine.Validate("Line Amount", 260);
        PurchaseLine.Validate("Inv. Discount Amount", 25);
        PurchaseLine.Modify(true);

        // [WHEN] Run report "Standard Purchase - Order"
        LibraryVariableStorage.Enqueue(false);
        PurchaseHeader.SetRange("No.", PurchaseHeader."No.");
        Commit();
        REPORT.Run(REPORT::"Standard Purchase - Order", true, false, PurchaseHeader);

        // [THEN] Report has fields added to W1 that are specific to NA.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementTagWithValueExists('TotalSubTotal', '260');
        LibraryReportDataset.AssertElementTagWithValueExists('TaxAmount', '16.45');
        LibraryReportDataset.AssertElementTagWithValueExists('TotalInvoiceDiscountAmount', '-25');
        LibraryReportDataset.AssertElementTagWithValueExists('TotalAmount', '251.45');
    end;

    [Test]
    [HandlerFunctions('SalesInvoiceTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PrintPostedSalesInvoiceIfSalesLineWithoutTaxGroup()
    var
        TaxArea: Record "Tax Area";
        SalesLineNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 281006] Print posted Sales Invoice if Sales Line does not contain Tax Group Code
        Initialize();

        // [GIVEN] Posted Sales Invoice
        // [GIVEN] Sales Line with "Tax Group Code" = ''
        CreateTaxAreaWithTaxAreaLine(TaxArea, false);
        SalesLineNo := CreatePostedSalesInvoice(TaxArea.Code, '');
        Commit();

        // [WHEN] Print posted Sales Invoice
        REPORT.Run(REPORT::"Sales Invoice NA");

        // [THEN] Report has been printed
        VerifyDataOnReport('TempSalesInvoiceLineNo', SalesLineNo);
    end;

    [Test]
    [HandlerFunctions('SalesCreditMemoRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PrintPostedSalesCrMemoIfSalesLineWithoutTaxGroup()
    var
        TaxArea: Record "Tax Area";
        SalesLineNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 281006] Print posted Sales Credit Memo if Sales Line does not contain Tax Group Code
        Initialize();

        // [GIVEN] Posted Sales Credit Memo
        // [GIVEN] Sales Line with "Tax Group Code" = ''
        CreateTaxAreaWithTaxAreaLine(TaxArea, false);
        SalesLineNo := CreatePostedSalesCreditMemo(TaxArea.Code, '');
        Commit();

        // [WHEN] Print posted Sales Invoice
        REPORT.Run(REPORT::"Sales Credit Memo NA");

        // [THEN] Report has been printed
        VerifyDataOnReport('TempSalesCrMemoLineNo', SalesLineNo);
    end;

    [Test]
    [HandlerFunctions('PurchaseInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PrintPostedPurchInvoiceIfPurchLineWithoutTaxGroup()
    var
        TaxArea: Record "Tax Area";
        PurchaseInvLineNo: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 281006] Print posted Purchase Invoice if Purchase Line does not contain Tax Group Code
        Initialize();

        // [GIVEN] Posted Purchase Invoice
        // [GIVEN] Purchase Line with "Tax Group Code" = ''
        CreateTaxAreaWithTaxAreaLine(TaxArea, false);
        PurchaseInvLineNo := CreatePostedPurchaseInvoice(TaxArea.Code, '');
        Commit();

        // [WHEN] Print posted Purchase Invoice
        REPORT.Run(REPORT::"Purchase Invoice NA");

        // [THEN] Report has been printed
        VerifyDataOnReport('ItemNumberToPrint', PurchaseInvLineNo);
    end;

    [Test]
    [HandlerFunctions('PurchaseCreditMemoRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PrintPostedPurchCrMemoIfPurchLineWithoutTaxGroup()
    var
        TaxArea: Record "Tax Area";
        PurchaseCrMemoLineNo: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 281006] Print posted Purchase Credit Memo if Purchase Line does not contain Tax Group Code
        Initialize();

        // [GIVEN] Posted Purchase Credit Memo
        // [GIVEN] Purchase Line with "Tax Group Code" = ''
        CreateTaxAreaWithTaxAreaLine(TaxArea, false);
        PurchaseCrMemoLineNo := CreatePostedPurchaseCreditMemo(TaxArea.Code, '');
        Commit();

        // [WHEN] Print posted Purchase Invoice
        REPORT.Run(REPORT::"Purchase Credit Memo NA");

        // [THEN] Report has been printed
        VerifyDataOnReport('ItemNumberToPrint', PurchaseCrMemoLineNo);
    end;

    [Test]
    [HandlerFunctions('ServiceInvoiceTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PrintPostedServInvoiceIfServLineWithoutTaxGroup()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        TaxArea: Record "Tax Area";
    begin
        // [FEATURE] [Service]
        // [SCENARIO 281006] Print posted Service Invoice if Service Line does not contain Tax Group Code
        Initialize();

        // [GIVEN] Posted Service Invoice
        // [GIVEN] Service Line with "Tax Group Code" = ''
        CreateTaxAreaWithTaxAreaLine(TaxArea, false);
        CreatePostedServiceInvoice(ServiceInvoiceHeader, TaxArea.Code);
        LibraryVariableStorage.Enqueue(ServiceInvoiceHeader."No.");
        Commit();

        // [WHEN] Print posted Service Invoice
        REPORT.Run(REPORT::"Service - Invoice");

        // [THEN] Report has been printed
        VerifyDataOnReport('No_ServiceInvHeader', ServiceInvoiceHeader."No.");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ServiceCrMemoTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PrintPostedServCrMemoIfServLineWithoutTaxGroup()
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        TaxArea: Record "Tax Area";
    begin
        // [FEATURE] [Service]
        // [SCENARIO 281006] Print posted Service Credit Memo if Service Line does not contain Tax Group Code
        Initialize();

        // [GIVEN] Posted Service Credit Memo
        // [GIVEN] Service Line with "Tax Group Code" = ''
        CreateTaxAreaWithTaxAreaLine(TaxArea, false);
        CreatePostedServiceCreditMemo(ServiceCrMemoHeader, TaxArea.Code);
        LibraryVariableStorage.Enqueue(ServiceCrMemoHeader."No.");
        Commit();

        // [WHEN] Print posted Service Invoice
        REPORT.Run(REPORT::"Service - Credit Memo");

        // [THEN] Report has been printed
        VerifyDataOnReport('No_ServCrMemoHdr', ServiceCrMemoHeader."No.");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('RHStandardPurchaseOrder')]
    [Scope('OnPrem')]
    procedure StandardPurchaseTotalVAT()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TaxDetail: Record "Tax Detail";
        TaxJurisdiction: Record "Tax Jurisdiction";
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
    begin
        // [SCENARIO 437909] Run report Standard Purchase - Order to verify Total VAT is correct.
        Initialize();
        UpdateMissingVATPostingSetup();

        TaxJurisdiction.Init();
        TaxJurisdiction.Code := 'Code2';
        TaxJurisdiction.Insert();

        TaxGroupCode := CreateTaxGroup();
        LibraryERM.CreateTaxDetail(
          TaxDetail, TaxJurisdiction.Code, TaxGroupCode, TaxDetail."Tax Type"::"Sales and Use Tax", WorkDate());
        TaxDetail.Validate("Tax Below Maximum", 7.0);
        TaxDetail.Modify(true);

        TaxAreaCode := CreateTaxArea();
        CreateTaxAreaLine(TaxAreaCode, TaxJurisdiction.Code);

        // [GIVEN] A purchase header and line
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateVendorWithTaxAreaSetup(TaxAreaCode));
        PurchaseHeader.Validate("Tax Area Code", TaxAreaCode);
        PurchaseHeader.Validate("Tax Liable", true);
        PurchaseHeader.Validate("Currency Code", '');
        PurchaseHeader.Validate("Currency Factor", 2);
        PurchaseHeader.Modify(true);

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item,
          CreateItemWithTaxGroupCode(TaxGroupCode), 10.0);
        PurchaseLine.Validate("Direct Unit Cost", 26.0);
        PurchaseLine.Validate("Tax Area Code", TaxAreaCode);
        PurchaseLine.Validate("Tax Group Code", TaxGroupCode);
        PurchaseLine.Validate("Tax Liable", true);
        PurchaseLine.Validate("Line Amount", 260);
        PurchaseLine.Validate("Inv. Discount Amount", 25);
        PurchaseLine.Modify(true);

        // [WHEN] Run report "Standard Purchase - Order"
        LibraryVariableStorage.Enqueue(false);
        PurchaseHeader.SetRange("No.", PurchaseHeader."No.");
        Commit();
        REPORT.Run(REPORT::"Standard Purchase - Order", true, false, PurchaseHeader);

        // [THEN] Verify Report has the TaxAmount value.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementTagWithValueExists('TaxAmount', '16.45');
    end;

    [Test]
    [HandlerFunctions('RHStandardPurchaseOrder')]
    [Scope('OnPrem')]
    procedure StandardPurchaseWithVAT()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VATCalculationType: Enum "Tax Calculation Type";
        VendorNo: Code[20];
    begin
        // [SCENARIO 468347] Run report Standard Purchase - Order to verify VAT Amount is printing in the report.
        Initialize();

        // [GIVEN] Find VAT Posting Setup
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATCalculationType::"Normal VAT");

        // [GIVEN] Create Vendor With VAT Bus Posting Group
        VendorNo := LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group");

        // [GIVEN] Create a Purchase Header and line
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo);

        // [GIVEN] Create a Purchase Line
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine,
            PurchaseHeader,
            PurchaseLine.Type::Item,
            LibraryInventory.CreateItemWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"),
            LibraryRandom.RandIntInRange(1, 10));

        // [GIVEN] Update Direct Unit Cost in Purchase Line
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(1, 30));
        PurchaseLine.Modify(true);

        // [GIVEN] Save the transaction.
        Commit();

        // [WHEN] Run report "Standard Purchase - Order"
        Report.Run(Report::"Standard Purchase - Order", true, false, PurchaseHeader);

        // [THEN] Verify Report has the TaxAmount value.
        PurchaseHeader.CalcFields("Amount Including VAT", Amount);
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementTagWithValueExists(
            TaxAmountCap,
            Format(PurchaseHeader."Amount Including VAT" - PurchaseHeader.Amount));
    end;

    [Test]
    [HandlerFunctions('ServiceInvoiceSalesTaxRequestPageHandler,ConfirmHandlerTrue,ContractTemplateListHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure VerifyServiceInvoiceReportShowingAllAddedDescriptionLinesOnServiceInvoice()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceInvoiceLine: Record "Service Invoice Line";
        SignServContractDoc: Codeunit SignServContractDoc;
    begin
        // [SCENARIO 472642] Service Invoice Report 10474 does not show all the added Description lines from a Service Invoice
        Initialize();

        // [GIVEN] Create Service Contract and Contract Line
        LibraryService.CreateServiceContractHeader(
            ServiceContractHeader,
            ServiceContractHeader."Contract Type"::Contract,
            LibrarySales.CreateCustomerNo());
        CreateServiceContractLine(ServiceContractLine, ServiceContractHeader);

        // [GIVEN] Sign the bnewly create Service Contract
        AmountsInServiceContractHeader(ServiceContractHeader);
        SignServContractDoc.SignContract(ServiceContractHeader);

        // [WHEN] Post the Service Invoice for Service Contract by adding description lines before posting
        PostServiceInvoice(ServiceContractHeader."Contract No.");

        // [THEN] Find Posted Service Invoice
        FindFirstServiceInvoiceOnServiceContract(ServiceInvoiceHeader, ServiceContractHeader."Contract No.");
        EnqueueValuesForServiceInvoiceAndCreditMemo(ServiceInvoiceHeader."No.", true, 0);
        Commit();

        // [WHEN] Run report "Service Invoice-Sales Tax" for Posted Service Invoice
        Report.Run(Report::"Service Invoice-Sales Tax");

        // [VERIFY] Verify: Report prints only all the Service Invoice Lines lines on the "Service Invoice-Sales Tax" report
        ServiceInvoiceLine.SetRange("Document No.", ServiceInvoiceHeader."No.");
        ServiceInvoiceLine.FindSet();
        LibraryReportDataset.LoadDataSetFile();
        Assert.AreEqual(ServiceInvoiceLine.Count, LibraryReportDataset.RowCount(), IncorrectLineCountErr);
    end;

    [Test]
    [HandlerFunctions('PurchaseDocumentTestReqPageHandler')]
    [Scope('OnPrem')]
    procedure TotalTaxAmtInPurchDocTestreportIsPrintedInFCYWhenCurrecyCodeIsNotBlankInPO()
    var
        Vendor: Record Vendor;
        TaxArea: Record "Tax Area";
        TaxGroup: Record "Tax Group";
        TaxDetail: Record "Tax Detail";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: array[2] of Record "Purchase Line";
        CurrencyCode: Code[10];
        VATAmount: Decimal;
        VATAmount2: Decimal;
    begin
        // [SCENARIO 542503] Total Tax Amount in Purchase Document - Test report shows Sum of Tax Amount 
        // In FCY when Currency Code is not blank in Purchase Order.
        Initialize();

        // [GIVEN] Create a Currency and Exchange Rate.
        CurrencyCode := CreateCurrencyWithExchangeRate();

        // [GIVEN] Create a Tax Area.
        LibraryERM.CreateTaxArea(TaxArea);

        // [GIVEN] Create a Tax Group.
        LibraryERM.CreateTaxGroup(TaxGroup);

        // [GIVEN] Create a Tax Area Setup with Values.
        CreateTaxAreaSetupWithValues(TaxDetail, TaxArea.Code, TaxGroup.Code, 3);

        // [GIVEN] Create a Vendor with Tax Area Code.
        Vendor.Get(CreateVendorWithTaxArea(TaxArea.Code));

        // [GIVEN] Create a Purchase Header and Validate Tax Area Code and Currency Code.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        PurchaseHeader.Validate("Tax Area Code", TaxArea.Code);
        PurchaseHeader.Validate("Currency Code", CurrencyCode);
        PurchaseHeader.Modify(true);

        // [GIVEN] Create Purchase Line [1] with Direct Unit Cost.
        CreatePurchaseLineWithDirectUnitCost(PurchaseLine[1], PurchaseHeader, TaxGroup);

        // [GIVEN] Create Purchase Line [2] with Direct Unit Cost.
        CreatePurchaseLineWithDirectUnitCost(PurchaseLine[2], PurchaseHeader, TaxGroup);

        // [GIVEN] Run Purchase Document - Test report.
        RunDocumentTestReport(PurchaseHeader."Document Type", PurchaseHeader."No.", REPORT::"Purchase Document - Test");
        LibraryReportDataset.LoadDataSetFile();

        // [WHEN] Generate and save VAT Amount of both Purchase Lines in two different Variables.
        VATAmount := PurchaseLine[1]."Amount Including VAT" - PurchaseLine[1].Amount;
        VATAmount2 := PurchaseLine[2]."Amount Including VAT" - PurchaseLine[2].Amount;

        // [THEN] Sum of Tax Amount in Purchase Document - Test report is equal to sum of VATAmount and VATAmount2.
        Assert.AreEqual(VATAmount + VATAmount2, SumTaxAmountInTestReport(), TaxAmountNotEqualTotalErr);
    end;

    [Test]
    [HandlerFunctions('SalesCrMemoXmlReportHandler')]
    procedure CheckSalesCreditMemoNACommentLine()
    var
        ReportSelections: Record "Report Selections";
        SalesCrmemoHdr: Record "Sales Cr.Memo Header";
        SalesHeader: Record "Sales Header";
        CrditMemoPage: TestPage "Posted Sales Credit Memo";
        ExpectedComment: Text[81];
    begin
        // [SCENARIO 564884] The Sales Credit Memo only prints the first 4 comments from the Comments table.
        Initialize();

        // [GIVEN] Sales Cr. Memo Created.
        LibrarySales.CreateSalesCreditMemo(SalesHeader);

        // [GIVEN] Multiple Comment lines created for Sales Cr. Memo.
        CreateCommentLines(SalesHeader);

        // [GIVEN] Sales Cr Memo Posted And Get Posted Sales Cr Memo.
        SalesCrmemoHdr.Get(LibrarySales.PostSalesDocument(SalesHeader, false, false));

        // [GIVEN] Get Last Comment Line of Posted Sales Cr Memo.
        ExpectedComment := GetExpectedComment(SalesCrmemoHdr);

        // [GIVEN] Report 10073 is Set as Report for Sales Cr Memo-CA
        ReportSelections.Get(ReportSelections.Usage::"S.Cr.Memo", 1);
        ReportSelections.Validate("Report ID", Report::"Sales Credit Memo NA");
        ReportSelections.Modify(true);

        // [WHEN] Report 10073 Print From Credit Memo Page
        CrditMemoPage.OpenEdit();
        CrditMemoPage.GoToRecord(SalesCrmemoHdr);
        Commit(); //Commit Required for Print
        CrditMemoPage.Print.Invoke();

        // [THEN] Verify Report DataSet with Expected Comment
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('TempSalesCrMemoLineDesc', ExpectedComment);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateAndUpdateCurrency(): Code[10]
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        CurrencyExchangeRate.SetRange("Currency Code", CreateCurrencyAndExchangeRate());
        CurrencyExchangeRate.FindFirst();
        CurrencyExchangeRate."Relational Exch. Rate Amount" := CurrencyExchangeRate."Exchange Rate Amount";
        CurrencyExchangeRate.Modify();
        exit(CurrencyExchangeRate."Currency Code");
    end;

    local procedure CreateCurrencyAndExchangeRate(): Code[10]
    var
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        Currency.Code := LibraryUTUtility.GetNewCode10();
        Currency.Insert();
        CurrencyExchangeRate."Currency Code" := Currency.Code;
        CurrencyExchangeRate."Exchange Rate Amount" := LibraryRandom.RandDec(100, 2);
        CurrencyExchangeRate.Insert();
        exit(Currency.Code);
    end;

    local procedure CreateCustomerWithTaxAreaSetup(TaxAreaCode: Code[20]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Tax Area Code", TaxAreaCode);
        Customer.Validate("Tax Liable", true);
        Customer.Validate("VAT Bus. Posting Group", '');
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateVendorWithTaxAreaSetup(TaxAreaCode: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Tax Area Code", TaxAreaCode);
        Vendor.Validate("Tax Liable", true);
        Vendor.Validate("VAT Bus. Posting Group", '');
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateItemWithTaxGroupCode(TaxGroupCode: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Tax Group Code", TaxGroupCode);
        Item.Validate("VAT Prod. Posting Group", '');
        Item.Validate("Last Direct Cost", LibraryRandom.RandDec(1000, 2));
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreatePostedSalesCreditMemo(TaxAreaCode: Code[20]; TaxGroupCode: Code[20]): Code[20]
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
    begin
        SalesCrMemoHeader."No." := LibraryUTUtility.GetNewCode();
        SalesCrMemoHeader."Sell-to Customer No." := LibraryUTUtility.GetNewCode();
        SalesCrMemoHeader."Tax Area Code" := TaxAreaCode;
        SalesCrMemoHeader.Insert();
        SalesCrMemoLine."Document No." := SalesCrMemoHeader."No.";
        SalesCrMemoLine.Type := SalesCrMemoLine.Type::Item;
        SalesCrMemoLine."No." := LibraryUTUtility.GetNewCode();
        SalesCrMemoLine."Tax Area Code" := TaxAreaCode;
        SalesCrMemoLine."Tax Group Code" := TaxGroupCode;
        SalesCrMemoLine."Tax Liable" := true;
        SalesCrMemoLine.Insert();
        LibraryVariableStorage.Enqueue(SalesCrMemoHeader."No.");  // Enqueue required for SalesCreditMemoRequestPageHandler.
        exit(SalesCrMemoLine."No.");
    end;

    local procedure CreatePostedServiceCreditMemo(var ServiceCrMemoHeader: Record "Service Cr.Memo Header"; TaxAreaCode: Code[20])
    var
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
    begin
        ServiceCrMemoHeader."No." := LibraryUTUtility.GetNewCode();
        ServiceCrMemoHeader."Responsibility Center" := CreateResponsibilityCenter();
        ServiceCrMemoHeader."Tax Area Code" := TaxAreaCode;
        ServiceCrMemoHeader.Insert();
        ServiceCrMemoLine."Document No." := ServiceCrMemoHeader."No.";
        ServiceCrMemoLine."Tax Area Code" := TaxAreaCode;
        ServiceCrMemoLine.Insert();
    end;

    local procedure CreatePostedSalesInvoice(TaxAreaCode: Code[20]; TaxGroupCode: Code[20]): Code[20]
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SalesInvoiceHeader."No." := LibraryUTUtility.GetNewCode();
        SalesInvoiceHeader."Sell-to Customer No." := LibraryUTUtility.GetNewCode();
        SalesInvoiceHeader."Tax Area Code" := TaxAreaCode;
        SalesInvoiceHeader.Insert();
        SalesInvoiceLine."Document No." := SalesInvoiceHeader."No.";
        SalesInvoiceLine.Type := SalesInvoiceLine.Type::Item;
        SalesInvoiceLine."No." := LibraryUTUtility.GetNewCode();
        SalesInvoiceLine."Tax Area Code" := TaxAreaCode;
        SalesInvoiceLine."Tax Group Code" := TaxGroupCode;
        SalesInvoiceLine."Tax Liable" := true;
        SalesInvoiceLine.Insert();
        LibraryVariableStorage.Enqueue(SalesInvoiceHeader."No.");  // Enqueue required for SalesInvoiceTestRequestPageHandler.
        exit(SalesInvoiceLine."No.");
    end;

    local procedure CreatePostedServiceInvoice(var ServiceInvoiceHeader: Record "Service Invoice Header"; TaxAreaCode: Code[20])
    var
        ServiceInvoiceLine: Record "Service Invoice Line";
    begin
        ServiceInvoiceHeader."No." := LibraryUTUtility.GetNewCode();
        ServiceInvoiceHeader."Responsibility Center" := CreateResponsibilityCenter();
        ServiceInvoiceHeader."Tax Area Code" := TaxAreaCode;
        ServiceInvoiceHeader.Insert();
        ServiceInvoiceLine."Document No." := ServiceInvoiceHeader."No.";
        ServiceInvoiceLine."Tax Area Code" := TaxAreaCode;
        ServiceInvoiceLine.Insert();
    end;

    local procedure CreatePostedPurchaseCreditMemo(TaxAreaCode: Code[20]; TaxGroupCode: Code[20]): Code[20]
    var
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
    begin
        PurchCrMemoHeader."No." := LibraryUTUtility.GetNewCode();
        PurchCrMemoHeader."Buy-from Vendor No." := LibraryUTUtility.GetNewCode();
        PurchCrMemoHeader."Tax Area Code" := TaxAreaCode;
        PurchCrMemoHeader.Insert();
        PurchCrMemoLine."Document No." := PurchCrMemoHeader."No.";
        PurchCrMemoLine.Type := PurchCrMemoLine.Type::Item;
        PurchCrMemoLine."No." := LibraryUTUtility.GetNewCode();
        PurchCrMemoLine."Tax Area Code" := TaxAreaCode;
        PurchCrMemoLine."Tax Group Code" := TaxGroupCode;
        PurchCrMemoLine."Tax Liable" := true;
        PurchCrMemoLine.Insert();
        LibraryVariableStorage.Enqueue(PurchCrMemoHeader."No.");  // Enqueue required for PurchCreditMemoRequestPageHandler.
        exit(PurchCrMemoLine."No.");
    end;

    local procedure CreatePostedPurchaseInvoice(TaxAreaCode: Code[20]; TaxGroupCode: Code[20]): Code[20]
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        PurchInvHeader."No." := LibraryUTUtility.GetNewCode();
        PurchInvHeader."Buy-from Vendor No." := LibraryUTUtility.GetNewCode();
        PurchInvHeader."Tax Area Code" := TaxAreaCode;
        PurchInvHeader.Insert();
        PurchInvLine."Document No." := PurchInvHeader."No.";
        PurchInvLine.Type := PurchInvLine.Type::Item;
        PurchInvLine."No." := LibraryUTUtility.GetNewCode();
        PurchInvLine."Tax Area Code" := TaxAreaCode;
        PurchInvLine."Tax Group Code" := TaxGroupCode;
        PurchInvLine."Tax Liable" := true;
        PurchInvLine.Insert();
        LibraryVariableStorage.Enqueue(PurchInvHeader."No.");  // Enqueue required for PurchaseInvoiceTestRequestPageHandler.
        exit(PurchInvLine."No.");
    end;

    local procedure CreatePurchaseLine(DocumentNo: Code[20]; TaxAreaCode: Code[20]; TaxGroupCode: Code[20]; DocumentType: Enum "Purchase Document Type"): Decimal
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine."Document Type" := DocumentType;
        PurchaseLine."Document No." := DocumentNo;
        PurchaseLine.Type := PurchaseLine.Type::Item;
        PurchaseLine."No." := LibraryUTUtility.GetNewCode();
        PurchaseLine.Quantity := LibraryRandom.RandDec(10, 2);
        PurchaseLine."Qty. to Receive" := PurchaseLine.Quantity;
        PurchaseLine."Qty. to Invoice" := PurchaseLine.Quantity;
        PurchaseLine."Tax Area Code" := TaxAreaCode;
        PurchaseLine."Tax Group Code" := TaxGroupCode;
        PurchaseLine."Tax Liable" := true;
        PurchaseLine."Line Amount" := LibraryRandom.RandDec(100, 2);
        PurchaseLine.Insert();
        exit(PurchaseLine."Line Amount");
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; CurrencyCode: Code[10]; TaxAreaCode: Code[20]; TaxGroupCode: Code[20]): Decimal
    begin
        PurchaseHeader."Document Type" := DocumentType;
        PurchaseHeader."No." := LibraryUTUtility.GetNewCode();
        PurchaseHeader."Buy-from Vendor No." := LibraryUTUtility.GetNewCode();
        PurchaseHeader."Tax Area Code" := TaxAreaCode;
        PurchaseHeader."Currency Code" := CurrencyCode;
        PurchaseHeader."Currency Factor" := LibraryRandom.RandDec(10, 2);
        PurchaseHeader.Insert();

        // Enqueue for PurchaseDocumentTestReqPageHandler,PurchaseOrderRequestPageHandler,PurchaseQuoteRequestPageHandler,PurchaseOrderPrePrintedRequestPageHandler;
        LibraryVariableStorage.Enqueue(PurchaseHeader."No.");
        exit(CreatePurchaseLine(PurchaseHeader."No.", TaxAreaCode, TaxGroupCode, DocumentType));
    end;

    local procedure CreatePurchaseDocumentWithTaxAreaSetup(TaxAreaCode: Code[20]; TaxGroupCode: Code[20]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateVendorWithTaxAreaSetup(TaxAreaCode));
        PurchaseHeader.Validate("Tax Area Code", TaxAreaCode);
        PurchaseHeader.Modify(true);

        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item,
          CreateItemWithTaxGroupCode(TaxGroupCode), LibraryRandom.RandDec(100, 2));

        exit(PurchaseHeader."No.");
    end;

    local procedure CreateResponsibilityCenter(): Code[10]
    var
        ResponsibilityCenter: Record "Responsibility Center";
    begin
        ResponsibilityCenter.Code := LibraryUTUtility.GetNewCode10();
        ResponsibilityCenter.Name := ResponsibilityCenter.Code;
        ResponsibilityCenter.Insert();
        exit(ResponsibilityCenter.Code);
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; TaxAreaCode: Code[20]; TaxGroupCode: Code[20]; CurrencyCode: Code[10]): Decimal
    begin
        SalesHeader."Document Type" := DocumentType;
        SalesHeader."No." := LibraryUTUtility.GetNewCode();
        SalesHeader."Tax Area Code" := TaxAreaCode;
        SalesHeader."Currency Code" := CurrencyCode;
        SalesHeader."Currency Factor" := LibraryRandom.RandDec(10, 2);
        SalesHeader.Insert();
        LibraryVariableStorage.Enqueue(SalesHeader."No.");  // Enqueue required for SalesOrderTestRequestPageHandler,SalesBlanketOrderRequestPageHandler,SalesDocumentTestRequestPageHandler and SalesQuoteTestRequestPageHandler.
        exit(CreateSalesLine(SalesHeader, TaxGroupCode));
    end;

    local procedure CreateSalesDocumentWithTaxAreaSetup(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; TaxAreaCode: Code[20]; TaxGroupCode: Code[20]; Quantity: Decimal; UnitPrice: Decimal)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CreateCustomerWithTaxAreaSetup(TaxAreaCode));
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, CreateItemWithTaxGroupCode(TaxGroupCode), Quantity);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesLine(SalesHeader: Record "Sales Header"; TaxGroupCode: Code[20]): Decimal
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        SalesLine.Type := SalesLine.Type::Item;
        SalesLine.Quantity := LibraryRandom.RandDec(10, 2);
        SalesLine."Qty. to Ship" := SalesLine.Quantity;
        SalesLine."Qty. to Invoice" := SalesLine.Quantity;
        SalesLine."Tax Area Code" := SalesHeader."Tax Area Code";
        SalesLine."Tax Group Code" := TaxGroupCode;
        SalesLine."Tax Liable" := true;
        SalesLine."Amount Including VAT" := LibraryRandom.RandDec(10, 2);
        SalesLine.Insert();
        exit(SalesLine."Amount Including VAT");
    end;

    local procedure CreateServiceDocument(var ServiceLine: Record "Service Line"; CurrencyCode: Code[10]; DocumentType: Enum "Service Document Type"; CurrencyFactor: Decimal)
    var
        ServiceHeader: Record "Service Header";
    begin
        ServiceHeader."Document Type" := DocumentType;
        ServiceHeader."No." := LibraryUTUtility.GetNewCode();
        ServiceHeader."Currency Factor" := CurrencyFactor;
        ServiceHeader.Insert();
        ServiceLine."Document Type" := DocumentType;
        ServiceLine."Document No." := ServiceHeader."No.";
        ServiceLine."Line No." := LibraryRandom.RandInt(100);
        ServiceLine.Quantity := LibraryRandom.RandDec(100, 2);
        ServiceLine."Unit Price" := LibraryRandom.RandDec(100, 2);
        ServiceLine."Currency Code" := CurrencyCode;
        ServiceLine.Insert();
        LibraryVariableStorage.Enqueue(ServiceHeader."No.");  // Enqueue required for ServiceOrderRequestPageHandler.
    end;

    local procedure CreateTaxAreaSetup(var TaxAreaCode: Code[20]; var TaxGroupCode: Code[20]): Decimal
    var
        TaxDetail: Record "Tax Detail";
        TaxJurisdictionCode: Code[10];
    begin
        TaxAreaCode := CreateTaxArea();
        TaxJurisdictionCode := CreateTaxJurisdiction();
        CreateTaxAreaLine(TaxAreaCode, TaxJurisdictionCode);
        TaxGroupCode := CreateTaxGroup();
        exit(CreateTaxDetail(TaxJurisdictionCode, TaxGroupCode, TaxDetail."Tax Type"::"Excise Tax"));
    end;

    local procedure CreateTaxAreaMultipleSetup(var TaxAreaCode: Code[20]; var TaxGroupCode: Code[20])
    var
        TaxDetail: Record "Tax Detail";
        TaxJurisdictionCode: Code[10];
        i: Integer;
    begin
        TaxAreaCode := CreateTaxArea();
        TaxGroupCode := CreateTaxGroup();

        for i := 1 to LibraryRandom.RandIntInRange(3, 10) do begin
            TaxJurisdictionCode := CreateTaxJurisdiction();
            CreateTaxAreaLine(TaxAreaCode, TaxJurisdictionCode);
            CreateTaxDetail(TaxJurisdictionCode, TaxGroupCode, TaxDetail."Tax Type"::"Sales and Use Tax");
        end;
    end;

    local procedure CreateTaxAreaWithCountry(Country: Option): Code[20]
    var
        TaxArea: Record "Tax Area";
    begin
        TaxArea.Code := LibraryUTUtility.GetNewCode();
        TaxArea."Country/Region" := Country;
        TaxArea.Insert();
        exit(TaxArea.Code);
    end;

    local procedure CreateTaxAreaWithTaxAreaLine(var TaxArea: Record "Tax Area"; UseExternalTaxEngine: Boolean): Code[10]
    var
        TaxAreaLine: Record "Tax Area Line";
        TaxDetail: Record "Tax Detail";
    begin
        CreateTaxDetailWithJurisdiction(TaxDetail);
        TaxArea.Code := LibraryUTUtility.GetNewCode();
        TaxArea."Use External Tax Engine" := UseExternalTaxEngine;
        // TFS ID 387685: Check that TaxArea with maxstrlen Description doesn't raise StringOverflow
        TaxArea.Description := LibraryUtility.GenerateRandomXMLText(MaxStrLen(TaxArea.Description));
        TaxArea.Insert();
        TaxAreaLine."Tax Area" := TaxArea.Code;
        TaxAreaLine."Tax Jurisdiction Code" := TaxDetail."Tax Jurisdiction Code";
        TaxAreaLine.Insert();
        exit(TaxDetail."Tax Group Code");
    end;

    local procedure CreateTaxDetailWithJurisdiction(var TaxDetail: Record "Tax Detail")
    var
        TaxJurisdiction: Record "Tax Jurisdiction";
    begin
        TaxJurisdiction.Code := LibraryUTUtility.GetNewCode10();
        TaxJurisdiction.Insert();
        TaxDetail."Tax Jurisdiction Code" := TaxJurisdiction.Code;
        TaxDetail."Tax Group Code" := LibraryUTUtility.GetNewCode10();
        TaxDetail."Tax Below Maximum" := LibraryRandom.RandDecInRange(5, 10, 2);
        TaxDetail.Insert();
    end;

    local procedure CreateTaxArea(): Code[20]
    var
        TaxArea: Record "Tax Area";
    begin
        LibraryERM.CreateTaxArea(TaxArea);
        exit(TaxArea.Code);
    end;

    local procedure CreateTaxGroup(): Code[10]
    var
        TaxGroup: Record "Tax Group";
    begin
        LibraryERM.CreateTaxGroup(TaxGroup);
        exit(TaxGroup.Code);
    end;

    local procedure CreateTaxJurisdiction(): Code[10]
    var
        TaxJurisdiction: Record "Tax Jurisdiction";
    begin
        LibraryERM.CreateTaxJurisdiction(TaxJurisdiction);
        TaxJurisdiction.Validate("Tax Account (Sales)", LibraryERM.CreateGLAccountNo());
        TaxJurisdiction.Modify(true);
        exit(TaxJurisdiction.Code);
    end;

    local procedure CreateTaxAreaLine(TaxAreaCode: Code[20]; TaxJurisdictionCode: Code[10])
    var
        TaxAreaLine: Record "Tax Area Line";
    begin
        LibraryERM.CreateTaxAreaLine(TaxAreaLine, TaxAreaCode, TaxJurisdictionCode);
    end;

    local procedure CreateTaxDetail(TaxJurisdictionCode: Code[10]; TaxGroupCode: Code[20]; TaxType: Option): Decimal
    var
        TaxDetail: Record "Tax Detail";
    begin
        LibraryERM.CreateTaxDetail(TaxDetail, TaxJurisdictionCode, TaxGroupCode, TaxType, WorkDate());
        TaxDetail.Validate("Tax Below Maximum", LibraryRandom.RandDec(100, 2) * 0.1);
        TaxDetail.Modify(true);
        exit(TaxDetail."Tax Below Maximum");
    end;

    local procedure MockTaxArea(): Code[20]
    var
        TaxArea: Record "Tax Area";
    begin
        TaxArea.Init();
        TaxArea.Code := LibraryUTUtility.GetNewCode();
        TaxArea.Insert();
        LibraryVariableStorage.Enqueue(TaxArea.Code);
        // Enqueue value to use in SalesTaxAreaListRequestPageHandler.
        exit(TaxArea.Code);
    end;

    local procedure MockTaxGroup(): Code[10]
    var
        TaxGroup: Record "Tax Group";
    begin
        TaxGroup.Init();
        TaxGroup.Code := LibraryUTUtility.GetNewCode10();
        TaxGroup.Insert();
        LibraryVariableStorage.Enqueue(TaxGroup.Code);
        // Enqueue required for SalesTaxGroupListRequestPageHandler.
        exit(TaxGroup.Code);
    end;

    local procedure MockTaxJurisdiction(): Code[10]
    var
        TaxJurisdiction: Record "Tax Jurisdiction";
    begin
        TaxJurisdiction.Init();
        TaxJurisdiction.Code := LibraryUTUtility.GetNewCode10();
        TaxJurisdiction."Report-to Jurisdiction" := TaxJurisdiction.Code;
        TaxJurisdiction.Insert();
        exit(TaxJurisdiction.Code);
    end;

    local procedure EnqueueValuesForSalesTaxesCollected("Code": Code[10]; IncludeSales: Boolean; IncludePurchase: Boolean; IncludeUseTax: Boolean)
    begin
        // Enqueue value to use in SalesTaxesCollectedRequestPageHandler.
        LibraryVariableStorage.Enqueue(Code);
        LibraryVariableStorage.Enqueue(IncludeSales);
        LibraryVariableStorage.Enqueue(IncludePurchase);
        LibraryVariableStorage.Enqueue(IncludeUseTax);
    end;

    local procedure EnqueueValuesForServiceInvoiceAndCreditMemo(No: Code[20]; CompanyAddress: Boolean; NumberOfCopies: Integer)
    begin
        // Enqueue value required in ServiceCreditMemoSalesTaxRequestPageHandler and ServiceInvoiceSalesTaxRequestPageHandler.
        LibraryVariableStorage.Enqueue(No);
        LibraryVariableStorage.Enqueue(CompanyAddress);
        LibraryVariableStorage.Enqueue(NumberOfCopies);
    end;

    local procedure FindTaxDetail(var TaxDetail: Record "Tax Detail"; TaxAreaCode: Code[20]; TaxGroupCode: Code[20])
    var
        TaxAreaLine: Record "Tax Area Line";
    begin
        TaxAreaLine.SetRange("Tax Area", TaxAreaCode);
        TaxAreaLine.FindFirst();
        TaxDetail.SetRange("Tax Jurisdiction Code", TaxAreaLine."Tax Jurisdiction Code");
        TaxDetail.SetRange("Tax Group Code", TaxGroupCode);
        TaxDetail.FindFirst();
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20])
    begin
        SalesLine.SetRange("Document Type", DocumentType);
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.FindFirst();
    end;

    local procedure UpdateMissingVATPostingSetup()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
    begin
        VATPostingSetup.SetRange("VAT Bus. Posting Group", '');
        VATPostingSetup.SetRange("VAT Prod. Posting Group", '');
        VATPostingSetup.SetRange("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Sales Tax");
        if VATPostingSetup.IsEmpty() then begin
            VATPostingSetup.Init();
            VATPostingSetup."VAT Calculation Type" := VATPostingSetup."VAT Calculation Type"::"Sales Tax";
            VATPostingSetup."VAT %" := LibraryRandom.RandIntInRange(1, 25);
            LibraryERM.CreateGLAccount(GLAccount);
            VATPostingSetup."Sales VAT Account" := GLAccount."No.";
            LibraryERM.CreateGLAccount(GLAccount);
            VATPostingSetup."Purchase VAT Account" := GLAccount."No.";
            VATPostingSetup.Insert(true);
        end;
    end;

    local procedure UpdateItemInServiceCreditMemoLine(DocumentNo: Code[20]): Code[20]
    var
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
    begin
        ServiceCrMemoLine.SetRange("Document No.", DocumentNo);
        ServiceCrMemoLine.FindFirst();
        ServiceCrMemoLine.Type := ServiceCrMemoLine.Type::Item;
        ServiceCrMemoLine."No." := LibraryUTUtility.GetNewCode();
        ServiceCrMemoLine.Modify();
        exit(ServiceCrMemoLine."No.");
    end;

    local procedure UpdateItemInServiceInvoiceLine(DocumentNo: Code[20]): Code[20]
    var
        ServiceInvoiceLine: Record "Service Invoice Line";
    begin
        ServiceInvoiceLine.SetRange("Document No.", DocumentNo);
        ServiceInvoiceLine.FindFirst();
        ServiceInvoiceLine.Type := ServiceInvoiceLine.Type::Item;
        ServiceInvoiceLine."No." := LibraryUTUtility.GetNewCode();
        ServiceInvoiceLine.Modify();
        exit(ServiceInvoiceLine."No.");
    end;

    local procedure UpdateVATInUseOnGLSetup(): Code[10]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."VAT in Use" := true;
        GeneralLedgerSetup.Modify();
        exit(GeneralLedgerSetup."LCY Code");
    end;

    local procedure UpdateUnitPriceOnSalesLine(DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20]; TaxGroupCode: Code[20]; UnitPrice: Decimal): Decimal
    var
        SalesLine: Record "Sales Line";
        TaxDetail: Record "Tax Detail";
    begin
        FindSalesLine(SalesLine, DocumentType, DocumentNo);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);
        FindTaxDetail(TaxDetail, SalesLine."Tax Area Code", TaxGroupCode);
        exit(Round(SalesLine."Line Amount" * TaxDetail."Tax Below Maximum" / 100, LibraryERM.GetAmountRoundingPrecision()));
    end;

    local procedure RunSalesDocumentTestReport(DocumentNo: Code[20])
    begin
        Commit();
        LibraryVariableStorage.Enqueue(DocumentNo);
        REPORT.Run(REPORT::"Sales Document - Test");
    end;

    local procedure RunPurchaseDocumentTestReport(DocumentNo: Code[20])
    begin
        Commit();
        LibraryVariableStorage.Enqueue(DocumentNo);
        REPORT.Run(REPORT::"Purchase Document - Test");
    end;

    local procedure VerifyDataOnReport(ElementName: Text; ExpectedValue: Variant)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(ElementName, ExpectedValue);
    end;

    local procedure VerifyPostedSalesInvoice(DocumentNo: Code[20]; LineType: Enum "Sales Line Type"; Qty: Decimal; AmtIncludingVAT: Decimal)
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SalesInvoiceLine.SetRange("Document No.", DocumentNo);
        SalesInvoiceLine.SetRange(Type, LineType);
        SalesInvoiceLine.FindFirst();

        Assert.AreEqual(Qty, SalesInvoiceLine.Quantity, StrSubstNo(QtyErr, SalesInvoiceLine.TableCaption()));
        Assert.AreEqual(
          AmtIncludingVAT, SalesInvoiceLine."Amount Including VAT", StrSubstNo(AmountIncludingVATErr, SalesInvoiceLine.TableCaption()));
    end;

    local procedure VerifyDocumentTestReportSalesTaxAmountLinePct(TaxGroupCode: Code[20])
    var
        TaxDetail: Record "Tax Detail";
    begin
        LibraryReportDataset.LoadDataSetFile();
        TaxDetail.SetRange("Tax Group Code", TaxGroupCode);
        TaxDetail.FindSet();
        repeat
            LibraryReportDataset.AssertElementWithValueExists('SalesTaxAmountLine__Tax___', TaxDetail."Tax Below Maximum");
        until TaxDetail.Next() = 0;
    end;

    local procedure CreateServiceContractLine(var ServiceContractLine: Record "Service Contract Line"; ServiceContractHeader: Record "Service Contract Header")
    var
        ServiceItem: Record "Service Item";
        ServicePeriod: DateFormula;
    begin
        LibraryService.CreateServiceItem(ServiceItem, ServiceContractHeader."Customer No.");
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");

        // Use Random because value is not important.
        ServiceContractLine.Validate("Line Cost", 1000 * LibraryRandom.RandDecInRange(5, 10, 2));
        ServiceContractLine.Validate("Line Value", 1000 * LibraryRandom.RandDecInRange(5, 10, 2));
        Evaluate(ServicePeriod, '<' + Format(LibraryRandom.RandIntInRange(5, 10)) + 'M>');
        ServiceContractLine.Validate("Service Period", ServicePeriod);
        ServiceContractLine.Modify(true);
    end;

    local procedure AmountsInServiceContractHeader(var ServiceContractHeader: Record "Service Contract Header")
    begin
        ServiceContractHeader.CalcFields("Calcd. Annual Amount");
        ServiceContractHeader.Validate("Annual Amount", ServiceContractHeader."Calcd. Annual Amount");
        ServiceContractHeader.Validate("Starting Date", WorkDate());
        ServiceContractHeader.Validate("Price Update Period", ServiceContractHeader."Service Period");
        ServiceContractHeader.Modify(true);
    end;

    local procedure PostServiceInvoice(ServiceContractNo: Code[20])
    var
        ServiceDocumentRegister: Record "Service Document Register";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // Find the Service Invoice by searching in Service Document Register.
        ServiceDocumentRegister.SetRange("Source Document Type", ServiceDocumentRegister."Source Document Type"::Contract);
        ServiceDocumentRegister.SetRange("Source Document No.", ServiceContractNo);
        ServiceDocumentRegister.SetRange("Destination Document Type", ServiceDocumentRegister."Destination Document Type"::Invoice);
        ServiceDocumentRegister.FindFirst();
        ServiceHeader.Get(ServiceHeader."Document Type"::Invoice, ServiceDocumentRegister."Destination Document No.");

        // Update
        ServiceLine.SetCurrentKey("Contract No.", "Line No.");
        ServiceLine.SetRange("Contract No.", ServiceContractNo);
        ServiceLine.SetAscending("Line No.", true);
        if ServiceLine.FindLast() then
            CreateNewServiceLineWithBlankType(ServiceLine);

        LibraryService.PostServiceOrder(ServiceHeader, false, false, false);
    end;

    local procedure CreateNewServiceLineWithBlankType(ServiceLine: Record "Service Line")
    var
        ServiceLine1: Record "Service Line";
        i: Integer;
        LineNo: Integer;
    begin
        LineNo := ServiceLine."Line No." - 10;
        for i := 0 to 4 do begin
            ServiceLine1.Init();
            ServiceLine1."Document Type" := ServiceLine."Document Type"::Invoice;
            ServiceLine1."Document No." := ServiceLine."Document No.";
            ServiceLine1."Line No." := LineNo;
            ServiceLine1.Type := ServiceLine1.Type::" ";
            ServiceLine1.Description := LibraryRandom.RandText(20);
            ServiceLine1.Insert();
            LineNo -= 10;
        end;

        LineNo := ServiceLine."Line No." + 10;
        for i := 0 to 4 do begin
            ServiceLine1.Init();
            ServiceLine1."Document Type" := ServiceLine."Document Type"::Invoice;
            ServiceLine1."Document No." := ServiceLine."Document No.";
            ServiceLine1."Line No." := LineNo;
            ServiceLine1.Type := ServiceLine1.Type::" ";
            ServiceLine1.Description := LibraryRandom.RandText(20);
            ServiceLine1.Insert();
            LineNo += 10;
        end;
    end;

    local procedure FindFirstServiceInvoiceOnServiceContract(var ServiceInvoiceHeader: Record "Service Invoice Header"; ServiceContractNo: Code[20])
    begin
        ServiceInvoiceHeader.SetRange("Contract No.", ServiceContractNo);
        ServiceInvoiceHeader.FindFirst();
    end;

    local procedure CreateCurrencyWithExchangeRate(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        Currency.Validate("Residual Gains Account", LibraryERM.CreateGLAccountNo());
        Currency.Validate("Residual Losses Account", Currency."Residual Gains Account");
        Currency.Validate("Realized G/L Gains Account", LibraryERM.CreateGLAccountNo());
        Currency.Validate("Realized G/L Losses Account", Currency."Realized G/L Gains Account");
        Currency.Modify(true);

        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateItemWithTaxGroup(TaxGroupCode: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Tax Group Code", TaxGroupCode);
        Item.Validate("VAT Prod. Posting Group", '');
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateVendorWithTaxArea(TaxAreaCode: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GeneralPostingSetup.SetFilter("Purch. Account", '<>%1', '');
        GeneralPostingSetup.SetFilter("Gen. Bus. Posting Group", '<>%1', '');
        GeneralPostingSetup.FindFirst();

        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", '');
        Vendor.Validate("Tax Liable", true);
        Vendor.Validate("Tax Area Code", TaxAreaCode);
        Vendor.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        Vendor.Validate("Vendor Posting Group", LibraryPurchase.FindVendorPostingGroup());
        Vendor.Modify(true);

        exit(Vendor."No.");
    end;

    local procedure CreateTaxAreaSetupWithValues(var TaxDetail: Record "Tax Detail"; TaxAreaCode: Code[20]; TaxGroupCode: Code[20]; TaxBelowMax: Decimal)
    var
        TaxJurisdiction: Record "Tax Jurisdiction";
        TaxAreaLine: Record "Tax Area Line";
    begin
        LibraryERM.CreateTaxJurisdiction(TaxJurisdiction);
        TaxJurisdiction.Validate("Tax Account (Purchases)", LibraryERM.CreateGLAccountNo());
        TaxJurisdiction.Modify(true);

        LibraryERM.CreateTaxDetail(TaxDetail, TaxJurisdiction.Code, TaxGroupCode, TaxDetail."Tax Type"::"Sales and Use Tax", WorkDate());
        TaxDetail.Validate("Tax Below Maximum", TaxBelowMax);
        TaxDetail.Modify(true);

        LibraryERM.CreateTaxAreaLine(TaxAreaLine, TaxAreaCode, TaxJurisdiction.Code);
    end;

    local procedure CreatePurchaseLineWithDirectUnitCost(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; TaxGroup: Record "Tax Group")
    begin
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine,
            PurchaseHeader,
            PurchaseLine.Type::Item,
            CreateItemWithTaxGroup(TaxGroup.Code),
            LibraryRandom.RandInt(0));

        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(100, 100));
        PurchaseLine.Modify(true);
    end;

    local procedure RunDocumentTestReport(DocumentType: Enum "Purchase Document Type"; DocumentNo: Code[20]; ReportType: Integer)
    begin
        Commit();

        LibraryVariableStorage.Enqueue(DocumentType);
        LibraryVariableStorage.Enqueue(DocumentNo);
        REPORT.Run(ReportType);
    end;

    local procedure SumTaxAmountInTestReport(): Decimal
    begin
        exit(LibraryReportDataset.Sum('SalesTaxAmountLine__Tax_Amount__Control1020000'));
    end;

    local procedure GetExpectedComment(var SalesCrmemoHdr: Record "Sales Cr.Memo Header"): Text[81]
    var
        SalesCommentLine: Record "Sales Comment Line";
    begin
        SalesCommentLine.Reset();
        SalesCommentLine.SetRange("Document Type", SalesCommentLine."Document Type"::"Posted Credit Memo");
        SalesCommentLine.SetRange("No.", SalesCrmemoHdr."No.");
        SalesCommentLine.FindLast();
        exit(SalesCommentLine.Comment + ' ');
    end;

    local procedure CreateCommentLines(var SalesHeader: Record "Sales Header")
    var
        SalesCommentLine: Record "Sales Comment Line";
        DocumentType: Enum "Sales Document Type";
    begin
        LibrarySales.CreateSalesCommentLine(SalesCommentLine, DocumentType::"Credit Memo", SalesHeader."No.", 0);
        SalesCommentLine.Validate("Print On Credit Memo", true);
        SalesCommentLine.Modify(true);
        LibrarySales.CreateSalesCommentLine(SalesCommentLine, DocumentType::"Credit Memo", SalesHeader."No.", 0);
        SalesCommentLine.Validate("Print On Credit Memo", true);
        SalesCommentLine.Modify(true);
        LibrarySales.CreateSalesCommentLine(SalesCommentLine, DocumentType::"Credit Memo", SalesHeader."No.", 0);
        SalesCommentLine.Validate("Print On Credit Memo", true);
        SalesCommentLine.Modify(true);
        LibrarySales.CreateSalesCommentLine(SalesCommentLine, DocumentType::"Credit Memo", SalesHeader."No.", 0);
        SalesCommentLine.Validate("Print On Credit Memo", true);
        SalesCommentLine.Modify(true);
        LibrarySales.CreateSalesCommentLine(SalesCommentLine, DocumentType::"Credit Memo", SalesHeader."No.", 0);
        SalesCommentLine.Validate("Print On Credit Memo", true);
        SalesCommentLine.Modify(true);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseDocumentTestRequestPageHandler(var PurchaseDocumentTest: TestRequestPage "Purchase Document - Test")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        PurchaseDocumentTest."Purchase Header".SetFilter("No.", No);
        PurchaseDocumentTest.ReceiveShip.SetValue(true);
        PurchaseDocumentTest.Invoice.SetValue(true);
        PurchaseDocumentTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseBlanketOrderRequestPageHandler(var PurchaseBlanketOrder: TestRequestPage "Purchase Blanket Order")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        PurchaseBlanketOrder."Purchase Header".SetFilter("No.", No);
        PurchaseBlanketOrder.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemoRequestPageHandler(var PurchaseCreditMemo: TestRequestPage "Purchase Credit Memo NA")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        PurchaseCreditMemo."Purch. Cr. Memo Hdr.".SetFilter("No.", No);
        PurchaseCreditMemo.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceRequestPageHandler(var PurchaseInvoice: TestRequestPage "Purchase Invoice NA")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        PurchaseInvoice."Purch. Inv. Header".SetFilter("No.", No);
        PurchaseInvoice.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseOrderRequestPageHandler(var PurchaseOrder: TestRequestPage "Purchase Order")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        PurchaseOrder."Purchase Header".SetFilter("No.", No);
        PurchaseOrder.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseOrderPrePrintedRequestPageHandler(var PurchaseOrderPrePrinted: TestRequestPage "Purchase Order (Pre-Printed)")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        PurchaseOrderPrePrinted."Purchase Header".SetFilter("No.", No);
        PurchaseOrderPrePrinted.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseQuoteRequestPageHandler(var PurchaseQuote: TestRequestPage "Purchase Quote NA")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        PurchaseQuote."Purchase Header".SetFilter("No.", No);
        PurchaseQuote.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesBlanketOrderRequestPageHandler(var SalesBlanketOrder: TestRequestPage "Sales Blanket Order")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        SalesBlanketOrder."Sales Header".SetFilter("No.", No);
        SalesBlanketOrder.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesCreditMemoRequestPageHandler(var SalesCreditMemo: TestRequestPage "Sales Credit Memo NA")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        SalesCreditMemo."Sales Cr.Memo Header".SetFilter("No.", No);
        SalesCreditMemo.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
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
    procedure SalesInvoiceTestRequestPageHandler(var SalesInvoice: TestRequestPage "Sales Invoice NA")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        SalesInvoice."Sales Invoice Header".SetFilter("No.", No);
        SalesInvoice.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesInvoicePrePrintedRequestPageHandler(var SalesInvoicePrePrinted: TestRequestPage "Sales Invoice (Pre-Printed)")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        SalesInvoicePrePrinted."Sales Invoice Header".SetFilter("No.", No);
        SalesInvoicePrePrinted.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderTestRequestPageHandler(var SalesOrder: TestRequestPage "Sales Order")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        SalesOrder."Sales Header".SetFilter("No.", No);
        SalesOrder.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesTaxAreaListRequestPageHandler(var SalesTaxAreaList: TestRequestPage "Sales Tax Area List")
    var
        "Code": Variant;
    begin
        LibraryVariableStorage.Dequeue(Code);
        SalesTaxAreaList."Tax Area".SetFilter(Code, Code);
        SalesTaxAreaList.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesTaxesCollectedRequestPageHandler(var SalesTaxesCollected: TestRequestPage "Sales Taxes Collected")
    var
        "Code": Variant;
        IncludePurchase: Variant;
        IncludeSales: Variant;
        IncludeUseTax: Variant;
    begin
        LibraryVariableStorage.Dequeue(Code);
        LibraryVariableStorage.Dequeue(IncludeSales);
        LibraryVariableStorage.Dequeue(IncludePurchase);
        LibraryVariableStorage.Dequeue(IncludeUseTax);
        SalesTaxesCollected."Tax Jurisdiction".SetFilter(Code, Code);
        SalesTaxesCollected.IncludeSales.SetValue(IncludeSales);
        SalesTaxesCollected.IncludePurchases.SetValue(IncludePurchase);
        SalesTaxesCollected.IncludeUseTax.SetValue(IncludeUseTax);
        SalesTaxesCollected.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesTaxDetailByAreaRequestPageHandler(var SalesTaxDetailbyArea: TestRequestPage "Sales Tax Detail by Area")
    var
        "Code": Variant;
        TaxGroupCode: Variant;
    begin
        LibraryVariableStorage.Dequeue(Code);
        LibraryVariableStorage.Dequeue(TaxGroupCode);
        SalesTaxDetailbyArea."Tax Area".SetFilter(Code, Code);
        SalesTaxDetailbyArea."Tax Detail".SetFilter("Tax Group Code", TaxGroupCode);
        SalesTaxDetailbyArea.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesTaxJurisdictionListRequestPageHandler(var SalesTaxJurisdictionList: TestRequestPage "Sales Tax Jurisdiction List")
    var
        "Code": Variant;
    begin
        LibraryVariableStorage.Dequeue(Code);
        SalesTaxJurisdictionList."Tax Jurisdiction".SetFilter(Code, Code);
        SalesTaxJurisdictionList.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesTaxGroupListRequestPageHandler(var SalesTaxGroupList: TestRequestPage "Sales Tax Group List")
    var
        TaxGroupCode: Variant;
    begin
        LibraryVariableStorage.Dequeue(TaxGroupCode);
        SalesTaxGroupList."Tax Group".SetFilter(Code, TaxGroupCode);
        SalesTaxGroupList.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesTaxDetailListRequestPageHandler(var SalesTaxDetailList: TestRequestPage "Sales Tax Detail List")
    var
        TaxJurisdictionCode: Variant;
    begin
        LibraryVariableStorage.Dequeue(TaxJurisdictionCode);
        SalesTaxDetailList."Tax Jurisdiction".SetFilter(Code, TaxJurisdictionCode);
        SalesTaxDetailList.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesQuoteTestRequestPageHandler(var SalesQuote: TestRequestPage "Sales Quote NA")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        SalesQuote."Sales Header".SetFilter("No.", No);
        SalesQuote.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ServiceCreditMemoSalesTaxRequestPageHandler(var ServiceCreditMemoSalesTax: TestRequestPage "Service Credit Memo-Sales Tax")
    var
        No: Variant;
        NumberOfCopies: Variant;
        PrintCompanyAddress: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(PrintCompanyAddress);
        LibraryVariableStorage.Dequeue(NumberOfCopies);
        ServiceCreditMemoSalesTax.NumberOfCopies.SetValue(NumberOfCopies);
        ServiceCreditMemoSalesTax.PrintCompanyAddress.SetValue(PrintCompanyAddress);
        ServiceCreditMemoSalesTax."Service Cr.Memo Header".SetFilter("No.", No);
        ServiceCreditMemoSalesTax.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ServiceInvoiceSalesTaxRequestPageHandler(var ServiceInvoiceSalesTax: TestRequestPage "Service Invoice-Sales Tax")
    var
        No: Variant;
        NumberOfCopies: Variant;
        PrintCompanyAddress: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(PrintCompanyAddress);
        LibraryVariableStorage.Dequeue(NumberOfCopies);
        ServiceInvoiceSalesTax.NumberOfCopies.SetValue(NumberOfCopies);
        ServiceInvoiceSalesTax.PrintCompanyAddress.SetValue(PrintCompanyAddress);
        ServiceInvoiceSalesTax."Service Invoice Header".SetFilter("No.", No);
        ServiceInvoiceSalesTax.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ServiceOrderRequestPageHandler(var ServiceOrder: TestRequestPage "Service Order")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        ServiceOrder."Service Header".SetFilter("No.", No);
        ServiceOrder.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ServiceQuoteRequestPageHandler(var ServiceQuote: TestRequestPage "Service Quote")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        ServiceQuote."Service Header".SetFilter("No.", No);
        ServiceQuote.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHStandardPurchaseOrder(var StandardPurchaseOrder: TestRequestPage "Standard Purchase - Order")
    begin
        StandardPurchaseOrder.LogInteraction.SetValue(false);
        StandardPurchaseOrder.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ServiceInvoiceTestRequestPageHandler(var ServiceInvoice: TestRequestPage "Service - Invoice")
    begin
        ServiceInvoice."Service Invoice Header".SetFilter("No.", LibraryVariableStorage.DequeueText());
        ServiceInvoice.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ServiceCrMemoTestRequestPageHandler(var ServiceCreditMemo: TestRequestPage "Service - Credit Memo")
    begin
        ServiceCreditMemo."Service Cr.Memo Header".SetFilter("No.", LibraryVariableStorage.DequeueText());
        ServiceCreditMemo.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseDocumentTestReqPageHandler(var PurchaseDocumentTest: TestRequestPage "Purchase Document - Test")
    var
        DocumentType: Variant;
        No: Variant;
        DocumentType2: Option;
    begin
        LibraryVariableStorage.Dequeue(DocumentType);
        LibraryVariableStorage.Dequeue(No);
        DocumentType2 := DocumentType;
        PurchaseDocumentTest."Purchase Header".SetFilter("Document Type", Format(DocumentType2));
        PurchaseDocumentTest."Purchase Header".SetFilter("No.", No);
        PurchaseDocumentTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ContractTemplateListHandler(var ServiceContractTemplateList: Page "Service Contract Template List"; var Response: Action)
    begin
        Response := Action::LookupOK;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [RequestPageHandler]
    procedure SalesCrMemoXmlReportHandler(var SalesCrMemo: TestRequestPage "Sales Credit Memo NA")
    begin
        SalesCrMemo.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

