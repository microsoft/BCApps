codeunit 147130 "ERM Sales VAT Ledger"
{
    // // [FEATURE] [UT] [VAT Ledger] [Sales]

    TestPermissions = NonRestrictive;
    Subtype = Test;
    Permissions = tabledata "VAT Entry" = imd,
                  tabledata "Vendor Ledger Entry" = imd,
                  tabledata "Sales Invoice Header" = imd;

    var
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRUReports: Codeunit "Library RU Reports";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        VATLedgerMgt: Codeunit "VAT Ledger Management";
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure SalesVATEntry()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Customer: Record Customer;
        VATLedgerCode: Code[20];
    begin
        // [SCENARIO] Sales VAT Ledger Line is created when run REP12456 "Create VAT Sales Ledger" for customer
        Initialize();
        LibraryRUReports.UpdateCompanyInfo();
        LibraryRUReports.CreateCustomer(Customer);

        // [GIVEN] Posted VAT Entry for customer "C" with "Full Name" = "X" (250 chars length), "VAT Registration No." = "Y", "KPP Code" = "Z"
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", VATLedgerMgt.GetVATPctRate2019());
        MockSaleVATEntry(VATPostingSetup, Customer."No.", WorkDate(), WorkDate());

        // [WHEN] Run "Create VAT Sales Ledger" report for customer "C"
        VATLedgerCode := LibrarySales.CreateSalesVATLedger(WorkDate(), WorkDate(), Customer."No.");

        // [THEN] Sales VAT Ledger Line is created with following details:
        // [THEN] "C/V No." = "C"
        // [THEN] "C/V Name" = "X" (TFS 378389), 250 chars length (TFS 378853)
        // [THEN] "C/V VAT Reg. No." = "Y"
        // [THEN] "Reg. Reason Code" = "Z"
        VerifySalesVATLedgerLineCount(VATLedgerCode, Customer."No.", 1);
        VerifySalesVATLedgerLineCustomerDetails(VATLedgerCode, Customer."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchPrepmtVATEntry()
    var
        VATEntry: Record "VAT Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        Vendor: Record Vendor;
        VATLedgerCode: Code[20];
    begin
        // [FEATURE] [Purchase] [Prepayment]
        // [SCENARIO] Sales VAT Ledger Line is created when run REP12456 "Create VAT Sales Ledger" for vendor with "Prepayment" vat entry
        Initialize();
        LibraryRUReports.UpdateCompanyInfo();
        LibraryRUReports.CreateVendor(Vendor);

        // [GIVEN] Posted prepayment VAT Entry for vendor "V"
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", VATLedgerMgt.GetVATPctRate2019());
        CreatePurchPrepmtVATEntry(VATEntry, VATPostingSetup, Vendor."No.", WorkDate(), WorkDate());

        // [WHEN] Run "Create VAT Sales Ledger" report for vendor "V"
        VATLedgerCode := LibrarySales.CreateSalesVATLedger(WorkDate(), WorkDate(), Vendor."No.");

        // [THEN] Sales VAT Ledger Line is created with following details:
        // [THEN] "C/V No." = "V"
        // [THEN] "C/V Name" = <CompanyName>
        // [THEN] "C/V VAT Reg. No." = <Company VAT Registration No.>
        // [THEN] "Reg. Reason Code" = <Company KPP Code>
        // [THEN] "External Document No." = <prepayment document no.> (TFS 378466)
        // [THEN] "Payment Date" = <prepayment date> (TFS 378466)
        VerifySalesVATLedgerLineCount(VATLedgerCode, Vendor."No.", 1);
        VerifySalesVATLedgerLineCompanyDetails(VATLedgerCode, Vendor."No.");
        VerifySalesVATLedgerDocPdtvOpl(VATLedgerCode, Vendor."No.", VATEntry."External Document No.", VATEntry."Posting Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchReturnVATEntry()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VendorNo: Code[20];
        VATLedgerCode: Code[20];
    begin
        // [FEATURE] [Purchase] [Prepayment]
        // [SCENARIO] Sales VAT Ledger Line is created when run REP12456 "Create VAT Sales Ledger" for vendor with "Credit Memo" vat entry
        Initialize();
        VendorNo := LibraryPurchase.CreateVendorNo();

        // [GIVEN] Posted "Credit Memo" VAT Entry for vendor "V" with "Full Name" = "X", "VAT Registration No." = "Y", "KPP Code" = "Z"
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", VATLedgerMgt.GetVATPctRate2019());
        CreatePurchReturnVATEntry(VATPostingSetup, VendorNo, WorkDate(), WorkDate());

        // [WHEN] Run "Create VAT Sales Ledger" report for vendor "V"
        VATLedgerCode := LibrarySales.CreateSalesVATLedger(WorkDate(), WorkDate(), VendorNo);

        // [THEN] Sales VAT Ledger Line is created with following details:
        // [THEN] "C/V No." = "V"
        // [THEN] "C/V Name" = "X"  (TFS 378389)
        // [THEN] "C/V VAT Reg. No." = "Y"
        // [THEN] "Reg. Reason Code" = "Z"
        VerifySalesVATLedgerLineCount(VATLedgerCode, VendorNo, 1);
        VerifySalesVATLedgerLineVendorDetails(VATLedgerCode, VendorNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchVATReinstVATEntry()
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
        CreatePurchVATReinstVATEntry(VATPostingSetup, VendorNo, WorkDate(), WorkDate());

        // Excercise:
        VATLedgerCode := LibrarySales.CreateSalesVATLedger(WorkDate(), WorkDate(), VendorNo);

        // Verify:
        VerifySalesVATLedgerLineCount(VATLedgerCode, VendorNo, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATAgentVATEntry()
    var
        VATEntry: Record "VAT Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        Vendor: Record Vendor;
        VATLedgerCode: Code[20];
    begin
        // [FEATURE] [Purchase] [VAT Agent]
        // [SCENARIO] Sales VAT Ledger Line is created when run REP12456 "Create VAT Sales Ledger" for "VAT Agent" vendor
        Initialize();
        LibraryRUReports.UpdateCompanyInfo();
        LibraryRUReports.CreateVendor(Vendor);

        // [GIVEN] Posted VAT Entry for "VAT Agent" vendor "V"
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", VATLedgerMgt.GetVATPctRate2019());
        CreateVATAgentVATEntry(VATEntry, VATPostingSetup, Vendor."No.", WorkDate(), WorkDate());

        // [WHEN] Run "Create VAT Sales Ledger" report for vendor "V"
        VATLedgerCode := LibrarySales.CreateSalesVATLedger(WorkDate(), WorkDate(), Vendor."No.");

        // [THEN] Sales VAT Ledger Line is created with following details:
        // [THEN] "C/V No." = "V"
        // [THEN] "C/V Name" = <CompanyName>
        // [THEN] "C/V VAT Reg. No." = <Company VAT Registration No.>
        // [THEN] "Reg. Reason Code" = <Company KPP Code>
        // [THEN] "External Document No." = <payment document no.> (TFS 378466)
        // [THEN] "Payment Date" = <payment date> (TFS 378466)
        VerifySalesVATLedgerLineCount(VATLedgerCode, Vendor."No.", 1);
        VerifySalesVATLedgerLineCompanyDetails(VATLedgerCode, Vendor."No.");
        VerifySalesVATLedgerDocPdtvOpl(VATLedgerCode, Vendor."No.", VATEntry."External Document No.", VATEntry."Posting Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesRevisionInvoice()
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
        VATLedgerCode := LibrarySales.CreateSalesVATLedger(WorkDate(), WorkDate(), VendorNo);
        VATLedgerCode := LibrarySales.CreateSalesVATLedgerAddSheet(VATLedgerCode);

        // Verify:
        VerifySalesVATLedgerLineCount(VATLedgerCode, VendorNo, 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NavigateSalesVATLedger()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATLedger: Record "VAT Ledger";
        VATSalesLedgerCard: TestPage "VAT Sales Ledger Card";
        Navigate: TestPage Navigate;
        CustomerNo: Code[20];
        DocumentNo: Code[20];
        Index: Integer;
        "Count": Integer;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 376533] Navigate button opens Navigate page with information for selected line in list part
        Initialize();

        // [GIVEN] VAT Sales Ledger with 2 posted documents "X1" and "X2"
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", VATLedgerMgt.GetVATPctRate2019());
        CustomerNo := LibrarySales.CreateCustomerNo();
        Count := LibraryRandom.RandIntInRange(5, 10);
        for Index := 1 to Count do
            MockSaleVATEntry(VATPostingSetup, CustomerNo, WorkDate(), WorkDate());

        VATLedger.Get(VATLedger.Type::Sales, LibrarySales.CreateSalesVATLedger(WorkDate(), WorkDate(), CustomerNo));

        // [GIVEN] Selected second line for document "X2"
        VATSalesLedgerCard.OpenView();
        VATSalesLedgerCard.GotoRecord(VATLedger);
        VATSalesLedgerCard.SalesSubform.Last();
        DocumentNo := VATSalesLedgerCard.SalesSubform."Document No.".Value();

        // [WHEN] Click "Navigate" on "Sales VAT Ledger" card
        Navigate.Trap();
        VATSalesLedgerCard."&Navigate".Invoke(); // Navigate

        // [THEN] Navigate window show information for document "X2"
        Navigate.DocNoFilter.AssertEquals(DocumentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesVATEntryZeroVATRate()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATEntry: Record "VAT Entry";
        CustomerNo: Code[20];
        VATLedgerCode: Code[20];
    begin
        // [SCENARIO 377011] Sales VAT entry with Amount = 0 should be included in sales VAT ledger
        Initialize();

        // [GIVEN] Post sales entry with normal VAT, VAT Rate = 0%, VAT Amount = 0
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 0);
        CustomerNo := LibrarySales.CreateCustomerNo();
        InsertSaleVATEntryWithVATAmount(VATEntry, VATPostingSetup, CustomerNo, WorkDate(), WorkDate(), LibraryRandom.RandInt(1000), 0);

        // [WHEN] Create sales VAT ledger
        VATLedgerCode := LibrarySales.CreateSalesVATLedger(WorkDate(), WorkDate(), CustomerNo);

        // [THEN] VAT entry is included in ledger
        VerifySalesVATLedgerLineCount(VATLedgerCode, CustomerNo, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPrepaymentVATEntryZeroVATRate()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATEntry: Record "VAT Entry";
        CustomerNo: Code[20];
        VATLedgerCode: Code[20];
    begin
        // [FEATURE] [Prepayment]
        // [SCENARIO 377011] Sales prepayment VAT entry with Amount = 0 should not be included in sales VAT ledger
        Initialize();

        // [GIVEN] Post sales prepayment entry with normal VAT, VAT Rate = 0%, VAT Amount = 0
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 0);
        CustomerNo := LibrarySales.CreateCustomerNo();
        InsertSaleVATEntryWithVATAmount(VATEntry, VATPostingSetup, CustomerNo, WorkDate(), WorkDate(), LibraryRandom.RandInt(1000), 0);
        VATEntry.Prepayment := true;
        VATEntry.Modify();

        // [WHEN] Create sales VAT ledger
        VATLedgerCode := LibrarySales.CreateSalesVATLedger(WorkDate(), WorkDate(), CustomerNo);

        // [THEN] VAT entry is not included in ledger
        VerifySalesVATLedgerLineCount(VATLedgerCode, CustomerNo, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPrepaymentUnrealizedVAT()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATEntry: Record "VAT Entry";
        CustomerNo: Code[20];
        VATLedgerCode: Code[20];
    begin
        // [FEATURE] [Prepayment] [Unrealized VAT]
        // [SCENARIO 377011] Unrealized sales prepayment VAT entry should be included in sales VAT ledger
        Initialize();

        // [GIVEN] Post sales prepayment entry with unrealized VAT
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", VATLedgerMgt.GetVATPctRate2019());
        CustomerNo := LibrarySales.CreateCustomerNo();
        CreateUnrealizedSalesPrepmtVATEntry(VATEntry, VATPostingSetup, CustomerNo, WorkDate(), WorkDate());

        // [WHEN] Create sales VAT ledger
        VATLedgerCode := LibrarySales.CreateSalesVATLedger(WorkDate(), WorkDate(), CustomerNo);

        // [THEN] VAT entry is included in ledger
        VerifySalesVATLedgerLineCount(VATLedgerCode, CustomerNo, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TwoSalesDocWithTwoDifferentSetup()
    var
        VATPostingSetup: array[2] of Record "VAT Posting Setup";
        VATEntry: Record "VAT Entry";
        CustomerNo: Code[20];
        DocumentNo: array[2] of Code[20];
        Index: Integer;
        VATLedgerCode: Code[20];
    begin
        // [SCENARIO 377995]  Posted 2 documents that generated 4 VAT Entries, where VAT groups are different, but same VAT%.
        Initialize();

        // [GIVEN] Create VAT entry with 2 posted documents with lines VAT different setup
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup[1], VATPostingSetup[1]."VAT Calculation Type"::"Normal VAT", VATLedgerMgt.GetVATPctRate2019());
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup[2], VATPostingSetup[2]."VAT Calculation Type"::"Normal VAT", VATLedgerMgt.GetVATPctRate2019());
        CustomerNo := LibrarySales.CreateCustomerNo();

        DocumentNo[1] := LibraryUtility.GenerateRandomCode(VATEntry.FieldNo("Document No."), DATABASE::"VAT Entry");
        DocumentNo[2] := LibraryUtility.GenerateRandomCode(VATEntry.FieldNo("Document No."), DATABASE::"VAT Entry");
        CreateSalesVATEntryWithDoc(VATPostingSetup[1], CustomerNo, DocumentNo[1], WorkDate(), WorkDate());
        CreateSalesVATEntryWithDoc(VATPostingSetup[2], CustomerNo, DocumentNo[2], WorkDate(), WorkDate());

        // [WHEN] Create sales VAT ledger
        VATLedgerCode := LibrarySales.CreateSalesVATLedger(WorkDate(), WorkDate(), CustomerNo);

        // [THEN] VAT ledger contains 2 lines, one per document, where Amount is a sum of document's VAT Entries .
        for Index := 1 to 2 do begin
            VATEntry.SetRange("Document No.", DocumentNo[Index]);
            VATEntry.CalcSums(Amount);
            VerifyVATLedgerLineAmount(VATLedgerCode, DocumentNo[Index], VATEntry.Amount)
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UI_SalesVATLedgerTotalBase20Amount20FieldsVisibility()
    var
        Customer: Record Customer;
        VATPostingSetup: Record "VAT Posting Setup";
        VATLedger: Record "VAT Ledger";
        VATSalesLedgerCard: TestPage "VAT Sales Ledger Card";
        VATLedgerCode: Code[20];
        Base20: Decimal;
        Amount20: Decimal;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 303035] Sales VAT Ledger has visible fields Total Base20, Total Amount20
        Initialize();
        LibraryApplicationArea.EnableBasicSetup();
        LibraryRUReports.UpdateCompanyInfo();
        LibraryRUReports.CreateCustomer(Customer);

        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", VATLedgerMgt.GetVATPctRate2019());
        MockSaleVATEntry(VATPostingSetup, Customer."No.", WorkDate(), WorkDate());
        VATLedgerCode := LibrarySales.CreateSalesVATLedger(WorkDate(), WorkDate(), Customer."No.");
        VATLedger.Get(VATLedger.Type::Sales, VATLedgerCode);

        Base20 := LibraryRandom.RandDec(1000, 2);
        Amount20 := LibraryRandom.RandDec(1000, 2);

        VATSalesLedgerCard.Trap();
        PAGE.Run(PAGE::"VAT Sales Ledger Card", VATLedger);
        Assert.IsTrue(VATSalesLedgerCard."Tot Base20 Amt VAT Sales Ledg".Visible(), '"Tot Base20 Amt VAT Sales Ledg" should be visible');
        Assert.IsTrue(VATSalesLedgerCard."Total VAT20 Amt VAT Sales Ledg".Visible(), '"Total VAT20 Amt VAT Sales Ledg" should be visible');
        VATSalesLedgerCard."Tot Base20 Amt VAT Sales Ledg".SetValue(Base20);
        VATSalesLedgerCard."Total VAT20 Amt VAT Sales Ledg".SetValue(Amount20);
        VATSalesLedgerCard.Close();

        VATLedger.Find();
        VATLedger.TestField("Tot Base20 Amt VAT Sales Ledg", Base20);
        VATLedger.TestField("Total VAT20 Amt VAT Sales Ledg", Amount20);
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

    local procedure MockVendorLedgerEntry(VATEntry: Record "VAT Entry"): Integer
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.Init();
        VendorLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(VendorLedgerEntry, VendorLedgerEntry.FieldNo("Entry No."));
        VendorLedgerEntry."Posting Date" := VATEntry."Posting Date";
        VendorLedgerEntry."Vendor No." := VATEntry."Bill-to/Pay-to No.";
        VendorLedgerEntry."Document Type" := VATEntry."Document Type";
        VendorLedgerEntry."Document No." := VATEntry."Document No.";
        VendorLedgerEntry."Document Date" := VATEntry."Document Date";
        VendorLedgerEntry.Insert();
        exit(VendorLedgerEntry."Entry No.");
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
        VATEntry."VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";
        VATEntry."VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";
        VATEntry."Bill-to/Pay-to No." := CVNo;
        VATEntry."Posting Date" := PostingDate;
        VATEntry."Document Date" := DocumentDate;
        VATEntry.Type := VATType;
        VATEntry.Base := BaseAmount;
        VATEntry.Amount := VATAmount;
        VATEntry."Document No." := LibraryUtility.GenerateRandomCode(VATEntry.FieldNo("Document No."), DATABASE::"VAT Entry");
        VATEntry.Insert();
        exit(VATEntry."Entry No.");
    end;

    local procedure CreatePurchPrepmtVATEntry(var VATEntry: Record "VAT Entry"; VATPostingSetup: Record "VAT Posting Setup"; CVNo: Code[20]; PostingDate: Date; DocumentDate: Date)
    begin
        InsertPurchaseVATEntry(VATEntry, VATPostingSetup, CVNo, PostingDate, DocumentDate);
        VATEntry."Unrealized VAT Entry No." := MockPurchaseVATEntry(VATPostingSetup, CVNo, PostingDate, DocumentDate);
        VATEntry.Prepayment := true;
        VATEntry."External Document No." := LibraryUtility.GenerateGUID();
        VATEntry."CV Ledg. Entry No." := MockVendorLedgerEntry(VATEntry);
        VATEntry.Modify();
    end;

    local procedure CreatePurchReturnVATEntry(VATPostingSetup: Record "VAT Posting Setup"; CVNo: Code[20]; PostingDate: Date; DocumentDate: Date)
    var
        VATEntry: Record "VAT Entry";
    begin
        InsertPurchaseVATEntry(VATEntry, VATPostingSetup, CVNo, PostingDate, DocumentDate);
        VATEntry."Document Type" := VATEntry."Document Type"::"Credit Memo";
        VATEntry."Include In Other VAT Ledger" := true;
        VATEntry.Modify();
    end;

    local procedure CreatePurchVATReinstVATEntry(VATPostingSetup: Record "VAT Posting Setup"; CVNo: Code[20]; PostingDate: Date; DocumentDate: Date)
    var
        VATEntry: Record "VAT Entry";
    begin
        InsertPurchaseVATEntry(VATEntry, VATPostingSetup, CVNo, PostingDate, DocumentDate);
        VATEntry."Unrealized VAT Entry No." := MockPurchaseVATEntry(VATPostingSetup, CVNo, PostingDate, DocumentDate);
        VATEntry."VAT Reinstatement" := true;
        VATEntry.Modify();
    end;

    local procedure CreateVATAgentVATEntry(var VATEntry: Record "VAT Entry"; VATPostingSetup: Record "VAT Posting Setup"; CVNo: Code[20]; PostingDate: Date; DocumentDate: Date)
    begin
        InsertPurchaseVATEntry(VATEntry, VATPostingSetup, CVNo, PostingDate, DocumentDate);
        VATEntry."VAT Agent" := true;
        VATEntry."External Document No." := LibraryUtility.GenerateGUID();
        VATEntry."CV Ledg. Entry No." := MockVendorLedgerEntry(VATEntry);
        VATEntry.Modify();
    end;

    local procedure CreateRevisionVATEntry(VATPostingSetup: Record "VAT Posting Setup"; CVNo: Code[20]; PostingDate: Date; DocumentDate: Date)
    var
        VATEntry: Record "VAT Entry";
        SalesInvHeader: Record "Sales Invoice Header";
        NewPostingDate: Date;
        NewDocumentDate: Date;
        OriginalDocNo: Code[20];
    begin
        InsertSaleVATEntry(VATEntry, VATPostingSetup, CVNo, PostingDate, DocumentDate);
        VATEntry."Document Type" := VATEntry."Document Type"::Invoice;
        VATEntry.Modify();
        OriginalDocNo := VATEntry."Document No.";

        SalesInvHeader.Init();
        SalesInvHeader."No." := OriginalDocNo;
        SalesInvHeader."Posting Date" := PostingDate;
        SalesInvHeader.Insert();

        NewPostingDate := CalcDate('<+1M>', PostingDate);
        NewDocumentDate := NewPostingDate;
        InsertSaleVATEntry(VATEntry, VATPostingSetup, CVNo, NewPostingDate, NewDocumentDate);
        VATEntry."Document Type" := VATEntry."Document Type"::"Credit Memo";
        VATEntry."Additional VAT Ledger Sheet" := true;
        VATEntry."Corrected Document Date" := PostingDate;
        VATEntry.Modify();

        InsertSaleVATEntry(VATEntry, VATPostingSetup, CVNo, NewPostingDate, NewDocumentDate);
        VATEntry."Document Type" := VATEntry."Document Type"::Invoice;
        VATEntry."Additional VAT Ledger Sheet" := true;
        VATEntry."Corrected Document Date" := PostingDate;
        VATEntry."Corrective Doc. Type" := VATEntry."Corrective Doc. Type"::Revision;
        VATEntry.Modify();

        SalesInvHeader.Init();
        SalesInvHeader."No." := VATEntry."Document No.";
        SalesInvHeader."Posting Date" := NewPostingDate;
        SalesInvHeader."Original Doc. Type" := SalesInvHeader."Original Doc. Type"::Invoice;
        SalesInvHeader."Original Doc. No." := OriginalDocNo;
        SalesInvHeader."Corrective Doc. Type" := SalesInvHeader."Corrective Doc. Type"::Revision;
        SalesInvHeader."Corrected Doc. Type" := SalesInvHeader."Corrected Doc. Type"::Invoice;
        SalesInvHeader."Corrected Doc. No." := OriginalDocNo;
        SalesInvHeader.Insert();
    end;

    local procedure CreateUnrealizedSalesPrepmtVATEntry(var VATEntry: Record "VAT Entry"; VATPostingSetup: Record "VAT Posting Setup"; CVNo: Code[20]; PostingDate: Date; DocumentDate: Date)
    begin
        InsertSaleVATEntryWithVATAmount(VATEntry, VATPostingSetup, CVNo, PostingDate, DocumentDate, 0, 0);
        VATEntry."Unrealized Base" := LibraryRandom.RandInt(1000);
        VATEntry."Unrealized Amount" := LibraryRandom.RandInt(100);
        VATEntry.Prepayment := true;
        VATEntry.Modify();
    end;

    local procedure CreateSalesVATEntryWithDoc(VATPostingSetup: Record "VAT Posting Setup"; CVNo: Code[20]; DocumentNo: Code[20]; PostingDate: Date; DocumentDate: Date)
    var
        VATEntry: Record "VAT Entry";
    begin
        InsertSaleVATEntry(VATEntry, VATPostingSetup, CVNo, PostingDate, DocumentDate);
        VATEntry."Document No." := DocumentNo;
        VATEntry.Modify();
    end;

    local procedure VerifyVATLedgerLineAmount(VATLedgerCode: Code[20]; DocumentNo: Code[20]; ExpectedVATLedgerLineAmount: Decimal)
    var
        VATLedgerLine: Record "VAT Ledger Line";
    begin
        VATLedgerLine.SetRange(Code, VATLedgerCode);
        VATLedgerLine.SetRange("Document No.", DocumentNo);
        VATLedgerLine.CalcSums(Amount20);
        VATLedgerLine.TestField(Amount20, -ExpectedVATLedgerLineAmount);
    end;

    local procedure VerifySalesVATLedgerLineCustomerDetails(VATLedgerCode: Code[20]; CustomerNo: Code[20])
    var
        VATLedgerLine: Record "VAT Ledger Line";
    begin
        LibraryRUReports.VerifyVATLedgerLineCustomerDetails(VATLedgerLine.Type::Sales, VATLedgerCode, CustomerNo);
    end;

    local procedure VerifySalesVATLedgerLineVendorDetails(VATLedgerCode: Code[20]; VendorNo: Code[20])
    var
        VATLedgerLine: Record "VAT Ledger Line";
    begin
        LibraryRUReports.VerifyVATLedgerLineVendorDetails(VATLedgerLine.Type::Sales, VATLedgerCode, VendorNo);
    end;

    local procedure VerifySalesVATLedgerLineCompanyDetails(VATLedgerCode: Code[20]; CVNo: Code[20])
    var
        VATLedgerLine: Record "VAT Ledger Line";
    begin
        LibraryRUReports.VerifyVATLedgerLineCompanyDetails(VATLedgerLine.Type::Sales, VATLedgerCode, CVNo);
    end;

    local procedure VerifySalesVATLedgerLineCount(VATLedgerCode: Code[20]; CVNo: Code[20]; ExpectedVATLedgerLineCount: Integer)
    var
        VATLedgerLine: Record "VAT Ledger Line";
    begin
        LibraryRUReports.VerifyVATLedgerLineCount(VATLedgerLine.Type::Sales, VATLedgerCode, CVNo, ExpectedVATLedgerLineCount);
    end;

    local procedure VerifySalesVATLedgerDocPdtvOpl(VATLedgerCode: Code[20]; CVNo: Code[20]; ExpectedExternalDocNo: Code[35]; ExpectedPaymentDate: Date)
    var
        VATLedgerLine: Record "VAT Ledger Line";
    begin
        LibraryRUReports.FindVATLedgerLine(VATLedgerLine, VATLedgerLine.Type::Sales, VATLedgerCode, CVNo);
        Assert.AreEqual(ExpectedExternalDocNo, VATLedgerLine."External Document No.", VATLedgerLine.FieldCaption("External Document No."));
        Assert.AreEqual(ExpectedPaymentDate, VATLedgerLine."Payment Date", VATLedgerLine.FieldCaption("Payment Date"));
    end;
}

