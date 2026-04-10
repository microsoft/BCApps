codeunit 134286 "Non. Ded. VAT Currency"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Non Deductible VAT]
    end;

    var
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        LibraryNonDeductibleVAT: Codeunit "Library - NonDeductible VAT";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryJournals: Codeunit "Library - Journals";
        isInitialized: Boolean;

    [Test]
    procedure BasicPurchInvWithACY()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        CurrencyCode: Code[10];
        DocNo: Code[10];
        Base: Decimal;
        Amount: Decimal;
        NDBase: Decimal;
        NDAmount: Decimal;
    begin
        // [SCENARIO 456471] Stan can post non-deductble VAT purchase invoice with ACY and see the result of posting in GL and VAT entries

        Initialize();
        // [GIVEN] Normal VAT Posting Setup with "VAT %" = 20 and Non-Deductible VAT %" = 10
        CreateNonDeductibleNormalVATPostingSetup(VATPostingSetup);
        // [GIVEN] Additional Currency is turned on. Rate is 10
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 10, 10);
        LibraryERM.SetAddReportingCurrency(CurrencyCode);
        // [GIVEN] Purchase invoice with amount = 1000
        CreatePurchaseInvoice(PurchHeader, PurchLine, VATPostingSetup, '');
        // [WHEN] Post Document
        DocNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);
        // [THEN] VAT Entry has the following values:
        // [THEN] Base ACY = 10000
        // [THEN] Amount ACY = 2000
        // [THEN] "Non-Deductible Base ACY" = 1000
        // [THEN] "Non-Deductible Amount ACY" = 100
        CalculateNDValues(Base, Amount, NDBase, NDAmount, PurchLine, VATPostingSetup, CurrencyCode, PurchHeader."Posting Date", 1);
        VerifyACYVATEntry(DocNo, PurchHeader."Posting Date", Base, Amount, NDBase, NDAmount);
    end;

    [Test]
    procedure PurchInvWithdFCYAndTwoLines()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine1: Record "Purchase Line";
        PurchLine2: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        CurrencyCode: Code[10];
        DocNo: Code[20];
        Base: array[2] of Decimal;
        Amount: array[2] of Decimal;
        NDBase: array[2] of Decimal;
        NDAmount: array[2] of Decimal;
    begin
        // [SCENARIO 456471] Stan can post the purchase invoice with foregin currency and two lines
        Initialize();
        // [GIVEN] Normal VAT Posting Setup with "VAT %" = 20 and Non-Deductible VAT %" = 10
        CreateNonDeductibleNormalVATPostingSetup(VATPostingSetup);
        // [GIVEN] Currency code USD with exchange rate = 10
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 10, 10);
        // [GIVEN] USD Purchase invoice
        CreatePurchaseInvoice(PurchHeader, PurchLine1, VATPostingSetup, CurrencyCode);
        // [GIVEN] First invoice line has amount = 1000
        CalculateNDValues(Base[1], Amount[1], NDBase[1], NDAmount[1], PurchLine1, VATPostingSetup, CurrencyCode, PurchHeader."Posting Date", 0.01);
        // [GIVEN] Second invoice line with the same VAT Identifier has amount = 2000
        LibraryPurchase.CreatePurchaseLine(
            PurchLine2, PurchHeader, PurchLine2.Type::Item,
            LibraryInventory.CreateItemWithVATProdPostingGroup(PurchLine1."VAT Prod. Posting Group"), LibraryRandom.RandInt(100));
        PurchLine2.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchLine2.Modify(true);
        CalculateNDValues(Base[2], Amount[2], NDBase[2], NDAmount[2], PurchLine2, VATPostingSetup, CurrencyCode, PurchHeader."Posting Date", 0.01);
        Base[1] += Base[2];
        Amount[1] += Amount[2];
        NDBase[1] += NDBase[2];
        NDAmount[1] += NDAmount[2];

        // [WHEN] Post Document
        DocNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

        // [THEN] VAT Entry has the following values:
        // [THEN] Base ACY = 10000 + 20000 = 30000
        // [THEN] Amount ACY = 2000 + 4000 = 6000
        // [THEN] "Non-Deductible Base ACY" = 1000 + 2000 = 3000
        // [THEN] "Non-Deductible Amount ACY" = 100 + 200 = 300
        VerifyVATEntry(DocNo, PurchHeader."Posting Date", Base[1], Amount[1], NDBase[1], NDAmount[1]);
    end;

    [Test]
    procedure JournalLineWithFCY()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VATPostingSetup: Record "VAT Posting Setup";
        CurrencyCode: Code[10];
        Base: Decimal;
        Amount: Decimal;
        NDBase: Decimal;
        NDAmount: Decimal;
    begin
        // [SCENARIO 456471] Stan can post the journal line with foregin currency and Non-Deductible VAT
        Initialize();
        // [GIVEN] Normal VAT Posting Setup with "VAT %" = 20 and Non-Deductible VAT %" = 10
        CreateNonDeductibleNormalVATPostingSetup(VATPostingSetup);
        // [GIVEN] Currency code USD with exchange rate = 10
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 10, 10);
        // [GIVEN] USD General Journal Line with amount = 1000
        CreateJournalLineWithFCY(GenJournalLine, VATPostingSetup, CurrencyCode);
        // [GIVEN] First invoice line has amount = 1000
        CalculateNDValues(Base, Amount, NDBase, NDAmount, GenJournalLine, VATPostingSetup, CurrencyCode, GenJournalLine."Posting Date", 0.01);
        // [WHEN] Post Document
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        // [THEN] VAT Entry has the following values:
        // [THEN] Base = 10000
        // [THEN] Amount = 2000
        // [THEN] "Non-Deductible Base LCY" = 1000
        // [THEN] "Non-Deductible Amount LCY" = 100
        VerifyVATEntry(GenJournalLine."Document No.", GenJournalLine."Posting Date", Base, Amount, NDBase, NDAmount);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Non. Ded. VAT Currency");
        LibrarySetupStorage.Restore();
        if isInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Non. Ded. VAT Currency");
        LibrarySetupStorage.SaveGeneralLedgerSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryNonDeductibleVAT.EnableNonDeductibleVAT();
        LibrarySetupStorage.Save(Database::"VAT Setup");
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Non. Ded. VAT Currency");
    end;

    local procedure CreatePurchaseInvoice(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; VATPostingSetup: Record "VAT Posting Setup"; CurrencyCode: Code[10])
    begin
        LibraryPurchase.CreatePurchHeader(
            PurchHeader, PurchHeader."Document Type"::Invoice,
            LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        PurchHeader.Validate("Currency Code", CurrencyCode);
        PurchHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
            PurchLine, PurchHeader, PurchLine.Type::Item,
            LibraryInventory.CreateItemWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"), LibraryRandom.RandInt(100));
        PurchLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchLine.Modify(true);
    end;

    local procedure CreateNonDeductibleNormalVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandIntInRange(10, 25));
        LibraryNonDeductibleVAT.SetAllowNonDeductibleVATForVATPostingSetup(VATPostingSetup);
        VATPostingSetup.Validate("Non-Deductible VAT %", LibraryRandom.RandIntInRange(10, 25));
        VATPostingSetup.Modify(true);
    end;

    local procedure CreateJournalLineWithFCY(var GenJournalLine: Record "Gen. Journal Line"; VATPostingSetup: Record "VAT Posting Setup"; CurrencyCode: Code[10])
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
            GenJournalLine, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account",
            LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, "General Posting Type"::Purchase), LibraryRandom.RandDec(100, 2));
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Modify(true);
    end;

    local procedure CalculateNDValues(var Base: Decimal; var Amount: Decimal; var NDBase: Decimal; var NDAmount: Decimal; PurchLine: Record "Purchase Line"; VATPostingSetup: Record "VAT Posting Setup"; CurrencyCode: Code[10]; PostingDate: Date; AdjustmentFactor: Decimal)
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        CurrencyFactor: Decimal;
    begin
        CurrencyExchangeRate.Get(CurrencyCode, PostingDate);
        CurrencyFactor := CurrencyExchangeRate."Exchange Rate Amount" / CurrencyExchangeRate."Relational Exch. Rate Amount" * AdjustmentFactor;
        Base := Round(PurchLine.Amount * CurrencyFactor);
        Amount := Round((PurchLine."Amount Including VAT" - PurchLine.Amount) * CurrencyFactor);
        NDBase := Round(Base * GetNonDeductibleVATPctFromVATPostingSetup(VATPostingSetup) / 100);
        NDAmount := Round(Amount * GetNonDeductibleVATPctFromVATPostingSetup(VATPostingSetup) / 100);
        Base -= NDBase;
        Amount -= NDAmount;
    end;

    local procedure CalculateNDValues(var Base: Decimal; var Amount: Decimal; var NDBase: Decimal; var NDAmount: Decimal; GenJournalLine: Record "Gen. Journal Line"; VATPostingSetup: Record "VAT Posting Setup"; CurrencyCode: Code[10]; PostingDate: Date; AdjustmentFactor: Decimal)
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        CurrencyFactor: Decimal;
        BaseFCY: Decimal;
        VATAmountFCY: Decimal;
    begin
        CurrencyExchangeRate.Get(CurrencyCode, PostingDate);
        CurrencyFactor := CurrencyExchangeRate."Exchange Rate Amount" / CurrencyExchangeRate."Relational Exch. Rate Amount" * AdjustmentFactor;
        Base := Round(GenJournalLine."Amount (LCY)" / (1 + VATPostingSetup."VAT %" / 100));
        Amount := GenJournalLine."Amount (LCY)" - Base;
        BaseFCY := Round(GenJournalLine.Amount / (1 + VATPostingSetup."VAT %" / 100));
        VATAmountFCY := Round(GenJournalLine.Amount - BaseFCY);
        NDBase := Round(Round(BaseFCY * GetNonDeductibleVATPctFromVATPostingSetup(VATPostingSetup) / 100) * CurrencyFactor);
        NDAmount := Round(VATAmountFCY * GetNonDeductibleVATPctFromVATPostingSetup(VATPostingSetup) / 100 * CurrencyFactor);
        Base -= NDBase;
        Amount -= NDAmount;
    end;

    local procedure GetNonDeductibleVATPctFromVATPostingSetup(VATPostingSetup: Record "VAT Posting Setup"): Decimal
    begin
        exit(VATPostingSetup."Non-Deductible VAT %");
    end;

    local procedure VerifyACYVATEntry(DocumentNo: Code[20]; PostingDate: Date; Base: Decimal; Amount: Decimal; NDBase: Decimal; NDAmount: Decimal)
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.SetRange("Posting Date", PostingDate);
        VATEntry.FindFirst();
        VATEntry.TestField("Additional-Currency Base", Base);
        VATEntry.TestField("Additional-Currency Amount", Amount);
        VATEntry.TestField("Non-Deductible VAT Base ACY", NDBase);
        VATEntry.TestField("Non-Deductible VAT Amount ACY", NDAmount);
    end;

    local procedure VerifyVATEntry(DocumentNo: Code[20]; PostingDate: Date; Base: Decimal; Amount: Decimal; NDBase: Decimal; NDAmount: Decimal)
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.SetRange("Posting Date", PostingDate);
        VATEntry.FindFirst();
        VATEntry.TestField(Base, Base);
        VATEntry.TestField(Amount, Amount);
        VATEntry.TestField("Non-Deductible VAT Base", NDBase);
        VATEntry.TestField("Non-Deductible VAT Amount", NDAmount);
    end;
}