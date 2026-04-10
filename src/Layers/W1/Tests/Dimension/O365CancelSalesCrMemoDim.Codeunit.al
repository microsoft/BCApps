codeunit 138036 "O365 Cancel Sales Cr Memo Dim."
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Cancelled Document] [Credit Memo] [Sales] [Dimension]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySmallBusiness: Codeunit "Library - Small Business";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        IsInitialized: Boolean;
        DimensionBlockedErr: Label 'You cannot cancel this posted sales credit memo because the dimension rule setup';
        DimCombItemBlockedErr: Label 'You cannot cancel this posted sales credit memo because the dimension combination';
        DimCombCustBlockedErr: Label 'You cannot cancel this posted sales credit memo because the combination of dimensions';

    [Test]
    [Scope('OnPrem')]
    procedure CannotCancelCreditMemoWithBlockedItemDim()
    var
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        DimValue: Record "Dimension Value";
    begin
        // [FEATURE] [Blocked Dimension]
        // [SCENARIO 168492] It's not possible to cancel Posted Credit Memo when Item Dimension is Blocked

        Initialize();

        // [GIVEN] Posted Credit Memo cancelled Invoice with Dimension = "X" for Item
        PostInvoiceWithDim(SalesInvHeader, '', '', LibrarySmallBusiness.InitGlobalDimCodeValue(DimValue, 1), '');
        CancelInvoice(SalesCrMemoHeader, SalesInvHeader);

        // [GIVEN] Blocked Dimension "X"
        // [WHEN] Cancel Posted Credit Memo
        // [THEN] Error message "You cannot cancel this posted sales credit memo because the dimension rule setup for Item X prevent from being cancelled" is raised
        VerifyBlockedDimOnCancelCrMemo(SalesCrMemoHeader, DimValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotCancelCreditMemoWithBlockedCustDim()
    var
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        DimValue: Record "Dimension Value";
    begin
        // [FEATURE] [Blocked Dimension]
        // [SCENARIO 168492] It's not possible to cancel Posted Credit Memo when Customer Dimension is Blocked

        Initialize();

        // [GIVEN] Posted Credit Memo cancelled Invoice with Dimension = "X" for Customer
        PostInvoiceWithDim(SalesInvHeader, LibrarySmallBusiness.InitGlobalDimCodeValue(DimValue, 1), '', '', '');
        CancelInvoice(SalesCrMemoHeader, SalesInvHeader);

        // [GIVEN] Blocked Dimension "X"
        // [WHEN] Cancel Posted Credit Memo
        // [THEN] Error message "You cannot cancel this posted sales credit memo because the dimension rule setup for Customer X prevent from being cancelled" is raised
        VerifyBlockedDimOnCancelCrMemo(SalesCrMemoHeader, DimValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotCancelCreditMemoWithBlockedItemDimComb()
    var
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        DimValue1: Record "Dimension Value";
        DimValue2: Record "Dimension Value";
    begin
        // [FEATURE] [Dimension Combination]
        // [SCENARIO 168492] It's not possible to cancel Posted Credit Memo when Item Dimension Combination is Blocked

        Initialize();

        // [GIVEN] Posted Credit Memo cancelled Invoice with Dimensions "X1" and "X2" for Item
        PostInvoiceWithDim(
          SalesInvHeader, '', '', LibrarySmallBusiness.InitGlobalDimCodeValue(DimValue1, 1),
          LibrarySmallBusiness.InitGlobalDimCodeValue(DimValue2, 2));
        CancelInvoice(SalesCrMemoHeader, SalesInvHeader);

        // [GIVEN] Blocked Dimension Combination "X1" - "X2"
        // [WHEN] Cancel Posted Credit Memo
        // [THEN] Error message "You cannot cancel this posted sales credit memo because the dimension combination for item X1 X2 is not allowed." is raised
        VerifyBlockedDimCombOnCancelCrMemo(SalesCrMemoHeader, DimValue1, DimValue2, DimCombItemBlockedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotCancelCreditMemoWithBlockedCustDimComb()
    var
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        DimValue1: Record "Dimension Value";
        DimValue2: Record "Dimension Value";
    begin
        // [FEATURE] [Dimension Combination]
        // [SCENARIO 168492] It's not possible to cancel Posted Credit Memo when Customer Dimension Combination is Blocked

        Initialize();

        // [GIVEN] Posted Credit Memo cancelled Invoice with Dimensions "X1" and "X2" for Customer
        PostInvoiceWithDim(
          SalesInvHeader, LibrarySmallBusiness.InitGlobalDimCodeValue(DimValue1, 1),
          LibrarySmallBusiness.InitGlobalDimCodeValue(DimValue2, 2), '', '');
        CancelInvoice(SalesCrMemoHeader, SalesInvHeader);

        // [GIVEN] Blocked Dimension Combination "X1" - "X2"
        // [WHEN] Cancel Posted Credit Memo
        // [THEN] Error message "You cannot cancel this posted sales credit memo because the dimension combination for customer X1 X2 is not allowed." is raised
        VerifyBlockedDimCombOnCancelCrMemo(SalesCrMemoHeader, DimValue1, DimValue2, DimCombCustBlockedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotCancelCreditMemoWithReceivablesAccountMandatoryDim()
    var
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        CustNo: Code[20];
        ItemNo: Code[20];
    begin
        // [FEATURE] [Dimension Code Mandatory]
        // [SCENARIO 168492] It's not possible to cancel Posted Credit Memo when mandatory "Default Dimension" assigned to "Receivables Account"

        Initialize();

        // [GIVEN] Posted Credit Memo cancelled Invoice with Customer "X"
        PostSimpleInvoice(SalesInvHeader, CustNo, ItemNo);
        CancelInvoice(SalesCrMemoHeader, SalesInvHeader);

        // [GIVEN] Defaulm Dimension is "Code Mandatory" for "Receivables Account" = "A" of Customer "X"
        AddMandatoryDefDimToReceivablesAccount(CustNo);

        // [WHEN] Cancel Posted Credit Memo
        asserterror CancelCrMemo(SalesCrMemoHeader);

        // [THEN] Error message "You cannot cancel this posted sales credit memo because the dimension rule setup for GLACCOUNT A prevent from being cancelled" is raised
        Assert.ExpectedError(DimensionBlockedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotCancelCreditMemoWithInventoryAccountMandatoryDim()
    var
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        CustNo: Code[20];
        ItemNo: Code[20];
    begin
        // [FEATURE] [Dimension Code Mandatory]
        // [SCENARIO 168492] It's not possible to cancel Posted Credit Memo when mandatory "Default Dimension" assigned to "Inventory Account"

        Initialize();

        // [GIVEN] Posted Credit Memo cancelled Invoice with Item "X"
        PostSimpleInvoice(SalesInvHeader, CustNo, ItemNo);
        CancelInvoice(SalesCrMemoHeader, SalesInvHeader);

        // [GIVEN] Defaulm Dimension is "Code Mandatory" for "Inventory Account" = "A" of Item "X"
        AddMandatoryDefDimToInventoryAccount(SalesCrMemoHeader."Location Code", ItemNo);

        // [WHEN] Cancel Posted Credit Memo
        asserterror CancelCrMemo(SalesCrMemoHeader);

        // [THEN] Error message "You cannot cancel this posted sales credit memo because the dimension rule setup for GLACCOUNT A prevent from being cancelled" is raised
        Assert.ExpectedError(DimensionBlockedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotCancelCreditMemoWithSalesVATAccountMandatoryDim()
    var
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        CustNo: Code[20];
        ItemNo: Code[20];
    begin
        // [FEATURE] [Dimension Code Mandatory]
        // [SCENARIO 168492] It's not possible to cancel Posted Credit Memo when VAT and G/L Account dimensions are mandatory

        Initialize();

        // [GIVEN] Posted Credit Memo cancelled Invoice with Customer "A" and Item "B"
        PostSimpleInvoice(SalesInvHeader, CustNo, ItemNo);
        CancelInvoice(SalesCrMemoHeader, SalesInvHeader);

        // [GIVEN] Defaulm Dimension is "Code Mandatory" for "Sales Account" = "A" of Customer "A" and Item "B"
        AddMandatoryDefDimToSalesAccount(CustNo, ItemNo);

        // [WHEN] Cancel Posted Credit Memo
        asserterror CancelCrMemo(SalesCrMemoHeader);

        // [THEN] Error message "You cannot cancel this posted sales credit memo because the dimension rule setup for GLACCOUNT A prevent from being cancelled" is raised
        Assert.ExpectedError(DimensionBlockedErr);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"O365 Cancel Sales Cr Memo Dim.");
        LibraryApplicationArea.EnableFoundationSetup();
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddAccountReceivables();
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"O365 Cancel Sales Cr Memo Dim.");

        IsInitialized := true;
        LibraryERMCountryData.CreateVATData();
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"O365 Cancel Sales Cr Memo Dim.");
    end;

    local procedure CreateItemNoWithDimensions(Dim1Code: Code[20]; Dim2Code: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Global Dimension 1 Code", Dim1Code);
        Item.Validate("Global Dimension 2 Code", Dim2Code);
        Item."Unit Price" := LibraryRandom.RandDec(100, 2);
        Item.Modify();
        exit(Item."No.");
    end;

    local procedure CreateCustNoWithDimensions(Dim1Code: Code[20]; Dim2Code: Code[20]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Global Dimension 1 Code", Dim1Code);
        Customer.Validate("Global Dimension 2 Code", Dim2Code);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure PostInvoiceWithDim(var SalesInvHeader: Record "Sales Invoice Header"; CustDimValue1Code: Code[20]; CustDimValue2Code: Code[20]; ItemDimValue1Code: Code[20]; ItemDimValue2Code: Code[20])
    var
        CustNo: Code[20];
        ItemNo: Code[20];
    begin
        CreateAndPostInvoice(
          SalesInvHeader, CustNo, ItemNo, CustDimValue1Code, CustDimValue2Code, ItemDimValue1Code, ItemDimValue2Code);
    end;

    local procedure PostSimpleInvoice(var SalesInvHeader: Record "Sales Invoice Header"; var CustNo: Code[20]; var ItemNo: Code[20])
    begin
        CreateAndPostInvoice(SalesInvHeader, CustNo, ItemNo, '', '', '', '');
    end;

    local procedure CreateAndPostInvoice(var SalesInvHeader: Record "Sales Invoice Header"; var CustNo: Code[20]; var ItemNo: Code[20]; CustDimValue1Code: Code[20]; CustDimValue2Code: Code[20]; ItemDimValue1Code: Code[20]; ItemDimValue2Code: Code[20])
    begin
        CustNo := CreateCustNoWithDimensions(CustDimValue1Code, CustDimValue2Code);
        ItemNo := CreateItemNoWithDimensions(ItemDimValue1Code, ItemDimValue2Code);
        PostSalesInvoice(SalesInvHeader, CustNo, ItemNo);
    end;

    local procedure PostSalesInvoice(var SalesInvHeader: Record "Sales Invoice Header"; CustNo: Code[20]; ItemNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustNo);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandInt(100));
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        SalesInvHeader.SetRange("Pre-Assigned No.", SalesHeader."No.");
        SalesInvHeader.FindLast();
    end;

    local procedure AddMandatoryDefDimToReceivablesAccount(CustNo: Code[20])
    var
        Customer: Record Customer;
        CustPostingGroup: Record "Customer Posting Group";
        GLAcc: Record "G/L Account";
        DefaultDim: Record "Default Dimension";
    begin
        Customer.Get(CustNo);
        CustPostingGroup.Get(Customer."Customer Posting Group");
        GLAcc.Get(CustPostingGroup."Receivables Account");
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

    local procedure AddMandatoryDefDimToSalesAccount(CustNo: Code[20]; ItemNo: Code[20])
    var
        Customer: Record Customer;
        Item: Record Item;
        VATPostingSetup: Record "VAT Posting Setup";
        GLAcc: Record "G/L Account";
        DefaultDim: Record "Default Dimension";
    begin
        Customer.Get(CustNo);
        Item.Get(ItemNo);
        VATPostingSetup.Get(Customer."VAT Bus. Posting Group", Item."VAT Prod. Posting Group");
        GLAcc.Get(VATPostingSetup."Sales VAT Account");
        LibraryDimension.CreateDefaultDimensionWithNewDimValue(
          DefaultDim, DATABASE::"G/L Account", GLAcc."No.", DefaultDim."Value Posting"::"Code Mandatory");
    end;

    local procedure CancelInvoice(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; SalesInvHeader: Record "Sales Invoice Header")
    var
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        CorrectPostedSalesInvoice.CancelPostedInvoice(SalesInvHeader);
        LibrarySmallBusiness.FindSalesCorrectiveCrMemo(SalesCrMemoHeader, SalesInvHeader);
    end;

    local procedure CancelCrMemo(var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        CancelPostedSalesCrMemo: Codeunit "Cancel Posted Sales Cr. Memo";
    begin
        CancelPostedSalesCrMemo.CancelPostedCrMemo(SalesCrMemoHeader);
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

    local procedure VerifyBlockedDimOnCancelCrMemo(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var DimValue: Record "Dimension Value")
    begin
        BlockDimValue(DimValue);
        asserterror CancelCrMemo(SalesCrMemoHeader);
        Assert.ExpectedError(DimensionBlockedErr);
        // Tear down: Unblock the Dimension
        UnblockDimValue(DimValue);
    end;

    local procedure VerifyBlockedDimCombOnCancelCrMemo(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var DimValue1: Record "Dimension Value"; var DimValue2: Record "Dimension Value"; ExpectedError: Text)
    begin
        BlockDimCombination(DimValue1."Dimension Code", DimValue2."Dimension Code");
        asserterror CancelCrMemo(SalesCrMemoHeader);
        Assert.ExpectedError(ExpectedError);
        // Tear down: Unblock the Dimension Combination
        UnblockDimCombination(DimValue1."Dimension Code", DimValue2."Dimension Code");
    end;
}

