codeunit 144075 "ERM No Taxable VAT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [No Taxable VAT]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryNonDeductibleVAT: Codeunit "Library - NonDeductible VAT";
        LibraryDimension: Codeunit "Library - Dimension";
        IsInitialized: Boolean;
        NotEqualToTxt: Label '<>%1.';
        VATBufferAmountCap: Label 'VATBuffer2_Amount';
        VATBufferBaseAmountCap: Label 'VATBuffer2_Base_VATBuffer2_Amount';
        VATBufferBaseCap: Label 'VATBuffer2_Base';
        VATEntryMustNotExistMsg: Label 'VAT Entry must not exist.';
        EUCountryCodeTxt: Label 'DE';
        NoTaxableEntryErr: Label 'Entries count must matched with expected value.';
        VATEntryMustExistMsgLbl: Label 'Entries count must matched with expected value %1.';

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesOrderWithNoTaxableVAT()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Test to verify VAT Entry does not exists for Posted Sales Order with No Taxable VAT.
        PostSalesDocumentWithNoTaxableVAT(SalesHeader."Document Type"::Order);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesCreditMemoWithNoTaxableVAT()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Test to verify VAT Entry does not exists for Posted Sales Credit Memo with No Taxable VAT.
        PostSalesDocumentWithNoTaxableVAT(SalesHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseOrderWithNoTaxableVAT()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] Test to verify VAT Entry does not exists for Posted Purchase Order with No Taxable VAT.
        PostPurchaseDocumentWithNoTaxableVAT(PurchaseHeader."Document Type"::Order);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseCreditMemoWithNoTaxableVAT()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] Test to verify VAT Entry does not exists for Posted Purchase Credit Memo with No Taxable VAT.
        PostPurchaseDocumentWithNoTaxableVAT(PurchaseHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentSalesModalPageHandler,SalesInvoiceBookRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceBookReportForPostedSalesInvoice()
    var
        SalesHeader: Record "Sales Header";
        Quantity: Decimal;
    begin
        // [FEATURE] [Sales] [Report]
        // [SCENARIO 293795] Sales Invoice Book report for posted Sales Invoice with VAT Calculation Type as No Taxable VAT.
        Initialize();
        Quantity := LibraryRandom.RandInt(10);
        SalesInvoiceBookReportWithNoTaxableVAT(
          SalesHeader."Document Type"::Invoice, Quantity, CreateGLAccountWithNoTaxableVAT(), 1);
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentSalesModalPageHandler,SalesInvoiceBookRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceBookReportForPostedSalesCreditMemo()
    var
        SalesHeader: Record "Sales Header";
        Quantity: Decimal;
    begin
        // [FEATURE] [Sales] [Report]
        // [SCENARIO 293795] Sales Invoice Book report for posted Sales Credit Memo with VAT Calculation Type as No Taxable VAT.
        Initialize();
        Quantity := LibraryRandom.RandInt(10);
        SalesInvoiceBookReportWithNoTaxableVAT(
          SalesHeader."Document Type"::"Credit Memo", Quantity, CreateGLAccountWithNoTaxableVAT(), -1);
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentPurchModalPageHandler,PurchasesInvoiceBookRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceBookReportForPostedPurchInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        Quantity: Decimal;
    begin
        // [FEATURE] [Purchase] [Report]
        // [SCENARIO 293795] Purchase Invoice Book report for posted Purchase Invoice with VAT Calculation Type as No Taxable VAT.
        Initialize();
        Quantity := LibraryRandom.RandInt(10);
        PurchaseInvoiceBookReportWithNoTaxableVAT(
          PurchaseHeader."Document Type"::Invoice, Quantity, CreateGLAccountWithNoTaxableVAT(), 1);
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentPurchModalPageHandler,PurchasesInvoiceBookRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceBookReportForPostedPurchCreditMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        Quantity: Decimal;
    begin
        // [FEATURE] [Purchase] [Report]
        // [SCENARIO 293795] Purchase Invoice Book report for posted Purchase Credit Memo with VAT Calculation Type as No Taxable VAT.
        Initialize();
        Quantity := LibraryRandom.RandInt(10);
        PurchaseInvoiceBookReportWithNoTaxableVAT(
          PurchaseHeader."Document Type"::"Credit Memo", Quantity, CreateGLAccountWithNoTaxableVAT(), -1);
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentSalesModalPageHandler,SalesInvoiceBookRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceBookReportNotIn347()
    var
        SalesHeader: Record "Sales Header";
        SalesLineChargeItem: Record "Sales Line";
        SalesLineGLAccount: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales] [Report]
        // [SCENARIO 323351] Sales Invoice Book report does not show No Taxable VAT that ignores in 347 report.

        Initialize();

        // [GIVEN] Posted sales invoice "A" with G/L Account setup of No Taxable VAT and option "Ignore in 347 report" on
        PostSalesDocForNoTaxableScenario(
          DocumentNo, SalesLineChargeItem, SalesLineGLAccount,
          SalesHeader."Document Type"::Invoice, LibraryRandom.RandDec(100, 2), CreateNoTaxGLAccNotIn347Report());
        LibraryVariableStorage.Enqueue(DocumentNo);  // Enqueue for SalesInvoiceBookRequestPageHandler.

        // [WHEN] Run Sales Invoice Book
        REPORT.Run(REPORT::"Sales Invoice Book");  // Opens SalesInvoiceBookRequestPageHandler.

        // [THEN] No information about posted invoice "A" in the report
        VerifyNoXmlValuesOnReport(DocumentNo, SalesLineGLAccount."Sell-to Customer No.", SalesLineGLAccount.Amount);
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentPurchModalPageHandler,PurchasesInvoiceBookRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceBookReportNotIn347()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLineChargeItem: Record "Purchase Line";
        PurchaseLineGLAccount: Record "Purchase Line";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Report]
        // [SCENARIO 323351] Purchases Invoice Book report does not show No Taxable VAT that ignores in 347 report.

        Initialize();

        // [GIVEN] Posted purchase invoice "A" with G/L Account setup of No Taxable VAT and option "Ignore in 347 report" on
        PostPurchDocForNoTaxableScenario(
          DocumentNo, PurchaseLineChargeItem, PurchaseLineGLAccount,
          PurchaseHeader."Document Type"::Invoice, LibraryRandom.RandDec(100, 2), CreateNoTaxGLAccNotIn347Report());
        LibraryVariableStorage.Enqueue(DocumentNo);  // Enqueue for PurchasesInvoiceBookRequestPageHandler.

        // [WHEN] Run Purchases Invoice Book
        REPORT.Run(REPORT::"Purchases Invoice Book");  // Opens PurchasesInvoiceBookRequestPageHandler.

        // [THEN] No information about posted invoice "A" in the report
        VerifyNoXmlValuesOnReport(DocumentNo, PurchaseLineGLAccount."Buy-from Vendor No.", PurchaseLineGLAccount.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoTaxableEntryCreatesIndividuallyForEachPurchInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        NoTaxableEntry: Record "No Taxable Entry";
        PurchSetup: Record "Purchases & Payables Setup";
        NoTaxableEntryCount: Integer;
        DocNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Invoice]
        // [SCENARIO 420328] No Taxable Entry creates individually for each posted purchase invoice

        Initialize();

        // [GIVEN] Post first purchase invoice with No Taxable VAT
        FindVATPostingSetupWithNoTaxableVAT(VATPostingSetup);
        CreatePurchaseDocument(PurchaseHeader, VATPostingSetup, PurchaseHeader."Document Type"::Invoice, LibraryRandom.RandDec(10, 2));
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        NoTaxableEntryCount := NoTaxableEntry.Count();

        // [GIVEN] Set a new No. Series code to the "Posted Invoice Nos." in Purchase Setup to start numeration from the "001" document
        PurchSetup.Get();
        PurchSetup.Validate("Posted Invoice Nos.", CreateNoSeriesCodeWithIntegers());
        PurchSetup.Modify(true);

        // [GIVEN] Create second purchase invoice with No Taxable VAT. Amount in the line is "X"
        CreatePurchaseDocument(PurchaseHeader, VATPostingSetup, PurchaseHeader."Document Type"::Invoice, LibraryRandom.RandDec(10, 2));
        LibraryPurchase.FindFirstPurchLine(PurchaseLine, PurchaseHeader);

        // [WHEN] Post second purchase invoice
        DocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Only one additional No Taxable Entry creates with Base = "X"
        Assert.RecordCount(NoTaxableEntry, NoTaxableEntryCount + 1);
        NoTaxableEntry.SetRange("Document No.", DocNo);
        NoTaxableEntry.FindLast();
        NoTaxableEntry.TestField(Base, PurchaseLine.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoTaxableEntryCreatesIndividuallyForEachPurchCrMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        NoTaxableEntry: Record "No Taxable Entry";
        PurchSetup: Record "Purchases & Payables Setup";
        NoTaxableEntryCount: Integer;
        DocNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Credit Memo]
        // [SCENARIO 420328] No Taxable Entry creates individually for each posted purchase credit memo

        Initialize();

        // [GIVEN] Post first purchase credit memo with No Taxable VAT
        FindVATPostingSetupWithNoTaxableVAT(VATPostingSetup);
        CreatePurchaseDocument(PurchaseHeader, VATPostingSetup, PurchaseHeader."Document Type"::"Credit Memo", LibraryRandom.RandDec(10, 2));
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        NoTaxableEntryCount := NoTaxableEntry.Count();

        // [GIVEN] Set a new No. Series code to the "Posted Credit Memo Nos." in Purchase Setup to start numeration from the "001" document
        PurchSetup.Get();
        PurchSetup.Validate("Posted Credit Memo Nos.", CreateNoSeriesCodeWithIntegers());
        PurchSetup.Modify(true);

        // [GIVEN] Create second purchase credit memo with No Taxable VAT. Amount in the line is "X"
        CreatePurchaseDocument(PurchaseHeader, VATPostingSetup, PurchaseHeader."Document Type"::"Credit Memo", LibraryRandom.RandDec(10, 2));
        LibraryPurchase.FindFirstPurchLine(PurchaseLine, PurchaseHeader);

        // [WHEN] Post second purchase credit memo
        DocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Only one additional No Taxable Entry creates with Base = "X"
        Assert.RecordCount(NoTaxableEntry, NoTaxableEntryCount + 1);
        NoTaxableEntry.SetRange("Document No.", DocNo);
        NoTaxableEntry.FindLast();
        NoTaxableEntry.TestField(Base, -PurchaseLine.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoTaxableEntryCreatesIndividuallyForEachSalesInvoice()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        NoTaxableEntry: Record "No Taxable Entry";
        SalesSetup: Record "Sales & Receivables Setup";
        NoTaxableEntryCount: Integer;
        DocNo: Code[20];
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 420328] No Taxable Entry creates individually for each posted sales invoice

        Initialize();

        // [GIVEN] Post first sales invoice with No Taxable VAT
        FindVATPostingSetupWithNoTaxableVAT(VATPostingSetup);
        CreateSalesDocument(SalesHeader, VATPostingSetup, SalesHeader."Document Type"::Invoice, LibraryRandom.RandDec(10, 2));
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        NoTaxableEntryCount := NoTaxableEntry.Count();

        // [GIVEN] Set a new No. Series code to the "Posted Invoice Nos." in Sales Setup to start numeration from the "001" document
        SalesSetup.Get();
        SalesSetup.Validate("Posted Invoice Nos.", CreateNoSeriesCodeWithIntegers());
        SalesSetup.Modify(true);

        // [GIVEN] Create second sales invoice with No Taxable VAT. Amount in the line is "X"
        CreateSalesDocument(SalesHeader, VATPostingSetup, SalesHeader."Document Type"::Invoice, LibraryRandom.RandDec(10, 2));
        LibrarySales.FindFirstSalesLine(SalesLine, SalesHeader);

        // [WHEN] Post second sales invoice
        DocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Only one additional No Taxable Entry creates with Base = "X"
        Assert.RecordCount(NoTaxableEntry, NoTaxableEntryCount + 1);
        NoTaxableEntry.SetRange("Document No.", DocNo);
        NoTaxableEntry.FindLast();
        NoTaxableEntry.TestField(Base, -SalesLine.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoTaxableEntryCreatesIndividuallyForEachSalesCrMemo()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        NoTaxableEntry: Record "No Taxable Entry";
        SalesSetup: Record "Sales & Receivables Setup";
        NoTaxableEntryCount: Integer;
        DocNo: Code[20];
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 420328] No Taxable Entry creates individually for each posted sales credit memo

        Initialize();

        // [GIVEN] Post first sales credit memo with No Taxable VAT
        FindVATPostingSetupWithNoTaxableVAT(VATPostingSetup);
        CreateSalesDocument(SalesHeader, VATPostingSetup, SalesHeader."Document Type"::"Credit Memo", LibraryRandom.RandDec(10, 2));
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        NoTaxableEntryCount := NoTaxableEntry.Count();

        // [GIVEN] Set a new No. Series code to the "Posted Credit Memo Nos." in Sales Setup to start numeration from the "001" document
        SalesSetup.Get();
        SalesSetup.Validate("Posted Credit Memo Nos.", CreateNoSeriesCodeWithIntegers());
        SalesSetup.Modify(true);

        // [GIVEN] Create second sales credit memo with No Taxable VAT. Amount in the line is "X"
        CreateSalesDocument(SalesHeader, VATPostingSetup, SalesHeader."Document Type"::"Credit Memo", LibraryRandom.RandDec(10, 2));
        LibrarySales.FindFirstSalesLine(SalesLine, SalesHeader);

        // [WHEN] Post second sales credit memo
        DocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Only one additional No Taxable Entry creates with Base = "X"
        Assert.RecordCount(NoTaxableEntry, NoTaxableEntryCount + 1);
        NoTaxableEntry.SetRange("Document No.", DocNo);
        NoTaxableEntry.FindLast();
        NoTaxableEntry.TestField(Base, SalesLine.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoTaxableEntriesPage()
    var
        NoTaxableEntries: TestPage "No Taxable Entries";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 437076] Closed field is accessible on No Taxable Entries Page
        NoTaxableEntries.OpenView();
        Assert.IsTrue(NoTaxableEntries.Closed.Enabled(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseInvoiceWithMultipleNoTaxableEntries()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATPostingSetup2: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        ItemNo1: Code[20];
        ItemNo2: Code[20];
        VendorNo: Code[20];
        PostingDate: Date;
    begin
        // [SCENARIO 527243] Stan Post multiple No Taxabale Entries when Purchase Invoice posted With Same 
        // "VAT Bus. Posting Group" and different "VAT Product Posting Group"
        Initialize();

        // [GIVEN] Two different VAT Posting Setup with "VAT Calculation Type" = "No Taxable VAT"
        CreateNoTaxableVATPostingSetup(VATPostingSetup, false);
        CreateVATPostingSetupForBusGroup(VATPostingSetup2, VATPostingSetup."VAT Bus. Posting Group");
        VATPostingSetup2.Validate("VAT Calculation Type", VATPostingSetup2."VAT Calculation Type"::"No Taxable VAT");
        VATPostingSetup2.Modify(true);

        // [GIVEN] Create Vendor with VAT Registration No.
        VendorNo := CreateVendor(EUCountryCodeTxt, VATPostingSetup."VAT Bus. Posting Group", LibraryERM.GenerateVATRegistrationNo(EUCountryCodeTxt));

        // [GIVEN] Set Posting Date
        PostingDate := GetNewWorkDate();

        // [GIVEN] Create Item with Unit Cost
        ItemNo1 := CreateItemWithUnitCost(VATPostingSetup."VAT Prod. Posting Group");
        ItemNo2 := CreateItemWithUnitCost(VATPostingSetup2."VAT Prod. Posting Group");

        // [GIVEN] Create Purchase Invoice has two lines with "No Taxable VAT"
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo, PostingDate);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo1, LibraryRandom.RandIntInRange(10, 20));
        LibraryPurchase.CreatePurchaseLine(PurchaseLine2, PurchaseHeader, PurchaseLine2.Type::Item, ItemNo2, LibraryRandom.RandIntInRange(10, 20));

        // [WHEN] Post the Purchase Invoice
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Verify the multiple No Taxable Entries has been created.
        VerifyMultipleNoTaxableEntriesCreated(VendorNo, 2);
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentGetReceiptLinesModalPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceWithDifferentVATCombinationsAndItemCharges()
    var
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
        GenProductPostingGroup: array[3] of Record "Gen. Product Posting Group";
        GeneralPostingSetup: Record "General Posting Setup";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATProductPostingGroup: array[3] of Record "VAT Product Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
        ItemCharge: array[3] of Record "Item Charge";
        Vendor: Record Vendor;
        VATEntry: Record "VAT Entry";
        DocumentNo: Code[20];
    begin
        // [SCENARIO 538908] Purchase Invoice with different VAT Combinations and Item Charges produces wrong VAT Amount in the Spanish version.
        Initialize();

        // [GIVEN] Create General/VAT Posting Setup with their Business Posting Group X, and 3 different General/VAT Product Posting Group
        CreateGeneralPostingSetupWithGenBusAndProdPostingGroup(GenBusinessPostingGroup, GenProductPostingGroup, GeneralPostingSetup);
        CreateVATPostingSetupWithVATBusAndProdPostingGroups(VATBusinessPostingGroup, VATProductPostingGroup, VATPostingSetup);

        // [GIVEN] Create 3 different Item Charges for all General/VAT Product Posting Groups
        CreateItemChargesWithGenProdandVATProdPostingGroups(ItemCharge, GenProductPostingGroup, VATProductPostingGroup);

        // [GIVEN] Create Vendor and Update General/VAT Business Posting Groups on Vendor
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Gen. Bus. Posting Group", GenBusinessPostingGroup.Code);
        Vendor.Validate("VAT Bus. Posting Group", VATBusinessPostingGroup.Code);
        Vendor.Modify(true);

        // [THEN] Create and post multiple Purchase Orders with Item to use later with Charge Item Assignment
        CreateAndPostPurchaseOrderWithItem(Vendor."No.", GenProductPostingGroup, VATProductPostingGroup);

        // [WHEN] Post Purchase Invoice with Item Charge Lines
        DocumentNo := PostPurchaseInvoiceWithItemChargeLines(VATPostingSetup, GenProductPostingGroup, VATProductPostingGroup, ItemCharge, Vendor."No.");

        // [THEN] Verify: All posted VAT Entries with VAT % Zero contains Amount as Zero
        VATEntry.SetRange("Document No.", DocumentNo);
        if VATEntry.FindSet() then
            repeat
                if VATEntry."VAT %" = 0 then
                    VATEntry.TestField(Amount, 0);
            until VATEntry.Next() = 0;
    end;

    [Test]
    [HandlerFunctions('PurchasesInvoiceBookRequestPageHandler')]
    procedure SumCorrectlyNonDeductibleVATAndBaseAmount()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        Vendor: Record Vendor;
        DimensionValue: array[4] of Record "Dimension Value";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: array[4] of Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        VATEntry: Record "VAT Entry";
        PurchaseInvoiceBook: Report "Purchases Invoice Book";
        ItemNo: array[4] of Code[20];
        Quantity: Integer;
        DirectUnitCost: array[4] of Integer;
        i: Integer;
        ExpectedValue: Integer;
    begin
        // [SCENARIO 544316] When Stan runs Purchase Invoice Book Report then Non Deductible VAT Base and VAT Amount Summing Correctly.
        Initialize();

        // [GIVEN] Create a VAT Posting Setup.
        LibraryNonDeductibleVAT.CreateVATPostingSetupWithNonDeductibleDetail(VATPostingSetup, 21, 60);

        // [GIVEN] Create a General Posting Setup.
        CreateGeneralPostingSetup(GeneralPostingSetup);

        // [GIVEN] Create a Vendor.
        CreateVendorWithPostingGroup(Vendor, GeneralPostingSetup, VATPostingSetup);

        // [GIVEN] Create Dimension with two Dimension Values.
        CreateDimensionsWithValues(DimensionValue);

        // [GIVEN] Create a Item No with Posting Setup.
        for i := 1 to 4 do
            ItemNo[i] := LibraryInventory.CreateItemNoWithPostingSetup(
                GeneralPostingSetup."Gen. Prod. Posting Group",
                VATPostingSetup."VAT Prod. Posting Group");

        // [GIVEN] Generate a Quantity and save it in a Variable.
        Quantity := LibraryRandom.RandInt(0);

        // [GIVEN] Generate a Direct Unit Cost and save it in a Variable.
        GenerateDirectUnitCost(DirectUnitCost);

        // [GIVEN] Create a Purchase Header.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");

        // [GIVEN] Update "Vendor Invoice No.".
        UpdatePurchInvoiceNo(PurchaseHeader);

        // [GIVEN] Create a Purchase Line and Validate "Direct Unit Cost" and "Shortcut Dimension 1 Code".
        for i := 1 to 4 do begin
            LibraryPurchase.CreatePurchaseLine(PurchaseLine[i], PurchaseHeader, PurchaseLine[i].Type::Item, ItemNo[i], Quantity);
            PurchaseLine[i].Validate("Direct Unit Cost", DirectUnitCost[i]);
            PurchaseLine[i].Validate("Shortcut Dimension 1 Code", DimensionValue[i].Code);
            PurchaseLine[i].Modify(true);
        end;

        // [WHEN] Purchase Invoice is Posted. 
        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));

        // [GIVEN] Generate and save Expected Value in a Variable.
        ExpectedValue := LibraryRandom.RandIntInRange(2, 2);

        // [WHEN] Retrieve VAT Entry.
        GetVATEntry(VATEntry, PurchInvHeader."No.");

        // [THEN Verify Count of VAT Entry.
        Assert.AreEqual(2, VATEntry.Count, StrSubstNo(VATEntryMustExistMsgLbl, ExpectedValue));

        // [WHEN] Run Purchase Invoice Book Report. 
        LibraryVariableStorage.Enqueue(PurchInvHeader."No.");
        Clear(PurchaseInvoiceBook);
        PurchaseInvoiceBook.SetTableView(VATEntry);
        PurchaseInvoiceBook.Run();
        LibraryReportDataset.LoadDataSetFile();

        // [THEN] Verify Non Deductible VAT Base and Non Deductible VAT Amount are summing up correctly. 
        LibraryReportDataset.AssertElementWithValueExists(
            'VATEntry2_NonDeductibleVATBase', VATEntry."Non-Deductible VAT Base");
        LibraryReportDataset.AssertElementWithValueExists(
            'VATEntry2_NonDeductibleVATAmt', VATEntry."Non-Deductible VAT Amount");
    end;

    [Test]
    [HandlerFunctions('PurchasesInvoiceBookRequestPageHandler')]
    procedure TotalAmountIsCorrectWhenUsingNonDeductibleVAT()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        VATEntry: Record "VAT Entry";
        PurchaseInvoiceBook: Report "Purchases Invoice Book";
        ItemNo: Code[20];
        Quantity: Integer;
        DirectUnitCost: Integer;
    begin
        // [SCENARIO 546807] When Stan runs Purchase Invoice Book Report then Total Field Includes Base, Amount, Non Deductible VAT Base and VAT Amount.
        Initialize();

        // [GIVEN] Create a VAT Posting Setup.
        LibraryNonDeductibleVAT.CreateVATPostingSetupWithNonDeductibleDetail(VATPostingSetup, 21, 60);

        // [GIVEN] Create a General Posting Setup.
        CreateGeneralPostingSetup(GeneralPostingSetup);

        // [GIVEN] Create a Vendor.
        CreateVendorWithPostingGroup(Vendor, GeneralPostingSetup, VATPostingSetup);

        // [GIVEN] Create a Item No with Posting Setup.
        ItemNo := LibraryInventory.CreateItemNoWithPostingSetup(
            GeneralPostingSetup."Gen. Prod. Posting Group",
            VATPostingSetup."VAT Prod. Posting Group");

        // [GIVEN] Generate a Quantity and save it in a Variable.
        Quantity := LibraryRandom.RandInt(0);

        // [GIVEN] Generate a Direct Unit Cost and save it in a Variable.
        DirectUnitCost := LibraryRandom.RandIntInRange(1000, 1000);

        // [GIVEN] Create a Purchase Header.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");

        // [GIVEN] Update "Vendor Invoice No.".
        UpdatePurchInvoiceNo(PurchaseHeader);

        // [GIVEN] Create a Purchase Line and Validate "Direct Unit Cost".
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);

        // [WHEN] Purchase Invoice is Posted. 
        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));

        // [THEN] Retrieve VAT Entry.
        GetVATEntry(VATEntry, PurchInvHeader."No.");

        // [WHEN] Run Purchase Invoice Book Report. 
        LibraryVariableStorage.Enqueue(PurchInvHeader."No.");
        Clear(PurchaseInvoiceBook);
        PurchaseInvoiceBook.SetTableView(VATEntry);
        PurchaseInvoiceBook.Run();
        LibraryReportDataset.LoadDataSetFile();

        // [THEN] Verify Total Amount Field Included Base, Amount, Non-Deductible VAT Base, Non-Deductible VAT Amount. 
        LibraryReportDataset.AssertElementWithValueExists(
            'VATEntry2_TotalAmount',
            VATEntry.Base +
            VATEntry.Amount +
            VATEntry."Non-Deductible VAT Base" +
            VATEntry."Non-Deductible VAT Amount");
    end;

    [Test]
    [HandlerFunctions('PurchasesInvoiceBookRequestPageHandler')]
    procedure NonDeductibleVATAndBaseAmountHasValuesWhenDifferentVATPercentInSameDocumentNo()
    var
        VATPostingSetup: array[2] of Record "VAT Posting Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        GLAccount: Record "G/L Account";
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: array[2] of Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        VATEntry: Record "VAT Entry";
        PurchaseInvoiceBook: Report "Purchases Invoice Book";
        i: Integer;
    begin
        // [SCENARIO 545171] When Stan runs Purchase Invoice Book Report then Non Deductible VAT Base and VAT Amount having Correct Values.
        Initialize();

        // [GIVEN] Create a VAT Posting Setup.
        LibraryNonDeductibleVAT.CreateVATPostingSetupWithNonDeductibleDetail(VATPostingSetup[1], 21, 50);
        CreateVATPostingSetUpWithZeroPercent(
            VATPostingSetup[2], VATPostingSetup[1]."VAT Bus. Posting Group",
            VATPostingSetup[1]."Sales VAT Account", VATPostingSetup[1]."Purchase VAT Account");

        // [GIVEN] Create a General Posting Setup.
        CreateGeneralPostingSetup(GeneralPostingSetup);

        // [GIVEN] Create a Vendor.
        CreateVendorWithPostingGroup(Vendor, GeneralPostingSetup, VATPostingSetup[1]);

        // [GIVEN] Create a G/L Account No.
        GLAccount.Get(LibraryERM.CreateGLAccountNoWithDirectPosting());
        LibraryERM.UpdateGLAccountWithPostingSetup(
            GLAccount, GLAccount."Gen. Posting Type"::Purchase,
            GeneralPostingSetup, VATPostingSetup[1]);

        // [GIVEN] Create a Purchase Header.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");

        // [GIVEN] Update "Vendor Invoice No.".
        UpdatePurchInvoiceNo(PurchaseHeader);

        // [GIVEN] Create Purchase Lines.
        for i := 1 to 2 do begin
            LibraryPurchase.CreatePurchaseLine(
                PurchaseLine[i], PurchaseHeader,
                PurchaseLine[i].Type::"G/L Account", GLAccount."No.",
                LibraryRandom.RandInt(0));
            PurchaseLine[i].Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(5, 10, 2));
            PurchaseLine[i].Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
            PurchaseLine[i].Validate("VAT Prod. Posting Group", VATPostingSetup[i]."VAT Prod. Posting Group");
            PurchaseLine[i].Modify(true);
        end;

        // [GIVEN] Purchase Invoice is Posted. 
        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));

        // [GIVEN] Retrieve VAT Entry.
        GetVATEntry(VATEntry, PurchInvHeader."No.");

        // [WHEN] Run Purchase Invoice Book Report. 
        LibraryVariableStorage.Enqueue(PurchInvHeader."No.");
        Clear(PurchaseInvoiceBook);
        PurchaseInvoiceBook.SetTableView(VATEntry);
        PurchaseInvoiceBook.Run();
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('VATEntry2__Document_No__', PurchInvHeader."No.");

        // [THEN] Verify Non Deductible VAT Base and Non Deductible VAT Amount are having correct values. 
        LibraryReportDataset.AssertElementWithValueExists(
            'VATEntry2_NonDeductibleVATBase', VATEntry."Non-Deductible VAT Base");
        LibraryReportDataset.AssertElementWithValueExists(
            'VATEntry2_NonDeductibleVATAmt', VATEntry."Non-Deductible VAT Amount");
    end;

    [Test]
    [HandlerFunctions('AutoInvoicesListRequestPageHandler')]
    procedure AutoInvoiceListReportWithNonDeductibleVAT()
    var
        PurchaseLine: Record "Purchase Line";
        VATEntry: Record "VAT Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
        RequestPageXML: Text;
    begin
        // [SCENARIO 565480] Verify AutoInvoices List report should display the non-deductible operations.
        Initialize();

        // [GIVEN] Create VAT Posting Setup With Non-Deductible VAT 100 %.
        CreateHundredPctNDReverseChargeVATPostingSetup(VATPostingSetup);

        // [GIVEN] Post Purchase Invoice.
        DocumentNo := CreatePostPurchInvoiceWithVATSetup(PurchaseLine, VATPostingSetup);

        // [GIVEN] Find VAT Entry
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.FindFirst();

        // [WHEN] Run AutoInvoices Report.
        Commit(); // Commit required before running this Report.
        RequestPageXML := Report.RunRequestPage(Report::"AutoInvoices List", RequestPageXML);
        LibraryReportDataset.RunReportAndLoad(Report::"AutoInvoices List", VATEntry, RequestPageXML);

        // [THEN] Verify Non-Deductible Operations.
        LibraryReportDataset.AssertElementWithValueExists('VATBuffer2__VAT___NonDeductibleVAT___', VATEntry."Non-Deductible VAT %");
        LibraryReportDataset.AssertElementWithValueExists('VATBuffer2_NonDeductibleVATBase', VATEntry."Non-Deductible VAT Base");
        LibraryReportDataset.AssertElementWithValueExists('VATBuffer2_NonDeductibleVATAmt', VATEntry."Non-Deductible VAT Amount");
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;

        LibrarySetupStorage.SavePurchasesSetup();
        LibrarySetupStorage.SaveSalesSetup();
        Commit();
        IsInitialized := true;
    end;

    local procedure CreateGLAccountWithNoTaxableVAT(): Code[20]
    var
        GeneralPostingSetup: Record "General Posting Setup";
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        FindVATPostingSetupWithNoTaxableVAT(VATPostingSetup);
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        GeneralPostingSetup.Validate("COGS Account", GLAccount."No.");
        GeneralPostingSetup.Modify(true);
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateNoTaxGLAccNotIn347Report(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Get(CreateGLAccountWithNoTaxableVAT());
        GLAccount.Validate("Ignore in 347 Report", true);
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateItem(VATProdPostingGroup: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateItemCharge(VATProdPostingGroup: Code[20]): Code[20]
    var
        ItemCharge: Record "Item Charge";
    begin
        LibraryInventory.CreateItemCharge(ItemCharge);
        ItemCharge.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        ItemCharge.Modify(true);
        exit(ItemCharge."No.");
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; VATPostingSetup: Record "VAT Posting Setup"; DocumentType: Enum "Purchase Document Type"; Quantity: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Vendor.Modify(true);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, Vendor."No.");
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."Buy-from Vendor No.");
        PurchaseHeader.Modify(true);
        CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(VATPostingSetup."VAT Prod. Posting Group"), Quantity);
    end;

    local procedure CreatePurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; Type: Enum "Purchase Line Type"; No: Code[20]; Quantity: Decimal)
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Type, No, Quantity);
        PurchaseLine.Validate("Direct Unit Cost", Quantity);  // Validating Direct Unit Cost as Quantity because value is not important.
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; VATPostingSetup: Record "VAT Posting Setup"; DocumentType: Enum "Sales Document Type"; Quantity: Decimal)
    var
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Modify(true);
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, Customer."No.");
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(VATPostingSetup."VAT Prod. Posting Group"), Quantity);
    end;

    local procedure CreateSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; Type: Enum "Sales Line Type"; No: Code[20]; Quantity: Decimal)
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Type, No, Quantity);
        SalesLine.Validate("Unit Price", Quantity);  // Validating Unit Price as Quantity because value is not important.
        SalesLine.Modify(true);
    end;

    local procedure FindVATPostingSetupWithNoTaxableVAT(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        VATPostingSetup.SetFilter("VAT Bus. Posting Group", StrSubstNo(NotEqualToTxt, ''));  // Blank used for Not Equal to Blank filter.
        VATPostingSetup.SetFilter("VAT Prod. Posting Group", StrSubstNo(NotEqualToTxt, ''));  // Blank used for Not Equal to Blank filter.
        VATPostingSetup.SetRange("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"No Taxable VAT");
        VATPostingSetup.FindFirst();
    end;

    local procedure PostSalesDocumentWithNoTaxableVAT(DocumentType: Enum "Sales Document Type")
    var
        SalesHeader: Record "Sales Header";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
    begin
        // Setup.
        Initialize();
        FindVATPostingSetupWithNoTaxableVAT(VATPostingSetup);
        CreateSalesDocument(SalesHeader, VATPostingSetup, DocumentType, LibraryRandom.RandDec(10, 2));  // Random value used for Quantity.

        // Exercise.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);  // Post as Ship and Invoice.

        // Verify.
        VerifyNoVATEntryExist(DocumentNo);
    end;

    local procedure SalesInvoiceBookReportWithNoTaxableVAT(DocumentType: Enum "Sales Document Type"; Quantity: Decimal; GLAccNo: Code[20]; Sign: Integer)
    var
        SalesLineChargeItem: Record "Sales Line";
        SalesLineGLAccount: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
        Amount: Decimal;
        VATAmount: Decimal;
    begin
        // Setup: Create Sales Document with Normal VAT for Item and Item Charge, No Taxable VAT for G/L Account. Post Sales Document.
        PostSalesDocForNoTaxableScenario(
          DocumentNo, SalesLineChargeItem, SalesLineGLAccount, DocumentType, Quantity, GLAccNo);
        LibraryVariableStorage.Enqueue(DocumentNo);  // Enqueue for SalesInvoiceBookRequestPageHandler.
        Amount := Sign * Quantity * SalesLineChargeItem."Unit Price";
        VATPostingSetup.Get(SalesLineChargeItem."VAT Bus. Posting Group", SalesLineChargeItem."VAT Prod. Posting Group");
        VATAmount := Amount * VATPostingSetup."VAT %" / 100;

        // Exercise.
        REPORT.Run(REPORT::"Sales Invoice Book");  // Opens SalesInvoiceBookRequestPageHandler.

        // Verify: Sales Invoice Book report shows Amounts for Item and Item Charge Sales lines and not for G/L Account.
        VerifyXmlValuesOnReport(
          VATAmount + VATAmount, Amount + Amount, DocumentNo,
          SalesLineGLAccount."Sell-to Customer No.", Sign * SalesLineGLAccount.Amount);
    end;

    local procedure PostPurchaseDocumentWithNoTaxableVAT(DocumentType: Enum "Purchase Document Type")
    var
        PurchaseHeader: Record "Purchase Header";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
    begin
        // Setup.
        Initialize();
        FindVATPostingSetupWithNoTaxableVAT(VATPostingSetup);
        CreatePurchaseDocument(PurchaseHeader, VATPostingSetup, DocumentType, LibraryRandom.RandDec(10, 2));  // Random value used for Quantity.

        // Exercise.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // Post as Receive and Invoice.

        // Verify.
        VerifyNoVATEntryExist(DocumentNo);
    end;

    local procedure PurchaseInvoiceBookReportWithNoTaxableVAT(DocumentType: Enum "Purchase Document Type"; Quantity: Decimal; GLAccNo: Code[20]; Sign: Integer)
    var
        PurchaseLineChargeItem: Record "Purchase Line";
        PurchaseLineGLAccount: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
        Amount: Decimal;
        VATAmount: Decimal;
    begin
        PostPurchDocForNoTaxableScenario(
          DocumentNo, PurchaseLineChargeItem, PurchaseLineGLAccount, DocumentType, Quantity, GLAccNo);

        LibraryVariableStorage.Enqueue(DocumentNo);  // Enqueue for PurchasesInvoiceBookRequestPageHandler.
        Amount := Sign * Quantity * PurchaseLineChargeItem."Direct Unit Cost";
        VATPostingSetup.Get(PurchaseLineChargeItem."VAT Bus. Posting Group", PurchaseLineChargeItem."VAT Prod. Posting Group");
        VATAmount := Amount * VATPostingSetup."VAT %" / 100;

        // Exercise.
        REPORT.Run(REPORT::"Purchases Invoice Book");  // Opens PurchasesInvoiceBookRequestPageHandler.

        // Verify: Purchases Invoice Book report shows Amounts for Item and Item Charge Purchase lines and not for G/L Account.
        VerifyXmlValuesOnReport(
          VATAmount + VATAmount, Amount + Amount, DocumentNo,
          PurchaseLineGLAccount."Buy-from Vendor No.", Sign * PurchaseLineGLAccount.Amount);
    end;

    local procedure PostSalesDocForNoTaxableScenario(var DocumentNo: Code[20]; var SalesLineChargeItem: Record "Sales Line"; var SalesLineGLAccount: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; Quantity: Decimal; GLAccNo: Code[20])
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreateSalesDocument(SalesHeader, VATPostingSetup, DocumentType, Quantity);
        CreateSalesLine(
          SalesLineChargeItem, SalesHeader, SalesLineChargeItem.Type::"Charge (Item)",
          CreateItemCharge(VATPostingSetup."VAT Prod. Posting Group"), Quantity);
        SalesLineChargeItem.ShowItemChargeAssgnt();
        CreateSalesLine(
          SalesLineGLAccount, SalesHeader, SalesLineGLAccount.Type::"G/L Account", GLAccNo, LibraryRandom.RandDec(10, 2));  // Random value used for Quantity.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);  // Post as Ship and Invoice.
    end;

    local procedure PostPurchDocForNoTaxableScenario(var DocumentNo: Code[20]; var PurchLineChargeItem: Record "Purchase Line"; var PurchLineGLAccount: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; Quantity: Decimal; GLAccNo: Code[20])
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreatePurchaseDocument(PurchaseHeader, VATPostingSetup, DocumentType, Quantity);
        CreatePurchaseLine(
          PurchLineChargeItem, PurchaseHeader, PurchLineChargeItem.Type::"Charge (Item)",
          CreateItemCharge(VATPostingSetup."VAT Prod. Posting Group"), Quantity);
        PurchLineChargeItem.ShowItemChargeAssgnt();
        CreatePurchaseLine(
          PurchLineGLAccount, PurchaseHeader, PurchLineGLAccount.Type::"G/L Account", GLAccNo, LibraryRandom.RandDec(10, 2));  // Random value used for Quantity.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // Post as Ship and Invoice.
    end;

    local procedure CreateNoSeriesCodeWithIntegers(): Code[20]
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        LibraryUtility.CreateNoSeries(NoSeries, true, true, false);
        LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, '001', '999');
        exit(NoSeries.Code);
    end;

    local procedure VerifyNoVATEntryExist(DocumentNo: Code[20])
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document No.", DocumentNo);
        Assert.IsFalse(VATEntry.FindFirst(), VATEntryMustNotExistMsg);
    end;

    local procedure VerifyXmlValuesOnReport(Amount: Decimal; Base: Decimal; DocumentNo: Code[20]; SourceNo: Code[20]; NoTaxAmount: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(VATBufferAmountCap, Amount);
        LibraryReportDataset.AssertElementWithValueExists(VATBufferBaseCap, Base);
        LibraryReportDataset.AssertElementWithValueExists(VATBufferBaseAmountCap, Base + Amount);
        LibraryReportDataset.SetRange('SourceNo_NoTaxableEntry', SourceNo);
        LibraryReportDataset.AssertElementWithValueExists('DocumentNo_NoTaxableEntry', DocumentNo);
        LibraryReportDataset.AssertElementWithValueExists('Base_NoTaxableEntry', NoTaxAmount);
    end;

    local procedure VerifyNoXmlValuesOnReport(DocumentNo: Code[20]; SourceNo: Code[20]; NoTaxAmount: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('SourceNo_NoTaxableEntry', SourceNo);
        LibraryReportDataset.AssertElementWithValueNotExist('DocumentNo_NoTaxableEntry', DocumentNo);
        LibraryReportDataset.AssertElementWithValueNotExist('Base_NoTaxableEntry', NoTaxAmount);
    end;

    local procedure VerifyMultipleNoTaxableEntriesCreated(SourceNo: Code[20]; ExpectedValue: Integer)
    var
        NoTaxableEntry: Record "No Taxable Entry";
    begin
        NoTaxableEntry.SetRange("Source No.", SourceNo);
        NoTaxableEntry.FindSet();
        Assert.AreEqual(ExpectedValue, NoTaxableEntry.Count, NoTaxableEntryErr);
    end;

    local procedure CreateNoTaxableVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; EUService: Boolean)
    begin
        CreateVATPostingSetup(VATPostingSetup, EUService);
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"No Taxable VAT");
        VATPostingSetup.Modify(true);
    end;

    local procedure CreateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; EUService: Boolean)
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroup.Code, VATProductPostingGroup.Code);
        VATPostingSetup.Validate("EU Service", EUService);
        VATPostingSetup.Modify(true);
    end;

    local procedure CreateVATPostingSetupForBusGroup(var VATPostingSetup: Record "VAT Posting Setup"; VATBusGroupCode: Code[20])
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusGroupCode, VATProductPostingGroup.Code);
    end;

    local procedure CreateVendor(CountryRegionCode: Code[10]; VATBusPostingGroup: Code[20]; VATRegistrationNo: Text): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Vendor.Validate("Country/Region Code", CountryRegionCode);
        Vendor.Validate("VAT Registration No.", VATRegistrationNo);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateItemWithUnitCost(VATProdPostingGroup: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        Item.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        Item.Validate("Last Direct Cost", LibraryRandom.RandDec(100, 2));
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure GetNewWorkDate(): Date
    var
        GLRegister: Record "G/L Register";
    begin
        GLRegister.SetCurrentKey("Posting Date");
        GLRegister.FindLast();
        exit(CalcDate('<1Y>', GLRegister."Posting Date"));
    end;

    local procedure CreatePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20]; PostingDate: Date)
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate("Posting Date", PostingDate);
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
    end;

    local procedure CreateGeneralPostingSetupWithGenBusAndProdPostingGroup(
        var GenBusinessPostingGroup: Record "Gen. Business Posting Group";
        var GenProductPostingGroup: array[3] of Record "Gen. Product Posting Group";
        var GeneralPostingSetup: Record "General Posting Setup")
    var
        i: Integer;
    begin
        LibraryERM.CreateGenBusPostingGroup(GenBusinessPostingGroup);
        for i := 1 to ArrayLen(GenProductPostingGroup) do begin
            LibraryERM.CreateGenProdPostingGroup(GenProductPostingGroup[i]);
            LibraryERM.CreateGeneralPostingSetup(GeneralPostingSetup, GenBusinessPostingGroup.Code, GenProductPostingGroup[i].Code);
            GeneralPostingSetup.Validate("Sales Account", LibraryERM.CreateGLAccountNo());
            GeneralPostingSetup.Validate("Purch. Account", LibraryERM.CreateGLAccountNo());
            GeneralPostingSetup.Validate("COGS Account", LibraryERM.CreateGLAccountNo());
            GeneralPostingSetup.Validate("Inventory Adjmt. Account", LibraryERM.CreateGLAccountNo());
            GeneralPostingSetup.Validate("Direct Cost Applied Account", LibraryERM.CreateGLAccountNo());
            GeneralPostingSetup.Modify(true);
        end;
    end;

    local procedure CreateVATPostingSetupWithVATBusAndProdPostingGroups(
        var VATBusinessPostingGroup: Record "VAT Business Posting Group";
        var VATProductPostingGroup: array[3] of Record "VAT Product Posting Group";
        var VATPostingSetup: Record "VAT Posting Setup")
    var
        SalesVATAccount: Code[20];
        PurchVATAccount: Code[20];
        VATRate: Decimal;
        i: Integer;
    begin
        VATRate := 0;
        SalesVATAccount := LibraryERM.CreateGLAccountNo();
        PurchVATAccount := LibraryERM.CreateGLAccountNo();
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);

        for i := 1 to ArrayLen(VATProductPostingGroup) do begin
            VATPostingSetup.Init();
            LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup[i]);
            LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroup.Code, VATProductPostingGroup[i].Code);
            VATPostingSetup.Validate("VAT Bus. Posting Group", VATBusinessPostingGroup.Code);
            VATPostingSetup.Validate("VAT Prod. Posting Group", VATProductPostingGroup[i].Code);
            VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
            VATPostingSetup.Validate("VAT %", VATRate);
            VATPostingSetup.Validate("VAT Identifier", 'VI' + Format(VATRate));
            VATPostingSetup.Validate("Sales VAT Account", SalesVATAccount);
            VATPostingSetup.Validate("Purchase VAT Account", PurchVATAccount);
            VATPostingSetup.Validate("Reverse Chrg. VAT Acc.", LibraryERM.CreateGLAccountNo());
            VATPostingSetup.Validate("Tax Category", 'S');
            VATRate := LibraryRandom.RandDecInRange(21, 21, 2);
            VATPostingSetup.Modify(true);
        end;
    end;

    local procedure CreateItemChargesWithGenProdandVATProdPostingGroups(
        var ItemCharge: array[3] of Record "Item Charge";
        GenProductPostingGroup: array[3] of Record "Gen. Product Posting Group";
        VATProductPostingGroup: array[3] of Record "VAT Product Posting Group")
    var
        i: Integer;
    begin
        for i := 1 to ArrayLen(ItemCharge) do begin
            LibraryInventory.CreateItemCharge(ItemCharge[i]);
            ItemCharge[i].Validate("Gen. Prod. Posting Group", GenProductPostingGroup[i].Code);
            ItemCharge[i].Validate("VAT Prod. Posting Group", VATProductPostingGroup[i].Code);
            ItemCharge[i].Modify(true);
        end;
    end;


    local procedure CreateAndPostPurchaseOrderWithItem(
        VendorNo: Code[20];
        GenProductPostingGroup: array[3] of Record "Gen. Product Posting Group";
        VATProductPostingGroup: array[3] of Record "VAT Product Posting Group")
    var
        PurchaseHeaderOrder: Record "Purchase Header";
        PurchaseLineOrder: array[3] of Record "Purchase Line";
        Item: array[3] of Record Item;
        i: Integer;
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderOrder, PurchaseHeaderOrder."Document Type"::Order, VendorNo);
        for i := 1 to ArrayLen(Item) do begin
            LibraryInventory.CreateItem(Item[i]);
            Item[i].Validate("Gen. Prod. Posting Group", GenProductPostingGroup[i].Code);
            Item[i].Validate("VAT Prod. Posting Group", VATProductPostingGroup[1].Code);
            Item[i].Modify(true);
            LibraryPurchase.CreatePurchaseLine(
                PurchaseLineOrder[i], PurchaseHeaderOrder, PurchaseLineOrder[i].Type::Item,
                Item[i]."No.", LibraryRandom.RandIntInRange(5, 20));
            PurchaseLineOrder[i].Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(100, 200));
            PurchaseLineOrder[i].Modify(true);
        end;
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderOrder, true, true);
    end;

    local procedure PostPurchaseInvoiceWithItemChargeLines(
        VATPostingSetup: Record "VAT Posting Setup";
        GenProductPostingGroup: array[3] of Record "Gen. Product Posting Group";
        VATProductPostingGroup: array[3] of Record "VAT Product Posting Group";
        ItemCharge: array[3] of Record "Item Charge";
        VendorNo: Code[20]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchLineChargeItem: Record "Purchase Line";
        PurchLineGLAccount: Record "Purchase Line";
        i, index : Integer;
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        CreatePurchaseLine(
            PurchLineGLAccount, PurchaseHeader, PurchLineGLAccount.Type::"G/L Account",
            LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, "General Posting Type"::Purchase), LibraryRandom.RandIntInRange(1, 1));
        PurchLineGLAccount.Validate("VAT Prod. Posting Group", VATProductPostingGroup[2].Code);
        PurchLineGLAccount."Gen. Prod. Posting Group" := GenProductPostingGroup[2].Code;
        PurchLineGLAccount.Modify(true);

        for i := 1 to ArrayLen(ItemCharge) do begin
            PurchLineChargeItem.Reset();
            CreatePurchaseLine(PurchLineChargeItem, PurchaseHeader, PurchLineChargeItem.Type::"Charge (Item)", ItemCharge[i]."No.", 1);
            PurchLineChargeItem.Validate("Gen. Prod. Posting Group", GenProductPostingGroup[i].Code);
            PurchLineChargeItem.Validate("VAT Prod. Posting Group", VATProductPostingGroup[1].Code);
            PurchLineChargeItem.Modify(true);

            LibraryVariableStorage.Enqueue(ArrayLen(ItemCharge));
            for index := 1 to ArrayLen(ItemCharge) do
                LibraryVariableStorage.Enqueue(PurchLineChargeItem.Quantity);

            GetReceiptLinesForItemCharge(PurchLineChargeItem);
            Commit();
            PurchLineChargeItem.ShowItemChargeAssgnt();
        end;

        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));  // Post as Ship and Invoice.
    end;

    local procedure GetReceiptLinesForItemCharge(PurchaseLineSource: Record "Purchase Line")
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        ItemChargeAssgntPurch: Codeunit "Item Charge Assgnt. (Purch.)";
    begin
        PurchaseLineSource.TestField("Qty. to Invoice");

        PurchRcptLine.SetRange("Buy-from Vendor No.", PurchaseLineSource."Buy-from Vendor No.");
        PurchRcptLine.FindFirst();

        ItemChargeAssignmentPurch."Document Type" := PurchaseLineSource."Document Type";
        ItemChargeAssignmentPurch."Document No." := PurchaseLineSource."Document No.";
        ItemChargeAssignmentPurch."Document Line No." := PurchaseLineSource."Line No.";
        ItemChargeAssignmentPurch."Item Charge No." := PurchaseLineSource."No.";

        ItemChargeAssignmentPurch.SetRange("Document Type", PurchaseLineSource."Document Type");
        ItemChargeAssignmentPurch.SetRange("Document No.", PurchaseLineSource."Document No.");
        ItemChargeAssignmentPurch.SetRange("Document Line No.", PurchaseLineSource."Line No.");

        ItemChargeAssignmentPurch."Unit Cost" := PurchaseLineSource."Direct Unit Cost";
        ItemChargeAssgntPurch.CreateRcptChargeAssgnt(PurchRcptLine, ItemChargeAssignmentPurch);
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

    local procedure CreateDimensionsWithValues(var DimensionValue: array[2] of Record "Dimension Value")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        LibraryDimension.CreateDimensionValue(DimensionValue[1], GeneralLedgerSetup."Global Dimension 1 Code");
        LibraryDimension.CreateDimensionValue(DimensionValue[2], GeneralLedgerSetup."Global Dimension 1 Code");
        DimensionValue[3] := DimensionValue[1];
        DimensionValue[4] := DimensionValue[2];
    end;

    local procedure GenerateDirectUnitCost(var DirectUnitCost: array[4] of Integer)
    begin
        DirectUnitCost[1] := LibraryRandom.RandIntInRange(120000, 120000);
        DirectUnitCost[2] := LibraryRandom.RandIntInRange(48800, 48800);
        DirectUnitCost[3] := LibraryRandom.RandIntInRange(403644, 403644);
        DirectUnitCost[4] := LibraryRandom.RandIntInRange(150782, 150782);
    end;

    local procedure UpdatePurchInvoiceNo(var PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader.Find();
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);
    end;

    local procedure GetVATEntry(var VATEntry: Record "VAT Entry"; DocumentNo: Code[20])
    begin
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.CalcSums(
            Base, Amount,
            "Non-Deductible VAT Base", "Non-Deductible VAT Amount");
    end;

    local procedure CreateVATPostingSetUpWithZeroPercent(
        var VATPostingSetup: Record "VAT Posting Setup";
        VATBusPostingGroup: Code[20];
        SalesVATAccount: Code[20];
        PurchaseVATAccount: Code[20])
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusPostingGroup, VATProductPostingGroup.Code);
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.Validate("VAT %", 0);
        VATPostingSetup.Validate("Sales VAT Account", SalesVATAccount);
        VATPostingSetup.Validate("Purchase VAT Account", PurchaseVATAccount);
        VATPostingSetup.Modify(true);
    end;

    local procedure CreateHundredPctNDReverseChargeVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Bus. Posting Group", VATProductPostingGroup.Code);
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
        VATPostingSetup.Validate("VAT %", LibraryRandom.RandInt(10));
        VATPostingSetup.Validate("VAT Identifier", VATPostingSetup."VAT Prod. Posting Group");

        LibraryNonDeductibleVAT.SetAllowNonDeductibleVATForVATPostingSetup(VATPostingSetup);
        VATPostingSetup.Validate("Non-Deductible VAT %", 0);
        VATPostingSetup.Validate("Purchase VAT Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("Reverse Chrg. VAT Acc.", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("Sales VAT Account", LibraryERM.CreateGLAccountNo());
        LibraryNonDeductibleVAT.SetAllowNonDeductibleVATForVATPostingSetup(VATPostingSetup);
        VATPostingSetup.Validate("Non-Ded. Purchase VAT Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Modify(true);
    end;

    local procedure CreateGLAccount(VATPostingSetup: Record "VAT Posting Setup"; GenPostingType: Enum "General Posting Type"): Code[20]
    var
        GLAccount: Record "G/L Account";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount.Validate("Gen. Posting Type", GenPostingType);
        GLAccount.Modify(true);

        exit(GLAccount."No.");
    end;

    local procedure CreatePostPurchInvoiceWithVATSetup(var PurchaseLine: Record "Purchase Line"; VATPostingSetup: Record "VAT Posting Setup"): Code[20]
    var
        GLAccount: Record "G/L Account";
        PurchaseHeader: Record "Purchase Header";
        GLAccountNo: Code[20];
    begin
        LibraryPurchase.CreatePurchHeader(
            PurchaseHeader, PurchaseHeader."Document Type"::Invoice, CreateVendor(VATPostingSetup."VAT Bus. Posting Group"));
        GLAccountNo :=
          CreateGLAccount(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccountNo, LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);

        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateVendor(VATBusPostingGroup: Code[20]): Code[20]
    var
        CompanyInformation: Record "Company Information";
        Vendor: Record Vendor;
    begin
        CompanyInformation.Get();
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Country/Region Code", CompanyInformation."Country/Region Code");
        Vendor.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Vendor.Modify(true);

        exit(Vendor."No.");
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    procedure ItemChargeAssignmentGetReceiptLinesModalPageHandler(var ItemChargeAssignmentPurch: TestPage "Item Charge Assignment (Purch)")
    var
        Index: Integer;
        "Count": Integer;
    begin
        Count := LibraryVariableStorage.DequeueInteger();

        ItemChargeAssignmentPurch.First();
        ItemChargeAssignmentPurch."Qty. to Assign".SetValue(LibraryVariableStorage.DequeueDecimal());

        for Index := 2 to Count do begin
            ItemChargeAssignmentPurch.Next();
            ItemChargeAssignmentPurch."Qty. to Assign".SetValue(LibraryVariableStorage.DequeueDecimal());
        end;

        ItemChargeAssignmentPurch.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemChargeAssignmentPurchModalPageHandler(var ItemChargeAssignmentPurch: TestPage "Item Charge Assignment (Purch)")
    begin
        ItemChargeAssignmentPurch.SuggestItemChargeAssignment.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemChargeAssignmentSalesModalPageHandler(var ItemChargeAssignmentSales: TestPage "Item Charge Assignment (Sales)")
    begin
        ItemChargeAssignmentSales.SuggestItemChargeAssignment.Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchasesInvoiceBookRequestPageHandler(var PurchasesInvoiceBook: TestRequestPage "Purchases Invoice Book")
    var
        DocumentNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNo);
        PurchasesInvoiceBook.VATEntry.SetFilter("Posting Date", Format(WorkDate()));
        PurchasesInvoiceBook.VATEntry.SetFilter("Document No.", DocumentNo);
        PurchasesInvoiceBook."No Taxable Entry".SetFilter("Document No.", DocumentNo);
        PurchasesInvoiceBook.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesInvoiceBookRequestPageHandler(var SalesInvoiceBook: TestRequestPage "Sales Invoice Book")
    var
        DocumentNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNo);
        SalesInvoiceBook.VATEntry.SetFilter("Posting Date", Format(WorkDate()));
        SalesInvoiceBook.VATEntry.SetFilter("Document No.", DocumentNo);
        SalesInvoiceBook."No Taxable Entry".SetFilter("Document No.", DocumentNo);
        SalesInvoiceBook.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    procedure AutoInvoicesListRequestPageHandler(var AutoInvoicesList: TestRequestPage "AutoInvoices List")
    begin
    end;
}

