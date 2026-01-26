#if not CLEAN27
codeunit 144003 "UT REP VAT REPORT"
{
    // Unit Test Cases for VATREP feature in various reports.
    // 
    // 1. Verify Data on XML after running Report 402 (Sales Document - Test) for Sales Order.
    // 2. Verify Data on XML after running Report 402 (Sales Document - Test) for Sales Invoice.
    // 
    // Covers Test Cases for WI - 339798
    // -------------------------------------------------------------------------------------------
    // Test Function Name                                                                  TFS ID
    // -------------------------------------------------------------------------------------------
    // OnPreDataItemSalesDocumentTestForOrder, OnPreDataItemSalesDocumentTestForInvoice    159784

    Subtype = Test;
    TestPermissions = Disabled;
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Reverse Charge VAT GB app';
    ObsoleteTag = '27.0';

    trigger OnRun()
    begin
    end;

    var
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";

    [Test]
    [HandlerFunctions('SalesDocumentTestRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemSalesDocumentTestForOrder()
    var
        SalesLine: Record "Sales Line";
    begin
        // Purpose of this test is to test OnPreDataItem Trigger of Report 202 (Sales Document - Test) for Sales Order.
        Initialize();
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
        // Purpose of this test is to test OnPreDataItem Trigger of Report 202 (Sales Document - Test) for Sales Invoice.
        Initialize();
        CreateSalesDocumentAndVerifySalesDocumentTest(SalesLine."Document Type"::Invoice);
    end;

    local procedure CreateSalesDocumentAndVerifySalesDocumentTest(DocumentType: Enum "Sales Document Type")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesLine: Record "Sales Line";
    begin
        // Setup.
        FindReverseChargeVATPostingSetup(VATPostingSetup);
        UpdateThresholdAppliesOnGLSetup();
        UpdateDomesticCustomersOnSalesReceivablesSetup(VATPostingSetup."VAT Bus. Posting Group");
        CreateSalesDocument(SalesLine, VATPostingSetup, DocumentType);
        LibraryVariableStorage.Enqueue(SalesLine."Document No.");  // Enqueue value for SalesDocumentTestRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Sales Document - Test");   // Open SalesDocumentTestRequestPageHandler.

        // Verify.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Sales_Line___VAT_Identifier_', VATPostingSetup."VAT Identifier");
        LibraryReportDataset.AssertElementWithValueExists('Sales_Line__Quantity', SalesLine.Quantity);
        LibraryReportDataset.AssertElementWithValueExists('Sales_Line___Unit_Price_', SalesLine."Unit Price");
        LibraryReportDataset.AssertElementWithValueExists(
          'Sales_Line___Line_Amount_', Round(SalesLine.Quantity * SalesLine."Unit Price"));
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateSalesDocument(var SalesLine: Record "Sales Line"; VATPostingSetup: Record "VAT Posting Setup"; DocumentType: Enum "Sales Document Type")
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader."Document Type" := DocumentType;
        SalesHeader."No." := LibraryUTUtility.GetNewCode();
        SalesHeader."Sell-to Customer No." := LibraryUTUtility.GetNewCode();
        SalesHeader."VAT Registration No." := SalesHeader."Sell-to Customer No.";
        SalesHeader."VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";
        SalesHeader.Insert();

        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        SalesLine."Line No." := LibraryRandom.RandInt(10);  // Random Line No.
        SalesLine.Type := SalesLine.Type::Item;
        SalesLine."No." := LibraryUTUtility.GetNewCode();
        SalesLine."VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";
        SalesLine."VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";
        SalesLine."Reverse Charge Item" := true;
        SalesLine.Quantity := LibraryRandom.RandDecInRange(10, 100, 2);  // Random Quantity.
        SalesLine."Qty. to Invoice" := SalesLine.Quantity;
        SalesLine."Unit Price" := LibraryRandom.RandDecInRange(100, 1000, 2);  // Random Unit Price.
        SalesLine.Insert();
    end;

    local procedure FindReverseChargeVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        VATPostingSetup.SetFilter("VAT Bus. Posting Group", '<>%1', '');
        VATPostingSetup.SetFilter("VAT Prod. Posting Group", '<>%1', '');
        VATPostingSetup.SetRange("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
        VATPostingSetup.FindFirst();
    end;

    local procedure UpdateDomesticCustomersOnSalesReceivablesSetup(DomesticCustomers: Code[20])
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Domestic Customers" := DomesticCustomers;
        SalesReceivablesSetup.Modify();
    end;

    local procedure UpdateThresholdAppliesOnGLSetup()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Threshold applies" := true;
        GeneralLedgerSetup.Modify();
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
}
#endif

