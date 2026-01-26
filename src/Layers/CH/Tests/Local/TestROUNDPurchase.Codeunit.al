codeunit 144063 "Test ROUND Purchase"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryCH: Codeunit "Library - CH";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyVATEntriesForPurchaseCreditMemoWithRecalculateLines()
    var
        PurchaseHeader: Record "Purchase Header";
        VATEntry: Record "VAT Entry";
        GLEntry: Record "G/L Entry";
    begin
        VerifyVATEntriesWithRecalculateLines(
          PurchaseHeader."Document Type"::"Credit Memo",
          GLEntry."Document Type"::"Credit Memo",
          VATEntry."Document Type"::"Credit Memo",
          "Purchase Document Type From"::"Posted Credit Memo");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyVATEntriesForPurchaseInvoiceWithRecalculateLines()
    var
        PurchaseHeader: Record "Purchase Header";
        VATEntry: Record "VAT Entry";
        GLEntry: Record "G/L Entry";
    begin
        VerifyVATEntriesWithRecalculateLines(
          PurchaseHeader."Document Type"::Invoice,
          GLEntry."Document Type"::Invoice,
          VATEntry."Document Type"::Invoice,
          "Purchase Document Type From"::"Posted Invoice");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyVATEntriesForPurchaseOrderWithRecalculateLines()
    var
        PurchaseHeader: Record "Purchase Header";
        VATEntry: Record "VAT Entry";
        GLEntry: Record "G/L Entry";
    begin
        VerifyVATEntriesWithRecalculateLines(
          PurchaseHeader."Document Type"::Order,
          GLEntry."Document Type"::Invoice,
          VATEntry."Document Type"::Invoice,
          "Purchase Document Type From"::"Posted Invoice");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyVATEntriesForPurchaseReturnOrderWithRecalculateLines()
    var
        PurchaseHeader: Record "Purchase Header";
        VATEntry: Record "VAT Entry";
        GLEntry: Record "G/L Entry";
    begin
        VerifyVATEntriesWithRecalculateLines(
          PurchaseHeader."Document Type"::"Return Order",
          GLEntry."Document Type"::"Credit Memo",
          VATEntry."Document Type"::"Credit Memo",
          "Purchase Document Type From"::"Posted Credit Memo");
    end;

    [Normal]
    local procedure VerifyVATEntriesWithRecalculateLines(DocumentType: Enum "Purchase Document Type"; GLEntryDocumentType: Enum "Gen. Journal Document Type"; VATEntryDocumentType: Enum "Gen. Journal Document Type"; PostedDocumentType: Enum "Purchase Document Type From")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader1: Record "Purchase Header";
        PurchaseLine1: Record "Purchase Line";
        PurchaseHeader2: Record "Purchase Header";
        PurchaseLine2: Record "Purchase Line";
        DocumentNo1: Code[20];
        DocumentNo2: Code[20];
        VATAmount1: Decimal;
        VATAmount2: Decimal;
        VATAmount: Decimal;
    begin
        Init();

        // Create and post a purchase credit memo
        CreatePurchaseDocument(PurchaseHeader1, PurchaseLine1, DocumentType, PurchaseLine1.Type::"G/L Account");
        VATAmountCalculation(VATAmount1, PurchaseHeader1);
        DocumentNo1 := LibraryPurchase.PostPurchaseDocument(PurchaseHeader1, true, true);

        // Create a second purchase document. Do not post it. Use as a base for copying.
        CreatePurchaseDocument(PurchaseHeader2, PurchaseLine2, DocumentType, PurchaseLine2.Type::"G/L Account");

        // Post the second purchase document.
        LibraryPurchase.CopyPurchaseDocument(PurchaseHeader2, PostedDocumentType, DocumentNo1, false, true);
        VATAmountCalculation(VATAmount2, PurchaseHeader2);
        DocumentNo2 := LibraryPurchase.PostPurchaseDocument(PurchaseHeader2, true, true);

        VATAmount := VATAmount1 + VATAmount2;

        // Validate
        // First see the that G/L entries are OK.
        VerifyGLEntry(DocumentNo2, GLEntryDocumentType, VATAmount);

        // Now verify the VAT Entries
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VerifyVATEntry(
          DocumentNo2, VATAmount, VATEntryDocumentType);
    end;

    local procedure Init()
    begin
        LibraryVariableStorage.Clear();

        if IsInitialized then
            exit;

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        UpdateSetup(LibraryRandom.RandDec(0, 2));

        IsInitialized := true;
    end;

    local procedure UpdateSetup(NewInvRoundPrecision: Decimal)
    var
        GLSetup: Record "General Ledger Setup";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        GLSetup.Get();
        GLSetup.Validate("Inv. Rounding Precision (LCY)", NewInvRoundPrecision);
        GLSetup.Modify(true);
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Invoice Rounding", true);
        PurchasesPayablesSetup.Validate("Ext. Doc. No. Mandatory", false);
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure CreateItem(VATProdPostingGroup: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        exit(Item."No.");
    end;

    local procedure CreateGLAccount(VATProdPostingGroup: Code[20]; VATBusPostingGroup: Code[20]): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.FindGLAccount(GLAccount);

        GLAccount.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        GLAccount.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        exit(GLAccount."No.");
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; LineType: Enum "Purchase Line Type")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        "Code": Code[20];
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");

        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, DocumentType, CreateVendor());

        // Create Purchase Line with Random Quantity and Direct Unit Cost.
        case LineType of
            PurchaseLine.Type::"G/L Account":
                Code := CreateGLAccount(VATPostingSetup."VAT Prod. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
            PurchaseLine.Type::Item:
                Code := CreateItem(VATPostingSetup."VAT Prod. Posting Group");
        end;

        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine,
          PurchaseHeader,
          LineType,
          Code,
          LibraryRandom.RandInt(100));

        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));

        PurchaseLine.Modify(true);
    end;

    [Normal]
    local procedure CreateVendor(): Code[20]
    var
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        Vendor: Record Vendor;
    begin
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryCH.CreateVendor(Vendor, GeneralPostingSetup."Gen. Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        exit(Vendor."No.");
    end;

    [Normal]
    local procedure VATAmountCalculation(var VATAmount: Decimal; PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindFirst();
        VATAmount := PurchaseLine."VAT %" * (-PurchaseLine.Quantity * PurchaseLine."Direct Unit Cost") / 100;

        case PurchaseLine."Document Type" of
            PurchaseLine."Document Type"::Invoice,
          PurchaseLine."Document Type"::Order:
                VATAmount := -VATAmount;
            PurchaseLine."Document Type"::"Credit Memo",
          PurchaseLine."Document Type"::"Return Order":
                VATAmount := VATAmount;
        end;
    end;

    [Normal]
    local procedure VerifyGLEntry(DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; VATAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document Type", DocumentType);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.FindFirst();
        Assert.AreNearlyEqual(
          GLEntry."VAT Amount",
          VATAmount, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo('VAT Amounts are not equal. Expected: %1, Actual: %2', GLEntry."VAT Amount", VATAmount))
    end;

    [Normal]
    local procedure VerifyVATEntry(DocumentNo: Code[20]; VATAmount: Decimal; DocumentType: Enum "Gen. Journal Document Type")
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.SetRange("Document Type", DocumentType);
        VATEntry.SetRange(Type, VATEntry.Type::Purchase);

        VATEntry.FindFirst();

        Assert.AreNearlyEqual(
          VATAmount, VATEntry.Amount, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo('VAT amounts are not equal. Expected: %1, Actual: %2', VATEntry.Amount, VATAmount));
    end;
}

