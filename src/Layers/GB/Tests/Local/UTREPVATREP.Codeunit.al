codeunit 144024 "UT REP VATREP"
{
    //  3 - 4. Purpose of this test is to validate Purchase Quote.
    //
    // Covers Test Cases for WI - 341554
    // -----------------------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                                   TFS ID
    // -----------------------------------------------------------------------------------------------------------------------------
    // OnAfterGetRecordPurchaseQuote

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Report] [VAT]
    end;

    var
#if not CLEAN27
        Assert: Codeunit Assert;
#endif
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
#if not CLEAN27
        ManualVATDifferenceCap: Label 'Manual_VAT_Difference';
        VATEntryAmountCap: Label 'VAT_Entry_Amount';

    [Test]
    [HandlerFunctions('PurchaseDocumentTestRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemPurchaseDocumentTestForOrder()
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // Purpose of this test is to validate OnPreDataItem Trigger of Report 402 Purchase Document - Test for Purchase Order.
        CreateAndVerifyPurchaseDocumentTest(PurchaseLine."Document Type"::Order);
    end;

    [Test]
    [HandlerFunctions('PurchaseDocumentTestRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemPurchaseDocumentTestForInvoice()
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // Purpose of this test is to validate OnPreDataItem Trigger of Report 402 Purchase Document - Test for Purchase Invoice.
        CreateAndVerifyPurchaseDocumentTest(PurchaseLine."Document Type"::Invoice);
    end;

    local procedure CreateAndVerifyPurchaseDocumentTest(DocumentType: Enum "Purchase Document Type")
    var
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Setup.
        Initialize();
        FindReverseChargeVATPostingSetup(VATPostingSetup);
        UpdateThresholdAppliesOnGLSetup();
        UpdateDomesticVendorsOnPurchasesPayablesSetup(VATPostingSetup."VAT Bus. Posting Group");
        CreatePurchaseDocument(PurchaseLine, VATPostingSetup, DocumentType);
        LibraryVariableStorage.Enqueue(PurchaseLine."Document No.");  // Enqueue value for PurchaseDocumentTestRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Purchase Document - Test");  // Open PurchaseDocumentTestRequestPageHandler.

        // Verify.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Purchase_Line___VAT_Identifier_', VATPostingSetup."VAT Identifier");
        LibraryReportDataset.AssertElementWithValueExists('Purchase_Line__Quantity', PurchaseLine.Quantity);
        LibraryReportDataset.AssertElementWithValueExists('Purchase_Line___Direct_Unit_Cost_', PurchaseLine."Direct Unit Cost");
        LibraryReportDataset.AssertElementWithValueExists(
          'Purchase_Line___Line_Amount_', Round(PurchaseLine.Quantity * PurchaseLine."Direct Unit Cost"));
    end;
#endif

    [Test]
    [HandlerFunctions('PurchaseQuoteRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPurchaseQuote()
    var
        ResponsibilityCenter: Record "Responsibility Center";
        No: Code[20];
    begin
        // Setup.
        Initialize();
        CreateResponsibilityCenter(ResponsibilityCenter);
        No := CreatePurchaseQuote(ResponsibilityCenter.Code);
        LibraryVariableStorage.Enqueue(No);  // Enqueue value for PurchaseQuoteRequestPageHandler.
        Commit();  // Commit required, because it is explicitly called by OnRun Trigger of Codeunit ID - 317 Purch.Header-Printed.

        // Exercise.
        REPORT.Run(REPORT::"Purchase - Quote");  // Open PurchaseQuoteRequestPageHandler.

        // Verify: Verify Purchase Quote No and Company Information Phone No on Report Purchase - Quote.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('PurchHeadNo', No);
        LibraryReportDataset.AssertElementWithValueExists('CompanyInfoPhoneNo', ResponsibilityCenter."Phone No.");
    end;

#if not CLEAN27
    [Test]
    [HandlerFunctions('SalesDocumentTestRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemSalesDocumentTestForOrder()
    var
        SalesLine: Record "Sales Line";
    begin
        // Purpose of this test is to test OnPreDataItem Trigger of Report 202 Sales Document - Test for Sales Order.
        CreateSalesDocumentAndVerifySalesDocumentTest(SalesLine."Document Type"::Order);
    end;

    [Test]
    [HandlerFunctions('SalesDocumentTestRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemSalesDocumentTestForInvoice()
    var
        SalesLine: Record "Sales Line";
    begin
        // Purpose of this test is to test OnPreDataItem Trigger of Report 202 Sales Document - Test for Sales Invoice.
        CreateSalesDocumentAndVerifySalesDocumentTest(SalesLine."Document Type"::Invoice);
    end;

    local procedure CreateSalesDocumentAndVerifySalesDocumentTest(DocumentType: Enum "Sales Document Type")
    var
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Setup.
        Initialize();
        FindReverseChargeVATPostingSetup(VATPostingSetup);
        UpdateThresholdAppliesOnGLSetup();
        UpdateDomesticCustomersOnSalesReceivablesSetup(VATPostingSetup."VAT Bus. Posting Group");
        CreateSalesDocument(SalesLine, VATPostingSetup, DocumentType);
        LibraryVariableStorage.Enqueue(SalesLine."Document No.");  // Enqueue value for SalesDocumentTestRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Sales Document - Test");  // Open SalesDocumentTestRequestPageHandler.

        // Verify.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Sales_Line___VAT_Identifier_', VATPostingSetup."VAT Identifier");
        LibraryReportDataset.AssertElementWithValueExists('Sales_Line__Quantity', SalesLine.Quantity);
        LibraryReportDataset.AssertElementWithValueExists('Sales_Line___Unit_Price_', SalesLine."Unit Price");
        LibraryReportDataset.AssertElementWithValueExists(
          'Sales_Line___Line_Amount_', Round(SalesLine.Quantity * SalesLine."Unit Price"));
    end;

    [Test]
    [HandlerFunctions('SalesInvoiceGBRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecSalesInvLineSalesInvoiceGB()
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        // Purpose of the test is to validate Sales Invoice Line - OnAfterGetRecord Trigger of Report 10572 - "Sales - Invoice GB".
        // Setup.
        Initialize();
        CreateSalesInvoice(SalesInvoiceLine);
        LibraryVariableStorage.Enqueue(SalesInvoiceLine."Document No.");  // Enqueue value required for SalesInvoiceGBRequestPageHandler.
        Commit();  // Commit required as it is called explicitly from OnRun function of Codeunit 315 Sales Inv.-Printed.

        // Exercise And Verify.
        RunReportAndVerifyXMLData(
          REPORT::"Sales - Invoice GB", 'No_SalesInvcHeader', SalesInvoiceLine."Document No.", SalesInvoiceLine."Reverse Charge");
    end;

    [Test]
    [HandlerFunctions('SalesCreditMemoGBRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecSalesCrMemoLineSalesCrMemoGB()
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
    begin
        // Purpose of the test is to validate Sales Cr. Memo Line - OnAfterGetRecord Trigger of Report 10573 - "Sales - Credit Memo GB".
        // Setup.
        Initialize();
        CreateSalesCrMemo(SalesCrMemoLine);
        LibraryVariableStorage.Enqueue(SalesCrMemoLine."Document No.");  // Enqueue value required for SalesCreditMemoGBRequestPageHandler.
        Commit();  // Commit required as it is called explicitly from OnRun function of Codeunit 316 Sales Cr. Memo-Printed.

        // Exercise And Verify.
        RunReportAndVerifyXMLData(
          REPORT::"Sales - Credit Memo GB", 'No_SalesCrMemoHeader', SalesCrMemoLine."Document No.", SalesCrMemoLine."Reverse Charge");
    end;

    [Test]
    [HandlerFunctions('VATEntryExceptionReportRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportVATEntryExceptionReportError()
    begin
        // Purpose of the test is to validate OnPreReport Trigger of Report 10511 - VAT Entry Exception Report.

        // Setup.
        Initialize();

        // Exercise.
        asserterror REPORT.Run(REPORT::"VAT Entry Exception Report");

        // Verify: Verify error 'No checking selected'.
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [HandlerFunctions('VATEntryExceptionReportWithVATRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordVATEntryWithoutBaseVATEntryExceptionReport()
    var
        VATEntry: Record "VAT Entry";
    begin
        // Purpose of the test is to validate OnAfterGetRecord Trigger of Report 10511 - VAT Entry Exception Report with Zero Base.

        // Setup.
        Initialize();
        CreateVATEntry(VATEntry, VATEntry.Type::Purchase, 0, '', '', CreateVendor());  // Taken Zero for Base and blank for VATProdPostingGroup, VATBusPostingGroup.
        LibraryVariableStorage.Enqueue(VATEntry."Document No.");  // Enqueue for VATEntryExceptionReportRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"VAT Entry Exception Report");

        // Verify.
        VerifyValuesOnReport(ManualVATDifferenceCap, VATEntryAmountCap, VATEntry."VAT Difference", VATEntry.Amount)
    end;

    [Test]
    [HandlerFunctions('VATEntryExceptionReportWithVATRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordVATEntryWithBaseVATEntryExceptionReport()
    var
        VATEntry: Record "VAT Entry";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Purpose of the test is to validate OnAfterGetRecord Trigger of Report 10511 - VAT Entry Exception Report with Random Base.

        // Setup.
        Initialize();
        FindVATPostingSetup(VATPostingSetup);
        CreateVATEntry(
          VATEntry, VATEntry.Type::Purchase, LibraryRandom.RandDec(10, 2),
          VATPostingSetup."VAT Prod. Posting Group", VATPostingSetup."VAT Bus. Posting Group", CreateVendor());  // Taken random for Base.
        LibraryVariableStorage.Enqueue(VATEntry."Document No.");  // Enqueue for VATEntryExceptionReportRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"VAT Entry Exception Report");

        // Verify.
        VerifyValuesOnReport(ManualVATDifferenceCap, VATEntryAmountCap, VATEntry."VAT Difference", VATEntry.Amount)
    end;
#endif

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

#if not CLEAN27
    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        Customer."No." := LibraryUTUtility.GetNewCode();
        Customer.Insert();
        exit(Customer."No.");
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        Item."No." := LibraryUTUtility.GetNewCode();
        Item.Insert();
        exit(Item."No.");
    end;
#endif

    local procedure CreatePurchaseQuote(ResponsibilityCenter: Code[10]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::Quote;
        PurchaseHeader."No." := LibraryUTUtility.GetNewCode();
        PurchaseHeader."Buy-from Vendor No." := LibraryUTUtility.GetNewCode();
        PurchaseHeader."Vendor Invoice No." := LibraryUTUtility.GetNewCode();
        PurchaseHeader."Responsibility Center" := ResponsibilityCenter;
        PurchaseHeader.Insert();
        PurchaseLine."Document No." := PurchaseHeader."No.";
        PurchaseLine.Quantity := LibraryRandom.RandDec(10, 2);
        PurchaseLine."Amount Including VAT" := LibraryRandom.RandDec(10, 2);
        PurchaseLine.Insert();
        exit(PurchaseHeader."No.");
    end;

#if not CLEAN27
    local procedure CreatePurchaseDocument(var PurchaseLine: Record "Purchase Line"; VATPostingSetup: Record "VAT Posting Setup"; DocumentType: Enum "Purchase Document Type")
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader."Document Type" := DocumentType;
        PurchaseHeader."No." := LibraryUTUtility.GetNewCode();
        PurchaseHeader."Buy-from Vendor No." := CreateVendor();
        PurchaseHeader."Pay-to Vendor No." := PurchaseHeader."Buy-from Vendor No.";
        PurchaseHeader."VAT Registration No." := PurchaseHeader."Buy-from Vendor No.";
        PurchaseHeader."VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";
        PurchaseHeader."Posting Date" := WorkDate();
        PurchaseHeader.Insert();

        PurchaseLine."Document Type" := PurchaseHeader."Document Type";
        PurchaseLine."Document No." := PurchaseHeader."No.";
        PurchaseLine."Line No." := LibraryRandom.RandInt(10);
        PurchaseLine.Type := PurchaseLine.Type::Item;
        PurchaseLine."No." := CreateItem();
        PurchaseLine."VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";
        PurchaseLine."Reverse Charge Item" := true;
        PurchaseLine.Quantity := LibraryRandom.RandDecInRange(10, 100, 2);
        PurchaseLine."Qty. to Invoice" := PurchaseLine.Quantity;
        PurchaseLine."Direct Unit Cost" := LibraryRandom.RandDecInRange(100, 1000, 2);
        PurchaseLine."VAT Identifier" := VATPostingSetup."VAT Identifier";
        PurchaseLine.Insert();
    end;
#endif

    local procedure CreateResponsibilityCenter(var ResponsibilityCenter: Record "Responsibility Center")
    begin
        ResponsibilityCenter.Code := LibraryUTUtility.GetNewCode10();
        ResponsibilityCenter."Phone No." := LibraryUTUtility.GetNewCode();
        ResponsibilityCenter.Insert();
    end;

#if not CLEAN27
    local procedure CreateSalesCrMemo(var SalesCrMemoLine: Record "Sales Cr.Memo Line")
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        SalesCrMemoHeader."No." := LibraryUTUtility.GetNewCode();
        SalesCrMemoHeader."Sell-to Customer No." := CreateCustomer();
        SalesCrMemoHeader."Bill-to Customer No." := SalesCrMemoHeader."Sell-to Customer No.";
        SalesCrMemoHeader.Insert();
        SalesCrMemoLine."Document No." := SalesCrMemoHeader."No.";
        SalesCrMemoLine.Amount := LibraryRandom.RandDecInRange(0, 10, 2);
        SalesCrMemoLine."Amount Including VAT" := LibraryRandom.RandDecInRange(10, 50, 2);
        SalesCrMemoLine."Reverse Charge" := SalesCrMemoLine."Amount Including VAT" - SalesCrMemoLine.Amount;
        SalesCrMemoLine.Insert();
    end;

    local procedure CreateSalesDocument(var SalesLine: Record "Sales Line"; VATPostingSetup: Record "VAT Posting Setup"; DocumentType: Enum "Sales Document Type")
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader."Document Type" := DocumentType;
        SalesHeader."No." := LibraryUTUtility.GetNewCode();
        SalesHeader."Sell-to Customer No." := CreateCustomer();
        SalesHeader."VAT Registration No." := SalesHeader."Sell-to Customer No.";
        SalesHeader."VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";
        SalesHeader.Insert();

        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        SalesLine."Line No." := LibraryRandom.RandInt(10);
        SalesLine.Type := SalesLine.Type::Item;
        SalesLine."No." := CreateItem();
        SalesLine."VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";
        SalesLine."VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";
        SalesLine."Reverse Charge Item" := true;
        SalesLine.Quantity := LibraryRandom.RandDecInRange(10, 100, 2);
        SalesLine."Qty. to Invoice" := SalesLine.Quantity;
        SalesLine."Unit Price" := LibraryRandom.RandDecInRange(100, 1000, 2);
        SalesLine.Insert();
    end;

    local procedure CreateSalesInvoice(var SalesInvoiceLine: Record "Sales Invoice Line")
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader."No." := LibraryUTUtility.GetNewCode();
        SalesInvoiceHeader."Sell-to Customer No." := CreateCustomer();
        SalesInvoiceHeader."Bill-to Customer No." := SalesInvoiceHeader."Sell-to Customer No.";
        SalesInvoiceHeader.Insert();
        SalesInvoiceLine."Document No." := SalesInvoiceHeader."No.";
        SalesInvoiceLine.Amount := LibraryRandom.RandDecInRange(0, 10, 2);
        SalesInvoiceLine."Amount Including VAT" := LibraryRandom.RandDecInRange(10, 50, 2);
        SalesInvoiceLine."Reverse Charge" := SalesInvoiceLine."Amount Including VAT" - SalesInvoiceLine.Amount;
        SalesInvoiceLine.Insert();
    end;

    local procedure CreateVATEntry(var VATEntry: Record "VAT Entry"; Type: Enum "General Posting Type"; Base: Decimal; VATProdPostingSetup: Code[20]; VATBusPostingSetup: Code[20]; BillToPayToNo: Code[20])
    var
        VATEntry2: Record "VAT Entry";
    begin
        VATEntry2.FindLast();
        VATEntry."Entry No." := VATEntry2."Entry No." + 1;
        VATEntry.Type := Type;
        VATEntry."Bill-to/Pay-to No." := BillToPayToNo;
        VATEntry."Document No." := LibraryUTUtility.GetNewCode();
        VATEntry."VAT Bus. Posting Group" := VATBusPostingSetup;
        VATEntry."VAT Prod. Posting Group" := VATProdPostingSetup;
        VATEntry.Base := Base;
        VATEntry."VAT Base Discount %" := LibraryRandom.RandDec(10, 2);
        VATEntry."VAT Difference" := LibraryRandom.RandDec(10, 2);
        VATEntry.Amount := LibraryRandom.RandDec(10, 2);
        VATEntry."Posting Date" := WorkDate();
        VATEntry.Insert();
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        Vendor."No." := LibraryUTUtility.GetNewCode();
        Vendor.Insert();
        exit(Vendor."No.");
    end;

    local procedure FindReverseChargeVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        VATPostingSetup.SetFilter("VAT Bus. Posting Group", '<>%1', '');
        VATPostingSetup.SetFilter("VAT Prod. Posting Group", '<>%1', '');
        VATPostingSetup.SetRange("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
        VATPostingSetup.FindFirst();
    end;

    local procedure FindVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        VATPostingSetup.SetFilter("VAT Bus. Posting Group", '<>''''');
        VATPostingSetup.SetFilter("VAT Prod. Posting Group", '<>''''');
        VATPostingSetup.SetRange("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.SetFilter("VAT %", '>0');
        VATPostingSetup.FindFirst();
    end;

    local procedure RunReportAndVerifyXMLData(ReportID: Option; SalesDocumentCap: Text[30]; DocumentNo: Code[20]; ReverseCharge: Decimal)
    begin
        // Exercise.
        REPORT.Run(ReportID);  // Open SalesInvoiceGBReqPageHandler, SalesCreditMemoGBRequestPageHandler.

        // Verify: Verify No, Reverse Charge on Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(SalesDocumentCap, DocumentNo);
        LibraryReportDataset.AssertElementWithValueExists('TotalReverseCharge', ReverseCharge);
        // BUG 279809
        LibraryReportDataset.AssertElementWithValueExists('TotalReverseChargeVATCaption', 'Total Reverse Charge VAT');
    end;

    local procedure SaveAsXMLVATEntryExceptionReport(var VATEntryExceptionReport: TestRequestPage "VAT Entry Exception Report"; VATBaseDiscount: Boolean; ManualVATDifference: Boolean; VATCalculationTypes: Boolean; VATRate: Boolean)
    begin
        VATEntryExceptionReport.VATBaseDiscount.SetValue(VATBaseDiscount);
        VATEntryExceptionReport.ManualVATDifference.SetValue(ManualVATDifference);
        VATEntryExceptionReport.VATCalculationTypes.SetValue(VATCalculationTypes);
        VATEntryExceptionReport.VATRate.SetValue(VATRate);
        VATEntryExceptionReport.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    local procedure UpdateDomesticCustomersOnSalesReceivablesSetup(DomesticCustomers: Code[20])
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Domestic Customers" := DomesticCustomers;
        SalesReceivablesSetup.Modify();
    end;

    local procedure UpdateDomesticVendorsOnPurchasesPayablesSetup(DomesticVendors: Code[20])
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup."Domestic Vendors" := DomesticVendors;
        PurchasesPayablesSetup."Reverse Charge VAT Posting Gr." := PurchasesPayablesSetup."Domestic Vendors";
        PurchasesPayablesSetup."Posting Date Check on Posting" := true;
        PurchasesPayablesSetup."Default Posting Date" := PurchasesPayablesSetup."Default Posting Date"::"No Date";
        PurchasesPayablesSetup.Modify();
    end;

    local procedure UpdateThresholdAppliesOnGLSetup()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Threshold applies" := true;
        GeneralLedgerSetup.Modify();
    end;

    local procedure VerifyValuesOnReport(ElementName: Text; ElementName2: Text; ExpectedValue: Variant; ExpectedValue2: Variant)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(ElementName, ExpectedValue);
        LibraryReportDataset.AssertElementWithValueExists(ElementName2, ExpectedValue2);
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
#endif

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseQuoteRequestPageHandler(var PurchaseQuote: TestRequestPage "Purchase - Quote")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        PurchaseQuote."Purchase Header".SetFilter("No.", No);
        PurchaseQuote.LogInteraction.SetValue(true);
        PurchaseQuote.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

#if not CLEAN27
    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesCreditMemoGBRequestPageHandler(var SalesCreditMemoGB: TestRequestPage "Sales - Credit Memo GB")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        SalesCreditMemoGB."Sales Cr.Memo Header".SetFilter("No.", No);
        SalesCreditMemoGB.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
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
    procedure SalesInvoiceGBRequestPageHandler(var SalesInvoiceGB: TestRequestPage "Sales - Invoice GB")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        SalesInvoiceGB."Sales Invoice Header".SetFilter("No.", No);
        SalesInvoiceGB.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VATEntryExceptionReportWithVATRequestPageHandler(var VATEntryExceptionReport: TestRequestPage "VAT Entry Exception Report")
    var
        DocumentNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNo);
        VATEntryExceptionReport."VAT Entry".SetFilter("Document No.", DocumentNo);
        SaveAsXMLVATEntryExceptionReport(VATEntryExceptionReport, true, true, true, true);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VATEntryExceptionReportRequestPageHandler(var VATEntryExceptionReport: TestRequestPage "VAT Entry Exception Report")
    begin
        SaveAsXMLVATEntryExceptionReport(VATEntryExceptionReport, false, false, false, false);
    end;
#endif
}
