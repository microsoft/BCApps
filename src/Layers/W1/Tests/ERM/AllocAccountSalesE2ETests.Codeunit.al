#pragma warning disable AA0210
codeunit 134830 "Alloc. Account Sales E2E Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibrarySales: Codeunit "Library - Sales";
        TestProxyNotifMgtExt: Codeunit "Test Proxy Notif. Mgt. Ext.";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryERM: Codeunit "Library - ERM";
        Any: Codeunit Any;
        Assert: Codeunit Assert;
        Initialized: Boolean;
        DestinationAccountErr: Label 'Destination GL Account must be %1 in %2.', Comment = '%1 = GL Account No. %2 = Page Name';

    local procedure Initialize()
    var
        AllocationAccount: Record "Allocation Account";
        AllocAccManualOverride: Record "Alloc. Acc. Manual Override";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Alloc. Account Sales E2E Tests");

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
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        AllocationAccountPage: TestPage "Allocation Account";
        SalesInvoice: TestPage "Sales Invoice";
        PostedAmount: Decimal;
    begin
        Initialize();

        // [GIVEN] Three GL accounts with dimensions and balances, one Balancing G/L Account and three Destination G/L Accounts
        CreateBreakdownAccountsWithBalances(FirstBreakdownGLAccount, SecondBreakdownGLAccount, ThirdBreakdownGLAccount);
        FirstDestinationGLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        SecondDestinationGLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        ThirdDestinationGLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        BalancingGLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());

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

        // [GIVEN] The Sales Invoice with an Item and a Allocation Account
        CreateSalesInvoice(AllocationAccount."No.", SalesInvoice, SalesHeader);

        // [WHEN] The Sales Invoice is posted
        SalesInvoice.Post.Invoke();
        SalesInvoiceHeader.SetRange("Draft Invoice SystemId", SalesHeader.SystemId);
        SalesInvoiceHeader.FindFirst();

        // [THEN] The costs are split into mulitple ledger entries which has the same dimension code
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.SetRange("No.", FirstDestinationGLAccount."No.");
        Assert.AreEqual(1, SalesInvoiceLine.Count(), 'Wrong number of Sales Invoice Lines created for the first destination account');
        SalesInvoiceLine.FindFirst();
        VerifySalesLineAmount(SalesInvoiceLine, GetLineAmountToForceRounding(), 6);
        PostedAmount := SalesInvoiceLine.Amount;

        SalesInvoiceLine.SetRange("No.", SecondDestinationGLAccount."No.");
        Assert.AreEqual(1, SalesInvoiceLine.Count(), 'Wrong number of Sales Invoice Lines for the second destination account');
        SalesInvoiceLine.FindFirst();
        VerifySalesLineAmount(SalesInvoiceLine, GetLineAmountToForceRounding(), 3);
        PostedAmount += SalesInvoiceLine.Amount;

        SalesInvoiceLine.SetRange("No.", ThirdDestinationGLAccount."No.");
        Assert.AreEqual(1, SalesInvoiceLine.Count(), 'Wrong number of Sales Invoice Lines for the second destination account');
        SalesInvoiceLine.FindFirst();
        VerifySalesLineAmount(SalesInvoiceLine, GetLineAmountToForceRounding(), 2);
        PostedAmount += SalesInvoiceLine.Amount;

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
        SalesHeader: Record "Sales Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoice: TestPage "Sales Invoice";
        PostedAmount: Decimal;
    begin
        Initialize();

        // [GIVEN] A dimension that is defined as a department with three values
        CreateDimensionsWithValues(FirstDimensionValue, SecondDimensionValue, ThirdDimensionValue);

        // [GIVEN] Three GL accounts with dimensions and balances and one Balancing G/L Account
        CreateBreakdownAccountsWithBalances(FirstBreakdownGLAccount, SecondBreakdownGLAccount, ThirdBreakdownGLAccount);
        DestinationGLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        BalancingGLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());

        // [GIVEN] An Allocation Account with variable GL distributions
        CreateAllocationAccountwithVariableGLDistributions(AllocationAccount, FirstDimensionValue, SecondDimensionValue, ThirdDimensionValue, DestinationGLAccount, FirstBreakdownGLAccount, SecondBreakdownGLAccount, ThirdBreakdownGLAccount);

        // [GIVEN] The Sales Invoice with Item and Allocation account
        CreateSalesInvoice(AllocationAccount."No.", SalesInvoice, SalesHeader);

        // [WHEN] The Sales Invoice is posted
        SalesInvoice.Post.Invoke();
        SalesInvoiceHeader.SetRange("Draft Invoice SystemId", SalesHeader.SystemId);
        SalesInvoiceHeader.FindFirst();

        // [THEN] The costs are split into mulitple ledger entries which has the same dimension code
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.SetRange("No.", DestinationGLAccount."No.");

        FirstDimensionValue.SetRecFilter();
        SalesInvoiceLine.SetRange("Dimension Set ID", CreateDimensionSetID(FirstDimensionValue));
        Assert.AreEqual(1, SalesInvoiceLine.Count(), 'Wrong number of Sales Invoice Lines created for the first destination account');
        SalesInvoiceLine.FindFirst();
        VerifySalesLineAmount(SalesInvoiceLine, GetLineAmountToForceRounding(), 6);
        PostedAmount := SalesInvoiceLine.Amount;

        SecondDimensionValue.SetRecFilter();
        SalesInvoiceLine.SetRange("Dimension Set ID", CreateDimensionSetID(SecondDimensionValue));
        Assert.AreEqual(1, SalesInvoiceLine.Count(), 'Wrong number of Sales Invoice Lines for the second destination account');
        SalesInvoiceLine.FindFirst();
        VerifySalesLineAmount(SalesInvoiceLine, GetLineAmountToForceRounding(), 3);
        PostedAmount += SalesInvoiceLine.Amount;

        ThirdDimensionValue.SetRecFilter();
        SalesInvoiceLine.SetRange("Dimension Set ID", CreateDimensionSetID(ThirdDimensionValue));
        Assert.AreEqual(1, SalesInvoiceLine.Count(), 'Wrong number of Sales Invoice Lines for the second destination account');
        SalesInvoiceLine.FindFirst();
        VerifySalesLineAmount(SalesInvoiceLine, GetLineAmountToForceRounding(), 2);
        PostedAmount += SalesInvoiceLine.Amount;
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
        SalesHeader: Record "Sales Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoice: TestPage "Sales Invoice";
        PostedAmount: Decimal;
    begin
        Initialize();

        // [GIVEN] A dimension that is defined as a department with three values
        CreateDimensionsWithValues(FirstDimensionValue, SecondDimensionValue, ThirdDimensionValue);

        // [GIVEN] Three GL accounts with dimensions and balances and one Balancing G/L Account
        CreateBreakdownAccountsWithBalances(FirstBreakdownGLAccount, SecondBreakdownGLAccount, ThirdBreakdownGLAccount);
        BalancingGLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        DestinationGLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());

        // [GIVEN] An Allocation Account with variable GL distributions
        CreateAllocationAccountwithVariableGLDistributions(AllocationAccount, FirstDimensionValue, SecondDimensionValue, ThirdDimensionValue, DestinationGLAccount, FirstBreakdownGLAccount, SecondBreakdownGLAccount, ThirdBreakdownGLAccount);

        // [GIVEN] The Sales Invoice with Item and Allocation account
        CreateSalesInvoice(AllocationAccount."No.", SalesInvoice, SalesHeader);

        // [WHEN] The Sales Invoice is posted
        SalesInvoice.Post.Invoke();
        SalesInvoiceHeader.SetRange("Draft Invoice SystemId", SalesHeader.SystemId);
        SalesInvoiceHeader.FindFirst();

        // [THEN] The costs are split into mulitple ledger entries which has the same dimension code
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.SetRange("No.", DestinationGLAccount."No.");
        FirstDimensionValue.SetRecFilter();
        SalesInvoiceLine.SetRange("Dimension Set ID", CreateDimensionSetID(FirstDimensionValue));
        Assert.AreEqual(1, SalesInvoiceLine.Count(), 'Wrong number of Sales Invoice Lines created for the first destination account');
        SalesInvoiceLine.FindFirst();
        VerifySalesLineAmount(SalesInvoiceLine, GetLineAmountToForceRounding(), 6);
        PostedAmount := SalesInvoiceLine.Amount;

        SecondDimensionValue.SetRecFilter();
        SalesInvoiceLine.SetRange("Dimension Set ID", CreateDimensionSetID(SecondDimensionValue));
        Assert.AreEqual(1, SalesInvoiceLine.Count(), 'Wrong number of Sales Invoice Lines for the second destination account');
        SalesInvoiceLine.FindFirst();
        VerifySalesLineAmount(SalesInvoiceLine, GetLineAmountToForceRounding(), 3);
        PostedAmount += SalesInvoiceLine.Amount;

        ThirdDimensionValue.SetRecFilter();
        SalesInvoiceLine.SetRange("Dimension Set ID", CreateDimensionSetID(ThirdDimensionValue));
        Assert.AreEqual(1, SalesInvoiceLine.Count(), 'Wrong number of Sales Invoice Lines for the second destination account');
        SalesInvoiceLine.FindFirst();
        VerifySalesLineAmount(SalesInvoiceLine, GetLineAmountToForceRounding(), 2);
        PostedAmount += SalesInvoiceLine.Amount;
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
        SalesHeader: Record "Sales Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        AllocationAccount: Record "Allocation Account";
        AllocAccManualOverride: Record "Alloc. Acc. Manual Override";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoice: TestPage "Sales Invoice";
        PostedAmount: Decimal;
    begin
        Initialize();

        // [GIVEN] A dimension that is defined as a department with three values
        CreateDimensionsWithValues(FirstDimensionValue, SecondDimensionValue, ThirdDimensionValue);
        CreateDimensionsWithValues(OverrideFirstDimensionValue, OverrideSecondDimensionValue, OverrideThirdDimensionValue);

        // [GIVEN] Three GL accounts with dimensions and balances and one Balancing G/L Account
        CreateBreakdownAccountsWithBalances(FirstBreakdownGLAccount, SecondBreakdownGLAccount, ThirdBreakdownGLAccount);
        DestinationGLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        BalancingGLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());

        // [GIVEN] An Allocation Account with variable GL distributions
        CreateAllocationAccountwithVariableGLDistributions(AllocationAccount, FirstDimensionValue, SecondDimensionValue, ThirdDimensionValue, DestinationGLAccount, FirstBreakdownGLAccount, SecondBreakdownGLAccount, ThirdBreakdownGLAccount);

        // [GIVEN] The Sales Invoice with Item and Allocation account
        CreateSalesInvoice(AllocationAccount."No.", SalesInvoice, SalesHeader);

        // [GIVEN] User defines an override manually
        LibraryVariableStorage.Enqueue(GetLineAmountToForceRounding());
        LibraryVariableStorage.Enqueue(OverrideFirstDimensionValue.SystemId);
        LibraryVariableStorage.Enqueue(OverrideSecondDimensionValue.SystemId);
        LibraryVariableStorage.Enqueue(OverrideThirdDimensionValue.SystemId);
        SalesInvoice.SalesLines.RedistributeAccAllocations.Invoke();

        // [WHEN] The Sales Invoice is posted
        SalesInvoice.Post.Invoke();
        SalesInvoiceHeader.SetRange("Draft Invoice SystemId", SalesHeader.SystemId);
        SalesInvoiceHeader.FindFirst();

        // [THEN] The costs are split into mulitple ledger entries which has the same dimension code
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        Assert.AreEqual(4, SalesInvoiceLine.Count(), 'Wrong number of Sales Invoice Lines created for the destination account');

        // [THEN] Override values are used
        FirstDimensionValue.SetRecFilter();
        OverrideFirstDimensionValue.SetFilter(SystemId, '%1|%2', FirstDimensionValue.SystemId, OverrideFirstDimensionValue.SystemId);
        SalesInvoiceLine.SetRange("Dimension Set ID", CreateDimensionSetID(OverrideFirstDimensionValue));
        Assert.AreEqual(1, SalesInvoiceLine.Count(), 'Wrong number of Sales Invoice Lines for the first breakdown account');
        SalesInvoiceLine.FindFirst();
        Assert.AreEqual(GetOverrideAmount(), SalesInvoiceLine."Line Amount", 'The override amount was not used');
        PostedAmount := SalesInvoiceLine."Line Amount";

        SecondDimensionValue.SetRecFilter();
        OverrideSecondDimensionValue.SetFilter(SystemId, '%1|%2', SecondDimensionValue.SystemId, OverrideSecondDimensionValue.SystemId);
        SalesInvoiceLine.SetRange("Dimension Set ID", CreateDimensionSetID(OverrideSecondDimensionValue));
        Assert.AreEqual(1, SalesInvoiceLine.Count(), 'Wrong number of Sales Invoice Lines for the second breakdown account');
        SalesInvoiceLine.FindFirst();
        Assert.AreEqual(GetOverrideAmount(), SalesInvoiceLine."Line Amount", 'The override amount was not used');
        PostedAmount += SalesInvoiceLine."Line Amount";

        ThirdDimensionValue.SetRecFilter();
        OverrideThirdDimensionValue.SetFilter(SystemId, '%1|%2', ThirdDimensionValue.SystemId, OverrideThirdDimensionValue.SystemId);
        SalesInvoiceLine.SetRange("Dimension Set ID", CreateDimensionSetID(OverrideThirdDimensionValue));
        Assert.AreEqual(1, SalesInvoiceLine.Count(), 'Wrong number of Sales Invoice Lines for the third breakdown account');
        SalesInvoiceLine.FindFirst();
        PostedAmount += SalesInvoiceLine."Line Amount";

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
        SalesHeader: Record "Sales Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        AllocationAccount: Record "Allocation Account";
        AllocAccManualOverride: Record "Alloc. Acc. Manual Override";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        AllocationAccountMgt: Codeunit "Allocation Account Mgt.";
        SalesInvoice: TestPage "Sales Invoice";
        PostedAmount: Decimal;
    begin
        Initialize();

        // [GIVEN] A dimension that is defined as a department with three values
        CreateDimensionsWithValues(FirstDimensionValue, SecondDimensionValue, ThirdDimensionValue);
        CreateDimensionsWithValues(OverrideFirstDimensionValue, OverrideSecondDimensionValue, OverrideThirdDimensionValue);

        // [GIVEN] Three GL accounts with dimensions and balances and one Balancing G/L Account
        CreateBreakdownAccountsWithBalances(FirstBreakdownGLAccount, SecondBreakdownGLAccount, ThirdBreakdownGLAccount);
        DestinationGLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        BalancingGLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());

        // [GIVEN] An Allocation Account with variable GL distributions and split per quantity
        CreateAllocationAccountwithVariableGLDistributions(AllocationAccount, FirstDimensionValue, SecondDimensionValue, ThirdDimensionValue, DestinationGLAccount, FirstBreakdownGLAccount, SecondBreakdownGLAccount, ThirdBreakdownGLAccount);
        AllocationAccount."Document Lines Split" := AllocationAccount."Document Lines Split"::"Split Quantity";
        AllocationAccount.Modify();

        // [GIVEN] The Sales Invoice with Item and Allocation account
        CreateSalesInvoice(AllocationAccount."No.", SalesInvoice, SalesHeader);

        // [GIVEN] User defines an override manually
        LibraryVariableStorage.Enqueue(OverrideFirstDimensionValue.SystemId);
        LibraryVariableStorage.Enqueue(OverrideSecondDimensionValue.SystemId);
        LibraryVariableStorage.Enqueue(OverrideThirdDimensionValue.SystemId);
        SalesInvoice.SalesLines.RedistributeAccAllocations.Invoke();

        // [WHEN] The Sales Invoice is posted
        SalesInvoice.Post.Invoke();
        SalesInvoiceHeader.SetRange("Draft Invoice SystemId", SalesHeader.SystemId);
        SalesInvoiceHeader.FindFirst();

        // [THEN] The costs are split into mulitple ledger entries which has the same dimension code
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.SetRange(Type, SalesInvoiceLine.Type::"G/L Account");
        Assert.AreEqual(3, SalesInvoiceLine.Count(), 'Wrong number of Sales Invoice Lines created for the destination account');
        SalesInvoiceLine.CalcSums(Quantity);
        Assert.AreEqual(1, SalesInvoiceLine.Quantity, 'The quantity was not calculated correctly');

        // [THEN] Override values are used
        FirstDimensionValue.SetRecFilter();
        OverrideFirstDimensionValue.SetFilter(SystemId, '%1|%2', FirstDimensionValue.SystemId, OverrideFirstDimensionValue.SystemId);
        SalesInvoiceLine.SetRange("Dimension Set ID", CreateDimensionSetID(OverrideFirstDimensionValue));
        Assert.AreEqual(1, SalesInvoiceLine.Count(), 'Wrong number of Sales Invoice Lines for the first breakdown account');

        SalesInvoiceLine.FindFirst();
        Assert.AreEqual(Round(GetLineAmountToForceRounding() * GetOverrideQuantity(), AllocationAccountMgt.GetCurrencyRoundingPrecision(SalesInvoiceLine.GetCurrencyCode())), SalesInvoiceLine."Line Amount", 'The override amount was not used');
        PostedAmount := SalesInvoiceLine."Line Amount";

        SecondDimensionValue.SetRecFilter();
        OverrideSecondDimensionValue.SetFilter(SystemId, '%1|%2', SecondDimensionValue.SystemId, OverrideSecondDimensionValue.SystemId);
        SalesInvoiceLine.SetRange("Dimension Set ID", CreateDimensionSetID(OverrideSecondDimensionValue));
        Assert.AreEqual(1, SalesInvoiceLine.Count(), 'Wrong number of Sales Invoice Lines for the second breakdown account');
        SalesInvoiceLine.FindFirst();
        Assert.AreEqual(Round(GetLineAmountToForceRounding() * GetOverrideQuantity(), AllocationAccountMgt.GetCurrencyRoundingPrecision(SalesInvoiceLine.GetCurrencyCode())), SalesInvoiceLine."Line Amount", 'The override amount was not used');
        PostedAmount += SalesInvoiceLine."Line Amount";

        ThirdDimensionValue.SetRecFilter();
        OverrideThirdDimensionValue.SetFilter(SystemId, '%1|%2', ThirdDimensionValue.SystemId, OverrideThirdDimensionValue.SystemId);
        SalesInvoiceLine.SetRange("Dimension Set ID", CreateDimensionSetID(OverrideThirdDimensionValue));
        Assert.AreEqual(1, SalesInvoiceLine.Count(), 'Wrong number of Sales Invoice Lines for the third breakdown account');
        SalesInvoiceLine.FindFirst();
        PostedAmount += SalesInvoiceLine."Line Amount";

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
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        AllocationAccountPage: TestPage "Allocation Account";
        SalesInvoice: TestPage "Sales Invoice";
        PostedAmount: Decimal;
    begin
        Initialize();

        // [GIVEN] Three GL accounts with dimensions and balances, one Balancing G/L Account and three Destination G/L Accounts
        CreateBreakdownAccountsWithBalances(FirstBreakdownGLAccount, SecondBreakdownGLAccount, ThirdBreakdownGLAccount);
        FirstDestinationGLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        SecondDestinationGLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        ThirdDestinationGLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        BalancingGLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());

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

        // [GIVEN] The Sales Invoice with an Item and a Allocation Account
        CreateSalesInvoice(AllocationAccount."No.", SalesInvoice, SalesHeader);

        // [WHEN] The Sales Invoice is posted
        SalesInvoice.Post.Invoke();
        SalesInvoiceHeader.SetRange("Draft Invoice SystemId", SalesHeader.SystemId);
        SalesInvoiceHeader.FindFirst();

        // [THEN] The costs are split into mulitple ledger entries which has the same dimension code
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.SetRange("No.", FirstDestinationGLAccount."No.");
        Assert.AreEqual(1, SalesInvoiceLine.Count(), 'Wrong number of Sales Invoice Lines created for the first destination account');
        SalesInvoiceLine.FindFirst();
        VerifySalesLineAmount(SalesInvoiceLine, GetLineAmountToForceRounding(), 6);
        PostedAmount := SalesInvoiceLine.Amount;

        SalesInvoiceLine.SetRange("No.", SecondDestinationGLAccount."No.");
        Assert.AreEqual(1, SalesInvoiceLine.Count(), 'Wrong number of Sales Invoice Lines for the second destination account');
        SalesInvoiceLine.FindFirst();
        VerifySalesLineAmount(SalesInvoiceLine, GetLineAmountToForceRounding(), 3);
        PostedAmount += SalesInvoiceLine.Amount;

        SalesInvoiceLine.SetRange("No.", ThirdDestinationGLAccount."No.");
        Assert.AreEqual(1, SalesInvoiceLine.Count(), 'Wrong number of Sales Invoice Lines for the second destination account');
        SalesInvoiceLine.FindFirst();
        VerifySalesLineAmount(SalesInvoiceLine, GetLineAmountToForceRounding(), 2);
        PostedAmount += SalesInvoiceLine.Amount;

        SalesInvoiceLine.CalcSums(Quantity);
        Assert.AreEqual(1, SalesInvoiceLine.Quantity, 'The quantity was not calculated correctly');

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
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        AllocationAccountPage: TestPage "Allocation Account";
        SalesInvoice: TestPage "Sales Invoice";
        PostedAmount: Decimal;
    begin
        Initialize();

        // [GIVEN] Three GL accounts with dimensions and balances, one Balancing G/L Account and three Destination G/L Accounts
        CreateBreakdownAccountsWithBalances(FirstBreakdownGLAccount, SecondBreakdownGLAccount, ThirdBreakdownGLAccount);
        FirstDestinationGLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        SecondDestinationGLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        ThirdDestinationGLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        BalancingGLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());

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

        // [GIVEN] The Sales Invoice with an Item and a Allocation Account
        CreateSalesInvoice(AllocationAccount."No.", SalesInvoice, SalesHeader);

        // [WHEN] The Sales Invoice is posted
        SalesInvoice.SalesLines.ReplaceAllocationAccountWithLines.Invoke();
        SalesInvoice.Post.Invoke();
        SalesInvoiceHeader.SetRange("Draft Invoice SystemId", SalesHeader.SystemId);
        SalesInvoiceHeader.FindFirst();

        // [THEN] The costs are split into mulitple ledger entries which has the same dimension code
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.SetRange("No.", FirstDestinationGLAccount."No.");
        Assert.AreEqual(1, SalesInvoiceLine.Count(), 'Wrong number of Sales Invoice Lines created for the first destination account');
        SalesInvoiceLine.FindFirst();
        VerifySalesLineAmount(SalesInvoiceLine, GetLineAmountToForceRounding(), 6);
        PostedAmount := SalesInvoiceLine.Amount;

        SalesInvoiceLine.SetRange("No.", SecondDestinationGLAccount."No.");
        Assert.AreEqual(1, SalesInvoiceLine.Count(), 'Wrong number of Sales Invoice Lines for the second destination account');
        SalesInvoiceLine.FindFirst();
        VerifySalesLineAmount(SalesInvoiceLine, GetLineAmountToForceRounding(), 3);
        PostedAmount += SalesInvoiceLine.Amount;

        SalesInvoiceLine.SetRange("No.", ThirdDestinationGLAccount."No.");
        Assert.AreEqual(1, SalesInvoiceLine.Count(), 'Wrong number of Sales Invoice Lines for the second destination account');
        SalesInvoiceLine.FindFirst();
        VerifySalesLineAmount(SalesInvoiceLine, GetLineAmountToForceRounding(), 2);
        PostedAmount += SalesInvoiceLine.Amount;

        SalesInvoiceLine.CalcSums(Quantity);
        Assert.AreEqual(1, SalesInvoiceLine.Quantity, 'The quantity was not calculated correctly');

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
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        AllocationAccountPage: TestPage "Allocation Account";
        SalesInvoice: TestPage "Sales Invoice";
        PostedAmount: Decimal;
    begin
        Initialize();

        // [GIVEN] Three GL accounts with dimensions and balances, one Balancing G/L Account and three Destination G/L Accounts
        CreateBreakdownAccountsWithBalances(FirstBreakdownGLAccount, SecondBreakdownGLAccount, ThirdBreakdownGLAccount);
        FirstDestinationGLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        SecondDestinationGLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        ThirdDestinationGLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        BalancingGLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());

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

        // [GIVEN] The Sales Invoice with an Item and a Allocation Account
        CreateSalesInvoice(AllocationAccount."No.", SalesInvoice, SalesHeader);

        // [WHEN] The Sales Invoice is posted
        SalesInvoice.SalesLines.ReplaceAllocationAccountWithLines.Invoke();
        SalesInvoice.Post.Invoke();
        SalesInvoiceHeader.SetRange("Draft Invoice SystemId", SalesHeader.SystemId);
        SalesInvoiceHeader.FindFirst();

        // [THEN] The costs are split into mulitple ledger entries which has the same dimension code
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.SetRange(Type, SalesInvoiceLine.Type::"G/L Account");
        SalesInvoiceLine.CalcSums(Quantity);
        Assert.AreEqual(3, SalesInvoiceLine.Quantity, 'The quantity was not calculated correctly');

        SalesInvoiceLine.SetRange("No.", FirstDestinationGLAccount."No.");
        Assert.AreEqual(1, SalesInvoiceLine.Count(), 'Wrong number of Sales Invoice Lines created for the first destination account');

        SalesInvoiceLine.FindFirst();
        VerifySalesLineAmount(SalesInvoiceLine, GetLineAmountToForceRounding(), 6);
        PostedAmount := SalesInvoiceLine.Amount;

        SalesInvoiceLine.SetRange("No.", SecondDestinationGLAccount."No.");
        Assert.AreEqual(1, SalesInvoiceLine.Count(), 'Wrong number of Sales Invoice Lines for the second destination account');
        SalesInvoiceLine.FindFirst();
        VerifySalesLineAmount(SalesInvoiceLine, GetLineAmountToForceRounding(), 3);
        PostedAmount += SalesInvoiceLine.Amount;

        SalesInvoiceLine.SetRange("No.", ThirdDestinationGLAccount."No.");
        Assert.AreEqual(1, SalesInvoiceLine.Count(), 'Wrong number of Sales Invoice Lines for the second destination account');
        SalesInvoiceLine.FindFirst();
        VerifySalesLineAmount(SalesInvoiceLine, GetLineAmountToForceRounding(), 2);
        PostedAmount += SalesInvoiceLine.Amount;

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
        SalesHeader: Record "Sales Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        AllocationAccount: Record "Allocation Account";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoice: TestPage "Sales Invoice";
        PostedAmount: Decimal;
    begin
        Initialize();

        // [GIVEN] A dimension that is defined as a department with three values
        CreateDimensionsWithValues(FirstDimensionValue, SecondDimensionValue, ThirdDimensionValue);

        // [GIVEN] Three GL accounts with dimensions and balances and one Balancing G/L Account
        CreateBreakdownAccountsWithBalances(FirstBreakdownGLAccount, SecondBreakdownGLAccount, ThirdBreakdownGLAccount);
        DestinationGLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        BalancingGLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());

        // [GIVEN] An Allocation Account with variable GL distributions
        CreateAllocationAccountwithFixedGLDistributions(AllocationAccount, FirstDimensionValue, SecondDimensionValue, ThirdDimensionValue, DestinationGLAccount);
        AllocationAccount."Document Lines Split" := AllocationAccount."Document Lines Split"::"Split Quantity";
        AllocationAccount.Modify();

        // [GIVEN] The Sales Invoice with Item and Allocation account
        CreateSalesInvoice(AllocationAccount."No.", SalesInvoice, SalesHeader);

        // [WHEN] The Sales Invoice is posted
        SalesInvoice.Post.Invoke();
        SalesInvoiceHeader.SetRange("Draft Invoice SystemId", SalesHeader.SystemId);
        SalesInvoiceHeader.FindFirst();

        // [THEN] The costs are split into mulitple ledger entries which has the same dimension code
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.SetRange(Type, SalesInvoiceLine.Type::"G/L Account");
        Assert.AreEqual(3, SalesInvoiceLine.Count(), 'Wrong number of Sales Invoice Lines created for the destination account');
        SalesInvoiceLine.CalcSums(Quantity);
        Assert.AreEqual(1, SalesInvoiceLine.Quantity, 'The quantity was not calculated correctly');

        FirstDimensionValue.SetRecFilter();
        SalesInvoiceLine.SetRange("Dimension Set ID", CreateDimensionSetID(FirstDimensionValue));
        Assert.AreEqual(1, SalesInvoiceLine.Count(), 'Wrong number of Sales Invoice Lines for the first line');
        SalesInvoiceLine.FindFirst();
        VerifySalesLineAmount(SalesInvoiceLine, GetLineAmountToForceRounding(), 6);
        PostedAmount := SalesInvoiceLine.Amount;

        SecondDimensionValue.SetRecFilter();
        SalesInvoiceLine.SetRange("Dimension Set ID", CreateDimensionSetID(SecondDimensionValue));
        Assert.AreEqual(1, SalesInvoiceLine.Count(), 'Wrong number of Sales Invoice Lines for the second line');
        SalesInvoiceLine.FindFirst();
        VerifySalesLineAmount(SalesInvoiceLine, GetLineAmountToForceRounding(), 3);
        PostedAmount += SalesInvoiceLine.Amount;

        ThirdDimensionValue.SetRecFilter();
        SalesInvoiceLine.SetRange("Dimension Set ID", CreateDimensionSetID(ThirdDimensionValue));
        Assert.AreEqual(1, SalesInvoiceLine.Count(), 'Wrong number of Sales Invoice Lines for the third line');
        SalesInvoiceLine.FindFirst();
        VerifySalesLineAmount(SalesInvoiceLine, GetLineAmountToForceRounding(), 2);
        PostedAmount += SalesInvoiceLine.Amount;

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
        SalesHeader: Record "Sales Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        AllocationAccount: Record "Allocation Account";
        AllocAccManualOverride: Record "Alloc. Acc. Manual Override";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoice: TestPage "Sales Invoice";
        PostedAmount: Decimal;
        NewAmount: Decimal;
    begin
        Initialize();

        // [GIVEN] A dimension that is defined as a department with three values
        CreateDimensionsWithValues(FirstDimensionValue, SecondDimensionValue, ThirdDimensionValue);
        CreateDimensionsWithValues(OverrideFirstDimensionValue, OverrideSecondDimensionValue, OverrideThirdDimensionValue);

        // [GIVEN] Three GL accounts with dimensions and balances and one Balancing G/L Account
        CreateBreakdownAccountsWithBalances(FirstBreakdownGLAccount, SecondBreakdownGLAccount, ThirdBreakdownGLAccount);
        DestinationGLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        BalancingGLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());

        // [GIVEN] An Allocation Account with variable GL distributions
        CreateAllocationAccountwithVariableGLDistributions(AllocationAccount, FirstDimensionValue, SecondDimensionValue, ThirdDimensionValue, DestinationGLAccount, FirstBreakdownGLAccount, SecondBreakdownGLAccount, ThirdBreakdownGLAccount);

        // [GIVEN] The Sales Invoice with Item and Allocation account
        CreateSalesInvoice(AllocationAccount."No.", SalesInvoice, SalesHeader);

        // [GIVEN] User defines an override manually
        LibraryVariableStorage.Enqueue(GetLineAmountToForceRounding());
        LibraryVariableStorage.Enqueue(OverrideFirstDimensionValue.SystemId);
        LibraryVariableStorage.Enqueue(OverrideSecondDimensionValue.SystemId);
        LibraryVariableStorage.Enqueue(OverrideThirdDimensionValue.SystemId);
        SalesInvoice.SalesLines.RedistributeAccAllocations.Invoke();
        Assert.IsFalse(AllocAccManualOverride.IsEmpty(), 'The manual override was not created');

        // [WHEN] The General Journal line is modified
        SalesInvoice.SalesLines.First();
        SalesInvoice.SalesLines.Next();
        NewAmount := Round(GetLineAmountToForceRounding() / 2, 0.01);
        SalesInvoice.SalesLines."Line Amount".SetValue(NewAmount);
        SalesInvoice.SalesLines.First();

        // [THEN] Manual overrides are deleted
        Assert.IsTrue(AllocAccManualOverride.IsEmpty(), 'The manual override was not deleted');

        // [WHEN] The Sales Invoice is posted without overrides
        SalesInvoice.Post.Invoke();
        SalesInvoiceHeader.SetRange("Draft Invoice SystemId", SalesHeader.SystemId);
        SalesInvoiceHeader.FindFirst();

        // [THEN] Regular values are used
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        Assert.AreEqual(4, SalesInvoiceLine.Count(), 'Wrong number of Sales Invoice Lines created for the destination account');

        FirstDimensionValue.SetRecFilter();
        SalesInvoiceLine.SetRange("Dimension Set ID", CreateDimensionSetID(FirstDimensionValue));
        Assert.AreEqual(1, SalesInvoiceLine.Count(), 'Wrong number of Sales Invoice Lines for the first breakdown account');
        SalesInvoiceLine.FindFirst();
        Assert.AreEqual(NewAmount / 6, SalesInvoiceLine."Line Amount", 'The new amount was not used');
        PostedAmount := SalesInvoiceLine."Line Amount";

        SecondDimensionValue.SetRecFilter();
        SalesInvoiceLine.SetRange("Dimension Set ID", CreateDimensionSetID(SecondDimensionValue));
        Assert.AreEqual(1, SalesInvoiceLine.Count(), 'Wrong number of Sales Invoice Lines for the second breakdown account');
        SalesInvoiceLine.FindFirst();
        Assert.AreEqual(NewAmount / 3, SalesInvoiceLine."Line Amount", 'The new amount was not used');
        PostedAmount += SalesInvoiceLine."Line Amount";

        ThirdDimensionValue.SetRecFilter();
        SalesInvoiceLine.SetRange("Dimension Set ID", CreateDimensionSetID(ThirdDimensionValue));
        Assert.AreEqual(1, SalesInvoiceLine.Count(), 'Wrong number of Sales Invoice Lines for the third breakdown account');
        SalesInvoiceLine.FindFirst();
        PostedAmount += SalesInvoiceLine."Line Amount";

        Assert.AreEqual(NewAmount, PostedAmount, 'The rounding amount was not distributed correctly');
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
        SalesHeader: Record "Sales Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        AllocationAccount: Record "Allocation Account";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoice: TestPage "Sales Invoice";
        PostedAmount: Decimal;
    begin
        Initialize();

        // [GIVEN] A dimension that is defined as a department with three values
        CreateDimensionsWithValues(FirstDimensionValue, SecondDimensionValue, ThirdDimensionValue);

        // [GIVEN] Three GL accounts with dimensions and balances and one Balancing G/L Account
        CreateBreakdownAccountsWithBalances(FirstBreakdownGLAccount, SecondBreakdownGLAccount, ThirdBreakdownGLAccount);
        DestinationGLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        BalancingGLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());

        // [GIVEN] An Allocation Account with variable GL distributions
        CreateAllocationAccountwithFixedGLDistributions(AllocationAccount, FirstDimensionValue, SecondDimensionValue, ThirdDimensionValue, DestinationGLAccount);

        // [GIVEN] The Sales Invoice with Item and Allocation account
        CreateSalesInvoice(AllocationAccount."No.", SalesInvoice, SalesHeader);

        // [WHEN] The Sales Invoice is posted
        SalesInvoice.Post.Invoke();
        SalesInvoiceHeader.SetRange("Draft Invoice SystemId", SalesHeader.SystemId);
        SalesInvoiceHeader.FindFirst();

        // [THEN] The costs are split into mulitple ledger entries which has the same dimension code
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        Assert.AreEqual(4, SalesInvoiceLine.Count(), 'Wrong number of Sales Invoice Lines created for the destination account');

        FirstDimensionValue.SetRecFilter();
        SalesInvoiceLine.SetRange("Dimension Set ID", CreateDimensionSetID(FirstDimensionValue));
        Assert.AreEqual(1, SalesInvoiceLine.Count(), 'Wrong number of Sales Invoice Lines for the first line');
        SalesInvoiceLine.FindFirst();
        VerifySalesLineAmount(SalesInvoiceLine, GetLineAmountToForceRounding(), 6);
        PostedAmount := SalesInvoiceLine.Amount;

        SecondDimensionValue.SetRecFilter();
        SalesInvoiceLine.SetRange("Dimension Set ID", CreateDimensionSetID(SecondDimensionValue));
        Assert.AreEqual(1, SalesInvoiceLine.Count(), 'Wrong number of Sales Invoice Lines for the second line');
        SalesInvoiceLine.FindFirst();
        VerifySalesLineAmount(SalesInvoiceLine, GetLineAmountToForceRounding(), 3);
        PostedAmount += SalesInvoiceLine.Amount;

        ThirdDimensionValue.SetRecFilter();
        SalesInvoiceLine.SetRange("Dimension Set ID", CreateDimensionSetID(ThirdDimensionValue));
        Assert.AreEqual(1, SalesInvoiceLine.Count(), 'Wrong number of Sales Invoice Lines for the third line');
        SalesInvoiceLine.FindFirst();
        VerifySalesLineAmount(SalesInvoiceLine, GetLineAmountToForceRounding(), 2);
        PostedAmount += SalesInvoiceLine.Amount;

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
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        AllocationAccountPage: TestPage "Allocation Account";
        SalesInvoice: TestPage "Sales Invoice";
        PostedAmount: Decimal;
    begin
        Initialize();

        // [GIVEN] Three GL accounts with dimensions and balances, one Balancing G/L Account and three Destination G/L Accounts
        CreateBreakdownAccountsWithBalances(FirstBreakdownGLAccount, SecondBreakdownGLAccount, ThirdBreakdownGLAccount);
        FirstDestinationGLAccount.Get(LibraryERM.CreateGLAccountWithPurchSetup());
        SecondDestinationGLAccount.Get(LibraryERM.CreateGLAccountWithPurchSetup());
        ThirdDestinationGLAccount.Get(LibraryERM.CreateGLAccountWithPurchSetup());
        BalancingGLAccount.Get(LibraryERM.CreateGLAccountWithPurchSetup());

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

        // [GIVEN] The Sales Invoice with an Item and a Allocation Account
        CreateSalesInvoiceWithInheritFromParent(FirstDestinationGLAccount."No.", AllocationAccount."No.", SalesInvoice, SalesHeader);

        // [WHEN] The Sales Invoice is posted
        SalesInvoice.Post.Invoke();
        SalesInvoiceHeader.SetRange("Draft Invoice SystemId", SalesHeader.SystemId);
        SalesInvoiceHeader.FindFirst();

        // [THEN] The costs are split into mulitple ledger entries which has the same dimension code
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.SetRange("No.", FirstDestinationGLAccount."No.");
        Assert.AreEqual(1, SalesInvoiceLine.Count(), 'Wrong number of Sales Invoice Lines created for the first destination account');
        SalesInvoiceLine.FindFirst();
        VerifySalesLineAmount(SalesInvoiceLine, GetLineAmountToForceRounding(), 6);
        PostedAmount := SalesInvoiceLine.Amount;

        SalesInvoiceLine.SetRange("No.", SecondDestinationGLAccount."No.");
        Assert.AreEqual(1, SalesInvoiceLine.Count(), 'Wrong number of Sales Invoice Lines for the second destination account');
        SalesInvoiceLine.FindFirst();
        VerifySalesLineAmount(SalesInvoiceLine, GetLineAmountToForceRounding(), 3);
        PostedAmount += SalesInvoiceLine.Amount;

        SalesInvoiceLine.SetRange("No.", ThirdDestinationGLAccount."No.");
        Assert.AreEqual(1, SalesInvoiceLine.Count(), 'Wrong number of Sales Invoice Lines for the second destination account');
        SalesInvoiceLine.FindFirst();
        VerifySalesLineAmount(SalesInvoiceLine, GetLineAmountToForceRounding(), 2);
        PostedAmount += SalesInvoiceLine.Amount;

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
        SalesHeader: Record "Sales Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoice: TestPage "Sales Invoice";
        PostedAmount: Decimal;
    begin
        Initialize();

        // [GIVEN] A dimension that is defined as a department with three values
        CreateDimensionsWithValues(FirstDimensionValue, SecondDimensionValue, ThirdDimensionValue);

        // [GIVEN] Three GL accounts with dimensions and balances and one Balancing G/L Account
        CreateBreakdownAccountsWithBalances(FirstBreakdownGLAccount, SecondBreakdownGLAccount, ThirdBreakdownGLAccount);
        DestinationGLAccount.Get(LibraryERM.CreateGLAccountWithPurchSetup());
        BalancingGLAccount.Get(LibraryERM.CreateGLAccountWithPurchSetup());

        // [GIVEN] An Allocation Account with variable GL distributions
        CreateAllocationAccountwithVariableGLDistributionsAndInheritFromParent(AllocationAccount, FirstDimensionValue, SecondDimensionValue, ThirdDimensionValue, FirstBreakdownGLAccount, SecondBreakdownGLAccount, ThirdBreakdownGLAccount);

        // [GIVEN] The Sales Invoice with Item and Allocation account
        CreateSalesInvoiceWithInheritFromParent(DestinationGLAccount."No.", AllocationAccount."No.", SalesInvoice, SalesHeader);

        // [WHEN] The Sales Invoice is posted
        SalesInvoice.Post.Invoke();
        SalesInvoiceHeader.SetRange("Draft Invoice SystemId", SalesHeader.SystemId);
        SalesInvoiceHeader.FindFirst();

        // [THEN] The costs are split into mulitple ledger entries which has the same dimension code
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.SetRange("No.", DestinationGLAccount."No.");

        FirstDimensionValue.SetRecFilter();
        SalesInvoiceLine.SetRange("Dimension Set ID", CreateDimensionSetID(FirstDimensionValue));
        Assert.AreEqual(1, SalesInvoiceLine.Count(), 'Wrong number of Sales Invoice Lines created for the first destination account');
        SalesInvoiceLine.FindFirst();
        VerifySalesLineAmount(SalesInvoiceLine, GetLineAmountToForceRounding(), 6);
        PostedAmount := SalesInvoiceLine.Amount;

        SecondDimensionValue.SetRecFilter();
        SalesInvoiceLine.SetRange("Dimension Set ID", CreateDimensionSetID(SecondDimensionValue));
        Assert.AreEqual(1, SalesInvoiceLine.Count(), 'Wrong number of Sales Invoice Lines for the second destination account');
        SalesInvoiceLine.FindFirst();
        VerifySalesLineAmount(SalesInvoiceLine, GetLineAmountToForceRounding(), 3);
        PostedAmount += SalesInvoiceLine.Amount;

        ThirdDimensionValue.SetRecFilter();
        SalesInvoiceLine.SetRange("Dimension Set ID", CreateDimensionSetID(ThirdDimensionValue));
        Assert.AreEqual(1, SalesInvoiceLine.Count(), 'Wrong number of Sales Invoice Lines for the second destination account');
        SalesInvoiceLine.FindFirst();
        VerifySalesLineAmount(SalesInvoiceLine, GetLineAmountToForceRounding(), 2);
        PostedAmount += SalesInvoiceLine.Amount;
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
        SalesHeader: Record "Sales Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        AllocationAccount: Record "Allocation Account";
        AllocAccManualOverride: Record "Alloc. Acc. Manual Override";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoice: TestPage "Sales Invoice";
        PostedAmount: Decimal;
    begin
        Initialize();

        // [GIVEN] A dimension that is defined as a department with three values
        CreateDimensionsWithValues(FirstDimensionValue, SecondDimensionValue, ThirdDimensionValue);
        CreateDimensionsWithValues(OverrideFirstDimensionValue, OverrideSecondDimensionValue, OverrideThirdDimensionValue);

        // [GIVEN] Three GL accounts with dimensions and balances and one Balancing G/L Account
        CreateBreakdownAccountsWithBalances(FirstBreakdownGLAccount, SecondBreakdownGLAccount, ThirdBreakdownGLAccount);
        DestinationGLAccount.Get(LibraryERM.CreateGLAccountWithPurchSetup());
        BalancingGLAccount.Get(LibraryERM.CreateGLAccountWithPurchSetup());

        // [GIVEN] An Allocation Account with variable GL distributions
        CreateAllocationAccountwithVariableGLDistributionsAndInheritFromParent(AllocationAccount, FirstDimensionValue, SecondDimensionValue, ThirdDimensionValue, FirstBreakdownGLAccount, SecondBreakdownGLAccount, ThirdBreakdownGLAccount);

        // [GIVEN] The Sales Invoice with Item and Allocation account
        CreateSalesInvoiceWithInheritFromParent(DestinationGLAccount."No.", AllocationAccount."No.", SalesInvoice, SalesHeader);

        // [GIVEN] User defines an override manually
        LibraryVariableStorage.Enqueue(GetLineAmountToForceRounding());
        LibraryVariableStorage.Enqueue(OverrideFirstDimensionValue.SystemId);
        LibraryVariableStorage.Enqueue(OverrideSecondDimensionValue.SystemId);
        LibraryVariableStorage.Enqueue(OverrideThirdDimensionValue.SystemId);
        SalesInvoice.SalesLines.RedistributeAccAllocations.Invoke();

        // [WHEN] The Sales Invoice is posted
        SalesInvoice.Post.Invoke();
        SalesInvoiceHeader.SetRange("Draft Invoice SystemId", SalesHeader.SystemId);
        SalesInvoiceHeader.FindFirst();

        // [THEN] The costs are split into mulitple ledger entries which has the same dimension code
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        Assert.AreEqual(4, SalesInvoiceLine.Count(), 'Wrong number of Sales Invoice Lines created for the destination account');

        // [THEN] Override values are used
        FirstDimensionValue.SetRecFilter();
        OverrideFirstDimensionValue.SetFilter(SystemId, '%1|%2', FirstDimensionValue.SystemId, OverrideFirstDimensionValue.SystemId);
        SalesInvoiceLine.SetRange("Dimension Set ID", CreateDimensionSetID(OverrideFirstDimensionValue));
        Assert.AreEqual(1, SalesInvoiceLine.Count(), 'Wrong number of Sales Invoice Lines for the first breakdown account');
        SalesInvoiceLine.FindFirst();
        Assert.AreEqual(GetOverrideAmount(), SalesInvoiceLine."Line Amount", 'The override amount was not used');
        PostedAmount := SalesInvoiceLine."Line Amount";

        SecondDimensionValue.SetRecFilter();
        OverrideSecondDimensionValue.SetFilter(SystemId, '%1|%2', SecondDimensionValue.SystemId, OverrideSecondDimensionValue.SystemId);
        SalesInvoiceLine.SetRange("Dimension Set ID", CreateDimensionSetID(OverrideSecondDimensionValue));
        Assert.AreEqual(1, SalesInvoiceLine.Count(), 'Wrong number of Sales Invoice Lines for the second breakdown account');
        SalesInvoiceLine.FindFirst();
        Assert.AreEqual(GetOverrideAmount(), SalesInvoiceLine."Line Amount", 'The override amount was not used');
        PostedAmount += SalesInvoiceLine."Line Amount";

        ThirdDimensionValue.SetRecFilter();
        OverrideThirdDimensionValue.SetFilter(SystemId, '%1|%2', ThirdDimensionValue.SystemId, OverrideThirdDimensionValue.SystemId);
        SalesInvoiceLine.SetRange("Dimension Set ID", CreateDimensionSetID(OverrideThirdDimensionValue));
        Assert.AreEqual(1, SalesInvoiceLine.Count(), 'Wrong number of Sales Invoice Lines for the third breakdown account');
        SalesInvoiceLine.FindFirst();
        PostedAmount += SalesInvoiceLine."Line Amount";

        Assert.AreEqual(GetLineAmountToForceRounding(), PostedAmount, 'The rounding amount was not distributed correctly');
        Assert.IsTrue(AllocAccManualOverride.IsEmpty(), 'The manual override was not deleted');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse')]
    procedure AccountTypeChangeOnAllocationKeepsLineIntact()
    var
        GLAccount: Record "G/L Account";
        DummyAllocAccountDistribution: Record "Alloc. Account Distribution";
        AllocationAccountPage: TestPage "Allocation Account";
    begin
        // [SCENARIO 539504] Issue when modifying the Account Type on the allocation page it resets automatically.
        Initialize();

        // [GIVEN] Create GL Account.
        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());

        // [GIVEN] Open Allocation Account Page.
        AllocationAccountPage.OpenNew();

        // [GIVEN] Create Allocation Account.
        AllocationAccountPage."No.".SetValue(LibraryERM.CreateNoSeriesCode());

        // [GIVEN] Create New Fixed Distribution.
        AllocationAccountPage.FixedAccountDistribution.New();

        // [GIVEN] Set Value to GL Account and Assign Gl Account No.
        AllocationAccountPage.FixedAccountDistribution."Destination Account Type".SetValue(DummyAllocAccountDistribution."Destination Account Type"::"G/L Account");
        AllocationAccountPage.FixedAccountDistribution."Destination Account Number".SetValue(GLAccount."No.");

        // [GIVEN] Change the Account Type to Variable and Cancel it.
        AllocationAccountPage."Account Type".SetValue(DummyAllocAccountDistribution."Account Type"::Variable);

        // [THEN] Destination Account Number must not be reset.
        Assert.AreEqual(
            AllocationAccountPage.FixedAccountDistribution."Destination Account Number".Value(),
            GLAccount."No.",
            StrSubstNo(DestinationAccountErr,
            GLAccount."No.",
            AllocationAccountPage.Caption()));
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

    local procedure CreateSalesInvoiceWithInheritFromParent(GLAccountNo: Code[20]; SelectedAlloctationAccountNo: Code[20]; var SalesInvoice: TestPage "Sales Invoice"; var SalesHeader: Record "Sales Header")
    var
        DummySalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesInvoice(SalesHeader);
        SalesInvoice.OpenEdit();
        SalesInvoice.GoToRecord(SalesHeader);
        SalesInvoice.SalesLines.New();
        SalesInvoice.SalesLines.Type.SetValue(DummySalesLine.Type::"G/L Account");
        SalesInvoice.SalesLines."No.".SetValue(GLAccountNo);
        SalesInvoice.SalesLines.Quantity.SetValue(1);
        SalesInvoice.SalesLines."Unit Price".SetValue(GetLineAmountToForceRounding());
        SalesInvoice.SalesLines."Allocation Account No.".SetValue(SelectedAlloctationAccountNo);
    end;

    local procedure CreateSalesInvoice(AccountNo: Code[20]; var SalesInvoice: TestPage "Sales Invoice"; var SalesHeader: Record "Sales Header")
    var
        DummySalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesInvoice(SalesHeader);
        SalesInvoice.OpenEdit();
        SalesInvoice.GoToRecord(SalesHeader);
        SalesInvoice.SalesLines.New();
        SalesInvoice.SalesLines.Type.SetValue(DummySalesLine.Type::"Allocation Account");
        SalesInvoice.SalesLines."No.".SetValue(AccountNo);
        SalesInvoice.SalesLines.Quantity.SetValue(1);
        SalesInvoice.SalesLines."Unit Price".SetValue(GetLineAmountToForceRounding());
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
            GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());

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
            GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());

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

    local procedure VerifySalesLineAmount(var SalesInvoiceLine: Record "Sales Invoice Line"; ExpectedAmount: Decimal; Division: Integer)
    begin
        Assert.IsTrue((ExpectedAmount / Division + 0.01) >= SalesInvoiceLine."Line Amount", 'The Line amount is too high');
        Assert.IsTrue((ExpectedAmount / Division - 0.01) <= SalesInvoiceLine."Line Amount", 'The Line amount is too low');
    end;

    local procedure CreateBreakdownAccountsWithBalances(var FirstBreakdownGLAccount: Record "G/L Account"; var SecondBreakdownGLAccount: Record "G/L Account"; var ThirdBreakdownGLAccount: Record "G/L Account")
    begin
        FirstBreakdownGLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        CreateBalanceForGLAccount(100, FirstBreakdownGLAccount, 0);

        SecondBreakdownGLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        CreateBalanceForGLAccount(200, SecondBreakdownGLAccount, 0);

        ThirdBreakdownGLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
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

    local procedure GetOverrideAmount(): Decimal
    begin
        exit(100.11);
    end;

    local procedure GetOverrideQuantity(): Decimal
    begin
        exit(0.33);
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

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(QuestionText: Text[1024]; var Relpy: Boolean)
    begin
        Relpy := true;
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerFalse(QuestionText: Text[1024]; var Relpy: Boolean)
    begin
        Relpy := false;
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
}
#pragma warning restore AA0210
