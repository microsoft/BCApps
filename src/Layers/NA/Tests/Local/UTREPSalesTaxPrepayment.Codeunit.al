codeunit 142069 "UT REP Sales Tax Prepayment"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Sales Tax] [Prepayment] [Reports]
    end;

    var
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryERM: Codeunit "Library - ERM";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        DimTextCap: Label 'DimText';
        FORMATPurchaseHeaderPrepmtIncludeTaxCap: Label 'FORMAT__Purchase_Header___Prepmt__Include_Tax__';
        PrepaymentCreditMemoCap: Label 'Prepayment Credit Memo';
        PrepaymentInvoiceCap: Label 'Prepayment Invoice';
        PurchaseLinePrepmtLineAmountCap: Label 'Purchase_Line___Prepmt__Line_Amount_';
        SalesHeaderPrepmtIncludeTaxCap: Label 'Sales_Header___Prepmt__Include_Tax_';
        SalesLinePrepmtLineAmountCap: Label 'Sales_Line___Prepmt__Line_Amount_';

    [Test]
    [HandlerFunctions('PurchasePrepmtDocTestRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemForPrepmtInvCodePurchasePrepmtDocTest()
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // The purpose of the test is to verify trigger OnPreDataItem - Purchase Line without tax and show dimension as false for Invoice of Report 412.

        // Setup.
        CreatePurchaseSetup(PurchaseLine, 0, '', '', false, false);  // Using 0 for Invoice.

        // Exercise.
        REPORT.Run(REPORT::"Purchase Prepmt. Doc. - Test");

        // Verify.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(PurchaseLinePrepmtLineAmountCap, PurchaseLine."Prepmt. Line Amount");
    end;

    [Test]
    [HandlerFunctions('PurchasePrepmtDocTestRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemWithDimPrepmtInvPurchasePrepmtDocTest()
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // The purpose of the test is to verify trigger OnPreDataItem - Purchase Line without tax and show dimension as true for Invoice of Report 412.

        // Setup.
        CreatePurchaseSetup(PurchaseLine, 0, '', '', false, true);  // Using 0 for Invoice.

        // Exercise.
        REPORT.Run(REPORT::"Purchase Prepmt. Doc. - Test");

        // Verify.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(PurchaseLinePrepmtLineAmountCap, PurchaseLine."Prepmt. Line Amount");
        LibraryReportDataset.AssertElementWithValueExists(DimTextCap, FindDimensionCode(PurchaseLine.Area));
    end;

    [Test]
    [HandlerFunctions('PurchasePrepmtDocTestRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemInclTaxForInvoicePurchPrepmtDocTest()
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // The purpose of the test is to verify trigger OnPreDataItem - Purchase Line with tax for Invoice of Report 412.

        // Setup.
        CreatePurchaseSetup(PurchaseLine, 0, CreateTaxArea(), LibraryUTUtility.GetNewCode10(), true, false);  // Using 0 for Invoice.

        // Exercise.
        REPORT.Run(REPORT::"Purchase Prepmt. Doc. - Test");

        // Verify.
        LibraryReportDataset.LoadDataSetFile();
        VerifyPrepaymentValues(PrepaymentInvoiceCap, FORMATPurchaseHeaderPrepmtIncludeTaxCap);
    end;

    [Test]
    [HandlerFunctions('PurchasePrepmtDocTestRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemInclTaxForCreMemoPurchPrepmtDocTest()
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // The purpose of the test is to verify trigger OnPreDataItem - Purchase Line with tax for Credit Memo of Report 412.

        // Setup.
        CreatePurchaseSetup(PurchaseLine, 1, CreateTaxArea(), LibraryUTUtility.GetNewCode10(), true, false);  // Using 1 for Credit Memo.

        // Exercise.
        REPORT.Run(REPORT::"Purchase Prepmt. Doc. - Test");

        // Verify.
        LibraryReportDataset.LoadDataSetFile();
        VerifyPrepaymentValues(PrepaymentCreditMemoCap, FORMATPurchaseHeaderPrepmtIncludeTaxCap);
    end;

    [Test]
    [HandlerFunctions('PurchasePrepmtDocTestRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemInclTaxDimCreMemoPurchPrepmtDocTest()
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // The purpose of the test is to verify trigger OnPreDataItem - Purchase Line with tax and Show dimension as true for Credit Memo of Report 412.

        // Setup.
        CreatePurchaseSetup(PurchaseLine, 1, CreateTaxArea(), LibraryUTUtility.GetNewCode10(), true, true);  // Using 1 for Credit Memo.

        // Exercise.
        REPORT.Run(REPORT::"Purchase Prepmt. Doc. - Test");

        // Verify.
        LibraryReportDataset.LoadDataSetFile();
        VerifyPrepaymentValues(PrepaymentCreditMemoCap, FORMATPurchaseHeaderPrepmtIncludeTaxCap);
        LibraryReportDataset.AssertElementWithValueExists(DimTextCap, FindDimensionCode(PurchaseLine.Area));
    end;

    [Test]
    [HandlerFunctions('SalesPrepmtDocTestRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemForPrepmtInvCodeSalesPrepmtDocTest()
    var
        SalesLine: Record "Sales Line";
    begin
        // The purpose of the test is to verify trigger OnPreDataItem - Sales Line without tax and show dimension as false for Invoice of Report 212.

        // Setup.
        CreateSalesSetup(SalesLine, 0, '', '', false, false);  // Using 0 for Invoice.

        // Exercise.
        REPORT.Run(REPORT::"Sales Prepmt. Document Test");

        // Verify.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(SalesLinePrepmtLineAmountCap, SalesLine."Prepmt. Line Amount");
    end;

    [Test]
    [HandlerFunctions('SalesPrepmtDocTestRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemWithDimPrepmtInvSalesPrepmtDocTest()
    var
        SalesLine: Record "Sales Line";
    begin
        // The purpose of the test is to verify trigger OnPreDataItem - Sales Line without tax and show dimension as true for Invoice of Report 212.

        // Setup.
        CreateSalesSetup(SalesLine, 0, '', '', false, true);  // Using 0 for Invoice.

        // Exercise.
        REPORT.Run(REPORT::"Sales Prepmt. Document Test");

        // Verify.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(SalesLinePrepmtLineAmountCap, SalesLine."Prepmt. Line Amount");
        LibraryReportDataset.AssertElementWithValueExists(DimTextCap, FindDimensionCode(SalesLine.Area));
    end;

    [Test]
    [HandlerFunctions('SalesPrepmtDocTestRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemInclTaxForInvoiceSalesPrepmtDocTest()
    var
        SalesLine: Record "Sales Line";
    begin
        // The purpose of the test is to verify trigger OnPreDataItem - Sales Line with tax for Invoice of Report 212.

        // Setup.
        CreateSalesSetup(SalesLine, 0, CreateTaxArea(), LibraryUTUtility.GetNewCode10(), true, false);  // Using 0 for Invoice.

        // Exercise.
        REPORT.Run(REPORT::"Sales Prepmt. Document Test");

        // Verify.
        LibraryReportDataset.LoadDataSetFile();
        VerifyPrepaymentValues(PrepaymentInvoiceCap, SalesHeaderPrepmtIncludeTaxCap);
    end;

    [Test]
    [HandlerFunctions('SalesPrepmtDocTestRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemInclTaxForCreMemoSalesPrepmtDocTest()
    var
        SalesLine: Record "Sales Line";
    begin
        // The purpose of the test is to verify trigger OnPreDataItem - Sales Line with tax for Credit Memo of Report 212.

        // Setup.
        CreateSalesSetup(SalesLine, 1, CreateTaxArea(), LibraryUTUtility.GetNewCode10(), true, false);  // Using 1 for Credit Memo.

        // Exercise.
        REPORT.Run(REPORT::"Sales Prepmt. Document Test");

        // Verify.
        LibraryReportDataset.LoadDataSetFile();
        VerifyPrepaymentValues(PrepaymentCreditMemoCap, SalesHeaderPrepmtIncludeTaxCap);
    end;

    [Test]
    [HandlerFunctions('SalesPrepmtDocTestRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemInclTaxDimCreMemoSalesPrepmtDocTest()
    var
        SalesLine: Record "Sales Line";
    begin
        // The purpose of the test is to verify trigger OnPreDataItem - Sales Line with tax and Show dimension as true for Credit Memo of Report 212.

        // Setup.
        CreateSalesSetup(SalesLine, 1, CreateTaxArea(), LibraryUTUtility.GetNewCode10(), true, true);  // Using 1 for Credit Memo.

        // Exercise.
        REPORT.Run(REPORT::"Sales Prepmt. Document Test");

        // Verify.
        LibraryReportDataset.LoadDataSetFile();
        VerifyPrepaymentValues(PrepaymentCreditMemoCap, SalesHeaderPrepmtIncludeTaxCap);
        LibraryReportDataset.AssertElementWithValueExists(DimTextCap, FindDimensionCode(SalesLine.Area));
    end;

    local procedure CreateDimensionCode(): Code[20]
    var
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        DimensionSetEntry."Dimension Code" := LibraryUTUtility.GetNewCode10();
        DimensionSetEntry."Dimension Value Code" := LibraryUTUtility.GetNewCode10();
        DimensionSetEntry.Insert();
        exit(DimensionSetEntry."Dimension Code");
    end;

    local procedure CreatePurchaseDocument(var PurchaseLine: Record "Purchase Line"; TaxAreaCode: Code[20]; TaxGroupCode: Code[20]; PrepmtIncludeTax: Boolean)
    var
        GeneralPostingSetup: Record "General Posting Setup";
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader."No." := LibraryUTUtility.GetNewCode();
        PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::Order;
        PurchaseHeader."Buy-from Vendor No." := LibraryUTUtility.GetNewCode();
        PurchaseHeader."Tax Area Code" := TaxAreaCode;
        PurchaseHeader."Prepayment %" := LibraryRandom.RandInt(10);
        PurchaseHeader."Posting Date" := WorkDate();
        PurchaseHeader."Prepmt. Include Tax" := PrepmtIncludeTax;
        PurchaseHeader.Area := CreateDimensionCode();
        PurchaseHeader.Insert();
        PurchaseLine."Document Type" := PurchaseHeader."Document Type";
        PurchaseLine."Document No." := PurchaseHeader."No.";
        PurchaseLine."Line No." := LibraryRandom.RandInt(10);
        PurchaseLine."Buy-from Vendor No." := PurchaseHeader."Buy-from Vendor No.";
        PurchaseLine.Type := PurchaseLine.Type::Item;
        PurchaseLine."No." := LibraryUTUtility.GetNewCode();
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        PurchaseLine."Gen. Bus. Posting Group" := GeneralPostingSetup."Gen. Bus. Posting Group";
        PurchaseLine."Gen. Prod. Posting Group" := GeneralPostingSetup."Gen. Prod. Posting Group";
        PurchaseLine.Area := PurchaseHeader.Area;
        PurchaseLine."Line Amount" := LibraryRandom.RandDec(1000, 2);
        PurchaseLine."Prepayment %" := PurchaseHeader."Prepayment %";
        PurchaseLine."Prepmt. Line Amount" := PurchaseLine."Line Amount" * PurchaseLine."Prepayment %" / 100;
        PurchaseLine."Tax Group Code" := TaxGroupCode;
        PurchaseLine.Insert();
    end;

    local procedure CreatePurchaseSetup(var PurchaseLine: Record "Purchase Line"; PrepaymentDocumentType: Option; TaxAreaCode: Code[20]; TaxGroupCode: Code[20]; IncludeTax: Boolean; ShowDimensions: Boolean)
    begin
        CreatePurchaseDocument(PurchaseLine, TaxAreaCode, TaxGroupCode, IncludeTax);
        EnqueueValuesForPrepmtTestReport(PurchaseLine."Document No.", PrepaymentDocumentType, ShowDimensions);
    end;

    local procedure CreateSalesSetup(var SalesLine: Record "Sales Line"; PrepaymentDocumentType: Option; TaxAreaCode: Code[20]; TaxGroupCode: Code[20]; IncludeTax: Boolean; ShowDimensions: Boolean)
    begin
        CreateSalesDocument(SalesLine, TaxAreaCode, TaxGroupCode, IncludeTax);
        EnqueueValuesForPrepmtTestReport(SalesLine."Document No.", PrepaymentDocumentType, ShowDimensions);
    end;

    local procedure CreateSalesDocument(var SalesLine: Record "Sales Line"; TaxAreaCode: Code[20]; TaxGroupCode: Code[20]; PrepmtIncludeTax: Boolean)
    var
        GeneralPostingSetup: Record "General Posting Setup";
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader."No." := LibraryUTUtility.GetNewCode();
        SalesHeader."Document Type" := SalesHeader."Document Type"::Order;
        SalesHeader."Sell-to Customer No." := LibraryUTUtility.GetNewCode();
        SalesHeader."Tax Area Code" := TaxAreaCode;
        SalesHeader."Prepayment %" := LibraryRandom.RandInt(10);
        SalesHeader."Posting Date" := WorkDate();
        SalesHeader."Document Date" := WorkDate();
        SalesHeader."Prepayment Due Date" := WorkDate();
        SalesHeader."Prepmt. Include Tax" := PrepmtIncludeTax;
        SalesHeader.Area := CreateDimensionCode();
        SalesHeader.Insert();
        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        SalesLine."Line No." := LibraryRandom.RandInt(10);
        SalesLine."Sell-to Customer No." := SalesHeader."Sell-to Customer No.";
        SalesLine.Type := SalesLine.Type::Item;
        SalesLine."No." := LibraryUTUtility.GetNewCode();
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        SalesLine."Gen. Bus. Posting Group" := GeneralPostingSetup."Gen. Bus. Posting Group";
        SalesLine."Gen. Prod. Posting Group" := GeneralPostingSetup."Gen. Prod. Posting Group";
        SalesLine.Area := SalesHeader.Area;
        SalesLine."Line Amount" := LibraryRandom.RandDec(1000, 2);
        SalesLine."Prepayment %" := SalesHeader."Prepayment %";
        SalesLine."Prepmt. Line Amount" := SalesLine."Line Amount" * SalesLine."Prepayment %" / 100;
        SalesLine."Tax Group Code" := TaxGroupCode;
        SalesLine.Insert();
    end;

    local procedure CreateTaxArea(): Code[20]
    var
        TaxArea: Record "Tax Area";
    begin
        TaxArea.Code := LibraryUTUtility.GetNewCode();
        TaxArea.Insert();
        exit(TaxArea.Code);
    end;

    local procedure EnqueueValuesForPrepmtTestReport(DocumentNo: Variant; PrepaymentDocumentType: Variant; ShowDimensions: Variant)
    begin
        LibraryVariableStorage.Enqueue(DocumentNo);  // Enqueue value required in PurchasePrepmtDocTestRequestPageHandler/SalesPrepmtDocTestRequestPageHandler.
        LibraryVariableStorage.Enqueue(PrepaymentDocumentType);
        LibraryVariableStorage.Enqueue(ShowDimensions);
    end;

    local procedure FindDimensionCode(DimensionCode: Code[20]) DimText: Text[250]
    var
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        DimensionSetEntry.SetRange("Dimension Code", DimensionCode);
        DimensionSetEntry.FindFirst();
        DimText := StrSubstNo('%1 - %2', DimensionSetEntry."Dimension Code", DimensionSetEntry."Dimension Value Code");
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchasePrepmtDocTestRequestPageHandler(var PurchasePrepmtDocTest: TestRequestPage "Purchase Prepmt. Doc. - Test")
    var
        No: Variant;
        PrepaymentDocumentType: Variant;
        ShowDimensions: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(PrepaymentDocumentType);
        LibraryVariableStorage.Dequeue(ShowDimensions);
        PurchasePrepmtDocTest."Purchase Header".SetFilter("No.", No);
        PurchasePrepmtDocTest.PrepaymentDocumentType.SetValue(PrepaymentDocumentType);
        PurchasePrepmtDocTest.ShowDimensions.SetValue(ShowDimensions);
        PurchasePrepmtDocTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesPrepmtDocTestRequestPageHandler(var SalesPrepmtDocumentTest: TestRequestPage "Sales Prepmt. Document Test")
    var
        No: Variant;
        PrepaymentDocumentType: Variant;
        ShowDimensions: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(PrepaymentDocumentType);
        LibraryVariableStorage.Dequeue(ShowDimensions);
        SalesPrepmtDocumentTest."Sales Header".SetFilter("No.", No);
        SalesPrepmtDocumentTest.PrepaymentDocumentType.SetValue(PrepaymentDocumentType);
        SalesPrepmtDocumentTest.ShowDimensions.SetValue(ShowDimensions);
        SalesPrepmtDocumentTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    local procedure VerifyPrepaymentValues(PrepaymentValue: Text[250]; PrepmtIncludeTaxCap: Text[250])
    begin
        LibraryReportDataset.AssertElementWithValueExists(PrepmtIncludeTaxCap, 'Yes');
        LibraryReportDataset.AssertElementWithValueExists('PrepmtDocText', PrepaymentValue);
    end;
}

