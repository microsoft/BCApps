codeunit 147131 "ERM Purchase VAT Ledger"
{
    // // [FEATURE] [UT] [VAT Ledger] [Purchase]

    TestPermissions = NonRestrictive;
    Subtype = Test;
    Permissions = tabledata "VAT Entry" = imd,
                  tabledata "Vendor Ledger Entry" = imd,
                  tabledata "Purch. Inv. Header" = imd,
                  tabledata "Detailed Vendor Ledg. Entry" = imd;

    var
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRUReports: Codeunit "Library RU Reports";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        Assert: Codeunit Assert;
        VATLedgerMgt: Codeunit "VAT Ledger Management";
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure PurchVATEntry()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Vendor: Record Vendor;
        VATLedgerCode: Code[20];
    begin
        // [SCENARIO] Purchase VAT Ledger Line is created when run REP12455 "Create VAT Purchase Ledger" for vendor
        Initialize();
        LibraryRUReports.UpdateCompanyInfo();
        LibraryRUReports.CreateVendor(Vendor);

        // [GIVEN] Posted VAT Entry for vendor "V" with "Full Name" = "X" (250 chars length), "VAT Registration No." = "Y", "KPP Code" = "Z"
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", VATLedgerMgt.GetVATPctRate2019());
        MockPurchaseVATEntry(VATPostingSetup, Vendor."No.", WorkDate(), WorkDate());

        // [WHEN] Run "Create VAT Purchase Ledger" report for vendor "V"
        VATLedgerCode := LibraryPurchase.CreatePurchaseVATLedger(WorkDate(), WorkDate(), Vendor."No.", false, true);

        // [THEN] Purchase VAT Ledger Line is created with following details:
        // [THEN] "C/V No." = "V"
        // [THEN] "C/V Name" = "X" (TFS 378389), 250 chars length (TFS 378853)
        // [THEN] "C/V VAT Reg. No." = "Y"
        // [THEN] "Reg. Reason Code" = "Z"
        VerifyPurchaseVATLedgerLineCount(VATLedgerCode, Vendor."No.", 1);
        VerifyPurchaseVATLedgerLineVendorDetails(VATLedgerCode, Vendor."No.");

        // Tear Down
        Vendor.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchPrepmtVATEntry()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VendorNo: Code[20];
        VATLedgerCode: Code[20];
    begin
        Initialize();

        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", VATLedgerMgt.GetVATPctRate2019());
        VendorNo := LibraryPurchase.CreateVendorNo();
        CreatePurchPrepmtVATEntry(VATPostingSetup, VendorNo, WorkDate(), WorkDate());

        // Excercise:
        VATLedgerCode := LibraryPurchase.CreatePurchaseVATLedger(WorkDate(), WorkDate(), VendorNo, false, true);

        // Verify:
        VerifyPurchaseVATLedgerLineCount(VATLedgerCode, VendorNo, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPrepmtVATEntry()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Customer: Record Customer;
        VATLedgerCode: Code[20];
    begin
        // [FEATURE] [Sales] [Prepayment]
        // [SCENARIO] Purchase VAT Ledger Line is created when run REP12455 "Create VAT Purchase Ledger" for customer with "Prepayment" vat entry
        Initialize();
        LibraryRUReports.UpdateCompanyInfo();
        LibraryRUReports.CreateCustomer(Customer);

        // [GIVEN] Posted prepayment VAT Entry for customer "C"
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", VATLedgerMgt.GetVATPctRate2019());
        CreateSalesPrepmtVATEntry(VATPostingSetup, Customer."No.", WorkDate(), WorkDate());

        // [WHEN] Run "Create VAT Purchase Ledger" report for customer "C"
        VATLedgerCode := LibraryPurchase.CreatePurchaseVATLedger(WorkDate(), WorkDate(), Customer."No.", false, true);

        // [THEN] Purchase VAT Ledger Line is created with following details:
        // [THEN] "C/V No." = "C"
        // [THEN] "C/V Name" = <CompanyName>
        // [THEN] "C/V VAT Reg. No." = <Company VAT Registration No.>
        // [THEN] "Reg. Reason Code" = <Company KPP Code>
        VerifyPurchaseVATLedgerLineCount(VATLedgerCode, Customer."No.", 1);
        VerifyPurchaseVATLedgerLineCompanyDetails(VATLedgerCode, Customer."No.");

        // Tear Down
        Customer.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesReturnVATEntry()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        CustomerNo: Code[20];
        VATLedgerCode: Code[20];
    begin
        // [FEATURE] [Sales] [Prepayment]
        // [SCENARIO] Purchase VAT Ledger Line is created when run REP12455 "Create VAT Purchase Ledger" for customer with "Credit Memo" vat entry
        Initialize();
        CustomerNo := LibrarySales.CreateCustomerNo();

        // [GIVEN] Posted "Credit Memo" VAT Entry for customer "C" with "Full Name" = "X", "VAT Registration No." = "Y", "KPP Code" = "Z"
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", VATLedgerMgt.GetVATPctRate2019());
        CreateSalesReturnVATEntry(VATPostingSetup, CustomerNo, WorkDate(), WorkDate());

        // [WHEN] Run "Create VAT Purchase Ledger" report for customer "C"
        VATLedgerCode := LibraryPurchase.CreatePurchaseVATLedger(WorkDate(), WorkDate(), CustomerNo, false, true);

        // [THEN] Purchase VAT Ledger Line is created with following details:
        // [THEN] "C/V No." = "C"
        // [THEN] "C/V Name" = "X" (TFS 378389)
        // [THEN] "C/V VAT Reg. No." = "Y"
        // [THEN] "Reg. Reason Code" = "Z"
        VerifyPurchaseVATLedgerLineCount(VATLedgerCode, CustomerNo, 1);
        VerifyPurchaseVATLedgerLineCustomerDetails(VATLedgerCode, CustomerNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATAgentVATEntry()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VendorNo: Code[20];
        VATLedgerCode: Code[20];
    begin
        // [SCENARIO] Purchase VAT Ledger Line is created when run REP12455 "Create VAT Purchase Ledger" for "Non-resident" "VAT Agent" vendor
        Initialize();
        VendorNo := CreateVATAgentVendorNo();

        // [GIVEN] Posted VAT Entry for "Non-resident" "VAT Agent" vendor "V" with "Full Name" = "X"
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", VATLedgerMgt.GetVATPctRate2019());
        CreateVATAgentVATEntry(VATPostingSetup, VendorNo, WorkDate(), WorkDate());

        // [WHEN] Run "Create VAT Purchase Ledger" report for vendor "V"
        VATLedgerCode := LibraryPurchase.CreatePurchaseVATLedger(WorkDate(), WorkDate(), VendorNo, false, true);

        // [THEN] Purchase VAT Ledger Line is created with following details:
        // [THEN] "C/V No." = "V"
        // [THEN] "C/V Name" = "X" (TFS 378389)
        // [THEN] "C/V VAT Reg. No." = '-'
        // [THEN] "Reg. Reason Code" = '-'
        VerifyPurchaseVATLedgerLineCount(VATLedgerCode, VendorNo, 1);
        VerifyPurchaseVATLedgerLineVendorDetails(VATLedgerCode, VendorNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchRevisionInvoice()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VendorNo: Code[20];
        VATLedgerCode: Code[20];
    begin
        // Setup:
        Initialize();

        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", VATLedgerMgt.GetVATPctRate2019());
        VendorNo := LibraryPurchase.CreateVendorNo();
        CreateRevisionVATEntry(VATPostingSetup, VendorNo, WorkDate(), WorkDate());

        // Excercise:
        VATLedgerCode := LibraryPurchase.CreatePurchaseVATLedger(WorkDate(), WorkDate(), VendorNo, false, true);
        LibraryPurchase.CreatePurchaseVATLedgerAddSheet(VATLedgerCode, 0);

        // Verify:
        VerifyPurchaseVATLedgerLineCount(VATLedgerCode, VendorNo, 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NavigatePurchaseVATLedger()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATLedger: Record "VAT Ledger";
        VATPurchaseLedgerCard: TestPage "VAT Purchase Ledger Card";
        Navigate: TestPage Navigate;
        VendorNo: Code[20];
        DocumentNo: Code[20];
        Index: Integer;
        "Count": Integer;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 376533] Navigate button opens Navigate page with information for selected line in list part
        Initialize();

        // [GIVEN] VAT Purchase Ledger with 2 posted documents "X1" and "X2"
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", VATLedgerMgt.GetVATPctRate2019());
        VendorNo := LibraryPurchase.CreateVendorNo();
        Count := LibraryRandom.RandIntInRange(5, 10);
        for Index := 1 to Count do
            MockPurchaseVATEntry(VATPostingSetup, VendorNo, WorkDate(), WorkDate());

        VATLedger.Get(VATLedger.Type::Purchase, LibraryPurchase.CreatePurchaseVATLedger(WorkDate(), WorkDate(), VendorNo, false, true));

        // [GIVEN] Selected second line for document "X2"
        VATPurchaseLedgerCard.OpenView();
        VATPurchaseLedgerCard.PurchSubform.Last();
        DocumentNo := VATPurchaseLedgerCard.PurchSubform."Document No.".Value();

        // [WHEN] Click "Navigate" on "Purchase VAT Ledger" card
        Navigate.Trap();
        VATPurchaseLedgerCard."&Navigate".Invoke(); // Navigate

        // [THEN] Navigate window show information for document "X2"
        Navigate.DocNoFilter.AssertEquals(DocumentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TwoPurchaseDocWithTwoDifferentSetup()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATPostingSetup2: Record "VAT Posting Setup";
        VATEntry: Record "VAT Entry";
        VATLedgerCode: Code[20];
        VendorNo: Code[20];
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
        ExpectedAmount: Decimal;
    begin
        // [SCENARIO 379333] Purchase VAT Ledger line amount should correspond to total amount purchase lines with different VAT posting setup
        Initialize();

        // [GIVEN] Create 2 VAT different posting setup
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", VATLedgerMgt.GetVATPctRate2019());
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup2, VATPostingSetup2."VAT Calculation Type"::"Normal VAT", VATLedgerMgt.GetVATPctRate2019());
        VendorNo := LibraryPurchase.CreateVendorNo();

        // [GIVEN] Create 2 line VAT Entry with Document No = "D1": 1 line VAT Posting Setup Code = "V1" and Amount = "A11"
        // [GIVEN] 2 line VAT Posting Setup Code = "V2" and Amount "A12"
        DocumentNo := LibraryUtility.GenerateRandomCode(VATEntry.FieldNo("Document No."), DATABASE::"VAT Entry");
        CreatePurchaseVATEntryWithDocument(VATPostingSetup, VendorNo, DocumentNo, WorkDate(), WorkDate());
        CreatePurchaseVATEntryWithDocument(VATPostingSetup2, VendorNo, DocumentNo, WorkDate(), WorkDate());
        // [GIVEN] Create 2 line VAT Entry with Document No = "D2": 1 line VAT Posting Setup Code = "V1" and Amount = "A21"
        // [GIVEN] 2 line VAT Posting Setup Code = "V2" and Amount "A22"
        DocumentNo2 := LibraryUtility.GenerateRandomCode(VATEntry.FieldNo("Document No."), DATABASE::"VAT Entry");
        CreatePurchaseVATEntryWithDocument(VATPostingSetup, VendorNo, DocumentNo2, WorkDate(), WorkDate());
        CreatePurchaseVATEntryWithDocument(VATPostingSetup2, VendorNo, DocumentNo2, WorkDate(), WorkDate());

        // [WHEN] Create purchase VAT ledger
        VATLedgerCode := LibraryPurchase.CreatePurchaseVATLedger(WorkDate(), WorkDate(), VendorNo, false, false);

        // [THEN] One document "D1": Ledger Line Amount = "A11" + "A12"
        ExpectedAmount := FindVATEntryAmount(DocumentNo);
        VerifyVATLedgerLineAmount(VATLedgerCode, DocumentNo, ExpectedAmount);
        // [THEN] One document "D2": Ledger Line Amount = "A21" + "A22"
        ExpectedAmount := FindVATEntryAmount(DocumentNo2);
        VerifyVATLedgerLineAmount(VATLedgerCode, DocumentNo2, ExpectedAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UI_PurchaseLEdgerLine_VAT20PctVisibility()
    var
        Vendor: Record Vendor;
        VATPostingSetup: Record "VAT Posting Setup";
        VATEntry: Record "VAT Entry";
        VATLedgerLine: Record "VAT Ledger Line";
        VATPurchaseLedgerSubform: TestPage "VAT Purchase Ledger Subform";
        VATLedgerCode: Code[20];
    begin
        // [FEATURE] [UI]
        // [SCENARIO 303035] Purchase VAT Ledger Line has visible fields Base20, Amount20
        Initialize();
        LibraryApplicationArea.EnableBasicSetup();
        LibraryRUReports.UpdateCompanyInfo();
        LibraryRUReports.CreateVendor(Vendor);

        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", VATLedgerMgt.GetVATPctRate2019());
        VATEntry.Get(MockPurchaseVATEntry(VATPostingSetup, Vendor."No.", WorkDate(), WorkDate()));

        VATLedgerCode := LibraryPurchase.CreatePurchaseVATLedger(WorkDate(), WorkDate(), Vendor."No.", false, true);
        VATLedgerLine.SetRange(Type, VATLedgerLine.Type::Purchase);
        VATLedgerLine.SetRange(Code, VATLedgerCode);

        VATPurchaseLedgerSubform.Trap();
        PAGE.Run(PAGE::"VAT Purchase Ledger Subform", VATLedgerLine);
        Assert.IsTrue(VATPurchaseLedgerSubform.Base20.Visible(), 'Purchase VAT Ledger Line Base20 field should be visible');
        Assert.IsTrue(VATPurchaseLedgerSubform.Amount20.Visible(), 'Purchase VAT Ledger Line Amount20 field should be visible');
        VATPurchaseLedgerSubform.Base20.AssertEquals(VATEntry.Base);
        VATPurchaseLedgerSubform.Amount20.AssertEquals(VATEntry.Amount);
        VATPurchaseLedgerSubform.Close();
    end;

    local procedure Initialize()
    begin
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;
        IsInitialized := true;

        LibrarySetupStorage.Save(DATABASE::"Company Information");
    end;

    local procedure MockPurchaseVATEntry(VATPostingSetup: Record "VAT Posting Setup"; CVNo: Code[20]; PostingDate: Date; DocumentDate: Date): Integer
    var
        VATEntry: Record "VAT Entry";
    begin
        exit(InsertPurchaseVATEntry(VATEntry, VATPostingSetup, CVNo, PostingDate, DocumentDate));
    end;

    local procedure MockSaleVATEntry(VATPostingSetup: Record "VAT Posting Setup"; CVNo: Code[20]; PostingDate: Date; DocumentDate: Date): Integer
    var
        VATEntry: Record "VAT Entry";
    begin
        exit(InsertSaleVATEntry(VATEntry, VATPostingSetup, CVNo, PostingDate, DocumentDate));
    end;

    local procedure InsertPurchaseVATEntry(var VATEntry: Record "VAT Entry"; VATPostingSetup: Record "VAT Posting Setup"; CVNo: Code[20]; PostingDate: Date; DocumentDate: Date): Integer
    begin
        exit(
          InsertPurchaseVATEntryWithVATAmount(
            VATEntry, VATPostingSetup, CVNo, PostingDate, DocumentDate, LibraryRandom.RandInt(1000), LibraryRandom.RandInt(100)));
    end;

    local procedure InsertSaleVATEntry(var VATEntry: Record "VAT Entry"; VATPostingSetup: Record "VAT Posting Setup"; CVNo: Code[20]; PostingDate: Date; DocumentDate: Date): Integer
    begin
        exit(
          InsertSaleVATEntryWithVATAmount(
            VATEntry, VATPostingSetup, CVNo, PostingDate, DocumentDate, LibraryRandom.RandInt(1000), LibraryRandom.RandInt(100)));
    end;

    local procedure InsertPurchaseVATEntryWithVATAmount(var VATEntry: Record "VAT Entry"; VATPostingSetup: Record "VAT Posting Setup"; CVNo: Code[20]; PostingDate: Date; DocumentDate: Date; BaseAmount: Decimal; VATAmount: Decimal): Integer
    begin
        exit(
          InsertVATEntryWithVATAmount(
            VATEntry, VATPostingSetup, CVNo, PostingDate, DocumentDate,
            VATEntry.Type::Purchase, BaseAmount, VATAmount));
    end;

    local procedure InsertSaleVATEntryWithVATAmount(var VATEntry: Record "VAT Entry"; VATPostingSetup: Record "VAT Posting Setup"; CVNo: Code[20]; PostingDate: Date; DocumentDate: Date; BaseAmount: Decimal; VATAmount: Decimal): Integer
    begin
        exit(
          InsertVATEntryWithVATAmount(
            VATEntry, VATPostingSetup, CVNo, PostingDate, DocumentDate,
            VATEntry.Type::Sale, BaseAmount, VATAmount));
    end;

    local procedure InsertVATEntryWithVATAmount(var VATEntry: Record "VAT Entry"; VATPostingSetup: Record "VAT Posting Setup"; CVNo: Code[20]; PostingDate: Date; DocumentDate: Date; VATType: Enum "General Posting Type"; BaseAmount: Decimal; VATAmount: Decimal): Integer
    begin
        VATEntry.Init();
        VATEntry."Entry No." := LibraryUtility.GetNewRecNo(VATEntry, VATEntry.FieldNo("Entry No."));
        VATEntry."VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";
        VATEntry."VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";
        VATEntry."Bill-to/Pay-to No." := CVNo;
        VATEntry."Posting Date" := PostingDate;
        VATEntry."Document Date" := DocumentDate;
        VATEntry.Base := BaseAmount;
        VATEntry.Amount := VATAmount;
        VATEntry.Type := VATType;
        VATEntry."Document No." := LibraryUtility.GenerateRandomCode(VATEntry.FieldNo("Document No."), DATABASE::"VAT Entry");
        VATEntry.Insert();
        exit(VATEntry."Entry No.");
    end;

    local procedure CreateVATAgentVendorNo(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Agent", true);
        Vendor.Validate("VAT Agent Type", Vendor."VAT Agent Type"::"Non-resident");
        Vendor."VAT Registration No." := '-';
        Vendor."KPP Code" := '-';
        Vendor.Modify();
        exit(Vendor."No.");
    end;

    local procedure CreatePurchPrepmtVATEntry(VATPostingSetup: Record "VAT Posting Setup"; CVNo: Code[20]; PostingDate: Date; DocumentDate: Date)
    var
        VATEntry: Record "VAT Entry";
    begin
        InsertPurchaseVATEntry(VATEntry, VATPostingSetup, CVNo, PostingDate, DocumentDate);
        VATEntry.Prepayment := true;
        VATEntry.Modify();
    end;

    local procedure CreateSalesPrepmtVATEntry(VATPostingSetup: Record "VAT Posting Setup"; CVNo: Code[20]; PostingDate: Date; DocumentDate: Date)
    var
        VATEntry: Record "VAT Entry";
    begin
        InsertSaleVATEntry(VATEntry, VATPostingSetup, CVNo, PostingDate, DocumentDate);
        VATEntry."Unrealized VAT Entry No." := MockSaleVATEntry(VATPostingSetup, CVNo, PostingDate, DocumentDate);
        VATEntry.Prepayment := true;
        VATEntry.Modify();
    end;

    local procedure CreateSalesReturnVATEntry(VATPostingSetup: Record "VAT Posting Setup"; CVNo: Code[20]; PostingDate: Date; DocumentDate: Date)
    var
        VATEntry: Record "VAT Entry";
    begin
        InsertSaleVATEntry(VATEntry, VATPostingSetup, CVNo, PostingDate, DocumentDate);
        VATEntry."Document Type" := VATEntry."Document Type"::"Credit Memo";
        VATEntry."Include In Other VAT Ledger" := true;
        VATEntry.Modify();
    end;

    local procedure CreateVATAgentVATEntry(VATPostingSetup: Record "VAT Posting Setup"; CVNo: Code[20]; PostingDate: Date; DocumentDate: Date)
    var
        VATEntry: Record "VAT Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        InsertPurchaseVATEntry(VATEntry, VATPostingSetup, CVNo, PostingDate, DocumentDate);
        VATEntry."VAT Agent" := true;
        VATEntry.Modify();

        VendLedgEntry.Init();
        VendLedgEntry.Validate("Original Amount", LibraryRandom.RandInt(1000));
        VendLedgEntry.Validate("Remaining Amount", VendLedgEntry."Original Amount" / 2);
        VendLedgEntry.Insert();
    end;

    local procedure CreateRevisionVATEntry(VATPostingSetup: Record "VAT Posting Setup"; CVNo: Code[20]; PostingDate: Date; DocumentDate: Date)
    var
        VATEntry: Record "VAT Entry";
        PurchInvHeader: Record "Purch. Inv. Header";
        NewPostingDate: Date;
        NewDocumentDate: Date;
        OriginalDocNo: Code[20];
    begin
        InsertPurchaseVATEntry(VATEntry, VATPostingSetup, CVNo, PostingDate, DocumentDate);
        VATEntry."Document Type" := VATEntry."Document Type"::Invoice;
        VATEntry.Modify();
        OriginalDocNo := VATEntry."Document No.";

        PurchInvHeader.Init();
        PurchInvHeader."No." := OriginalDocNo;
        PurchInvHeader."Posting Date" := PostingDate;
        PurchInvHeader.Insert();

        NewPostingDate := CalcDate('<+1M>', PostingDate);
        NewDocumentDate := NewPostingDate;
        InsertPurchaseVATEntry(VATEntry, VATPostingSetup, CVNo, NewPostingDate, NewDocumentDate);
        VATEntry."Document Type" := VATEntry."Document Type"::"Credit Memo";
        VATEntry."Additional VAT Ledger Sheet" := true;
        VATEntry."Corrected Document Date" := PostingDate;
        VATEntry.Modify();

        InsertPurchaseVATEntry(VATEntry, VATPostingSetup, CVNo, NewPostingDate, NewDocumentDate);
        VATEntry."Document Type" := VATEntry."Document Type"::Invoice;
        VATEntry."Additional VAT Ledger Sheet" := true;
        VATEntry."Corrected Document Date" := PostingDate;
        VATEntry."Corrective Doc. Type" := VATEntry."Corrective Doc. Type"::Revision;
        VATEntry.Modify();

        PurchInvHeader.Init();
        PurchInvHeader."No." := VATEntry."Document No.";
        PurchInvHeader."Posting Date" := NewPostingDate;
        PurchInvHeader."Original Doc. Type" := PurchInvHeader."Original Doc. Type"::Invoice;
        PurchInvHeader."Original Doc. No." := OriginalDocNo;
        PurchInvHeader."Corrective Doc. Type" := PurchInvHeader."Corrective Doc. Type"::Revision;
        PurchInvHeader."Corrected Doc. Type" := PurchInvHeader."Corrected Doc. Type"::Invoice;
        PurchInvHeader."Corrected Doc. No." := OriginalDocNo;
        PurchInvHeader.Insert();
    end;

    local procedure CreatePurchaseVATEntryWithDocument(VATPostingSetup: Record "VAT Posting Setup"; CVNo: Code[20]; DocumentNo: Code[20]; DocumentDate: Date; PostingDate: Date)
    var
        VATEntry: Record "VAT Entry";
    begin
        InsertPurchaseVATEntry(VATEntry, VATPostingSetup, CVNo, PostingDate, DocumentDate);
        VATEntry."Document No." := DocumentNo;
        VATEntry.Modify();
    end;

    local procedure FindVATEntryAmount(DocumentNo: Code[20]): Decimal
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.CalcSums(Amount);
        exit(VATEntry.Amount);
    end;

    local procedure VerifyPurchaseVATLedgerLineCustomerDetails(VATLedgerCode: Code[20]; CustomerNo: Code[20])
    var
        VATLedgerLine: Record "VAT Ledger Line";
    begin
        LibraryRUReports.VerifyVATLedgerLineCustomerDetails(VATLedgerLine.Type::Purchase, VATLedgerCode, CustomerNo);
    end;

    local procedure VerifyPurchaseVATLedgerLineVendorDetails(VATLedgerCode: Code[20]; VendorNo: Code[20])
    var
        VATLedgerLine: Record "VAT Ledger Line";
    begin
        LibraryRUReports.VerifyVATLedgerLineVendorDetails(VATLedgerLine.Type::Purchase, VATLedgerCode, VendorNo);
    end;

    local procedure VerifyPurchaseVATLedgerLineCompanyDetails(VATLedgerCode: Code[20]; CVNo: Code[20])
    var
        VATLedgerLine: Record "VAT Ledger Line";
    begin
        LibraryRUReports.VerifyVATLedgerLineCompanyDetails(VATLedgerLine.Type::Purchase, VATLedgerCode, CVNo);
    end;

    local procedure VerifyPurchaseVATLedgerLineCount(VATLedgerCode: Code[20]; CVNo: Code[20]; ExpectedVATLedgerLineCount: Integer)
    var
        VATLedgerLine: Record "VAT Ledger Line";
    begin
        LibraryRUReports.VerifyVATLedgerLineCount(VATLedgerLine.Type::Purchase, VATLedgerCode, CVNo, ExpectedVATLedgerLineCount);
    end;

    local procedure VerifyVATLedgerLineAmount(VATLedgerCode: Code[20]; DocumentNo: Code[20]; ExpectedVATLedgerLineAmount: Decimal)
    var
        VATLedgerLine: Record "VAT Ledger Line";
    begin
        VATLedgerLine.SetRange(Code, VATLedgerCode);
        VATLedgerLine.SetRange("Document No.", DocumentNo);
        VATLedgerLine.CalcSums(Amount20);
        VATLedgerLine.TestField(Amount20, ExpectedVATLedgerLineAmount);
    end;
}

