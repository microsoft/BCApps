codeunit 138037 "O365 Cancel Purch Cr Memo Dim."
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Cancelled Document] [Credit Memo] [Purchase] [Dimension]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySmallBusiness: Codeunit "Library - Small Business";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        IsInitialized: Boolean;
        DimensionBlockedErr: Label 'You cannot cancel this posted purchase credit memo because the dimension rule setup';
        DimCombItemBlockedErr: Label 'You cannot cancel this posted purchase credit memo because the dimension combination';
        DimCombVendBlockedErr: Label 'You cannot cancel this posted purchase credit memo because the combination of dimensions';

    [Test]
    [Scope('OnPrem')]
    procedure CannotCancelCreditMemoWithBlockedItemDim()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        DimValue: Record "Dimension Value";
    begin
        // [FEATURE] [Blocked Dimension]
        // [SCENARIO 168492] It's not possible to cancel Posted Credit Memo when Item Dimension is Blocked

        Initialize();

        // [GIVEN] Posted Credit Memo cancelled Invoice with Dimension = "X" for Item
        PostInvoiceWithDim(PurchInvHeader, '', '', LibrarySmallBusiness.InitGlobalDimCodeValue(DimValue, 1), '');
        CancelInvoice(PurchCrMemoHdr, PurchInvHeader);

        // [GIVEN] Blocked Dimension "X"
        // [WHEN] Cancel Posted Credit Memo
        // [THEN] Error message "You cannot cancel this posted purchase credit memo because the dimension rule setup for Item X prevent from being cancelled" is raised
        VerifyBlockedDimOnCancelCrMemo(PurchCrMemoHdr, DimValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotCancelCreditMemoWithBlockedVendDim()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        DimValue: Record "Dimension Value";
    begin
        // [FEATURE] [Blocked Dimension]
        // [SCENARIO 168492] It's not possible to cancel Posted Credit Memo when Vendor Dimension is Blocked

        Initialize();

        // [GIVEN] Posted Credit Memo cancelled Invoice with Dimension = "X" for Vendor
        PostInvoiceWithDim(PurchInvHeader, LibrarySmallBusiness.InitGlobalDimCodeValue(DimValue, 1), '', '', '');
        CancelInvoice(PurchCrMemoHdr, PurchInvHeader);

        // [GIVEN] Blocked Dimension "X"
        // [WHEN] Cancel Posted Credit Memo
        // [THEN] Error message "You cannot cancel this posted purchase credit memo because the dimension rule setup for Vendor X prevent from being cancelled" is raised
        VerifyBlockedDimOnCancelCrMemo(PurchCrMemoHdr, DimValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotCancelCreditMemoWithBlockedItemDimComb()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        DimValue1: Record "Dimension Value";
        DimValue2: Record "Dimension Value";
    begin
        // [FEATURE] [Dimension Combination]
        // [SCENARIO 168492] It's not possible to cancel Posted Credit Memo when Item Dimension Combination is Blocked

        Initialize();

        // [GIVEN] Posted Credit Memo cancelled Invoice with Dimensions "X1" and "X2" for Item
        PostInvoiceWithDim(
          PurchInvHeader, '', '', LibrarySmallBusiness.InitGlobalDimCodeValue(DimValue1, 1),
          LibrarySmallBusiness.InitGlobalDimCodeValue(DimValue2, 2));
        CancelInvoice(PurchCrMemoHdr, PurchInvHeader);

        // [GIVEN] Blocked Dimension Combination "X1" - "X2"
        // [WHEN] Cancel Posted Credit Memo
        // [THEN] Error message "You cannot cancel this posted purchase credit memo because the dimension combination for item X1 X2 is not allowed." is raised
        VerifyBlockedDimCombOnCancelCrMemo(PurchCrMemoHdr, DimValue1, DimValue2, DimCombItemBlockedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotCancelCreditMemoWithBlockedVendDimComb()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        DimValue1: Record "Dimension Value";
        DimValue2: Record "Dimension Value";
    begin
        // [FEATURE] [Dimension Combination]
        // [SCENARIO 168492] It's not possible to cancel Posted Credit Memo when Vendor Dimension Combination is Blocked

        Initialize();

        // [GIVEN] Posted Credit Memo cancelled Invoice with Dimensions "X1" and "X2" for Vendor
        PostInvoiceWithDim(
          PurchInvHeader, LibrarySmallBusiness.InitGlobalDimCodeValue(DimValue1, 1),
          LibrarySmallBusiness.InitGlobalDimCodeValue(DimValue2, 2), '', '');
        CancelInvoice(PurchCrMemoHdr, PurchInvHeader);

        // [GIVEN] Blocked Dimension Combination "X1" - "X2"
        // [WHEN] Cancel Posted Credit Memo
        // [THEN] Error message "You cannot cancel this posted purchase credit memo because the dimension combination for Vendor X1 X2 is not allowed." is raised
        VerifyBlockedDimCombOnCancelCrMemo(PurchCrMemoHdr, DimValue1, DimValue2, DimCombVendBlockedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotCancelCreditMemoWithPayablesAccountMandatoryDim()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        VendNo: Code[20];
        ItemNo: Code[20];
    begin
        // [FEATURE] [Dimension Code Mandatory]
        // [SCENARIO 168492] It's not possible to cancel Posted Credit Memo when mandatory "Default Dimension" assigned to "Payables Account"

        Initialize();

        // [GIVEN] Posted Credit Memo cancelled Invoice with Vendor "X"
        PostSimpleInvoice(PurchInvHeader, VendNo, ItemNo);
        CancelInvoice(PurchCrMemoHdr, PurchInvHeader);

        // [GIVEN] Defaulm Dimension is "Code Mandatory" for "Payables Account" = "A" of Vendor "X"
        AddMandatoryDefDimToPayablesAccount(VendNo);

        // [WHEN] Cancel Posted Credit Memo
        asserterror CancelCrMemo(PurchCrMemoHdr);

        // [THEN] Error message "You cannot cancel this posted purchase credit memo because the dimension rule setup for GLACCOUNT A prevent from being cancelled" is raised
        Assert.ExpectedError(DimensionBlockedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotCancelCreditMemoWithInventoryAccountMandatoryDim()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        VendNo: Code[20];
        ItemNo: Code[20];
    begin
        // [FEATURE] [Dimension Code Mandatory]
        // [SCENARIO 168492] It's not possible to cancel Posted Credit Memo when mandatory "Default Dimension" assigned to "Inventory Account"

        Initialize();

        // [GIVEN] Posted Credit Memo cancelled Invoice with Item "X"
        PostSimpleInvoice(PurchInvHeader, VendNo, ItemNo);
        CancelInvoice(PurchCrMemoHdr, PurchInvHeader);

        // [GIVEN] Defaulm Dimension is "Code Mandatory" for "Inventory Account" = "A" of Item "X"
        AddMandatoryDefDimToInventoryAccount(PurchCrMemoHdr."Location Code", ItemNo);

        // [WHEN] Cancel Posted Credit Memo
        asserterror CancelCrMemo(PurchCrMemoHdr);

        // [THEN] Error message "You cannot cancel this posted purchase credit memo because the dimension rule setup for GLACCOUNT A prevent from being cancelled" is raised
        Assert.ExpectedError(DimensionBlockedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotCancelCreditMemoWithPurchaseVATAccountMandatoryDim()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        VendNo: Code[20];
        ItemNo: Code[20];
    begin
        // [FEATURE] [Dimension Code Mandatory]
        // [SCENARIO 168492] It's not possible to cancel Posted Credit Memo when VAT and G/L Account dimensions are mandatory

        Initialize();

        // [GIVEN] Posted Credit Memo cancelled Invoice with Vendor "A" and Item "B"
        PostSimpleInvoice(PurchInvHeader, VendNo, ItemNo);
        CancelInvoice(PurchCrMemoHdr, PurchInvHeader);

        // [GIVEN] Defaulm Dimension is "Code Mandatory" for "Purchase Account" = "A" of Vendor "A" and Item "B"
        AddMandatoryDefDimToPurchAccount(VendNo, ItemNo);

        // [WHEN] Cancel Posted Credit Memo
        asserterror CancelCrMemo(PurchCrMemoHdr);

        // [THEN] Error message "You cannot cancel this posted purchase credit memo because the dimension rule setup for GLACCOUNT A prevent from being cancelled" is raised
        Assert.ExpectedError(DimensionBlockedErr);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"O365 Cancel Purch Cr Memo Dim.");
        LibraryApplicationArea.EnableFoundationSetup();
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddAccountPayables();
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"O365 Cancel Purch Cr Memo Dim.");

        IsInitialized := true;
        LibraryERMCountryData.CreateVATData();
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"O365 Cancel Purch Cr Memo Dim.");
    end;

    local procedure CreateItemNoWithDimensions(Dim1Code: Code[20]; Dim2Code: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Global Dimension 1 Code", Dim1Code);
        Item.Validate("Global Dimension 2 Code", Dim2Code);
        Item.Modify();
        exit(Item."No.");
    end;

    local procedure CreateVendNoWithDimensions(Dim1Code: Code[20]; Dim2Code: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Global Dimension 1 Code", Dim1Code);
        Vendor.Validate("Global Dimension 2 Code", Dim2Code);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure PostInvoiceWithDim(var PurchInvHeader: Record "Purch. Inv. Header"; VendDimValue1Code: Code[20]; VendDimValue2Code: Code[20]; ItemDimValue1Code: Code[20]; ItemDimValue2Code: Code[20])
    var
        VendNo: Code[20];
        ItemNo: Code[20];
    begin
        CreateAndPostInvoice(
          PurchInvHeader, VendNo, ItemNo, VendDimValue1Code, VendDimValue2Code, ItemDimValue1Code, ItemDimValue2Code);
    end;

    local procedure PostSimpleInvoice(var PurchInvHeader: Record "Purch. Inv. Header"; var VendNo: Code[20]; var ItemNo: Code[20])
    begin
        CreateAndPostInvoice(PurchInvHeader, VendNo, ItemNo, '', '', '', '');
    end;

    local procedure CreateAndPostInvoice(var PurchInvHeader: Record "Purch. Inv. Header"; var VendNo: Code[20]; var ItemNo: Code[20]; VendDimValue1Code: Code[20]; VendDimValue2Code: Code[20]; ItemDimValue1Code: Code[20]; ItemDimValue2Code: Code[20])
    begin
        VendNo := CreateVendNoWithDimensions(VendDimValue1Code, VendDimValue2Code);
        ItemNo := CreateItemNoWithDimensions(ItemDimValue1Code, ItemDimValue2Code);
        PostPurchInvoice(PurchInvHeader, VendNo, ItemNo);
    end;

    local procedure PostPurchInvoice(var PurchInvHeader: Record "Purch. Inv. Header"; VendNo: Code[20]; ItemNo: Code[20])
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Invoice, VendNo);
        LibraryPurchase.CreatePurchaseLine(
          PurchLine, PurchHeader, PurchLine.Type::Item, ItemNo, LibraryRandom.RandInt(100));
        PurchLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

        PurchInvHeader.SetRange("Pre-Assigned No.", PurchHeader."No.");
        PurchInvHeader.FindLast();
    end;

    local procedure AddMandatoryDefDimToPayablesAccount(VendNo: Code[20])
    var
        Vendor: Record Vendor;
        VendPostingGroup: Record "Vendor Posting Group";
        GLAcc: Record "G/L Account";
        DefaultDim: Record "Default Dimension";
    begin
        Vendor.Get(VendNo);
        VendPostingGroup.Get(Vendor."Vendor Posting Group");
        GLAcc.Get(VendPostingGroup."Payables Account");
        LibraryDimension.CreateDefaultDimensionWithNewDimValue(
          DefaultDim, DATABASE::"G/L Account", GLAcc."No.", DefaultDim."Value Posting"::"Code Mandatory");
    end;

    local procedure AddMandatoryDefDimToInventoryAccount(LocationCode: Code[10]; ItemNo: Code[20])
    var
        Item: Record Item;
        InvtPostingSetup: Record "Inventory Posting Setup";
        GLAcc: Record "G/L Account";
        DefaultDim: Record "Default Dimension";
    begin
        Item.Get(ItemNo);
        InvtPostingSetup.Get(LocationCode, Item."Inventory Posting Group");
        GLAcc.Get(InvtPostingSetup."Inventory Account");
        LibraryDimension.CreateDefaultDimensionWithNewDimValue(
          DefaultDim, DATABASE::"G/L Account", GLAcc."No.", DefaultDim."Value Posting"::"Code Mandatory");
    end;

    local procedure AddMandatoryDefDimToPurchAccount(VendNo: Code[20]; ItemNo: Code[20])
    var
        Vendor: Record Vendor;
        Item: Record Item;
        VATPostingSetup: Record "VAT Posting Setup";
        GLAcc: Record "G/L Account";
        DefaultDim: Record "Default Dimension";
    begin
        Vendor.Get(VendNo);
        Item.Get(ItemNo);
        VATPostingSetup.Get(Vendor."VAT Bus. Posting Group", Item."VAT Prod. Posting Group");
        GLAcc.Get(VATPostingSetup."Purchase VAT Account");
        LibraryDimension.CreateDefaultDimensionWithNewDimValue(
          DefaultDim, DATABASE::"G/L Account", GLAcc."No.", DefaultDim."Value Posting"::"Code Mandatory");
    end;

    local procedure CancelInvoice(var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; PurchInvHeader: Record "Purch. Inv. Header")
    var
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
    begin
        CorrectPostedPurchInvoice.CancelPostedInvoice(PurchInvHeader);
        LibrarySmallBusiness.FindPurchCorrectiveCrMemo(PurchCrMemoHdr, PurchInvHeader);
    end;

    local procedure CancelCrMemo(var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    var
        CancelPostedPurchCrMemo: Codeunit "Cancel Posted Purch. Cr. Memo";
    begin
        CancelPostedPurchCrMemo.CancelPostedCrMemo(PurchCrMemoHdr);
    end;

    local procedure BlockDimValue(var DimValue: Record "Dimension Value")
    begin
        DimValue.Validate(Blocked, true);
        DimValue.Modify(true);
        Commit();
    end;

    local procedure BlockDimCombination(DimCode1: Code[20]; DimCode2: Code[20])
    var
        DimCombination: Record "Dimension Combination";
    begin
        DimCombination.Init();
        DimCombination.Validate("Dimension 1 Code", DimCode1);
        DimCombination.Validate("Dimension 2 Code", DimCode2);
        DimCombination.Validate("Combination Restriction", DimCombination."Combination Restriction"::Blocked);
        DimCombination.Insert();
        Commit();
    end;

    local procedure UnblockDimValue(var DimValue: Record "Dimension Value")
    begin
        DimValue.Validate(Blocked, false);
        DimValue.Modify(true);
        Commit();
    end;

    local procedure UnblockDimCombination(DimCode1: Code[20]; DimCode2: Code[20])
    var
        DimCombination: Record "Dimension Combination";
    begin
        DimCombination.Get(DimCode1, DimCode2);
        DimCombination.Delete(true);
        Commit();
    end;

    local procedure VerifyBlockedDimOnCancelCrMemo(var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; var DimValue: Record "Dimension Value")
    begin
        BlockDimValue(DimValue);
        asserterror CancelCrMemo(PurchCrMemoHdr);
        Assert.ExpectedError(DimensionBlockedErr);
        // Tear down: Unblock the Dimension
        UnblockDimValue(DimValue);
    end;

    local procedure VerifyBlockedDimCombOnCancelCrMemo(var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; var DimValue1: Record "Dimension Value"; var DimValue2: Record "Dimension Value"; ExpectedError: Text)
    begin
        BlockDimCombination(DimValue1."Dimension Code", DimValue2."Dimension Code");
        asserterror CancelCrMemo(PurchCrMemoHdr);
        Assert.ExpectedError(ExpectedError);
        // Tear down: Unblock the Dimension Combination
        UnblockDimCombination(DimValue1."Dimension Code", DimValue2."Dimension Code");
    end;
}

