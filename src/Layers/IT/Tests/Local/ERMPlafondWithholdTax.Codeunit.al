codeunit 144089 "ERM Plafond - Withhold Tax"
{
    // // [FEATURE] [Withholding Tax] [Vendor Bill] [Purchase]
    // Test for PLAFOND - Withhold Tax functionality.
    // 1. Verify Error message - Actual error: You have not specified any Withhold Code Line for Withhold Code.
    // 2. Verify that a Vendor Bill Line must be created after Insert Vendor Bill Line from Vendor Bill Card.
    // 3. Verify VendorBillWithhTax menu presence on Vendor Bill Line, verification done in VendorBillWithholdTaxModalPageHandler.
    // 4. Verify Posted Vendor Bill Line and G/L Entry after posting Vendor Bill.
    // 5. Verify Posted Vendor Bill Line after posting Vendor Bill.
    // 6. Verify Bill Reference on Vendor Bill Report as TEMPORARY for Open Status of Vendor Bill.
    // 7. Verify Bill Reference on Vendor Bill Report as Vendor Bill List No for Sent Status of Vendor Bill.
    // 8. Verify Dimension of Vendor updated on Posted Vendor Bill.
    // 9. Verify Vendor Bill Line contains Correct Values after Insert Vendor Bill Line from Vendor Bill Card.
    // 10. Verify Manual Vendor Payment Line Card Contains Blank Values after Insert Vendor Bill Line from Vendor Bill Card.
    // 11. Verify Withhold Tax Amount on Vendor Bill Lines after Suggest Payment Vendor.
    // 
    // Covers Test Cases for IT - 346931
    // ------------------------------------------------------------------------------------
    // Test Function Name                                                            TFS ID
    // ------------------------------------------------------------------------------------
    // PurchaseInvoiceWithholdCodeError                                              156032
    // VendorBillLineUsingInsertVendBillLineManual                            156033,156041
    // VendorBillLineMenuWithholdingINPS                                      156035,156037
    // VendorBillIssueWithVendorBillPayment                                   156043,215115
    // 
    // Covers Test Cases for IT - 346115
    // ------------------------------------------------------------------------------------
    // Test Function Name                                                            TFS ID
    // ------------------------------------------------------------------------------------
    // WithholdingTaxAmountUsingSuggestPayment                                219829,219830
    // 
    // Covers Test Cases for IT - 346249
    // ------------------------------------------------------------------------------------
    // Test Function Name                                                            TFS ID
    // ------------------------------------------------------------------------------------
    // VendorBillReportBillReferenceTemporary                                        278458
    // VendorBillReportBillReferenceVendorBillListNo                                 278458
    // PostedVendorBillUpdatedWithDimension                                          243251
    // 
    // Covers Test Cases for IT - 348981
    // ------------------------------------------------------------------------------------
    // Test Function Name                                                            TFS ID
    // ------------------------------------------------------------------------------------
    // VendorBillLineDetailUsingInsertVendBillLineManual                             348389
    // BlankManualVendorPaymentLineOnInsertVendBillLineManual
    // 
    // Covers Test Cases for Bug ID - 71866
    // ------------------------------------------------------------------------------------
    // Test Function Name                                                            TFS ID
    // ------------------------------------------------------------------------------------
    // WithholdingTaxAmountOnVendorBillLines

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        StringTxt: Label 'A', Comment = 'Single character string is required for the field 770 Code which is of 1 character';
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryITLocalization: Codeunit "Library - IT Localization";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        WithholdCodeErr: Label 'You have not specified any withhold code lines for withhold code';
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryDimension: Codeunit "Library - Dimension";
        LibrarySales: Codeunit "Library - Sales";
        BillReferenceCap: Label 'BillReference';
        WithHoldTaxAmountErr: Label '%1 should be equal to %2.', Comment = '%1 = Field Caption,%2 = Field Value';
        RecalculateINPSMsg: Label 'Please recalculate %1 and %2 from the Withholding - INPS.', Comment = '%1 = FIELDCAPTION("Withholding Tax Amount"), %2 = FIELDCAPTION("Social Security Amount")';
        ValueMustBeEqualErr: Label '%1 must be equal to %2.', Comment = '%1 = Field Caption , %2 = Field Value';

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceWithholdCodeError()
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
    begin
        // Verify Error message - Actual error: You have not specified any Withhold Code Line for Withhold Code.

        // Setup: Create Purchase Invoice and Vendor with Withhold Code.
        Initialize();
        CreateVendorWithholdCode(Vendor);
        CreatePurchaseInvoice(PurchaseHeader, Vendor."No.");

        // Exercise: Opens Page Withh. Taxes-Contribution Card from Purchase Invoice page and using blank value for Withhold Code.
        asserterror OpenWithholdTaxesContributionCardOnPurchInvoice(PurchaseHeader."No.", '');

        // Verify: Verify Error message - Actual error: You have not specified any Withhold Code Line for Withhold Code.
        Assert.ExpectedError(WithholdCodeErr);
    end;

    [Test]
    [HandlerFunctions('ManualVendorPaymentLinePageHandler')]
    [Scope('OnPrem')]
    procedure VendorBillLineUsingInsertVendBillLineManual()
    var
        VendorBillLine: Record "Vendor Bill Line";
        VendorBillHeaderNo: Code[20];
    begin
        // Verify that a Vendor Bill Line must be created after Insert Vendor Bill Line from Vendor Bill Card.

        // Setup & Exercise: Create Vendor with Withhold Code, create Vendor Bill Header Insert Vendor Bill Line Manual from Vendor Bill Card.
        Initialize();
        VendorBillHeaderNo := CreateVendorBillWithholdCodeAndInsertVendBillLineManual();

        // Verify: Verify that a Vendor Bill Line must be created after Insert Vendor Bill Line from Vendor Bill Card.
        FindVendorBillLine(VendorBillLine, VendorBillHeaderNo);
        VendorBillLine.TestField("Manual Line", true);
    end;

    [Test]
    [HandlerFunctions('ManualVendorPaymentLinePageHandler,VendorBillWithholdTaxModalPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure VendorBillLineMenuWithholdingINPS()
    var
        VendorBillLine: Record "Vendor Bill Line";
        VendorBillCard: TestPage "Vendor Bill Card";
        VendorBillHeaderNo: Code[20];
    begin
        // Verify VendorBillWithholdTax menu present on Vendor Bill Line, verification done in VendorBillWithholdTaxModalPageHandler.

        // Setup: Create Vendor with Withhold Code, create Vendor Bill Header and Invoke InsertVendBillLineManual from Vendor Bill Card.
        Initialize();
        VendorBillHeaderNo := CreateVendorBillWithholdCodeAndInsertVendBillLineManual();
        FindVendorBillLine(VendorBillLine, VendorBillHeaderNo);
        LibraryVariableStorage.Enqueue(VendorBillLine."Withholding Tax Amount");  // Enqueue value for VendorBillWithholdTaxModalPageHandler.
        LibraryVariableStorage.Enqueue(VendorBillLine."Instalment Amount");  // Enqueue value for VendorBillWithholdTaxModalPageHandler.
        VendorBillCard.OpenEdit();
        VendorBillCard.FILTER.SetFilter("No.", VendorBillHeaderNo);

        // Exercise.
        VendorBillCard.VendorBillLines.WithholdingINPS.Invoke();

        // Verify: Verify VendorBillWithholTax menu presence on Vendor Bill Line, verification done in VendorBillWithholdTaxModalPageHandler.
    end;

    [Test]
    [HandlerFunctions('SuggestVendorBillsRequestPageHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure VendorBillIssueWithVendorBillPayment()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorBillLine: Record "Vendor Bill Line";
        Vendor: Record Vendor;
        WithholdCode: Record "Withhold Code";
        VendorBillHeaderNo: Code[20];
    begin
        // Verify Posted Vendor Bill Line and G/L Entry after posting Vendor Bill.

        // Setup: Create Vendor with Withhold Code and Suggest Payment on Vendor Bills.
        Initialize();
        CreateAndPostPurchaseInvoice(PurchaseHeader);
        Vendor.Get(PurchaseHeader."Buy-from Vendor No.");
        WithholdCode.Get(Vendor."Withholding Tax Code");
        VendorBillHeaderNo := CreateVendorBillHeader();
        SuggestPaymentAndChangeStatusOnVendorBill(VendorBillHeaderNo);
        FindVendorBillLine(VendorBillLine, VendorBillHeaderNo);

        // Exercise: Post Vendor Bill Issued.
        PostVendorBill(VendorBillHeaderNo);

        // Verify: Verify Posted Vendor Bill Line after posting Vendor Bill and verify G/L Entry.
        VerifyPostedVendorBillLine(Vendor."No.", VendorBillLine."Instalment Amount", VendorBillLine."Amount to Pay");
        VerifyGLEntry(Vendor."No.", Vendor."No.", VendorBillLine."Withholding Tax Amount", 0);  // Credit Amount, Debit Amount - 0.
        VerifyGLEntry(WithholdCode."Withholding Taxes Payable Acc.", Vendor."No.", 0, VendorBillLine."Withholding Tax Amount");  // Credit Amount - 0, Debit Amount.
    end;

    [Test]
    [HandlerFunctions('SuggestVendorBillsRequestPageHandler,ConfirmHandler,VendorBillWithhTaxModalPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure WithholdingTaxAmountUsingSuggestPayment()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorBillLine: Record "Vendor Bill Line";
        VendorBillHeaderNo: Code[20];
    begin
        // Verify Posted Vendor Bill Line after posting Vendor Bill.

        // Setup: Create Vendor with Withhold Code and Suggest Payments on Vendor Bills.
        Initialize();
        CreateAndPostPurchaseInvoice(PurchaseHeader);
        VendorBillHeaderNo := CreateVendorBillHeader();
        SuggestPaymentAndChangeStatusOnVendorBill(VendorBillHeaderNo);
        FindVendorBillLine(VendorBillLine, VendorBillHeaderNo);

        // Exercise.
        VendorBillLine.ShowVendorBillWithhTax(true);

        // Verify: Verification for updated Withholding Tax Amount done in VendorBillWithhTaxModalPageHandler.
    end;

    [Test]
    [HandlerFunctions('SuggestVendorBillsRequestPageHandler,VendorBillReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VendorBillReportBillReferenceTemporary()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorBillCard: TestPage "Vendor Bill Card";
        VendorBillHeaderNo: Code[20];
    begin
        // Verify Bill Reference on Vendor Bill Report as TEMPORARY.

        // Setup: Create Vendor with Withhold Code and Suggest Payments on Vendor Bills.
        Initialize();
        CreateAndPostPurchaseInvoice(PurchaseHeader);
        VendorBillHeaderNo := CreateVendorBillHeader();
        SuggestPaymentOnVendorBill(VendorBillCard, VendorBillHeaderNo);

        // Exercise: Run Vendor Bill Report for Open Status of Vendor Bill.
        RunVendorBillReport(VendorBillHeaderNo);

        // Verify: Verify Bill Reference is updated as TEMPORARY on Vendor Bill Report.
        VerifyBillReference('TEMPORARY');
    end;

    [Test]
    [HandlerFunctions('SuggestVendorBillsRequestPageHandler,ConfirmHandler,VendorBillReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VendorBillReportBillReferenceVendorBillListNo()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorBillHeader: Record "Vendor Bill Header";
        VendorBillHeaderNo: Code[20];
    begin
        // Verify Bill Reference on Vendor Bill Report as Vendor Bill List.

        // Setup: Create and Post Purchase Invoice, create Vendor with Withhold Code, Suggest Payment on Vendor Bills and Change Status to sent.
        Initialize();
        CreateAndPostPurchaseInvoice(PurchaseHeader);
        VendorBillHeaderNo := CreateVendorBillHeader();
        SuggestPaymentAndChangeStatusOnVendorBill(VendorBillHeaderNo);

        // Exercise: Run Vendor Bill Report for Sent Status of Vendor Bill.
        RunVendorBillReport(VendorBillHeaderNo);

        // Verify: Verify Bill Reference is updated as Vendor Bill List Number on Vendor Bill Report.
        VendorBillHeader.Get(VendorBillHeaderNo);
        VerifyBillReference(VendorBillHeader."Vendor Bill List No.")
    end;

    [Test]
    [HandlerFunctions('ManualVendorPaymentLinePageHandler,ConfirmHandler,MessageHandler,DimensionSetEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure PostedVendorBillUpdatedWithDimension()
    var
        PurchaseHeader: Record "Purchase Header";
        PostedVendorBillLine: Record "Posted Vendor Bill Line";
        PostedVendorBillCard: TestPage "Posted Vendor Bill Card";
        VendorBillHeaderNo: Code[20];
    begin
        // Verify Dimension on Posted Vendor Bill Line after posting Vendor Bill.

        // Setup: Create and Post Purchase Invoice with Dimension on Vendor, create Vendor with Withhold Code and Post Vendor Bill.
        Initialize();
        CreateAndPostPurchaseInvoice(PurchaseHeader);
        VendorBillHeaderNo := CreateVendorBillHeader();
        InsertVendorBillLineManualWithChangeStatus(VendorBillHeaderNo);
        PostVendorBill(VendorBillHeaderNo);
        FindPostedVendorBillLine(PostedVendorBillLine, PurchaseHeader."Buy-from Vendor No.");
        LibraryVariableStorage.Enqueue(FindDefaultDimension(PurchaseHeader."Buy-from Vendor No."));  // Required inside DimensionSetEntriesPageHandler.
        PostedVendorBillCard.OpenEdit();
        PostedVendorBillCard.FILTER.SetFilter("No.", PostedVendorBillLine."Vendor Bill No.");

        // Exercise: Show Dimension on Posted Vendor Bill Line Page.
        PostedVendorBillCard.SubformPostedVendBillLines.Dimension.Invoke();  // Opens DimensionSetEntriesPageHandler.

        // Verify: Verify Dimension updated on Posted Vendor Bill Line in DimensionSetEntriesPageHandler.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorBillLineDetailUsingInsertVendBillLineManual()
    var
        Vendor: Record Vendor;
        VendorBillCard: TestPage "Vendor Bill Card";
        TotalAmount: Decimal;
        VendorBillNo: Code[20];
    begin
        // Verify Vendor Bill Line contains Correct Values after Insert Vendor Bill Line from Vendor Bill Card.

        // Setup.
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        TotalAmount := LibraryRandom.RandDec(10, 2);

        // Exercise: Create Vendor Bill Header, Insert Vendor Bill Line from Vendor Bill Card.
        VendorBillNo := CreateLineOnVendorBillWithInsertLine(Vendor."No.", TotalAmount);

        // Verify: Verify that a Vendor Bill Line Created Correct Vendor Number and Amount after Insert Vendor Bill Line from Vendor Bill Card.
        VendorBillCard.OpenEdit();
        VendorBillCard.FILTER.SetFilter("No.", VendorBillNo);
        VendorBillCard.VendorBillLines."Vendor No.".AssertEquals(Vendor."No.");
        VendorBillCard.VendorBillLines."Instalment Amount".AssertEquals(TotalAmount);
        VendorBillCard.Close();
    end;

    [Test]
    [HandlerFunctions('SuggestVendBillsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure WithholdingTaxAmountOnVendorBillLines()
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        VendorBillCard: TestPage "Vendor Bill Card";
        VendorBillHeaderNo: Code[20];
        VendorNo: Code[20];
        Amount: Decimal;
    begin
        // Verify Withhold Tax Amount on Vendor Bill Lines after Suggest Payment Vendor.

        // Setup: Create and post Purchase Invoice with and without Withhold Tax.
        Initialize();
        Amount := CreateAndPostPurchaseInvoice(PurchaseHeader);
        VendorNo := PostPurchaseInvoiceWithoutWithHoldTax();
        VendorBillHeaderNo := CreateVendorBillHeader();

        // Exercise: Run Suggest Payment on Vendor Bill.
        SuggestPaymentOnVendorBill(VendorBillCard, VendorBillHeaderNo);

        // Verify: Verify Withhold Tax Amounts on Vendor Bill Lines.
        Vendor.Get(PurchaseHeader."Buy-from Vendor No.");
        VerifyWithHoldAmountOnVendorBillLine(Vendor."No.", CalculateWithholdingTaxAmount(Vendor."Withholding Tax Code", Amount));
        VerifyWithHoldAmountOnVendorBillLine(VendorNo, 0);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure VendorBillWithhTaxWithNoTaxableBase()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        VendorBillHeader: Record "Vendor Bill Header";
        WithholdingTax: Record "Withholding Tax";
        Amount: Decimal;
    begin
        // [SCENARIO 377969] Withholding Tax should be reported on Posted Vendor Bill even if no withholding tax amounts have been calculated
        Initialize();

        // [GIVEN] Posted Purchase Invoice of Amount = "A" with Withholding Tax where "Taxable Base" = 0
        CreateVendorWithholdCodeWithTaxableBase(Vendor, 0);
        Amount := CreateAndPostPurchaseInvoiceForVendor(PurchaseHeader, Vendor."No.", Vendor."Withholding Tax Code");

        // [GIVEN] Issued Vendor Bill for Purchase Invoice with "Non Taxable Amount" = Invoice Amount = "A"
        VendorBillHeader.Get(CreateVendorBillHeader());
        RunSuggestVendorBills(VendorBillHeader, Vendor."No.");
        LibraryITLocalization.IssueVendorBill(VendorBillHeader);

        // [WHEN] Post Issued Vendor Bill
        LibraryITLocalization.PostIssuedVendorBill(VendorBillHeader);

        // [THEN] Withholding Tax is generated for Vendor Bill with Non Taxable Amount = "A"
        WithholdingTax.SetRange("Vendor No.", PurchaseHeader."Buy-from Vendor No.");
        WithholdingTax.FindFirst();
        WithholdingTax.TestField("Non Taxable Amount", Amount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure VendorBillWithhTaxPostedVendorBillListNo()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        VendorBillHeader: Record "Vendor Bill Header";
        VendorBillLine: Record "Vendor Bill Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // [SCENARIO 331142] "Vendor Bill List" and "Vendor Bill No." are not blank on Vendor Ledger Entry after Issued Vendor Bill is posted
        Initialize();

        // [GIVEN] Posted Purchase Invoice with Withholding Tax
        CreateVendorWithholdCode(Vendor);
        CreateAndPostPurchaseInvoiceForVendor(PurchaseHeader, Vendor."No.", Vendor."Withholding Tax Code");

        // [GIVEN] Issued Vendor Bill for Purchase Invoice
        VendorBillHeader.Get(CreateVendorBillHeader());
        RunSuggestVendorBills(VendorBillHeader, Vendor."No.");
        LibraryITLocalization.IssueVendorBill(VendorBillHeader);
        VendorBillLine.SetRange("Vendor Bill List No.", VendorBillHeader."No.");
        VendorBillLine.FindFirst();

        // [WHEN] Post Issued Vendor Bill
        LibraryITLocalization.PostIssuedVendorBill(VendorBillHeader);

        // [THEN] "Vendor Bill List" and "Vendor Bill No." are not blank on Vendor Ledger Entry
        VendorLedgerEntry.SetRange("Vendor No.", Vendor."No.");
        VendorLedgerEntry.FindFirst();
        VendorLedgerEntry.TestField("Vendor Bill List", VendorBillHeader."Vendor Bill List No.");
        VendorLedgerEntry.TestField("Vendor Bill No.", VendorBillLine."Vendor Bill No.");
    end;

    [Test]
    [HandlerFunctions('VendorBillWithholdTaxNoCheckModalPageHandler,MessageHandlerWithCheck')]
    [Scope('OnPrem')]
    procedure AmountToPayRemainsUnchangedWhenCloseVendorBillWithholdingTaxPageWithoutChanges()
    var
        VendorBillWithholdingTax: Record "Vendor Bill Withholding Tax";
        VendorBillLine: Record "Vendor Bill Line";
        ExpectedAmountToPay: Decimal;
    begin
        // [FEATURE] [UT] [UI]
        // [SCENARIO 361346] The "Amount to Pay" remains unchanged when close the Vendor Bill Withholding Tax page without any changes

        Initialize();

        // [GIVEN] Vendor Bill Line with "Remaining Amount " = 500, "Amount to Pay" = 250, "Withholoding Tax Amount" = 100
        VendorBillLine.Init();
        VendorBillLine."Vendor Bill List No." := LibraryUtility.GenerateGUID();
        VendorBillLine."Remaining Amount" := LibraryRandom.RandDecInRange(500, 1000, 2);
        VendorBillLine."Amount to Pay" := Round(VendorBillLine."Remaining Amount" / 2);
        VendorBillLine."Withholding Tax Amount" := Round(VendorBillLine."Amount to Pay" / 2);
        VendorBillLine.Insert();
        ExpectedAmountToPay := VendorBillLine."Amount to Pay";
        // [GIVEN] Vendor Bill Withholding Tax related to Vendor Bill Line with the same "Withholding Tax Amount" and "Free-Lance Amount" = 150
        VendorBillWithholdingTax.Init();
        VendorBillWithholdingTax."Vendor Bill List No." := VendorBillLine."Vendor Bill List No.";
        VendorBillWithholdingTax."Withholding Tax Amount" := VendorBillLine."Withholding Tax Amount";
        VendorBillWithholdingTax."Free-Lance Amount" :=
          VendorBillLine."Remaining Amount" - VendorBillLine."Amount to Pay" - VendorBillLine."Withholding Tax Amount";
        VendorBillWithholdingTax.Insert();
        LibraryVariableStorage.Enqueue(
          StrSubstNo(RecalculateINPSMsg,
            VendorBillLine.FieldCaption("Withholding Tax Amount"), VendorBillLine.FieldCaption("Social Security Amount")));

        // [GIVEN] The "Vendor Bill Withholdoing Tax" page is opened

        // [WHEN] Close the the "Vendor Bill Withholdoing Tax" page
        VendorBillLine.ShowVendorBillWithhTax(true);

        // [THEN] The "Amount to Pay" of Vendor Bill Line remains unchanged and equals 250
        VendorBillLine.Find();
        VendorBillLine.TestField("Amount to Pay", ExpectedAmountToPay);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure AllowPostingForIssuedBillCardIfDifferentPurchaserCodeAreSelectedInPurchaseInvoice()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        VendorBillHeader: Record "Vendor Bill Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        SalespersonPurchaserNew: Record "Salesperson/Purchaser";
        ExpectedDimesnionSetID: Integer;
    begin
        // [SCENARIO 473200] Verify Posting is allowed for Issued bill card if different purchaser code are selected in the Posted purchase invoice.
        Initialize();

        // [GIVEN] Created multiple SalesPerson/Purchaser with Default Dimension.
        CreateMultiplePurchaserWithDefaultDimension(SalespersonPurchaser, SalespersonPurchaserNew);

        // [GIVEN] Created a Vendor Bill Header with a Bank Account, Bill Posting Group and Payment Method.
        VendorBillHeader.Get(CreateVendorBillHeader());

        // [GIVEN] Create a Vendor with SalesPerson/Purchaser and Payment Method Code.
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Purchaser Code", SalespersonPurchaser.Code);
        Vendor.Validate("Payment Method Code", VendorBillHeader."Payment Method Code");
        Vendor.Modify();

        // [GIVEN] Create a Purchase invoice with the new Salesperson/Purchaser.
        LibraryPurchase.CreatePurchaseInvoiceForVendorNo(PurchaseHeader, Vendor."No.");
        PurchaseHeader.Validate("Purchaser Code", SalespersonPurchaserNew.Code);
        PurchaseHeader.Modify();

        // [GIVEN] Save Dimension Set ID in a variable.
        ExpectedDimesnionSetID := PurchaseHeader."Dimension Set ID";

        // [GIVEN] Post the Purchase Invoice.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Issued Vendor Bill for Purchase Invoice.
        RunSuggestVendorBills(VendorBillHeader, Vendor."No.");
        LibraryITLocalization.IssueVendorBill(VendorBillHeader);

        // [WHEN] Post Issued Vendor Bill.
        LibraryITLocalization.PostIssuedVendorBill(VendorBillHeader);

        // [VERIFY] Verify the Dimension Set ID in the Vendor Ledger Entry for the posted vendor bill.
        VendorLedgerEntry.SetRange("Vendor No.", Vendor."No.");
        VendorLedgerEntry.FindLast();
        Assert.AreEqual(
            ExpectedDimesnionSetID,
            VendorLedgerEntry."Dimension Set ID",
            StrSubstNo(
                ValueMustBeEqualErr,
                VendorLedgerEntry.FieldCaption("Dimension Set ID"),
                ExpectedDimesnionSetID));
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CalculateWithholdingTaxAmount(WithholdCode: Code[20]; TaxBaseAmount: Decimal): Decimal
    var
        WithholdCodeLine: Record "Withhold Code Line";
    begin
        WithholdCodeLine.SetRange("Withhold Code", WithholdCode);
        WithholdCodeLine.FindFirst();
        exit(Round(((TaxBaseAmount * WithholdCodeLine."Taxable Base %" / 100) * WithholdCodeLine."Withholding Tax %") / 100));
    end;

    local procedure FindPostedVendorBillLine(var PostedVendorBillLine: Record "Posted Vendor Bill Line"; VendorNo: Code[20])
    begin
        PostedVendorBillLine.SetRange("Vendor No.", VendorNo);
        PostedVendorBillLine.FindFirst();
    end;

    local procedure FindDefaultDimension(VendorNo: Code[20]): Code[20]
    var
        DefaultDimension: Record "Default Dimension";
    begin
        DefaultDimension.SetRange("No.", VendorNo);
        DefaultDimension.FindFirst();
        exit(DefaultDimension."Dimension Code");
    end;

    local procedure CreateVendor(var Vendor: Record Vendor; WithholdingTaxCode: Code[20]; PaymentMethodCode: Code[10])
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Vendor.Validate("Withholding Tax Code", WithholdingTaxCode);
        Vendor.Validate("Payment Method Code", PaymentMethodCode);
        Vendor.Modify(true);
    end;

    local procedure CreateWithholdCode(): Code[20]
    var
        WithholdCode: Record "Withhold Code";
    begin
        LibraryITLocalization.CreateWithholdCode(WithholdCode);
        WithholdCode.Validate("Withholding Taxes Payable Acc.", CreateGLAccount());
        WithholdCode.Validate("Tax Code", Format(LibraryRandom.RandIntInRange(100, 9999)));  // Using Random value for Tax Code.
        WithholdCode.Validate("770 Code", StringTxt);
        WithholdCode.Modify(true);
        exit(WithholdCode.Code);
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.FindGenProductPostingGroup(GenProductPostingGroup);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        GLAccount.Validate("Gen. Prod. Posting Group", GenProductPostingGroup.Code);
        GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreatePurchaseInvoice(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20]): Decimal
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", CreateGLAccount(), LibraryRandom.RandDecInRange(100, 500, 2));  // Using Random value for Quantity.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(100, 500, 2));
        PurchaseLine.Validate("Line Discount %", LibraryRandom.RandInt(10));
        PurchaseLine.Modify(true);
        UpdateCheckTotalOnPuchaseInvoice(PurchaseHeader, PurchaseLine."Amount Including VAT");
        exit(PurchaseLine."Line Amount");
    end;

    local procedure CreateAndPostPurchaseInvoice(var PurchaseHeader: Record "Purchase Header"): Decimal
    var
        Vendor: Record Vendor;
    begin
        CreateVendorWithholdCode(Vendor);
        exit(CreateAndPostPurchaseInvoiceForVendor(PurchaseHeader, Vendor."No.", Vendor."Withholding Tax Code"));
    end;

    local procedure CreateAndPostPurchaseInvoiceForVendor(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20]; WithholdTaxCode: Code[20]) Amount: Decimal
    begin
        Amount := CreatePurchaseInvoice(PurchaseHeader, VendorNo);
        OpenWithholdTaxesContributionCardOnPurchInvoice(PurchaseHeader."No.", WithholdTaxCode);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // TRUE for Ship and Invoice.
    end;

    local procedure CreateVendorWithholdCode(var Vendor: Record Vendor)
    var
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
    begin
        CreateVendorWithholdCodeWithTaxableBase(Vendor, LibraryRandom.RandInt(10));
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryDimension.CreateDefaultDimensionVendor(DefaultDimension, Vendor."No.", DimensionValue."Dimension Code", DimensionValue.Code);
        LibraryVariableStorage.Enqueue(Vendor."No.");  // Enqueue value for ManualVendorPaymentLinePageHandler.
        LibraryVariableStorage.Enqueue(Vendor."Withholding Tax Code");  // Enqueue value for ManualVendorPaymentLinePageHandler.
    end;

    local procedure CreateVendorWithholdCodeWithTaxableBase(var Vendor: Record Vendor; TaxableBase: Decimal)
    var
        WithholdCodeLine: Record "Withhold Code Line";
    begin
        LibraryITLocalization.CreateWithholdCodeLine(WithholdCodeLine, CreateWithholdCode(), WorkDate());
        WithholdCodeLine.Validate("Withholding Tax %", LibraryRandom.RandInt(10));
        WithholdCodeLine.Validate("Taxable Base %", TaxableBase);
        WithholdCodeLine.Modify(true);
        CreateVendor(Vendor, WithholdCodeLine."Withhold Code", FindPaymentMethod());
    end;

    local procedure CreateVendorBillWithholdCodeAndInsertVendBillLineManual() VendorBillHeaderNo: Code[20]
    var
        Vendor: Record Vendor;
    begin
        CreateVendorWithholdCode(Vendor);
        VendorBillHeaderNo := CreateVendorBillHeader();
        InsertVendBillLineManualUsingVendorBillCardPage(VendorBillHeaderNo);
    end;

    local procedure CreateVendorBillHeader(): Code[20]
    var
        BankAccount: Record "Bank Account";
        BillPostingGroup: Record "Bill Posting Group";
        VendorBillHeader: Record "Vendor Bill Header";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        LibraryITLocalization.CreateBillPostingGroup(BillPostingGroup, BankAccount."No.", FindPaymentMethod());
        LibraryITLocalization.CreateVendorBillHeader(VendorBillHeader);
        VendorBillHeader.Validate("Bank Account No.", BankAccount."No.");
        VendorBillHeader.Validate("Payment Method Code", BillPostingGroup."Payment Method");
        VendorBillHeader.Modify(true);
        exit(VendorBillHeader."No.");
    end;

    local procedure InsertVendorBillLineManual(var VendorBillCard: TestPage "Vendor Bill Card"; No: Code[20])
    begin
        VendorBillCard.OpenEdit();
        VendorBillCard.FILTER.SetFilter("No.", No);
        VendorBillCard.InsertVendBillLineManual.Invoke();  // Opens ManualVendorPaymentLinePageHandler.
    end;

    local procedure InsertVendBillLineManualUsingVendorBillCardPage(No: Code[20])
    var
        VendorBillCard: TestPage "Vendor Bill Card";
    begin
        InsertVendorBillLineManual(VendorBillCard, No);
        VendorBillCard.Close();
    end;

    local procedure InsertVendorBillLineManualWithChangeStatus(No: Code[20])
    var
        VendorBillHeader: Record "Vendor Bill Header";
        VendorBillCard: TestPage "Vendor Bill Card";
    begin
        Commit();  // Commit required.
        InsertVendorBillLineManual(VendorBillCard, No);
        VendorBillHeader.Get(No);
        LibraryITLocalization.IssueVendorBill(VendorBillHeader);
        VendorBillCard.Close();
    end;

    local procedure FindPaymentMethod(): Code[10]
    var
        Bill: Record Bill;
        PaymentMethod: Record "Payment Method";
    begin
        Bill.SetRange("Allow Issue", false);
        Bill.SetRange("Bank Receipt", false);
        Bill.FindFirst();
        PaymentMethod.SetRange("Bill Code", Bill.Code);
        LibraryERM.FindPaymentMethod(PaymentMethod);
        exit(PaymentMethod.Code);
    end;

    local procedure FindVendorBillLine(var VendorBillLine: Record "Vendor Bill Line"; VendorBillListNo: Code[20])
    begin
        VendorBillLine.SetRange("Vendor Bill List No.", VendorBillListNo);
        VendorBillLine.FindFirst();
    end;

    local procedure OpenWithholdTaxesContributionCardOnPurchInvoice(No: Code[20]; WithholdCode: Code[20])
    var
        PurchaseInvoice: TestPage "Purchase Invoice";
        WithhTaxesContributionCard: TestPage "Withh. Taxes-Contribution Card";
    begin
        WithhTaxesContributionCard.Trap();
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.FILTER.SetFilter("No.", No);
        PurchaseInvoice."With&hold Taxes-Soc. Sec.".Invoke();
        WithhTaxesContributionCard."Withholding Tax Code".SetValue(WithholdCode);
        WithhTaxesContributionCard.OK().Invoke();
        PurchaseInvoice.Close();
    end;

    local procedure PostVendorBill(No: Code[20])
    var
        VendorBillHeader: Record "Vendor Bill Header";
    begin
        VendorBillHeader.Get(No);
        LibraryITLocalization.PostIssuedVendorBill(VendorBillHeader);
    end;

    local procedure PostPurchaseInvoiceWithoutWithHoldTax(): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
    begin
        CreateVendor(Vendor, '', FindPaymentMethod());
        CreatePurchaseInvoice(PurchaseHeader, Vendor."No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        exit(Vendor."No.");
    end;

    local procedure SuggestPaymentOnVendorBill(var VendorBillCard: TestPage "Vendor Bill Card"; No: Code[20])
    begin
        Commit();  // Commit required.
        VendorBillCard.OpenEdit();
        VendorBillCard.FILTER.SetFilter("No.", No);
        VendorBillCard.SuggestPayment.Invoke();  // Opens SuggestVendorBillsRequestPageHandler.
    end;

    local procedure SuggestPaymentAndChangeStatusOnVendorBill(No: Code[20])
    var
        VendorBillHeader: Record "Vendor Bill Header";
        VendorBillCard: TestPage "Vendor Bill Card";
    begin
        SuggestPaymentOnVendorBill(VendorBillCard, No);
        VendorBillHeader.Get(No);
        LibraryITLocalization.IssueVendorBill(VendorBillHeader);
        VendorBillCard.Close();
    end;

    local procedure UpdateCheckTotalOnPuchaseInvoice(PurchaseHeader: Record "Purchase Header"; CheckTotal: Decimal)
    begin
        PurchaseHeader.Validate("Check Total", CheckTotal);
        PurchaseHeader.Modify(true);
    end;

    local procedure RunVendorBillReport(No: Code[20])
    var
        VendorBillHeader: Record "Vendor Bill Header";
        VendorBillReport: Report "Vendor Bill Report";
    begin
        Commit();  // Commit required.
        Clear(VendorBillReport);
        VendorBillHeader.SetRange("No.", No);
        VendorBillReport.SetTableView(VendorBillHeader);
        VendorBillReport.Run();
    end;

    local procedure RunSuggestVendorBills(VendorBillHeader: Record "Vendor Bill Header"; VendorNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SuggestVendorBills: Report "Suggest Vendor Bills";
    begin
        Clear(SuggestVendorBills);
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        SuggestVendorBills.InitValues(VendorBillHeader);
        SuggestVendorBills.SetTableView(VendorLedgerEntry);
        SuggestVendorBills.UseRequestPage(false);
        SuggestVendorBills.Run();
    end;

    local procedure VerifyPostedVendorBillLine(VendorNo: Code[20]; InstalmentAmount: Decimal; AmountToPay: Decimal)
    var
        PostedVendorBillLine: Record "Posted Vendor Bill Line";
    begin
        FindPostedVendorBillLine(PostedVendorBillLine, VendorNo);
        PostedVendorBillLine.TestField("Instalment Amount", InstalmentAmount);
        PostedVendorBillLine.TestField("Amount to Pay", AmountToPay);
    end;

    local procedure VerifyGLEntry(BalAccountNo: Code[20]; VendorNo: Code[20]; CreditAmount: Decimal; DebitAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
        PostedVendorBillLine: Record "Posted Vendor Bill Line";
    begin
        FindPostedVendorBillLine(PostedVendorBillLine, VendorNo);
        GLEntry.SetRange("Document No.", PostedVendorBillLine."Vendor Bill No.");
        GLEntry.SetRange("Bal. Account No.", BalAccountNo);
        GLEntry.FindFirst();
        GLEntry.TestField("Credit Amount", CreditAmount);
        GLEntry.TestField("Debit Amount", DebitAmount);
    end;

    local procedure VerifyBillReference(BillReference: Text)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(BillReferenceCap, BillReference);
    end;

    local procedure VerifyWithHoldAmountOnVendorBillLine(VendorNo: Code[20]; WithHoldTaxAmount: Decimal)
    var
        VendorBillLine: Record "Vendor Bill Line";
    begin
        VendorBillLine.SetRange("Vendor No.", VendorNo);
        VendorBillLine.FindFirst();
        Assert.AreEqual(
          WithHoldTaxAmount,
          VendorBillLine."Withholding Tax Amount", StrSubstNo(WithHoldTaxAmountErr, VendorBillLine.FieldCaption("Withholding Tax Amount"), WithHoldTaxAmount));
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ManualVendorPaymentLinePageHandler(var ManualVendorPaymentLine: TestPage "Manual vendor Payment Line")
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorNo: Variant;
        WithholdingTaxCode: Variant;
    begin
        LibraryVariableStorage.Dequeue(VendorNo);
        LibraryVariableStorage.Dequeue(WithholdingTaxCode);
        ManualVendorPaymentLine.VendorNo.SetValue(VendorNo);
        ManualVendorPaymentLine.WithholdingTaxCode.SetValue(WithholdingTaxCode);
        ManualVendorPaymentLine.DocumentType.SetValue(VendorLedgerEntry."Document Type"::Payment);
        ManualVendorPaymentLine.DocumentNo.SetValue(LibraryUtility.GenerateGUID());
        ManualVendorPaymentLine.DocumentDate.SetValue(WorkDate());
        ManualVendorPaymentLine.TotalAmount.SetValue(LibraryRandom.RandInt(100));
        ManualVendorPaymentLine.InsertLine.Invoke();
    end;

    local procedure CreateLineOnVendorBillWithInsertLine(VendorNo: Code[20]; TotalAmount: Decimal) VendorBillHeaderNo: Code[20]
    var
        ManualVendorPaymentLine: TestPage "Manual vendor Payment Line";
        VendorBillCard: TestPage "Vendor Bill Card";
    begin
        VendorBillCard.OpenEdit();
        ManualVendorPaymentLine.Trap();
        VendorBillCard.FILTER.SetFilter("No.", CreateVendorBillHeader());
        VendorBillCard.InsertVendBillLineManual.Invoke();
        ManualVendorPaymentLine.VendorNo.SetValue(VendorNo);
        ManualVendorPaymentLine.TotalAmount.SetValue(TotalAmount);
        ManualVendorPaymentLine.InsertLine.Invoke();
        VendorBillHeaderNo := VendorBillCard."No.".Value();
        VendorBillCard.Close();
    end;

    local procedure CreateMultiplePurchaserWithDefaultDimension(
        var SalespersonPurchaser: Record "Salesperson/Purchaser";
        var SalespersonPurchaserNew: Record "Salesperson/Purchaser")
    var
        DefaultDimension: Record "Default Dimension";
    begin
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        LibraryDimension.CreateDefaultDimensionWithNewDimValue(
            DefaultDimension,
            Database::"Salesperson/Purchaser",
            SalespersonPurchaser.Code,
            "Default Dimension Value Posting Type"::"Same Code");

        LibrarySales.CreateSalesperson(SalespersonPurchaserNew);
        LibraryDimension.CreateDefaultDimensionWithNewDimValue(
            DefaultDimension,
            Database::"Salesperson/Purchaser",
            SalespersonPurchaserNew.Code,
            "Default Dimension Value Posting Type"::"Same Code");
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestVendorBillsRequestPageHandler(var SuggestVendorBills: TestRequestPage "Suggest Vendor Bills")
    var
        VendorNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(VendorNo);
        SuggestVendorBills."Vendor Ledger Entry".SetFilter("Vendor No.", VendorNo);
        SuggestVendorBills.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VendorBillWithholdTaxModalPageHandler(var VendorBillWithhTax: TestPage "Vendor Bill Withh. Tax")
    var
        TotalAmount: Variant;
        WithholdingTaxAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(WithholdingTaxAmount);
        LibraryVariableStorage.Dequeue(TotalAmount);
        VendorBillWithhTax."Withholding Tax Amount".AssertEquals(WithholdingTaxAmount);
        VendorBillWithhTax."Total Amount".AssertEquals(TotalAmount);
        VendorBillWithhTax.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VendorBillWithholdTaxNoCheckModalPageHandler(var VendorBillWithhTax: TestPage "Vendor Bill Withh. Tax")
    begin
        VendorBillWithhTax.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VendorBillReportRequestPageHandler(var VendorBillReport: TestRequestPage "Vendor Bill Report")
    begin
        VendorBillReport.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DimensionSetEntriesPageHandler(var DimensionSetEntries: TestPage "Dimension Set Entries")
    var
        DimensionCode: Variant;
    begin
        LibraryVariableStorage.Dequeue(DimensionCode);
        DimensionSetEntries."Dimension Code".AssertEquals(DimensionCode);
        DimensionSetEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VendorBillWithhTaxModalPageHandler(var VendorBillWithhTax: TestPage "Vendor Bill Withh. Tax")
    var
        Currency: Record Currency;
        WithholdingTaxAmount: Decimal;
    begin
        VendorBillWithhTax."Total Amount".SetValue(LibraryRandom.RandInt(100));
        WithholdingTaxAmount :=
          Round(VendorBillWithhTax."Taxable Base".AsDecimal() * VendorBillWithhTax."Withholding Tax %".AsDecimal() / 100,
            Currency."Amount Rounding Precision");
        VendorBillWithhTax."Withholding Tax Amount".AssertEquals(WithholdingTaxAmount);
        VendorBillWithhTax.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandlerWithCheck(Message: Text[1024])
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Message);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestVendBillsRequestPageHandler(var SuggestVendorBills: TestRequestPage "Suggest Vendor Bills")
    begin
        SuggestVendorBills.OK().Invoke();
    end;
}

