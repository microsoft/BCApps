codeunit 144033 "UT TAB EASINPPINV"
{
    // Test for feature: EASINPPINV - Easy Input for Purchase Invoice.

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Purchases] [UT] [VAT]
    end;

    var
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateDocAmountVATPurchInvoiceHeaderError()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Purpose of the test is to validate  Doc. Amount VAT - Purchase Header Trigger of Table ID - 38 Purchase Header for Document Type Invoice.
        ValidateDocAmountVATPurchaseHeaderScenario(PurchaseHeader."Document Type"::Invoice);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateDocAmountVATPurchCrMemoHeaderError()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Purpose of the test is to validate  Doc. Amount VAT - Purchase Header Trigger of Table ID - 38 Purchase Header for Document Type Credit Memo.
        ValidateDocAmountVATPurchaseHeaderScenario(PurchaseHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateDocAmountInclVATPurchInvoiceHeader()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Purpose of the test is to validate Doc. Amount Incl. VAT - OnValidate Trigger of Table ID - 38 Purchase Header for Document Type Invoice.
        ValidateDocAmountInclVATPurchaseHeaderScenario(PurchaseHeader."Document Type"::Invoice);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateDocAmountInclVATPurchCrMemoHeader()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Purpose of the test is to validate Doc. Amount Incl. VAT - OnValidate Trigger of Table ID - 38 Purchase Header for Document Type Credit Memo.
        ValidateDocAmountInclVATPurchaseHeaderScenario(PurchaseHeader."Document Type"::"Credit Memo")
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VerifyDocAmtInclVATDontUpdateLineAmountOnInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocAmtInclVat: Decimal;
    begin
        // [SCENARIO 465533] Changing "Doc. Amount Incl. VAT", on Purchase Invoice, must not affect "Direct Unit Cost" on purchase invoice lines

        // [GIVEN] Purchase Invoice
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice);
        DocAmtInclVat := PurchaseLine."Amount Including VAT" + LibraryRandom.RandDecInRange(10, 20, 2);

        // [WHEN] Set value in "Doc. Amount Incl. VAT"
        PurchaseHeader.Validate("Doc. Amount Incl. VAT", DocAmtInclVat);

        // [THEN] Verify line amounts are not changed
        PurchaseLine.SetLoadFields("Direct Unit Cost", "Amount Including VAT");
        PurchaseLine.SetRecFilter();
        PurchaseLine.FindFirst();
        Assert.AreNotEqual(DocAmtInclVat, PurchaseLine."Amount Including VAT", 'Line amount including vat has been changed');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VerifyDocAmtInclVATDontUpdateLineAmountOnCrMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocAmtInclVat: Decimal;
    begin
        // [SCENARIO 465533] Changing "Doc. Amount Incl. VAT", on Purchase Credit Memo, must not affect "Direct Unit Cost" on purchase credit memo lines

        // [GIVEN] Purchase Credit Memo
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::"Credit Memo");
        DocAmtInclVat := PurchaseLine."Amount Including VAT" + LibraryRandom.RandDecInRange(10, 20, 2);

        // [WHEN] Set value in "Doc. Amount Incl. VAT"
        PurchaseHeader.Validate("Doc. Amount Incl. VAT", DocAmtInclVat);

        // [THEN] Verify line amounts are not changed
        PurchaseLine.SetLoadFields("Direct Unit Cost", "Amount Including VAT");
        PurchaseLine.SetRecFilter();
        PurchaseLine.FindFirst();
        Assert.AreNotEqual(DocAmtInclVat, PurchaseLine."Amount Including VAT", 'Line amount including vat has been changed');
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"): Decimal
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(),
          LibraryRandom.RandDecInRange(10, 20, 2));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(10, 20, 2));
        PurchaseLine.Validate("Suggested Line", true);
        PurchaseLine.Modify(true);
        exit(PurchaseLine."VAT %");
    end;

    local procedure ValidateDocAmountVATPurchaseHeaderScenario(DocumentType: Enum "Purchase Document Type")
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Setup.
        PurchaseHeader."Document Type" := DocumentType;
        PurchaseHeader."Doc. Amount Incl. VAT" := LibraryRandom.RandDec(10, 2);

        // Exercise: Validate Doc. Amount VAT with more than Doc. Amount Incl. VAT of Purchase Header.
        asserterror PurchaseHeader.Validate("Doc. Amount VAT", PurchaseHeader."Doc. Amount Incl. VAT" + LibraryRandom.RandDec(10, 2));

        // Verify: Verify Expected error code, Actual error: Doc. Amount VAT must not be more than Doc. Amount Incl. VAT.
        Assert.ExpectedErrorCode('Dialog');
    end;

    local procedure ValidateDocAmountInclVATPurchaseHeaderScenario(DocumentType: Enum "Purchase Document Type")
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Currency: Record Currency;
        DocAmountVAT: Decimal;
        DocBaseAmount: Decimal;
        VATPct: Decimal;
    begin
        // Setup: Create Purchase Document.
        Currency.InitRoundingPrecision();
        VATPct := CreatePurchaseDocument(PurchaseHeader, PurchaseLine, DocumentType);

        // Exercise.
        PurchaseHeader.Validate("Doc. Amount Incl. VAT", PurchaseLine."Amount Including VAT");

        // Verify: Verify Doc. Amount VAT on Purchase line. Using calculation formula for DocBaseAmount same as Doc. Amount Incl. VAT - OnValidate Trigger of Table ID - 38 Purchase Header
        DocBaseAmount :=
          Round(
            PurchaseHeader."Doc. Amount Incl. VAT" / (1 + (1 - PurchaseHeader."VAT Base Discount %" / 100) * VATPct / 100),
            Currency."Amount Rounding Precision");
        DocAmountVAT :=
          Round(DocBaseAmount * (1 - PurchaseHeader."VAT Base Discount %" / 100) * VATPct / 100, Currency."Amount Rounding Precision");
        PurchaseHeader.TestField("Doc. Amount VAT", DocAmountVAT);
    end;
}

