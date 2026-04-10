// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Test;

using Microsoft.Projects.Resources.Resource;

codeunit 136124 "Service Adjust Costs/Prices"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Adjust Resource Costs/Prices] [Service]
        IsInitialized := false;
    end;

    var
        LibraryService: Codeunit "Library - Service";
        LibraryRandom: Codeunit "Library - Random";
        LibraryResource: Codeunit "Library - Resource";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        WrongUpdateErrorMessage: Label 'Field must be updated as per Adjustment Factor.';
        ProfitChangeErrorMessage: Label 'Profit % must not change.';

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Service Adjust Costs/Prices");
        // Lazy Setup.
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Service Adjust Costs/Prices");

        LibraryService.SetupServiceMgtNoSeries();
        LibraryERMCountryData.CreateVATData();

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Service Adjust Costs/Prices");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateIndirectUnitCost()
    var
        Resource: Record Resource;
        Selection: Option "Direct Unit Cost","Indirect Cost %","Unit Cost","Profit %","Unit Price";
        AdjFactor: Decimal;
        UpdatedUnitCost: Decimal;
    begin
        // Covers document number - refer to TFS ID 130447.
        // Test Indirect Unit Cost of resource changes according to Adjustment factor.

        // 1. Setup: Create New Resource.
        CreateResource(Resource);

        // 2. Exercise: Input Indirect Unit Cost and Run Report Adjust Resource Costs/Prices.
        Resource.Validate("Unit Cost", LibraryRandom.RandDec(100, 2));
        Resource.Modify(true);
        AdjFactor := LibraryRandom.RandInt(10);
        UpdatedUnitCost := Resource."Unit Cost" * AdjFactor;
        VerifyResourceCostPrice(Resource, Selection::"Unit Cost", AdjFactor);

        // 3. Verify: Check that Unit Cost got updated as per Adjustment Factor.
        Resource.Get(Resource."No.");
        Assert.AreEqual(UpdatedUnitCost, Resource."Unit Cost", WrongUpdateErrorMessage);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateDirectUnitCost()
    var
        Resource: Record Resource;
        Selection: Option "Direct Unit Cost","Indirect Cost %","Unit Cost","Profit %","Unit Price";
        AdjFactor: Decimal;
        UpdateDirectUnitCost: Decimal;
    begin
        // Covers document number  - refer to TFS ID 130447.
        // Test Direct Unit Cost of resource changes according to Adjustment factor.

        // 1. Setup: Create New Resource.
        CreateResource(Resource);

        // 2. Exercise: Input Direct Unit Cost and Run Report Adjust Resource Costs/Prices.
        Resource.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        Resource.Modify(true);
        AdjFactor := LibraryRandom.RandInt(10);
        UpdateDirectUnitCost := Resource."Direct Unit Cost" * AdjFactor;
        VerifyResourceCostPrice(Resource, Selection::"Direct Unit Cost", AdjFactor);

        // 3. Verify: Check that Direct Unit Cost got updated as per Adjustment Factor.
        Resource.Get(Resource."No.");
        Assert.AreEqual(UpdateDirectUnitCost, Resource."Direct Unit Cost", WrongUpdateErrorMessage);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateUnitPrice()
    var
        Resource: Record Resource;
        Selection: Option "Direct Unit Cost","Indirect Cost %","Unit Cost","Profit %","Unit Price";
        AdjFactor: Decimal;
        UpdatedUnitPrice: Decimal;
    begin
        // Covers document number  - refer to TFS ID 130447.
        // Test Unit Price of resource changes according to Adjustment factor.

        // 1. Setup: Create New Resource.
        CreateResource(Resource);

        // 2. Exercise: Input Unit Price and Run Report Adjust Resource Costs/Prices.
        Resource.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        Resource.Modify(true);
        AdjFactor := LibraryRandom.RandInt(10);
        UpdatedUnitPrice := Resource."Unit Price" * AdjFactor;
        VerifyResourceCostPrice(Resource, Selection::"Unit Price", AdjFactor);

        // 3. Verify: Check that Unit Price got updated as per Adjustment Factor.
        Resource.Get(Resource."No.");
        Assert.AreEqual(UpdatedUnitPrice, Resource."Unit Price", WrongUpdateErrorMessage);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateIndirectCostPercentage()
    var
        Resource: Record Resource;
        Selection: Option "Direct Unit Cost","Indirect Cost %","Unit Cost","Profit %","Unit Price";
        AdjFactor: Decimal;
        UpdatedIndirectCostPercentage: Decimal;
    begin
        // Covers document number  - refer to TFS ID 130447.
        // Test Indirect Cost % of resource changes according to Adjustment factor.

        // 1. Setup: Create New Resource.
        CreateResource(Resource);

        // 2. Exercise: Input Indirect Cost % and Run Report Adjust Resource Costs/Prices.
        Resource.Validate("Indirect Cost %", LibraryRandom.RandDec(10, 2));
        Resource.Modify(true);
        AdjFactor := LibraryRandom.RandInt(10);
        UpdatedIndirectCostPercentage := Resource."Indirect Cost %" * AdjFactor;
        VerifyResourceCostPrice(Resource, Selection::"Indirect Cost %", AdjFactor);

        // 3. Verify: Check that Indirect Cost % got updated as per Adjustment Factor.
        Resource.Get(Resource."No.");
        Assert.AreEqual(UpdatedIndirectCostPercentage, Resource."Indirect Cost %", WrongUpdateErrorMessage);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateProfitPercentage()
    var
        Resource: Record Resource;
        Selection: Option "Direct Unit Cost","Indirect Cost %","Unit Cost","Profit %","Unit Price";
        BaseProfitPercentage: Decimal;
    begin
        // Covers document number  - refer to TFS ID 130447.
        // Test Profit % of resource will not changes according to Adjustment factor.

        // 1. Setup: Create New Resource.
        CreateResource(Resource);

        // 2. Exercise: Input Profit % and Run Report Adjust Resource Costs/Prices.
        Resource.Validate("Unit Cost", LibraryRandom.RandDec(10, 2));
        Resource.Validate("Unit Price", LibraryRandom.RandInt(10) + Resource."Unit Cost");
        Resource.Modify(true);
        BaseProfitPercentage := Resource."Profit %";
        VerifyResourceCostPrice(Resource, Selection::"Profit %", LibraryRandom.RandInt(10));

        // 3. Verify: Check that Profit % should not updated as per Adjustment Factor.
        Resource.Get(Resource."No.");
        Assert.AreEqual(BaseProfitPercentage, Resource."Profit %", ProfitChangeErrorMessage);
    end;

    local procedure CreateResource(var Resource: Record Resource)
    begin
        Initialize();
        LibraryResource.CreateResourceNew(Resource);
    end;

    local procedure VerifyResourceCostPrice(var Resource: Record Resource; Selection: Option; AdjFactor: Decimal)
    var
        AdjustResourceCostsPrices: Report "Adjust Resource Costs/Prices";
    begin
        Resource.SetRange("No.", Resource."No.");
        Clear(AdjustResourceCostsPrices);
        AdjustResourceCostsPrices.SetTableView(Resource);
        AdjustResourceCostsPrices.InitializeRequest(Selection, AdjFactor, '');
        AdjustResourceCostsPrices.UseRequestPage(false);
        AdjustResourceCostsPrices.RunModal();
    end;
}

