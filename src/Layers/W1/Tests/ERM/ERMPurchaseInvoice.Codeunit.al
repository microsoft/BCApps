codeunit 134328 "ERM Purchase Invoice"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        // [FEATURE] [Purchase] [Invoice]
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryERM: Codeunit "Library - ERM";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryUtilityOnPrem: Codeunit "Library - Utility OnPrem";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryCosting: Codeunit "Library - Costing";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryJob: Codeunit "Library - Job";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        CopyFromToPriceListLine: Codeunit CopyFromToPriceListLine;
        LibraryTemplates: Codeunit "Library - Templates";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        isInitialized: Boolean;
        VATAmountErr: Label 'VAT Amount must be %1 in VAT Amount Line.', Comment = '%1 = Amount';
        FieldErr: Label 'Number of Lines for Purchase Line and Purchase Receipt Line must be Equal.';
        AmountErr: Label '%1 must be Equal in %2.', Comment = '%1 = Field Name, %2 = Field Value';
        CurrencyErr: Label 'Currency Code must be Equal in %1.', Comment = '%1 = Table Name';
        InvoiceDiscountErr: Label '%1 must be %2 in %3.', Comment = '%1 = Field Name, %2 = Amount, %3 = Table Name';
        ValidateErr: Label '%1 must be %2 in %3 Entry No. = %4.', Comment = '%1 = Field Name, %2 =Amount, %3 = Table Name, %4 = Entry No.';
        PageNotOpenErr: Label 'The TestPage is not open.';
        NoOfRecordErr: Label 'No. of records must be 1.';
        WhseReceiveIsRequiredErr: Label 'Warehouse Receive is required for Line No.';
        CopyDocDateOrderConfirmMsg: Label 'The Posting Date of the copied document is different from the Posting Date of the original document. The original document already has a Posting No. based on a number series with date order. When you post the copied document, you may have the wrong date order in the posted documents.\Do you want to continue?';
        DocumentShouldNotBeCopiedErr: Label 'Document should not be copied';
        DocumentShouldBeCopiedErr: Label 'Document should be copied';
        WrongConfirmationMsgErr: Label 'Wrong confirmation message';
        TestFieldTok: Label 'TestField';
        NegativeAmountErr: Label 'Amount must be negative';
        ContactShouldNotBeEditableErr: Label 'Contact should not be editable when vendor is not selected.';
        ContactShouldBeEditableErr: Label 'Contact should be editable when vendorr is selected.';
        RemitToCodeShouldNotBeEditableErr: Label 'Remit-to code should not be editable when vendor is not selected.';
        RemitToCodeShouldBeEditableErr: Label 'Remit-to code should be editable when vendorr is selected.';
        PayToAddressFieldsNotEditableErr: Label 'Pay-to address fields should not be editable.';
        PayToAddressFieldsEditableErr: Label 'Pay-to address fields should be editable.';
        ConfirmCreateEmptyPostedInvMsg: Label 'Deleting this document will cause a gap in the number series for posted invoices. An empty posted invoice %1 will be created', Comment = '%1 - Invoice No.';
        PurchaseAccountIsMissingTxt: Label 'Purch. Account is missing in General Posting Setup.';
        PurchaseVatAccountIsMissingTxt: Label 'Purchase VAT Account is missing in VAT Posting Setup.';
        CannotAllowInvDiscountErr: Label 'The value of the Allow Invoice Disc. field is not valid when the VAT Calculation Type field is set to "Full VAT".';
        DocumentNoErr: Label 'Document No. are not equal.';
        AmountZeroErr: Label 'Amount must be zero';
        AmountMustSameErr: Label 'Amount must be same';
        ChangeExtendedTextErr: Label 'You cannot change %1 for Extended Text Line.', Comment = '%1= Field Caption';

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceCreation()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Test New Purchase Invoice creation.

        // Setup.
        Initialize();

        // Exercise: Create Purchase Invoice.
        CreatePurchaseInvoice(PurchaseHeader, PurchaseLine, CreateVendor(''));

        // Verify: Verify Purchase Invoice created.
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATAmountOnPurchaseInvoice()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATAmountLine: Record "VAT Amount Line";
        QtyType: Option General,Invoicing,Shipping;
    begin
        // Create a Purchase Invoice, Calculates applicable VAT for a VAT Posting Group and verify it with VAT Amount Line.

        // Setup.
        Initialize();
        CreatePurchaseInvoice(PurchaseHeader, PurchaseLine, CreateVendor(''));

        // Exercise: Calculate VAT Amount on Purchase Invoice.
        LibraryLowerPermissions.SetAccountPayables();
        PurchaseLine.CalcVATAmountLines(QtyType::Invoicing, PurchaseHeader, PurchaseLine, VATAmountLine);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        PurchaseHeader.CalcFields(Amount);

        // Verify: Verify VAT Amount on Purchase Invoice.
        GeneralLedgerSetup.Get();
        Assert.AreNearlyEqual(
          PurchaseHeader.Amount * PurchaseLine."VAT %" / 100, VATAmountLine."VAT Amount", GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(VATAmountErr, PurchaseHeader.Amount * PurchaseLine."VAT %" / 100));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceReport()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseDocumentTest: Report "Purchase Document - Test";
        FilePath: Text[1024];
    begin
        // Create New Purchase Invoice and save as external file and verify saved files have data.

        // Setup.
        Initialize();
        CreatePurchaseInvoice(PurchaseHeader, PurchaseLine, CreateVendor(''));

        // Exercise: Generate Report as external file for Purchase Invoice.
        LibraryLowerPermissions.SetPurchDocsCreate();
        Clear(PurchaseDocumentTest);
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseHeader.SetRange("No.", PurchaseHeader."No.");
        PurchaseDocumentTest.SetTableView(PurchaseHeader);
        FilePath := TemporaryPath + Format(PurchaseHeader."Document Type") + PurchaseHeader."No." + '.xlsx';
        PurchaseDocumentTest.SaveAsExcel(FilePath);

        // Verify: Verify that saved files have some data.
        LibraryUtilityOnPrem.CheckFileNotEmpty(FilePath);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        VATPostingSetup: Record "VAT Posting Setup";
        NoSeries: Codeunit "No. Series";
        PurchaseLineCount: Integer;
        PostedInvoiceNo: Code[20];
        DocumentNo: Code[20];
    begin
        // Create and Post Purchase Invoice and verify Purchase Posted Receipt Line,Vendor Ledger, GL Entry, and VAT Entry.

        // Setup: Update Purchase and Payable Setup to generate Posted Purchase Receipt document from Purchase Invoice.
        // Create Purchase Invoice, Store Line count of Purchase Invoice, Posted Receipt No. and Posted Invoice No. in a variable.
        Initialize();
        UpdatePurchaseAndPayableSetup(true, false);
        FindVATPostingSetup(VATPostingSetup);
        CreatePurchaseInvoice(PurchaseHeader, PurchaseLine, CreateAndModifyVendor('', VATPostingSetup."VAT Bus. Posting Group"));
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type");
        PurchaseLineCount := PurchaseLine.Count();
        DocumentNo := NoSeries.PeekNextNo(PurchaseHeader."Receiving No. Series");

        // Exercise: Post Purchase Invoice.
        LibraryLowerPermissions.SetPurchDocsPost();
        PostedInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify Posted Purchase Receipt,GL Entry, Vendor Ledger Entry, Value Entry and VAT Entry.
        PurchRcptLine.SetRange("Document No.", DocumentNo);
        Assert.AreEqual(PurchaseLineCount, PurchRcptLine.Count, FieldErr);
        PurchInvHeader.Get(PostedInvoiceNo);
        PurchInvHeader.CalcFields(Amount, "Amount Including VAT");
        VerifyGLEntry(PostedInvoiceNo, PurchInvHeader."Amount Including VAT");
        VerifyVendorLedgerEntry(PostedInvoiceNo, PurchInvHeader."Amount Including VAT");
        VerifyVATEntry(PostedInvoiceNo, PurchInvHeader."Amount Including VAT");
        VerifyValueEntry(PostedInvoiceNo, PurchInvHeader.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseInvoiceWithPreviewTokInPostingNo()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        PostedInvoiceNo: Code[20];
    begin
        // Create and Post Purchase Invoice with Posting No as *** and verify that it gets posted and *** entries are not created.

        // Create Purchase Invoice, set 'Posting No.' to ***.
        Initialize();
        FindVATPostingSetup(VATPostingSetup);
        CreatePurchaseInvoice(PurchaseHeader, PurchaseLine, CreateAndModifyVendor('', VATPostingSetup."VAT Bus. Posting Group"));
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader."Posting No." := '***';
        PurchaseHeader.Modify(true);

        // Exercise: Post Purchase Invoice.
        LibraryLowerPermissions.SetPurchDocsPost();
        PostedInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify Posted Purchase Invoice does not have *** as the id..
        Assert.AreNotEqual(PostedInvoiceNo, '***', '*** entry created');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseInvoiceWhileModifyingLineDuringPosting()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvLine: Record "Purch. Inv. Line";
        ERMPurchaseInvoice: codeunit "ERM Purchase Invoice";
        PostedDocumentNo: Code[20];
    begin
        // [SCENARIO 315920] Line is getting refreshed inside posting of a Purchase Invoice.
        Initialize();
        // [GIVEN] Create Purchase Order, where Description is 'A' in the line.
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, CreateVendor(''), PurchaseHeader."Document Type"::Order);
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
        PurchaseLine.Validate(Quantity, 2);
        PurchaseLine.Validate("Direct Unit Cost", 10);
        PurchaseLine.Validate("Qty. to Invoice", 1);
        PurchaseLine."Description 2" := 'A';
        PurchaseLine.Modify(true);

        // [GIVEN] Subscribe to COD90.OnBeforePostUpdateOrderLineModifyTempLine to set Description to 'X'
        BindSubscription(ERMPurchaseInvoice);
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Description is still 'A', not changed
        PurchInvLine.Get(PostedDocumentNo, PurchaseLine."Line No.");
        PurchInvLine.TestField("Description 2", 'A');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchaseInvoiceReport()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseInvoice: Report "Purchase - Invoice";
        NoSeries: Codeunit "No. Series";
        FilePath: Text[1024];
        PostedDocumentNo: Code[20];
    begin
        // Test if Post a Purchase Invoice and generate Posted Purchase Invoice Report.

        // Setup.
        Initialize();
        CreatePurchaseInvoice(PurchaseHeader, PurchaseLine, CreateVendor(''));
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
        PostedDocumentNo := NoSeries.PeekNextNo(PurchaseHeader."Posting No. Series");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Exercise: Generate Report as external file for Posted Purchase Invoice.
        LibraryLowerPermissions.SetPurchDocsPost();
        Clear(PurchaseInvoice);
        PurchInvHeader.SetRange("No.", PostedDocumentNo);
        PurchaseInvoice.SetTableView(PurchInvHeader);
        FilePath := TemporaryPath + Format('Purchase - Invoice') + PurchInvHeader."No." + '.xlsx';
        PurchaseInvoice.SaveAsExcel(FilePath);

        // Verify: Verify that Saved files have some data.
        LibraryUtilityOnPrem.CheckFileNotEmpty(FilePath);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceForWhseLocation()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        WarehouseEmployee: Record "Warehouse Employee";
        NoSeries: Codeunit "No. Series";
        PostedDocumentNo: Code[20];
    begin
        // Test if Post a Purchase Invoice with Warehouse Location and verify Posted Purchase Receipt Entry.

        // Setup: Update Purchase and Payable Setup to generate Posted Purchase Receipt document from Purchase Invoice.
        Initialize();
        LibraryLowerPermissions.SetOutsideO365Scope();
        UpdatePurchaseAndPayableSetup(true, false);

        // Exercise: Create Purchase Invoice for Warehouse Location. Using RANDOM Quantity for Purchase Line, value is not important.
        CreatePurchaseHeader(PurchaseHeader, CreateVendor(''), PurchaseHeader."Document Type"::Invoice);
        PurchaseHeader.Validate("Location Code", UpdateWarehouseLocation(true));
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(), LibraryRandom.RandInt(10));
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, PurchaseLine."Location Code", false);
        PostedDocumentNo := NoSeries.PeekNextNo(PurchaseHeader."Receiving No. Series");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify Quantity Posted Receipt Document.
        PurchRcptLine.SetRange("Document No.", PostedDocumentNo);
        PurchRcptLine.FindFirst();
        Assert.AreEqual(PurchaseLine.Quantity, PurchRcptLine.Quantity, FieldErr);

        // Tear Down: Rollback Setup changes for Location and Warehouse Employee.
        UpdateWarehouseLocation(false);
        WarehouseEmployee.Get(UserId, PurchaseLine."Location Code");
        WarehouseEmployee.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LineDiscountOnPurchaseInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLineDiscount: Record "Purchase Line Discount";
        PriceListLine: Record "Price List Line";
        PostedDocumentNo: Code[20];
    begin
        // Test Line Discount on Purchase Invoice, Post Invoice and verify Posted GL Entry.

        // Setup: Create Line Discount Setup.
        Initialize();
        SetupLineDiscount(PurchaseLineDiscount);
        CopyFromToPriceListLine.CopyFrom(PurchaseLineDiscount, PriceListLine);

        // Exercise: Create and Post Invoice with Random Quantity. Take Quantity greater than Purchase Line Discount Minimum Quantity.
        LibraryLowerPermissions.SetPurchDocsPost();
        CreatePurchaseHeader(PurchaseHeader, PurchaseLineDiscount."Vendor No.", PurchaseHeader."Document Type"::Invoice);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, PurchaseLineDiscount."Item No.",
          PurchaseLineDiscount."Minimum Quantity" + LibraryRandom.RandInt(10));
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify Purchase Line and Posted G/L Entry for Line Discount Amount.
        VerifyLineDiscountAmount(
          PurchaseLine, PostedDocumentNo,
          (PurchaseLine.Quantity * PurchaseLine."Direct Unit Cost") * PurchaseLineDiscount."Line Discount %" / 100);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceItemOnPurchaseInvoice()
    var
        Item: Record Item;
        PurchaseLineDiscount: Record "Purchase Line Discount";
    begin
        // Test Line Service Item gets posted and verify Value Entries are non Inventoriable

        // Setup: Create Line Discount Setup.
        Initialize();
        Item.Get(CreateServiceItem());
        SetupLineDiscount(PurchaseLineDiscount);
        // Exercise: Create and Post Invoice with Random Quantity. Take Quantity greater than Purchase Line Discount Minimum Quantity.
        LibraryLowerPermissions.SetPurchDocsPost();
        PostItemAndVerifyValueEntries(Item, PurchaseLineDiscount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NonStockItemOnPurchaseInvoice()
    var
        Item: Record Item;
        PurchaseLineDiscount: Record "Purchase Line Discount";
    begin
        // Test Line Service Item gets posted and verify Value Entries are non Inventoriable

        // Setup: Create Line Discount Setup.
        Initialize();
        Item.Get(CreateNonStockItem());
        SetupLineDiscount(PurchaseLineDiscount);
        // Exercise: Create and Post Invoice with Random Quantity. Take Quantity greater than Purchase Line Discount Minimum Quantity.
        LibraryLowerPermissions.SetPurchDocsPost();
        PostItemAndVerifyValueEntries(Item, PurchaseLineDiscount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvDiscountOnPurchaseInvoice()
    var
        VendorInvoiceDisc: Record "Vendor Invoice Disc.";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PostedDocumentNo: Code[20];
    begin
        // Create New Invoice Discount Setup for Vendor and make new Purchase Invoice, Post Invoice and verify Posted GL Entry.

        // Setup: Create Invoice Discount Setup.
        Initialize();
        SetupInvoiceDiscount(VendorInvoiceDisc, LibraryRandom.RandInt(10));

        // Exercise: Create Purchase Invoice using Random value for Quantity, calculate Invoice Discount and Post Invoice.
        CreatePurchaseHeader(PurchaseHeader, VendorInvoiceDisc.Code, PurchaseHeader."Document Type"::Invoice);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(), LibraryRandom.RandInt(10));

        // Invoice Value always greater than Minimum Amount of Invoice Discount Setup.
        LibraryLowerPermissions.SetPurchDocsPost();
        PurchaseLine.Validate("Direct Unit Cost", VendorInvoiceDisc."Minimum Amount");
        PurchaseLine.Modify(true);
        CODEUNIT.Run(CODEUNIT::"Purch.-Calc.Discount", PurchaseLine);
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify Purchase Line and Posted G/L Entry for Invoice Discount Amount.
        VerifyInvoiceDiscountAmount(
          PurchaseLine, PostedDocumentNo,
          (PurchaseLine.Quantity * PurchaseLine."Direct Unit Cost") * VendorInvoiceDisc."Discount %" / 100);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceWithFCY()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        PostedDocumentNo: Code[20];
    begin
        // Create and Post a Purchase Invoice with Currency and verify currency on Posted Purchase Invoice Entry.

        // Setup.
        Initialize();

        // Exercise: Create Purchase Invoice, attach new Currency on Purchase Invoice and Post Invoice.
        CreatePurchaseHeader(PurchaseHeader, CreateVendor(''), PurchaseHeader."Document Type"::Invoice);
        PurchaseHeader.Validate("Currency Code", CreateCurrency());
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(), LibraryRandom.RandInt(10));
        LibraryLowerPermissions.SetPurchDocsPost();
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify Currency Code in Purchase Line and Posted Purchase Invoice Header.
        PurchInvHeader.Get(PostedDocumentNo);
        Assert.AreEqual(
          PurchaseHeader."Currency Code", PurchaseLine."Currency Code",
          StrSubstNo(CurrencyErr, PurchaseLine.TableCaption()));
        Assert.AreEqual(
          PurchaseHeader."Currency Code", PurchInvHeader."Currency Code",
          StrSubstNo(CurrencyErr, PurchInvHeader.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceWithSourceCurrency()
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        GLEntry: Record "G/L Entry";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        PostedDocumentNo: Code[20];
    begin
        // Create and Post a Purchase Invoice with Currency and verify Source Currency Amount on G/L Entries

        // Setup.
        Initialize();

        // Exercise: Create Purchase Invoice, attach new Currency on Purchase Invoice and Post Invoice.
        CreatePurchaseHeader(PurchaseHeader, CreateVendor(''), PurchaseHeader."Document Type"::Invoice);
        PurchaseHeader.Validate("Currency Code", CreateCurrency());
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(), LibraryRandom.RandInt(10));
        LibraryLowerPermissions.SetPurchDocsPost();
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify Currency Code in Purchase Line and Posted Purchase Invoice Header.
        PurchInvHeader.Get(PostedDocumentNo);
        Assert.AreEqual(
          PurchaseHeader."Currency Code", PurchaseLine."Currency Code",
          StrSubstNo(CurrencyErr, PurchaseLine.TableCaption()));
        Assert.AreEqual(
          PurchaseHeader."Currency Code", PurchInvHeader."Currency Code",
          StrSubstNo(CurrencyErr, PurchInvHeader.TableCaption()));

        // Verify: Source Currency Amounts in G/L Entries
        GLEntry.SetRange("Document No.", PurchInvHeader."No.");
        GLEntry.FindSet();
        repeat
            if GLEntry."Source Currency Amount" <> 0 then
                Assert.AreNearlyEqual(
                    GLEntry."Source Currency Amount",
                    CurrencyExchangeRate.ExchangeAmtLCYToFCY(
                        PurchInvHeader."Posting Date", PurchInvHeader."Currency Code", GLEntry.Amount, PurchInvHeader."Currency Factor"),
                    0.01, 'incorrect Source Currency Amount in G/L Entry');
        until GLEntry.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceBeforeRelease()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineDiscountAmount: Decimal;
        OutStandingAmountLCY: Decimal;
    begin
        // Check Purchase Lines Field after Create and before Release Purchase Invoice with Currency.

        // Setup.
        Initialize();
        CreatePurchaseInvoiceCurrency(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice);

        // Exercise: Calculate Line Discount and Outstanding Amount LCY field  on Purchase Line.
        LineDiscountAmount := Round(PurchaseLine.Quantity * PurchaseLine."Direct Unit Cost" * PurchaseLine."Line Discount %" / 100);
        OutStandingAmountLCY := Round(LibraryERM.ConvertCurrency(PurchaseLine."Line Amount", PurchaseHeader."Currency Code", '', WorkDate()));
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");

        // Verify: Verify Purchase Line fields before releasing.
        PurchaseLine.TestField("Line Discount Amount", LineDiscountAmount);
        PurchaseLine.TestField("VAT Base Amount", PurchaseLine.Amount);
        PurchaseLine.TestField("Line Amount", PurchaseLine."Amount Including VAT");
        PurchaseLine.TestField("Outstanding Amount (LCY)", OutStandingAmountLCY);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceAfterRelease()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Currency: Record Currency;
        GeneralLedgerSetup: Record "General Ledger Setup";
        LineAmount: Decimal;
        RoundingPrecision: Decimal;
    begin
        // Check Purchase Lines Field after Create and Release Purchase Invoice with Currency.

        // Setup.
        Initialize();
        CreatePurchaseInvoiceCurrency(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice);
        if Currency.Get(PurchaseLine."Currency Code") then
            RoundingPrecision := Currency."Amount Rounding Precision";
        if RoundingPrecision = 0 then begin
            GeneralLedgerSetup.Get();
            RoundingPrecision := GeneralLedgerSetup."Amount Rounding Precision";
        end;
        LineAmount :=
          Round(
            PurchaseLine."Line Amount" - (PurchaseLine."Line Amount" * PurchaseLine."VAT %") / (PurchaseLine."VAT %" + 100),
            RoundingPrecision);

        // Exercise.
        LibraryLowerPermissions.SetPurchDocsPost();
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        PurchaseHeader.CalcFields("Amount Including VAT");
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");

        // Verify: Verify Purchase Line Fields after Releasing.
        PurchaseLine.TestField("VAT Base Amount", LineAmount);
        PurchaseLine.TestField(Amount, LineAmount);
        PurchaseLine.TestField("Amount Including VAT", PurchaseHeader."Amount Including VAT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderAfterInvDiscount()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchCalcDiscount: Codeunit "Purch.-Calc.Discount";
        InvDiscAmountToInvoice: Decimal;
        InvoiceDiscount: Decimal;
        TotalAmount: Decimal;
    begin
        // Check Purchase Lines Field after Create and Calculate Invoice Discount on Purchase order with Currency.

        // Setup.
        Initialize();
        GeneralLedgerSetup.Get();
        InvoiceDiscount := CreatePurchaseInvoiceCurrency(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order);
        PurchaseLine.Validate("Qty. to Invoice", PurchaseLine.Quantity / 2);
        PurchaseLine.Modify(true);
        TotalAmount := PurchaseLine."Direct Unit Cost" * PurchaseLine."Qty. to Invoice";
        InvDiscAmountToInvoice := Round((TotalAmount - (TotalAmount * PurchaseLine."Line Discount %" / 100)) * InvoiceDiscount / 100);

        // Exercise.
        LibraryLowerPermissions.SetPurchDocsCreate();
        PurchCalcDiscount.CalculateInvoiceDiscount(PurchaseHeader, PurchaseLine);
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");

        // Verify: Verify Purchase Line Fields after Calculate Invoice Discount.
        Assert.AreNearlyEqual(
          InvDiscAmountToInvoice, PurchaseLine."Inv. Disc. Amount to Invoice", GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(
            InvoiceDiscountErr, PurchaseLine.FieldCaption("Inv. Disc. Amount to Invoice"), InvDiscAmountToInvoice,
            PurchaseLine.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvDiscountPurchStatistics()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchaseHeader: Record "Purchase Header";
        VATAmountLine: Record "VAT Amount Line";
        PurchaseLine: Record "Purchase Line";
        QtyType: Option General,Invoicing,Shipping;
        InvDiscountAmount: Decimal;
    begin
        // Check Invoice Discount Amount on Purchase Order for Partial Posting.

        // Setup.
        Initialize();
        GeneralLedgerSetup.Get();
        CreateAndPostPurchaseOrder(PurchaseLine, InvDiscountAmount);

        // Exercise: Calculate VAT Amount.
        LibraryLowerPermissions.SetPurchDocsCreate();
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        PurchaseLine.CalcVATAmountLines(QtyType::Invoicing, PurchaseHeader, PurchaseLine, VATAmountLine);

        // Verify: Verify Invoice Discount Amount.
        Assert.AreNearlyEqual(
          Round(InvDiscountAmount / 2), VATAmountLine."Invoice Discount Amount", GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(
            InvoiceDiscountErr, VATAmountLine.FieldCaption("Invoice Discount Amount"), InvDiscountAmount / 2, VATAmountLine.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvDiscountPstdPurchStatistics()
    var
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
        VATAmountLine: Record "VAT Amount Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        InvDiscountAmount: Decimal;
        DocumentNo: Code[20];
    begin
        // Check Invoice Discount Amount on Purchase Order for Posted Purchase Invoice.

        // Setup.
        Initialize();
        GeneralLedgerSetup.Get();
        DocumentNo := CreateAndPostPurchaseOrder(PurchaseLine, InvDiscountAmount);

        // Exercise: Calculate VAT Amount.
        LibraryLowerPermissions.SetPurchDocsCreate();
        PurchInvHeader.Get(DocumentNo);
        PurchInvLine.CalcVATAmountLines(PurchInvHeader, VATAmountLine);

        // Verify: Verify Invoice Discount Amount.
        Assert.AreNearlyEqual(
          Round(InvDiscountAmount / 2), VATAmountLine."Invoice Discount Amount", GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(
            InvoiceDiscountErr, VATAmountLine.FieldCaption("Invoice Discount Amount"), InvDiscountAmount / 2, VATAmountLine.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceContactNotEditableBeforeVendorSelected()
    var
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [FEATURE] [UI]
        // [Scenario] Contact Field on Purchase Invoice Page not editable if no vendor selected
        // [Given]
        Initialize();

        // [WHEN] Purchase Invoice page is opened
        PurchaseInvoice.OpenNew();

        // [THEN] Contact Field is not editable
        Assert.IsFalse(PurchaseInvoice."Buy-from Contact".Editable(), ContactShouldNotBeEditableErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceContactEditableAfterVendorSelected()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [FEATURE] [UI]
        // [Scenario] Contact Field on Purchase Invoice Page  editable if vendor selected
        // [Given]
        Initialize();

        // [Given] A sample Purchase Invoice
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());

        // [WHEN] Purchase Invoice page is opened
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GotoRecord(PurchaseHeader);

        // [THEN] Contact Field is editable
        Assert.IsTrue(PurchaseInvoice."Buy-from Contact".Editable(), ContactShouldBeEditableErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoicePayToAddressFieldsNotEditableIfSamePayToVendor()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [FEATURE] [UI]
        // [Scenario] Pay-to Address Fields on Purchase Invoice Page not editable if vendor selected equals pay-to vendor
        // [Given]
        Initialize();

        // [Given] A sample Purchase Invoice
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());

        // [WHEN] Purchase Invoice page is opened
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GotoRecord(PurchaseHeader);

        // [THEN] Pay-to Address Fields is not editable
        Assert.IsFalse(PurchaseInvoice."Pay-to Address".Editable(), PayToAddressFieldsNotEditableErr);
        Assert.IsFalse(PurchaseInvoice."Pay-to Address 2".Editable(), PayToAddressFieldsNotEditableErr);
        Assert.IsFalse(PurchaseInvoice."Pay-to City".Editable(), PayToAddressFieldsNotEditableErr);
        Assert.IsFalse(PurchaseInvoice."Pay-to Contact".Editable(), PayToAddressFieldsNotEditableErr);
        Assert.IsFalse(PurchaseInvoice."Pay-to Post Code".Editable(), PayToAddressFieldsNotEditableErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchaseInvoicePayToAddressFieldsEditableIfDifferentPayToVendor()
    var
        PurchaseHeader: Record "Purchase Header";
        PayToVendor: Record Vendor;
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [FEATURE] [UI]
        // [Scenario] Pay-to Address Fields on Purchase Invoice Page editable if vendor selected not equals pay-to vendor
        // [Given]
        Initialize();

        // [Given] A sample Purchase Invoice
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());

        // [WHEN] Purchase Invoice page is opened
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GotoRecord(PurchaseHeader);

        // [WHEN] Another Pay-to vendor is picked
        PayToVendor.Get(LibraryPurchase.CreateVendorNo());
        PurchaseInvoice."Pay-to Name".SetValue(PayToVendor.Name);

        // [THEN] Pay-to Address Fields is editable
        Assert.IsTrue(PurchaseInvoice."Pay-to Address".Editable(), PayToAddressFieldsEditableErr);
        Assert.IsTrue(PurchaseInvoice."Pay-to Address 2".Editable(), PayToAddressFieldsEditableErr);
        Assert.IsTrue(PurchaseInvoice."Pay-to City".Editable(), PayToAddressFieldsEditableErr);
        Assert.IsTrue(PurchaseInvoice."Pay-to Contact".Editable(), PayToAddressFieldsEditableErr);
        Assert.IsTrue(PurchaseInvoice."Pay-to Post Code".Editable(), PayToAddressFieldsEditableErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceFixedAssets()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        CurrencyCode: Code[10];
        DocumentNo: Code[20];
    begin
        // Create Vendor with Currency and post Purchase Invoice for same while purchasing Fixed Asset and Verifying the
        // Purchase Invoice Header.

        // Setup: Create Currency,Vendor and Update Additional Currency on General Ledger Setup.
        Initialize();
        CurrencyCode := CreateCurrency();
        LibraryERM.SetAddReportingCurrency(CurrencyCode);

        CreatePurchaseHeader(PurchaseHeader, CreateVendor(CurrencyCode), PurchaseHeader."Document Type"::Invoice);

        // Using RANDOM Quantity for Purchase Line, value is not important.
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Fixed Asset", FindFixedAsset(), LibraryRandom.RandInt(10));

        // Exercise: Post Purchase order.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify Purchase Invoice Header created with Currency Code for Fixed Assets.
        PurchInvHeader.Get(DocumentNo);
        PurchInvHeader.TestField("Currency Code", CurrencyCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceWithACY()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseLine: Record "Purchase Line";
        CurrencyCode: Code[10];
        PostedDocumentNo: Code[20];
        InvoiceAmountLCY: Decimal;
    begin
        // Verify Amount on G/L Entry and Amount LCY on Vendor Ledger Entry after posting Purchase Invoice with ACY.

        // Setup: Create Currency and Exchange Rate. Update Inv. Rounding Precision LCY and Additional Currency on General Ledger Setup.
        // Run Additional Reporting Currency and create Vendor with Currency.
        Initialize();
        CurrencyCode := CreateCurrency();
        LibraryERM.SetAddReportingCurrency(CurrencyCode);
        LibraryERM.SetInvRoundingPrecisionLCY(1);  // 1 used for Inv. Rounding Precision LCY according to script.
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");

        // Exercise: Create and Post Purchase Invoice.
        PostedDocumentNo := CreateAndPostPurchaseInvoice(PurchaseLine, PurchaseLine.Type::Item, CurrencyCode, VATPostingSetup);
        InvoiceAmountLCY := LibraryERM.ConvertCurrency(PurchaseLine."Line Amount", CurrencyCode, '', WorkDate());

        // Verify: Verify Amount on G/L Entry and Amount LCY on Vendor Ledger Entry.
        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        VerifyAmountOnGLEntry(PostedDocumentNo, GeneralPostingSetup."Purch. Account", InvoiceAmountLCY);
        VerifyAmountLCYOnVendorLedger(PostedDocumentNo, -InvoiceAmountLCY);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceVATWithACY()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseLine: Record "Purchase Line";
        CurrencyCode: Code[10];
        PostedDocumentNo: Code[20];
        VATAmountLCY: Decimal;
    begin
        // Verify VAT Amount on G/L Entry and VAT Entry after posting Purchase Invoice with ACY.

        // Setup: Create Currency and Exchange Rate. Update Additional Currency on General Ledger Setup.
        // Run Additional Reporting Currency. Find VAT Posting Setup. Create Vendor and Item.
        Initialize();
        CurrencyCode := CreateCurrency();
        LibraryERM.SetAddReportingCurrency(CurrencyCode);
        FindVATPostingSetup(VATPostingSetup);

        // Exercise: Create and Post Purchase Invoice.
        PostedDocumentNo := CreateAndPostPurchaseInvoice(PurchaseLine, PurchaseLine.Type::"Fixed Asset", CurrencyCode, VATPostingSetup);
        VATAmountLCY := PurchaseLine."Line Amount" * PurchaseLine."VAT %" / 100;
        VATAmountLCY := LibraryERM.ConvertCurrency(VATAmountLCY, CurrencyCode, '', WorkDate());

        // Verify: Verify VAT Amount and VAT Entry.
        VATPostingSetup.Get(PurchaseLine."VAT Bus. Posting Group", PurchaseLine."VAT Prod. Posting Group");
        VerifyAmountOnGLEntry(PostedDocumentNo, VATPostingSetup."Purchase VAT Account", VATAmountLCY);
        VerifyAmountOnVATEntry(PostedDocumentNo, VATPostingSetup."VAT Prod. Posting Group", VATAmountLCY);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaserCodePurchaseInvoice()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GLEntry: Record "G/L Entry";
        PaymentMethod: Record "Payment Method";
        GLAccount: Record "G/L Account";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Amount: Decimal;
        DocumentNo: Code[20];
    begin
        // Check GL And Vendor Ledger Entry for Amount and Purchaser Code after Posting Purchase Invoice.

        // Setup: Create and Post Purchase Invoice with Payment Method and Purchaser Code with Random Values.
        Initialize();
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        PaymentMethod.Validate("Bal. Account No.", GLAccount."No.");
        PaymentMethod.Modify(true);
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        CreatePurchaseHeader(PurchaseHeader, CreateVendor(''), PurchaseHeader."Document Type"::Invoice);
        PurchaseHeader.Validate("Purchaser Code", SalespersonPurchaser.Code);
        PurchaseHeader.Validate("Payment Method Code", PaymentMethod.Code);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(), LibraryRandom.RandDec(10, 2));
        Amount := PurchaseLine."Line Amount" + (PurchaseLine."Line Amount" * PurchaseLine."VAT %" / 100);

        // Exercise.
        LibraryLowerPermissions.SetPurchDocsPost();
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify GL And Vendor Ledger Entry for Amount and Purchaser Code.
        GeneralLedgerSetup.Get();
        FindGLEntry(GLEntry, DocumentNo, PaymentMethod."Bal. Account No.");
        Assert.AreNearlyEqual(
          -Amount, GLEntry.Amount, GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(AmountErr, GLEntry.FieldCaption(Amount), -Amount));

        FindVendorLedgerEntry(VendorLedgerEntry, DocumentNo, VendorLedgerEntry."Document Type"::Payment);
        Assert.AreEqual(
          PurchaseHeader."Purchaser Code", VendorLedgerEntry."Purchaser Code",
          StrSubstNo(AmountErr, PurchaseHeader.FieldCaption("Purchaser Code"), PurchaseHeader."Purchaser Code"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LineAmountOnPurchaseInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Check Line Amount on Purchase Invoice for New Vendor.

        // Setup:
        Initialize();

        // Exercise: Create Purchase Invoice.
        LibraryLowerPermissions.AddVendorEdit();
        CreatePurchaseInvoice(PurchaseHeader, PurchaseLine, CreateVendor(''));

        // Verify: Check Line Amount of Purchase Invoice.
        VerifyPurchLineAmount(PurchaseHeader."No.", PurchaseLine."No.", PurchaseLine."Line Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BalanceLCYonVendor()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Check Total (LCY) and Balance (LCY) of Vendor after post Purchase Invoice.

        // Setup: Create Vendor, Item and Purchase Invoice.
        Initialize();
        CreatePurchaseInvoice(PurchaseHeader, PurchaseLine, CreateVendor(''));
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        PurchaseHeader.CalcFields("Amount Including VAT");

        // Exercise: Post the Purchase Invoice.
        LibraryLowerPermissions.SetPurchDocsPost();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Check Balance(LCY) and Total(LCY) of Vendor.
        VerifyAmountOnVendor(PurchaseHeader."Buy-from Vendor No.", PurchaseHeader."Amount Including VAT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvWithMultipleLinesFCY()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GeneralPostingSetup: Record "General Posting Setup";
        Vendor: Record Vendor;
        Item: Record Item;
        DocumentNo: Code[20];
        GLAccountNo: Code[20];
        LineAmtGLAccount: Decimal;
        LineAmtItem: Decimal;
    begin
        // Verify program allows to posting the purchase invoice with multiple lines when FCY is involved and
        // verify Amount and Additional amount on GL entry.

        // Setup: Create G/L Account, Create Currency and its Exchange rate, Create Vendor and Item.
        Initialize();
        GLAccountNo := LibraryERM.CreateGLAccountWithPurchSetup();
        Vendor.Get(CreateVendor(CreateCurrency()));
        LibraryERM.SetAddReportingCurrency(Vendor."Currency Code");
        Item.Get(CreateItem());
        GeneralPostingSetup.Get(Vendor."Gen. Bus. Posting Group", Item."Gen. Prod. Posting Group");
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        LineAmtGLAccount := CreatePurchLineWithReturnAmt(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccountNo);
        LineAmtItem := CreatePurchLineWithReturnAmt(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.");

        // Exercise: Create and post Purchase Invoice.
        LibraryLowerPermissions.SetPurchDocsPost();
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify Amount and Additional Currency Amount on G/L entries.
        VerifyAdditionalAmtOnGLEntry(DocumentNo, GLAccountNo, LineAmtGLAccount);
        VerifyAmountOnGLEntry(DocumentNo, GLAccountNo, LibraryERM.ConvertCurrency(LineAmtGLAccount, Vendor."Currency Code", '', WorkDate()));
        VerifyAdditionalAmtOnGLEntry(DocumentNo, GeneralPostingSetup."Purch. Account", LineAmtItem);
        VerifyAmountOnGLEntry(
          DocumentNo, GeneralPostingSetup."Purch. Account", LibraryERM.ConvertCurrency(LineAmtItem, Vendor."Currency Code", '', WorkDate()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseReceiptInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Verifying that the posted purchase receipt and posted purchase invoice have been created after posting Purchase Order.

        // Setup: Create Purchase Order.
        Initialize();
        CreatePurchaseHeader(PurchaseHeader, CreateVendor(''), PurchaseHeader."Document Type"::Order);

        // Using Random Number Generator for Random Quantity.
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(), LibraryRandom.RandDec(10, 2));

        // Exercise: Post Purchase Order.
        LibraryLowerPermissions.SetPurchDocsPost();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify Purchase Order.
        VerifyPurchRcptLine(PurchaseLine, FindPurchRcptHeaderNo(PurchaseHeader."No."));
        VerifyPurchInvLine(PurchaseLine, FindPostedPurchaseInvoiceNo(PurchaseHeader."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenAndCloseVendorPageToVerifyError()
    var
        VendorCard: TestPage "Vendor Card";
    begin
        // open and close Vendor page and verify error message after closing the Vendor page.

        // Setup.
        Initialize();
        VendorCard.OpenView();
        VendorCard.Close();

        // Exercise: Open and close Vendor Page.
        LibraryLowerPermissions.SetVendorView();
        asserterror VendorCard.Close();

        // Verify: Verify error message on Vendor page.
        Assert.ExpectedError(PageNotOpenErr);
    end;

    [Test]
    [HandlerFunctions('TemplateSelectionPageHandler')]
    [Scope('OnPrem')]
    procedure VendorCreationByPage()
    var
        Vendor: Record Vendor;
        VendorNo: Code[20];
    begin
        // Check Vendor after Creating a new Vendor with Page.

        // Setup.
        Initialize();

        // Exercise: Create Vendor with Page.
        LibraryLowerPermissions.SetVendorEdit();
        VendorNo := CreateVendorCard();

        // Verify: Verify value on Vendor.
        Vendor.Get(VendorNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorWithDimension()
    var
        DefaultDimension: Record "Default Dimension";
    begin
        // Check Dimension on Vendor after creating a Vendor with Dimension.

        // Setup.
        Initialize();

        // Exercise: Create Vendor with Dimension.
        CreateVendorWithDimension(DefaultDimension);

        // Verify: Verify Dimension.
        DefaultDimension.Get(DefaultDimension."Table ID", DefaultDimension."No.", DefaultDimension."Dimension Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATEntryForPurchaseInvoiceWithICPartner()
    var
        GLAccount: Record "G/L Account";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        PostedInvoiceNo: Code[20];
        VendorNo: Code[20];
    begin
        // Check Base on VAT Entry after posting Purchase Invoice with IC Partner.

        // Setup: Create Purchase Invoice with IC Partner Code.
        Initialize();
        LibraryLowerPermissions.SetOutsideO365Scope();
        GLAccount.Get(LibraryERM.CreateGLAccountWithPurchSetup());
        VendorNo :=
          LibraryPurchase.CreateVendorWithBusPostingGroups(GLAccount."Gen. Bus. Posting Group", GLAccount."VAT Bus. Posting Group");
        CreatePurchaseHeader(PurchaseHeader, VendorNo, PurchaseHeader."Document Type"::Invoice);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccount."No.", LibraryRandom.RandDec(10, 2));  // Using Random Number Generator for Random Quantity.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));  // Using Random Number Generator for Random Direct Unit Cost.
        PurchaseLine.Validate("IC Partner Code", LibraryERM.CreateICPartnerNo());
        PurchaseLine.Validate("IC Partner Reference", FindICGLAccount());
        PurchaseLine.Modify(true);

        // Exercise: Post Purchase Invoice.
        PostedInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify Values on VAT Entry.
        PurchInvHeader.Get(PostedInvoiceNo);
        PurchInvHeader.CalcFields(Amount);
        VerifyVATEntryBase(PostedInvoiceNo, PurchInvHeader.Amount);
    end;

    [Test]
    [HandlerFunctions('GetReceiptLinesPageHandler')]
    [Scope('OnPrem')]
    procedure GetReceiptLineOnPurchaseInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        // Verify Receipts on Get Receipt Lines are filtered according to Buy-from Vendor No. on Purchase Invoice.

        // Setup: Create and Receive two Purchase Orders using different Buy-from Vendor No. and same Pay-to Vendor No. and create Purchase Invoice using First Vendor.
        Initialize();
        CreateReceiptsAndPurchaseInvoice(PurchaseHeader);

        // Exercise: Open created Purchase Invoice page and do Get Receipt Lines.
        OpenPurchaseInvoiceAndGetReceiptLine(PurchaseHeader."No.");

        // Verify: Verify Buy-from Vendor No. on Get Receipt Lines page.
        PurchRcptLine.SetRange("Buy-from Vendor No.", PurchaseHeader."Buy-from Vendor No.");
        Assert.AreEqual(1, PurchRcptLine.Count, NoOfRecordErr);  // Take 1 for the Purchase Receipt Line.
    end;

    [Test]
    [HandlerFunctions('GetReceiptLinesPageHandler')]
    [Scope('OnPrem')]
    procedure GLEntriesAfterGetReceiptLine()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
    begin
        // Verify the GL Entries when posting the Purchase Invoice after Get Receipt Lines using page.

        // Setup: Create and Receive two Purchase Orders using different Vendors and create Purchase Invoice using first Vendor. Open created Purchase Invoice page and do Get Receipt Lines.
        Initialize();
        CreateReceiptsAndPurchaseInvoice(PurchaseHeader);
        OpenPurchaseInvoiceAndGetReceiptLine(PurchaseHeader."No.");
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        FindPurchaseLine(PurchaseLine, PurchaseHeader."Document Type", PurchaseHeader."No.");
        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");

        // Exercise: Post the created Purchase Invoice.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify Amount on GL Entry.
        VerifyAmountOnGLEntry(DocumentNo, GeneralPostingSetup."Purch. Account", PurchaseLine."Line Amount");
    end;

    [Test]
    [HandlerFunctions('GetReceiptLinesPageHandler,ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure TotalsShouldBeRecalculatedByPriceInclVAT()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        PurchaseInvoice: TestPage "Purchase Invoice";
        Price: Decimal;
        AmountIncVAT: Decimal;
    begin
        // [FEATURE] [Totals] [UI]
        // [SCENARIO 401966] Changing "Price Incl VAT" forces the totals calculation.
        Initialize();

        // [GIVEN] Create and Receive Purchase Order 'PO', where "Price Incl VAT" is 'No'
        LibraryPurchase.CreateVendor(Vendor);
        CreateAndReceivePurchaseDocument(Vendor."No.", Vendor."No.");
        // [GIVEN] Create Purchase Invoice 'PI' and do "Get Receipt Lines" to get line from 'PO'.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");

        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.FILTER.SetFilter("No.", PurchaseHeader."No.");
        PurchaseInvoice.PurchLines.GetReceiptLines.Invoke();
        Evaluate(AmountIncVAT, PurchaseInvoice.PurchLines."Total Amount Incl. VAT".Value());

        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        FindPurchaseLine(PurchaseLine, PurchaseHeader."Document Type", PurchaseHeader."No.");
        Price := PurchaseLine."Direct Unit Cost";

        // [WHEN] In 'PI' Change "Price Incl VAT" to Yes, but do not confirm recalculation of prices
        PurchaseInvoice."Prices Including VAT".SetValue(true);

        // [THEN] Price on the line is not changed, totals are updated on the page.
        PurchaseLine.Find();
        PurchaseLine.TestField("Direct Unit Cost", Price);
        Assert.AreNotEqual(AmountIncVAT, PurchaseLine."Amount Including VAT", 'total is not changed.');
        PurchaseInvoice.PurchLines."Total Amount Incl. VAT".AssertEquals(PurchaseLine."Amount Including VAT");
    end;

    [Test]
    [HandlerFunctions('QuantityOnGetReceiptLinesPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure GetReceiptLinesAfterPartialPosting()
    var
        PurchaseHeader: Record "Purchase Header";
        GetReceiptLines: TestPage "Get Receipt Lines";
    begin
        // Verify Get Receipt Lines page that lines are filtered according to Purchase Order.

        // Setup: Post the Purchase Order.
        Initialize();
        PartiallyPostPurchaseOrder(PurchaseHeader);

        // Exercise: Open Get Receipt Lines page.
        GetReceiptLines.OpenEdit();

        // Verify: Verify that both lines are exists on Get Receipt Lines page with same Quantity on which Purchase Order is posted.

        // Verification done in QuantityOnGetReceiptLinesPageHandler page handler.
    end;

    [Test]
    [HandlerFunctions('QuantityFilterUsingGetReceiptLinesPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure GetReceiptLinesAfterPartialPostingWithQuantityFilter()
    var
        PurchaseHeader: Record "Purchase Header";
        GetReceiptLines: TestPage "Get Receipt Lines";
    begin
        // Verify Filter on Get Receipt Lines page filtered according to Quantity.

        // Setup: Post the Purchase Order.
        Initialize();
        PartiallyPostPurchaseOrder(PurchaseHeader);

        // Exercise: Open Get Receipt Lines page.
        GetReceiptLines.OpenEdit();

        // Verify: Verify Quantity Filter on Get Receipt Lines page, Verification done in the QuantityFilterUsingGetReceiptLinesPageHandler page handler.
    end;

    [Test]
    [HandlerFunctions('InvokeGetReceiptLinesPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostPurchaseInvoiceAfterQuantityFilterOnGetReceiptLine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        GetReceiptLines: TestPage "Get Receipt Lines";
        DocumentNo: Code[20];
    begin
        // Verify G/L Entry for Posted Purchase Invoice after Get Receipt Line on Purchase Invoice.

        // Setup: Post the Purchase Order and open Get Receipt Lines page.
        Initialize();
        PartiallyPostPurchaseOrder(PurchaseHeader);
        GetReceiptLines.OpenEdit();

        // Exercise: Post the Purchase Invoice.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify Value on G/L Entry.
        PurchInvHeader.Get(DocumentNo);
        PurchInvHeader.CalcFields("Amount Including VAT");
        VerifyGLEntry(DocumentNo, PurchInvHeader."Amount Including VAT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvoiceWithoutPriceInclVAT()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseLineDiscount: Record "Purchase Line Discount";
        PostedDocumentNo: Code[20];
        Amount: Decimal;
    begin
        // Verify GL Entry after post Purhcase Invoice without Price Including VAT.
        Initialize();
        SetupLineDiscount(PurchaseLineDiscount);
        CreatePurchInvWithPricesIncludingVAT(PurchaseHeader, PurchaseLineDiscount, false);
        FindPurchaseLine(PurchaseLine, PurchaseHeader."Document Type", PurchaseHeader."No.");
        Amount := PurchaseLine."Line Discount Amount" + PurchaseLine."Line Discount Amount" * PurchaseLine."VAT %" / 100;

        // Exercise.
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify GL Entry after post Purhcase Invoice.
        PurchInvHeader.Get(PostedDocumentNo);
        PurchInvHeader.CalcFields("Amount Including VAT");
        VerifyGLEntry(PostedDocumentNo, PurchInvHeader."Amount Including VAT" + Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvoiceWithPriceInclVAT()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseLineDiscount: Record "Purchase Line Discount";
        PostedDocumentNo: Code[20];
    begin
        // Verify GL Entry after post Purhcase Invoice with Price Including VAT.
        Initialize();
        SetupLineDiscount(PurchaseLineDiscount);
        CreatePurchInvWithPricesIncludingVAT(PurchaseHeader, PurchaseLineDiscount, true);
        FindPurchaseLine(PurchaseLine, PurchaseHeader."Document Type", PurchaseHeader."No.");

        // Exercise.
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify GL Entry after post Purhcase Invoice.
        PurchInvHeader.Get(PostedDocumentNo);
        PurchInvHeader.CalcFields("Amount Including VAT");
        VerifyGLEntry(PostedDocumentNo, PurchInvHeader."Amount Including VAT" + PurchaseLine."Line Discount Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DueDateOnPurchaseCreditMemoAfterCopyDocument()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Test Due Date is calculated on Purchase Credit memo after running Copy Purchase Document Report.
        DueDateOnPurchaseDocumentAfterCopyDocument(PurchaseHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DueDateOnPurchaseReturnOrderAfterCopyDocument()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Test Due Date is calculated on Purchase Return Order after running Copy Purchase Document Report.
        DueDateOnPurchaseDocumentAfterCopyDocument(PurchaseHeader."Document Type"::"Return Order");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreatePurchaseInvoiceLineWhiteLocationQtyError()
    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
    begin
        // Unit test
        LibraryLowerPermissions.SetOutsideO365Scope();
        asserterror PurchDocLineQtyValidation();
        Assert.ExpectedError(WhseReceiveIsRequiredErr);

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreatePurchaseInvoiceLineWithJobAndJobTask()
    var
        PurchaseLine: Record "Purchase Line";
        JobNo: Code[20];
        JobTaskNo: Code[20];
    begin
        // [FEATURE] [Change Global Dimensions] [Job]
        // [SCENARIO 376908] Purchase Line's global dim values are updated after validate Job Task No.
        Initialize();
        LibraryLowerPermissions.SetOutsideO365Scope();
        UpdateGlobalDims();

        // [GIVEN] Job "X" with global dim1 value = "D1". Job task "Y" with global dim2 value = "D2".
        CreateJobAndJobTaskWithDimensions(JobNo, JobTaskNo);
        // [GIVEN] Purchase Line with "Job No." = "X"
        CreatePurchaseInvoiceWithJob(PurchaseLine, JobNo);

        // [WHEN] Validate PurchaseLine."Job Task No." = "Y"
        PurchaseLine.Validate("Job Task No.", JobTaskNo);

        // [THEN] PurchaseLine."Shortcut Dimension 1 Code" =  "D1"
        // [THEN] PurchaseLine."Shortcut Dimension 2 Code" =  "D2"
        // [THEN] PurchaseLine."Dimension Set ID" = DimensionSetEntry."Dimension Set ID", where DimensionSetEntry is linked to "D1", "D2"
        VerifyPurchaseLineDimensions(PurchaseLine, JobNo, JobTaskNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteLineWithExtendedTextInPurchaseOrder()
    var
        Item: Record Item;
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchCalcDiscByType: Codeunit "Purch - Calc Disc. By Type";
    begin
        // [FEATURE] [Extended Text] [Purchase Order] [Invoice Discount]
        // [SCENARIO 363756] Purchase Line is deleted from Purchase Order when there is Extended Text and "Calc Inv. Discount" is TRUE
        Initialize();
        UpdatePurchasePayablesSetupCalcInvDisc(true);

        // [GIVEN] Vendor and Item "X" with Extended Text
        CreateItemAndExtendedText(Item);

        // [GIVEN] Purchase Header
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '');

        // [GIVEN] Purchase Line with Item, second Purchase Line with Extended Text
        CreatePurchLineWithExtendedText(PurchHeader, Item."No.");
        // [GIVEN] Purchase - Calc Discount By Type calculation
        PurchCalcDiscByType.ApplyDefaultInvoiceDiscount(0, PurchHeader);
        Commit(); // Commit to close transaction.

        // [WHEN] Delete Purchase Line with Item
        DeletePurchaseLine(PurchHeader."No.", PurchLine.Type::Item, Item."No.");

        // [THEN] Purchase Lines with Extended Text of "X" deleted
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        PurchLine.SetRange("No.", Item."No.");
        Assert.RecordIsEmpty(PurchLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteLineWithExtendedTextInPurchaseOrderWithShptLines()
    var
        PurchHeader: Record "Purchase Header";
        InvoicePurchaseHeader: Record "Purchase Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchLine: Record "Purchase Line";
        Item: Record Item;
        PurchGetReceipt: Codeunit "Purch.-Get Receipt";
        PurchCalcDiscByType: Codeunit "Purch - Calc Disc. By Type";
        LineDiscAmt: Decimal;
        VATPercent: Decimal;
    begin
        // [FEATURE] [Extended Text] [Purchase Order] [Invoice Discount]
        // [SCENARIO 363756] Purchase Line is deleted from Purchase Order when there is Extended Text and Receipt Lines
        Initialize();
        UpdatePurchasePayablesSetupCalcInvDisc(true);
        LineDiscAmt := LibraryRandom.RandDec(10, 2);

        // [GIVEN] Received purchase order with line discount OrderLineDiscAmt and Prices Including VAT = OrderPricesInclVAT
        CreateReceivePurchOrderWithPricesInclVATAndLineDisc(
          PurchHeader, VATPercent, LineDiscAmt, false);
        // [GIVEN] Purchase Invoice with Prices Including VAT = InvPricesInclVAT
        CreatePurchDocWithPricesInclVAT(
          InvoicePurchaseHeader, InvoicePurchaseHeader."Document Type"::Invoice, PurchHeader."Buy-from Vendor No.", true);
        // [GIVEN] Posted Receipt Line associated with Order
        FindRcptLine(PurchRcptLine, PurchHeader."No.");
        PurchGetReceipt.SetPurchHeader(InvoicePurchaseHeader);

        // [WHEN] Invoice Line created from Receipt Line
        PurchGetReceipt.CreateInvLines(PurchRcptLine);

        // [GIVEN] Item "X" with Extended Text
        CreateItemAndExtendedText(Item);
        // [GIVEN] Purchase Line with Item, second Purchase Line with Extended Text
        CreatePurchLineWithExtendedText(InvoicePurchaseHeader, Item."No.");

        // [GIVEN] Purchase - Calc Discount By Type calculation
        PurchCalcDiscByType.ApplyDefaultInvoiceDiscount(0, InvoicePurchaseHeader);
        Commit(); // Commit to close transaction.

        // [WHEN] Delete Purchase Line with Item
        DeletePurchaseLine(InvoicePurchaseHeader."No.", PurchLine.Type::Item, Item."No.");

        // [THEN] Line Discount Amount on Invoice is InvLineDiscAmt
        VerifyLineDiscAmountInLine(InvoicePurchaseHeader, Round(LineDiscAmt * (1 + VATPercent / 100)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LineDiscInPriceInclVATInvWithRcptLinesFromPriceExclVATOrder()
    var
        PurchHeader: Record "Purchase Header";
        InvoicePurchaseHeader: Record "Purchase Header";
        LineDiscAmt: Decimal;
        VATPercent: Decimal;
    begin
        // [FEATURE] [Discount]
        // [SCENARIO 360474] Line Discount Amount of with Prices Incl. VAT generated by GetRcptLines function from order with Prices Excl. VAT is increased by VAT %
        Initialize();
        LineDiscAmt := LibraryRandom.RandDec(10, 2);

        // [GIVEN] Received purchase order with line discount OrderLineDiscAmt and Prices Including VAT = FALSE
        CreateReceivePurchOrderWithPricesInclVATAndLineDisc(
          PurchHeader, VATPercent, LineDiscAmt, false);

        // [WHEN] Invoice Line created from Receipt Line associated with Order
        LineDiscInInvWithDiffPricesInclVATThenSourceOrder(
          PurchHeader, InvoicePurchaseHeader, true);

        // [THEN] Line Discount Amount on Invoice is InvLineDiscAmt
        VerifyLineDiscAmountInLine(InvoicePurchaseHeader, Round(LineDiscAmt * (1 + VATPercent / 100)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LineDiscInPriceExclVATInvWithRcptLinesFromPriceInclVATOrder()
    var
        PurchHeader: Record "Purchase Header";
        InvoicePurchaseHeader: Record "Purchase Header";
        LineDiscAmt: Decimal;
        VATPercent: Decimal;
    begin
        // [FEATURE] [Discount]
        // [SCENARIO 360474] Line Discount Amount of with Prices Excl. VAT generated by GetRcptLines function from order with Prices Incl. VAT is decreased by VAT %
        Initialize();
        LineDiscAmt := LibraryRandom.RandDec(10, 2);

        // [GIVEN] Received purchase order with line discount OrderLineDiscAmt and Prices Including VAT = TRUE
        CreateReceivePurchOrderWithPricesInclVATAndLineDisc(
          PurchHeader, VATPercent, LineDiscAmt, true);

        // [WHEN] Invoice Line created from Receipt Line associated with Order
        LineDiscInInvWithDiffPricesInclVATThenSourceOrder(
          PurchHeader, InvoicePurchaseHeader, false);

        // [THEN] Line Discount Amount on Invoice is InvLineDiscAmt
        VerifyLineDiscAmountInLine(InvoicePurchaseHeader, Round(LineDiscAmt / (1 + VATPercent / 100)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OutstandingAmountForPurchaseOrderLineWithZeroQuantity()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [SCENARIO] Outstanding Amounts should be 0 after changing Quanity to 0 in Sales Line
        Initialize();

        // [GIVEN] Create Sales Invoice Line with non zero Quantity and Outstanding amount
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, '');
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(), LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));
        PurchaseLine.Modify(true);

        // [THEN] Outstanding Amounts should be non zero
        Assert.AreNotEqual(0, PurchaseLine."Outstanding Amount", 'should be non zero');
        Assert.AreNotEqual(0, PurchaseLine."Outstanding Amount (LCY)", 'should be non zero');
        Assert.AreNotEqual(0, PurchaseLine."Outstanding Amt. Ex. VAT (LCY)", 'should be non zero');

        // [WHEN] Set Quantity as zero
        PurchaseLine.Validate(Quantity, 0);

        // [THEN] Outstanding Amounts should be 0
        Assert.AreEqual(0, PurchaseLine."Outstanding Amount", 'should be zero');
        Assert.AreEqual(0, PurchaseLine."Outstanding Amount (LCY)", 'should be zero');
        Assert.AreEqual(0, PurchaseLine."Outstanding Amt. Ex. VAT (LCY)", 'should be zero');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateUnitCostWithPurchPriceWhenChangeVendorNo()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchPrice: Record "Purchase Price";
        PriceListLine: Record "Price List Line";
    begin
        // [FEATURE] [Purchase Price] [UT]
        // [SCENARIO 375443] Direct Unit Cost should be updated when change Buy-From Vendor No. with Purchase Prices defined

        Initialize();
        // [GIVEN] Purchase Invoice with Vendor "A", Item "X" and "Direct Unit Cost" = 100
        CreatePurchaseHeader(PurchHeader, LibraryPurchase.CreateVendorNo(), PurchHeader."Document Type"::Invoice);
        LibraryPurchase.CreatePurchaseLine(
          PurchLine, PurchHeader, PurchLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
        PurchLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchLine.Modify(true);

        // [GIVEN] Vendor "B" with Purchase Price defined: Item "X", "Direct Unit Cost" = 150
        LibraryCosting.CreatePurchasePrice(
          PurchPrice, LibraryPurchase.CreateVendorNo(), PurchLine."No.", 0D, '', '', '', 0);
        PurchPrice.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchPrice.Modify(true);
        CopyFromToPriceListLine.CopyFrom(PurchPrice, PriceListLine);

        PurchHeader.SetHideValidationDialog(true);

        // [WHEN] Change "Buy From Vendor No." from "A" to "B" in Purchase Invoice
        PurchHeader.Validate("Buy-from Vendor No.", PurchPrice."Vendor No.");

        // [THEN] "Direct Unit Cost" in Purchase Line is 150
        PurchLine.Find();
        PurchLine.TestField("Direct Unit Cost", PurchPrice."Direct Unit Cost");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnitCostNotUpdatedWithoutPurchPriceWhenChangeVendorNo()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ExpectedDirectUnitCost: Decimal;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 375443] Direct Unit Cost should not be updated when change Buy-From Vendor No. without Purchase Prices defined

        Initialize();
        // [GIVEN] Purchase Invoice with Vendor "A", Item "X" and "Direct Unit Cost" = 100
        CreatePurchaseHeader(PurchHeader, LibraryPurchase.CreateVendorNo(), PurchHeader."Document Type"::Invoice);
        LibraryPurchase.CreatePurchaseLine(
          PurchLine, PurchHeader, PurchLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
        PurchLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchLine.Modify(true);
        ExpectedDirectUnitCost := PurchLine."Direct Unit Cost";
        PurchHeader.SetHideValidationDialog(true);

        // [WHEN] Change "Buy From Vendor No." from "A" to "B" in Purchase Invoice
        PurchHeader.Validate("Buy-from Vendor No.", LibraryPurchase.CreateVendorNo());

        // [THEN] "Direct Unit Cost" in Purchase Line is 100
        PurchLine.Find();
        PurchLine.TestField("Direct Unit Cost", ExpectedDirectUnitCost);
    end;

    [Test]
    [HandlerFunctions('ConfirmCopyDocDateOrderHandlerVerify')]
    [Scope('OnPrem')]
    procedure CopyPostedInvShptDateOrderNonConfirm()
    var
        PurchHeader: Record "Purchase Header";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        VendorNo: Code[20];
        PostedDocNo: Code[20];
        InitialPostingDate: Date;
        OldDateOrder: Boolean;
    begin
        // [FEATURE] [Date Order]
        // [SCENARIO 375365] Copy Document from Posted Purchase Invoice and Receipt with Date Order enabled and user not accepted confirmation
        Initialize();

        // [GIVEN] Posted Purchase Invoice with Posting Date = "X"
        PostedDocNo :=
          CreateAndPostSimplePurchaseDocument(PurchHeader."Document Type"::Invoice, VendorNo);

        // [GIVEN] Posted Invoice Nos. has "Date Order" = TRUE
        OldDateOrder := SetNoSeriesDateOrder(true);

        // [GIVEN] Purchase Document with Posting Date = "X" + 1 day and Posting No. assigned
        CreatePurchaseHeaderWithPostingNo(
          PurchHeader, LibraryPurchase.CreateVendorNo(),
          LibraryRandom.RandInt(5), PostedDocNo);
        InitialPostingDate := PurchHeader."Posting Date";
        LibraryVariableStorage.Enqueue(false);

        // [WHEN] Run Copy Document from Posted Purchase Invoice to Purchase Document with Include Header = TRUE
        CopyDocument(PurchHeader, "Purchase Document Type From"::"Posted Invoice", PostedDocNo);
        PurchHeader.Find();

        // [THEN] Confirmation dialog appears with warning and Document not copied (user pressed cancel)
        Assert.AreEqual(InitialPostingDate, PurchHeader."Posting Date", DocumentShouldNotBeCopiedErr);

        // [WHEN] Run Copy Document from Posted Purchase Receipt to Purchase Document with Include Header = TRUE
        PurchRcptHeader.SetRange("Buy-from Vendor No.", VendorNo);
        PurchRcptHeader.FindFirst();
        LibraryVariableStorage.Enqueue(false);
        CopyDocument(PurchHeader, "Purchase Document Type From"::"Posted Receipt", PurchRcptHeader."No.");
        PurchHeader.Get(PurchHeader."Document Type", PurchHeader."No.");

        // [THEN] Confirmation dialog appears with warning and Document not copied (user pressed cancel)
        Assert.AreEqual(InitialPostingDate, PurchHeader."Posting Date", DocumentShouldNotBeCopiedErr);

        SetNoSeriesDateOrder(OldDateOrder);
    end;

    [Test]
    [HandlerFunctions('ConfirmCopyDocDateOrderHandlerVerify')]
    [Scope('OnPrem')]
    procedure CopyPostedCrMemoRetRecDateOrderNonConfirm()
    var
        PurchHeader: Record "Purchase Header";
        ReturnShptHeader: Record "Return Shipment Header";
        VendorNo: Code[20];
        PostedDocNo: Code[20];
        InitialPostingDate: Date;
        OldDateOrder: Boolean;
    begin
        // [FEATURE] [Date Order]
        // [SCENARIO 375365] Copy Document from Posted Purchase Credit Memo and Return Shipment with Date Order enabled and user not accepted confirmation
        Initialize();

        // [GIVEN] Posted Credit Memo with Posting Date = "X"
        PostedDocNo :=
          CreateAndPostSimplePurchaseDocument(PurchHeader."Document Type"::"Return Order", VendorNo);

        // [GIVEN] Posted Invoice Nos. has "Date Order" = TRUE
        OldDateOrder := SetNoSeriesDateOrder(true);

        // [GIVEN] Purchase Document with Posting Date = "X" + 1 day and Posting No. assigned
        CreatePurchaseHeaderWithPostingNo(
          PurchHeader, LibraryPurchase.CreateVendorNo(),
          LibraryRandom.RandInt(5), PostedDocNo);
        InitialPostingDate := PurchHeader."Posting Date";
        LibraryVariableStorage.Enqueue(false);

        // [WHEN] Run Copy Document from Posted Purchase Cr. Memo to Purchase Document with Include Header = TRUE
        CopyDocument(PurchHeader, "Purchase Document Type From"::"Posted Credit Memo", PostedDocNo);

        // [THEN] Confirmation dialog appears with warning and Document not copied (user pressed cancel)
        PurchHeader.Find();
        Assert.AreEqual(InitialPostingDate, PurchHeader."Posting Date", DocumentShouldNotBeCopiedErr);

        // [WHEN] Run Copy Document from Posted Return Shipment to Purchase Document with Include Header = TRUE
        ReturnShptHeader.SetRange("Buy-from Vendor No.", VendorNo);
        ReturnShptHeader.FindFirst();
        LibraryVariableStorage.Enqueue(false);
        CopyDocument(PurchHeader, "Purchase Document Type From"::"Posted Return Shipment", ReturnShptHeader."No.");
        PurchHeader.Get(PurchHeader."Document Type", PurchHeader."No.");

        // [THEN] Confirmation dialog appears with warning and Document not copied (user pressed cancel)
        Assert.AreEqual(InitialPostingDate, PurchHeader."Posting Date", DocumentShouldBeCopiedErr);

        SetNoSeriesDateOrder(OldDateOrder);
    end;

    [Test]
    [HandlerFunctions('ConfirmCopyDocDateOrderHandlerVerify')]
    [Scope('OnPrem')]
    procedure CopyQuoteDateOrderNonConfirm()
    var
        PurchHeaderSrc: Record "Purchase Header";
        PurchHeaderDst: Record "Purchase Header";
        VendorNo: Code[20];
        OldDateOrder: Boolean;
    begin
        // [FEATURE] [Date Order]
        // [SCENARIO 375365] Copy Document from Purchase Quote with Date Order enabled and user not accepted confirmation
        Initialize();

        // [GIVEN] Posted Invoice Nos. has "Date Order" = TRUE
        OldDateOrder := SetNoSeriesDateOrder(true);

        // [GIVEN] Purchase Quote with Posting Date = "X"
        LibraryPurchase.CreatePurchHeader(
          PurchHeaderSrc, PurchHeaderSrc."Document Type"::Quote, LibraryPurchase.CreateVendorNo());

        // [GIVEN] Purchase Document with Posting Date = "X" + 1 day and Posting No. assigned
        VendorNo := LibraryPurchase.CreateVendorNo();
        CreatePurchaseHeaderWithPostingNo(
          PurchHeaderDst, VendorNo, LibraryRandom.RandInt(5),
          LibraryUtility.GenerateRandomCode(PurchHeaderDst.FieldNo("Posting No."), DATABASE::"Purchase Header"));
        LibraryVariableStorage.Enqueue(false);

        // [WHEN] Run Copy Document from Purchase Quote to Purchase Document with Include Header = TRUE
        CopyDocument(PurchHeaderDst, "Purchase Document Type From"::Quote, PurchHeaderSrc."No.");

        // [THEN] Confirmation dialog appears with warning and Document not copied (user pressed cancel)
        PurchHeaderDst.Get(PurchHeaderDst."Document Type", PurchHeaderDst."No.");
        Assert.AreEqual(VendorNo, PurchHeaderDst."Buy-from Vendor No.", DocumentShouldBeCopiedErr);

        SetNoSeriesDateOrder(OldDateOrder);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CopyPostedInvShptDateOrderConfirm()
    var
        PurchHeader1: Record "Purchase Header";
        PurchHeader2: Record "Purchase Header";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PostedDocNo: Code[20];
        VendorNoSrc: Code[20];
        VendorNoDst: Code[20];
        OldDateOrder: Boolean;
    begin
        // [FEATURE] [Date Order]
        // [SCENARIO 375365] Copy Document from Posted Purchase Invoice and Receipt with Date Order enabled and user accepted confirmation
        Initialize();

        // [GIVEN] Posted Purchase Invoice with Posting Date = "X"
        PostedDocNo :=
          CreateAndPostSimplePurchaseDocument(PurchHeader1."Document Type"::Invoice, VendorNoSrc);

        // [GIVEN] Posted Invoice Nos. has "Date Order" = TRUE
        OldDateOrder := SetNoSeriesDateOrder(true);

        // [GIVEN] Purchase Document with Posting Date = "X" + 1 day and Posting No. assigned
        VendorNoDst := LibraryPurchase.CreateVendorNo();
        CreatePurchaseHeaderWithPostingNo(PurchHeader1, VendorNoDst, LibraryRandom.RandInt(5), PostedDocNo);
        // [WHEN] Run Copy Document from Posted Purchase Invoice to Purchase Document with Include Header = TRUE
        CopyDocument(PurchHeader1, "Purchase Document Type From"::"Posted Invoice", PostedDocNo);
        PurchHeader1.Get(PurchHeader1."Document Type", PurchHeader1."No.");

        // [THEN] Confirmation dialog appears with warning and Document is copied after user confirmation
        Assert.AreEqual(VendorNoSrc, PurchHeader1."Buy-from Vendor No.", DocumentShouldBeCopiedErr);

        // [WHEN] Run Copy Document from Posted Purchase Receipt to Purchase Document with Include Header = TRUE
        PurchRcptHeader.SetRange("Buy-from Vendor No.", VendorNoSrc);
        PurchRcptHeader.FindFirst();
        CreatePurchaseHeaderWithPostingNo(PurchHeader2, VendorNoDst, LibraryRandom.RandInt(5), PostedDocNo);
        CopyDocument(PurchHeader2, "Purchase Document Type From"::"Posted Receipt", PurchRcptHeader."No.");
        PurchHeader2.Get(PurchHeader2."Document Type", PurchHeader2."No.");

        // [THEN] Confirmation dialog appears with warning and Document is copied after user confirmation
        Assert.AreEqual(VendorNoSrc, PurchHeader2."Buy-from Vendor No.", DocumentShouldBeCopiedErr);

        SetNoSeriesDateOrder(OldDateOrder);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CopyPostedCrMemoRetRecDateOrderConfirm()
    var
        PurchHeader1: Record "Purchase Header";
        PurchHeader2: Record "Purchase Header";
        ReturnShipmentHeader: Record "Return Shipment Header";
        VendorNo: Code[20];
        PostedDocNo: Code[20];
        OldDateOrder: Boolean;
    begin
        // [FEATURE] [Date Order]
        // [SCENARIO 375365] Copy Document from Posted Purchase Credit Memo and Return Shipment with Date Order enabled and user accepted confirmation
        Initialize();

        // [GIVEN] Posted Credit Memo with Posting Date = "X"
        PostedDocNo :=
          CreateAndPostSimplePurchaseDocument(PurchHeader1."Document Type"::"Return Order", VendorNo);

        // [GIVEN] Posted Invoice Nos. has "Date Order" = TRUE
        OldDateOrder := SetNoSeriesDateOrder(true);

        // [GIVEN] Purchase Document with Posting Date = "X" + 1 day and Posting No. assigned
        CreatePurchaseHeaderWithPostingNo(
          PurchHeader1, LibraryPurchase.CreateVendorNo(), LibraryRandom.RandInt(5), PostedDocNo);

        // [WHEN] Run Copy Document from Posted Purchase Cr. Memo to Purchase Document with Include Header = TRUE
        CopyDocument(PurchHeader1, "Purchase Document Type From"::"Posted Credit Memo", PostedDocNo);

        // [THEN] Confirmation dialog appears with warning and Document is copied after user confirmation
        PurchHeader1.Get(PurchHeader1."Document Type", PurchHeader1."No.");
        Assert.AreEqual(VendorNo, PurchHeader1."Buy-from Vendor No.", DocumentShouldBeCopiedErr);

        // [WHEN] Run Copy Document from Posted Return Shipment to Purchase Document with Include Header = TRUE
        CreatePurchaseHeaderWithPostingNo(
          PurchHeader2, LibraryPurchase.CreateVendorNo(), LibraryRandom.RandInt(5), PostedDocNo);

        ReturnShipmentHeader.SetRange("Buy-from Vendor No.", VendorNo);
        ReturnShipmentHeader.FindFirst();
        CopyDocument(PurchHeader2, "Purchase Document Type From"::"Posted Return Shipment", ReturnShipmentHeader."No.");
        PurchHeader2.Get(PurchHeader2."Document Type", PurchHeader2."No.");

        // [THEN] Confirmation dialog appears with warning and Document is copied after user confirmation
        Assert.AreEqual(VendorNo, PurchHeader2."Buy-from Vendor No.", DocumentShouldBeCopiedErr);

        SetNoSeriesDateOrder(OldDateOrder);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CopyQuoteDateOrderConfirm()
    var
        PurchHeaderSrc: Record "Purchase Header";
        PurchHeaderDst: Record "Purchase Header";
        OldDateOrder: Boolean;
    begin
        // [FEATURE] [Date Order]
        // [SCENARIO 375365] Copy Document from Purchase Quote with Date Order enabled and user accepted confirmation
        Initialize();

        // [GIVEN] Posted Invoice Nos. has "Date Order" = TRUE
        OldDateOrder := SetNoSeriesDateOrder(true);

        // [GIVEN] Purchase Quote with Posting Date = "X"
        LibraryPurchase.CreatePurchHeader(
          PurchHeaderSrc, PurchHeaderSrc."Document Type"::Quote, LibraryPurchase.CreateVendorNo());

        // [GIVEN] Purchase Document with Posting Date = "X" + 1 day and Posting No. assigned
        CreatePurchaseHeaderWithPostingNo(
          PurchHeaderDst, LibraryPurchase.CreateVendorNo(), LibraryRandom.RandInt(5),
          LibraryUtility.GenerateRandomCode(PurchHeaderDst.FieldNo("Posting No."), DATABASE::"Purchase Header"));

        // [WHEN] Run Copy Document from Purchase Quote to Purchase Document with Include Header = TRUE
        CopyDocument(PurchHeaderDst, "Purchase Document Type From"::Quote, PurchHeaderSrc."No.");

        // [THEN] Confirmation dialog appears with warning and Document is copied after user confirmation
        PurchHeaderDst.Get(PurchHeaderDst."Document Type", PurchHeaderDst."No.");
        Assert.AreEqual(PurchHeaderSrc."Buy-from Vendor No.", PurchHeaderDst."Buy-from Vendor No.", DocumentShouldBeCopiedErr);

        SetNoSeriesDateOrder(OldDateOrder);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyPurchaseInvoiceWithDifferentVATBusGroup()
    var
        PurchHeaderSrc: Record "Purchase Header";
        PurchHeaderDst: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
    begin
        // [SCENARIO 376478] It is not allowed to Copy document when VAT group of source lines does not match VAT group of destination header
        // [FEATURE] [Copy Document]
        Initialize();

        // [GIVEN] Source Purchase Invoice with "VAT Bus. Posting Group" = "X" in line
        LibraryPurchase.CreatePurchHeader(
          PurchHeaderSrc, PurchHeaderSrc."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandInt(20));
        PurchHeaderSrc.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        PurchHeaderSrc.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchHeaderSrc, PurchaseLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Sale),
          LibraryRandom.RandDec(10, 2));

        // [GIVEN] Destination Purchase Invoice with "VAT Bus. Posting Group" = "Y"
        LibraryPurchase.CreatePurchHeader(
          PurchHeaderDst, PurchHeaderDst."Document Type"::Invoice, PurchHeaderSrc."Buy-from Vendor No.");

        // [WHEN] Run "Copy Purchase Document" report Invoice to Invoice with Include Header = FALSE and Recalculate Lines = FALSE
        asserterror LibraryPurchase.CopyPurchaseDocument(PurchHeaderDst, "Purchase Document Type From"::Invoice, PurchHeaderSrc."No.", false, false);

        // [THEN] Error thrown due to different VAT Business Groups in copied line and header
        Assert.ExpectedErrorCode(TestFieldTok);
        Assert.ExpectedTestFieldError(PurchHeaderDst.FieldCaption("VAT Bus. Posting Group"), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyPurchaseInvoiceWithDifferentVATBusGroupInclVAT()
    var
        PurchHeaderSrc: Record "Purchase Header";
        PurchHeaderDst: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        VATBusPostGroup: Code[20];
    begin
        // [SCENARIO 421483] It is allowed to Copy document with multiple VAT Bus. Posting Group in the source lines if header included.
        // [FEATURE] [Copy Document]
        Initialize();

        // [GIVEN] Source Purchase Invoice with "VAT Bus. Posting Group" = "X" in line
        LibraryPurchase.CreatePurchHeader(
          PurchHeaderSrc, PurchHeaderSrc."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandInt(20));
        PurchHeaderSrc.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        PurchHeaderSrc.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchHeaderSrc, PurchaseLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Sale),
          LibraryRandom.RandDec(10, 2));
        VATBusPostGroup := PurchaseLine."VAT Bus. Posting Group";

        // [GIVEN] Destination Purchase Invoice with "VAT Bus. Posting Group" = "Y"
        LibraryPurchase.CreatePurchHeader(
          PurchHeaderDst, PurchHeaderDst."Document Type"::Invoice, PurchHeaderSrc."Buy-from Vendor No.");

        // [WHEN] Run "Copy Purchase Document" report Invoice to Invoice with Include Header = TRUE and Recalculate Lines = FALSE
        LibraryPurchase.CopyPurchaseDocument(PurchHeaderDst, "Purchase Document Type From"::Invoice, PurchHeaderSrc."No.", true, false);

        // [THEN] Line is copied
        PurchaseLine.Reset();
        PurchaseLine.SetRange("Document Type", PurchHeaderDst."Document Type");
        PurchaseLine.SetRange("Document No.", PurchHeaderDst."No.");
        Assert.RecordCount(PurchaseLine, 1);
        PurchaseLine.FindFirst();
        PurchaseLine.TestField("VAT Bus. Posting Group", VATBusPostGroup);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure DeleteNonPostedInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseInvoice: TestPage "Purchase Invoice";
        ErrorMessagesPage: TestPage "Error Messages";
        VendorNo: Code[20];
        PurchaseHeaderNo: Code[20];
    begin
        // [SCENARIO] Create a Purchase Invoice with Negative quanity, try to post and then delete.
        Initialize();

        // [GIVEN] Purchase Invoice with an Item with negative quantity
        VendorNo := LibraryPurchase.CreateVendorNo();
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(), -LibraryRandom.RandInt(10));
        PurchaseHeaderNo := PurchaseHeader."No.";

        // [WHEN] Trying to POST and see the error in the page. Business Manager should be able to delete the Purchase Invoice
        ErrorMessagesPage.Trap();
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GotoRecord(PurchaseHeader);
        PurchaseInvoice.Post.Invoke();
        Assert.ExpectedMessage(NegativeAmountErr, ErrorMessagesPage.Description.Value);

        LibraryLowerPermissions.SetO365BusFull();
        PurchaseHeader.Get(PurchaseHeader."Document Type"::Invoice, PurchaseHeaderNo);
        PurchaseHeader.Delete(true);

        // [THEN] No other error is thrown. Test succeeds
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TotalVATIsNotCalculatedForReverseChargeInPurchInv()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [FEATURE] [UT] [Reverse Charge]
        // [SCENARIO 208584] "Total VAT Amount" field of Purchase Invoice Subform should not inclide "VAT Amount" of lines in case of Reverse Charge VAT Calculation Type

        Initialize();

        // [GIVEN] Purchase Invoice "PI" with two lines
        CreatePurchaseHeader(PurchaseHeader, CreateVendor(''), PurchaseHeader."Document Type"::Invoice);

        // [GIVEN] Purchase Line "PL1" with 1000 Amount and 123 Reverse Charge VAT
        CreateItemWithLastDirectCost(Item);
        CreateVATPostingSetupWithReverseChargeVAT(VATPostingSetup, PurchaseHeader);
        Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Item.Modify(true);

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 1);
        PurchaseLine.Validate("VAT Calculation Type", PurchaseLine."VAT Calculation Type"::"Reverse Charge VAT");
        PurchaseLine.Modify();

        // [GIVEN] Purchase Line "PL2" with 2000 Amount and  321 Normal VAT
        CreateItemWithLastDirectCost(Item);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 1);

        // [WHEN] Purchase Invoice Subform is openned
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GotoRecord(PurchaseHeader);

        // [THEN] "Total VAT Amount" field of Purchase Invoice Subform is 321, so it includes only the Amount of "PL2" and does not include the Amount of "PL1"
        Assert.AreEqual(
          Round(Item."Last Direct Cost" * PurchaseLine."VAT %" / 100), PurchaseInvoice.PurchLines."Total VAT Amount".AsDecimal(), '');

        // [THEN] "Total Amount Incl. VAT" field of Purchase Invoice Subform is 3321
        Assert.AreEqual(
          PurchaseInvoice.PurchLines."Total Amount Excl. VAT".AsDecimal() + PurchaseInvoice.PurchLines."Total VAT Amount".AsDecimal(),
          PurchaseInvoice.PurchLines."Total Amount Incl. VAT".AsDecimal(),
          '');
        PurchaseInvoice.Close();
    end;

    [Test]
    [HandlerFunctions('CreateEmptyPostedInvConfirmHandler')]
    [Scope('OnPrem')]
    procedure EmptyPostedInvCreationConfirmOnPurchaseInvoiceDeletion()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // [FEATURE] [Deletion]
        // [SCENARIO 226743] If "Posted Invoice Nos." and "Invoice Nos." No. Series are the same, then on deletion of Purchase Invoice before posting, then confirmation for creation of empty posted invoice must appear
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Journal Templ. Name Mandatory" := false;
        GeneralLedgerSetup.Modify();

        // [GIVEN] "Posted Invoice Nos." and "Invoice Nos." No. Series are the same
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Invoice Nos.", PurchasesPayablesSetup."Posted Invoice Nos.");
        PurchasesPayablesSetup.Modify(true);

        // [GIVEN] Purchase Invoice with "No." = 1111
        PurchaseHeader.Init();
        PurchaseHeader.Validate("Document Type", PurchaseHeader."Document Type"::Invoice);
        PurchaseHeader.Validate("Buy-from Vendor No.", LibraryPurchase.CreateVendorNo());
        PurchaseHeader.Insert(true);

        PurchaseHeader.Validate("Posting No. Series", PurchaseHeader."No. Series");
        PurchaseHeader.Modify(true);

        LibraryVariableStorage.Enqueue(StrSubstNo(ConfirmCreateEmptyPostedInvMsg, PurchaseHeader."No."));

        // [WHEN] Delete Purchase Invoice
        PurchaseHeader.ConfirmDeletion();

        // [THEN] "Deleting this document will cause a gap in the number series for posted invoices. An empty posted invoice 1111 will be created" error appear
        // Checked within CreateEmptyPostedInvConfirmHandler
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvoiceWithPostedReceiptNegativeQty()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        // [FEATURE] [Receipt]
        // [SCENARIO 253750] Calculation of "Quantity Invoiced" and "Qty. Invoiced (Base)" in Posted Receipt when posting a purchase with negative quantity
        Initialize();

        // [GIVEN] "Receipt on Invoice" = TRUE, "Exact Cost Reversing Mandatory" = FALSE in Purchase Setup
        UpdatePurchaseAndPayableSetup(true, false);
        UpdatePurchasePayablesSetupExactCostReversing(false);

        // [GIVEN] Purchase Invoice with second line of item "I" with Quantity = -1
        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(), -1);

        // [WHEN] Post Purchase Invoice
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Purchase Receipt Line with item "I" has "Quantity Invoiced" = "Qty. Invoiced (Base)" = -1
        // [THEN] "Qty. Rcd. Not Invoiced" = 0
        PurchRcptLine.SetRange("Buy-from Vendor No.", PurchaseHeader."Buy-from Vendor No.");
#pragma warning disable AA0210
        PurchRcptLine.SetRange("No.", PurchaseLine."No.");
#pragma warning restore AA0210
        PurchRcptLine.FindFirst();
        PurchRcptLine.TestField("Quantity Invoiced", -1);
        PurchRcptLine.TestField("Qty. Invoiced (Base)", -1);
        PurchRcptLine.TestField("Qty. Rcd. Not Invoiced", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCrMemoWithPostedReceiptNegativeQty()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReturnShipmentLine: Record "Return Shipment Line";
    begin
        // [FEATURE] [Return Shipment]
        // [SCENARIO 257861] Calculation of "Quantity Invoiced" and "Qty. Invoiced (Base)" in Posted Return Shipment when posting credit memo with negative quantity
        Initialize();

        // [GIVEN] "Return Shipment on Credit Memo" = TRUE, "Exact Cost Reversing Mandatory" = FALSE in Purchase Setup
        UpdatePurchaseAndPayableSetup(false, true);
        UpdatePurchasePayablesSetupExactCostReversing(false);

        // [GIVEN] Purchase Credit Memo with second line of item "I" with Quantity = -1
        LibraryPurchase.CreatePurchaseCreditMemo(PurchaseHeader);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(), -1);

        // [WHEN] Post Purchase Credit Memo
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Purchase Shipment Line with item "I" has "Quantity Invoiced" = "Qty. Invoiced (Base)" = -1
        // [THEN] "Return Qty. Shipped Not Invd." = 0
        ReturnShipmentLine.SetRange("Buy-from Vendor No.", PurchaseHeader."Buy-from Vendor No.");
#pragma warning disable AA0210
        ReturnShipmentLine.SetRange("No.", PurchaseLine."No.");
#pragma warning restore AA0210
        ReturnShipmentLine.FindFirst();
        ReturnShipmentLine.TestField("Quantity Invoiced", -1);
        ReturnShipmentLine.TestField("Qty. Invoiced (Base)", -1);
        ReturnShipmentLine.TestField("Return Qty. Shipped Not Invd.", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceChangePricesInclVATRefreshesPage()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoicePage: TestPage "Purchase Invoice";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 277993] User changes Prices including VAT, page refreshes and shows appropriate captions
        Initialize();

        // [GIVEN] Page with Prices including VAT disabled was open
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, '');
        PurchaseInvoicePage.OpenEdit();
        PurchaseInvoicePage.GotoRecord(PurchaseHeader);

        // [WHEN] User checks Prices including VAT
        PurchaseInvoicePage."Prices Including VAT".SetValue(true);

        // [THEN] Caption for PurchaseInvoicePage.PurchLines."Direct Unit Cost" field is updated
        Assert.AreEqual('Direct Unit Cost Incl. VAT',
          PurchaseInvoicePage.PurchLines."Direct Unit Cost".Caption,
          'The caption for PurchaseInvoicePage.PurchLines."Direct Unit Cost" is incorrect');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostAndNew()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchSetup: Record "Purchases & Payables Setup";
        NoSeries: Codeunit "No. Series";
        PurchaseInvoice: TestPage "Purchase Invoice";
        PurchaseInvoice2: TestPage "Purchase Invoice";
        NextDocNo: Code[20];
    begin
        // [FEATURE] [UI]
        // [SCENARIO 293548] Action "Post and new" opens new invoice after posting the current one
        Initialize();

        // [GIVEN] Purchase Invoice card is opened with invoice
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(), LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);

        LibraryLowerPermissions.SetPurchDocsPost();
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.FILTER.SetFilter("No.", PurchaseHeader."No.");

        // [WHEN] Action "Post and new" is being clicked
        PurchaseInvoice2.Trap();
        PurchSetup.Get();
        NextDocNo := NoSeries.PeekNextNo(PurchSetup."Invoice Nos.");
        PurchaseInvoice.PostAndNew.Invoke();

        // [THEN] Purchase invoice page opened with new invoice
        PurchaseInvoice2."No.".AssertEquals(NextDocNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceLineLimitedPermissionCreation()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        StandardText: Record "Standard Text";
        MyNotifications: Record "My Notifications";
        PostingSetupManagement: Codeunit PostingSetupManagement;
    begin
        // [FEATURE] [Permissions]
        // [SCENARIO 325667] Purchase Line without type is added when user has limited permissions.
        Initialize();

        // [GIVEN] Standard text.
        LibrarySales.CreateStandardText(StandardText);
        // [GIVEN] Enabled notification about missing G/L account.
        MyNotifications.InsertDefault(PostingSetupManagement.GetPostingSetupNotificationID(), '', '', true);
        // [GIVEN] Purchase header.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, CreateVendor(''));
        // [GIVEN] Permisson to create purchase invoices.
        LibraryLowerPermissions.SetPurchDocsCreate();

        // [WHEN] Add Purchase Line with standard text, but without type.
        PurchaseLine.Init();
        PurchaseLine.Validate("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.Validate("Document No.", PurchaseHeader."No.");
        PurchaseLine.Validate("No.", StandardText.Code);
        PurchaseLine.Insert(true);

        // [THEN] Purchase line is created.
        Assert.RecordIsNotEmpty(PurchaseLine);
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler')]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceLineWithoutAccountCreation()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        MyNotifications: Record "My Notifications";
        PostingSetupManagement: Codeunit PostingSetupManagement;
    begin
        // [SCENARIO 325667] Notification is shown when Purchase Line is added and G/L Account is missing in posting group.
        Initialize();

        // [GIVEN] Enabled notification about missing G/L account.
        MyNotifications.InsertDefault(PostingSetupManagement.GetPostingSetupNotificationID(), '', '', true);
        // [GIVEN] Purchase header with "Gen. Bus. Posting Group" and "VAT Bus. Posting Group" are not in Posting Setup.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, CreateVendorWithNewPostingGroups());

        // [WHEN] Add Purchase Line (SendNotificationHandler).
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(), LibraryRandom.RandInt(10));

        // [THEN] Notification "Purch. Account is missing in General Posting Setup." is sent.
        Assert.ExpectedMessage(PurchaseAccountIsMissingTxt, LibraryVariableStorage.DequeueText());
        // [THEN] Notification "Purchase VAT Account is missing in VAT Posting Setup." is sent.
        Assert.ExpectedMessage(PurchaseVatAccountIsMissingTxt, LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetFullDocTypeName()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [SCENARIO] Get full document type and name
        // [GIVEN] Purchase Header of type "Invoice"
        PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::Invoice;

        // [WHEN] GetFullDocTypeTxt is called
        // [THEN] 'Purchase Invoice' is returned
        Assert.AreEqual('Purchase Invoice', PurchaseHeader.GetFullDocTypeTxt(), 'The expected full document type is incorrect');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateBuyFromVendorNameValidateItemInLine()
    var
        Vendor1: Record Vendor;
        Vendor2: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 332188]
        Initialize();

        CreateVendorsWithSameName(Vendor1, Vendor2);

        PurchaseHeader.Init();
        PurchaseHeader.Validate("Document Type", PurchaseHeader."Document Type"::Invoice);
        PurchaseHeader.Insert(true);
        PurchaseHeader.TestField("No.");

        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.FILTER.SetFilter("No.", PurchaseHeader."No.");

        PurchaseInvoice."Buy-from Vendor Name".SetValue(Vendor1."No.");
        PurchaseInvoice.PurchLines.Type.SetValue(PurchaseLine.Type::Item);
        PurchaseInvoice.PurchLines."No.".SetValue(LibraryInventory.CreateItemNo());
        PurchaseInvoice.Close();

        PurchaseHeader.Find();
        PurchaseHeader.TestField("Buy-from Vendor No.", Vendor1."No.");
        PurchaseHeader.TestField("Buy-from Vendor Name", Vendor1.Name);
        PurchaseHeader.TestField("Pay-to Vendor No.", Vendor1."No.");
        PurchaseHeader.TestField("Pay-to Name", Vendor1.Name);
        LibraryPurchase.FindFirstPurchLine(PurchaseLine, PurchaseHeader);
        PurchaseLine.TestField(Type);
        PurchaseLine.TestField("No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYesNo')]
    [Scope('OnPrem')]
    procedure ValidatePayToVendorNameValidateItemInLine()
    var
        Vendor1: Record Vendor;
        Vendor2: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 332188]
        Initialize();

        CreateVendorsWithSameName(Vendor1, Vendor2);
        Vendor2.Name := CopyStr(LibraryUtility.GenerateRandomAlphabeticText(100, 0), 1, MaxStrLen(Vendor2.Name));
        Vendor2.Modify(); // we don't need duplicate names in this test

        PurchaseHeader.Init();
        PurchaseHeader.Validate("Document Type", PurchaseHeader."Document Type"::Invoice);
        PurchaseHeader.Insert(true);
        PurchaseHeader.TestField("No.");

        LibraryVariableStorage.Enqueue(true);

        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.FILTER.SetFilter("No.", PurchaseHeader."No.");

        PurchaseInvoice."Buy-from Vendor Name".SetValue(Vendor1."No.");
        PurchaseInvoice."Pay-to Name".SetValue(Vendor2."No.");
        PurchaseInvoice.PurchLines.Type.SetValue(PurchaseLine.Type::Item);
        PurchaseInvoice.PurchLines."No.".SetValue(LibraryInventory.CreateItemNo());
        PurchaseInvoice.Close();

        PurchaseHeader.Find();
        PurchaseHeader.TestField("Buy-from Vendor No.", Vendor1."No.");
        PurchaseHeader.TestField("Buy-from Vendor Name", Vendor1.Name);
        PurchaseHeader.TestField("Pay-to Vendor No.", Vendor2."No.");
        PurchaseHeader.TestField("Pay-to Name", Vendor2.Name);
        LibraryPurchase.FindFirstPurchLine(PurchaseLine, PurchaseHeader);
        PurchaseLine.TestField(Type);
        PurchaseLine.TestField("No.");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangePriceIncludingVATTrueValueRecalculateAmountCorrectlyForFullVAT()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        DirectUnitCost: Decimal;
        LineAmount: Decimal;
    begin
        // [FEATURE] [Full VAT]
        // [SCENARIO 348949] Create Purchase line with "Prices Including VAT" = False and Full VAT and change "Prices Including VAT" to True
        Initialize();

        // [GIVEN] Created VAT Posting Setup for Full VAT
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Full VAT", 100);

        // [GIVEN] Create Purchase Header with Line
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        PurchaseHeader.SetHideValidationDialog(true);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
            VATPostingSetup.GetPurchAccount(false), LibraryRandom.RandInt(10));

        // [GIVEN] Validate "VAT Prod. Posting Group"
        // [GIVEN] Memorize "Direct Unit Cost" as "D"
        // [GIVEN] Memorize "Line Amount" as "L"
        PurchaseLine.Validate("VAT Prod. Posting Group");
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(1000, 2));
        PurchaseLine.Modify(true);
        DirectUnitCost := PurchaseLine."Direct Unit Cost";
        LineAmount := PurchaseLine."Line Amount";

        // [WHEN] Change "Prices Including VAT" to True
        PurchaseHeader.Validate("Prices Including VAT", true);

        // [THEN] "Direct Unit Cost" are equal to "D"
        // [THEN] "Line Amount" are equal to "L"
        PurchaseLine.TestField("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.TestField("Line Amount", LineAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangePriceIncludingVATFalseValueRecalculateAmountCorrectlyForFullVAT()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        DirectUnitCost: Decimal;
        LineAmount: Decimal;
    begin
        // [FEATURE] [Full VAT]
        // [SCENARIO 348949] Create Purchase line with "Prices Including VAT" = True and Full VAT and change "Prices Including VAT" to False
        Initialize();

        // [GIVEN] Created VAT Posting Setup for Full VAT
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Full VAT", 100);

        // [GIVEN] Create Purchase Header with Line with "Prices Including VAT" = true
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        PurchaseHeader.SetHideValidationDialog(true);
        PurchaseHeader.Validate("Prices Including VAT", true);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
            VATPostingSetup.GetPurchAccount(false), LibraryRandom.RandInt(10));

        // [GIVEN] Validate "VAT Prod. Posting Group"
        // [GIVEN] Memorize "Direct Unit Cost" as "D"
        // [GIVEN] Memorize "Line Amount" as "L"
        PurchaseLine.Validate("VAT Prod. Posting Group");
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(1000, 2));
        PurchaseLine.Modify(true);
        DirectUnitCost := PurchaseLine."Direct Unit Cost";
        LineAmount := PurchaseLine."Line Amount";

        // [WHEN] Change "Prices Including VAT" to False
        PurchaseHeader.Validate("Prices Including VAT", false);

        // [THEN] "Direct Unit Cost" are equal to "D"
        // [THEN] "Line Amount" are equal to "L"
        PurchaseLine.TestField("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.TestField("Line Amount", LineAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangePriceIncludingVATTrueValueRecalculateAmountCorrectlyForFullVATWithDiscount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        DirectUnitCost: Decimal;
        LineAmount: Decimal;
    begin
        // [FEATURE] [Full VAT]
        // [SCENARIO 348949] Create Purchase line with "Prices Including VAT" = False, "Inv. Discount Amount" and Full VAT and change "Prices Including VAT" to True
        Initialize();

        // [GIVEN] Created VAT Posting Setup for Full VAT
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Full VAT", 100);

        // [GIVEN] Create Purchase Header with Line
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        PurchaseHeader.SetHideValidationDialog(true);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
            VATPostingSetup.GetPurchAccount(false), LibraryRandom.RandInt(10));

        // [GIVEN] Validate "VAT Prod. Posting Group"
        // [GIVEN] Memorize "Direct Unit Cost" as "D"
        // [GIVEN] Memorize "Line Amount" as "L"
        PurchaseLine.Validate("VAT Prod. Posting Group");
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(1000, 2));
        PurchaseLine.Modify(true);
        DirectUnitCost := PurchaseLine."Direct Unit Cost";
        LineAmount := PurchaseLine."Line Amount";

        // [GIVEN] Mock "Inv. Discount Amount" for line
        PurchaseLine."Inv. Discount Amount" := PurchaseLine."Line Amount" / 10;
        PurchaseLine.Modify();

        // [WHEN] Change "Prices Including VAT" to True
        PurchaseHeader.Validate("Prices Including VAT", true);

        // [THEN] "Direct Unit Cost" are equal to "D"
        // [THEN] "Line Amount" are equal to "L"
        PurchaseLine.TestField("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.TestField("Line Amount", LineAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangePriceIncludingVATFalseValueRecalculateAmountCorrectlyForFullVATWithDiscount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        DirectUnitCost: Decimal;
        LineAmount: Decimal;
    begin
        // [FEATURE] [Full VAT]
        // [SCENARIO 348949] Create Purchase line with "Prices Including VAT" = True, "Inv. Discount Amount" and Full VAT and change "Prices Including VAT" to False
        Initialize();

        // [GIVEN] Created VAT Posting Setup for Full VAT
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Full VAT", 100);

        // [GIVEN] Create Purchase Header with Line with "Prices Including VAT" = true
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        PurchaseHeader.SetHideValidationDialog(true);
        PurchaseHeader.Validate("Prices Including VAT", true);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
            VATPostingSetup.GetPurchAccount(false), LibraryRandom.RandInt(10));

        // [GIVEN] Validate "VAT Prod. Posting Group"
        // [GIVEN] Memorize "Direct Unit Cost" as "D"
        // [GIVEN] Memorize "Line Amount" as "L"
        PurchaseLine.Validate("VAT Prod. Posting Group");
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(1000, 2));
        PurchaseLine.Modify(true);
        DirectUnitCost := PurchaseLine."Direct Unit Cost";
        LineAmount := PurchaseLine."Line Amount";

        // [GIVEN] Mock "Inv. Discount Amount" for line
        PurchaseLine."Inv. Discount Amount" := PurchaseLine."Line Amount" / 10;
        PurchaseLine.Modify();

        // [WHEN] Change "Prices Including VAT" to False
        PurchaseHeader.Validate("Prices Including VAT", false);

        // [THEN] "Direct Unit Cost" are equal to "D"
        // [THEN] "Line Amount" are equal to "L"
        PurchaseLine.TestField("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.TestField("Line Amount", LineAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DocumentTotalsCalculateCorrectlyWithFullVATAndPriceIncludingVATTrue()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VATPostingSetup2: Record "VAT Posting Setup";
        TotalPurchaseLine: Record "Purchase Line";
        DocumentTotals: Codeunit "Document Totals";
        VATAmount: Decimal;
    begin
        // [FEATURE] [Full VAT]
        // [SCENARIO 348949] Create Purchase line with "Prices Including VAT" = True and Full VAT and check Totals
        Initialize();

        // [GIVEN] Created VAT Posting Setup for Full VAT
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Full VAT", 100);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup2, VATPostingSetup."VAT Bus. Posting Group", '');

        // [GIVEN] Create Purchase Header with "Prices Including VAT" and Purchase Line
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        PurchaseHeader.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        PurchaseHeader.Validate("Prices Including VAT", true);
        PurchaseHeader.Modify(true);
        CreatePurchaseLineWithGLAccount(PurchaseLine, PurchaseHeader, VATPostingSetup);

        // [GIVEN] Validate "VAT Prod. Posting Group" and "Direct Unit Cost"
        PurchaseLine.Validate("VAT Prod. Posting Group");
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(1000, 2));
        PurchaseLine.Modify(true);

        // [WHEN] Totals are calculated
        DocumentTotals.CalculatePurchaseTotals(TotalPurchaseLine, VATAmount, PurchaseLine);

        // [THEN] "Total Amount Excl. VAT" equal to 0
        // [THEN] "Total Amount Incl. VAT" equal to "Amount Including VAT"
        // [THEN] "Total VAT Amount" equal to "Amount Including VAT"
        TotalPurchaseLine.TestField(Amount, 0);
        TotalPurchaseLine.TestField("Amount Including VAT", PurchaseLine."Amount Including VAT");
        PurchaseLine.TestField("Amount Including VAT", VATAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotSetupAllowInvoiceDiscountForFullVATLine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VATPostingSetup2: Record "VAT Posting Setup";
    begin
        // [FEATURE] [Full VAT]
        // [SCENARIO 348949] Create Purchase line with Full VAT and try to set "Allow Invoice Disc." to True
        Initialize();

        // [GIVEN] Created VAT Posting Setup for Full VAT
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Full VAT", 100);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup2, VATPostingSetup."VAT Bus. Posting Group", '');

        // [GIVEN] Create Purchase Header with "Prices Including VAT" and Purchase Line
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        PurchaseHeader.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        PurchaseHeader.Validate("Prices Including VAT", true);
        PurchaseHeader.Modify(true);
        CreatePurchaseLineWithGLAccount(PurchaseLine, PurchaseHeader, VATPostingSetup);

        // [GIVEN] Validate "VAT Prod. Posting Group" and "Direct Unit Cost"
        PurchaseLine.Validate("VAT Prod. Posting Group");
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(1000, 2));
        PurchaseLine.Modify(true);

        // [WHEN] Set "Allow Invoice Disc." to True
        asserterror PurchaseLine.VALIDATE("Allow Invoice Disc.", true);

        // [THEN] The error was shown
        Assert.ExpectedError(CannotAllowInvDiscountErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AllowInvoiceDiscountResetToFalseAfterSetUpVATCalcullationTypeToFullVAT()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VATPostingSetup2: Record "VAT Posting Setup";
    begin
        // [FEATURE] [Full VAT]
        // [SCENARIO 348949] Create Purchase line with Normal VAT and change "VAT Prod. Posting Group" to Full VAT
        Initialize();

        // [GIVEN] VAT Posting Setup for Full VAT as "Full VAT Setup"
        // [GIVEN] VAT Posting Setup for Normal VAT as "Normal VAT Setup"
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Full VAT", 100);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup2, VATPostingSetup."VAT Bus. Posting Group", '');

        // [GIVEN] Create Purchase Header with "Prices Including VAT" and Purchase Line for "Full VAT Setup"
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        PurchaseHeader.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        PurchaseHeader.Validate("Prices Including VAT", true);
        PurchaseHeader.Modify(true);
        CreatePurchaseLineWithGLAccount(PurchaseLine, PurchaseHeader, VATPostingSetup);

        // [GIVEN] Validate "VAT Prod. Posting Group" and "Direct Unit Cost"
        PurchaseLine.Validate("VAT Prod. Posting Group");
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(1000, 2));

        // [GIVEN] Changed "VAT Prod. Posting Group" to "VAT Prod. Posting Group" from "Normal VAT Setup"
        PurchaseLine.Validate("VAT Prod. Posting Group", VATPostingSetup2."VAT Prod. Posting Group");
        PurchaseLine.Validate("Allow Invoice Disc.", true);

        // [WHEN] Change "VAT Prod. Posting Group" to "VAT Prod. Posting Group" from "Full VAT Setup"
        PurchaseLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");

        // [THEN] "Allow Invoice Disc." set to False
        PurchaseLine.TestField("Allow Invoice Disc.", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceFCYReverseChargeVATAndLineDiscount()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        GenJournalDocumentType: Enum "Gen. Journal Document Type";
        CurrencyCode: Code[10];
        ExchangeRateAmount: Decimal;
        ExpectedAmount: Decimal;
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Line Discount] [Reverse Charge VAT]
        // [SCENARIO 424978] System considers foreign currency exchange rate when posting negative VAT entry for Reverse Charge VAT caused by Line Discount.
        Initialize();

        ExchangeRateAmount := Round(1 / LibraryRandom.RandDecInRange(10, 20, 2));
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), ExchangeRateAmount, ExchangeRateAmount);
        CreatePurchaseHeader(PurchaseHeader, CreateVendor(CurrencyCode), PurchaseHeader."Document Type"::Invoice);

        CreateItemWithLastDirectCost(Item);
        CreateVATPostingSetupWithReverseChargeVAT(VATPostingSetup, PurchaseHeader);
        Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Item.Modify(true);

        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(100, 200));
        PurchaseLine.Validate("Line Discount %", LibraryRandom.RandIntInRange(20, 50));
        PurchaseLine.Modify(true);

        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        ExpectedAmount := Round(PurchaseLine."Line Discount Amount" * VATPostingSetup."VAT %" / 100 / ExchangeRateAmount);
        // Discounted VAT Amount on Purchase Account
        VerifyGLEntryForGLAccount(GenJournalDocumentType::Invoice, DocumentNo, VATPostingSetup.GetPurchAccount(false), false, -ExpectedAmount);
        // Discounted VAT Amount on Reverse Charge VAT Account
        VerifyGLEntryForGLAccount(GenJournalDocumentType::Invoice, DocumentNo, VATPostingSetup.GetRevChargeAccount(false), true, ExpectedAmount);
        // Discounted VAT Amount on VAT Entry
        VerifyVATEntryAmount(GenJournalDocumentType::Invoice, DocumentNo, false, -ExpectedAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceFCYNormalVATAndLineDiscount()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        GenJournalDocumentType: Enum "Gen. Journal Document Type";
        CurrencyCode: Code[10];
        ExchangeRateAmount: Decimal;
        ExpectedAmount: Decimal;
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Line Discount] [Normal VAT]
        // [SCENARIO 424978] System considers foreign currency exchange rate when posting negative VAT entry for Normal VAT caused by Line Discount.
        Initialize();

        ExchangeRateAmount := Round(1 / LibraryRandom.RandDecInRange(10, 20, 2));
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), ExchangeRateAmount, ExchangeRateAmount);
        CreatePurchaseHeader(PurchaseHeader, CreateVendor(CurrencyCode), PurchaseHeader."Document Type"::Invoice);

        CreateItemWithLastDirectCost(Item);
        CreateVATPostingSetupWithVATCalculationType(VATPostingSetup, PurchaseHeader, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Item.Modify(true);

        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(100, 200));
        PurchaseLine.Validate("Line Discount %", LibraryRandom.RandIntInRange(20, 50));
        PurchaseLine.Modify(true);

        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        ExpectedAmount := Round(PurchaseLine."Line Discount Amount" * VATPostingSetup."VAT %" / 100 / ExchangeRateAmount);
        // Discounted VAT Amount on Purchase Account
        VerifyGLEntryForGLAccount(GenJournalDocumentType::Invoice, DocumentNo, VATPostingSetup.GetPurchAccount(false), false, -ExpectedAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceRemitToNotEditableBeforeVendorSelected()
    var
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [FEATURE] [UI]
        // [Scenario] Remit-to code Field on Purchase Invoice Page not editable if no vendor selected
        // [Given]
        Initialize();

        // [WHEN] Purchase Invoice page is opened
        PurchaseInvoice.OpenNew();

        // [THEN] Field is not editable
        Assert.IsFalse(PurchaseInvoice."Remit-to Code".Editable(), RemitToCodeShouldNotBeEditableErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceRemitToEditableAfterVendorSelected()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseInvoice: TestPage "Purchase Invoice";
        VendorNo: Code[20];
    begin
        // [FEATURE] [UI]
        // [Scenario] Remit-to code Field on Purchase Invoice Page  editable if vendor selected
        // [Given]
        Initialize();

        // [Given] A sample Purchase Invoice
        VendorNo := LibraryPurchase.CreateVendorNo();
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(), LibraryRandom.RandInt(10));
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GotoRecord(PurchaseHeader);
        PurchaseInvoice."Buy-from Vendor No.".SetValue(VendorNo);

        // [THEN] Remit-to code Field is editable
        Assert.IsTrue(PurchaseInvoice."Remit-to Code".Editable(), RemitToCodeShouldBeEditableErr);
    end;

    [Test]
    [HandlerFunctions('PurchaseDocumentTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceReportVerifyRemit()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        RemitAddress: Record "Remit Address";
        PurchaseInvoicePage: TestPage "Purchase Invoice";
        VendorNo: Code[20];
        RequestPageXML: Text;
    begin
        // [SCENARIO] Create a Purchase Invoice with Negative quanity, try to post and then delete.
        Initialize();
        // Exercise: Update Permissions.
        LibraryLowerPermissions.SetO365Full();

        // [GIVEN] Create a new Remit-to address
        VendorNo := LibraryPurchase.CreateVendorNo();
        LibraryPurchase.CreateRemitToAddress(RemitAddress, VendorNo);

        // [GIVEN] Purchase Invoice with one Item
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(), LibraryRandom.RandInt(10));
        PurchaseHeader.Validate("Remit-to Code", RemitAddress.Code);
        PurchaseHeader.Modify(true);
        PurchaseInvoicePage.OpenEdit();
        PurchaseInvoicePage.GotoRecord(PurchaseHeader);
        Commit();

        // [WHEN] Run report "Purchase - Invoice"
        RequestPageXML := REPORT.RunRequestPage(REPORT::"Purchase Document - Test", RequestPageXML);
        LibraryReportDataset.RunReportAndLoad(REPORT::"Purchase Document - Test", PurchaseHeader, RequestPageXML);

        // [THEN] TotalBalOnBankAccount has value 200
        LibraryReportDataset.AssertElementWithValueExists('RemitToAddress_Name', RemitAddress.Name);

    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceChangeVendorDoUpdateRemitToCode()
    var
        PurchaseHeader: Record "Purchase Header";
        RemitAddress: Record "Remit Address";
        VendorNo: Code[20];
        VendorNo2: Code[20];
    begin
        // [SCENARIO] [542440] [Purchase Header] [Remit-to Code] is updated to empty when changing vendor to the one without Remit-to address
        Initialize();

        // [GIVEN] Create a new Vendor X and Remit-to address
        VendorNo := LibraryPurchase.CreateVendorNo();
        LibraryPurchase.CreateRemitToAddress(RemitAddress, VendorNo);

        // [GIVEN] Create a new Vendor Y without Remit-to address
        VendorNo2 := LibraryPurchase.CreateVendorNo();

        // [GIVEN] Purchase Invoice with vendor X and remit-to address
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        PurchaseHeader.Validate("Remit-to Code", RemitAddress.Code);

        // [WHEN] Change vendor to the one Y without Remit-to address
        PurchaseHeader.Validate("Buy-from Vendor No.", VendorNo2);

        // [THEN] Remit-to code is updated to empty
        PurchaseHeader.Testfield("Remit-to Code", '');
    end;

    [Test]
    [HandlerFunctions('VendorLookupSelectVendorPageHandler')]
    [Scope('OnPrem')]
    procedure EnsureInsertingSearchVendorNameInPurchaseInvoice()
    var
        Vendor: Record Vendor;
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 447956] Inserting the vendor name in a Purchase Invoice without any error
        Initialize();

        // [GIVEN] Create vendor
        LibraryPurchase.CreateVendor(Vendor);
        LibraryVariableStorage.Enqueue(Vendor."No.");

        // [WHEN] Create new Purchase Invoice and click on lookup at "Buy-from Vendor Name" field
        PurchaseInvoice.OpenNew();
        PurchaseInvoice."Buy-from Vendor Name".Lookup();

        // [THEN] Verify vendor name inserted to "Buy-from Vendor Name" without any error
        PurchaseInvoice."Buy-from Vendor Name".AssertEquals(Vendor.Name);
        PurchaseInvoice.Close();

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('GetReceiptLinesPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyDeferralEntry()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        PostedDeferralHeader: Record "Posted Deferral Header";
        DocumentNo: Code[20];
        DeferralCode: Code[10];
        PostingDate: Date;
    begin
        // [SCENARIO 458652] error message appears when posting a Purchase/Sales Invoice with Deferral Code get from Receipt/Shipment Lines
        Initialize();

        // [GIVEN] Create Deferral Template and Posting date within open accounting period
        DeferralCode := CreateDeferralTemplate();
        LibraryVariableStorage.Enqueue(DeferralCode);
        PostingDate := CalcDate('<+1D>', LibraryFiscalYear.GetFirstPostingDate(false));

        // [GIVEN] Create Vendor
        LibraryPurchase.CreateVendor(Vendor);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);

        // [GIVEN] Create GL Account and upate Daeferral Template and VAT prod Posting Group
        CreateGLAccount(GLAccount);
        GLAccount.Validate("Default Deferral Template Code", DeferralCode);
        GLAccount.Validate("VAT Prod. Posting Group", VATProductPostingGroup.Code);
        GLAccount.Modify();

        // [THEN] Create VATPosting Setup
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, Vendor."VAT Bus. Posting Group", GLAccount."VAT Prod. Posting Group");
        VATPostingSetup."Purchase VAT Account" := LibraryERM.CreateGLAccountNo();
        VATPostingSetup.Modify();

        // [GIVEN] Create Purchase Order and update Posting date in accounting period
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        PurchaseHeader.Validate("Posting Date", PostingDate);
        PurchaseHeader.Modify();

        // [GIVEN] Create Purchase Line  and update "Qty. to Receive" and "Direct Unit Cost"
        LibraryPurchase.CreatePurchaseLine(
         PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccount."No.", 2 * LibraryRandom.RandInt(20));
        PurchaseLine.Validate("Qty. to Receive", PurchaseLine.Quantity);
        PurchaseLine.Validate("Direct Unit Cost", 100 + LibraryRandom.RandDec(10, 2));
        PurchaseLine.Modify(true);

        // [THEN] Post Purchase Receipt
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] CReate Purchase Invoice and update Posting date within accounting period
        LibraryPurchase.CreatePurchHeader(PurchaseHeader2, PurchaseHeader2."Document Type"::Invoice, PurchaseHeader."Buy-from Vendor No.");
        PurchaseHeader2.Validate("Posting Date", PostingDate);
        PurchaseHeader2.Modify();

        // [THEN] Open Purchase Invoice and CLick on get Receipt line from action
        OpenPurchaseInvoiceAndGetReceiptLine(PurchaseHeader2."No.");
        PurchaseHeader2.Get(PurchaseHeader2."Document Type", PurchaseHeader2."No.");

        // [WHEN] Post the created Purchase Invoice.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader2, true, true);

        // [VERIFY] No error will come and Purchase Invoice will post with deferral schedule and verify Posted Deferral Schedule have entry
        PostedDeferralHeader.SetRange("Document Type", 7);
        PostedDeferralHeader.SetFilter("Document No.", DocumentNo);
        PostedDeferralHeader.FindFirst();
        Assert.AreEqual(DocumentNo, PostedDeferralHeader."Document No.", DocumentNoErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestCancellingInvoiceForBigAmount()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        GLEntry: Record "G/L Entry";
        ReasonCode: Record "Reason Code";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
        PostedPurchaseCreditMemo: TestPage "Posted Purchase Credit Memo";
        UnitPrice: Decimal;
    begin
        // [SCENARIO 473457] "Value is either too large or too small for a Decimal" while canceling invoice with big amount.
        Initialize();

        // [GIVEN] Save large value to calculation of Invoice
        UnitPrice := 4 * Power(10, 14);

        // [GIVEN] Get Last G/L Entry Posted
        if GLEntry.FindLast() then;

        // [GIVEN] Create Vendor
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Create Reason Code
        LibraryERM.CreateReasonCode(ReasonCode);

        // [GIVEN] Create Purchase Invoice
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");

        // [GIVEN] Update Reason Code in Purchase Header
        PurchaseHeader."Reason Code" := ReasonCode.Code;
        PurchaseHeader.Modify();

        // [GIVEN] Create Purchase Line
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), 1);

        // [GIVEN] Update Unit Price in Purchase Line.
        PurchaseLine.Validate("Direct Unit Cost", UnitPrice);
        PurchaseLine.Modify(true);

        // [WHEN] Post Purchase Invoice
        Codeunit.Run(Codeunit::"Purch.-Post", PurchaseHeader);

        // [GIVEN] Filter Posted Purchase Invoice on Purch. Inv. Header table
        PurchInvHeader.SetFilter("Buy-from Vendor No.", Vendor."No.");
        PurchInvHeader.FindFirst();

        // [GIVEN] Open Posted Purchase Invoice page.
        PostedPurchaseInvoice.OpenView();
        PostedPurchaseInvoice.GotoRecord(PurchInvHeader);

        // [GIVEN] Enqueue Cancel Confirm Handler values.
        LibraryVariableStorage.Enqueue(true); // for the cancel confirm handler
        LibraryVariableStorage.Enqueue(true); // for the open credit memo confirm handler

        // [THEN] Click on Cancel button of Posted Purchase Invoice and close the page
        PostedPurchaseCreditMemo.Trap();
        PostedPurchaseInvoice.CancelInvoice.Invoke();
        PostedPurchaseCreditMemo.Close();

        // [VERIFY] Verify Purchase Credit Memo posted successfully and everything will be reverted.
        CheckEverythingIsReverted(Item, Vendor, GLEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseInvoiceWhenAmountZero()
    var
        PurchHeader: Record "Purchase Header";
        PurchaseLine: array[2] of Record "Purchase Line";
        VATPostingSetup: array[2] of Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        TaxCalculationType: Enum "Tax Calculation Type";
        PostedDocumentNo: Code[20];
    begin
        // [SCENARIO 537597] ] No unexpected G/L Entry and VAT amount is posted for a line in purchase invoice with amount 0
        Initialize();

        // [GIVEN] Create Purchase Header with new Vendor
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());

        // [GIVEN] Create multiple VAT posting Setup
        CreateMultipleVATPostingSetup(VATPostingSetup, PurchHeader, TaxCalculationType::"Reverse Charge VAT");

        // [GIVEN] Create Purchase Libe with first VAT posting Setup
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine[1], PurchHeader, PurchaseLine[1].Type::"G/L Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup[1], GLAccount."Gen. Posting Type"::Purchase),
          LibraryRandom.RandDec(10, 2));

        // [GIVEN] Upate VAT Bus. Posting group and Direct Unit Cost
        PurchaseLine[1].Validate("VAT Prod. Posting Group", VATPostingSetup[1]."VAT Prod. Posting Group");
        PurchaseLine[1].Validate("Direct Unit Cost", LibraryRandom.RandDec(50, 2));
        PurchaseLine[1].Modify();

        // [GIVEN] Create Second Purchaes Libe
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine[2], PurchHeader, PurchaseLine[2].Type::"G/L Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup[2], GLAccount."Gen. Posting Type"::Purchase),
          LibraryRandom.RandDec(10, 2));

        // [WHEN] Post the Purchase Invoice
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

        // [WHEN] Find the 0 amount G/L ENtry
        FindGLEntry(GLEntry, PostedDocumentNo, PurchaseLine[2]."No.");

        // [THEN] Verify the 0 amount G/l entry posted.
        Assert.AreEqual(0, GLEntry.Amount, AmountZeroErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AmountUpdatedInPurchInvEntityAggregateTableWhenPurchInvHasLastLineAsGLAccount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate";
        LineAmtGLAccount: Decimal;
        LineAmtItem: Decimal;
        TotalAmountIncludingVAT: Decimal;
    begin
        // [SCENARIO 557775] Amount not updated in Purch. Inv. Entity Aggregate Table 5477 when last line of the Purchase Invoice has type G/L Account
        Initialize();

        // [GIVEN] Create Purchase Header and 2 Purchase Line, 1st line type with Item
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        LineAmtItem := CreatePurchLineWithReturnAmt(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem());
        TotalAmountIncludingVAT := PurchaseLine."Amount Including VAT";

        // [WHEN] 2nd line type with G/L Account
        LineAmtGLAccount := CreatePurchLineWithReturnAmt(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup());
        TotalAmountIncludingVAT += PurchaseLine."Amount Including VAT";

        // [THEN] Verify Amount and "Amount Including VAT" as same as total amounts on purchase lines
        PurchInvEntityAggregate.SetRange("No.", PurchaseHeader."No.");
        PurchInvEntityAggregate.FindFirst();
        Assert.AreEqual(LineAmtGLAccount + LineAmtItem, PurchInvEntityAggregate.Amount, AmountMustSameErr);
        Assert.AreEqual(TotalAmountIncludingVAT, PurchInvEntityAggregate."Amount Including VAT", AmountMustSameErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateExtendedTextTypeNotAllowed()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [SCENARIO 564049] Error message when adding a Purchase line with type Item that have extended text previously
        Initialize();

        // [GIVEN] Item "X" with Extended Text
        CreateItemAndExtendedText(Item);

        // [GIVEN] Create Purchase Header
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');

        // [GIVEN] Purchase Line with Item, second Purchase Line with Extended Text
        CreatePurchLineWithExtendedText(PurchaseHeader, Item."No.");

        // [WHEN] Get extended text Purchase Line
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindLast();

        // [THEN] Error come when try to change type of extended text Purchase line
        asserterror PurchaseLine.Validate(Type, PurchaseLine.Type::Item);

        // [THEN] Verify the error of extended text
        Assert.ExpectedError(StrSubstNo(ChangeExtendedTextErr, PurchaseLine.FieldCaption(Type)));
    end;

    [Test]
    procedure VerifySourceCurrencyAmountForReverseCharge()
    var
        //myInt: Integer;
        GenJournalLine: Record "Gen. Journal Line";
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        CurrencyCode: Code[10];
        GLAccountNo: Code[20];
    begin
        // [SCENARIO 572499] Wrong calculation in Source Currency Amount when VAT calculation type is Reverse Charge in VAT posting setup and the posting is done via Journal.
        Initialize();

        // [GIVEN] Create Currency with Exchange Rate
        CurrencyCode := CreateCurrency();

        // [GIVEN] Create VAT Posting Setup With Reverse Charge VAT and create new GL Account
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
        GLAccountNo := LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase);

        // [GIVEN] Create Gen. Journal and assign the same currency created above
        CreateGnlJnlLines(GenJournalLine, GLAccountNo, LibraryRandom.RandIntInRange(10000, 10000));
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Modify(true);

        // [WHEN] Post Gen Journal Line
        LibraryVariableStorage.Enqueue(GenJournalLine."Document No.");
        LibraryVariableStorage.Enqueue(GenJournalLine.Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Verify Source Currency Amount for Reverse Charge VAT Account in GL Entry
        VerifySourceCurrencyAmountInGLEntry(VATPostingSetup);
        LibraryVariableStorage.Clear();
    end;

    local procedure Initialize()
    var
        ICSetup: Record "IC Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PriceListLine: Record "Price List Line";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Purchase Invoice");
        if not ICSetup.Get() then begin
            ICSetup.Init();
            ICSetup.Insert();
        end;
        ICSetup."Auto. Send Transactions" := false;
        ICSetup.Modify();
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();
        PurchaseLine.DeleteAll();
        PurchaseHeader.DontNotifyCurrentUserAgain(PurchaseHeader.GetModifyVendorAddressNotificationId());
        PurchaseHeader.DontNotifyCurrentUserAgain(PurchaseHeader.GetModifyPayToVendorAddressNotificationId());
        PriceListLine.DeleteAll();
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Purchase Invoice");

        LibraryTemplates.EnableTemplatesFeature();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        isInitialized := true;
        Commit();

        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Purchase Invoice");
    end;

    local procedure CopyDocument(PurchHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type From"; DocumentNo: Code[20])
    begin
        LibraryPurchase.CopyPurchaseDocument(PurchHeader, DocumentType, DocumentNo, true, false);
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.SetCurrencyGainLossAccounts(Currency);
        Currency.Validate("Residual Gains Account", Currency."Realized Gains Acc.");
        Currency.Validate("Residual Losses Account", Currency."Realized Losses Acc.");
        Currency.Modify(true);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Last Direct Cost", LibraryRandom.RandInt(100));  // Using RANDOM value for Last Direct Cost.
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateItemWithLastDirectCost(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Last Direct Cost", LibraryRandom.RandDecInRange(1000, 2000, 2));
        Item.Modify(true);
    end;

    local procedure CreateServiceItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Last Direct Cost", LibraryRandom.RandInt(100));  // Using RANDOM value for Last Direct Cost.
        Item.Type := Item.Type::Service;
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateNonStockItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Last Direct Cost", LibraryRandom.RandInt(100));  // Using RANDOM value for Last Direct Cost.
        Item.Type := Item.Type::"Non-Inventory";
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateItemAndExtendedText(var Item: Record Item): Text[100]
    var
        ExtendedTextHeader: Record "Extended Text Header";
        ExtendedTextLine: Record "Extended Text Line";
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Automatic Ext. Texts", true);
        Item.Modify(true);

        LibraryInventory.CreateExtendedTextHeaderItem(ExtendedTextHeader, Item."No.");
        LibraryInventory.CreateExtendedTextLineItem(ExtendedTextLine, ExtendedTextHeader);
        UpdateTextInExtendedTextLine(ExtendedTextLine, Item."No.");
        exit(ExtendedTextLine.Text);
    end;

    local procedure CreateAndModifyItem(VATProductPostingGroup: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Last Direct Cost", LibraryRandom.RandDec(100, 2));  // Using RANDOM value for Last Direct Cost.
        Item.Validate("VAT Prod. Posting Group", VATProductPostingGroup);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateAndPostPurchaseInvoice(var PurchaseLine: Record "Purchase Line"; Type: Enum "Purchase Line Type"; CurrencyCode: Code[10]; VATPostingSetup: Record "VAT Posting Setup"): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        No: Code[20];
        VendorNo: Code[20];
    begin
        VendorNo := CreateAndModifyVendor(CurrencyCode, VATPostingSetup."VAT Bus. Posting Group");

        case Type of
            PurchaseLine.Type::Item:
                No := CreateAndModifyItem(VATPostingSetup."VAT Prod. Posting Group");
            PurchaseLine.Type::"Fixed Asset":
                No := CreateFixedAssetWithGroup(VATPostingSetup);
        end;

        // Use Random values for Quantity and Direct Unit Cost.
        CreatePurchaseHeader(PurchaseHeader, VendorNo, PurchaseHeader."Document Type"::Invoice);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Type, No, LibraryRandom.RandDec(100, 2));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateAndPostSimplePurchaseDocument(DocType: Enum "Purchase Document Type"; var VendorNo: Code[20]): Code[20]
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        VendorNo := LibraryPurchase.CreateVendorNo();
        CreatePurchaseHeader(PurchHeader, VendorNo, DocType);
        LibraryPurchase.CreatePurchaseLine(
          PurchLine, PurchHeader, PurchLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
        PurchLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchLine.Modify(true);
        exit(LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true));
    end;

    local procedure CreateAndReceivePurchaseDocument(BuyFromVendorNo: Code[20]; PayToVendorNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Create Purchase document using Random Quantity.
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order, BuyFromVendorNo, PayToVendorNo);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
    end;

    local procedure CreateFixedAssetWithGroup(VATPostingSetup: Record "VAT Posting Setup"): Code[20]
    var
        FixedAsset: Record "Fixed Asset";
        FAPostingGroup: Record "FA Posting Group";
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);
        UpdateFAPostingGroup(FAPostingGroup, VATPostingSetup);
        FixedAsset.Validate("FA Posting Group", FAPostingGroup.Code);
        FixedAsset.Modify(true);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset);
        exit(FixedAsset."No.");
    end;

    local procedure CreateFADepreciationBook(var FADepreciationBook: Record "FA Depreciation Book"; FixedAsset: Record "Fixed Asset")
    begin
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", LibraryFixedAsset.GetDefaultDeprBook());
        FADepreciationBook.Validate("Depreciation Starting Date", WorkDate());

        // Random Number Generator for Ending date.
        FADepreciationBook.Validate("Depreciation Ending Date", CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'Y>', WorkDate()));
        FADepreciationBook.Validate("FA Posting Group", FixedAsset."FA Posting Group");
        FADepreciationBook.Modify(true);
    end;

    local procedure CreatePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20]; DocumentType: Enum "Purchase Document Type")
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
    end;

    local procedure CreatePurchaseHeaderWithPostingNo(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20]; PostingDateShift: Integer; PostingNo: Code[20])
    begin
        CreatePurchaseHeader(PurchaseHeader, VendorNo, PurchaseHeader."Document Type"::Invoice);
        PurchaseHeader.Validate("Posting Date", PurchaseHeader."Posting Date" + PostingDateShift);
        PurchaseHeader.Validate("Posting No.", PostingNo);
        PurchaseHeader.Modify(true);
    end;

    local procedure CreatePurchaseInvoice(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; VendorNo: Code[20])
    var
        Counter: Integer;
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);

        // Create Multiple purchase line and using RANDOM for Quantity.
        for Counter := 1 to 1 + LibraryRandom.RandInt(10) do
            LibraryPurchase.CreatePurchaseLine(
              PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(), LibraryRandom.RandInt(10));
    end;

    local procedure CreatePurchInvWithPricesIncludingVAT(var PurchaseHeader: Record "Purchase Header"; PurchaseLineDiscount: Record "Purchase Line Discount"; PricesIncludingVAT: Boolean)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseHeader(PurchaseHeader, PurchaseLineDiscount."Vendor No.", PurchaseHeader."Document Type"::Invoice);
        PurchaseHeader.Validate("Prices Including VAT", PricesIncludingVAT);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, PurchaseLineDiscount."Item No.",
          PurchaseLineDiscount."Minimum Quantity" + LibraryRandom.RandInt(10));  // Take Quantity greater than Purchase Line Discount Minimum Quantity.
    end;

    local procedure CreatePurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; InvDiscountAmount: Decimal)
    var
        QtyToReceive: Decimal;
    begin
        // Using RANDOM value for Quantity and Direct Unit Cost. Amount greater than 100 needed to avoid rounding issue.
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(), 2 * LibraryRandom.RandInt(20));
        QtyToReceive := PurchaseLine.Quantity / 2; // Taking here 2 for partial posting.
        // Used in QuantityOnGetReceiptLinesPageHandler, QuantityFilterUsingGetReceiptLinesPageHandler and InvokeGetReceiptLinesPageHandler
        LibraryVariableStorage.Enqueue(QtyToReceive);
        PurchaseLine.Validate("Qty. to Receive", QtyToReceive);
        PurchaseLine.Validate("Direct Unit Cost", 100 + LibraryRandom.RandDec(10, 2));
        PurchaseLine.Validate("Inv. Discount Amount", InvDiscountAmount);
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchLineWithReturnAmt(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; Type: Enum "Purchase Line Type"; No: Code[20]): Decimal
    begin
        // Take random values for Quantity and Unit Cost Amount greater than 100 needed to avoid rounding issue.
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Type, No, 10 + LibraryRandom.RandDec(10, 2));
        PurchaseLine.Validate("Direct Unit Cost", 100 + LibraryRandom.RandDec(10, 2));
        PurchaseLine.Modify(true);
        exit(PurchaseLine."Line Amount");
    end;

    local procedure CreatePurchLineWithExtendedText(PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
        TransferExtendedText: Codeunit "Transfer Extended Text";
    begin
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, LibraryRandom.RandInt(10));
        TransferExtendedText.PurchCheckIfAnyExtText(PurchaseLine, true);
        TransferExtendedText.InsertPurchExtText(PurchaseLine);
    end;

    local procedure CreateAndPostPurchaseOrder(var PurchaseLine: Record "Purchase Line"; var InvDiscountAmount: Decimal) DocumentNo: Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        InvDiscountAmount := 10 + 10 * LibraryRandom.RandDec(10, 2);  // Using RANDOM value for Invoice Discount Amount.
        CreatePurchaseHeader(PurchaseHeader, CreateVendor(''), PurchaseHeader."Document Type"::Order);
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, InvDiscountAmount);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreatePurchDocWithPricesInclVAT(var PurchHeader: Record "Purchase Header"; DocType: Enum "Purchase Document Type"; VendNo: Code[20]; PricesInclVAT: Boolean)
    begin
        LibraryPurchase.CreatePurchHeader(PurchHeader, DocType, VendNo);
        PurchHeader.Validate("Prices Including VAT", PricesInclVAT);
        PurchHeader.Modify(true);
    end;

    local procedure CreateVendor(CurrencyCode: Code[10]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Currency Code", CurrencyCode);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateVendorWithPaymentTermsCode(PaymentTermsCode: Code[10]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(CreateVendor(''));
        Vendor.Validate("Payment Terms Code", PaymentTermsCode);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateAndModifyVendor(CurrencyCode: Code[10]; VATBusinessPostingGroup: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(CreateVendor(CurrencyCode));
        Vendor.Validate("VAT Bus. Posting Group", VATBusinessPostingGroup);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateVendorsWithSameName(var Vendor1: Record Vendor; var Vendor2: Record Vendor)
    begin
        LibraryPurchase.CreateVendor(Vendor1);
        LibraryPurchase.CreateVendor(Vendor2);
        Vendor1.Validate(Name, CopyStr(LibraryUtility.GenerateRandomAlphabeticText(100, 0), 1, MaxStrLen(Vendor1.Name)));
        Vendor1.Modify(true);
        Vendor2.Validate(Name, Vendor1.Name);
        Vendor2.Modify(true);
    end;

    local procedure CreatePurchaseInvoiceCurrency(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"): Decimal
    var
        VendorInvoiceDisc: Record "Vendor Invoice Disc.";
    begin
        // Take Random Amount for Quantity and Line Discount % in Purchase Line and Zero for Minimum Amount in Invoice Discount.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, SetupInvoiceDiscount(VendorInvoiceDisc, 0));
        PurchaseHeader.Validate("Prices Including VAT", true);
        PurchaseHeader.Validate("Currency Code", CreateCurrency());
        PurchaseHeader.Modify(true);

        // Take Quantity in Multiple of 2 so that we can take half equal value without Decimal.
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(), LibraryRandom.RandInt(10) * 2);
        PurchaseLine.Validate("Line Discount %", LibraryRandom.RandDec(10, 2));
        PurchaseLine.Modify(true);
        exit(VendorInvoiceDisc."Discount %");
    end;

    local procedure CreateVendorCard() VendorNo: Code[20]
    var
        VendorCard: TestPage "Vendor Card";
    begin
        VendorCard.OpenNew();
        VendorCard.Name.Activate();
        VendorNo := CopyStr(VendorCard."No.".Value(), 1, MaxStrLen(VendorNo));
        VendorCard.OK().Invoke();
    end;

    local procedure CreateVendorWithDimension(var DefaultDimension: Record "Default Dimension")
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
    begin
        LibraryDimension.FindDimension(Dimension);
        LibraryDimension.FindDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDefaultDimensionVendor(
          DefaultDimension, CreateVendor(''), DimensionValue."Dimension Code", DimensionValue.Code);
    end;

    local procedure CreateVendorWithNewPostingGroups(): Code[20]
    var
        Vendor: Record Vendor;
        VendorPostingGroup: Record "Vendor Posting Group";
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
    begin
        LibraryPurchase.CreateVendorPostingGroup(VendorPostingGroup);
        LibraryERM.CreateGenBusPostingGroup(GenBusinessPostingGroup);
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Vendor Posting Group", VendorPostingGroup.Code);
        Vendor.Validate("Gen. Bus. Posting Group", GenBusinessPostingGroup.Code);
        Vendor.Validate("VAT Bus. Posting Group", VATBusinessPostingGroup.Code);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateReceiptsAndPurchaseInvoice(var PurchaseHeader: Record "Purchase Header")
    var
        Vendor: Record Vendor;
        Vendor2: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        CreateAndReceivePurchaseDocument(Vendor."No.", Vendor."No.");
        LibraryPurchase.CreateVendor(Vendor2);
        CreateAndReceivePurchaseDocument(Vendor2."No.", Vendor2."No.");
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; BuyFromVendorNo: Code[20]; PayToVendorNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // Create Purchase document using Random Quantity and Direct Unit Cost.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, BuyFromVendorNo);
        PurchaseHeader.Validate("Pay-to Vendor No.", PayToVendorNo);
        PurchaseHeader.Modify(true);
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, 0);  // Using 0 for Invoice Discount.
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; VendorNo: Code[20]; DocumentType: Enum "Purchase Document Type")
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(), LibraryRandom.RandInt(10));
    end;

    local procedure CreateReceivePurchOrderWithPricesInclVATAndLineDisc(var PurchHeader: Record "Purchase Header"; var VATPercent: Decimal; LineDiscAmt: Decimal; PricesInclVAT: Boolean)
    var
        PurchLine: Record "Purchase Line";
    begin
        CreatePurchDocWithPricesInclVAT(
          PurchHeader, PurchHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo(), PricesInclVAT);
        LibraryPurchase.CreatePurchaseLine(
          PurchLine, PurchHeader, PurchLine.Type::Item, LibraryInventory.CreateItemNo(),
          LibraryRandom.RandIntInRange(100, 1000));
        VATPercent := PurchLine."VAT %";
        PurchLine.Validate("Line Discount Amount", LineDiscAmt);
        PurchLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchHeader, true, false);
    end;

    local procedure CreateVATPostingSetupWithReverseChargeVAT(var VATPostingSetup: Record "VAT Posting Setup"; PurchaseHeader: Record "Purchase Header")
    begin
        CreateVATPostingSetupWithVATCalculationType(VATPostingSetup, PurchaseHeader, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
    end;

    local procedure CreateVATPostingSetupWithVATCalculationType(var VATPostingSetup: Record "VAT Posting Setup"; PurchaseHeader: Record "Purchase Header"; TaxCalculationType: Enum "Tax Calculation Type")
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, TaxCalculationType, LibraryRandom.RandIntInRange(15, 35));
        VATPostingSetup."VAT Bus. Posting Group" := PurchaseHeader."VAT Bus. Posting Group";
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        VATPostingSetup."VAT Prod. Posting Group" := VATProductPostingGroup.Code;
        VATPostingSetup."Reverse Chrg. VAT Acc." := LibraryERM.CreateGLAccountNo();
        VATPostingSetup.Insert();
    end;

    local procedure DeletePurchaseLine(DocumentNo: Code[20]; Type: Enum "Purchase Line Type"; ItemNo: Code[20])
    var
        PurchLine: Record "Purchase Line";
    begin
        FindPurchaseLineByType(PurchLine, DocumentNo, Type, ItemNo);
        PurchLine.Delete(true);
    end;

    local procedure DueDateOnPurchaseDocumentAfterCopyDocument(PurchaseHeaderDocumentType: Enum "Purchase Document Type")
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PaymentTerms: Record "Payment Terms";
        PurchaseInvoiceNo: Code[20];
    begin
        // Setup: Create and Post Purchase Order and Create Purchase Document.
        Initialize();
        LibraryERM.GetDiscountPaymentTerm(PaymentTerms);
        CreatePurchaseOrder(
          PurchaseHeader, PurchaseLine, CreateVendorWithPaymentTermsCode(PaymentTerms.Code), PurchaseHeader."Document Type"::Order);
        PurchaseInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader2, PurchaseHeaderDocumentType, PurchaseHeader."Buy-from Vendor No.");

        // Exercise: Run Copy Purchase Document Report with Include Header,Recalculate Lines as True.
        PurchaseCopyDocument(PurchaseHeader2, PurchaseInvoiceNo, "Purchase Document Type From"::"Posted Invoice", true);

        // Verify: Verify Due Date on Purchase Header.
        VerifyDueDateOnPurchaseDocumentHeader(PurchaseHeader2, PaymentTerms."Due Date Calculation");
    end;

    local procedure FindFixedAsset(): Code[20]
    var
        FixedAsset: Record "Fixed Asset";
    begin
#pragma warning disable AA0210
        FixedAsset.SetRange(Blocked, false);
#pragma warning restore AA0210
        FixedAsset.FindFirst();
        exit(FixedAsset."No.");
    end;

    local procedure FindGLEntry(var GLEntry: Record "G/L Entry"; DocumentNo: Code[20]; GLAccountNo: Code[20])
    begin
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.FindFirst();
    end;

    local procedure FindPurchaseLine(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; DocumentNo: Code[20])
    begin
        PurchaseLine.SetRange("Document Type", DocumentType);
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.SetFilter(Type, '<>''''');
        PurchaseLine.FindFirst();
    end;

    local procedure FindPurchaseLineByType(var PurchLine: Record "Purchase Line"; DocumentNo: Code[20]; Type: Enum "Purchase Line Type"; ItemNo: Code[20])
    begin
        PurchLine.SetRange("Document No.", DocumentNo);
        PurchLine.SetRange(Type, Type);
        PurchLine.SetRange("No.", ItemNo);
        PurchLine.FindFirst();
    end;

    local procedure FindVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    begin
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, DocumentType, DocumentNo);
        VendorLedgerEntry.CalcFields(Amount);
    end;

    local procedure FindVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        VATPostingSetup.SetRange("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::" ");
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
    end;

    local procedure FindPostedPurchaseInvoiceNo(OrderNo: Code[20]): Code[20]
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader.SetRange("Order No.", OrderNo);
        PurchInvHeader.FindFirst();
        exit(PurchInvHeader."No.");
    end;

    local procedure FindPurchRcptHeaderNo(OrderNo: Code[20]): Code[20]
    var
        PurchRcptHeader: Record "Purch. Rcpt. Header";
    begin
        PurchRcptHeader.SetRange("Order No.", OrderNo);
        PurchRcptHeader.FindFirst();
        exit(PurchRcptHeader."No.");
    end;

    local procedure FindICGLAccount(): Code[20]
    var
        ICGLAccount: Record "IC G/L Account";
    begin
#pragma warning disable AA0210
        ICGLAccount.SetRange("Account Type", ICGLAccount."Account Type"::Posting);
        ICGLAccount.SetRange(Blocked, false);
#pragma warning restore AA0210
        ICGLAccount.FindFirst();
        exit(ICGLAccount."No.");
    end;

    local procedure FilterQuantityOnGetReceiptLines(var GetReceiptLines: TestPage "Get Receipt Lines"; DocumentNo: Code[20]; Quantity: Decimal)
    begin
        GetReceiptLines.FILTER.SetFilter("Document No.", DocumentNo);
        GetReceiptLines.FILTER.SetFilter(Quantity, Format(Quantity));
        GetReceiptLines.Quantity.AssertEquals(Quantity);
    end;

    local procedure FindRcptLine(var PurchRcptLine: Record "Purch. Rcpt. Line"; OrderNo: Code[20])
    var
        PurchRcptHeader: Record "Purch. Rcpt. Header";
    begin
        PurchRcptHeader.SetRange("Order No.", OrderNo);
        PurchRcptHeader.FindFirst();
        PurchRcptLine.SetRange("Document No.", PurchRcptHeader."No.");
        PurchRcptLine.FindFirst();
    end;

    local procedure OpenPurchaseInvoiceAndGetReceiptLine(No: Code[20])
    var
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.FILTER.SetFilter("No.", No);
        PurchaseInvoice.PurchLines.GetReceiptLines.Invoke();
    end;

    local procedure PartiallyPostPurchaseOrder(var PurchaseHeader: Record "Purchase Header")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VendorNo: Code[20];
    begin
        // Create and Receive two Purchase Orders using same Vendor and create Purchase Invoice.

        // Using global variables(PostedDocumentNo and PostedDocumentNo2) due to need in verification.
        FindVATPostingSetup(VATPostingSetup);
        VendorNo := CreateAndModifyVendor('', VATPostingSetup."VAT Bus. Posting Group");
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo, VendorNo);
        LibraryVariableStorage.Enqueue(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false));

        PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, PurchaseHeader."No.");
        LibraryVariableStorage.Enqueue(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false));

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);

        // Open created Purchase Invoice page and do Get Receipt Line.
        OpenPurchaseInvoiceAndGetReceiptLine(PurchaseHeader."No.");
    end;

    local procedure PurchaseCopyDocument(PurchaseHeader: Record "Purchase Header"; DocumentNo: Code[20]; DocumentType: Enum "Purchase Document Type From"; ReCalculateLines: Boolean)
    var
        CopyPurchaseDocument: Report "Copy Purchase Document";
    begin
        CopyPurchaseDocument.SetPurchHeader(PurchaseHeader);
        CopyPurchaseDocument.SetParameters(DocumentType, DocumentNo, true, ReCalculateLines);
        CopyPurchaseDocument.UseRequestPage(false);
        CopyPurchaseDocument.Run();
    end;

    local procedure UpdateFAPostingGroup(FAPostingGroup: Record "FA Posting Group"; VATPostingSetup: Record "VAT Posting Setup")
    var
        FAPostingGroup2: Record "FA Posting Group";
        GLAccount: Record "G/L Account";
        GLAccountNo: Code[20];
    begin
#pragma warning disable AA0210
        FAPostingGroup2.SetFilter("Acquisition Cost Account", '<>''''');
#pragma warning restore AA0210
        FAPostingGroup2.FindFirst();
        FAPostingGroup.TransferFields(FAPostingGroup2, false);

        GLAccountNo :=
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase);
        FAPostingGroup.Validate("Acquisition Cost Account", GLAccountNo);
        FAPostingGroup.Modify(true);
    end;

    local procedure UpdateWarehouseLocation(RequireReceive: Boolean): Code[10]
    var
        Location: Record Location;
    begin
        Location.SetRange("Bin Mandatory", false);
        Location.SetRange("Use As In-Transit", false);
        Location.FindFirst();
        Location.Validate("Require Receive", RequireReceive);
        Location.Modify(true);
        exit(Location.Code);
    end;

    local procedure UpdateTextInExtendedTextLine(var ExtendedTextLine: Record "Extended Text Line"; TextLineText: Text[50])
    begin
        ExtendedTextLine.Validate(Text, TextLineText);
        ExtendedTextLine.Modify(true);
    end;

    local procedure UpdatePurchaseAndPayableSetup(ReceiptOnInvoice: Boolean; RetShpmtOnCrMemo: Boolean)
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        // Update Purchase and Payable Setup to generate Posted Purchase Receipt document from Purchase Invoice.
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Receipt on Invoice", ReceiptOnInvoice);
        PurchasesPayablesSetup.Validate("Return Shipment on Credit Memo", RetShpmtOnCrMemo);
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure UpdatePurchasePayablesSetupCalcInvDisc(CalcInvDiscount: Boolean)
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Calc. Inv. Discount", CalcInvDiscount);
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure UpdatePurchasePayablesSetupExactCostReversing(CostReversing: Boolean)
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Exact Cost Reversing Mandatory", CostReversing);
        PurchasesPayablesSetup.Modify(true);
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

    local procedure SetNoSeriesDateOrder(DateOrder: Boolean) OldDateOrder: Boolean
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        NoSeries: Record "No. Series";
    begin
        PurchasesPayablesSetup.Get();
        NoSeries.Get(PurchasesPayablesSetup."Posted Invoice Nos.");
        OldDateOrder := NoSeries."Date Order";
        NoSeries.Validate("Date Order", DateOrder);
        NoSeries.Modify(true);
    end;

    local procedure SetupInvoiceDiscount(var VendorInvoiceDisc: Record "Vendor Invoice Disc."; MinimumAmount: Decimal): Code[20]
    begin
        // Required Random Value for "Minimum Amount" and "Discount %" fields value is not important.
        LibraryERM.CreateInvDiscForVendor(VendorInvoiceDisc, CreateVendor(''), '', MinimumAmount);
        VendorInvoiceDisc.Validate("Discount %", LibraryRandom.RandInt(10));
        VendorInvoiceDisc.Modify(true);
        exit(VendorInvoiceDisc.Code);
    end;

    local procedure SetupLineDiscount(var PurchaseLineDiscount: Record "Purchase Line Discount")
    var
        GeneralPostingSetup: Record "General Posting Setup";
        Item: Record Item;
        VATPostingSetup: Record "VAT Posting Setup";
        Vendor: Record Vendor;
    begin
        // Required Random Value for "Minimum Quantity" and "Line Discount %" fields value is not important.
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        Item.Get(CreateAndModifyItem(VATPostingSetup."VAT Prod. Posting Group"));
        LibraryERM.CreateLineDiscForVendor(
          PurchaseLineDiscount, Item."No.", CreateAndModifyVendor('', VATPostingSetup."VAT Bus. Posting Group"), WorkDate(), '', '',
          Item."Base Unit of Measure", LibraryRandom.RandInt(10));
        PurchaseLineDiscount.Validate("Line Discount %", LibraryRandom.RandInt(10));
        PurchaseLineDiscount.Modify(true);

        // Set unique "Purch. Line Disc. Account"
        Vendor.Get(PurchaseLineDiscount."Vendor No.");
        GeneralPostingSetup.Get(Vendor."Gen. Bus. Posting Group", Item."Gen. Prod. Posting Group");
        GeneralPostingSetup.Validate(
          "Purch. Line Disc. Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"));
        GeneralPostingSetup.Modify(true);
    end;

    local procedure VerifyAdditionalAmtOnGLEntry(DocumentNo: Code[20]; GLAccountNo: Code[20]; AdditionalCurrencyAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindFirst();
        Assert.AreNearlyEqual(
          AdditionalCurrencyAmount, GLEntry."Additional-Currency Amount", LibraryERM.GetInvoiceRoundingPrecisionLCY(),
          StrSubstNo(
            ValidateErr, GLEntry.FieldCaption("Additional-Currency Amount"), AdditionalCurrencyAmount, GLEntry.TableCaption(), GLEntry."Entry No."));
    end;

    local procedure VerifyAmountOnGLEntry(DocumentNo: Code[20]; GLAccountNo: Code[20]; Amount2: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindFirst();
        Assert.AreNearlyEqual(
          Amount2, GLEntry.Amount, LibraryERM.GetInvoiceRoundingPrecisionLCY(),
          StrSubstNo(ValidateErr, GLEntry.FieldCaption(Amount), Amount2, GLEntry.TableCaption(), GLEntry."Entry No."));
    end;

    local procedure VerifyAmountOnVATEntry(DocumentNo: Code[20]; VATProdPostingGroupCode: Code[20]; Amount2: Decimal)
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.SetRange("VAT Prod. Posting Group", VATProdPostingGroupCode);
        // required for BE to avoid finding rounding VAT Entry
        VATEntry.FindFirst();
        Assert.AreNearlyEqual(
          Amount2, VATEntry.Amount, LibraryERM.GetInvoiceRoundingPrecisionLCY(),
          StrSubstNo(ValidateErr, VATEntry.FieldCaption(Amount), Amount2, VATEntry.TableCaption(), VATEntry."Entry No."));
    end;

    local procedure VerifyAmountOnVendor(VendorNo: Code[20]; Amount: Decimal)
    var
        Vendor: Record Vendor;
        TotalAmountLCY: Decimal;
    begin
        Vendor.Get(VendorNo);
        Vendor.CalcFields("Balance (LCY)", "Outstanding Orders (LCY)", "Amt. Rcd. Not Invoiced (LCY)", "Outstanding Invoices (LCY)");
        TotalAmountLCY :=
          Vendor."Balance (LCY)" +
          Vendor."Outstanding Orders (LCY)" + Vendor."Amt. Rcd. Not Invoiced (LCY)" + Vendor."Outstanding Invoices (LCY)";
        Vendor.TestField("Balance (LCY)", Amount);
        Assert.AreEqual(TotalAmountLCY, Amount, StrSubstNo(AmountErr, 'Total LCY', Vendor.TableCaption()));
    end;

    local procedure VerifyAmountLCYOnVendorLedger(DocumentNo: Code[20]; AmountLCY: Decimal)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("Document No.", DocumentNo);
        VendorLedgerEntry.FindFirst();
        VendorLedgerEntry.CalcFields("Amount (LCY)");
        Assert.AreNearlyEqual(
          AmountLCY, VendorLedgerEntry."Amount (LCY)", LibraryERM.GetInvoiceRoundingPrecisionLCY(),
          StrSubstNo(ValidateErr, VendorLedgerEntry.FieldCaption("Amount (LCY)"), AmountLCY, VendorLedgerEntry.TableCaption(), VendorLedgerEntry."Entry No."));
    end;

    local procedure VerifyPurchLineAmount(DocumentNo: Code[20]; No: Code[20]; LineAmount: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.SetRange("No.", No);
        PurchaseLine.FindFirst();
        PurchaseLine.TestField("Line Amount", LineAmount);
    end;

    local procedure VerifyGLEntry(DocumentNo: Code[20]; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
        TotalGLAmount: Decimal;
    begin
        GeneralLedgerSetup.Get();
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Invoice);
        GLEntry.SetFilter(Amount, '>0');
        GLEntry.CalcSums(Amount);
        TotalGLAmount := GLEntry.Amount;
        Assert.AreNearlyEqual(
          Amount, TotalGLAmount, GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(AmountErr, GLEntry.FieldCaption(Amount), GLEntry.TableCaption()));
    end;

    local procedure VerifyGLEntryForGLAccount(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; GLAccountNo: Code[20]; PositiveAmount: Boolean; ExpectedAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
#pragma warning disable AA0210
        GLEntry.SetRange("Document Type", DocumentType);
#pragma warning restore AA0210
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        if PositiveAmount then
            GLEntry.SetFilter(Amount, '>0')
        else
            GLEntry.SetFilter(Amount, '<0');
        GLEntry.FindFirst();
        GLEntry.TestField(Amount, ExpectedAmount);
    end;

    local procedure VerifyVATEntryAmount(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; PositiveAmount: Boolean; ExpectedAmount: Decimal)
    var
        VATEntry: Record "VAT Entry";
    begin
#pragma warning disable AA0210
        VATEntry.SetRange("Document Type", DocumentType);
#pragma warning restore AA0210
        VATEntry.SetRange("Document No.", DocumentNo);
        if PositiveAmount then
            VATEntry.SetFilter(Amount, '>0')
        else
            VATEntry.SetFilter(Amount, '<0');
        VATEntry.FindFirst();
        VATEntry.TestField(Amount, ExpectedAmount);
    end;

    local procedure VerifyValueEntry(DocumentNo: Code[20]; Amount: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        ValueEntry: Record "Value Entry";
        PurchaseAmount: Decimal;
    begin
        GeneralLedgerSetup.Get();
        ValueEntry.SetRange("Document No.", DocumentNo);
        ValueEntry.FindSet();
        repeat
            PurchaseAmount += ValueEntry."Purchase Amount (Actual)";
        until ValueEntry.Next() = 0;
        Assert.AreNearlyEqual(
          Amount, PurchaseAmount, GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(AmountErr, ValueEntry.FieldCaption("Purchase Amount (Actual)"), ValueEntry.TableCaption()));
    end;

    local procedure VerifyValueEntryAreNonInventoriable(DocumentNo: Code[20])
    var
        DummyValueEntry: Record "Value Entry";
    begin
        DummyValueEntry.SetRange("Document No.", DocumentNo);
        DummyValueEntry.SetRange(Inventoriable, true);
        Assert.RecordIsEmpty(DummyValueEntry);
    end;

    local procedure VerifyVATEntry(DocumentNo: Code[20]; Amount: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        VATEntry: Record "VAT Entry";
    begin
        GeneralLedgerSetup.Get();
        VATEntry.SetRange("Document No.", DocumentNo);
#pragma warning disable AA0210
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::Invoice);
#pragma warning restore AA0210
        VATEntry.FindFirst();
        Assert.AreNearlyEqual(
          Amount, VATEntry.Base + VATEntry.Amount, GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(AmountErr, VATEntry.FieldCaption(Amount), VATEntry.TableCaption()));
    end;

    local procedure VerifyVendorLedgerEntry(DocumentNo: Code[20]; Amount: Decimal)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        VendorLedgerEntry.SetRange("Document No.", DocumentNo);
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Invoice);
        VendorLedgerEntry.FindFirst();
        VendorLedgerEntry.CalcFields("Amount (LCY)");
        Assert.AreNearlyEqual(
          -Amount, VendorLedgerEntry."Amount (LCY)", GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(AmountErr, VendorLedgerEntry.FieldCaption("Amount (LCY)"), VendorLedgerEntry.TableCaption()));
    end;

    local procedure VerifyInvoiceDiscountAmount(PurchaseLine: Record "Purchase Line"; DocumentNo: Code[20]; InvoiceDiscountAmount: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        GLEntry: Record "G/L Entry";
    begin
        GeneralLedgerSetup.Get();
        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GeneralPostingSetup."Purch. Inv. Disc. Account");
        GLEntry.FindFirst();
        Assert.AreNearlyEqual(
          -InvoiceDiscountAmount, GLEntry.Amount, GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(AmountErr, GLEntry.FieldCaption(Amount), GLEntry.TableCaption()));
        Assert.AreNearlyEqual(
          InvoiceDiscountAmount, PurchaseLine."Inv. Discount Amount", GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(AmountErr, PurchaseLine.FieldCaption("Inv. Discount Amount"), PurchaseLine.TableCaption()));
    end;

    local procedure VerifyLineDiscountAmount(PurchaseLine: Record "Purchase Line"; DocumentNo: Code[20]; LineDiscountAmount: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        GLEntry: Record "G/L Entry";
    begin
        GeneralLedgerSetup.Get();
        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GeneralPostingSetup."Purch. Line Disc. Account");
        GLEntry.FindFirst();
        Assert.AreNearlyEqual(
          -LineDiscountAmount, GLEntry.Amount, GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(AmountErr, GLEntry.FieldCaption(Amount), GLEntry.TableCaption()));
        Assert.AreNearlyEqual(
          LineDiscountAmount, PurchaseLine."Line Discount Amount", GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(AmountErr, PurchaseLine.FieldCaption("Line Discount Amount"), PurchaseLine.TableCaption()));
    end;

    local procedure VerifyPurchRcptLine(PurchaseLine: Record "Purchase Line"; DocumentNo: Code[20])
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        PurchRcptLine.SetRange("Document No.", DocumentNo);
        PurchRcptLine.FindFirst();
        PurchRcptLine.TestField("No.", PurchaseLine."No.");
        PurchRcptLine.TestField(Quantity, PurchaseLine.Quantity);
    end;

    local procedure VerifyPurchInvLine(PurchaseLine: Record "Purchase Line"; PostedInvoiceNo: Code[20])
    var
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        PurchInvLine.SetRange("Document No.", PostedInvoiceNo);
        PurchInvLine.FindFirst();
        PurchInvLine.TestField("No.", PurchaseLine."No.");
        PurchInvLine.TestField(Quantity, PurchaseLine.Quantity);
    end;

    local procedure VerifyVATEntryBase(DocumentNo: Code[20]; Amount: Decimal)
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document No.", DocumentNo);
#pragma warning disable AA0210
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::Invoice);
#pragma warning restore AA0210
        VATEntry.FindFirst();
        Assert.AreNearlyEqual(
          Amount, VATEntry.Base + VATEntry."Unrealized Base", LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountErr, VATEntry.FieldCaption(Amount), VATEntry.TableCaption()));
    end;

    local procedure VerifyDueDateOnPurchaseDocumentHeader(PurchaseHeader: Record "Purchase Header"; DueDateCalculation: DateFormula)
    var
        PurchaseHeader2: Record "Purchase Header";
    begin
        PurchaseHeader2.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseHeader2.SetRange("No.", PurchaseHeader."No.");
        PurchaseHeader2.FindFirst();
        PurchaseHeader2.TestField("Due Date", CalcDate(DueDateCalculation, PurchaseHeader."Document Date"));
    end;

    local procedure VerifyLineDiscAmountInLine(var PurchHeader: Record "Purchase Header"; ExpectedLineDiscAmt: Decimal)
    var
        PurchLine: Record "Purchase Line";
    begin
        FindPurchaseLine(PurchLine, PurchHeader."Document Type", PurchHeader."No.");
        Assert.AreEqual(
          ExpectedLineDiscAmt, PurchLine."Line Discount Amount",
          StrSubstNo(AmountErr, PurchLine.FieldCaption("Line Discount Amount"), PurchLine."Line Discount Amount"));
    end;

    local procedure PurchDocLineQtyValidation()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Location: Record Location;
        Item: Record Item;
        PurchaseInvoice: TestPage "Purchase Invoice";
        VendorNo: Code[20];
        i: Integer;
    begin
        // SETUP:
        LibraryWarehouse.CreateFullWMSLocation(Location, 3);
        PurchaseHeader.Init();
        PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::Invoice;
        PurchaseHeader.Status := PurchaseHeader.Status::Open;
        VendorNo := LibraryPurchase.CreateVendorNo();
        PurchaseHeader.Validate("Buy-from Vendor No.", VendorNo);
        i := 0;
        repeat
            i += 1;
            PurchaseHeader."No." := 'TEST' + Format(i);
        until PurchaseHeader.Insert();
        PurchaseLine.Init();
        PurchaseLine."Document Type" := PurchaseLine."Document Type"::Invoice;
        PurchaseLine."Document No." := PurchaseHeader."No.";
        PurchaseLine."Line No." := 10000;
        PurchaseLine.Type := PurchaseLine.Type::Item;
        LibraryInventory.CreateItem(Item);
        PurchaseLine."No." := Item."No.";
        PurchaseLine."Location Code" := Location.Code;
        PurchaseLine."Pay-to Vendor No." := VendorNo;
        PurchaseLine.Insert();
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GotoRecord(PurchaseHeader);
        // EXECUTE:
        PurchaseInvoice.PurchLines.Quantity.SetValue(100);
        // VERIFY: In the test method
    end;

    local procedure CreateJobAndJobTaskWithDimensions(var JobNo: Code[20]; var JobTaskNo: Code[20])
    var
        Job: Record Job;
    begin
        JobNo := CreateJobWithDimension(Job);
        JobTaskNo := CreateJobTaskWithDimension(Job);
    end;

    local procedure InsertJobTaskDim(var JobTaskDim: Record "Job Task Dimension"; JobTask: Record "Job Task"; DimValue: Record "Dimension Value")
    begin
        JobTaskDim.Init();
        JobTaskDim.Validate("Job No.", JobTask."Job No.");
        JobTaskDim.Validate("Job Task No.", JobTask."Job Task No.");
        JobTaskDim.Validate("Dimension Code", DimValue."Dimension Code");
        JobTaskDim.Validate("Dimension Value Code", DimValue.Code);
        JobTaskDim.Insert(true);
    end;

    local procedure CreateJobWithDimension(var Job: Record Job): Code[20]
    var
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
    begin
        LibraryJob.CreateJob(Job);
        LibraryDimension.CreateDimensionValue(DimensionValue, LibraryERM.GetGlobalDimensionCode(1));
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, DATABASE::Job, Job."No.", DimensionValue."Dimension Code", DimensionValue.Code);
        exit(Job."No.");
    end;

    local procedure CreatePurchaseInvoiceWithJob(var PurchaseLine: Record "Purchase Line"; JobNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, CreateVendor(''));
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(), LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Job No.", JobNo);
        PurchaseLine.Modify(true);
    end;

    local procedure VerifyPurchaseLineDimensions(PurchaseLine: Record "Purchase Line"; JobNo: Code[20]; JobTaskNo: Code[20])
    var
        DimensionSetEntry: Record "Dimension Set Entry";
        JobTaskDimension: Record "Job Task Dimension";
    begin
        FindJobTaskDimension(JobTaskDimension, JobNo, JobTaskNo);
        repeat
            DimensionSetEntry.SetRange("Dimension Set ID", PurchaseLine."Dimension Set ID");
            DimensionSetEntry.SetRange("Dimension Code", JobTaskDimension."Dimension Code");
            DimensionSetEntry.SetRange("Dimension Value Code", JobTaskDimension."Dimension Value Code");
            Assert.RecordIsNotEmpty(DimensionSetEntry);
        until JobTaskDimension.Next() = 0;

        JobTaskDimension.SetRange("Dimension Code", LibraryERM.GetGlobalDimensionCode(1));
        FindJobTaskDimension(JobTaskDimension, JobNo, JobTaskNo);
        Assert.AreEqual(
          JobTaskDimension."Dimension Value Code", PurchaseLine."Shortcut Dimension 1 Code",
          PurchaseLine.FieldCaption("Shortcut Dimension 1 Code"));

        JobTaskDimension.SetRange("Dimension Code", LibraryERM.GetGlobalDimensionCode(2));
        FindJobTaskDimension(JobTaskDimension, JobNo, JobTaskNo);
        Assert.AreEqual(
          JobTaskDimension."Dimension Value Code", PurchaseLine."Shortcut Dimension 2 Code",
          PurchaseLine.FieldCaption("Shortcut Dimension 2 Code"));
    end;

    local procedure CreateJobTaskWithDimension(Job: Record Job): Code[20]
    var
        JobTask: Record "Job Task";
        DimensionValue: Record "Dimension Value";
        JobTaskDimension: Record "Job Task Dimension";
    begin
        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryDimension.CreateDimensionValue(DimensionValue, LibraryERM.GetGlobalDimensionCode(2));
        InsertJobTaskDim(JobTaskDimension, JobTask, DimensionValue);
        exit(JobTask."Job Task No.");
    end;

    local procedure FindJobTaskDimension(var JobTaskDimension: Record "Job Task Dimension"; JobNo: Code[20]; JobTaskNo: Code[20])
    begin
        JobTaskDimension.SetRange("Job No.", JobNo);
        JobTaskDimension.SetRange("Job Task No.", JobTaskNo);
        JobTaskDimension.FindSet();
    end;

    local procedure LineDiscInInvWithDiffPricesInclVATThenSourceOrder(PurchHeader: Record "Purchase Header"; var InvoicePurchaseHeader: Record "Purchase Header"; InvPricesInclVAT: Boolean)
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchGetReceipt: Codeunit "Purch.-Get Receipt";
    begin
        CreatePurchDocWithPricesInclVAT(
          InvoicePurchaseHeader, InvoicePurchaseHeader."Document Type"::Invoice, PurchHeader."Buy-from Vendor No.", InvPricesInclVAT);
        FindRcptLine(PurchRcptLine, PurchHeader."No.");
        PurchGetReceipt.SetPurchHeader(InvoicePurchaseHeader);
        PurchGetReceipt.CreateInvLines(PurchRcptLine);
    end;

    local procedure CreatePurchaseLineWithGLAccount(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; VATPostingSetup: Record "VAT Posting Setup")
    begin
        LibraryPurchase.CreatePurchaseLineSimple(PurchaseLine, PurchaseHeader);
        PurchaseLine.Validate(Type, PurchaseLine.Type::"G/L Account");
        PurchaseLine.Validate("No.", VATPostingSetup.GetPurchAccount(false));
        PurchaseLine.Validate(Quantity, LibraryRandom.RandInt(10));
        PurchaseLine.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        PurchaseLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        PurchaseLine.Modify(true);
    end;

    local procedure CreateGLAccount(var GLAccount: Record "G/L Account")
    var
        DeffaralVariant: Variant;
    begin
        LibraryVariableStorage.Dequeue(DeffaralVariant);
        GLAccount.Get(LibraryERM.CreateGLAccountWithPurchSetup());
        GLAccount.Validate("Direct Posting", true);
        GLAccount.Validate("Default Deferral Template Code", DeffaralVariant);
        GLAccount.Modify(true);
    end;

    local procedure CreateDeferralTemplate(): code[10]
    var
        DeferralTemplate: Record "Deferral Template";
    begin
        DeferralTemplate.Init();
        DeferralTemplate."Deferral Code" := LibraryUtility.GenerateRandomCode(DeferralTemplate.FieldNo("Deferral Code"), DATABASE::"Deferral Template");
        DeferralTemplate."Deferral Account" := LibraryERM.CreateGLAccountNo();
        DeferralTemplate."Deferral %" := 100;
        DeferralTemplate."Calc. Method" := DeferralTemplate."Calc. Method"::"Straight-Line";
        DeferralTemplate."Start Date" := DeferralTemplate."Start Date"::"Posting Date";
        DeferralTemplate."No. of Periods" := 3;
        DeferralTemplate.Insert();

        exit(DeferralTemplate."Deferral Code");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnBeforePostUpdateOrderLineModifyTempLine', '', false, false)]
    local procedure OnBeforePostUpdateOrderLineModifyTempLineHandler(var TempPurchaseLine: Record "Purchase Line" temporary; WhseShip: Boolean; WhseReceive: Boolean; CommitIsSuppressed: Boolean; PurchHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.Get(TempPurchaseLine.RecordId);
        PurchaseLine."Description 2" := 'x';
        PurchaseLine.Modify();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GetReceiptLinesPageHandler(var GetReceiptLines: TestPage "Get Receipt Lines")
    begin
        GetReceiptLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure QuantityOnGetReceiptLinesPageHandler(var GetReceiptLines: TestPage "Get Receipt Lines")
    var
        QtyToReceive: Variant;
    begin
        // Verification for both lines filtering in the Get Receipt Lines page which is partially posted Purchase Order for same vendor.
        LibraryVariableStorage.Dequeue(QtyToReceive);
        FilterQuantityOnGetReceiptLines(GetReceiptLines, CopyStr(LibraryVariableStorage.DequeueText(), 1, 20), QtyToReceive);
        FilterQuantityOnGetReceiptLines(GetReceiptLines, CopyStr(LibraryVariableStorage.DequeueText(), 1, 20), QtyToReceive);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure QuantityFilterUsingGetReceiptLinesPageHandler(var GetReceiptLines: TestPage "Get Receipt Lines")
    var
        QtyToReceive: Variant;
    begin
        // Verification for filter in the Get Receipt Lines page according to Quantity.
        LibraryVariableStorage.Dequeue(QtyToReceive);
        FilterQuantityOnGetReceiptLines(GetReceiptLines, CopyStr(LibraryVariableStorage.DequeueText(), 1, 20), QtyToReceive);
    end;



    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure InvokeGetReceiptLinesPageHandler(var GetReceiptLines: TestPage "Get Receipt Lines")
    var
        QtyToReceive: Variant;
    begin
        LibraryVariableStorage.Dequeue(QtyToReceive);
        FilterQuantityOnGetReceiptLines(GetReceiptLines, CopyStr(LibraryVariableStorage.DequeueText(), 1, 20), QtyToReceive);
        GetReceiptLines.OK().Invoke();
    end;

    local procedure CheckEverythingIsReverted(Item: Record Item; Vendor: Record Vendor; LastGLEntry: Record "G/L Entry")
    var
        VendorPostingGroup: Record "Vendor Posting Group";
        GLEntry: Record "G/L Entry";
        ValueEntry: Record "Value Entry";
        TotalDebit: Decimal;
        TotalCredit: Decimal;
        TotalCost: Decimal;
        TotalQty: Decimal;
    begin
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');
        ValueEntry.SetRange("Source Type", ValueEntry."Source Type"::Vendor);
        ValueEntry.SetRange("Source No.", Vendor."No.");
        ValueEntry.FindSet();
        repeat
            TotalQty += ValueEntry."Item Ledger Entry Quantity";
            TotalCost += ValueEntry."Cost Amount (Actual)";
        until ValueEntry.Next() = 0;
        Assert.AreEqual(0, TotalQty, '');
        Assert.AreEqual(0, TotalCost, '');

        // Vendor balance should go back to zero
        Vendor.CalcFields(Balance);
        Assert.AreEqual(0, Vendor.Balance, '');

        VendorPostingGroup.Get(Vendor."Vendor Posting Group");
        GLEntry.SetFilter("Entry No.", '>%1', LastGLEntry."Entry No.");
        GLEntry.FindSet();
        repeat
            TotalDebit += GLEntry."Credit Amount";
            TotalCredit += GLEntry."Debit Amount";
        until GLEntry.Next() = 0;

        Assert.AreEqual(TotalDebit, TotalCredit, '');
    end;

    local procedure CreateMultipleVATPostingSetup(var VATPostingSetup: array[2] of Record "VAT Posting Setup"; PurchaseHeader: Record "Purchase Header"; TaxCalculationType: Enum "Tax Calculation Type")
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup[1], TaxCalculationType, LibraryRandom.RandIntInRange(15, 35));
        VATPostingSetup[1]."VAT Bus. Posting Group" := PurchaseHeader."VAT Bus. Posting Group";
        VATPostingSetup[1]."Reverse Chrg. VAT Acc." := LibraryERM.CreateGLAccountNo();
        VATPostingSetup[1].Insert();

        LibraryERM.CreateVATPostingSetupWithAccounts(
        VATPostingSetup[2], TaxCalculationType, LibraryRandom.RandIntInRange(10, 15));
        VATPostingSetup[2]."VAT Bus. Posting Group" := PurchaseHeader."VAT Bus. Posting Group";
        VATPostingSetup[2]."Reverse Chrg. VAT Acc." := LibraryERM.CreateGLAccountNo();
        VATPostingSetup[2].Insert();
    end;

    [Normal]
    local procedure CreateGnlJnlLines(var GenJournalLine: Record "Gen. Journal Line"; GLAccountNo: Code[20]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // Create General Journal Lines using newly created GL Account.
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", GLAccountNo, Amount);
    end;

    local procedure VerifySourceCurrencyAmountInGLEntry(VATPostingSetup: Record "VAT Posting Setup")
    var
        GLEntry: Record "G/L Entry";
        DocumentNo: Code[20];
        LineAmount: Decimal;
    begin
        DocumentNo := LibraryVariableStorage.DequeueText();
        LineAmount := LibraryVariableStorage.DequeueDecimal();

        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", VATPostingSetup."Reverse Chrg. VAT Acc.");
        GLEntry.FindFirst();

        Assert.AreEqual(Abs(GLEntry."Source Currency Amount"), (LineAmount * VATPostingSetup."VAT %") / 100, GLEntry.FieldCaption("Source Currency Amount"));
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Message Handler.
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        // Confirm Handler for the Confirmation message and always send reply as TRUE.
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmCopyDocDateOrderHandlerVerify(Question: Text[1024]; var Reply: Boolean)
    var
        ExpectedConfirmText: Text;
    begin
        ExpectedConfirmText := CopyDocDateOrderConfirmMsg;
        Assert.AreEqual(ExpectedConfirmText, Question, WrongConfirmationMsgErr);
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure TemplateSelectionPageHandler(var SelectVendorTemplList: TestPage "Select Vendor Templ. List")
    begin
        SelectVendorTemplList.First();
        SelectVendorTemplList.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure CreateEmptyPostedInvConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Question);
        Reply := false;
    end;

    [Scope('OnPrem')]
    procedure PostItemAndVerifyValueEntries(Item: Record Item; PurchaseLineDiscount: Record "Purchase Line Discount")
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PostedDocumentNo: Code[20];
    begin
        CreatePurchaseHeader(PurchaseHeader, PurchaseLineDiscount."Vendor No.", PurchaseHeader."Document Type"::Invoice);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify Purchase Line and Posted G/L Entry have no cost for the service item.
        VerifyValueEntryAreNonInventoriable(PostedDocumentNo);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VendorLookupHandler(var VendorLookup: TestPage "Vendor Lookup")
    begin
        VendorLookup.GotoKey(LibraryVariableStorage.DequeueText());
        VendorLookup.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VendorLookupSelectVendorPageHandler(var VendorLookup: TestPage "Vendor Lookup")
    begin
        VendorLookup.FILTER.SetFilter("No.", LibraryVariableStorage.DequeueText());
        VendorLookup.OK().Invoke();
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SendNotificationHandler(var Notification: Notification): Boolean
    begin
        LibraryVariableStorage.Enqueue(Notification.Message);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYesNo(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerNo(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseDocumentTestRequestPageHandler(var PurchaseDocumentTest: TestRequestPage "Purchase Document - Test")
    begin
        // Close handler
    end;
}
