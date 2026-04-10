codeunit 134285 "Non-Deductible VAT Post. Basic"
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
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        LibraryNonDeductibleVAT: Codeunit "Library - NonDeductible VAT";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        Assert: Codeunit Assert;
        isInitialized: Boolean;
        AmountErr: Label '%1 must be %2 in %3.';
        EntryDoesNotExistErr: Label '%1 with filters %2 does not exist.';
        WrongValueErr: Label 'Wrong value of field %2 in table %1.';

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvDeductiblePctRandomWithNondeductibleAcc()
    begin
        // Verify that Reverse Charge VAT and Non-deductible reverse charge vat should be split into two different accounts that are Reverse Charge VAT Account and Nondeductible VAT Account with Random Deductible Pct.
        Initialize();
        PurchaseInvoiceWithDeductiblePct(
          LibraryERM.CreateGLAccountWithSalesSetup(), LibraryRandom.RandDecInRange(10, 50, 2));  // Using Random value.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvDeductiblePcthundredWithNondeductibleAcc()
    begin
        // Verify that Reverse Charge VAT and Non-deductible reverse charge vat should be split into two different accounts that are Reverse Charge VAT Account and Nondeductible VAT Account with 100 Deductible Pct.
        Initialize();
        PurchaseInvoiceWithDeductiblePct(LibraryERM.CreateGLAccountWithSalesSetup(), 100);  // Using 100 for Deductible Percent.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvDeductiblePctRandomWithoutNondeductibleAcc()
    begin
        // Verify that Reverse Charge VAT and Non-deductible reverse charge vat should be posted to the Account which is entered in the invoice when Nondeductible VAT Account =<blank> with Random Deductible Pct.
        Initialize();
        PurchaseInvoiceWithDeductiblePct('', LibraryRandom.RandDecInRange(10, 50, 2));  // Using blank value for Nondeductible Account.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvDeductiblePcthundredWithoutNondeductibleAcc()
    begin
        // Verify that Reverse Charge VAT and Non-deductible reverse charge vat should be posted to the Account which is entered in the invoice when Nondeductible VAT Account =<blank> with 100 Deductible Pct.
        Initialize();
        PurchaseInvoiceWithDeductiblePct('', 100);  // Using blank value for Nondeductible Account and 100 for Deductible Percent.
    end;

    local procedure PurchaseInvoiceWithDeductiblePct(GLAccountNo: Code[20]; DeductiblePct: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
        VATEntry: Record "VAT Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        PostedDocumentNo: Code[20];
        Amount: Decimal;
    begin
        // Setup: Update VAT Posting Setup, Create Purchase Invoice.
        UpdateNondeductibleVATAccOnVATPostingSetup(VATPostingSetup, GLAccountNo, DeductiblePct);
        CreatePurchaseInvoice(
          PurchaseLine, VATPostingSetup."VAT Bus. Posting Group", '', PurchaseLine.Type::"G/L Account",
          CreateGLAccount(VATPostingSetup));  // Blank value used for Currency Code.
        Amount :=
          (PurchaseLine."Amount Including VAT" * VATPostingSetup."VAT %") / 100 -
          (PurchaseLine."Amount Including VAT" * VATPostingSetup."VAT %") * (100 - GetDeductibleVATPctFromVATPostingSetup(VATPostingSetup)) / 10000;

        // Exercise.
        PostedDocumentNo := PostPurchaseInvoice(PurchaseLine."Document No.");

        // Verify: Verify GL Entry and VAT for VAT Posting Setup Account.
        VATPostingSetup.Get(VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        VerifyGLEntry(PostedDocumentNo, VATPostingSetup."Purchase VAT Account", Amount);
        VerifyGLEntry(PostedDocumentNo, VATPostingSetup."Reverse Chrg. VAT Acc.", -Amount);
        VerifyVATEntryWithVATPostingSetup(VATEntry,
          PostedDocumentNo, ((PurchaseLine."Amount Including VAT" * GetDeductibleVATPctFromVATPostingSetup(VATPostingSetup)) * VATPostingSetup."VAT %") / 10000,
          (PurchaseLine."Amount Including VAT" * GetDeductibleVATPctFromVATPostingSetup(VATPostingSetup)) / 100);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchNonDeductibleReverseVAT()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchLine: Record "Purchase Line";
        GLEntry: Record "G/L Entry";
        VATEntry: Record "VAT Entry";
        DocNo: Code[20];
    begin
        // Test to verify that 100% Non-Deductible Reverse Charge VAT posted correctly.

        Initialize();
        CreateHundredPctNDReverseChargeVATPostingSetup(VATPostingSetup);
        DocNo := CreatePostPurchInvoiceWithVATSetup(PurchLine, VATPostingSetup);
        VerifyCreditGLEntryExists(
          GLEntry."Document Type"::Invoice, DocNo, VATPostingSetup."Reverse Chrg. VAT Acc.");
        VerifyReverseChargeDeductibleVATEntries(VATEntry."Document Type"::Invoice, DocNo);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Non-Deductible VAT Post. Basic");
        LibrarySetupStorage.Restore();
        if isInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Non-Deductible VAT Post. Basic");
        LibraryNonDeductibleVAT.EnableNonDeductibleVAT();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibrarySetupStorage.Save(Database::"VAT Setup");
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Non-Deductible VAT Post. Basic");
    end;

    local procedure CreatePurchaseInvoice(var PurchaseLine: Record "Purchase Line"; VATBusinessPostingGroup: Code[20]; CurrencyCode: Code[10]; Type: Enum "Purchase Line Type"; No: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice, CreateVendor(VATBusinessPostingGroup, CurrencyCode));
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, Type, No);
    end;

    local procedure CreatePurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; Type: Enum "Purchase Line Type"; No: Code[20])
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Type, No, LibraryRandom.RandDec(10, 2));  // Use Random Decimal Quantity.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseLine(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; Type: Enum "Purchase Line Type"; No: Code[20]; Quantity: Decimal; DirectUnitCost: Decimal)
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Type, No, Quantity);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePostPurchInvoiceWithVATSetup(var PurchLine: Record "Purchase Line"; VATPostingSetup: Record "VAT Posting Setup"): Code[20]
    var
        GLAccount: Record "G/L Account";
        PurchHeader: Record "Purchase Header";
        GLAccNo: Code[20];
    begin
        LibraryPurchase.CreatePurchHeader(
          PurchHeader, PurchHeader."Document Type"::Invoice, CreateVendor(VATPostingSetup."VAT Bus. Posting Group"));
        GLAccNo :=
          CreateGLAccount(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase);
        CreatePurchaseLine(
          PurchHeader, PurchLine, PurchLine.Type::"G/L Account", GLAccNo,
          LibraryRandom.RandInt(10), LibraryRandom.RandDec(100, 2));
        exit(LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true));
    end;

    local procedure CreateVendor(VATBusPostingGroup: Code[20]; CurrencyCode: Code[10]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATBusPostingGroup));
        Vendor.Validate("Currency Code", CurrencyCode);
        Vendor.Modify(true);
        exit(Vendor."No.");
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

    local procedure CreateGLAccount(VATPostingSetup: Record "VAT Posting Setup"): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        exit(LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase));
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

    local procedure CreateHundredPctNDReverseChargeVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Bus. Posting Group", VATProductPostingGroup.Code);
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
        VATPostingSetup.Validate("VAT %", LibraryRandom.RandInt(10));
        AssignDeductibleVATPct(VATPostingSetup, 0);
        VATPostingSetup.Validate("Purchase VAT Account", CreateSimpleGLAccount());
        VATPostingSetup.Validate("Reverse Chrg. VAT Acc.", CreateSimpleGLAccount());
        VATPostingSetup.Validate("Sales VAT Account", CreateSimpleGLAccount());
        AssignNonDeductibleVATAccount(VATPostingSetup, CreateSimpleGLAccount());
        VATPostingSetup.Modify(true);
    end;

    local procedure UpdateNondeductibleVATAccOnVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; GLAccountNo: Code[20]; DeductiblePct: Decimal)
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT", LibraryRandom.RandIntInRange(10, 30));
        VATPostingSetup.Get(VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        AssignNonDeductibleVATAccount(VATPostingSetup, GLAccountNo);
        VATPostingSetup.Validate("Reverse Chrg. VAT Acc.", LibraryERM.CreateGLAccountNo());
        AssignDeductibleVATPct(VATPostingSetup, DeductiblePct);
        VATPostingSetup.Modify(true);
    end;

    local procedure CreateSimpleGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        exit(GLAccount."No.");
    end;

    local procedure AssignDeductibleVATPct(var VATPostingSetup: Record "VAT Posting Setup"; DedVATPct: Decimal)
    begin
        LibraryNonDeductibleVAT.SetAllowNonDeductibleVATForVATPostingSetup(VATPostingSetup);
        VATPostingSetup.Validate("Non-Deductible VAT %", 100 - DedVATPct);
    end;

    local procedure AssignNonDeductibleVATAccount(var VATPostingSetup: Record "VAT Posting Setup"; GLAccNo: Code[20])
    begin
        LibraryNonDeductibleVAT.SetAllowNonDeductibleVATForVATPostingSetup(VATPostingSetup);
        VATPostingSetup.Validate("Non-Ded. Purchase VAT Account", GLAccNo);
    end;

    local procedure GetDeductibleVATPctFromVATPostingSetup(VATPostingSetup: Record "VAT Posting Setup"): Decimal
    begin
        exit(100 - VATPostingSetup."Non-Deductible VAT %");
    end;

    local procedure PostPurchaseInvoice(No: Code[20]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.Get(PurchaseHeader."Document Type"::Invoice, No);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure VerifyGLEntry(DocumentNo: Code[20]; GLAccountNo: Code[20]; Amount2: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindFirst();
        Assert.AreNearlyEqual(
          Amount2, GLEntry.Amount, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountErr, GLEntry.FieldCaption(Amount), Amount2, GLEntry.TableCaption()));
    end;

    local procedure VerifyVATEntryWithVATPostingSetup(var VATEntry: Record "VAT Entry"; DocumentNo: Code[20]; Amount: Decimal; Amount2: Decimal)
    begin
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.FindFirst();
        Assert.AreNearlyEqual(
          Amount2, VATEntry.Base, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountErr, VATEntry.FieldCaption(Base), Amount2, VATEntry.TableCaption()));
        Assert.AreNearlyEqual(
          Amount, VATEntry.Amount, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountErr, VATEntry.FieldCaption(Amount), Amount, VATEntry.TableCaption()));
    end;

    local procedure VerifyCreditGLEntryExists(DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20]; GLAccNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document Type", DocType);
        GLEntry.SetRange("Document No.", DocNo);
        GLEntry.SetRange("G/L Account No.", GLAccNo);
        Assert.IsTrue(GLEntry.FindFirst(), StrSubstNo(EntryDoesNotExistErr, GLEntry.TableCaption(), GLEntry.GetFilters));
        Assert.AreEqual(Abs(GLEntry.Amount), GLEntry."Credit Amount", StrSubstNo(WrongValueErr, GLEntry.TableCaption(), GLEntry.FieldCaption("Credit Amount")));
    end;

    local procedure VerifyReverseChargeDeductibleVATEntries(DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20])
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document Type", DocType);
        VATEntry.SetRange("Document No.", DocNo);
        VATEntry.SetRange(Type, VATEntry.Type::Purchase);
        VATEntry.FindFirst();
        Assert.AreEqual(0, VATEntry.Base, StrSubstNo(WrongValueErr, VATEntry.TableCaption(), VATEntry.FieldCaption(Base)));
        Assert.AreEqual(0, VATEntry.Amount, StrSubstNo(WrongValueErr, VATEntry.TableCaption(), VATEntry.FieldCaption(Amount)));
        Assert.IsTrue(
          VATEntry."Non-Deductible VAT Base" <> 0, StrSubstNo(WrongValueErr, VATEntry.TableCaption(), VATEntry.FieldCaption("Non-Deductible VAT Base")));
        Assert.IsTrue(
          VATEntry."Non-Deductible VAT Amount" <> 0, StrSubstNo(WrongValueErr, VATEntry.TableCaption(), VATEntry.FieldCaption("Non-Deductible VAT Amount")));
    end;
}