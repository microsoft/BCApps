codeunit 144004 "Non. Ded. VAT Currency IT"
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
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
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
        CreateNonDeductibleNormalVATPostingSetup(VATPostingSetup);
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 10, 10);
        LibraryERM.SetAddReportingCurrency(CurrencyCode);
        CreateNonDeductibleNormalVATPostingSetup(VATPostingSetup);
        CreatePurchaseInvoice(PurchHeader, PurchLine, VATPostingSetup, '');
        // [WHEN] Post Document
        DocNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);
        // [THEN]
        CalculateNDValues(Base, Amount, NDBase, NDAmount, PurchLine, VATPostingSetup, CurrencyCode, PurchHeader."Posting Date", 1);
        VerifyACYVATEntry(DocNo, PurchHeader."Posting Date", Base, Amount, NDBase, NDAmount);
    end;

    [Test]
    procedure PurchInvWithdFCYAndTwoLines()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        CurrencyCode: Code[10];
        DocNo: Code[10];
        Base: array[2] of Decimal;
        Amount: array[2] of Decimal;
        NDBase: array[2] of Decimal;
        NDAmount: array[2] of Decimal;
    begin
        // [SCENARIO 456471] Stan can post the purchase invoice with foregin currency and two lines
        Initialize();
        CreateNonDeductibleNormalVATPostingSetup(VATPostingSetup);
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 10, 10);
        CreatePurchaseInvoice(PurchHeader, PurchLine, VATPostingSetup, CurrencyCode);
        CalculateNDValues(Base[1], Amount[1], NDBase[1], NDAmount[1], PurchLine, VATPostingSetup, CurrencyCode, PurchHeader."Posting Date", 0.01);
        LibraryPurchase.CreatePurchaseLine(
            PurchLine, PurchHeader, PurchLine.Type::Item,
            LibraryInventory.CreateItemWithVATProdPostingGroup(PurchLine."VAT Prod. Posting Group"), LibraryRandom.RandInt(100));
        PurchLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchLine.Modify(true);
        CalculateNDValues(Base[2], Amount[2], NDBase[2], NDAmount[2], PurchLine, VATPostingSetup, CurrencyCode, PurchHeader."Posting Date", 0.01);
        Base[1] += Base[2];
        Amount[1] += Amount[2];
        NDBase[1] += NDBase[2];
        NDAmount[1] += NDAmount[2];
        // [WHEN] Post Document
        DocNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

        VerifyVATEntry(DocNo, PurchHeader."Posting Date", Base[1], Amount[1], NDBase[1], NDAmount[1]);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Non. Ded. VAT Currency IT");
        LibrarySetupStorage.Restore();
        if isInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Non. Ded. VAT Currency IT");
        LibrarySetupStorage.SaveGeneralLedgerSetup();
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Non. Ded. VAT Currency IT");
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
        VATPostingSetup.Validate("Deductible %", LibraryRandom.RandIntInRange(10, 25));
        VATPostingSetup.Modify(true);
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

    local procedure GetNonDeductibleVATPctFromVATPostingSetup(VATPostingSetup: Record "VAT Posting Setup"): Decimal
    begin
        exit(100 - VATPostingSetup."Deductible %");
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
        VATEntry.TestField("Add. Curr. Nondeductible Base", NDBase);
        VATEntry.TestField("Add. Curr. Nondeductible Amt.", NDAmount);
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
        VATEntry.TestField("Nondeductible Base", NDBase);
        VATEntry.TestField("Nondeductible Amount", NDAmount);
    end;
}