// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Test;

using Microsoft.Service.Document;
using Microsoft.Manufacturing.Journal;
using Microsoft.Finance.Dimension;
using System.TestLibraries.Utilities;
using Microsoft.Inventory.Journal;
using Microsoft.Service.Item;
using Microsoft.Sales.Customer;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Service.History;
using Microsoft.Service.Ledger;
using Microsoft.Service.Contract;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Inventory.Ledger;
using Microsoft.Projects.Resources.Ledger;
using Microsoft.Manufacturing.Document;
using Microsoft.Sales.Receivables;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Inventory.Item;
using Microsoft.Service.Pricing;
using Microsoft.Inventory.Location;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Service.Setup;
using Microsoft.CRM.Team;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Sales.Setup;

codeunit 136118 "Service Posting - Dimensions"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Dimension] [Service]
        IsInitialized := false;
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryResource: Codeunit "Library - Resource";
        LibraryService: Codeunit "Library - Service";
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        IsInitialized: Boolean;
        ServiceContractConfirmation: Label 'Do you want to create the contract using a contract template?';
        BlockDimension: Label 'Dimension %1 is blocked.';
        UnknownError: Label 'Unexpected Error.';
        BlockDimensionOnServiceHeader: Label 'The dimensions used in %1 %2 are invalid. Dimension %3 is blocked.';
        BlockDimensionOnItemLine: Label 'The dimensions used in %1 %2, line no. %3 are invalid. Dimension %4 is blocked.';
        LimitedDimensionCombination: Label 'The combination of dimensions used in %1 %2 is blocked. Dimension combinations %3 - %4 and %5 - %6 can''t be used concurrently.';
        LimitedDimensionItemLine: Label 'The combination of dimensions used in %1 %2, line no. %3 is blocked. Dimension combinations %4 - %5 and %6 - %7 can''t be used concurrently.';
        MandatoryDimensionOnHeader: Label 'The dimensions used in %1 %2 are invalid. Select a %3 for the %4 %5 for Customer %6.';
        MandatoryDimensionServiceLine: Label 'The dimensions used in %1 %2, line no. %3 are invalid. Select a %4 for the %5 %6 for %7 %8.';
        SameCodeOrNoCodeDimHeader: Label 'The dimensions used in %1 %2 are invalid. The %3 must be %4 for %5 %6 for %7 %8. Currently it''s %9.', Comment = '%3 = "Dimension value code" caption, %4 = expected "Dimension value code" value, %5 = "Dimension code" caption, %6 = "Dimension Code" value, %7 = Table caption (Vendor), %8 = Table value (XYZ), %9 = current "Dimension value code" value';
        SameCodeOrNoCodeDimLine: Label 'The dimensions used in %1 %2, line no. %3 are invalid. The %4 must be %5 for %6 %7 for %8 %9. Currently it''s %10.', Comment = '%4 = "Dimension value code" caption, %5 = expected "Dimension value code" value, %6 = "Dimension code" caption, %7 = "Dimension Code" value, %8 = Table caption (Vendor), %9 = Table value (XYZ), %10 = current "Dimension value code" value';
        BlankLbl: Label 'blank';
        DimensionSetIDErr: Label 'Dimension Set ID is incorrect on Posted Service Shipment Line';
        IncorrectShortcutDimensionValueErr: Label 'Incorrect Shortcut Dimension value for %1';
        DimensionValueCodeError: Label '%1 must be %2.';

    [Test]
    [HandlerFunctions('ConfirmMessageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure DimOnServiceHeader()
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        ResponsibilityCenter: Record "Responsibility Center";
        ServiceOrderType: Record "Service Order Type";
        DefaultDimension: Record "Default Dimension";
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        ContractNo: Code[20];
    begin
        // Test Dimensions on Service Header.

        // 1. Setup: Create Customer, Salesperson, Responsibility Center, Service Order Type, Service Contract, Create Default Dimensions
        // for all and Sign the Contract.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        LibraryService.CreateResponsibilityCenter(ResponsibilityCenter);
        LibraryService.CreateServiceOrderType(ServiceOrderType);

        CreateDimensionAndDimensionValue(Dimension, DimensionValue);

        LibraryDimension.CreateDefaultDimensionCustomer(
          DefaultDimension, Customer."No.", Dimension.Code, DimensionValue.Code);

        CreateDimensionAndDimensionValue(Dimension, DimensionValue);

        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, DATABASE::"Salesperson/Purchaser", SalespersonPurchaser.Code, Dimension.Code,
          DimensionValue.Code);

        CreateDimensionAndDimensionValue(Dimension, DimensionValue);

        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, DATABASE::"Responsibility Center", ResponsibilityCenter.Code, Dimension.Code,
          DimensionValue.Code);

        CreateDimensionAndDimensionValue(Dimension, DimensionValue);

        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, DATABASE::"Service Order Type", ServiceOrderType.Code, Dimension.Code, DimensionValue.Code);

        ContractNo := CreateAndSignServiceContract(Customer."No.");

        // 2. Exercise: Create Service Header, Update Salesperson, Responsibility Center, Contract No. and Service Order Type on Service
        // Header.
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");
        UpdateServiceHeader(ServiceHeader, SalespersonPurchaser.Code, ResponsibilityCenter.Code, ContractNo, ServiceOrderType.Code);

        // 3. Verify: Verify Dimensions on Service Header.
        VerifyDimForCustomer(ServiceHeader, Customer."No.");
        VerifyDimForResponsibility(ServiceHeader, ResponsibilityCenter.Code);
        VerifyDimForSalesperson(ServiceHeader, SalespersonPurchaser.Code);
        VerifyDimForOrderType(ServiceHeader, ServiceOrderType.Code);
        VerifyDimForContract(ServiceHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DimOnServiceItemLine()
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        Dimension: Record Dimension;
        DefaultDimension: Record "Default Dimension";
        ServiceItemNo: Code[20];
        ServiceItemGroupCode: Code[10];
    begin
        // Test Dimensions on Service Item Line.

        // 1. Setup: Create Customer, Service Item group, Service Item, Create Default Dimension for Service Item Group and Service Item.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        ServiceItemGroupCode := CreateServiceItemGroup();

        LibraryDimension.FindDimension(Dimension);
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, DATABASE::"Service Item Group", ServiceItemGroupCode, Dimension.Code, FindDimensionValue(Dimension.Code));

        ServiceItemNo := CreateServiceItem(Customer."No.", ServiceItemGroupCode);
        Dimension.Next();
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, DATABASE::"Service Item", ServiceItemNo, Dimension.Code, FindDimensionValue(Dimension.Code));

        // 2. Exercise: Create Service Header and Service Item Line.
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItemNo);

        // 3. Verify: Verify Dimensions on Service Item Line.
        VerifyDimForServiceItem(ServiceItemLine, ServiceItemNo);
        VerifyDimForServiceItemGrp(ServiceItemLine, ServiceItemGroupCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShortcutDimOnServiceItemLine()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceItemNo: Code[20];
        ShortcutDimCode: array[2] of Code[20];
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Service] [Dimensions]
        // [SCENARIO 118320] Shortcut Dimension is updated in Service Item Line when create new line with Service Item No.
        Initialize();

        // [GIVEN] Create Customer and Service Order with Global Dimensions
        CustomerNo := CreateCustomerWithDefGlobalDimensions(ShortcutDimCode);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, CustomerNo);
        // [GIVEN] Create Service Item
        ServiceItemNo := CreateServiceItem(CustomerNo, CreateServiceItemGroup());

        // [WHEN] Create Service Item Line
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItemNo);

        // [THEN] Shortcut Dimensions are updated in Service Item Line
        Assert.AreEqual(
          ShortcutDimCode[1], ServiceItemLine."Shortcut Dimension 1 Code",
          StrSubstNo(IncorrectShortcutDimensionValueErr, ServiceItemLine.FieldCaption("Shortcut Dimension 1 Code")));
        Assert.AreEqual(
          ShortcutDimCode[2], ServiceItemLine."Shortcut Dimension 2 Code",
          StrSubstNo(IncorrectShortcutDimensionValueErr, ServiceItemLine.FieldCaption("Shortcut Dimension 2 Code")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DimOnServiceLine()
    var
        ServiceLine: Record "Service Line";
        CustomerNo: Code[20];
        ItemNo: Code[20];
        ResourceNo: Code[20];
        GLAccountNo: Code[20];
    begin
        // Test Dimensions on Service Line for Type Item, Resource and G/L Account.

        // 1. Setup: Create Customer, Item, Resource, G/L Account and assign Default Dimension on all.
        CreateItemResourceGLDefaultDim(CustomerNo, ItemNo, ResourceNo, GLAccountNo);

        // 2. Exercise: Create Service Header, Service Line for Type Item, Resource and G/L Account.
        CreateServiceOrderWithLines(ServiceLine, CustomerNo, ItemNo, ResourceNo, GLAccountNo);

        // 3. Verify: Verify Dimensions on Service Line for Type Item, Resource and G/L Account.
        VerifyDimOnServiceLine(ServiceLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DimOnServiceLineCost()
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
        ServiceCost: Record "Service Cost";
        ServiceLine: Record "Service Line";
    begin
        // Test Dimensions on Service Line for Type Cost and Blank.

        // 1. Setup: Create Customer.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        CreateServiceCost(ServiceCost);

        // 2. Exercise: Create Service Header and Service Line for Type Cost and Blank.
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Cost, ServiceCost.Code);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::" ", '');

        // 3. Verify: Verify Dimensions on Service Line for Type Cost and Blank.
        VerifyDimOnServiceLineCost(ServiceLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DimPriorityOnServiceLine()
    var
        Dimension: Record Dimension;
        ServiceLine: Record "Service Line";
        DefaultDimension: Record "Default Dimension";
        CustomerNo: Code[20];
        ItemNo: Code[20];
        ResourceNo: Code[20];
        GLAccountNo: Code[20];
    begin
        // Test Dimensions on Service Line according to the Dimension Priority.

        // 1. Setup: Create Customer, Item, Resource, G/L Account and assign Default Dimension on all.
        CreateItemResourceGLDefaultDim(CustomerNo, ItemNo, ResourceNo, GLAccountNo);
        LibraryDimension.FindDimension(Dimension);
        LibraryDimension.CreateDefaultDimensionCustomer(DefaultDimension, CustomerNo, Dimension.Code, FindDimensionValue(Dimension.Code));
        UpdateDefaultDimForItem(ItemNo);
        UpdateDefaultDimForResource(ResourceNo);
        UpdateDefaultDimForGLAccount(GLAccountNo);

        // 2. Exercise: Create Service Header, Service Line for Type Item, Resource and G/L Account.
        CreateServiceOrderWithLines(ServiceLine, CustomerNo, ItemNo, ResourceNo, GLAccountNo);

        // 3. Verify: Verify Dimensions on Service Line.
        VerifyPriorityDimOnServiceLine(ServiceLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlockDimOnHeader()
    var
        Customer: Record Customer;
        Dimension: Record Dimension;
        ServiceHeader: Record "Service Header";
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        // Test error occurs on Selecting Block Dimension on Service Header.

        // 1. Setup: Create Customer, Select Dimension and Set Blocked to True.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        LibraryDimension.FindDimension(Dimension);
        ModifyDimension(Dimension, true);

        // 2. Exercise: Create Service Header.
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");

        // 3. Verify: Verify error occurs "Dimension Blocked" on Selecting Block Dimension on Service Header.
        DimensionSetEntry.Init();
        asserterror DimensionSetEntry.Validate("Dimension Code", Dimension.Code);
        Assert.AreEqual(StrSubstNo(BlockDimension, Dimension.Code), GetLastErrorText, UnknownError);

        // 4. Cleanup: Set Blocked False for Dimension.
        ModifyDimension(Dimension, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipBlockDimOnHeader()
    var
        Dimension: Record Dimension;
        ServiceHeader: Record "Service Header";
    begin
        // Test error occurs on Posting Service Order as Ship with Block Dimension on Service Header.

        // 1. Setup: Create Customer, Create Default Dimension for Customer, Block the assign dimension and Create Service Header and line.
        CreateServiceHeaderBlockDim(ServiceHeader, Dimension);
        ModifyDimension(Dimension, true);

        // 2. Exercise: Post Service Order as Ship.
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // 3. Verify: Verify error occurs "Dimension Blocked" on Posting Service Order as Ship with Block Dimension on Service Header.
        VerifyBlockDimOnServiceHeader(ServiceHeader, Dimension.Code);

        // 4. Cleanup: Set Blocked False for Dimension.
        ModifyDimension(Dimension, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvBlockDimOnHeader()
    var
        Dimension: Record Dimension;
        ServiceHeader: Record "Service Header";
    begin
        // Test error occurs on Posting Service Order as Invoice with Block Dimension on Service Header.

        // 1. Setup: Create Customer, Create Default Dimension for Customer, Block the assign dimension and Create Service Header.
        CreateServiceHeaderBlockDim(ServiceHeader, Dimension);

        // 2. Exercise: Post Service Order as Invoice.
        ModifyDimension(Dimension, true);
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        asserterror LibraryService.PostServiceOrder(ServiceHeader, false, false, true);

        // 3. Verify: Verify error occurs "Dimension Blocked" on Posting Service Order as Invoice with Block Dimension on Service Header.
        VerifyBlockDimOnServiceHeader(ServiceHeader, Dimension.Code);

        // 4. Cleanup: Set Blocked False for Dimension.
        ModifyDimension(Dimension, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipInvBlockDimOnHeader()
    var
        Dimension: Record Dimension;
        ServiceHeader: Record "Service Header";
    begin
        // Test error occurs on Posting Service Order as Ship and Invoice with Block Dimension on Service Header.

        // 1. Setup: Create Customer, Create Default Dimension for Customer, Block the assign dimension and Create Service Header.
        CreateServiceHeaderBlockDim(ServiceHeader, Dimension);

        // 2. Exercise: Post Service Order as Ship and Invoice.
        ModifyDimension(Dimension, true);
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // 3. Verify: Verify error occurs "Dimension Blocked" on Posting Service Order as Ship and Invoice with Block Dimension on
        // Service Header.
        VerifyBlockDimOnServiceHeader(ServiceHeader, Dimension.Code);

        // 4. Cleanup: Set Blocked False for Dimension.
        ModifyDimension(Dimension, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipConsumeBlockDimOnHeader()
    var
        Dimension: Record Dimension;
        ServiceHeader: Record "Service Header";
    begin
        // Test error occurs on Posting Service Order as Ship and Consume with Block Dimension on Service Header.

        // 1. Setup: Create Customer, Create Default Dimension for Customer, Block the assign dimension and Create Service Header.
        CreateServiceHeaderBlockDim(ServiceHeader, Dimension);

        // 2. Exercise: Post Service Order as Ship and Consume.
        ModifyDimension(Dimension, true);
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, true, false);

        // 3. Verify: Verify error occurs "Dimension Blocked" on Posting Service Order as Ship and Consume with Block Dimension on
        // Service Header.
        VerifyBlockDimOnServiceHeader(ServiceHeader, Dimension.Code);

        // 4. Cleanup: Set Blocked False for Dimension.
        ModifyDimension(Dimension, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler')]
    [Scope('OnPrem')]
    procedure ShipBlockDimOnItemLine()
    var
        Dimension: Record Dimension;
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
    begin
        // Test error occurs on Posting Service Order as Ship with Block Dimension on Service Item Line.

        // 1. Create Customer, Create Service Item, Create Default Dimension for Service Item, Create Service Header, Service Item Line,
        // Service Line for Type Item, update Quantity on Line and Block the assigned Dimension.
        CreateItemLineBlockDim(ServiceItemLine, Dimension, false);
        ModifyDimension(Dimension, true);
        ServiceHeader.Get(ServiceItemLine."Document Type", ServiceItemLine."Document No.");

        // 2. Exercise: Post Service Order as Ship.
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // 3. Verify: Verify error occurs "Dimension Blocked" on Posting Service Order as Ship with Block Dimension on Service Item Line.
        VerifyBlockDimOnItemLine(ServiceItemLine, Dimension.Code);

        // 4. Cleanup: Set Blocked False for Dimension.
        ModifyDimension(Dimension, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler')]
    [Scope('OnPrem')]
    procedure InvBlockDimOnItemLine()
    var
        Dimension: Record Dimension;
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
    begin
        // Test error occurs on Posting Service Order as Invoice with Block Dimension on Service Item Line.

        // 1. Setup: Create Customer, Service Item, Create Default Dimension for Service Item, Create Service Header, Service Item Line,
        // Service Line for Type Item, update Quantity on Line, Post Service Order as Ship and Block the assigned Dimension.
        CreateItemLineBlockDim(ServiceItemLine, Dimension, false);
        ServiceHeader.Get(ServiceItemLine."Document Type", ServiceItemLine."Document No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        ModifyDimension(Dimension, true);

        // 2. Exercise: Post Service Order as Invoice.
        ServiceHeader.Get(ServiceItemLine."Document Type", ServiceItemLine."Document No.");
        asserterror LibraryService.PostServiceOrder(ServiceHeader, false, false, true);

        // 3. Verify: Verify error occurs "Dimension Blocked" on Posting Service Order as Invoice with Block Dimension on Service Item Line.
        VerifyBlockDimOnItemLine(ServiceItemLine, Dimension.Code);

        // 4. Cleanup: Set Blocked False for Dimension.
        ModifyDimension(Dimension, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler')]
    [Scope('OnPrem')]
    procedure ShipInvBlockDimOnItemLine()
    var
        Dimension: Record Dimension;
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
    begin
        // Test error occurs on Posting Service Order as Ship and Invoice with Block Dimension on Service Item Line.

        // 1. Setup: Create Customer, Service Item, Create Default Dimension for Service Item, Create Service Header, Service Item Line,
        // Service Line for Type Item, update Quantity on Line and Block the assigned Dimension.
        CreateItemLineBlockDim(ServiceItemLine, Dimension, false);
        ModifyDimension(Dimension, true);
        ServiceHeader.Get(ServiceItemLine."Document Type", ServiceItemLine."Document No.");

        // 2. Exercise: Post Service Order as Ship and Invoice.
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // 3. Verify: Verify error occurs "Dimension Blocked" on Posting Service Order as Ship and Invoice with Block Dimension on
        // Service Item Line.
        VerifyBlockDimOnItemLine(ServiceItemLine, Dimension.Code);

        // 4. Cleanup: Set Blocked False for Dimension.
        ModifyDimension(Dimension, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler')]
    [Scope('OnPrem')]
    procedure ShipConsumeBlockDimOnItemLine()
    var
        Dimension: Record Dimension;
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
    begin
        // Test error occurs on Posting Service Order as Ship and Consume with Block Dimension on Service Item Line.

        // 1. Setup: Create Customer, Service Item, Create Default Dimension for Service Item, Create Service Header, Service Item Line,
        // Service Line for Type Item, update Qty. to consume on Line and Block the assigned Dimension.
        CreateItemLineBlockDim(ServiceItemLine, Dimension, true);
        ServiceHeader.Get(ServiceItemLine."Document Type", ServiceItemLine."Document No.");
        ModifyDimension(Dimension, true);

        // 2. Exercise: Post Service Order as Ship and Consume.
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, true, false);

        // 3. Verify: Verify error occurs "Dimension Blocked" on Posting Service Order as Ship and Consume with Block Dimension on
        // Service Item Line.
        VerifyBlockDimOnItemLine(ServiceItemLine, Dimension.Code);

        // 4. Cleanup: Set Blocked False for Dimension.
        ModifyDimension(Dimension, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipDimBlockItem()
    var
        Dimension: Record Dimension;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // Test error occurs on Posting Service Order as Ship with Blocked Dimension on Service Line of Type Item.

        // 1. Setup: Create Customer, Item, Create Default Dimension for Item, Create Service Header, Service Item Line, Service Line of
        // Type Item and Block assigned Dimension.
        CreateLineBlockDimItem(ServiceLine, Dimension, false);
        ModifyDimension(Dimension, true);
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");

        // 2. Exercise: Post Service Order as Ship.
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // 3. Verify: Verify error occurs "Dimension Blocked" on Posting Service Order as Ship with Blocked Dimension on Service Line
        // of Type Item.
        VerifyBlockDimOnLine(ServiceLine, Dimension.Code);

        // 4. Cleanup: Set Blocked False for Dimension.
        ModifyDimension(Dimension, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvDimBlockItem()
    var
        Dimension: Record Dimension;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // Test error occurs on Posting Service Order as Invoice with Blocked Dimension on Service Line of Type Item.

        // 1. Setup: Create Customer, Item, Create Default Dimension for Item, Create Service Header, Service Item Line, Service Line of
        // Type Item, Post Service Order as Ship and Block assigned Dimension.
        CreateLineBlockDimItem(ServiceLine, Dimension, false);
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
        ModifyDimension(Dimension, true);

        // 2. Exercise: Post Service Order as Invoice.
        asserterror LibraryService.PostServiceOrder(ServiceHeader, false, false, true);

        // 3. Verify: Verify error occurs "Dimension Blocked" on Posting Service Order as Invoice with Blocked Dimension on Service Line
        // of Type Item.
        VerifyBlockDimOnLine(ServiceLine, Dimension.Code);

        // 4. Cleanup: Set Blocked False for Dimension.
        ModifyDimension(Dimension, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipInvDimBlockItem()
    var
        Dimension: Record Dimension;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // Test error occurs on Posting Service Order as Ship and Invoice with Blocked Dimension on Service Line of Type Item.

        // 1. Setup: Create Customer, Item, Create Default Dimension for Item, Create Service Header, Service Item Line, Service Line of
        // Type Item and Block assigned Dimension.
        CreateLineBlockDimItem(ServiceLine, Dimension, false);
        ModifyDimension(Dimension, true);
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");

        // 2. Exercise: Post Service Order as Ship and Invoice.
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // 3. Verify: Verify error occurs "Dimension Blocked" on Posting Service Order as Ship and Invoice with Blocked Dimension on Service
        // Line of Type Item.
        VerifyBlockDimOnLine(ServiceLine, Dimension.Code);

        // 4. Cleanup: Set Blocked False for Dimension.
        ModifyDimension(Dimension, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ConsumeDimBlockItem()
    var
        Dimension: Record Dimension;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // Test error occurs on Posting Service Order as Ship and Consume with Blocked Dimension on Service Line of Type Item.

        // 1. Setup: Create Customer, Item, Create Default Dimension for Item, Create Service Header, Service Item Line, Service Line of
        // Type Item and Block assigned Dimension.
        CreateLineBlockDimItem(ServiceLine, Dimension, true);
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        ModifyDimension(Dimension, true);

        // 2. Exercise: Post Service Order as Ship and Consume.
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, true, false);

        // 3. Verify: Verify error occurs "Dimension Blocked" on Posting Service Order as Ship and Consume with Blocked Dimension on Service
        // Line of Type Item.
        VerifyBlockDimOnLine(ServiceLine, Dimension.Code);

        // 4. Cleanup: Set Blocked False for Dimension.
        ModifyDimension(Dimension, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipDimBlockResource()
    var
        Dimension: Record Dimension;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // Test error occurs on Posting Service Order as Ship with Blocked Dimension on Service Line of Type Resource.

        // 1. Setup: Create Customer, Service Resource, Create Default Dimension for Resource, Create Service Header, Service Item Line
        // Service Line of Type Resource and Block assigned Dimension.
        CreateLineBlockDimResource(ServiceLine, Dimension, false);
        ModifyDimension(Dimension, true);
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");

        // 2. Exercise: Post Service Order as Ship.
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // 3. Verify: Verify error occurs "Dimension Blocked" on Posting Service Order as Ship with Blocked Dimension on Service Line of
        // Type Resource.
        VerifyBlockDimOnLine(ServiceLine, Dimension.Code);

        // 4. Cleanup: Set Blocked False for Dimension.
        ModifyDimension(Dimension, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvDimBlockResource()
    var
        Dimension: Record Dimension;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // Test error occurs on Posting Service Order as Invoice with Blocked Dimension on Service Line of Type Resource.

        // 1. Setup: Create Customer, Service Resource, Create Default Dimension for Resource, Create Service Header, Service Item Line
        // Service Line of Type Resource, Post Service Order as Ship and Block assigned Dimension.
        CreateLineBlockDimResource(ServiceLine, Dimension, false);
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
        ModifyDimension(Dimension, true);

        // 2. Exercise: Post Service Order as Invoice.
        asserterror LibraryService.PostServiceOrder(ServiceHeader, false, false, true);

        // 3. Verify: Verify error occurs "Dimension Blocked" on Posting Service Order as Invoice with Blocked Dimension on Service Line of
        // Type Resource.
        VerifyBlockDimOnLine(ServiceLine, Dimension.Code);

        // 4. Cleanup: Set Blocked False for Dimension.
        ModifyDimension(Dimension, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipInvDimBlockResource()
    var
        Dimension: Record Dimension;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // Test error occurs on Posting Service Order as Ship and Invoice with Blocked Dimension on Service Line of Type Resource.

        // 1. Setup: Create Customer, Service Resource, Create Default Dimension for Resource, Create Service Header, Service Item Line
        // Service Line of Type Resource and Block assigned Dimension.
        CreateLineBlockDimResource(ServiceLine, Dimension, false);
        ModifyDimension(Dimension, true);
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");

        // 2. Exercise: Post Service Order as Ship and Invoice.
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // 3. Verify: Verify error occurs "Dimension Blocked" on Posting Service Order as Ship and Invoice with Blocked Dimension on Service
        // Line of Type Resource.
        VerifyBlockDimOnLine(ServiceLine, Dimension.Code);

        // 4. Cleanup: Set Blocked False for Dimension.
        ModifyDimension(Dimension, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ConsumeDimBlockResource()
    var
        Dimension: Record Dimension;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // Test error occurs on Posting Service Order as Ship and Consume with Blocked Dimension on Service Line of Type Resource.

        // 1. Setup: Create Customer, Service Resource, Create Default Dimension for Resource, Create Service Header, Service Item Line
        // Service Line of Type Resource and Block assigned Dimension.
        CreateLineBlockDimResource(ServiceLine, Dimension, true);
        ModifyDimension(Dimension, true);
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");

        // 2. Exercise: Post Service Order as Ship and Consume.
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, true, false);

        // 3. Verify: Verify error occurs "Dimension Blocked" on Posting Service Order as Ship and Consume with Blocked Dimension on Service
        // Line of Type Resource.
        VerifyBlockDimOnLine(ServiceLine, Dimension.Code);

        // 4. Cleanup: Set Blocked False for Dimension.
        ModifyDimension(Dimension, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipDimBlockCost()
    var
        Dimension: Record Dimension;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // Test error occurs on Posting Service Order as Ship with Blocked Dimension on Service Line of Type Cost.

        // 1. Setup: Create Customer, Service Header, Service Item Line, Service Line of Type Cost, Create Document Dimension for Type
        // Cost and Block assigned Dimension.
        CreateLineBlockDimCost(ServiceLine, Dimension);
        ModifyDimension(Dimension, true);
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");

        // 2. Exercise: Post Service Order as Ship.
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // 3. Verify: Verify error occurs "Dimension Blocked" on Posting Service Order as Ship with Blocked Dimension on Service Line of
        // Type Cost.
        VerifyBlockDimOnLine(ServiceLine, Dimension.Code);

        // 4. Cleanup: Set Blocked False for Dimension.
        ModifyDimension(Dimension, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvDimBlockCost()
    var
        Dimension: Record Dimension;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // Test error occurs on Posting Service Order as Invoice with Blocked Dimension on Service Line of Type Cost.

        // 1. Setup: Create Customer, Service Header, Service Item Line, Service Line of Type Cost, Create Document Dimension for Type
        // Cost, Post Service Order as Ship and Block assigned Dimension.
        CreateLineBlockDimCost(ServiceLine, Dimension);
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
        ModifyDimension(Dimension, true);

        // 2. Exercise: Post Service Order as Invoice.
        asserterror LibraryService.PostServiceOrder(ServiceHeader, false, false, true);

        // 3. Verify: Verify error occurs "Dimension Blocked" on Posting Service Order as Invoice with Blocked Dimension on Service Line of
        // Type Cost.
        VerifyBlockDimOnLine(ServiceLine, Dimension.Code);

        // 4. Cleanup: Set Blocked False for Dimension.
        ModifyDimension(Dimension, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipInvDimBlockCost()
    var
        Dimension: Record Dimension;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // Test error occurs on Posting Service Order as Ship and Invoice with Blocked Dimension on Service Line of Type Cost.

        // 1. Setup: Create Customer, Service Header, Service Item Line, Service Line of Type Cost, Create Document Dimension for Type
        // Cost and Block assigned Dimension.
        CreateLineBlockDimCost(ServiceLine, Dimension);
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        ModifyDimension(Dimension, true);

        // 2. Exercise: Post Service Order as Ship and Invoice.
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // 3. Verify: Verify error occurs "Dimension Blocked" on Posting Service Order as Ship and Invoice with Blocked Dimension on Service
        // Line of Type Cost.
        VerifyBlockDimOnLine(ServiceLine, Dimension.Code);

        // 4. Cleanup: Set Blocked False for Dimension.
        ModifyDimension(Dimension, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipDimBlockGLAccount()
    var
        Dimension: Record Dimension;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // Test error occurs on Posting Service Order as Ship with Blocked Dimension on Service Line of Type G/L Account.

        // 1. Setup: Create Customer, Create G/L Account, Default Dimension for G/L Account, Create Service Header, Service Item Line,
        // Service Line of Type G/L Account and Block assigned Dimension.
        CreateLineBlockDimGLAccount(ServiceLine, Dimension);
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        ModifyDimension(Dimension, true);

        // 2. Exercise: Post Service Order as Ship.
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // 3. Verify: Verify error occurs "Dimension Blocked" on Posting Service Order as Ship with Blocked Dimension on Service Line of
        // Type G/L Account.
        VerifyBlockDimOnLine(ServiceLine, Dimension.Code);

        // 4. Cleanup: Set Blocked False for Dimension.
        ModifyDimension(Dimension, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvDimBlockGLAccount()
    var
        Dimension: Record Dimension;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // Test error occurs on Posting Service Order as Invoice with Blocked Dimension on Service Line of Type G/L Account.

        // 1. Setup: Create Customer, Create G/L Account, Create Default Dimension for G/L Account, Create Service Header, Service
        // Item Line, Service Line of Type G/L Account, Post Service Order as Ship and Block assigned Dimension.
        CreateLineBlockDimGLAccount(ServiceLine, Dimension);
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
        ModifyDimension(Dimension, true);

        // 2. Exercise: Post Service Order as Invoice.
        asserterror LibraryService.PostServiceOrder(ServiceHeader, false, false, true);

        // 3. Verify: Verify error occurs "Dimension Blocked" on Posting Service Order as Invoice with Blocked Dimension on Service
        // Line of Type G/L Account.
        VerifyBlockDimOnLine(ServiceLine, Dimension.Code);

        // 4. Cleanup: Set Blocked False for Dimension.
        ModifyDimension(Dimension, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipInvDimBlockGLAccount()
    var
        Dimension: Record Dimension;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // Test error occurs on Posting Service Order as Ship and Invoice with Blocked Dimension on Service Line of Type G/L Account.

        // 1. Create Customer, Create G/L Account, Create Default Dimension for G/L Account, Create Service Header, Service Item Line,
        // Service Line of Type G/L Account and Block assigned Dimension.
        CreateLineBlockDimGLAccount(ServiceLine, Dimension);
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        ModifyDimension(Dimension, true);

        // 2. Exercise: Post Service Order as Ship and Invoice.
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // 3. Verify: Verify error occurs "Dimension Blocked" on Posting Service Order as Ship and Invoice with Blocked Dimension on Service
        // Line of Type G/L Account.
        VerifyBlockDimOnLine(ServiceLine, Dimension.Code);

        // 4. Cleanup: Set Blocked False for Dimension.
        ModifyDimension(Dimension, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipLimitedDimHeader()
    var
        ServiceHeader: Record "Service Header";
        DimensionValueCombination: Record "Dimension Value Combination";
    begin
        // Test error occurs on Posting as Ship Service Order with Dimension set Limited Dimension Combination on Service Header.

        // 1. Setup: Create Customer, Create Service Header and Create Document Dimension on Service Header.
        CreateLimitedDimHeader(ServiceHeader, DimensionValueCombination);

        // 2. Exercise: Post Service Order as Ship
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // 3. Verify: Verify error occurs on Posting Service Order as Ship with Limited Dimension Combination on Service
        // Header.
        VerifyLimitedDimCombination(ServiceHeader, DimensionValueCombination);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvLimitedDimHeader()
    var
        ServiceHeader: Record "Service Header";
        DimensionValueCombination: Record "Dimension Value Combination";
    begin
        // Test error occurs on Posting as Invoice Service Order with Dimension set Limited Dimension Combination on Service Header.

        // 1. Setup: Create Customer, Create Service Header and Create Document Dimension on Service Header.
        CreateLimitedDimHeader(ServiceHeader, DimensionValueCombination);

        // 2. Exercise: Post Service Order as Invoice.
        asserterror LibraryService.PostServiceOrder(ServiceHeader, false, false, true);

        // 3. Verify: Verify error occurs on Posting Service Order as Invoice with Limited Dimension Combination on Service Header.
        VerifyLimitedDimCombination(ServiceHeader, DimensionValueCombination);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipInvLimitedDimHeader()
    var
        ServiceHeader: Record "Service Header";
        DimensionValueCombination: Record "Dimension Value Combination";
    begin
        // Test error occurs on Posting as Ship and Invoice Service Order with Dimension set Limited Dimension Combination on Service
        // Header.

        // 1. Setup: Create Customer, Create Service Header and Create Document Dimension on Service Header.
        CreateLimitedDimHeader(ServiceHeader, DimensionValueCombination);

        // 2. Exercise: Post Service Order as Ship and Invoice.
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // 3. Verify: Verify error occurs on Posting Service Order as Ship and Invoice with Limited Dimension Combination on Service
        // Header.
        VerifyLimitedDimCombination(ServiceHeader, DimensionValueCombination);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipConsumeLimitedDimHeader()
    var
        ServiceHeader: Record "Service Header";
        DimensionValueCombination: Record "Dimension Value Combination";
    begin
        // Test error occurs on Posting as Ship and Consume Service Order with Dimension set Limited Dimension Combination on Service
        // Header.

        // 1. Setup: Create Customer, Create Service Header and Create Document Dimension on Service Header.
        CreateLimitedDimHeader(ServiceHeader, DimensionValueCombination);

        // 2. Exercise: Post Service Order as Ship and Consume.
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, true, false);

        // 3. Verify: Verify error occurs on Posting Service Order as Ship and Consume with Limited Dimension Combination on Service
        // Header.
        VerifyLimitedDimCombination(ServiceHeader, DimensionValueCombination);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler')]
    [Scope('OnPrem')]
    procedure ShipLimitedDimItemLine()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        DimensionValueCombination: Record "Dimension Value Combination";
    begin
        // Test error occurs on Posting as Ship Service Order with Dimension set Limited Dimension Combination on Service Item Line.

        // 1. Setup: Create Customer, Service Item, Service Header, Service Item Line, Service Line.
        CreateServiceOrderWithItem(ServiceItemLine, false);

        // 2. Exercise: Create Document Dimension on Service Item Line.
        ServiceHeader.Get(ServiceItemLine."Document Type", ServiceItemLine."Document No.");
        CreateLimitedDimItemLine(DimensionValueCombination, ServiceItemLine);

        // 3. Verify: Verify error occurs on Posting Service Order as Ship with Limited Dimension Combination on Service Item Line.
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
        VerifyLimitedDimItemLine(ServiceItemLine, DimensionValueCombination);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler')]
    [Scope('OnPrem')]
    procedure InvLimitedDimItemLine()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        DimensionValueCombination: Record "Dimension Value Combination";
    begin
        // Test error occurs on Posting as Invoice Service Order with Dimension set Limited Dimension Combination on Service Item Line.

        // 1. Setup: Create Customer, Service Item, Service Header, Service Item Line and Service Line.
        CreateServiceOrderWithItem(ServiceItemLine, false);

        // 2. Exercise: Post Service Order as Ship and Create Document Dimension on Service Item Line.
        ServiceHeader.Get(ServiceItemLine."Document Type", ServiceItemLine."Document No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
        ServiceItemLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceItemLine.FindFirst();
        CreateLimitedDimItemLine(DimensionValueCombination, ServiceItemLine);

        // 2. Verify: Verify error occurs on Posting Service Order as Invoice with Limited Dimension Combination on Service Item Line.
        ServiceHeader.Get(ServiceItemLine."Document Type", ServiceItemLine."Document No.");
        asserterror LibraryService.PostServiceOrder(ServiceHeader, false, false, true);
        VerifyLimitedDimItemLine(ServiceItemLine, DimensionValueCombination);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler')]
    [Scope('OnPrem')]
    procedure ShipInvLimitedDimItemLine()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        DimensionValueCombination: Record "Dimension Value Combination";
    begin
        // Test error occurs on Posting as Ship and Invoice Service Order with Dimension set Limited Dimension Combination on Service Item
        // Line.

        // 1. Setup: Create Customer, Service Item, Service Header, Service Item Line and Service Line.
        CreateServiceOrderWithItem(ServiceItemLine, false);

        // 2. Exercise: Create Document Dimension on Service Item Line.
        ServiceHeader.Get(ServiceItemLine."Document Type", ServiceItemLine."Document No.");
        CreateLimitedDimItemLine(DimensionValueCombination, ServiceItemLine);

        // 3. Verify: Verify error occurs on Posting Service Order as Ship and Invoice with Limited Dimension Combination on Service Item
        // Line.
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        VerifyLimitedDimItemLine(ServiceItemLine, DimensionValueCombination);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler')]
    [Scope('OnPrem')]
    procedure ConsumeLimitedDimItemLine()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        DimensionValueCombination: Record "Dimension Value Combination";
    begin
        // Test error occurs on Posting as Ship and Consume Service Order with Dimension set Limited Dimension Combination on Service Item
        // Line.

        // 1. Setup: Create Customer, Service Item, Service Header, Service Item Line and Service Line.
        CreateServiceOrderWithItem(ServiceItemLine, true);

        // 2. Exercise: Create Document Dimension on Service Item Line and update Qty. to consume on Service Line.
        ServiceHeader.Get(ServiceItemLine."Document Type", ServiceItemLine."Document No.");
        CreateLimitedDimItemLine(DimensionValueCombination, ServiceItemLine);

        // 3. Verify: Verify error occurs on Posting Service Order as Ship and Consume with Limited Dimension Combination on Service Item
        // Line.
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, true, false);
        VerifyLimitedDimItemLine(ServiceItemLine, DimensionValueCombination);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipDimLimitedItem()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        DimensionValueCombination: Record "Dimension Value Combination";
    begin
        // Test error occurs on Posting as Ship Service Order with Dimension set Limited Dimension Combination on Service Line of Type Item.

        // 1. Setup: Create Customer, Item, Service Header, Service Item Line, Service Line of Type Item and Create Document Dimension on
        // Service Line.
        CreateServiceOrderItem(ServiceLine, false);
        CreateLimitedDimServiceLine(DimensionValueCombination, ServiceLine);
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");

        // 2. Exercise: Post Service Order as Ship.
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // 3. Verify: Verify error occurs on Posting Service Order as Ship with Limited Dimension Combination on Service Line of Type Item.
        VerifyLimitedDimLine(ServiceLine, DimensionValueCombination);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvDimLimitedItem()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        DimensionValueCombination: Record "Dimension Value Combination";
    begin
        // Test error occurs on Posting as Invoice Service Order with Dimension set Limited Dimension Combination on Service Line of Type
        // Item.

        // 1. Setup: Create Customer, Item, Service Header, Service Item Line, Service Line of Type Item, Post Service Order as Ship and
        // Create Document Dimension on Service Line.
        CreateServiceOrderItem(ServiceLine, false);
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.FindFirst();
        CreateLimitedDimServiceLine(DimensionValueCombination, ServiceLine);

        // 2. Exercise: Post Service Order as Invoice.
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        asserterror LibraryService.PostServiceOrder(ServiceHeader, false, false, true);

        // 3. Verify: Verify error occurs on Posting Service Order as Invoice with Limited Dimension Combination on Service Line of Type
        // Item.
        VerifyLimitedDimLine(ServiceLine, DimensionValueCombination);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipInvDimLimitedItem()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        DimensionValueCombination: Record "Dimension Value Combination";
    begin
        // Test error occurs on Posting as Ship and Invoice Service Order with Dimension set Limited Dimension Combination on Service Line
        // of Type Item.

        // 1. Setup: Create Customer, Item, Service Header, Service Item Line, Service Line of Type Item and Create Document Dimension on
        // Service Line.
        CreateServiceOrderItem(ServiceLine, false);
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        CreateLimitedDimServiceLine(DimensionValueCombination, ServiceLine);

        // 2. Exercise: Post Service Order as Ship and Invoice.
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // 3. Verify: Verify error occurs on Posting Service Order as Ship and Invoice with Limited Dimension Combination on Service Line of
        // Type Item.
        VerifyLimitedDimLine(ServiceLine, DimensionValueCombination);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ConsumeDimLimitedItem()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        DimensionValueCombination: Record "Dimension Value Combination";
    begin
        // Test error occurs on Posting as Ship and Consume Service Order with Dimension set Limited Dimension Combination on Service Line
        // of Type Item.

        // 1. Setup: Create Customer, Item, Service Header, Service Item Line, Service Line of Type Item, Update Qty to consume on Service
        // Line and Create Document Dimension on Service Line.
        CreateServiceOrderItem(ServiceLine, true);
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        CreateLimitedDimServiceLine(DimensionValueCombination, ServiceLine);

        // 2. Exercise: Post Service Order as Ship and Consume.
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, true, false);

        // 3. Verify: Verify error occurs on Posting Service Order as Ship and Consume with Limited Dimension Combination on Service Line of
        // Type Item.
        VerifyLimitedDimLine(ServiceLine, DimensionValueCombination);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipDimLimitedResource()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        DimensionValueCombination: Record "Dimension Value Combination";
    begin
        // Test error occurs on Posting as Ship Service Order with Dimension set Limited Dimension Combination on Service Line of Type
        // Resource.

        // 1. Setup: Create Customer, Resource, Service Header, Service Item Line, Service Line of Type Resource and Create Document
        // Dimension on Service Line.
        CreateServiceOrderResource(ServiceLine, false);
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        CreateLimitedDimServiceLine(DimensionValueCombination, ServiceLine);

        // 2. Exercise: Post Service Order as Ship.
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // 3. Verify: Verify error occurs on Posting Service Order as Ship with Limited Dimension Combination on Service Line of Type
        // Resource.
        VerifyLimitedDimLine(ServiceLine, DimensionValueCombination);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvDimLimitedResource()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        DimensionValueCombination: Record "Dimension Value Combination";
    begin
        // Test error occurs on Posting as Invoice Service Order with Dimension set Limited Dimension Combination on Service Line of Type
        // Resource.

        // 1. Setup: Create Customer, Resource, Service Header, Service Item Line, Service Line of Type Resource, Post Service Order as Ship
        // and Create Document Dimension on Service Line.
        CreateServiceOrderResource(ServiceLine, false);
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.FindFirst();
        CreateLimitedDimServiceLine(DimensionValueCombination, ServiceLine);

        // 2. Exercise: Post Service Order as Invoice.
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        asserterror LibraryService.PostServiceOrder(ServiceHeader, false, false, true);

        // 3. Verify: Verify error occurs on Posting Service Order as Invoice with Limited Dimension Combination on Service Line of Type
        // Resource.
        VerifyLimitedDimLine(ServiceLine, DimensionValueCombination);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipInvDimLimitedResource()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        DimensionValueCombination: Record "Dimension Value Combination";
    begin
        // Test error occurs on Posting as Ship and Invoice Service Order with Dimension set Limited Dimension Combination on Service
        // Line of Type Resource.

        // 1. Setup: Create Customer, Resource, Service Header, Service Item Line, Service Line of Type Resource and Create Document
        // Dimension on Service Line.
        CreateServiceOrderResource(ServiceLine, false);
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        CreateLimitedDimServiceLine(DimensionValueCombination, ServiceLine);

        // 2. Exercise: Post Service Order as Ship and Invoice.
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // 3. Verify: Verify error occurs on Posting Service Order as Ship and Invoice with Limited Dimension Combination on Service Line of
        // Type Resource.
        VerifyLimitedDimLine(ServiceLine, DimensionValueCombination);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ConsumeDimLimitedResource()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        DimensionValueCombination: Record "Dimension Value Combination";
    begin
        // Test error occurs on Posting as Ship and Consume Service Order with Dimension set Limited Dimension Combination on Service
        // Line of Type Resource.

        // 1. Setup: Create Customer, Resource, Service Header, Service Item Line, Service Line of Type Resource, Update Qty to consume on
        // Service Line and Create Document Dimension on Service Line.
        CreateServiceOrderResource(ServiceLine, true);
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        CreateLimitedDimServiceLine(DimensionValueCombination, ServiceLine);

        // 2. Exercise: Post Service Order as Ship and Consume.
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, true, false);

        // 3. Verify: Verify error occurs on Posting Service Order as Ship and Consume with Limited Dimension Combination on Service Line of
        // Type Resource.
        VerifyLimitedDimLine(ServiceLine, DimensionValueCombination);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipDimLimitedCost()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        DimensionValueCombination: Record "Dimension Value Combination";
    begin
        // Test error occurs on Posting as Ship Service Order with Dimension set Limited Dimension Combination on Service Line of Type Cost.

        // 1. Setup: Create Customer, Service Header, Service Item Line, Service Line of Type Cost and Create Document Dimension on
        // Service Line.
        CreateServiceOrderCost(ServiceLine);
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        CreateLimitedDimServiceLine(DimensionValueCombination, ServiceLine);

        // 2. Exercise: Post Service Order as Ship.
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // 3. Verify: Verify error occurs on Posting Service Order as Ship with Limited Dimension Combination on Service Line of
        // Type Cost.
        VerifyLimitedDimLine(ServiceLine, DimensionValueCombination);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvDimLimitedCost()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        DimensionValueCombination: Record "Dimension Value Combination";
    begin
        // Test error occurs on Posting as Invoice Service Order with Dimension set Limited Dimension Combination on Service Line of Type
        // Cost.

        // 1. Setup: Create Customer, Service Header, Service Item Line, Service Line of Type Cost, Post Service Order as Ship and Create
        // Document Dimension on Service Line.
        CreateServiceOrderCost(ServiceLine);
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.FindFirst();
        CreateLimitedDimServiceLine(DimensionValueCombination, ServiceLine);

        // 2. Exercise: Post Service Order as Invoice.
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        asserterror LibraryService.PostServiceOrder(ServiceHeader, false, false, true);

        // 3. Verify: Verify error occurs on Posting Service Order as Invoice with Limited Dimension Combination on Service Line of Type
        // Cost.
        VerifyLimitedDimLine(ServiceLine, DimensionValueCombination);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipInvDimLimitedCost()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        DimensionValueCombination: Record "Dimension Value Combination";
    begin
        // Test error occurs on Posting as Ship and Invoice Service Order with Dimension set Limited Dimension Combination on Service Line
        // of Type Cost.

        // 1. Setup: Create Customer, Service Header, Service Item Line, Service Line of Type Cost and Create Document Dimension on
        // Service Line.
        CreateServiceOrderCost(ServiceLine);
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        CreateLimitedDimServiceLine(DimensionValueCombination, ServiceLine);

        // 2. Exercise: Post Service Order as Ship and Invoice.
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // 3. Verify: Verify error occurs on Posting Service Order as Ship and Invoice with Limited Dimension Combination on Service Line of
        // Type Cost.
        VerifyLimitedDimLine(ServiceLine, DimensionValueCombination);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipDimLimitedGLAccount()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        DimensionValueCombination: Record "Dimension Value Combination";
    begin
        // Test error occurs on Posting as Ship Service Order with Dimension set Limited Dimension Combination on Service Line of Type
        // of Type G/L Account.

        // 1. Setup: Create Customer, G/L Account, Service Header, Service Item Line, Service Line of Type G/L Account and Create Document
        // Dimension on Service Line.
        CreateServiceOrderGLAccount(ServiceLine);
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        CreateLimitedDimServiceLine(DimensionValueCombination, ServiceLine);

        // 2. Exercise: Post Service Order as Ship.
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // 3. Verify: Verify error occurs on Posting Service Order as Ship with Limited Dimension Combination on Service Line of
        // Type G/L Account.
        VerifyLimitedDimLine(ServiceLine, DimensionValueCombination);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvDimLimitedGLAccount()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        DimensionValueCombination: Record "Dimension Value Combination";
    begin
        // Test error occurs on Posting as Invoice Service Order with Dimension set Limited Dimension Combination on Service Line of Type
        // of Type G/L Account.

        // 1. Setup: Create Customer, G/L Account, Service Header, Service Item Line, Service Line of Type G/L Account, Post Service Order
        // as Ship and Create Document Dimension on Service Line.
        CreateServiceOrderGLAccount(ServiceLine);
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.FindSet();
        CreateLimitedDimServiceLine(DimensionValueCombination, ServiceLine);

        // 2. Exercise: Post Service Order as Invoice.
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        asserterror LibraryService.PostServiceOrder(ServiceHeader, false, false, true);

        // 3. Verify: Verify error occurs on Posting Service Order as Invoice with Limited Dimension Combination on Service Line of
        // Type G/L Account.
        VerifyLimitedDimLine(ServiceLine, DimensionValueCombination);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipInvDimLimitedGLAccount()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        DimensionValueCombination: Record "Dimension Value Combination";
    begin
        // Test error occurs on Posting as Ship and Invoice Service Order with Dimension set Limited Dimension Combination on Service
        // Line of Type of Type G/L Account.

        // 1. Setup: Create Customer, G/L Account, Service Header, Service Item Line, Service Line of Type G/L Account and Create Document
        // Dimension on Service Line.
        CreateServiceOrderGLAccount(ServiceLine);
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        CreateLimitedDimServiceLine(DimensionValueCombination, ServiceLine);

        // 2. Exercise: Post Service Order as Ship and Invoice.
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // 3. Verify: Verify error occurs on Posting Service Order as Ship and Invoice with Limited Dimension Combination on Service Line of
        // Type G/L Account.
        VerifyLimitedDimLine(ServiceLine, DimensionValueCombination);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipServiceOrderDim()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // Test Dimensions on Posted Service Shipment, Item Ledger Entries and Value Entries after Posting Service Order as Ship.

        // 1. Setup: Create Customer, Service Item, Item, Resource, G/L Account, Cost, assign Default Dimensions on all, Create Service
        // Header, Service Item Line and Service Line of Type Item, Resource, G/L Account and Cost.
        CreateServiceOrderWithDim(ServiceHeader, ServiceLine, false);

        // 2. Exercise: Update Qty to Ship on Service Line and Post Service Order as Ship.
        UpdatePartialQtyToShip(ServiceLine);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // 3. Verify: Verify Dimensions on Posted Service Shipment, Item Ledger Entries and Value Entries.
        VerifyDimForShipmentHeader(ServiceHeader);
        VerifyDimForShipmentItemLine(ServiceHeader);
        VerifyDimForShipmentLine(ServiceLine);
        VerifyDimShipmentLineCustomer(ServiceLine);
        VerifyDimForItemLedgerEntry(ServiceLine);
        VerifyDimForValueEntry(ServiceLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvServiceOrderDim()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // Test Dimensions on Posted Service Invoice, Customer Ledger Entries and G/L Entries after Posting Service Order as Invoice.

        // 1. Setup: Create Customer, Service Item, Item, Resource, G/L Account, Cost, assign Default Dimensions on all, Create Service
        // Header, Service Item Line and Service Line of Type Item, Resource, G/L Account, Cost and Post Service Order as Ship.
        CreateServiceOrderWithDim(ServiceHeader, ServiceLine, false);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // 2. Exercise: Update Qty to Invoice on Service Line and Post Service Order as Invoice.
        UpdatePartialQtyToInvoice(ServiceLine);
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, false, false, true);

        // 3. Verify: Verify Dimensions on Posted Service Invoice, Customer Ledger Entries and G/L Entries.
        VerifyDimForInvoiceHeader(ServiceHeader);
        VerifyDimForInvoiceLine(ServiceLine);
        VerifyDimInvoiceLineCustomer(ServiceLine);
        VerifyDimForCustomerLederEntry(ServiceHeader."No.");
        VerifyDimForGLEntry(ServiceHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipInvServiceOrderDim()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // Test Dimensions on Posted Service Shipment, Invoice and Resource Ledger Entries after Posting Service Order as Ship and Invoice.

        // 1. Setup: Create Customer, Service Item, Item, Resource, G/L Account, Cost, assign Default Dimensions on all, Create Service
        // Header, Service Item Line and Service Line of Type Item, Resource, G/L Account and Cost.
        CreateServiceOrderWithDim(ServiceHeader, ServiceLine, false);

        // 2. Exercise: Update Qty to Ship on Service Line and Post Service Order as Ship and Invoice.
        UpdatePartialQtyToShip(ServiceLine);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // 3. Verify: Verify Dimensions on Posted Service Shipment, Invoice and Resource Ledger Entries.
        VerifyDimForShipmentHeader(ServiceHeader);
        VerifyDimForShipmentItemLine(ServiceHeader);
        VerifyDimForShipmentLine(ServiceLine);
        VerifyDimShipmentLineCustomer(ServiceLine);
        VerifyDimForInvoiceHeader(ServiceHeader);
        VerifyDimForInvoiceLine(ServiceLine);
        VerifyDimInvoiceLineCustomer(ServiceLine);
        VerifyDimForResourceLederEntry(ServiceLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipConsumeServiceOrderDim()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // Test Dimensions on Posted Service Shipment and Service Ledger Entries after Posting Service Order as Ship and Consume.

        // 1. Setup: Create Customer, Service Item, Item, Resource, assign Default Dimensions on all, Create Service Header, Service Item
        // Line and Service Line of Type Item and Resource.
        CreateServiceOrderWithDim(ServiceHeader, ServiceLine, true);

        // 2. Exercise: Update Qty to Consume on Service Line and Post Service Order as Ship and Consume.
        UpdatePartialQtyToConsume(ServiceLine);
        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);

        // 3. Verify: Verify Dimensions on Posted Service Shipment and Service Ledger Entries.
        VerifyDimForShipmentHeader(ServiceHeader);
        VerifyDimForShipmentItemLine(ServiceHeader);
        VerifyDimForShipmentLine(ServiceLine);
        VerifyDimShipmentLineCustomer(ServiceLine);
        VerifyDimForServiceLederEntry(ServiceLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoDimCodeMandatoryHeader()
    var
        ServiceHeader: Record "Service Header";
        DefaultDimension: Record "Default Dimension";
    begin
        // Test error occurs on Posting Service Order without Dimension marked as Code mandatory on Service Header.

        // 1. Setup: Create Customer, Create Default Dimension for Customer and Create Service Header.
        CreateServiceHeaderWithDim(ServiceHeader, DefaultDimension, DefaultDimension."Value Posting"::"Code Mandatory");
        Commit();

        // 2. Exercise: Delete Document Dimension for Service Header and Post Service Order as Ship and Invoice.
        UpdateDimSetIdOnHeader(
          ServiceHeader, LibraryDimension.DeleteDimSet(ServiceHeader."Dimension Set ID", DefaultDimension."Dimension Code"));
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // 3. Verify: Verify error occurs "Dimension Invalid" on Posting Service Order as Ship and Invoice.
        Assert.AreEqual(
          StrSubstNo(
            MandatoryDimensionOnHeader, ServiceHeader."Document Type", ServiceHeader."No.",
            DefaultDimension.FieldCaption("Dimension Value Code"), DefaultDimension.FieldCaption("Dimension Code"),
            DefaultDimension."Dimension Code", ServiceHeader."Customer No."),
          GetLastErrorText, UnknownError);

        // 4. Cleanup: Change Value Posting to Blank.
        ModifyDefaultDimension(DefaultDimension, DefaultDimension."Value Posting"::" ");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DimCodeMandatoryHeader()
    var
        DefaultDimension: Record "Default Dimension";
    begin
        // Test Service Order Sucessfully Posted with Dimension marked as Code mandatory on Service Header.

        ShipInvWithHeaderDim(DefaultDimension."Value Posting"::"Code Mandatory");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DimSameCodeHeader()
    var
        DefaultDimension: Record "Default Dimension";
    begin
        // Test Service Order Sucessfully Posted with same Dimension value code marked as Same Code on Service Header.

        ShipInvWithHeaderDim(DefaultDimension."Value Posting"::"Same Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DimNoCodeHeader()
    var
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        DefaultDimension: Record "Default Dimension";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        // Test Service Order Sucessfully Posted without Dimension marked as No Code on Service Header.

        // 1. Setup: Create Customer, Create Default Dimension for Customer, Create Service Header, Service Item Line and Service Line.
        CreateServiceHeaderWithDim(ServiceHeader, DefaultDimension, DefaultDimension."Value Posting"::"No Code");
        LibraryInventory.CreateItem(Item);
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.", ServiceItemLine."Line No.");

        // 2. Post Service Order as Ship and Invoice.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // 3. Verify: Verify Service Shipment Header created after Posting Service Order.
        VerifyServiceShipmentHeader(ServiceHeader);

        // 4. Teardown: Change Value Posting to Blank.
        ModifyDefaultDimension(DefaultDimension, DefaultDimension."Value Posting"::" ");
    end;

    local procedure ShipInvWithHeaderDim(ValuePosting: Enum "Default Dimension Value Posting Type")
    var
        ServiceHeader: Record "Service Header";
        DefaultDimension: Record "Default Dimension";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        // 1. Setup: Create Customer, Create Default Dimension for Customer, Create Service Header, Service Item Line and Service Line.
        CreateServiceHeaderWithDim(ServiceHeader, DefaultDimension, ValuePosting);
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItemNo(), ServiceItemLine."Line No.");

        // 2. Exercise: Post Service Order as Ship and Invoice.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // 3. Verify: Verify Service Shipment Header created after Posting Service Order.
        VerifyServiceShipmentHeader(ServiceHeader);

        // 4. Cleanup: Change Value Posting to Blank.
        ModifyDefaultDimension(DefaultDimension, DefaultDimension."Value Posting"::" ");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoDimCodeMandatoryGLAccount()
    var
        Dimension: Record Dimension;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        DefaultDimension: Record "Default Dimension";
    begin
        // Test error occurs on Posting Service Order without Dimension marked as Code mandatory on Service Line of Type G/L Account.

        // 1. Setup: Create Customer, Create G/L Account, Create Default Dimension for G/L Account, Create Service Header, Service Item
        // Line, Service Line of Type G/L Account and Change Value Posting to "Code Mandatory" for G/L Account.
        CreateLineBlockDimGLAccount(ServiceLine, Dimension);
        LibraryDimension.FindDefaultDimension(DefaultDimension, DATABASE::"G/L Account", ServiceLine."No.");
        ModifyDefaultDimension(DefaultDimension, DefaultDimension."Value Posting"::"Code Mandatory");

        // 2. Exercise: Delete Document Dimension for Service Line and Post Service Order as Ship and Invoice.
        UpdateDimSetIdOnLine(
          ServiceLine, LibraryDimension.DeleteDimSet(ServiceLine."Dimension Set ID", DefaultDimension."Dimension Code"));
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // 3. Verify: Verify error occurs "Dimension Invalid" on Posting Service Order as Ship and Invoice.
        Assert.AreEqual(
          StrSubstNo(
            MandatoryDimensionServiceLine, ServiceLine."Document Type", ServiceLine."Document No.", ServiceLine."Line No.",
            DefaultDimension.FieldCaption("Dimension Value Code"), DefaultDimension.FieldCaption("Dimension Code"), Dimension.Code,
            ServiceLine.Type, ServiceLine."No."), GetLastErrorText, UnknownError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoDimCodeMandatoryItem()
    var
        Dimension: Record Dimension;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        DefaultDimension: Record "Default Dimension";
    begin
        // Test error occurs on Posting Service Order without Dimension marked as Code mandatory on Service Line of Type Item.

        // 1. Setup: Create Customer, Create Item, Create Default Dimension for Item, Create Service Header, Service Item
        // Line, Service Line of Type Item and Change Value Posting to "Code Mandatory" for Item.
        CreateLineBlockDimItem(ServiceLine, Dimension, false);
        LibraryDimension.FindDefaultDimension(DefaultDimension, DATABASE::Item, ServiceLine."No.");
        ModifyDefaultDimension(DefaultDimension, DefaultDimension."Value Posting"::"Code Mandatory");

        // 2. Exercise: Delete Document Dimension for Service Line and Post Service Order as Ship and Invoice.
        UpdateDimSetIdOnLine(
          ServiceLine, LibraryDimension.DeleteDimSet(ServiceLine."Dimension Set ID", DefaultDimension."Dimension Code"));
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // 3. Verify: Verify error occurs "Dimension Invalid" on Posting Service Order as Ship and Invoice.
        Assert.AreEqual(
          StrSubstNo(
            MandatoryDimensionServiceLine, ServiceLine."Document Type", ServiceLine."Document No.", ServiceLine."Line No.",
            DefaultDimension.FieldCaption("Dimension Value Code"), DefaultDimension.FieldCaption("Dimension Code"), Dimension.Code,
            ServiceLine.Type, ServiceLine."No."), GetLastErrorText, UnknownError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoDimCodeMandatoryResource()
    var
        Dimension: Record Dimension;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        DefaultDimension: Record "Default Dimension";
    begin
        // Test error occurs on Posting Service Order without Dimension marked as Code mandatory on Service Line of Type Resource.

        // 1. Setup: Create Customer, Create Resource, Create Default Dimension for Resource, Create Service Header, Service Item
        // Line, Service Line of Type Resource and Change Value Posting to "Code Mandatory" for Resource.
        CreateLineBlockDimResource(ServiceLine, Dimension, false);
        LibraryDimension.FindDefaultDimension(DefaultDimension, DATABASE::Resource, ServiceLine."No.");
        ModifyDefaultDimension(DefaultDimension, DefaultDimension."Value Posting"::"Code Mandatory");

        // 2. Exercise: Delete Document Dimension for Service Line and Post Service Order as Ship and Invoice.
        UpdateDimSetIdOnLine(
          ServiceLine, LibraryDimension.DeleteDimSet(ServiceLine."Dimension Set ID", DefaultDimension."Dimension Code"));
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // 3. Verify: Verify error occurs "Dimension Invalid" on Posting Service Order as Ship and Invoice.
        Assert.AreEqual(
          StrSubstNo(
            MandatoryDimensionServiceLine, ServiceLine."Document Type", ServiceLine."Document No.", ServiceLine."Line No.",
            DefaultDimension.FieldCaption("Dimension Value Code"), DefaultDimension.FieldCaption("Dimension Code"), Dimension.Code,
            ServiceLine.Type, ServiceLine."No."), GetLastErrorText, UnknownError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoDimSameCodeHeader()
    var
        ServiceHeader: Record "Service Header";
        DefaultDimension: Record "Default Dimension";
        DimSetEntry: Record "Dimension Set Entry";
        Customer: Record Customer;
    begin
        // Test error occurs on Posting Service Order with different Dimension value code marked as Same Code on Service Header.

        // 1. Setup: Create Customer, Create Default Dimension for Customer and Create Service Header.
        CreateServiceHeaderWithDim(ServiceHeader, DefaultDimension, DefaultDimension."Value Posting"::"Same Code");
        Commit();

        // 2. Exercise: Change the Dimension Value on Document Dimension for Service Header and Post Service Order as Ship and Invoice.
        UpdateDimSetIdOnHeader(
          ServiceHeader,
          LibraryDimension.EditDimSet(
            ServiceHeader."Dimension Set ID", DefaultDimension."Dimension Code",
            FindDifferentDimensionValue(DefaultDimension."Dimension Code", DefaultDimension."Dimension Value Code")));
        LibraryDimension.FindDimensionSetEntry(DimSetEntry, ServiceHeader."Dimension Set ID");
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // 3. Verify: Verify error occurs "Dimension Invalid" on Posting Service Order as Ship and Invoice.
        Assert.AreEqual(
          StrSubstNo(
            SameCodeOrNoCodeDimHeader, ServiceHeader."Document Type", ServiceHeader."No.",
            DefaultDimension.FieldCaption("Dimension Value Code"), DefaultDimension."Dimension Value Code",
            DefaultDimension.FieldCaption("Dimension Code"), DefaultDimension."Dimension Code",
            Customer.TableCaption(), ServiceHeader."Customer No.",
            DimSetEntry."Dimension Value Code"),
            GetLastErrorText, UnknownError);

        // 4. Cleanup: Change Value Posting to Blank.
        ModifyDefaultDimension(DefaultDimension, DefaultDimension."Value Posting"::" ");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoDimSameCodeItem()
    var
        Dimension: Record Dimension;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        DefaultDimension: Record "Default Dimension";
        DimSetEntry: Record "Dimension Set Entry";
    begin
        // Test error occurs on Posting Service Order with different Dimension value code marked as Same Code on Service Line of Type Item.

        // 1. Setup: Create Customer, Create Item, Create Default Dimension for Item, Create Service Header, Service Item
        // Line, Service Line of Type Item and Change Value Posting to "Same Code" for Item.
        CreateLineBlockDimItem(ServiceLine, Dimension, false);
        LibraryDimension.FindDefaultDimension(DefaultDimension, DATABASE::Item, ServiceLine."No.");
        ModifyDefaultDimension(DefaultDimension, DefaultDimension."Value Posting"::"Same Code");

        // 2. Exercise: Change the Dimension Value on Document Dimension for Service Line and Post Service Order as Ship and Invoice.
        UpdateDimSetIdOnLine(
          ServiceLine,
          LibraryDimension.EditDimSet(
            ServiceLine."Dimension Set ID", DefaultDimension."Dimension Code",
            FindDifferentDimensionValue(DefaultDimension."Dimension Code", DefaultDimension."Dimension Value Code")));
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        LibraryDimension.FindDimensionSetEntry(DimSetEntry, ServiceLine."Dimension Set ID");
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // 3. Verify: Verify error occurs "Dimension Invalid" on Posting Service Order as Ship and Invoice.
        Assert.AreEqual(
          StrSubstNo(
            SameCodeOrNoCodeDimLine, ServiceLine."Document Type", ServiceLine."Document No.", ServiceLine."Line No.",
            DefaultDimension.FieldCaption("Dimension Value Code"), DefaultDimension."Dimension Value Code",
            DefaultDimension.FieldCaption("Dimension Code"), DefaultDimension."Dimension Code",
            ServiceLine.Type, ServiceLine."No.",
            DimSetEntry."Dimension Value Code"),
            GetLastErrorText, UnknownError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoDimSameCodeResource()
    var
        Dimension: Record Dimension;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        DefaultDimension: Record "Default Dimension";
        DimSetEntry: Record "Dimension Set Entry";
    begin
        // Test error occurs on Posting Service Order with different Dimension value code marked as Same Code on Service Line of Type
        // Resource.

        // 1. Setup: Create Customer, Create Resource, Create Default Dimension for Resource, Create Service Header, Service Item
        // Line, Service Line of Type Resource and Change Value Posting to "Same Code" for Resource.
        CreateLineBlockDimResource(ServiceLine, Dimension, false);
        LibraryDimension.FindDefaultDimension(DefaultDimension, DATABASE::Resource, ServiceLine."No.");
        ModifyDefaultDimension(DefaultDimension, DefaultDimension."Value Posting"::"Same Code");

        // 2. Exercise: Change the Dimension Value on Document Dimension for Service Line and Post Service Order as Ship and Invoice.
        UpdateDimSetIdOnLine(
          ServiceLine,
          LibraryDimension.EditDimSet(
            ServiceLine."Dimension Set ID", DefaultDimension."Dimension Code",
            FindDifferentDimensionValue(DefaultDimension."Dimension Code", DefaultDimension."Dimension Value Code")));
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        LibraryDimension.FindDimensionSetEntry(DimSetEntry, ServiceLine."Dimension Set ID");
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // 3. Verify: Verify error occurs "Dimension Invalid" on Posting Service Order as Ship and Invoice.
        Assert.AreEqual(
          StrSubstNo(
            SameCodeOrNoCodeDimLine, ServiceLine."Document Type", ServiceLine."Document No.", ServiceLine."Line No.",
            DefaultDimension.FieldCaption("Dimension Value Code"), DefaultDimension."Dimension Value Code",
            DefaultDimension.FieldCaption("Dimension Code"), DefaultDimension."Dimension Code",
            ServiceLine.Type, ServiceLine."No.",
            DimSetEntry."Dimension Value Code"),
            GetLastErrorText, UnknownError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoDimSameCodeGLAccount()
    var
        Dimension: Record Dimension;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        DefaultDimension: Record "Default Dimension";
        DimSetEntry: Record "Dimension Set Entry";
    begin
        // Test error occurs on Posting Service Order with different Dimension value code marked as Same Code on Service Line of Type
        // G/L Account.

        // 1. Setup: Create Customer, Create G/L Account, Create Default Dimension for G/L Account, Create Service Header, Service Item
        // Line, Service Line of Type G/L Account and Change Value Posting to "Same Code" for G/L Account.
        CreateLineBlockDimGLAccount(ServiceLine, Dimension);
        LibraryDimension.FindDefaultDimension(DefaultDimension, DATABASE::"G/L Account", ServiceLine."No.");
        ModifyDefaultDimension(DefaultDimension, DefaultDimension."Value Posting"::"Same Code");

        // 2. Exercise: Change the Dimension Value on Document Dimension for Service Line and Post Service Order as Ship and Invoice.
        UpdateDimSetIdOnLine(
          ServiceLine,
          LibraryDimension.EditDimSet(
            ServiceLine."Dimension Set ID", DefaultDimension."Dimension Code",
            FindDifferentDimensionValue(DefaultDimension."Dimension Code", DefaultDimension."Dimension Value Code")));
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        LibraryDimension.FindDimensionSetEntry(DimSetEntry, ServiceLine."Dimension Set ID");
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // 3. Verify: Verify error occurs "Dimension Invalid" on Posting Service Order as Ship and Invoice.
        Assert.AreEqual(
            StrSubstNo(
            SameCodeOrNoCodeDimLine, ServiceLine."Document Type", ServiceLine."Document No.", ServiceLine."Line No.",
            DefaultDimension.FieldCaption("Dimension Value Code"), DefaultDimension."Dimension Value Code",
            DefaultDimension.FieldCaption("Dimension Code"), DefaultDimension."Dimension Code",
            ServiceLine.Type, ServiceLine."No.",
            DimSetEntry."Dimension Value Code"),
            GetLastErrorText, UnknownError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoDimNoCodeHeader()
    var
        ServiceHeader: Record "Service Header";
        DefaultDimension: Record "Default Dimension";
        Customer: Record Customer;
        DimensionValueCode: Code[20];
    begin
        // Test error occurs on Posting Service Order with Dimension marked as No Code on Service Header.

        // 1. Setup: Create Customer, Create Default Dimension for Customer and Create Service Header.
        CreateServiceHeaderWithDim(ServiceHeader, DefaultDimension, DefaultDimension."Value Posting"::"No Code");
        Commit();
        // 2. Exercise: Change the Dimension Value on Document Dimension for Service Header and Post Service Order as Ship and Invoice.
        DimensionValueCode := FindDifferentDimensionValue(DefaultDimension."Dimension Code", DefaultDimension."Dimension Value Code");
        UpdateDimSetIdOnHeader(
          ServiceHeader,
          LibraryDimension.CreateDimSet(
            ServiceHeader."Dimension Set ID", DefaultDimension."Dimension Code", DimensionValueCode));

        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // 3. Verify: Verify error occurs "Dimension Invalid" on Posting Service Order as Ship and Invoice.
        Assert.AreEqual(
          StrSubstNo(
            SameCodeOrNoCodeDimHeader, ServiceHeader."Document Type", ServiceHeader."No.",
            DefaultDimension.FieldCaption("Dimension Value Code"), BlankLbl,
            DefaultDimension.FieldCaption("Dimension Code"), DefaultDimension."Dimension Code",
            Customer.TableCaption(), ServiceHeader."Customer No.",
            DimensionValueCode),
            GetLastErrorText, UnknownError);

        // 4. Teardown: Change Value Posting to Blank.
        ModifyDefaultDimension(DefaultDimension, DefaultDimension."Value Posting"::" ");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoDimNoCodeGLAccount()
    var
        Dimension: Record Dimension;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        DefaultDimension: Record "Default Dimension";
        DimensionValueCode: Code[20];
    begin
        // Test error occurs on Posting Service Order with Dimension Value marked as No Code on Service Line of Type G/L Account.

        // 1. Setup: Create Customer, Create G/L Account, Create Default Dimension for G/L Account, Create Service Header, Service Item
        // Line, Service Line of Type G/L Account and Change Value Posting to "No Code" for G/L Account.
        CreateLineBlockDimGLAccount(ServiceLine, Dimension);
        DimensionValueCode := FindDimensionValue(Dimension.Code);
        LibraryDimension.FindDefaultDimension(DefaultDimension, DATABASE::"G/L Account", ServiceLine."No.");
        ModifyDefaultDimension(DefaultDimension, DefaultDimension."Value Posting"::"No Code");
        Commit();

        // 2. Exercise: Post Service Order as Ship and Invoice.
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // 3. Verify: Verify error occurs "Dimension Invalid" on Posting Service Order as Ship and Invoice.
        Assert.AreEqual(
          StrSubstNo(
            SameCodeOrNoCodeDimLine, ServiceLine."Document Type", ServiceLine."Document No.", ServiceLine."Line No.",
            DefaultDimension.FieldCaption("Dimension Value Code"), BlankLbl,
            DefaultDimension.FieldCaption("Dimension Code"), DefaultDimension."Dimension Code",
            ServiceLine.Type, ServiceLine."No.",
            DimensionValueCode),
            GetLastErrorText, UnknownError);

        // 4. Teardown: Change Value Posting to Blank.
        ModifyDefaultDimension(DefaultDimension, DefaultDimension."Value Posting"::" ");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoDimNoCodeItem()
    var
        Dimension: Record Dimension;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        DefaultDimension: Record "Default Dimension";
        DimensionValueCode: Code[20];
    begin
        // Test error occurs on Posting Service Order with Dimension Value marked as No Code on Service Line of Type Item.

        // 1. Setup: Create Customer, Create Item, Create Default Dimension for Item, Create Service Header, Service Item
        // Line, Service Line of Type Item and Change Value Posting to "No Code" for Item.
        CreateLineBlockDimItem(ServiceLine, Dimension, false);
        DimensionValueCode := FindDimensionValue(Dimension.Code);
        LibraryDimension.FindDefaultDimension(DefaultDimension, DATABASE::Item, ServiceLine."No.");
        ModifyDefaultDimension(DefaultDimension, DefaultDimension."Value Posting"::"No Code");
        Commit();

        // 2. Exercise: Post Service Order as Ship and Invoice.
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // 3. Verify: Verify error occurs "Dimension Invalid" on Posting Service Order as Ship and Invoice.
        Assert.AreEqual(
          StrSubstNo(
            SameCodeOrNoCodeDimLine, ServiceLine."Document Type", ServiceLine."Document No.", ServiceLine."Line No.",
            DefaultDimension.FieldCaption("Dimension Value Code"), BlankLbl,
            DefaultDimension.FieldCaption("Dimension Code"), DefaultDimension."Dimension Code",
            ServiceLine.Type, ServiceLine."No.",
            DimensionValueCode),
            GetLastErrorText, UnknownError);

        // 4. Teardown: Change Value Posting to Blank.
        ModifyDefaultDimension(DefaultDimension, DefaultDimension."Value Posting"::" ");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoDimNoCodeResource()
    var
        Dimension: Record Dimension;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        DefaultDimension: Record "Default Dimension";
        DimensionValueCode: Code[20];
    begin
        // Test error occurs on Posting Service Order with Dimension Value marked as No Code on Service Line of Type Resource.

        // 1. Setup: Create Customer, Create Resource, Create Default Dimension for Resource, Create Service Header, Service Item
        // Line, Service Line of Type Resource and Change Value Posting to "No Code" for Resource.
        CreateLineBlockDimResource(ServiceLine, Dimension, false);
        DimensionValueCode := FindDimensionValue(Dimension.Code);
        LibraryDimension.FindDefaultDimension(DefaultDimension, DATABASE::Resource, ServiceLine."No.");
        ModifyDefaultDimension(DefaultDimension, DefaultDimension."Value Posting"::"No Code");
        Commit();

        // 2. Exercise: Post Service Order as Ship and Invoice.
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // 3. Verify: Verify error occurs "Dimension Invalid" on Posting Service Order as Ship and Invoice.
        Assert.AreEqual(
          StrSubstNo(
            SameCodeOrNoCodeDimLine, ServiceLine."Document Type", ServiceLine."Document No.", ServiceLine."Line No.",
            DefaultDimension.FieldCaption("Dimension Value Code"), BlankLbl,
            DefaultDimension.FieldCaption("Dimension Code"), DefaultDimension."Dimension Code",
            ServiceLine.Type, ServiceLine."No.",
            DimensionValueCode),
            GetLastErrorText, UnknownError);

        // 4. Teardown: Change Value Posting to Blank.
        ModifyDefaultDimension(DefaultDimension, DefaultDimension."Value Posting"::" ");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DimCodeMandatory()
    var
        DefaultDimension: Record "Default Dimension";
    begin
        // Test Service Order Sucessfully Posted with Dimension marked as Code mandatory on Service Line of Type Item, Resource and
        // G/L Account.

        ShipInvDimServiceLine(DefaultDimension."Value Posting"::"Code Mandatory");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DimSameCode()
    var
        DefaultDimension: Record "Default Dimension";
    begin
        // Test Service Order Sucessfully Posted with same Dimension value code marked as Same Code on Service Line of Type Item, Resource
        // and G/L Account.

        ShipInvDimServiceLine(DefaultDimension."Value Posting"::"Same Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DimNoCode()
    var
        ServiceHeader: Record "Service Header";
        DefaultDimension: Record "Default Dimension";
    begin
        // Test Service Order Sucessfully Posted without Dimension Value marked as No Code on Service Line of Type Item, Resource and
        // G/L Account.

        // 1. Setup: Create Customer, Resource, Item, G/L Account and Assign Default Dimension for all with Value Posting "No Code",
        // Create Service Header, Service Item Line, Service Line of Type Item, Resource, G/L Account.
        CreateServiceOrderGLDim(ServiceHeader, DefaultDimension."Value Posting"::"No Code");

        // Delete Dimensions for all Service Lines.
        DeleteServiceLineDimensions(ServiceHeader);

        // 2. Exercise: Post Service Order as Ship and Invoice.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // 3. Verify: Verify Service Shipment Header created after Posting Service Header.
        VerifyServiceShipmentHeader(ServiceHeader);

        // 4. Teardown: Change Value Posting to Blank.
        DefaultDimension.SetRange("Value Posting", DefaultDimension."Value Posting"::"No Code");
        DefaultDimension.ModifyAll("Value Posting", DefaultDimension."Value Posting"::" ");
    end;

    local procedure ShipInvDimServiceLine(ValuePosting: Enum "Default Dimension Value Posting Type")
    var
        ServiceHeader: Record "Service Header";
    begin
        // 1. Setup: Create Customer, Resource, Item, G/L Account and Assign Default Dimension for all with Value Posting "No Code",
        // Create Service Header, Service Item Line, Service Line of Type Item, Resource, G/L Account.
        CreateServiceOrderGLDim(ServiceHeader, ValuePosting);

        // 2. Exercise: Post Service Order as Ship and Invoice.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // 3. Verify: Verify Service Shipment Header created after Posting Service Header.
        VerifyServiceShipmentHeader(ServiceHeader);

        // 4. Cleanup: Change Value Posting to Blank.
        RollbackValuePosting(ServiceHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler')]
    [Scope('OnPrem')]
    procedure SameDimHeaderLine()
    var
        ServiceLine: Record "Service Line";
        DefaultDimension: Record "Default Dimension";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        DimensionValueCode: Code[20];
        HeaderDimensionSetID: Integer;
    begin
        // Test on changing Dimension Values on Service Header its successfully updated on Service Item Line and Service Line.

        // 1. Setup: Create Customer, Create Item, Create Default Dimension for Item and Customer, Create Service Header, Service Item
        // Line and Service Line of Type Item.
        CreateOrderWithCustomerDim(ServiceLine, DefaultDimension);

        // 2. Exercise: Change Document Dimension Value on Service Header and Click Yes on Confirmation Message for updating Service Item
        // Line and Service Line Dimensions.
        DimensionValueCode := FindDifferentDimensionValue(DefaultDimension."Dimension Code", DefaultDimension."Dimension Value Code");
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        HeaderDimensionSetID := ServiceHeader."Dimension Set ID";
        UpdateDimSetIdOnHeader(
          ServiceHeader, LibraryDimension.EditDimSet(HeaderDimensionSetID, DefaultDimension."Dimension Code", DimensionValueCode));
        ServiceHeader.UpdateAllLineDim(ServiceHeader."Dimension Set ID", HeaderDimensionSetID);

        // 3. Verify: Verify Dimension value Successfully updated on Service Item Line and Service Line Dimensions.
        ServiceItemLine.SetRange("Document No.", ServiceLine."Document No.");
        ServiceItemLine.FindFirst();
        VerifyDimSetEntry(ServiceItemLine."Dimension Set ID", DefaultDimension."Dimension Code", DimensionValueCode);

        ServiceLine.SetRange("Document No.", ServiceLine."Document No.");
        ServiceLine.FindFirst();
        VerifyDimSetEntry(ServiceLine."Dimension Set ID", DefaultDimension."Dimension Code", DimensionValueCode);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandlerForFalse')]
    [Scope('OnPrem')]
    procedure DiffDimHeaderLine()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        DefaultDimension: Record "Default Dimension";
        HeaderDimensionSetID: Integer;
    begin
        // Test Service Order Sucessfully Posted with different Dimension Values on Service Header, Service Item Line and Service Line.

        // 1. Setup: Create Customer, Create Item, Create Default Dimension for Item and Customer, Create Service Header, Service Item
        // Line and Service Line of Type Item.
        CreateOrderWithCustomerDim(ServiceLine, DefaultDimension);

        // 2. Exercise: Change Document Dimension Value on Service Header and Click No on Confirmation Message for updating Service Item
        // Line, Service Line Dimensions and Post Service Order as Ship.
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        HeaderDimensionSetID := ServiceHeader."Dimension Set ID";
        UpdateDimSetIdOnHeader(
          ServiceHeader,
          LibraryDimension.EditDimSet(
            HeaderDimensionSetID, DefaultDimension."Dimension Code",
            FindDifferentDimensionValue(DefaultDimension."Dimension Code", DefaultDimension."Dimension Value Code")));
        ServiceHeader.UpdateAllLineDim(ServiceHeader."Dimension Set ID", HeaderDimensionSetID);

        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // 3. Verify: Verify Posted Service Shipment Created after Posting Service Order.
        VerifyServiceShipmentHeader(ServiceHeader);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler')]
    [Scope('OnPrem')]
    procedure SameDimItemLineLine()
    var
        ServiceLine: Record "Service Line";
        DefaultDimension: Record "Default Dimension";
        ServiceItemLine: Record "Service Item Line";
        DimensionValueCode: Code[20];
    begin
        // Test on changing Dimension Values on Service Item Line its Successfully updated on Service Line.

        // 1. Setup: Create Customer, Create Item, Create Default Dimension for Item and Customer, Create Service Header, Service Item
        // Line and Service Line of Type Item.
        CreateOrderWithCustomerDim(ServiceLine, DefaultDimension);

        // 2. Exercise: Change Document Dimension Value on Service Item Line and Click Yes on Confirmation Message for updating Service
        // Line Dimensions.
        FindServiceItemLine(ServiceItemLine, ServiceLine);
        DimensionValueCode := FindDifferentDimensionValue(DefaultDimension."Dimension Code", DefaultDimension."Dimension Value Code");
        UpdateDimSetIdOnItemLine(ServiceItemLine, DefaultDimension."Dimension Code", DimensionValueCode);

        // 3. Verify: Verify Dimension value Successfully updated on Service Line Dimensions.
        ServiceLine.SetRange("Document No.", ServiceLine."Document No.");
        ServiceLine.FindFirst();
        VerifyDimSetEntry(ServiceLine."Dimension Set ID", DefaultDimension."Dimension Code", DimensionValueCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultDimPriorityOrder()
    var
        Customer: Record Customer;
        SourceCodeSetup: Record "Source Code Setup";
        ServiceHeader: Record "Service Header";
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        DefaultDimensionPriority: Record "Default Dimension Priority";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        ServiceItemGroupCode: Code[10];
    begin
        // Test Dimensions on Service Header, Service Item Line and Service Line are updated according to Default Dimensions Priorities.

        // 1. Setup: Create Customer, Responsibility Center, Create Default Dimension Priority, Service Item, Resource, Item, G/L Account
        // Cost and Create Default Dimensions for all.
        Initialize();
        CreateDefaultDimensionPriority(DefaultDimensionPriority);
        LibraryDimension.FindDimension(Dimension);
        LibraryDimension.FindDimensionValue(DimensionValue, Dimension.Code);

        LibrarySales.CreateCustomer(Customer);
        LibraryDimension.CreateDefaultDimensionCustomer(DefaultDimension, Customer."No.", Dimension.Code, DimensionValue.Code);

        DimensionValue.Next();
        CreateHeaderResponsibility(ServiceHeader, Customer."No.", Dimension.Code, DimensionValue.Code);

        // 2. Exercise: Create Service Header, Update Responsibility Center on Service Header, Create Service Item Line and Service Lines.
        ServiceItemGroupCode := CreateServiceDocumentLines(ServiceLine, ServiceItemLine, DimensionValue, ServiceHeader, Dimension.Code);

        // 3. Verify: Verify Dimensions on Service Line according to Default Dimension Priorities.
        VerifyDimOnServiceLine(ServiceLine);
        VerifyDimForCost(ServiceLine);
        VerifyDimForResponsibility(ServiceHeader, ServiceHeader."Responsibility Center");
        VerifyDimForServiceItemGrp(ServiceItemLine, ServiceItemGroupCode);

        // 4. Teardown: Delete all Default Dimension Priority Related to Service Management.
        SourceCodeSetup.Get();
        DefaultDimensionPriority.SetRange("Source Code", SourceCodeSetup."Service Management");
        DefaultDimensionPriority.DeleteAll(true);
    end;

    [Test]
    [HandlerFunctions('ModalFormHander')]
    [Scope('OnPrem')]
    procedure DimFromStandardServiceCode()
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
        StandardServiceCode: Record "Standard Service Code";
        ServiceItemLine: Record "Service Item Line";
        StandardServiceItemGrCode: Record "Standard Service Item Gr. Code";
        ServiceItemGroupCode: Code[10];
    begin
        // Test Dimension on Service Lines after running Get Standard Service Code.

        // 1. Setup: Create Customer, Service Item Group and Create Standard Service Code with Standard Service Lines having Dimensions.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        CreateStandardServiceCodeDim(StandardServiceCode);
        ServiceItemGroupCode := CreateServiceItemGroup();
        LibraryVariableStorage.Enqueue(ServiceItemGroupCode);
        LibraryVariableStorage.Enqueue(StandardServiceCode.Code);

        // 2. Exercise: Create Service Header, Service Item Line, Update Service Item Group Code on Service Item Line and Run Insert Service
        // Lines functions.
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        ServiceItemLine.Validate("Service Item Group Code", ServiceItemGroupCode);
        ServiceItemLine.Modify(true);
        StandardServiceItemGrCode.InsertServiceLines(ServiceItemLine);

        // 3. Verify: Verify Dimensions on Service Lines.
        VerifyDimFromStandardCode(StandardServiceCode.Code, ServiceHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ModalFormHander')]
    [Scope('OnPrem')]
    procedure CombineDimFromStandardServiceCode()
    var
        Customer: Record Customer;
        Item: Record Item;
        Dimension: Record Dimension;
        DefaultDimension: Record "Default Dimension";
        ServiceHeader: Record "Service Header";
        StandardServiceCode: Record "Standard Service Code";
        StandardServiceLine: Record "Standard Service Line";
        ServiceItemLine: Record "Service Item Line";
        StandardServiceItemGrCode: Record "Standard Service Item Gr. Code";
        ServiceItemGroupCode: Code[10];
        ServItemDimSetID: Integer;
    begin
        // Test Dimension on Service Lines after running Get Standard Service Code.

        // 1. Setup: Create Customer, Service Item Group and Create Standard Service Code with Standard Service Lines having Dimensions.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateItem(Item);
        LibraryService.CreateStandardServiceCode(StandardServiceCode);
        LibraryDimension.FindDimension(Dimension);
        CreateStandardServiceLineDim(StandardServiceCode.Code, StandardServiceLine.Type::Item, Item."No.", Dimension.Code);
        Dimension.Next();
        LibraryDimension.CreateDefaultDimensionItem(DefaultDimension, Item."No.", Dimension.Code, FindDimensionValue(Dimension.Code));
        ServiceItemGroupCode := CreateServiceItemGroup();
        LibraryVariableStorage.Enqueue(ServiceItemGroupCode);
        LibraryVariableStorage.Enqueue(StandardServiceCode.Code);

        // 2. Exercise: Create Service Header, Service Item Line, Update Service Item Group Code on Service Item Line and Run Insert Service
        // Lines functions.
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        ServiceItemLine.Validate("Service Item Group Code", ServiceItemGroupCode);
        ServiceItemLine.Modify(true);
        ServItemDimSetID := ServiceItemLine."Dimension Set ID";
        StandardServiceItemGrCode.InsertServiceLines(ServiceItemLine);

        // 3. Verify: Verify Dimensions on Service Lines.
        CombineDimensions(ServiceItemLine, StandardServiceLine);
        Assert.AreEqual(ServItemDimSetID, ServiceItemLine."Dimension Set ID", 'Dim Set ID should be combined');
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler')]
    [Scope('OnPrem')]
    procedure UndoServiceShipmentForResourceWithSameCodeDimension()
    var
        Dimension: Record Dimension;
        DefaultDimension: Record "Default Dimension";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // Setup: Create Service Order for Resource with Dimension. Update Value Posting for Dimension. Post Service Order as Ship.
        CreateLineBlockDimResource(ServiceLine, Dimension, false);
        LibraryDimension.FindDefaultDimension(DefaultDimension, DATABASE::Resource, ServiceLine."No.");
        ModifyDefaultDimension(DefaultDimension, DefaultDimension."Value Posting"::"Same Code");
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // Exercise: Undo Posted Service Shipment.
        LibraryService.UndoShipmentLinesByServiceOrderNo(ServiceHeader."No.");

        // Verify: Verify the Dimension Set ID on the Service Ledger Entry.
        VerifyServiceLedgerEntryDimSetID(ServiceHeader."No.", ServiceLine."Dimension Set ID");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefDimWithHighestPriorityFromServItemLineInheritedToServLine()
    var
        Dimension: Record Dimension;
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        CustomerNo: Code[20];
        ServiceItemNo: Code[20];
        ItemNo: Code[20];
        ExpectedDimValueCode: Code[20];
    begin
        // [FEATURE] [Default Dimension Priority]
        // [SCENARIO 375456] Default Dimension with highest priority in Service Item Line should be inherited to Service Line

        Initialize();
        // [GIVEN] Default Dimension Priorities: Service Item = 1, Item = 2
        SetPairedDefaultDimPriorities(DATABASE::"Service Item", DATABASE::Item);
        LibraryDimension.CreateDimension(Dimension);

        // [GIVEN] Default Dimension "A1" for Customer, "A2" for Item, "A3" for Service Item
        CustomerNo := LibrarySales.CreateCustomerNo();
        ServiceItemNo := CreateServiceItem(CustomerNo, CreateServiceItemGroup());
        ItemNo := LibraryInventory.CreateItemNo();
        CreateDefDimWithNewDimValue(Dimension.Code, DATABASE::Customer, CustomerNo);
        CreateDefDimWithNewDimValue(Dimension.Code, DATABASE::Item, ItemNo);
        ExpectedDimValueCode :=
          CreateDefDimWithNewDimValue(Dimension.Code, DATABASE::"Service Item", ServiceItemNo);

        // [GIVEN] Service Order with Customer and Service Item Line with Service Item
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, CustomerNo);
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItemNo);

        // [WHEN] Create Service Line with Item
        CreateServiceLineWithServItemLineNo(ServiceLine, ServiceHeader, ItemNo, ServiceItemLine."Line No.");

        // [THEN] "Dimension Set ID" in Service Line has dimension with value "A3"
        VerifyDimSetEntry(ServiceLine."Dimension Set ID", Dimension.Code, ExpectedDimValueCode);
    end;

    [Test]
    [HandlerFunctions('ModalPageHandlerForDim')]
    [Scope('OnPrem')]
    procedure DefDimWithHighPriorityFromWorkCenterInheritedByProdJournal()
    var
        ProductionOrder: Record "Production Order";
        ItemNo: Code[20];
        ItemDimValueCode: Code[20];
        WorkCenterDimValueCode: Code[20];
    begin
        // [FEATURE] [Default Dimension Priority] [Production Journal]
        // [SCENARIO 378966] Default Dimension with high priority in Work Center should be inherited by Production Journal.
        Initialize();

        // [GIVEN] Default Dimension Priorities are high for Work Center and low for Item.
        // [GIVEN] Item with Routing "R" for Work Center.
        // [GIVEN] Default Dimension Value Codes are equal to "A1" for Item and "A2" for Work Center.
        // [GIVEN] Released Production Order for Item with Routing "R".
        CreateAndRefreshReleasedProdOrder(
          ProductionOrder, ItemNo, ItemDimValueCode, WorkCenterDimValueCode, DATABASE::"Work Center", DATABASE::Item);

        // [WHEN] Open Production Journal
        LibraryVariableStorage.Enqueue(ItemNo); // Enqueue for ModalPageHandlerForDim handler
        LibraryVariableStorage.Enqueue(WorkCenterDimValueCode); // Enqueue for ModalPageHandlerForDim handler
        LibraryManufacturing.OpenProductionJournal(ProductionOrder, FindProdOrderLineNo(ProductionOrder, ItemNo));

        // [THEN] Dimension Value Code in Production Journal Line is equal to "A2".
        // Checked on PageHandler named ModalPageHandlerForDim.
    end;

    [Test]
    [HandlerFunctions('ModalPageHandlerForDim')]
    [Scope('OnPrem')]
    procedure DefDimWithHighPriorityFromItemInheritedByProdJournal()
    var
        ProductionOrder: Record "Production Order";
        ItemNo: Code[20];
        ItemDimValueCode: Code[20];
        WorkCenterDimValueCode: Code[20];
    begin
        // [FEATURE] [Default Dimension Priority] [Production Journal]
        // [SCENARIO 378966] Default Dimension with high priority in Item should be inherited by Production Journal.
        Initialize();

        // [GIVEN] Default Dimension Priorities are high for Item and low for Work Center.
        // [GIVEN] Item with Routing "R" for Work Center.
        // [GIVEN] Default Dimension Value Codes are equal to "A1" for Item and "A2" for Work Center.
        // [GIVEN] Released Production Order for Item with Routing "R".
        CreateAndRefreshReleasedProdOrder(
          ProductionOrder, ItemNo, ItemDimValueCode, WorkCenterDimValueCode, DATABASE::Item, DATABASE::"Work Center");

        // [WHEN] Open Production Journal
        LibraryVariableStorage.Enqueue(ItemNo); // Enqueue for ModalPageHandlerForDim handler
        LibraryVariableStorage.Enqueue(ItemDimValueCode); // Enqueue for ModalPageHandlerForDim handler
        LibraryManufacturing.OpenProductionJournal(ProductionOrder, FindProdOrderLineNo(ProductionOrder, ItemNo));

        // [THEN] Dimension Value Code in Production Journal Line is equal to "A1".
        // Checked on PageHandler named ModalPageHandlerForDim.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ModifiedDefDimWithHighestPriorityFromServHeaderDoNotInheritedToServLine()
    var
        Dimension: Record Dimension;
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        CustomerNo: Code[20];
        ServiceItemNo: Code[20];
        ItemNo: Code[20];
        ExpectedDimValueCode: Code[20];
    begin
        // [FEATURE] [Default Dimension Priority]
        // [SCENARIO 375456] Default Dimension with highest priority modified in Service Item Line should not be inherited to Service Line

        Initialize();
        // [GIVEN] Default Dimension Priorities: Service Item = 1, Item = 2
        SetPairedDefaultDimPriorities(DATABASE::"Service Item", DATABASE::Item);
        LibraryDimension.CreateDimension(Dimension);

        // [GIVEN] Default Dimension "A1" for Customer, "A2" for Item, "A3" for Service Item
        CustomerNo := LibrarySales.CreateCustomerNo();
        ServiceItemNo := CreateServiceItem(CustomerNo, CreateServiceItemGroup());
        ItemNo := LibraryInventory.CreateItemNo();
        CreateDefDimWithNewDimValue(Dimension.Code, DATABASE::Customer, CustomerNo);
        ExpectedDimValueCode := CreateDefDimWithNewDimValue(Dimension.Code, DATABASE::Item, ItemNo);
        CreateDefDimWithNewDimValue(Dimension.Code, DATABASE::"Service Item", ServiceItemNo);

        // [GIVEN] Service Order with Customer and Service Item Line with Service Item and dimension "A3" replaced with "A"4
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, CustomerNo);
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItemNo);
        ServiceItemLine."Dimension Set ID" :=
          ChangeDimensionValueInDimensionSetID(ServiceItemLine."Dimension Set ID", Dimension.Code);
        ServiceItemLine.Modify(true);

        // [WHEN] Create Service Line with Item
        CreateServiceLineWithServItemLineNo(ServiceLine, ServiceHeader, ItemNo, ServiceItemLine."Line No.");

        // [THEN] "Dimension Set ID" in Service Line has dimension with value "A2"
        VerifyDimSetEntry(ServiceLine."Dimension Set ID", Dimension.Code, ExpectedDimValueCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DimFromServiceItemLineInheritedToServLine()
    var
        Dimension: Record Dimension;
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        ServiceItemNo: Code[20];
        CustomerNo: Code[20];
    begin
        // [SCENARIO 375646] Dimension from Service Item Line should be inherited to related Service Line

        Initialize();
        // [GIVEN] Service Order and Service Item Line with dimension "X"
        LibraryDimension.CreateDimension(Dimension);
        CustomerNo := LibrarySales.CreateCustomerNo();
        ServiceItemNo := CreateServiceItem(CustomerNo, CreateServiceItemGroup());
        CreateDefDimWithNewDimValue(Dimension.Code, DATABASE::"Service Item", ServiceItemNo);
        LibraryService.CreateServiceHeader(
          ServiceHeader, ServiceHeader."Document Type"::Order, CustomerNo);
        LibraryService.CreateServiceItemLine(
          ServiceItemLine, ServiceHeader, ServiceItemNo);

        // [THEN] Create Service Line related to Service Item Line
        CreateServiceLineWithServItemLineNo(
          ServiceLine, ServiceHeader, LibraryInventory.CreateItemNo(), ServiceItemLine."Line No.");

        // [WHEN] Service Line has dimension "X"
        ServiceLine.TestField("Dimension Set ID", ServiceItemLine."Dimension Set ID");
    end;

#if not CLEAN27
    [Test]
    [HandlerFunctions('ServiceOrderStatisticsMPH')]
    [Scope('OnPrem')]
    procedure NewDimOnInvoiceRoungingGLAccount()
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
        DimensionSetTreeNode: Record "Dimension Set Tree Node";
        ServiceOrder: TestPage "Service Order";
        InvoiceRoundingGLAccountNo: Code[20];
        DimValueId: Integer;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 380919] Dimension Set ID is not updated on Temporary Service Line on open Statistic page
        Initialize();

        // [GIVEN] Enabled "Invoice Rounding" in "Sales & Receivables Setup"
        // [GIVEN] "Invoice Rounding Precision" = 1
        InitRoundingSetup();

        // [GIVEN] Customer posting group "CPG" with Invoice Rounding G/L Account = "A"
        // [GIVEN] New Dimension Value "DV" added to "A"
        // [GIVEN] Customer "C" with posting group "CPG"
        // [GIVEN] Service order for "C" with line having = 123.17 (the amount causes invoice rounding calculation for the service line)
        LibrarySales.CreateCustomer(Customer);
        InvoiceRoundingGLAccountNo := CreateGLAccountForInvoiceRounding(Customer."Customer Posting Group");
        DimValueId := CreateDimOnGLAccount(InvoiceRoundingGLAccountNo);
        CreateServiceOrderWithItemLine(ServiceHeader, Customer."No.");

        // [WHEN] Open service order's statistics page
        ServiceOrder.OpenEdit();
        ServiceOrder.GotoRecord(ServiceHeader);
        ServiceOrder.Statistics.Invoke();
        ServiceOrder.Close();

        // [THEN] Dimension Set Tree Node for "DV" has not been created
        DimensionSetTreeNode.Init();
        DimensionSetTreeNode.SetRange("Dimension Value ID", DimValueId);
        Assert.RecordIsEmpty(DimensionSetTreeNode);
    end;
#endif
    [Test]
    [HandlerFunctions('ServiceOrderStatisticsMPH_NM')]
    [Scope('OnPrem')]
    procedure NewDimOnInvoiceRoungingGLAccountNM()
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
        DimensionSetTreeNode: Record "Dimension Set Tree Node";
        ServiceOrder: TestPage "Service Order";
        InvoiceRoundingGLAccountNo: Code[20];
        DimValueId: Integer;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 380919] Dimension Set ID is not updated on Temporary Service Line on open Statistic page
        Initialize();

        // [GIVEN] Enabled "Invoice Rounding" in "Sales & Receivables Setup"
        // [GIVEN] "Invoice Rounding Precision" = 1
        InitRoundingSetup();

        // [GIVEN] Customer posting group "CPG" with Invoice Rounding G/L Account = "A"
        // [GIVEN] New Dimension Value "DV" added to "A"
        // [GIVEN] Customer "C" with posting group "CPG"
        // [GIVEN] Service order for "C" with line having = 123.17 (the amount causes invoice rounding calculation for the service line)
        LibrarySales.CreateCustomer(Customer);
        InvoiceRoundingGLAccountNo := CreateGLAccountForInvoiceRounding(Customer."Customer Posting Group");
        DimValueId := CreateDimOnGLAccount(InvoiceRoundingGLAccountNo);
        CreateServiceOrderWithItemLine(ServiceHeader, Customer."No.");

        // [WHEN] Open service order's statistics page
        ServiceOrder.OpenEdit();
        ServiceOrder.GotoRecord(ServiceHeader);
        ServiceOrder.ServiceOrderStatistics.Invoke();
        ServiceOrder.Close();

        // [THEN] Dimension Set Tree Node for "DV" has not been created
        DimensionSetTreeNode.Init();
        DimensionSetTreeNode.SetRange("Dimension Value ID", DimValueId);
        Assert.RecordIsEmpty(DimensionSetTreeNode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostInvoiceWithRoundingGLAccAndMandatoryDimension()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        DimValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
        InvoiceRoundingGLAccountNo: Code[20];
    begin
        // [FEATURE] [Rounding]
        // [SCENARIO 204621] Dimensions are inherited from Service Header when post Service Order with Invoice Rounding Account and dimension setup "Code Mandatory"

        Initialize();

        // [GIVEN] Enabled "Invoice Rounding" in "Sales & Receivables Setup"
        // [GIVEN] "Invoice Rounding Precision" = 1
        InitRoundingSetup();

        // [GIVEN] Customer posting group with Invoice Rounding G/L Account = "A"
        // [GIVEN] Customer with posting group and dimension "DEPARTMENT" - "ADM"
        GeneralLedgerSetup.Get();
        LibrarySales.CreateCustomer(Customer);
        LibraryDimension.CreateDimensionValue(DimValue, GeneralLedgerSetup."Global Dimension 1 Code");
        LibraryDimension.CreateDefaultDimensionCustomer(
          DefaultDimension, Customer."No.", GeneralLedgerSetup."Global Dimension 1 Code", DimValue.Code);
        InvoiceRoundingGLAccountNo := CreateGLAccountForInvoiceRounding(Customer."Customer Posting Group");

        // [GIVEN] Dimension "DEPARTMENT" with "Value Posting" = "Code Mandatory" is set for Invoice Rounding G/L Account "A"
        CreateDimMandatoryOnGLAccount(InvoiceRoundingGLAccountNo, GeneralLedgerSetup."Global Dimension 1 Code");

        // [GIVEN] Service order with Customer and amount 123.17 (the amount causes invoice rounding calculation for the service line)
        CreateServiceOrderWithItemLine(ServiceHeader, Customer."No.");

        // [WHEN] Post Service Order
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [THEN] G/L Entry with G/L Account "A" is posted with Dimension "DEPARTMENT" - "ADM"
        VerifyGLEntryDimensionSetID(ServiceHeader."No.", InvoiceRoundingGLAccountNo, ServiceHeader."Dimension Set ID");
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure GlobalDimensionsFilledFromServiceContractUT()
    var
        ServiceHeader: Record "Service Header";
        ServiceContractHeader: Record "Service Contract Header";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 320423] Dimensions are inherited from Service Contract Header
        Initialize();

        // [GIVEN] Service Contract Header with 'Shortcut Dimension 1 Code' = "SDC001" and 'Shortcut Dimension 2 Code' = "SDC002"
        CreateAndSignServiceContractWithGlobalDim(ServiceContractHeader);
        ServiceContractHeader.TestField("Shortcut Dimension 1 Code");
        ServiceContractHeader.TestField("Shortcut Dimension 2 Code");

        // [WHEN] Validate 'Contract No.' in Service Order "X"
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ServiceContractHeader."Customer No.");
        ServiceHeader.Validate("Contract No.", ServiceContractHeader."Contract No.");

        // [THEN] Shortcut Dimensions are "SDC001" and "SDC002" for "X"
        ServiceHeader.TestField("Shortcut Dimension 1 Code", ServiceContractHeader."Shortcut Dimension 1 Code");
        ServiceHeader.TestField("Shortcut Dimension 2 Code", ServiceContractHeader."Shortcut Dimension 2 Code");
    end;

    [Test]
    procedure MissingDimInServiceItemLineDoesNotRestoreFromCustomerDefDim()
    var
        Dimension: array[2] of Record Dimension;
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        CustomerNo: Code[20];
        ServiceItemNo: Code[20];
        ExpectedDimValueCode: Code[20];
        UnexpectedDimValueCode: Code[20];
    begin
        // [SCENARIO 411591] Lacking dimension in service item line is not added to service line from customer when no dimension priority is defined.
        Initialize();

        // [GIVEN] Dimensions "D1" and "D2".
        LibraryDimension.CreateDimension(Dimension[1]);
        LibraryDimension.CreateDimension(Dimension[2]);

        // [GIVEN] Create customer "C", assign both dimensions.
        CustomerNo := LibrarySales.CreateCustomerNo();
        ExpectedDimValueCode := CreateDefDimWithNewDimValue(Dimension[1].Code, DATABASE::Customer, CustomerNo);
        UnexpectedDimValueCode := CreateDefDimWithNewDimValue(Dimension[2].Code, DATABASE::Customer, CustomerNo);

        // [GIVEN] Service order for customer "C".
        ServiceItemNo := CreateServiceItem(CustomerNo, CreateServiceItemGroup());
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, CustomerNo);
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItemNo);

        // [GIVEN] Delete dimension "D2" from the service item line.
        ServiceItemLine.Validate(
          "Dimension Set ID", LibraryDimension.DeleteDimSet(ServiceItemLine."Dimension Set ID", Dimension[2].Code));
        ServiceItemLine.Modify(true);

        // [WHEN] Create service line.
        CreateServiceLineWithServItemLineNo(ServiceLine, ServiceHeader, LibraryInventory.CreateItemNo(), ServiceItemLine."Line No.");

        // [THEN] The service line has dimension "D1" only.
        VerifyDimSetEntry(ServiceLine."Dimension Set ID", Dimension[1].Code, ExpectedDimValueCode);
        asserterror VerifyDimSetEntry(ServiceLine."Dimension Set ID", Dimension[2].Code, UnexpectedDimValueCode);
    end;

    [Test]
    procedure VerifyDimensionsAreNotReInitializedIfDefaultDimensionDoesntExist()
    var
        Customer: Record Customer;
        Location: Record Location;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceItemLine: Record "Service Item Line";
        DimensionValue: Record "Dimension Value";
        DimensionValue2: Record "Dimension Value";
        ServiceItemNo: Code[20];
    begin
        // [SCENARIO 455039] Verify dimensions are not re-initialized on validate field if default dimensions does not exist
        Initialize();

        // [GIVEN] Create Customer with default global dimension value
        CreateCustomerWithDefaultGlobalDimValue(Customer, DimensionValue);

        // [GIVEN] Create Service Item
        ServiceItemNo := CreateServiceItem(Customer."No.", CreateServiceItemGroup());

        // [GIVEN] Create Location without Default Dimension
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] Create Service Order
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItemNo);

        // [GIVEN] Create Service Line related to Service Item Line
        CreateServiceLineWithServItemLineNo(
          ServiceLine, ServiceHeader, LibraryInventory.CreateItemNo(), ServiceItemLine."Line No.");

        // [GIVEN] Update global dimension 1 on Service Line
        UpdateGlobalDimensionOnServiceLine(ServiceLine, DimensionValue2);

        // [WHEN] Change Location on Service Line
        UpdateLocationOnServiceLine(ServiceLine, Location.Code);

        // [VERIFY] Verify Dimensions are not re initialized on Service Line
        VerifyDimensionOnServiceLine(ServiceLine, DimensionValue2."Dimension Code");
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Service Posting - Dimensions");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Service Posting - Dimensions");

        // Create Demonstration Database.
        LibraryService.SetupServiceMgtNoSeries();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateGeneralPostingSetupData();

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Service Posting - Dimensions");
    end;

    local procedure CreateAndRefreshReleasedProdOrder(var ProductionOrder: Record "Production Order"; var ItemNo: Code[20]; var ItemDimValueCode: Code[20]; var WorkCenterDimValueCode: Code[20]; TableOfHighPriority: Integer; TableOfLowPriority: Integer)
    var
        SourceCodeSetup: Record "Source Code Setup";
        Item: Record Item;
        RoutingHeader: Record "Routing Header";
        WorkCenterNo: Code[20];
    begin
        SourceCodeSetup.Get();
        SetPairedDefaultDimPrioritiesForSourceCode(TableOfHighPriority, TableOfLowPriority, SourceCodeSetup."Production Journal");

        CreateCertifiedRoutingForWorkCenter(RoutingHeader, RoutingHeader.Type::Serial, WorkCenterNo);
        ItemNo := LibraryInventory.CreateItem(Item);
        Item.Validate("Routing No.", RoutingHeader."No.");
        Item.Modify(true);

        SetDifferentDefaultDimForItemAndWorkCenter(ItemNo, WorkCenterNo, ItemDimValueCode, WorkCenterDimValueCode);

        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released,
          ProductionOrder."Source Type"::Item, ItemNo, LibraryRandom.RandDec(100, 2));
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure CreateCertifiedRoutingForWorkCenter(var RoutingHeader: Record "Routing Header"; RoutingType: Option; var WorkCenterNo: Code[20])
    var
        WorkCenter: Record "Work Center";
        RoutingLine: Record "Routing Line";
    begin
        LibraryManufacturing.CreateWorkCenter(WorkCenter);

        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingType);
        LibraryManufacturing.CreateRoutingLineSetup(RoutingLine, RoutingHeader, WorkCenter."No.", LibraryUtility.GenerateGUID(), 0, 0);

        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
        WorkCenterNo := WorkCenter."No.";
    end;

    local procedure CreateHeaderResponsibility(var ServiceHeader: Record "Service Header"; CustomerNo: Code[20]; DimensionCode: Code[20]; DimensionValueResponsibility: Code[20])
    var
        ResponsibilityCenter: Record "Responsibility Center";
        DefaultDimension: Record "Default Dimension";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, CustomerNo);

        LibraryService.CreateResponsibilityCenter(ResponsibilityCenter);
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, DATABASE::"Responsibility Center", ResponsibilityCenter.Code, DimensionCode, DimensionValueResponsibility);
        ServiceHeader.Validate("Responsibility Center", ResponsibilityCenter.Code);
        ServiceHeader.Modify(true);
    end;

    local procedure CreateServiceHeaderBlockDim(var ServiceHeader: Record "Service Header"; var Dimension: Record Dimension)
    var
        Customer: Record Customer;
        DefaultDimension: Record "Default Dimension";
    begin
        // 1. Setup: Create Customer, Create Default Dimension for Customer.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        LibraryDimension.FindDimension(Dimension);
        LibraryDimension.CreateDefaultDimensionCustomer(
          DefaultDimension, Customer."No.", Dimension.Code, FindDimensionValue(Dimension.Code));

        // 2. Exercise: Create Service Header and line
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");
    end;

    local procedure CreateItemLineBlockDim(var ServiceItemLine: Record "Service Item Line"; var Dimension: Record Dimension; QtyToConsume: Boolean)
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
        Item: Record Item;
        ServiceItem: Record "Service Item";
        ServiceLine: Record "Service Line";
        DefaultDimension: Record "Default Dimension";
    begin
        // 1. Setup: Create Customer, Create Service Item, Create Default Dimension for Service Item.
        Initialize();
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceItem(ServiceItem, Customer."No.");
        LibraryDimension.FindDimension(Dimension);
        DeleteDefaultDimItem(Item."No.", Dimension.Code);

        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, DATABASE::"Service Item", ServiceItem."No.", Dimension.Code, FindDimensionValue(Dimension.Code));

        // 2. Exercise: Create Service Header, Service Item Line, Service Line for Type Item and update Quantity on Line.
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");

        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.");
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Validate("No.", Item."No.");
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10));  // Use Random because value is not important.
        if QtyToConsume then
            ServiceLine.Validate("Qty. to Consume", ServiceLine.Quantity);
        ServiceLine.Modify(true);

        UpdateDimSetIdOnItemLine(
          ServiceItemLine, DefaultDimension."Dimension Code",
          FindDifferentDimensionValue(DefaultDimension."Dimension Code", DefaultDimension."Dimension Value Code"));
    end;

    local procedure CreateLimitedDimHeader(var ServiceHeader: Record "Service Header"; var DimensionValueCombination: Record "Dimension Value Combination")
    var
        Customer: Record Customer;
        DimensionSetID: Integer;
    begin
        // 1. Setup: Create Customer.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        DimensionValueCombination.FindFirst();

        // 2. Exercise: Create Service Header and Document Dimension on Service Header.
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");
        DimensionSetID :=
          LibraryDimension.CreateDimSet(
            ServiceHeader."Dimension Set ID",
            DimensionValueCombination."Dimension 1 Code", DimensionValueCombination."Dimension 1 Value Code");
        DimensionSetID :=
          LibraryDimension.CreateDimSet(
            DimensionSetID,
            DimensionValueCombination."Dimension 2 Code", DimensionValueCombination."Dimension 2 Value Code");
        UpdateDimSetIdOnHeader(ServiceHeader, DimensionSetID);
    end;

    local procedure CreateLineBlockDimCost(var ServiceLine: Record "Service Line"; var Dimension: Record Dimension)
    var
        Customer: Record Customer;
        ServiceCost: Record "Service Cost";
    begin
        // 1. Setup: Create Customer.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        CreateServiceCost(ServiceCost);
        LibraryDimension.FindDimension(Dimension);

        // 2. Exercise: Create Service Header, Service Item Line, Service Line of Type Cost and Create Document Dimension for Type Cost.
        CreateServiceOrder(ServiceLine, ServiceLine.Type::Cost, ServiceCost.Code, Customer."No.", false);
        UpdateDimSetIdOnLine(
          ServiceLine,
          LibraryDimension.CreateDimSet(ServiceLine."Dimension Set ID", Dimension.Code, FindDimensionValue(Dimension.Code)));
    end;

    local procedure CreateLineBlockDimGLAccount(var ServiceLine: Record "Service Line"; var Dimension: Record Dimension)
    var
        Customer: Record Customer;
        GLAccount: Record "G/L Account";
        DefaultDimension: Record "Default Dimension";
    begin
        // 1. Setup: Create Customer, Create G/L Account and Create Default Dimension for G/L Account.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        CreateGLAccount(GLAccount);
        LibraryDimension.FindDimension(Dimension);
        LibraryDimension.CreateDefaultDimensionGLAcc(DefaultDimension, GLAccount."No.", Dimension.Code, FindDimensionValue(Dimension.Code));

        // 2. Exercise: Create Service Header, Service Item Line and Service Line of Type G/L Account.
        CreateServiceOrder(ServiceLine, ServiceLine.Type::"G/L Account", GLAccount."No.", Customer."No.", false);
    end;

    [HandlerFunctions('ConfirmMessageHandler')]
    local procedure CreateLineBlockDimItem(var ServiceLine: Record "Service Line"; var Dimension: Record Dimension; QtyToConsume: Boolean)
    var
        Customer: Record Customer;
        Item: Record Item;
        DefaultDimension: Record "Default Dimension";
    begin
        // 1. Setup: Create Customer, Create Item, Create Default Dimension for Item.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateItem(Item);
        LibraryDimension.FindDimension(Dimension);
        LibraryDimension.CreateDefaultDimensionItem(DefaultDimension, Item."No.", Dimension.Code, FindDimensionValue(Dimension.Code));

        // 2. Exercise: Create Service Header, Service Item Line and Service Line.
        CreateServiceOrder(ServiceLine, ServiceLine.Type::Item, Item."No.", Customer."No.", QtyToConsume);
    end;

    local procedure CreateLineBlockDimResource(var ServiceLine: Record "Service Line"; var Dimension: Record Dimension; QtyToConsume: Boolean)
    var
        Customer: Record Customer;
        DefaultDimension: Record "Default Dimension";
    begin
        // 1. Setup: Create Customer, Create Resource, Create Default Dimension for Resource.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        LibraryDimension.FindDimension(Dimension);
        LibraryDimension.CreateDefaultDimensionResource(
          DefaultDimension, CreateResource(), Dimension.Code, FindDimensionValue(Dimension.Code));

        // 2. Exercise: Create Service Header, Service Item Line and Service Line of Type Resource.
        CreateServiceOrder(ServiceLine, ServiceLine.Type::Resource, DefaultDimension."No.", Customer."No.", QtyToConsume);
    end;

    local procedure CreateOrderWithCustomerDim(var ServiceLine: Record "Service Line"; var DefaultDimension: Record "Default Dimension")
    var
        Item: Record Item;
        Customer: Record Customer;
        Dimension: Record Dimension;
    begin
        // Create Customer, Create Item, Create Default Dimension for Item and Customer, Create Service Header, Service Item
        // Line and Service Line of Type Item.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateItem(Item);
        LibraryDimension.FindDimension(Dimension);
        LibraryDimension.CreateDefaultDimensionCustomer(
          DefaultDimension, Customer."No.", Dimension.Code, FindDimensionValue(Dimension.Code));

        CreateServiceOrder(ServiceLine, ServiceLine.Type::Item, Item."No.", Customer."No.", false);
    end;

    local procedure CreateServiceCost(var ServiceCost: Record "Service Cost")
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.FindGLAccount(GLAccount);
        LibraryService.CreateServiceCost(ServiceCost);
        ServiceCost.Validate("Account No.", GLAccount."No.");
        ServiceCost.Modify(true);
    end;

    local procedure CreateServiceDocumentLines(var ServiceLine: Record "Service Line"; var ServiceItemLine: Record "Service Item Line"; var DimensionValue: Record "Dimension Value"; ServiceHeader: Record "Service Header"; DimensionCode: Code[20]) ServiceItemGroupCode: Code[10]
    var
        Item: Record Item;
        DefaultDimension: Record "Default Dimension";
        ServiceCost: Record "Service Cost";
        GLAccount: Record "G/L Account";
        ServiceItemNo: Code[20];
        ResourceNo: Code[20];
    begin
        DimensionValue.Next();
        ServiceItemGroupCode := CreateServiceItemGroup();
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, DATABASE::"Service Item Group", ServiceItemGroupCode, DimensionCode, DimensionValue.Code);

        DimensionValue.Next();
        ServiceItemNo := CreateServiceItem(ServiceHeader."Customer No.", ServiceItemGroupCode);
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, DATABASE::"Service Item", ServiceItemNo, DimensionCode, DimensionValue.Code);

        DimensionValue.Next();
        LibraryInventory.CreateItem(Item);
        LibraryDimension.CreateDefaultDimensionItem(DefaultDimension, Item."No.", DimensionCode, DimensionValue.Code);

        DimensionValue.Next();
        ResourceNo := CreateResource();
        LibraryDimension.CreateDefaultDimensionResource(DefaultDimension, ResourceNo, DimensionCode, DimensionValue.Code);

        DimensionValue.Next();
        CreateGLAccount(GLAccount);
        LibraryDimension.CreateDefaultDimensionGLAcc(DefaultDimension, GLAccount."No.", DimensionCode, DimensionValue.Code);

        CreateServiceCost(ServiceCost);

        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItemNo);
        CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.", ServiceItemLine."Line No.");
        CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Resource, ResourceNo, ServiceItemLine."Line No.");
        CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::"G/L Account", GLAccount."No.", ServiceItemLine."Line No.");
        CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Cost, ServiceCost.Code, ServiceItemLine."Line No.");
    end;

    local procedure CreateServiceHeaderWithDim(var ServiceHeader: Record "Service Header"; var DefaultDimension: Record "Default Dimension"; ValuePosting: Enum "Default Dimension Value Posting Type")
    var
        Customer: Record Customer;
        Dimension: Record Dimension;
    begin
        // Create Customer, Create Default Dimension for Customer and Create Service Header.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        LibraryDimension.FindDimension(Dimension);
        if ValuePosting = DefaultDimension."Value Posting"::"No Code" then
            LibraryDimension.CreateDefaultDimensionCustomer(DefaultDimension, Customer."No.", Dimension.Code, '')
        else
            LibraryDimension.CreateDefaultDimensionCustomer(DefaultDimension, Customer."No.",
              Dimension.Code, FindDimensionValue(Dimension.Code));

        DefaultDimension.Validate("Value Posting", ValuePosting);
        DefaultDimension.Modify(true);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");
    end;

    local procedure CreateServiceLine(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header"; Type: Enum "Service Line Type"; No: Code[20]; ServiceItemLineNo: Integer)
    begin
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, Type, No);
        ServiceLine.Validate("Service Item Line No.", ServiceItemLineNo);
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10));  // Use Random because value is not important.
        ServiceLine.Modify(true);
    end;

    local procedure CreateServiceOrder(var ServiceLine: Record "Service Line"; Type: Enum "Service Line Type"; No: Code[20]; CustomerNo: Code[20]; QtyToConsume: Boolean)
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
    begin
        // Create Service Header, Service item Line and Service Line.
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, CustomerNo);
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, Type, No);
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10));  // Use Random because value is not important.
        if QtyToConsume then
            ServiceLine.Validate("Qty. to Consume", ServiceLine.Quantity);
        ServiceLine.Modify(true);
    end;

    local procedure CreateServiceOrderCost(var ServiceLine: Record "Service Line")
    var
        Customer: Record Customer;
        ServiceCost: Record "Service Cost";
    begin
        // 1. Setup: Create Customer.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        CreateServiceCost(ServiceCost);

        // 2. Exercise: Create Service Header, Service Item Line and Service Line of Type Cost.
        CreateServiceOrder(ServiceLine, ServiceLine.Type::Cost, ServiceCost.Code, Customer."No.", false);
    end;

    local procedure CreateServiceOrderGLAccount(var ServiceLine: Record "Service Line")
    var
        Customer: Record Customer;
        GLAccount: Record "G/L Account";
    begin
        // 1. Setup: Create Customer, G/L Account.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        CreateGLAccount(GLAccount);

        // 2. Exercise: Create Service Header, Service Item Line and Service Line of Type Cost.
        CreateServiceOrder(ServiceLine, ServiceLine.Type::"G/L Account", GLAccount."No.", Customer."No.", false);
    end;

    local procedure CreateServiceOrderGLDim(var ServiceHeader: Record "Service Header"; ValuePosting: Enum "Default Dimension Value Posting Type")
    var
        Item: Record Item;
        Customer: Record Customer;
        Dimension: Record Dimension;
        ServiceLine: Record "Service Line";
        GLAccount: Record "G/L Account";
        DefaultDimension: Record "Default Dimension";
        ServiceItemLine: Record "Service Item Line";
        ResourceNo: Code[20];
    begin
        // Create Customer, Resource, Item, G/L Account and Assign Default Dimension for all with Value Posting "No Code",
        // Create Service Header, Service Item Line, Service Line of Type Item, Resource, G/L Account.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        ResourceNo := CreateResource();
        LibraryDimension.FindDimension(Dimension);
        LibraryDimension.CreateDefaultDimensionResource(DefaultDimension, ResourceNo, Dimension.Code, FindDimensionValue(Dimension.Code));
        ModifyDefaultDimension(DefaultDimension, ValuePosting);

        LibraryInventory.CreateItem(Item);
        Dimension.Next();
        LibraryDimension.CreateDefaultDimensionItem(DefaultDimension, Item."No.", Dimension.Code, FindDimensionValue(Dimension.Code));
        ModifyDefaultDimension(DefaultDimension, ValuePosting);

        CreateGLAccount(GLAccount);
        Dimension.Next();
        LibraryDimension.CreateDefaultDimensionGLAcc(DefaultDimension, GLAccount."No.", Dimension.Code, FindDimensionValue(Dimension.Code));
        ModifyDefaultDimension(DefaultDimension, ValuePosting);

        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.", ServiceItemLine."Line No.");
        CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Resource, ResourceNo, ServiceItemLine."Line No.");
        CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::"G/L Account", GLAccount."No.", ServiceItemLine."Line No.");
    end;

    local procedure CreateServiceOrderItem(var ServiceLine: Record "Service Line"; QtyToConsume: Boolean)
    var
        Customer: Record Customer;
        Item: Record Item;
    begin
        // 1. Setup: Create Customer and Item.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateItem(Item);

        // 2. Exercise: Create Service Header, Service Item Line and Service Line for Type Item.
        CreateServiceOrder(ServiceLine, ServiceLine.Type::Item, Item."No.", Customer."No.", QtyToConsume);
    end;

    local procedure CreateServiceOrderResource(var ServiceLine: Record "Service Line"; QtyToConsume: Boolean)
    var
        Customer: Record Customer;
    begin
        // 1. Setup: Create Customer.
        Initialize();
        LibrarySales.CreateCustomer(Customer);

        // 2. Exercise: Create Service Header, Service Item Line and Service Line of Type Resource.
        CreateServiceOrder(ServiceLine, ServiceLine.Type::Resource, CreateResource(), Customer."No.", QtyToConsume);
    end;

    local procedure CreateServiceOrderWithDim(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; Consume: Boolean)
    var
        Item: Record Item;
        GLAccount: Record "G/L Account";
        Customer: Record Customer;
        Dimension: Record Dimension;
        DefaultDimension: Record "Default Dimension";
        ServiceCost: Record "Service Cost";
        ServiceItemLine: Record "Service Item Line";
        ServiceItemNo: Code[20];
        ResourceNo: Code[20];
    begin
        // Create Customer, Service Item, Item, Resource, G/L Account, Cost, assign Default Dimensions on all, Create Service Header,
        // Service Item Line and Service Line of Type Item, Resource, G/L Account and Cost as per Consume parameter.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        LibraryDimension.FindDimension(Dimension);
        LibraryDimension.CreateDefaultDimensionCustomer(
          DefaultDimension, Customer."No.", Dimension.Code, FindDimensionValue(Dimension.Code));

        ServiceItemNo := CreateServiceItem(Customer."No.", '');
        Dimension.Next();
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, DATABASE::"Service Item", ServiceItemNo, Dimension.Code, FindDimensionValue(Dimension.Code));

        LibraryInventory.CreateItem(Item);
        Dimension.Next();
        LibraryDimension.CreateDefaultDimensionItem(DefaultDimension, Item."No.", Dimension.Code, FindDimensionValue(Dimension.Code));

        ResourceNo := CreateResource();
        LibraryDimension.CreateDefaultDimensionResource(DefaultDimension, ResourceNo, Dimension.Code, FindDimensionValue(Dimension.Code));

        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItemNo);
        CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.", ServiceItemLine."Line No.");
        CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Resource, ResourceNo, ServiceItemLine."Line No.");
        if Consume then
            exit;
        CreateGLAccount(GLAccount);
        LibraryDimension.CreateDefaultDimensionGLAcc(
          DefaultDimension, GLAccount."No.", Dimension.Code, FindDimensionValue(Dimension.Code));
        CreateServiceCost(ServiceCost);
        CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::"G/L Account", GLAccount."No.", ServiceItemLine."Line No.");
        CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Cost, ServiceCost.Code, ServiceItemLine."Line No.");
    end;

    local procedure CreateServiceOrderWithItem(var ServiceItemLine: Record "Service Item Line"; QtyToConsume: Boolean)
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceItem: Record "Service Item";
        ItemNo: Code[20];
    begin
        // Create Customer, Service Item, Create Service Header, Service Item Line and Service Line.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceItem(ServiceItem, Customer."No.");
        ItemNo := LibraryInventory.CreateItemNo();

        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, ItemNo);
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Validate("No.", ItemNo);
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10));  // Use Random because value is not important.
        if QtyToConsume then
            ServiceLine.Validate("Qty. to Consume", ServiceLine.Quantity);
        ServiceLine.Modify(true);
    end;

    local procedure CreateServiceOrderWithItemLine(var ServiceHeader: Record "Service Header"; CustNo: Code[20])
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        LibraryService.CreateServiceHeader(
          ServiceHeader, ServiceHeader."Document Type"::Order, CustNo);
        LibraryService.CreateServiceItemLine(
          ServiceItemLine, ServiceHeader, CreateServiceItem(CustNo, CreateServiceItemGroup()));
        CreateServiceLineWithServItemLineNo(
          ServiceLine, ServiceHeader, LibraryInventory.CreateItemNo(), ServiceItemLine."Line No.");
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10));
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDecInRange(100, 200, 2));
        ServiceLine.Modify(true);
    end;

    local procedure CreateServiceLineWithServItemLineNo(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header"; ItemNo: Code[20]; ItemLineNo: Integer)
    begin
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, ItemNo);
        ServiceLine.Validate("Service Item Line No.", ItemLineNo);
        ServiceLine.Validate("No.", ItemNo);
        ServiceLine.Modify(true);
    end;

    local procedure CreateStandardServiceCodeDim(var StandardServiceCode: Record "Standard Service Code")
    var
        Item: Record Item;
        GLAccount: Record "G/L Account";
        ServiceCost: Record "Service Cost";
        Dimension: Record Dimension;
        StandardServiceLine: Record "Standard Service Line";
    begin
        LibraryService.CreateStandardServiceCode(StandardServiceCode);

        LibraryInventory.CreateItem(Item);
        LibraryDimension.FindDimension(Dimension);
        CreateStandardServiceLineDim(StandardServiceCode.Code, StandardServiceLine.Type::Item, Item."No.", Dimension.Code);

        Dimension.Next();
        CreateStandardServiceLineDim(StandardServiceCode.Code, StandardServiceLine.Type::Resource, CreateResource(), Dimension.Code);

        CreateServiceCost(ServiceCost);
        Dimension.Next();
        CreateStandardServiceLineDim(StandardServiceCode.Code, StandardServiceLine.Type::Cost, ServiceCost.Code, Dimension.Code);

        CreateGLAccount(GLAccount);
        Dimension.Next();
        CreateStandardServiceLineDim(StandardServiceCode.Code, StandardServiceLine.Type::"G/L Account", GLAccount."No.", Dimension.Code);
    end;

    local procedure CreateStandardServiceLineDim(StandardServiceCode: Code[10]; StandardServiceLineType: Enum "Service Line Type"; StandardServiceLineNo: Code[20]; DimensionCode: Code[20]): Integer
    var
        StandardServiceLine: Record "Standard Service Line";
    begin
        CreateStandardServiceLine(StandardServiceLine, StandardServiceCode, StandardServiceLineType, StandardServiceLineNo);
        UpdateStandardServiceLineDim(
          StandardServiceLine,
          LibraryDimension.CreateDimSet(StandardServiceLine."Dimension Set ID", DimensionCode, FindDimensionValue(DimensionCode)));
        exit(StandardServiceLine."Dimension Set ID");
    end;

    local procedure CreateStandardServiceLine(var StandardServiceLine: Record "Standard Service Line"; StandardServiceCode: Code[10]; Type: Enum "Service Line Type"; No: Code[20])
    begin
        LibraryService.CreateStandardServiceLine(StandardServiceLine, StandardServiceCode);
        StandardServiceLine.Validate(Type, Type);
        StandardServiceLine.Validate("No.", No);
        StandardServiceLine.Validate(Quantity, LibraryRandom.RandInt(10));  // Use Random because value is not important.
        StandardServiceLine.Modify(true);
    end;

    local procedure CreateAndSignServiceContract(CustomerNo: Code[20]): Code[20]
    var
        ServiceContractHeader: Record "Service Contract Header";
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
    begin
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, CustomerNo);
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        UpdateAndSignServiceContract(ServiceContractHeader);
        exit(ServiceContractHeader."Contract No.");
    end;

    local procedure CreateAndSignServiceContractWithGlobalDim(var ServiceContractHeader: Record "Service Contract Header")
    var
        CustomerNo: Code[20];
    begin
        CustomerNo := LibrarySales.CreateCustomerNo();
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, CustomerNo);
        CreateServiceContractGlobalDimension(ServiceContractHeader);
        UpdateAndSignServiceContract(ServiceContractHeader);
    end;

    local procedure CreateDefaultDimensionPriority(var DefaultDimensionPriority: Record "Default Dimension Priority")
    var
        SourceCodeSetup: Record "Source Code Setup";
    begin
        // Use 1,2,3,4,5 Values for Dimension Priority.
        SourceCodeSetup.Get();

        DefaultDimensionPriority.SetRange("Source Code", SourceCodeSetup."Service Management");
        DefaultDimensionPriority.DeleteAll(true);
        LibraryDimension.CreateDefaultDimensionPriority(DefaultDimensionPriority, SourceCodeSetup."Service Management", DATABASE::Item);
        UpdatePriority(DefaultDimensionPriority, 1);

        LibraryDimension.CreateDefaultDimensionPriority(
          DefaultDimensionPriority, SourceCodeSetup."Service Management", DATABASE::"Service Item Group");
        UpdatePriority(DefaultDimensionPriority, 2);

        LibraryDimension.CreateDefaultDimensionPriority(
          DefaultDimensionPriority, SourceCodeSetup."Service Management", DATABASE::"Service Item");
        UpdatePriority(DefaultDimensionPriority, 3);

        LibraryDimension.CreateDefaultDimensionPriority(
          DefaultDimensionPriority, SourceCodeSetup."Service Management", DATABASE::"Responsibility Center");
        UpdatePriority(DefaultDimensionPriority, 4);

        LibraryDimension.CreateDefaultDimensionPriority(
          DefaultDimensionPriority, SourceCodeSetup."Service Management", DATABASE::Customer);
        UpdatePriority(DefaultDimensionPriority, 5);

        LibraryDimension.CreateDefaultDimensionPriority(
          DefaultDimensionPriority, SourceCodeSetup."Service Management", DATABASE::"G/L Account");
        UpdatePriority(DefaultDimensionPriority, 1);

        LibraryDimension.CreateDefaultDimensionPriority(
          DefaultDimensionPriority, SourceCodeSetup."Service Management", DATABASE::Resource);
        UpdatePriority(DefaultDimensionPriority, 1);
    end;

    local procedure CreateDefDimWithNewDimValue(DimensionCode: Code[20]; SourceID: Integer; SourceNo: Code[20]): Code[20]
    var
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
    begin
        LibraryDimension.CreateDimensionValue(DimensionValue, DimensionCode);
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, SourceID, SourceNo, DimensionValue."Dimension Code",
          DimensionValue.Code);
        exit(DimensionValue.Code);
    end;

    local procedure CreateDimOnGLAccount(GLAccountNo: Code[20]): Integer
    var
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
    begin
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryDimension.CreateDefaultDimensionGLAcc(
          DefaultDimension, GLAccountNo, DimensionValue."Dimension Code", DimensionValue.Code);
        DefaultDimension.Validate("Value Posting", DefaultDimension."Value Posting"::"Same Code");
        DefaultDimension.Modify();
        exit(DimensionValue."Dimension Value ID");
    end;

    local procedure CreateDimMandatoryOnGLAccount(GLAccountNo: Code[20]; DimensionCode: Code[20])
    var
        DefaultDimension: Record "Default Dimension";
    begin
        LibraryDimension.CreateDefaultDimensionGLAcc(
          DefaultDimension, GLAccountNo, DimensionCode, '');
        DefaultDimension.Validate("Value Posting", DefaultDimension."Value Posting"::"Code Mandatory");
        DefaultDimension.Modify();
    end;

    local procedure CreateItemResourceGLDefaultDim(var CustomerNo: Code[20]; var ItemNo: Code[20]; var ResourceNo: Code[20]; var GLAccountNo: Code[20])
    var
        Customer: Record Customer;
        Dimension: Record Dimension;
        Item: Record Item;
        GLAccount: Record "G/L Account";
        DefaultDimension: Record "Default Dimension";
    begin
        // Create Customer, Item, Resource, G/L Account and assign Default Dimension on all.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateItem(Item);
        LibraryDimension.FindDimension(Dimension);
        LibraryDimension.CreateDefaultDimensionItem(DefaultDimension, Item."No.", Dimension.Code, FindDimensionValue(Dimension.Code));

        ResourceNo := CreateResource();
        LibraryDimension.CreateDefaultDimensionResource(DefaultDimension, ResourceNo, Dimension.Code, FindDimensionValue(Dimension.Code));

        CreateGLAccount(GLAccount);
        LibraryDimension.CreateDefaultDimensionGLAcc(DefaultDimension, GLAccount."No.", Dimension.Code, FindDimensionValue(Dimension.Code));
        CustomerNo := Customer."No.";
        ItemNo := Item."No.";
        GLAccountNo := GLAccount."No.";
    end;

    local procedure CreateGLAccount(var GLAccount: Record "G/L Account")
    begin
        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        GLAccount.Validate("Direct Posting", true);
        GLAccount.Modify(true);
    end;

    local procedure CreateGLAccountForInvoiceRounding(CustomerPostingGroupCode: Code[20]): Code[20]
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        CustomerPostingGroup.Get(CustomerPostingGroupCode);
        CustomerPostingGroup.Validate("Invoice Rounding Account", LibraryERM.CreateGLAccountWithSalesSetup());
        CustomerPostingGroup.Modify(true);

        exit(CustomerPostingGroup."Invoice Rounding Account");
    end;

    local procedure CreateLimitedDimItemLine(var DimensionValueCombination: Record "Dimension Value Combination"; ServiceItemLine: Record "Service Item Line")
    var
        DimensionSetID: Integer;
    begin
        DimensionValueCombination.FindFirst();
        DimensionSetID :=
          LibraryDimension.CreateDimSet(
            ServiceItemLine."Dimension Set ID", DimensionValueCombination."Dimension 1 Code",
            DimensionValueCombination."Dimension 1 Value Code");
        DimensionSetID :=
          LibraryDimension.CreateDimSet(
            DimensionSetID, DimensionValueCombination."Dimension 2 Code", DimensionValueCombination."Dimension 2 Value Code");
        ServiceItemLine.UpdateAllLineDim(DimensionSetID, ServiceItemLine."Dimension Set ID");
        ServiceItemLine.Validate("Dimension Set ID", DimensionSetID);
        ServiceItemLine.Modify(true);
    end;

    local procedure CreateLimitedDimServiceLine(var DimensionValueCombination: Record "Dimension Value Combination"; ServiceLine: Record "Service Line")
    var
        DimensionSetID: Integer;
    begin
        DimensionValueCombination.FindFirst();
        DimensionSetID :=
          LibraryDimension.CreateDimSet(
            ServiceLine."Dimension Set ID",
            DimensionValueCombination."Dimension 1 Code", DimensionValueCombination."Dimension 1 Value Code");
        DimensionSetID :=
          LibraryDimension.CreateDimSet(
            DimensionSetID, DimensionValueCombination."Dimension 2 Code", DimensionValueCombination."Dimension 2 Value Code");
        ServiceLine.Validate("Dimension Set ID", DimensionSetID);
        ServiceLine.Modify(true);
    end;

    local procedure CreateResource(): Code[20]
    begin
        exit(LibraryResource.CreateResourceNo());
    end;

    local procedure CreateServiceItem(CustomerNo: Code[20]; ServiceItemGroupCode: Code[10]): Code[20]
    var
        ServiceItem: Record "Service Item";
    begin
        LibraryService.CreateServiceItem(ServiceItem, CustomerNo);
        ServiceItem.Validate("Service Item Group Code", ServiceItemGroupCode);
        ServiceItem.Modify(true);
        exit(ServiceItem."No.");
    end;

    local procedure CreateServiceOrderWithLines(var ServiceLine: Record "Service Line"; CustomerNo: Code[20]; ItemNo: Code[20]; ResourceNo: Code[20]; GLAccountNo: Code[20])
    var
        ServiceHeader: Record "Service Header";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, CustomerNo);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, ItemNo);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Resource, ResourceNo);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::"G/L Account", GLAccountNo);
    end;

    local procedure CreateCustomerWithDefGlobalDimensions(var ShortcutDimCode: array[2] of Code[20]): Code[20]
    var
        Customer: Record Customer;
        DefaultDimension: Record "Default Dimension";
        DimSetID: Integer;
    begin
        LibrarySales.CreateCustomer(Customer);
        InitDimSetIDWithGlobalDimensions(DimSetID, ShortcutDimCode);
        LibraryDimension.CreateDefaultDimensionCustomer(
          DefaultDimension, Customer."No.", LibraryERM.GetGlobalDimensionCode(1), ShortcutDimCode[1]);
        LibraryDimension.CreateDefaultDimensionCustomer(
          DefaultDimension, Customer."No.", LibraryERM.GetGlobalDimensionCode(2), ShortcutDimCode[2]);
        exit(Customer."No.");
    end;

    local procedure CreateServiceItemGroup(): Code[10]
    var
        ServiceItemGroup: Record "Service Item Group";
    begin
        LibraryService.CreateServiceItemGroup(ServiceItemGroup);
        exit(ServiceItemGroup.Code);
    end;

    local procedure CreateServiceContractGlobalDimension(var ServiceContractHeader: Record "Service Contract Header")
    var
        DimensionValue: Record "Dimension Value";
        DimensionCode: Code[20];
        i: Integer;
    begin
        for i := 1 to 2 do begin
            DimensionCode := LibraryERM.GetGlobalDimensionCode(i);
            LibraryDimension.CreateDimensionValue(DimensionValue, DimensionCode);
            LibraryDimension.CreateServiceContractDimension(ServiceContractHeader, DimensionCode, DimensionValue.Code);
        end;
    end;

    local procedure InitDimSetIDWithGlobalDimensions(var DimSetID: Integer; var ShortcutDimCode: array[2] of Code[20])
    begin
        ShortcutDimCode[1] := FindDimensionValue(LibraryERM.GetGlobalDimensionCode(1));
        ShortcutDimCode[2] := FindDimensionValue(LibraryERM.GetGlobalDimensionCode(2));
        DimSetID :=
          LibraryDimension.CreateDimSet(0, LibraryERM.GetGlobalDimensionCode(1), ShortcutDimCode[1]);
        DimSetID :=
          LibraryDimension.CreateDimSet(DimSetID, LibraryERM.GetGlobalDimensionCode(2), ShortcutDimCode[2]);
    end;

    local procedure InitRoundingSetup()
    begin
        LibraryERM.SetInvRoundingPrecisionLCY(1);
        LibrarySales.SetInvoiceRounding(true);
        LibrarySales.SetCalcInvDiscount(false);
        LibrarySales.SetStockoutWarning(false);
    end;

    local procedure DeleteDefaultDimItem(No: Code[20]; DimensionCode: Code[20])
    var
        DefaultDimension: Record "Default Dimension";
    begin
        DefaultDimension.SetRange("Table ID", DATABASE::Item);
        DefaultDimension.SetRange("No.", No);
        DefaultDimension.SetRange("Dimension Code", DimensionCode);
        DefaultDimension.DeleteAll(true);
    end;

    local procedure DeleteServiceLineDimensions(ServiceHeader: Record "Service Header")
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.FindSet();
        repeat
            ServiceLine.Validate("Dimension Set ID", 0);
            ServiceLine.Modify(true);
        until ServiceLine.Next() = 0;
    end;

    local procedure FilterDefaultDimension(var DefaultDimension: Record "Default Dimension"; Type: Enum "Service Line Type"; No: Code[20])
    begin
        if Type = Type::Item then
            DefaultDimension.SetRange("Table ID", DATABASE::Item);
        if Type = Type::Resource then
            DefaultDimension.SetRange("Table ID", DATABASE::Resource);
        if Type = Type::"G/L Account" then
            DefaultDimension.SetRange("Table ID", DATABASE::"G/L Account");
        DefaultDimension.SetRange("No.", No);
        DefaultDimension.FindFirst();
    end;

    local procedure FindCustLedgerEntryDimSetID(DocumentNo: Code[20]): Integer
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        CustLedgerEntry.FindFirst();
        exit(CustLedgerEntry."Dimension Set ID");
    end;

    local procedure FindDimensionValue(DimensionCode: Code[20]): Code[20]
    var
        DimensionValue: Record "Dimension Value";
    begin
        LibraryDimension.FindDimensionValue(DimensionValue, DimensionCode);
        exit(DimensionValue.Code);
    end;

    local procedure FindDifferentDimensionValue(DimensionCode: Code[20]; "Code": Code[20]): Code[20]
    var
        DimensionValue: Record "Dimension Value";
    begin
        DimensionValue.SetFilter(Code, '<>%1', Code);
        LibraryDimension.FindDimensionValue(DimensionValue, DimensionCode);
        exit(DimensionValue.Code);
    end;

    local procedure FindGLEntryDimSetID(GLAccountNo: Code[20]; DocumenNo: Code[20]): Integer
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Invoice);
        GLEntry.SetRange("Document No.", DocumenNo);
        GLEntry.FindFirst();
        exit(GLEntry."Dimension Set ID");
    end;

    local procedure FindItemLedgerEntryDimSetID(ServiceShipmentLine: Record "Service Shipment Line"): Integer
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Document Type", ItemLedgerEntry."Document Type"::"Service Shipment");
        ItemLedgerEntry.SetRange("Document No.", ServiceShipmentLine."Document No.");
        ItemLedgerEntry.SetRange("Document Line No.", ServiceShipmentLine."Line No.");
        ItemLedgerEntry.FindFirst();
        exit(ItemLedgerEntry."Dimension Set ID");
    end;

    local procedure FindProdOrderLineNo(ProductionOrder: Record "Production Order"; ItemNo: Code[20]): Integer
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.SetRange("Item No.", ItemNo);
        ProdOrderLine.FindFirst();
        exit(ProdOrderLine."Line No.");
    end;

    local procedure FindResLedgerEntryDimSetID(ResourceNo: Code[20]; DocumentNo: Code[20]): Integer
    var
        ResLedgerEntry: Record "Res. Ledger Entry";
    begin
        ResLedgerEntry.SetRange("Resource No.", ResourceNo);
        ResLedgerEntry.SetRange("Entry Type", ResLedgerEntry."Entry Type"::Sale);
        ResLedgerEntry.SetRange("Document No.", DocumentNo);
        ResLedgerEntry.FindFirst();
        exit(ResLedgerEntry."Dimension Set ID");
    end;

    local procedure FindServiceShipmentHeader(var ServiceShipmentHeader: Record "Service Shipment Header"; OrderNo: Code[20])
    begin
        ServiceShipmentHeader.SetRange("Order No.", OrderNo);
        ServiceShipmentHeader.FindFirst();
    end;

    local procedure FindServiceShipmentLine(var ServiceShipmentLine: Record "Service Shipment Line"; ServiceLine: Record "Service Line")
    begin
        ServiceShipmentLine.SetRange("Order No.", ServiceLine."Document No.");
        ServiceShipmentLine.SetRange("Order Line No.", ServiceLine."Line No.");
        ServiceShipmentLine.FindFirst();
    end;

    local procedure FindServiceItemLine(var ServiceItemLine: Record "Service Item Line"; ServiceLine: Record "Service Line")
    begin
        ServiceItemLine.SetRange("Document Type", ServiceLine."Document Type");
        ServiceItemLine.SetRange("Document No.", ServiceLine."Document No.");
        ServiceItemLine.FindFirst();
    end;

    local procedure FindServiceLine(var ServiceLine: Record "Service Line")
    begin
        ServiceLine.SetRange("Document Type", ServiceLine."Document Type");
        ServiceLine.SetRange("Document No.", ServiceLine."Document No.");
        ServiceLine.FindSet();
    end;

    local procedure FindValueEntryDimSetID(ServiceShipmentLine: Record "Service Shipment Line"): Integer
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Document Type", ValueEntry."Document Type"::"Service Shipment");
        ValueEntry.SetRange("Document No.", ServiceShipmentLine."Document No.");
        ValueEntry.SetRange("Document Line No.", ServiceShipmentLine."Line No.");
        ValueEntry.FindFirst();
        exit(ValueEntry."Dimension Set ID");
    end;

    local procedure ModifyDefaultDimension(var DefaultDimension: Record "Default Dimension"; ValuePosting: Enum "Default Dimension Value Posting Type")
    begin
        // Remove dimension value if value posting is No Code
        if ValuePosting = DefaultDimension."Value Posting"::"No Code" then
            DefaultDimension.Validate("Dimension Value Code", '');

        DefaultDimension.Validate("Value Posting", ValuePosting);
        DefaultDimension.Modify(true);
    end;

    local procedure ModifyDimension(var Dimension: Record Dimension; Blocked: Boolean)
    begin
        Dimension.Validate(Blocked, Blocked);
        Dimension.Modify(true);
    end;

    local procedure SetDifferentDefaultDimForItemAndWorkCenter(ItemNo: Code[20]; WorkCenterNo: Code[20]; var ItemDimValueCode: Code[20]; var WorkCenterDimValueCode: Code[20])
    var
        Dimension: Record Dimension;
    begin
        LibraryDimension.CreateDimension(Dimension);
        ItemDimValueCode := CreateDefDimWithNewDimValue(Dimension.Code, DATABASE::Item, ItemNo);
        WorkCenterDimValueCode := CreateDefDimWithNewDimValue(Dimension.Code, DATABASE::"Work Center", WorkCenterNo);
    end;

    local procedure SetPairedDefaultDimPriorities(HighPriorityTableID: Integer; LowPriorityTableID: Integer)
    var
        SourceCodeSetup: Record "Source Code Setup";
    begin
        SourceCodeSetup.Get();
        SetPairedDefaultDimPrioritiesForSourceCode(HighPriorityTableID, LowPriorityTableID, SourceCodeSetup."Service Management");
    end;

    local procedure SetPairedDefaultDimPrioritiesForSourceCode(HighPriorityTableID: Integer; LowPriorityTableID: Integer; SourceCode: Code[10])
    var
        DefaultDimensionPriority: Record "Default Dimension Priority";
    begin
        DefaultDimensionPriority.SetRange("Source Code", SourceCode);
        DefaultDimensionPriority.DeleteAll(true);

        LibraryDimension.CreateDefaultDimensionPriority(DefaultDimensionPriority, SourceCode, HighPriorityTableID);
        UpdatePriority(DefaultDimensionPriority, 1);
        LibraryDimension.CreateDefaultDimensionPriority(DefaultDimensionPriority, SourceCode, LowPriorityTableID);
        UpdatePriority(DefaultDimensionPriority, 2);
    end;

    local procedure RollbackValuePosting(OrderNo: Code[20])
    var
        ServiceShipmentHeader: Record "Service Shipment Header";
        ServiceShipmentLine: Record "Service Shipment Line";
        DefaultDimension: Record "Default Dimension";
    begin
        FindServiceShipmentHeader(ServiceShipmentHeader, OrderNo);
        ServiceShipmentLine.SetRange("Document No.", ServiceShipmentHeader."No.");
        ServiceShipmentLine.FindSet();
        repeat
            FilterDefaultDimension(DefaultDimension, ServiceShipmentLine.Type, ServiceShipmentLine."No.");
            ModifyDefaultDimension(DefaultDimension, DefaultDimension."Value Posting"::" ");
        until ServiceShipmentLine.Next() = 0;
    end;

    local procedure UpdateServiceContract(var ServiceContractHeader: Record "Service Contract Header")
    begin
        ServiceContractHeader.CalcFields("Calcd. Annual Amount");
        ServiceContractHeader.Validate("Annual Amount", ServiceContractHeader."Calcd. Annual Amount");
        ServiceContractHeader.Modify(true);
    end;

    local procedure UpdateServiceContractLineDate(var ServiceContractLine: Record "Service Contract Line"; ServiceContractHeader: Record "Service Contract Header")
    begin
        ServiceContractLine.Validate("Next Planned Service Date", ServiceContractHeader."Starting Date");
        ServiceContractLine.Validate("Starting Date", ServiceContractHeader."Starting Date");
        ServiceContractLine.Modify(true);
    end;

    local procedure UpdateServiceHeader(var ServiceHeader: Record "Service Header"; SalespersonCode: Code[20]; ResponsibilityCenterCode: Code[10]; ContractNo: Code[20]; ServiceOrderType: Code[10])
    begin
        ServiceHeader.Validate("Contract No.", ContractNo);
        ServiceHeader.Validate("Responsibility Center", ResponsibilityCenterCode);
        ServiceHeader.Validate("Service Order Type", ServiceOrderType);
        ServiceHeader.Validate("Salesperson Code", SalespersonCode);
        ServiceHeader.Modify(true);
    end;

    local procedure UpdateDimSetIdOnHeader(var ServiceHeader: Record "Service Header"; DimensionSetID: Integer)
    begin
        ServiceHeader.Validate("Dimension Set ID", DimensionSetID);
        ServiceHeader.Modify(true);
    end;

    local procedure UpdateDimSetIdOnItemLine(var ServiceItemLine: Record "Service Item Line"; DimensionCode: Code[20]; DimensionValueCode: Code[20])
    var
        DimensionSetID: Integer;
    begin
        DimensionSetID := LibraryDimension.EditDimSet(ServiceItemLine."Dimension Set ID", DimensionCode, DimensionValueCode);
        ServiceItemLine.UpdateAllLineDim(DimensionSetID, ServiceItemLine."Dimension Set ID");
        ServiceItemLine.Validate("Dimension Set ID", DimensionSetID);
        ServiceItemLine.Modify(true);
    end;

    local procedure UpdateDimSetIdOnLine(var ServiceLine: Record "Service Line"; DimensionSetID: Integer)
    begin
        ServiceLine.Validate("Dimension Set ID", DimensionSetID);
        ServiceLine.Modify(true);
    end;

    local procedure UpdateDefaultDimForItem(ItemNo: Code[20])
    var
        DefaultDimension: Record "Default Dimension";
    begin
        LibraryDimension.FindDefaultDimension(DefaultDimension, DATABASE::Item, ItemNo);
        DefaultDimension.Validate(
          "Dimension Value Code", FindDifferentDimensionValue(DefaultDimension."Dimension Code", DefaultDimension."Dimension Value Code"));
        DefaultDimension.Modify(true);
    end;

    local procedure UpdateDefaultDimForGLAccount(GLAccountNo: Code[20])
    var
        DefaultDimension: Record "Default Dimension";
    begin
        LibraryDimension.FindDefaultDimension(DefaultDimension, DATABASE::"G/L Account", GLAccountNo);
        DefaultDimension.Validate(
          "Dimension Value Code", FindDifferentDimensionValue(DefaultDimension."Dimension Code", DefaultDimension."Dimension Value Code"));
        DefaultDimension.Modify(true);
    end;

    local procedure UpdateDefaultDimForResource(ResourceNo: Code[20])
    var
        DefaultDimension: Record "Default Dimension";
    begin
        LibraryDimension.FindDefaultDimension(DefaultDimension, DATABASE::Resource, ResourceNo);
        DefaultDimension.Validate(
          "Dimension Value Code", FindDifferentDimensionValue(DefaultDimension."Dimension Code", DefaultDimension."Dimension Value Code"));
        DefaultDimension.Modify(true);
    end;

    local procedure UpdatePartialQtyToConsume(ServiceLine: Record "Service Line")
    begin
        FindServiceLine(ServiceLine);
        repeat
            ServiceLine.Validate("Qty. to Consume", ServiceLine.Quantity * LibraryUtility.GenerateRandomFraction());
            ServiceLine.Modify(true);
        until ServiceLine.Next() = 0;
    end;

    local procedure UpdatePartialQtyToShip(ServiceLine: Record "Service Line")
    begin
        FindServiceLine(ServiceLine);
        repeat
            ServiceLine.Validate("Qty. to Ship", ServiceLine.Quantity * LibraryUtility.GenerateRandomFraction());
            ServiceLine.Modify(true);
        until ServiceLine.Next() = 0;
    end;

    local procedure UpdatePartialQtyToInvoice(ServiceLine: Record "Service Line")
    begin
        FindServiceLine(ServiceLine);
        repeat
            ServiceLine.Validate("Qty. to Invoice", ServiceLine."Quantity Shipped" * LibraryUtility.GenerateRandomFraction());
            ServiceLine.Modify(true);
        until ServiceLine.Next() = 0;
    end;

    local procedure UpdatePriority(var DefaultDimensionPriority: Record "Default Dimension Priority"; Priority: Integer)
    begin
        DefaultDimensionPriority.Validate(Priority, Priority);
        DefaultDimensionPriority.Modify(true);
    end;

    local procedure UpdateStandardServiceLineDim(var StandardServiceLine: Record "Standard Service Line"; DimensionSetID: Integer)
    begin
        StandardServiceLine.Validate("Dimension Set ID", DimensionSetID);
        StandardServiceLine.Modify(true);
    end;

    local procedure UpdateAndSignServiceContract(var ServiceContractHeader: Record "Service Contract Header")
    var
        ServiceContractLine: Record "Service Contract Line";
        ServiceItem: Record "Service Item";
        SignServContractDoc: Codeunit SignServContractDoc;
    begin
        LibraryService.CreateServiceItem(ServiceItem, ServiceContractHeader."Customer No.");
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");
        ServiceContractLine.Validate("Line Value", LibraryRandom.RandInt(100));  // Use Random because value is not important.
        ServiceContractLine.Modify(true);
        UpdateServiceContract(ServiceContractHeader);
        UpdateServiceContractLineDate(ServiceContractLine, ServiceContractHeader);
        SignServContractDoc.SignContract(ServiceContractHeader);
    end;

    local procedure ChangeDimensionValueInDimensionSetID(DimensionSetID: Integer; DimensionCode: Code[20]): Integer
    var
        DimValue: Record "Dimension Value";
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        DimMgt: Codeunit DimensionManagement;
    begin
        DimMgt.GetDimensionSet(TempDimSetEntry, DimensionSetID);
        TempDimSetEntry.SetRange("Dimension Code", DimensionCode);
        TempDimSetEntry.FindFirst();
        LibraryDimension.CreateDimensionValue(DimValue, DimensionCode);
        TempDimSetEntry.Validate("Dimension Value Code", DimValue.Code);
        TempDimSetEntry.Modify(true);
        exit(DimMgt.GetDimensionSetID(TempDimSetEntry));
    end;

    local procedure CreateDimensionAndDimensionValue(var Dimension: Record Dimension; var DimensionValue: Record "Dimension Value")
    begin
        // creates a new Dimension and a related new DimensionValue where Dimension.Code=DimensionValue."Dimension Code"
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
    end;

    local procedure CombineDimensions(var ServItemLine: Record "Service Item Line"; StdServLine: Record "Standard Service Line")
    var
        DimensionManagement: Codeunit DimensionManagement;
        DimensionSetIDArr: array[10] of Integer;
    begin
        DimensionSetIDArr[1] := ServItemLine."Dimension Set ID";
        DimensionSetIDArr[2] := StdServLine."Dimension Set ID";

        ServItemLine."Dimension Set ID" :=
          DimensionManagement.GetCombinedDimensionSetID(
            DimensionSetIDArr, ServItemLine."Shortcut Dimension 1 Code", ServItemLine."Shortcut Dimension 2 Code");
    end;

    local procedure VerifyBlockDimOnServiceHeader(ServiceHeader: Record "Service Header"; DimensionCode: Code[20])
    begin
        Assert.AreEqual(
          StrSubstNo(
            BlockDimensionOnServiceHeader, ServiceHeader."Document Type", ServiceHeader."No.", DimensionCode),
          GetLastErrorText, UnknownError);
    end;

    local procedure VerifyBlockDimOnItemLine(ServiceItemLine: Record "Service Item Line"; DimensionCode: Code[20])
    begin
        Assert.AreEqual(
          StrSubstNo(
            BlockDimensionOnItemLine, ServiceItemLine."Document Type", ServiceItemLine."Document No.", ServiceItemLine."Line No.",
            DimensionCode),
          GetLastErrorText,
          UnknownError);
    end;

    local procedure VerifyBlockDimOnLine(ServiceLine: Record "Service Line"; DimensionCode: Code[20])
    begin
        Assert.AreEqual(
          StrSubstNo(
            BlockDimensionOnItemLine, ServiceLine."Document Type", ServiceLine."Document No.", ServiceLine."Line No.",
            DimensionCode),
          GetLastErrorText,
          UnknownError);
    end;

    local procedure VerifyLimitedDimCombination(ServiceHeader: Record "Service Header"; DimensionValueCombination: Record "Dimension Value Combination")
    begin
        Assert.AreEqual(
          StrSubstNo(
            LimitedDimensionCombination, ServiceHeader."Document Type", ServiceHeader."No.", DimensionValueCombination."Dimension 1 Code",
            DimensionValueCombination."Dimension 1 Value Code", DimensionValueCombination."Dimension 2 Code",
            DimensionValueCombination."Dimension 2 Value Code"),
          GetLastErrorText,
          UnknownError);
    end;

    local procedure VerifyLimitedDimItemLine(ServiceItemLine: Record "Service Item Line"; DimensionValueCombination: Record "Dimension Value Combination")
    begin
        Assert.AreEqual(
          StrSubstNo(
            LimitedDimensionItemLine, ServiceItemLine."Document Type", ServiceItemLine."Document No.", ServiceItemLine."Line No.",
            DimensionValueCombination."Dimension 1 Code", DimensionValueCombination."Dimension 1 Value Code",
            DimensionValueCombination."Dimension 2 Code", DimensionValueCombination."Dimension 2 Value Code"),
          GetLastErrorText,
          UnknownError);
    end;

    local procedure VerifyLimitedDimLine(ServiceLine: Record "Service Line"; DimensionValueCombination: Record "Dimension Value Combination")
    begin
        Assert.AreEqual(
          StrSubstNo(
            LimitedDimensionItemLine, ServiceLine."Document Type", ServiceLine."Document No.", ServiceLine."Line No.",
            DimensionValueCombination."Dimension 1 Code", DimensionValueCombination."Dimension 1 Value Code",
            DimensionValueCombination."Dimension 2 Code", DimensionValueCombination."Dimension 2 Value Code"),
          GetLastErrorText,
          UnknownError);
    end;

    local procedure VerifyDimForCost(ServiceLine: Record "Service Line")
    var
        DefaultDimension: Record "Default Dimension";
    begin
        ServiceLine.SetRange(Type, ServiceLine.Type::Cost);
        FindServiceLine(ServiceLine);

        LibraryDimension.FindDefaultDimension(DefaultDimension, DATABASE::"Responsibility Center", ServiceLine."Responsibility Center");
        VerifyDimSetEntry(ServiceLine."Dimension Set ID", DefaultDimension."Dimension Code", DefaultDimension."Dimension Value Code");
    end;

    local procedure VerifyDimForCustomer(ServiceHeader: Record "Service Header"; CustomerNo: Code[20])
    var
        DefaultDimension: Record "Default Dimension";
    begin
        LibraryDimension.FindDefaultDimension(DefaultDimension, DATABASE::Customer, CustomerNo);
        VerifyDimSetEntry(ServiceHeader."Dimension Set ID", DefaultDimension."Dimension Code", DefaultDimension."Dimension Value Code");
    end;

    local procedure VerifyDimForCustomerLederEntry(OrderNo: Code[20])
    var
        DefaultDimension: Record "Default Dimension";
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        ServiceInvoiceHeader.SetRange("Order No.", OrderNo);
        ServiceInvoiceHeader.FindFirst();
        LibraryDimension.FindDefaultDimension(DefaultDimension, DATABASE::Customer, ServiceInvoiceHeader."Customer No.");
        VerifyDimSetEntry(
          FindCustLedgerEntryDimSetID(ServiceInvoiceHeader."No."), DefaultDimension."Dimension Code",
          DefaultDimension."Dimension Value Code");
    end;

    local procedure VerifyDimForGLEntry(ServiceHeader: Record "Service Header")
    var
        DefaultDimension: Record "Default Dimension";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceLine: Record "Service Line";
    begin
        ServiceInvoiceHeader.SetRange("Order No.", ServiceHeader."No.");
        ServiceInvoiceHeader.FindFirst();
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.SetRange(Type, ServiceLine.Type::"G/L Account");
        ServiceLine.FindFirst();

        LibraryDimension.FindDefaultDimension(DefaultDimension, DATABASE::Customer, ServiceInvoiceHeader."Customer No.");
        VerifyDimSetEntry(
          FindGLEntryDimSetID(ServiceLine."No.", ServiceInvoiceHeader."No."), DefaultDimension."Dimension Code",
          DefaultDimension."Dimension Value Code");
    end;

    local procedure VerifyDimForInvoiceHeader(ServiceHeader: Record "Service Header")
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        DefaultDimension: Record "Default Dimension";
    begin
        ServiceInvoiceHeader.SetRange("Order No.", ServiceHeader."No.");
        ServiceInvoiceHeader.FindFirst();
        LibraryDimension.FindDefaultDimension(DefaultDimension, DATABASE::Customer, ServiceHeader."Customer No.");
        VerifyDimSetEntry(
          ServiceInvoiceHeader."Dimension Set ID", DefaultDimension."Dimension Code", DefaultDimension."Dimension Value Code");
    end;

    local procedure VerifyDimForInvoiceLine(ServiceLine: Record "Service Line")
    var
        DefaultDimension: Record "Default Dimension";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceInvoiceLine: Record "Service Invoice Line";
    begin
        ServiceLine.SetFilter(Type, '<>%1', ServiceLine.Type::Cost);
        FindServiceLine(ServiceLine);
        ServiceInvoiceHeader.SetRange("Order No.", ServiceLine."Document No.");
        ServiceInvoiceHeader.FindFirst();
        ServiceInvoiceLine.SetRange("Document No.", ServiceInvoiceHeader."No.");
        repeat
            ServiceInvoiceLine.SetRange("Line No.", ServiceLine."Line No.");
            ServiceInvoiceLine.FindFirst();
            FilterDefaultDimension(DefaultDimension, ServiceLine.Type, ServiceLine."No.");
            VerifyDimSetEntry(
              ServiceInvoiceLine."Dimension Set ID", DefaultDimension."Dimension Code", DefaultDimension."Dimension Value Code");
        until ServiceLine.Next() = 0;
    end;

    local procedure VerifyDimForItemLedgerEntry(ServiceLine: Record "Service Line")
    var
        DefaultDimension: Record "Default Dimension";
        ServiceShipmentLine: Record "Service Shipment Line";
        DimensionSetID: Integer;
    begin
        ServiceLine.SetRange(Type, ServiceShipmentLine.Type::Item);
        FindServiceLine(ServiceLine);
        FindServiceShipmentLine(ServiceShipmentLine, ServiceLine);
        DimensionSetID := FindItemLedgerEntryDimSetID(ServiceShipmentLine);

        LibraryDimension.FindDefaultDimension(DefaultDimension, DATABASE::Item, ServiceShipmentLine."No.");
        VerifyDimSetEntry(DimensionSetID, DefaultDimension."Dimension Code", DefaultDimension."Dimension Value Code");

        LibraryDimension.FindDefaultDimension(DefaultDimension, DATABASE::Customer, ServiceShipmentLine."Customer No.");
        VerifyDimSetEntry(DimensionSetID, DefaultDimension."Dimension Code", DefaultDimension."Dimension Value Code");
    end;

    local procedure VerifyDimForResponsibility(ServiceHeader: Record "Service Header"; ResponsibilityCenterCode: Code[10])
    var
        DefaultDimension: Record "Default Dimension";
    begin
        LibraryDimension.FindDefaultDimension(DefaultDimension, DATABASE::"Responsibility Center", ResponsibilityCenterCode);
        VerifyDimSetEntry(ServiceHeader."Dimension Set ID", DefaultDimension."Dimension Code", DefaultDimension."Dimension Value Code");
    end;

    local procedure VerifyDimForResourceLederEntry(ServiceLine: Record "Service Line")
    var
        DefaultDimension: Record "Default Dimension";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        DimensionSetID: Integer;
    begin
        ServiceLine.SetRange(Type, ServiceLine.Type::Resource);
        FindServiceLine(ServiceLine);
        ServiceInvoiceHeader.SetRange("Order No.", ServiceLine."Document No.");
        ServiceInvoiceHeader.FindFirst();
        DimensionSetID := FindResLedgerEntryDimSetID(ServiceLine."No.", ServiceInvoiceHeader."No.");

        LibraryDimension.FindDefaultDimension(DefaultDimension, DATABASE::Customer, ServiceInvoiceHeader."Customer No.");
        VerifyDimSetEntry(DimensionSetID, DefaultDimension."Dimension Code", DefaultDimension."Dimension Value Code");

        LibraryDimension.FindDefaultDimension(DefaultDimension, DATABASE::Resource, ServiceLine."No.");
        VerifyDimSetEntry(DimensionSetID, DefaultDimension."Dimension Code", DefaultDimension."Dimension Value Code");
    end;

    local procedure VerifyDimForSalesperson(ServiceHeader: Record "Service Header"; SalespersonCode: Code[20])
    var
        DefaultDimension: Record "Default Dimension";
    begin
        LibraryDimension.FindDefaultDimension(DefaultDimension, DATABASE::"Salesperson/Purchaser", SalespersonCode);
        VerifyDimSetEntry(ServiceHeader."Dimension Set ID", DefaultDimension."Dimension Code", DefaultDimension."Dimension Value Code");
    end;

    local procedure VerifyDimForServiceLederEntry(ServiceLine: Record "Service Line")
    var
        DefaultDimension: Record "Default Dimension";
        ServiceLedgerEntry: Record "Service Ledger Entry";
    begin
        FindServiceLine(ServiceLine);
        ServiceLedgerEntry.SetRange("Service Order No.", ServiceLine."Document No.");
        repeat
            FilterDefaultDimension(DefaultDimension, ServiceLine.Type, ServiceLine."No.");
            ServiceLedgerEntry.SetRange("Document Line No.", ServiceLine."Line No.");
            ServiceLedgerEntry.FindSet();
            repeat
                VerifyDimSetEntry(
                  ServiceLedgerEntry."Dimension Set ID", DefaultDimension."Dimension Code", DefaultDimension."Dimension Value Code");
            until ServiceLedgerEntry.Next() = 0;
        until ServiceLine.Next() = 0;

        LibraryDimension.FindDefaultDimension(DefaultDimension, DATABASE::Customer, ServiceLine."Customer No.");
        VerifyDimSetEntry(
          ServiceLedgerEntry."Dimension Set ID", DefaultDimension."Dimension Code", DefaultDimension."Dimension Value Code");
    end;

    local procedure VerifyDimForShipmentHeader(ServiceHeader: Record "Service Header")
    var
        ServiceShipmentHeader: Record "Service Shipment Header";
        DefaultDimension: Record "Default Dimension";
    begin
        FindServiceShipmentHeader(ServiceShipmentHeader, ServiceHeader."No.");
        LibraryDimension.FindDefaultDimension(DefaultDimension, DATABASE::Customer, ServiceHeader."Customer No.");
        VerifyDimSetEntry(
          ServiceShipmentHeader."Dimension Set ID", DefaultDimension."Dimension Code", DefaultDimension."Dimension Value Code");
    end;

    local procedure VerifyDimForShipmentItemLine(ServiceHeader: Record "Service Header")
    var
        ServiceShipmentHeader: Record "Service Shipment Header";
        ServiceShipmentItemLine: Record "Service Shipment Item Line";
        DefaultDimension: Record "Default Dimension";
    begin
        FindServiceShipmentHeader(ServiceShipmentHeader, ServiceHeader."No.");
        ServiceShipmentItemLine.SetRange("No.", ServiceShipmentHeader."No.");
        ServiceShipmentItemLine.FindFirst();

        LibraryDimension.FindDefaultDimension(DefaultDimension, DATABASE::Customer, ServiceHeader."Customer No.");
        VerifyDimSetEntry(
          ServiceShipmentItemLine."Dimension Set ID", DefaultDimension."Dimension Code", DefaultDimension."Dimension Value Code");

        LibraryDimension.FindDefaultDimension(DefaultDimension, DATABASE::"Service Item", ServiceShipmentItemLine."Service Item No.");
        VerifyDimSetEntry(
          ServiceShipmentItemLine."Dimension Set ID", DefaultDimension."Dimension Code", DefaultDimension."Dimension Value Code");
    end;

    local procedure VerifyDimForShipmentLine(ServiceLine: Record "Service Line")
    var
        DefaultDimension: Record "Default Dimension";
        ServiceShipmentLine: Record "Service Shipment Line";
    begin
        ServiceLine.SetFilter(Type, '<>%1', ServiceLine.Type::Cost);
        FindServiceLine(ServiceLine);
        ServiceShipmentLine.SetRange("Order No.", ServiceLine."Document No.");
        repeat
            ServiceShipmentLine.SetRange("Order Line No.", ServiceLine."Line No.");
            ServiceShipmentLine.FindFirst();
            FilterDefaultDimension(DefaultDimension, ServiceShipmentLine.Type, ServiceShipmentLine."No.");
            VerifyDimSetEntry(
              ServiceShipmentLine."Dimension Set ID", DefaultDimension."Dimension Code", DefaultDimension."Dimension Value Code");
        until ServiceLine.Next() = 0;
    end;

    local procedure VerifyDimFromStandardCode(StandardServiceCode: Code[10]; OrderNo: Code[20])
    var
        StandardServiceLine: Record "Standard Service Line";
        ServiceLine: Record "Service Line";
    begin
        StandardServiceLine.SetRange("Standard Service Code", StandardServiceCode);
        StandardServiceLine.FindSet();
        ServiceLine.SetRange("Document No.", OrderNo);
        repeat
            ServiceLine.SetRange("Line No.", StandardServiceLine."Line No.");
            ServiceLine.FindFirst();
            ServiceLine.TestField("Dimension Set ID", StandardServiceLine."Dimension Set ID");
        until StandardServiceLine.Next() = 0;
    end;

    local procedure VerifyDimShipmentLineCustomer(ServiceLine: Record "Service Line")
    var
        DefaultDimension: Record "Default Dimension";
        ServiceShipmentLine: Record "Service Shipment Line";
    begin
        FindServiceLine(ServiceLine);
        LibraryDimension.FindDefaultDimension(DefaultDimension, DATABASE::Customer, ServiceLine."Customer No.");
        ServiceShipmentLine.SetRange("Order No.", ServiceLine."Document No.");
        repeat
            ServiceShipmentLine.SetRange("Order Line No.", ServiceLine."Line No.");
            ServiceShipmentLine.FindFirst();
            VerifyDimSetEntry(
              ServiceShipmentLine."Dimension Set ID", DefaultDimension."Dimension Code", DefaultDimension."Dimension Value Code");
        until ServiceLine.Next() = 0;
    end;

    local procedure VerifyDimForOrderType(ServiceHeader: Record "Service Header"; ServiceOrderType: Code[10])
    var
        DefaultDimension: Record "Default Dimension";
    begin
        LibraryDimension.FindDefaultDimension(DefaultDimension, DATABASE::"Service Order Type", ServiceOrderType);
        VerifyDimSetEntry(ServiceHeader."Dimension Set ID", DefaultDimension."Dimension Code", DefaultDimension."Dimension Value Code");
    end;

    local procedure VerifyDimForContract(ServiceHeader: Record "Service Header")
    var
        ServiceContractHeader: Record "Service Contract Header";
        DimensionSetEntry2: Record "Dimension Set Entry";
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        ServiceContractHeader.SetRange("Contract No.", ServiceHeader."Contract No.");
        ServiceContractHeader.FindFirst();
        LibraryDimension.FindDimensionSetEntry(DimensionSetEntry, ServiceContractHeader."Dimension Set ID");

        DimensionSetEntry2.SetRange("Dimension Code", DimensionSetEntry."Dimension Code");
        LibraryDimension.FindDimensionSetEntry(DimensionSetEntry2, ServiceHeader."Dimension Set ID");
        DimensionSetEntry2.TestField("Dimension Value Code", DimensionSetEntry."Dimension Value Code");
    end;

    local procedure VerifyDimForServiceItem(ServiceItemLine: Record "Service Item Line"; ServiceItemNo: Code[20])
    var
        DefaultDimension: Record "Default Dimension";
    begin
        LibraryDimension.FindDefaultDimension(DefaultDimension, DATABASE::"Service Item", ServiceItemNo);
        VerifyDimSetEntry(ServiceItemLine."Dimension Set ID", DefaultDimension."Dimension Code", DefaultDimension."Dimension Value Code");
    end;

    local procedure VerifyDimForServiceItemGrp(ServiceItemLine: Record "Service Item Line"; ServiceItemGroupCode: Code[10])
    var
        DefaultDimension: Record "Default Dimension";
    begin
        LibraryDimension.FindDefaultDimension(DefaultDimension, DATABASE::"Service Item Group", ServiceItemGroupCode);
        VerifyDimSetEntry(ServiceItemLine."Dimension Set ID", DefaultDimension."Dimension Code", DefaultDimension."Dimension Value Code");
    end;

    local procedure VerifyDimForValueEntry(ServiceLine: Record "Service Line")
    var
        DefaultDimension: Record "Default Dimension";
        ServiceShipmentLine: Record "Service Shipment Line";
        DimensionSetID: Integer;
    begin
        FindServiceLine(ServiceLine);
        FindServiceShipmentLine(ServiceShipmentLine, ServiceLine);
        DimensionSetID := FindValueEntryDimSetID(ServiceShipmentLine);

        LibraryDimension.FindDefaultDimension(DefaultDimension, DATABASE::Item, ServiceShipmentLine."No.");
        VerifyDimSetEntry(DimensionSetID, DefaultDimension."Dimension Code", DefaultDimension."Dimension Value Code");

        LibraryDimension.FindDefaultDimension(DefaultDimension, DATABASE::Customer, ServiceShipmentLine."Customer No.");
        VerifyDimSetEntry(DimensionSetID, DefaultDimension."Dimension Code", DefaultDimension."Dimension Value Code");
    end;

    local procedure VerifyDimOnServiceLine(ServiceLine: Record "Service Line")
    var
        DefaultDimension: Record "Default Dimension";
    begin
        ServiceLine.SetFilter(Type, '<>%1', ServiceLine.Type::Cost);
        FindServiceLine(ServiceLine);
        repeat
            FilterDefaultDimension(DefaultDimension, ServiceLine.Type, ServiceLine."No.");
            VerifyDimSetEntry(ServiceLine."Dimension Set ID", DefaultDimension."Dimension Code", DefaultDimension."Dimension Value Code");
        until ServiceLine.Next() = 0;
    end;

    local procedure VerifyDimInvoiceLineCustomer(ServiceLine: Record "Service Line")
    var
        DefaultDimension: Record "Default Dimension";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceInvoiceLine: Record "Service Invoice Line";
    begin
        ServiceLine.SetFilter(Type, '<>%1', ServiceLine.Type::Cost);
        FindServiceLine(ServiceLine);
        ServiceInvoiceHeader.SetRange("Order No.", ServiceLine."Document No.");
        ServiceInvoiceHeader.FindFirst();
        LibraryDimension.FindDefaultDimension(DefaultDimension, DATABASE::Customer, ServiceInvoiceHeader."Customer No.");
        ServiceInvoiceLine.SetRange("Document No.", ServiceInvoiceHeader."No.");
        repeat
            ServiceInvoiceLine.SetRange("Line No.", ServiceLine."Line No.");
            ServiceInvoiceLine.FindFirst();
            VerifyDimSetEntry(
              ServiceInvoiceLine."Dimension Set ID", DefaultDimension."Dimension Code", DefaultDimension."Dimension Value Code");
        until ServiceLine.Next() = 0;
    end;

    local procedure VerifyDimOnServiceLineCost(ServiceLine: Record "Service Line")
    begin
        FindServiceLine(ServiceLine);
        repeat
            ServiceLine.TestField("Dimension Set ID", 0);
        until ServiceLine.Next() = 0;
    end;

    local procedure VerifyDimSetEntry(DimensionSetID: Integer; DimensionCode: Code[20]; DimensionValueCode: Code[20])
    var
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        DimensionSetEntry.SetRange("Dimension Code", DimensionCode);
        LibraryDimension.FindDimensionSetEntry(DimensionSetEntry, DimensionSetID);
        DimensionSetEntry.TestField("Dimension Value Code", DimensionValueCode);
    end;

    local procedure VerifyPriorityDimOnServiceLine(ServiceLine: Record "Service Line")
    var
        DefaultDimension: Record "Default Dimension";
    begin
        FindServiceLine(ServiceLine);
        LibraryDimension.FindDefaultDimension(DefaultDimension, DATABASE::Customer, ServiceLine."Customer No.");
        repeat
            VerifyDimSetEntry(ServiceLine."Dimension Set ID", DefaultDimension."Dimension Code", DefaultDimension."Dimension Value Code");
        until ServiceLine.Next() = 0;
    end;

    local procedure VerifyServiceShipmentHeader(ServiceHeader: Record "Service Header")
    var
        ServiceShipmentHeader: Record "Service Shipment Header";
    begin
        FindServiceShipmentHeader(ServiceShipmentHeader, ServiceHeader."No.");
        ServiceShipmentHeader.TestField("Customer No.", ServiceHeader."Customer No.");
    end;

    local procedure VerifyServiceLedgerEntryDimSetID(ServiceOrderNo: Code[20]; DimSetID: Integer)
    var
        ServiceLedgerEntry: Record "Service Ledger Entry";
    begin
        ServiceLedgerEntry.SetRange("Document Type", ServiceLedgerEntry."Document Type"::Shipment);
        ServiceLedgerEntry.SetRange("Service Order No.", ServiceOrderNo);
        ServiceLedgerEntry.FindSet();
        Assert.AreEqual(DimSetID, ServiceLedgerEntry."Dimension Set ID", DimensionSetIDErr);
        ServiceLedgerEntry.Next();
        Assert.AreEqual(DimSetID, ServiceLedgerEntry."Dimension Set ID", DimensionSetIDErr);
    end;

    local procedure VerifyGLEntryDimensionSetID(ServiceOrderNo: Code[20]; GLAccNo: Code[20]; ExpectedDimSetID: Integer)
    var
        ServiceInvHeader: Record "Service Invoice Header";
        GLEntry: Record "G/L Entry";
    begin
        ServiceInvHeader.SetRange("Order No.", ServiceOrderNo);
        ServiceInvHeader.FindFirst();
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Invoice);
        GLEntry.SetRange("Document No.", ServiceInvHeader."No.");
        GLEntry.SetRange("G/L Account No.", GLAccNo);
        GLEntry.FindFirst();
        GLEntry.TestField("Dimension Set ID", ExpectedDimSetID);
    end;

    local procedure VerifyDimensionOnServiceLine(var ServiceLine: Record "Service Line"; DimensionCode: Code[20])
    var
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        ServiceLine.Get(ServiceLine."Document Type", ServiceLine."Document No.", ServiceLine."Line No.");
        DimensionSetEntry.SetRange("Dimension Set ID", ServiceLine."Dimension Set ID");
        DimensionSetEntry.SetRange("Dimension Code", DimensionCode);
        DimensionSetEntry.FindFirst();
        Assert.AreEqual(
            DimensionCode, DimensionSetEntry."Dimension Code",
            StrSubstNo(DimensionValueCodeError, DimensionSetEntry.FieldCaption("Dimension Code"), DimensionCode));
    end;

    local procedure UpdateLocationOnServiceLine(var ServiceLine: Record "Service Line"; LocationCode: Code[10])
    begin
        ServiceLine.Validate("Location Code", LocationCode);
        ServiceLine.Modify(true);
    end;

    local procedure UpdateGlobalDimensionOnServiceLine(var ServiceLine: Record "Service Line"; var DimensionValue: Record "Dimension Value")
    begin
        LibraryDimension.CreateDimensionValue(DimensionValue, LibraryERM.GetGlobalDimensionCode(1));
        ServiceLine.Validate("Shortcut Dimension 1 Code", DimensionValue.Code);
        ServiceLine.Modify(true);
    end;

    local procedure CreateCustomerWithDefaultGlobalDimValue(var Customer: Record Customer; var DimensionValue: Record "Dimension Value")
    var
        DefaultDimension: Record "Default Dimension";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryDimension.CreateDimensionValue(DimensionValue, LibraryERM.GetGlobalDimensionCode(1));
        LibraryDimension.CreateDefaultDimensionCustomer(
          DefaultDimension, Customer."No.", DimensionValue."Dimension Code", DimensionValue.Code);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmMessageHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := not (Question = ServiceContractConfirmation);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmMessageHandlerForFalse(Question: Text[1024]; var Reply: Boolean)
    begin
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Question: Text[1024])
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalFormHander(var StandardServItemGrCodes: Page "Standard Serv. Item Gr. Codes"; var Response: Action)
    var
        StandardServiceItemGrCode: Record "Standard Service Item Gr. Code";
    begin
        LibraryService.CreateStandardServiceItemGr(
          StandardServiceItemGrCode,
          CopyStr(LibraryVariableStorage.DequeueText(), 1, 10),
          CopyStr(LibraryVariableStorage.DequeueText(), 1, 10));
        StandardServItemGrCodes.SetRecord(StandardServiceItemGrCode);
        StandardServItemGrCodes.SetTableView(StandardServiceItemGrCode);
        Response := ACTION::LookupOK;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalPageHandlerForDim(var ProductionJournal: Page "Production Journal"; var Response: Action)
    var
        DimensionSetEntry: Record "Dimension Set Entry";
        ItemJournalLine: Record "Item Journal Line";
    begin
        ItemJournalLine.SetRange("Item No.", LibraryVariableStorage.DequeueText());
        ItemJournalLine.FindFirst();
        LibraryDimension.FindDimensionSetEntry(DimensionSetEntry, ItemJournalLine."Dimension Set ID");
        DimensionSetEntry.TestField("Dimension Value Code", LibraryVariableStorage.DequeueText());
    end;

#if not CLEAN27
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceOrderStatisticsMPH(var ServiceOrderStatistics: TestPage "Service Order Statistics")
    begin
        ServiceOrderStatistics.OK().Invoke();
    end;
#endif
    [PageHandler]
    [Scope('OnPrem')]
    procedure ServiceOrderStatisticsMPH_NM(var ServiceOrderStatistics: TestPage "Service Order Statistics")
    begin
        ServiceOrderStatistics.OK().Invoke();
    end;
}
