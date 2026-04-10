codeunit 134999 "ERM Excel Reports"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Save As Excel]
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        EvaluateErr: Label 'Value %1 cannot be converted to decimal.';
        IncorrectTotalBalanceLCYErr: Label 'Incorrect total balance LCY value.';
        CellValueNotFoundErr: Label 'Excel cell (row=%1, column=%2) value is not found.';
        TotalLCYCap: Label 'Total (LCY)';
        VATAmtSpecCaptionTxt: Label 'VAT Amount Specification';
        VATSpecExistsErr: Label 'VAT specification section exists for line without VAT.';
        ShiptoAddressCaptionTxt: Label 'Ship-to Address';
        NoVATSpecLineErr: Label 'VAT spec line not found in report.';
        AmountMustBeSpecifiedTxt: Label 'Amount must be specified.';
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure GeneralJournalTestTotalBalance()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Total Balance printing by General Journal Test Report (bug 333253)

        // Setup.
        Initialize();
        Create2GenJnlLines(GenJournalLine);

        // Exercise: Save General Journal Test Report to Excel.
        RunReportGeneralJournalTest(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name");

        // Verify: Verify Total Balance value
        VerifyGeneralJournalTestTotalBalance();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderReport_PositiveVATAmt_VATLineExists()
    begin
        ValidatePurchaseOrderReportWithVAT(1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderReport_NegativeVATAmt_VATLineExists()
    begin
        ValidatePurchaseOrderReportWithVAT(-1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderReport_ZeroVATAmt_NoVATLines()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        Item: Record Item;
    begin
        Initialize();
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        PurchaseHeader.Validate("Prices Including VAT", false);
        LibraryERM.FindZeroVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        PurchaseHeader.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        PurchaseHeader.Modify(true);
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Item.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);

        SavePurchaseOrderReportAsExcel(PurchaseHeader);

        Assert.IsFalse(LibraryReportValidation.CheckIfValueExists(VATAmtSpecCaptionTxt), VATSpecExistsErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ZeroAmountWarningGeneralJournalTestEmptyGenPostingType()
    var
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [G/L Account] [Report]
        // [SCENARIO 361902] General Journal - Test report shows zero amount warning if posting type is blank in gen. journal and zero amount
        Initialize();

        // [GIVEN] G/L Account X with blank Gen. Posting Type
        CreateGLAccountWithPostingType(GLAccount, GLAccount."Gen. Posting Type"::" ");

        // [GIVEN] Gen. Journal Line with G/L Account X and 0 amount
        CreateGenJournalLine(GenJournalLine, GLAccount."No.", 0);

        // [WHEN] Run Report 2 General Journal - Test
        RunReportGeneralJournalTest(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name");

        // [THEN] Report contains warning - Amount must be specified.
        LibraryReportValidation.OpenExcelFile();
        LibraryReportValidation.VerifyCellValue(21, 4, AmountMustBeSpecifiedTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ZeroAmountWarningGeneralJournalTestNotEmptyGenPostingType()
    var
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [G/L Account] [Report]
        // [SCENARIO 361902] General Journal - Test report shows zero amount warning if posting type is not blank in gen. journal and zero amount
        Initialize();

        // [GIVEN] G/L Account X with not blank Gen. Posting Type
        CreateGLAccountWithPostingType(GLAccount, GLAccount."Gen. Posting Type"::Purchase);

        // [GIVEN] Gen. Journal Line with G/L Account X and 0 amount
        CreateGenJournalLine(GenJournalLine, GLAccount."No.", 0);

        // [WHEN] Run Report 2 General Journal - Test
        RunReportGeneralJournalTest(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name");

        // [THEN] Report contains warning - Amount must be specified.
        LibraryReportValidation.OpenExcelFile();
        LibraryReportValidation.VerifyCellValue(21, 4, AmountMustBeSpecifiedTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJournalTestReportOnRecurringGenJnlLinesWithPercentInDocNo()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        ExpectedDocNo: Code[20];
    begin
        // [FEATURE] [Recurring Journal] [Report]
        // [SCENARIO 309575] "General Journal - Test" report processes all recurring lines in current batch in case Document No. contains code like %1, %2 etc.
        Initialize();

        // [GIVEN] Two recurring General Journal Lines with Document No. = "%4 ABCD". %4 is substituted by month's name from Posting Date.
        LibraryERM.CreateRecurringTemplateName(GenJournalTemplate);
        LibraryERM.CreateRecurringBatchName(GenJournalBatch, GenJournalTemplate.Name);
        CreateRecurringGenJnlLine(GenJournalLine, GenJournalBatch, '%4 ' + LibraryUtility.GenerateGUID());
        CreateRecurringGenJnlLine(GenJournalLine, GenJournalBatch, GenJournalLine."Document No.");
        ExpectedDocNo := StrSubstNo(GenJournalLine."Document No.", '', '', '', FORMAT(GenJournalLine."Posting Date", 0, '<Month Text>'));

        // [WHEN] Run Report "General Journal - Test".
        RunReportGeneralJournalTest(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name");

        // [THEN] Both lines are shown in the report results.
        LibraryReportValidation.OpenExcelFile();
        LibraryReportValidation.VerifyCellValue(20, 4, ExpectedDocNo);
        LibraryReportValidation.VerifyCellValue(21, 4, ExpectedDocNo);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"ERM Excel Reports");

        LibraryVariableStorage.Clear();
        Clear(LibraryReportValidation);
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"ERM Excel Reports");

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"ERM Excel Reports");
    end;

    local procedure ClearGeneralJournalLines(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
    end;

    local procedure Create2GenJnlLines(var GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        Amount: Decimal;
    begin
        ClearGeneralJournalLines(GenJournalBatch);
        Amount := LibraryRandom.RandDec(1000, 2);

        CreateGenJnlLine(GenJournalLine, GenJournalBatch, Amount);
        CreateGenJnlLine(GenJournalLine, GenJournalBatch, -Amount);
    end;

    local procedure CreateGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; Amount: Decimal)
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNoWithDirectPosting(), Amount);
        GenJournalLine.Validate("Bal. Account No.", '');
        GenJournalLine.Modify();
    end;

    local procedure CreateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GLAccountNo: Code[20]; Amount: Decimal)
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", GLAccountNo, Amount);
    end;

    local procedure CreateRecurringGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; DocumentNo: Code[20])
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.Get(GenJournalBatch."Journal Template Name");
        GenJournalTemplate.TestField(Recurring, true);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), LibraryRandom.RandDecInRange(100, 200, 2));
        GenJournalLine.Validate("Document No.", DocumentNo);
        GenJournalLine.Validate("Recurring Method", GenJournalLine."Recurring Method"::"F  Fixed");
        Evaluate(GenJournalLine."Recurring Frequency", '<1M>');
        GenJournalLine.Modify(true);
    end;

    local procedure CreateGLAccountWithPostingType(var GLAccount: Record "G/L Account"; PostingType: Enum "General Posting Type")
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Posting Type", PostingType);
        GLAccount.Modify(true);
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20]; VendorInvoiceNo: Code[20]; DocumentType: Enum "Purchase Document Type"; No: Code[20]): Decimal
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate("Vendor Invoice No.", VendorInvoiceNo);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, No, LibraryRandom.RandDec(10, 2));  // Use Random Value for Purchase Line Quantity.
        ModifyDirectUnitCostOnPurchaseLine(PurchaseLine, LibraryRandom.RandDec(100, 2));
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        PurchaseHeader.CalcFields("Amount Including VAT");
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);
        exit(PurchaseHeader."Amount Including VAT");
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        exit(Vendor."No.");
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        exit(Item."No.");
    end;

    local procedure FindPurchaseLine(var PurchaseLine: Record "Purchase Line"; DocumentNo: Code[20]; DocumentType: Enum "Purchase Document Type")
    begin
        PurchaseLine.SetRange("Document Type", DocumentType);
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.FindFirst();
    end;

    local procedure ModifyDirectUnitCostOnPurchaseLine(var PurchaseLine: Record "Purchase Line"; DirectUnitCost: Decimal)
    begin
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
    end;

    local procedure RunReportGeneralJournalTest(JournalTemplateName: Code[20]; JournalBatchName: Code[20])
    var
        GenJnlLine: Record "Gen. Journal Line";
        GeneralJournalTest: Report "General Journal - Test";
    begin
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());
        GenJnlLine.SetRange("Journal Template Name", JournalTemplateName);
        GenJnlLine.SetRange("Journal Batch Name", JournalBatchName);
        GeneralJournalTest.SetTableView(GenJnlLine);
        GeneralJournalTest.SaveAsExcel(LibraryReportValidation.GetFileName());
        LibraryReportValidation.DownloadFile();
    end;

    local procedure VerifyGeneralJournalTestTotalBalance()
    var
        RefGenJnlLine: Record "Gen. Journal Line";
        ValueFound: Boolean;
        TotalBalanceLCYAsText: Text;
        TotalBalanceLCY: Decimal;
        Row: Integer;
        Column: Integer;
    begin
        // Verify Saved Report's Data.
        LibraryReportValidation.OpenExcelFile();

        // Retrieve value from cell: row Total (LCY) and column Balance (LCY)
        Row := LibraryReportValidation.FindRowNoFromColumnCaption(TotalLCYCap);
        Column := LibraryReportValidation.FindColumnNoFromColumnCaption(RefGenJnlLine.FieldCaption("Balance (LCY)"));
        TotalBalanceLCYAsText := LibraryReportValidation.GetValueAt(ValueFound, Row, Column);
        Assert.IsTrue(ValueFound, StrSubstNo(CellValueNotFoundErr, Row, Column));
        Assert.IsTrue(
          Evaluate(TotalBalanceLCY, TotalBalanceLCYAsText),
          CopyStr(StrSubstNo(EvaluateErr, TotalBalanceLCYAsText), 1, 1024));
        Assert.AreEqual(0, TotalBalanceLCY, IncorrectTotalBalanceLCYErr);
    end;

    local procedure SavePurchaseOrderReportAsExcel(PurchaseHeader: Record "Purchase Header")
    var
        PurchaseOrderReport: Report "Order";
    begin
        LibraryReportValidation.SetFileName(PurchaseHeader."No.");
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
        PurchaseHeader.SetRange("No.", PurchaseHeader."No.");
        PurchaseOrderReport.SetTableView(PurchaseHeader);
        PurchaseOrderReport.SaveAsExcel(LibraryReportValidation.GetFileName());
        LibraryReportValidation.DownloadFile();
    end;

    local procedure ValidatePurchaseOrderReportWithVAT(CostMultiplier: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        Initialize();
        CreatePurchaseDocument(
          PurchaseHeader, CreateVendor(), Format(LibraryRandom.RandInt(100)), PurchaseHeader."Document Type"::Order, CreateItem());
        FindPurchaseLine(PurchaseLine, PurchaseHeader."No.", PurchaseLine."Document Type"::Order);

        PurchaseLine.Validate("Direct Unit Cost", PurchaseLine."Direct Unit Cost" * CostMultiplier);
        PurchaseLine.Modify(true);

        SavePurchaseOrderReportAsExcel(PurchaseHeader);
        ValidatePurchaseOrderReportForVATSpecificationLine(PurchaseHeader, PurchaseLine);
    end;

    local procedure ValidatePurchaseOrderReportForVATSpecificationLine(PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line")
    var
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        VATSpecificationLine: array[50] of Text[250];
        ExcelValue: Decimal;
    begin
        PurchaseLine.CalcVATAmountLines(0, PurchaseHeader, PurchaseLine, TempVATAmountLine);

        LibraryReportValidation.FindFirstRow(VATSpecificationLine);
        repeat
            LibraryReportValidation.FindNextRow(VATSpecificationLine);

            if TempVATAmountLine."VAT Identifier" = VATSpecificationLine[1] then
                if Evaluate(ExcelValue, VATSpecificationLine[7]) then
                    if ExcelValue = TempVATAmountLine."VAT Amount" then
                        exit; // line found
        until VATSpecificationLine[1] = ShiptoAddressCaptionTxt;
        Assert.Fail(NoVATSpecLineErr);
    end;
}

