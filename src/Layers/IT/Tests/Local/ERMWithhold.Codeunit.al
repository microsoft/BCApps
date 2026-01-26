codeunit 144090 "ERM Withhold"
{
    // Test for Withhold Tax functionality.
    //  1. Verify Social Security Code on Vendor - using Lookup and select Contribution code.
    //  2. Verify Social Security Code on Vendor - using Lookup and create new Contribution code.
    //  3. Verify INAIL Code on Vendor - using Lookup and select Contribution code.
    //  4. Verify INAIL Code on Vendor - using Lookup and create new Contribution code.
    //  5. Verify Payable Amount on Withh. Taxes-Contribution Card window after creating purchase credit memo.
    //  6. Verify Payable Amount on Withh. Taxes-Contribution Card window after creating purchase invoice.
    //  7. Verify withholding tax is calculated correctly when using Base Excluded Amount after creating purchase invoice.
    //  8. Verify Tax value on Withh. Taxes-Contribution Card after creating Payment Journal with apply Posted Purchase Invoice.
    //  9. Verify Tax value on Withholding Tax after posting Payment Journal with apply Posted Purchase Invoice.
    // 10. Verify withholding tax amount on the payment of a purchase invoice is correct in Payment Journal.
    // 11. Verify no error message on Posting of Purchase Credit memo with apply Posted Purchase Invoice with withhold Tax and verify Amount in Vendor Ledger Entry.
    // 12. Verify Contributions after Posting of Payment Journal with apply Posted Purchase Invoice.
    // 13. Verify Gross Amount on Withh. Taxes-Contribution Card after creating Payment Journal.
    // 14. Verify Gross Amount same as Total Amount on Withh. Taxes-Contribution Card after creating Purchase Invoice.
    // 15. Verify Gross Amount same as Total Amount after update Total Amount on Withh. Taxes-Contribution Card after creating Purchase Invoice.
    // 16. Verify Error message on Posting of Payment Journal with apply Posted Purchase Invoice without Calculate Withhold Taxes Contribution.
    // 17. Verify no error message when posting a credit memo without withholding tax which is linked to an invoice with withholding tax and verify Amount in Vendor Ledger Entry.
    // 18. Verify error message "Document Type must be Payment or Refund type" pops up when running Withh. Tax-Soc.Sec. on Payment Journal.
    // 19. Verify INAIL Free-Lance Amount on Withh. Taxes-Contribution Card after creating Purchase Invoice.
    // 20. Verify Tax value on Report Certifications after posting Payment Journal as Refund with apply Posted Purchase Credit Memo.
    // 21. Verify Tax value on Report Certifications after posting Payment Journal with apply Posted Purchase Invoice.
    // 22. Verify Paid field on Withhold Tax when entry in the Withhold Tax Payment is deleted.
    // 23. Verify Withholding Tax Amount On Sub form Vendor Bill Lines after Insert Line from Manual Vendor Payment Line Page.
    // 24. Verify Taxable Base and Withholding Tax Amount on Withh. Taxes-Contribution Card while purchase invoice having Prices Including VAT Boolean - TRUE.
    // 25. Verify VAT Base Amount and VAT Amount on G/L Entry while purchase invoice having Prices Including VAT - TRUE.
    // 26. Verify Withholding Tax Entry after Post payment journal applied to posted Purchase invoice while Prices Including VAT - TRUE.
    // 27. Verify posting Withholding Tax Payment Journal using different Bal. Account can succeed and verify the tax amount in Vendor Ledger Entry.
    // 
    // Covers Test Cases for IT - 344606, 346115
    // -----------------------------------------------------------------------------------
    // Test Function Name                                                           TFS ID
    // -----------------------------------------------------------------------------------
    // SocialSecurityCodeLookupOnVendor                                             156448
    // SocialSecurityCodeCreatedOnLookupVendor                                      156449
    // INAILCodeLookupOnVendor                                                      156446
    // INAILCodeCreatedOnLookupVendor                                               156447
    // WithholdTaxesContributionOnPurchaseCreditMemo                                155470
    // WithholdTaxesContributionOnPurchaseInvoice                            152762,155469
    // WithholdTaxesWithBaseExcludedAmtOnPurchInvoice                               238885
    // WithholdTaxesContributionOnPaymentJnl                                        152762
    // WithholdingTaxPaymentJnlWithAppliesToInvoice                                 152762
    // WithholdingTaxPaymentJnlLine                                                 155866
    // PurchCreditMemoWithApplyWithholdTaxInvoice                                   155865
    // ContributionsPaymentJnlWithAppliesToInvoice                                  156450
    // VendorWithINPSAndTotalAmtPaymentJnl                                          203831
    // VendorWithINPSAndGrossAmtSameAsTotalAmtPurchInvoice                          203831
    // VendorWithINPSAndTotalAmtPurchInvoice                                        203831
    // PaymentJnlWithoutShowComputedWithholdTaxesError                              156861
    // PaymentJnlDocTypeCreditMemoAppliesToInvoice                                  156862
    // PaymentJnlDocTypeCreditMemoWithholdTaxesError                                259561
    // VendorINAILWithholdTaxesContributionOnPurchaseInvoice                        214229
    // CertificationsRefundPaymentJnlWithAppliesToCreditMemo                        259560
    // CertificationsPaymentJnlWithAppliesToInvoice                                 259560
    // WithholdingTaxPaidAsFalseDeleteWithholdTaxPayment                            278484
    // 
    // Covers Test Cases for WI - 349081.
    // ------------------------------------------------------------------------------------
    // Test Function Name                                                           TFS ID
    // -------------------------------------------------------------------------------------
    // WithholdingTaxAmountOnSubformVendorBillLines,
    // PurchaseInvoiceWithPricesIncludingVAT,
    // PostedPurchaseInvoiceWithPricesIncludingVAT,
    // PaymentJournalWithPricesIncludingVAT                                         348901
    // 
    // Covers Test Cases for IT - Sicily Bug
    // -----------------------------------------------------------------------------------
    // Test Function Name                                                           TFS ID
    // -----------------------------------------------------------------------------------
    // WithholdingTaxPaymentJnlUsingDifferentBalAccount                              70414

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Withholding Tax]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryITLocalization: Codeunit "Library - IT Localization";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        DocumentTypeErr: Label 'Document Type must be Payment or Refund';
        NonTaxableAmountCap: Label 'Withholding_Tax__Non_Taxable_Amount_';
        StringTxt: Label 'A', Comment = 'Single character string is required for the field 770 Code which is of 1 character';
        TaxableBaseCap: Label 'Withholding_Tax__Taxable_Base_';
        ValueMustBeSameMsg: Label 'Value must be same.';
        WithholdingTaxAmountCap: Label 'Withholding_Tax__Withholding_Tax_Amount_';
        LibraryRandom: Codeunit "Library - Random";
        WithholdingTaxErr: Label 'Because this invoice includes Withholding Tax, it should not be applied directly. Please use the function Payment Journals -> Payments -> Withh.Tax-Soc.Sec.';
        LibraryJournals: Codeunit "Library - Journals";
        PurchWithhContributionErr: Label 'Social Security Contribution fot Purchase Invoice was calculated incorrect.';
        RemainingGrossAmountErr: Label 'Remaining Gross Amount was calculated wrong.';
        WHTAmtManualEqWHTAmtErr: Label '%1 must not be equal to %2 in %3.', Comment = '%1=FIELDCAPTION("WHT Amount Manual"),%2=FIELDCAPTION("Withholding Tax Amount"),%3=TABLECAPTION("Purch. Withh. Contribution")';
        WHTAmtZeroTestFieldErr: Label '%1 must have a value in %2', Comment = '%1=FIELDCAPTION("Withholding Tax Amount"),%2=TABLECAPTION("Purch. Withh. Contribution")';
        TestFieldErr: Label 'TestField';
        DialogErr: Label 'Dialog';
        LibraryApplicationArea: Codeunit "Library - Application Area";
        MultiApplyErr: Label 'To calculate taxes correctly, the payment must be applied to only one document.';
        WithHoldingAmountZeroErr: Label 'Withholding Amount should be 0 in Vendor Bill Line.';
        TotalAmountErr: Label '%1 must be %2 in %3', Comment = '%1 = Total Amount, %2 = Line Amount, %3 = ComputedWithholdingTax';
        RemainingAmountErr: Label '%1 must be %2 in %3', Comment = '%1 = Remaining Amount, %2 = Line Amount, %3 = ComputedWithholdingTax';

    [Test]
    [HandlerFunctions('ContributionCodesINPSModalPageHandler')]
    [Scope('OnPrem')]
    procedure SocialSecurityCodeLookupOnVendor()
    var
        ContributionCode: Record "Contribution Code";
        Vendor: Record Vendor;
    begin
        // Verify Social Security Code on Vendor - using Lookup and select Contribution code.

        // Setup: Create Contribution code with Type INPS and create Vendor.
        Initialize();
        CreateContributionCode(ContributionCode, ContributionCode."Contribution Type"::INPS);
        LibraryVariableStorage.Enqueue(ContributionCode.Code);
        LibraryPurchase.CreateVendor(Vendor);

        // Exercise: Lookup on Social Security code on Vendor Card and Set value in Page Handler - ContributionCodesINPSModalPageHandler.
        SocialSecurityCodeLookupOnVendorCard(Vendor."No.");

        // Verify: Verify Social Security Code updated in Vendor.
        VerifySocialSecurityCodeOnVendor(Vendor."No.", ContributionCode.Code);
    end;

    [Test]
    [HandlerFunctions('NewContributionCodesINPSModalPageHandler')]
    [Scope('OnPrem')]
    procedure SocialSecurityCodeCreatedOnLookupVendor()
    var
        Vendor: Record Vendor;
        SocialSecurityCode: Variant;
    begin
        // Verify Social Security Code on Vendor - using Lookup and create new Contribution code.

        // Setup.
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);

        // Exercise: Lookup on Social Security code on Vendor Card and create new in Page Handler - NewContributionCodesINPSModalPageHandler.
        SocialSecurityCodeLookupOnVendorCard(Vendor."No.");

        // Verify: Verify Social Security Code updated in Vendor.
        LibraryVariableStorage.Dequeue(SocialSecurityCode);
        VerifySocialSecurityCodeOnVendor(Vendor."No.", SocialSecurityCode);
    end;

    [Test]
    [HandlerFunctions('ContributionCodesINAILModalPageHandler')]
    [Scope('OnPrem')]
    procedure INAILCodeLookupOnVendor()
    var
        ContributionCode: Record "Contribution Code";
        Vendor: Record Vendor;
    begin
        // Verify INAIL Code on Vendor - using Lookup and select Contribution code.

        // Setup: Create Contribution code with Type INAIL and create Vendor.
        Initialize();
        CreateContributionCode(ContributionCode, ContributionCode."Contribution Type"::INAIL);
        LibraryVariableStorage.Enqueue(ContributionCode.Code);
        LibraryPurchase.CreateVendor(Vendor);

        // Exercise: Lookup on INAIL code on Vendor Card and Set value in Page Handler - ContributionCodesINAILModalPageHandler.
        INAILCodeLookupOnVendorCard(Vendor."No.");

        // Verify: Verify INAIL Code updated in Vendor.
        VerifyINAILCodeOnVendor(Vendor."No.", ContributionCode.Code);
    end;

    [Test]
    [HandlerFunctions('NewContributionCodesINAILModalPageHandler')]
    [Scope('OnPrem')]
    procedure INAILCodeCreatedOnLookupVendor()
    var
        Vendor: Record Vendor;
        INAILCode: Variant;
    begin
        // Verify INAIL Code on Vendor - using Lookup and create new Contribution code.

        // Setup.
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);

        // Exercise: Lookup on INAIL code on Vendor Card and create new in Page Handler - NewContributionCodesINAILModalPageHandler.
        INAILCodeLookupOnVendorCard(Vendor."No.");

        // Verify: Verify INAIL Code updated in Vendor.
        LibraryVariableStorage.Dequeue(INAILCode);
        VerifyINAILCodeOnVendor(Vendor."No.", INAILCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WithholdTaxesContributionOnPurchaseCreditMemo()
    var
        PurchaseLine: Record "Purchase Line";
        WithhTaxesContributionCard: TestPage "Withh. Taxes-Contribution Card";
        TaxableBase: Decimal;
        WithholdingTaxAmount: Decimal;
    begin
        // Verify Payable Amount on Withh. Taxes-Contribution Card window after creating purchase credit memo.

        // Setup: Create Purchase Credit Memo.
        Initialize();
        CreatePurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::"Credit Memo", CreateVendor('', ''), false);  // Blank Social Security Code,INAIL Code and Prices Including VAT - FALSE.
        WithholdingTaxAmount := CalculateWithholdTaxes(PurchaseLine."Buy-from Vendor No.", PurchaseLine."Line Amount", TaxableBase);

        // Exercise: Calculate Withhold Taxes Contribution on Purchase Credit Memo page.
        CalculateWithholdTaxesContributionOnPurchCrMemo(WithhTaxesContributionCard, PurchaseLine."Document No.");

        // Verify: Verify Payable Amount, Taxable Base, Non Taxable Amount, Withholding Tax Amount on Page -Withhold Taxes-Contribution Card.
        VerifyTaxOnWithholdTaxesContributionCardPage(
          WithhTaxesContributionCard, PurchaseLine."Amount Including VAT", PurchaseLine."Line Amount", TaxableBase, WithholdingTaxAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WithholdTaxesContributionOnPurchaseInvoice()
    var
        PurchaseLine: Record "Purchase Line";
        WithhTaxesContributionCard: TestPage "Withh. Taxes-Contribution Card";
        TaxableBase: Decimal;
        WithholdingTaxAmount: Decimal;
    begin
        // Verify Payable Amount on Withh. Taxes-Contribution Card window after creating purchase invoice.

        // Setup: Create Purchase Invoice.
        Initialize();
        CreatePurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::Invoice, CreateVendor('', ''), false);  // Blank Social Security Code, INAIL Code and Prices Including VAT - FALSE.
        WithholdingTaxAmount := CalculateWithholdTaxes(PurchaseLine."Buy-from Vendor No.", PurchaseLine."Line Amount", TaxableBase);

        // Exercise: Calculate Withhold Taxes Contribution on Purchase Invoice page.
        CalculateWithholdTaxesContributionOnPurchInvoice(WithhTaxesContributionCard, PurchaseLine."Document No.");

        // Verify: Verify Payable Amount, Taxable Base, Non Taxable Amount, Withholding Tax Amount on Page -Withhold Taxes-Contribution Card.
        VerifyTaxOnWithholdTaxesContributionCardPage(
          WithhTaxesContributionCard, PurchaseLine."Amount Including VAT", PurchaseLine."Line Amount", TaxableBase, WithholdingTaxAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WithholdTaxesWithBaseExcludedAmtOnPurchInvoice()
    var
        PurchaseLine: Record "Purchase Line";
        WithhTaxesContributionCard: TestPage "Withh. Taxes-Contribution Card";
        BaseExcludedAmount: Decimal;
        TaxableBase: Decimal;
        WithholdingTaxAmount: Decimal;
    begin
        // Verify withholding tax is calculated correctly when using Base Excluded Amount after creating purchase invoice.

        // Setup: Create Purchase Invoice and Calculate Withhold Taxes Contribution.
        Initialize();
        BaseExcludedAmount := LibraryRandom.RandDec(10, 2);
        CreatePurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::Invoice, CreateVendor('', ''), false);  // Blank Social Security Code, INAIL Code and Prices Including VAT - FALSE..
        WithholdingTaxAmount :=
          CalculateWithholdTaxes(PurchaseLine."Buy-from Vendor No.", PurchaseLine."Line Amount" - BaseExcludedAmount, TaxableBase);
        CalculateWithholdTaxesContributionOnPurchInvoice(WithhTaxesContributionCard, PurchaseLine."Document No.");

        // Exercise: Update Base Excluded Amount value on Page.
        WithhTaxesContributionCard."Base - Excluded Amount".SetValue(BaseExcludedAmount);

        // Verify: Verify Payable Amount, Taxable Base, Non Taxable Amount, Withholding Tax Amount on Page -Withhold Taxes-Contribution Card after updating Base Excluded Amount value.
        VerifyTaxOnWithholdTaxesContributionCardPage(
          WithhTaxesContributionCard, PurchaseLine."Amount Including VAT", PurchaseLine."Line Amount" - BaseExcludedAmount, TaxableBase,
          WithholdingTaxAmount);
    end;

    [Test]
    [HandlerFunctions('TaxableValueShowComputedWithholdContribModalPageHandler')]
    [Scope('OnPrem')]
    procedure WithholdTaxesContributionOnPaymentJnl()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseLine: Record "Purchase Line";
        PostedDocumentNo: Code[20];
        NonTaxableAmount: Decimal;
        TaxableBase: Decimal;
    begin
        // Verify Tax value on Withh. Taxes-Contribution Card after creating Payment Journal with apply Posted Purchase Invoice.

        // Setup: Create and Post Purchase Invoice and Create and Apply payment Journal.
        Initialize();
        PostedDocumentNo := CreateAndPostPurchaseInvoice(PurchaseLine, '', '');  // Blank for Social Security Code and INAIL Code.
        CalculateWithholdTaxes(PurchaseLine."Buy-from Vendor No.", PurchaseLine."Line Amount", TaxableBase);
        NonTaxableAmount := PurchaseLine."Line Amount" - TaxableBase;

        // Enqueue value for Handler -TaxableValueShowComputedWithholdContribModalPageHandler
        CreateAndApplyGeneralJnlLine(
          GenJournalLine, GenJournalLine."Document Type"::Payment, PostedDocumentNo, GenJournalLine."Applies-to Doc. Type"::Invoice);
        LibraryVariableStorage.Enqueue(TaxableBase);
        LibraryVariableStorage.Enqueue(NonTaxableAmount);

        // Exercise: Show Computed Withhold Taxes Contribution on Payment Journal Page.
        ShowComputedWithholdContributionOnPayment(GenJournalLine."Journal Batch Name");

        // Verify: Verify Taxable Base and Non Taxable Amount in Handler -TaxableValueShowComputedWithholdContribModalPageHandler.
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ShowComputedWithholdContribModalPageHandler')]
    [Scope('OnPrem')]
    procedure WithholdingTaxPaymentJnlWithAppliesToInvoice()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseLine: Record "Purchase Line";
        PostedDocumentNo: Code[20];
        NonTaxableAmount: Decimal;
        TaxableBase: Decimal;
        WithholdingTaxAmount: Decimal;
    begin
        // [SCENARIO] Tax value on Withholding Tax after posting Payment Journal with apply Posted Purchase Invoice.

        // [GIVEN] Posted Purchase Invoice.
        Initialize();
        PostedDocumentNo := CreateAndPostPurchaseInvoice(PurchaseLine, '', '');  // Blank for Social Security Code and INAIL Code.
        WithholdingTaxAmount := CalculateWithholdTaxes(PurchaseLine."Buy-from Vendor No.", PurchaseLine."Line Amount", TaxableBase);
        NonTaxableAmount := PurchaseLine."Line Amount" - TaxableBase;

        // [WHEN] Create and Post Payment Journal with applies to Posted Invoice.
        CreateAndPostGeneralJnlLineWithAppliesToDoc(
          GenJournalLine."Document Type"::Payment, PostedDocumentNo, GenJournalLine."Applies-to Doc. Type"::Invoice);

        // [THEN] Record from table Tmp Withholding Contribution is deleted.
        VerifyTmpWithholdingContributionEmpty(PostedDocumentNo);
        // [THEN] Verify Non Taxable Amount, Taxable Base, Withholding Tax Amount on Withholding Tax.
        VerifyWithholdingTax(PurchaseLine."Buy-from Vendor No.", NonTaxableAmount, TaxableBase, WithholdingTaxAmount);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ShowComputedWithhContribModalPageHandler')]
    [Scope('OnPrem')]
    procedure WithholdingTaxNoCalcAmtPaymentJnlWithAppliesToInvoice()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseLine: Record "Purchase Line";
        PostedDocumentNo: Code[20];
        TaxableBase: Decimal;
    begin
        // [SCENARIO 374904] Record in Tmp Withholding Contribution table is cleared after posting Payment Journal with apply Posted Purchase Invoice.

        // [GIVEN] Posted Purchase Invoice with Withholding Tax Amount = 0.
        Initialize();
        PostedDocumentNo := CreateAndPostPurchaseInvoice(PurchaseLine, '', '');
        CalculateWithholdTaxes(PurchaseLine."Buy-from Vendor No.", PurchaseLine."Line Amount", TaxableBase);

        // [GIVEN] Create Payment Journal with applies to Posted Invoice.

        // [WHEN] Post Payment Journal.
        CreateAndPostGeneralJnlLineWithAppliesToDoc(
          GenJournalLine."Document Type"::Payment, PostedDocumentNo, GenJournalLine."Applies-to Doc. Type"::Invoice);

        // [THEN] Record from table Tmp Withholding Contribution is deleted.
        VerifyTmpWithholdingContributionEmpty(PostedDocumentNo);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ShowComputedWithhContribModalPageHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure MultipleWithholdingTaxNoCalcAmtPmtJnlWithAppliesToInvoice()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        PurchaseLine: Record "Purchase Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        InvoiceNo: array[2] of Code[20];
        TaxableBase: Decimal;
        i: Integer;
    begin
        // [SCENARIO 374904] Only 1 line in Tmp Withholding Contribution table is removed after posting only 1 Payment Journal line.
        Initialize();

        // [GIVEN] Posted 2 Purchase Invoices and 2 Payment Journal lines applied to invoices with Withholding Tax Amount = 0.
        CreateGenJournalBatch(GenJournalBatch);
        for i := 1 to 2 do begin
            InvoiceNo[i] := CreateAndPostPurchaseInvoice(PurchaseLine, '', '');
            CalculateWithholdTaxes(PurchaseLine."Buy-from Vendor No.", PurchaseLine."Line Amount", TaxableBase);

            LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Applies-to Doc. Type"::Invoice, InvoiceNo[i]);
            VendorLedgerEntry.CalcFields(Amount);

            CreateJournalLineWithAppliesToDocNo(
              GenJournalBatch, VendorLedgerEntry."Vendor No.", InvoiceNo[i], -VendorLedgerEntry.Amount);
            ShowComputedWithholdContributionOnPayment(GenJournalBatch.Name);
            VerifyTmpWithholdingContributionNotEmpty(InvoiceNo[i]);
        end;

        // [WHEN] Post second Payment Journal line.
        PostPaymentJournalWithPage(GenJournalBatch.Name, PurchaseLine."Buy-from Vendor No.");

        // [THEN] 2nd Record for Invoice 2 from table TempWithholdingSocSec is deleted, 1st line for Invoice 2 exists.
        VerifyTmpWithholdingContributionNotEmpty(InvoiceNo[1]);
        VerifyTmpWithholdingContributionEmpty(InvoiceNo[2]);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ShowComputedWithholdContribModalPageHandler')]
    [Scope('OnPrem')]
    procedure WithholdingTaxPaymentJnlLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseLine: Record "Purchase Line";
        PostedDocumentNo: Code[20];
        TaxableBase: Decimal;
        WithholdingTaxAmount: Decimal;
    begin
        // Verify withholding tax amount on the payment of a purchase invoice is correct in Payment Journal.

        // Setup: Create and Post Purchase Invoice and Create and Apply Payment Journal.
        Initialize();
        PostedDocumentNo := CreateAndPostPurchaseInvoice(PurchaseLine, '', '');  // Blank for Social Security Code and INAIL Code.
        WithholdingTaxAmount := CalculateWithholdTaxes(PurchaseLine."Buy-from Vendor No.", PurchaseLine."Line Amount", TaxableBase);
        CreateAndApplyGeneralJnlLine(
          GenJournalLine, GenJournalLine."Document Type"::Payment, PostedDocumentNo, GenJournalLine."Applies-to Doc. Type"::Invoice);

        // Exercise: Show Computed Withhold Taxes Contribution on Payment Journal Page.
        ShowComputedWithholdContributionOnPayment(GenJournalLine."Journal Batch Name");

        // Verify: Verify new created General Journal Line with Withholding tax amount.
        VerifyGenJournalLine(
          PurchaseLine."Buy-from Vendor No.", GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name",
          WithholdingTaxAmount);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCreditMemoWithApplyWithholdTaxInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GenJournalLine: Record "Gen. Journal Line";
        WithhTaxesContributionCard: TestPage "Withh. Taxes-Contribution Card";
        PostedDocumentNo: Code[20];
    begin
        // Verify no error message on Posting of Purchase Credit memo with apply Posted Purchase Invoice with withhold Tax and verify Amount in Vendor Ledger Entry.

        // Setup: Create and post Purchase Invoice and create Purchase Credit Memo and apply with Posted Purchase Invoice.
        Initialize();
        PostedDocumentNo := CreateAndPostPurchaseInvoice(PurchaseLine, '', '');  // Blank for Social Security Code and INAIL Code.
        CreatePurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::"Credit Memo", PurchaseLine."Buy-from Vendor No.", false);  // Prices Including VAT - FALSE.
        UpdateAppliesToDocOnPurchaseHeader(PurchaseHeader, PurchaseLine."Document No.", PostedDocumentNo);
        CalculateWithholdTaxesContributionOnPurchCrMemo(WithhTaxesContributionCard, PurchaseHeader."No.");

        // Exercise.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify.
        VerifyAmountInVendorLedgerEntry(
          GenJournalLine."Document Type"::"Credit Memo", PurchaseLine."Buy-from Vendor No.",
          GenJournalLine."Account Type"::"G/L Account", '', PurchaseLine."Amount Including VAT");
    end;

    [Test]
    [HandlerFunctions('ShowComputedWithholdContribModalPageHandler')]
    [Scope('OnPrem')]
    procedure ContributionsPaymentJnlWithAppliesToInvoice()
    var
        ContributionCodeLine: Record "Contribution Code Line";
        ContributionCodeLine2: Record "Contribution Code Line";
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseLine: Record "Purchase Line";
        PostedDocumentNo: Code[20];
    begin
        // Verify Contributions after Posting of Payment Journal with apply Posted Purchase Invoice.

        // Setup: Create Contribution Code with Type as INAIL and INPS. Create and Post Purchase Invoice.
        Initialize();
        CreateContributionCodeWithLine(ContributionCodeLine, ContributionCodeLine."Contribution Type"::INAIL);
        CreateContributionCodeWithLine(ContributionCodeLine2, ContributionCodeLine2."Contribution Type"::INPS);
        PostedDocumentNo := CreateAndPostPurchaseInvoice(PurchaseLine, ContributionCodeLine2.Code, ContributionCodeLine.Code);

        // Exercise.
        CreateAndPostGeneralJnlLineWithAppliesToDoc(
          GenJournalLine."Document Type"::Payment, PostedDocumentNo, GenJournalLine."Applies-to Doc. Type"::Invoice);

        // Verify: Verify Social Security % and INAIL Free-Lance % on Contributions.
        VerifyContributions(
          ContributionCodeLine2.Code, ContributionCodeLine.Code, ContributionCodeLine2."Social Security %",
          ContributionCodeLine."Free-Lance Amount %");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('GrossAmountShowComputedWithhContribModalPageHandler')]
    [Scope('OnPrem')]
    procedure VendorWithINPSAndTotalAmtPaymentJnl()
    var
        ContributionCodeLine: Record "Contribution Code Line";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Verify Gross Amount on Withh. Taxes-Contribution Card after creating Payment Journal.

        // Setup: Create Contribution Code with Type INPS and Create General Journal.
        Initialize();
        CreateContributionCodeWithLine(ContributionCodeLine, ContributionCodeLine."Contribution Type"::INPS);
        CreateGeneralJnlLine(
          GenJournalLine, GenJournalLine."Document Type"::Payment, CreateVendor(ContributionCodeLine.Code, ''),
          LibraryRandom.RandDecInRange(100, 500, 2));  // Blank for INAIL Code.
        ShowComputedWithholdContributionOnPayment(GenJournalLine."Journal Batch Name");  // Open handler - GrossAmountShowComputedWithhContribModalPageHandler

        // Exercise and Verify: Update Total Amount and verify Gross Amount on Page Handler - GrossAmountShowComputedWithhContribModalPageHandler
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorWithINPSAndGrossAmtSameAsTotalAmtPurchInvoice()
    var
        ContributionCodeLine: Record "Contribution Code Line";
        PurchaseLine: Record "Purchase Line";
        WithhTaxesContributionCard: TestPage "Withh. Taxes-Contribution Card";
    begin
        // Verify Gross Amount same as Total Amount on Withh. Taxes-Contribution Card after creating Purchase Invoice.

        // Setup: Create Contribution Code with Type INPS and Create Purchase Invoice.
        Initialize();
        CreateContributionCodeWithLine(ContributionCodeLine, ContributionCodeLine."Contribution Type"::INPS);
        CreatePurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::Invoice, CreateVendor(ContributionCodeLine.Code, ''), false);  // Blank for INAIL Code  and Prices Including VAT - FALSE.

        // Exercise: Calculate Withhold Taxes Contribution on Purchase Invoice Page.
        CalculateWithholdTaxesContributionOnPurchInvoice(WithhTaxesContributionCard, PurchaseLine."Document No.");

        // Verify: Verify Gross Amount same as Total amount on Page - Withh. Taxes-Contribution Card.
        WithhTaxesContributionCard."Gross Amount".AssertEquals(WithhTaxesContributionCard.TotalAmount.AsDecimal());
        WithhTaxesContributionCard.OK().Invoke();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorWithINPSAndTotalAmtPurchInvoice()
    var
        ContributionCodeLine: Record "Contribution Code Line";
        PurchaseLine: Record "Purchase Line";
        WithhTaxesContributionCard: TestPage "Withh. Taxes-Contribution Card";
    begin
        // Verify Gross Amount same as Total Amount after update Total Amount on Withh. Taxes-Contribution Card after creating Purchase Invoice.
        Initialize();
        CreateContributionCodeWithLine(ContributionCodeLine, ContributionCodeLine."Contribution Type"::INPS);
        CreatePurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::Invoice, CreateVendor(ContributionCodeLine.Code, ''), false);  // Blank for INAIL Code and Prices Including VAT - FALSE.
        CalculateWithholdTaxesContributionOnPurchInvoice(WithhTaxesContributionCard, PurchaseLine."Document No.");

        // Exercise: Update Total Amount.
        WithhTaxesContributionCard.TotalAmount.SetValue(LibraryRandom.RandDec(10, 2));

        // Verify: Verify Gross Amount same as Total amount on Page - Withh. Taxes-Contribution Card.
        WithhTaxesContributionCard."Gross Amount".AssertEquals(WithhTaxesContributionCard.TotalAmount.AsDecimal());
        WithhTaxesContributionCard.OK().Invoke();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentJnlWithoutShowComputedWithholdTaxesError()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseLine: Record "Purchase Line";
        PostedDocumentNo: Code[20];
    begin
        // Verify Error message on Posting of Payment Journal with apply Posted Purchase Invoice without Calculate Withhold Taxes Contribution.

        // Setup: Create and Post Purchase Invoice and create and apply General Journal line.
        Initialize();
        PostedDocumentNo := CreateAndPostPurchaseInvoice(PurchaseLine, '', '');  // Blank for Social Security Code and INAIL Code.
        UpdateBlankPaymentMethodCodeOnVendor(PurchaseLine."Buy-from Vendor No.");
        CreateAndApplyGeneralJnlLine(
          GenJournalLine, GenJournalLine."Document Type"::Payment, PostedDocumentNo, GenJournalLine."Applies-to Doc. Type"::Invoice);

        // Exercise.
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify error message - Because this invoice includes Withholding Tax, it should not be applied directly. Please use the function Payment Journals -> Payments -> Withh.Tax-Soc.Sec.
        Assert.ExpectedError(WithholdingTaxErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentJnlDocTypeCreditMemoAppliesToInvoice()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseLine: Record "Purchase Line";
        PostedDocumentNo: Code[20];
    begin
        // Verify no error message when posting a credit memo without withholding tax which is linked to an invoice with withholding tax and verify Amount in Vendor Ledger Entry.

        // Setup: Create and Post Purchase Invoice and Create Payment Journal with Document Type Credit Memo and apply to Posted Purchase Invoice.
        Initialize();
        PostedDocumentNo := CreateAndPostPurchaseInvoice(PurchaseLine, '', '');  // Blank for Social Security Code and INAIL Code.
        UpdateBlankPaymentMethodCodeOnVendor(PurchaseLine."Buy-from Vendor No.");
        CreateAndApplyGeneralJnlLine(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo", PostedDocumentNo, GenJournalLine."Applies-to Doc. Type"::Invoice);
        UpdateAmountOnGenJournalLine(GenJournalLine);

        // Exercise.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify.
        VerifyAmountInVendorLedgerEntry(
          GenJournalLine."Document Type"::"Credit Memo", PurchaseLine."Buy-from Vendor No.",
          GenJournalLine."Bal. Account Type", GenJournalLine."Bal. Account No.", GenJournalLine.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentJnlDocTypeCreditMemoWithholdTaxesError()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Verify error message "Document Type must be Payment or Refund type" pops up when running Withh. Tax-Soc.Sec. on Payment Journal.

        // Setup.
        Initialize();
        CreateGeneralJnlLine(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo", CreateVendor('', ''), LibraryRandom.RandDec(10, 2));  // Blank for Social Security Code and INAIL Code.

        // Exercise.
        asserterror ShowComputedWithholdContributionOnPayment(GenJournalLine."Journal Batch Name");

        // Verify: Verify error message - Because this invoice includes Withholding Tax, it should not be applied directly. Please use the function Payment Journals -> Payments -> Withh.Tax-Soc.Sec.
        Assert.ExpectedError(DocumentTypeErr);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorINAILWithholdTaxesContributionOnPurchaseInvoice()
    var
        Currency: Record Currency;
        ContributionCodeLine: Record "Contribution Code Line";
        PurchaseLine: Record "Purchase Line";
        WithhTaxesContributionCard: TestPage "Withh. Taxes-Contribution Card";
        INAILFreeLanceAmoeunt: Decimal;
        INAILTotalAmount: Decimal;
    begin
        // Verify INAIL Free-Lance Amount on Withh. Taxes-Contribution Card after creating Purchase Invoice.

        // Setup: Create Contribution code with Type as INAIL and create Purchase Invoice.
        Initialize();
        CreateContributionCodeWithLine(ContributionCodeLine, ContributionCodeLine."Contribution Type"::INAIL);
        CreatePurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::Invoice, CreateVendor('', ContributionCodeLine.Code), false);  // Blank for Social Security Code and Prices Including VAT - FALSE.
        INAILTotalAmount :=
          Round(PurchaseLine."Line Amount" * ContributionCodeLine."Social Security %" / 1000, Currency."Amount Rounding Precision");
        INAILFreeLanceAmoeunt :=
          Round(INAILTotalAmount * ContributionCodeLine."Free-Lance Amount %" / 100, Currency."Amount Rounding Precision");

        // Exercise.
        CalculateWithholdTaxesContributionOnPurchInvoice(WithhTaxesContributionCard, PurchaseLine."Document No.");

        // Verify: Verify INAIL detail on Page - Withhold Taxes Contribution Card.
        WithhTaxesContributionCard."INAIL Free-Lance %".AssertEquals(ContributionCodeLine."Free-Lance Amount %");
        WithhTaxesContributionCard."INAIL Total Amount".AssertEquals(INAILTotalAmount);
        WithhTaxesContributionCard."INAIL Free-Lance Amount".AssertEquals(INAILFreeLanceAmoeunt);
    end;

    [Test]
    [HandlerFunctions('ShowComputedWithholdContribModalPageHandler,CertificationsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CertificationsRefundPaymentJnlWithAppliesToCreditMemo()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseLine: Record "Purchase Line";
        PostedDocumentNo: Code[20];
        NonTaxableAmount: Decimal;
        TaxableBase: Decimal;
        WithholdingTaxAmount: Decimal;
    begin
        // Verify Tax value on Report Certifications after posting Payment Journal as Refund with apply Posted Purchase Credit Memo.

        // Setup: Create and Post Purchase Credit Memo and create General Journal line with refund and apply posted credit memo.
        Initialize();
        PostedDocumentNo := CreateAndPostPurchaseCreditMemo(PurchaseLine);
        WithholdingTaxAmount := CalculateWithholdTaxes(PurchaseLine."Buy-from Vendor No.", PurchaseLine."Line Amount", TaxableBase);
        NonTaxableAmount := PurchaseLine."Line Amount" - TaxableBase;
        CreateAndPostGeneralJnlLineWithAppliesToDoc(
          GenJournalLine."Document Type"::Refund, PostedDocumentNo, GenJournalLine."Applies-to Doc. Type"::"Credit Memo");

        // Exercise.
        RunCertificationsReport(PurchaseLine."Buy-from Vendor No.");

        // Verify: Verify Non Taxable Amount, Taxable Base, Withholding Tax Amount on generated XML file.
        VerifyTaxValueOnCertificationsReport(-NonTaxableAmount, -TaxableBase, -WithholdingTaxAmount);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ShowComputedWithholdContribModalPageHandler,CertificationsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CertificationsPaymentJnlWithAppliesToInvoice()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseLine: Record "Purchase Line";
        PostedDocumentNo: Code[20];
        NonTaxableAmount: Decimal;
        TaxableBase: Decimal;
        WithholdingTaxAmount: Decimal;
    begin
        // Verify Tax value on Report Certifications after posting Payment Journal with apply Posted Purchase Invoice.

        // Setup: Create and Post Purchase Invoice and create General Journal line with Payment and apply posted Invoice.
        Initialize();
        PostedDocumentNo := CreateAndPostPurchaseInvoice(PurchaseLine, '', '');  // Blank for Social Security Code and INAIL Code.
        WithholdingTaxAmount := CalculateWithholdTaxes(PurchaseLine."Buy-from Vendor No.", PurchaseLine."Line Amount", TaxableBase);
        NonTaxableAmount := PurchaseLine."Line Amount" - TaxableBase;
        CreateAndPostGeneralJnlLineWithAppliesToDoc(
          GenJournalLine."Document Type"::Payment, PostedDocumentNo, GenJournalLine."Applies-to Doc. Type"::Invoice);

        // Exercise.
        RunCertificationsReport(PurchaseLine."Buy-from Vendor No.");

        // Verify: Verify Non Taxable Amount, Taxable Base, Withholding Tax Amount on generated XML file.
        VerifyTaxValueOnCertificationsReport(NonTaxableAmount, TaxableBase, WithholdingTaxAmount);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ShowComputedWithholdContribModalPageHandler,WithholdingTaxesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure WithholdingTaxPaidAsFalseDeleteWithholdTaxPayment()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseLine: Record "Purchase Line";
        WithholdingTax: Record "Withholding Tax";
        WithholdingTaxPayment: Record "Withholding Tax Payment";
        Paid: Boolean;
        PostedDocumentNo: Code[20];
    begin
        // Verify Paid field on Withhold Tax when entry in the Withhold Tax Payment is deleted.

        // Setup: Delete Withholding Tax Payment, Create and Post Purchase Invoice, Create and Post Payment Journal and Run Withhold Taxes report.
        Initialize();
        WithholdingTaxPayment.DeleteAll();
        PostedDocumentNo := CreateAndPostPurchaseInvoice(PurchaseLine, '', '');  // Blank for Social Security Code and INAIL Code.
        CreateAndPostGeneralJnlLineWithAppliesToDoc(
          GenJournalLine."Document Type"::Payment, PostedDocumentNo, GenJournalLine."Applies-to Doc. Type"::Invoice);
        RunWithholdingTaxesReport(PurchaseLine."Buy-from Vendor No.");
        FindWithholdingTax(WithholdingTax, PurchaseLine."Buy-from Vendor No.");
        Paid := WithholdingTax.Paid;
        WithholdingTaxPayment.FindFirst();

        // Exercise.
        WithholdingTaxPayment.Delete(true);

        // Verify: Verify Paid Field on Withholding Tax as False after deleting Withholding Tax Payment entry.
        FindWithholdingTax(WithholdingTax, PurchaseLine."Buy-from Vendor No.");
        WithholdingTax.TestField(Paid, false);
        Assert.AreNotEqual(Paid, WithholdingTax.Paid, ValueMustBeSameMsg);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WithholdingTaxAmountOnSubformVendorBillLines()
    var
        Vendor: Record Vendor;
        ManualVendorPaymentLine: TestPage "Manual vendor Payment Line";
        AmountToPay: Decimal;
        WithholdingTaxAmount: Decimal;
    begin
        // Verify Withholding Tax Amount On Sub form Vendor Bill Lines after Insert Line from Manual Vendor Payment Line Page.

        // Setup: Set Total Amount and Tax Base Amount on Page - Manual Vendor Payment Line.
        Initialize();
        SetValuesOnManualVendorPaymentLinePage(ManualVendorPaymentLine);
        Vendor.Get(ManualVendorPaymentLine.VendorNo.Value);
        WithholdingTaxAmount :=
          CalculateWithholdingTaxAmount(Vendor."Withholding Tax Code", ManualVendorPaymentLine.TaxBaseAmount.AsDecimal());
        AmountToPay := ManualVendorPaymentLine.TotalAmount.AsDecimal() - WithholdingTaxAmount;

        // Exercise.
        ManualVendorPaymentLine.InsertLine.Invoke();

        // Verify: Verify Amount To Pay and Withholding Tax Amount on Subform Vendor Bill Lines.
        VerifyAmountToPayAndWithholdingTaxAmount(Vendor."No.", AmountToPay, WithholdingTaxAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceWithPricesIncludingVAT()
    var
        PurchaseLine: Record "Purchase Line";
        WithhTaxesContributionCard: TestPage "Withh. Taxes-Contribution Card";
        TaxableBase: Decimal;
        WithholdingTaxAmount: Decimal;
    begin
        // Verify Taxable Base and Withholding Tax Amount on Withh. Taxes-Contribution Card while purchase invoice having Prices Including VAT Boolean - TRUE.

        // Setup: Create Purchase Invoice with Calculating Withhold Taxes Contribution.
        Initialize();
        CreatePurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::Invoice, CreateVendor('', ''), true);  // Blank Social Security Code, INAIL Code and Prices Including VAT - TRUE.
        WithholdingTaxAmount :=
          CalculateWithholdTaxes(PurchaseLine."Buy-from Vendor No.", PurchaseLine."VAT Base Amount", TaxableBase);

        // Exercise.
        CalculateWithholdTaxesContributionOnPurchInvoice(WithhTaxesContributionCard, PurchaseLine."Document No.");

        // Verify: Verify Taxable Base and Withholding Tax Amount on Withh. Taxes-Contribution Card.
        WithhTaxesContributionCard."Taxable Base".AssertEquals(TaxableBase);
        WithhTaxesContributionCard."Withholding Tax Amount".AssertEquals(WithholdingTaxAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchaseInvoiceWithPricesIncludingVAT()
    var
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        WithhTaxesContributionCard: TestPage "Withh. Taxes-Contribution Card";
        PostedDocumentNo: Code[20];
    begin
        // Verify VAT Base Amount and VAT Amount on G/L Entry while purchase invoice having Prices Including VAT Boolean - TRUE.

        // Setup: Create Purchase Invoice with Calculating Withhold Taxes Contribution.
        Initialize();
        CreatePurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::Invoice, CreateVendor('', ''), true);  // Blank Social Security Code, INAIL Code and Prices Including VAT - TRUE.
        CalculateWithholdTaxesContributionOnPurchInvoice(WithhTaxesContributionCard, PurchaseLine."Document No.");
        VATPostingSetup.Get(PurchaseLine."VAT Bus. Posting Group", PurchaseLine."VAT Prod. Posting Group");

        // Exercise.
        PostedDocumentNo := PostPurchaseDocument(PurchaseLine."Document Type"::Invoice, PurchaseLine."Document No.");

        // Verify: Verify G/L Entry - VAT Base Amount and VAT Amount.
        VerifyGLEntryAmount(PostedDocumentNo, PurchaseLine."No.", PurchaseLine."VAT Base Amount");
        VerifyGLEntryAmount(
          PostedDocumentNo, VATPostingSetup."Purchase VAT Account", PurchaseLine."VAT Base Amount" / PurchaseLine."VAT %");
    end;

    [Test]
    [HandlerFunctions('ShowComputedWithholdContribModalPageHandler')]
    [Scope('OnPrem')]
    procedure PaymentJournalWithPricesIncludingVAT()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseLine: Record "Purchase Line";
        WithhTaxesContributionCard: TestPage "Withh. Taxes-Contribution Card";
        PostedDocumentNo: Code[20];
        TaxableBase: Decimal;
        WithholdingTaxAmount: Decimal;
    begin
        // Verify Withholding Tax Entry after Post payment journal applied to posted Purchase invoice while Prices Including VAT - TRUE.

        // Setup: Create Post Purchase Invoice with Calculating Withhold Taxes Contribution, Create Payment Journal and apply to posted Purchase Invoice.
        Initialize();
        CreatePurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::Invoice, CreateVendor('', ''), true);  // Blank Social Security Code, INAIL Code and Prices Including VAT - TRUE.
        WithholdingTaxAmount :=
          CalculateWithholdTaxes(PurchaseLine."Buy-from Vendor No.", PurchaseLine."VAT Base Amount", TaxableBase);
        CalculateWithholdTaxesContributionOnPurchInvoice(WithhTaxesContributionCard, PurchaseLine."Document No.");
        PostedDocumentNo := PostPurchaseDocument(PurchaseLine."Document Type"::Invoice, PurchaseLine."Document No.");
        CreateAndApplyGeneralJnlLine(
          GenJournalLine, GenJournalLine."Document Type"::Payment, PostedDocumentNo, GenJournalLine."Applies-to Doc. Type"::Invoice);
        ShowComputedWithholdContributionOnPayment(GenJournalLine."Journal Batch Name");

        // Exercise.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify Non Taxable Amount, Taxable Base, Withholding Tax Amount on Withholding Tax.
        VerifyWithholdingTax(PurchaseLine."Buy-from Vendor No.", PurchaseLine.Amount - TaxableBase, TaxableBase, WithholdingTaxAmount);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ShowComputedWithholdContribModalPageHandler')]
    [Scope('OnPrem')]
    procedure WithholdingTaxPaymentJnlUsingDifferentBalAccount()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseLine: Record "Purchase Line";
        PostedDocumentNo: Code[20];
        WithholdingTaxAmount: Decimal;
    begin
        // Verify posting Withholding Tax Payment Journal using different Bal. Account can succeed and verify the tax amount in Vendor Ledger Entry.

        // Setup: Create and Post Purchase Invoice with calculating Withholding Tax. Create and apply Payment journal to the Invoice.
        Initialize();
        PostedDocumentNo := PostPurchInvoiceWithCalcWithholdingTax(PurchaseLine, WithholdingTaxAmount);
        CreateAndApplyGeneralJnlLine(
          GenJournalLine, GenJournalLine."Document Type"::Payment, PostedDocumentNo, GenJournalLine."Applies-to Doc. Type"::Invoice);

        // Show Computed Withhold Taxes Contribution on Payment Journal Page.
        ShowComputedWithholdContributionOnPayment(GenJournalLine."Journal Batch Name");
        FindGenJournalLineForWithholdingTaxAndModifyBalAccNo(
          GenJournalLine, PurchaseLine."Buy-from Vendor No.", LibraryERM.CreateGLAccountNo());

        // Exercise: Post Gen. Jounal Line with updated Account No.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify Withholding Tax Amount in Vendor Ledger Entry.
        VerifyAmountInVendorLedgerEntry(
          GenJournalLine."Document Type"::Payment, PurchaseLine."Buy-from Vendor No.",
          GenJournalLine."Account Type"::"G/L Account", GenJournalLine."Bal. Account No.", WithholdingTaxAmount);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ShowComputedWithholdContribModalPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceWithhTaxWithNoTaxableBase()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseLine: Record "Purchase Line";
        WithholdingTax: Record "Withholding Tax";
        PostedDocumentNo: Code[20];
    begin
        // [SCENARIO 377969] Withholding Tax should be reported on Payment for Purchase Invoice even if no withholding tax amounts have been calculated
        Initialize();

        // [GIVEN] Posted Purchase Invoice of Amount = "A" with Withholding Tax where "Taxable Base" = 0
        PostedDocumentNo :=
          CreateAndPostPurchaseInvoiceWithZeroTaxableBase(PurchaseLine, '', '');

        // [GIVEN] Payment with Withhold Contribution where "Non Taxable Amount" = Invoice Amount = "A" applied to the Invoice
        CreateAndApplyGeneralJnlLine(
          GenJournalLine, GenJournalLine."Document Type"::Payment, PostedDocumentNo, GenJournalLine."Applies-to Doc. Type"::Invoice);
        ShowComputedWithholdContributionOnPayment(GenJournalLine."Journal Batch Name");

        // [WHEN] Post Payment journal line
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Withholding Tax is generated for the Payment with Non Taxable Amount = "A"
        WithholdingTax.SetRange("Document No.", GenJournalLine."Document No.");
        WithholdingTax.FindFirst();
        WithholdingTax.TestField("Non Taxable Amount", PurchaseLine.Amount);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ResidenceCountyOnVendorCard()
    var
        Vendor: Record Vendor;
        VendorCard: TestPage "Vendor Card";
    begin
        // [FEATURE] [UT] [Vendor]
        // [SCENARIO 376436] Field "Residence County" of Page "Vendor Card" should refer to field "Residence County" of Vendor Table
        Initialize();

        // [GIVEN] Vendor with "Residence County" = "X"
        Vendor.Init();
        Vendor."No." := LibraryUtility.GenerateGUID();
        Vendor."Residence County" := LibraryUtility.GenerateGUID();
        Vendor.Insert(true);

        // [WHEN] Open Vendor Card Page
        OpenVendorCard(VendorCard, Vendor."No.");

        // [THEN] Vendor Card has "Residence County" = "X"
        VendorCard."Residence County".AssertEquals(Vendor."Residence County");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateGrossAmountOnWithholdingContribution()
    var
        TmpWithholdingContribution: Record "Tmp Withholding Contribution";
        ContributionBracketLine: Record "Contribution Bracket Line";
        GrossAmount: Decimal;
        VendorNo: Code[20];
    begin
        // [FEATURE] [UT] [Social Security]
        // [SCENARIO 213698] Social Security fields are recalculated on validating Withholding Contribution's "Gross Amount" field in case of empty "INAIL Code"
        Initialize();

        // [GIVEN] Withholding Contribution with typed "Social Security Code" having:
        // [GIVEN] "INAIL Code" = "", "Social Security %" = 10, "Free-Lance %" = 33.33, ContributionBracketLine."Taxable Base %" = 5
        CreateVendorWithINPSContributionSetup(ContributionBracketLine, VendorNo, LibraryRandom.RandIntInRange(10, 20));
        InitTmpWithholdingContribution(TmpWithholdingContribution, VendorNo);

        // [WHEN] Validate "Gross Amount" = 1000
        GrossAmount := LibraryRandom.RandDecInRange(1000, 2000, 2);
        TmpWithholdingContribution.Validate("Gross Amount", GrossAmount);

        // [THEN] Withholding Contribution's Social Security group fields are recalculated:
        // [THEN] "Gross Amount" = 1000
        // [THEN] "Soc.Sec.Non Taxable Amount" = "Gross Amount" * (100 - "Taxable Base %") / 100 = 50
        // [THEN] "Contribution Base" = "Gross Amount" - "Soc.Sec.Non Taxable Amount" = 1000 - 50 = 950
        // [THEN] "Total Social Security Amount" = "Contribution Base" * "Social Security %" / 100 = 95
        // [THEN] "Free-Lance Amount" = "Total Social Security Amount" *  "Free-Lance %" / 100 = 31,66
        // [THEN] "Company Amount" = "Total Social Security Amount" - "Free-Lance Amount" = 63,34
        VerifyTmpWithholdingContribution_SocSecValues(
          TmpWithholdingContribution, GrossAmount, Round(GrossAmount * (100 - ContributionBracketLine."Taxable Base %") / 100));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateTotalAmountOnWithhContribAfterInvoiceAndZeroTaxableBasePct()
    var
        TmpWithholdingContribution: Record "Tmp Withholding Contribution";
        ContributionBracketLine: Record "Contribution Bracket Line";
        VendorNo: Code[20];
        GrossAmount: Decimal;
        InvoiceAmount: array[2] of Decimal;
        i: Integer;
    begin
        // [FEATURE] [Social Security]
        // [SCENARIO 214315] TAB 12112 "Computed Contribution"."Remaining Gross Amount" is considered when Social Security fields are recalculated
        Initialize();

        // [GIVEN] Vendor with "INPS" Social Security Withholding Contribution having following ContributionBracketLine setup:
        // [GIVEN] Line1: Amount = 6410, "Taxable Base %" = 0
        // [GIVEN] Line2: Amount = 10000, "Taxable Base %" = 100
        CreateVendorWithINPSContributionSetup(ContributionBracketLine, VendorNo, 0);
        AddContributionBracketLine(ContributionBracketLine, ContributionBracketLine.Amount * 10, 100);

        // [GIVEN] Two posted purchase invoices with "Posting Date" = 25-01-2019 and Amount = 2000
        for i := 1 to ArrayLen(InvoiceAmount) do begin
            InvoiceAmount[i] := LibraryRandom.RandDecInRange(1000, 2000, 2);
            CreatePostPurchaseInvoiceWithAmount(WorkDate(), VendorNo, InvoiceAmount[i]);
        end;
        // [GIVEN] Posted purchase invoices with "Posting Date" = 25-01-2020 and Amount = 2000
        CreatePostPurchaseInvoiceWithAmount(CalcDate('<1Y>', WorkDate()), VendorNo, LibraryRandom.RandDecInRange(1000, 2000, 2));

        // [GIVEN] Payment journal, "Posting Date" = 25-01-2019
        // [GIVEN] Open Vendor's Withholding Contribution from the payment journal
        InitTmpWithholdingContribution(TmpWithholdingContribution, VendorNo);

        // [WHEN] Validate "Total Amount" = 3000
        GrossAmount :=
          LibraryRandom.RandDecInRange(
            Round(ContributionBracketLine.Amount - InvoiceAmount[1] - InvoiceAmount[2], 1, '>'),
            Round(ContributionBracketLine.Amount, 1, '<'),
            2);
        TmpWithholdingContribution.Validate("Total Amount", GrossAmount);

        // [THEN] Withholding Contribution's Social Security group fields are recalculated:
        // [THEN] "Gross Amount" = 3000
        // [THEN] "Contribution Base" = 2000 + 2000 + 3000 - 6410 = 590
        // [THEN] "Soc.Sec.Non Taxable Amount" = 3000 - 590 = 2410
        VerifyTmpWithholdingContribution_SocSecValues(
          TmpWithholdingContribution, GrossAmount, ContributionBracketLine.Amount - InvoiceAmount[1] - InvoiceAmount[2]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateNonTaxableAmountOnPurchaseInvoicePostingWithSocSecBrackets()
    var
        ContributionBracketLine: Record "Contribution Bracket Line";
        PurchaseHeader: Record "Purchase Header";
        VendorNo: Code[20];
        InvoiceAmount: Decimal;
    begin
        // [FEATURE] [Social Security]
        // [SCENARIO 251046] TAB 12112 "Computed Contribution"."Remaining Gross Amount" is considered when Social Security on Purchase Invoice Page is recalculated.
        Initialize();

        // [GIVEN] Vendor with Social Security Contribution having Contribution Brackets.
        // [GIVEN] First Contribution Brackets Line with Amount = 6410 and "Taxable Base %" = 0.
        CreateVendorWithINPSContributionSetup(ContributionBracketLine, VendorNo, 0);

        // [GIVEN] Second Contribution Brackets Line with Amount = 64100 and "Taxable Base %" = 100.
        AddContributionBracketLine(ContributionBracketLine, ContributionBracketLine.Amount * 10, 100);

        // [GIVEN] Create and Post Purchase Invoice with Amount = 4000 < 6400.
        InvoiceAmount := LibraryRandom.RandDecInRange(0, ContributionBracketLine.Amount, 2);
        CreatePostPurchaseInvoiceWithAmount(WorkDate(), VendorNo, InvoiceAmount);

        // [WHEN] Create Purchase Invoice "PI" with Amount = 3000.
        CreatePurchaseInvoiceWithAmount(
          PurchaseHeader,
          WorkDate(),
          VendorNo,
          1,
          LibraryRandom.RandDecInRange(ContributionBracketLine.Amount, 10 * ContributionBracketLine.Amount, 2));

        // [THEN] Calculated Soc.Sec.Non Taxable Amount for "PI" is equal to 6400 - 4000 = 2400.
        VerifyPurchWithContribution(PurchaseHeader, InvoiceAmount, ContributionBracketLine.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestContributionRemainingGrossAmountCalculation()
    var
        WithholdingContribution: Codeunit "Withholding - Contribution";
        VendorNo: Code[20];
        RemainingGrossAmount: Decimal;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 251046] COD 12101 "Withholding - Contribution".GetCompContribRemGrossAmtForVendorInPeriod() returns remaining gross amount for the given vendor in specified period.
        VendorNo := LibraryPurchase.CreateVendorNo();
        RemainingGrossAmount := LibraryRandom.RandDecInRange(0, 10000, 2);

        // [GIVEN] Computed Contribution for Vendor "V1" with Posting Date = 28-11-2017 and Remaining Gross Amount = 100.
        CreateComputedContribution(VendorNo, WorkDate(), RemainingGrossAmount);

        // [GIVEN] Computed Contribution for Vendor "V1" with Posting Date = 28-11-2018 and Remaining Gross Amount = 100.
        CreateComputedContribution(VendorNo, CalcDate('<CY + 1D>', WorkDate()), RemainingGrossAmount);

        // [GIVEN] Computed Contribution for Vendor "V1" with Posting Date = 28-11-2016 and Remaining Gross Amount = 100.
        CreateComputedContribution(VendorNo, CalcDate('<-CY - 1D>', WorkDate()), RemainingGrossAmount);

        // [GIVEN] Computed Contribution for Vendor "V2" with Posting Date = 28-11-2017 and Remaining Gross Amount = 100.
        CreateComputedContribution(LibraryPurchase.CreateVendorNo(), WorkDate(), RemainingGrossAmount);

        // [WHEN] Run COD 12101 "Withholding - Contribution".GetCompContribRemGrossAmtForVendorInPeriod("V1",1-1-2017,31-12-2017).
        // [THEN] Calculated "Remaining Gross Amount" is equal to the 100.
        Assert.AreEqual(
          RemainingGrossAmount,
          WithholdingContribution.GetCompContribRemGrossAmtForVendorInPeriod(
            VendorNo,
            CalcDate('<-CY>', WorkDate()),
            CalcDate('<CY>', WorkDate())),
          RemainingGrossAmountErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchWithContributionIsCreatedOnInsertWhenVendorIsValidatedBeforeInsert()
    var
        PurchWithhContribution: Record "Purch. Withh. Contribution";
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        VendorNo: Code[20];
    begin
        // [SCENARIO 253610] When "Buy-from Vendor No." is validated and then Purchase Invoice is inserted, then Purch. With Contribution is created.
        Initialize();

        // [GIVEN] Vendor "V" with Withholding Tax Code = "T"
        VendorNo := CreateVendor('', '');

        // [GIVEN] Purchase Invoice with blank "No." and "Buy-from Vendor No." = "V"
        PurchaseHeader.Init();
        PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::Invoice;
        PurchaseHeader.Validate("Buy-from Vendor No.", VendorNo);

        // [WHEN] Insert record with assigned "No." = "1000"
        PurchaseHeader.Insert(true);

        // [THEN] Purch. With Contribution is created with "No." = "1000", "Document Type" = Invoice and "Withholding Tax Code" = "T"
        PurchWithhContribution.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        Vendor.Get(VendorNo);
        PurchWithhContribution.TestField("Withholding Tax Code", Vendor."Withholding Tax Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchWithContributionIsCreatedWhenVendorIsValidatedAfterInsert()
    var
        PurchWithhContribution: Record "Purch. Withh. Contribution";
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        VendorNo: Code[20];
    begin
        // [SCENARIO 253610] When "Buy-from Vendor No." is validated after Purchase Invoice is inserted, then Purch. With Contribution is created.
        Initialize();

        // [GIVEN] Vendor "V" with Withholding Tax Code = "T"
        VendorNo := CreateVendor('', '');

        // [GIVEN] Purchase Invoice is inserted with "No." = 1000
        PurchaseHeader.Init();
        PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::Invoice;
        PurchaseHeader.Insert(true);

        // [WHEN] Validate "Buy-from Vendor No." = "V"
        PurchaseHeader.Validate("Buy-from Vendor No.", VendorNo);

        // [THEN] Purch. With Contribution is created with "No." = "1000", "Document Type" = Invoice and "Withholding Tax Code" = "T"
        PurchWithhContribution.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        Vendor.Get(VendorNo);
        PurchWithhContribution.TestField("Withholding Tax Code", Vendor."Withholding Tax Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchWithContributionIsModifiedWhenChangeDocumentDate()
    var
        PurchWithhContribution: Record "Purch. Withh. Contribution";
        PurchaseHeader: Record "Purchase Header";
    begin
        // [SCENARIO 253610] When modify "Document Date" in Purchase Invoice, then Purch. With Contribution "Date Related" equals to "Document Date" from Purchase Invoice.
        Initialize();

        // [GIVEN] Purchase Invoice with "Document Date" = 1/24/2019 and "Pay-to Vendor No." = Vendor with Withholding Tax Code
        PurchaseHeader.Init();
        PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::Invoice;
        PurchaseHeader.Validate("Pay-to Vendor No.", CreateVendor('', ''));
        PurchaseHeader.Insert(true);

        // [WHEN] Validate "Document Date" = 1/25/2019 in Purchase Invoice
        PurchaseHeader.Validate("Posting Date", LibraryRandom.RandDate(3));
        PurchaseHeader.Validate("Document Date", PurchaseHeader."Posting Date");

        // [THEN] Purch. With Contribution "Date Related" = 1/25/2019
        PurchWithhContribution.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        PurchWithhContribution.TestField("Date Related", PurchaseHeader."Document Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchWithContributionWithBlankNoIsNotCreated()
    var
        PurchWithhContribution: Record "Purch. Withh. Contribution";
        PurchaseHeader: Record "Purchase Header";
    begin
        // [SCENARIO 253610] When Validate Vendor with non-blank Withholding Tax Code for Purchase Invoice with blank "No.", then Purch. With Contribution is not created.
        Initialize();

        // [GIVEN] Purchase Invoice with blank "No."
        PurchaseHeader.Init();
        PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::Invoice;

        // [WHEN] Validate "Pay-to Vendor No." = Vendor with Withholding Tax Code
        PurchaseHeader.Validate("Pay-to Vendor No.", CreateVendor('', ''));

        // [THEN] Purch. With Contribution with blank "No." and "Document Type" = Invoice does not exist
        PurchWithhContribution.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchWithhContribution.SetRange("No.", PurchaseHeader."No.");
        Assert.RecordIsEmpty(PurchWithhContribution);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchWithContributionIsDeletedOnDeleteOfPurchaseInvoice()
    var
        PurchWithhContribution: Record "Purch. Withh. Contribution";
        PurchaseHeader: Record "Purchase Header";
    begin
        // [SCENARIO 253610] When Purchase Invoice is deleted, then associated Purch. With Contribution is deleted as well.
        Initialize();

        // [GIVEN] Purchase Invoice for Vendor with Withholding Tax Code
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, CreateVendor('', ''));

        // [GIVEN] Purch. With Contribution is created for Purchase Invoice
        PurchWithhContribution.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchWithhContribution.SetRange("No.", PurchaseHeader."No.");
        Assert.RecordCount(PurchWithhContribution, 1);

        // [WHEN] Delete Purchase Invoice
        PurchaseHeader.Delete(true);

        // [THEN] Purch. With Contribution is deleted
        Assert.RecordIsEmpty(PurchWithhContribution);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WithholdingTaxHasReasonCodeK()
    var
        WithholdingTax: Record "Withholding Tax";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 259516] Withholding tax has reason code "K"

        Initialize();
        VerifyOptionInOptionString(DATABASE::"Withholding Tax", WithholdingTax.FieldNo(Reason), 'K');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TempWithholdingContributionHasReasonCodeK()
    var
        TmpWithholdingContribution: Record "Tmp Withholding Contribution";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 259516] Tmp Withholding Contribution has reason code "K"

        Initialize();
        VerifyOptionInOptionString(DATABASE::"Tmp Withholding Contribution", TmpWithholdingContribution.FieldNo(Reason), 'K');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WHTAmountManualOnPageWithhTaxesContributionCard()
    var
        WithhTaxesContributionCard: TestPage "Withh. Taxes-Contribution Card";
    begin
        // [FEATURE] [UT] [UI] [WHT Amount Manual] [Withh. Taxes-Contribution Card]
        // [SCENARIO 266126] "WHT Amount Manual" is enabled, visible and editable on page "Withh. Taxes-Contribution Card"
        WithhTaxesContributionCard.OpenEdit();
        Assert.IsTrue(WithhTaxesContributionCard."WHT Amount Manual".Visible(), '');
        Assert.IsTrue(WithhTaxesContributionCard."WHT Amount Manual".Enabled(), '');
        Assert.IsTrue(WithhTaxesContributionCard."WHT Amount Manual".Editable(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WHTAmountManualWhenNotEqualToNonBlankWithholdingTaxAmount()
    var
        PurchWithhContribution: Record "Purch. Withh. Contribution";
        PurchaseHeader: Record "Purchase Header";
        WHTAmountManual: Decimal;
    begin
        // [FEATURE] [UT] [WHT Amount Manual] [Purch. Withh. Contribution]
        // [SCENARIO 266126] When validate "WHT Amount Manual" = "X" <> "Withholding Tax Amount" and "Withholding Tax Amount" <> 0 then "WHT Amount Manual" = "X" in Purch. Withh. Contribution
        Initialize();

        LibraryPurchase.CreatePurchaseInvoiceForVendorNo(PurchaseHeader, LibraryPurchase.CreateVendorNo());
        PurchWithhContribution.Init();
        PurchWithhContribution."Document Type" := PurchaseHeader."Document Type".AsInteger();
        PurchWithhContribution."No." := PurchaseHeader."No.";

        PurchWithhContribution.Validate("Withholding Tax Amount", LibraryRandom.RandDecInRange(10, 20, 2));
        WHTAmountManual := PurchWithhContribution."Withholding Tax Amount" / 2;
        PurchWithhContribution.Validate("WHT Amount Manual", WHTAmountManual);
        PurchWithhContribution.TestField("WHT Amount Manual", WHTAmountManual);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WHTAmountManualWhenEqualToWithholdingTaxAmountErr()
    var
        PurchWithhContribution: Record "Purch. Withh. Contribution";
    begin
        // [FEATURE] [UT] [WHT Amount Manual] [Purch. Withh. Contribution]
        // [SCENARIO 266126] When validate "WHT Amount Manual" = "Withholding Tax Amount" <> 0 then error is displayed 'WHT Amount Manual must not be equal to Withholding Tax Amount in Purch. Withh. Contribution.'
        Initialize();

        PurchWithhContribution.Init();
        PurchWithhContribution.Validate("Withholding Tax Amount", LibraryRandom.RandDecInRange(10, 20, 2));
        asserterror PurchWithhContribution.Validate("WHT Amount Manual", PurchWithhContribution."Withholding Tax Amount");
        Assert.ExpectedError(
          StrSubstNo(
            WHTAmtManualEqWHTAmtErr, PurchWithhContribution.FieldCaption("WHT Amount Manual"),
            PurchWithhContribution.FieldCaption("Withholding Tax Amount"), PurchWithhContribution.TableCaption()));
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WHTAmountManualWhenWithholdingTaxAmountIsZeroErr()
    var
        PurchWithhContribution: Record "Purch. Withh. Contribution";
    begin
        // [FEATURE] [UT] [WHT Amount Manual] [Purch. Withh. Contribution]
        // [SCENARIO 266126] When "Withholding Tax Amount" = 0 and "WHT Amount Manual" is validated then error is displayed 'Withholding Tax Amount must have a value in Purch. Withh. Contribution...'
        Initialize();

        PurchWithhContribution.Init();
        asserterror PurchWithhContribution.Validate("WHT Amount Manual");
        Assert.ExpectedError(
          StrSubstNo(
            WHTAmtZeroTestFieldErr, PurchWithhContribution.FieldCaption("Withholding Tax Amount"), PurchWithhContribution.TableCaption()));
        Assert.ExpectedErrorCode(TestFieldErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WHTAmountManualInCompWithhTaxWhenPostInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        ComputedWithholdingTax: Record "Computed Withholding Tax";
        PostedDocNo: Code[20];
        WHTAmountManual: Decimal;
    begin
        // [FEATURE] [WHT Amount Manual] [Computed Withholding Tax]
        // [SCENARIO 266126] When Purchase Invoice is posted with "WHT Amount Manual" = "X" then Computed Withholding Tax has "WHT Amount Manual" = "X"
        Initialize();

        // [GIVEN] Purchase Invoice with Amount = 1000.0 for Vendor, having Withholding Tax = 10%
        CreatePurchaseInvoiceWithAmount(
          PurchaseHeader, WorkDate(), CreateVendor('', ''), LibraryRandom.RandInt(10), LibraryRandom.RandDecInRange(1000, 2000, 2));

        // [GIVEN] Purch. Withh. Contribution with "WHT Amount Manual" = 100.01
        WHTAmountManual := ModifyWHTAmountManualForPurchWithhContribution(PurchaseHeader."Document Type", PurchaseHeader."No.");

        // [WHEN] Purchase Invoice is posted
        PostedDocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Computed Withholding Tax has "WHT Amount Manual" = 100.01
        ComputedWithholdingTax.Get(PurchaseHeader."Buy-from Vendor No.", PurchaseHeader."Posting Date", PostedDocNo);
        Assert.AreEqual(WHTAmountManual, ComputedWithholdingTax."WHT Amount Manual", '');
    end;

    [Test]
    [HandlerFunctions('ShowComputedWithholdContribModalPageHandler')]
    [Scope('OnPrem')]
    procedure WithhTaxAmtInTmpWithholdingContributionWhenWHTAmountManualNonBlank()
    var
        PurchaseHeader: Record "Purchase Header";
        GenJournalLine: Record "Gen. Journal Line";
        TmpWithholdingContribution: Record "Tmp Withholding Contribution";
        WithholdingContribution: Codeunit "Withholding - Contribution";
        PostedDocNo: Code[20];
        WHTAmountManual: Decimal;
    begin
        // [FEATURE] [Withholding Tax Amount] [Tmp Withholding Contribution] [WHT Amount Manual]
        // [SCENARIO 266126] When Purchase Invoice is posted with "WHT Amount Manual" = "X" <> 0 and Tmp Withholding Contribution is created for Payment Journal Line
        // [SCENARIO 266126] Then Tmp Withholding Contribution has "Withholding Tax Amount" = "X"
        Initialize();

        // [GIVEN] Purchase Invoice with Amount = 1000.0 for Vendor, having Withholding Tax = 10%
        CreatePurchaseInvoiceWithAmount(
          PurchaseHeader, WorkDate(), CreateVendor('', ''), LibraryRandom.RandInt(10), LibraryRandom.RandDecInRange(1000, 2000, 2));

        // [GIVEN] Purch. Withh. Contribution with "WHT Amount Manual" = 100.01
        WHTAmountManual := ModifyWHTAmountManualForPurchWithhContribution(PurchaseHeader."Document Type", PurchaseHeader."No.");

        // [GIVEN] Posted Purchase Invoice with "No." = "I"
        PostedDocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Payment Journal Line with "Applies-To Doc. No." = "I"
        CreateAndApplyGeneralJnlLine(
          GenJournalLine, GenJournalLine."Document Type"::Payment, PostedDocNo, GenJournalLine."Applies-to Doc. Type"::Invoice);

        // [WHEN] Create Tmp Withholding Contribution for Payment Journal Line
        WithholdingContribution.CreateTmpWithhSocSec(GenJournalLine);

        // [THEN] Tmp Withholding Contribution has "Withholding Tax Amount" = 100.01
        TmpWithholdingContribution.Get(
          GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", GenJournalLine."Line No.");
        Assert.AreEqual(WHTAmountManual, TmpWithholdingContribution."Withholding Tax Amount", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorBillLineAmtToPayWhenSocSecNonTaxableNotChanged()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchWithhContribution: Record "Purch. Withh. Contribution";
        VendorBillHeader: Record "Vendor Bill Header";
        WithholdCode: Code[20];
        ContributionCode: Code[20];
    begin
        // [FEATURE] [Suggest Vendor Bills] [Purch. Withh. Contribution]
        // [SCENARIO 283001] Suggested Vendor Bill Line has proper Amounts in case Soc. Sec. Non Taxable Amount was not changed in Purch. Withh Contribution
        Initialize();

        // [GIVEN] Withholding Tax and Social Security were set up as follows:
        // [GIVEN] Contribution Bracket with Taxable Base = 80 %
        // [GIVEN] Contribution Code with Social Security 16 % and Free-Lance Amount 40 %
        // [GIVEN] Withhold Code with Taxable Base 50 % and Withholding Tax 23 %
        SetupWithhAndSocSec(ContributionCode, WithholdCode);

        // [GIVEN] Vendor Bill Header with Payment Method Code
        CreateVendorBillHeaderWithPaymentMethod(VendorBillHeader, CreatePaymentMethodWithBill());

        // [GIVEN] Purchase Invoice with same Payment Method Code, Amount 10000.0 and VAT 10 % (Amount Including VAT = 11000.0)
        CreatePurchaseInvoiceWithWithholdSetupAndPmtMethod(
          PurchaseHeader, WithholdCode, ContributionCode, VendorBillHeader."Payment Method Code");

        // [GIVEN] Purch. Withh Contribution had Withholding Tax Amount = 10000.0 * 50 % * 23 % = 1150.0
        // [GIVEN] Purch. Withh Contribution had Total Social Security Amount = 10000.0 * 80 % * 16 % = 1280.0
        // [GIVEN] Purch. Withh Contribution had Free-Lance Amount = 10000.0 * 80 % * 16 % * 40 % = 512.0
        PurchWithhContribution.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");

        // [GIVEN] Purchase Invoice was posted
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] Run report "Suggest Vendor Bills"
        RunSuggestVendorBillsForVendorNo(VendorBillHeader, PurchaseHeader."Buy-from Vendor No.");

        // [THEN] Vendor Bill Line is created with Amount to Pay = 11000.0 - 1150.0 - 640.0 = 9338.0
        // [THEN] Social Security Amount = 10000.0 * 80 % * 16 % = 1280.0 in Vendor Bill Line
        VerifyVendorBillLineAmtToPayAndSocSecAmt(PurchWithhContribution, VendorBillHeader."No.", PurchaseHeader."Amount Including VAT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorBillLineAmtToPayWhenSocSecNonTaxableChanged()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchWithhContribution: Record "Purch. Withh. Contribution";
        VendorBillHeader: Record "Vendor Bill Header";
        WithholdCode: Code[20];
        ContributionCode: Code[20];
    begin
        // [FEATURE] [Suggest Vendor Bills] [Purch. Withh. Contribution]
        // [SCENARIO 283001] Suggested Vendor Bill Line has proper Amounts in case Soc. Sec. Non Taxable Amount was changed in Purch. Withh Contribution
        Initialize();

        // [GIVEN] Withholding Tax and Social Security were set up as follows:
        // [GIVEN] Contribution Bracket with Taxable Base = 80 %
        // [GIVEN] Contribution Code with Social Security 16 % and Free-Lance Amount 40 %
        // [GIVEN] Withhold Code with Taxable Base 50 % and Withholding Tax 23 %
        SetupWithhAndSocSec(ContributionCode, WithholdCode);

        // [GIVEN] Vendor Bill Header with Payment Method Code
        CreateVendorBillHeaderWithPaymentMethod(VendorBillHeader, CreatePaymentMethodWithBill());

        // [GIVEN] Purchase Invoice with same Payment Method Code, Amount 10000.0 and VAT 10 % (Amount Including VAT = 11000.0)
        CreatePurchaseInvoiceWithWithholdSetupAndPmtMethod(
          PurchaseHeader, WithholdCode, ContributionCode, VendorBillHeader."Payment Method Code");

        // [GIVEN] Purch. Withh Contribution had Withholding Tax Amount = 10000.0 * 50 % * 23 % = 1150.0
        // [GIVEN] Purch. Withh Contribution had Total Social Security Amount = 10000.0 * 80 % * 16 % = 1280.0
        // [GIVEN] Purch. Withh Contribution had Free-Lance Amount = 10000.0 * 80 % * 16 % * 40 % = 512.0
        PurchWithhContribution.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");

        // [GIVEN] Modified Soc. Sec. Non Taxable Amount = 6000.0 in Purch. Withh Contribution (Free-Lance Amount was changed to 256.0 and Total Social Security Amount was changed to 640.0)
        PurchWithhContribution.Validate("Soc.Sec.Non Taxable Amount", PurchWithhContribution."Contribution Base");
        PurchWithhContribution.Modify(true);

        // [GIVEN] Purchase Invoice was posted
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] Run report "Suggest Vendor Bills"
        RunSuggestVendorBillsForVendorNo(VendorBillHeader, PurchaseHeader."Buy-from Vendor No.");

        // [THEN] Vendor Bill Line is created with Amount to Pay = 11000.0 - 1150.0 - 256.0 = 9594.0
        // [THEN] Social Security Amount = (10000.0 - 6000.0) * 16 % = 640.0 in Vendor Bill Line
        VerifyVendorBillLineAmtToPayAndSocSecAmt(PurchWithhContribution, VendorBillHeader."No.", PurchaseHeader."Amount Including VAT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorBillWithholdingTaxPageHasFieldReason()
    var
        VendorBillWithhTax: TestPage "Vendor Bill Withh. Tax";
    begin
        // [SCENARIO 327634] A "Vendor Bill Withh. Tax" page has the "Reason" field

        Initialize();
        LibraryApplicationArea.EnableBasicSetup();
        VendorBillWithhTax.OpenView();
        Assert.IsTrue(VendorBillWithhTax.Reason.Visible(), 'A reason field is not visible');
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [HandlerFunctions('ShowComputedWithholdContribModalPageHandler')]
    [Scope('OnPrem')]
    procedure WithholdingTaxPaymentJnlWithAppliesToInvoiceZeroWHT()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseHeader: Record "Purchase Header";
        PostedDocumentNo: Code[20];
        WithholdCode: Code[20];
        ContributionCode: Code[20];
    begin
        // [SCENARIO 347071] Withholding tax line appears with amount 0 for payment journal if amount of WHT on Invoice was 0
        Initialize();

        // [GIVEN] SocSec and WHT setup for 0% WHT
        SetupWithhAndSocSec(ContributionCode, WithholdCode);
        WithholdCode := CreateWithholdCodeWithLineAndRates(100, 0);

        // [GIVEN] Purchase invoce was posted
        CreatePurchaseInvoiceWithWithholdSetupAndPmtMethod(PurchaseHeader, WithholdCode, ContributionCode, '');
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Create Payment Journal line with applies to Posted Invoice.
        CreateAndApplyGeneralJnlLine(
          GenJournalLine, GenJournalLine."Document Type"::Payment, PostedDocumentNo, GenJournalLine."Applies-to Doc. Type"::Invoice);

        // [WHEN] Open SocSec Calculate and pressing OK
        ShowComputedWithholdContributionOnPayment(GenJournalLine."Journal Batch Name");

        // [THEN] General Journal Line for Withholding Tax with amount 0 exists.
        VerifyGenJournalLineWithoutWHTAmount(GenJournalLine);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorBillLineAmtToPayWhenSocSecAndManualWHTAmount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchWithhContribution: Record "Purch. Withh. Contribution";
        VendorBillHeader: Record "Vendor Bill Header";
        WithholdCode: Code[20];
        ContributionCode: Code[20];
    begin
        // [FEATURE] [Suggest Vendor Bills] [Purch. Withh. Contribution]
        // [SCENARIO 345618] Suggested Vendor Bill Line has proper Amounts in case Withholding Tax Amount was changed in Purch. Withh Contribution manually
        Initialize();

        // [GIVEN] Withholding Tax and Social Security were set up as follows:
        // [GIVEN] Contribution Bracket with Taxable Base = 80 %
        // [GIVEN] Contribution Code with Social Security 16 % and Free-Lance Amount 40 %
        // [GIVEN] Withhold Code with Taxable Base 50 % and Withholding Tax 23 %
        SetupWithhAndSocSec(ContributionCode, WithholdCode);

        // [GIVEN] Vendor Bill Header with Payment Method Code
        CreateVendorBillHeaderWithPaymentMethod(VendorBillHeader, CreatePaymentMethodWithBill());

        // [GIVEN] Purchase Invoice with same Payment Method Code, Amount 10000.0 and VAT 10 % (Amount Including VAT = 11000.0)
        CreatePurchaseInvoiceWithWithholdSetupAndPmtMethod(
          PurchaseHeader, WithholdCode, ContributionCode, VendorBillHeader."Payment Method Code");

        // [GIVEN] Purch. Withh Contribution had Withholding Tax Amount = 10000.0 * 50 % * 23 % = 1150.0
        // [GIVEN] Purch. Withh Contribution had Total Social Security Amount = 10000.0 * 80 % * 16 % = 1280.0
        // [GIVEN] Purch. Withh Contribution had Free-Lance Amount = 10000.0 * 80 % * 16 % * 40 % = 512.0
        // [GIVEN] Purch. Withh Contribution had Withholding Tax Amount (Manual) = 1149 (decreased by 1 from calculated WHT Amount)
        PurchWithhContribution.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");

        // [GIVEN] Modified Soc. Sec. Non Taxable Amount = 6000.0 in Purch. Withh Contribution (Free-Lance Amount was changed to 256.0 and Total Social Security Amount was changed to 640.0)
        PurchWithhContribution.Validate("Soc.Sec.Non Taxable Amount", PurchWithhContribution."Contribution Base");
        PurchWithhContribution.TestField("Withholding Tax Amount");
        PurchWithhContribution.Validate("WHT Amount Manual", Round(PurchWithhContribution."Withholding Tax Amount" * 0.99));
        PurchWithhContribution.Modify(true);

        // [GIVEN] Purchase Invoice was posted
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] Run report "Suggest Vendor Bills"
        RunSuggestVendorBillsForVendorNo(VendorBillHeader, PurchaseHeader."Buy-from Vendor No.");

        // [THEN] Vendor Bill Line is created with Amount to Pay = 11000.0 - 1149.0 - 256.0 = 9595.0
        // [THEN] Social Security Amount = (10000.0 - 6000.0) * 16 % = 640.0 in Vendor Bill Line
        VerifyVendorBillLineAmtToPayAndSocSecAmtWhtManual(
          PurchWithhContribution, VendorBillHeader."No.", PurchaseHeader."Amount Including VAT");
    end;

    [Test]
    [HandlerFunctions('ShowValidateWHTSocSecMPH')]
    procedure ExternalDocNo_ApplyInvoiceToPaymentWithBlankedValue()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        ContributionCode: Code[20];
        WithholdCode: Code[20];
        VendorNo: Code[20];
        PaymentNo: Code[20];
        InvoiceNo: Code[20];
        Amount: Decimal;
    begin
        // [SCENARIO 361963] External Document No. is updated on Withholding Tax and Contribution (Social Security) records
        // [SCENARIO 361963] in case of Invoice to Payment application where payment had an empty external doc. no. value
        Initialize();

        // [GIVEN] Vendor with Withholding Tax and Social Security setup
        SetupWithhAndSocSec(ContributionCode, WithholdCode);
        VendorNo := CreateVendorWithSocSecAndWithholdCodes(WithholdCode, ContributionCode, '');
        Amount := LibraryRandom.RandDec(1000, 2);

        // [GIVEN] Posted payment with a blanked External Document No. value
        PaymentNo := CreatePostVendorPaymentWithExternalDocNo(VendorNo, Amount, '');

        // [GIVEN] Posted invoice with External Document No. = "X"
        InvoiceNo := CreatePostPurchaseInvoiceWithAmount(WorkDate(), VendorNo, Amount);
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, InvoiceNo);
        VendorLedgerEntry.TestField("External Document No.");

        // [WHEN] Apply Invoice to Payment vendor ledger entry
        LibraryERM.ApplyVendorLedgerEntries(
          VendorLedgerEntry."Document Type"::Invoice, VendorLedgerEntry."Document Type"::Payment, InvoiceNo, PaymentNo);

        // [THEN] Withh.Tax and Social Sec. records are updated with External Document No. = "X"
        VerifyWithhTaxAndContribExternalDocNo(VendorNo, VendorLedgerEntry."External Document No.");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ShowValidateWHTSocSecMPH')]
    procedure ExternalDocNo_ApplyInvoiceToPaymentWithNotBlankedValue()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        ContributionCode: Code[20];
        WithholdCode: Code[20];
        VendorNo: Code[20];
        PaymentNo: Code[20];
        InvoiceNo: Code[20];
        Amount: Decimal;
    begin
        // [SCENARIO 361963] External Document No. is not updated on Withholding Tax and Contribution (Social Security) records
        // [SCENARIO 361963] in case of Invoice to Payment application where payment had external doc. no. value
        Initialize();

        // [GIVEN] Vendor with Withholding Tax and Social Security setup
        SetupWithhAndSocSec(ContributionCode, WithholdCode);
        VendorNo := CreateVendorWithSocSecAndWithholdCodes(WithholdCode, ContributionCode, '');
        Amount := LibraryRandom.RandDec(1000, 2);

        // [GIVEN] Posted payment with External Document No. = "X"
        PaymentNo := CreatePostVendorPaymentWithExternalDocNo(VendorNo, Amount, LibraryUtility.GenerateGUID());

        // [GIVEN] Posted invoice with External Document No. = "Y"
        InvoiceNo := CreatePostPurchaseInvoiceWithAmount(WorkDate(), VendorNo, Amount);
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, InvoiceNo);
        VendorLedgerEntry.TestField("External Document No.");

        // [WHEN] Apply Invoice to Payment vendor ledger entry
        LibraryERM.ApplyVendorLedgerEntries(
          VendorLedgerEntry."Document Type"::Invoice, VendorLedgerEntry."Document Type"::Payment, InvoiceNo, PaymentNo);

        // [THEN] Withh.Tax and Social Sec. records are remain with blanked External Document No.
        VerifyWithhTaxAndContribExternalDocNo(VendorNo, '');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ShowValidateWHTSocSecMPH')]
    procedure ExternalDocNo_ApplyInvoiceToPaymentWithBlankedButWithhValue()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        WithholdingTax: Record "Withholding Tax";
        Contributions: Record Contributions;
        ContributionCode: Code[20];
        WithholdCode: Code[20];
        VendorNo: Code[20];
        PaymentNo: Code[20];
        InvoiceNo: Code[20];
        Amount: Decimal;
        ExternalDocNo: Code[35];
    begin
        // [SCENARIO 361963] External Document No. remains with its value on Withholding Tax and Contribution (Social Security) records
        // [SCENARIO 361963] in case of Invoice to Payment application where payment had an empty external doc. no. value,
        // [SCENARIO 361963] but withholding tax and social security had external document no. value
        Initialize();

        // [GIVEN] Vendor with Withholding Tax and Social Security setup
        SetupWithhAndSocSec(ContributionCode, WithholdCode);
        VendorNo := CreateVendorWithSocSecAndWithholdCodes(WithholdCode, ContributionCode, '');
        Amount := LibraryRandom.RandDec(1000, 2);

        // [GIVEN] Posted payment with a blanked External Document No. value
        PaymentNo := CreatePostVendorPaymentWithExternalDocNo(VendorNo, Amount, LibraryUtility.GenerateGUID());

        // [GIVEN] Posted invoice with External Document No. = "X"
        InvoiceNo := CreatePostPurchaseInvoiceWithAmount(WorkDate(), VendorNo, Amount);
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, InvoiceNo);
        VendorLedgerEntry.TestField("External Document No.");

        // [GIVEN] Assign withholding tax and social security records External Document No. = "Y"
        ExternalDocNo := LibraryUtility.GenerateGUID();
        FindWithholdingTax(WithholdingTax, VendorNo);
        WithholdingTax."External Document No." := ExternalDocNo;
        WithholdingTax.Modify();
        FindContributions(Contributions, VendorNo);
        Contributions."External Document No." := ExternalDocNo;
        Contributions.Modify();

        // [WHEN] Apply Invoice to Payment vendor ledger entry
        LibraryERM.ApplyVendorLedgerEntries(
          VendorLedgerEntry."Document Type"::Invoice, VendorLedgerEntry."Document Type"::Payment, InvoiceNo, PaymentNo);

        // [THEN] Withh.Tax and Social Sec. records are remain with External Document No. = "Y"
        VerifyWithhTaxAndContribExternalDocNo(VendorNo, ExternalDocNo);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure TmpWithholdingContributionClearLineNosUT_Withholding()
    var
        TmpWithholdingContribution: Record "Tmp Withholding Contribution";
        GenJournalLine: array[2] of Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 369203] When deleting Gen. Journal Line that is related to Withholding contribution via "Payment Line-Withholding" field, it is cleared
        Initialize();

        // [GIVEN] A journal batch
        CreateGenJournalBatch(GenJournalBatch);

        // [GIVEN] Create 2 General Journal Lines
        CreatePaymentLineForBatch(GenJournalLine[1], GenJournalBatch);
        CreatePaymentLineForBatch(GenJournalLine[2], GenJournalBatch);

        // [GIVEN] Mock a Tmp Withholding Contribution with Line No. = first line's no and "Payment Line-Withholding" = second line's Line No.
        MockTmpWithholdingContribution(TmpWithholdingContribution, GenJournalLine[1]);
        TmpWithholdingContribution.Validate("Payment Line-Withholding", GenJournalLine[2]."Line No.");
        TmpWithholdingContribution.Modify(true);

        // [WHEN] Delete second Gen Journal Line
        GenJournalLine[2].Delete(true);

        // [THEN] "Payment Line-Withholding" is empty
        TmpWithholdingContribution.Find();
        TmpWithholdingContribution.TestField("Payment Line-Withholding", 0);
    end;

    [Test]
    procedure TmpWithholdingContributionClearLineNosUT_SocSec()
    var
        TmpWithholdingContribution: Record "Tmp Withholding Contribution";
        GenJournalLine: array[2] of Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 369203] When deleting Gen. Journal Line that is related to Withholding contribution via "Payment Line-Soc. Sec." field, it is cleared
        Initialize();

        // [GIVEN] A journal batch
        CreateGenJournalBatch(GenJournalBatch);

        // [GIVEN] Create 2 General Journal Lines
        CreatePaymentLineForBatch(GenJournalLine[1], GenJournalBatch);
        CreatePaymentLineForBatch(GenJournalLine[2], GenJournalBatch);

        // [GIVEN] Mock a Tmp Withholding Contribution with Line No. = first line's no and "Payment Line-Soc. Sec." = second line's Line No.
        MockTmpWithholdingContribution(TmpWithholdingContribution, GenJournalLine[1]);
        TmpWithholdingContribution.Validate("Payment Line-Soc. Sec.", GenJournalLine[2]."Line No.");
        TmpWithholdingContribution.Modify(true);

        // [WHEN] Delete second Gen Journal Line
        GenJournalLine[2].Delete(true);

        // [THEN] "Payment Line-Soc. Sec." is empty
        TmpWithholdingContribution.Find();
        TmpWithholdingContribution.TestField("Payment Line-Soc. Sec.", 0);
    end;

    [Test]
    [HandlerFunctions('CreatePaymentMPH')]
    procedure CreatePaymentFromVendorLedgerEntriesPage()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        InvoiceNo: Code[20];
    begin
        // [SCENARIO 370440] "Applies-to ID" is set after "Create Payment" action from vendor ledger entries page
        Initialize();

        // [GIVEN] Posted purchase invoice for a vendor including withholding taxes
        InvoiceNo :=
            CreatePostPurchaseInvoiceWithAmount(
                WorkDate(), CreateVendorWithBlankedPaymentMethod(), LibraryRandom.RandDecInRange(1000, 2000, 2));
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, InvoiceNo);

        // [WHEN] Invoke "Create Payment" action from the vendor ledger entries page for the posted invoice
        CreateGenJournalBatch(GenJournalBatch);
        RunCreatePayment(VendorLedgerEntry, GenJournalBatch);
        FindGenJournalLineByBatch(GenJournalLine, GenJournalBatch);

        // [THEN] A new payment line is created with "Applies-to ID" = "X", blanked "Applies-to Doc. No."
        // [THEN] The vendor ledger entry is updated with "Applies-to ID" = "X"
        Assert.RecordCount(GenJournalLine, 1);
        GenJournalLine.TestField("Applies-to ID");
        GenJournalLine.TestField("Applies-to Doc. No.", '');
        VendorLedgerEntry.Find();
        VendorLedgerEntry.TestField("Applies-to ID", GenJournalLine."Applies-to ID");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CreatePaymentMPH')]
    procedure ErrorOnTryPostPmtJournalAfterCreatePayment()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        InvoiceNo: Code[20];
    begin
        // [SCENARIO 370440] System doesn't allow to post a payment journal after
        // [SCENARIO 370440] "Create Payment" action from vendor ledger entries page
        Initialize();

        // [GIVEN] Posted purchase invoice for a vendor including withholding taxes
        InvoiceNo :=
            CreatePostPurchaseInvoiceWithAmount(
                WorkDate(), CreateVendorWithBlankedPaymentMethod(), LibraryRandom.RandDecInRange(10000, 20000, 2));
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, InvoiceNo);

        // [GIVEN] Invoke "Create Payment" action from the vendor ledger entries page for the posted invoice
        CreateGenJournalBatch(GenJournalBatch);
        RunCreatePayment(VendorLedgerEntry, GenJournalBatch);
        FindGenJournalLineByBatch(GenJournalLine, GenJournalBatch);

        // [WHEN] Try post the payment journal
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] An error occurs: "Because this invoice includes Withholding Tax, it should not be applied directly..."
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(WithholdingTaxErr);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CreatePaymentMPH,ShowComputedWithholdContribModalPageHandler')]
    procedure PostPmtJournalAfterCreatePaymentAndCalcWithhTaxes()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
        InvoiceNo: Code[20];
    begin
        // [SCENARIO 370440] Post payment journal after "Create Payment" action
        // [SCENARIO 370440] from vendor ledger entries page and calculated withholding taxes
        Initialize();

        // [GIVEN] Posted purchase invoice "X" for a vendor including withholding taxes
        InvoiceNo :=
            CreatePostPurchaseInvoiceWithAmount(
                WorkDate(), CreateVendorWithBlankedPaymentMethod(), LibraryRandom.RandDecInRange(1000, 2000, 2));
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, InvoiceNo);

        // [GIVEN] Invoke "Create Payment" action from the vendor ledger entries page for the posted invoice
        CreateGenJournalBatch(GenJournalBatch);
        RunCreatePayment(VendorLedgerEntry, GenJournalBatch);
        FindGenJournalLineByBatch(GenJournalLine, GenJournalBatch);

        // [GIVEN] Caluclate payment withholding taxes ("Withh.Tax-Soc.Sec." action from the journal page)
        ShowComputedWithholdContributionOnPayment(GenJournalBatch.Name);

        // [GIVEN] There are 4 journal lines have been created, all having blanked "Applies-to ID", including:
        Assert.RecordCount(GenJournalLine, 4);
        GenJournalLine.SetRange("Applies-to ID", '');
        Assert.RecordCount(GenJournalLine, 4);
        GenJournalLine.SetRange("Applies-to ID");
        // [GIVEN] 3 vendor payments with "Applies-to Doc. Type" = "Invoice", "Applies-to Doc. No." = "X", "Applies-to Occurrence No." = 1
        GenJournalLine.SetRange("Account Type", GenJournalLine."Account Type"::Vendor);
        GenJournalLine.SetRange("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.SetRange("Applies-to Doc. No.", InvoiceNo);
        GenJournalLine.SetRange("Applies-to Occurrence No.", 1);
        Assert.RecordCount(GenJournalLine, 3);
        // [GIVEN] 1 G/L account (balance) line with blanked "Applies-to Doc. No."
        GenJournalLine.SetRange("Account Type", GenJournalLine."Account Type"::"G/L Account");
        GenJournalLine.SetRange("Applies-to Doc. Type");
        GenJournalLine.SetRange("Applies-to Doc. No.", '');
        Assert.RecordCount(GenJournalLine, 1);
        GenJournalLine.SetRange("Applies-to Doc. No.");

        // [WHEN] Post the payment journal
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] The journal is posted and all posted vendor ledger enties (3 entries) are closed
        VendorLedgerEntry2.SetFilter("Entry No.", '>%1', VendorLedgerEntry."Entry No.");
        Assert.RecordCount(VendorLedgerEntry2, 3);
        VendorLedgerEntry2.SetRange(Open, false);
        Assert.RecordCount(VendorLedgerEntry2, 3);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure ErrorOnCalcWithhTaxesFromPmtJournalAppliedToSeveralInvoices()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        InvoiceNo: array[2] of Code[20];
        VendorNo: Code[20];
        i: Integer;
    begin
        // [SCENARIO 370440] Error on try to calculate payment withholding taxes ("Withh.Tax-Soc.Sec." payment journal action) 
        // [SCENARIO 370440] in case of payment line is applied to several invoices
        Initialize();

        // [GIVEN] Posted purchase invoice "X", "Y" for a vendor including withholding taxes
        VendorNo := CreateVendorWithBlankedPaymentMethod();
        for i := 1 to ArrayLen(InvoiceNo) do
            InvoiceNo[i] :=
                CreatePostPurchaseInvoiceWithAmount(
                    WorkDate(), VendorNo, LibraryRandom.RandDecInRange(1000, 2000, 2));

        // [GIVEN] Vendor payment journal line
        CreateGeneralJnlLine(GenJournalLine, GenJournalLine."Document Type"::Payment, VendorNo, 0);
        GenJournalLine.Validate("Applies-to ID", UserId);
        GenJournalLine.Modify();

        for i := 1 to ArrayLen(InvoiceNo) do begin
            LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, InvoiceNo[i]);
            LibraryERM.SetAppliestoIdVendor(VendorLedgerEntry);
        end;

        // [WHEN] Try caluclate payment withholding taxes ("Withh.Tax-Soc.Sec." action from the journal page)
        asserterror ShowComputedWithholdContributionOnPayment(GenJournalLine."Journal Batch Name");

        // [THEN] An error occurs: "The vendor payment line is applied to more than one document."
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(MultiApplyErr);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WHTAmountAndPercentWereChangedWhenWHTAmountManualValidated()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchWithhContribution: Record "Purch. Withh. Contribution";
        VendorBillHeader: Record "Vendor Bill Header";
        WithholdCode: Code[20];
        ContributionCode: Code[20];
        WithholdingTaxAmount: Decimal;
        WithholdingTaxPercent: Decimal;
    begin
        // [SCENARIO 375830] Input of the "WHT Amount Manual" change "Withholding Tax Amount" and "Withholding Tax %"
        Initialize();

        // [GIVEN] Withholding Tax and Social Security were set up:
        SetupWithhAndSocSec(ContributionCode, WithholdCode);

        // [GIVEN] Vendor Bill Header with Payment Method Code
        CreateVendorBillHeaderWithPaymentMethod(VendorBillHeader, CreatePaymentMethodWithBill());

        // [GIVEN] Purchase Invoice with same Payment Method Code, Amount 10000.0 and VAT 10 % (Amount Including VAT = 11000.0)
        CreatePurchaseInvoiceWithWithholdSetupAndPmtMethod(
          PurchaseHeader, WithholdCode, ContributionCode, VendorBillHeader."Payment Method Code");

        // [GIVEN] Opened "Purch. Withh. Contribution"
        PurchWithhContribution.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");

        // [GIVEN] Memorize "Withholding Tax Amount" and "Withholding Tax %"
        WithholdingTaxAmount := PurchWithhContribution."Withholding Tax Amount";
        WithholdingTaxPercent := PurchWithhContribution."Withholding Tax %";

        // [WHEN] Validate "WHT Amount Manual" to (2 * "Withholding Tax Amount")
        PurchWithhContribution.Validate("WHT Amount Manual", Round(PurchWithhContribution."Withholding Tax Amount" * 2));

        // [THEN] "Withholding Tax Amount" and "Withholding Tax %" increse too
        PurchWithhContribution.TestField("Withholding Tax Amount", WithholdingTaxAmount * 2);
        PurchWithhContribution.TestField("Withholding Tax %", WithholdingTaxPercent * 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WHTAmountAndPercentWereRecalculatedWhenWHTAmountManualValidatedTo0AndPaymantDateIsEmty()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchWithhContribution: Record "Purch. Withh. Contribution";
        VendorBillHeader: Record "Vendor Bill Header";
        WithholdCode: Code[20];
        ContributionCode: Code[20];
        WithholdingTaxAmount: Decimal;
        WithholdingTaxPercent: Decimal;
    begin
        // [SCENARIO 375830] Change of the "WHT Amount Manual" from non-zero value to 0 recalculate "Withholding Tax Amount" and "Withholding Tax %"
        Initialize();

        // [GIVEN] Withholding Tax and Social Security were set up:
        SetupWithhAndSocSec(ContributionCode, WithholdCode);

        // [GIVEN] Vendor Bill Header with Payment Method Code
        CreateVendorBillHeaderWithPaymentMethod(VendorBillHeader, CreatePaymentMethodWithBill());

        // [GIVEN] Purchase Invoice with same Payment Method Code, Amount 10000.0 and VAT 10 % (Amount Including VAT = 11000.0)
        CreatePurchaseInvoiceWithWithholdSetupAndPmtMethod(
          PurchaseHeader, WithholdCode, ContributionCode, VendorBillHeader."Payment Method Code");

        // [GIVEN] Opened "Purch. Withh. Contribution"
        PurchWithhContribution.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");

        // [GIVEN] Memorize "Withholding Tax Amount" and "Withholding Tax %"
        WithholdingTaxAmount := PurchWithhContribution."Withholding Tax Amount";
        WithholdingTaxPercent := PurchWithhContribution."Withholding Tax %";

        // [GIVEN] Validated "WHT Amount Manual" to (2 * "Withholding Tax Amount")
        PurchWithhContribution.Validate("WHT Amount Manual", Round(PurchWithhContribution."Withholding Tax Amount" * 2));

        // [GIVEN] Payment Date = ''
        PurchWithhContribution."Payment Date" := 0D;

        // [WHEN] Change "WHT Amount Manual" to 0
        PurchWithhContribution.Validate("WHT Amount Manual", 0);

        // [THEN] "Withholding Tax Amount" and "Withholding Tax %" recalculate to previous values
        PurchWithhContribution.TestField("Withholding Tax Amount", WithholdingTaxAmount);
        PurchWithhContribution.TestField("Withholding Tax %", WithholdingTaxPercent);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WHTAmountAndPercentWereRecalculatedWhenWHTAmountManualValidatedTo0AndPaymentDateIsFilled()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchWithhContribution: Record "Purch. Withh. Contribution";
        VendorBillHeader: Record "Vendor Bill Header";
        WithholdCode: Code[20];
        ContributionCode: Code[20];
        WithholdingTaxAmount: Decimal;
        WithholdingTaxPercent: Decimal;
    begin
        // [SCENARIO 375830] Change of the "WHT Amount Manual" from non-zero value to 0 recalculate "Withholding Tax Amount" and "Withholding Tax %"
        Initialize();

        // [GIVEN] Withholding Tax and Social Security were set up:
        SetupWithhAndSocSec(ContributionCode, WithholdCode);

        // [GIVEN] Vendor Bill Header with Payment Method Code
        CreateVendorBillHeaderWithPaymentMethod(VendorBillHeader, CreatePaymentMethodWithBill());

        // [GIVEN] Purchase Invoice with same Payment Method Code, Amount 10000.0 and VAT 10 % (Amount Including VAT = 11000.0)
        CreatePurchaseInvoiceWithWithholdSetupAndPmtMethod(
          PurchaseHeader, WithholdCode, ContributionCode, VendorBillHeader."Payment Method Code");

        // [GIVEN] Opened "Purch. Withh. Contribution"
        PurchWithhContribution.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");

        // [GIVEN] Memorize "Withholding Tax Amount" and "Withholding Tax %"
        WithholdingTaxAmount := PurchWithhContribution."Withholding Tax Amount";
        WithholdingTaxPercent := PurchWithhContribution."Withholding Tax %";

        // [GIVEN] Validated "WHT Amount Manual" to (2 * "Withholding Tax Amount")
        PurchWithhContribution.Validate("WHT Amount Manual", Round(PurchWithhContribution."Withholding Tax Amount" * 2));

        // [GIVEN] Payment Date = WorkDate
        PurchWithhContribution."Payment Date" := WorkDate();

        // [WHEN] Change "WHT Amount Manual" to 0
        PurchWithhContribution.Validate("WHT Amount Manual", 0);

        // [THEN] "Withholding Tax Amount" and "Withholding Tax %" recalculate to previous values
        PurchWithhContribution.TestField("Withholding Tax Amount", WithholdingTaxAmount);
        PurchWithhContribution.TestField("Withholding Tax %", WithholdingTaxPercent);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    procedure ZeroWithholdingTaxIsCreatedAfterPostVendorBill()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorBillHeader: Record "Vendor Bill Header";
        BillPostingGroup: Record "Bill Posting Group";
        WithholdingTax: Record "Withholding Tax";
        WithholdCode: Code[20];
        VendorNo: Code[20];
    begin
        // [SCENARIO 395226] Zero "Withholding Tax" is created after posting Vendor Bill with "Withholding Tax %" = 0, "Taxable Base %" = 100
        Initialize();

        // [GIVEN] Withholding Tax setup with "Withholding Tax %" = 0, "Taxable Base %" = 100
        WithholdCode := CreateWithholdCodeWithLineAndRates(100, 0);
        VendorNo := CreateVendorWithSocSecAndWithholdCodes(WithholdCode, '', '');
        // [GIVEN] Posted purchase invoice
        CreatePurchaseInvoiceWithAmount(PurchaseHeader, WorkDate(), VendorNo, 1, LibraryRandom.RandDecInRange(1000, 2000, 2));
        PurchaseHeader.Validate("Payment Method Code", CreatePaymentMethodWithBill());
        PurchaseHeader.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        // [GIVEN] Vendor Bill card with suggested vendor payment
        CreateVendorBillHeaderWithPaymentMethod(VendorBillHeader, PurchaseHeader."Payment Method Code");
        LibraryITLocalization.CreateBillPostingGroup(
          BillPostingGroup, VendorBillHeader."Bank Account No.", VendorBillHeader."Payment Method Code");
        RunSuggestVendorBillsForVendorNo(VendorBillHeader, VendorNo);
        // [GIVEN] Issue the Bill (Create List)
        LibraryITLocalization.IssueVendorBill(VendorBillHeader);

        // [WHEN] Post the Bill
        LibraryITLocalization.PostIssuedVendorBill(VendorBillHeader);

        // [THEN] Withholding Tax is created with "Withholding Tax Amount" = 0
        FindWithholdingTax(WithholdingTax, VendorNo);
        WithholdingTax.TestField("Total Amount");
        WithholdingTax.TestField("Withholding Tax Amount", 0);
    end;

    [Test]
    [HandlerFunctions('ShowComputedWithholdContribModalPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyThreshold()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseLine: Record "Purchase Line";
        TmpWithholdingContribution: Record "Tmp Withholding Contribution";
        PurchaseHeader: Record "Purchase Header";
        VendorNo: Code[20];
        ContributionCode: Code[20];
        WithholdCode: Code[20];
        InvoiceAmount: Decimal;
        PostedDocumentNo: Code[20];
        TaxableBase: Decimal;
        WithholdingTaxAmount: Decimal;
        WithhTaxesContributionCard: TestPage "Withh. Taxes-Contribution Card";
    begin
        // [SCENARIO 436923] Social Security threshold brackets calculation error.
        Initialize();

        // [GIVEN] Vendor with Social Security Contribution having Contribution Brackets.
        SetupWithhAndSocSec(ContributionCode, WithholdCode);
        VendorNo := CreateVendorWithSocSecAndWithholdCodes(WithholdCode, ContributionCode, '');

        // [GIVEN] Posted Purchase Invoice
        InvoiceAmount := LibraryRandom.RandDecInRange(1000, 2000, 2);
        CreatePurchaseInvoiceWithAmount(PurchaseHeader, WorkDate(), VendorNo, 1, InvoiceAmount);
        InitTmpWithholdingContribution(TmpWithholdingContribution, VendorNo);

        // [WHEN] Validate "Gross Amount"
        TmpWithholdingContribution.Validate("Gross Amount", InvoiceAmount);
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] Create and Post Payment Journal with applies to Posted Invoice.
        CreateAndPostGenJnlLineWithAppliesToDoc(
            GenJournalLine."Document Type"::Payment,
            PostedDocumentNo,
            GenJournalLine."Applies-to Doc. Type"::Invoice,
            WorkDate());

        // [GIVEN] Create Another Purchase Invoice of same vendor.
        InvoiceAmount := LibraryRandom.RandDecInRange(1000, 10000, 2);
        CreatePurchaseInvoiceWithAmount(PurchaseHeader, WorkDate(), VendorNo, 1, InvoiceAmount);
        WithholdingTaxAmount := CalculateWithholdTaxes(VendorNo, InvoiceAmount, TaxableBase);

        // [THEN] Calculate Withhold Taxes Contribution on Purchase Invoice page.
        CalculateWithholdTaxesContributionOnPurchInvoice(WithhTaxesContributionCard, PurchaseLine."Document No.");

        // [VERIFY] Verify Payable Amount is calculated on Page -Withhold Taxes-Contribution Card.
        VerifyValueOnWithholdTaxesContributionCardPage(WithhTaxesContributionCard);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateWithHoldingTaxAmountZeroInVendorBillLine()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorBillHeader: Record "Vendor Bill Header";
        VendorBillLine: Record "Vendor Bill Line";
        DocumentNo: code[20];
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [SCENARIO 492285] Withholding Tax Amount keeps showing in Vendor Bill Card even after removing it manually from Sale Invoice.
        Initialize();

        // [GIVEN] Create a Vendor.
        CreateVendorWithPaymentMethodAndWithHoldCodeWithLine(Vendor);

        // [GIVEN] Create Purchase Invoice.
        CreatePurchaseInvoice(PurchaseHeader, PurchaseLine, Vendor."No.");

        // [GIVEN] Open Purchase Invoice and click on "With&hold Taxes-Soc. Sec." action.
        OpenPurchaseInvoiceAndPerformWithHoldTaxesSocialSecurity(PurchaseInvoice, PurchaseHeader);

        // [GIVEN] Calculate Withhold Taxes Contribution.
        CalculateWithholdTaxesContributionOnPurchInvoicewithBaseExcludeAmount(
            PurchaseInvoice,
            PurchaseHeader."No.",
            PurchaseLine."Line Amount");

        // [THEN] Post the Purchase Invoice document.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Create Vendor Bill and click on "Suggest Vendor Bills"  action.
        CreateVendorBill(VendorBillHeader, CreateBillPostingGroup(Vendor."Payment Method Code"), DocumentNo);

        // [THEN] Find Purchase Line.
        VendorBillLine.SetRange("Vendor Bill List No.", VendorBillHeader."No.");
        VendorBillLine.FindFirst();

        // [VERIFY] Verify: Withholding Tax Amount 0 in Vendor Bill Line.
        Assert.AreEqual(0, VendorBillLine."Withholding Tax Amount", WithHoldingAmountZeroErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TotalAmtAndRemainingAmtInComputedWithholdingTaxEntryIsNegativeWhenPostPurchCrMemo()
    var
        PurchaseLine: Record "Purchase Line";
        ComputedWithholdingTax: Record "Computed Withholding Tax";
        WithhTaxesContributionCard: TestPage "Withh. Taxes-Contribution Card";
        PostedDocumentNo: Code[20];
    begin
        // [SCENARIO 542470] When Stan post Purchase Credit Memo then Computed Withholding Tax Entry is created with negative "Total Amount" and "Remaining Amount".
        Initialize();
 
        // [GIVEN] Create a Purchase Credit Memo.
        CreatePurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::"Credit Memo", CreateVendor('', ''), false);
 
        // [GIVEN] Calculate Withhold Taxes Contribution on Purchase Credit Memo page.
        CalculateWithholdTaxesContributionOnPurchCrMemo(WithhTaxesContributionCard, PurchaseLine."Document No.");
 
        // [GIVEN] Post Purchase Credit Memo.
        PostedDocumentNo := PostPurchaseDocument(PurchaseLine."Document Type"::"Credit Memo", PurchaseLine."Document No.");
 
        // [WHEN] Find Computed Withholding Tax.
        ComputedWithholdingTax.SetRange("Document No.", PostedDocumentNo);
        ComputedWithholdingTax.SetRange("Vendor No.", PurchaseLine."Buy-from Vendor No.");
        ComputedWithholdingTax.FindFirst();
 
        // [THEN] "Total Amount" of Computed Withholding Tax is equal to negative of "Line Amount" of Purchase Line.
        Assert.AreEqual(
            -PurchaseLine."Line Amount", 
            ComputedWithholdingTax."Total Amount", 
            StrSubstNo(
                TotalAmountErr, 
                ComputedWithholdingTax.FieldCaption("Total Amount"), 
                -PurchaseLine."Line Amount", 
                ComputedWithholdingTax.TableCaption()));

        // [THEN] "Remaining Amount" of Computed Withholding Tax is equal to negative of "Line Amount" of Purchase Line.        
        Assert.AreEqual(
            -PurchaseLine."Line Amount", 
            ComputedWithholdingTax."Remaining Amount", 
            StrSubstNo(
                RemainingAmountErr, 
                ComputedWithholdingTax.FieldCaption("Remaining Amount"), 
                -PurchaseLine."Line Amount", 
                ComputedWithholdingTax.TableCaption()));
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
        ClearPaymentJnlTemplates();
    end;

    local procedure ClearPaymentJnlTemplates()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Payments);
        GenJournalTemplate.DeleteAll();
    end;

    local procedure SetupWithhAndSocSec(var ContributionCode: Code[20]; var WithholdCode: Code[20])
    var
        ContributionCodeLine: Record "Contribution Code Line";
    begin
        CreateContributionCodeWithLineAndRates(
          ContributionCodeLine, ContributionCodeLine."Contribution Type"::INPS, LibraryRandom.RandDecInRange(10, 20, 2),
          LibraryRandom.RandDecInRange(30, 60, 2), LibraryRandom.RandDec(100, 2));
        ContributionCode := ContributionCodeLine.Code;
        WithholdCode :=
          CreateWithholdCodeWithLineAndRates(LibraryRandom.RandDecInRange(30, 60, 2), LibraryRandom.RandDecInRange(10, 30, 2));
    end;

    local procedure CalculateWithholdingTaxAmount(WithholdCode: Code[20]; TaxBaseAmount: Decimal): Decimal
    var
        WithholdCodeLine: Record "Withhold Code Line";
        WithholdingTaxAmount: Decimal;
    begin
        WithholdCodeLine.SetRange("Withhold Code", WithholdCode);
        WithholdCodeLine.FindFirst();
        WithholdingTaxAmount := ((TaxBaseAmount * WithholdCodeLine."Taxable Base %" / 100) * WithholdCodeLine."Withholding Tax %") / 100;
        exit(WithholdingTaxAmount);
    end;

    local procedure CalculateWithholdTaxes(VendorNo: Code[20]; LineAmount: Decimal; var TaxableBase: Decimal) WithholdingTaxAmount: Decimal
    var
        WithholdCodeLine: Record "Withhold Code Line";
        Currency: Record Currency;
    begin
        FindWithholdCodeLine(WithholdCodeLine, VendorNo);
        TaxableBase := Round(LineAmount * WithholdCodeLine."Taxable Base %" / 100);
        WithholdingTaxAmount := Round(TaxableBase * WithholdCodeLine."Withholding Tax %" / 100, Currency."Amount Rounding Precision");
    end;

    local procedure CalculateWithholdTaxesContributionOnPurchCrMemo(var WithhTaxesContributionCard: TestPage "Withh. Taxes-Contribution Card"; No: Code[20])
    var
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        WithhTaxesContributionCard.Trap();
        PurchaseCreditMemo.OpenEdit();
        PurchaseCreditMemo.FILTER.SetFilter("No.", No);
        PurchaseCreditMemo."With&hold Taxes-Soc. Sec.".Invoke();
    end;

    local procedure CalculateWithholdTaxesContributionOnPurchInvoice(var WithhTaxesContributionCard: TestPage "Withh. Taxes-Contribution Card"; No: Code[20])
    var
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        WithhTaxesContributionCard.Trap();
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.FILTER.SetFilter("No.", No);
        PurchaseInvoice."With&hold Taxes-Soc. Sec.".Invoke();
    end;

    local procedure ModifyWHTAmountManualForPurchWithhContribution(DocType: Enum "Purchase Document Type"; DocNo: Code[20]): Decimal
    var
        PurchWithhContribution: Record "Purch. Withh. Contribution";
    begin
        PurchWithhContribution.Get(DocType, DocNo);
        PurchWithhContribution.Validate("WHT Amount Manual", PurchWithhContribution."Withholding Tax Amount" / 2);
        PurchWithhContribution.Modify(true);
        exit(PurchWithhContribution."WHT Amount Manual");
    end;

    local procedure CreateAndPostPurchaseInvoice(var PurchaseLine: Record "Purchase Line"; SocialSecurityCode: Code[20]; INAILCode: Code[20]): Code[20]
    begin
        exit(CreateAndPostPurchaseInvoiceWithTaxableBase(PurchaseLine, CreateVendor(SocialSecurityCode, INAILCode)));
    end;

    local procedure CreateAndPostPurchaseInvoiceWithZeroTaxableBase(var PurchaseLine: Record "Purchase Line"; SocialSecurityCode: Code[20]; INAILCode: Code[20]): Code[20]
    begin
        exit(CreateAndPostPurchaseInvoiceWithTaxableBase(PurchaseLine, CreateVendorWithZeroTaxableBase(SocialSecurityCode, INAILCode)));
    end;

    local procedure CreateAndPostPurchaseInvoiceWithTaxableBase(var PurchaseLine: Record "Purchase Line"; VendorNo: Code[20]) PostedDocumentNo: Code[20]
    var
        WithhTaxesContributionCard: TestPage "Withh. Taxes-Contribution Card";
    begin
        CreatePurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::Invoice, VendorNo, false);  // Prices Including VAT - FALSE.
        CalculateWithholdTaxesContributionOnPurchInvoice(WithhTaxesContributionCard, PurchaseLine."Document No.");
        PostedDocumentNo := PostPurchaseDocument(PurchaseLine."Document Type"::Invoice, PurchaseLine."Document No.");
    end;

    local procedure CreateAndPostPurchaseCreditMemo(var PurchaseLine: Record "Purchase Line") PostedDocumentNo: Code[20]
    var
        WithhTaxesContributionCard: TestPage "Withh. Taxes-Contribution Card";
    begin
        CreatePurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::"Credit Memo", CreateVendor('', ''), false);  // Prices Including VAT - FALSE.
        CalculateWithholdTaxesContributionOnPurchCrMemo(WithhTaxesContributionCard, PurchaseLine."Document No.");
        PostedDocumentNo := PostPurchaseDocument(PurchaseLine."Document Type"::"Credit Memo", PurchaseLine."Document No.");
    end;

    local procedure CreateAndPostGeneralJnlLineWithAppliesToDoc(DocumentType: Enum "Gen. Journal Document Type"; AppliesToDocNo: Code[20];
                                                                                  AppliesToDocType: Enum "Gen. Journal Document Type")
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateAndApplyGeneralJnlLine(GenJournalLine, DocumentType, AppliesToDocNo, AppliesToDocType);
        ShowComputedWithholdContributionOnPayment(GenJournalLine."Journal Batch Name");
        VerifyTmpWithholdingContributionNotEmpty(AppliesToDocNo);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreatePostVendorPaymentWithExternalDocNo(VendorNo: Code[20]; Amount: Decimal; ExternalDocNo: Code[35]): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
        WithholdingContribution: Codeunit "Withholding - Contribution";
    begin
        CreateGeneralJnlLine(GenJournalLine, GenJournalLine."Document Type"::Payment, VendorNo, Amount);
        GenJournalLine.Validate("External Document No.", ExternalDocNo);
        GenJournalLine.Modify();
        LibraryVariableStorage.Enqueue(Round(Amount / 3));
        WithholdingContribution.CreateTmpWithhSocSec(GenJournalLine);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        EXIT(GenJournalLine."Document No.");
    end;

    local procedure CreateAndApplyGeneralJnlLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; AppliesToDocNo: Code[20];
                                                                                                                   AppliesToDocType: Enum "Gen. Journal Document Type")
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, AppliesToDocType, AppliesToDocNo);
        VendorLedgerEntry.CalcFields(Amount);
        CreateGeneralJnlLine(GenJournalLine, DocumentType, VendorLedgerEntry."Vendor No.", -VendorLedgerEntry.Amount);
        GenJournalLine.Validate("Applies-to Doc. Type", AppliesToDocType);
        GenJournalLine.Validate("Applies-to Doc. No.", AppliesToDocNo);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateContributionCode(var ContributionCode: Record "Contribution Code"; ContributionType: Option)
    begin
        LibraryITLocalization.CreateContributionCode(ContributionCode, ContributionType);
        ContributionCode.Validate("Social Security Payable Acc.", LibraryERM.CreateGLAccountNo());
        ContributionCode.Validate("Social Security Charges Acc.", LibraryERM.CreateGLAccountNo());
        ContributionCode.Modify(true);
    end;

    local procedure CreateContributionCodeWithLine(var ContributionCodeLine: Record "Contribution Code Line"; ContributionType: Option)
    begin
        CreateContributionCodeWithLineAndRates(
          ContributionCodeLine, ContributionType, LibraryRandom.RandIntInRange(5, 10), LibraryRandom.RandIntInRange(10, 20),
          LibraryRandom.RandIntInRange(10, 20));
    end;

    local procedure CreateContributionCodeWithLineAndRates(var ContributionCodeLine: Record "Contribution Code Line"; ContributionType: Option; SocSecRate: Decimal; FreeLanceRate: Decimal; TaxableBaseRate: Decimal)
    var
        ContributionCode: Record "Contribution Code";
    begin
        CreateContributionCode(ContributionCode, ContributionType);
        LibraryITLocalization.CreateContributionCodeLine(
          ContributionCodeLine, ContributionCode.Code, WorkDate(), ContributionCode."Contribution Type");
        ContributionCodeLine.Validate("Social Security %", SocSecRate);
        ContributionCodeLine.Validate("Free-Lance Amount %", FreeLanceRate);
        ContributionCodeLine.Validate(
          "Social Security Bracket Code", CreateContributionBracketWithLine(
            ContributionCodeLine."Contribution Type", TaxableBaseRate));
        ContributionCodeLine.Modify(true);
    end;

    local procedure CreateContributionBracketWithLine(ContributionType: Option; TaxableBase: Decimal): Code[10]
    var
        ContributionBracket: Record "Contribution Bracket";
        ContributionBracketLine: Record "Contribution Bracket Line";
    begin
        LibraryITLocalization.CreateContributionBracket(ContributionBracket, ContributionType);
        LibraryITLocalization.CreateContributionBracketLine(
          ContributionBracketLine, ContributionBracket.Code, LibraryRandom.RandIntInRange(10000, 99999),
          ContributionBracket."Contribution Type");  // Using large value for Amount.
        ContributionBracketLine.Validate("Taxable Base %", TaxableBase);
        ContributionBracketLine.Modify(true);
        exit(ContributionBracket.Code);
    end;

    local procedure CreateGeneralJnlLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; VendorNo: Code[20];
                                                                                                           Amount: Decimal)
    var
        BankAccount: Record "Bank Account";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        CreateGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          DocumentType, GenJournalLine."Account Type"::Vendor, VendorNo, Amount);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Bal. Account No.", BankAccount."No.");
        GenJournalLine.Modify(true);
    end;

    local procedure CreateJournalLineWithAppliesToDocNo(GenJournalBatch: Record "Gen. Journal Batch"; VendorNo: Code[20]; PostedDocumentNo: Code[20]; Amount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryJournals.CreateGenJournalLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, VendorNo,
          GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), Amount);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", PostedDocumentNo);
        GenJournalLine.Modify(true);
    end;

    local procedure CreatePurchaseDocument(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20];
                                                                                                       PricesIncludingVAT: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate("Prices Including VAT", PricesIncludingVAT);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithPurchSetup(), LibraryRandom.RandIntInRange(100, 200));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(10, 100, 2));
        PurchaseLine.Modify(true);
        PurchaseHeader.Validate("Check Total", PurchaseLine."Amount Including VAT");
        PurchaseHeader.Modify(true);
    end;

    local procedure CreatePurchaseInvoiceWithAmount(var PurchaseHeader: Record "Purchase Header"; PostingDate: Date; VendorNo: Code[20]; Quantity: Integer; DirectUnitCost: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
        WithholdingContribution: Codeunit "Withholding - Contribution";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        PurchaseHeader.Validate("Posting Date", PostingDate);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(), Quantity);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
        WithholdingContribution.CalculateWithholdingTax(PurchaseHeader, true);
    end;

    local procedure CreatePurchaseInvoiceWithWithholdSetupAndPmtMethod(var PurchaseHeader: Record "Purchase Header"; WithholdCode: Code[20]; SocSecCode: Code[20]; PaymentMethodCode: Code[10])
    begin
        CreatePurchaseInvoiceWithAmount(
          PurchaseHeader, WorkDate(), CreateVendorWithSocSecAndWithholdCodes(WithholdCode, SocSecCode, ''),
          LibraryRandom.RandIntInRange(10, 20), LibraryRandom.RandDecInRange(1000, 2000, 2));
        PurchaseHeader.Validate("Payment Method Code", PaymentMethodCode);
        PurchaseHeader.Modify(true);
        PurchaseHeader.CalcFields("Amount Including VAT", Amount);
    end;

    local procedure CreatePostPurchaseInvoiceWithAmount(PostingDate: Date; VendorNo: Code[20]; DirectUnitCost: Decimal): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreatePurchaseInvoiceWithAmount(PurchaseHeader, PostingDate, VendorNo, 1, DirectUnitCost);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateVendorWithSocSecAndWithholdCodes(WithholdingTaxCode: Code[20]; SocialSecurityCode: Code[20]; INAILCode: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Withholding Tax Code", WithholdingTaxCode);
        Vendor.Validate("Social Security Code", SocialSecurityCode);
        Vendor.Validate("INAIL Code", INAILCode);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateVendor(SocialSecurityCode: Code[20]; INAILCode: Code[20]): Code[20]
    begin
        exit(CreateVendorWithSocSecAndWithholdCodes(CreateWithholdCodeWithLine(), SocialSecurityCode, INAILCode));
    end;

    local procedure CreateVendorWithZeroTaxableBase(SocialSecurityCode: Code[20]; INAILCode: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Withholding Tax Code", CreateWithholdCodeWithLineAndRates(0, LibraryRandom.RandInt(10)));
        Vendor.Validate("Social Security Code", SocialSecurityCode);
        Vendor.Validate("INAIL Code", INAILCode);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateVendorWithBlankedPaymentMethod() VendorNo: Code[20]
    var
        ContributionCode: Code[20];
        WithholdCode: Code[20];
    begin
        SetupWithhAndSocSec(ContributionCode, WithholdCode);
        VendorNo := CreateVendorWithSocSecAndWithholdCodes(WithholdCode, ContributionCode, '');
        UpdateBlankPaymentMethodCodeOnVendor(VendorNo);
    end;

    local procedure CreateVendorBillHeaderWithPaymentMethod(var VendorBillHeader: Record "Vendor Bill Header"; PaymentMethodCode: Code[10])
    begin
        VendorBillHeader.Get(CreateVendorBillHeader());
        VendorBillHeader.Validate("Payment Method Code", PaymentMethodCode);
        VendorBillHeader.Modify(true);
    end;

    local procedure CreateVendorBillHeader(): Code[20]
    var
        VendorBillHeader: Record "Vendor Bill Header";
        BankAccount: Record "Bank Account";
    begin
        LibraryITLocalization.CreateVendorBillHeader(VendorBillHeader);
        LibraryERM.CreateBankAccount(BankAccount);
        VendorBillHeader.Validate("Bank Account No.", BankAccount."No.");
        VendorBillHeader.Modify(true);
        exit(VendorBillHeader."No.");
    end;

    local procedure CreatePaymentLineForBatch(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch")
    begin
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
            GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor,
            LibraryPurchase.CreateVendorNo(), LibraryRandom.RandDec(200, 2));
    end;

    local procedure CreatePaymentMethodWithBill(): Code[10]
    var
        PaymentMethod: Record "Payment Method";
        Bill: Record Bill;
    begin
        LibraryITLocalization.CreateBill(Bill);
        Bill.Validate("Vendor Bill List", LibraryERM.CreateNoSeriesCode());
        Bill.Validate("Vendor Bill No.", LibraryERM.CreateNoSeriesCode());
        Bill.Modify(true);
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        PaymentMethod.Validate("Bill Code", Bill.Code);
        PaymentMethod.Modify(true);
        exit(PaymentMethod.Code);
    end;

    local procedure CreateWithholdCode(): Code[20]
    var
        WithholdCode: Record "Withhold Code";
    begin
        LibraryITLocalization.CreateWithholdCode(WithholdCode);
        WithholdCode.Validate("Withholding Taxes Payable Acc.", LibraryERM.CreateGLAccountNo());
        WithholdCode.Validate("Tax Code", Format(LibraryRandom.RandIntInRange(1000, 9999)));  // Using Random value for Tax Code - 4 Char length.
        WithholdCode.Validate("770 Code", StringTxt);
        WithholdCode.Modify(true);
        exit(WithholdCode.Code);
    end;

    local procedure CreateWithholdCodeWithLine(): Code[20]
    begin
        exit(CreateWithholdCodeWithLineAndRates(LibraryRandom.RandIntInRange(10, 20), LibraryRandom.RandInt(10)));
    end;

    local procedure CreateWithholdCodeWithLineAndRates(TaxableBase: Decimal; WithholdingTaxRate: Decimal): Code[20]
    var
        WithholdCodeLine: Record "Withhold Code Line";
    begin
        LibraryITLocalization.CreateWithholdCodeLine(WithholdCodeLine, CreateWithholdCode(), WorkDate());  // Starting Date as Workdate.
        WithholdCodeLine.Validate("Withholding Tax %", WithholdingTaxRate);
        WithholdCodeLine.Validate("Taxable Base %", TaxableBase);
        WithholdCodeLine.Modify(true);
        exit(WithholdCodeLine."Withhold Code");
    end;

    local procedure CreateGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate(Type, GenJournalTemplate.Type::Payments);
        GenJournalTemplate.Modify(true);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure CreateComputedContribution(VendorNo: Code[20]; PostingDate: Date; RemainingGrossAmount: Decimal)
    var
        ComputedContribution: Record "Computed Contribution";
    begin
        ComputedContribution.Init();
        ComputedContribution.Validate("Vendor No.", VendorNo);
        ComputedContribution.Validate("Document Date", PostingDate);
        ComputedContribution.Validate("Document No.", LibraryUtility.GenerateRandomCode20(ComputedContribution.FieldNo("Document No."), DATABASE::"Computed Contribution"));
        ComputedContribution.Validate("Posting Date", PostingDate);
        ComputedContribution.Validate("Remaining Gross Amount", RemainingGrossAmount);
        ComputedContribution.Insert();
    end;

    local procedure CreateVendorWithINPSContributionSetup(var ContributionBracketLine: Record "Contribution Bracket Line"; var VendorNo: Code[20]; TaxableBase: Decimal)
    var
        ContributionCodeLine: Record "Contribution Code Line";
        WithholdingContribution: Codeunit "Withholding - Contribution";
    begin
        CreateContributionCodeWithLine(ContributionCodeLine, ContributionCodeLine."Contribution Type"::INPS);
        WithholdingContribution.SetSocSecBracketFilters(
          ContributionBracketLine, ContributionCodeLine."Social Security Bracket Code", ContributionCodeLine."Contribution Type"::INPS, '');
        ContributionBracketLine.Validate("Taxable Base %", TaxableBase);
        ContributionBracketLine.Modify(true);
        VendorNo := CreateVendor(ContributionCodeLine.Code, '');
    end;

    local procedure InitTmpWithholdingContribution(var TmpWithholdingContribution: Record "Tmp Withholding Contribution"; VendorNo: Code[20])
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(VendorNo);
        TmpWithholdingContribution.Init();
        TmpWithholdingContribution.Validate("Vendor No.", Vendor."No.");
        TmpWithholdingContribution.Validate("Withholding Tax Code", Vendor."Withholding Tax Code");
        TmpWithholdingContribution.Validate("Payment Date", WorkDate());
        TmpWithholdingContribution.Validate("Social Security Code", Vendor."Social Security Code");

        TmpWithholdingContribution.TestField("Social Security %");
        TmpWithholdingContribution.TestField("Free-Lance %");
        TmpWithholdingContribution.TestField("INAIL Code", '');
    end;

    local procedure AddContributionBracketLine(ContributionBracketLine: Record "Contribution Bracket Line"; NewAmount: Decimal; NewTaxableBasePct: Decimal)
    begin
        ContributionBracketLine.Validate(Amount, NewAmount);
        ContributionBracketLine.Validate("Taxable Base %", NewTaxableBasePct);
        ContributionBracketLine.Insert(true);
    end;

    local procedure FindWithholdCodeLine(var WithholdCodeLine: Record "Withhold Code Line"; VendorNo: Code[20])
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(VendorNo);
        WithholdCodeLine.SetRange("Withhold Code", Vendor."Withholding Tax Code");
        WithholdCodeLine.FindFirst();
    end;

    local procedure FindWithholdingTax(var WithholdingTax: Record "Withholding Tax"; VendorNo: Code[20])
    begin
        WithholdingTax.SetRange("Vendor No.", VendorNo);
        WithholdingTax.FindFirst();
    end;

    local procedure FindContributions(var Contributions: Record Contributions; VendorNo: Code[20]);
    begin
        Contributions.SetRange("Vendor No.", VendorNo);
        Contributions.FindFirst();
    end;

    local procedure FindGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; JournalTemplateName: Code[10]; JournalBatchName: Code[10]; BalAccountType: enum "Gen. Journal Account Type"; BalAccountNo: Code[20])
    begin
        GenJournalLine.SetRange("Journal Template Name", JournalTemplateName);
        GenJournalLine.SetRange("Journal Batch Name", JournalBatchName);
        GenJournalLine.SetRange("Bal. Account Type", BalAccountType);
        GenJournalLine.SetRange("Bal. Account No.", BalAccountNo);
        GenJournalLine.FindFirst();
    end;

    local procedure FindGenJournalLineForWithholdingTaxAndModifyBalAccNo(var GenJournalLine: Record "Gen. Journal Line"; VendorNo: Code[20]; BalAccountNo: Code[20])
    var
        Vendor: Record Vendor;
        WithholdCode: Record "Withhold Code";
    begin
        Vendor.Get(VendorNo);
        WithholdCode.Get(Vendor."Withholding Tax Code");
        FindGenJournalLine(
          GenJournalLine, GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name",
          GenJournalLine."Bal. Account Type"::"G/L Account", WithholdCode."Withholding Taxes Payable Acc.");
        GenJournalLine.Validate("Bal. Account No.", BalAccountNo);
        GenJournalLine.Modify(true);
    end;

    local procedure FindGenJournalLineByBatch(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch")
    begin
        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.FindFirst();
    end;

    local procedure MockTmpWithholdingContribution(var TmpWithholdingContribution: Record "Tmp Withholding Contribution"; GenJournalLine: Record "Gen. Journal Line")
    begin
        TmpWithholdingContribution.Init();
        TmpWithholdingContribution."Journal Batch Name" := GenJournalLine."Journal Batch Name";
        TmpWithholdingContribution."Journal Template Name" := GenJournalLine."Journal Template Name";
        TmpWithholdingContribution."Line No." := GenJournalLine."Line No.";
        TmpWithholdingContribution.Insert();
    end;

    local procedure GetExternalDocNoFromPostedInvoice(VendorNo: Code[20]): Code[35]
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader.SetRange("Buy-from Vendor No.", VendorNo);
        PurchInvHeader.FindFirst();
        PurchInvHeader.TestField("Vendor Invoice No.");
        exit(PurchInvHeader."Vendor Invoice No.");
    end;

    local procedure INAILCodeLookupOnVendorCard(No: Code[20])
    var
        VendorCard: TestPage "Vendor Card";
    begin
        OpenVendorCard(VendorCard, No);
        VendorCard."INAIL Code".Lookup();
        VendorCard.OK().Invoke();
    end;

    local procedure OpenVendorCard(var VendorCard: TestPage "Vendor Card"; No: Code[20])
    begin
        VendorCard.OpenEdit();
        VendorCard.FILTER.SetFilter("No.", No);
    end;

    local procedure PostPurchaseDocument(DocumentType: Enum "Purchase Document Type"; No: Code[20]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.Get(DocumentType, No);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure PostPurchInvoiceWithCalcWithholdingTax(var PurchaseLine: Record "Purchase Line"; var WithholdingTaxAmount: Decimal) PostedDocumentNo: Code[20]
    var
        TaxableBase: Decimal;
    begin
        PostedDocumentNo := CreateAndPostPurchaseInvoice(PurchaseLine, '', '');  // Blank for INAIL Code and Posted Document Number.
        UpdateBlankPaymentMethodCodeOnVendor(PurchaseLine."Buy-from Vendor No.");
        WithholdingTaxAmount := CalculateWithholdTaxes(PurchaseLine."Buy-from Vendor No.", PurchaseLine."Line Amount", TaxableBase);
    end;

    local procedure RunCertificationsReport(No: Code[20])
    var
        Vendor: Record Vendor;
        Certifications: Report Certifications;
    begin
        Clear(Certifications);
        Vendor.SetRange("No.", No);
        Certifications.SetTableView(Vendor);
        Certifications.Run();
    end;

    local procedure RunWithholdingTaxesReport(VendorNo: Code[20])
    var
        WithholdingTax: Record "Withholding Tax";
        WithholdingTaxes: Report "Withholding Taxes";
    begin
        Clear(WithholdingTaxes);
        WithholdingTax.SetRange("Vendor No.", VendorNo);
        WithholdingTaxes.SetTableView(WithholdingTax);
        WithholdingTaxes.Run();
    end;

    local procedure RunSuggestVendorBillsForVendorNo(VendorBillHeader: Record "Vendor Bill Header"; VendorNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SuggestVendorBills: Report "Suggest Vendor Bills";
    begin
        SuggestVendorBills.InitValues(VendorBillHeader);
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        SuggestVendorBills.SetTableView(VendorLedgerEntry);
        SuggestVendorBills.UseRequestPage(false);
        SuggestVendorBills.RunModal();
    end;

    local procedure RunCreatePayment(var VendorLedgerEntry: Record "Vendor Ledger Entry"; GenJournalBatch: Record "Gen. Journal Batch")
    var
        CreatePayment: Page "Create Payment";
    begin
        LibraryVariableStorage.Enqueue(GenJournalBatch."Journal Template Name");
        LibraryVariableStorage.Enqueue(GenJournalBatch.Name);

        CreatePayment.RunModal();
        CreatePayment.MakeGenJnlLines(VendorLedgerEntry);
        CreatePayment.Close();
    end;

    local procedure PostPaymentJournalWithPage(GenJournalBatchName: Code[10]; AccountNo: Code[20])
    var
        PaymentJournal: TestPage "Payment Journal";
    begin
        PaymentJournal.OpenEdit();
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalBatchName);
        PaymentJournal.FILTER.SetFilter("Account No.", AccountNo);
        PaymentJournal.Post.Invoke();
        PaymentJournal.OK().Invoke();
    end;

    local procedure ShowComputedWithholdContributionOnPayment(JnlBatchName: Code[10])
    var
        PaymentJournal: TestPage "Payment Journal";
    begin
        PaymentJournal.OpenEdit();
        PaymentJournal.CurrentJnlBatchName.SetValue(JnlBatchName);
        PaymentJournal.Last();
        PaymentJournal.WithhTaxSocSec.Invoke();  // Invoke Handler - ShowComputedWithholdContribModalPageHandler.
        PaymentJournal.Close();
    end;

    local procedure SetValuesOnManualVendorPaymentLinePage(var ManualVendorPaymentLine: TestPage "Manual vendor Payment Line")
    var
        VendorBillCard: TestPage "Vendor Bill Card";
    begin
        VendorBillCard.OpenEdit();
        ManualVendorPaymentLine.Trap();
        VendorBillCard.FILTER.SetFilter("No.", CreateVendorBillHeader());
        VendorBillCard.InsertVendBillLineManual.Invoke();
        ManualVendorPaymentLine.VendorNo.SetValue(CreateVendor('', ''));  // Blank Social Security Code, INAIL Code.
        ManualVendorPaymentLine.TotalAmount.SetValue(LibraryRandom.RandDecInRange(100, 1000, 2));
        ManualVendorPaymentLine.TaxBaseAmount.SetValue(LibraryRandom.RandDecInRange(50, 100, 2));
    end;

    local procedure SocialSecurityCodeLookupOnVendorCard(No: Code[20])
    var
        VendorCard: TestPage "Vendor Card";
    begin
        OpenVendorCard(VendorCard, No);
        VendorCard."Social Security Code".Lookup();
        VendorCard.OK().Invoke();
    end;

    local procedure UpdateAppliesToDocOnPurchaseHeader(var PurchaseHeader: Record "Purchase Header"; DocumentNo: Code[20]; AppliesToDocNo: Code[20])
    begin
        PurchaseHeader.Get(PurchaseHeader."Document Type"::"Credit Memo", DocumentNo);
        PurchaseHeader.Validate("Applies-to Doc. Type", PurchaseHeader."Applies-to Doc. Type"::Invoice);
        PurchaseHeader.Validate("Applies-to Doc. No.", AppliesToDocNo);
        PurchaseHeader.Modify(true);
    end;

    local procedure UpdateAmountOnGenJournalLine(var GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine.Validate(Amount, LibraryRandom.RandDec(10, 2));
        GenJournalLine.Modify(true);
    end;

    local procedure UpdateBlankPaymentMethodCodeOnVendor(No: Code[20])
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(No);
        Vendor.Validate("Payment Method Code", '');
        Vendor.Modify(true);
    end;

    local procedure VerifyVendorBillLineAmtToPayAndSocSecAmt(PurchWithhContribution: Record "Purch. Withh. Contribution"; VendorBillHeaderNo: Code[20]; TotalAmtInclVAT: Decimal)
    var
        VendorBillLine: Record "Vendor Bill Line";
    begin
        VendorBillLine.SetRange("Vendor Bill List No.", VendorBillHeaderNo);
        VendorBillLine.FindFirst();
        VendorBillLine.TestField(
          "Amount to Pay",
          TotalAmtInclVAT - PurchWithhContribution."Withholding Tax Amount" - PurchWithhContribution."Free-Lance Amount");
        VendorBillLine.TestField("Social Security Amount", PurchWithhContribution."Total Social Security Amount");
        VendorBillLine.TestField("Withholding Tax Amount", PurchWithhContribution."Withholding Tax Amount");
    end;

    local procedure VerifyVendorBillLineAmtToPayAndSocSecAmtWhtManual(PurchWithhContribution: Record "Purch. Withh. Contribution"; VendorBillHeaderNo: Code[20]; TotalAmtInclVAT: Decimal)
    var
        VendorBillLine: Record "Vendor Bill Line";
        VendorBillWithholdingTax: Record "Vendor Bill Withholding Tax";
    begin
        VendorBillLine.SetRange("Vendor Bill List No.", VendorBillHeaderNo);
        VendorBillLine.FindFirst();
        VendorBillLine.TestField("Gross Amount to Pay", TotalAmtInclVAT);
        VendorBillLine.TestField("Social Security Amount", PurchWithhContribution."Total Social Security Amount");
        VendorBillWithholdingTax.Get(VendorBillLine."Vendor Bill List No.", VendorBillLine."Line No.");
        VendorBillWithholdingTax.TestField("Withholding Tax Amount", PurchWithhContribution."WHT Amount Manual");
    end;

    local procedure VerifyContributions(SocialSecurityCode: Code[20]; INAILCode: Code[20]; SocialSecurityPct: Decimal; INAILFreeLancePct: Decimal)
    var
        Contributions: Record Contributions;
    begin
        Contributions.SetRange("Social Security Code", SocialSecurityCode);
        Contributions.SetRange("INAIL Code", INAILCode);
        Contributions.FindFirst();
        Contributions.TestField("Social Security %", SocialSecurityPct);
        Contributions.TestField("INAIL Free-Lance %", INAILFreeLancePct);
    end;

    local procedure VerifyGLEntryAmount(DocumentNo: Code[20]; GLAccountNo: Code[20]; DebitAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindFirst();
        Assert.AreNearlyEqual(DebitAmount, GLEntry."Debit Amount", LibraryERM.GetAmountRoundingPrecision(), ValueMustBeSameMsg);
    end;

    local procedure VerifyGenJournalLine(No: Code[20]; JournalTemplateName: Code[10]; JournalBatchName: Code[10]; DebitAmount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        WithholdCode: Record "Withhold Code";
    begin
        Vendor.Get(No);
        WithholdCode.Get(Vendor."Withholding Tax Code");
        FindGenJournalLine(
          GenJournalLine, JournalTemplateName, JournalBatchName,
          GenJournalLine."Bal. Account Type"::"G/L Account", WithholdCode."Withholding Taxes Payable Acc.");
        GenJournalLine.TestField("Debit Amount", DebitAmount);
    end;

    local procedure VerifyINAILCodeOnVendor(No: Code[20]; INAILCode: Code[20])
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(No);
        Vendor.TestField("INAIL Code", INAILCode);
    end;

    local procedure VerifyAmountToPayAndWithholdingTaxAmount(VendorNo: Code[20]; AmountToPay: Decimal; WithholdingTaxAmount: Decimal)
    var
        SubformVendorBillLines: TestPage "Subform Vendor Bill Lines";
    begin
        SubformVendorBillLines.OpenEdit();
        SubformVendorBillLines.FILTER.SetFilter("Vendor No.", VendorNo);
        Assert.AreNearlyEqual(
          AmountToPay, SubformVendorBillLines."Amount to Pay".AsDecimal(), LibraryERM.GetAmountRoundingPrecision(), ValueMustBeSameMsg);
        Assert.AreNearlyEqual(
          WithholdingTaxAmount, SubformVendorBillLines."Withholding Tax Amount".AsDecimal(), LibraryERM.GetAmountRoundingPrecision(),
          ValueMustBeSameMsg);
    end;

    local procedure VerifyTaxOnWithholdTaxesContributionCardPage(WithhTaxesContributionCard: TestPage "Withh. Taxes-Contribution Card"; AmountIncludingVAT: Decimal; LineAmount: Decimal; TaxableBase: Decimal; WithholdingTaxAmount: Decimal)
    begin
        WithhTaxesContributionCard."Payable Amount".AssertEquals(AmountIncludingVAT - WithholdingTaxAmount);
        WithhTaxesContributionCard."Withholding Tax Amount".AssertEquals(WithholdingTaxAmount);
        WithhTaxesContributionCard."Taxable Base".AssertEquals(TaxableBase);
        WithhTaxesContributionCard."Non Taxable Amount".AssertEquals(LineAmount - TaxableBase);
        WithhTaxesContributionCard.OK().Invoke();
    end;

    local procedure VerifySocialSecurityCodeOnVendor(No: Code[20]; SocialSecurityCode: Code[20])
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(No);
        Vendor.TestField("Social Security Code", SocialSecurityCode);
    end;

    local procedure VerifyTaxValueOnCertificationsReport(NonTaxableAmount: Decimal; TaxableBase: Decimal; WithholdingTaxAmount: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(NonTaxableAmountCap, NonTaxableAmount);
        LibraryReportDataset.AssertElementWithValueExists(TaxableBaseCap, TaxableBase);
        LibraryReportDataset.AssertElementWithValueExists(WithholdingTaxAmountCap, WithholdingTaxAmount);
    end;

    local procedure VerifyWithholdingTax(VendorNo: Code[20]; NonTaxableAmount: Decimal; TaxableBase: Decimal; WithholdingTaxAmount: Decimal)
    var
        WithholdingTax: Record "Withholding Tax";
    begin
        FindWithholdingTax(WithholdingTax, VendorNo);
        Assert.AreNearlyEqual(
          NonTaxableAmount, WithholdingTax."Non Taxable Amount", LibraryERM.GetAmountRoundingPrecision(), ValueMustBeSameMsg);
        Assert.AreNearlyEqual(TaxableBase, WithholdingTax."Taxable Base", LibraryERM.GetAmountRoundingPrecision(), ValueMustBeSameMsg);
        Assert.AreNearlyEqual(
          WithholdingTaxAmount, WithholdingTax."Withholding Tax Amount", LibraryERM.GetAmountRoundingPrecision(), ValueMustBeSameMsg);
        Assert.AreEqual(
          GetExternalDocNoFromPostedInvoice(VendorNo),
          WithholdingTax."External Document No.",
          'WithholdingTax."External Document No."');
    end;

    local procedure VerifyAmountInVendorLedgerEntry(DocType: Enum "Gen. Journal Document Type"; VendorNo: Code[20];
                                                                 BalAccType: Enum "Gen. Journal Account Type";
                                                                 BalAccNo: Code[20];
                                                                 ExpectedAmount: Decimal)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("Document Type", DocType);
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.SetRange("Bal. Account Type", BalAccType);
        VendorLedgerEntry.SetRange("Bal. Account No.", BalAccNo);
        VendorLedgerEntry.FindFirst();
        VendorLedgerEntry.CalcFields(Amount);
        VendorLedgerEntry.TestField(Amount, ExpectedAmount);
    end;

    local procedure VerifyTmpWithholdingContributionNotEmpty(DocumentNo: Code[20])
    var
        TmpWithholdingContribution: Record "Tmp Withholding Contribution";
    begin
        TmpWithholdingContribution.Init();
        TmpWithholdingContribution.SetRange("Invoice No.", DocumentNo);
        Assert.RecordIsNotEmpty(TmpWithholdingContribution);
    end;

    local procedure VerifyTmpWithholdingContributionEmpty(DocumentNo: Code[20])
    var
        TmpWithholdingContribution: Record "Tmp Withholding Contribution";
    begin
        TmpWithholdingContribution.Init();
        TmpWithholdingContribution.SetRange("Invoice No.", DocumentNo);
        Assert.RecordIsEmpty(TmpWithholdingContribution);
    end;

    local procedure VerifyTmpWithholdingContribution_SocSecValues(TmpWithholdingContribution: Record "Tmp Withholding Contribution"; GrossAmount: Decimal; SocSecNonTaxableAmount: Decimal)
    begin
        TmpWithholdingContribution.TestField("Gross Amount", GrossAmount);
        TmpWithholdingContribution.TestField("Soc.Sec.Non Taxable Amount", SocSecNonTaxableAmount);
        TmpWithholdingContribution.TestField("Contribution Base", TmpWithholdingContribution."Gross Amount" - TmpWithholdingContribution."Soc.Sec.Non Taxable Amount");
        TmpWithholdingContribution.TestField("Total Social Security Amount", Round(TmpWithholdingContribution."Contribution Base" * TmpWithholdingContribution."Social Security %" / 100));
        TmpWithholdingContribution.TestField("Free-Lance Amount", Round(TmpWithholdingContribution."Total Social Security Amount" * TmpWithholdingContribution."Free-Lance %" / 100));
        TmpWithholdingContribution.TestField("Company Amount", TmpWithholdingContribution."Total Social Security Amount" - TmpWithholdingContribution."Free-Lance Amount");
    end;

    local procedure VerifyPurchWithContribution(PurchaseHeader: Record "Purchase Header"; InvoiceAmount: Decimal; BracketAmount: Decimal)
    var
        PurchWithhContribution: Record "Purch. Withh. Contribution";
    begin
        PurchWithhContribution.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        Assert.AreEqual(BracketAmount - InvoiceAmount, PurchWithhContribution."Soc.Sec.Non Taxable Amount", PurchWithhContributionErr);
    end;

    local procedure VerifyOptionInOptionString(TableID: Integer; FieldID: Integer; OptionToVerify: Text)
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
        CurOption: Text;
        OptionSet: Text;
        CommaPos: Integer;
        Found: Boolean;
    begin
        RecRef.Open(TableID);
        FieldRef := RecRef.Field(FieldID);
        OptionSet := FieldRef.OptionString;
        repeat
            CommaPos := StrPos(OptionSet, ',');
            if CommaPos = 0 then
                CurOption := OptionSet
            else begin
                CurOption := CopyStr(OptionSet, 1, CommaPos - 1);
                OptionSet := CopyStr(OptionSet, CommaPos + 1, StrLen(OptionSet) - CommaPos);
            end;
            Found := CurOption = OptionToVerify;
        until Found or (OptionSet = '');
        Assert.IsTrue(Found,
          StrSubstNo('Not possible to find option %1 in field %2 of table %3 with option string %4',
            OptionToVerify, TableID, FieldID, FieldRef.OptionString));
    end;

    local procedure VerifyGenJournalLineWithoutWHTAmount(GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalLine2: Record "Gen. Journal Line";
    begin
        GenJournalLine2.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        GenJournalLine2.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJournalLine2.SetRange("System-Created Entry", true);
        GenJournalLine2.SetRange("Applies-to Doc. No.", GenJournalLine."Applies-to Doc. No.");
        GenJournalLine2.FindFirst();
        Assert.AreEqual(0, GenJournalLine2.Amount, 'Amount in this line must be 0');
    end;

    local procedure VerifyWithhTaxAndContribExternalDocNo(VendorNo: Code[20]; ExternalDocNo: Code[35]);
    var
        WithholdingTax: Record "Withholding Tax";
        Contributions: Record Contributions;
    begin
        FindWithholdingTax(WithholdingTax, VendorNo);
        WithholdingTax.TestField("External Document No.", ExternalDocNo);

        FindContributions(Contributions, VendorNo);
        Contributions.TestField("External Document No.", ExternalDocNo);
    end;

    local procedure CreateAndPostGenJnlLineWithAppliesToDoc(
        DocumentType: Enum "Gen. Journal Document Type";
        AppliesToDocNo: Code[20];
        AppliesToDocType: Enum "Gen. Journal Document Type";
        PostingDate: Date)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateAndApplyGeneralJnlLine(GenJournalLine, DocumentType, AppliesToDocNo, AppliesToDocType);
        GenJournalLine.Validate("Posting Date", PostingDate);
        ShowComputedWithholdContributionOnPayment(GenJournalLine."Journal Batch Name");
        VerifyTmpWithholdingContributionNotEmpty(AppliesToDocNo);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure VerifyValueOnWithholdTaxesContributionCardPage(WithhTaxesContributionCard: TestPage "Withh. Taxes-Contribution Card")
    var
        PayableAmttxt: Text;
        PayableAmt: Decimal;
    begin
        PayableAmttxt := WithhTaxesContributionCard."Payable Amount".Value();
        Evaluate(PayableAmt, PayableAmttxt);
        Assert.AreNotEqual(0, PayableAmt, '');
        WithhTaxesContributionCard.OK().Invoke();
    end;

    local procedure CreateVendorWithPaymentMethodAndWithHoldCodeWithLine(var Vendor: Record Vendor)
    var
        PaymentMethod: Record "Payment Method";
    begin
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        PaymentMethod.Validate("Bill Code", CreateBill());
        PaymentMethod.Modify(true);
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Payment Method Code", PaymentMethod.Code);
        Vendor.Validate("Withholding Tax Code", CreateWithholdCodeWithLine());
        Vendor.Modify(true);
    end;

    local procedure CreatePurchaseInvoice(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; VendorNo: Code[20])
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine,
            PurchaseHeader,
            PurchaseLine.Type::"G/L Account",
            LibraryERM.CreateGLAccountWithSalesSetup(),
            LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(1000));
        PurchaseLine.Modify(true);
        PurchaseHeader.Validate("Check Total", PurchaseLine."Amount Including VAT");
        PurchaseHeader.Modify(true);
    end;

    local procedure OpenPurchaseInvoiceAndPerformWithHoldTaxesSocialSecurity(var PurchaseInvoice: TestPage "Purchase Invoice"; PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GoToRecord(PurchaseHeader);
        PurchaseInvoice."With&hold Taxes-Soc. Sec.".Invoke();
    end;

    local procedure CalculateWithholdTaxesContributionOnPurchInvoicewithBaseExcludeAmount(var PurchaseInvoice: TestPage "Purchase Invoice"; No: Code[20]; LineAmount: Decimal)
    var
        WithhTaxesContributionCard: TestPage "Withh. Taxes-Contribution Card";
    begin
        PurchaseInvoice.Trap();
        WithhTaxesContributionCard.OpenEdit();
        WithhTaxesContributionCard.Filter.SetFilter("No.", No);
        WithhTaxesContributionCard.TotalAmount.SetValue(LineAmount);
        WithhTaxesContributionCard."Base - Excluded Amount".SetValue(LineAmount);
        WithhTaxesContributionCard.Close();
    end;

    local procedure CreateBillPostingGroup(PaymentMethodCode: Code[10]): Code[20]
    var
        BankAccount: Record "Bank Account";
        BillPostingGroup: Record "Bill Posting Group";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        LibraryITLocalization.CreateBillPostingGroup(BillPostingGroup, BankAccount."No.", PaymentMethodCode);
        BillPostingGroup.Validate("Bills For Collection Acc. No.", LibraryERM.CreateGLAccountNo());
        BillPostingGroup.Validate("Bills For Discount Acc. No.", BillPostingGroup."Bills For Collection Acc. No.");
        BillPostingGroup.Modify(true);

        exit(BillPostingGroup."No.");
    end;

    local procedure CreateVendorBill(var VendorBillHeader: Record "Vendor Bill Header"; No: Code[20]; DocumentNo: Code[20])
    var
        BillPostingGroup: Record "Bill Posting Group";
    begin
        FindBillPostingGroup(BillPostingGroup, No);
        LibraryITLocalization.CreateVendorBillHeader(VendorBillHeader);
        VendorBillHeader.Validate("Bank Account No.", BillPostingGroup."No.");
        VendorBillHeader.Validate("Payment Method Code", BillPostingGroup."Payment Method");
        VendorBillHeader.Modify(true);
        RunSuggestVendorBills(VendorBillHeader, DocumentNo);
    end;

    local procedure CreateBill(): Code[20]
    var
        Bill: Record Bill;
    begin
        LibraryITLocalization.CreateBill(Bill);
        Bill.Validate("Allow Issue", true);
        Bill.Validate("Bills for Coll. Temp. Acc. No.", LibraryERM.CreateGLAccountNo());
        Bill.Validate("List No.", LibraryERM.CreateNoSeriesSalesCode());
        Bill.Validate("Temporary Bill No.", Bill."List No.");
        Bill.Validate("Final Bill No.", Bill."List No.");
        Bill.Validate("Vendor Bill List", Bill."List No.");
        Bill.Validate("Vendor Bill No.", Bill."List No.");
        Bill.Modify(true);

        exit(Bill.Code);
    end;

    local procedure FindBillPostingGroup(var BillPostingGroup: Record "Bill Posting Group"; No: Code[20])
    begin
        BillPostingGroup.SetRange("No.", No);
        BillPostingGroup.FindFirst();
    end;

    local procedure RunSuggestVendorBills(VendorBillHeader: Record "Vendor Bill Header"; DocumentNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SuggestVendorBills: Report "Suggest Vendor Bills";
    begin
        Clear(SuggestVendorBills);
        VendorLedgerEntry.SetRange("Document No.", DocumentNo);
        SuggestVendorBills.InitValues(VendorBillHeader);
        SuggestVendorBills.SetTableView(VendorLedgerEntry);
        SuggestVendorBills.UseRequestPage(false);
        SuggestVendorBills.Run();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ContributionCodesINAILModalPageHandler(var ContributionCodesINAIL: TestPage "Contribution Codes-INAIL")
    var
        "Code": Variant;
    begin
        LibraryVariableStorage.Dequeue(Code);
        ContributionCodesINAIL.FILTER.SetFilter(Code, Code);
        ContributionCodesINAIL.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ContributionCodesINPSModalPageHandler(var ContributionCodesINPS: TestPage "Contribution Codes-INPS")
    var
        "Code": Variant;
    begin
        LibraryVariableStorage.Dequeue(Code);
        ContributionCodesINPS.FILTER.SetFilter(Code, Code);
        ContributionCodesINPS.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GrossAmountShowComputedWithhContribModalPageHandler(var ShowComputedWithhContrib: TestPage "Show Computed Withh. Contrib.")
    begin
        ShowComputedWithhContrib."Total Amount".SetValue(LibraryRandom.RandDec(10, 2));
        ShowComputedWithhContrib."Gross Amount".AssertEquals(ShowComputedWithhContrib."Total Amount".AsDecimal());
        ShowComputedWithhContrib.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure NewContributionCodesINAILModalPageHandler(var ContributionCodesINAIL: TestPage "Contribution Codes-INAIL")
    begin
        ContributionCodesINAIL.New();
        ContributionCodesINAIL.Code.SetValue(LibraryUtility.GenerateGUID());
        LibraryVariableStorage.Enqueue(ContributionCodesINAIL.Code.Value);
        ContributionCodesINAIL.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure NewContributionCodesINPSModalPageHandler(var ContributionCodesINPS: TestPage "Contribution Codes-INPS")
    begin
        ContributionCodesINPS.New();
        ContributionCodesINPS.Code.SetValue(LibraryUtility.GenerateGUID());
        LibraryVariableStorage.Enqueue(ContributionCodesINPS.Code.Value);
        ContributionCodesINPS.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ShowComputedWithholdContribModalPageHandler(var ShowComputedWithhContrib: TestPage "Show Computed Withh. Contrib.")
    begin
        ShowComputedWithhContrib.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ShowComputedWithhContribModalPageHandler(var ShowComputedWithhContrib: TestPage "Show Computed Withh. Contrib.")
    var
        TotalAmount: Decimal;
    begin
        Evaluate(TotalAmount, ShowComputedWithhContrib."Total Amount".Value);
        ShowComputedWithhContrib."Base - Excluded Amount".SetValue(TotalAmount);
        ShowComputedWithhContrib.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ShowValidateWHTSocSecMPH(var ShowComputedWithhContrib: TestPage "Show Computed Withh. Contrib.");
    begin
        ShowComputedWithhContrib."Total Amount".SetValue(LibraryVariableStorage.DequeueDecimal());
        ShowComputedWithhContrib.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure TaxableValueShowComputedWithholdContribModalPageHandler(var ShowComputedWithhContrib: TestPage "Show Computed Withh. Contrib.")
    var
        NonTaxableAmount: Variant;
        TaxableBase: Variant;
    begin
        LibraryVariableStorage.Dequeue(TaxableBase);
        LibraryVariableStorage.Dequeue(NonTaxableAmount);
        ShowComputedWithhContrib."Taxable Base".AssertEquals(TaxableBase);
        ShowComputedWithhContrib."Non Taxable Amount".AssertEquals(NonTaxableAmount);
        ShowComputedWithhContrib.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure WithholdingTaxesRequestPageHandler(var WithholdingTaxes: TestRequestPage "Withholding Taxes")
    begin
        WithholdingTaxes.FinalPrinting.SetValue(true);
        WithholdingTaxes.PrintDetails.SetValue(false);
        WithholdingTaxes.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CertificationsRequestPageHandler(var Certifications: TestRequestPage Certifications)
    begin
        Certifications.FromPaymentDate.SetValue(WorkDate());
        Certifications.ToPaymentDate.SetValue(WorkDate());
        Certifications.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
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

    [ModalPageHandler]
    procedure CreatePaymentMPH(var CreatePayment: TestPage "Create Payment")
    begin
        CreatePayment."Posting Date".SetValue(WorkDate());
        CreatePayment."Template Name".SetValue(LibraryVariableStorage.DequeueText());
        CreatePayment."Batch Name".SetValue(LibraryVariableStorage.DequeueText());
        CreatePayment."Starting Document No.".SetValue(LibraryUtility.GenerateGUID());
        CreatePayment."Bank Account".SetValue(LibraryERM.CreateBankAccountNo());
        CreatePayment.OK().Invoke();
    end;
}

