codeunit 144008 "IT - VAT Reporting - Purchase"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryMarketing: Codeunit "Library - Marketing";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVATUtils: Codeunit "Library - VAT Utils";
        isInitialized: Boolean;
        YouMustSpecifyValueErr: Label 'You must specify a value for the %1 field';

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvIncl()
    var
        PurchHeader: Record "Purchase Header";
    begin
        // Purch. Invoice, [Prices Including VAT] = No.
        // [Include in VAT Transac. Rep.] = Yes in VAT Posting Setup.
        // Line Amount > [Threshold Amount Excl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = Yes.
        VerifyPurchDocIncl(PurchHeader."Document Type"::Invoice, false, true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvExcl()
    var
        PurchHeader: Record "Purchase Header";
    begin
        // Purch. Invoice, [Prices Including VAT] = No.
        // [Include in VAT Transac. Rep.] = Yes in VAT Posting Setup.
        // Line Amount < [Threshold Amount Excl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = No.
        VerifyPurchDocIncl(PurchHeader."Document Type"::Invoice, false, true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvExcl2()
    var
        PurchHeader: Record "Purchase Header";
    begin
        // Purch. Invoice, [Prices Including VAT] = No.
        // [Include in VAT Transac. Rep.] = No in VAT Posting Setup.
        // Line Amount > [Threshold Amount Excl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = No.
        VerifyPurchDocIncl(PurchHeader."Document Type"::Invoice, false, false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvInclWVAT()
    var
        PurchHeader: Record "Purchase Header";
    begin
        // Purch. Invoice, [Prices Including VAT] = Yes.
        // [Include in VAT Transac. Rep.] = Yes in VAT Posting Setup.
        // Line Amount > [Threshold Amount Incl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = Yes.
        VerifyPurchDocIncl(PurchHeader."Document Type"::Invoice, true, true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvExclWVAT()
    var
        PurchHeader: Record "Purchase Header";
    begin
        // Purch. Invoice, [Prices Including VAT] = Yes.
        // [Include in VAT Transac. Rep.] = Yes in VAT Posting Setup.
        // Line Amount < [Threshold Amount Incl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = No.
        VerifyPurchDocIncl(PurchHeader."Document Type"::Invoice, true, true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvExcl2WVAT()
    var
        PurchHeader: Record "Purchase Header";
    begin
        // Purch. Invoice, [Prices Including VAT] = Yes.
        // [Include in VAT Transac. Rep.] = No in VAT Posting Setup.
        // Line Amount > [Threshold Amount Incl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = No.
        VerifyPurchDocIncl(PurchHeader."Document Type"::Invoice, true, false, true);
    end;

    local procedure VerifyPurchDocIncl(DocumentType: Enum "Purchase Document Type"; InclVAT: Boolean; InclInVATSetup: Boolean; InclInVATTransRep: Boolean)
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        LineAmount: Decimal;
    begin
        Initialize();

        // Setup.
        SetupThresholdAmount(WorkDate());
        LibraryVATUtils.UpdateVATPostingSetup(InclInVATSetup);

        // Create Purch Document.
        LineAmount := CalculateAmount(WorkDate(), InclVAT, InclInVATTransRep);
        CreatePurchDocument(
          PurchHeader, PurchLine, DocumentType, CreateVendor(false, PurchHeader.Resident::Resident, true, InclVAT), LineAmount);

        // Verify Purch Line.
        PurchLine.TestField("Include in VAT Transac. Rep.", InclInVATSetup); // Amount is no longer compared to Threshold.

        // Tear Down.
        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchOrdLnkBlOrdSingleLine()
    begin
        // Purchase Blanket Order with Single Line.
        // [Prices Including VAT] = No.
        // [Include in VAT Transac. Rep.] = Yes in VAT Posting Setup.
        // Order Amount > [Threshold Amount Incl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = Yes.
        VerifyPurchBlOrd(false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchOrdLnkBlOrdMultipleLines()
    begin
        // Purchase Blanket Order with Multiple Lines.
        // [Prices Including VAT] = No.
        // [Include in VAT Transac. Rep.] = Yes in VAT Posting Setup.
        // Order Amount > [Threshold Amount Incl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = Yes.
        VerifyPurchBlOrd(true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchOrdLnkBlOrdSingleLineWVAT()
    begin
        // Purchase Blanket Order with Single Line.
        // [Prices Including VAT] = Yes.
        // [Include in VAT Transac. Rep.] = Yes in VAT Posting Setup.
        // Order Amount > [Threshold Amount Incl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = Yes.
        VerifyPurchBlOrd(false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchOrdLnkBlOrdMultiLinesWVAT()
    begin
        // Purchase Blanket Order with Multiple Lines.
        // [Prices Including VAT] = Yes.
        // [Include in VAT Transac. Rep.] = Yes in VAT Posting Setup.
        // Order Amount > [Threshold Amount Incl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = Yes.
        VerifyPurchBlOrd(true, true);
    end;

    local procedure VerifyPurchBlOrd(MultiLine: Boolean; InclVAT: Boolean)
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchOrderHeader: Record "Purchase Header";
        LineAmount: Decimal;
        OrderAmount: Decimal;
    begin
        Initialize();

        // Setup.
        SetupThresholdAmount(WorkDate());
        LibraryVATUtils.UpdateVATPostingSetup(true);

        // Calculate Amounts.
        OrderAmount := CalculateAmount(WorkDate(), InclVAT, true); // Above threshold.
        LineAmount := CalculateAmount(WorkDate(), InclVAT, false); // Below threshold.

        // Create Purch Blanket Order.
        CreatePurchDocument(
          PurchHeader, PurchLine, PurchHeader."Document Type"::"Blanket Order",
          CreateVendor(false, PurchHeader.Resident::Resident, true, InclVAT), OrderAmount);

        if MultiLine then begin
            // Set Quantity to Receive to 0 on line with Amount above Threshold.
            PurchLine.Validate("Qty. to Receive", 0);
            PurchLine.Modify(true);

            // Create Purch Line with Line Amount below Threshold.
            CreatePurchLine(PurchHeader, PurchLine, LineAmount);
        end else begin
            // Update Quantity to Receive so that Line Amount is below Threshold.
            PurchLine.Validate("Qty. to Receive", LineAmount / PurchLine."Direct Unit Cost");
            PurchLine.Modify(true);
        end;

        // Release and Make Order.
        CODEUNIT.Run(CODEUNIT::"Release Purchase Document", PurchHeader);
        MakeOrderPurchase(PurchHeader, PurchOrderHeader);

        // Verify Line.
        FindPurchLine(PurchLine, PurchOrderHeader."Document Type", PurchOrderHeader."No.");
        PurchLine.TestField("Include in VAT Transac. Rep.", true);

        // Tear Down.
        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EUCountryPurchInv()
    begin
        VerifyCountryPurchInv(CreateCountry()); // EU Country.
    end;

    local procedure VerifyCountryPurchInv(CountryRegionCode: Code[10])
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        Vendor: Record Vendor;
        LineAmount: Decimal;
    begin
        Initialize();

        // Setup.
        SetupThresholdAmount(WorkDate());
        LibraryVATUtils.UpdateVATPostingSetup(true);

        // Create Vendor.
        Vendor.Get(CreateVendor(false, PurchHeader.Resident::"Non-Resident", true, false));
        Vendor.Validate("Country/Region Code", CountryRegionCode);
        Vendor.Modify(true);

        // Create Purchase Document.
        LineAmount := CalculateAmount(WorkDate(), false, true);
        CreatePurchDocument(PurchHeader, PurchLine, PurchHeader."Document Type"::Invoice, Vendor."No.", LineAmount);

        // Verify Purchase Line.
        PurchLine.TestField("Include in VAT Transac. Rep.", false);

        // Tear Down.
        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchDocManualInclude()
    var
        PurchaseInvoiceTestPage: TestPage "Purchase Invoice";
        PurchaseOrderTestpage: TestPage "Purchase Order";
        PurchaseCreditmemoTestPage: TestPage "Purchase Credit Memo";
        PurchaseReturnOrderTestPage: TestPage "Purchase Return Order";
    begin
        // Verify EDITABLE is TRUE through pages because property is not available through record.
        // Purchase Invoice.
        PurchaseInvoiceTestPage.OpenNew();
        PurchaseInvoiceTestPage."Buy-from Vendor Name".SetValue(LibraryPurchase.CreateVendorNo());
        Assert.IsTrue(
          PurchaseInvoiceTestPage.PurchLines."Include in VAT Transac. Rep.".Editable(),
          'EDITABLE should be TRUE for the field ' + PurchaseInvoiceTestPage.PurchLines."Include in VAT Transac. Rep.".Caption);
        PurchaseInvoiceTestPage.Close();
        // Purchase Order.
        PurchaseOrderTestpage.OpenNew();
        PurchaseOrderTestpage."Buy-from Vendor Name".SetValue(LibraryPurchase.CreateVendorNo());
        Assert.IsTrue(
          PurchaseOrderTestpage.PurchLines."Include in VAT Transac. Rep.".Editable(),
          'EDITABLE should be TRUE for the field ' + PurchaseOrderTestpage.PurchLines."Include in VAT Transac. Rep.".Caption);
        PurchaseOrderTestpage.Close();
        // Purchase Credit Memo.
        PurchaseCreditmemoTestPage.OpenNew();
        PurchaseCreditmemoTestPage."Buy-from Vendor Name".SetValue(LibraryPurchase.CreateVendorNo());
        Assert.IsTrue(
          PurchaseCreditmemoTestPage.PurchLines."Include in VAT Transac. Rep.".Editable(),
          'EDITABLE should be TRUE for the field ' + PurchaseCreditmemoTestPage.PurchLines."Include in VAT Transac. Rep.".Caption);
        PurchaseCreditmemoTestPage.Close();
        // Purchase Return Order.
        PurchaseReturnOrderTestPage.OpenNew();
        PurchaseReturnOrderTestPage."Buy-from Vendor Name".SetValue(LibraryPurchase.CreateVendorNo());
        Assert.IsTrue(
          PurchaseReturnOrderTestPage.PurchLines."Include in VAT Transac. Rep.".Editable(),
          'EDITABLE should be TRUE for the field ' + PurchaseReturnOrderTestPage.PurchLines."Include in VAT Transac. Rep.".Caption);
        PurchaseReturnOrderTestPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvPostIncl()
    var
        PurchHeader: Record "Purchase Header";
    begin
        // Purch. Invoice, [Prices Including VAT] = No.
        // [Include in VAT Transac. Rep.] = Yes in VAT Posting Setup.
        // Line Amount > [Threshold Amount Excl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = Yes.
        VerifyPurchDocPostIncl(PurchHeader."Document Type"::Invoice, false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvPostExcl()
    var
        PurchHeader: Record "Purchase Header";
    begin
        // Purch. Invoice, [Prices Including VAT] = No.
        // [Include in VAT Transac. Rep.] = Yes in VAT Posting Setup.
        // Line Amount < [Threshold Amount Excl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = No.
        VerifyPurchDocPostIncl(PurchHeader."Document Type"::Invoice, false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvPostInclWVAT()
    var
        PurchHeader: Record "Purchase Header";
    begin
        // Purch. Invoice, [Prices Including VAT] = Yes.
        // [Include in VAT Transac. Rep.] = Yes in VAT Posting Setup.
        // Line Amount > [Threshold Amount Incl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = Yes.
        VerifyPurchDocPostIncl(PurchHeader."Document Type"::Invoice, true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvPostExclWVAT()
    var
        PurchHeader: Record "Purchase Header";
    begin
        // Purch. Invoice, [Prices Including VAT] = Yes.
        // [Include in VAT Transac. Rep.] = Yes in VAT Posting Setup.
        // Line Amount < [Threshold Amount Incl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = No.
        VerifyPurchDocPostIncl(PurchHeader."Document Type"::Invoice, true, false);
    end;

    local procedure VerifyPurchDocPostIncl(DocumentType: Enum "Purchase Document Type"; InclVAT: Boolean; InclInVATTransRep: Boolean)
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        LineAmount: Decimal;
        DocumentNo: Code[20];
    begin
        Initialize();

        // Setup.
        SetupThresholdAmount(WorkDate());
        LibraryVATUtils.UpdateVATPostingSetup(true);

        // Create Purch Document.
        LineAmount := CalculateAmount(WorkDate(), InclVAT, InclInVATTransRep);
        CreatePurchDocument(
          PurchHeader, PurchLine, DocumentType, CreateVendor(false, PurchHeader.Resident::Resident, true, InclVAT), LineAmount);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

        // Verify Purch Line.
        VerifyIncludeVAT(GetDocumentTypeVATEntry(DATABASE::"Purchase Header", DocumentType.AsInteger()), DocumentNo, true); // Amount is no longer compared to Threshold.

        // Tear Down.
        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchOrdWithContPostSingleLine()
    begin
        // Purchase Order linked to Blanket Order.
        // Single Line with Contact No.
        // Expected result: Contract No. copied to VAT Entry.
        VerifyPurchOrdwithContractPost(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchOrdWithContPostMultiLine()
    begin
        // Purchase Order linked to Blanket Order.
        // Multiple Lines (only one has Contact No.).
        // Expected result: Contract No. copied to VAT Entry.
        VerifyPurchOrdwithContractPost(true);
    end;

    local procedure VerifyPurchOrdwithContractPost(Multi: Boolean)
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchLine2: Record "Purchase Line";
        PurchOrderHeader: Record "Purchase Header";
        LineAmount: Decimal;
        OrderAmount: Decimal;
        DocumentNo: Code[20];
    begin
        Initialize();

        // Setup.
        SetupThresholdAmount(WorkDate());
        LibraryVATUtils.UpdateVATPostingSetup(true);

        // Calculate Amounts.
        OrderAmount := CalculateAmount(WorkDate(), false, true); // Above threshold.
        LineAmount := CalculateAmount(WorkDate(), false, false); // Below threshold.

        // Create Purchase Blanket Order.
        CreatePurchDocument(
          PurchHeader, PurchLine, PurchHeader."Document Type"::"Blanket Order", CreateVendor(false, PurchHeader.Resident::Resident, true, false),
          OrderAmount);

        // Create Purchase Order Header.
        LibraryPurchase.CreatePurchHeader(PurchOrderHeader, PurchHeader."Document Type"::Order, PurchHeader."Buy-from Vendor No.");

        // Create Purchase Line w/o Contract.
        if Multi then
            CreatePurchLine(PurchOrderHeader, PurchLine2, OrderAmount);

        // Create Purch Line and Assign Contract No.
        LibraryPurchase.CreatePurchaseLine(
          PurchLine2, PurchOrderHeader, PurchLine.Type::"G/L Account", PurchLine."No.", LibraryRandom.RandDec(10, 2));
        PurchLine2.Validate("Direct Unit Cost", LineAmount / PurchLine.Quantity);
        PurchLine2.Validate("Blanket Order No.", PurchHeader."No.");
        PurchLine2.Validate("Blanket Order Line No.", PurchLine."Line No.");
        PurchLine2.Modify(true);

        // Post Purch Order.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchOrderHeader, true, true);

        // Verify VAT Entry.
        if Multi then
            VerifyContractNo(PurchHeader."Document Type"::Invoice, DocumentNo, OrderAmount, '');
        VerifyContractNo(PurchHeader."Document Type"::Invoice, DocumentNo, PurchLine2."Line Amount", PurchHeader."No.");

        // Tear Down.
        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCMRefToBlank()
    var
        PurchHeader: Record "Purchase Header";
    begin
        // Purch Credit Memo, [Prices Including VAT] = No.
        // [Include in VAT Transac. Rep.] = Yes in VAT Posting Setup.
        // Line Amount > [Threshold Amount Excl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = Yes.
        VerifyPurchDocRefTo(PurchHeader."Document Type"::"Credit Memo", PurchHeader."Refers to Period"::" ", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCMRefToCurrent()
    var
        PurchHeader: Record "Purchase Header";
    begin
        // Purch Credit Memo, [Prices Including VAT] = No.
        // [Include in VAT Transac. Rep.] = Yes in VAT Posting Setup.
        // Line Amount > [Threshold Amount Excl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = Yes.
        // Expected Result: [Refers to Period] = Current.
        VerifyPurchDocRefTo(PurchHeader."Document Type"::"Credit Memo", PurchHeader."Refers to Period"::Current, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCMRefToCrYear()
    var
        PurchHeader: Record "Purchase Header";
    begin
        // Purch Credit Memo, [Prices Including VAT] = No.
        // [Include in VAT Transac. Rep.] = Yes in VAT Posting Setup.
        // Line Amount > [Threshold Amount Excl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = Yes.
        // Expected Result: [Refers to Period] = Current.
        VerifyPurchDocRefTo(PurchHeader."Document Type"::"Credit Memo", PurchHeader."Refers to Period"::"Current Calendar Year", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCMRefToPrevious()
    var
        PurchHeader: Record "Purchase Header";
    begin
        // Purch Credit Memo, [Prices Including VAT] = No.
        // [Include in VAT Transac. Rep.] = Yes in VAT Posting Setup.
        // Line Amount > [Threshold Amount Excl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = Yes.
        // Expected Result: [Refers to Period] = Previous.
        VerifyPurchDocRefTo(PurchHeader."Document Type"::"Credit Memo", PurchHeader."Refers to Period"::"Previous Calendar Year", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchRtnOrdRefToCurrent()
    var
        PurchHeader: Record "Purchase Header";
    begin
        // Purch Credit Memo, [Prices Including VAT] = No.
        // [Include in VAT Transac. Rep.] = Yes in VAT Posting Setup.
        // Line Amount > [Threshold Amount Excl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = Yes.
        // Expected Result: [Refers to Period] = Current.
        VerifyPurchDocRefTo(PurchHeader."Document Type"::"Return Order", PurchHeader."Refers to Period"::Current, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchRtnOrdRefToCrYear()
    var
        PurchHeader: Record "Purchase Header";
    begin
        // Purch Credit Memo, [Prices Including VAT] = No.
        // [Include in VAT Transac. Rep.] = Yes in VAT Posting Setup.
        // Line Amount > [Threshold Amount Excl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = Yes.
        // Expected Result: [Refers to Period] = Current.
        VerifyPurchDocRefTo(PurchHeader."Document Type"::"Return Order", PurchHeader."Refers to Period"::"Current Calendar Year", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchRtnOrdRefToPrevious()
    var
        PurchHeader: Record "Purchase Header";
    begin
        // Purch Return Order, [Prices Including VAT] = No.
        // [Include in VAT Transac. Rep.] = Yes in VAT Posting Setup.
        // Line Amount > [Threshold Amount Excl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = Yes.
        // Expected Result: [Refers to Period] = Previous.
        VerifyPurchDocRefTo(PurchHeader."Document Type"::"Return Order", PurchHeader."Refers to Period"::"Previous Calendar Year", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCMLineRefToCurrent()
    var
        PurchHeader: Record "Purchase Header";
    begin
        // Purch Credit Memo, [Prices Including VAT] = No.
        // [Include in VAT Transac. Rep.] = Yes in VAT Posting Setup.
        // Line Amount > [Threshold Amount Excl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = Yes.
        // Expected Result: [Refers to Period] = Current.
        VerifyPurchDocRefTo(PurchHeader."Document Type"::"Credit Memo", PurchHeader."Refers to Period"::Current, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCMLineRefToCrYear()
    var
        PurchHeader: Record "Purchase Header";
    begin
        // Purch Credit Memo, [Prices Including VAT] = No.
        // [Include in VAT Transac. Rep.] = Yes in VAT Posting Setup.
        // Line Amount > [Threshold Amount Excl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = Yes.
        // Expected Result: [Refers to Period] = Current.
        VerifyPurchDocRefTo(PurchHeader."Document Type"::"Credit Memo", PurchHeader."Refers to Period"::"Current Calendar Year", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchRtnOrdLineRefToPrevious()
    var
        PurchHeader: Record "Purchase Header";
    begin
        // Purch Return Order, [Prices Including VAT] = No.
        // [Include in VAT Transac. Rep.] = Yes in VAT Posting Setup.
        // Line Amount > [Threshold Amount Excl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = Yes.
        // Expected Result: [Refers to Period] = Previous.
        VerifyPurchDocRefTo(PurchHeader."Document Type"::"Return Order", PurchHeader."Refers to Period"::"Previous Calendar Year", true);
    end;

    local procedure VerifyPurchDocRefTo(DocumentType: Enum "Purchase Document Type"; RefersToPeriod: Option; UpdateLine: Boolean)
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        LineAmount: Decimal;
        DocumentNo: Code[20];
    begin
        // [Prices Including VAT] = No.
        // Line Amount > [Threshold Amount Excl. VAT.].
        Initialize();

        // Setup.
        SetupThresholdAmount(WorkDate());
        LibraryVATUtils.UpdateVATPostingSetup(true);

        // Create Purch Document.
        LineAmount := CalculateAmount(WorkDate(), false, true);

        // Create Purchase Header.
        LibraryPurchase.CreatePurchHeader(PurchHeader, DocumentType, CreateVendor(false, PurchHeader.Resident::Resident, true, false));
        PurchHeader.Validate("Vendor Cr. Memo No.", PurchHeader."No.");

        // Update Refers to Period on Header.
        PurchHeader.Validate("Refers to Period", RefersToPeriod);
        PurchHeader.Modify(true);

        // Create Purch. Line.
        CreatePurchLine(PurchHeader, PurchLine, LineAmount);

        // Update Refers to Period on Line.
        if UpdateLine then begin
            PurchLine.Validate("Refers to Period", RefersToPeriod);
            PurchLine.Modify(true);
        end;

        // Post Purch Document.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

        // Verify Posted Purch Cr. Memo and VAT Entry.
        if UpdateLine then
            VerifyRefersToPeriod(DATABASE::"Purch. Cr. Memo Line", DocumentNo, RefersToPeriod)
        else
            VerifyRefersToPeriod(DATABASE::"Purch. Cr. Memo Hdr.", DocumentNo, RefersToPeriod);

        // Verify VAT Entry.
        VerifyIncludeVAT(GetDocumentTypeVATEntry(DATABASE::"Purchase Header", DocumentType.AsInteger()), DocumentNo, true);

        // Tear Down.
        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchOrdPrep()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        VATEntry: Record "VAT Entry";
        LineAmount: Decimal;
        DocumentNo: Code[20];
        PrepDocumentNo: Code[20];
    begin
        // [Prices Including VAT] = No.
        // Line Amount > [Threshold Amount Excl. VAT.].
        Initialize();

        // Setup.
        SetupThresholdAmount(WorkDate());
        LibraryVATUtils.UpdateVATPostingSetup(true);
        SetupPrepayments();

        // Create Sales Document.
        LineAmount := CalculateAmount(WorkDate(), false, true);

        // Create Sales Header.
        LibraryPurchase.CreatePurchHeader(
          PurchHeader, PurchHeader."Document Type"::Order, CreateVendor(false, PurchHeader.Resident::Resident, true, false));
        PurchHeader.Validate("Prepayment %", LibraryRandom.RandInt(50)); // Prepayment below the Threshold
        PurchHeader.Validate("Prepayment Due Date", PurchHeader."Posting Date");
        PurchHeader.Modify(true);

        // Create Sales Line.
        CreatePurchLine(PurchHeader, PurchLine, LineAmount);

        // Post Prepayment Invoice.
        PrepDocumentNo := PostPurchPrepInvoice(PurchHeader);

        // Post Purchase Document.
        DocumentNo := PostPurchOrder(PurchHeader);

        // Verify VAT Entry.
        FindVATEntry(VATEntry, VATEntry."Document Type"::Invoice, PrepDocumentNo);
        VATEntry.TestField("Include in VAT Transac. Rep.", false); // Prepayment Invoice VAT.

        VATEntry.SetFilter(Base, '>0');
        FindVATEntry(VATEntry, VATEntry."Document Type"::Invoice, DocumentNo);
        VATEntry.TestField("Include in VAT Transac. Rep.", true); // Invoice VAT.

        VATEntry.SetFilter(Base, '<0');
        FindVATEntry(VATEntry, VATEntry."Document Type"::Invoice, DocumentNo);
        VATEntry.TestField("Include in VAT Transac. Rep.", false); // Reverse of Prepayment Invoice VAT.

        // Tear Down.
        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendTaxRepContact()
    var
        Vendor: Record Vendor;
    begin
        VendTaxRep(Vendor."Tax Representative Type"::Contact);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendTaxRepVend()
    var
        Vendor: Record Vendor;
    begin
        VendTaxRep(Vendor."Tax Representative Type"::Vendor);
    end;

    local procedure VendTaxRep(TaxRepType: Option)
    var
        Vendor: Record Vendor;
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        VATEntry: Record "VAT Entry";
        Amount: Decimal;
        DocumentNo: Code[20];
        TaxRepNo: Code[20];
        ExpectedTaxRepType: Option;
    begin
        Initialize();

        // Create Vendor.
        Vendor.Get(CreateVendor(false, Vendor.Resident::"Non-Resident", false, false));

        // Set Tax Representative Type & No.
        case TaxRepType of
            Vendor."Tax Representative Type"::Contact:
                begin
                    TaxRepNo := CreateContact();
                    ExpectedTaxRepType := VATEntry."Tax Representative Type"::Contact;
                end;
            Vendor."Tax Representative Type"::Vendor:
                begin
                    TaxRepNo := CreateVendor(false, Vendor.Resident::Resident, true, true);
                    ExpectedTaxRepType := VATEntry."Tax Representative Type"::Vendor;
                end;
        end;
        Vendor.Validate("Tax Representative Type", TaxRepType);
        Vendor.Validate("Tax Representative No.", TaxRepNo);
        Vendor.Modify(true);

        // Create Purchase Document.
        Amount := LibraryRandom.RandDec(10000, 2);
        CreatePurchDocument(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, Vendor."No.", Amount);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

        // Verify VAT Entry.
        VerifyTaxRep(
          GetDocumentTypeVATEntry(DATABASE::"Purchase Header", PurchHeader."Document Type".AsInteger()), DocumentNo, ExpectedTaxRepType, TaxRepNo);

        // Tear Down.
        TearDown();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure InvIndVendResFiscalCode()
    var
        Vendor: Record Vendor;
        PurchHeader: Record "Purchase Header";
    begin
        VerifyPurchDocReqFields(PurchHeader."Document Type"::Invoice, true, Vendor.Resident::Resident, Vendor.FieldNo("Fiscal Code"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvIndVendNonResCountryRegion()
    var
        Vendor: Record Vendor;
        PurchHeader: Record "Purchase Header";
    begin
        VerifyPurchDocReqFields(
          PurchHeader."Document Type"::Invoice, true, Vendor.Resident::"Non-Resident", Vendor.FieldNo("Country/Region Code"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvIndVendNonResFirstName()
    var
        Vendor: Record Vendor;
        PurchHeader: Record "Purchase Header";
    begin
        VerifyPurchDocReqFields(PurchHeader."Document Type"::Invoice, true, Vendor.Resident::"Non-Resident", Vendor.FieldNo("First Name"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvIndVendNonResLastName()
    var
        Vendor: Record Vendor;
        PurchHeader: Record "Purchase Header";
    begin
        VerifyPurchDocReqFields(PurchHeader."Document Type"::Invoice, true, Vendor.Resident::"Non-Resident", Vendor.FieldNo("Last Name"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvIndVendNonResDateOfBirth()
    var
        Vendor: Record Vendor;
        PurchHeader: Record "Purchase Header";
    begin
        VerifyPurchDocReqFields(
          PurchHeader."Document Type"::Invoice, true, Vendor.Resident::"Non-Resident", Vendor.FieldNo("Date of Birth"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvIndVendNonResBirthCity()
    var
        Vendor: Record Vendor;
        PurchHeader: Record "Purchase Header";
    begin
        VerifyPurchDocReqFields(PurchHeader."Document Type"::Invoice, true, Vendor.Resident::"Non-Resident", Vendor.FieldNo("Birth City"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvKnVendResVATRegNo()
    var
        Vendor: Record Vendor;
        PurchHeader: Record "Purchase Header";
    begin
        VerifyPurchDocReqFields(
          PurchHeader."Document Type"::Invoice, false, Vendor.Resident::"Non-Resident", Vendor.FieldNo("VAT Registration No."));
    end;

    local procedure VerifyPurchDocReqFields(DocumentType: Enum "Purchase Document Type"; IndividualPerson: Boolean; Resident: Option; FieldId: Integer)
    var
        Vendor: Record Vendor;
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        FieldRef: FieldRef;
        RecordRef: RecordRef;
        LineAmount: Decimal;
        ExpectedError: Text;
    begin
        Initialize();

        // Setup.
        SetupThresholdAmount(WorkDate());
        LibraryVATUtils.UpdateVATPostingSetup(true);

        // Calculate Line Amount (Excl. VAT).
        LineAmount := CalculateAmount(WorkDate(), false, true);

        // Create Vendor.
        Vendor.Get(CreateVendor(IndividualPerson, Resident, true, false));

        // Remove Value from Field under test.
        RecordRef.GetTable(Vendor);
        FieldRef := RecordRef.Field(FieldId);
        ClearField(RecordRef, FieldRef);

        // Create Purchase Document.
        CreatePurchDocument(PurchHeader, PurchLine, DocumentType, Vendor."No.", LineAmount);

        // Try to Post Purchase Document.
        asserterror LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

        // Verify Error Message.
        if FieldId = Vendor.FieldNo("Country/Region Code") then
            ExpectedError := StrSubstNo(YouMustSpecifyValueErr, PurchHeader.FieldCaption("Buy-from Country/Region Code"))
        else
            ExpectedError := StrSubstNo(YouMustSpecifyValueErr, FindFieldCaption(DATABASE::"Purchase Header", FieldRef.Name));
        Assert.ExpectedError(ExpectedError);

        // Tear Down.
        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvIndVendResExclVATRep()
    var
        Vendor: Record Vendor;
        PurchHeader: Record "Purchase Header";
    begin
        VerifyPurchDocReqFieldsExcl(PurchHeader."Document Type"::Invoice, true, Vendor.Resident::Resident);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvIndVendNonResExclVATRep()
    var
        Vendor: Record Vendor;
        PurchHeader: Record "Purchase Header";
    begin
        VerifyPurchDocReqFieldsExcl(PurchHeader."Document Type"::Invoice, true, Vendor.Resident::"Non-Resident");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvKnVendResExclVATRep()
    var
        Vendor: Record Vendor;
        PurchHeader: Record "Purchase Header";
    begin
        VerifyPurchDocReqFieldsExcl(PurchHeader."Document Type"::Invoice, false, Vendor.Resident::"Non-Resident");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchPrePayInvPost()
    var
        PurchHeader: Record "Purchase Header";
    begin
        VerifyPrePayPurchDocPostIncl(PurchHeader."Document Type"::Order, false, true);
    end;

    local procedure VerifyPurchDocReqFieldsExcl(DocumentType: Enum "Purchase Document Type"; IndividualPerson: Boolean; Resident: Option)
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        LineAmount: Decimal;
    begin
        Initialize();

        // Setup.
        SetupThresholdAmount(WorkDate());
        LibraryVATUtils.UpdateVATPostingSetup(false);

        // Calculate Line Amount (Excl. VAT).
        LineAmount := CalculateAmount(WorkDate(), false, true);

        // Create Purchase Document.
        CreatePurchDocument(PurchHeader, PurchLine, DocumentType, CreateVendor(IndividualPerson, Resident, false, false), LineAmount);

        // Post Purchase Document (no error message).
        LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

        // Tear Down.
        TearDown();
    end;

    local procedure VerifyPrePayPurchDocPostIncl(DocumentType: Enum "Purchase Document Type"; InclVAT: Boolean; InclInVATTransRep: Boolean)
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        LineAmount: Decimal;
        DocumentNo: Code[20];
    begin
        Initialize();

        // Setup.
        SetupThresholdAmount(WorkDate());
        LibraryVATUtils.UpdateVATPostingSetup(true);
        SetupPrepayments();

        // Create Sales Document. // WORKING
        LineAmount := CalculateAmount(WorkDate(), InclVAT, InclInVATTransRep);

        // Create Sales Header.
        LibraryPurchase.CreatePurchHeader(PurchHeader, DocumentType, CreateVendor(false, PurchHeader.Resident::Resident, true, false));
        PurchHeader.Validate("Prepayment %", LibraryRandom.RandInt(50)); // Prepayment below the Threshold
        PurchHeader.Validate("Prepayment Due Date", PurchHeader."Posting Date");
        PurchHeader.Modify(true);

        // Create Sales Line.
        CreatePurchLine(PurchHeader, PurchLine, LineAmount);

        // Post the pre-payment invoice
        DocumentNo := PostPurchPrepInvoice(PurchHeader);

        // Verify Sales Line.
        VerifyIncludeVAT(GetDocumentTypeVATEntry(DATABASE::"Purchase Header", DocumentType.AsInteger()), DocumentNo, false); // Amount is no longer compared to Threshold.

        // Tear Down.
        TearDown();
    end;

    local procedure Initialize()
    begin
        TearDown(); // Cleanup.
        LibraryVariableStorage.Clear();

        if isInitialized then
            exit;

        isInitialized := true;
        CreateVATReportSetup();
        Commit();

        TearDown(); // Cleanup for the first test.
    end;

    local procedure CalculateAmount(StartingDate: Date; InclVAT: Boolean; InclInVATTransRep: Boolean) Amount: Decimal
    var
        Delta: Decimal;
    begin
        // Random delta should be less than difference between Threshold Incl. VAT and Excl. VAT.
        Delta := LibraryRandom.RandDec(GetThresholdAmount(StartingDate, true) - GetThresholdAmount(StartingDate, false), 2);

        if not InclInVATTransRep then
            Delta := -Delta;

        Amount := GetThresholdAmount(StartingDate, InclVAT) + Delta;
    end;

    local procedure ClearField(RecordRef: RecordRef; FieldRef: FieldRef)
    var
        FieldRef2: FieldRef;
        RecordRef2: RecordRef;
    begin
        RecordRef2.Open(RecordRef.Number, true); // Open temp table.
        FieldRef2 := RecordRef2.Field(FieldRef.Number);

        FieldRef.Validate(FieldRef2.Value); // Clear field value.
        RecordRef.Modify(true);
    end;

    local procedure CreateContact(): Code[20]
    var
        Contact: Record Contact;
    begin
        LibraryMarketing.CreateCompanyContact(Contact);
        Contact.Validate(
          "VAT Registration No.", LibraryUtility.GenerateRandomCode(Contact.FieldNo("VAT Registration No."), DATABASE::Contact));
        Contact.Modify(true);
        exit(Contact."No.");
    end;

    local procedure CreateCountry(): Code[10]
    var
        CountryRegion: Record "Country/Region";
    begin
        LibraryERM.CreateCountryRegion(CountryRegion);
        CountryRegion.Validate("Intrastat Code", CountryRegion.Code); // Fill with Country Code as value is not important for test.
        CountryRegion.Modify(true);
        exit(CountryRegion.Code);
    end;

    local procedure CreateGLAccount(GenPostingType: Enum "General Posting Type"): Code[20]
    var
        GLAccount: Record "G/L Account";
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        VATPostingSetup.SetRange("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT"); // Always use Normal for G/L Accounts.
        if not FindVATPostingSetup(VATPostingSetup, true) then
            FindVATPostingSetup(VATPostingSetup, false);

        // Gen. Posting Type, Gen. Bus. and VAT Bus. Posting Groups are required for General Journal.
        if GenPostingType <> GLAccount."Gen. Posting Type"::" " then begin
            GLAccount.Validate("Gen. Posting Type", GenPostingType);
            GLAccount.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
            GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        end;
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreatePurchDocument(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20]; LineAmount: Decimal)
    begin
        // Create Purch. Header.
        CreatePurchHeader(PurchHeader, DocumentType, VendorNo);

        // Create Purch. Line.
        CreatePurchLine(PurchHeader, PurchLine, LineAmount);

        // Fill Total.
        UpdateCheckTotal(PurchHeader, LineAmount);
    end;

    local procedure CreatePurchHeader(var PurchHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20])
    begin
        // Create Purch. Header.
        LibraryPurchase.CreatePurchHeader(PurchHeader, DocumentType, VendorNo);
        if (DocumentType = PurchHeader."Document Type"::"Credit Memo") or
           (DocumentType = PurchHeader."Document Type"::"Return Order")
        then begin
            PurchHeader.Validate("Vendor Cr. Memo No.", PurchHeader."No.");
            PurchHeader.Modify(true);
        end;
    end;

    local procedure CreatePurchLine(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; LineAmount: Decimal)
    var
        GLAccount: Record "G/L Account";
    begin
        // Create Purch. Line.
        LibraryPurchase.CreatePurchaseLine(
          PurchLine, PurchHeader, PurchLine.Type::"G/L Account", CreateGLAccount(GLAccount."Gen. Posting Type"::" "),
          LibraryRandom.RandDec(10, 2));
        PurchLine.Validate("Direct Unit Cost", LineAmount / PurchLine.Quantity);
        PurchLine.Modify(true);
    end;

    local procedure CreateVendor(IndividualPerson: Boolean; Resident: Option; ReqFlds: Boolean; PricesInclVAT: Boolean): Code[20]
    var
        Vendor: Record Vendor;
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        if not FindVATPostingSetup(VATPostingSetup, true) then
            FindVATPostingSetup(VATPostingSetup, false);
        Vendor.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Vendor.Validate("Individual Person", IndividualPerson);
        Vendor.Validate(Resident, Resident);

        if ReqFlds then begin
            if Resident = Vendor.Resident::"Non-Resident" then
                Vendor.Validate("Country/Region Code", GetCountryCode());

            if not IndividualPerson then
                Vendor.Validate(
                  "VAT Registration No.",
                  CopyStr(
                    LibraryUtility.GenerateRandomCode(Vendor.FieldNo("VAT Registration No."), DATABASE::Vendor), 1,
                    LibraryUtility.GetFieldLength(DATABASE::Vendor, Vendor.FieldNo("VAT Registration No."))))
            else
                case Resident of
                    Vendor.Resident::Resident:
                        Vendor.Validate(
                          "Fiscal Code",
                          CopyStr(
                            LibraryUtility.GenerateRandomCode(Vendor.FieldNo("Fiscal Code"), DATABASE::Vendor), 1,
                            LibraryUtility.GetFieldLength(DATABASE::Vendor, Vendor.FieldNo("Fiscal Code"))));
                    Vendor.Resident::"Non-Resident":
                        begin
                            Vendor.Validate("First Name", LibraryUtility.GenerateRandomCode(Vendor.FieldNo("First Name"), DATABASE::Vendor));
                            Vendor.Validate("Last Name", LibraryUtility.GenerateRandomCode(Vendor.FieldNo("Last Name"), DATABASE::Vendor));
                            Vendor.Validate("Date of Birth", CalcDate('<-' + Format(LibraryRandom.RandInt(100)) + 'Y>'));
                            Vendor.Validate("Birth City", LibraryUtility.GenerateRandomCode(Vendor.FieldNo("Birth City"), DATABASE::Vendor));
                        end;
                end;
        end;

        Vendor.Validate("Prices Including VAT", PricesInclVAT);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateVATReportSetup()
    var
        VATReportSetup: Record "VAT Report Setup";
    begin
        // Create VAT Report Setup.
        if VATReportSetup.IsEmpty() then
            VATReportSetup.Insert(true);
        VATReportSetup.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        VATReportSetup.Modify(true);
    end;

    local procedure CreateVATTransReportAmount(var VATTransRepAmount: Record "VAT Transaction Report Amount"; StartingDate: Date)
    begin
        VATTransRepAmount.Init();
        VATTransRepAmount.Validate("Starting Date", StartingDate);
        VATTransRepAmount.Insert(true);
    end;

    local procedure EnableUnrealizedVAT(UnrealVAT: Boolean)
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        GLSetup.Validate("Unrealized VAT", UnrealVAT);
        GLSetup.Modify(true);
    end;

    local procedure FindFieldCaption(TableNo: Integer; FieldName: Text[30]): Text
    var
        "Field": Record "Field";
    begin
        Field.SetRange(TableNo, TableNo);
        Field.SetRange(FieldName, FieldName);
        Field.FindFirst();
        exit(Field."Field Caption");
    end;

    local procedure GetCountryCode(): Code[10]
    var
        CompanyInformation: Record "Company Information";
        CountryRegion: Record "Country/Region";
    begin
        CompanyInformation.Get();
        CountryRegion.SetFilter(Code, '<>%1', CompanyInformation."Country/Region Code");
        CountryRegion.SetFilter("Intrastat Code", '');
        LibraryERM.FindCountryRegion(CountryRegion);
        exit(CountryRegion.Code);
    end;

    local procedure GetDocumentTypeVATEntry(TableNo: Option; DocumentType: Option) DocumentTypeVATEntry: Enum "Gen. Journal Document Type"
    var
        PurchHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        ServiceHeader: Record "Service Header";
        VATEntry: Record "VAT Entry";
    begin
        case TableNo of
            DATABASE::"Gen. Journal Line":
                DocumentTypeVATEntry := "Gen. Journal Document Type".FromInteger(DocumentType);
            DATABASE::"Sales Header":
                case DocumentType of
                    SalesHeader."Document Type"::Invoice.AsInteger(),
                    SalesHeader."Document Type"::Order.AsInteger():
                        DocumentTypeVATEntry := VATEntry."Document Type"::Invoice;
                    SalesHeader."Document Type"::"Credit Memo".AsInteger(),
                    SalesHeader."Document Type"::"Return Order".AsInteger():
                        DocumentTypeVATEntry := VATEntry."Document Type"::"Credit Memo";
                end;
            DATABASE::"Service Header":
                case DocumentType of
                    ServiceHeader."Document Type"::Invoice.AsInteger(),
                    ServiceHeader."Document Type"::Order.AsInteger():
                        DocumentTypeVATEntry := VATEntry."Document Type"::Invoice;
                    ServiceHeader."Document Type"::"Credit Memo".AsInteger():
                        DocumentTypeVATEntry := VATEntry."Document Type"::"Credit Memo";
                end;
            DATABASE::"Purchase Header":
                case DocumentType of
                    PurchHeader."Document Type"::Invoice.AsInteger(),
                    PurchHeader."Document Type"::Order.AsInteger():
                        DocumentTypeVATEntry := VATEntry."Document Type"::Invoice;
                    PurchHeader."Document Type"::"Credit Memo".AsInteger(),
                    PurchHeader."Document Type"::"Return Order".AsInteger():
                        DocumentTypeVATEntry := VATEntry."Document Type"::"Credit Memo";
                end;
        end;
    end;

    local procedure GetThresholdAmount(StartingDate: Date; InclVAT: Boolean) Amount: Decimal
    var
        VATTransactionReportAmount: Record "VAT Transaction Report Amount";
    begin
        VATTransactionReportAmount.SetFilter("Starting Date", '<=%1', StartingDate);
        VATTransactionReportAmount.FindLast();

        if InclVAT then
            Amount := VATTransactionReportAmount."Threshold Amount Incl. VAT"
        else
            Amount := VATTransactionReportAmount."Threshold Amount Excl. VAT";
    end;

    local procedure FindPurchLine(var PurchLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; DocumentNo: Code[20])
    begin
        PurchLine.SetRange("Document Type", DocumentType);
        PurchLine.SetFilter("Document No.", DocumentNo);
        PurchLine.FindFirst();
    end;

    local procedure FindVATEntry(var VATEntry: Record "VAT Entry"; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    begin
        VATEntry.SetRange("Document Type", DocumentType);
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.FindSet();
    end;

    local procedure FindVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; IncludeInVATTransacRep: Boolean): Boolean
    begin
        VATPostingSetup.SetFilter("VAT Bus. Posting Group", '<>%1', '''''');
        VATPostingSetup.SetFilter("VAT Prod. Posting Group", '<>%1', '''''');
        VATPostingSetup.SetRange("VAT %", LibraryVATUtils.FindMaxVATRate(VATPostingSetup."VAT Calculation Type"::"Normal VAT"));
        VATPostingSetup.SetRange("Include in VAT Transac. Rep.", IncludeInVATTransacRep);
        VATPostingSetup.SetRange("Deductible %", 100);
        exit(VATPostingSetup.FindFirst())
    end;

    local procedure MakeOrderPurchase(var PurchHeader: Record "Purchase Header"; var PurchOrderHeader: Record "Purchase Header")
    var
        BlanketPurchOrderToOrder: Codeunit "Blanket Purch. Order to Order";
    begin
        BlanketPurchOrderToOrder.Run(PurchHeader);
        BlanketPurchOrderToOrder.GetPurchOrderHeader(PurchOrderHeader);
    end;

    local procedure PostPurchOrder(var PurchHeader: Record "Purchase Header") DocumentNo: Code[20]
    var
        PurchLine: Record "Purchase Line";
        NoSeries: Codeunit "No. Series";
        NoSeriesCode: Code[20];
    begin
        PurchHeader.Find(); // Required to avoid Another user has modified the record error.
        PurchHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        PurchHeader.Validate(Receive, true);
        PurchHeader.Validate(Invoice, true);

        FindPurchLine(PurchLine, PurchHeader."Document Type", PurchHeader."No.");
        UpdateCheckTotal(PurchHeader, PurchLine."Amount Including VAT" - PurchLine."Prepmt. Amt. Incl. VAT");

        NoSeriesCode := PurchHeader."Posting No. Series";
        DocumentNo := NoSeries.PeekNextNo(NoSeriesCode);
        CODEUNIT.Run(CODEUNIT::"Purch.-Post", PurchHeader);
    end;

    local procedure PostPurchPrepInvoice(PurchHeader: Record "Purchase Header"): Code[20]
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchLine: Record "Purchase Line";
        PurchPostPrepayments: Codeunit "Purchase-Post Prepayments";
    begin
        FindPurchLine(PurchLine, PurchHeader."Document Type", PurchHeader."No.");
        UpdateCheckTotal(PurchHeader, Round(PurchLine."Prepmt. Line Amount" / 100 * (100 + PurchLine."VAT %")));
        PurchPostPrepayments.Invoice(PurchHeader);
        PurchInvHeader.SetRange("Prepayment Order No.", PurchHeader."No.");
        PurchInvHeader.FindFirst();
        exit(PurchInvHeader."No.");
    end;

    local procedure SetupThresholdAmount(StartingDate: Date)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATTransRepAmount: Record "VAT Transaction Report Amount";
        ThresholdAmount: Decimal;
        VATRate: Decimal;
    begin
        // Law States Threshold Incl. VAT as 3600 and Threshold Excl. VAT as 3000.
        // For test purpose Threshold Excl. VAT is generated randomly in 1000..10000 range.
        CreateVATTransReportAmount(VATTransRepAmount, StartingDate);
        VATRate := LibraryVATUtils.FindMaxVATRate(VATPostingSetup."VAT Calculation Type"::"Normal VAT");

        ThresholdAmount := 1000 * LibraryRandom.RandInt(10);
        VATTransRepAmount.Validate("Threshold Amount Incl. VAT", ThresholdAmount * (1 + VATRate / 100));
        VATTransRepAmount.Validate("Threshold Amount Excl. VAT", ThresholdAmount);

        VATTransRepAmount.Modify(true);
    end;

    local procedure SetupPrepayments()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.SetRange("Include in VAT Transac. Rep.", true);
        VATPostingSetup.FindFirst();
        VATPostingSetup.Validate("Sales Prepayments Account", CreateGLAccount("General Posting Type"::" "));
        VATPostingSetup.Validate("Purch. Prepayments Account", CreateGLAccount("General Posting Type"::" "));
        VATPostingSetup.Modify(true);
    end;

    local procedure UpdateCheckTotal(var PurchHeader: Record "Purchase Header"; CheckTotal: Decimal)
    begin
        PurchHeader.Validate("Check Total", CheckTotal);
        PurchHeader.Modify(true);
    end;

    local procedure VerifyContractNo(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; Base: Decimal; ContractNo: Code[20])
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document Type", DocumentType);
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.SetRange(Base, Base);
        VATEntry.FindSet();
        repeat
            VATEntry.TestField("Contract No.", ContractNo);
        until VATEntry.Next() = 0;
    end;

    local procedure VerifyIncludeVAT(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; InclInVATTransRep: Boolean)
    var
        VATEntry: Record "VAT Entry";
    begin
        FindVATEntry(VATEntry, DocumentType, DocumentNo);
        repeat
            VATEntry.TestField("Include in VAT Transac. Rep.", InclInVATTransRep);
        until VATEntry.Next() = 0;
    end;

    local procedure VerifyRefersToPeriod(TableID: Option; DocumentNo: Code[20]; RefersToPeriod: Option)
    var
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        VATEntry: Record "VAT Entry";
    begin
        case TableID of
            DATABASE::"Sales Cr.Memo Header":
                begin
                    SalesCrMemoHeader.Get(DocumentNo);
                    SalesCrMemoHeader.TestField("Refers to Period", RefersToPeriod);
                end;
            DATABASE::"Purch. Cr. Memo Hdr.":
                begin
                    PurchCrMemoHeader.Get(DocumentNo);
                    PurchCrMemoHeader.TestField("Refers to Period", RefersToPeriod);
                end;
            DATABASE::"Sales Cr.Memo Line":
                begin
                    SalesCrMemoLine.SetRange("Document No.", DocumentNo);
                    SalesCrMemoLine.FindFirst();
                    SalesCrMemoLine.TestField("Refers to Period", RefersToPeriod);
                end;
            DATABASE::"Purch. Cr. Memo Line":
                begin
                    PurchCrMemoLine.SetRange("Document No.", DocumentNo);
                    PurchCrMemoLine.FindFirst();
                    PurchCrMemoLine.TestField("Refers to Period", RefersToPeriod);
                end;
        end;

        FindVATEntry(VATEntry, VATEntry."Document Type"::"Credit Memo", DocumentNo);
        repeat
            VATEntry.TestField("Refers To Period", RefersToPeriod);
        until VATEntry.Next() = 0;
    end;

    local procedure VerifyTaxRep(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; TaxRepType: Option; TaxRepNo: Code[20])
    var
        VATEntry: Record "VAT Entry";
    begin
        FindVATEntry(VATEntry, DocumentType, DocumentNo);
        repeat
            VATEntry.TestField("Tax Representative Type", TaxRepType);
            VATEntry.TestField("Tax Representative No.", TaxRepNo);
        until VATEntry.Next() = 0;
    end;

    local procedure TearDown()
    var
        VATTransRepAmount: Record "VAT Transaction Report Amount";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.SetRange("Include in VAT Transac. Rep.", true);
        VATPostingSetup.ModifyAll("Sales Prepayments Account", '', true);
        VATPostingSetup.ModifyAll("Purch. Prepayments Account", '', true);
        VATPostingSetup.ModifyAll("Include in VAT Transac. Rep.", false, true);

        VATPostingSetup.Reset();
        VATPostingSetup.SetFilter("Unrealized VAT Type", '<>%1', VATPostingSetup."Unrealized VAT Type"::" ");
        VATPostingSetup.ModifyAll("Sales VAT Unreal. Account", '', true);
        VATPostingSetup.ModifyAll("Purch. VAT Unreal. Account", '', true);
        VATPostingSetup.ModifyAll("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::" ", true);

        VATTransRepAmount.DeleteAll(true);
        EnableUnrealizedVAT(false);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Just for Handle the Message.
    end;
}

