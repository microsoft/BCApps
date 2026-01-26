codeunit 144123 "ERM Details Purchase"
{
    // // [FEATURE] [Purchase]
    //  Test for feature: Details Purchase.
    //  1. Test to verify Purchase Credit Memo posted successfully with higher Expected Receipt Date than its Posting Date.
    //  2. Test to verify Purchase Credit Memo posted successfully with earlier Expected Receipt Date than its Posting Date.
    //  3. Test to verify Purchase Credit Memo posted successfully with same Expected Receipt Date as Posting Date.
    //  4. Test to verify Purchase Return Order posted successfully with higher Expected Receipt Date than its Posting Date.
    //  5. Test to verify Purchase Return Order posted successfully with earlier Expected Receipt Date than its Posting Date.
    //  6. Test to verify Purchase Return Order posted successfully with same Expected Receipt Date as Posting Date.
    //  7. Test to verify Purchase Invoice posted successfully with higher Expected Receipt Date than its Posting Date.
    //  8. Test to verify Purchase Invoice posted successfully with earlier Expected Receipt Date than its Posting Date.
    //  9. Test to verify Purchase Invoice posted successfully with same Expected Receipt Date as Posting Date.
    // 10. Test to verify Purchase Order created successfully Blanket Purchase Order with higher Expected Receipt Date than its Posting Date.
    // 11. Test to verify Purchase Order created successfully Blanket Purchase Order with lesser Expected Receipt Date than its Posting Date.
    // 12. Test to verify Purchase Order created successfully Blanket Purchase Order with same Expected Receipt Date as Posting Date.
    // 13. Test to verify that No. Series in Posted Purchase Invoice is correct after uncheck Ext. Doc No. mandatory in Purchase Setup.
    // 14. Test to verify that No. Series in Posted Purchase Credit Memo is correct after uncheck Ext. Doc No. mandatory in Purchase Setup.
    // 15. Test to verify Report Vendor - Top 10 List run successfully without any error for Show Type Balance (LCY).
    // 16. Test to verify Vendor Sheet - Print for Payment of Invoice only of which posting date is included in the date filter.
    // 17. Test to verify Purchase Credit Memo posted successfully against Purchase Return Order by using Get return Shipment.
    // 18. Test to validate Due Date in "Detailed Vendor Ledr. Entry" after posting Sales Invoice.
    // 
    //   Covers Test Cases for WI - 346248
    //   -----------------------------------------------------------------------------------------------------
    //   Test Function Name                                                                            TFS ID
    //   -----------------------------------------------------------------------------------------------------
    //   PostedPurchCrMemoWithHigherExpectedReceiptDate                                          202219,167795
    //   PostedPurchCrMemoWithEarlierExpectedReceiptDate                                                202219
    //   PostedPurchCrMemoWithSameExpectedReceiptDate                                                   202219
    //   PostedPurchRetOrderWithHigherExpectedReceiptDate                                        202220,167794
    //   PostedPurchRetOrderWithEarlierExpectedReceiptDate                                              202220
    //   PostedPurchRetOrderWithSameExpectedReceiptDate                                                 202220
    //   PostedPurchInvoiceWithHigherExpectedReceiptDate                                         202221,167793
    //   PostedPurchInvoiceWithEarlierExpectedReceiptDate                                               202221
    //   PostedPurchInvoiceWithSameExpectedReceiptDate                                                  202221
    //   BlanketPurchOrderMakeOrderWithHigherExpectedRcptDate                                           202222
    //   BlanketPurchOrderMakeOrderWithEalierExpectedRcptDate                                           202223
    //   BlanketPurchOrderMakeOrderWithSameExpectedRcptDate                                             202223
    //   PostedPurchInvoiceWithCorrectNoSeries                                                          252129
    //   PostedPurchCreditMemoWithCorrectNoSeries                                                       252130
    //   VendorTopTenListWithBalanceLCY                                                                 298558
    // 
    //   Covers Test Cases for WI - 346249
    //   -----------------------------------------------------------------------------------------------------
    //   Test Function Name                                                                            TFS ID
    //   -----------------------------------------------------------------------------------------------------
    //   VendorSheetPrintForPayment                                                                    264097
    // 
    //   Covers Test Cases for WI - 347414
    //   -----------------------------------------------------------------------------------------------------
    //   Test Function Name                                                                            TFS ID
    //   -----------------------------------------------------------------------------------------------------
    //   PostedCreditMemoWithGetReturnShipmentLine                                                     293066
    // 
    //   -----------------------------------------------------------------------------------------------------
    //   Test Function Name
    //   -----------------------------------------------------------------------------------------------------
    //   CheckDueDateDetailedVendorLedgEntryAfterPostingPurchaseInvoice                                359853

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryRandom: Codeunit "Library - Random";
        AmountLCYCap: Label 'AmountLCY';
        VendoNoCap: Label 'No_Vendor';
        WrongDueDateDetailedVendorLedgEntryErr: Label 'Wrong Initial Entry Due Date in Detailed Vendor Ledger Entry.';
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        Assert: Codeunit Assert;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchCrMemoWithHigherExpectedReceiptDate()
    var
        PurchaseHeader: Record "Purchase Header";
        ExpectedReceiptDate: Date;
    begin
        // Test to verify Purchase Credit Memo posted successfully with higher Expected Receipt Date than its Posting Date.
        ExpectedReceiptDate := CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate());  // Expected Receipt Date later than Posting Date.
        PostedPurchDocumentWithExpectedReceiptDate(PurchaseHeader."Document Type"::"Credit Memo", ExpectedReceiptDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchCrMemoWithEarlierExpectedReceiptDate()
    var
        PurchaseHeader: Record "Purchase Header";
        ExpectedReceiptDate: Date;
    begin
        // Test to verify Purchase Credit Memo posted successfully with earlier Expected Receipt Date than its Posting Date.
        ExpectedReceiptDate := CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate());  // Expected Receipt Date earlier than Posting Date.
        PostedPurchDocumentWithExpectedReceiptDate(PurchaseHeader."Document Type"::"Credit Memo", ExpectedReceiptDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchCrMemoWithSameExpectedReceiptDate()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Test to verify Purchase Credit Memo posted successfully with same Expected Receipt Date as Posting Date.
        PostedPurchDocumentWithExpectedReceiptDate(PurchaseHeader."Document Type"::"Credit Memo", WorkDate());  // Expected Receipt Date same as Posting Date.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchRetOrderWithHigherExpectedReceiptDate()
    var
        PurchaseHeader: Record "Purchase Header";
        ExpectedReceiptDate: Date;
    begin
        // Test to verify Purchase Return Order posted successfully with higher Expected Receipt Date than its Posting Date.
        ExpectedReceiptDate := CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate());  // Expected Receipt Date later than Posting Date.
        PostedPurchDocumentWithExpectedReceiptDate(PurchaseHeader."Document Type"::"Return Order", ExpectedReceiptDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchRetOrderWithEarlierExpectedReceiptDate()
    var
        PurchaseHeader: Record "Purchase Header";
        ExpectedReceiptDate: Date;
    begin
        // Test to verify Purchase Return Order posted successfully with earlier Expected Receipt Date than its Posting Date.
        ExpectedReceiptDate := CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate());  // Expected Receipt Date earlier than Posting Date.
        PostedPurchDocumentWithExpectedReceiptDate(PurchaseHeader."Document Type"::"Return Order", ExpectedReceiptDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchRetOrderWithSameExpectedReceiptDate()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Test to verify Purchase Return Order posted successfully with same Expected Receipt Date as Posting Date.
        PostedPurchDocumentWithExpectedReceiptDate(PurchaseHeader."Document Type"::"Return Order", WorkDate());  // Expected Receipt Date same as Posting Date.
    end;

    local procedure PostedPurchDocumentWithExpectedReceiptDate(DocumentType: Enum "Purchase Document Type"; ExpectedReceiptDate: Date)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchCrMemoHeaderNo: Code[20];
    begin
        // Create Purchase Document.
        CreatePurchaseDocument(PurchaseHeader, DocumentType, ExpectedReceiptDate, '');

        // Exercise: Post Purchase Document.
        PurchCrMemoHeaderNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify Purchase Document posted successfully with different Expected Receipt Date.
        PurchCrMemoHdr.Get(PurchCrMemoHeaderNo);
        PurchCrMemoHdr.TestField("Posting Date", WorkDate());
        PurchCrMemoHdr.TestField("Expected Receipt Date", ExpectedReceiptDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchInvoiceWithHigherExpectedReceiptDate()
    var
        ExpectedReceiptDate: Date;
    begin
        // Test to verify Purchase Invoice posted successfully with higher Expected Receipt Date than its Posting Date.
        ExpectedReceiptDate := CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate());  // Expected Receipt Date later than Posting Date.
        PostedPurchInvoiceWithExpectedReceiptDate(ExpectedReceiptDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchInvoiceWithEarlierExpectedReceiptDate()
    var
        ExpectedReceiptDate: Date;
    begin
        // Test to verify Purchase Invoice posted successfully with earlier Expected Receipt Date than its Posting Date.
        ExpectedReceiptDate := CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate());  // Expected Receipt Date earlier than Posting Date.
        PostedPurchInvoiceWithExpectedReceiptDate(ExpectedReceiptDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchInvoiceWithSameExpectedReceiptDate()
    begin
        // Test to verify Purchase Invoice posted successfully with same Expected Receipt Date as Posting Date.
        PostedPurchInvoiceWithExpectedReceiptDate(WorkDate());  // Expected Receipt Date same as Posting Date.
    end;

    local procedure PostedPurchInvoiceWithExpectedReceiptDate(ExpectedReceiptDate: Date)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvHeaderNo: Code[20];
    begin
        // Create Purchase Invoice.
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, ExpectedReceiptDate, '');

        // Exercise: Post Purchase Invoice.
        PurchInvHeaderNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify Purchase Invoice posted successfully with different Expected Receipt Date.
        PurchInvHeader.Get(PurchInvHeaderNo);
        PurchInvHeader.TestField("Posting Date", WorkDate());
        PurchInvHeader.TestField("Expected Receipt Date", ExpectedReceiptDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlanketPurchOrderMakeOrderWithHigherExpectedReceiptDate()
    var
        ExpectedReceiptDate: Date;
    begin
        // Test to verify Purchase Order created successfully Blanket Purchase Order with higher Expected Receipt Date than its Posting Date.
        ExpectedReceiptDate := CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate());  // Expected Receipt Date later than Posting Date.
        BlanketPurchOrderMakeOrderWithExpectedRcptDate(ExpectedReceiptDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlanketPurchOrderMakeOrderWithEalierExpectedRcptDate()
    var
        ExpectedReceiptDate: Date;
    begin
        // Test to verify Purchase Order created successfully Blanket Purchase Order with lesser Expected Receipt Date than its Posting Date.
        ExpectedReceiptDate := CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate());  // Expected Receipt Date earlier than Posting Date.
        BlanketPurchOrderMakeOrderWithExpectedRcptDate(ExpectedReceiptDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlanketPurchOrderMakeOrderWithSameExpectedRcptDate()
    begin
        // Test to verify Purchase Order created successfully Blanket Purchase Order with same Expected Receipt Date as Posting Date.
        BlanketPurchOrderMakeOrderWithExpectedRcptDate(WorkDate());  // Expected Receipt Date same as Posting Date.
    end;

    local procedure BlanketPurchOrderMakeOrderWithExpectedRcptDate(ExpectedReceiptDate: Date)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrderHeader: Record "Purchase Header";
    begin
        // Create Blanket Purchase Order.
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Blanket Order", ExpectedReceiptDate, '');

        // Exercise: Make Purchase Order from Blanket Purchase Order.
        PurchaseOrderHeader.Get(
          PurchaseOrderHeader."Document Type"::Order, LibraryPurchase.BlanketPurchaseOrderMakeOrder(PurchaseHeader));

        // Verify: Verify Purchase Order created successfully with different Expected Receipt Date.
        PurchaseOrderHeader.TestField("Expected Receipt Date", ExpectedReceiptDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchInvoiceWithCorrectNoSeries()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseInvHeaderNo: Code[20];
        OldExtDocNoMandatory: Boolean;
    begin
        // Setup: Update Ext. Doc. No. Mandatory - FALSE on Purchases & Payables Setup and Create Purchase Invoice.
        OldExtDocNoMandatory := UpdatePurchasesPayablesSetupExtDocNoMandatory(false);
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, WorkDate(), '');  // Expected Receipt Date - WORKDATE.

        // Exercise: Post Purchase Invoice.
        PurchaseInvHeaderNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify Purchase Invoice Header No. is updated with correct No. Series.
        PurchInvHeader.Get(PurchaseInvHeaderNo);
        PurchInvHeader.TestField("No.", FindNoSeriesLinePurchase(PurchaseHeader."Posting No. Series", PurchaseHeader."Posting Date"));

        // Teardown.
        UpdatePurchasesPayablesSetupExtDocNoMandatory(OldExtDocNoMandatory);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingNoSeriesIsUpdatedOnBuyFromVendorNoValidateOnBlankPurchaseInvoicePage()
    var
        NoSeriesLine: Record "No. Series Line";
        PurchaseHeader: Record "Purchase Header";
        VendorNo: Code[20];
        DocumentNo: Code[20];
        VATBusinessPostingGroupCode: Code[20];
        DefaultNoSeriesCode: Code[20];
    begin
        // [SCENARIO 233646] "VAT Bus. Posting Group"."Posting No. Series" is not applied when validating "Buy-From Vendor No." in "Purchase Invoice" Page.

        // [GIVEN] Posted Purchase Invoice No. Series exists at Purchases & Payables Setup.
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");
        DefaultNoSeriesCode := UpdatePurchasesPayablesSetupPostingNoSeries();

        // [GIVEN] No. Series "NSP" with "No. Series Type" = Purchase.
        // [GIVEN] "NSP" with a No. Series Line Purchase.
        LibraryERM.CreateNoSeriesLine(NoSeriesLine, LibraryERM.CreateNoSeriesPurchaseCode(), '', '');

        // [GIVEN] VAT Bus. Posting Group "VBPG" with "Default Purch. Operation Type" = "NSP".
        VATBusinessPostingGroupCode := SetupVATBusinessPostingGroup(NoSeriesLine."Series Code");

        // [GIVEN] Vendor "V" with "VBPG".
        VendorNo := LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATBusinessPostingGroupCode);

        // [WHEN] New Purchase Invoice created for vendor "V".
        DocumentNo := InitializePurchaseInvoiceForVendor(VendorNo);

        // [THEN] Purchase Invoice is created with "Posting No. Series" = "NSP".
        PurchaseHeader.Get(PurchaseHeader."Document Type"::Invoice, DocumentNo);
        PurchaseHeader.TestField("Posting No. Series", NoSeriesLine."Series Code");
        Assert.AreNotEqual(DefaultNoSeriesCode, PurchaseHeader."Posting No. Series", 'Posting No. Series must not match');

        LibrarySetupStorage.Restore();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchCreditMemoWithCorrectNoSeries()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchaseCrMemoHeaderNo: Code[20];
        OldExtDocNoMandatory: Boolean;
    begin
        // Setup: Update Ext. Doc. No. Mandatory - FALSE on Purchases & Payables Setup and Create Purchase Credit Memo.
        OldExtDocNoMandatory := UpdatePurchasesPayablesSetupExtDocNoMandatory(false);
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", WorkDate(), '');  // Expected Receipt Date - WORKDATE.

        // Exercise: Post Purchase Credit Memo.
        PurchaseCrMemoHeaderNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify Purchase Credit Memo Header No. is updated with correct No. Series.
        PurchCrMemoHdr.Get(PurchaseCrMemoHeaderNo);
        PurchCrMemoHdr.TestField("No.", FindNoSeriesLinePurchase(PurchaseHeader."Posting No. Series", PurchaseHeader."Posting Date"));

        // Teardown.
        UpdatePurchasesPayablesSetupExtDocNoMandatory(OldExtDocNoMandatory);
    end;

    [Test]
    [HandlerFunctions('VendorSheetPrintRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VendorSheetPrintForPayment()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        CurrencyCode: Code[10];
        PostedPurchaseInvoiceNo: Code[20];
        Amount: Decimal;
    begin
        // Setup: Create Currency with Exchange rate, create and post Purchase Invoice with that Currency and Apply payment for Invoice on next year.
        CurrencyCode := LibraryERM.CreateCurrencyWithRandomExchRates();
        LibraryERM.RunExchRateAdjustmentSimple(CurrencyCode, WorkDate(), WorkDate());  // Ending Date, Posting Date - WORKDATE.
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, WorkDate(), CurrencyCode);  // Expected Receipt Date.

        PostedPurchaseInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        PurchInvHeader.Get(PostedPurchaseInvoiceNo);
        Amount := ApplyPaymentForInvoice(PurchInvHeader."Buy-from Vendor No.", PostedPurchaseInvoiceNo);

        // Exercise: Run Report Vendor Sheet - Print with Date filter on the Date range of payment rather than Purchase Invoice.
        RunVendorSheetPrint(PurchInvHeader."Buy-from Vendor No.");

        // Verify: Verify Vendor and Amount of Payment updated on report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(VendoNoCap, PurchInvHeader."Buy-from Vendor No.");
        LibraryReportDataset.AssertElementWithValueExists(AmountLCYCap, Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedCreditMemoWithGetReturnShipmentLine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchCrMemoHdrNo: Code[20];
        AmountInclVAT: Decimal;
    begin
        // Setup: Create Purchase Return Order, Create Purchase Credit memo and Get Return Shipment Line on it with updating Check Total.
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", WorkDate(), '');
        AmountInclVAT := UpdatePurchaseLineDirectUnitCost(PurchaseHeader."No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);  // Post Return Order as Ship.
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader2, PurchaseHeader2."Document Type"::"Credit Memo", PurchaseHeader."Buy-from Vendor No.");
        GetReturnShipmentLine(PurchaseHeader2);
        UpdatePurchaseHeaderCheckTotal(PurchaseHeader2, AmountInclVAT);

        // Exercise: Post Purchase Credit Memo.
        PurchCrMemoHdrNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader2, true, true);

        // Verify: Verify Purchase Credit Memo posted successfully after updating Check Total.
        PurchCrMemoHdr.Get(PurchCrMemoHdrNo);
        PurchCrMemoHdr.TestField("Buy-from Vendor No.", PurchaseHeader."Buy-from Vendor No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckDueDateDetailedVendorLedgEntryAfterPostingPurchaseInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // SETUP
        CreatePurchaseHeaderWithPaymentTerms(PurchaseHeader);
        // EXERCISE
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        // VERIFY
        VerifyDetailedVendorLedgEntryDueDate(PurchaseHeader."Buy-from Vendor No.");
    end;

    local procedure ApplyPaymentForInvoice(AccountNo: Code[20]; AppliestoDocNo: Code[20]) Amount: Decimal
    var
        BankAccount: Record "Bank Account";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        FindGenJournalBatch(GenJournalBatch);
        Amount := LibraryRandom.RandDec(10, 2);  // Using Ranodm value for Amount.
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, AccountNo, Amount);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", AppliestoDocNo);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Bal. Account No.", BankAccount."No.");
        GenJournalLine.Validate("Posting Date", CalcDate('<1Y>', WorkDate()));
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; ExpectedReceiptDate: Date; CurrencyCode: Code[10])
    var
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, Vendor."No.");
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Validate("Expected Receipt Date", ExpectedReceiptDate);
        PurchaseHeader.Validate("Currency Code", CurrencyCode);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItem(Item), LibraryRandom.RandDec(10, 2));  // Random value for Quantity.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(1000, 2000, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure InitializePurchaseInvoiceForVendor(VendorNo: Code[20]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.Init();
        PurchaseHeader.Validate("Document Type", PurchaseHeader."Document Type"::Invoice);
        PurchaseHeader.Validate("Buy-from Vendor No.", VendorNo);
        PurchaseHeader.Insert(true);
        exit(PurchaseHeader."No.");
    end;

    local procedure FindGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Payments);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.FindGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
    end;

    local procedure FindNoSeriesLinePurchase(NoSeriesCode: Code[20]; LastDateUsed: Date): Code[20]
    var
        NoSeriesLine: Record "No. Series Line";
    begin
#pragma warning disable AA0210
        NoSeriesLine.SetRange("No. Series Type", NoSeriesLine."No. Series Type"::"Purchase");
#pragma warning disable AA0210
        NoSeriesLine.SetRange("Series Code", NoSeriesCode);
        NoSeriesLine.SetRange("Last Date Used", LastDateUsed);
        NoSeriesLine.FindFirst();
        exit(NoSeriesLine."Last No. Used");
    end;

    local procedure GetReturnShipmentLine(PurchaseHeader: Record "Purchase Header")
    var
        ReturnShipmentLine: Record "Return Shipment Line";
        PurchGetReturnShipments: Codeunit "Purch.-Get Return Shipments";
    begin
        ReturnShipmentLine.SetRange("Buy-from Vendor No.", PurchaseHeader."Buy-from Vendor No.");
        ReturnShipmentLine.FindLast();
        PurchGetReturnShipments.SetPurchHeader(PurchaseHeader);
        PurchGetReturnShipments.CreateInvLines(ReturnShipmentLine);
    end;

    local procedure UpdatePurchaseLineDirectUnitCost(DocumentNo: Code[20]): Decimal
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::"Return Order");
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.FindFirst();
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));
        PurchaseLine.Modify(true);
        exit(PurchaseLine."Amount Including VAT");
    end;

    local procedure UpdatePurchaseHeaderCheckTotal(var PurchaseHeader: Record "Purchase Header"; CheckTotal: Decimal)
    begin
        PurchaseHeader.Validate("Check Total", CheckTotal);
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
    end;

    local procedure RunVendorSheetPrint(No: Code[20])
    var
        Vendor: Record Vendor;
        VendorSheetPrint: Report "Vendor Sheet - Print";
    begin
        Commit();  // Commit Required.
        Clear(VendorSheetPrint);
        Vendor.SetRange("No.", No);
        Vendor.SetRange("Date Filter", CalcDate('<-CY + 1Y>', WorkDate()), CalcDate('<CY + 1Y>', WorkDate()));  // Date filter on the Date range of payment.
        VendorSheetPrint.SetTableView(Vendor);
        VendorSheetPrint.Run();
    end;

    local procedure UpdatePurchasesPayablesSetupExtDocNoMandatory(ExtDocNoMandatory: Boolean) OldExtDocNoMandatory: Boolean
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        OldExtDocNoMandatory := PurchasesPayablesSetup."Ext. Doc. No. Mandatory";
        PurchasesPayablesSetup.Validate("Ext. Doc. No. Mandatory", ExtDocNoMandatory);
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure UpdatePurchasesPayablesSetupPostingNoSeries(): Code[20]
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup."Posted Invoice Nos." := LibraryERM.CreateNoSeriesCode();
        PurchasesPayablesSetup.Modify();
        exit(PurchasesPayablesSetup."Posted Invoice Nos.");
    end;

    local procedure CreatePurchaseHeaderWithPaymentTerms(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice,
          LibraryPurchase.CreateVendor(Vendor));
        PurchaseHeader.Validate("Payment Terms Code", CreatePaymentTerms());
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item,
          LibraryInventory.CreateItem(Item), LibraryRandom.RandDec(100, 2));
    end;

    local procedure CreatePaymentTerms(): Code[10]
    var
        PaymentTerms: Record "Payment Terms";
        PaymentLines: Record "Payment Lines";
    begin
        LibraryERM.CreatePaymentTermsIT(PaymentTerms);
        LibraryERM.CreatePaymentLines(PaymentLines, PaymentLines."Sales/Purchase"::" ", PaymentLines.Type::"Payment Terms", PaymentTerms.Code, '', 0);
        Evaluate(PaymentLines."Due Date Calculation", '<' + Format(LibraryRandom.RandInt(30)) + 'D>');
        PaymentLines.Validate("Due Date Calculation", PaymentLines."Due Date Calculation");
        PaymentLines.Modify(true);
        exit(PaymentLines.Code);
    end;

    local procedure FindVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; DocumentType: Enum "Gen. Journal Document Type"; VendorNo: Code[20])
    begin
        VendorLedgerEntry.SetRange("Document Type", DocumentType);
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.FindFirst();
    end;

    local procedure SetupVATBusinessPostingGroup(SeriesCode: Code[20]): Code[20]
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
    begin
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        VATBusinessPostingGroup."Default Purch. Operation Type" := SeriesCode;
        VATBusinessPostingGroup.Modify();
        exit(VATBusinessPostingGroup.Code);
    end;

    local procedure VerifyDetailedVendorLedgEntryDueDate(VendorNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, VendorNo);
        DetailedVendorLedgEntry.SetRange("Vendor Ledger Entry No.", VendorLedgerEntry."Entry No.");
        DetailedVendorLedgEntry.FindLast();
        Assert.AreEqual(VendorLedgerEntry."Due Date", DetailedVendorLedgEntry."Initial Entry Due Date", WrongDueDateDetailedVendorLedgEntryErr);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VendorSheetPrintRequestPageHandler(var VendorSheetPrint: TestRequestPage "Vendor Sheet - Print")
    begin
        VendorSheetPrint.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

