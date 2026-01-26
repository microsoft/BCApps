codeunit 144000 "ERM VAT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Purchase] [VAT]
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        AmountError: Label '%1 must be %2 in %3.', Comment = '%1 = Amount FieldCaption, %2 = Amount Value, %3 = Record TableCaption';

    [Test]
    [Scope('OnPrem')]
    procedure VATEntriesAfterPostPurchaseOrder()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GeneralPostingSetup: Record "General Posting Setup";
        DocumentNo: Code[20];
    begin
        // Test to validate Amount in G/L entry and VAT Entry after post Purchase Order with VAT.

        // Setup: Create Purchase Order with VAT.
        Initialize();
        CreateVatPostingSetup(VATPostingSetup);
        CreatePurchaseDocument(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, CreateVendor(VATPostingSetup."VAT Bus. Posting Group"),
          CreateItem(VATPostingSetup."VAT Prod. Posting Group"));
        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");

        // Exercise: Post Purchase order and Calculate VAT Amount.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Amount in G/L Entry and VAT Entry.
        VerifyVATAmountOnGLEntry(
          DocumentNo, PurchaseLine."Document Type"::Invoice, GeneralPostingSetup."Purch. Account",
          -PurchaseLine.Quantity * PurchaseLine."Direct Unit Cost");
        VerifyVATAmountOnGLEntry(
          DocumentNo, PurchaseLine."Document Type"::Invoice, VATPostingSetup."Purch. VAT Unreal. Account",
          -PurchaseLine.Quantity * PurchaseLine."Direct Unit Cost" * PurchaseLine."VAT %" / 100);
        VerifyVATEntry(DocumentNo, PurchaseLine."Document Type"::Invoice, 0, 0);  // Verify 0 value in Base and Amount field of VAT Entry for Posted Purchase Order.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATEntriesAfterPostPurchaseCreditMemo()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GeneralPostingSetup: Record "General Posting Setup";
        DocumentNo: Code[20];
    begin
        // Test to validate Amount in G/L Entry and VAT Entry after post Purchase Credit Memo with VAT.

        // Setup: Create Purchase Order with VAT.
        Initialize();
        CreateVatPostingSetup(VATPostingSetup);
        CreatePurchaseDocument(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::"Credit Memo",
          CreateVendor(VATPostingSetup."VAT Bus. Posting Group"), CreateItem(VATPostingSetup."VAT Prod. Posting Group"));
        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");

        // Exercise: Post Purchase Credit Memo and Calculate VAT Amount.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify:  Amount in G/L Entry and VAT Entry.
        VerifyVATAmountOnGLEntry(
          DocumentNo, PurchaseLine."Document Type"::"Credit Memo", GeneralPostingSetup."Purch. Account",
          PurchaseLine.Quantity * PurchaseLine."Direct Unit Cost");
        VerifyVATAmountOnGLEntry(
          DocumentNo, PurchaseLine."Document Type"::"Credit Memo", VATPostingSetup."Purch. VAT Unreal. Account",
          PurchaseLine.Quantity * PurchaseLine."Direct Unit Cost" * PurchaseLine."VAT %" / 100);
        VerifyVATEntry(DocumentNo, PurchaseLine."Document Type"::"Credit Memo", 0, 0);   // Verify 0 value in Base and Amount field of VAT Entry for Posted Purchase Credit Memo.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATEntriesAfterPostPurchaseApplication()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        GLEntry: Record "G/L Entry";
        SourceCodeSetup: Record "Source Code Setup";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VATAmount: Decimal;
        DocumentNo: Code[20];
        VendorNo: Code[20];
        ItemNo: Code[20];
    begin
        // Test to Amount in G/L Entry and VAT Entry after post Purchase application.

        // Create and Post Purchase Order and Purchase Credit Memo.
        Initialize();
        SourceCodeSetup.Get();
        CreateVatPostingSetup(VATPostingSetup);
        VendorNo := CreateVendor(VATPostingSetup."VAT Bus. Posting Group");
        ItemNo := CreateItem(VATPostingSetup."VAT Prod. Posting Group");
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, VendorNo, ItemNo);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine2, PurchaseHeader."Document Type"::"Credit Memo", VendorNo, ItemNo);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Exercise: Apply and post Purchase application.
        ApplyAndPostVendorEntry(VendorLedgerEntry."Document Type"::Invoice, DocumentNo);
        VATAmount := PurchaseLine.Quantity * PurchaseLine."Direct Unit Cost" * PurchaseLine."VAT %" / 100;

        // Verify: Amount in G/L Entry and VAT Entry.
        VerifyVATAmountForPostApplication(
          VATPostingSetup."Purchase VAT Account", GLEntry."Gen. Posting Type"::Purchase,
          -(PurchaseLine.Quantity * PurchaseLine."Direct Unit Cost" * PurchaseLine."VAT %") / 100,
          SourceCodeSetup."Purchase Entry Application");
        VerifyVATAmountForPostApplication(
          VATPostingSetup."Purch. VAT Unreal. Account", GLEntry."Gen. Posting Type",
          (PurchaseLine.Quantity * PurchaseLine."Direct Unit Cost" * PurchaseLine."VAT %") / 100,
          SourceCodeSetup."Purchase Entry Application");
        VerifyVATEntryForPostApplication(-(PurchaseLine.Quantity * PurchaseLine."Direct Unit Cost"), -VATAmount);
    end;

    local procedure Initialize()
    begin
        UpdateGeneralLedgerSetup(true);
    end;

    local procedure ApplyVendorEntry(var ApplyingVendorLedgerEntry: Record "Vendor Ledger Entry"; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GLRegister: Record "G/L Register";
    begin
        LibraryERM.FindVendorLedgerEntry(ApplyingVendorLedgerEntry, DocumentType, DocumentNo);
        ApplyingVendorLedgerEntry.CalcFields("Remaining Amount");
        LibraryERM.SetApplyVendorEntry(ApplyingVendorLedgerEntry, ApplyingVendorLedgerEntry."Remaining Amount");

        // Find Posted Vendor Ledger Entries.
        GLRegister.FindLast();
        VendorLedgerEntry.SetRange("Entry No.", GLRegister."From Entry No.", GLRegister."To Entry No.");
        VendorLedgerEntry.SetRange("Applying Entry", false);
        VendorLedgerEntry.FindFirst();

        // Set Applies-to ID.
        LibraryERM.SetAppliestoIdVendor(VendorLedgerEntry);
    end;

    local procedure ApplyAndPostVendorEntry(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        ApplyVendorEntry(VendorLedgerEntry, DocumentType, DocumentNo);
        LibraryERM.PostVendLedgerApplication(VendorLedgerEntry);
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

    local procedure CreateVendor(VATBusPostingGroup: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20]; ItemNo: Code[20])
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, LibraryRandom.RandDec(10, 2));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CreateVatPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        GLAccount: Record "G/L Account";
    begin
        FindGLAccount(GLAccount);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.FindVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroup.Code, VATProductPostingGroup.Code);
        VATPostingSetup.Validate("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::Percentage);
        VATPostingSetup.Validate("VAT %", LibraryRandom.RandDec(10, 2));  // Use random value for VAT %.
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.Validate("Sales VAT Account", GLAccount."No.");
        VATPostingSetup.Validate("Sales VAT Unreal. Account", GLAccount."No.");
        VATPostingSetup.Validate("Purchase VAT Account", GLAccount."No.");
        VATPostingSetup.Validate("Purch. VAT Unreal. Account", GLAccount."No.");
        VATPostingSetup.Modify(true);
    end;

    local procedure FindGLAccount(var GLAccount: Record "G/L Account")
    begin
        GLAccount.SetRange("Direct Posting", true);
        GLAccount.SetRange("Reconciliation Account", true);
        GLAccount.FindFirst();
    end;

    local procedure UpdateGeneralLedgerSetup(NewUnrealizedVAT: Boolean) OldUnrealizedVAT: Boolean
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        OldUnrealizedVAT := GeneralLedgerSetup."Unrealized VAT";
        GeneralLedgerSetup."Unrealized VAT" := NewUnrealizedVAT;
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure VerifyVATEntry(DocumentNo: Code[20]; DocumentType: Enum "Purchase Document Type"; Amount: Decimal; VATAmount: Decimal)
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document Type", DocumentType);
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.FindFirst();
        Assert.AreNearlyEqual(
          VATEntry.Base, Amount, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountError, VATEntry.FieldCaption(Base), Amount, VATEntry.TableCaption()));
        Assert.AreNearlyEqual(
          VATEntry.Amount, VATAmount, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountError, VATEntry.FieldCaption(Amount), VATAmount, VATEntry.TableCaption()));
    end;

    local procedure VerifyVATAmountForPostApplication(GLAcountNo: Code[20]; GenPostingType: Enum "General Posting Type"; Amount: Decimal; SourceCode: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("G/L Account No.", GLAcountNo);
        GLEntry.SetRange("Gen. Posting Type", GenPostingType);
        GLEntry.SetRange("Source Code", SourceCode);
        GLEntry.FindFirst();
        Assert.AreNearlyEqual(
          GLEntry.Amount, Amount, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountError, GLEntry.FieldCaption(Amount), Amount, GLEntry.TableCaption()));
    end;

    local procedure VerifyVATEntryForPostApplication(Amount: Decimal; VATAmount: Decimal)
    var
        VATEntry: Record "VAT Entry";
        GLRegister: Record "G/L Register";
    begin
        GLRegister.FindLast();
        VATEntry.SetRange("Entry No.", GLRegister."From VAT Entry No.", GLRegister."To VAT Entry No.");
        VATEntry.FindSet();
        Assert.AreNearlyEqual(
          VATEntry.Base, Amount, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountError, VATEntry.FieldCaption(Base), Amount, VATEntry.TableCaption()));
        Assert.AreNearlyEqual(
          VATEntry.Amount, VATAmount, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountError, VATEntry.FieldCaption(Amount), VATAmount, VATEntry.TableCaption()));
        VATEntry.Next();
        Assert.AreNearlyEqual(
          VATEntry.Base, -Amount, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountError, VATEntry.FieldCaption(Base), -Amount, VATEntry.TableCaption()));
        Assert.AreNearlyEqual(
          VATEntry.Amount, -VATAmount, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountError, VATEntry.FieldCaption(Amount), -VATAmount, VATEntry.TableCaption()));
    end;

    local procedure VerifyVATAmountOnGLEntry(DocumentNo: Code[20]; DocumentType: Enum "Purchase Document Type"; GLAcountNo: Code[20]; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document Type", DocumentType);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAcountNo);
        GLEntry.FindFirst();
        Assert.AreNearlyEqual(
          GLEntry.Amount, -Amount, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountError, GLEntry.FieldCaption(Amount), -Amount, GLEntry.TableCaption()));
    end;
}

