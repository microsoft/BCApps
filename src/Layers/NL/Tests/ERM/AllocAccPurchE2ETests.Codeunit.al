#pragma warning disable AA0210
codeunit 134831 "Alloc. Acc. Purch. E2E Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryPurchase: Codeunit "Library - Purchase";
        TestProxyNotifMgtExt: Codeunit "Test Proxy Notif. Mgt. Ext.";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        Any: Codeunit Any;
        Assert: Codeunit Assert;
        Initialized: Boolean;
        AmountMustBeEqualErr: Label 'Amount Must be equal.';

    local procedure Initialize()
    var
        AllocationAccount: Record "Allocation Account";
        AllocAccManualOverride: Record "Alloc. Acc. Manual Override";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Alloc. Acc. Purch. E2E Tests");

        AllocationAccount.DeleteAll();
        AllocAccManualOverride.DeleteAll();

        if Initialized then
            exit;

        BindSubscription(TestProxyNotifMgtExt);
        Initialized := true;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    procedure TestAllocateToDifferentAccountsVariableGLAllocation()
    var
        FirstDestinationGLAccount: Record "G/L Account";
        SecondDestinationGLAccount: Record "G/L Account";
        ThirdDestinationGLAccount: Record "G/L Account";
        FirstBreakdownGLAccount: Record "G/L Account";
        SecondBreakdownGLAccount: Record "G/L Account";
        ThirdBreakdownGLAccount: Record "G/L Account";
        BalancingGLAccount: Record "G/L Account";
        AllocationAccount: Record "Allocation Account";
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoiceHeader: Record "Purch. Inv. Header";
        PurchaseInvoiceLine: Record "Purch. Inv. Line";
        AllocationAccountPage: TestPage "Allocation Account";
        PurchaseInvoice: TestPage "Purchase Invoice";
        PostedAmount: Decimal;
    begin
        Initialize();

        // [GIVEN] Three GL accounts with dimensions and balances, one Balancing G/L Account and three Destination G/L Accounts
        CreateBreakdownAccountsWithBalances(FirstBreakdownGLAccount, SecondBreakdownGLAccount, ThirdBreakdownGLAccount);
        FirstDestinationGLAccount.Get(CreateGLAccount());
        SecondDestinationGLAccount.Get(CreateGLAccount());
        ThirdDestinationGLAccount.Get(CreateGLAccount());
        BalancingGLAccount.Get(CreateGLAccount());

        // [GIVEN] An Allocation Account with variable GL distributions
        AllocationAccount.Get(CreateAllocationAccountWithVariableDistribution(AllocationAccountPage));
        AddGLDestinationAccountForVariableDistribution(AllocationAccountPage, FirstDestinationGLAccount);
        AddGLBreakdownAccountForVariableDistribution(AllocationAccountPage, FirstBreakdownGLAccount);

        AllocationAccountPage.VariableAccountDistribution.New();
        AddGLDestinationAccountForVariableDistribution(AllocationAccountPage, SecondDestinationGLAccount);
        AddGLBreakdownAccountForVariableDistribution(AllocationAccountPage, SecondBreakdownGLAccount);

        AllocationAccountPage.VariableAccountDistribution.New();
        AddGLDestinationAccountForVariableDistribution(AllocationAccountPage, ThirdDestinationGLAccount);
        AddGLBreakdownAccountForVariableDistribution(AllocationAccountPage, ThirdBreakdownGLAccount);
        AllocationAccountPage.Close();

        // [GIVEN] The Purchase Invoice with an Item and a Allocation Account
        CreatePurchaseInvoice(AllocationAccount."No.", PurchaseInvoice, PurchaseHeader);

        // [WHEN] The Purchase Invoice is posted
        PurchaseInvoice.Post.Invoke();
        PurchaseInvoiceHeader.SetRange("Draft Invoice SystemId", PurchaseHeader.SystemId);
        PurchaseInvoiceHeader.FindFirst();

        // [THEN] The costs are split into mulitple ledger entries which has the same dimension code
        PurchaseInvoiceLine.SetRange("Document No.", PurchaseInvoiceHeader."No.");
        PurchaseInvoiceLine.SetRange("No.", FirstDestinationGLAccount."No.");
        Assert.AreEqual(1, PurchaseInvoiceLine.Count(), 'Wrong number of Purch. Inv. Lines created for the first destination account');
        PurchaseInvoiceLine.FindFirst();
        VerifyPurchaseLineAmount(PurchaseInvoiceLine, GetLineAmountToForceRounding(), 6);
        PostedAmount := PurchaseInvoiceLine.Amount;

        PurchaseInvoiceLine.SetRange("No.", SecondDestinationGLAccount."No.");
        Assert.AreEqual(1, PurchaseInvoiceLine.Count(), 'Wrong number of Purch. Inv. Lines for the second destination account');
        PurchaseInvoiceLine.FindFirst();
        VerifyPurchaseLineAmount(PurchaseInvoiceLine, GetLineAmountToForceRounding(), 3);
        PostedAmount += PurchaseInvoiceLine.Amount;

        PurchaseInvoiceLine.SetRange("No.", ThirdDestinationGLAccount."No.");
        Assert.AreEqual(1, PurchaseInvoiceLine.Count(), 'Wrong number of Purch. Inv. Lines for the second destination account');
        PurchaseInvoiceLine.FindFirst();
        VerifyPurchaseLineAmount(PurchaseInvoiceLine, GetLineAmountToForceRounding(), 2);
        PostedAmount += PurchaseInvoiceLine.Amount;

        Assert.AreEqual(GetLineAmountToForceRounding(), PostedAmount, 'The rounding amount was not distributed correctly');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,HandleEditDimensionSetEntriesPage')]
    procedure TestAllocateToSameAccountDifferentDimensionsVariableGLAllocation()
    var
        FirstDimensionValue: Record "Dimension Value";
        SecondDimensionValue: Record "Dimension Value";
        ThirdDimensionValue: Record "Dimension Value";
        DestinationGLAccount: Record "G/L Account";
        FirstBreakdownGLAccount: Record "G/L Account";
        SecondBreakdownGLAccount: Record "G/L Account";
        ThirdBreakdownGLAccount: Record "G/L Account";
        BalancingGLAccount: Record "G/L Account";
        AllocationAccount: Record "Allocation Account";
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoiceLine: Record "Purch. Inv. Line";
        PurchaseInvoiceHeader: Record "Purch. Inv. Header";
        PurchaseInvoice: TestPage "Purchase Invoice";
        PostedAmount: Decimal;
    begin
        Initialize();

        // [GIVEN] A dimension that is defined as a department with three values
        CreateDimensionsWithValues(FirstDimensionValue, SecondDimensionValue, ThirdDimensionValue);

        // [GIVEN] Three GL accounts with dimensions and balances and one Balancing G/L Account
        CreateBreakdownAccountsWithBalances(FirstBreakdownGLAccount, SecondBreakdownGLAccount, ThirdBreakdownGLAccount);
        DestinationGLAccount.Get(CreateGLAccount());
        BalancingGLAccount.Get(CreateGLAccount());

        // [GIVEN] An Allocation Account with variable GL distributions
        CreateAllocationAccountwithVariableGLDistributions(AllocationAccount, FirstDimensionValue, SecondDimensionValue, ThirdDimensionValue, DestinationGLAccount, FirstBreakdownGLAccount, SecondBreakdownGLAccount, ThirdBreakdownGLAccount);

        // [GIVEN] The Purchase Invoice with Item and Allocation account
        CreatePurchaseInvoice(AllocationAccount."No.", PurchaseInvoice, PurchaseHeader);

        // [WHEN] The Purchase Invoice is posted
        PurchaseInvoice.Post.Invoke();
        PurchaseInvoiceHeader.SetRange("Draft Invoice SystemId", PurchaseHeader.SystemId);
        PurchaseInvoiceHeader.FindFirst();

        // [THEN] The costs are split into mulitple ledger entries which has the same dimension code
        PurchaseInvoiceLine.SetRange("Document No.", PurchaseInvoiceHeader."No.");
        PurchaseInvoiceLine.SetRange("No.", DestinationGLAccount."No.");

        FirstDimensionValue.SetRecFilter();
        PurchaseInvoiceLine.SetRange("Dimension Set ID", CreateDimensionSetID(FirstDimensionValue));
        Assert.AreEqual(1, PurchaseInvoiceLine.Count(), 'Wrong number of Purch. Inv. Lines created for the first destination account');
        PurchaseInvoiceLine.FindFirst();
        VerifyPurchaseLineAmount(PurchaseInvoiceLine, GetLineAmountToForceRounding(), 6);
        PostedAmount := PurchaseInvoiceLine.Amount;

        SecondDimensionValue.SetRecFilter();
        PurchaseInvoiceLine.SetRange("Dimension Set ID", CreateDimensionSetID(SecondDimensionValue));
        Assert.AreEqual(1, PurchaseInvoiceLine.Count(), 'Wrong number of Purch. Inv. Lines for the second destination account');
        PurchaseInvoiceLine.FindFirst();
        VerifyPurchaseLineAmount(PurchaseInvoiceLine, GetLineAmountToForceRounding(), 3);
        PostedAmount += PurchaseInvoiceLine.Amount;

        ThirdDimensionValue.SetRecFilter();
        PurchaseInvoiceLine.SetRange("Dimension Set ID", CreateDimensionSetID(ThirdDimensionValue));
        Assert.AreEqual(1, PurchaseInvoiceLine.Count(), 'Wrong number of Purch. Inv. Lines for the second destination account');
        PurchaseInvoiceLine.FindFirst();
        VerifyPurchaseLineAmount(PurchaseInvoiceLine, GetLineAmountToForceRounding(), 2);
        PostedAmount += PurchaseInvoiceLine.Amount;
        Assert.AreEqual(GetLineAmountToForceRounding(), PostedAmount, 'The rounding amount was not distributed correctly');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,HandleEditDimensionSetEntriesPage')]
    procedure TestAllocateBalancingAccountVariableGLAllocation()
    var
        FirstDimensionValue: Record "Dimension Value";
        SecondDimensionValue: Record "Dimension Value";
        ThirdDimensionValue: Record "Dimension Value";
        DestinationGLAccount: Record "G/L Account";
        FirstBreakdownGLAccount: Record "G/L Account";
        SecondBreakdownGLAccount: Record "G/L Account";
        ThirdBreakdownGLAccount: Record "G/L Account";
        BalancingGLAccount: Record "G/L Account";
        AllocationAccount: Record "Allocation Account";
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoiceLine: Record "Purch. Inv. Line";
        PurchaseInvoiceHeader: Record "Purch. Inv. Header";
        PurchaseInvoice: TestPage "Purchase Invoice";
        PostedAmount: Decimal;
    begin
        Initialize();

        // [GIVEN] A dimension that is defined as a department with three values
        CreateDimensionsWithValues(FirstDimensionValue, SecondDimensionValue, ThirdDimensionValue);

        // [GIVEN] Three GL accounts with dimensions and balances and one Balancing G/L Account
        CreateBreakdownAccountsWithBalances(FirstBreakdownGLAccount, SecondBreakdownGLAccount, ThirdBreakdownGLAccount);
        BalancingGLAccount.Get(CreateGLAccount());
        DestinationGLAccount.Get(CreateGLAccount());

        // [GIVEN] An Allocation Account with variable GL distributions
        CreateAllocationAccountwithVariableGLDistributions(AllocationAccount, FirstDimensionValue, SecondDimensionValue, ThirdDimensionValue, DestinationGLAccount, FirstBreakdownGLAccount, SecondBreakdownGLAccount, ThirdBreakdownGLAccount);

        // [GIVEN] The Purchase Invoice with Item and Allocation account
        CreatePurchaseInvoice(AllocationAccount."No.", PurchaseInvoice, PurchaseHeader);

        // [WHEN] The Purchase Invoice is posted
        PurchaseInvoice.Post.Invoke();
        PurchaseInvoiceHeader.SetRange("Draft Invoice SystemId", PurchaseHeader.SystemId);
        PurchaseInvoiceHeader.FindFirst();

        // [THEN] The costs are split into mulitple ledger entries which has the same dimension code
        PurchaseInvoiceLine.SetRange("Document No.", PurchaseInvoiceHeader."No.");
        PurchaseInvoiceLine.SetRange("No.", DestinationGLAccount."No.");
        FirstDimensionValue.SetRecFilter();
        PurchaseInvoiceLine.SetRange("Dimension Set ID", CreateDimensionSetID(FirstDimensionValue));
        Assert.AreEqual(1, PurchaseInvoiceLine.Count(), 'Wrong number of Purch. Inv. Lines created for the first destination account');
        PurchaseInvoiceLine.FindFirst();
        VerifyPurchaseLineAmount(PurchaseInvoiceLine, GetLineAmountToForceRounding(), 6);
        PostedAmount := PurchaseInvoiceLine.Amount;

        SecondDimensionValue.SetRecFilter();
        PurchaseInvoiceLine.SetRange("Dimension Set ID", CreateDimensionSetID(SecondDimensionValue));
        Assert.AreEqual(1, PurchaseInvoiceLine.Count(), 'Wrong number of Purch. Inv. Lines for the second destination account');
        PurchaseInvoiceLine.FindFirst();
        VerifyPurchaseLineAmount(PurchaseInvoiceLine, GetLineAmountToForceRounding(), 3);
        PostedAmount += PurchaseInvoiceLine.Amount;

        ThirdDimensionValue.SetRecFilter();
        PurchaseInvoiceLine.SetRange("Dimension Set ID", CreateDimensionSetID(ThirdDimensionValue));
        Assert.AreEqual(1, PurchaseInvoiceLine.Count(), 'Wrong number of Purch. Inv. Lines for the second destination account');
        PurchaseInvoiceLine.FindFirst();
        VerifyPurchaseLineAmount(PurchaseInvoiceLine, GetLineAmountToForceRounding(), 2);
        PostedAmount += PurchaseInvoiceLine.Amount;
        Assert.AreEqual(GetLineAmountToForceRounding(), PostedAmount, 'The rounding amount was not distributed correctly');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,HandleEditDimensionSetEntriesPage,OverrideGLDistributions')]
    procedure TestOverrideGLAllocation()
    var
        FirstDimensionValue: Record "Dimension Value";
        SecondDimensionValue: Record "Dimension Value";
        ThirdDimensionValue: Record "Dimension Value";
        OverrideFirstDimensionValue: Record "Dimension Value";
        OverrideSecondDimensionValue: Record "Dimension Value";
        OverrideThirdDimensionValue: Record "Dimension Value";
        DestinationGLAccount: Record "G/L Account";
        FirstBreakdownGLAccount: Record "G/L Account";
        SecondBreakdownGLAccount: Record "G/L Account";
        ThirdBreakdownGLAccount: Record "G/L Account";
        BalancingGLAccount: Record "G/L Account";
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoiceLine: Record "Purch. Inv. Line";
        AllocationAccount: Record "Allocation Account";
        AllocAccManualOverride: Record "Alloc. Acc. Manual Override";
        PurchaseInvoiceHeader: Record "Purch. Inv. Header";
        PurchaseInvoice: TestPage "Purchase Invoice";
        PostedAmount: Decimal;
    begin
        Initialize();

        // [GIVEN] A dimension that is defined as a department with three values
        CreateDimensionsWithValues(FirstDimensionValue, SecondDimensionValue, ThirdDimensionValue);
        CreateDimensionsWithValues(OverrideFirstDimensionValue, OverrideSecondDimensionValue, OverrideThirdDimensionValue);

        // [GIVEN] Three GL accounts with dimensions and balances and one Balancing G/L Account
        CreateBreakdownAccountsWithBalances(FirstBreakdownGLAccount, SecondBreakdownGLAccount, ThirdBreakdownGLAccount);
        DestinationGLAccount.Get(CreateGLAccount());
        BalancingGLAccount.Get(CreateGLAccount());

        // [GIVEN] An Allocation Account with variable GL distributions
        CreateAllocationAccountwithVariableGLDistributions(AllocationAccount, FirstDimensionValue, SecondDimensionValue, ThirdDimensionValue, DestinationGLAccount, FirstBreakdownGLAccount, SecondBreakdownGLAccount, ThirdBreakdownGLAccount);

        // [GIVEN] The Purchase Invoice with Item and Allocation account
        CreatePurchaseInvoice(AllocationAccount."No.", PurchaseInvoice, PurchaseHeader);

        // [GIVEN] User defines an override manually
        LibraryVariableStorage.Enqueue(GetLineAmountToForceRounding());
        LibraryVariableStorage.Enqueue(OverrideFirstDimensionValue.SystemId);
        LibraryVariableStorage.Enqueue(OverrideSecondDimensionValue.SystemId);
        LibraryVariableStorage.Enqueue(OverrideThirdDimensionValue.SystemId);
        PurchaseInvoice.PurchLines.RedistributeAccAllocations.Invoke();

        // [WHEN] The Purchase Invoice is posted
        PurchaseInvoice.Post.Invoke();
        PurchaseInvoiceHeader.SetRange("Draft Invoice SystemId", PurchaseHeader.SystemId);
        PurchaseInvoiceHeader.FindFirst();

        // [THEN] The costs are split into mulitple ledger entries which has the same dimension code
        PurchaseInvoiceLine.SetRange("Document No.", PurchaseInvoiceHeader."No.");
        Assert.AreEqual(4, PurchaseInvoiceLine.Count(), 'Wrong number of Purch. Inv. Lines created for the destination account');

        // [THEN] Override values are used
        FirstDimensionValue.SetRecFilter();
        OverrideFirstDimensionValue.SetFilter(SystemId, '%1|%2', FirstDimensionValue.SystemId, OverrideFirstDimensionValue.SystemId);
        PurchaseInvoiceLine.SetRange("Dimension Set ID", CreateDimensionSetID(OverrideFirstDimensionValue));
        Assert.AreEqual(1, PurchaseInvoiceLine.Count(), 'Wrong number of Purch. Inv. Lines for the first breakdown account');
        PurchaseInvoiceLine.FindFirst();
        Assert.AreEqual(GetOverrideAmount(), PurchaseInvoiceLine."Line Amount", 'The override amount was not used');
        PostedAmount := PurchaseInvoiceLine."Line Amount";

        SecondDimensionValue.SetRecFilter();
        OverrideSecondDimensionValue.SetFilter(SystemId, '%1|%2', SecondDimensionValue.SystemId, OverrideSecondDimensionValue.SystemId);
        PurchaseInvoiceLine.SetRange("Dimension Set ID", CreateDimensionSetID(OverrideSecondDimensionValue));
        Assert.AreEqual(1, PurchaseInvoiceLine.Count(), 'Wrong number of Purch. Inv. Lines for the second breakdown account');
        PurchaseInvoiceLine.FindFirst();
        Assert.AreEqual(GetOverrideAmount(), PurchaseInvoiceLine."Line Amount", 'The override amount was not used');
        PostedAmount += PurchaseInvoiceLine."Line Amount";

        ThirdDimensionValue.SetRecFilter();
        OverrideThirdDimensionValue.SetFilter(SystemId, '%1|%2', ThirdDimensionValue.SystemId, OverrideThirdDimensionValue.SystemId);
        PurchaseInvoiceLine.SetRange("Dimension Set ID", CreateDimensionSetID(OverrideThirdDimensionValue));
        Assert.AreEqual(1, PurchaseInvoiceLine.Count(), 'Wrong number of Purch. Inv. Lines for the third breakdown account');
        PurchaseInvoiceLine.FindFirst();
        PostedAmount += PurchaseInvoiceLine."Line Amount";

        Assert.AreEqual(GetLineAmountToForceRounding(), PostedAmount, 'The rounding amount was not distributed correctly');
        Assert.IsTrue(AllocAccManualOverride.IsEmpty(), 'The manual override was not deleted');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,HandleEditDimensionSetEntriesPage,OverrideGLDistributionsPerQuantity')]
    procedure TestOverrideGLAllocationSplitPerQuantity()
    var
        FirstDimensionValue: Record "Dimension Value";
        SecondDimensionValue: Record "Dimension Value";
        ThirdDimensionValue: Record "Dimension Value";
        OverrideFirstDimensionValue: Record "Dimension Value";
        OverrideSecondDimensionValue: Record "Dimension Value";
        OverrideThirdDimensionValue: Record "Dimension Value";
        DestinationGLAccount: Record "G/L Account";
        FirstBreakdownGLAccount: Record "G/L Account";
        SecondBreakdownGLAccount: Record "G/L Account";
        ThirdBreakdownGLAccount: Record "G/L Account";
        BalancingGLAccount: Record "G/L Account";
        PurchaseHeader: Record "Purchase Header";
        PurchInvLine: Record "Purch. Inv. Line";
        AllocationAccount: Record "Allocation Account";
        AllocAccManualOverride: Record "Alloc. Acc. Manual Override";
        PurchInvHeader: Record "Purch. Inv. Header";
        AllocationAccountMgt: Codeunit "Allocation Account Mgt.";
        PurchaseInvoice: TestPage "Purchase Invoice";
        PostedAmount: Decimal;
    begin
        Initialize();

        // [GIVEN] A dimension that is defined as a department with three values
        CreateDimensionsWithValues(FirstDimensionValue, SecondDimensionValue, ThirdDimensionValue);
        CreateDimensionsWithValues(OverrideFirstDimensionValue, OverrideSecondDimensionValue, OverrideThirdDimensionValue);

        // [GIVEN] Three GL accounts with dimensions and balances and one Balancing G/L Account
        CreateBreakdownAccountsWithBalances(FirstBreakdownGLAccount, SecondBreakdownGLAccount, ThirdBreakdownGLAccount);
        DestinationGLAccount.Get(CreateGLAccount());
        BalancingGLAccount.Get(CreateGLAccount());

        // [GIVEN] An Allocation Account with variable GL distributions and split per quantity
        CreateAllocationAccountwithVariableGLDistributions(AllocationAccount, FirstDimensionValue, SecondDimensionValue, ThirdDimensionValue, DestinationGLAccount, FirstBreakdownGLAccount, SecondBreakdownGLAccount, ThirdBreakdownGLAccount);
        AllocationAccount."Document Lines Split" := AllocationAccount."Document Lines Split"::"Split Quantity";
        AllocationAccount.Modify();

        // [GIVEN] The Purchase Invoice with Item and Allocation account
        CreatePurchaseInvoice(AllocationAccount."No.", PurchaseInvoice, PurchaseHeader);

        // [GIVEN] User defines an override manually
        LibraryVariableStorage.Enqueue(OverrideFirstDimensionValue.SystemId);
        LibraryVariableStorage.Enqueue(OverrideSecondDimensionValue.SystemId);
        LibraryVariableStorage.Enqueue(OverrideThirdDimensionValue.SystemId);
        PurchaseInvoice.PurchLines.RedistributeAccAllocations.Invoke();

        // [WHEN] The Purchase Invoice is posted
        PurchaseInvoice.Post.Invoke();
        PurchInvHeader.SetRange("Draft Invoice SystemId", PurchaseHeader.SystemId);
        PurchInvHeader.FindFirst();

        // [THEN] The costs are split into mulitple ledger entries which has the same dimension code
        PurchInvLine.SetRange("Document No.", PurchInvHeader."No.");
        PurchInvLine.SetRange(Type, PurchInvLine.Type::"G/L Account");
        Assert.AreEqual(3, PurchInvLine.Count(), 'Wrong number of Purchase Invoice Lines created for the destination account');
        PurchInvLine.CalcSums(Quantity);
        Assert.AreEqual(1, PurchInvLine.Quantity, 'The quantity was not calculated correctly');

        // [THEN] Override values are used
        FirstDimensionValue.SetRecFilter();
        OverrideFirstDimensionValue.SetFilter(SystemId, '%1|%2', FirstDimensionValue.SystemId, OverrideFirstDimensionValue.SystemId);
        PurchInvLine.SetRange("Dimension Set ID", CreateDimensionSetID(OverrideFirstDimensionValue));
        Assert.AreEqual(1, PurchInvLine.Count(), 'Wrong number of Purchase Invoice Lines for the first breakdown account');

        PurchInvLine.FindFirst();
        Assert.AreEqual(Round(GetLineAmountToForceRounding() * GetOverrideQuantity(), AllocationAccountMgt.GetCurrencyRoundingPrecision(PurchInvLine.GetCurrencyCode())), PurchInvLine."Line Amount", 'The override amount was not used');
        PostedAmount := PurchInvLine."Line Amount";

        SecondDimensionValue.SetRecFilter();
        OverrideSecondDimensionValue.SetFilter(SystemId, '%1|%2', SecondDimensionValue.SystemId, OverrideSecondDimensionValue.SystemId);
        PurchInvLine.SetRange("Dimension Set ID", CreateDimensionSetID(OverrideSecondDimensionValue));
        Assert.AreEqual(1, PurchInvLine.Count(), 'Wrong number of Purchase Invoice Lines for the second breakdown account');
        PurchInvLine.FindFirst();
        Assert.AreEqual(Round(GetLineAmountToForceRounding() * GetOverrideQuantity(), AllocationAccountMgt.GetCurrencyRoundingPrecision(PurchInvLine.GetCurrencyCode())), PurchInvLine."Line Amount", 'The override amount was not used');
        PostedAmount += PurchInvLine."Line Amount";

        ThirdDimensionValue.SetRecFilter();
        OverrideThirdDimensionValue.SetFilter(SystemId, '%1|%2', ThirdDimensionValue.SystemId, OverrideThirdDimensionValue.SystemId);
        PurchInvLine.SetRange("Dimension Set ID", CreateDimensionSetID(OverrideThirdDimensionValue));
        Assert.AreEqual(1, PurchInvLine.Count(), 'Wrong number of Purchase Invoice Lines for the third breakdown account');
        PurchInvLine.FindFirst();
        PostedAmount += PurchInvLine."Line Amount";

        Assert.AreEqual(GetLineAmountToForceRounding(), PostedAmount, 'The rounding amount was not distributed correctly');
        Assert.IsTrue(AllocAccManualOverride.IsEmpty(), 'The manual override was not deleted');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    procedure TestAllocateToDifferentAccountsPerQuantityGLAllocation()
    var
        FirstDestinationGLAccount: Record "G/L Account";
        SecondDestinationGLAccount: Record "G/L Account";
        ThirdDestinationGLAccount: Record "G/L Account";
        FirstBreakdownGLAccount: Record "G/L Account";
        SecondBreakdownGLAccount: Record "G/L Account";
        ThirdBreakdownGLAccount: Record "G/L Account";
        BalancingGLAccount: Record "G/L Account";
        AllocationAccount: Record "Allocation Account";
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
        AllocationAccountPage: TestPage "Allocation Account";
        PurchaseInvoice: TestPage "Purchase Invoice";
        PostedAmount: Decimal;
    begin
        Initialize();

        // [GIVEN] Three GL accounts with dimensions and balances, one Balancing G/L Account and three Destination G/L Accounts
        CreateBreakdownAccountsWithBalances(FirstBreakdownGLAccount, SecondBreakdownGLAccount, ThirdBreakdownGLAccount);
        FirstDestinationGLAccount.Get(CreateGLAccount());
        SecondDestinationGLAccount.Get(CreateGLAccount());
        ThirdDestinationGLAccount.Get(CreateGLAccount());
        BalancingGLAccount.Get(CreateGLAccount());

        // [GIVEN] An Allocation Account with variable GL distributions
        AllocationAccount.Get(CreateAllocationAccountWithVariableDistribution(AllocationAccountPage));
        AllocationAccount."Document Lines Split" := AllocationAccount."Document Lines Split"::"Split Quantity";
        AllocationAccount.Modify();

        AddGLDestinationAccountForVariableDistribution(AllocationAccountPage, FirstDestinationGLAccount);
        AddGLBreakdownAccountForVariableDistribution(AllocationAccountPage, FirstBreakdownGLAccount);

        AllocationAccountPage.VariableAccountDistribution.New();
        AddGLDestinationAccountForVariableDistribution(AllocationAccountPage, SecondDestinationGLAccount);
        AddGLBreakdownAccountForVariableDistribution(AllocationAccountPage, SecondBreakdownGLAccount);

        AllocationAccountPage.VariableAccountDistribution.New();
        AddGLDestinationAccountForVariableDistribution(AllocationAccountPage, ThirdDestinationGLAccount);
        AddGLBreakdownAccountForVariableDistribution(AllocationAccountPage, ThirdBreakdownGLAccount);
        AllocationAccountPage.Close();

        // [GIVEN] The Purchase Invoice with an Item and a Allocation Account
        CreatePurchaseInvoice(AllocationAccount."No.", PurchaseInvoice, PurchaseHeader);

        // [WHEN] The Purchase Invoice is posted
        PurchaseInvoice.Post.Invoke();
        PurchInvHeader.SetRange("Draft Invoice SystemId", PurchaseHeader.SystemId);
        PurchInvHeader.FindFirst();

        // [THEN] The costs are split into mulitple ledger entries which has the same dimension code
        PurchInvLine.SetRange("Document No.", PurchInvHeader."No.");
        PurchInvLine.SetRange("No.", FirstDestinationGLAccount."No.");
        Assert.AreEqual(1, PurchInvLine.Count(), 'Wrong number of Purchase Invoice Lines created for the first destination account');
        PurchInvLine.FindFirst();
        VerifyPurchaseLineAmount(PurchInvLine, GetLineAmountToForceRounding(), 6);
        PostedAmount := PurchInvLine.Amount;

        PurchInvLine.SetRange("No.", SecondDestinationGLAccount."No.");
        Assert.AreEqual(1, PurchInvLine.Count(), 'Wrong number of Purchase Invoice Lines for the second destination account');
        PurchInvLine.FindFirst();
        VerifyPurchaseLineAmount(PurchInvLine, GetLineAmountToForceRounding(), 3);
        PostedAmount += PurchInvLine.Amount;

        PurchInvLine.SetRange("No.", ThirdDestinationGLAccount."No.");
        Assert.AreEqual(1, PurchInvLine.Count(), 'Wrong number of Purchase Invoice Lines for the second destination account');
        PurchInvLine.FindFirst();
        VerifyPurchaseLineAmount(PurchInvLine, GetLineAmountToForceRounding(), 2);
        PostedAmount += PurchInvLine.Amount;

        PurchInvLine.CalcSums(Quantity);
        Assert.AreEqual(1, PurchInvLine.Quantity, 'The quantity was not calculated correctly');

        Assert.AreEqual(GetLineAmountToForceRounding(), PostedAmount, 'The rounding amount was not distributed correctly');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    procedure TestReplaceAllocationAccountWithLinesPerQuantityGLAllocation()
    var
        FirstDestinationGLAccount: Record "G/L Account";
        SecondDestinationGLAccount: Record "G/L Account";
        ThirdDestinationGLAccount: Record "G/L Account";
        FirstBreakdownGLAccount: Record "G/L Account";
        SecondBreakdownGLAccount: Record "G/L Account";
        ThirdBreakdownGLAccount: Record "G/L Account";
        BalancingGLAccount: Record "G/L Account";
        AllocationAccount: Record "Allocation Account";
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
        AllocationAccountPage: TestPage "Allocation Account";
        PurchaseInvoice: TestPage "Purchase Invoice";
        PostedAmount: Decimal;
    begin
        Initialize();

        // [GIVEN] Three GL accounts with dimensions and balances, one Balancing G/L Account and three Destination G/L Accounts
        CreateBreakdownAccountsWithBalances(FirstBreakdownGLAccount, SecondBreakdownGLAccount, ThirdBreakdownGLAccount);
        FirstDestinationGLAccount.Get(CreateGLAccount());
        SecondDestinationGLAccount.Get(CreateGLAccount());
        ThirdDestinationGLAccount.Get(CreateGLAccount());
        BalancingGLAccount.Get(CreateGLAccount());

        // [GIVEN] An Allocation Account with variable GL distributions
        AllocationAccount.Get(CreateAllocationAccountWithVariableDistribution(AllocationAccountPage));
        AllocationAccount."Document Lines Split" := AllocationAccount."Document Lines Split"::"Split Quantity";
        AllocationAccount.Modify();

        AddGLDestinationAccountForVariableDistribution(AllocationAccountPage, FirstDestinationGLAccount);
        AddGLBreakdownAccountForVariableDistribution(AllocationAccountPage, FirstBreakdownGLAccount);

        AllocationAccountPage.VariableAccountDistribution.New();
        AddGLDestinationAccountForVariableDistribution(AllocationAccountPage, SecondDestinationGLAccount);
        AddGLBreakdownAccountForVariableDistribution(AllocationAccountPage, SecondBreakdownGLAccount);

        AllocationAccountPage.VariableAccountDistribution.New();
        AddGLDestinationAccountForVariableDistribution(AllocationAccountPage, ThirdDestinationGLAccount);
        AddGLBreakdownAccountForVariableDistribution(AllocationAccountPage, ThirdBreakdownGLAccount);
        AllocationAccountPage.Close();

        // [GIVEN] The Purchase Invoice with an Item and a Allocation Account
        CreatePurchaseInvoice(AllocationAccount."No.", PurchaseInvoice, PurchaseHeader);

        // [WHEN] The Purchase Invoice is posted
        PurchaseInvoice.PurchLines.ReplaceAllocationAccountWithLines.Invoke();
        PurchaseInvoice.Post.Invoke();
        PurchInvHeader.SetRange("Draft Invoice SystemId", PurchaseHeader.SystemId);
        PurchInvHeader.FindFirst();

        // [THEN] The costs are split into mulitple ledger entries which has the same dimension code
        PurchInvLine.SetRange("Document No.", PurchInvHeader."No.");
        PurchInvLine.SetRange("No.", FirstDestinationGLAccount."No.");
        Assert.AreEqual(1, PurchInvLine.Count(), 'Wrong number of Purchase Invoice Lines created for the first destination account');
        PurchInvLine.FindFirst();
        VerifyPurchaseLineAmount(PurchInvLine, GetLineAmountToForceRounding(), 6);
        PostedAmount := PurchInvLine.Amount;

        PurchInvLine.SetRange("No.", SecondDestinationGLAccount."No.");
        Assert.AreEqual(1, PurchInvLine.Count(), 'Wrong number of Purchase Invoice Lines for the second destination account');
        PurchInvLine.FindFirst();
        VerifyPurchaseLineAmount(PurchInvLine, GetLineAmountToForceRounding(), 3);
        PostedAmount += PurchInvLine.Amount;

        PurchInvLine.SetRange("No.", ThirdDestinationGLAccount."No.");
        Assert.AreEqual(1, PurchInvLine.Count(), 'Wrong number of Purchase Invoice Lines for the second destination account');
        PurchInvLine.FindFirst();
        VerifyPurchaseLineAmount(PurchInvLine, GetLineAmountToForceRounding(), 2);
        PostedAmount += PurchInvLine.Amount;

        PurchInvLine.CalcSums(Quantity);
        Assert.AreEqual(1, PurchInvLine.Quantity, 'The quantity was not calculated correctly');

        Assert.AreEqual(GetLineAmountToForceRounding(), PostedAmount, 'The rounding amount was not distributed correctly');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    procedure TestReplaceAllocationAccountWithLinesPerAmountGLAllocation()
    var
        FirstDestinationGLAccount: Record "G/L Account";
        SecondDestinationGLAccount: Record "G/L Account";
        ThirdDestinationGLAccount: Record "G/L Account";
        FirstBreakdownGLAccount: Record "G/L Account";
        SecondBreakdownGLAccount: Record "G/L Account";
        ThirdBreakdownGLAccount: Record "G/L Account";
        BalancingGLAccount: Record "G/L Account";
        AllocationAccount: Record "Allocation Account";
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
        AllocationAccountPage: TestPage "Allocation Account";
        PurchaseInvoice: TestPage "Purchase Invoice";
        PostedAmount: Decimal;
    begin
        Initialize();

        // [GIVEN] Three GL accounts with dimensions and balances, one Balancing G/L Account and three Destination G/L Accounts
        CreateBreakdownAccountsWithBalances(FirstBreakdownGLAccount, SecondBreakdownGLAccount, ThirdBreakdownGLAccount);
        FirstDestinationGLAccount.Get(CreateGLAccount());
        SecondDestinationGLAccount.Get(CreateGLAccount());
        ThirdDestinationGLAccount.Get(CreateGLAccount());
        BalancingGLAccount.Get(CreateGLAccount());

        // [GIVEN] An Allocation Account with variable GL distributions
        AllocationAccount.Get(CreateAllocationAccountWithVariableDistribution(AllocationAccountPage));

        AddGLDestinationAccountForVariableDistribution(AllocationAccountPage, FirstDestinationGLAccount);
        AddGLBreakdownAccountForVariableDistribution(AllocationAccountPage, FirstBreakdownGLAccount);

        AllocationAccountPage.VariableAccountDistribution.New();
        AddGLDestinationAccountForVariableDistribution(AllocationAccountPage, SecondDestinationGLAccount);
        AddGLBreakdownAccountForVariableDistribution(AllocationAccountPage, SecondBreakdownGLAccount);

        AllocationAccountPage.VariableAccountDistribution.New();
        AddGLDestinationAccountForVariableDistribution(AllocationAccountPage, ThirdDestinationGLAccount);
        AddGLBreakdownAccountForVariableDistribution(AllocationAccountPage, ThirdBreakdownGLAccount);
        AllocationAccountPage.Close();

        // [GIVEN] The Purchase Invoice with an Item and a Allocation Account
        CreatePurchaseInvoice(AllocationAccount."No.", PurchaseInvoice, PurchaseHeader);

        // [WHEN] The Purchase Invoice is posted
        PurchaseInvoice.PurchLines.ReplaceAllocationAccountWithLines.Invoke();
        PurchaseInvoice.Post.Invoke();
        PurchInvHeader.SetRange("Draft Invoice SystemId", PurchaseHeader.SystemId);
        PurchInvHeader.FindFirst();

        // [THEN] The costs are split into mulitple ledger entries which has the same dimension code
        PurchInvLine.SetRange("Document No.", PurchInvHeader."No.");
        PurchInvLine.SetRange(Type, PurchInvLine.Type::"G/L Account");
        PurchInvLine.CalcSums(Quantity);
        Assert.AreEqual(3, PurchInvLine.Quantity, 'The quantity was not calculated correctly');

        PurchInvLine.SetRange("No.", FirstDestinationGLAccount."No.");
        Assert.AreEqual(1, PurchInvLine.Count(), 'Wrong number of Purchase Invoice Lines created for the first destination account');

        PurchInvLine.FindFirst();
        VerifyPurchaseLineAmount(PurchInvLine, GetLineAmountToForceRounding(), 6);
        PostedAmount := PurchInvLine.Amount;

        PurchInvLine.SetRange("No.", SecondDestinationGLAccount."No.");
        Assert.AreEqual(1, PurchInvLine.Count(), 'Wrong number of Purchase Invoice Lines for the second destination account');
        PurchInvLine.FindFirst();
        VerifyPurchaseLineAmount(PurchInvLine, GetLineAmountToForceRounding(), 3);
        PostedAmount += PurchInvLine.Amount;

        PurchInvLine.SetRange("No.", ThirdDestinationGLAccount."No.");
        Assert.AreEqual(1, PurchInvLine.Count(), 'Wrong number of Purchase Invoice Lines for the second destination account');
        PurchInvLine.FindFirst();
        VerifyPurchaseLineAmount(PurchInvLine, GetLineAmountToForceRounding(), 2);
        PostedAmount += PurchInvLine.Amount;

        Assert.AreEqual(GetLineAmountToForceRounding(), PostedAmount, 'The rounding amount was not distributed correctly');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,HandleEditDimensionSetEntriesPage')]
    procedure TestAllocateToSameAccountFixedPerQuantityGLAllocation()
    var
        FirstDimensionValue: Record "Dimension Value";
        SecondDimensionValue: Record "Dimension Value";
        ThirdDimensionValue: Record "Dimension Value";
        DestinationGLAccount: Record "G/L Account";
        FirstBreakdownGLAccount: Record "G/L Account";
        SecondBreakdownGLAccount: Record "G/L Account";
        ThirdBreakdownGLAccount: Record "G/L Account";
        BalancingGLAccount: Record "G/L Account";
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoiceLine: Record "Purch. Inv. Line";
        AllocationAccount: Record "Allocation Account";
        PurchaseInvoiceHeader: Record "Purch. Inv. Header";
        PurchaseInvoice: TestPage "Purchase Invoice";
        PostedAmount: Decimal;
    begin
        Initialize();

        // [GIVEN] A dimension that is defined as a department with three values
        CreateDimensionsWithValues(FirstDimensionValue, SecondDimensionValue, ThirdDimensionValue);

        // [GIVEN] Three GL accounts with dimensions and balances and one Balancing G/L Account
        CreateBreakdownAccountsWithBalances(FirstBreakdownGLAccount, SecondBreakdownGLAccount, ThirdBreakdownGLAccount);
        DestinationGLAccount.Get(CreateGLAccount());
        BalancingGLAccount.Get(CreateGLAccount());

        // [GIVEN] An Allocation Account with variable GL distributions
        CreateAllocationAccountwithFixedGLDistributions(AllocationAccount, FirstDimensionValue, SecondDimensionValue, ThirdDimensionValue, DestinationGLAccount);
        AllocationAccount."Document Lines Split" := AllocationAccount."Document Lines Split"::"Split Quantity";
        AllocationAccount.Modify();

        // [GIVEN] The Purchase Invoice with Item and Allocation account
        CreatePurchaseInvoice(AllocationAccount."No.", PurchaseInvoice, PurchaseHeader);

        // [WHEN] The Purchase Invoice is posted
        PurchaseInvoice.Post.Invoke();
        PurchaseInvoiceHeader.SetRange("Draft Invoice SystemId", PurchaseHeader.SystemId);
        PurchaseInvoiceHeader.FindFirst();

        // [THEN] The costs are split into mulitple ledger entries which has the same dimension code
        PurchaseInvoiceLine.SetRange("Document No.", PurchaseInvoiceHeader."No.");
        PurchaseInvoiceLine.SetRange(Type, PurchaseInvoiceLine.Type::"G/L Account");
        Assert.AreEqual(3, PurchaseInvoiceLine.Count(), 'Wrong number of Purchase Invoice Lines created for the destination account');
        PurchaseInvoiceLine.CalcSums(Quantity);
        Assert.AreEqual(1, PurchaseInvoiceLine.Quantity, 'The quantity was not calculated correctly');

        FirstDimensionValue.SetRecFilter();
        PurchaseInvoiceLine.SetRange("Dimension Set ID", CreateDimensionSetID(FirstDimensionValue));
        Assert.AreEqual(1, PurchaseInvoiceLine.Count(), 'Wrong number of Purchase Invoice Lines for the first line');
        PurchaseInvoiceLine.FindFirst();
        VerifyPurchaseLineAmount(PurchaseInvoiceLine, GetLineAmountToForceRounding(), 6);
        PostedAmount := PurchaseInvoiceLine.Amount;

        SecondDimensionValue.SetRecFilter();
        PurchaseInvoiceLine.SetRange("Dimension Set ID", CreateDimensionSetID(SecondDimensionValue));
        Assert.AreEqual(1, PurchaseInvoiceLine.Count(), 'Wrong number of Purchase Invoice Lines for the second line');
        PurchaseInvoiceLine.FindFirst();
        VerifyPurchaseLineAmount(PurchaseInvoiceLine, GetLineAmountToForceRounding(), 3);
        PostedAmount += PurchaseInvoiceLine.Amount;

        ThirdDimensionValue.SetRecFilter();
        PurchaseInvoiceLine.SetRange("Dimension Set ID", CreateDimensionSetID(ThirdDimensionValue));
        Assert.AreEqual(1, PurchaseInvoiceLine.Count(), 'Wrong number of Purchase Invoice Lines for the third line');
        PurchaseInvoiceLine.FindFirst();
        VerifyPurchaseLineAmount(PurchaseInvoiceLine, GetLineAmountToForceRounding(), 2);
        PostedAmount += PurchaseInvoiceLine.Amount;

        Assert.AreEqual(GetLineAmountToForceRounding(), PostedAmount, 'The rounding amount was not distributed correctly');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,HandleEditDimensionSetEntriesPage,OverrideGLDistributions')]
    procedure TestOverrideGLAllocationIsDeletedIfLineChanged()
    var
        FirstDimensionValue: Record "Dimension Value";
        SecondDimensionValue: Record "Dimension Value";
        ThirdDimensionValue: Record "Dimension Value";
        OverrideFirstDimensionValue: Record "Dimension Value";
        OverrideSecondDimensionValue: Record "Dimension Value";
        OverrideThirdDimensionValue: Record "Dimension Value";
        DestinationGLAccount: Record "G/L Account";
        FirstBreakdownGLAccount: Record "G/L Account";
        SecondBreakdownGLAccount: Record "G/L Account";
        ThirdBreakdownGLAccount: Record "G/L Account";
        BalancingGLAccount: Record "G/L Account";
        PurchaseHeader: Record "Purchase Header";
        AllocationAccount: Record "Allocation Account";
        AllocAccManualOverride: Record "Alloc. Acc. Manual Override";
        PurchaseInvoice: TestPage "Purchase Invoice";
        NewAmount: Decimal;
    begin
        Initialize();

        // [GIVEN] A dimension that is defined as a department with three values
        CreateDimensionsWithValues(FirstDimensionValue, SecondDimensionValue, ThirdDimensionValue);
        CreateDimensionsWithValues(OverrideFirstDimensionValue, OverrideSecondDimensionValue, OverrideThirdDimensionValue);

        // [GIVEN] Three GL accounts with dimensions and balances and one Balancing G/L Account
        CreateBreakdownAccountsWithBalances(FirstBreakdownGLAccount, SecondBreakdownGLAccount, ThirdBreakdownGLAccount);
        DestinationGLAccount.Get(CreateGLAccount());
        BalancingGLAccount.Get(CreateGLAccount());

        // [GIVEN] An Allocation Account with variable GL distributions
        CreateAllocationAccountwithVariableGLDistributions(AllocationAccount, FirstDimensionValue, SecondDimensionValue, ThirdDimensionValue, DestinationGLAccount, FirstBreakdownGLAccount, SecondBreakdownGLAccount, ThirdBreakdownGLAccount);

        // [GIVEN] The Purchase Invoice with Item and Allocation account
        CreatePurchaseInvoice(AllocationAccount."No.", PurchaseInvoice, PurchaseHeader);

        // [GIVEN] User defines an override manually
        LibraryVariableStorage.Enqueue(GetLineAmountToForceRounding());
        LibraryVariableStorage.Enqueue(OverrideFirstDimensionValue.SystemId);
        LibraryVariableStorage.Enqueue(OverrideSecondDimensionValue.SystemId);
        LibraryVariableStorage.Enqueue(OverrideThirdDimensionValue.SystemId);
        PurchaseInvoice.PurchLines.RedistributeAccAllocations.Invoke();
        Assert.IsFalse(AllocAccManualOverride.IsEmpty(), 'The manual override was not created');

        // [WHEN] The General Journal line is modified
        PurchaseInvoice.PurchLines.First();
        PurchaseInvoice.PurchLines.Next();
        NewAmount := Round(GetLineAmountToForceRounding() / 2, 0.01);
        PurchaseInvoice.PurchLines."Line Amount".SetValue(NewAmount);
        PurchaseInvoice.PurchLines.First();

        // [THEN] Manual overrides are deleted
        Assert.IsTrue(AllocAccManualOverride.IsEmpty(), 'The manual override was not deleted');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,HandleEditDimensionSetEntriesPage')]
    procedure TestAllocateToSameAccountFixedGLAllocation()
    var
        FirstDimensionValue: Record "Dimension Value";
        SecondDimensionValue: Record "Dimension Value";
        ThirdDimensionValue: Record "Dimension Value";
        DestinationGLAccount: Record "G/L Account";
        FirstBreakdownGLAccount: Record "G/L Account";
        SecondBreakdownGLAccount: Record "G/L Account";
        ThirdBreakdownGLAccount: Record "G/L Account";
        BalancingGLAccount: Record "G/L Account";
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoiceLine: Record "Purch. Inv. Line";
        AllocationAccount: Record "Allocation Account";
        PurchaseInvoiceHeader: Record "Purch. Inv. Header";
        PurchaseInvoice: TestPage "Purchase Invoice";
        PostedAmount: Decimal;
    begin
        Initialize();

        // [GIVEN] A dimension that is defined as a department with three values
        CreateDimensionsWithValues(FirstDimensionValue, SecondDimensionValue, ThirdDimensionValue);

        // [GIVEN] Three GL accounts with dimensions and balances and one Balancing G/L Account
        CreateBreakdownAccountsWithBalances(FirstBreakdownGLAccount, SecondBreakdownGLAccount, ThirdBreakdownGLAccount);
        DestinationGLAccount.Get(CreateGLAccount());
        BalancingGLAccount.Get(CreateGLAccount());

        // [GIVEN] An Allocation Account with variable GL distributions
        CreateAllocationAccountwithFixedGLDistributions(AllocationAccount, FirstDimensionValue, SecondDimensionValue, ThirdDimensionValue, DestinationGLAccount);

        // [GIVEN] The Purchase Invoice with Item and Allocation account
        CreatePurchaseInvoice(AllocationAccount."No.", PurchaseInvoice, PurchaseHeader);

        // [WHEN] The Purchase Invoice is posted
        PurchaseInvoice.Post.Invoke();
        PurchaseInvoiceHeader.SetRange("Draft Invoice SystemId", PurchaseHeader.SystemId);
        PurchaseInvoiceHeader.FindFirst();

        // [THEN] The costs are split into mulitple ledger entries which has the same dimension code
        PurchaseInvoiceLine.SetRange("Document No.", PurchaseInvoiceHeader."No.");
        Assert.AreEqual(4, PurchaseInvoiceLine.Count(), 'Wrong number of Purch. Inv. Lines created for the destination account');

        FirstDimensionValue.SetRecFilter();
        PurchaseInvoiceLine.SetRange("Dimension Set ID", CreateDimensionSetID(FirstDimensionValue));
        Assert.AreEqual(1, PurchaseInvoiceLine.Count(), 'Wrong number of Purch. Inv. Lines for the first line');
        PurchaseInvoiceLine.FindFirst();
        VerifyPurchaseLineAmount(PurchaseInvoiceLine, GetLineAmountToForceRounding(), 6);
        PostedAmount := PurchaseInvoiceLine.Amount;

        SecondDimensionValue.SetRecFilter();
        PurchaseInvoiceLine.SetRange("Dimension Set ID", CreateDimensionSetID(SecondDimensionValue));
        Assert.AreEqual(1, PurchaseInvoiceLine.Count(), 'Wrong number of Purch. Inv. Lines for the second line');
        PurchaseInvoiceLine.FindFirst();
        VerifyPurchaseLineAmount(PurchaseInvoiceLine, GetLineAmountToForceRounding(), 3);
        PostedAmount += PurchaseInvoiceLine.Amount;

        ThirdDimensionValue.SetRecFilter();
        PurchaseInvoiceLine.SetRange("Dimension Set ID", CreateDimensionSetID(ThirdDimensionValue));
        Assert.AreEqual(1, PurchaseInvoiceLine.Count(), 'Wrong number of Purch. Inv. Lines for the third line');
        PurchaseInvoiceLine.FindFirst();
        VerifyPurchaseLineAmount(PurchaseInvoiceLine, GetLineAmountToForceRounding(), 2);
        PostedAmount += PurchaseInvoiceLine.Amount;

        Assert.AreEqual(GetLineAmountToForceRounding(), PostedAmount, 'The rounding amount was not distributed correctly');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    procedure TestAllocateToDifferentAccountsInheritFromParentVariableGLAllocation()
    var
        FirstDestinationGLAccount: Record "G/L Account";
        SecondDestinationGLAccount: Record "G/L Account";
        ThirdDestinationGLAccount: Record "G/L Account";
        FirstBreakdownGLAccount: Record "G/L Account";
        SecondBreakdownGLAccount: Record "G/L Account";
        ThirdBreakdownGLAccount: Record "G/L Account";
        BalancingGLAccount: Record "G/L Account";
        AllocationAccount: Record "Allocation Account";
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoiceHeader: Record "Purch. Inv. Header";
        PurchaseInvoiceLine: Record "Purch. Inv. Line";
        AllocationAccountPage: TestPage "Allocation Account";
        PurchaseInvoice: TestPage "Purchase Invoice";
        PostedAmount: Decimal;
    begin
        Initialize();

        // [GIVEN] Three GL accounts with dimensions and balances, one Balancing G/L Account and three Destination G/L Accounts
        CreateBreakdownAccountsWithBalances(FirstBreakdownGLAccount, SecondBreakdownGLAccount, ThirdBreakdownGLAccount);
        FirstDestinationGLAccount.Get(CreateGLAccount());
        SecondDestinationGLAccount.Get(CreateGLAccount());
        ThirdDestinationGLAccount.Get(CreateGLAccount());
        BalancingGLAccount.Get(CreateGLAccount());

        // [GIVEN] An Allocation Account with variable GL distributions
        AllocationAccount.Get(CreateAllocationAccountWithVariableDistribution(AllocationAccountPage));
        AddInheritFromParentForVariableDistribution(AllocationAccountPage);
        AddGLBreakdownAccountForVariableDistribution(AllocationAccountPage, FirstBreakdownGLAccount);

        AllocationAccountPage.VariableAccountDistribution.New();
        AddGLDestinationAccountForVariableDistribution(AllocationAccountPage, SecondDestinationGLAccount);
        AddGLBreakdownAccountForVariableDistribution(AllocationAccountPage, SecondBreakdownGLAccount);

        AllocationAccountPage.VariableAccountDistribution.New();
        AddGLDestinationAccountForVariableDistribution(AllocationAccountPage, ThirdDestinationGLAccount);
        AddGLBreakdownAccountForVariableDistribution(AllocationAccountPage, ThirdBreakdownGLAccount);
        AllocationAccountPage.Close();

        // [GIVEN] The Purchase Invoice with an Item and a Allocation Account
        CreatePurchaseInvoiceWithInheritFromParent(FirstDestinationGLAccount."No.", AllocationAccount."No.", PurchaseInvoice, PurchaseHeader);

        // [WHEN] The Purchase Invoice is posted
        PurchaseInvoice.Post.Invoke();
        PurchaseInvoiceHeader.SetRange("Draft Invoice SystemId", PurchaseHeader.SystemId);
        PurchaseInvoiceHeader.FindFirst();

        // [THEN] The costs are split into mulitple ledger entries which has the same dimension code
        PurchaseInvoiceLine.SetRange("Document No.", PurchaseInvoiceHeader."No.");
        PurchaseInvoiceLine.SetRange("No.", FirstDestinationGLAccount."No.");
        Assert.AreEqual(1, PurchaseInvoiceLine.Count(), 'Wrong number of Purch. Inv. Lines created for the first destination account');
        PurchaseInvoiceLine.FindFirst();
        VerifyPurchaseLineAmount(PurchaseInvoiceLine, GetLineAmountToForceRounding(), 6);
        PostedAmount := PurchaseInvoiceLine.Amount;

        PurchaseInvoiceLine.SetRange("No.", SecondDestinationGLAccount."No.");
        Assert.AreEqual(1, PurchaseInvoiceLine.Count(), 'Wrong number of Purch. Inv. Lines for the second destination account');
        PurchaseInvoiceLine.FindFirst();
        VerifyPurchaseLineAmount(PurchaseInvoiceLine, GetLineAmountToForceRounding(), 3);
        PostedAmount += PurchaseInvoiceLine.Amount;

        PurchaseInvoiceLine.SetRange("No.", ThirdDestinationGLAccount."No.");
        Assert.AreEqual(1, PurchaseInvoiceLine.Count(), 'Wrong number of Purch. Inv. Lines for the second destination account');
        PurchaseInvoiceLine.FindFirst();
        VerifyPurchaseLineAmount(PurchaseInvoiceLine, GetLineAmountToForceRounding(), 2);
        PostedAmount += PurchaseInvoiceLine.Amount;

        Assert.AreEqual(GetLineAmountToForceRounding(), PostedAmount, 'The rounding amount was not distributed correctly');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,HandleEditDimensionSetEntriesPage')]
    procedure TestAllocateToSameAccountDifferentDimensionsVariableGLAllocationIntheritFromParent()
    var
        FirstDimensionValue: Record "Dimension Value";
        SecondDimensionValue: Record "Dimension Value";
        ThirdDimensionValue: Record "Dimension Value";
        DestinationGLAccount: Record "G/L Account";
        FirstBreakdownGLAccount: Record "G/L Account";
        SecondBreakdownGLAccount: Record "G/L Account";
        ThirdBreakdownGLAccount: Record "G/L Account";
        BalancingGLAccount: Record "G/L Account";
        AllocationAccount: Record "Allocation Account";
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoiceLine: Record "Purch. Inv. Line";
        PurchaseInvoiceHeader: Record "Purch. Inv. Header";
        PurchaseInvoice: TestPage "Purchase Invoice";
        PostedAmount: Decimal;
    begin
        Initialize();

        // [GIVEN] A dimension that is defined as a department with three values
        CreateDimensionsWithValues(FirstDimensionValue, SecondDimensionValue, ThirdDimensionValue);

        // [GIVEN] Three GL accounts with dimensions and balances and one Balancing G/L Account
        CreateBreakdownAccountsWithBalances(FirstBreakdownGLAccount, SecondBreakdownGLAccount, ThirdBreakdownGLAccount);
        DestinationGLAccount.Get(CreateGLAccount());
        BalancingGLAccount.Get(CreateGLAccount());

        // [GIVEN] An Allocation Account with variable GL distributions
        CreateAllocationAccountwithVariableGLDistributionsAndInheritFromParent(AllocationAccount, FirstDimensionValue, SecondDimensionValue, ThirdDimensionValue, FirstBreakdownGLAccount, SecondBreakdownGLAccount, ThirdBreakdownGLAccount);

        // [GIVEN] The Purchase Invoice with Item and Allocation account
        CreatePurchaseInvoiceWithInheritFromParent(DestinationGLAccount."No.", AllocationAccount."No.", PurchaseInvoice, PurchaseHeader);

        // [WHEN] The Purchase Invoice is posted
        PurchaseInvoice.Post.Invoke();
        PurchaseInvoiceHeader.SetRange("Draft Invoice SystemId", PurchaseHeader.SystemId);
        PurchaseInvoiceHeader.FindFirst();

        // [THEN] The costs are split into mulitple ledger entries which has the same dimension code
        PurchaseInvoiceLine.SetRange("Document No.", PurchaseInvoiceHeader."No.");
        PurchaseInvoiceLine.SetRange("No.", DestinationGLAccount."No.");

        FirstDimensionValue.SetRecFilter();
        PurchaseInvoiceLine.SetRange("Dimension Set ID", CreateDimensionSetID(FirstDimensionValue));
        Assert.AreEqual(1, PurchaseInvoiceLine.Count(), 'Wrong number of Purch. Inv. Lines created for the first destination account');
        PurchaseInvoiceLine.FindFirst();
        VerifyPurchaseLineAmount(PurchaseInvoiceLine, GetLineAmountToForceRounding(), 6);
        PostedAmount := PurchaseInvoiceLine.Amount;

        SecondDimensionValue.SetRecFilter();
        PurchaseInvoiceLine.SetRange("Dimension Set ID", CreateDimensionSetID(SecondDimensionValue));
        Assert.AreEqual(1, PurchaseInvoiceLine.Count(), 'Wrong number of Purch. Inv. Lines for the second destination account');
        PurchaseInvoiceLine.FindFirst();
        VerifyPurchaseLineAmount(PurchaseInvoiceLine, GetLineAmountToForceRounding(), 3);
        PostedAmount += PurchaseInvoiceLine.Amount;

        ThirdDimensionValue.SetRecFilter();
        PurchaseInvoiceLine.SetRange("Dimension Set ID", CreateDimensionSetID(ThirdDimensionValue));
        Assert.AreEqual(1, PurchaseInvoiceLine.Count(), 'Wrong number of Purch. Inv. Lines for the second destination account');
        PurchaseInvoiceLine.FindFirst();
        VerifyPurchaseLineAmount(PurchaseInvoiceLine, GetLineAmountToForceRounding(), 2);
        PostedAmount += PurchaseInvoiceLine.Amount;
        Assert.AreEqual(GetLineAmountToForceRounding(), PostedAmount, 'The rounding amount was not distributed correctly');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,HandleEditDimensionSetEntriesPage,OverrideGLDistributions')]
    procedure TestOverrideGLAllocationInheritFromParent()
    var
        FirstDimensionValue: Record "Dimension Value";
        SecondDimensionValue: Record "Dimension Value";
        ThirdDimensionValue: Record "Dimension Value";
        OverrideFirstDimensionValue: Record "Dimension Value";
        OverrideSecondDimensionValue: Record "Dimension Value";
        OverrideThirdDimensionValue: Record "Dimension Value";
        DestinationGLAccount: Record "G/L Account";
        FirstBreakdownGLAccount: Record "G/L Account";
        SecondBreakdownGLAccount: Record "G/L Account";
        ThirdBreakdownGLAccount: Record "G/L Account";
        BalancingGLAccount: Record "G/L Account";
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoiceLine: Record "Purch. Inv. Line";
        AllocationAccount: Record "Allocation Account";
        AllocAccManualOverride: Record "Alloc. Acc. Manual Override";
        PurchaseInvoiceHeader: Record "Purch. Inv. Header";
        PurchaseInvoice: TestPage "Purchase Invoice";
        PostedAmount: Decimal;
    begin
        Initialize();

        // [GIVEN] A dimension that is defined as a department with three values
        CreateDimensionsWithValues(FirstDimensionValue, SecondDimensionValue, ThirdDimensionValue);
        CreateDimensionsWithValues(OverrideFirstDimensionValue, OverrideSecondDimensionValue, OverrideThirdDimensionValue);

        // [GIVEN] Three GL accounts with dimensions and balances and one Balancing G/L Account
        CreateBreakdownAccountsWithBalances(FirstBreakdownGLAccount, SecondBreakdownGLAccount, ThirdBreakdownGLAccount);
        DestinationGLAccount.Get(CreateGLAccount());
        BalancingGLAccount.Get(CreateGLAccount());

        // [GIVEN] An Allocation Account with variable GL distributions
        CreateAllocationAccountwithVariableGLDistributionsAndInheritFromParent(AllocationAccount, FirstDimensionValue, SecondDimensionValue, ThirdDimensionValue, FirstBreakdownGLAccount, SecondBreakdownGLAccount, ThirdBreakdownGLAccount);

        // [GIVEN] The Purchase Invoice with Item and Allocation account
        CreatePurchaseInvoiceWithInheritFromParent(DestinationGLAccount."No.", AllocationAccount."No.", PurchaseInvoice, PurchaseHeader);

        // [GIVEN] User defines an override manually
        LibraryVariableStorage.Enqueue(GetLineAmountToForceRounding());
        LibraryVariableStorage.Enqueue(OverrideFirstDimensionValue.SystemId);
        LibraryVariableStorage.Enqueue(OverrideSecondDimensionValue.SystemId);
        LibraryVariableStorage.Enqueue(OverrideThirdDimensionValue.SystemId);
        PurchaseInvoice.PurchLines.RedistributeAccAllocations.Invoke();

        // [WHEN] The Purchase Invoice is posted
        PurchaseInvoice.Post.Invoke();
        PurchaseInvoiceHeader.SetRange("Draft Invoice SystemId", PurchaseHeader.SystemId);
        PurchaseInvoiceHeader.FindFirst();

        // [THEN] The costs are split into mulitple ledger entries which has the same dimension code
        PurchaseInvoiceLine.SetRange("Document No.", PurchaseInvoiceHeader."No.");
        Assert.AreEqual(4, PurchaseInvoiceLine.Count(), 'Wrong number of Purch. Inv. Lines created for the destination account');

        // [THEN] Override values are used
        FirstDimensionValue.SetRecFilter();
        OverrideFirstDimensionValue.SetFilter(SystemId, '%1|%2', FirstDimensionValue.SystemId, OverrideFirstDimensionValue.SystemId);
        PurchaseInvoiceLine.SetRange("Dimension Set ID", CreateDimensionSetID(OverrideFirstDimensionValue));
        Assert.AreEqual(1, PurchaseInvoiceLine.Count(), 'Wrong number of Purch. Inv. Lines for the first breakdown account');
        PurchaseInvoiceLine.FindFirst();
        Assert.AreEqual(GetOverrideAmount(), PurchaseInvoiceLine."Line Amount", 'The override amount was not used');
        PostedAmount := PurchaseInvoiceLine."Line Amount";

        SecondDimensionValue.SetRecFilter();
        OverrideSecondDimensionValue.SetFilter(SystemId, '%1|%2', SecondDimensionValue.SystemId, OverrideSecondDimensionValue.SystemId);
        PurchaseInvoiceLine.SetRange("Dimension Set ID", CreateDimensionSetID(OverrideSecondDimensionValue));
        Assert.AreEqual(1, PurchaseInvoiceLine.Count(), 'Wrong number of Purch. Inv. Lines for the second breakdown account');
        PurchaseInvoiceLine.FindFirst();
        Assert.AreEqual(GetOverrideAmount(), PurchaseInvoiceLine."Line Amount", 'The override amount was not used');
        PostedAmount += PurchaseInvoiceLine."Line Amount";

        ThirdDimensionValue.SetRecFilter();
        OverrideThirdDimensionValue.SetFilter(SystemId, '%1|%2', ThirdDimensionValue.SystemId, OverrideThirdDimensionValue.SystemId);
        PurchaseInvoiceLine.SetRange("Dimension Set ID", CreateDimensionSetID(OverrideThirdDimensionValue));
        Assert.AreEqual(1, PurchaseInvoiceLine.Count(), 'Wrong number of Purch. Inv. Lines for the third breakdown account');
        PurchaseInvoiceLine.FindFirst();
        PostedAmount += PurchaseInvoiceLine."Line Amount";

        Assert.AreEqual(GetLineAmountToForceRounding(), PostedAmount, 'The rounding amount was not distributed correctly');
        Assert.IsTrue(AllocAccManualOverride.IsEmpty(), 'The manual override was not deleted');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    procedure PostPurchaseInvoiceWithAllocationAccountUsingSplitQuantity()
    var
        DestinationGLAccount: Record "G/L Account";
        AllocationAccount: Record "Allocation Account";
        PurchaseHeader: Record "Purchase Header";
        DimensionValue: array[2] of Record "Dimension Value";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
        PurchaseInvoice: TestPage "Purchase Invoice";
        Quantity: Integer;
        DirectUnitCost: Decimal;
        AmountIncludingVAT: Decimal;
    begin
        // [SCENARIO 539634] Purchase Invoice gets Posted with Allocation Account same as Inherit Parent and
        // as Breakdown Account Type equals GL Account.
        Initialize();

        // [GIVEN] Create a GL Account.
        DestinationGLAccount.Get(CreateGLAccount());

        // [GIVEN] Create a dimension that is defined as a department with two values.
        CreateDimensionsWithValues(DimensionValue);

        // [GIVEN] Create a Variable Allocation Account with Eight Distribution Lines and inherit from parent values.
        CreateVariableAllocationAccountwithEightDistributionLinesInheritFromParent(AllocationAccount, DestinationGLAccount."No.", DimensionValue);

        // [GIVEN] Generate Quantity and save it in a Variable.
        Quantity := LibraryRandom.RandIntInRange(6497, 6497);
        DirectUnitCost := LibraryRandom.RandDecInDecimalRange(1.96, 1.96, 2);

        // [GIVEN] Create a Purchase Invoice with Inherit
        CreatePurchaseInvoiceWithInheritFromParent(DestinationGLAccount."No.", AllocationAccount."No.", PurchaseInvoice, PurchaseHeader, Quantity, DirectUnitCost);

        // [GIVEN] Save the value in AmountIncludingVAT variable
        Evaluate(AmountIncludingVAT, PurchaseInvoice.DocAmount.Value());

        // [WHEN] The Purchase Invoice is posted
        PurchaseInvoice.Post.Invoke();
        PurchInvHeader.SetRange("Draft Invoice SystemId", PurchaseHeader.SystemId);
        PurchInvHeader.FindFirst();

        // [THEN] Verify the Amount Including VAT will be equal to Posted Purchase Invoice
        PurchInvLine.SetRange("Document No.", PurchInvHeader."No.");
        PurchInvLine.CalcSums("Amount Including VAT");
        Assert.AreEqual(AmountIncludingVAT, PurchInvLine."Amount Including VAT", AmountMustBeEqualErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    procedure PostPurchaseInvoiceWithAllocationAccountUsingFixAccountSplitAmount()
    var
        AllocationAccount: Record "Allocation Account";
        DimensionValue: array[2] of Record "Dimension Value";
        GLAccount: Record "G/L Account";
        PurchInvLine: Record "Purch. Inv. Line";
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseInvoice: TestPage "Purchase Invoice";
        Quantity: Decimal;
        UnitCost: Decimal;
        AmountIncludingVAT: Decimal;
    begin
        // [SCENARIO 572659] A Purchase Invoice with a G/L Account and Allocation Account generates correct
        // allocation of the Expense and include Canada Tax in the Allocation of the Purchase Invoice Line Amount
        Initialize();

        // [GIVEN] Assign the value for quantity, unit cost and amount
        Quantity := LibraryRandom.RandIntInRange(25, 25);
        UnitCost := LibraryRandom.RandDecInDecimalRange(26.85, 26.85, 2);

        // [GIVEN] Create a GL Account.
        GLAccount.Get((CreateGLAccount()));

        // [GIVEN] Create a dimension that is defined as a department with two values.
        CreateDimensionsWithNineValues(DimensionValue);

        // [GIVEN] Create a fixed Allocation Account with nine Distribution Lines and inherit from parent values.
        CreateFixedAllocationAccountWithNineDistributionLinesInheritFromParent(AllocationAccount, DimensionValue);

        // [GIVEN] Create a Purchase Invoice with Inherit
        CreatePurchaseInvoiceWithInheritFromParent(GLAccount."No.", AllocationAccount."No.", PurchaseInvoice, PurchaseHeader, Quantity, UnitCost);

        // [GIVEN] Save the value in AmountIncludingVAT variable
        Evaluate(AmountIncludingVAT, PurchaseInvoice.DocAmount.Value());

        // [WHEN] The Purchase Invoice is posted
        PurchaseInvoice.Post.Invoke();
        PurchInvHeader.SetRange("Draft Invoice SystemId", PurchaseHeader.SystemId);
        PurchInvHeader.FindFirst();

        // [THEN] Verify G/L entry will be posted with correct amount.
        PurchInvLine.SetRange("Document No.", PurchInvHeader."No.");
        PurchInvLine.CalcSums("Amount Including VAT");
        Assert.AreEqual(AmountIncludingVAT, PurchInvLine."Amount Including VAT", AmountMustBeEqualErr);
    end;

    [Test]
    procedure TestAllocationAccountWithPricesIncludingVAT()
    var
        FirstDestinationGLAccount: Record "G/L Account";
        SecondDestinationGLAccount: Record "G/L Account";
        AllocationAccount: Record "Allocation Account";
        GeneralPostingSetup: Record "General Posting Setup";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATProductPostingGroup: array[2] of Record "VAT Product Posting Group";
        VATPostingSetup: array[2] of Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorNo: Code[20];
        AllocationAmount: Decimal;
        ExpectedVATExclusiveAmount1: Decimal;
        ExpectedVATExclusiveAmount2: Decimal;
        ExpectedVATAmount1: Decimal;
        ExpectedVATAmount2: Decimal;
    begin
        // [SCENARIO 603705] Purchase Invoice with Allocation Account and Prices Incl. VAT leads to incorrect VAT and G/L Entries.
        Initialize();

        // [GIVEN] Create two destination G/L accounts with different VAT setups
        // First account with 19% VAT
        LibraryERM.FindGeneralPostingSetupInvtFull(GeneralPostingSetup);
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup[1]);
        CreateVATPostingSetupWithSalesPurchAcc(VATPostingSetup[1], VATBusinessPostingGroup.Code, VATProductPostingGroup[1].Code, VATPostingSetup[1]."VAT Calculation Type"::"Normal VAT", 19);
        FirstDestinationGLAccount.Get(
            LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup[1], "General Posting Type"::Purchase));

        // Second account with 0% VAT 
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup[2]);
        CreateVATPostingSetupWithSalesPurchAcc(VATPostingSetup[2], VATBusinessPostingGroup.Code, VATProductPostingGroup[2].Code, VATPostingSetup[2]."VAT Calculation Type"::"Normal VAT", 0);
        SecondDestinationGLAccount.Get(
            LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup[2], "General Posting Type"::Purchase));

        // [GIVEN] Create a fixed allocation account with 77% to first account (with VAT) and 23% to second account (no VAT)
        CreateFixedAllocationAccountWithTwoDistributions(AllocationAccount,
            FirstDestinationGLAccount."No.", 77, SecondDestinationGLAccount."No.", 23);

        // [GIVEN] Create a vendor and purchase invoice with "Prices Including VAT" = true
        VendorNo := LibraryPurchase.CreateVendorWithBusPostingGroups(
            GeneralPostingSetup."Gen. Bus. Posting Group", VATPostingSetup[1]."VAT Bus. Posting Group");
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        PurchaseHeader.Validate("Prices Including VAT", true);
        PurchaseHeader.Modify(true);

        // [GIVEN] Create a purchase line with allocation account for €52.45 (VAT-inclusive)
        AllocationAmount := 52.45;
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Allocation Account",
            AllocationAccount."No.", 1);
        PurchaseLine.Validate("Direct Unit Cost", AllocationAmount);
        PurchaseLine.Modify(true);

        // [WHEN] Generate allocation lines from the allocation account line
        CreateLinesFromAllocationAccountLine(PurchaseLine);

        // [THEN] Verify the generated purchase lines have correct VAT calculations
        // Expected: 77% should have VAT base of €33.94 + €6.45 VAT = €40.39 VAT-inclusive
        // Expected: 23% should have VAT base of €12.06 + €0.00 VAT = €12.06 VAT-inclusive
        ExpectedVATExclusiveAmount1 := Round(AllocationAmount * 0.77 / 1.19, 0.01); // €33.94
        ExpectedVATAmount1 := Round(ExpectedVATExclusiveAmount1 * 0.19, 0.01); // €6.45
        ExpectedVATExclusiveAmount2 := Round(AllocationAmount * 0.23, 0.01); // €12.06 (no VAT)
        ExpectedVATAmount2 := 0;

        VerifyGeneratedAllocationLines(PurchaseHeader, FirstDestinationGLAccount."No.",
            ExpectedVATExclusiveAmount1, ExpectedVATAmount1);
        VerifyGeneratedAllocationLines(PurchaseHeader, SecondDestinationGLAccount."No.",
            ExpectedVATExclusiveAmount2, ExpectedVATAmount2);
    end;

    local procedure CreateAllocationAccountwithVariableGLDistributionsAndInheritFromParent(
        var AllocationAccount: Record "Allocation Account";
        FirstDimensionValue: Record "Dimension Value";
        SecondDimensionValue: Record "Dimension Value";
        ThirdDimensionValue: Record "Dimension Value";
        FirstBreakdownGLAccount: Record "G/L Account";
        SecondBreakdownGLAccount: Record "G/L Account";
        ThirdBreakdownGLAccount: Record "G/L Account"
    )
    var
        AllocationAccountPage: TestPage "Allocation Account";
        VariableAllocationAccountCode: Code[20];
    begin
        VariableAllocationAccountCode := CreateAllocationAccountWithVariableDistribution(AllocationAccountPage);
        AddInheritFromParentForVariableDistribution(AllocationAccountPage);
        AddGLBreakdownAccountForVariableDistribution(AllocationAccountPage, FirstBreakdownGLAccount);
        SetDimensionToCurrentVariableLine(AllocationAccountPage, FirstDimensionValue);

        AllocationAccountPage.VariableAccountDistribution.New();
        AddInheritFromParentForVariableDistribution(AllocationAccountPage);
        AddGLBreakdownAccountForVariableDistribution(AllocationAccountPage, SecondBreakdownGLAccount);
        SetDimensionToCurrentVariableLine(AllocationAccountPage, SecondDimensionValue);

        AllocationAccountPage.VariableAccountDistribution.New();
        AddInheritFromParentForVariableDistribution(AllocationAccountPage);
        AddGLBreakdownAccountForVariableDistribution(AllocationAccountPage, ThirdBreakdownGLAccount);
        SetDimensionToCurrentVariableLine(AllocationAccountPage, ThirdDimensionValue);
        AllocationAccountPage.Close();

        AllocationAccount.Get(VariableAllocationAccountCode);
    end;

    local procedure AddInheritFromParentForVariableDistribution(var AllocationAccountPage: TestPage "Allocation Account")
    var
        DummyAllocAccountDistribution: Record "Alloc. Account Distribution";
    begin
        AllocationAccountPage.VariableAccountDistribution."Destination Account Type".SetValue(DummyAllocAccountDistribution."Destination Account Type"::"Inherit from Parent");
    end;

    local procedure CreatePurchaseInvoiceWithInheritFromParent(GLAccountNo: Code[20]; SelectedAlloctationAccountNo: Code[20]; var PurchaseInvoice: TestPage "Purchase Invoice"; var PurchaseHeader: Record "Purchase Header")
    var
        DummyPurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GoToRecord(PurchaseHeader);
        PurchaseInvoice.PurchLines.New();
        PurchaseInvoice.PurchLines.Type.SetValue(DummyPurchaseLine.Type::"G/L Account");
        PurchaseInvoice.PurchLines."No.".SetValue(GLAccountNo);
        PurchaseInvoice.PurchLines.Quantity.SetValue(1);
        PurchaseInvoice.PurchLines."Direct Unit Cost".SetValue(GetLineAmountToForceRounding());
        PurchaseInvoice.PurchLines."Allocation Account No.".SetValue(SelectedAlloctationAccountNo);
        PurchaseHeader.CalcFields("Amount Including VAT");
        PurchaseInvoice.DocAmount.SetValue(PurchaseHeader."Amount Including VAT" + GetLineAmountToForceRounding());
    end;

    local procedure CreatePurchaseInvoice(AccountNo: Code[20]; var PurchaseInvoice: TestPage "Purchase Invoice"; var PurchaseHeader: Record "Purchase Header")
    var
        DummyPurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GoToRecord(PurchaseHeader);
        PurchaseInvoice.PurchLines.New();
        PurchaseInvoice.PurchLines.Type.SetValue(DummyPurchaseLine.Type::"Allocation Account");
        PurchaseInvoice.PurchLines."No.".SetValue(AccountNo);
        PurchaseInvoice.PurchLines.Quantity.SetValue(1);
        PurchaseInvoice.PurchLines."Direct Unit Cost".SetValue(GetLineAmountToForceRounding());
        PurchaseHeader.CalcFields("Amount Including VAT");
        PurchaseInvoice.DocAmount.SetValue(PurchaseHeader."Amount Including VAT" + GetLineAmountToForceRounding());
    end;

    local procedure GetLineAmountToForceRounding(): Decimal
    begin
        exit(1025.27)
    end;

    local procedure CreateAllocationAccountwithFixedGLDistributions(
       var AllocationAccount: Record "Allocation Account";
       FirstDimensionValue: Record "Dimension Value";
       SecondDimensionValue: Record "Dimension Value";
       ThirdDimensionValue: Record "Dimension Value";
       DestinationGLAccount: Record "G/L Account"
   )
    var
        AllocationAccountPage: TestPage "Allocation Account";
        FixedAllocationAccountCode: Code[20];
    begin
        FixedAllocationAccountCode := CreateAllocationAccountWithFixedDistribution(AllocationAccountPage);
        AddGLDestinationAccountForFixedDistribution(AllocationAccountPage, DestinationGLAccount);
        AllocationAccountPage.FixedAccountDistribution.Share.SetValue(100);
        SetDimensionToCurrentFixedLine(AllocationAccountPage, FirstDimensionValue);

        AllocationAccountPage.FixedAccountDistribution.New();
        AddGLDestinationAccountForFixedDistribution(AllocationAccountPage, DestinationGLAccount);
        AllocationAccountPage.FixedAccountDistribution.Share.SetValue(200);
        SetDimensionToCurrentFixedLine(AllocationAccountPage, SecondDimensionValue);

        AllocationAccountPage.FixedAccountDistribution.New();
        AddGLDestinationAccountForFixedDistribution(AllocationAccountPage, DestinationGLAccount);
        AllocationAccountPage.FixedAccountDistribution.Share.SetValue(300);
        SetDimensionToCurrentFixedLine(AllocationAccountPage, ThirdDimensionValue);
        AllocationAccountPage.Close();

        AllocationAccount.Get(FixedAllocationAccountCode);
    end;

    local procedure CreateAllocationAccountwithVariableGLDistributions(
        var AllocationAccount: Record "Allocation Account";
        FirstDimensionValue: Record "Dimension Value";
        SecondDimensionValue: Record "Dimension Value";
        ThirdDimensionValue: Record "Dimension Value";
        DestinationGLAccount: Record "G/L Account";
        FirstBreakdownGLAccount: Record "G/L Account";
        SecondBreakdownGLAccount: Record "G/L Account";
        ThirdBreakdownGLAccount: Record "G/L Account"
    )
    var
        AllocationAccountPage: TestPage "Allocation Account";
        VariableAllocationAccountCode: Code[20];
    begin
        VariableAllocationAccountCode := CreateAllocationAccountWithVariableDistribution(AllocationAccountPage);
        AddGLDestinationAccountForVariableDistribution(AllocationAccountPage, DestinationGLAccount);
        AddGLBreakdownAccountForVariableDistribution(AllocationAccountPage, FirstBreakdownGLAccount);
        SetDimensionToCurrentVariableLine(AllocationAccountPage, FirstDimensionValue);

        AllocationAccountPage.VariableAccountDistribution.New();
        AddGLDestinationAccountForVariableDistribution(AllocationAccountPage, DestinationGLAccount);
        AddGLBreakdownAccountForVariableDistribution(AllocationAccountPage, SecondBreakdownGLAccount);
        SetDimensionToCurrentVariableLine(AllocationAccountPage, SecondDimensionValue);

        AllocationAccountPage.VariableAccountDistribution.New();
        AddGLDestinationAccountForVariableDistribution(AllocationAccountPage, DestinationGLAccount);
        AddGLBreakdownAccountForVariableDistribution(AllocationAccountPage, ThirdBreakdownGLAccount);
        SetDimensionToCurrentVariableLine(AllocationAccountPage, ThirdDimensionValue);
        AllocationAccountPage.Close();

        AllocationAccount.Get(VariableAllocationAccountCode);
    end;

    local procedure AddGLDestinationAccountForVariableDistribution(var AllocationAccountPage: TestPage "Allocation Account"; var GLAccount: Record "G/L Account")
    var
        DummyAllocAccountDistribution: Record "Alloc. Account Distribution";
    begin
        if GLAccount."No." = '' then
            GLAccount.Get(CreateGLAccount());

        AllocationAccountPage.VariableAccountDistribution."Destination Account Type".SetValue(DummyAllocAccountDistribution."Destination Account Type"::"G/L Account");
        AllocationAccountPage.VariableAccountDistribution."Destination Account Number".SetValue(GLAccount."No.");
    end;

    local procedure CreateAllocationAccountWithVariableDistribution(var AllocationAccountPage: TestPage "Allocation Account"): Code[20]
    var
        DummyAllocationAccount: Record "Allocation Account";
        AllocationAccountNo: Code[20];
    begin
        AllocationAccountPage.OpenNew();
#pragma warning disable AA0139
        AllocationAccountNo := Any.AlphanumericText(MaxStrLen(DummyAllocationAccount."No."));
#pragma warning restore AA0139

        AllocationAccountPage."No.".SetValue(AllocationAccountNo);
        AllocationAccountPage."Account Type".SetValue(DummyAllocationAccount."Account Type"::Variable);
        AllocationAccountPage.Name.SetValue(Any.AlphabeticText(MaxStrLen(DummyAllocationAccount.Name)));
        exit(AllocationAccountNo);
    end;

    local procedure CreateAllocationAccountWithFixedDistribution(var AllocationAccountPage: TestPage "Allocation Account"): Code[20]
    var
        DummyAllocationAccount: Record "Allocation Account";
        AllocationAccountNo: Code[20];
    begin
        AllocationAccountPage.OpenNew();
#pragma warning disable AA0139
        AllocationAccountNo := Any.AlphanumericText(MaxStrLen(DummyAllocationAccount."No."));
#pragma warning restore AA0139

        AllocationAccountPage."No.".SetValue(AllocationAccountNo);
        AllocationAccountPage."Account Type".SetValue(DummyAllocationAccount."Account Type"::Fixed);
        AllocationAccountPage.Name.SetValue(Any.AlphabeticText(MaxStrLen(DummyAllocationAccount.Name)));
        exit(AllocationAccountNo);
    end;

    local procedure AddGLDestinationAccountForFixedDistribution(var AllocationAccountPage: TestPage "Allocation Account"; var GLAccount: Record "G/L Account")
    var
        DummyAllocAccountDistribution: Record "Alloc. Account Distribution";
    begin
        if GLAccount."No." = '' then
            GLAccount.Get(CreateGLAccount());

        AllocationAccountPage.FixedAccountDistribution."Destination Account Type".SetValue(DummyAllocAccountDistribution."Destination Account Type"::"G/L Account");
        AllocationAccountPage.FixedAccountDistribution."Destination Account Number".SetValue(GLAccount."No.");
    end;

    local procedure SetDimensionToCurrentFixedLine(var AllocationAcccount: TestPage "Allocation Account"; var DimensionValue: Record "Dimension Value")
    begin
        LibraryVariableStorage.Enqueue(DimensionValue.SystemId);
        AllocationAcccount.FixedAccountDistribution.Dimensions.Invoke();
    end;

    local procedure AddGLBreakdownAccountForVariableDistribution(var AllocationAccountPage: TestPage "Allocation Account"; var GLAccount: Record "G/L Account")
    var
        DummyAllocAccountDistribution: Record "Alloc. Account Distribution";
    begin
        AllocationAccountPage.VariableAccountDistribution."Breakdown Account Type".SetValue(DummyAllocAccountDistribution."Breakdown Account Type"::"G/L Account");
        AllocationAccountPage.VariableAccountDistribution."Breakdown Account Number".SetValue(GLAccount."No.");
    end;

    local procedure VerifyPurchaseLineAmount(var PurchaseInvoiceLine: Record "Purch. Inv. Line"; ExpectedAmount: Decimal; Division: Integer)
    begin
        Assert.IsTrue((ExpectedAmount / Division + 0.01) >= PurchaseInvoiceLine."Line Amount", 'The Line amount is too high');
        Assert.IsTrue((ExpectedAmount / Division - 0.01) <= PurchaseInvoiceLine."Line Amount", 'The Line amount is too low');
    end;

    local procedure CreateBreakdownAccountsWithBalances(var FirstBreakdownGLAccount: Record "G/L Account"; var SecondBreakdownGLAccount: Record "G/L Account"; var ThirdBreakdownGLAccount: Record "G/L Account")
    begin
        FirstBreakdownGLAccount.Get(LibraryERM.CreateGLAccountWithPurchSetup());
        CreateBalanceForGLAccount(100, FirstBreakdownGLAccount, 0);

        SecondBreakdownGLAccount.Get(LibraryERM.CreateGLAccountWithPurchSetup());
        CreateBalanceForGLAccount(200, SecondBreakdownGLAccount, 0);

        ThirdBreakdownGLAccount.Get(LibraryERM.CreateGLAccountWithPurchSetup());
        CreateBalanceForGLAccount(300, ThirdBreakdownGLAccount, 0);
    end;

    local procedure CreateBalanceForGLAccount(Balance: Decimal; var GLAccount: Record "G/L Account"; DimensionSetID: Integer)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account",
          GLAccount."No.", Balance);
        GenJournalLine.Validate("Posting Date", WorkDate());
        GenJournalLine.Validate("Dimension Set ID", DimensionSetID);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateDimensionSetID(var DimensionValue: Record "Dimension Value"): Integer
    var
        DimSetID: Integer;
    begin
        DimensionValue.FindSet();

        repeat
            DimSetID := LibraryDimension.CreateDimSet(DimSetID, DimensionValue."Dimension Code", DimensionValue.Code);
        until DimensionValue.Next() = 0;

        exit(DimSetID);
    end;

    local procedure SetDimensionToCurrentVariableLine(var AllocationAcccount: TestPage "Allocation Account"; var DimensionValue: Record "Dimension Value")
    begin
        LibraryVariableStorage.Enqueue(DimensionValue.SystemId);
        AllocationAcccount.VariableAccountDistribution.Dimensions.Invoke();
    end;

    local procedure CreateDimensionsWithValues(var FirstDimensionValue: Record "Dimension Value"; var SecondDimensionValue: Record "Dimension Value"; var ThirdDimensionValue: Record "Dimension Value")
    var
        Dimension: Record Dimension;
    begin
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(FirstDimensionValue, Dimension.Code);
        LibraryDimension.CreateDimensionValue(SecondDimensionValue, Dimension.Code);
        LibraryDimension.CreateDimensionValue(ThirdDimensionValue, Dimension.Code);
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GenPostingType: Enum "General Posting Type";
    begin
        VATPostingSetup.SetFilter("VAT Bus. Posting Group", '<>%1', '');
        VATPostingSetup.SetFilter("VAT Prod. Posting Group", '<>%1', '');
        VATPostingSetup.SetRange("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.SetRange("VAT %", 0);
        VATPostingSetup.FindFirst();
        exit(LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GenPostingType::Purchase));
    end;

    local procedure GetOverrideAmount(): Decimal
    begin
        exit(100.11);
    end;

    local procedure GetOverrideQuantity(): Decimal
    begin
        exit(0.33);
    end;

    local procedure CreateDimensionsWithValues(var DimensionValue: array[2] of Record "Dimension Value")
    var
        Dimension: Record Dimension;
    begin
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue[1], Dimension.Code);
        LibraryDimension.CreateDimensionValue(DimensionValue[2], Dimension.Code);
    end;

    local procedure CreateVariableAllocationAccountwithEightDistributionLinesInheritFromParent(
        var AllocationAccount: Record "Allocation Account";
        BreakdownAccountNumber: Code[20];
        DimensionValue: array[2] of Record "Dimension Value")
    var
        VariableAllocationAccountCode: Code[20];
        i: Integer;
    begin
        VariableAllocationAccountCode := CreateAllocationAccountWithVariableDistribution();

        CreateAllocationAccountDistributionLineInheritFromParent(
            VariableAllocationAccountCode,
            BreakdownAccountNumber,
            DimensionValue[1].Code);
        CreateAllocationAccountDistributionLineInheritFromParent(
            VariableAllocationAccountCode,
            BreakdownAccountNumber,
            DimensionValue[2].Code);

        for i := 1 to 6 do
            CreateAllocationAccountDistributionLineInheritFromParent(
                VariableAllocationAccountCode,
                BreakdownAccountNumber, '');

        AllocationAccount.Get(VariableAllocationAccountCode);
    end;

    local procedure CreateAllocationAccountWithVariableDistribution(): Code[20]
    var
        AllocationAccount: Record "Allocation Account";
    begin
        AllocationAccount."No." := Format(LibraryRandom.RandText(5));
        AllocationAccount."Account Type" := AllocationAccount."Account Type"::Variable;
        AllocationAccount.Name := Format(LibraryRandom.RandText(10));
        AllocationAccount."Document Lines Split" := AllocationAccount."Document Lines Split"::"Split Quantity";
        AllocationAccount.Insert(true);
        exit(AllocationAccount."No.");
    end;

    local procedure CreateAllocationAccountDistributionLineInheritFromParent(AllocationAccountNo: Code[20]; BreakdownAccountNumber: Code[20]; DimensionValueCode: Code[20])
    var
        AllocAccountDistribution: Record "Alloc. Account Distribution";
    begin
        AllocAccountDistribution."Allocation Account No." := AllocationAccountNo;
        AllocAccountDistribution."Line No." := LibraryUtility.GetNewRecNo(AllocAccountDistribution, AllocAccountDistribution.FieldNo("Line No."));
        AllocAccountDistribution.Validate("Account Type", AllocAccountDistribution."Account Type"::Variable);
        AllocAccountDistribution.Validate("Destination Account Type", AllocAccountDistribution."Destination Account Type"::"Inherit from Parent");
        AllocAccountDistribution.Validate("Breakdown Account Type", AllocAccountDistribution."Breakdown Account Type"::"G/L Account");
        AllocAccountDistribution.Validate("Breakdown Account Number", BreakdownAccountNumber);
        AllocAccountDistribution.Validate("Calculation Period", AllocAccountDistribution."Calculation Period"::Month);
        AllocAccountDistribution.Validate("Dimension 1 Filter", DimensionValueCode);
        AllocAccountDistribution.Insert(true);
    end;

    local procedure CreatePurchaseInvoiceWithInheritFromParent(
        GLAccountNo: Code[20];
        SelectedAlloctationAccountNo: Code[20];
        var PurchaseInvoice: TestPage "Purchase Invoice";
        var PurchaseHeader: Record "Purchase Header";
        Quantity: Decimal;
        DirectUnitCost: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GoToRecord(PurchaseHeader);
        PurchaseInvoice.PurchLines.New();
        PurchaseInvoice.PurchLines.Type.SetValue(PurchaseLine.Type::"G/L Account");
        PurchaseInvoice.PurchLines."No.".SetValue(GLAccountNo);
        PurchaseInvoice.PurchLines.Quantity.SetValue(Quantity);
        PurchaseInvoice.PurchLines."Direct Unit Cost".SetValue(DirectUnitCost);
        PurchaseInvoice.PurchLines."Allocation Account No.".SetValue(SelectedAlloctationAccountNo);
        PurchaseHeader.CalcFields("Amount Including VAT");
        PurchaseInvoice.DocAmount.SetValue(PurchaseHeader."Amount Including VAT" + (Quantity * DirectUnitCost));
    end;

    [ModalPageHandler]
    procedure HandleEditDimensionSetEntriesPage(var EditDimensionSetEntriesPage: TestPage "Edit Dimension Set Entries")
    var
        DimensionValue: Record "Dimension Value";
        DimensionValueSystemId: Text;
    begin
        DimensionValueSystemId := LibraryVariableStorage.DequeueText();
        DimensionValue.GetBySystemId(DimensionValueSystemId);
        EditDimensionSetEntriesPage.New();
        EditDimensionSetEntriesPage."Dimension Code".SetValue(DimensionValue."Dimension Code");
        EditDimensionSetEntriesPage.DimensionValueCode.SetValue(DimensionValue.Code);
        EditDimensionSetEntriesPage.OK().Invoke();
    end;

    local procedure CreateFixedAllocationAccountwithNineDistributionLinesInheritFromParent(var AllocationAccount: Record "Allocation Account"; DimensionValue: array[9] of Record "Dimension Value")
    var
        FixedAllocationAccountCode: Code[20];
        i: Integer;
    begin
        FixedAllocationAccountCode := CreateAllocationAccountWithFixedDistribution();

        for i := 1 to ArrayLen(DimensionValue) do
            CreateAllocationAccountDistributionLineInheritFromParent(FixedAllocationAccountCode, '', '');

        AllocationAccount.Get(FixedAllocationAccountCode);
    end;

    local procedure CreateAllocationAccountWithFixedDistribution(): Code[20]
    var
        AllocationAccount: Record "Allocation Account";
    begin
        AllocationAccount."No." := Format(LibraryRandom.RandText(5));
        AllocationAccount."Account Type" := AllocationAccount."Account Type"::Fixed;
        AllocationAccount.Name := Format(LibraryRandom.RandText(10));
        AllocationAccount."Document Lines Split" := AllocationAccount."Document Lines Split"::"Split Amount";
        AllocationAccount.Insert(true);
        exit(AllocationAccount."No.");
    end;

    local procedure CreateDimensionsWithNineValues(var DimensionValue: array[9] of Record "Dimension Value")
    var
        Dimension: Record Dimension;
        i: Integer;
    begin
        LibraryDimension.CreateDimension(Dimension);

        for i := 1 to ArrayLen(DimensionValue) do
            LibraryDimension.CreateDimensionValue(DimensionValue[i], Dimension.Code);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(QuestionText: Text[1024]; var Relpy: Boolean)
    begin
        Relpy := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure OverrideGLDistributions(var RedistributeAccAllocations: TestPage "Redistribute Acc. Allocations")
    var
        TotalAmount: Decimal;
    begin
        TotalAmount := LibraryVariableStorage.DequeueDecimal();

        RedistributeAccAllocations.First();
        RedistributeAccAllocations.Amount.SetValue(GetOverrideAmount());
        TotalAmount -= GetOverrideAmount();

        RedistributeAccAllocations.Dimensions.Invoke();

        RedistributeAccAllocations.Next();
        RedistributeAccAllocations.Amount.SetValue(GetOverrideAmount());
        TotalAmount -= GetOverrideAmount();

        RedistributeAccAllocations.Dimensions.Invoke();

        RedistributeAccAllocations.Next();
        RedistributeAccAllocations.Amount.SetValue(TotalAmount);
        RedistributeAccAllocations.Dimensions.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure OverrideGLDistributionsPerQuantity(var RedistributeAccAllocations: TestPage "Redistribute Acc. Allocations")
    begin
        RedistributeAccAllocations.First();
        RedistributeAccAllocations.Quantity.SetValue(GetOverrideQuantity());

        RedistributeAccAllocations.Dimensions.Invoke();

        RedistributeAccAllocations.Next();
        RedistributeAccAllocations.Quantity.SetValue(GetOverrideQuantity());

        RedistributeAccAllocations.Dimensions.Invoke();

        RedistributeAccAllocations.Next();
        RedistributeAccAllocations.Quantity.SetValue(1 - GetOverrideQuantity() * 2);
        RedistributeAccAllocations.Dimensions.Invoke();
    end;

    local procedure CreateVATPostingSetupWithSalesPurchAcc(var VATPostingSetup: Record "VAT Posting Setup"; VATBusinessPostingGroup: Code[20]; VATProductPostingGroup: Code[20]; VATCalculationType: Enum "Tax Calculation Type"; VATRate: Decimal)
    begin
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroup, VATProductPostingGroup);
        VATPostingSetup.Validate("VAT Calculation Type", VATCalculationType);
        VATPostingSetup.Validate("VAT %", VATRate);
        VATPostingSetup.Validate("Sales VAT Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("Purchase VAT Account", LibraryERM.CreateGLAccountNo());
    end;

    local procedure CreateFixedAllocationAccountWithTwoDistributions(var AllocationAccount: Record "Allocation Account"; FirstAccountNo: Code[20]; FirstPercentage: Decimal; SecondAccountNo: Code[20]; SecondPercentage: Decimal)
    var
        AllocAccountDistribution: Record "Alloc. Account Distribution";
    begin
        // Create allocation account like the existing tests do
        AllocationAccount."No." := Format(LibraryRandom.RandText(5));
        AllocationAccount."Account Type" := AllocationAccount."Account Type"::Fixed;
        AllocationAccount."Document Lines Split" := AllocationAccount."Document Lines Split"::"Split Amount";
        AllocationAccount.Name := Any.AlphabeticText(MaxStrLen(AllocationAccount.Name));
        AllocationAccount.Insert(true);

        // Create first distribution line
        AllocAccountDistribution."Allocation Account No." := AllocationAccount."No.";
        AllocAccountDistribution."Line No." := 10000;
        AllocAccountDistribution."Destination Account Type" := AllocAccountDistribution."Destination Account Type"::"G/L Account";
        AllocAccountDistribution."Destination Account Number" := FirstAccountNo;
        AllocAccountDistribution.Share := FirstPercentage;
        AllocAccountDistribution.Insert(true);

        // Create second distribution line
        Clear(AllocAccountDistribution);
        AllocAccountDistribution."Allocation Account No." := AllocationAccount."No.";
        AllocAccountDistribution."Line No." := 20000;
        AllocAccountDistribution."Destination Account Type" := AllocAccountDistribution."Destination Account Type"::"G/L Account";
        AllocAccountDistribution."Destination Account Number" := SecondAccountNo;
        AllocAccountDistribution.Share := SecondPercentage;
        AllocAccountDistribution.Insert(true);
    end;

    local procedure CreateLinesFromAllocationAccountLine(var AllocationAccountPurchaseLine: Record "Purchase Line")
    var
        PurchaseAllocAccMgt: Codeunit "Purchase Alloc. Acc. Mgt.";
    begin
        PurchaseAllocAccMgt.CreateLinesFromAllocationAccountLine(AllocationAccountPurchaseLine);
    end;

    local procedure VerifyGeneratedAllocationLines(var PurchaseHeader: Record "Purchase Header"; AccountNo: Code[20]; ExpectedAmount: Decimal; ExpectedVATAmount: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
        ExpectedAmountIncludingVAT: Decimal;
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange("No.", AccountNo);
        PurchaseLine.SetRange(Type, PurchaseLine.Type::"G/L Account");
        Assert.RecordIsNotEmpty(PurchaseLine);
        PurchaseLine.FindFirst();

        ExpectedAmountIncludingVAT := ExpectedAmount + ExpectedVATAmount;

        // Verify VAT-exclusive amount (Line Amount)
        Assert.AreNearlyEqual(ExpectedAmountIncludingVAT, PurchaseLine."Line Amount", 0.01,
            StrSubstNo('Line Amount should be %1 but was %2 for account %3', ExpectedAmount, PurchaseLine."Line Amount", AccountNo));

        // Verify VAT-inclusive amount
        Assert.AreNearlyEqual(ExpectedAmountIncludingVAT, PurchaseLine."Amount Including VAT", 0.01,
            StrSubstNo('Amount Including VAT should be %1 but was %2 for account %3', ExpectedAmountIncludingVAT, PurchaseLine."Amount Including VAT", AccountNo));
    end;
}
#pragma warning restore AA0210