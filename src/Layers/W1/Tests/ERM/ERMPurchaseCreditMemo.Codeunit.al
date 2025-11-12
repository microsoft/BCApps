codeunit 134330 "ERM Purchase Credit Memo"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Credit Memo] [Purchase]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryCosting: Codeunit "Library - Costing";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtilityOnPrem: Codeunit "Library - Utility OnPrem";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryRandom: Codeunit "Library - Random";
        CopyFromToPriceListLine: Codeunit CopyFromToPriceListLine;
        LibraryNonDeductibleVAT: Codeunit "Library - NonDeductible VAT";
        DocumentNo2: Code[20];
        IsInitialized: Boolean;
        FieldErr: Label '%1 must be equal in %2.', Comment = '%1 = Field Name, %2 = Table Name';
        LineErr: Label 'Number of lines for %1 and %2 must be equal.', Comment = '%1 = Table Name, %2 = Table Name';
        VATAmountErr: Label 'VAT Amount must be %1 in %2.', Comment = '%1 = Amount, %2 = Table Name';
        CommonErr: Label '%1 in %2 must be same as %3.', Comment = '%1 = Field Name, %2 = Table Name, %3 = Table Name';
        CurrencyChangeErr: Label 'If you change %1, the existing purchase lines will be deleted and new purchase lines based on the new information in the header will be created.\\Do you want to continue?', Comment = '%1 = Currency Code';
        ChangeQuantitySignErr: Label 'Qty. to Invoice must have the same sign as the return shipment in Purchase Line Document Type=''Credit Memo'',Document No.=''%1'',Line No.=''%2''.', Comment = '%1 = Document No., %2 = Line No.';
        ChangeRetQtyToShipErr: Label 'You cannot return more than %1 units.', Comment = '%1 = Quantity';
        ChangeQuantityErr: Label 'The quantity that you are trying to invoice is greater than the quantity in return shipment %1.', Comment = '%1 = Document No.';
        WhseShipmentIsRequiredErr: Label 'Warehouse Shipment is required for Line No.';
        WrongErrorReturnedErr: Label 'Wrong error returned: %1.', Comment = '%1 = Error Text';
        ContactShouldNotBeEditableErr: Label 'Contact should not be editable when vendor is not selected.';
        ContactShouldBeEditableErr: Label 'Contact should be editable when vendorr is selected.';
        NonDeducVATEntryMustExistMsgLbl: Label 'VAT Entry must have Non-Deductible VAT amount';
        FieldErrDetLbl: Label '%1 must be equal to %2 in %3.', Comment = '%1 = Field Name,  %2 = Expected Value, %3 = Table Name';
        PostedDocType: Option PostedReturnShipments,PostedInvoices;

    [Test]
    [Scope('OnPrem')]
    procedure CopyPurchaseDocumentWithDiffCurrency()
    var
        PurchaseHeader: Record "Purchase Header";
        NewPurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PostedInvoiceNo: Code[20];
    begin
        // Check error message in case of copy document with different Currency Code and LineType <> Item
        Initialize();

        // Create And Post Purchase Invoice
        CreatePurchaseHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice,
          LibraryPurchase.CreateVendorNo());
        CreatePurchaseInvoiceLine(
          PurchaseHeader, PurchaseLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithPurchSetup());
        PostedInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Create New Purchase Credit Memo with Currency
        CreatePurchCrMemoWithCurrency(NewPurchaseHeader);

        // Use CopyDocument for new Credit Memo
        asserterror CreditMemoWithCopyDocument(NewPurchaseHeader, "Purchase Document Type From"::"Posted Invoice", PostedInvoiceNo, false, true);
        Assert.ExpectedTestFieldError(PurchaseHeader.FieldCaption("Currency Code"), PurchaseHeader."Currency Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemoCreation()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Covers Document TFS_TC_ID 122458.
        // Test New Purchase Credit Memo creation.

        // Setup.
        Initialize();

        // Exercise: Create Purchase Credit Memo.
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", LibraryPurchase.CreateVendorNo());
        CreatePurchaseLine(PurchaseLine, PurchaseHeader);

        // Verify: Verify Purchase Credit Memo created.
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATAmountOnPurchaseCreditMemo()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATAmountLine: Record "VAT Amount Line";
        QtyType: Option General,Invoicing,Shipping;
    begin
        // Covers Document TFS_TC_ID 122459.
        // Create a Purchase Credit Memo and verify that correct VAT Amount calculated for Purchase Credit Memo.

        // Setup.
        Initialize();

        // Exercise: Create Purchase Credit Memo and calculate VAT Amount for Purchase Lines.
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", LibraryPurchase.CreateVendorNo());
        CreatePurchaseLine(PurchaseLine, PurchaseHeader);
        PurchaseLine.CalcVATAmountLines(QtyType::Invoicing, PurchaseHeader, PurchaseLine, VATAmountLine);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        PurchaseHeader.CalcFields(Amount);

        // Verify: Verify VAT Amount on Purchase Credit Memo.
        GeneralLedgerSetup.Get();
        Assert.AreNearlyEqual(
          PurchaseHeader.Amount * PurchaseLine."VAT %" / 100, VATAmountLine."VAT Amount", GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(VATAmountErr, PurchaseHeader.Amount * PurchaseLine."VAT %" / 100, VATAmountLine.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemoReport()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseDocumentTest: Report "Purchase Document - Test";
        FilePath: Text[1024];
    begin
        // Covers Document TFS_TC_ID 122460.
        // Create a Purchase Credit Memo and save it as external file and verify that saved files has some data.

        // Setup.
        Initialize();
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", LibraryPurchase.CreateVendorNo());
        CreatePurchaseLine(PurchaseLine, PurchaseHeader);

        // Exercise: Generate Report as external file for Purchase Credit Memo.
        Clear(PurchaseDocumentTest);
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::"Credit Memo");
        PurchaseHeader.SetRange("No.", PurchaseHeader."No.");
        PurchaseDocumentTest.SetTableView(PurchaseHeader);
        FilePath := TemporaryPath + Format(PurchaseHeader."Document Type") + PurchaseHeader."No." + '.xlsx';
        PurchaseDocumentTest.SaveAsExcel(FilePath);

        // Verify: Verify that saved files have some data.
        LibraryUtilityOnPrem.CheckFileNotEmpty(FilePath);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchaseCreditMemoReport()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchaseCreditMemo: Report "Purchase - Credit Memo";
        FilePath: Text[1024];
        PostedCreditMemoNo: Code[20];
    begin
        // Covers Document TFS_TC_ID 122461, 122463.
        // Create a Purchase Credit Memo and Post it. Generate Posted Purchase Credit Memo Report and verify that it contains some data.

        // Setup.
        Initialize();
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", LibraryPurchase.CreateVendorNo());
        CreatePurchaseLine(PurchaseLine, PurchaseHeader);
        PostedCreditMemoNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Exercise: Generate Report as external file for Posted Purchase Credit Memo.
        Clear(PurchaseCreditMemo);
        PurchCrMemoHdr.SetRange("No.", PostedCreditMemoNo);
        PurchaseCreditMemo.SetTableView(PurchCrMemoHdr);
        FilePath := TemporaryPath + Format('Purchase - Credit Memo') + PurchCrMemoHdr."No." + '.xlsx';
        PurchaseCreditMemo.SaveAsExcel(FilePath);

        // Verify: Verify that Saved files have some data.
        LibraryUtilityOnPrem.CheckFileNotEmpty(FilePath);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseCreditMemo()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        ReturnShipmentLine: Record "Return Shipment Line";
        PostedCreditMemoNo: Code[20];
        PostedReturnShipmentNo: Code[20];
        Counter: Integer;
        AmountInclVAT: Decimal;
    begin
        // Covers Document TFS_TC_ID 122462, 122464, 122465, 122466, 122467.
        // Create and Post Purchase Credit Memo and verify Posted Return Shipment Lines,Vendor Ledger Entry, GL Entry, VAT Entry and
        // Value Entries.

        // Setup:
        Initialize();

        // Exercise: Create and Post Purchase Credit Memo with multiple lines.
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", LibraryPurchase.CreateVendorNo());
        for Counter := 1 to 1 + LibraryRandom.RandInt(10) do
            CreatePurchaseLine(PurchaseLine, PurchaseHeader);
        PostedReturnShipmentNo := GetNextReturnShipmentNo(PurchaseHeader."Return Shipment No. Series");
        PostedCreditMemoNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify Posted Return Shipment Lines, GL Entries, Vendor Ledger Entries, VAT Entries and Value Entries.
        ReturnShipmentLine.SetRange("Document No.", PostedReturnShipmentNo);
        Assert.AreEqual(
          Counter, ReturnShipmentLine.Count, StrSubstNo(LineErr, PurchaseLine.TableCaption(), ReturnShipmentLine.TableCaption()));
        PurchCrMemoHdr.Get(PostedCreditMemoNo);
        PurchCrMemoHdr.CalcFields(Amount);
        VATPostingSetup.Get(PurchaseLine."VAT Bus. Posting Group", PurchaseLine."VAT Prod. Posting Group");
        AmountInclVAT := Round(PurchCrMemoHdr.Amount * (1 + VATPostingSetup."VAT %" / 100));

        VerifyGLEntry(PostedCreditMemoNo, AmountInclVAT);
        VerifyVendorLedgerEntry(PostedCreditMemoNo, AmountInclVAT);
        VerifyVATEntry(PostedCreditMemoNo, AmountInclVAT);
        VerifyValueEntry(PostedCreditMemoNo, PurchCrMemoHdr.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocationOnPurchaseCreditMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Location: Record Location;
        ReturnShipmentLine: Record "Return Shipment Line";
        PostedReturnShipmentNo: Code[20];
        RequireShipment: Boolean;
    begin
        // Covers Document TFS_TC_ID 122468, 122469.
        // Create a Purchase Credit Memo with Location and Post it, verify Location on Return Shipment Line.

        // Setup: Update Warehouse Location to Enable Require Shipment.
        Initialize();
        Location.SetRange("Bin Mandatory", false);
        Location.SetRange("Use As In-Transit", false);
        Location.FindFirst();
        RequireShipment := Location."Require Shipment";  // Store the original state of Require Shipment Field.
        Location.Validate("Require Shipment", true);
        Location.Modify(true);

        // Exercise: Create Purchase Credit Memo with Location and Post it.
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", LibraryPurchase.CreateVendorNo());
        CreatePurchaseLine(PurchaseLine, PurchaseHeader);
        PurchaseLine.Validate("Location Code", Location.Code);
        PurchaseLine.Modify(true);
        PostedReturnShipmentNo := GetNextReturnShipmentNo(PurchaseHeader."Return Shipment No. Series");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify Location on Return Shipment Line.
        ReturnShipmentLine.SetRange("Document No.", PostedReturnShipmentNo);
        ReturnShipmentLine.FindFirst();
        Assert.AreEqual(
          PurchaseLine."Location Code", ReturnShipmentLine."Location Code",
          StrSubstNo(
            CommonErr, ReturnShipmentLine.FieldCaption("Location Code"), ReturnShipmentLine.TableCaption(), PurchaseLine.TableCaption()));

        // Tear Down: Cleanup of Warehouse Location Setup Done.
        Location.Validate("Require Shipment", RequireShipment);  // Restore previous state of Location.
        Location.Modify(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LineDiscountPurchaseCreditMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLineDiscount: Record "Purchase Line Discount";
        PriceListLine: Record "Price List Line";
        PostedDocumentNo: Code[20];
    begin
        // Covers Document TFS_TC_ID 122470, 122471.
        // Create Purchase Credit Memo with Line Discount and Verify the Amount in GL Entry.

        // Setup: Create Line Discount Setup.
        Initialize();
        SetupLineDiscount(PurchaseLineDiscount);
        CopyFromToPriceListLine.CopyFrom(PurchaseLineDiscount, PriceListLine);

        // Exercise: Create and Post Purchase Credit Memo. Take Quantity greater than Purchase Line Discount Min. Quantity.
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", PurchaseLineDiscount."Vendor No.");
        CreatePurchaseLine(PurchaseLine, PurchaseHeader);

        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, PurchaseLineDiscount."Item No.",
          PurchaseLineDiscount."Minimum Quantity" + LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Qty. to Receive", 0);  // Qty. to Receive must be 0 for Purchase Credit Memo.
        PurchaseLine.Modify(true);

        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify the Line Discount Amount for Purchase Credit Memo in GL Entry.
        VerifyLineDiscountAmount(
          PurchaseLine, PostedDocumentNo,
          (PurchaseLine.Quantity * PurchaseLine."Direct Unit Cost") * PurchaseLineDiscount."Line Discount %" / 100);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvDiscountPurchaseCreditMemo()
    var
        VendorInvoiceDisc: Record "Vendor Invoice Disc.";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PostedDocumentNo: Code[20];
    begin
        // Covers Document TFS_TC_ID 122472, 122473.
        // Create Purchase Credit Memo with Invoice Discount, Post it and verify Posted GL Entry.

        // Setup: Create Invoice Discount Setup.
        Initialize();
        SetupInvoiceDiscount(VendorInvoiceDisc);

        // Exercise: Create Purchase Credit Memo, calculate Invoice Discount and Post the Credit Memo.
        // Take Direct Unit Cost equal to Minimum Amount so that the Total Amount always greater than Minimum Amount.
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", VendorInvoiceDisc.Code);
        CreatePurchaseLine(PurchaseLine, PurchaseHeader);
        PurchaseLine.Validate("Direct Unit Cost", VendorInvoiceDisc."Minimum Amount");
        PurchaseLine.Modify(true);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
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
    procedure PurchaseCreditMemoWithFCY()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReturnShipmentHeader: Record "Return Shipment Header";
        PostedDocumentNo: Code[20];
    begin
        // Covers Document TFS_TC_ID 122474, 122475.
        // Create and Post a Purchase Credit Memo with Currency and verify currency on Return Shipment.

        // Setup.
        Initialize();

        // Exercise: Create Purchase Credit Memo with new Currency and Post it.
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", LibraryPurchase.CreateVendorNo());
        PurchaseHeader.Validate("Currency Code", CreateCurrency());
        PurchaseHeader.Modify(true);
        CreatePurchaseLine(PurchaseLine, PurchaseHeader);
        PostedDocumentNo := GetNextReturnShipmentNo(PurchaseHeader."Return Shipment No. Series");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify Currency Code in Purchase Line and Posted Purchase Return Shipment Header.
        ReturnShipmentHeader.Get(PostedDocumentNo);
        Assert.AreEqual(
          PurchaseHeader."Currency Code", PurchaseLine."Currency Code",
          StrSubstNo(FieldErr, PurchaseLine.FieldCaption("Currency Code"), PurchaseLine.TableCaption()));
        Assert.AreEqual(
          PurchaseHeader."Currency Code", ReturnShipmentHeader."Currency Code",
          StrSubstNo(FieldErr, ReturnShipmentHeader.FieldCaption("Currency Code"), ReturnShipmentHeader.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyPurchaseDocument()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        PurchaseOrderNo: Code[20];
    begin
        // Covers Document TFS_TC_ID 122476.
        // Create Purchase Order. Perform Copy Document on Purchase Credit Memo and Verify the data in Purchase Credit Memo.

        // Setup: Create a Purchase Order.
        Initialize();
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        CreatePurchaseLine(PurchaseLine, PurchaseHeader);
        PurchaseOrderNo := PurchaseHeader."No.";

        // Exercise: Create Purchase Credit Memo Header and copy the Purchase Order to Purchase Credit Memo.
        PurchaseHeader.Init();
        PurchaseHeader.Validate("Document Type", PurchaseHeader."Document Type"::"Credit Memo");
        PurchaseHeader.Insert(true);

        CreditMemoWithCopyDocument(PurchaseHeader, "Purchase Document Type From"::Order, PurchaseOrderNo, true, false);

        // Verify: Verify that Correct Item No. and Quantity copied from Purchase Order to Purchase Credit Memo Line.
        PurchaseLine2.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine2.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine2.FindFirst();
        Assert.AreEqual(
          PurchaseLine."No.", PurchaseLine2."No.", StrSubstNo(FieldErr, PurchaseLine.FieldCaption("No."), PurchaseLine.TableCaption()));
        Assert.AreEqual(
          PurchaseLine.Quantity, PurchaseLine2.Quantity,
          StrSubstNo(FieldErr, PurchaseLine.FieldCaption(Quantity), PurchaseLine.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemoApplication()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader2: Record "Purchase Header";
        PurchaseLine2: Record "Purchase Line";
        ReturnShipmentHeader: Record "Return Shipment Header";
        PostedPurchaseInvoiceNo: Code[20];
        PostedReturnShipmentNo: Code[20];
    begin
        // Covers Document TFS_TC_ID 122477.
        // Check if Credit Memo can be applied against Purchase Invoice.

        // Setup: Create a Purchase Invoice and Post it. Store Posted Invoice No. in a variable.
        Initialize();
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        CreatePurchaseLine(PurchaseLine, PurchaseHeader);
        PostedPurchaseInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Exercise: Create Purchase Credit Memo with the same Vendor used in Purchase Invoice, Update Applies to Document Type
        // and Document No. fields and Post Purchase Credit Memo.
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader2, PurchaseHeader2."Document Type"::"Credit Memo", PurchaseHeader."Buy-from Vendor No.");
        PurchaseHeader2.Validate("Vendor Cr. Memo No.", PurchaseHeader2."No.");
        PurchaseHeader2.Validate("Applies-to Doc. Type", PurchaseHeader2."Applies-to Doc. Type"::Invoice);
        PurchaseHeader2.Validate("Applies-to Doc. No.", PostedPurchaseInvoiceNo);
        PurchaseHeader2.Modify(true);

        CreatePurchaseLine(PurchaseLine2, PurchaseHeader2);
        PostedReturnShipmentNo := GetNextReturnShipmentNo(PurchaseHeader2."Return Shipment No. Series");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader2, true, true);

        // Verify: Verify the Applies to Doc Type and Applies to Doc No. in Return Shipment Header.
        ReturnShipmentHeader.Get(PostedReturnShipmentNo);
        Assert.AreEqual(
          PurchaseHeader."Document Type", ReturnShipmentHeader."Applies-to Doc. Type",
          StrSubstNo(FieldErr, ReturnShipmentHeader.FieldCaption("Applies-to Doc. Type"), ReturnShipmentHeader.TableCaption()));
        Assert.AreEqual(
          PostedPurchaseInvoiceNo, ReturnShipmentHeader."Applies-to Doc. No.",
          StrSubstNo(FieldErr, ReturnShipmentHeader.FieldCaption("Applies-to Doc. No."), ReturnShipmentHeader.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemoContactNotEditableBeforeVendorSelected()
    var
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        // [FEATURE] [UI]
        // [Scenario] Contact Field on Purchase Credit Memo Page not editable if no vendor selected
        // [Given]
        Initialize();

        // [WHEN] Purchase Credit Memo page is opened
        PurchaseCreditMemo.OpenNew();

        // [THEN] Contact Field is not editable
        Assert.IsFalse(PurchaseCreditMemo."Buy-from Contact".Editable(), ContactShouldNotBeEditableErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemoContactEditableAfterVendorSelected()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        // [FEATURE] [UI]
        // [Scenario] Contact Field on Purchase Credit Memo Page  editable if vendor selected
        // [Given]
        Initialize();

        // [Given] A sample Purchase Credit Memo
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", LibraryPurchase.CreateVendorNo());

        // [WHEN] Purchase Credit Memo page is opened
        PurchaseCreditMemo.OpenEdit();
        PurchaseCreditMemo.GotoRecord(PurchaseHeader);

        // [THEN] Contact Field is editable
        Assert.IsTrue(PurchaseCreditMemo."Buy-from Contact".Editable(), ContactShouldBeEditableErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyPurchaseInvoiceAndVerify()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        PostedCreditMemoNo: Code[20];
        PostedPurchaseInvoiceNo: Code[20];
    begin
        // Test Copy Document functionality by creating Purchase Invoice then copy it to Purchase Credit memo and Verify in
        // G/L Entry.

        // Setup: Create G/L Account, Update General Ledger Setup and VAT Posting Setup. Create Purchase Invoice and post.
        Initialize();
        LibraryERM.SetUnrealizedVAT(true);
        FindAndUpdateVATPostingSetup(VATPostingSetup);
        CreatePurchaseInvoiceWithVAT(PurchaseHeader, VATPostingSetup);
        PostedPurchaseInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Exercise: Create Purchase Credit Memo Header, copy the Purchase Invoice to Purchase Credit Memo and post.
        CreatePurchaseHeader(PurchaseHeader2, PurchaseHeader2."Document Type"::"Credit Memo", PurchaseHeader."Buy-from Vendor No.");
        CreditMemoWithCopyDocument(PurchaseHeader2, "Purchase Document Type From"::"Posted Invoice", PostedPurchaseInvoiceNo, false, false);
        GetPurchaseLine(PurchaseLine, PurchaseHeader2."Document Type", PurchaseHeader2."No.");
        PostedCreditMemoNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader2, true, true);

        // Verify: Verify VAT Amount in G/L Entry.
        VerifyVATAmountOnGLEntry(
          PurchaseHeader2."Document Type", PostedCreditMemoNo,
          -GetVATAmountOnGLEntry(PostedPurchaseInvoiceNo, PurchaseHeader."Document Type"));

        // TearDown: Rollback VAT Posting Setup and General Ledger Setup.
        UpdateVATPostingSetup(
          VATPostingSetup, VATPostingSetup."Unrealized VAT Type", VATPostingSetup."Purch. VAT Unreal. Account",
          VATPostingSetup."Reverse Chrg. VAT Unreal. Acc.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipPurchaseReturnOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
    begin
        // Verify Item Ledger Entry after ship the Purchase Return Order.

        // Setup. Create Purchase Return Order.
        Initialize();
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", LibraryPurchase.CreateVendorNo());
        CreatePurchaseLine(PurchaseLine, PurchaseHeader);

        // Exercise: Ship Purchase Return Order.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // Verify: Verify Item Ledger Entry.
        VerifyItemLedgerEntry(DocumentNo, PurchaseLine."No.", -PurchaseLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('GetReturnShipmentHandler')]
    [Scope('OnPrem')]
    procedure DirectCostInclVATOnPurchCrMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        DirectCostInclVAT: Decimal;
    begin
        // Check Direct Cost Incl VAT field in Purchase Credit Memo Line created by using the function Get Return Shipment lines When Price
        // Including VAT is True.

        // Setup. Create Purchase Return Order and create Purchase Credit Memo.
        Initialize();
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", LibraryPurchase.CreateVendorNo());
        CreatePurchaseLine(PurchaseLine, PurchaseHeader);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        CreatePurchaseHeader(PurchaseHeader2, PurchaseHeader2."Document Type"::"Credit Memo", PurchaseHeader."Buy-from Vendor No.");
        PurchaseHeader2.Validate("Prices Including VAT", true);
        PurchaseHeader2.Modify(true);
        PurchaseLine2.Validate("Document Type", PurchaseHeader2."Document Type");
        PurchaseLine2.Validate("Document No.", PurchaseHeader2."No.");
        DirectCostInclVAT := PurchaseLine."Direct Unit Cost" + PurchaseLine."Direct Unit Cost" * PurchaseLine."VAT %" / 100;

        // Exercise.
        CODEUNIT.Run(CODEUNIT::"Purch.-Get Return Shipments", PurchaseLine2);

        // Verify: Verify Unit Price Incl VAT field in Sales Credit Memo Line.
        PurchaseLine2.SetRange("Document Type", PurchaseHeader2."Document Type");
        PurchaseLine2.SetRange("Document No.", PurchaseHeader2."No.");
        PurchaseLine2.SetRange("No.", PurchaseLine."No.");
        PurchaseLine2.FindFirst();
        Assert.AreNearlyEqual(
          DirectCostInclVAT, PurchaseLine2."Direct Unit Cost", LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(FieldErr, PurchaseLine.FieldCaption("Direct Unit Cost"), PurchaseLine.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATAmountOnPurchaseCrMemoUsingCopyDocument()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
        VATAmount: Decimal;
    begin
        // Test VAT Amount on GL Entry after posting Purchase Credit Memo against the Purchase Invoice with Reverse Charge VAT using Copy Document.

        // Setup: Create G/L Account, Purchase Invoice and copy it to Purchase Credit Memo. Update General Ledger Setup, VAT Posting Setup and the Direct Unit Cost on Purchase Line.
        Initialize();
        LibraryERM.SetUnrealizedVAT(true);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
        UpdateVATPostingSetup(
          VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::Percentage, LibraryERM.CreateGLAccountNo(), LibraryERM.CreateGLAccountNo());

        CreatePurchaseInvoiceWithVAT(PurchaseHeader, VATPostingSetup);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        CreatePurchaseHeader(PurchaseHeader2, PurchaseHeader2."Document Type"::"Credit Memo", PurchaseHeader."Buy-from Vendor No.");
        CreditMemoWithCopyDocument(PurchaseHeader2, "Purchase Document Type From"::"Posted Invoice", DocumentNo, false, false);
        GetAndUpdatePurchaseLine(PurchaseLine, PurchaseHeader2."Document Type", PurchaseHeader2."No.");
        VATAmount := Round(Round(PurchaseLine.Quantity * PurchaseLine."Direct Unit Cost") * VATPostingSetup."VAT %" / 100);

        // Exercise: Post Purchase Credit Memo.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader2, true, true);

        // Verify: Verify VAT Amount in G/L Entry.
        VerifyVATAmountOnGLEntry(PurchaseHeader2."Document Type", DocumentNo, -VATAmount);

        // TearDown: Rollback VAT Posting Setup and General Ledger Setup.
        UpdateVATPostingSetup(
          VATPostingSetup, VATPostingSetup."Unrealized VAT Type", VATPostingSetup."Purch. VAT Unreal. Account",
          VATPostingSetup."Reverse Chrg. VAT Unreal. Acc.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATAmountOnPostedPurchaseInvoice()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
        VATAmount: Decimal;
    begin
        // Verify G/L Entry for VAT Amount after posting Purchase Invoice.

        // Setup.
        Initialize();
        CreatePurchaseInvoice(PurchaseHeader);
        GetPurchaseLine(PurchaseLine, PurchaseHeader."Document Type", PurchaseHeader."No.");
        VATPostingSetup.Get(PurchaseLine."VAT Bus. Posting Group", PurchaseLine."VAT Prod. Posting Group");
        VATAmount := Round(Round(PurchaseLine.Quantity * PurchaseLine."Direct Unit Cost") * VATPostingSetup."VAT %" / 100);

        // Exercise: Post Purchase Invoice.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify.
        VerifyVATAmountOnGLEntry(PurchaseHeader."Document Type", DocumentNo, VATAmount);
    end;

    [Test]
    [HandlerFunctions('PostedPurchaseDocumentLinesHandler')]
    [Scope('OnPrem')]
    procedure PostPurchaseCrMemoUsingGetPostedDocLines()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
        VATAmount: Decimal;
    begin
        // Verify G/L Entry for VAT Amount after posting Purchase Credit Memo using Get Posted Document Lines to Reverse against posting of Return Order as Receive.

        // Setup: Update General Ledger Setup, Create Purchase Invoice, Purchase Return Order using Copy Document and post it, Create Purchase Credit Memo using Get Posted Document Lines.
        Initialize();
        LibraryERM.SetVATRoundingType('=');
        CreatePurchaseInvoice(PurchaseHeader);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        CreatePurchaseHeader(PurchaseHeader2, PurchaseHeader2."Document Type"::"Return Order", PurchaseHeader."Buy-from Vendor No.");
        LibraryPurchase.CopyPurchaseDocument(PurchaseHeader2, "Purchase Document Type From"::"Posted Invoice", DocumentNo, false, true);  // Set TRUE for Include Header and FALSE for Recalculate Lines.
        DocumentNo2 := LibraryPurchase.PostPurchaseDocument(PurchaseHeader2, true, false);  // Using global variable DocumentNo2 due to need in verification.
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", PurchaseHeader2."Buy-from Vendor No.");
        GetPostedDocumentLines(PurchaseHeader."No.", PostedDocType::PostedReturnShipments);
        GetPurchaseLine(PurchaseLine, PurchaseHeader."Document Type", PurchaseHeader."No.");
        VATPostingSetup.Get(PurchaseLine."VAT Bus. Posting Group", PurchaseLine."VAT Prod. Posting Group");
        VATAmount := Round(Round(PurchaseLine.Quantity * PurchaseLine."Direct Unit Cost") * VATPostingSetup."VAT %" / 100);

        // Exercise: Post the Purchase Credit Memo.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify VAT Amount on G/L Entry.
        VerifyVATAmountOnGLEntry(PurchaseHeader."Document Type", DocumentNo, -VATAmount);
    end;

    [Test]
    [HandlerFunctions('PostedPurchaseDocumentLinesHandler')]
    [Scope('OnPrem')]
    procedure GetPostedDocumentWithPriceIncludingVAT()
    begin
        // Verify Error while Get Posted Invoice with Price Including VAT to Reverse from Credit Memo without Price Including VAT.
        ErrorOnGetPostedDocumentLineToReverse(true, false);
    end;

    [Test]
    [HandlerFunctions('PostedPurchaseDocumentLinesHandler')]
    [Scope('OnPrem')]
    procedure GetPostedDocumentWithoutPriceIncludingVAT()
    begin
        // Verify Error while Get Posted Invoice without Price Including VAT to Reverse from Credit Memo with Price Including VAT.
        ErrorOnGetPostedDocumentLineToReverse(false, true);
    end;

    local procedure GetNextReturnShipmentNo(ReturnShipmentNoSeries: Code[20]): Code[20]
    var
        NoSeries: Codeunit "No. Series";
    begin
        exit(NoSeries.PeekNextNo(ReturnShipmentNoSeries));
    end;

    local procedure ErrorOnGetPostedDocumentLineToReverse(PricesIncludingVAT: Boolean; PricesIncludingVAT2: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Setup: Create and Post Purchase Invoice, create Purchase Credit Memo.
        Initialize();
        CreateAndPostPurchInvWithPricesInclVAT(PurchaseLine, PricesIncludingVAT);
        CreatePurchDocWithPriceInclVAT(
          PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", PurchaseLine."Buy-from Vendor No.", PricesIncludingVAT2);

        // Exercise.
        asserterror GetPostedDocumentLines(PurchaseHeader."No.", PostedDocType::PostedInvoices);

        // Verify: Verify error while Get Posted Document to Reverse from Credit Memo.
        Assert.ExpectedTestFieldError(PurchaseHeader.FieldCaption("Prices Including VAT"), Format(PurchaseHeader."Prices Including VAT"));
    end;

    [Test]
    [HandlerFunctions('PostedPurchaseDocumentLinesHandler')]
    [Scope('OnPrem')]
    procedure PurchCreditMemoWithtPriceIncludingVAT()
    begin
        // Verify Purchase Credit Memo Line after Get Posted Invoice Line with Price Including VAT to Reverse from Credit Memo.
        CreditMemoFromGetPostedDocumentLine(true, true)
    end;

    [Test]
    [HandlerFunctions('PostedPurchaseDocumentLinesHandler')]
    [Scope('OnPrem')]
    procedure PurchCreditMemoWithoutPriceIncludingVAT()
    begin
        // Verify Purchase Credit Memo Line after Get Posted Invoice Line without Price Including VAT to Reverse from Credit Memo.
        CreditMemoFromGetPostedDocumentLine(false, false)
    end;

    local procedure CreditMemoFromGetPostedDocumentLine(PricesInclVATFirstDoc: Boolean; PricesInclVATSecondDoc: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Setup: Create and Post Purchase Invoice, create Purchase Credit Memo with Price Including VAT.
        Initialize();
        CreateAndPostPurchInvWithPricesInclVAT(PurchaseLine, PricesInclVATFirstDoc);
        CreatePurchDocWithPriceInclVAT(
          PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", PurchaseLine."Buy-from Vendor No.", PricesInclVATSecondDoc);

        // Exercise.
        GetPostedDocumentLines(PurchaseHeader."No.", PostedDocType::PostedInvoices);

        // Verify: Verify Credit Memo Line After Get Posted Document Line to Reverse.
        PurchaseHeader.TestField("Prices Including VAT", PricesInclVATFirstDoc);
        VerifyPurchaseLine(PurchaseHeader, PurchaseLine.Quantity, PurchaseLine."Line Amount");
    end;

    [Test]
    [HandlerFunctions('GetReturnShipmentHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ChangePurchCrMemoHdrInfoError()
    var
        Currency: Record Currency;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
    begin
        // Verify error when change Purchase Credit Memo Header Information, created from Purchase Return Order.

        // Setup: Create and Ship Purchase Return Order. Create Purchase Credit Memo using Get Return Shipment Lines.
        Initialize();
        DocumentNo := CreateAndShipPurchRetOrder(PurchaseHeader);
        CreatePurchCrMemoUsingGetRetShptLines(PurchaseHeader, PurchaseHeader."Buy-from Vendor No.");
        GetPurchaseLine(PurchaseLine, PurchaseHeader."Document Type", PurchaseHeader."No.");
        LibraryVariableStorage.Enqueue(
          StrSubstNo(CurrencyChangeErr, PurchaseHeader.FieldCaption("Currency Code")));  // Enqueue values for ConfirmHandler.
        LibraryERM.FindCurrency(Currency);

        // Exercise.
        asserterror PurchaseHeader.Validate("Currency Code", Currency.Code);
        // Verify: Verify error when change Currency Code on Purchase Credit Memo.
        Assert.ExpectedTestFieldError(PurchaseLine.FieldCaption("Return Shipment No."), '');
    end;

    [Test]
    [HandlerFunctions('GetReturnShipmentHandler')]
    [Scope('OnPrem')]
    procedure DeletePurchRetOrdAfterGetReturnShipmentError()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader2: Record "Purchase Header";
    begin
        // Verify error when delete Purchase Return Order after creating Purchase Credit Memo.

        // Setup: Create and Ship Purchase Return Order. Create Purchase Credit Memo using Get Return Shipment Lines.
        Initialize();
        CreateAndShipPurchRetOrder(PurchaseHeader);
        GetPurchaseLine(PurchaseLine, PurchaseHeader."Document Type", PurchaseHeader."No.");
        CreatePurchCrMemoUsingGetRetShptLines(PurchaseHeader2, PurchaseHeader."Buy-from Vendor No.");

        // Exercise: Delete Purchase Return Order.
        asserterror PurchaseHeader.Delete(true);

        // Verify: Verify error when Purchase Return Order.
        Assert.ExpectedTestFieldError(PurchaseLine.FieldCaption("Return Qty. Shipped Not Invd."), Format(0));
    end;

    [Test]
    [HandlerFunctions('GetReturnShipmentHandler')]
    [Scope('OnPrem')]
    procedure ChangePurchCrMemoLnInfoError()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader2: Record "Purchase Header";
        DocumentNo: Code[20];
    begin
        // Verify error when change Purchase Credit Memo Line Information, created from Purchase Return Order.

        // Setup: Create and Ship Purchase Return Order. Create Purchase Credit Memo using Get Return Shipment Lines.
        Initialize();
        DocumentNo := CreateAndShipPurchRetOrder(PurchaseHeader);
        CreatePurchCrMemoUsingGetRetShptLines(PurchaseHeader2, PurchaseHeader."Buy-from Vendor No.");
        GetPurchaseLine(PurchaseLine, PurchaseHeader2."Document Type", PurchaseHeader2."No.");

        // Exercise.
        asserterror PurchaseLine.Validate(Type, PurchaseLine.Type::"G/L Account");

        // Verify: Verify error when change Line Type on Purchase Credit Memo.
        Assert.ExpectedTestFieldError(PurchaseLine.FieldCaption("Return Shipment No."), '');
    end;

    [Test]
    [HandlerFunctions('GetReturnShipmentHandler')]
    [Scope('OnPrem')]
    procedure ChangePurchCrMemoQtySignError()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader2: Record "Purchase Header";
    begin
        // Verify error when change Sign of Purchase Credit Memo Quantity, created from Purchase Return Order.

        // Setup: Create and Ship Purchase Return Order. Create Purchase Credit Memo using Get Return Shipment Lines.
        Initialize();
        CreateAndShipPurchRetOrder(PurchaseHeader);
        CreatePurchCrMemoUsingGetRetShptLines(PurchaseHeader2, PurchaseHeader."Buy-from Vendor No.");
        GetPurchaseLine(PurchaseLine, PurchaseHeader2."Document Type", PurchaseHeader2."No.");

        // Exercise: Change the Sign of Purchase Line Quantity.
        asserterror PurchaseLine.Validate(Quantity, -PurchaseLine.Quantity);

        // Verify: Verify error when change Sign of Purchase Credit Memo Quantity.
        Assert.ExpectedError(StrSubstNo(ChangeQuantitySignErr, PurchaseLine."Document No.", PurchaseLine."Line No."));
    end;

    [Test]
    [HandlerFunctions('GetReturnShipmentHandler')]
    [Scope('OnPrem')]
    procedure ChangeReturnQtyToShipOnPurchCrMemoError()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader2: Record "Purchase Header";
    begin
        // Verify error when change Return Qty. to Ship on Purchase Credit Memo, created from Purchase Return Order.

        // Setup: Create and Ship Purchase Return Order. Create Purchase Credit Memo using Get Return Shipment Lines.
        Initialize();
        CreateAndShipPurchRetOrder(PurchaseHeader);
        CreatePurchCrMemoUsingGetRetShptLines(PurchaseHeader2, PurchaseHeader."Buy-from Vendor No.");
        GetPurchaseLine(PurchaseLine, PurchaseHeader2."Document Type", PurchaseHeader2."No.");

        // Exercise: Input Return Qty. to Ship more than Purchase Line Quantity.
        asserterror PurchaseLine.Validate("Return Qty. to Ship", PurchaseLine.Quantity + 1);  // Using 1 for adding more than Quantity.

        // Verify: Verify error when change Return Qty. to Ship on Purchase Credit Memo.
        Assert.ExpectedError(StrSubstNo(ChangeRetQtyToShipErr, PurchaseLine.Quantity));
    end;

    [Test]
    [HandlerFunctions('GetReturnShipmentHandler')]
    [Scope('OnPrem')]
    procedure ChangePurchCrMemoQtyError()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader2: Record "Purchase Header";
        DocumentNo: Code[20];
    begin
        // Verify error when change Quantity on Purchase Credit Memo, created from Purchase Return Order.

        // Setup: Create and Ship Purchase Return Order. Create Purchase Credit Memo using Get Return Shipment Lines.
        Initialize();
        DocumentNo := CreateAndShipPurchRetOrder(PurchaseHeader);
        CreatePurchCrMemoUsingGetRetShptLines(PurchaseHeader2, PurchaseHeader."Buy-from Vendor No.");
        GetPurchaseLine(PurchaseLine, PurchaseHeader2."Document Type", PurchaseHeader2."No.");

        // Exercise: Input Quantity more than Purchase Line Quantity.
        asserterror PurchaseLine.Validate(Quantity, PurchaseLine.Quantity + 1);  // Using 1 for adding more than Quantity.

        // Verify: Verify error when change Quantity on Purchase Credit Memo.
        Assert.ExpectedError(StrSubstNo(ChangeQuantityErr, DocumentNo));
    end;

    [Test]
    [HandlerFunctions('GetReturnShipmentHandler')]
    [Scope('OnPrem')]
    procedure ExplBOMOnPurchCrMemoError()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Verify error while applying Explode BOM on Purchase Credit Memo created from Purchase Return Order.

        // Setup: Create and Ship Purchase Return Order. Create Purchase Credit Memo using Get Return Shipment Lines.
        Initialize();
        CreateAndShipPurchRetOrder(PurchaseHeader);
        CreatePurchCrMemoUsingGetRetShptLines(PurchaseHeader2, PurchaseHeader."Buy-from Vendor No.");
        FilterOnPurchaseLine(PurchaseLine, PurchaseHeader2."Document Type", PurchaseHeader2."No.");
        PurchaseLine.FindFirst();

        // Excercise: Apply Explode BOM on Purchase Credit Memo Line.
        asserterror LibraryPurchase.ExplodeBOM(PurchaseLine);

        // Verify: Verify error while applying Explode BOM on Purchase Credit Memo.
        Assert.ExpectedTestFieldError(PurchaseLine.FieldCaption(Type), Format(PurchaseLine.Type::Item));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExtendedTextOnPurchRetOrd()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseReturnOrder: TestPage "Purchase Return Order";
        ItemNo: Code[20];
    begin
        // Verify Extended Text on Purchase Return Order Line with Extended Text Line of Item.

        // Setup: Create Item with extended Text Line. Create Purchase Return Order.
        Initialize();
        ItemNo := CreateItemAndExtendedText();
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, LibraryRandom.RandDec(10, 2));  // Use Random value for Quantity.
        PurchaseReturnOrder.OpenEdit();

        // Exercise: Insert Extended Text in Purchase Line.
        PurchaseReturnOrder.PurchLines."Insert &Ext. Texts".Invoke();

        // Verify: Verify desription of Extended Text of Purchase Return Order Line.
        GetPurchaseLine(PurchaseLine, PurchaseHeader."Document Type", PurchaseHeader."No.");
        PurchaseLine.TestField(Description, ItemNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreatePurchaseCrMemoLineWhiteLocationQtyError()
    begin
        // Unit test
        asserterror PurchDocLineQtyValidation();
        Assert.IsTrue(StrPos(GetLastErrorText, WhseShipmentIsRequiredErr) > 0, StrSubstNo(WrongErrorReturnedErr, GetLastErrorText));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreditMemoLineDiscountRoundingUsingCopyDoc()
    var
        PurchaseHeaderSrc: Record "Purchase Header";
        PurchaseHeaderDst: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
        UnitPrice: Decimal;
        DiscountAmt: Decimal;
    begin
        // [FEATURE] [Line Discount] [Rounding] [Copy Document]
        // [SCENARIO 375821] Line Discount Amount is correctly copied when using Copy Document for Purchase Credit Memo
        Initialize();
        DiscountAmt := 1;
        UnitPrice := 20000000; // = 1 / (0.00001 / 2)

        // [GIVEN] Posted Purchase Invoice with Quantity = 1, "Unit Price" = 20000000, "Line Discount Amount" = 1, "Line Discount %" = 0.00001
        CreatePurchaseInvoice(PurchaseHeaderSrc);
        ModifyPurchaseLine(PurchaseHeaderSrc."Document Type", PurchaseHeaderSrc."No.", 1, UnitPrice, DiscountAmt);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeaderSrc, true, true);

        // [WHEN] Create new Purchase Credit Memo using Copy Document
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeaderDst, PurchaseHeaderDst."Document Type"::"Credit Memo", PurchaseHeaderSrc."Buy-from Vendor No.");
        LibraryPurchase.CopyPurchaseDocument(PurchaseHeaderDst, "Purchase Document Type From"::"Posted Invoice", DocumentNo, true, false);

        // [THEN] Purchase Credit Memo "Line Discount Amount" = 1
        GetPurchaseLine(PurchaseLine, PurchaseHeaderDst."Document Type", PurchaseHeaderDst."No.");
        Assert.AreEqual(DiscountAmt, PurchaseLine."Line Discount Amount", PurchaseLine.FieldCaption("Line Discount Amount"));
    end;

    [Test]
    [HandlerFunctions('PostedPurchaseDocumentLinesHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoLineDiscountRoundingUsingGetPostedDocLines()
    var
        PurchaseHeaderSrc: Record "Purchase Header";
        PurchaseHeaderDst: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        UnitPrice: Decimal;
        DiscountAmt: Decimal;
    begin
        // [FEATURE] [Line Discount] [Rounding] [Get Document Lines to Reverse]
        // [SCENARIO 375821] Line Discount Amount is correctly copied when using Get Posted Document Lines for Purchase Credit Memo
        Initialize();
        DiscountAmt := 1;
        UnitPrice := 20000000; // = 1 / (0.00001 / 2)

        // [GIVEN] Posted Purchase Invoice with Quantity = 1, "Unit Price" = 20000000, "Line Discount Amount" = 1, "Line Discount %" = 0.00001
        CreatePurchaseHeader(PurchaseHeaderSrc, PurchaseHeaderSrc."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeaderSrc, PurchaseLine.Type::Item, CreateItem(), 1);
        ModifyPurchaseLine(PurchaseHeaderSrc."Document Type", PurchaseHeaderSrc."No.", 1, UnitPrice, DiscountAmt);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderSrc, true, true);

        // [WHEN] Create new Purchase Credit Memo using Get Posted Document Lines
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeaderDst, PurchaseHeaderDst."Document Type"::"Credit Memo", PurchaseHeaderSrc."Buy-from Vendor No.");
        GetPostedDocumentLines(PurchaseHeaderDst."No.", PostedDocType::PostedInvoices);

        // [THEN] Purchase Credit Memo "Line Discount Amount" = 1
        GetPurchaseLine(PurchaseLine, PurchaseHeaderDst."Document Type", PurchaseHeaderDst."No.");
        Assert.AreEqual(DiscountAmt, PurchaseLine."Line Discount Amount", PurchaseLine.FieldCaption("Line Discount Amount"));
    end;

    [Test]
    [HandlerFunctions('PostedPurchaseDocumentLinesHandler')]
    [Scope('OnPrem')]
    procedure GetDocLinesToReverseFromInvoiceWithTwoShipments()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineDiscount: Decimal;
    begin
        // [FEATURE] [Line Discount] [Get Document Lines to Reverse]
        // [SCENARIO 376131] Action "Get Document Lines to Reserse" copies line discount from original purchase document when the purch. order is received in two parts, then invoiced

        // [GIVEN] Purchase order with one line: "Line Discount %" = 10
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(), LibraryRandom.RandDecInRange(5, 10, 2));

        LineDiscount := LibraryRandom.RandDec(50, 2);
        PurchaseLine.Validate("Line Discount %", LineDiscount);
        PurchaseLine.Validate("Qty. to Receive", PurchaseLine.Quantity / 2);
        PurchaseLine.Modify(true);
        // [GIVEN] Post partial receipt
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        // [GIVEN] Receive remaining quantity
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        // [GIVEN] Invoice total amount
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [GIVEN] Create credit memo
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", PurchaseHeader."Buy-from Vendor No.");
        // [WHEN] Run Get Document Lines to Reverse and copy from posted purchase invoice
        GetPostedDocumentLines(PurchaseHeader."No.", PostedDocType::PostedInvoices);

        // [THEN] "Line Discount %" = 10 in the credit memo
        GetPurchaseLine(PurchaseLine, PurchaseHeader."Document Type", PurchaseHeader."No.");
        Assert.AreEqual(LineDiscount, PurchaseLine."Line Discount %", PurchaseLine.FieldCaption("Line Discount Amount"));
    end;

    [Test]
    [HandlerFunctions('PostedPurchaseDocumentLinesWithSpecificCrMemoValidationHandler')]
    [Scope('OnPrem')]
    procedure UI_GetPostedDocumentLinesToReverseFromPurchCrMemoWithItem()
    var
        PurchHeader: Record "Purchase Header";
        NewPurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchCreditMemo: TestPage "Purchase Credit Memo";
        CrMemoNo: Code[20];
    begin
        // [FEATURE] [UI] [Credit Memo] [Get Posted Document Lines to Reverse]
        // [SCENARIO 382062] It is possible to get Posted Purchase Credit Memo with item to reverse from new Purchase Credit Memo

        Initialize();

        // [GIVEN] Posted Purchase Credit Memo "X" with Item
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::"Credit Memo", LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(
          PurchLine, PurchHeader, PurchLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
        CrMemoNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);
        LibraryVariableStorage.Enqueue(CrMemoNo); // for PostedPurchaseDocumentLinesWithSpecificCrMemoValidationHandler

        // [GIVEN] New Purchase Credit Memo
        LibraryPurchase.CreatePurchHeader(NewPurchHeader, NewPurchHeader."Document Type"::"Credit Memo", PurchHeader."Pay-to Vendor No.");

        // [GIVEN] Opened Purchase Credit Memo page with new Purchase Credit Memo
        PurchCreditMemo.OpenEdit();
        PurchCreditMemo.FILTER.SetFilter("No.", NewPurchHeader."No.");

        // [WHEN] Invoke action "Get Posted Document Lines to Reverse"
        PurchCreditMemo.GetPostedDocumentLinesToReverse.Invoke();

        // [THEN] "Posted Purchase Document Lines" is opened and Posted Purchase Credit Memo "X" exists in "Posted Credit Memos" list
        // Verification done in handler PostedPurchaseDocumentLinesWithSpecificCrMemoValidationHandler
    end;

    [Test]
    [HandlerFunctions('PostedPurchaseDocumentLinesHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoLineDiscountNotRecalculatedAfterReducingLineQty()
    var
        PurchaseLineDiscount: Record "Purchase Line Discount";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        PriceListLine: Record "Price List Line";
    begin
        // [FEATURE] [Line Discount] [Get Document Lines to Reverse]
        // [SCEANRIO 258074] Line discount % in purchase credit memo line is not recalculated if the line is copied from a posted invoice

        Initialize();

        // [GIVEN] Purchase line discount 10% for item "I" and customer "V", minimum quantity is 20
        SetupLineDiscount(PurchaseLineDiscount);
        CopyFromToPriceListLine.CopyFrom(PurchaseLineDiscount, PriceListLine);

        // [GIVEN] Purchase order for vendor "V", 20 pcs of item "I" are purchased
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, PurchaseLineDiscount."Vendor No.");
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, PurchaseLineDiscount."Item No.", PurchaseLineDiscount."Minimum Quantity");

        // [GIVEN] Post the purchase order
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        PurchInvHeader.SetRange("Order No.", PurchaseHeader."No.");
        PurchInvHeader.FindFirst();

        // [GIVEN] Create a purchase credit memo
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", PurchaseLineDiscount."Vendor No.");
        LibraryVariableStorage.Enqueue(PostedDocType::PostedInvoices);

        // [WHEN] Run "Get Document Lines to Reverse" function to copy lines from the posted invoice
        PurchaseHeader.GetPstdDocLinesToReverse();
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.FindFirst();

        // [THEN] Field "Copied From Posted Doc." in the credit memo line is set to TRUE
        PurchaseLine.TestField("Copied From Posted Doc.", true);

        // [WHEN] Change quantity in the credit memo line from 20 to 10
        PurchaseLine.Validate(Quantity, PurchaseLineDiscount."Minimum Quantity" / 2);

        // [THEN] Line discount % in the credit memo line remains 10
        PurchaseLine.TestField("Line Discount %", PurchaseLineDiscount."Line Discount %");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreditMemoLineDiscountRecalculatedManuallyCreatedLine()
    var
        PurchaseLineDiscount: Record "Purchase Line Discount";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PriceListLine: Record "Price List Line";
    begin
        // [FEATURE] [Line Discount]
        // [SCEANRIO 258074] Line discount % in purchase credit memo line is recalculated on validating quantity if the line is created manually

        // [GIVEN] Purchase line discount 10% for item "I" and vendor "C", minimum quantity is 20
        SetupLineDiscount(PurchaseLineDiscount);
        CopyFromToPriceListLine.CopyFrom(PurchaseLineDiscount, PriceListLine);

        // [GIVEN] Purchase credit memo for vendor "C", 20 pcs of item "I"
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", PurchaseLineDiscount."Vendor No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, PurchaseLineDiscount."Item No.", 0);

        // [WHEN] Set "Quantity" = 20 in the credit memo line
        PurchaseLine.Validate(Quantity, PurchaseLineDiscount."Minimum Quantity");

        // [THEN] "Line Discount %" is 10
        PurchaseLine.TestField("Line Discount %", PurchaseLineDiscount."Line Discount %");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemoChangePricesInclVATRefreshesPage()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseCreditMemoPage: TestPage "Purchase Credit Memo";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 277993] User changes Prices including VAT, page refreshes and shows appropriate captions
        Initialize();

        // [GIVEN] Page with Prices including VAT disabled was open
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", '');
        PurchaseCreditMemoPage.OpenEdit();
        PurchaseCreditMemoPage.GotoRecord(PurchaseHeader);

        // [WHEN] User checks Prices including VAT
        PurchaseCreditMemoPage."Prices Including VAT".SetValue(true);

        // [THEN] Caption for PurchaseCreditMemoPage.PurchLines."Direct Unit Cost" field is updated
        Assert.AreEqual('Direct Unit Cost Incl. VAT',
          PurchaseCreditMemoPage.PurchLines."Direct Unit Cost".Caption,
          'The caption for PurchaseCreditMemoPage.PurchLines."Direct Unit Cost" is incorrect');
    end;


    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PostAndNew()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchSetup: Record "Purchases & Payables Setup";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        PurchaseCreditMemo2: TestPage "Purchase Credit Memo";
        NoSeries: Codeunit "No. Series";
        NextDocNo: Code[20];
    begin
        // [FEATURE] [UI]
        // [SCENARIO 293548] Action "Post and new" opens new credit memo after posting the current one
        Initialize();

        // [GIVEN] Purchase Credit Memo card is opened with credit memo
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(), LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);

        PurchaseCreditMemo.OpenEdit();
        PurchaseCreditMemo.FILTER.SetFilter("No.", PurchaseHeader."No.");

        // [WHEN] Action "Post and new" is being clicked
        PurchaseCreditMemo2.Trap();
        PurchSetup.Get();
        NextDocNo := NoSeries.PeekNextNo(PurchSetup."Credit Memo Nos.");
        PurchaseCreditMemo.PostAndNew.Invoke();

        // [THEN] Purchase credit memo page opened with new credit memo
        PurchaseCreditMemo2."No.".AssertEquals(NextDocNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetFullDocTypeName()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [SCENARIO] Get full document type and name
        // [GIVEN] Purchase Header of type "Credit Memo"
        PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::"Credit Memo";

        // [WHEN] GetFullDocTypeTxt is called
        // [THEN] 'Purchase Create Memo' is returned
        Assert.AreEqual('Purchase Credit Memo', PurchaseHeader.GetFullDocTypeTxt(), 'The expected full document type is incorrect');
    end;

    [Test]
    [HandlerFunctions('PostedPurchaseDocumentLinesHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoLineUnitCostNotRecalculatedAfterChangingLineQty()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchasePrice: Record "Purchase Price";
        PurchInvHeader: Record "Purch. Inv. Header";
        Vendor: Record Vendor;
    begin
        // [FEATURE] [Line Discount] [Get Document Lines to Reverse]
        // [SCEANRIO 365623] "Unit Cost" in purchase credit memo line is not recalculated if the line is copied from a posted invoice
        Initialize();

        // [GIVEN] Purchase special "Unit Cost" 10 for item "I" and customer "V", minimum quantity is 10
        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(Item);
        LibraryCosting.CreatePurchasePrice(
          PurchasePrice, Vendor."No.", Item."No.", 0D, '', '', Item."Base Unit of Measure", LibraryRandom.RandIntInRange(10, 20));

        // [GIVEN] Purchase order for vendor "V", 20 pcs of item "I" are purchased
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", PurchasePrice."Minimum Quantity");

        // [GIVEN] Post the purchase order
        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));

        // [GIVEN] Create a purchase credit memo
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", Vendor."No.");
        LibraryVariableStorage.Enqueue(PostedDocType::PostedInvoices);

        // [GIVEN] Run "Get Document Lines to Reverse" function to copy lines from the posted invoice
        PurchaseHeader.GetPstdDocLinesToReverse();
        FilterOnPurchaseLine(PurchaseLine, PurchaseHeader."Document Type", PurchaseHeader."No.");
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.FindFirst();

        // [WHEN] Change quantity in the credit memo line from 10 to 9
        PurchaseLine.Validate(Quantity, PurchasePrice."Minimum Quantity" - 1);

        // [THEN] "Unit Cost" in the credit memo line remains 10
        PurchaseLine.TestField("Unit Cost", PurchasePrice."Direct Unit Cost");
    end;

    [Test]
    [HandlerFunctions('PostedPurchaseDocumentLinesHandler')]
    [Scope('OnPrem')]
    procedure CrMemoGetPostedDocumentLinesPostedPurchShptUnitPrice()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchasePrice: Record "Purchase Price";
        InitialUnitCost: Decimal;
    begin
        // [FEATURE] [Get Document Lines to Reverse]
        // [SCENARIO 393339] Action "Get Document Lines to Reserse" copies Unit Price from Posted Purchase Shipment and not from current Purchase Price
        Initialize();

        // [GIVEN] Purchase order with one line: Item "I1" with Unit Cost = X.
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", LibraryPurchase.CreateVendorNo());
        InitialUnitCost := LibraryRandom.RandIntInRange(5, 10);
        LibraryPurchase.CreatePurchaseLineWithUnitCost(PurchaseLine, PurchaseHeader, CreateItem(), InitialUnitCost, 1);

        // [GIVEN] Post Credit Memo
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Purchase Price for Item "I1" = X + 5 for WorkDate
        LibraryCosting.CreatePurchasePrice(
          PurchasePrice, PurchaseHeader."Buy-from Vendor No.", PurchaseLine."No.", WorkDate(), '', '', '', 0);
        PurchasePrice.Validate("Direct Unit Cost", InitialUnitCost + 5);
        PurchasePrice.Modify(true);
        PurchaseLine.Reset();

        // [GIVEN] Create Purchase Credit Memo
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", PurchaseHeader."Buy-from Vendor No.");

        // [WHEN] Run Get Document Lines to Reverse and copy from Posted Purchase Shipment
        GetPostedDocumentLines(PurchaseHeader."No.", PostedDocType::PostedReturnShipments);

        // [THEN] "Unit Cost" = X in created Purchase Line
        GetPurchaseLine(PurchaseLine, PurchaseHeader."Document Type", PurchaseHeader."No.");
        Assert.AreEqual(InitialUnitCost, PurchaseLine."Unit Cost", PurchaseLine.FieldCaption("Unit Cost"));
    end;

    [Test]
    [HandlerFunctions('PostedPurchaseDocumentLinesHandler')]
    procedure ValueEntryCostAmountActualIsCorrectWhenPostPurchaseCreditMemoUsingNonDeductibleVAT()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        GLEntry: Record "G/L Entry";
        InventoryPostingGroup: Record "Inventory Posting Group";
        Item: Record Item;
        Location: Record Location;
        PurchaseHeader: array[2] of Record "Purchase Header";
        PurchaseLine: array[2] of Record "Purchase Line";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchInvHeader: Record "Purch. Inv. Header";
        VATEntry: array[2] of Record "VAT Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        Vendor: Record Vendor;
        DocumentType: Enum "Item Ledger Document Type";
        PurchaseDocumentType: Enum "Purchase Document Type";
        ActualAmount: array[4] of Decimal;
        CostAmountActual: array[2] of Decimal;
    begin
        // [SCENARIO 540329] When Stans Posts Purchase Credit Memo using Non-Deductible VAT
        // Then Non-Deductible Amount is added in item costs in G/L Entry and Value Entry.
        Initialize();

        // [GIVEN] Create a Non Deductible VAT Posting Setup.
        CreateVATSetupForNonDeductible(VATPostingSetup);

        // [GIVEN] Create a General Posting Setup.
        CreateGeneralPostingSetup(GeneralPostingSetup);

        // [GIVEN] Create a Vendor.
        CreateVendorWithPostingGroup(Vendor, GeneralPostingSetup, VATPostingSetup);

        // [GIVEN] Create a Location.
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] Create a Inventory Posting Setup.
        CreateInventoryPostingSetup(Location, InventoryPostingGroup);

        // [GIVEN] Create a Item No with Posting Setup and Validate Inventory Posting Group.
        CreateItemWithPostingSetup(Item, GeneralPostingSetup."Gen. Prod. Posting Group",
            VATPostingSetup."VAT Prod. Posting Group", InventoryPostingGroup.Code);

        // [GIVEN] Create a Purchase Header Document Type of Invoice and Validate Location Code.
        CreatePurchaseDocument(PurchaseHeader[1], PurchaseDocumentType::Invoice, Vendor."No.", Location.Code);

        // [GIVEN] Create a Purchase Line and Validate "Direct Unit Cost".
        LibraryPurchase.CreatePurchaseLine(PurchaseLine[1], PurchaseHeader[1],
            PurchaseLine[1].Type::Item, Item."No.", LibraryRandom.RandInt(0));
        PurchaseLine[1].Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(10000, 10000));
        PurchaseLine[1].Modify(true);

        // [WHEN] Posts a Purchase Invoice.
        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader[1], true, true));

        // [THEN] Retrieve VAT Entry.
        GetVATEntry(VATEntry[1], PurchInvHeader."No.");

        // [THEN] Verify "Non-Deductible VAT Amount" of VAT Entry exists.
        Assert.AreNotEqual(0, VATEntry[1]."Non-Deductible VAT Amount", NonDeducVATEntryMustExistMsgLbl);

        // [GIVEN] Get Direct Cost Applied Amount for Document Type Purchase Invoice.
        ActualAmount[1] := GetGLEntryAmount(GLEntry, PurchInvHeader."No.", GeneralPostingSetup."Direct Cost Applied Account");

        // [GIVEN] Get Amount Posted to Inventory Account for Document Type Purchase Invoice.
        ActualAmount[2] := GetGLEntryAmount(GLEntry, PurchInvHeader."No.", GetInventoryAccount(Location.Code, InventoryPostingGroup.Code));

        // [WHEN] Calculate Cost Amount Actual.
        CostAmountActual[1] := VATEntry[1]."Non-Deductible VAT Base" + VATEntry[1]."Non-Deductible VAT Amount";

        // [THEN] Verify Cost Amount (Actual) of Value Entry for Purchase Invoice.
        VerifyValueEntry(PurchInvHeader."No.", CostAmountActual[1], DocumentType::"Purchase Invoice");

        // [THEN] Verify Direct Cost Applied Amount of GL Entry.
        Assert.AreEqual(-CostAmountActual[1], ActualAmount[1],
            StrSubstNo(FieldErrDetLbl, GLEntry.FieldCaption(Amount), -CostAmountActual[1], GLEntry.TableCaption()));

        // [THEN] Verify Amount Posted to Inventory Account of GL Entry.
        Assert.AreEqual(CostAmountActual[1], ActualAmount[2],
            StrSubstNo(FieldErrDetLbl, GLEntry.FieldCaption(Amount), CostAmountActual[1], GLEntry.TableCaption()));

        // [GIVEN] Create a Purchase Header for Document Type Credit Memo.
        CreatePurchaseDocument(PurchaseHeader[2], PurchaseDocumentType::"Credit Memo", Vendor."No.", Location.Code);

        // [GIVEN] Run Get Document Lines to Reverse and copy from Posted Purchase Invoices.
        GetPostedDocumentLines(PurchaseHeader[2]."No.", PostedDocType::PostedInvoices);

        // [GIVEN] Posts a Purchase Credit Memo.
        PurchCrMemoHdr.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader[2], true, true));

        // [WHEN] Retrieve VAT Entry.
        GetVATEntry(VATEntry[2], PurchCrMemoHdr."No.");

        // [THEN] Verify "Non-Deductible VAT Amount" of VAT Entry exists.
        Assert.AreNotEqual(0, VATEntry[2]."Non-Deductible VAT Amount", NonDeducVATEntryMustExistMsgLbl);

        // [GIVEN] Get Direct Cost Applied Amount for Document Type Purchase Credit Memo.
        ActualAmount[3] := GetGLEntryAmount(GLEntry, PurchCrMemoHdr."No.", GeneralPostingSetup."Direct Cost Applied Account");

        // [GIVEN] Get Amount Posted to Inventory Account for Document Type Purchase Credit Memo.
        ActualAmount[4] := GetGLEntryAmount(GLEntry, PurchCrMemoHdr."No.", GetInventoryAccount(Location.Code, InventoryPostingGroup.Code));

        // [WHEN] Calculate Cost Amount Actual.
        CostAmountActual[2] := VATEntry[2]."Non-Deductible VAT Base" + VATEntry[2]."Non-Deductible VAT Amount";

        // [THEN] Verify Field "Cost Amount (Actual)" of Value Entry for Purchase Invoice.
        VerifyValueEntry(PurchCrMemoHdr."No.", CostAmountActual[2], DocumentType::"Purchase Credit Memo");

        // [THEN] Verify Direct Cost Applied Amount of GL Entry.
        Assert.AreEqual(-CostAmountActual[2], ActualAmount[3],
            StrSubstNo(FieldErrDetLbl, GLEntry.FieldCaption(Amount), CostAmountActual[2], GLEntry.TableCaption()));

        // [THEN] Verify Amount Posted to Inventory Account of GL Entry.
        Assert.AreEqual(CostAmountActual[2], ActualAmount[4],
            StrSubstNo(FieldErrDetLbl, GLEntry.FieldCaption(Amount), -CostAmountActual[2], GLEntry.TableCaption()));
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Purchase Credit Memo");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();
        DocumentNo2 := '';
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Purchase Credit Memo");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();

        IsInitialized := true;
        Commit();
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Purchase Credit Memo");
    end;

    local procedure CreateAndPostPurchInvWithPricesInclVAT(var PurchaseLine: Record "Purchase Line"; PricesIncludingVAT: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreatePurchDocWithPriceInclVAT(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo(), PricesIncludingVAT);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithPurchSetup(), LibraryRandom.RandInt(10));
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreateAndShipPurchRetOrder(var PurchaseHeader: Record "Purchase Header"): Code[20]
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", LibraryPurchase.CreateVendorNo());
        CreatePurchaseLine(PurchaseLine, PurchaseHeader);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false));
    end;

    local procedure CreatePurchCrMemoUsingGetRetShptLines(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", VendorNo);
        PurchaseLine.Validate("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.Validate("Document No.", PurchaseHeader."No.");
        CODEUNIT.Run(CODEUNIT::"Purch.-Get Return Shipments", PurchaseLine);
    end;

    local procedure CreatePurchDocWithPriceInclVAT(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; BuyFromVendorNo: Code[20]; PricesIncludingVAT: Boolean)
    begin
        CreatePurchaseHeader(PurchaseHeader, DocumentType, BuyFromVendorNo);
        PurchaseHeader.Validate("Prices Including VAT", PricesIncludingVAT);
        PurchaseHeader.Modify(true);
    end;

    local procedure CreatePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20])
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
    end;

    local procedure CreatePurchaseInvoiceWithVAT(var PurchaseHeader: Record "Purchase Header"; VATPostingSetup: Record "VAT Posting Setup")
    var
        PurchaseLine: Record "Purchase Line";
        GLAccount: Record "G/L Account";
    begin
        CreatePurchaseHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice,
          LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        CreatePurchaseInvoiceLine(
          PurchaseHeader, PurchaseLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase));
    end;

    local procedure CreatePurchaseInvoice(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        CreatePurchaseInvoiceLine(PurchaseHeader, PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup());
    end;

    local procedure CreatePurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header")
    begin
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item,
          LibraryInventory.CreateItemNo(), LibraryRandom.RandIntInRange(10, 20));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(1000, 2000));
        PurchaseLine.Modify();

        if PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::"Credit Memo" then begin
            PurchaseLine.Validate("Qty. to Receive", 0);  // Qty. to Receive must be 0 for Purchase Credit Memo.
            PurchaseLine.Modify(true);
        end;
    end;

    local procedure CreatePurchaseInvoiceLine(PurchaseHeader: Record "Purchase Header"; Type: Enum "Purchase Line Type"; No: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Type, No, LibraryRandom.RandDec(10, 2));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));  // Use Random Unit Price between 1 and 100.
        PurchaseLine.Modify(true);
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

    local procedure CreateItemAndExtendedText(): Code[20]
    var
        ExtendedTextHeader: Record "Extended Text Header";
        ExtendedTextLine: Record "Extended Text Line";
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateExtendedTextHeaderItem(ExtendedTextHeader, Item."No.");
        LibraryInventory.CreateExtendedTextLineItem(ExtendedTextLine, ExtendedTextHeader);
        ExtendedTextLine.Validate(Text, Item."No.");
        ExtendedTextLine.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreditMemoWithCopyDocument(var PurchaseHeader: Record "Purchase Header"; DocType: Enum "Purchase Document Type From"; DocNo: Code[20]; IncludeHeader: Boolean; RecalcLines: Boolean)
    var
        CopyPurchaseDocument: Report "Copy Purchase Document";
    begin
        CopyPurchaseDocument.SetPurchHeader(PurchaseHeader);
        CopyPurchaseDocument.SetParameters(DocType, DocNo, IncludeHeader, RecalcLines);
        CopyPurchaseDocument.UseRequestPage(false);
        CopyPurchaseDocument.Run();
    end;

    local procedure CreatePurchCrMemoWithCurrency(var PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader.Init();
        PurchaseHeader.Validate("Buy-from Vendor No.", LibraryPurchase.CreateVendorNo());
        PurchaseHeader.Validate("Currency Code", CreateCurrency());
        PurchaseHeader.Validate("Document Type", PurchaseHeader."Document Type"::"Credit Memo");
        PurchaseHeader.Insert(true);
    end;

    local procedure ModifyPurchaseLine(DocumentType: Enum "Purchase Document Type"; DocumentNo: Code[20]; NewQuantity: Decimal; NewDirectUnitCost: Decimal; NewLineDiscountAmt: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        GetPurchaseLine(PurchaseLine, DocumentType, DocumentNo);
        PurchaseLine.Validate(Quantity, NewQuantity);
        PurchaseLine.Validate("Direct Unit Cost", NewDirectUnitCost);
        PurchaseLine.Validate("Line Discount Amount", NewLineDiscountAmt);
        PurchaseLine.Modify();
    end;

    local procedure FindAndUpdateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        UpdateVATPostingSetup(
          VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::Percentage, LibraryERM.CreateGLAccountNo(), LibraryERM.CreateGLAccountNo());
    end;

    local procedure FilterOnPurchaseLine(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; DocumentNo: Code[20])
    begin
        PurchaseLine.SetRange("Document Type", DocumentType);
        PurchaseLine.SetRange("Document No.", DocumentNo);
    end;

    local procedure GetVATAmountOnGLEntry(DocumentNo: Code[20]; DocumentType: Enum "Purchase Document Type"): Decimal
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("Document Type", DocumentType);
        GLEntry.FindFirst();
        exit(GLEntry."VAT Amount");
    end;

    local procedure GetPurchaseLine(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; DocumentNo: Code[20])
    begin
        FilterOnPurchaseLine(PurchaseLine, DocumentType, DocumentNo);
        PurchaseLine.SetFilter(Type, '<>%1', PurchaseLine.Type::" ");
        PurchaseLine.FindFirst();
    end;

    local procedure GetPostedDocumentLines(No: Code[20]; DocumentType: Option)
    var
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        LibraryVariableStorage.Enqueue(DocumentType);
        PurchaseCreditMemo.OpenEdit();
        PurchaseCreditMemo.FILTER.SetFilter("No.", No);
        PurchaseCreditMemo.GetPostedDocumentLinesToReverse.Invoke();
    end;

    local procedure GetAndUpdatePurchaseLine(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; DocumentNo: Code[20])
    begin
        // Enter Random value for Direct Unit Cost.
        GetPurchaseLine(PurchaseLine, DocumentType, DocumentNo);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure SetupLineDiscount(var PurchaseLineDiscount: Record "Purchase Line Discount")
    var
        Item: Record Item;
    begin
        // Enter Random Values for "Minimum Quantity" and "Line Discount %".
        Item.Get(CreateItem());
        LibraryERM.CreateLineDiscForVendor(
          PurchaseLineDiscount, Item."No.", LibraryPurchase.CreateVendorNo(),
          WorkDate(), '', '', Item."Base Unit of Measure", LibraryRandom.RandInt(10));
        PurchaseLineDiscount.Validate("Line Discount %", LibraryRandom.RandInt(10));
        PurchaseLineDiscount.Modify(true);
    end;

    local procedure SetupInvoiceDiscount(var VendorInvoiceDisc: Record "Vendor Invoice Disc.")
    begin
        // Enter Random Values for "Minimum Amount" and "Discount %".
        LibraryERM.CreateInvDiscForVendor(
          VendorInvoiceDisc, LibraryPurchase.CreateVendorNo(), '', LibraryRandom.RandInt(100));
        VendorInvoiceDisc.Validate("Discount %", LibraryRandom.RandInt(10));
        VendorInvoiceDisc.Modify(true);
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure UpdateVATPostingSetup(VATPostingSetup: Record "VAT Posting Setup"; UnrealizedVATType: Option; PurchVATUnrealAccountNo: Code[20]; ReverseChrgVATUnrealAccNo: Code[20])
    begin
        // Update Unrealized VAT Type and Purch. VAT Unreal. Account field and Reverse Chrg. VAT Unreal. Account field in VAT Posting Setup.
        VATPostingSetup.Get(VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        VATPostingSetup.Validate("Unrealized VAT Type", UnrealizedVATType);
        VATPostingSetup.Validate("Purch. VAT Unreal. Account", PurchVATUnrealAccountNo);
        VATPostingSetup.Validate("Reverse Chrg. VAT Unreal. Acc.", ReverseChrgVATUnrealAccNo);
        VATPostingSetup.Modify(true);
    end;

    local procedure VerifyVATAmountOnGLEntry(DocumentType: Enum "Purchase Document Type"; DocumentNo: Code[20]; VATAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document Type", DocumentType);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.FindFirst();
        GLEntry.TestField("VAT Amount", VATAmount);
    end;

    local procedure VerifyGLEntry(DocumentNo: Code[20]; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
        TotalGLAmount: Decimal;
    begin
        GeneralLedgerSetup.Get();
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::"Credit Memo");
        GLEntry.SetFilter(Amount, '>0');
        GLEntry.FindSet();
        repeat
            TotalGLAmount += GLEntry.Amount;
        until GLEntry.Next() = 0;
        Assert.AreNearlyEqual(
          Amount, TotalGLAmount, GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(FieldErr, GLEntry.FieldCaption(Amount), GLEntry.TableCaption()));
    end;

    local procedure VerifyVendorLedgerEntry(DocumentNo: Code[20]; Amount: Decimal)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        VendorLedgerEntry.SetRange("Document No.", DocumentNo);
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::"Credit Memo");
        VendorLedgerEntry.FindFirst();
        VendorLedgerEntry.CalcFields("Amount (LCY)");
        Assert.AreNearlyEqual(
          Amount, Abs(VendorLedgerEntry."Amount (LCY)"), GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(FieldErr, VendorLedgerEntry.FieldCaption("Amount (LCY)"), VendorLedgerEntry.TableCaption()));
    end;

    local procedure VerifyVATEntry(DocumentNo: Code[20]; Amount: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        VATEntry: Record "VAT Entry";
    begin
        GeneralLedgerSetup.Get();
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::"Credit Memo");
        VATEntry.FindFirst();
        Assert.AreNearlyEqual(
          Amount, Abs(VATEntry.Base + VATEntry.Amount), GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(FieldErr, VATEntry.FieldCaption(Amount), VATEntry.TableCaption()));
    end;

    local procedure VerifyValueEntry(DocumentNo: Code[20]; Amount: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        ValueEntry: Record "Value Entry";
        CostAmount: Decimal;
    begin
        GeneralLedgerSetup.Get();
        ValueEntry.SetRange("Document No.", DocumentNo);
        ValueEntry.SetRange("Document Type", ValueEntry."Document Type"::"Purchase Credit Memo");
        ValueEntry.FindSet();
        repeat
            CostAmount += ValueEntry."Cost Amount (Actual)";
        until ValueEntry.Next() = 0;
        Assert.AreNearlyEqual(
          -Amount, CostAmount, GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(FieldErr, ValueEntry.FieldCaption("Cost Amount (Actual)"), ValueEntry.TableCaption()));
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
          LineDiscountAmount, GLEntry.Amount, GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(FieldErr, GLEntry.FieldCaption(Amount), GLEntry.TableCaption()));
        Assert.AreNearlyEqual(
          LineDiscountAmount, PurchaseLine."Line Discount Amount", GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(FieldErr, PurchaseLine.FieldCaption("Line Discount Amount"), PurchaseLine.TableCaption()));
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
          InvoiceDiscountAmount, Abs(GLEntry.Amount), GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(FieldErr, GLEntry.FieldCaption(Amount), GLEntry.TableCaption()));
        Assert.AreNearlyEqual(
          InvoiceDiscountAmount, PurchaseLine."Inv. Discount Amount", GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(FieldErr, PurchaseLine.FieldCaption("Inv. Discount Amount"), PurchaseLine.TableCaption()));
    end;

    local procedure VerifyItemLedgerEntry(DocumentNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Document No.", DocumentNo);
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.TestField(Quantity, Quantity);
    end;

    local procedure VerifyPurchaseLine(PurchaseHeader: Record "Purchase Header"; Quantity: Decimal; LineAmount: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        GetPurchaseLine(PurchaseLine, PurchaseHeader."Document Type", PurchaseHeader."No.");
        PurchaseLine.TestField(Quantity, Quantity);
        PurchaseLine.TestField("Line Amount", LineAmount);
    end;

    local procedure PurchDocLineQtyValidation()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Location: Record Location;
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        // SETUP:
        LibraryWarehouse.CreateFullWMSLocation(Location, 3);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), 0);
        PurchaseLine.Validate("Location Code", Location.Code);
        PurchaseLine.Modify(true);

        PurchaseCreditMemo.OpenEdit();
        PurchaseCreditMemo.GotoRecord(PurchaseHeader);
        // EXECUTE:
        PurchaseCreditMemo.PurchLines.Quantity.SetValue(100);
        // VERIFY: In the test method
    end;

    local procedure CreateVATSetupForNonDeductible(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        LibraryNonDeductibleVAT.EnableNonDeductibleVAT();
        LibraryNonDeductibleVAT.SetUseForItemCost();
        LibraryNonDeductibleVAT.CreateVATPostingSetupWithNonDeductibleDetail(VATPostingSetup, 19, 100);
    end;

    local procedure CreateGeneralPostingSetup(var GeneralPostingSetup: Record "General Posting Setup")
    begin
        LibraryERM.CreateGeneralPostingSetupInvt(GeneralPostingSetup);
        LibraryERM.SetGeneralPostingSetupPurchAccounts(GeneralPostingSetup);
        LibraryERM.SetGeneralPostingSetupSalesAccounts(GeneralPostingSetup);
        LibraryERM.SetGeneralPostingSetupMfgAccounts(GeneralPostingSetup);
        GeneralPostingSetup.Modify(true);
    end;

    local procedure CreateVendorWithPostingGroup(var Vendor: Record Vendor; var GeneralPostingSetup: Record "General Posting Setup"; var VATPostingSetup: Record "VAT Posting Setup")
    begin
        Vendor.Get(LibraryPurchase.CreateVendorWithBusPostingGroups(GeneralPostingSetup."Gen. Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group"));
    end;

    local procedure CreateInventoryPostingSetup(Location: Record Location; var InventoryPostingGroup: Record "Inventory Posting Group")
    begin
        LibraryInventory.SetAutomaticCostPosting(true);
        LibraryInventory.CreateInventoryPostingGroup(InventoryPostingGroup);
        LibraryInventory.UpdateInventoryPostingSetup(Location, InventoryPostingGroup.Code);
    end;

    local procedure CreateItemWithPostingSetup(var Item: Record Item; GenProdPostingGroupCode: Code[20]; VATProdPostingGroupCode: Code[20]; InventoryPostingGroupCode: Code[20])
    begin
        Item.Get(LibraryInventory.CreateItemNoWithPostingSetup(GenProdPostingGroupCode, VATProdPostingGroupCode));
        Item.Validate("Inventory Posting Group", InventoryPostingGroupCode);
        Item.Modify(true);
    end;

    local procedure GetInventoryAccount(LocationCode: Code[20]; InvtPostingGroupCode: Code[20]): Code[20]
    var
        InventoryPostingSetup: Record "Inventory Posting Setup";
    begin
        InventoryPostingSetup.SetRange("Location Code", LocationCode);
        InventoryPostingSetup.SetRange("Invt. Posting Group Code", InvtPostingGroupCode);
        if InventoryPostingSetup.FindFirst() then
            exit(InventoryPostingSetup."Inventory Account");
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; PurchaseDocumentType: Enum "Purchase Document Type"; VendorNo: Code[20]; LocationCode: Code[20])
    begin
        CreatePurchaseHeader(PurchaseHeader, PurchaseDocumentType, VendorNo);
        PurchaseHeader.Validate(PurchaseHeader."Location Code", LocationCode);
        PurchaseHeader.Modify(true);
    end;

    local procedure GetVATEntry(var VATEntry: Record "VAT Entry"; DocumentNo: Code[20])
    begin
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.CalcSums("Non-Deductible VAT Base", "Non-Deductible VAT Amount");
    end;

    local procedure VerifyValueEntry(DocumentNo: Code[20]; ExpectedAmount: Decimal; DocumentType: Enum "Item Ledger Document Type")
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Document No.", DocumentNo);
        ValueEntry.SetRange("Document Type", DocumentType);
        ValueEntry.FindFirst();

        Assert.AreEqual(ExpectedAmount, ValueEntry."Cost Amount (Actual)", StrSubstNo(FieldErrDetLbl,
            ValueEntry.FieldCaption("Cost Amount (Actual)"), ExpectedAmount, ValueEntry.TableCaption()));
    end;

    local procedure GetGLEntryAmount(var GLEntry: Record "G/L Entry"; DocumentNo: Code[20]; GLAccountNo: Code[20]): Decimal
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindFirst();
        exit(GLEntry.Amount);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Message: Text[1024]; var Reply: Boolean)
    begin
        Assert.IsTrue(StrPos(Message, LibraryVariableStorage.DequeueText()) > 0, Message);
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Message: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GetReturnShipmentHandler(var GetReturnShipmentLines: TestPage "Get Return Shipment Lines")
    begin
        GetReturnShipmentLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchaseDocumentLinesHandler(var PostedPurchaseDocumentLines: TestPage "Posted Purchase Document Lines")
    var
        DocumentType: Option "Posted Receipts","Posted Invoices","Posted Return Shipments","Posted Cr. Memos";
    begin
        case LibraryVariableStorage.DequeueInteger() of
            PostedDocType::PostedReturnShipments:
                begin
                    PostedPurchaseDocumentLines.PostedReceiptsBtn.SetValue(Format(DocumentType::"Posted Return Shipments"));
                    PostedPurchaseDocumentLines.PostedReturnShpts.FILTER.SetFilter("Document No.", DocumentNo2);
                end;
            PostedDocType::PostedInvoices:
                PostedPurchaseDocumentLines.PostedReceiptsBtn.SetValue(Format(DocumentType::"Posted Invoices"));
        end;
        PostedPurchaseDocumentLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchaseDocumentLinesWithSpecificCrMemoValidationHandler(var PostedPurchaseDocumentLines: TestPage "Posted Purchase Document Lines")
    begin
        PostedPurchaseDocumentLines.PostedCrMemos."Document No.".AssertEquals(LibraryVariableStorage.DequeueText());
        PostedPurchaseDocumentLines.OK().Invoke();
    end;
}
