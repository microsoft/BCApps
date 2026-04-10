codeunit 134038 "ERM Purchase VAT Posting Group"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Bill-to/Sell-to VAT Calc.] [Purchase]
        IsInitialized := false;
    end;

    var
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        PostingGroupError: Label '%1 must be %2 in %3: %4.';

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure VATPostingGroupSellToBuyFromNo()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchaseHeader: Record "Purchase Header";
        BillToSellToVATCalc: Enum "G/L Setup VAT Calculation";
    begin
        // Check that correct VAT Posting Group updated on Purchase Header when Bill To Sell To VAT Calc is Sell to Buy From No.

        // Update General Ledger Setup. Create Purchase Header and Update Pay To Vendor No.
        Initialize();
        UpdateGeneralLedgerSetup(BillToSellToVATCalc, GeneralLedgerSetup."Bill-to/Sell-to VAT Calc."::"Sell-to/Buy-from No.");
        CreateAndUpdatePurchaseHeader(PurchaseHeader);

        // Verify: Verify that correct VAT Business Posting Group Updated on Purchase Header.
        VerifyVendorVATPostingGroup(PurchaseHeader, PurchaseHeader."Buy-from Vendor No.");

        // Tear Down: Delete the earlier created Purchase Header and rollback General Ledger Setup.
        PurchaseHeader.Delete(true);
        UpdateGeneralLedgerSetup(BillToSellToVATCalc, BillToSellToVATCalc);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure VATPostingGroupBillToPayToNo()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchaseHeader: Record "Purchase Header";
        PayToVendorNo: Code[20];
        BillToSellToVATCalc: Enum "G/L Setup VAT Calculation";
    begin
        // Check that correct VAT Posting Group updated on Purchase Header when Bill To Sell To VAT Calc is Bill To Pay To No.

        // Update General Ledger Setup. Create Purchase Header and Update Pay To Vendor No.
        Initialize();
        UpdateGeneralLedgerSetup(BillToSellToVATCalc, GeneralLedgerSetup."Bill-to/Sell-to VAT Calc."::"Bill-to/Pay-to No.");
        PayToVendorNo := CreateAndUpdatePurchaseHeader(PurchaseHeader);

        // Verify: Verify the VAT Business Posting Group on Purchase Header.
        VerifyVendorVATPostingGroup(PurchaseHeader, PayToVendorNo);

        // Tear Down: Delete the earlier created Purchase Header and rollback General Ledger Setup.
        PurchaseHeader.Delete(true);
        UpdateGeneralLedgerSetup(BillToSellToVATCalc, BillToSellToVATCalc);
    end;

    local procedure Initialize()
    var
        PurchaseHeader: Record "Purchase Header";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Purchase VAT Posting Group");
        PurchaseHeader.DontNotifyCurrentUserAgain(PurchaseHeader.GetModifyVendorAddressNotificationId());
        PurchaseHeader.DontNotifyCurrentUserAgain(PurchaseHeader.GetModifyPayToVendorAddressNotificationId());
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Purchase VAT Posting Group");
        LibraryERMCountryData.CreateVATData();
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Purchase VAT Posting Group");
    end;

    local procedure CreateAndUpdatePurchaseHeader(var PurchaseHeader: Record "Purchase Header") PayToVendorNo: Code[20]
    var
        Vendor: Record Vendor;
    begin
        // Setup: Create a Purchase Header of Order Type.
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        PayToVendorNo := FindVendor(Vendor."VAT Bus. Posting Group");

        // Exercise: Update the Purchase Header with a new Pay To Vendor No.
        PurchaseHeader.Validate("Pay-to Vendor No.", PayToVendorNo);
        PurchaseHeader.Modify(true);
    end;

    local procedure FindVendor(VATBusPostingGroup: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        // Find a Vendor with different VAT Business Posting Group.
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure UpdateGeneralLedgerSetup(var BillToSellToVATCalcOld: Enum "G/L Setup VAT Calculation"; BillToSellToVATCalc: Enum "G/L Setup VAT Calculation")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        BillToSellToVATCalcOld := GeneralLedgerSetup."Bill-to/Sell-to VAT Calc.";
        GeneralLedgerSetup.Validate("Bill-to/Sell-to VAT Calc.", BillToSellToVATCalc);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure VerifyVendorVATPostingGroup(PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20])
    var
        Vendor: Record Vendor;
        Assert: Codeunit Assert;
    begin
        Vendor.Get(VendorNo);
        Assert.AreEqual(
          Vendor."VAT Bus. Posting Group", PurchaseHeader."VAT Bus. Posting Group",
          StrSubstNo(PostingGroupError, PurchaseHeader.FieldCaption("VAT Bus. Posting Group"),
            Vendor."VAT Bus. Posting Group", PurchaseHeader.TableCaption(), PurchaseHeader."No."));
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

