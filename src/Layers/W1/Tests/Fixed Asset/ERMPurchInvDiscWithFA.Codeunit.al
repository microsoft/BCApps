codeunit 134913 "ERM Purch Inv Disc With FA"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Fixed Asset] [Invoice Discount] [Purchase]
        IsInitialized := false;
    end;

    var
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        AmountError: Label 'Amount must be %1 in %2.';

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceDiscountFA()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchFADiscAccount: Code[20];
        InvoiceAmount: Decimal;
        OldSubtractDiscinPurchInv: Boolean;
    begin
        // Create and Post Purchase Invoice and Update General Posting setup for Purchase Invoice Discount Amount.

        // Setup: Create Fixed Asset, Purchase Invoice and Update General Posting Setup.
        Initialize();
        UpdateDepreciationBook(OldSubtractDiscinPurchInv, true);
        InvoiceAmount := CreatePurchaseInvoice(PurchaseHeader, PurchaseLine);
        PurchFADiscAccount := UpdateGeneralPostingSetup(PurchaseLine);

        // Exercise: Post Purchase Invoice.
        LibraryLowerPermissions.SetPurchDocsPost();
        LibraryLowerPermissions.AddO365FAEdit();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify GL Entry for Purchase Invoice Discount Amount.
        VerifyGLEntry(PurchFADiscAccount, InvoiceAmount, PurchaseLine."Document No.");

        // Tear Down: Reset the initial value of Subtract Discount in Depreciation Book.
        LibraryLowerPermissions.SetOutsideO365Scope();
        UpdateDepreciationBook(OldSubtractDiscinPurchInv, OldSubtractDiscinPurchInv);
        LibraryFixedAsset.VerifyLastFARegisterGLRegisterOneToOneRelation(); // TFS 376879
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Purch Inv Disc With FA");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Purch Inv Disc With FA");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Purch Inv Disc With FA");
    end;

    local procedure CreateFixedAsset(): Code[20]
    var
        FixedAsset: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        FAPostingGroup: Record "FA Posting Group";
    begin
        FAPostingGroup.FindFirst();
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", LibraryFixedAsset.GetDefaultDeprBook());
        FADepreciationBook.Validate("FA Posting Group", FAPostingGroup.Code);
        FADepreciationBook.Modify(true);
        exit(FixedAsset."No.");
    end;

    local procedure CreatePurchaseInvoice(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"): Decimal
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, '');

        // Using Random values for calculation and value is not important for Test Case.
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Fixed Asset", CreateFixedAsset(), LibraryRandom.RandInt(5));
        PurchaseLine.Validate("Direct Unit Cost", 300 * LibraryRandom.RandDec(10, 2));
        PurchaseLine.Validate("Line Discount %", LibraryRandom.RandInt(15));
        PurchaseLine.Modify(true);
        exit(PurchaseLine.Quantity * PurchaseLine."Direct Unit Cost" * PurchaseLine."Line Discount %" / 100);
    end;

    local procedure UpdateGeneralPostingSetup(PurchaseLine: Record "Purchase Line"): Code[20]
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        GeneralPostingSetup.Validate("Purch. FA Disc. Account", LibraryERM.CreateGLAccountNo());
        GeneralPostingSetup.Modify(true);
        exit(GeneralPostingSetup."Purch. FA Disc. Account");
    end;

    local procedure UpdateDepreciationBook(var OldSubtractDiscinPurchInv: Boolean; SubtractDiscinPurchInv: Boolean)
    var
        DepreciationBook: Record "Depreciation Book";
    begin
        DepreciationBook.Get(LibraryFixedAsset.GetDefaultDeprBook());
        OldSubtractDiscinPurchInv := DepreciationBook."Subtract Disc. in Purch. Inv.";
        DepreciationBook.Validate("Subtract Disc. in Purch. Inv.", SubtractDiscinPurchInv);
        DepreciationBook.Modify(true);
    end;

    local procedure VerifyGLEntry(GLAccountNo: Code[20]; Amount: Decimal; PreAssignedNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
        PurchInvHeader: Record "Purch. Inv. Header";
        GeneralLedgerSetup: Record "General Ledger Setup";
        Assert: Codeunit Assert;
    begin
        GeneralLedgerSetup.Get();
        PurchInvHeader.SetRange("Pre-Assigned No.", PreAssignedNo);
        PurchInvHeader.FindFirst();
        GLEntry.SetRange("Document No.", PurchInvHeader."No.");
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindFirst();
        Assert.AreNearlyEqual(
          Amount, GLEntry.Amount, GeneralLedgerSetup."Amount Rounding Precision", StrSubstNo(AmountError, Amount, GLEntry.TableCaption()));
    end;
}

