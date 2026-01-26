codeunit 144003 "UT REP Purchase Process Doc"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Purchase] [Reports]
    end;

    var
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        NoPurchaseHeaderCap: Label 'No_PurchHeader';
        CompanyAddressCap: Label 'CompanyAddress1';
        ItemNumberToPrintCap: Label 'ItemNumberToPrint';
        TotalTaxLabelCap: Label 'TotalTaxLabel';
        PaymentTermsDescriptionCap: Label 'PaymentTermsDescription';
        CopyNoCap: Label 'CopyNo';
        CopyTextCap: Label 'CopyTxt';
        SalesPurchasePersonNameCap: Label 'SalesPurchPersonName';
        TotalTaxTxt: Label 'Total Tax';
        TotalSalesTaxTxt: Label 'Total Sales Tax';
        CopyTxt: Label 'COPY';
        PaymentTermsDescCap: Label 'PaymentTermsDesc';

    [Test]
    [HandlerFunctions('PurchaseDocumentTestRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemPurchaseHeaderSummarizePurchDocTest()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Purpose of the test is to validate OnPreDataItem of Purchase Header of Report 402 - Purchase Document - Test.

        // Setup: Create Purchase Header Document Type - Order.
        Initialize();
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order);

        // Exercise.
        REPORT.Run(REPORT::"Purchase Document - Test");  // Set Summary Boolean as TRUE on handler - PurchaseDocumentTestRequestPageHandler.

        // Verify: Verify Summarize as TRUE and Document No on Report Purchase Document - Test.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Summarize', true);
        LibraryReportDataset.AssertElementWithValueExists('Purchase_Header_No_', PurchaseHeader."No.");
    end;

    [Test]
    [HandlerFunctions('PurchaseBlanketOrderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnPreDataItemPurchaseBlanketOrder()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Purpose of the test is to validate OnPreDataItem Trigger of Purchase Header of Report 10119 - Purchase Blanket Order.

        // Setup: Create Purchase Header Document Type - Blanket Order.
        Initialize();
        OnPreDataItemPurchaseDocument(
          PurchaseHeader."Document Type"::"Blanket Order", REPORT::"Purchase Blanket Order", NoPurchaseHeaderCap);
    end;

    [Test]
    [HandlerFunctions('PurchaseOrderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnPreDataItemPurchaseOrder()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Purpose of the test is to validate OnPreDataItem Trigger of Purchase Header of Report 10122 - Purchase Order.

        // Setup: Create Purchase Header Document Type - Order.
        Initialize();
        OnPreDataItemPurchaseDocument(PurchaseHeader."Document Type"::Order, REPORT::"Purchase Order", 'No_PurchaseHeader');
    end;

    [Test]
    [HandlerFunctions('PurchaseOrderPrePrintedRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnPreDataItemPurchaseOrderPrePrinted()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Purpose of the test is to validate OnPreDataItem Trigger of Purchase Header of Report 10125 - Purchase Order (Pre-Printed).

        // Setup: Create Purchase Header Document Type - Order for Report - Purchase Order (Pre-Printed).
        Initialize();
        OnPreDataItemPurchaseDocument(PurchaseHeader."Document Type"::Order, REPORT::"Purchase Order (Pre-Printed)", 'No_PurchHdr');
    end;

    [Test]
    [HandlerFunctions('ReturnOrderConfirmRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnPreDataItemReturnOrderConfirm()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Purpose of the test is to validate OnPreDataItem Trigger of Purchase Header of Report 10126 - Return Order Confirm.

        // Setup: Create Purchase Header Document Type - Return Order for Report - Return Order Confirm.
        Initialize();
        OnPreDataItemPurchaseDocument(PurchaseHeader."Document Type"::"Return Order", REPORT::"Return Order Confirm", NoPurchaseHeaderCap);
    end;

    local procedure OnPreDataItemPurchaseDocument(DocumentType: Enum "Purchase Document Type"; ReportID: Integer; ElementCaption: Text)
    var
        PurchaseHeader: Record "Purchase Header";
        ResponsibilityCenter: Record "Responsibility Center";
    begin
        // Create Purchase Header.
        CreatePurchaseHeader(PurchaseHeader, DocumentType);

        // Exercise: Opens different Request Page Handler. Commit required as the explicit Commit used on OnRun Trigger of Codeunit 317 - Purch.Header-Printed.
        RunReportsPPForCompanyAddress(ResponsibilityCenter, PurchaseHeader."Responsibility Center", ReportID);

        // Verify: Verify Purchase Header No and Company Address on Different Reports.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(ElementCaption, PurchaseHeader."No.");
        LibraryReportDataset.AssertElementWithValueExists(CompanyAddressCap, ResponsibilityCenter.Name);
    end;

    [Test]
    [HandlerFunctions('PurchaseBlanketOrderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPurchaseBlanketOrder()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Purpose of the test is to validate OnAfterGetRecord Trigger of Purchase Header of Report 10119 - Purchase Blanket Order.

        // Setup: Create Purchase Header Document Type - Blanket Order.
        Initialize();
        OnAfterGetRecordPurchaseDocument(
          PurchaseHeader."Document Type"::"Blanket Order", REPORT::"Purchase Blanket Order", PaymentTermsDescriptionCap);
    end;

    [Test]
    [HandlerFunctions('PurchaseOrderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPurchaseOrder()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Purpose of the test is to validate OnAfterGetRecord Trigger of Purchase Header of Report 10122 - Purchase Order.

        // Setup: Create Purchase Header Document Type - Order.
        Initialize();
        OnAfterGetRecordPurchaseDocument(PurchaseHeader."Document Type"::Order, REPORT::"Purchase Order", PaymentTermsDescriptionCap);
    end;

    [Test]
    [HandlerFunctions('PurchaseOrderPrePrintedRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPurchaseOrderPrePrinted()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Purpose of the test is to validate OnAfterGetRecord Trigger of Purchase Header of Report 10125 - Purchase Order (Pre-Printed).

        // Setup: Create Purchase Header Document Type - Order for Report - Purchase Order (Pre-Printed).
        Initialize();
        OnAfterGetRecordPurchaseDocument(
          PurchaseHeader."Document Type"::Order, REPORT::"Purchase Order (Pre-Printed)", PaymentTermsDescriptionCap);
    end;

    [Test]
    [HandlerFunctions('ReturnOrderConfirmRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordReturnOrderConfirm()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Purpose of the test is to validate OnAfterGetRecord Trigger of Purchase Header of Report 10126 - Return Order Confirm.

        // Setup: Create Purchase Header Document Type - Return Order for Report - Return Order Confirm.
        Initialize();
        OnAfterGetRecordPurchaseDocument(
          PurchaseHeader."Document Type"::"Return Order", REPORT::"Return Order Confirm", PaymentTermsDescCap);
    end;

    local procedure OnAfterGetRecordPurchaseDocument(DocumentType: Enum "Purchase Document Type"; ReportID: Integer; ElementCaption: Text)
    var
        PurchaseHeader: Record "Purchase Header";
        PaymentTerms: Record "Payment Terms";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
    begin
        // Create Purchase Header.
        PaymentTerms.FindFirst();
        CreateSalespersonPurchaser(SalespersonPurchaser);
        CreatePurchaseHeader(PurchaseHeader, DocumentType);
        PurchaseHeader."Payment Terms Code" := PaymentTerms.Code;
        PurchaseHeader."Purchaser Code" := SalespersonPurchaser.Code;
        PurchaseHeader.Modify();
        LibraryVariableStorage.Enqueue(false);  // Enqueue value for different RequestPageHandlers.

        // Exercise.
        Commit();  // Commit required as the explicit Commit used on OnRun Trigger of Codeunit 317 - Purch.Header-Printed.
        REPORT.Run(ReportID);  // Opens handler PurchaseBlanketOrderRequestPageHandler, PurchaseOrderRequestPageHandler or PurchaseQuoteRequestPageHandler.

        // Verify: Verify Sales Person Purchaser Name and Payment term Description on different Reports.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(SalesPurchasePersonNameCap, SalespersonPurchaser.Name);
        LibraryReportDataset.AssertElementWithValueExists(ElementCaption, PaymentTerms.Description);
    end;

    [Test]
    [HandlerFunctions('NumberOfCopiesPurchaseBlanketOrderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordCopyLoopPurchaseBlanketOrder()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Purpose of the test is to validate OnAfterGetRecord Trigger of CopyLoop of Report 10119 - Purchase Blanket Order.

        // Setup: Create Purchase Header Document Type - Blanket Order.
        Initialize();
        OnAfterGetRecordCopyLoopPurchaseDocument(PurchaseHeader."Document Type"::"Blanket Order", REPORT::"Purchase Blanket Order");
    end;

    [Test]
    [HandlerFunctions('NumberOfCopiesPurchaseOrderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordCopyLoopPurchaseOrder()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Purpose of the test is to validate OnAfterGetRecord Trigger of CopyLoop of Report 10122 - Purchase Order.

        // Setup: Create Purchase Header Document Type Order.
        Initialize();
        OnAfterGetRecordCopyLoopPurchaseDocument(PurchaseHeader."Document Type"::Order, REPORT::"Purchase Order");
    end;

    [Test]
    [HandlerFunctions('NumberOfCopiesPurchaseQuoteRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordCopyLoopPurchaseQuote()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Purpose of the test is to validate OnAfterGetRecord Trigger of CopyLoop of Report 10123 - Purchase Quote.

        // Setup: Create Purchase Header Document Type - Quote.
        Initialize();
        OnAfterGetRecordCopyLoopPurchaseDocument(PurchaseHeader."Document Type"::Quote, REPORT::"Purchase Quote NA");
    end;

    [Test]
    [HandlerFunctions('NumberOfCopiesPurchOrdPrePrintedRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordCopyLoopPurchaseOrderPrePrinted()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Purpose of the test is to validate OnAfterGetRecord Trigger of CopyLoop of Report 10125 - Purchase Order (Pre-Printed).

        // Setup: Create Purchase Header Document Type - Order for Report - Purchase Order (Pre-Printed).
        Initialize();
        OnAfterGetRecordCopyLoopPurchaseDocument(PurchaseHeader."Document Type"::Order, REPORT::"Purchase Order (Pre-Printed)");
    end;

    [Test]
    [HandlerFunctions('NumberOfCopiesReturnOrderConfirmRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordCopyLoopReturnOrderConfirm()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Purpose of the test is to validate OnAfterGetRecord Trigger of CopyLoop of Report 10126 - Return Order Confirm.

        // Setup: Create Purchase Header Document Type - Return Order for Report - Return Order Confirm.
        Initialize();
        OnAfterGetRecordCopyLoopPurchaseDocument(PurchaseHeader."Document Type"::"Return Order", REPORT::"Return Order Confirm");
    end;

    local procedure OnAfterGetRecordCopyLoopPurchaseDocument(DocumentType: Enum "Purchase Document Type"; ReportID: Integer)
    var
        PurchaseHeader: Record "Purchase Header";
        NumberOfCopies: Integer;
    begin
        // Create Purchase Header of different Document Type.
        CreatePurchaseHeader(PurchaseHeader, DocumentType);

        // Exercise: Set Number of copies on different Request Page Handler. Commit required as the explicit Commit used on OnRun Trigger of Codeunit 317 - Purch.Header-Printed.
        RunRepotsPPForNumberOfCopies(NumberOfCopies, ReportID);

        // Verify: Verify Copy Caption and total number of copies on Different Reports.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(CopyTextCap, Format(CopyTxt));
        LibraryReportDataset.AssertElementWithValueExists(CopyNoCap, NumberOfCopies + 1);
    end;

    [Test]
    [HandlerFunctions('NumberOfCopiesPurchaseBlanketOrderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordCopyLoopTaxAreaCAPurchBlanketOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        TaxArea: Record "Tax Area";
    begin
        // Purpose of the test is to validate OnAfterGetRecord of CopyLoop of Report 10119 - Purchase Blanket Order.

        // Setup: Create Purchase Blanket Order with Tax Area Country CA.
        Initialize();
        OnAfterGetRecordCopyLoopTaxAreaPurchaseDocument(
          TaxArea."Country/Region"::CA, PurchaseHeader."Document Type"::"Blanket Order", REPORT::"Purchase Blanket Order",
          TotalTaxLabelCap, TotalTaxTxt);
    end;

    [Test]
    [HandlerFunctions('NumberOfCopiesPurchaseBlanketOrderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordCopyLoopTaxAreaUSPurchBlanketOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        TaxArea: Record "Tax Area";
    begin
        // Purpose of the test is to validate OnAfterGetRecord of CopyLoop of Report 10119 - Purchase Blanket Order.

        // Setup: Create Purchase Blanket Order with Tax Area Country US.
        Initialize();
        OnAfterGetRecordCopyLoopTaxAreaPurchaseDocument(
          TaxArea."Country/Region"::US, PurchaseHeader."Document Type"::"Blanket Order", REPORT::"Purchase Blanket Order",
          TotalTaxLabelCap, TotalSalesTaxTxt);
    end;

    [Test]
    [HandlerFunctions('NumberOfCopiesPurchaseOrderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordCopyLoopTaxAreaCAPurchaseOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        TaxArea: Record "Tax Area";
    begin
        // Purpose of the test is to validate OnAfterGetRecord of Copy Loop of Report 10122 - Purchase Order.

        // Setup: Create Purchase Order with Tax Area Country CA.
        Initialize();
        OnAfterGetRecordCopyLoopTaxAreaPurchaseDocument(
          TaxArea."Country/Region"::CA, PurchaseHeader."Document Type"::Order, REPORT::"Purchase Order", TotalTaxLabelCap, TotalTaxTxt);
    end;

    [Test]
    [HandlerFunctions('NumberOfCopiesPurchaseOrderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordCopyLoopTaxAreaUSPurchaseOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        TaxArea: Record "Tax Area";
    begin
        // Purpose of the test is to validate OnAfterGetRecord of Copy Loop of Report 10122 - Purchase Order.

        // Setup: Create Purchase Order with Tax Area Country US.
        Initialize();
        OnAfterGetRecordCopyLoopTaxAreaPurchaseDocument(
          TaxArea."Country/Region"::US, PurchaseHeader."Document Type"::Order, REPORT::"Purchase Order", TotalTaxLabelCap, TotalSalesTaxTxt);
    end;

    local procedure OnAfterGetRecordCopyLoopTaxAreaPurchaseDocument(Country: Option; DocumentType: Enum "Purchase Document Type"; ReportID: Integer; ElementCaption: Text; ExpectedTaxValue: Text)
    var
        PurchaseHeader: Record "Purchase Header";
        TaxArea: Record "Tax Area";
    begin
        // Create Purchase Document with Tax Area.
        CreateTaxArea(TaxArea, Country);
        CreatePurchaseDocument(PurchaseHeader, DocumentType);
        LibraryVariableStorage.Enqueue(LibraryRandom.RandInt(10));  // Enqueue value required in different Request Handlers.
        UpdatePurchaseHeaderTaxAreaCode(PurchaseHeader, TaxArea.Code);

        // Exercise.
        Commit();  // Commit required as the explicit Commit used on OnRun Trigger of Codeunit 317 - Purch.Header-Printed.
        REPORT.Run(ReportID);  // Opens Request Page handlers - NumberOfCopiesPurchaseBlanketOrderRequestPageHandler, NumberOfCopiesPurchaseOrderRequestPageHandler or NumberOfCopiesPurchaseQuoteRequestPageHandler.

        // Verify: Verify Total Tax Label on different Reports.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(ElementCaption, ExpectedTaxValue + ':');  // Not able to pass Symbol - :, as part of constant hence taking it here.
    end;

    [Test]
    [HandlerFunctions('PurchaseOrderPrePrintedRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordQuantityPurchaseOrderPrePrinted()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Purpose of the test is to validate OnAfterGetRecord of Purchase Line of Report 10125 - Purchase Order (Pre-Printed).

        // Setup: Create Purchase Document Type Order with Tax Area.
        Initialize();
        OnAfterGetRecordPurchaseLine(
          PurchaseHeader."Document Type"::Order, REPORT::"Purchase Order (Pre-Printed)", ItemNumberToPrintCap, 'Quantity_PurchaseLine');
    end;

    [Test]
    [HandlerFunctions('ReturnOrderConfirmRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPurchaseLineReturnOrderConfirm()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Purpose of the test is to validate OnAfterGetRecord of CopyLoop of Report 10126 - Return Order Confirm.

        // Setup: Create Purchase Document Type Return Order with Tax Area.
        Initialize();
        OnAfterGetRecordPurchaseLine(
          PurchaseHeader."Document Type"::"Return Order", REPORT::"Return Order Confirm", 'ItemNoTo_PrintPurchLine', 'Qty_PrintPurchLine');
    end;

    local procedure OnAfterGetRecordPurchaseLine(DocumentType: Enum "Purchase Document Type"; ReportID: Integer; ItemNoToPrint: Text; QuantityToPrint: Text)
    var
        PurchaseHeader: Record "Purchase Header";
        TaxArea: Record "Tax Area";
        PurchaseLine: Record "Purchase Line";
    begin
        // Create Purchase Document with Tax Area.
        CreateTaxArea(TaxArea, LibraryRandom.RandIntInRange(0, 1)); // Only two option value for Tax Area so using Range 0 to 1.
        CreatePurchaseDocument(PurchaseHeader, DocumentType);
        UpdatePurchaseHeaderTaxAreaCode(PurchaseHeader, TaxArea.Code);
        UpdatePurchaseLine(PurchaseLine, PurchaseHeader."Document Type", PurchaseHeader."No.");
        LibraryVariableStorage.Enqueue(false);  // Enqueue value for PurchaseOrderPrePrintedRequestPageHandler or ReturnOrderConfirmRequestPageHandler.

        // Exercise.
        Commit();  // Commit required as the explicit Commit used on OnRun Trigger of Codeunit 317 - Purch.Header-Printed.
        REPORT.Run(ReportID);  // Opens Request Page handler - PurchaseOrderPrePrintedRequestPageHandler or ReturnOrderConfirmRequestPageHandler.

        // Verify: Verify Purchase line Quantity and No on different Reports - Purchase Order (Pre-Printed) or Return Order Confirm.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(ItemNoToPrint, PurchaseLine."No.");
        LibraryReportDataset.AssertElementWithValueExists(QuantityToPrint, PurchaseLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('OpenPurchaseInvoicesByJobRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecVendLedgEntryOpenPurchInvoicesByJob()
    var
        PurchInvLine: Record "Purch. Inv. Line";
        AmountLCY: Decimal;
    begin
        // Purpose of the test is to validate OnAfterGetRecord of VendorLedgerEntry of Report 10092 - Open Purchase Invoices by Job.

        // Setup: Create Posted Purchase Invoice with Job.
        Initialize();
        CreatePostedPurchaseInvoiceWithJob(PurchInvLine);
        AmountLCY :=
          CreateDetailedVendorLedgerEntry(CreateVendorLedgerEntry(PurchInvLine."Document No.", PurchInvLine."Buy-from Vendor No."));

        // Exercise.
        REPORT.Run(REPORT::"Open Purchase Invoices by Job");  // Opens handler - OpenPurchaseInvoicesByJobRequestPageHandler.

        // Verify: Verify Job Number, Document No, and Remaining Amount LCY on Report - Open Purchase Invoices by Job.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Job_No_', PurchInvLine."Job No.");
        LibraryReportDataset.AssertElementWithValueExists('Purch__Inv__Line_Document_No_', PurchInvLine."Document No.");
        LibraryReportDataset.AssertElementWithValueExists('Vendor_Ledger_Entry___Remaining_Amt___LCY__', AmountLCY);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateJob(): Code[20]
    var
        Job: Record Job;
    begin
        Job."No." := LibraryUTUtility.GetNewCode();
        Job.Insert();
        exit(Job."No.");
    end;

    local procedure CreateTaxArea(var TaxArea: Record "Tax Area"; Country: Option)
    begin
        TaxArea.Code := LibraryUTUtility.GetNewCode();
        TaxArea."Country/Region" := Country;
        TaxArea.Insert();
    end;

    local procedure CreatePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type")
    begin
        PurchaseHeader."Document Type" := DocumentType;
        PurchaseHeader."No." := LibraryUTUtility.GetNewCode();
        PurchaseHeader."Buy-from Vendor No." := CreateVendor();
        PurchaseHeader."Responsibility Center" := CreateResponsibilityCenter();
        PurchaseHeader.Insert();
        LibraryVariableStorage.Enqueue(PurchaseHeader."No.");  // Enqueue value required in RequestPageHandler.
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseHeader(PurchaseHeader, DocumentType);
        PurchaseLine."Document Type" := PurchaseHeader."Document Type";
        PurchaseLine."Document No." := PurchaseHeader."No.";
        PurchaseLine.Insert();
    end;

    local procedure CreatePostedPurchaseInvoiceWithJob(var PurchInvLine: Record "Purch. Inv. Line")
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader."No." := LibraryUTUtility.GetNewCode();
        PurchInvHeader."Pay-to Vendor No." := CreateVendor();
        PurchInvHeader.Insert();
        PurchInvLine."Document No." := PurchInvHeader."No.";
        PurchInvLine."Job No." := CreateJob();
        PurchInvLine."Buy-from Vendor No." := PurchInvHeader."Pay-to Vendor No.";
        PurchInvLine.Insert();
        LibraryVariableStorage.Enqueue(PurchInvLine."Job No.");  // Enqueue value required in OpenPurchaseInvoicesByJobRequestPageHandler.
    end;

    local procedure CreateResponsibilityCenter(): Code[10]
    var
        ResponsibilityCenter: Record "Responsibility Center";
    begin
        ResponsibilityCenter.Code := LibraryUTUtility.GetNewCode10();
        ResponsibilityCenter.Name := LibraryUTUtility.GetNewCode();
        ResponsibilityCenter.Insert();
        exit(ResponsibilityCenter.Code);
    end;

    local procedure CreateSalespersonPurchaser(var SalespersonPurchaser: Record "Salesperson/Purchaser")
    begin
        SalespersonPurchaser.Code := LibraryUTUtility.GetNewCode10();
        SalespersonPurchaser.Name := LibraryUTUtility.GetNewCode();
        SalespersonPurchaser.Insert();
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        VendorPostingGroup.FindFirst();
        Vendor."No." := LibraryUTUtility.GetNewCode();
        Vendor."Vendor Posting Group" := VendorPostingGroup.Code;
        Vendor.Insert();
        exit(Vendor."No.")
    end;

    local procedure CreateVendorLedgerEntry(DocumentNo: Code[20]; VendorNo: Code[20]): Integer
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry2.FindLast();
        VendorLedgerEntry."Entry No." := VendorLedgerEntry2."Entry No." + 1;
        VendorLedgerEntry."Document No." := DocumentNo;
        VendorLedgerEntry."Document Type" := VendorLedgerEntry."Document Type"::Invoice;
        VendorLedgerEntry."Vendor No." := VendorNo;
        VendorLedgerEntry.Open := true;
        VendorLedgerEntry.Insert();
        exit(VendorLedgerEntry."Entry No.");
    end;

    local procedure CreateDetailedVendorLedgerEntry(VendorLedgerEntryNo: Integer): Decimal
    var
        DetailedVendorLedgerEntry: Record "Detailed Vendor Ledg. Entry";
        DetailedVendorLedgerEntry2: Record "Detailed Vendor Ledg. Entry";
    begin
        DetailedVendorLedgerEntry2.FindLast();
        DetailedVendorLedgerEntry."Entry No." := DetailedVendorLedgerEntry2."Entry No." + 1;
        DetailedVendorLedgerEntry."Vendor Ledger Entry No." := VendorLedgerEntryNo;
        DetailedVendorLedgerEntry."Amount (LCY)" := LibraryRandom.RandDec(10, 2);
        DetailedVendorLedgerEntry.Insert(true);
        exit(DetailedVendorLedgerEntry."Amount (LCY)");
    end;

    local procedure DequeueDocumentNoAndNumberOfCopies(var No: Variant; var NumberOfCopies: Variant)
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(NumberOfCopies);
    end;

    local procedure DequeuePrintCompanyAddress(var No: Variant; var PrintCompanyAddress: Variant)
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(PrintCompanyAddress);
    end;

    local procedure UpdatePurchaseHeaderTaxAreaCode(PurchaseHeader: Record "Purchase Header"; TaxAreaCode: Code[20])
    begin
        PurchaseHeader."Tax Area Code" := TaxAreaCode;
        PurchaseHeader.Modify();
    end;

    local procedure UpdatePurchaseLine(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; DocumentNo: Code[20])
    begin
        PurchaseLine.SetRange("Document Type", DocumentType);
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.FindFirst();
        PurchaseLine.Type := PurchaseLine.Type::Item;
        PurchaseLine."No." := LibraryUTUtility.GetNewCode();
        PurchaseLine.Quantity := LibraryRandom.RandDec(10, 2);
        PurchaseLine.Modify();
    end;

    local procedure OpenPurchaseBlanketOrderRequestPage(PurchaseBlanketOrder: TestRequestPage "Purchase Blanket Order"; No: Variant)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseBlanketOrder."Purchase Header".SetFilter("Document Type", Format(PurchaseHeader."Document Type"::"Blanket Order"));
        PurchaseBlanketOrder."Purchase Header".SetFilter("No.", No);
        PurchaseBlanketOrder.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    local procedure OpenPurchaseOrderRequestPage(PurchaseOrder: TestRequestPage "Purchase Order"; No: Variant)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseOrder."Purchase Header".SetFilter("Document Type", Format(PurchaseHeader."Document Type"::Order));
        PurchaseOrder."Purchase Header".SetFilter("No.", No);
        PurchaseOrder.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    local procedure OpenPurchaseQuoteRequestPage(var PurchaseQuote: TestRequestPage "Purchase Quote NA"; No: Variant)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseQuote."Purchase Header".SetFilter("Document Type", Format(PurchaseHeader."Document Type"::Quote));
        PurchaseQuote."Purchase Header".SetFilter("No.", No);
        PurchaseQuote.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    local procedure OpenPurchaseOrderPrePrintedRequestPage(var PurchaseOrderPrePrinted: TestRequestPage "Purchase Order (Pre-Printed)"; No: Variant)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseOrderPrePrinted."Purchase Header".SetFilter("Document Type", Format(PurchaseHeader."Document Type"::Order));
        PurchaseOrderPrePrinted."Purchase Header".SetFilter("No.", No);
        PurchaseOrderPrePrinted.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    local procedure OpenReturnOrderConfirmRequestPage(var ReturnOrderConfirm: TestRequestPage "Return Order Confirm"; No: Variant)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        ReturnOrderConfirm."Purchase Header".SetFilter("Document Type", Format(PurchaseHeader."Document Type"::"Return Order"));
        ReturnOrderConfirm."Purchase Header".SetFilter("No.", No);
        ReturnOrderConfirm.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    local procedure RunReportsPPForCompanyAddress(var ResponsibilityCenter: Record "Responsibility Center"; "Code": Code[10]; ReportID: Integer)
    begin
        ResponsibilityCenter.Get(Code);
        LibraryVariableStorage.Enqueue(true);  // Enqueue value for different Request Page Handler.
        Commit();  // Commit required as the explicit Commit used on OnRun Trigger of different Codeunits.
        REPORT.Run(ReportID);  // Opens handlers - PurchaseInvoiceRequestPageHandler, PurchaseCreditMemoRequestPageHandler, PurchaseReceiptRequestPageHandler Or ReturnShipmentRequestPageHandler.
    end;

    local procedure RunRepotsPPForNumberOfCopies(var NumberOfCopies: Integer; ReportID: Integer)
    begin
        NumberOfCopies := LibraryRandom.RandInt(10);
        LibraryVariableStorage.Enqueue(NumberOfCopies);  // Enqueue value required in different Request Page Handler.
        Commit();  // Commit required as the explicit Commit used on OnRun Trigger of different Codeunits.
        REPORT.Run(ReportID);  // Opens different handlers - NumberOfCopiesPurchaseInvoiceRequestPageHandler, NumberOfCopiesPurchaseCreditMemoRequestPageHandler or NumberOfCopiesPurchaseReceiptRequestPageHandler.
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseDocumentTestRequestPageHandler(var PurchaseDocumentTest: TestRequestPage "Purchase Document - Test")
    var
        PurchaseHeader: Record "Purchase Header";
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        PurchaseDocumentTest."Purchase Header".SetFilter("Document Type", Format(PurchaseHeader."Document Type"::Order));
        PurchaseDocumentTest."Purchase Header".SetFilter("No.", No);
        PurchaseDocumentTest.Summary.SetValue(true);
        PurchaseDocumentTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseBlanketOrderRequestPageHandler(var PurchaseBlanketOrder: TestRequestPage "Purchase Blanket Order")
    var
        No: Variant;
        PrintCompanyAddress: Variant;
    begin
        DequeuePrintCompanyAddress(No, PrintCompanyAddress);
        PurchaseBlanketOrder.PrintCompanyAddress.SetValue(PrintCompanyAddress);
        OpenPurchaseBlanketOrderRequestPage(PurchaseBlanketOrder, No);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure NumberOfCopiesPurchaseBlanketOrderRequestPageHandler(var PurchaseBlanketOrder: TestRequestPage "Purchase Blanket Order")
    var
        No: Variant;
        NumberOfCopies: Variant;
    begin
        DequeueDocumentNoAndNumberOfCopies(No, NumberOfCopies);
        PurchaseBlanketOrder.NumberOfCopies.SetValue(NumberOfCopies);
        OpenPurchaseBlanketOrderRequestPage(PurchaseBlanketOrder, No);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseOrderRequestPageHandler(var PurchaseOrder: TestRequestPage "Purchase Order")
    var
        No: Variant;
        PrintCompanyAddress: Variant;
    begin
        DequeuePrintCompanyAddress(No, PrintCompanyAddress);
        PurchaseOrder.PrintCompanyAddress.SetValue(PrintCompanyAddress);
        OpenPurchaseOrderRequestPage(PurchaseOrder, No);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure NumberOfCopiesPurchaseOrderRequestPageHandler(var PurchaseOrder: TestRequestPage "Purchase Order")
    var
        No: Variant;
        NumberOfCopies: Variant;
    begin
        DequeueDocumentNoAndNumberOfCopies(No, NumberOfCopies);
        PurchaseOrder.NumberOfCopies.SetValue(NumberOfCopies);
        OpenPurchaseOrderRequestPage(PurchaseOrder, No);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure NumberOfCopiesPurchaseQuoteRequestPageHandler(var PurchaseQuote: TestRequestPage "Purchase Quote NA")
    var
        No: Variant;
        NumberOfCopies: Variant;
    begin
        DequeueDocumentNoAndNumberOfCopies(No, NumberOfCopies);
        PurchaseQuote.NumberOfCopies.SetValue(NumberOfCopies);
        OpenPurchaseQuoteRequestPage(PurchaseQuote, No);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseOrderPrePrintedRequestPageHandler(var PurchaseOrderPrePrinted: TestRequestPage "Purchase Order (Pre-Printed)")
    var
        No: Variant;
        PrintCompanyAddress: Variant;
    begin
        DequeuePrintCompanyAddress(No, PrintCompanyAddress);
        PurchaseOrderPrePrinted.PrintCompanyAddress.SetValue(PrintCompanyAddress);
        OpenPurchaseOrderPrePrintedRequestPage(PurchaseOrderPrePrinted, No);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure NumberOfCopiesPurchOrdPrePrintedRequestPageHandler(var PurchaseOrderPrePrinted: TestRequestPage "Purchase Order (Pre-Printed)")
    var
        No: Variant;
        NumberOfCopies: Variant;
    begin
        DequeueDocumentNoAndNumberOfCopies(No, NumberOfCopies);
        PurchaseOrderPrePrinted.NumberOfCopies.SetValue(NumberOfCopies);
        OpenPurchaseOrderPrePrintedRequestPage(PurchaseOrderPrePrinted, No);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReturnOrderConfirmRequestPageHandler(var ReturnOrderConfirm: TestRequestPage "Return Order Confirm")
    var
        No: Variant;
        PrintCompanyAddress: Variant;
    begin
        DequeuePrintCompanyAddress(No, PrintCompanyAddress);
        ReturnOrderConfirm.PrintCompanyAddress.SetValue(PrintCompanyAddress);
        OpenReturnOrderConfirmRequestPage(ReturnOrderConfirm, No);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure NumberOfCopiesReturnOrderConfirmRequestPageHandler(var ReturnOrderConfirm: TestRequestPage "Return Order Confirm")
    var
        No: Variant;
        NumberOfCopies: Variant;
    begin
        DequeueDocumentNoAndNumberOfCopies(No, NumberOfCopies);
        ReturnOrderConfirm.NumberOfCopies.SetValue(NumberOfCopies);
        OpenReturnOrderConfirmRequestPage(ReturnOrderConfirm, No);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure OpenPurchaseInvoicesByJobRequestPageHandler(var OpenPurchaseInvoicesByJob: TestRequestPage "Open Purchase Invoices by Job")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        OpenPurchaseInvoicesByJob.Job.SetFilter("No.", No);
        OpenPurchaseInvoicesByJob.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

