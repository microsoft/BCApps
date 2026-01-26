codeunit 145400 "ERM Fixed Assets Prepayment"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Fixed Asset] [Prepayment] [Purchase]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        AmountError: Label '%1 must be %2 in %3.', Comment = '%1 = Field Caption, %2 = Field Value,%3 = Table Caption";';

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseOrderWithFixedAsset()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        PurchasePostPrepayments: Codeunit "Purchase-Post Prepayments";
        FixedAssetNo: Code[20];
        PurchasePmtLineAmount: Decimal;
    begin
        // [SCENARIO] GL Entry after Posting Prepayment invoice with Type Fixed Asset in Purchase Order.

        // [GIVEN] Create Purchase Order and update Purchase Prepayment Account.
        FixedAssetNo := FindFixedAsset();
        LibraryPurchase.CreateVendor(Vendor);
        UpdatePurchasePrepaymentAccount(FixedAssetNo, Vendor);
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, FixedAssetNo, Vendor."No.");
        PurchasePmtLineAmount := Round(PurchaseLine."Line Amount" * PurchaseHeader."Prepayment %" / 100);

        // [WHEN] Post Purchase Prepayment Invoice.
        PurchasePostPrepayments.Invoice(PurchaseHeader);

        // [THEN] Verify Amount on G/L Entry for Prepayment Invoice.
        VerifyGLEntryAfterPrepaymentInvoice(PurchaseHeader, PurchasePmtLineAmount);
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; FixedAssetNo: Code[20]; VendorNo: Code[20])
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo);
        PurchaseHeader.Validate("Prepayment %", LibraryRandom.RandInt(50));
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Fixed Asset",
          FixedAssetNo, LibraryRandom.RandInt(100));  // Take Random Value for Quantity.
        PurchaseLine.Validate("Prepayment %", PurchaseHeader."Prepayment %");
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(1000, 2));  // Take Random Values for Direct Unit Cost.
        PurchaseLine.Modify(true);
    end;

    local procedure FindFixedAsset(): Code[20]
    var
        FixedAsset: Record "Fixed Asset";
    begin
        FixedAsset.SetRange(Blocked, false);
        FixedAsset.Next(LibraryRandom.RandInt(FixedAsset.Count));  // Used LibraryRandom.RandInt to take next Record always from Fixed Asset.Count.
        exit(FixedAsset."No.");
    end;

    local procedure GetAcquisitionCostAccount(FixedAssetNo: Code[20]; var GLAccount: Record "G/L Account")
    var
        FADepreciationBook: Record "FA Depreciation Book";
        FAPostingGroup: Record "FA Posting Group";
        FASetup: Record "FA Setup";
    begin
        FASetup.Get();
        FADepreciationBook.Get(FixedAssetNo, FASetup."Default Depr. Book");
        FAPostingGroup.Get(FADepreciationBook."FA Posting Group");
        GLAccount.Get(FAPostingGroup."Acquisition Cost Account");
    end;

    local procedure UpdatePurchasePrepaymentAccount(FixedAssetNo: Code[20]; var Vendor: Record Vendor)
    var
        GeneralPostingSetup: Record "General Posting Setup";
        GLAccount: Record "G/L Account";
        GLAccount2: Record "G/L Account";
    begin
        GetAcquisitionCostAccount(FixedAssetNo, GLAccount);
        LibraryERM.CreateGLAccount(GLAccount2);
        GLAccount2.Validate("VAT Prod. Posting Group", GLAccount."VAT Prod. Posting Group");
        GLAccount2.Modify(true);
        GeneralPostingSetup.Get(Vendor."Gen. Bus. Posting Group", GLAccount."Gen. Prod. Posting Group");
        GeneralPostingSetup.Validate("Purch. Prepayments Account", GLAccount2."No.");
        GeneralPostingSetup.Validate("Sales Prepayments Account", GLAccount2."No.");
        GeneralPostingSetup.Modify(true);
        LibraryERMCountryData.UpdatePrepaymentAccounts();
    end;

    local procedure VerifyGLEntryAfterPrepaymentInvoice(PurchaseHeader: Record "Purchase Header"; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
        PurchInvHeader: Record "Purch. Inv. Header";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        PurchInvHeader.SetRange("Buy-from Vendor No.", PurchaseHeader."Buy-from Vendor No.");
        PurchInvHeader.SetRange("Vendor Invoice No.", PurchaseHeader."Vendor Invoice No.");
        PurchInvHeader.FindFirst();
        GLEntry.SetRange("Document No.", PurchInvHeader."No.");
        GLEntry.FindFirst();
        Assert.AreNearlyEqual(
          Amount, GLEntry.Amount, GeneralLedgerSetup."Amount Rounding Precision", StrSubstNo(
            AmountError, GLEntry.FieldCaption(Amount), Amount, GLEntry.TableCaption()))
    end;
}

