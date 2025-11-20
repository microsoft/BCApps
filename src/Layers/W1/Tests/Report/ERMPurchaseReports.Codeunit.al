codeunit 134983 "ERM Purchase Reports"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Purchase] [Report]
        isInitialized := false;
    end;

    var
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibraryJob: Codeunit "Library - Job";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        isInitialized: Boolean;
        ValidationErr: Label '%1 must be %2 in Report.', Comment = '%1 - Name of node; %2 - Value of node';
        AgedLbl: Label 'Portion of %1', Comment = '%1 - Aged type';
        Aged2Lbl: Label 'Purchases (LCY),Balance (LCY)';
        DimensionTxt: Label '%1 - %2', Comment = '%1 - Dimension Code; %2 - Dimension Value Code';
        LineDimensionsLbl: Label 'Line Dimensions';
        RowNotFoundErr: Label 'There is no dataset row corresponding to Element Name %1 with value %2.', Comment = '%1=Field Caption,%2=Field Value;';
        RepCaptionErrorTxt: Label 'ErrorText_Number_';
        PurchDocAlreadyExistTxt: Label 'Purchase %1 %2 already exists for this vendor.', Comment = '%1 = Document Type, %2 = Document No.';

    [Test]
    [HandlerFunctions('RHPurchaseDocumentTest')]
    [Scope('OnPrem')]
    procedure PurchDocumentWithDifferentVAT()
    var
        PurchaseHeader: Record "Purchase Header";
        TempPurchaseLine: Record "Purchase Line" temporary;
        VATAmountLine: Record "VAT Amount Line";
        QtyType: Option General,Invoicing,Shipping;
    begin
        // Check Report showing correct value with different VAT.

        // Setup: Create Purchase Order with different VAT.
        Initialize();
        CreateVATPurchaseDocument(PurchaseHeader, TempPurchaseLine, false);
        TempPurchaseLine.CalcVATAmountLines(QtyType::General, PurchaseHeader, TempPurchaseLine, VATAmountLine);

        // Exercise: Save Report with default options.
        SavePurchaseDocumentTestReport(PurchaseHeader."No.", false, false, false, false);

        // Verify: Verify VAT Lines different column values.
        VATAmountLine.SetFilter("VAT %", '>0');
        VATAmountLine.FindSet();
        LibraryReportDataset.LoadDataSetFile();
        repeat
            LibraryReportDataset.SetRange('VATAmountLine__VAT_Identifier_', VATAmountLine."VAT Identifier");
            if not LibraryReportDataset.GetNextRow() then
                Error(RowNotFoundErr, 'VATAmountLine__VAT_Identifier_', VATAmountLine."VAT Identifier");
            LibraryReportDataset.AssertCurrentRowValueEquals('VATAmountLine__VAT___', VATAmountLine."VAT %");
            LibraryReportDataset.AssertCurrentRowValueEquals(
              'VATAmountLine__VAT_Base_', VATAmountLine."VAT Base");
            LibraryReportDataset.AssertCurrentRowValueEquals(
              'VATAmountLine__Line_Amount_', VATAmountLine."Line Amount");
            LibraryReportDataset.AssertCurrentRowValueEquals(
              'VATAmountLine__Inv__Disc__Base_Amount_', VATAmountLine."Inv. Disc. Base Amount");
        until VATAmountLine.Next() = 0;
    end;

    [Test]
    [HandlerFunctions('RHPurchaseDocumentTest')]
    [Scope('OnPrem')]
    procedure PurchDocumentWithChargeItem()
    var
        ItemCharge: Record "Item Charge";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Check Report showing correct value for Charge Item Line.

        // Setup: Create Purchase Order for Item and Charge Item. Using RANDOM for Quantity and Direct Unit Cost.
        Initialize();
        LibraryInventory.CreateItemCharge(ItemCharge);
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateItem(), '');
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Charge (Item)", ItemCharge."No.", LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));
        PurchaseLine.Modify(true);

        // Exercise: Save Report using Charge Item Flag Yes.
        SavePurchaseDocumentTestReport(PurchaseHeader."No.", false, false, false, true);

        // Verify: Verify all Lines for Item and Charge Item.
        LibraryReportDataset.LoadDataSetFile();
        VerifyChargeItem(PurchaseHeader."No.");
    end;

    [Test]
    [HandlerFunctions('RHPurchaseDocumentTest')]
    [Scope('OnPrem')]
    procedure PurchDocumentWithDimension()
    var
        DefaultDimension: Record "Default Dimension";
        PurchaseHeader: Record "Purchase Header";
    begin
        // Check Report showing correct value for Dimension Line.

        // Setup.
        Initialize();
        CreateItemWithDimension(DefaultDimension);
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order, DefaultDimension."No.", '');

        // Exercise: Save Report using Dimension Flag Yes.
        SavePurchaseDocumentTestReport(PurchaseHeader."No.", false, false, true, false);

        // Verify: Verify Line Dimension and Warning message on Purchase Document Test Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('Line_DimensionsCaption', LineDimensionsLbl);
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFoundErr, 'Line_DimensionsCaption', LineDimensionsLbl);
        LibraryReportDataset.AssertCurrentRowValueEquals(
          'DimText_Control165', StrSubstNo(DimensionTxt, DefaultDimension."Dimension Code", DefaultDimension."Dimension Value Code"));
    end;

    [Test]
    [HandlerFunctions('RHPurchaseDocumentTest')]
    [Scope('OnPrem')]
    procedure PurchDocumentReceiveAndInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchSetup: Record "Purchases & Payables Setup";
    begin
        // Check Report showing correct value using Receive and Invoice Flag.

        // Setup: Modify Purchase & Payables Setup.
        Initialize();
        PurchSetup.Get();
        PurchSetup.Validate("Ext. Doc. No. Mandatory", true);
        PurchSetup.Modify(true);

        // Setup: Create Purchase Order.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateVendor());
        PurchaseHeader.Validate("Vendor Invoice No.", '');
        PurchaseHeader.Modify(true);
        CreatePurchaseLine(PurchaseHeader, CreateItem());

        // Exercise: Save Report using Receive Invoice Flag Yes.
        SavePurchaseDocumentTestReport(PurchaseHeader."No.", true, true, false, false);

        // Verify: Verify Order Posting String and Warning message.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('ReceiveInvoiceText', 'Order Posting: Receive and Invoice');
        LibraryReportDataset.AssertElementWithValueExists('ErrorText_Number_', 'Vendor Invoice No. must be specified.');
    end;

    [Test]
    [HandlerFunctions('RHPurchaseDocumentTest')]
    [Scope('OnPrem')]
    procedure PurchDocumentWithCurrency()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Check Purchase Document Test Report showing correct value with Currency.

        // Setup: Create Purchase Order.
        Initialize();
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateItem(), CreateCurrencyAndExchangeRate());

        // Exercise: Save Report using default value.
        SavePurchaseDocumentTestReport(PurchaseHeader."No.", false, false, false, false);

        // Verify: Verify Currency Information on Purchase Test Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('TotalExclVATText',
          StrSubstNo('Total %1 Excl. VAT', PurchaseHeader."Currency Code"));
    end;

    [Test]
    [HandlerFunctions('RHOrder')]
    [Scope('OnPrem')]
    procedure PurchOrderWithCurrency()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Check Purchase Order Report showing correct value with Currency.

        // Setup: Create Purchase Order.
        Initialize();
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateItem(), CreateCurrencyAndExchangeRate());

        // Exercise: Save Report using default value.
        SavePurchaseOrderReport(PurchaseHeader."No.", false, false, false);

        // Verify: Verify Currency Information on Purchase Order Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('TotalExclVATText',
          StrSubstNo('Total %1 Excl. VAT', PurchaseHeader."Currency Code"));
    end;

    [Test]
    [HandlerFunctions('RHOrder')]
    [Scope('OnPrem')]
    procedure PurchOrderWithDifferentVAT()
    var
        PurchaseHeader: Record "Purchase Header";
        TempPurchaseLine: Record "Purchase Line" temporary;
        VATAmountLine: Record "VAT Amount Line";
        QtyType: Option General,Invoicing,Shipping;
    begin
        // Check Report showing correct value with different VAT.

        // Setup: Create Purchase Order with different VAT.
        Initialize();
        CreateVATPurchaseDocument(PurchaseHeader, TempPurchaseLine, false);
        TempPurchaseLine.CalcVATAmountLines(QtyType::General, PurchaseHeader, TempPurchaseLine, VATAmountLine);

        // Exercise: Save Report with default options.
        SavePurchaseOrderReport(PurchaseHeader."No.", false, false, false);

        // Verify: Verify VAT Lines different column values.
        VATAmountLine.SetFilter("VAT %", '>0');
        VATAmountLine.FindSet();
        LibraryReportDataset.LoadDataSetFile();
        repeat
            LibraryReportDataset.SetRange('VATAmtLineVATIdentifier', VATAmountLine."VAT Identifier");
            if not LibraryReportDataset.GetNextRow() then
                Error(RowNotFoundErr, 'VATAmtLineVATIdentifier', VATAmountLine."VAT Identifier");
            LibraryReportDataset.AssertCurrentRowValueEquals('VATAmtLineVAT', VATAmountLine."VAT %");
            LibraryReportDataset.AssertCurrentRowValueEquals(
              'VATAmtLineVATBase', VATAmountLine."VAT Base");
            LibraryReportDataset.AssertCurrentRowValueEquals(
              'VATAmtLineLineAmt', VATAmountLine."Line Amount");
            LibraryReportDataset.AssertCurrentRowValueEquals(
              'VATAmtLineInvDiscBaseAmt', VATAmountLine."Inv. Disc. Base Amount");
        until VATAmountLine.Next() = 0;
    end;

    [Test]
    [HandlerFunctions('RHOrder')]
    [Scope('OnPrem')]
    procedure PurchOrderWithInternalInfo()
    var
        DefaultDimension: Record "Default Dimension";
        PurchaseHeader: Record "Purchase Header";
        ExpectedDimensionValue: Text[120];
    begin
        // Check Report showing correct value for Dimension Line.

        // Setup.
        Initialize();
        CreateItemWithDimension(DefaultDimension);
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order, DefaultDimension."No.", '');
        ExpectedDimensionValue := StrSubstNo('%1 %2', DefaultDimension."Dimension Code", DefaultDimension."Dimension Value Code");

        // Exercise: Save Report using Dimension Flag Yes.
        SavePurchaseOrderReport(PurchaseHeader."No.", true, true, false);

        // Verify: Verify Line Dimension on Purchase Order Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('DimText', ExpectedDimensionValue);
    end;

    [Test]
    [HandlerFunctions('RHOrder')]
    [Scope('OnPrem')]
    procedure PurchOrderWithArchive()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Check Purchase Order Report with Archive Option.

        // Setup: Create Purchase Order.
        Initialize();
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateItem(), '');

        // Exercise: Save Report using Archive Flag Yes.
        SavePurchaseOrderReport(PurchaseHeader."No.", false, true, false);

        // Verify: Verify Archive Entry created for Purchase Order.
        LibraryReportDataset.LoadDataSetFile();
        VerifyPurchaseArchive(PurchaseHeader."Document Type", PurchaseHeader."No.");
    end;

    [Test]
    [HandlerFunctions('RHOrder')]
    [Scope('OnPrem')]
    procedure PurchOrderInteractionEntry()
    var
        PurchaseHeader: Record "Purchase Header";
        InteractionLogEntry: Record "Interaction Log Entry";
    begin
        // Check Purchase Order Report with Option Interaction Log Entry.

        // Setup: Create Purchase Order.
        Initialize();
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateItem(), '');

        // Exercise: Save Report using Interaction Log Entry Flag Yes.
        SavePurchaseOrderReport(PurchaseHeader."No.", false, false, true);

        // Verify: Verify Interaction Log Entry created for Purchase Order.
        LibraryReportDataset.LoadDataSetFile();
        VerifyInteractionLogEntry(InteractionLogEntry."Document Type"::"Purch. Ord.", PurchaseHeader."No.");
    end;

    [Test]
    [HandlerFunctions('RHStandardPurchaseOrder')]
    [Scope('OnPrem')]
    procedure StandardPurchOrderWithCurrency()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [SCENARIO] Check Purchase Order Report showing correct value with Currency.

        // [GIVEN] Create Purchase Order.
        Initialize();
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateItem(), CreateCurrencyAndExchangeRate());

        // [WHEN] Save Report using default value.
        SaveStandardPurchaseOrderReport(PurchaseHeader."No.", false);

        // [THEN] Verify Currency Information on Purchase Order Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('TotalExclVATText',
          StrSubstNo('Total %1 Excl. VAT', PurchaseHeader."Currency Code"));
    end;

    [Test]
    [HandlerFunctions('RHStandardPurchaseOrder')]
    [Scope('OnPrem')]
    procedure StandardPurchOrderWithDifferentVAT()
    var
        PurchaseHeader: Record "Purchase Header";
        TempPurchaseLine: Record "Purchase Line" temporary;
        VATAmountLine: Record "VAT Amount Line";
        QtyType: Option General,Invoicing,Shipping;
    begin
        // [SCENARIO]Check Report showing correct value with different VAT.

        // [GIVEN] Create Purchase Order with different VAT.
        Initialize();
        CreateVATPurchaseDocument(PurchaseHeader, TempPurchaseLine, false);
        TempPurchaseLine.CalcVATAmountLines(QtyType::General, PurchaseHeader, TempPurchaseLine, VATAmountLine);

        // [WHEN] Save Report with default options.
        SaveStandardPurchaseOrderReport(PurchaseHeader."No.", false);

        // [THEN] Verify VAT Lines different column values.
        VATAmountLine.SetFilter("VAT %", '>0');
        VATAmountLine.FindSet();
        LibraryReportDataset.LoadDataSetFile();
        repeat
            LibraryReportDataset.SetRange('VATAmtLineVATIdentifier', VATAmountLine."VAT Identifier");
            if not LibraryReportDataset.GetNextRow() then
                Error(RowNotFoundErr, 'VATAmtLineVATIdentifier', VATAmountLine."VAT Identifier");
            LibraryReportDataset.AssertCurrentRowValueEquals('VATAmtLineVAT', VATAmountLine."VAT %");
            LibraryReportDataset.AssertCurrentRowValueEquals(
              'VATAmtLineVATBase', VATAmountLine."VAT Base");
            LibraryReportDataset.AssertCurrentRowValueEquals(
              'VATAmtLineLineAmt', VATAmountLine."Line Amount");
            LibraryReportDataset.AssertCurrentRowValueEquals(
              'VATAmtLineInvDiscBaseAmt', VATAmountLine."Inv. Disc. Base Amount");
        until VATAmountLine.Next() = 0;
    end;

    [Test]
    [HandlerFunctions('RHStandardPurchaseOrder')]
    [Scope('OnPrem')]
    procedure StandardPurchOrderInteractionEntry()
    var
        PurchaseHeader: Record "Purchase Header";
        InteractionLogEntry: Record "Interaction Log Entry";
    begin
        // [SCENARIO] Check Purchase Order Report with Option Interaction Log Entry.

        // [ GIVEN] Create Purchase Order.
        Initialize();
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateItem(), '');

        // [WHEN] Save Report using Interaction Log Entry Flag Yes.
        SaveStandardPurchaseOrderReport(PurchaseHeader."No.", true);

        // [THEN] Verify Interaction Log Entry created for Purchase Order.
        LibraryReportDataset.LoadDataSetFile();
        VerifyInteractionLogEntry(InteractionLogEntry."Document Type"::"Purch. Ord.", PurchaseHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ReportHandlerPurchaseInvoice')]
    [Scope('OnPrem')]
    procedure PurchInvoiceWithCurrency()
    var
        PurchaseHeader: Record "Purchase Header";
        DocumentNo: Code[20];
    begin
        // Check Posted Purchase Invoice Report showing correct value with Currency.

        // Setup: Create Purchase Order.
        Initialize();
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateItem(), CreateCurrencyAndExchangeRate());
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Exercise: Save Purchase Invoice Report.
        SavePurchaseInvoiceReport(DocumentNo, false, false);

        // Verify: Verify Currency Information on Posted Purchase Invoice Report.
        VerifyPostedInvoice(DocumentNo);
        LibraryReportDataset.AssertElementWithValueExists('TotalExclVATText',
          StrSubstNo('Total %1 Excl. VAT', PurchaseHeader."Currency Code"));
    end;

    [Test]
    [HandlerFunctions('ReportHandlerPurchaseInvoice')]
    [Scope('OnPrem')]
    procedure PurchInvoiceWithInternalInfo()
    var
        DefaultDimension: Record "Default Dimension";
        PurchaseHeader: Record "Purchase Header";
        DocumentNo: Code[20];
        ExpectedDimensionValue: Text[120];
    begin
        // Check Report showing correct value for Dimension Line.

        // Setup.
        Initialize();
        CreateItemWithDimension(DefaultDimension);
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order, DefaultDimension."No.", '');
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        ExpectedDimensionValue := StrSubstNo('%1 %2', DefaultDimension."Dimension Code", DefaultDimension."Dimension Value Code");

        // Exercise: Save Report using Dimension Flag Yes.
        SavePurchaseInvoiceReport(DocumentNo, true, false);

        // Verify: Verify Line Dimension on Posted Purchase Invoice Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('DimText_DimensionLoop2', ExpectedDimensionValue);
    end;

    [Test]
    [HandlerFunctions('ReportHandlerPurchaseInvoice')]
    [Scope('OnPrem')]
    procedure PurchInvoiceInteractionEntry()
    var
        PurchaseHeader: Record "Purchase Header";
        InteractionLogEntry: Record "Interaction Log Entry";
        DocumentNo: Code[20];
    begin
        // Check Purchase Order Report with Option Interaction Log Entry.

        // Setup: Create Purchase Order.
        Initialize();
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateItem(), '');
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Exercise: Save Report using Interaction Log Entry Flag Yes.
        SavePurchaseInvoiceReport(DocumentNo, false, true);

        // Verify: Verify Interaction Log Entry created for Posted Purchase Invoice.
        VerifyInteractionLogEntry(InteractionLogEntry."Document Type"::"Purch. Inv.", DocumentNo);
    end;

    [Test]
    [HandlerFunctions('ReportHandlerPurchaseInvoice')]
    [Scope('OnPrem')]
    procedure PurchInvoiceWithDifferentVAT()
    var
        PurchaseHeader: Record "Purchase Header";
        TempPurchaseLine: Record "Purchase Line" temporary;
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
        VATAmountLine: Record "VAT Amount Line";
    begin
        // Check Report showing correct value with different VAT.

        // Setup: Create Purchase Order with different VAT.
        Initialize();
        CreateVATPurchaseDocument(PurchaseHeader, TempPurchaseLine, false);
        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
        PurchInvLine.CalcVATAmountLines(PurchInvHeader, VATAmountLine);

        // Exercise: Save Report with default options.
        SavePurchaseInvoiceReport(PurchInvHeader."No.", false, false);

        // Verify: Verify VAT Lines different column values.
        LibraryReportDataset.LoadDataSetFile();
        VATAmountLine.SetFilter("VAT %", '>0');
        VATAmountLine.FindSet();

        repeat
            LibraryReportDataset.AssertElementWithValueExists('VATAmtLineVAT_VATCounter', VATAmountLine."VAT %");
            LibraryReportDataset.AssertElementWithValueExists('VATAmtLineVATBase', VATAmountLine."VAT Base");
            LibraryReportDataset.AssertElementWithValueExists('VATAmtLineLineAmt', VATAmountLine."Line Amount");
            LibraryReportDataset.AssertElementWithValueExists('VATAmtLineInvDiscBaseAmt', VATAmountLine."Inv. Disc. Base Amount");
        until VATAmountLine.Next() = 0;
    end;

    [Test]
    [HandlerFunctions('RHPurchaseCreditMemo')]
    [Scope('OnPrem')]
    procedure PurchCrMemoWithCurrency()
    var
        PurchaseHeader: Record "Purchase Header";
        DocumentNo: Code[20];
    begin
        // Check Posted Purchase Credit Memo Report showing correct value with Currency.

        // Setup: Create Purchase Credit Memo.
        Initialize();
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", CreateItem(), CreateCurrencyAndExchangeRate());
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Exercise: Save Purchase Credit Memo Report.
        SavePurchaseCrMemoReport(DocumentNo, false, false);

        // Verify: Verify Currency Information on Posted Purchase Credit Memo Report.
        LibraryReportDataset.LoadDataSetFile();
        VerifyPostedCreditMemo(DocumentNo);
        LibraryReportDataset.AssertElementWithValueExists('TotalExclVATText',
          StrSubstNo('Total %1 Excl. VAT', PurchaseHeader."Currency Code"));
    end;

    [Test]
    [HandlerFunctions('RHPurchaseCreditMemo')]
    [Scope('OnPrem')]
    procedure PurchCrMemoWithInternalInfo()
    var
        DefaultDimension: Record "Default Dimension";
        PurchaseHeader: Record "Purchase Header";
        DocumentNo: Code[20];
        ExpectedDimensionValue: Text[120];
    begin
        // Check Posted Credit Memo Report showing correct value for Dimension Line.

        // Setup.
        Initialize();
        CreateItemWithDimension(DefaultDimension);
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", DefaultDimension."No.", '');
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        ExpectedDimensionValue := StrSubstNo('%1 %2', DefaultDimension."Dimension Code", DefaultDimension."Dimension Value Code");

        // Exercise: Save Report using Dimension Flag Yes.
        SavePurchaseCrMemoReport(DocumentNo, true, false);

        // Verify: Verify Line Dimension on Posted Purchase Credit Memo Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('DimText_DimensionLoop2', ExpectedDimensionValue);
    end;

    [Test]
    [HandlerFunctions('RHPurchaseCreditMemo')]
    [Scope('OnPrem')]
    procedure PurchCrMemoInteractionEntry()
    var
        PurchaseHeader: Record "Purchase Header";
        InteractionLogEntry: Record "Interaction Log Entry";
        DocumentNo: Code[20];
    begin
        // Check Posted Purchase Credit Memo Report with Option Interaction Log Entry.

        // Setup: Create Purchase Credit Memo.
        Initialize();
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", CreateItem(), '');
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Exercise: Save Report using Interaction Log Entry Flag Yes.
        SavePurchaseCrMemoReport(DocumentNo, false, true);

        // Verify: Verify Interaction Log Entry created for Posted Purchase Credit Memo.
        VerifyInteractionLogEntry(InteractionLogEntry."Document Type"::"Purch. Cr. Memo", DocumentNo);
    end;

    [Test]
    [HandlerFunctions('RHPurchaseCreditMemo')]
    [Scope('OnPrem')]
    procedure PurchCrMemoWithVAT()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        VATAmountLine: Record "VAT Amount Line";
    begin
        // Check Report showing correct value for VAT Entry.

        // Setup: Create Purchase Credit Memo.
        Initialize();
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", CreateVendor());
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
        CreatePurchaseLine(PurchaseHeader, CreateItemWithVAT());
        PurchCrMemoHdr.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
        PurchCrMemoLine.CalcVATAmountLines(PurchCrMemoHdr, VATAmountLine);

        // Exercise: Save Report with default options.
        SavePurchaseCrMemoReport(PurchCrMemoHdr."No.", false, false);

        // Verify: Verify VAT Entry on Posted Purchase Credit Memo Report.
        LibraryReportDataset.LoadDataSetFile();
        VATAmountLine.SetFilter("VAT %", '>0');
        VATAmountLine.FindSet();
        repeat
            LibraryReportDataset.AssertElementWithValueExists('VATAmountLineVAT_VATCounter', VATAmountLine."VAT %");
            LibraryReportDataset.AssertElementWithValueExists('VATAmountLineVATBase', VATAmountLine."VAT Base");
            LibraryReportDataset.AssertElementWithValueExists('VATAmountLineLineAmount', VATAmountLine."Line Amount");
            LibraryReportDataset.AssertElementWithValueExists('VATAmtLineInvDiscBaseAmt', VATAmountLine."Inv. Disc. Base Amount");
        until VATAmountLine.Next() = 0;
    end;

    [Test]
    [HandlerFunctions('RHVATExceptions')]
    [Scope('OnPrem')]
    procedure VATExceptionsWithAddCurrency()
    var
        PurchaseLine: Record "Purchase Line";
        CurrencyCode: Code[10];
        DocumentNo: Code[20];
        OldAdditionalReportingCurrency: Code[10];
        TotalAmount: Decimal;
        VATAmount: Decimal;
    begin
        // Check VAT Exceptions Report with Additional Currency.

        // Setup: Update Additional Currency on General Ledger Setup. Create and Post Purchase Order.
        Initialize();
        CurrencyCode := CreateCurrencyAndExchangeRate();
        UpdateAddnlReportingCurrency(OldAdditionalReportingCurrency, CurrencyCode);
        DocumentNo := CreateAndPostPurchaseOrder(PurchaseLine, 0);
        TotalAmount := LibraryERM.ConvertCurrency(PurchaseLine."Line Amount", '', CurrencyCode, WorkDate());
        VATAmount := TotalAmount * PurchaseLine."VAT %" / 100;

        // Exercise: Run VAT Exceptions Report with Additional Currency.
        RunVATExceptionsReport(PurchaseLine."VAT Prod. Posting Group", DocumentNo, true);

        // Verify: Verify VAT Exceptions Report.
        LibraryReportDataset.LoadDataSetFile();
        VerifyVATEntry(DocumentNo, TotalAmount, VATAmount);

        // Tear Down: Roll Back Additional Reporting Currency and state.
        UpdateAddnlReportingCurrency(OldAdditionalReportingCurrency, OldAdditionalReportingCurrency);
    end;

    [Test]
    [HandlerFunctions('RHVATExceptions')]
    [Scope('OnPrem')]
    procedure VATExceptionsVATDifference()
    var
        PurchaseLine: Record "Purchase Line";
        LibraryUtility: Codeunit "Library - Utility";
        DocumentNo: Code[20];
    begin
        // Check VAT Exceptions Report for VAT Difference.

        // Setup: Create and Post Purchase Order with VAT Difference Random Values.
        Initialize();
        DocumentNo := CreateAndPostPurchaseOrder(PurchaseLine, LibraryUtility.GenerateRandomFraction());

        // Exercise: Save VAT Exceptions Report.
        RunVATExceptionsReport(PurchaseLine."VAT Prod. Posting Group", DocumentNo, false);

        // Verify: Verify Base and Amount on VAT Entry.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('DocumentNo_VatEntry', DocumentNo);
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFoundErr, 'DocumentNo_VatEntry', DocumentNo);
        LibraryReportDataset.AssertCurrentRowValueEquals('VatDiff_VatEntry', PurchaseLine."VAT Difference");
    end;

    [Test]
    [HandlerFunctions('RHVendorList')]
    [Scope('OnPrem')]
    procedure VendorList()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Vendor - List]
        // [SCENARIO] Check Vendor List Report values
        Initialize();

        // [GIVEN] Posted Purchase Order for Vendor "V"
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateItem(), '');
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        Vendor.Get(PurchaseHeader."Buy-from Vendor No.");

        // [WHEN] Run "Vendor - List" report for vendor "V"
        RunVendorListReport(Vendor);

        // [THEN] Report has correct Vendor "V" values for "Vendor Posting Group", "Payment Method Code", "Balance (LCY)"
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('Vendor__No__', PurchaseHeader."Buy-from Vendor No.");
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFoundErr, 'Vendor__No__', PurchaseHeader."Buy-from Vendor No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('Vendor__Vendor_Posting_Group_', PurchaseHeader."Vendor Posting Group");
        LibraryReportDataset.AssertCurrentRowValueEquals('Vendor__Vendor_Posting_Group_', PurchaseHeader."Vendor Posting Group");
        LibraryReportDataset.AssertCurrentRowValueEquals('Vendor__Invoice_Disc__Code_', PurchaseHeader."Buy-from Vendor No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('Vendor__Payment_Method_Code_', PurchaseHeader."Payment Method Code");

        Vendor.CalcFields("Balance (LCY)");
        LibraryReportDataset.AssertCurrentRowValueEquals('Vendor__Balance__LCY__', Vendor."Balance (LCY)");
    end;

    [Test]
    [HandlerFunctions('RHVendorList')]
    [Scope('OnPrem')]
    procedure VendorListFilterStringWithGlobalDimCaptions()
    var
        Vendor: Record Vendor;
        DimValueCode: array[2] of Code[20];
        ExpectedFilterString: Text;
    begin
        // [FEATURE] [Vendor - List]
        // [SCENARIO 376798] "Vendor - List" report prints global dimension captions in case of vendor dimension filters
        Initialize();
        UpdateGlobalDims();

        // [GIVEN] General Ledger Setup with two global dimensions: "Department", "Project".
        // [GIVEN] Vendor "V" with two default dimensions: Code = "Department", Value = "ADM"; Code = "Project", Value = "VW".
        CreateVendorWithDefaultGlobalDimValues(Vendor, DimValueCode);

        // [WHEN] Run "Vendor - List" report with following filters: "No." = "V"; "Department Code" = "ADM", "Project Code" = "VW"
        Vendor.SetFilter("Global Dimension 1 Code", DimValueCode[1]);
        Vendor.SetFilter("Global Dimension 2 Code", DimValueCode[2]);
        RunVendorListReport(Vendor);

        // [THEN] Report prints vendor "V" with following filter string: "No.: <"V">, Department Code: ADM, Project Code: VW"
        ExpectedFilterString :=
          StrSubstNo('%1: %2, %3: %4, %5: %6',
            Vendor.FieldName("No."), Vendor."No.",
            Vendor.FieldCaption("Global Dimension 1 Code"), DimValueCode[1],
            Vendor.FieldCaption("Global Dimension 2 Code"), DimValueCode[2]);

        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('Vendor__No__', Vendor."No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('VendFilter', ExpectedFilterString);
    end;

    [Test]
    [HandlerFunctions('RHVendorRegister')]
    [Scope('OnPrem')]
    procedure VendorRegister()
    var
        GLRegister: Record "G/L Register";
        PurchaseHeader: Record "Purchase Header";
        LineAmount: Decimal;
    begin
        // Check Vendor Register Report with LCY.

        // Setup.
        Initialize();
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateItem(), '');
        LineAmount := FindPurchaseLineAmount(PurchaseHeader."No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        GLRegister.FindLast();

        // Save Vendor Register Report and Verify it.
        SaveAndVerifyVendorRegister(GLRegister."No.", LineAmount, false);
    end;

    [Test]
    [HandlerFunctions('RHVendorRegister')]
    [Scope('OnPrem')]
    procedure VendorRegisterWithFCY()
    var
        GLRegister: Record "G/L Register";
        PurchaseHeader: Record "Purchase Header";
        Amount: Decimal;
    begin
        // Check Vendor Register Report with FCY.

        // Setup.
        Initialize();
        Amount := CreatePostPurchDocWithCurr(PurchaseHeader, CreateCurrencyAndExchangeRate());
        GLRegister.FindLast();

        // Save Vendor Register Report and Verify it.
        SaveAndVerifyVendorRegister(GLRegister."No.", Amount, true);
    end;

    [Test]
    [HandlerFunctions('RHVendorTop10List')]
    [Scope('OnPrem')]
    procedure VendorTop10ListBalanceLCY()
    var
        ShowType: Option "Purchases (LCY)","Balance (LCY)";
    begin
        // Check Vendor Top 10 List Report with option Balance LCY.
        Initialize();
        VendorTop10List(ShowType::"Balance (LCY)");
    end;

    [Test]
    [HandlerFunctions('RHVendorTop10List')]
    [Scope('OnPrem')]
    procedure VendorTop10ListPurchaseLCY()
    var
        ShowType: Option "Purchases (LCY)","Balance (LCY)";
    begin
        // Check Vendor Top 10 List Report with option Purchases LCY.
        Initialize();
        VendorTop10List(ShowType::"Purchases (LCY)");
    end;

    local procedure VendorTop10List(ShowType: Option)
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorTop10List: Report "Vendor - Top 10 List";
        TotalPurchase: Decimal;
    begin
        // Setup: Create and Post Purchase Order with Currency. Customized Round formula is required as per Report.
        CreatePostPurchDocWithCurr(PurchaseHeader, CreateCurrencyAndExchangeRate());
        VendorLedgerEntry.SetRange("Vendor No.", PurchaseHeader."Buy-from Vendor No.");
        VendorLedgerEntry.FindFirst();
        VendorLedgerEntry.CalcFields("Amount (LCY)");
        TotalPurchase := Round(VendorLedgerEntry."Purchase (LCY)" / VendorLedgerEntry."Purchase (LCY)" * 100, 0.1);

        // Exercise.
        Clear(VendorTop10List);
        Vendor.SetRange("No.", PurchaseHeader."Buy-from Vendor No.");
        VendorTop10List.SetTableView(Vendor);
        LibraryVariableStorage.Enqueue(ShowType);
        Commit();
        VendorTop10List.Run();

        // Verify: Verify Saved Report with Different Fields data.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('Vendor__No__', PurchaseHeader."Buy-from Vendor No.");
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFoundErr, 'Vendor__No__', PurchaseHeader."Buy-from Vendor No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('Vendor__Balance__LCY__', -VendorLedgerEntry."Amount (LCY)");
        LibraryReportDataset.AssertCurrentRowValueEquals('Vendor__Purchases__LCY__', -VendorLedgerEntry."Purchase (LCY)");
        LibraryReportDataset.AssertCurrentRowValueEquals('Vendor__Purchases__LCY___Control23', -VendorLedgerEntry."Purchase (LCY)");
        LibraryReportDataset.AssertCurrentRowValueEquals('STRSUBSTNO_Text003_SELECTSTR_ShowType_1_Text004__',
          StrSubstNo(AgedLbl, SelectStr(ShowType + 1, Aged2Lbl)));
        LibraryReportDataset.Reset();
        Assert.AreEqual(TotalPurchase,
          (LibraryReportDataset.Sum('Vendor__Purchases__LCY__') * 100) / LibraryReportDataset.Sum('TotalVenPurchases'),
          StrSubstNo(ValidationErr, Vendor.FieldCaption("Balance (LCY)"), TotalPurchase));
    end;

    [Test]
    [HandlerFunctions('RHVendorItemPurchases')]
    [Scope('OnPrem')]
    procedure VendorItemPurchases()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ValueEntry: Record "Value Entry";
        Vendor: Record Vendor;
        VendorItemPurchases: Report "Vendor/Item Purchases";
        DocumentNo: Code[20];
    begin
        // Check Vendor Item Purchases Report.

        // Setup: Create Purchase Document, Update Invoice Discount for Vendor and then calculate Invoice Discount.
        Initialize();
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, CreateItem(), '');
        CreateInvoiceDiscountForVendor(PurchaseHeader."Buy-from Vendor No.");
        GetPurchaseLine(PurchaseLine, PurchaseHeader);
        CODEUNIT.Run(CODEUNIT::"Purch.-Calc.Discount", PurchaseLine);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Exercise: Save Vendor Item Purchases Report.
        Clear(VendorItemPurchases);
        Vendor.SetRange("No.", PurchaseHeader."Buy-from Vendor No.");
        VendorItemPurchases.SetTableView(Vendor);
        Commit();
        VendorItemPurchases.Run();
        LibraryReportDataset.LoadDataSetFile();

        // Verify: Verify data on Vendor Item Purchases Report.
        ValueEntry.SetRange("Document No.", DocumentNo);
        ValueEntry.SetRange("Item No.", PurchaseLine."No.");
        ValueEntry.FindFirst();
        LibraryReportDataset.SetRange('Value_Entry__Item_No__', PurchaseLine."No.");
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFoundErr, 'Value_Entry__Item_No__', PurchaseLine."No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('Value_Entry___Cost_Amount__Actual__', ValueEntry."Cost Amount (Actual)");
        LibraryReportDataset.AssertCurrentRowValueEquals('Value_Entry___Discount_Amount_', ValueEntry."Discount Amount");
        LibraryReportDataset.AssertCurrentRowValueEquals('Value_Entry__Invoiced_Quantity_', ValueEntry."Invoiced Quantity");
        LibraryReportDataset.Reset();
        Assert.AreEqual(ValueEntry."Cost Amount (Actual)", LibraryReportDataset.Sum('Value_Entry___Cost_Amount__Actual__'),
          StrSubstNo(ValidationErr, ValueEntry.FieldCaption("Cost Amount (Actual)"), ValueEntry."Cost Amount (Actual)"));
        Assert.AreEqual(ValueEntry."Discount Amount", LibraryReportDataset.Sum('Value_Entry___Discount_Amount_'),
          StrSubstNo(ValidationErr, ValueEntry.FieldCaption("Discount Amount"), ValueEntry."Discount Amount"));
    end;

    [Test]
    [HandlerFunctions('RHPurchaseReturnShipment')]
    [Scope('OnPrem')]
    procedure ReturnShipment()
    var
        DocumentNo: Code[20];
    begin
        // Check Purchase Return Shipment Report without any option.

        // Setup.
        Initialize();
        DocumentNo := CreateAndPostReturnShipment(CreateItem());

        // Exercise: Save Purchase Return Shipment Report without any option selected.
        SavePurchaseReturnShipment(DocumentNo, false, false, false);

        // Verify: Verify data on Purchase Return Shipment Report.
        VerifyReturnShipment(DocumentNo);
    end;

    [Test]
    [HandlerFunctions('RHPurchaseReturnShipment')]
    [Scope('OnPrem')]
    procedure ReturnShipmentInternalInfo()
    var
        ReturnShipmentLine: Record "Return Shipment Line";
        DefaultDimension: Record "Default Dimension";
        DocumentNo: Code[20];
    begin
        // Check Purchase Return Shipment Report with Show Internal Information option.

        // Setup: Create Item With Dimension, Create Purchase Return Order and Post it with Ship Option.
        Initialize();
        CreateItemWithDimension(DefaultDimension);
        DocumentNo := CreateAndPostReturnShipment(DefaultDimension."No.");
        GetReturnShipmentLine(ReturnShipmentLine, DocumentNo);

        // Exercise: Save Purchase Return Shipment Report with Show Internal Information option.
        SavePurchaseReturnShipment(DocumentNo, true, false, false);

        // Verify: Verify Dimension and Dimension Value on Purchase Return Shipment Report.
        LibraryReportDataset.SetRange('LineDimensionsCaption', LineDimensionsLbl);
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFoundErr, 'LineDimensionsCaption', LineDimensionsLbl);
        LibraryReportDataset.AssertCurrentRowValueEquals('DimText_DimensionLoop2',
          StrSubstNo(DimensionTxt, DefaultDimension."Dimension Code", DefaultDimension."Dimension Value Code"));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,RHPurchaseReturnShipment')]
    [TestPermissions(TestPermissions::Disabled)]
    [Scope('OnPrem')]
    procedure ReturnShipmentCorrection()
    var
        ReturnShipmentLine: Record "Return Shipment Line";
        DocumentNo: Code[20];
    begin
        // Check Purchase Return Shipment Report with Show Correction Lines option.

        // Setup: Create and Post Purchase Return Shipment and Undo the posted Shipment.
        Initialize();
        DocumentNo := CreateAndPostReturnShipment(CreateItem());
        GetReturnShipmentLine(ReturnShipmentLine, DocumentNo);
        LibraryPurchase.UndoReturnShipmentLine(ReturnShipmentLine);
        ReturnShipmentLine.Next();

        // Exercise: Save Purchase Return Shipment Report with Show Correction Lines option.
        SavePurchaseReturnShipment(DocumentNo, false, true, false);
        LibraryReportDataset.SetRange('No_ReturnShipmentLine', ReturnShipmentLine."No.");
        LibraryReportDataset.GetNextRow();
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFoundErr, 'No_ReturnShipmentLine', ReturnShipmentLine."No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('Qty_ReturnShipmentLine', ReturnShipmentLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('RHPurchaseReturnShipment')]
    [Scope('OnPrem')]
    procedure ReturnShipmentLogEntry()
    var
        InteractionLogEntry: Record "Interaction Log Entry";
        DocumentNo: Code[20];
    begin
        // Check Interaction Log Entry after Saving Purchase Return Shipment Report with Log Interaction Option.
        // Setup:
        Initialize();
        DocumentNo := CreateAndPostReturnShipment(CreateItem());

        // Exercise: Save Purchase Return Shipment Report with Log Interaction Option.
        SavePurchaseReturnShipment(DocumentNo, false, false, true);

        // Verify: Verify Interaction Log Entry for the saved Report.
        VerifyInteractionLogEntry(InteractionLogEntry."Document Type"::"Purch. Return Shipment", DocumentNo);
    end;

    [Test]
    [HandlerFunctions('VendorSummaryAgingRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CurrencyCodeOnVendorSummerAgingReport()
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
    begin
        // Check Currency Code after saving Vendor Summary Aging Report.

        // Setup: Post Purchase Document with Currecy Code.
        Initialize();
        CreatePostPurchDocWithCurr(PurchaseHeader, CreateCurrencyAndExchangeRate());

        // Exercise: Save Vendor - Summary Aging Report.
        Vendor.SetRange("Currency Filter", PurchaseHeader."Currency Code");
        REPORT.Run(REPORT::"Vendor - Summary Aging", true, false, Vendor);

        // Verify: Verify Currency Code After saving Vendor - Summary Aging Report.
        VerifyCurrencyCode(PurchaseHeader."Buy-from Vendor No.", PurchaseHeader."Currency Code");
    end;

    [Test]
    [HandlerFunctions('PurchaseOrderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CheckValueOnPurchaseOrderReport()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Check purchase order report when purchase line exist with Type value blank.

        // Setup: Create purchase order with type blank
        Initialize();
        CreatePurchaseDocWithTypeBlank(PurchaseHeader);
        LibraryVariableStorage.Enqueue(PurchaseHeader."No.");

        // Exercise: Run Order report.

        PurchaseHeader.SetRange("No.", PurchaseHeader."No.");
        Commit();
        REPORT.Run(REPORT::Order, true, false, PurchaseHeader);

        // Verify: Verifying that no repeation of line exist on report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Desc_PurchLine', PurchaseHeader."No.");
    end;

    [Test]
    [HandlerFunctions('StandardPurchaseOrderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CheckValueOnStandardPurchaseOrderReport()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [SCENARIO] Check purchase order report when purchase line exist with Type value blank.

        // [GIVEN] Create purchase order with type blank
        Initialize();
        CreatePurchaseDocWithTypeBlank(PurchaseHeader);
        LibraryVariableStorage.Enqueue(PurchaseHeader."No.");

        // [WHEN] Run Order report.
        PurchaseHeader.SetRange("No.", PurchaseHeader."No.");
        Commit();
        REPORT.Run(REPORT::"Standard Purchase - Order", true, false, PurchaseHeader);

        // [THEN] Verifying that no repeation of line exist on report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Desc_PurchLine', PurchaseHeader."No.");
    end;

    [Test]
    [HandlerFunctions('RHPurchaseDocumentTest')]
    [Scope('OnPrem')]
    procedure PurchDocTestRepExternalDocumentNo()
    var
        OriginalPurchaseHeader: Record "Purchase Header";
        NewPurchaseHeader: Record "Purchase Header";
        VendorInvoiceNo: Code[35];
        ExpectedErrorText: Text;
    begin
        // [SCENARIO 109016.1] Verify that "Purchase Document - Test" report correctly checks External Doc. No. for the same Vendor
        Initialize();
        VendorInvoiceNo :=
          CopyStr(
            LibraryUtility.GenerateRandomText(MaxStrLen(OriginalPurchaseHeader."Vendor Invoice No.")),
            1, MaxStrLen(OriginalPurchaseHeader."Vendor Invoice No."));

        // [GIVEN] Create and Post Purchase Invoice
        CreatePurchaseDocument(OriginalPurchaseHeader, OriginalPurchaseHeader."Document Type"::Invoice, CreateItem(), '');
        UpdateVendorInvoiceNo(OriginalPurchaseHeader, VendorInvoiceNo);
        LibraryPurchase.PostPurchaseDocument(OriginalPurchaseHeader, true, true);

        // [GIVEN] Create second Purchase Invoice for the same Vendor and use the same Vendor Invoice No.
        LibraryPurchase.CreatePurchHeader(
          NewPurchaseHeader, OriginalPurchaseHeader."Document Type", OriginalPurchaseHeader."Buy-from Vendor No.");
        UpdateVendorInvoiceNo(NewPurchaseHeader, VendorInvoiceNo);
        CreatePurchaseLine(NewPurchaseHeader, CreateItem());

        // [WHEN] Run "Purchase Document - Test" report
        SavePurchaseDocumentTestReport(NewPurchaseHeader."No.", true, true, false, false); // default values

        // [THEN] Report shows an error text that "Vendor Invoice No." is already used
        ExpectedErrorText := StrSubstNo(PurchDocAlreadyExistTxt, Format(NewPurchaseHeader."Document Type"), VendorInvoiceNo);
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(RepCaptionErrorTxt, ExpectedErrorText);

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('RHPurchasePrepmtDocTest')]
    [Scope('OnPrem')]
    procedure PurchPrepmtDocTestRepExternalDocumentNo()
    var
        OriginalPurchaseHeader: Record "Purchase Header";
        NewPurchaseHeader: Record "Purchase Header";
        VendorInvoiceNo: Code[35];
        ExpectedErrorText: Text;
    begin
        // [SCENARIO 109016.2] Verify that "Purchase Prepmt. Doc. - Test" report correctly checks External Doc. No. for the same Vendor
        Initialize();
        VendorInvoiceNo :=
          CopyStr(
            LibraryUtility.GenerateRandomText(MaxStrLen(OriginalPurchaseHeader."Vendor Invoice No.")),
            1, MaxStrLen(OriginalPurchaseHeader."Vendor Invoice No."));

        // [GIVEN] Create and Post Purchase Order
        CreatePurchaseDocument(OriginalPurchaseHeader, OriginalPurchaseHeader."Document Type"::Order, CreateItem(), '');
        UpdateVendorInvoiceNo(OriginalPurchaseHeader, VendorInvoiceNo);
        LibraryPurchase.PostPurchaseDocument(OriginalPurchaseHeader, true, true);

        // [GIVEN] Create second Purchase Order for the same Vendor and use the same Vendor Invoice No.
        LibraryPurchase.CreatePurchHeader(
          NewPurchaseHeader, OriginalPurchaseHeader."Document Type", OriginalPurchaseHeader."Buy-from Vendor No.");
        UpdateVendorInvoiceNo(NewPurchaseHeader, VendorInvoiceNo);
        CreatePurchaseLine(NewPurchaseHeader, CreateItem());

        // [WHEN] Run "Purchase Prepmt. Doc. - Test" report
        SavePurchasePrepmtDocTestReport(NewPurchaseHeader."No.");

        // [THEN] Report shows an error text that "Vendor Invoice No." is already used
        ExpectedErrorText := StrSubstNo(PurchDocAlreadyExistTxt, Format(NewPurchaseHeader."Document Type"::Invoice), VendorInvoiceNo);
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(RepCaptionErrorTxt, ExpectedErrorText);

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorGetFilterStringWithDimCaptions()
    var
        Vendor: Record Vendor;
        FormatDocument: Codeunit "Format Document";
        DimValueCode: array[2] of Code[20];
        ExpectedFilterString: Text;
    begin
        // [FEATURE] [Vendor] [UT]
        // [SCENARIO 376798] COD368 "FormatDocument" method GetRecordFiltersWithCaptions() returns vendor filter string with global dimension's captions
        Initialize();
        UpdateGlobalDims();

        // [GIVEN] General Ledger Setup with two global dimensions: "Department", "Project".
        // [GIVEN] Vendor "V" with following filters: "Department Code" = "ADM", "Project Code" = "VW".
        CreateVendorWithDefaultGlobalDimValues(Vendor, DimValueCode);

        // [WHEN] Call COD368 "FormatDocument" method GetRecordFiltersWithCaptions()
        Vendor.SetFilter("Global Dimension 1 Code", DimValueCode[1]);
        Vendor.SetFilter("Global Dimension 2 Code", DimValueCode[2]);

        // [THEN] Return value = "Department Code: ADM, Project Code: VW"
        ExpectedFilterString :=
          StrSubstNo('%1: %2, %3: %4',
            Vendor.FieldCaption("Global Dimension 1 Code"), DimValueCode[1],
            Vendor.FieldCaption("Global Dimension 2 Code"), DimValueCode[2]);
        Assert.ExpectedMessage(ExpectedFilterString, FormatDocument.GetRecordFiltersWithCaptions(Vendor));
    end;

    [Test]
    [HandlerFunctions('RequestPagePurchaseCreditMemo')]
    [Scope('OnPrem')]
    procedure PrintYourReferenceOfPostedPurchaseCrMemo()
    var
        PostedCrMemoNo: Code[20];
        YourReference: Text[35];
    begin
        // [FEATURE] [Purchase - Credit Memo]
        // [SCENARIO 382079] Value of "Your Reference" of Posted Purchase Cr. Memo have to printed.
        Initialize();

        // [GIVEN] Posted purchase credit memo with "Your Reference" = "Ref"
        CreatePostPurchCrMemoWithYourRef(PostedCrMemoNo, YourReference);
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());

        // [WHEN] Print report 407 - "Purchase - Credit Memo"
        SavePurchaseCrMemoReport(PostedCrMemoNo, false, true);

        // [THEN] Caption of "Your reference" contains "Ref"
        VerifyYourReferencePurchaseCrMemo(YourReference);
    end;

    [Test]
    [HandlerFunctions('PurchaseQuoteADChangeRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseQuoteArchiveDocFlagStateIsSavedAfterRun()
    var
        ArchiveDocValue: Text;
    begin
        // [FEATURE] [Purchase Quote]
        // [SCENARIO 256827] "Archive Document" flag state is saved when Stan runs the "Purchase - Quote" report for the second time, i.e. "Saved setting" feature works for this flag.
        Initialize();

        // [GIVEN] Report "Purchase - Quote" was run for the first time, "Archive Document" flag state was changed before the report was run.
        Commit();
        LibraryVariableStorage.Enqueue(false);
        REPORT.Run(REPORT::"Purchase - Quote");
        ArchiveDocValue := LibraryVariableStorage.DequeueText();

        // [WHEN] Report "Purchase - Quote" is run for the second time.
        LibraryVariableStorage.Enqueue(true);
        REPORT.Run(REPORT::"Purchase - Quote");

        // [THEN] "Archive Document" flag state is saved after the first run.
        Assert.AreEqual(
          ArchiveDocValue, LibraryVariableStorage.DequeueText(), 'Unexpected value for ArchiveDocument field');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('OrderADChangeRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OrderArchiveDocFlagStateIsSavedAfterRun()
    var
        ArchiveDocValue: Text;
    begin
        // [FEATURE] [Purchase Order]
        // [SCENARIO 256827] "Archive Document" flag state is saved when Stan runs the "Order" report for the second time, i.e. "Saved setting" feature works for this flag.
        Initialize();

        // [GIVEN] Report "Order" was run for the first time, "Archive Document" flag state was changed before the report was run.
        Commit();
        LibraryVariableStorage.Enqueue(false);
        REPORT.Run(REPORT::Order);
        ArchiveDocValue := LibraryVariableStorage.DequeueText();

        // [WHEN] Report "Order" is run for the second time.
        LibraryVariableStorage.Enqueue(true);
        REPORT.Run(REPORT::Order);

        // [THEN] "Archive Document" flag state is saved after the first run.
        Assert.AreEqual(
          ArchiveDocValue, LibraryVariableStorage.DequeueText(), 'Unexpected value for ArchiveDocument field');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('BlanketPurchaseOrderADChangeRequestPageHandler')]
    [Scope('OnPrem')]
    procedure BlanketPurchaseOrderArchiveDocFlagStateIsSavedAfterRun()
    var
        ArchiveDocValue: Text;
    begin
        // [FEATURE] [Blanket Purchase Order]
        // [SCENARIO 256827] "Archive Document" flag state is saved when Stan runs the "Blanket Purchase Order" report for the second time, i.e. "Saved setting" feature works for this flag.
        Initialize();

        // [GIVEN] Report "Blanket Purchase Order" was run for the first time, "Archive Document" flag state was changed before the report was run.
        Commit();
        LibraryVariableStorage.Enqueue(false);
        REPORT.Run(REPORT::"Blanket Purchase Order");
        ArchiveDocValue := LibraryVariableStorage.DequeueText();

        // [WHEN] Report "Blanket Purchase Order" is run for the second time.
        LibraryVariableStorage.Enqueue(true);
        REPORT.Run(REPORT::"Blanket Purchase Order");

        // [THEN] "Archive Document" flag state is saved after the first run.
        Assert.AreEqual(
          ArchiveDocValue, LibraryVariableStorage.DequeueText(), 'Unexpected value for ArchiveDocument field');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StandardPurchaseOrderADChangeRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StandardPurchaseOrderArchiveDocFlagStateIsSavedAfterRun()
    var
        ArchiveDocValue: Text;
    begin
        // [FEATURE] [Purchase Order]
        // [SCENARIO 256827] "Archive Document" flag state is saved when Stan runs the "Standard Purchase - Order" report for the second time, i.e. "Saved setting" feature works for this flag.
        Initialize();

        // [GIVEN] Report "Standard Purchase - Order" was run for the first time, "Archive Document" flag state was changed before the report was run.
        Commit();
        LibraryVariableStorage.Enqueue(false);
        REPORT.Run(REPORT::"Standard Purchase - Order");
        ArchiveDocValue := LibraryVariableStorage.DequeueText();

        // [WHEN] Report "Standard Purchase - Order" is run for the second time.
        LibraryVariableStorage.Enqueue(true);
        REPORT.Run(REPORT::"Standard Purchase - Order");

        // [THEN] "Archive Document" flag state is saved after the first run.
        Assert.AreEqual(
          ArchiveDocValue, LibraryVariableStorage.DequeueText(), 'Unexpected value for ArchiveDocument field');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StandardPurchaseOrderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CheckJobNoValueOnStandardPurchaseOrderReport()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [SCENARIO 263850] Purchase Line "Job No." and "Job Task No." exist in Purchase Order Report dataset.
        Initialize();

        // [GIVEN] Create Purchase Order and Purchase Line with "Job No." and "Job Task No.".
        CreatePurchaseOrderWithLineSetJobTask(PurchaseHeader, PurchaseLine);

        // [WHEN] Run Order report.
        LibraryVariableStorage.Enqueue(PurchaseHeader."No.");
        PurchaseHeader.SetRange("No.", PurchaseHeader."No.");
        Commit();
        REPORT.Run(REPORT::"Standard Purchase - Order", true, false, PurchaseHeader);

        // [THEN] Verifying that "Job No." and "Job Task No." exist on report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('JobNo_PurchLine', PurchaseLine."Job No.");
        LibraryReportDataset.AssertElementWithValueExists('JobTaskNo_PurchLine', PurchaseLine."Job Task No.");
    end;

    [Test]
    [HandlerFunctions('StandardPurchaseOrderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CheckUnitPriceValueOnStandardPurchaseOrderReport()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [SCENARIO 263850] Purchase Line "Unit Price (LCY)" exist in Purchase Order Report dataset.
        // [SCENARIO 322593] Column caption for Direct Unit Cost value is "Direct Unit Cost".
        Initialize();

        // [GIVEN] Create Purchase Order and Purchase Line with Unit Price.
        CreatePurchaseOrderWithLine(PurchaseHeader, PurchaseLine);
        PurchaseLine.Validate("Unit Price (LCY)", LibraryRandom.RandDec(10, 2));
        PurchaseLine.Modify(true);

        // [WHEN] Run Order report.
        LibraryVariableStorage.Enqueue(PurchaseHeader."No.");
        PurchaseHeader.SetRange("No.", PurchaseHeader."No.");
        Commit();
        REPORT.Run(REPORT::"Standard Purchase - Order", true, false, PurchaseHeader);

        // [THEN] Verifying that Unit Price exists on report.
        // [THEN] DirectUniCost_Lbl has value "Direct Unit Cost".
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('UnitPrice_PurchLine', PurchaseLine."Unit Price (LCY)");
        LibraryReportDataset.AssertElementWithValueExists('DirectUniCost_Lbl', 'Direct Unit Cost');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchInvoiceTotalAmountWithPricesIncludingVAT()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
        PurchaseInvoice: Report "Purchase - Invoice";
        PostedDocumentNo: Code[20];
    begin
        // [SCENARIO 272731] The value of Total Amount must be shown when "Purchase Invoice"."Prices Including VAT" = TRUE
        Initialize();

        // [GIVEN] Posted Purchase Invoice with Total Amount = 100 and "Prices Including VAT" = TRUE
        CreatePurchaseOrderWithLine(PurchaseHeader, PurchaseLine);
        PurchaseHeader.Validate("Prices Including VAT", true);
        PurchaseHeader.Modify(true);
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        PurchInvLine.SetRange("Document No.", PostedDocumentNo);
        PurchInvLine.FindFirst();

        // [WHEN] Run "Purchase Invoice" report
        Clear(PurchaseInvoice);
        PurchInvHeader.SetRange("No.", PostedDocumentNo);
        PurchaseInvoice.SetTableView(PurchInvHeader);
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());
        PurchaseInvoice.SaveAsExcel(LibraryReportValidation.GetFileName());

        // [THEN] The Total Amount = 100
        LibraryReportValidation.OpenExcelFile();
        LibraryReportValidation.VerifyCellValue(85, 33, LibraryReportValidation.FormatDecimalValue(PurchInvLine.Amount));
    end;

    [Test]
    [HandlerFunctions('RHPurchaseReturnShipment')]
    [Scope('OnPrem')]
    procedure VerifyShipToAddressInPurchaseReturnShipmentReport()
    var
        ReturnShipmentHeader: Record "Return Shipment Header";
        DocumentNo: Code[20];
        ShipToName: Text[50];
        ShipToContact: Text[50];
        ShipToAddress: Text[50];
    begin
        // [SCENARIO 278343] Report "Purchase - Return Shipment" is run and result contains Ship-to Address
        Initialize();

        // [GIVEN] Create and Post Purchase Return Shipment with Ship-to Address "X"
        DocumentNo := CreateAndPostReturnShipmentWithShipToAddress(ShipToName, ShipToContact, ShipToAddress);

        // [WHEN] Report "Purchase - Return Shipment" is run
        ReturnShipmentHeader.SetRange("No.", DocumentNo);
        REPORT.Run(REPORT::"Purchase - Return Shipment", true, false, ReturnShipmentHeader);

        // [THEN] report contains Ship-to Address fields
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementTagWithValueExists('ShptShipToAddrCaption', 'Ship-to Address');
        LibraryReportDataset.AssertElementTagWithValueExists('ShptShipToAddr1', ShipToName);
        LibraryReportDataset.AssertElementTagWithValueExists('ShptShipToAddr2', ShipToContact);
        LibraryReportDataset.AssertElementTagWithValueExists('ShptShipToAddr3', ShipToAddress);
    end;

    [Test]
    [HandlerFunctions('StandardPurchaseOrderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchLineVATPctStandardPurchaseOrderReport()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 417377] "Standard - Purchase Order" contains value of "Purchase Line"."VAT %"

        Initialize();

        LibraryPurchase.CreatePurchHeader(
            PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item,
            LibraryInventory.CreateItemNo(), LibraryRandom.RandIntInRange(1, 5));
        PurchaseLine."VAT %" := LibraryRandom.RandIntInRange(1, 20);
        PurchaseLine.Modify();
        LibraryVariableStorage.Enqueue(PurchaseHeader."No.");

        PurchaseHeader.SetRange("No.", PurchaseHeader."No.");
        Commit();
        Report.Run(Report::"Standard Purchase - Order", true, false, PurchaseHeader);

        LibraryReportDataset.RunReportAndLoad(
            Report::"Standard Purchase - Order", PurchaseHeader, '');
        LibraryReportDataset.AssertElementWithValueExists('PurchLine_VATPct', PurchaseLine."VAT %");
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Purchase Reports");
        LibraryVariableStorage.Clear();
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Purchase Reports");

        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Purchase Reports");
    end;

    local procedure CopyPurchaseLine(var TempPurchaseLine: Record "Purchase Line" temporary; PurchaseLine: Record "Purchase Line")
    begin
        TempPurchaseLine := PurchaseLine;
        TempPurchaseLine.Insert();
    end;

    local procedure CreateAndPostPurchaseOrder(var PurchaseLine: Record "Purchase Line"; VATDifference: Decimal) PostedDocumentNo: Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Create Purchase Order with Random Quantity and Unit Cost.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateVendor());
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItemWithVAT(), LibraryRandom.RandDec(10, 2));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Validate("VAT Difference", VATDifference);
        PurchaseLine.Modify(true);
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreateAndPostReturnShipment(ItemNo: Code[20]) DocumentNo: Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        NoSeries: Codeunit "No. Series";
    begin
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", ItemNo, '');
        DocumentNo := NoSeries.PeekNextNo(PurchaseHeader."Return Shipment No. Series");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
    end;

    [Scope('OnPrem')]
    procedure CreateAndPostReturnShipmentWithShipToAddress(var ShipToName: Text[50]; var ShipToContact: Text[50]; var ShipToAddress: Text[50]) DocumentNo: Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        NoSeries: Codeunit "No. Series";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", Vendor."No.");
        ShipToName := CopyStr(LibraryRandom.RandText(10), 1, 10);
        ShipToContact := CopyStr(LibraryRandom.RandText(10), 1, 10);
        ShipToAddress := CopyStr(LibraryRandom.RandText(10), 1, 10);
        PurchaseHeader.Validate("Ship-to Name", ShipToName);
        PurchaseHeader.Validate("Ship-to Contact", ShipToContact);
        PurchaseHeader.Validate("Ship-to Address", ShipToAddress);
        PurchaseHeader.Modify(true);

        CreatePurchaseLine(PurchaseHeader, CreateItem());
        DocumentNo := NoSeries.PeekNextNo(PurchaseHeader."Return Shipment No. Series");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
    end;

    local procedure CreateCurrencyAndExchangeRate(): Code[10]
    var
        Currency: Record Currency;
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        Currency.Validate("Residual Gains Account", GLAccount."No.");
        Currency.Validate("Residual Losses Account", GLAccount."No.");
        Currency.Modify(true);
        exit(Currency.Code);
    end;

    local procedure CreateInvoiceDiscountForVendor("Code": Code[20])
    var
        VendorInvoiceDisc: Record "Vendor Invoice Disc.";
    begin
        // Create Invoice Discount for Vendor with Random Discount Percent, no Currency and zero Minimum Amount.
        LibraryERM.CreateInvDiscForVendor(VendorInvoiceDisc, Code, '', 0);
        VendorInvoiceDisc.Validate("Discount %", LibraryRandom.RandDec(10, 2));
        VendorInvoiceDisc.Modify(true);
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Last Direct Cost", LibraryRandom.RandDec(100, 2));   // Using RANDOM value for Last Direct Cost.
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateItemWithDimension(var DefaultDimension: Record "Default Dimension")
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        LibraryDimension: Codeunit "Library - Dimension";
    begin
        LibraryDimension.FindDimension(Dimension);
        LibraryDimension.FindDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDefaultDimensionItem(DefaultDimension, CreateItem(), DimensionValue."Dimension Code", DimensionValue.Code);
    end;

    local procedure CreateItemWithVAT(): Code[20]
    var
        Item: Record Item;
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        Item.Get(CreateItem());
        Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateItemWithZeroVAT(): Code[20]
    var
        Item: Record Item;
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindZeroVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        Item.Get(CreateItem());
        Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreatePostPurchDocWithCurr(var PurchaseHeader: Record "Purchase Header"; CurrencyCode: Code[10]) Amount: Decimal
    var
        Currency: Record Currency;
        LineAmount: Decimal;
    begin
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateItem(), CurrencyCode);
        LineAmount := FindPurchaseLineAmount(PurchaseHeader."No.");
        Currency.Get(PurchaseHeader."Currency Code");
        Amount := LibraryERM.ConvertCurrency(Round(LineAmount, Currency."Invoice Rounding Precision"), Currency.Code, '', WorkDate());
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; ItemNo: Code[20]; CurrencyCode: Code[10])
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, Vendor."No.");
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Validate("Currency Code", CurrencyCode);
        PurchaseHeader.Modify(true);
        CreatePurchaseLine(PurchaseHeader, ItemNo);
    end;

    local procedure CreatePurchaseDocWithTypeBlank(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        PurchaseLine.Init();
        PurchaseLine."Document Type" := PurchaseHeader."Document Type"::Order;
        PurchaseLine."Document No." := PurchaseHeader."No.";
        PurchaseLine."Line No." := 10000;
        PurchaseLine.Description := PurchaseHeader."No.";
        PurchaseLine.Insert();
    end;

    local procedure CreatePurchaseLine(PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, LibraryRandom.RandDec(10, 2));  // Use Random Value.
    end;

    local procedure CreatePurchaseOrderWithLine(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(), LibraryRandom.RandDec(10, 2));
    end;

    local procedure CreatePurchaseOrderWithLineSetJobTask(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    var
        Job: Record Job;
        JobTask: Record "Job Task";
    begin
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        CreatePurchaseOrderWithLine(PurchaseHeader, PurchaseLine);
        PurchaseLine.Validate("Job No.", Job."No.");
        PurchaseLine.Validate("Job Task No.", JobTask."Job Task No.");
        PurchaseLine.Modify(true);
    end;

    local procedure CreateVATPurchaseDocument(var PurchaseHeader: Record "Purchase Header"; var TempPurchaseLine: Record "Purchase Line" temporary; PricesIncludingVAT: Boolean)
    begin
        // Create Purchase Order with 3 Different VAT Posting Group Items.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        PurchaseHeader.Validate("Prices Including VAT", PricesIncludingVAT);
        PurchaseHeader.Modify(true);

        CreateVATPurchaseLine(PurchaseHeader, TempPurchaseLine, LibraryInventory.CreateItemNo());
        CreateVATPurchaseLine(PurchaseHeader, TempPurchaseLine, FindItem(TempPurchaseLine."VAT %"));
        CreateVATPurchaseLine(PurchaseHeader, TempPurchaseLine, CreateItemWithZeroVAT());
    end;

    local procedure CreateVATPurchaseLine(PurchaseHeader: Record "Purchase Header"; var TempPurchaseLine: Record "Purchase Line" temporary; ItemNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
        CopyPurchaseLine(TempPurchaseLine, PurchaseLine);
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateVendorWithDefaultGlobalDimValues(var Vendor: Record Vendor; var DimValueCode: array[2] of Code[20])
    var
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        i: Integer;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        for i := 1 to 2 do begin
            LibraryDimension.CreateDimensionValue(DimensionValue, LibraryERM.GetGlobalDimensionCode(i));
            LibraryDimension.CreateDefaultDimensionVendor(
              DefaultDimension, Vendor."No.", DimensionValue."Dimension Code", DimensionValue.Code);
            DimValueCode[i] := DimensionValue.Code;
        end;
    end;

    local procedure CreatePostPurchCrMemoWithYourRef(var PostedCrMemoNo: Code[20]; var YourReference: Text[35])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandIntInRange(1, 10));
        LibraryUtility.FillFieldMaxText(PurchaseHeader, PurchaseHeader.FieldNo("Your Reference"));
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        PostedCrMemoNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        YourReference := PurchaseHeader."Your Reference";
    end;

    local procedure RunVATExceptionsReport(VATProdPostingGroup: Text[20]; DocumentNo: Code[20]; AddCurrency: Boolean)
    begin
        LibraryVariableStorage.Enqueue(WorkDate());
        LibraryVariableStorage.Enqueue(VATProdPostingGroup);
        LibraryVariableStorage.Enqueue(DocumentNo);
        LibraryVariableStorage.Enqueue(AddCurrency);
        LibraryVariableStorage.Enqueue(false);
        Commit();
        REPORT.Run(REPORT::"VAT Exceptions");
    end;

    local procedure RunVendorListReport(var Vendor: Record Vendor)
    begin
        Commit();
        Vendor.SetRange("No.", Vendor."No.");
        REPORT.Run(REPORT::"Vendor - List", true, false, Vendor);
    end;

    local procedure FindItem(VATPct: Decimal): Code[20]
    var
        Item: Record Item;
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Not using Library Item Finder method to make this funtion World ready.
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.SetFilter("VAT %", '>0&<>%1', VATPct);
        VATPostingSetup.FindFirst();
        Item.SetRange(Blocked, false);
        Item.FindFirst();
        Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Item.Validate("Last Direct Cost", LibraryRandom.RandDec(100, 2)); // Using Random for Random Decimal value.
        Item.Validate("Unit Price", Item."Last Direct Cost");
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure FindPurchaseLineAmount(DocumentNo: Code[20]): Decimal
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.FindFirst();
        exit(PurchaseLine."Amount Including VAT");
    end;

    local procedure GetPurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange("Buy-from Vendor No.", PurchaseHeader."Buy-from Vendor No.");
        PurchaseLine.FindFirst();
    end;

    local procedure GetReturnShipmentLine(var ReturnShipmentLine: Record "Return Shipment Line"; DocumentNo: Code[20])
    begin
        ReturnShipmentLine.SetRange("Document No.", DocumentNo);
        ReturnShipmentLine.FindFirst();
    end;

    local procedure SaveAndVerifyVendorRegister(GLRegisterNo: Integer; ExpectedValue: Decimal; AmountLCY: Boolean)
    begin
        // Exercise.
        SaveVendorRegisterReport(GLRegisterNo, AmountLCY);

        // Verify: Verify Saved Report with Different Fields data.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('Vendor_Ledger_Entry__Posting_Date_', Format(WorkDate()));

        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFoundErr, 'Vendor_Ledger_Entry__Posting_Date_', WorkDate());
        LibraryReportDataset.AssertCurrentRowValueEquals('VendAmountLCY', -ExpectedValue);
        LibraryReportDataset.AssertCurrentRowValueEquals('Vendor_Ledger_Entry__Due_Date_', Format(WorkDate()));
        LibraryReportDataset.AssertCurrentRowValueEquals('VendCreditAmountLCY_Control64', ExpectedValue);
        LibraryReportDataset.AssertCurrentRowValueEquals('G_L_Register__No__', GLRegisterNo);
    end;

    local procedure SavePurchaseCrMemoReport(DocumentNo: Code[20]; ShowInternalInfo: Boolean; LogInteraction: Boolean)
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchaseCreditMemo: Report "Purchase - Credit Memo";
    begin
        Clear(PurchaseCreditMemo);
        PurchCrMemoHdr.SetRange("No.", DocumentNo);
        PurchaseCreditMemo.SetTableView(PurchCrMemoHdr);
        PurchaseCreditMemo.InitializeRequest(0, ShowInternalInfo, LogInteraction);  // Using 0 for No. of Copies.
        Commit();
        PurchaseCreditMemo.Run();
    end;

    local procedure SavePurchaseDocumentTestReport(DocumentNo: Code[20]; Receive: Boolean; Invoice: Boolean; ShowDimension: Boolean; ShowItemCharge: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseDocumentTest: Report "Purchase Document - Test";
    begin
        Clear(PurchaseDocumentTest);
        PurchaseHeader.SetRange("No.", DocumentNo);
        PurchaseDocumentTest.SetTableView(PurchaseHeader);
        PurchaseDocumentTest.InitializeRequest(Receive, Invoice, ShowDimension, ShowItemCharge);
        Commit();
        PurchaseDocumentTest.Run();
    end;

    local procedure SavePurchasePrepmtDocTestReport(DocumentNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchasePrepmtDocTest: Report "Purchase Prepmt. Doc. - Test";
        DocumentType: Option Invoice,"Credit Memo";
    begin
        Clear(PurchasePrepmtDocTest);
        PurchaseHeader.SetRange("No.", DocumentNo);
        PurchasePrepmtDocTest.SetTableView(PurchaseHeader);
        PurchasePrepmtDocTest.InitializeRequest(DocumentType::Invoice, false); // ShowDim = FALSE
        Commit();
        PurchasePrepmtDocTest.Run();
    end;

    local procedure SavePurchaseInvoiceReport(DocumentNo: Code[20]; ShowInternalInfo: Boolean; LogInteraction: Boolean)
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseInvoice: Report "Purchase - Invoice";
    begin
        LibraryVariableStorage.Enqueue(0); // Using 0 for No. of Copies.
        LibraryVariableStorage.Enqueue(ShowInternalInfo);
        LibraryVariableStorage.Enqueue(LogInteraction);

        Commit();
        Clear(PurchaseInvoice);
        PurchInvHeader.SetRange("No.", DocumentNo);
        PurchaseInvoice.SetTableView(PurchInvHeader);
        PurchaseInvoice.Run();
    end;

    local procedure SavePurchaseOrderReport(DocumentNo: Code[20]; ShowInternalInfo: Boolean; ArchiveDocument: Boolean; LogInteraction: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryVariableStorage.Enqueue(ShowInternalInfo);
        LibraryVariableStorage.Enqueue(ArchiveDocument);
        LibraryVariableStorage.Enqueue(LogInteraction);
        PurchaseHeader.SetRange("No.", DocumentNo);
        Commit();
        REPORT.Run(REPORT::Order, true, false, PurchaseHeader);
    end;

    local procedure SaveStandardPurchaseOrderReport(DocumentNo: Code[20]; LogInteraction: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryVariableStorage.Enqueue(LogInteraction);
        PurchaseHeader.SetRange("No.", DocumentNo);
        Commit();
        REPORT.Run(REPORT::"Standard Purchase - Order", true, false, PurchaseHeader);
    end;

    local procedure SavePurchaseReturnShipment(No: Code[20]; ShowInternalInfo: Boolean; ShowCorrectionLines: Boolean; ShowLogInteract: Boolean)
    var
        ReturnShipmentHeader: Record "Return Shipment Header";
        PurchaseReturnShipment: Report "Purchase - Return Shipment";
    begin
        Clear(ReturnShipmentHeader);
        ReturnShipmentHeader.SetRange("No.", No);
        PurchaseReturnShipment.SetTableView(ReturnShipmentHeader);
        PurchaseReturnShipment.InitializeRequest(0, ShowInternalInfo, ShowCorrectionLines, ShowLogInteract);  // Using 0 for No. of Copies.
        Commit();
        PurchaseReturnShipment.Run();
        LibraryReportDataset.LoadDataSetFile();
    end;

    local procedure SaveVendorRegisterReport(No: Integer; AmountLCY: Boolean)
    var
        GLRegister: Record "G/L Register";
        VendorRegister: Report "Vendor Register";
    begin
        Clear(VendorRegister);
        GLRegister.SetRange("No.", No);
        VendorRegister.SetTableView(GLRegister);
        VendorRegister.InitializeRequest(AmountLCY);
        VendorRegister.Run();
    end;

    local procedure UpdateAddnlReportingCurrency(var OldAdditionalReportingCurrency: Code[10]; AdditionalReportingCurrency: Code[10])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        OldAdditionalReportingCurrency := GeneralLedgerSetup."Additional Reporting Currency";
        GeneralLedgerSetup."Additional Reporting Currency" := AdditionalReportingCurrency;
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdateVendorInvoiceNo(var PurchaseHeader: Record "Purchase Header"; VendorInvoiceNo: Code[35])
    begin
        PurchaseHeader.Validate("Vendor Invoice No.", VendorInvoiceNo);
        PurchaseHeader.Modify(true);
    end;

    local procedure UpdateGlobalDims()
    var
        Dimension: array[2] of Record Dimension;
    begin
        if (LibraryERM.GetGlobalDimensionCode(1) = '') or (LibraryERM.GetGlobalDimensionCode(2) = '') then begin
            LibraryDimension.CreateDimension(Dimension[1]);
            LibraryDimension.CreateDimension(Dimension[2]);
            LibraryDimension.RunChangeGlobalDimensions(Dimension[1].Code, Dimension[2].Code);
        end;
    end;

    local procedure VerifyCurrencyCode(BuyFromVendorNo: Code[20]; CurrencyCode: Code[10])
    var
        Vendor: Record Vendor;
    begin
        LibraryReportDataset.LoadDataSetFile();
        Vendor.Get(BuyFromVendorNo);
        Vendor.CalcFields("Balance (LCY)");
        LibraryReportDataset.SetRange('Vendor__No__', Format(Vendor."No."));
        if LibraryReportDataset.GetNextRow() then begin
            LibraryReportDataset.AssertCurrentRowValueEquals('Currency2_Code', CurrencyCode);
            LibraryReportDataset.AssertCurrentRowValueEquals('InVendBalanceDueLCY_2', -Vendor."Balance (LCY)");
        end;
    end;

    local procedure VerifyChargeItem(DocumentNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.FindSet();
        repeat
            LibraryReportDataset.SetRange('Purchase_Line__Type', Format(PurchaseLine.Type));
            if not LibraryReportDataset.GetNextRow() then
                Error(RowNotFoundErr, 'Purchase_Line__Type', Format(PurchaseLine.Type));
            LibraryReportDataset.AssertCurrentRowValueEquals('Purchase_Line___No__', PurchaseLine."No.");
            LibraryReportDataset.AssertCurrentRowValueEquals('Purchase_Line__Description', PurchaseLine.Description);
            LibraryReportDataset.AssertCurrentRowValueEquals('Purchase_Line__Quantity', PurchaseLine.Quantity);
            LibraryReportDataset.AssertCurrentRowValueEquals('Purchase_Line___Line_Amount_', PurchaseLine.Amount);
        until PurchaseLine.Next() = 0;
    end;

    local procedure VerifyPostedCreditMemo(DocumentNo: Code[20])
    var
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
    begin
        PurchCrMemoLine.SetRange("Document No.", DocumentNo);
        PurchCrMemoLine.SetRange(Type, PurchCrMemoLine.Type::Item);
        PurchCrMemoLine.FindSet();
        repeat
            LibraryReportDataset.AssertElementWithValueExists('Quantity_PurchCrMemoLine', PurchCrMemoLine.Quantity);
            LibraryReportDataset.AssertElementWithValueExists('LineAmt_PurchCrMemoLine', PurchCrMemoLine."Line Amount");
            LibraryReportDataset.AssertElementWithValueExists('DirUntCst_PurchCrMemoLine', PurchCrMemoLine."Direct Unit Cost");
        until PurchCrMemoLine.Next() = 0;
    end;

    local procedure VerifyInteractionLogEntry(DocumentType: Enum "Interaction Log Entry Document Type"; DocumentNo: Code[20])
    var
        InteractionLogEntry: Record "Interaction Log Entry";
    begin
        InteractionLogEntry.SetRange("Document Type", DocumentType);
        InteractionLogEntry.SetRange("Document No.", DocumentNo);
        InteractionLogEntry.FindFirst();
    end;

    local procedure VerifyPostedInvoice(DocumentNo: Code[20])
    var
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        LibraryReportDataset.LoadDataSetFile();
        PurchInvLine.SetRange("Document No.", DocumentNo);
        PurchInvLine.FindSet();

        repeat
            LibraryReportDataset.AssertElementWithValueExists('Qty_PurchInvLine', PurchInvLine.Quantity);
            LibraryReportDataset.AssertElementWithValueExists('LineAmt_PurchInvLine', PurchInvLine."Line Amount");
            LibraryReportDataset.AssertElementWithValueExists('DirectUnitCost_PurchInvLine', PurchInvLine."Direct Unit Cost");
        until PurchInvLine.Next() = 0;
    end;

    local procedure VerifyPurchaseArchive(DocumentType: Enum "Purchase Document Type"; No: Code[20])
    var
        PurchaseHeaderArchive: Record "Purchase Header Archive";
        PurchaseLineArchive: Record "Purchase Line Archive";
    begin
        PurchaseHeaderArchive.SetRange("Document Type", DocumentType);
        PurchaseHeaderArchive.SetRange("No.", No);
        PurchaseHeaderArchive.FindFirst();

        PurchaseLineArchive.SetRange("Document Type", PurchaseHeaderArchive."Document Type");
        PurchaseLineArchive.SetRange("Document No.", PurchaseHeaderArchive."No.");
        PurchaseLineArchive.FindFirst();
    end;

    local procedure VerifyReturnShipment(DocumentNo: Code[20])
    var
        ReturnShipmentLine: Record "Return Shipment Line";
    begin
        GetReturnShipmentLine(ReturnShipmentLine, DocumentNo);
        LibraryReportDataset.SetRange('No_ReturnShipmentLine', ReturnShipmentLine."No.");
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFoundErr, 'No_ReturnShipmentLine', ReturnShipmentLine."No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('No_ReturnShipmentLine',
          CopyStr(ReturnShipmentLine."No.", 1,
            LibraryUtility.GetFieldLength(DATABASE::"Return Shipment Line", ReturnShipmentLine.FieldNo("No."))));
        LibraryReportDataset.AssertCurrentRowValueEquals('Qty_ReturnShipmentLine', ReturnShipmentLine.Quantity);
        LibraryReportDataset.AssertCurrentRowValueEquals('UOM_ReturnShpLine', ReturnShipmentLine."Unit of Measure");
    end;

    local procedure VerifyVATEntry(DocumentNo: Code[20]; TotalAmount: Decimal; VATAmount: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        VATEntry: Record "VAT Entry";
        TotalAmountInDec: Variant;
        VATAmountInDec: Variant;
    begin
        GeneralLedgerSetup.Get();
        LibraryReportDataset.SetRange('DocumentNo_VatEntry', DocumentNo);
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFoundErr, 'DocumentNo_VatEntry', DocumentNo);
        LibraryReportDataset.FindCurrentRowValue('Base_VatEntry', TotalAmountInDec);
        Assert.AreNearlyEqual(
          TotalAmount, TotalAmountInDec, GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(ValidationErr, VATEntry.FieldCaption(Amount), TotalAmount));
        LibraryReportDataset.FindCurrentRowValue('Amount_VatEntry', VATAmountInDec);
        Assert.AreNearlyEqual(
          VATAmount, VATAmountInDec, GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(ValidationErr, VATEntry.FieldCaption(Amount), VATAmount));
    end;

    local procedure VerifyYourReferencePurchaseCrMemo(YourReference: Text[35])
    begin
        LibraryReportValidation.OpenExcelFile();
        LibraryReportValidation.VerifyCellValue(26, 5, YourReference);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        // Handler for confirmation messages, always send positive reply.
        Reply := true;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReportHandlerPurchaseInvoice(var PurchaseInvoice: TestRequestPage "Purchase - Invoice")
    var
        NoOfCopies: Variant;
        ShowInternalInfo: Variant;
        LogInteraction: Variant;
    begin
        LibraryVariableStorage.Dequeue(NoOfCopies);
        LibraryVariableStorage.Dequeue(ShowInternalInfo);
        LibraryVariableStorage.Dequeue(LogInteraction);
        PurchaseInvoice.NoOfCopies.SetValue(NoOfCopies);
        PurchaseInvoice.ShowInternalInfo.SetValue(ShowInternalInfo);
        PurchaseInvoice.LogInteraction.SetValue(LogInteraction);
        PurchaseInvoice.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VendorSummaryAgingRequestPageHandler(var VendorSummaryAging: TestRequestPage "Vendor - Summary Aging")
    begin
        VendorSummaryAging.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHPurchaseCreditMemo(var PurchaseCreditMemo: TestRequestPage "Purchase - Credit Memo")
    begin
        PurchaseCreditMemo.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RequestPagePurchaseCreditMemo(var PurchaseCreditMemo: TestRequestPage "Purchase - Credit Memo")
    begin
        PurchaseCreditMemo.SaveAsExcel(LibraryReportValidation.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHVATExceptions(var VATExceptions: TestRequestPage "VAT Exceptions")
    var
        PostingDate: Variant;
        VATProdPostingGroup: Variant;
        AddCurrency: Variant;
        IncludeReversedEntries: Variant;
        DocumentNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(PostingDate);
        LibraryVariableStorage.Dequeue(VATProdPostingGroup);
        LibraryVariableStorage.Dequeue(DocumentNo);
        LibraryVariableStorage.Dequeue(AddCurrency);
        LibraryVariableStorage.Dequeue(IncludeReversedEntries);
        VATExceptions.AmountsInAddReportingCurrency.SetValue(AddCurrency);
        VATExceptions.IncludeReversedEntries.SetValue(IncludeReversedEntries);
        VATExceptions."VAT Entry".SetFilter("Posting Date", Format(PostingDate));
        VATExceptions."VAT Entry".SetFilter("VAT Prod. Posting Group", VATProdPostingGroup);
        VATExceptions."VAT Entry".SetFilter("Document No.", DocumentNo);
        VATExceptions.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHPurchaseDocumentTest(var PurchaseDocumentTest: TestRequestPage "Purchase Document - Test")
    begin
        PurchaseDocumentTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHPurchasePrepmtDocTest(var PurchasePrepmtDocTest: TestRequestPage "Purchase Prepmt. Doc. - Test")
    begin
        PurchasePrepmtDocTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHOrder(var "Order": TestRequestPage "Order")
    var
        ShowInternalInfo: Variant;
        ArchiveDocument: Variant;
        LogInteraction: Variant;
    begin
        LibraryVariableStorage.Dequeue(ShowInternalInfo);
        LibraryVariableStorage.Dequeue(ArchiveDocument);
        LibraryVariableStorage.Dequeue(LogInteraction);
        Order.NoofCopies.SetValue(0);
        Order.ShowInternalInformation.SetValue(ShowInternalInfo);
        Order.ArchiveDocument.SetValue(ArchiveDocument);
        Order.LogInteraction.SetValue(LogInteraction);
        Order.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHStandardPurchaseOrder(var StandardPurchaseOrder: TestRequestPage "Standard Purchase - Order")
    var
        LogInteraction: Variant;
    begin
        LibraryVariableStorage.Dequeue(LogInteraction);
        StandardPurchaseOrder.LogInteraction.SetValue(LogInteraction);
        StandardPurchaseOrder.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHVendorList(var VendorList: TestRequestPage "Vendor - List")
    begin
        VendorList.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHVendorRegister(var VendorRegister: TestRequestPage "Vendor Register")
    begin
        VendorRegister.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHVendorTop10List(var VendorTop10List: TestRequestPage "Vendor - Top 10 List")
    var
        ShowType: Variant;
    begin
        LibraryVariableStorage.Dequeue(ShowType);
        VendorTop10List.Show.SetValue(ShowType);
        VendorTop10List.Quantity.SetValue(LibraryRandom.RandInt(5));
        VendorTop10List.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHVendorItemPurchases(var VendorItemPurchases: TestRequestPage "Vendor/Item Purchases")
    begin
        VendorItemPurchases.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHPurchaseReturnShipment(var PurchaseReturnShipment: TestRequestPage "Purchase - Return Shipment")
    begin
        PurchaseReturnShipment.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseOrderRequestPageHandler(var "Order": TestRequestPage "Order")
    begin
        Order.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StandardPurchaseOrderRequestPageHandler(var StandardPurchaseOrder: TestRequestPage "Standard Purchase - Order")
    begin
        StandardPurchaseOrder.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseQuoteADChangeRequestPageHandler(var PurchaseQuote: TestRequestPage "Purchase - Quote")
    begin
        if not LibraryVariableStorage.DequeueBoolean() then
            PurchaseQuote.ArchiveDocument.SetValue(not PurchaseQuote.ArchiveDocument.AsBoolean());

        LibraryVariableStorage.Enqueue(PurchaseQuote.ArchiveDocument.Value);
        PurchaseQuote.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure OrderADChangeRequestPageHandler(var "Order": TestRequestPage "Order")
    begin
        if not LibraryVariableStorage.DequeueBoolean() then
            Order.ArchiveDocument.SetValue(not Order.ArchiveDocument.AsBoolean());

        LibraryVariableStorage.Enqueue(Order.ArchiveDocument.Value);
        Order.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BlanketPurchaseOrderADChangeRequestPageHandler(var BlanketPurchaseOrder: TestRequestPage "Blanket Purchase Order")
    begin
        if not LibraryVariableStorage.DequeueBoolean() then
            BlanketPurchaseOrder.ArchiveDocument.SetValue(not BlanketPurchaseOrder.ArchiveDocument.AsBoolean());

        LibraryVariableStorage.Enqueue(BlanketPurchaseOrder.ArchiveDocument.Value);
        BlanketPurchaseOrder.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StandardPurchaseOrderADChangeRequestPageHandler(var StandardPurchaseOrder: TestRequestPage "Standard Purchase - Order")
    begin
        if not LibraryVariableStorage.DequeueBoolean() then
            StandardPurchaseOrder.ArchiveDocument.SetValue(not StandardPurchaseOrder.ArchiveDocument.AsBoolean());

        LibraryVariableStorage.Enqueue(StandardPurchaseOrder.ArchiveDocument.Value);
        StandardPurchaseOrder.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

