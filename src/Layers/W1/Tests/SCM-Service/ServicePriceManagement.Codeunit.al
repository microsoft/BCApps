// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Test;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Inventory.Item;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Sales.Customer;
using Microsoft.Service.Contract;
using Microsoft.Service.Document;
using Microsoft.Service.Item;
using Microsoft.Service.Pricing;

codeunit 136105 "Service - Price Management"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Service] [Price Management]
        IsInitialized := false;
    end;

    var
        ServiceItemLine: Record "Service Item Line";
        WarrantyError: Label 'There are no Service Lines to adjust.';
        ServicePriceGroupCodeError: Label 'A service item line cannot belong to a service contract and to a service price group at the same time.';
        ServiceContractConfirmation: Label 'Do you want to create the contract using a contract template?';
        UnexpectedError: Label 'Unexpected error message.';
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryService: Codeunit "Library - Service";
        LibrarySales: Codeunit "Library - Sales";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        IsInitialized: Boolean;
        AmountError: Label '%1 and %2 must match.';

    [Normal]
    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Service - Price Management");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Service - Price Management");

        // Create Demonstration Database
        LibraryService.SetupServiceMgtNoSeries();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Service - Price Management");
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler,ModalFormHandler')]
    [Scope('OnPrem')]
    procedure UnitPriceFromServicePriceGroup()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine2: Record "Service Item Line";
        Item: Record Item;
        ServiceLine: Record "Service Line";
        ServicePriceGroup: Record "Service Price Group";
        ServicePriceAdjustmentGroup: Record "Service Price Adjustment Group";
        ServicePriceManagement: Codeunit "Service Price Management";
        AdjustmentType: Option "Fixed",Maximum,Minimum;
    begin
        // Covers document number TC0127 - refer to TFS ID 21728.
        // Test Unit Price and Amount on Service Line after Service Price Adjustment.

        // 1. Setup: Create Service Order - Create Service Price Group, Service Price Adjustmnet Group, Service Price Group Setup.
        Initialize();
        LibraryService.CreateServicePriceGroup(ServicePriceGroup);
        LibraryService.CreateServPriceAdjustmentGroup(ServicePriceAdjustmentGroup);
        CreateServicePriceGroupSetup(ServicePriceAdjustmentGroup.Code, ServicePriceGroup.Code, AdjustmentType::Fixed, false, false);
        CreateServiceHeader(ServiceHeader);
        CreateServItemLineWithPricGrou(ServiceItemLine2, ServiceHeader, ServicePriceGroup.Code);
        CreateItem(Item);

        CreateServiceLineWithOutDisc(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.", ServiceItemLine2."Line No.");
        ServiceItemLine := ServiceItemLine2;

        // 2. Exercise: Service Price Adjustment on Service Order.
        ServicePriceManagement.ShowPriceAdjustment(ServiceItemLine2);

        // 3. Verify: Verify that the Unit Price and Amount on Service Line is Amount of Service Price Group Setup of Service Price
        // Group Code on Service Item Line.
        VerifyUnitPrice(ServiceItemLine2);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler')]
    [Scope('OnPrem')]
    procedure WarrantyOnServiceOrder()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceItemLine2: Record "Service Item Line";
        ServicePriceGroup: Record "Service Price Group";
        ServicePriceAdjustmentGroup: Record "Service Price Adjustment Group";
        ServicePriceManagement: Codeunit "Service Price Management";
        AdjustmentType: Option "Fixed",Maximum,Minimum;
    begin
        // Covers document number TC0127 - refer to TFS ID 21728.
        // Test error occurs "no service lines to adjust" on Service Price Adjustment.

        // 1. Setup: Create Service Price Group Setup.
        Initialize();
        LibraryService.CreateServicePriceGroup(ServicePriceGroup);
        LibraryService.CreateServPriceAdjustmentGroup(ServicePriceAdjustmentGroup);
        CreateServicePriceGroupSetup(ServicePriceAdjustmentGroup.Code, ServicePriceGroup.Code, AdjustmentType::Fixed, false, false);

        // 2. Exercise: Create Service Order.
        CreateServiceHeader(ServiceHeader);
        LibraryService.CreateServiceItemLine(ServiceItemLine2, ServiceHeader, '');
        UpdateServPriceOnServItemLine(ServiceItemLine2, ServicePriceGroup.Code);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItemNo());
        UpdateWarrantyOnServiceLine(ServiceLine, ServiceItemLine2."Line No.");
        ServiceItemLine := ServiceItemLine2;

        // 3. Verify: Verify that the Service Order shows error "No Service Line" on Run Service Price Adjustment.
        asserterror ServicePriceManagement.ShowPriceAdjustment(ServiceItemLine2);
        Assert.AreEqual(StrSubstNo(WarrantyError), GetLastErrorText, UnexpectedError);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ServiceItemAttachOnContract()
    var
        ServiceHeader: Record "Service Header";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceItemLine2: Record "Service Item Line";
        ServicePriceGroup: Record "Service Price Group";
        ServicePriceAdjustmentGroup: Record "Service Price Adjustment Group";
        SignServContractDoc: Codeunit SignServContractDoc;
        AdjustmentType: Option "Fixed",Maximum,Minimum;
    begin
        // Covers document number TC0127 - refer to TFS ID 21728.
        // Test error occurs on Service Price Group Code updation on Service Item Line.

        // 1. Setup:  Create and Sign Service Contract.
        Initialize();
        CreateServiceContract(ServiceContractHeader, ServiceContractLine);
        SignServContractDoc.SignContract(ServiceContractHeader);
        LibraryService.CreateServicePriceGroup(ServicePriceGroup);
        LibraryService.CreateServPriceAdjustmentGroup(ServicePriceAdjustmentGroup);
        CreateServicePriceGroupSetup(ServicePriceAdjustmentGroup.Code, ServicePriceGroup.Code, AdjustmentType::Fixed, false, false);

        // 2. Exercise: Create Service Header.
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ServiceContractLine."Customer No.");

        // 3. Verify: Verify that the Service Item Line raised an error after enter Service Price Group Code.
        LibraryService.CreateServiceItemLine(ServiceItemLine2, ServiceHeader, ServiceContractLine."Service Item No.");
        asserterror ServiceItemLine2.Validate("Service Price Group Code", ServicePriceGroup.Code);
        Assert.AreEqual(StrSubstNo(ServicePriceGroupCodeError), GetLastErrorText, UnexpectedError);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler,ModalFormHandler')]
    [Scope('OnPrem')]
    procedure UnitPriceWithoutDiscountAndVAT()
    var
        TempServiceLine: Record "Service Line" temporary;
        ServiceItemLine2: Record "Service Item Line";
    begin
        // Covers document number TC0126, TC0129, TC0130 - refer to TFS ID 21728.
        // Test values on Service Line after Service Price Adjustment with Adjustment Type Fixed, without Discount and VAT.

        // 1. Create Service Price Group Setup with Adjustment Type Fixed, Include Discount True and Include VAT False and Create
        // Service Order and Service Price Adjustment on Service Order.
        UnitPriceFixedWithResourceCost(TempServiceLine, ServiceItemLine2, false, false);

        // 2. Verify: Check Unit Price, Line Discount Amount and Amount on Service Line.
        VerifyPriceAdjustment(TempServiceLine, ServiceItemLine2);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler,ModalFormHandler')]
    [Scope('OnPrem')]
    procedure UndoPriceWithoutDiscountAndVAT()
    var
        ServiceItemLine2: Record "Service Item Line";
        TempServiceLine: Record "Service Line" temporary;
    begin
        // Covers document number TC0126, TC0129, TC0130 - refer to TFS ID 21728.
        // Test undo Service Price Adjustment with Adjustment Type Fixed, without Discount and VAT.

        // 1. Setup: Create Service Price Group Setup with Adjustment Type Fixed, Include Discount and Include VAT False, Create Service
        // Order and Service Price Adjustment on Service Order.
        UnitPriceFixedWithResourceCost(TempServiceLine, ServiceItemLine2, false, false);

        // 2. Exercise: Undo Service Price Adjustment on Service Order.
        UndoServicePriceAdjustment(ServiceItemLine2);

        // 3. Verify: Check Unit Price and Amount is Unit Price and Amount on Service Line before running the Service Price Adjustment.
        VerifyUndoPriceAdjustment(TempServiceLine, ServiceItemLine2);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler,ModalFormHandler')]
    [Scope('OnPrem')]
    procedure UnitPriceFixedWithDiscount()
    var
        TempServiceLine: Record "Service Line" temporary;
        ServiceItemLine2: Record "Service Item Line";
    begin
        // Covers document number TC0126, TC0129, TC0131 - refer to TFS ID 21728.
        // Test values on Service Line after Service Price Adjustment with Adjustment Type Fixed, withDiscount.

        // 1. Create Service Price Group Setup with Adjustment Type Fixed, Include Discount True and Include VAT False and Create
        // Service Order and Service Price Adjustment on Service Order.
        UnitPriceFixedWithResourceCost(TempServiceLine, ServiceItemLine2, true, false);

        // 2. Verify: Check Unit Price, Line Discount Amount and Amount on Service Line.
        VerifyPriceAdjustment(TempServiceLine, ServiceItemLine2);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler,ModalFormHandler')]
    [Scope('OnPrem')]
    procedure UnitPriceFixedWithVAT()
    var
        TempServiceLine: Record "Service Line" temporary;
        ServiceItemLine2: Record "Service Item Line";
    begin
        // Covers document number TC0126, TC0129, TC0131 - refer to TFS ID 21728.
        // Test values on Service Line after Service Price Adjustment with Adjustment Type Fixed, withVAT.

        // 1. Create Service Price Group Setup with Adjustment Type Fixed, Include Discount False and Include VAT True and Create
        // Service Order and Service Price Adjustment on Service Order.
        UnitPriceFixedWithResourceCost(TempServiceLine, ServiceItemLine2, false, true);

        // 2. Verify: Check Unit Price, Line Discount Amount, Amount Including VAT and Amount on Service Line.
        VerifyPriceAdjustmentWithVAT(TempServiceLine, ServiceItemLine2);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler,ModalFormHandler')]
    [Scope('OnPrem')]
    procedure UnitPriceWithDiscountAndVAT()
    var
        TempServiceLine: Record "Service Line" temporary;
        ServiceItemLine2: Record "Service Item Line";
    begin
        // Covers document number TC0126, TC0129, TC0132 - refer to TFS ID 21728.
        // Test values on Service Line after Service Price Adjustment with Adjustment Type Fixed, with Discount and VAT.

        // 1. Create Service Price Group Setup with Adjustment Type Fixed, Include Discount True and Include VAT True and Create
        // Service Order and Service Price Adjustment on Service Order.
        UnitPriceFixedWithResourceCost(TempServiceLine, ServiceItemLine2, true, true);

        // 2. Verify: Check Unit Price, Line Discount Amount, Amount Including VAT and Amount on Service Line.
        VerifyPriceAdjustmentWithVAT(TempServiceLine, ServiceItemLine2);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler,ModalFormHandler')]
    [Scope('OnPrem')]
    procedure UnitPriceMaximum()
    var
        TempServiceLine: Record "Service Line" temporary;
        ServiceItemLine2: Record "Service Item Line";
        AdjustmentType: Option "Fixed",Maximum,Minimum;
    begin
        // Covers document number TC0126, TC0129, TC0133 - refer to TFS ID 21728.
        // Test values on Service Line after Service Price Adjustment with Adjustment Type Maximum, without Discount and VAT.

        // 1. Create Service Price Group Setup with Adjustment Type Maximum, Include Discount False and Include VAT False and Create
        // Service Order and Service Price Adjustment on Service Order.
        UnitPriceWithItem(TempServiceLine, ServiceItemLine2, AdjustmentType::Maximum, false, false);

        // 2. Verify: Check Unit Price, Line Discount Amount and Amount on Service Line.
        VerifyPriceAdjustmentMaximum(TempServiceLine, ServiceItemLine2);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler,ModalFormHandler')]
    [Scope('OnPrem')]
    procedure UnitPriceMaximumWithDiscount()
    var
        TempServiceLine: Record "Service Line" temporary;
        ServiceItemLine2: Record "Service Item Line";
        AdjustmentType: Option "Fixed",Maximum,Minimum;
    begin
        // Covers document number TC0126, TC0129, TC0133 - refer to TFS ID 21728.
        // Test values on Service Line after Service Price Adjustment with Adjustment Type Maximum, with Discount.

        // 1. Create Service Price Group Setup with Adjustment Type Maximum, Include Discount True and Include VAT False and Create
        // Service Order and Service Price Adjustment on Service Order.
        UnitPriceWithItem(TempServiceLine, ServiceItemLine2, AdjustmentType::Maximum, true, false);

        // 2. Verify: Check Unit Price, Line Discount Amount and Amount on Service Line.
        VerifyPriceAdjustmentMaximum(TempServiceLine, ServiceItemLine2);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler,ModalFormHandler')]
    [Scope('OnPrem')]
    procedure UnitPriceMaximumWithVAT()
    var
        TempServiceLine: Record "Service Line" temporary;
        ServiceItemLine2: Record "Service Item Line";
        AdjustmentType: Option "Fixed",Maximum,Minimum;
    begin
        // Covers document number TC0126, TC0129, TC0133 - refer to TFS ID 21728.
        // Test values on Service Line after Service Price Adjustment with Adjustment Type Maximum, with VAT.

        // 1. Create Service Price Group Setup with Adjustment Type Maximum, Include Discount False and Include VAT True and Create
        // Service Order and Service Price Adjustment on Service Order.
        UnitPriceWithItem(TempServiceLine, ServiceItemLine2, AdjustmentType::Maximum, false, true);

        // 2. Verify: Check Unit Price, Line Discount Amount, Amount Including VAT and Amount on Service Line.
        VerifyPricAdjustMaxWithInclVAT(TempServiceLine, ServiceItemLine2);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler,ModalFormHandler')]
    [Scope('OnPrem')]
    procedure UnitPriceMaxWithDiscountAndVAT()
    var
        TempServiceLine: Record "Service Line" temporary;
        ServiceItemLine2: Record "Service Item Line";
        AdjustmentType: Option "Fixed",Maximum,Minimum;
    begin
        // Covers document number TC0126, TC0129, TC0133 - refer to TFS ID 21728.
        // Test values on Service Line after Service Price Adjustment with Adjustment Type Maximum, with Discount and VAT.

        // 1. Create Service Price Group Setup with Adjustment Type Maximum, Include Discount True and Include VAT True and Create
        // Service Order and Service Price Adjustment on Service Order.
        UnitPriceWithItem(TempServiceLine, ServiceItemLine2, AdjustmentType::Maximum, true, true);

        // 2. Verify: Check Unit Price, Line Discount Amount, Amount Including VAT and Amount on Service Line.
        VerifyPricAdjustMaxWithInclVAT(TempServiceLine, ServiceItemLine2);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler,ModalFormHandler')]
    [Scope('OnPrem')]
    procedure UnitPriceMinimum()
    var
        TempServiceLine: Record "Service Line" temporary;
        ServiceItemLine2: Record "Service Item Line";
        AdjustmentType: Option "Fixed",Maximum,Minimum;
    begin
        // Covers document number TC0126, TC0129, TC0133 - refer to TFS ID 21728.
        // Test values on Service Line after Service Price Adjustment with Adjustment Type Minimum, without Discount and VAT.

        // 1. Create Service Price Group Setup with Adjustment Type Minimum, Include Discount False and Include VAT False and Create
        // Service Order and Service Price Adjustment on Service Order.
        UnitPriceWithItem(TempServiceLine, ServiceItemLine2, AdjustmentType::Minimum, false, false);

        // 2. Verify: Check Unit Price,Line Discount Amount and Amount on Service Line.
        VerifyPriceAdjustmentMinimum(TempServiceLine, ServiceItemLine2);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler,ModalFormHandler')]
    [Scope('OnPrem')]
    procedure UnitPriceMinimumWithDiscount()
    var
        TempServiceLine: Record "Service Line" temporary;
        ServiceItemLine2: Record "Service Item Line";
        AdjustmentType: Option "Fixed",Maximum,Minimum;
    begin
        // Covers document number TC0126, TC0129, TC0133 - refer to TFS ID 21728.
        // Test values on Service Line after Service Price Adjustment with Adjustment Type Minimum, with Discount.

        // 1. Create Service Price Group Setup with Adjustment Type Minimum, Include Discount True and Include VAT False and Create
        // Service Order and Service Price Adjustment on Service Order.
        UnitPriceWithItem(TempServiceLine, ServiceItemLine2, AdjustmentType::Minimum, true, false);

        // 2. Verify: Check Unit Price, Line Discount Amount and Amount on Service Line.
        VerifyPriceAdjustmentMinimum(TempServiceLine, ServiceItemLine2);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler,ModalFormHandler')]
    [Scope('OnPrem')]
    procedure UnitPriceMinimumWithVAT()
    var
        TempServiceLine: Record "Service Line" temporary;
        ServiceItemLine2: Record "Service Item Line";
        AdjustmentType: Option "Fixed",Maximum,Minimum;
    begin
        // Covers document number TC0126, TC0129, TC0133 - refer to TFS ID 21728.
        // Test values on Service Line after Service Price Adjustment with Adjustment Type Minimum, with VAT.

        // 1. Create Service Price Group Setup with Adjustment Type Minimum, Include Discount False and Include VAT True and Create
        // Service Order and Service Price Adjustment on Service Order.
        UnitPriceWithItem(TempServiceLine, ServiceItemLine2, AdjustmentType::Minimum, false, true);

        // 2. Verify: Check Unit Price, Line Discount Amount, Amount Including VAT and Amount on Service Line.
        VerifyPricAdjustMinWithInclVAT(TempServiceLine, ServiceItemLine2);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler,ModalFormHandler')]
    [Scope('OnPrem')]
    procedure UnitPriceMinWithDiscountAndVAT()
    var
        TempServiceLine: Record "Service Line" temporary;
        ServiceItemLine2: Record "Service Item Line";
        AdjustmentType: Option "Fixed",Maximum,Minimum;
    begin
        // Covers document number TC0126, TC0129, TC0133 - refer to TFS ID 21728.
        // Test values on Service Line after Service Price Adjustment with Adjustment Type Minimum, with Discount and VAT.

        // 1. Create Service Price Group Setup with Adjustment Type Minimum, Include Discount True and Include VAT True and Create
        // Service Order and Service Price Adjustment on Service Order.
        UnitPriceWithItem(TempServiceLine, ServiceItemLine2, AdjustmentType::Minimum, true, true);

        // 2. Verify: Check Unit Price, Line Discount Amount, Amount Including VAT and Amount on Service Line.
        VerifyPricAdjustMinWithInclVAT(TempServiceLine, ServiceItemLine2);
    end;

    [Normal]
    local procedure UnitPriceFixedWithResourceCost(var TempServiceLine: Record "Service Line" temporary; var ServiceItemLine2: Record "Service Item Line"; IncludeDiscount: Boolean; IncludeVAT: Boolean)
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServicePriceGroup: Record "Service Price Group";
        ServiceCost: Record "Service Cost";
        Resource: Record Resource;
        ServicePriceAdjustmentGroup: Record "Service Price Adjustment Group";
        ServPriceAdjustmentDetail: Record "Serv. Price Adjustment Detail";
        ServicePriceManagement: Codeunit "Service Price Management";
        LibraryResource: Codeunit "Library - Resource";
        AdjustmentType: Option "Fixed",Maximum,Minimum;
    begin
        // 1. Setup: Create Service Price Group Setup with Adjustment Type Fixed, Include Discount and Include VAT False and Create
        // Service Order.
        Initialize();
        LibraryService.CreateServicePriceGroup(ServicePriceGroup);
        LibraryService.CreateServPriceAdjustmentGroup(ServicePriceAdjustmentGroup);
        LibraryResource.FindResource(Resource);
        LibraryService.FindServiceCost(ServiceCost);
        CreateServicePriceAdjustDetail(
          ServPriceAdjustmentDetail, ServicePriceAdjustmentGroup.Code, ServPriceAdjustmentDetail.Type::Resource, Resource."No.");
        CreateServicePriceAdjustDetail(
          ServPriceAdjustmentDetail, ServicePriceAdjustmentGroup.Code, ServPriceAdjustmentDetail.Type::"Service Cost", ServiceCost.Code);

        CreateServicePriceGroupSetup(
          ServicePriceAdjustmentGroup.Code, ServicePriceGroup.Code, AdjustmentType::Fixed, IncludeDiscount, IncludeVAT);
        CreateServiceHeader(ServiceHeader);
        CreateServItemLineWithItemGrp(ServiceItemLine2, ServiceHeader, ServicePriceGroup.Code);

        if IncludeDiscount then begin
            CreateServiceLineWithDiscount(ServiceLine, ServiceHeader, ServiceLine.Type::Resource, Resource."No.", ServiceItemLine2."Line No.");
            CreateServiceLineWithDiscount(ServiceLine, ServiceHeader, ServiceLine.Type::Cost, ServiceCost.Code, ServiceItemLine2."Line No.");
        end else begin
            CreateServiceLineWithOutDisc(ServiceLine, ServiceHeader, ServiceLine.Type::Resource, Resource."No.", ServiceItemLine2."Line No.");
            CreateServiceLineWithOutDisc(ServiceLine, ServiceHeader, ServiceLine.Type::Cost, ServiceCost.Code, ServiceItemLine2."Line No.");
        end;

        ServiceItemLine := ServiceItemLine2;
        SaveServiceLineInTempTable(TempServiceLine, ServiceItemLine2);

        // 2. Exercise: Service Price Adjustment on Service Order.
        ServicePriceManagement.ShowPriceAdjustment(ServiceItemLine2);
    end;

    [Normal]
    local procedure UnitPriceWithItem(var TempServiceLine: Record "Service Line" temporary; var ServiceItemLine2: Record "Service Item Line"; AdjustmentType: Option; IncludeDiscount: Boolean; IncludeVAT: Boolean)
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        Item: Record Item;
        Item2: Record Item;
        ServicePriceGroup: Record "Service Price Group";
        ServicePriceAdjustmentGroup: Record "Service Price Adjustment Group";
        ServPriceAdjustmentDetail: Record "Serv. Price Adjustment Detail";
        ServicePriceManagement: Codeunit "Service Price Management";
        OldRate: Decimal;
    begin
        // 1. Setup: Create Service Price Group Setup with Adjustment Type Maximum, Include Discount False and Include VAT False and Create
        // Service Order.
        Initialize();
        LibraryService.CreateServicePriceGroup(ServicePriceGroup);
        LibraryService.CreateServPriceAdjustmentGroup(ServicePriceAdjustmentGroup);
        CreateItem(Item);
        CreateItem(Item2);
        OldRate := AdjustVATRate(Item."VAT Prod. Posting Group", LibraryRandom.RandIntInRange(10, 15));
        CreateServicePriceAdjustDetail(
          ServPriceAdjustmentDetail, ServicePriceAdjustmentGroup.Code, ServPriceAdjustmentDetail.Type::Item, Item."No.");
        CreateServicePriceAdjustDetail(
          ServPriceAdjustmentDetail, ServicePriceAdjustmentGroup.Code, ServPriceAdjustmentDetail.Type::Item, Item2."No.");

        CreateServicePriceGroupSetup(ServicePriceAdjustmentGroup.Code, ServicePriceGroup.Code, AdjustmentType, IncludeDiscount, IncludeVAT);
        CreateServiceHeader(ServiceHeader);
        CreateServItemLineWithItemGrp(ServiceItemLine2, ServiceHeader, ServicePriceGroup.Code);

        if IncludeDiscount then begin
            CreateServiceLineWithDiscount(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.", ServiceItemLine2."Line No.");
            CreateServiceLineWithDiscount(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item2."No.", ServiceItemLine2."Line No.");
        end else begin
            CreateServiceLineWithOutDisc(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.", ServiceItemLine2."Line No.");
            CreateServiceLineWithOutDisc(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item2."No.", ServiceItemLine2."Line No.");
        end;

        ServiceItemLine := ServiceItemLine2;
        SaveServiceLineInTempTable(TempServiceLine, ServiceItemLine2);

        // 2. Exercise: Service Price Adjustment on Service Order.
        ServicePriceManagement.ShowPriceAdjustment(ServiceItemLine2);

        AdjustVATRate(Item."VAT Prod. Posting Group", OldRate);
    end;

    [Normal]
    local procedure CreateServiceHeader(var ServiceHeader: Record "Service Header")
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");
    end;

    [Normal]
    local procedure CreateServItemLineWithPricGrou(var ServiceItemLine2: Record "Service Item Line"; ServiceHeader: Record "Service Header"; ServicePriceGroupCode: Code[10])
    begin
        LibraryService.CreateServiceItemLine(ServiceItemLine2, ServiceHeader, '');
        ServiceItemLine2.Validate("Service Price Group Code", ServicePriceGroupCode);
        ServiceItemLine2.Modify(true);
    end;

    [Normal]
    local procedure CreateServiceLineWithDiscount(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header"; Type: Enum "Service Line Type"; No: Code[20]; ServiceItemLineNo: Integer)
    begin
        // Use Random for Quantity and "Line Discount %" because value is not important.
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, Type, No);
        ServiceLine.Validate("Service Item Line No.", ServiceItemLineNo);
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10));
        ServiceLine.Validate("Line Discount %", LibraryRandom.RandInt(99));  // Maximum value 99 is important for calculation of different amounts.
        ServiceLine.Modify(true);
    end;

    [Normal]
    local procedure CreateServiceLineWithOutDisc(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header"; Type: Enum "Service Line Type"; No: Code[20]; ServiceItemLineNo: Integer)
    begin
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, Type, No);
        ServiceLine.Validate("Service Item Line No.", ServiceItemLineNo);
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10));  // Use Random because value is not important.
        ServiceLine.Validate("Line Discount %", 0);  // Use 0 for without Line Discount.
        ServiceLine.Modify(true);
    end;

    [Normal]
    local procedure CreateServItemLineWithItemGrp(var ServiceItemLine2: Record "Service Item Line"; ServiceHeader: Record "Service Header"; ServicePriceGroupCode: Code[10])
    begin
        LibraryService.CreateServiceItemLine(ServiceItemLine2, ServiceHeader, '');
        ServiceItemLine2.Validate("Service Item Group Code", SelectServiceItemGroup(ServicePriceGroupCode));
        ServiceItemLine2.Modify(true);
    end;

    [Normal]
    local procedure CreateServiceContract(var ServiceContractHeader: Record "Service Contract Header"; var ServiceContractLine: Record "Service Contract Line")
    var
        ServiceItem: Record "Service Item";
    begin
        LibraryService.CreateServiceItem(ServiceItem, FindCustomer());
        LibraryService.CreateServiceContractHeader(
          ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, ServiceItem."Customer No.");
        CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");
        UpdateServiceContractHeaderAmt(ServiceContractHeader);
        UpdateServiceContractLineDate(ServiceContractLine, ServiceContractHeader);
    end;

    [Normal]
    local procedure CreateServiceContractLine(var ServiceContractLine: Record "Service Contract Line"; ServiceContractHeader: Record "Service Contract Header"; ServiceItemNo: Code[20])
    begin
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItemNo);
        ServiceContractLine.Validate("Line Value", LibraryRandom.RandInt(100));  // Use Random because value is not important.
        ServiceContractLine.Modify(true);
    end;

    [Normal]
    local procedure CreateServicePriceGroupSetup(ServicePriceAdjustGroupCode: Code[10]; ServicePriceGroupCode: Code[10]; AdjustmentType: Option; IncludeDiscount: Boolean; IncludeVAT: Boolean)
    var
        ServPriceGroupSetup: Record "Serv. Price Group Setup";
    begin
        LibraryService.CreateServPriceGroupSetup(ServPriceGroupSetup, ServicePriceGroupCode, '', '');
        ServPriceGroupSetup.Validate("Serv. Price Adjmt. Gr. Code", ServicePriceAdjustGroupCode);
        ServPriceGroupSetup.Validate("Adjustment Type", AdjustmentType);
        ServPriceGroupSetup.Validate("Include Discounts", IncludeDiscount);
        ServPriceGroupSetup.Validate("Include VAT", IncludeVAT);
        ServPriceGroupSetup.Modify(true);
    end;

    [Normal]
    local procedure CreateServicePriceAdjustDetail(ServPriceAdjustmentDetail: Record "Serv. Price Adjustment Detail"; ServicePriceAdjustGroupCode: Code[10]; Type: Option; No: Code[20])
    begin
        ServPriceAdjustmentDetail.Init();
        ServPriceAdjustmentDetail.Validate("Serv. Price Adjmt. Gr. Code", ServicePriceAdjustGroupCode);
        ServPriceAdjustmentDetail.Validate(Type, Type);
        ServPriceAdjustmentDetail.Validate("No.", No);
        ServPriceAdjustmentDetail.Insert(true);
    end;

    [Normal]
    local procedure CalculateAdjustedAmount(ServiceItemLine2: Record "Service Item Line"; Amount: Decimal; TotalAmount: Decimal; RoundingPrecision: Decimal): Decimal
    var
        ServPriceGroupSetup: Record "Serv. Price Group Setup";
    begin
        ServPriceGroupSetup.Init();
        ServPriceGroupSetup.SetRange("Service Price Group Code", ServiceItemLine2."Service Price Group Code");
        ServPriceGroupSetup.SetRange("Serv. Price Adjmt. Gr. Code", ServiceItemLine2."Serv. Price Adjmt. Gr. Code");
        ServPriceGroupSetup.FindFirst();
        exit(Round(ServPriceGroupSetup.Amount * (Amount * 100 / TotalAmount) / 100, RoundingPrecision));
    end;

    [Normal]
    local procedure UpdateServPriceOnServItemLine(var ServiceItemLine2: Record "Service Item Line"; ServicePriceGroupCode: Code[10])
    begin
        ServiceItemLine2.Validate("Service Price Group Code", ServicePriceGroupCode);
        ServiceItemLine2.Validate(Warranty, true);
        ServiceItemLine2.Modify(true);
    end;

    [Normal]
    local procedure UpdateWarrantyOnServiceLine(ServiceLine: Record "Service Line"; ServiceItemLineNo: Integer)
    begin
        ServiceLine.Validate("Service Item Line No.", ServiceItemLineNo);
        ServiceLine.Validate(Warranty, true);
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10));  // Use Random because value is not important.
        ServiceLine.Modify(true);
    end;

    [Normal]
    local procedure UpdateServiceContractLineDate(var ServiceContractLine: Record "Service Contract Line"; ServiceContractHeader: Record "Service Contract Header")
    begin
        ServiceContractLine.Validate("Next Planned Service Date", ServiceContractHeader."Starting Date");
        ServiceContractLine.Validate("Starting Date", ServiceContractHeader."Starting Date");
        ServiceContractLine.Modify(true);
    end;

    [Normal]
    local procedure UpdateServiceContractHeaderAmt(var ServiceContractHeader: Record "Service Contract Header")
    begin
        ServiceContractHeader.CalcFields("Calcd. Annual Amount");
        ServiceContractHeader.Validate("Annual Amount", ServiceContractHeader."Calcd. Annual Amount");
        ServiceContractHeader.Modify(true);
    end;

    [Normal]
    local procedure SaveServiceLineInTempTable(var TempServiceLine: Record "Service Line" temporary; ServiceItemLine2: Record "Service Item Line")
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceLine.SetRange("Document Type", ServiceItemLine2."Document Type");
        ServiceLine.SetRange("Document No.", ServiceItemLine2."Document No.");
        ServiceLine.SetRange("Service Item Line No.", ServiceItemLine2."Line No.");
        ServiceLine.FindSet();
        repeat
            TempServiceLine := ServiceLine;
            TempServiceLine.Insert();
        until ServiceLine.Next() = 0;
    end;

    [Normal]
    local procedure SelectServiceItemGroup(ServicePriceGroupCode: Code[10]): Code[10]
    var
        ServiceItemGroup: Record "Service Item Group";
    begin
        LibraryService.FindServiceItemGroup(ServiceItemGroup);
        ServiceItemGroup.Validate("Default Serv. Price Group Code", ServicePriceGroupCode);
        ServiceItemGroup.Modify(true);
        exit(ServiceItemGroup.Code);
    end;

    [Normal]
    local procedure CalculateTotalAmount(var TempServiceLine: Record "Service Line" temporary; IncludingVAT: Boolean) TotalAmount: Decimal
    begin
        TempServiceLine.FindSet();
        TempServiceLine.CalcSums("Amount Including VAT", Amount);
        if IncludingVAT then
            TotalAmount := TempServiceLine."Amount Including VAT"
        else
            TotalAmount := TempServiceLine.Amount;
        TempServiceLine.FindFirst();
    end;

    local procedure CreateItem(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        Item.Validate("Unit Cost", LibraryRandom.RandDec(100, 2));
        Item.Modify(true);
    end;

    local procedure FindCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        exit(Customer."No.");
    end;

    [Normal]
    local procedure FindServiceLine(var ServiceLine: Record "Service Line"; ServiceItemLine2: Record "Service Item Line")
    begin
        ServiceLine.SetRange("Document Type", ServiceItemLine2."Document Type");
        ServiceLine.SetRange("Document No.", ServiceItemLine2."Document No.");
        ServiceLine.SetRange("Service Item Line No.", ServiceItemLine2."Line No.");
        ServiceLine.FindSet();
    end;

    [Normal]
    local procedure UndoServicePriceAdjustment(ServiceItemLine2: Record "Service Item Line")
    var
        ServiceLine: Record "Service Line";
        ServicePriceManagement: Codeunit "Service Price Management";
    begin
        ServiceLine.SetRange("Document Type", ServiceItemLine2."Document Type");
        ServiceLine.SetRange("Document No.", ServiceItemLine2."Document No.");
        ServiceLine.SetRange("Service Item Line No.", ServiceItemLine2."Line No.");
        ServiceLine.FindFirst();
        ServicePriceManagement.CheckServItemGrCode(ServiceLine);
        ServicePriceManagement.ResetAdjustedLines(ServiceLine);
    end;

    [Normal]
    local procedure VerifyUnitPrice(ServiceItemLine2: Record "Service Item Line")
    var
        ServiceLine: Record "Service Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        ServiceLine.Get(ServiceItemLine2."Document Type", ServiceItemLine2."Document No.", ServiceItemLine2."Line No.");
        ServiceLine.TestField(
          "Unit Price",
          Round(ServiceItemLine2."Base Amount to Adjust" / ServiceLine.Quantity, GeneralLedgerSetup."Unit-Amount Rounding Precision"));
        ServiceLine.TestField(Amount, ServiceItemLine2."Base Amount to Adjust");
    end;

    [Normal]
    local procedure VerifyPriceAdjustment(var TempServiceLine: Record "Service Line" temporary; ServiceItemLine2: Record "Service Item Line")
    var
        ServiceLine: Record "Service Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        TotalAmount: Decimal;
        NewAmount: Decimal;
    begin
        GeneralLedgerSetup.Get();
        TotalAmount := CalculateTotalAmount(TempServiceLine, false);
        FindServiceLine(ServiceLine, ServiceItemLine2);
        repeat
            ServiceLine.TestField("No.", TempServiceLine."No.");
            NewAmount :=
              CalculateAdjustedAmount(
                ServiceItemLine2, TempServiceLine.Amount, TotalAmount, GeneralLedgerSetup."Inv. Rounding Precision (LCY)");
            VerifyAdjustAmountWithOutVAT(TempServiceLine, ServiceLine, GeneralLedgerSetup, NewAmount);
            TempServiceLine.Next();
        until ServiceLine.Next() = 0;
    end;

    [Normal]
    local procedure VerifyUndoPriceAdjustment(var TempServiceLine: Record "Service Line" temporary; ServiceItemLine2: Record "Service Item Line")
    var
        ServiceLine: Record "Service Line";
    begin
        TempServiceLine.FindFirst();
        ServiceLine.SetRange("Document Type", ServiceItemLine2."Document Type");
        ServiceLine.SetRange("Document No.", ServiceItemLine2."Document No.");
        ServiceLine.SetRange("Service Item Line No.", ServiceItemLine2."Line No.");
        ServiceLine.FindSet();
        repeat
            ServiceLine.TestField("No.", TempServiceLine."No.");
            ServiceLine.TestField("Unit Price", TempServiceLine."Unit Price");
            ServiceLine.TestField(Amount, TempServiceLine.Amount);
            TempServiceLine.Next();
        until ServiceLine.Next() = 0;
    end;

    [Normal]
    local procedure VerifyPriceAdjustmentWithVAT(var TempServiceLine: Record "Service Line" temporary; ServiceItemLine2: Record "Service Item Line")
    var
        ServiceLine: Record "Service Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        TotalAmount: Decimal;
        NewAmount: Decimal;
        UnitPrice: Decimal;
    begin
        GeneralLedgerSetup.Get();
        TotalAmount := CalculateTotalAmount(TempServiceLine, true);
        FindServiceLine(ServiceLine, ServiceItemLine2);
        repeat
            ServiceLine.TestField("No.", TempServiceLine."No.");
            NewAmount :=
              CalculateAdjustedAmount(
                ServiceItemLine2, TempServiceLine."Amount Including VAT", TotalAmount, GeneralLedgerSetup."Inv. Rounding Precision (LCY)");
            UnitPrice :=
              Round(((Round(NewAmount / (1 + TempServiceLine."VAT %" / 100),
                        GeneralLedgerSetup."Inv. Rounding Precision (LCY)") * 100) / (100 - TempServiceLine."Line Discount %")) /
                TempServiceLine.Quantity, GeneralLedgerSetup."Unit-Amount Rounding Precision");
            VerifyAdjustedAmount(TempServiceLine, ServiceLine, NewAmount, UnitPrice, GeneralLedgerSetup."Inv. Rounding Precision (LCY)");
            TempServiceLine.Next();
        until ServiceLine.Next() = 0;
    end;

    [Normal]
    local procedure VerifyPriceAdjustmentMinimum(var TempServiceLine: Record "Service Line" temporary; ServiceItemLine2: Record "Service Item Line")
    var
        ServiceLine: Record "Service Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        TotalAmount: Decimal;
        NewAmount: Decimal;
    begin
        GeneralLedgerSetup.Get();
        TotalAmount := CalculateTotalAmount(TempServiceLine, false);
        FindServiceLine(ServiceLine, ServiceItemLine2);
        repeat
            ServiceLine.TestField("No.", TempServiceLine."No.");
            NewAmount :=
              CalculateAdjustedAmount(
                ServiceItemLine2, TempServiceLine.Amount, TotalAmount, GeneralLedgerSetup."Inv. Rounding Precision (LCY)");
            if TotalAmount < ServiceItemLine2."Base Amount to Adjust" then
                VerifyAdjustAmountWithOutVAT(TempServiceLine, ServiceLine, GeneralLedgerSetup, NewAmount)
            else
                VerifyWithOldServiceLine(TempServiceLine, ServiceLine);
            TempServiceLine.Next();
        until ServiceLine.Next() = 0;
    end;

    [Normal]
    local procedure VerifyPriceAdjustmentMaximum(var TempServiceLine: Record "Service Line" temporary; ServiceItemLine2: Record "Service Item Line")
    var
        ServiceLine: Record "Service Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        TotalAmount: Decimal;
        NewAmount: Decimal;
    begin
        GeneralLedgerSetup.Get();
        TotalAmount := CalculateTotalAmount(TempServiceLine, false);
        FindServiceLine(ServiceLine, ServiceItemLine2);
        repeat
            ServiceLine.TestField("No.", TempServiceLine."No.");
            NewAmount :=
              CalculateAdjustedAmount(
                ServiceItemLine2, TempServiceLine.Amount, TotalAmount, GeneralLedgerSetup."Inv. Rounding Precision (LCY)");
            if TotalAmount > ServiceItemLine2."Base Amount to Adjust" then
                VerifyAdjustAmountWithOutVAT(TempServiceLine, ServiceLine, GeneralLedgerSetup, NewAmount)
            else
                VerifyWithOldServiceLine(TempServiceLine, ServiceLine);
            TempServiceLine.Next();
        until ServiceLine.Next() = 0;
    end;

    [Normal]
    local procedure VerifyPricAdjustMaxWithInclVAT(var TempServiceLine: Record "Service Line" temporary; ServiceItemLine2: Record "Service Item Line")
    var
        ServiceLine: Record "Service Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        TotalAmount: Decimal;
        NewAmount: Decimal;
        UnitPrice: Decimal;
    begin
        GeneralLedgerSetup.Get();
        TotalAmount := CalculateTotalAmount(TempServiceLine, true);
        FindServiceLine(ServiceLine, ServiceItemLine2);
        repeat
            ServiceLine.TestField("No.", TempServiceLine."No.");
            NewAmount :=
              CalculateAdjustedAmount(
                ServiceItemLine2, TempServiceLine."Amount Including VAT", TotalAmount, GeneralLedgerSetup."Inv. Rounding Precision (LCY)");
            UnitPrice :=
              Round(((Round(NewAmount / (1 + TempServiceLine."VAT %" / 100),
                        GeneralLedgerSetup."Inv. Rounding Precision (LCY)") * 100) / (100 - TempServiceLine."Line Discount %")) /
                TempServiceLine.Quantity, GeneralLedgerSetup."Unit-Amount Rounding Precision");
            if TotalAmount > ServiceItemLine2."Base Amount to Adjust" then
                VerifyAdjustedAmount(TempServiceLine, ServiceLine, NewAmount, UnitPrice, GeneralLedgerSetup."Inv. Rounding Precision (LCY)")
            else
                VerifyWithOldServiceLine(TempServiceLine, ServiceLine);
            TempServiceLine.Next();
        until ServiceLine.Next() = 0;
    end;

    [Normal]
    local procedure VerifyAdjustAmountWithOutVAT(var TempServiceLine: Record "Service Line" temporary; var ServiceLine: Record "Service Line"; GeneralLedgerSetup: Record "General Ledger Setup"; NewAmount: Decimal)
    begin
        ServiceLine.TestField(Amount, NewAmount);
        ServiceLine.TestField(
          "Unit Price", Round((NewAmount * 100 / (100 - TempServiceLine."Line Discount %")) /
            TempServiceLine.Quantity, GeneralLedgerSetup."Unit-Amount Rounding Precision"));
        Assert.AreNearlyEqual(
          ServiceLine."Line Discount Amount",
          Round(
            NewAmount / (100 - TempServiceLine."Line Discount %") *
            TempServiceLine."Line Discount %", GeneralLedgerSetup."Inv. Rounding Precision (LCY)"),
          GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(AmountError, ServiceLine.FieldCaption("Line Discount Amount"), 'Line Discount Amount'));
    end;

    [Normal]
    local procedure VerifyWithOldServiceLine(var TempServiceLine: Record "Service Line" temporary; var ServiceLine: Record "Service Line")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        ServiceLine.TestField("Amount Including VAT", TempServiceLine."Amount Including VAT");
        ServiceLine.TestField(Amount, TempServiceLine.Amount);
        ServiceLine.TestField("Unit Price", TempServiceLine."Unit Price");
        Assert.AreNearlyEqual(
          ServiceLine."Line Discount Amount",
          TempServiceLine."Line Discount Amount",
          GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(AmountError, ServiceLine.FieldCaption("Line Discount Amount"), 'Line Discount Amount'));
    end;

    [Normal]
    local procedure VerifyAdjustedAmount(var TempServiceLine: Record "Service Line" temporary; var ServiceLine: Record "Service Line"; NewAmount: Decimal; UnitPrice: Decimal; RoundingPrecision: Decimal)
    begin
        ServiceLine.TestField("Amount Including VAT", NewAmount);
        ServiceLine.TestField(Amount, Round(NewAmount / (1 + TempServiceLine."VAT %" / 100), RoundingPrecision));
        ServiceLine.TestField("Unit Price", UnitPrice);
        ServiceLine.TestField(
          "Line Discount Amount",
          Round(
            Round(UnitPrice * TempServiceLine.Quantity, RoundingPrecision) *
            TempServiceLine."Line Discount %" / 100, RoundingPrecision));
    end;

    [Normal]
    local procedure VerifyPricAdjustMinWithInclVAT(var TempServiceLine: Record "Service Line" temporary; ServiceItemLine2: Record "Service Item Line")
    var
        ServiceLine: Record "Service Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        TotalAmount: Decimal;
        NewAmount: Decimal;
        UnitPrice: Decimal;
    begin
        GeneralLedgerSetup.Get();
        TotalAmount := CalculateTotalAmount(TempServiceLine, true);
        FindServiceLine(ServiceLine, ServiceItemLine2);
        repeat
            ServiceLine.TestField("No.", TempServiceLine."No.");
            NewAmount :=
              CalculateAdjustedAmount(
                ServiceItemLine2, TempServiceLine."Amount Including VAT", TotalAmount, GeneralLedgerSetup."Inv. Rounding Precision (LCY)");
            UnitPrice :=
              Round(((Round(NewAmount / (1 + TempServiceLine."VAT %" / 100),
                        GeneralLedgerSetup."Inv. Rounding Precision (LCY)") * 100) / (100 - TempServiceLine."Line Discount %")) /
                TempServiceLine.Quantity, GeneralLedgerSetup."Unit-Amount Rounding Precision");
            if TotalAmount < ServiceItemLine2."Base Amount to Adjust" then
                VerifyAdjustedAmount(TempServiceLine, ServiceLine, NewAmount, UnitPrice, GeneralLedgerSetup."Inv. Rounding Precision (LCY)")
            else
                VerifyWithOldServiceLine(TempServiceLine, TempServiceLine);
            TempServiceLine.Next();
        until ServiceLine.Next() = 0;
    end;

    local procedure AdjustVATRate(VATProdPostingGroup: Code[20]; NewRate: Decimal) OldRate: Decimal;
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindVATPostingSetupInvt(VATPostingSetup);
        VATPostingSetup.Get(VATPostingSetup."VAT Bus. Posting Group", VATProdPostingGroup);
        OldRate := VATPostingSetup."VAT %";
        VATPostingSetup."VAT %" := NewRate;
        VATPostingSetup.Modify();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalFormHandler(var ServiceLinePriceAdjmtForm: Page "Service Line Price Adjmt."; var Response: Action)
    var
        ServiceHeader: Record "Service Header";
        ServPriceGroupSetup: Record "Serv. Price Group Setup";
        ServiceLinePriceAdjmt: Record "Service Line Price Adjmt.";
        ServicePriceManagement: Codeunit "Service Price Management";
    begin
        // Run Service Price Adjustment on Service Order.
        ServiceLinePriceAdjmt.SetRange("Document Type", ServiceItemLine."Document Type");
        ServiceLinePriceAdjmt.SetRange("Document No.", ServiceItemLine."Document No.");
        ServiceLinePriceAdjmt.SetRange("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLinePriceAdjmt.FindFirst();
        ServiceHeader.Get(ServiceItemLine."Document Type", ServiceItemLine."Document No.");
        ServicePriceManagement.GetServPriceGrSetup(ServPriceGroupSetup, ServiceHeader, ServiceItemLine);
        ServicePriceManagement.AdjustLines(ServiceLinePriceAdjmt, ServPriceGroupSetup);
        Commit();
        ServiceLinePriceAdjmtForm.UpdateAmounts();
        Response := ACTION::OK;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmMessageHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := not (Question = ServiceContractConfirmation);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;
}

