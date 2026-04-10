// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Test;

using Microsoft.Projects.Resources.Resource;
using Microsoft.Sales.Customer;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using Microsoft.Service.Item;
using Microsoft.Service.Pricing;
using Microsoft.Utilities;

codeunit 136113 "Service Line Update Validation"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Service Line] [Service]
        IsInitialized := false;
    end;

    var
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibraryResource: Codeunit "Library - Resource";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        NegativeQuantityError: Label '%1 must be positive in %2 %3=''%4'',%5=''%6'',%7=''%8''.';
        UnknownError: Label 'Unexpected Error';
        QuantityError: Label '%1 must not be less than %2 in %3 %4=''%5'',%6=''%7'',%8=''%9''.';
        QtyToShipError: Label 'You cannot ship more than %1 units.';
        QtyToInvoiceError: Label 'You cannot invoice more than %1 units.';
        QtyToConsumeError: Label 'You cannot consume more than %1 units.';
        ServiceShipmentLineError: Label '%1 must be %2 on %3 %4=%5.';

    [Normal]
    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Service Line Update Validation");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Service Line Update Validation");

        // Create Demonstration Database
        LibraryService.SetupServiceMgtNoSeries();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Service Line Update Validation");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NegativeQuantity()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceCost: Record "Service Cost";
    begin
        // Covers document number TC-PP-VR-1, TC-PP-VR-2, TC-PP-VR-3, TC-PP-VR-4 - refer to TFS ID 20884.
        // Test error occurs on Negative Quantity, Qty. to Ship, Qty. to Invoice and Qty. to Consume updation on Service Line.

        // 1. Create Service Order - Service Header, Service Item Line and Service Line with Type Item, Resource and Cost.
        CreateServiceOrder(ServiceHeader);
        LibraryService.FindServiceCost(ServiceCost);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Cost, ServiceCost.Code);
        Commit();

        // 2. Verify: Verify error occurs "Quantity must be Positive" on updating Negative Quantity, Qty. to Ship, Qty. to Invoice
        // and Qty. to Consume on All Service Lines.
        // Use Random because value is not important.
        VerifyNegativeQuantity(ServiceLine, LibraryRandom.RandInt(10));
        VerifyNegativeQtyToShip(ServiceLine, LibraryRandom.RandInt(10));
        VerifyNegativeQtyToInvoice(ServiceLine, LibraryRandom.RandInt(10));
        VerifyNegativeQtyToConsume(ServiceLine, LibraryRandom.RandInt(10));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FractionQuantity()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceCost: Record "Service Cost";
        Quantity: Decimal;
    begin
        // Covers document number TC-PP-VR-1 - refer to TFS ID 20884.
        // Test Fraction Quantity Successfully updated on Service Line.

        // 1. Setup: Create Service Order - Service Header, Service Item Line and Service Line with Type Item, Resource and Cost.
        CreateServiceOrder(ServiceHeader);
        LibraryService.FindServiceCost(ServiceCost);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Cost, ServiceCost.Code);

        // 2. Exercise: Update fraction Quantity on Service Line.
        Quantity := LibraryUtility.GenerateRandomFraction();
        UpdateFractionQuantity(ServiceLine, Quantity);

        // 3. Verify: Verify that Quantity Successfully updated with Fraction Value on All Service Lines.
        VerifyFractionQuantity(ServiceLine, Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FractionQuantityToShip()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceCost: Record "Service Cost";
        Quantity: Decimal;
    begin
        // Covers document number TC-PP-VR-2 - refer to TFS ID 20884.
        // Test Fraction Quantity to Ship Successfully updated on Service Line.

        // 1. Setup: Create Service Order - Service Header, Service Item Line and Service Line with Type Item, Resource and Cost.
        CreateServiceOrder(ServiceHeader);
        LibraryService.FindServiceCost(ServiceCost);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Cost, ServiceCost.Code);

        // 2. Exercise: Update fraction Qty. to Ship on Service Line.
        Quantity := LibraryUtility.GenerateRandomFraction();
        UpdateFractionQtyToShip(ServiceLine, Quantity);

        // 3. Verify: Verify that Qty. to Ship Successfully updated with Fraction Value on All Service Lines.
        VerifyFractionQtyToShip(ServiceLine, Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FractionQuantityToInvoice()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceCost: Record "Service Cost";
        Quantity: Decimal;
    begin
        // Covers document number TC-PP-VR-3 - refer to TFS ID 20884.
        // Test Fraction Quantity to Invoice Successfully updated on Service Line.

        // 1. Setup: Create Service Order - Service Header, Service Item Line and Service Line with Type Item, Resource and Cost.
        CreateServiceOrder(ServiceHeader);
        LibraryService.FindServiceCost(ServiceCost);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Cost, ServiceCost.Code);

        // 2. Exercise: Update fraction Qty. to Invoice on Service Line.
        Quantity := LibraryUtility.GenerateRandomFraction();
        UpdateFractionQtyToInvoice(ServiceLine, Quantity);

        // 3. Verify: Verify that Qty. to Invoice Successfully updated with Fraction Value on All Service Lines.
        VerifyFractionQtyToInvoice(ServiceLine, Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FractionQuantityToConsume()
    var
        ServiceHeader: Record "Service Header";
        Quantity: Decimal;
    begin
        // Covers document number TC-PP-VR-4 - refer to TFS ID 20884.
        // Test Fraction Quantity to Consume Successfully updated on Service Line.

        // 1. Setup: Create Service Order - Service Header, Service Item Line and Service Line with Type Item, and Resource.
        CreateServiceOrder(ServiceHeader);

        // 2. Exercise: Update fraction Qty. to Consume on Service Line.
        Quantity := LibraryUtility.GenerateRandomFraction();
        UpdateFractionQtyToConsume(ServiceHeader, Quantity);

        // 3. Verify: Verify that Qty. to Consume Successfully updated with Fraction Value on All Service Lines.
        VerifyFractionQtyToConsume(ServiceHeader, Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyLimitOnSameQty()
    var
        ServiceHeader: Record "Service Header";
        TempServiceLine: Record "Service Line" temporary;
    begin
        // Covers document number TC-PP-VR-5 - refer to TFS ID 20884.
        // Test same value of Quantity Successfully updated on Service Line.

        // 1. Setup: Create Service Order - Service Header, Service Item Line, Service Line with Type Item and Post Order in Multiple Steps.
        CreateAndPostServiceOrder(ServiceHeader);

        // 2. Exercise: Save Service Line in Temporary Table and Update same value of Quantity on Service Line.
        SaveServiceLineInTempTable(TempServiceLine, ServiceHeader);
        UpdateQtyOnServiceLine(ServiceHeader, 0);  // Use 0 for same Quantity Updation.

        // 3. Verify: Verify that Quantity Successfully updated with Same Value of Quantity on All Service Lines.
        VerifyQuantityUpdation(TempServiceLine, 0);  // Use 0 for same Quantity Updation.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyLimitGreaterThanQty()
    var
        ServiceHeader: Record "Service Header";
        TempServiceLine: Record "Service Line" temporary;
        Quantity: Decimal;
    begin
        // Covers document number TC-PP-VR-5 - refer to TFS ID 20884.
        // Test greater value of Quantity Successfully updated on Service Line.

        // 1. Setup: Create Service Order - Service Header, Service Item Line, Service Line with Type Item and Post Order in Multiple Steps.
        CreateAndPostServiceOrder(ServiceHeader);

        // 2. Exercise: Save Service Line in Temporary Table and Update greater value of Quantity on Service Line.
        SaveServiceLineInTempTable(TempServiceLine, ServiceHeader);
        Quantity := LibraryRandom.RandInt(10);  // Use Random because value is not important.
        UpdateQtyOnServiceLine(ServiceHeader, Quantity);

        // 3. Verify: Verify that Quantity Successfully updated with Greater value than Quantity on All Service Lines.
        VerifyQuantityUpdation(TempServiceLine, Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyLimitLessThanQtyShipped()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Covers document number TC-PP-VR-5 - refer to TFS ID 20884.
        // Test error occurs on less value of Quantity updation on Service Line.

        // 1. Create Service Order - Service Header, Service Item Line, Service Line with Type Item and Post Order in Multiple Steps.
        CreateAndPostServiceOrder(ServiceHeader);

        // 2. Verify: Verify that error occurs "Quantity cannot be less than" on Updating Quantity less than Quantity Shipped on all Service
        // Lines.
        VerifyLessQuantityUpdation(ServiceHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyToShipEqualRemainingQty()
    var
        ServiceHeader: Record "Service Header";
        TempServiceLine: Record "Service Line" temporary;
    begin
        // Covers document number TC-PP-VR-6 - refer to TFS ID 20884.
        // Test Qty. to Ship Successfully updated on Service Line equal Remaining Quantity.

        // 1. Setup: Create Service Order - Service Header, Service Item Line, Service Line with Type Item and Post Order in Multiple Steps.
        CreateAndPostServiceOrder(ServiceHeader);

        // 2. Exercise: Save Service Line in Temporary Table and Update Qty. to Ship on Service Line equal Remaining Quantity.
        SaveServiceLineInTempTable(TempServiceLine, ServiceHeader);
        UpdateEqualQtyToShip(ServiceHeader);

        // 3. Verify: Verify that Qty. to Ship Successfully updated with Remaining Quantity on All Service Lines.
        VerifyEqualQtyToShip(TempServiceLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyToShipGreaterRemainingQty()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Covers document number TC-PP-VR-6 - refer to TFS ID 20884.
        // Test error occurs on Qty. to Ship updation on Service Line greater than Remaining Quantity.

        // 1. Create Service Order - Service Header, Service Item Line, Service Line with Type Item and Post Order in Multiple Steps.
        CreateAndPostServiceOrder(ServiceHeader);

        // 2. Verify: Verify that error occurs "Qty. to Ship must not be Greater" on updating Qty. to Ship with greater than Remaining
        // Quantity on All Service Lines.
        VerifyGreaterQtyToShip(ServiceHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyToInvoiceEqualRemainingQty()
    var
        ServiceHeader: Record "Service Header";
        TempServiceLine: Record "Service Line" temporary;
    begin
        // Covers document number TC-PP-VR-7 - refer to TFS ID 20884.
        // Test Qty. to Invoice Successfully updated on Service Line equal Remaining Quantity.

        // 1. Setup: Create Service Order - Service Header, Service Item Line, Service Line with Type Item and Post Order in Multiple Steps.
        CreateAndPostServiceOrder(ServiceHeader);

        // 2. Exercise: Save Service Line in Temporary Table and Update Qty. to Invoice on Service Line equal Remaining Quantity.
        SaveServiceLineInTempTable(TempServiceLine, ServiceHeader);
        UpdateSameQtyToInvoice(ServiceHeader);

        // 3. Verify: Verify that Qty. to Invoice Successfully updated with Remaining Quantity on All Service Lines.
        VerifySameQtyToInvoice(TempServiceLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyToInvoiceLessRemainingQty()
    var
        ServiceHeader: Record "Service Header";
        TempServiceLine: Record "Service Line" temporary;
        FractionFactor: Decimal;
    begin
        // Covers document number TC-PP-VR-7 - refer to TFS ID 20884.
        // Test Qty. to Invoice Successfully updated on Service Line less than Remaining Quantity.

        // 1. Setup: Create Service Order - Service Header, Service Item Line, Service Line with Type Item and Post Order in Multiple Steps.
        CreateAndPostServiceOrder(ServiceHeader);

        // 2. Exercise: Save Service Line in Temporary Table and Update Qty. to Invoice on Service Line less than Remaining Quantity.
        SaveServiceLineInTempTable(TempServiceLine, ServiceHeader);
        FractionFactor := LibraryUtility.GenerateRandomFraction();
        UpdateLessQtyToInvoice(ServiceHeader, FractionFactor);

        // 3. Verify: Verify that Qty. to Invoice Successfully updated with less than Remaining Quantity on All Service Lines.
        VerifyLessQtyToInvoice(TempServiceLine, FractionFactor);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyToInvoiceLargeRemainingQty()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Covers document number TC-PP-VR-7 - refer to TFS ID 20884.
        // Test error occurs on Qty. to Invoice updation on Service Line with greater than Remaining Quantity.

        // 1. Create Service Order - Service Header, Service Item Line, Service Line with Type Item and Post Order in Multiple Steps.
        CreateAndPostServiceOrder(ServiceHeader);

        // Verify: Verify that error occurs "Qty. to Invoice must not be Greater" on updating Qty. to Invoice with greater than Remaining
        // Quantity on All Service Lines.
        VerifyGreaterQtyToInvoice(ServiceHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyToConsumeEqualZero()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Covers document number TC-PP-VR-8 - refer to TFS ID 20884.
        // Test Qty. to Consume Successfully updated on Service Line with zero.

        // 1. Setup: Create Service Order - Service Header, Service Item Line, Service Line with Type Item and Post Order in Multiple Steps.
        CreateAndPostServiceOrder(ServiceHeader);

        // 2. Exercise: Update Qty. to Consume on Service Line with Zero.
        UpdateZeroQtyToConsume(ServiceHeader);

        // 3. Verify: Verify that Qty. to Consume Successfully updated with 0 on All Service Lines.
        VerifyZeroQtyToConsumeUpdation(ServiceHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyToConsumeLessRemainQty()
    var
        ServiceHeader: Record "Service Header";
        TempServiceLine: Record "Service Line" temporary;
    begin
        // Covers document number TC-PP-VR-8 - refer to TFS ID 20884.
        // Test Qty. to Consume Successfully updated on Service Line less than Remaining Quantity.

        // 1. Setup: Create Service Order - Service Header, Service Item Line, Service Line with Type Item and Post Order in Multiple Steps.
        CreateAndPostServiceOrder(ServiceHeader);

        // 2. Exercise: Save Service Line in Temporary Table and Update Qty. to Consume on Service Line less than Remaining Quantity.
        SaveServiceLineInTempTable(TempServiceLine, ServiceHeader);
        UpdateLessQtyToConsume(ServiceHeader);

        // 3. Verify: Verify that Qty. to Consume Successfully updated with less than Remaining Quantity on All Service Lines.
        VerifyLessQtyToConsume(TempServiceLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyToConsumeGreaterRemainQty()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Covers document number TC-PP-VR-8 - refer to TFS ID 20884.
        // Test error occurs on Qty. to Consume updation on Service Line with greater than Remaining Quantity.

        // 1. Create Service Order - Service Header, Service Item Line, Service Line with Type Item and Post Order in Multiple Steps.
        CreateAndPostServiceOrder(ServiceHeader);

        // 2. Verify: Verify that error occurs "Qty. to Consume must not be Greater" on updating Qty. to Consume with greater than Remaining
        // Quantity on All Service Lines.
        VerifyGreaterQtyToConsume(ServiceHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingAsShipWithCurrency()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Covers document number TC-PP-SV-1 - refer to TFS ID 20885.
        // Test Service Line values after Post Service Order as Ship with Currency Code.

        // 1. Setup: Create Service Order with Customer having Currency Code.
        CreateServiceOrderWithCurrency(ServiceHeader);

        // 2. Exercise: Post Service Order as Ship Partially.
        UpdatePartQtyToShip(ServiceHeader);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // 3. Verify: Verify the Values of Service Line after Posting.
        VerifyServiceLineAfterShip(ServiceHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingAsConsumeWithCurrency()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Covers document number TC-PP-SV-1 - refer to TFS ID 20885.
        // Test Service Line values after Post Service Order as Ship and Consume with Currency Code.

        // 1. Setup: Create Service Order with Customer having Currency Code.
        CreateServiceOrderWithCurrency(ServiceHeader);

        // 2. Exercise: Post Service Order as Ship and Consume Partially.
        UpdateQtyToConsume(ServiceHeader);
        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);

        // 3. Verify: Verify the Values of Service Line after Posting.
        VerifyServiceLineAfterConsume(ServiceHeader);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler')]
    [Scope('OnPrem')]
    procedure UndoConsumptionWithCurrency()
    var
        ServiceHeader: Record "Service Header";
        ServiceShipmentLine: Record "Service Shipment Line";
    begin
        // Covers document number TC-PP-SV-1 - refer to TFS ID 20885.
        // Test Service Line values after Undo Consumption with Currency Code.

        // 1. Setup: Create Service Order with Customer having Currency Code, Update Qty. to Consume on Service Line.
        CreateServiceOrderWithCurrency(ServiceHeader);

        UpdateQtyToConsume(ServiceHeader);

        // 2. Exercise: Post Service Order as Ship and Consume Partially, Undo Consumption.
        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);
        ServiceShipmentLine.SetRange("Order No.", ServiceHeader."No.");
        CODEUNIT.Run(CODEUNIT::"Undo Service Consumption Line", ServiceShipmentLine);

        // 3. Verify: Verify the Values of Service Line after Posting.
        VerifyUndoServiceLine(ServiceHeader);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler')]
    [Scope('OnPrem')]
    procedure UndoShipmentWithCurrency()
    var
        ServiceHeader: Record "Service Header";
        ServiceShipmentLine: Record "Service Shipment Line";
    begin
        // Covers document number TC-PP-SV-1, TC-PP-VR-17 - refer to TFS ID 20885.
        // Test Service Line values after Undo Shipment with Currency Code.

        // 1. Setup: Create Service Order with Customer having Currency Code, Update Qty. to Ship on Service line.
        CreateServiceOrderWithCurrency(ServiceHeader);

        UpdatePartQtyToShip(ServiceHeader);

        // 2. Exercise: Post Service Order as Ship and Consume Partially, Undo Consumption.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
        ServiceShipmentLine.SetRange("Order No.", ServiceHeader."No.");
        CODEUNIT.Run(CODEUNIT::"Undo Service Shipment Line", ServiceShipmentLine);

        // Verify: Verify the Values of Service Line after Posting.
        VerifyUndoServiceLine(ServiceHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingAsShipInvoiceCurrency()
    var
        ServiceHeader: Record "Service Header";
        TempServiceLine: Record "Service Line" temporary;
    begin
        // Covers document number TC-PP-SV-1 - refer to TFS ID 20885.
        // Test Service Line values after Post Service Order as Ship and Invoice with Currency Code.

        // 1. Setup: Create Service Order with Customer having Currency Code.
        CreateServiceOrderWithCurrency(ServiceHeader);

        // 2. Exercise: Post Service Order as Ship and Invoice Partially.
        UpdateQtyToInvoice(ServiceHeader);
        SaveServiceLineInTempTable(TempServiceLine, ServiceHeader);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // 3. Verify: Verify the Values of Service Line after Posting.
        VerifyServiceLine(TempServiceLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingAsInvoiceWithCurrency()
    var
        ServiceHeader: Record "Service Header";
        TempServiceLine: Record "Service Line" temporary;
    begin
        // Covers document number TC-PP-SV-1 - refer to TFS ID 20885.
        // Test Service Line values after Post Service Order as Invoice with Currency Code.

        // 1. Setup: Create Service Order with Customer having Currency Code.
        CreateServiceOrderWithCurrency(ServiceHeader);

        // 2. Exercise: Post Service Order as Ship Partially, Post Service Order as Invoice Partially.
        UpdatePartQtyToShip(ServiceHeader);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
        UpdatePartQtyToInvoice(ServiceHeader);
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        SaveServiceLineInTempTable(TempServiceLine, ServiceHeader);
        LibraryService.PostServiceOrder(ServiceHeader, false, false, true);

        // 3. Verify: Verify the Values of Service Line after Posting.
        VerifyServiceLineAfterInvoice(TempServiceLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnitPriceOnServiceLine()
    var
        ServiceHeader: Record "Service Header";
        UnitPrice: Decimal;
    begin
        // Covers document number TC-PP-SV-1 - refer to TFS ID 20885.
        // Test Unit Price Updation on Service Line with Currency Code.

        // 1. Setup: Create Service Order with Customer having Currency Code.
        CreateServiceOrderWithCurrency(ServiceHeader);

        // 2. Exercise: Update Unit Price on all Service Lines.
        UnitPrice := LibraryRandom.RandInt(10);  // Use Random because value is not important.
        UpdateUnitPriceOnServiceLine(ServiceHeader, UnitPrice);

        // 3. Verify: Verify that Unit Price Successfully updated on all Service Lines.
        VerifyUnitPriceOnServiceLine(ServiceHeader, UnitPrice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnitCostOnServiceLine()
    var
        ServiceHeader: Record "Service Header";
        UnitCost: Decimal;
    begin
        // Covers document number TC-PP-SV-1 - refer to TFS ID 20885.
        // Test Unit Cost Updation on Service Line with Currency Code.

        // 1. Setup: Create Service Order with Customer having Currency Code.
        CreateServiceOrderWithCurrency(ServiceHeader);

        // 2. Exercise: Update Unit Cost on all Service Lines.
        UnitCost := LibraryRandom.RandInt(10);  // Use Random because value is not important.
        UpdateUnitCostOnServiceLine(ServiceHeader, UnitCost);

        // 3. Verify: Verify that Unit Cost Successfully updated on all Service Lines.
        VerifyUnitCostOnServiceLine(ServiceHeader, UnitCost);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyEqualSameQtyResource()
    var
        ServiceHeader: Record "Service Header";
        TempServiceLine: Record "Service Line" temporary;
    begin
        // Covers document number TC-PP-VR-9 - refer to TFS ID 20884.
        // Test same value of Quantity Successfully updated on Service Line with Type Item and Resource.

        // 1. Setup: Create Service Order - Service Header, Service Item Line, Service Line with Type Item, Resource and Post Order in
        // Multiple Steps.
        CreateAndPostOrderResource(ServiceHeader);

        // 2. Exercise: Save Service Line in Temporary Table and Update same value of Quantity on Service Line.
        SaveServiceLineInTempTable(TempServiceLine, ServiceHeader);
        UpdateQtyOnServiceLine(ServiceHeader, 0);  // Use 0 for same Quantity Updation.

        // 3. Verify: Verify that Quantity Successfully updated with Same Value of Quantity on All Service Lines.
        VerifyQuantityUpdation(TempServiceLine, 0);  // Use 0 for same Quantity Updation.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyGreaterThanQtyResource()
    var
        ServiceHeader: Record "Service Header";
        TempServiceLine: Record "Service Line" temporary;
        Quantity: Decimal;
    begin
        // Covers document number TC-PP-VR-9 - refer to TFS ID 20884.
        // Test greater value of Quantity Successfully updated on Service Line with Type Item and Resource.

        // 1. Setup: Create Service Order - Service Header, Service Item Line, Service Line with Type Item, Resource and Post Order in
        // Multiple Steps.
        CreateAndPostOrderResource(ServiceHeader);

        // 2. Exercise: Save Service Line in Temporary Table and Update greater value of Quantity on Service Line.
        SaveServiceLineInTempTable(TempServiceLine, ServiceHeader);
        Quantity := LibraryRandom.RandInt(10);  // Use Random because value is not important.
        UpdateQtyOnServiceLine(ServiceHeader, Quantity);

        // 3. Verify: Verify that Quantity Successfully updated with Greater value than Quantity on All Service Lines.
        VerifyQuantityUpdation(TempServiceLine, Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyEqualQtyShippedResource()
    var
        ServiceHeader: Record "Service Header";
        TempServiceLine: Record "Service Line" temporary;
    begin
        // Covers document number TC-PP-VR-9 - refer to TFS ID 20884.
        // Test Quantity Successfully updated on Service Line equal Quantity Shipped with Type Item and Resource.

        // 1. Setup: Create Service Order - Service Header, Service Item Line, Service Line with Type Item, Resource and Post Order in
        // Multiple Steps.
        CreateAndPostOrderResource(ServiceHeader);

        // 2. Exercise: Save Service Line in Temporary Table and Update Quantity equal Quantity Shipped on Service Line.
        SaveServiceLineInTempTable(TempServiceLine, ServiceHeader);
        UpdateQtyEqualQuantityShipped(ServiceHeader);

        // 3. Verify: Verify that Quantity Successfully updated with equal Quantity Shipped on All Service Lines.
        VerifyQtyToShipUpdation(TempServiceLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyToShipRemainingQtyResource()
    var
        ServiceHeader: Record "Service Header";
        TempServiceLine: Record "Service Line" temporary;
    begin
        // Covers document number TC-PP-VR-10 - refer to TFS ID 20884.
        // Test Qty. to Ship Successfully updated on Service Line equal Remaining Quantity with Type Item and Resource.

        // 1. Setup: Create Service Order - Service Header, Service Item Line, Service Line with Type Item, Resource and Post Order in
        // Multiple Steps.
        CreateAndPostOrderResource(ServiceHeader);

        // 2. Exercise: Save Service Line in Temporary Table and Update Qty. to Ship on Service Line equal Remaining Quantity.
        SaveServiceLineInTempTable(TempServiceLine, ServiceHeader);
        UpdateEqualQtyToShip(ServiceHeader);

        // 3. Verify: Verify that Qty. to Ship Successfully updated with Remaining Quantity on All Service Lines.
        VerifyEqualQtyToShip(TempServiceLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyToShipEqualZeroResource()
    var
        ServiceHeader: Record "Service Header";
        TempServiceLine: Record "Service Line" temporary;
    begin
        // Covers document number TC-PP-VR-10 - refer to TFS ID 20884.
        // Test Qty. to Ship Successfully updated on Service Line equal Zero with Type Item and Resource.

        // 1. Setup: Create Service Order - Service Header, Service Item Line, Service Line with Type Item, Resource and Post Order in
        // Multiple Steps.
        CreateAndPostOrderResource(ServiceHeader);

        // 2. Exercise: Save Service Line in Temporary Table and Update Qty. to Ship on Service Line equal Zero.
        SaveServiceLineInTempTable(TempServiceLine, ServiceHeader);
        UpdateZeroQtyToShip(ServiceHeader);

        // 3. Verify: Verify that Qty. to Ship Successfully updated with Zero on All Service Lines.
        VerifyZeroQtyToShip(TempServiceLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyToShipLessRemainingResource()
    var
        ServiceHeader: Record "Service Header";
        TempServiceLine: Record "Service Line" temporary;
        FractionFactor: Decimal;
    begin
        // Covers document number TC-PP-VR-10 - refer to TFS ID 20884.
        // Test Qty. to Ship Successfully updated on Service Line less than Remaining Quantity with Type Item and Resource.

        // 1. Setup: Create Service Order - Service Header, Service Item Line, Service Line with Type Item, Resource and Post Order in
        // Multiple Steps.
        CreateAndPostOrderResource(ServiceHeader);

        // 2. Exercise: Save Service Line in Temporary Table and Update Qty. to Ship on Service Line less than Remaining Quantity.
        SaveServiceLineInTempTable(TempServiceLine, ServiceHeader);
        FractionFactor := LibraryUtility.GenerateRandomFraction();
        UpdateLessQtyToShip(ServiceHeader, FractionFactor);

        // 3. Verify: Verify that Qty. to Ship Successfully updated with less than Remaining Quantity on All Service Lines.
        VerifyLessQtyToShipUpdation(TempServiceLine, FractionFactor);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyToInvoiceRemainingResource()
    var
        ServiceHeader: Record "Service Header";
        TempServiceLine: Record "Service Line" temporary;
    begin
        // Covers document number TC-PP-VR-11 - refer to TFS ID 20884.
        // Test Qty. to Invoice Successfully updated on Service Line equal Remaining Quantity with Type Item and Resource.

        // 1. Setup: Create Service Order - Service Header, Service Item Line, Service Line with Type Item, Resource and Post Order in
        // Multiple Steps.
        CreateAndPostOrderResource(ServiceHeader);

        // 2. Exercise: Save Service Line in Temporary Table and Update Qty. to Invoice on Service Line equal Remaining Quantity.
        SaveServiceLineInTempTable(TempServiceLine, ServiceHeader);
        UpdateSameQtyToInvoice(ServiceHeader);

        // 3. Verify: Verify that Qty. to Invoice Successfully updated with Remaining Quantity on All Service Lines.
        VerifySameQtyToInvoice(TempServiceLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyToInvoiceEqualZeroResource()
    var
        ServiceHeader: Record "Service Header";
        TempServiceLine: Record "Service Line" temporary;
    begin
        // Covers document number TC-PP-VR-11 - refer to TFS ID 20884.
        // Test Qty. to Invoice Successfully updated on Service Line equal Zero with Type Item and Resource.

        // 1. Setup: Create Service Order - Service Header, Service Item Line, Service Line with Type Item, Resource and Post Order in
        // Multiple Steps.
        CreateAndPostOrderResource(ServiceHeader);

        // 2. Exercise: Save Service Line in Temporary Table and Update Qty. to Invoice on Service Line equal Zero.
        SaveServiceLineInTempTable(TempServiceLine, ServiceHeader);
        UpdateZeroQtyToInvoice(ServiceHeader);

        // 3. Verify: Verify that Qty. to Invoice Successfully updated with Zero on All Service Lines.
        VerifyZeroQtyToInvoice(TempServiceLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyToInvoiceLessResource()
    var
        ServiceHeader: Record "Service Header";
        TempServiceLine: Record "Service Line" temporary;
        FractionFactor: Decimal;
    begin
        // Covers document number TC-PP-VR-11 - refer to TFS ID 20884.
        // Test Qty. to Invoice Successfully updated on Service Line less than Remaining Quantity with Type Item and Resource.

        // 1. Setup: Create Service Order - Service Header, Service Item Line, Service Line with Type Item, Resource and Post Order in
        // Multiple Steps.
        CreateAndPostOrderResource(ServiceHeader);

        // 2. Exercise: Save Service Line in Temporary Table and Update Qty. to Invoice on Service Line less than Remaining Quantity.
        SaveServiceLineInTempTable(TempServiceLine, ServiceHeader);
        FractionFactor := LibraryUtility.GenerateRandomFraction();
        UpdateLessQtyToInvoice(ServiceHeader, FractionFactor);

        // 3. Verify: Verify that Qty. to Invoice Successfully updated with less than Remaining Quantity on All Service Lines.
        VerifyLessQtyToInvoice(TempServiceLine, FractionFactor);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyToConsumeEqualZeroResource()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Covers document number TC-PP-VR-12 - refer to TFS ID 20884.
        // Test Qty. to Consume Successfully updated on Service Line equal zero with Type Item and Resource.

        // 1. Setup: Create Service Order - Service Header, Service Item Line, Service Line with Type Item, Resource and Post Order in
        // Multiple Steps.
        CreateAndPostOrderResource(ServiceHeader);

        // 2. Exercise: Update Qty. to Consume on Service Line with Zero.
        UpdateZeroQtyToConsume(ServiceHeader);

        // 3. Verify: Verify that Qty. to Consume Successfully updated with Zero on All Service Lines.
        VerifyZeroQtyToConsumeUpdation(ServiceHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyToConsumeLessResource()
    var
        ServiceHeader: Record "Service Header";
        TempServiceLine: Record "Service Line" temporary;
    begin
        // Covers document number TC-PP-VR-12 - refer to TFS ID 20884.
        // Test Qty. to Consume Successfully updated on Service Line less than Remaining Quantity with Type Item and Resource.

        // 1. Setup: Create Service Order - Service Header, Service Item Line, Service Line with Type Item, Resource and Post Order in
        // Multiple Steps.
        CreateAndPostOrderResource(ServiceHeader);

        // 2. Exercise: Save Service Line in Temporary Table and Update Qty. to Consume on Service Line less than Remaining Quantity.
        SaveServiceLineInTempTable(TempServiceLine, ServiceHeader);
        UpdateLessQtyToConsume(ServiceHeader);

        // 3. Verify: Verify that Qty. to Consume Successfully updated with less than Remaining Quantity on All Service Lines.
        VerifyLessQtyToConsume(TempServiceLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyToConsumeRemainingResource()
    var
        ServiceHeader: Record "Service Header";
        TempServiceLine: Record "Service Line" temporary;
    begin
        // Covers document number TC-PP-VR-12 - refer to TFS ID 20884.
        // Test Qty. to Consume Successfully updated on Service Line equal Remaining Quantity with Type Item and Resource.

        // 1. Setup: Create Service Order - Service Header, Service Item Line, Service Line with Type Item, Resource and Post Order in
        // Multiple Steps.
        CreateAndPostOrderResource(ServiceHeader);

        // 2. Exercise: Save Service Line in Temporary Table and Update Qty. to Consume on Service Line equal Remaining Quantity.
        SaveServiceLineInTempTable(TempServiceLine, ServiceHeader);
        UpdateSameQtyToConsume(ServiceHeader);

        // 3. Verify: Verify that Qty. to Consume Successfully updated with Remaining Quantity on All Service Lines.
        VerifySameQtyToConsumeUpdation(TempServiceLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipEqualRemainingQty()
    var
        ServiceHeader: Record "Service Header";
        TempServiceLine: Record "Service Line" temporary;
    begin
        // Covers document number TC-PP-VR-13 - refer to TFS ID 20884.
        // Test Service Line values after Post Service Order as Ship having "Qty. to Ship" equal Remaining Quantity with Type Item
        // and Resource.

        // 1. Setup: Create Service Order - Service Header, Service Item Line, Service Line with Type Item, Resource and Post Order in
        // Multiple Steps.
        CreateAndPostOrderResource(ServiceHeader);

        // 2. Exercise: Update Qty. to Ship on Service Line equal Remaining Quantity, Save Service Line in Temporary Table and Post Service
        // Order as Ship.
        UpdateEqualQtyToShip(ServiceHeader);
        SaveServiceLineInTempTable(TempServiceLine, ServiceHeader);
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // 3. Verify: Verify Values of Service Line after Posting.
        VerifyServiceLine(TempServiceLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipZeroQtyToShip()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Covers document number TC-PP-VR-13 - refer to TFS ID 20884.
        // Test error occurs on Posting Service Order as Ship having Zero "Qty. to Ship " with Type Item and Resource.

        // 1. Setup: Create Service Order - Service Header, Service Item Line, Service Line with Type Item, Resource and Post Order in
        // Multiple Steps.
        CreateAndPostOrderResource(ServiceHeader);

        // 2. Exercise: Update Zero Qty. to Ship on Service Line.
        UpdateZeroQtyToShip(ServiceHeader);

        // 3. Verify: Verify error occurs "Nothing to Post" on Posting Service Order as Ship.
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
        Assert.AreEqual(StrSubstNo(DocumentErrorsMgt.GetNothingToPostErrorMsg()), GetLastErrorText, UnknownError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoiceEqualRemainingQty()
    var
        ServiceHeader: Record "Service Header";
        TempServiceLine: Record "Service Line" temporary;
    begin
        // Covers document number TC-PP-VR-14 - refer to TFS ID 20884.
        // Test Service Line values after Post Service Order as Invoice having "Qty. to Invoice" equal Remaining Quantity with Type Item and
        // Resource.

        // 1. Setup: Create Service Order - Service Header, Service Item Line, Service Line with Type Item, Resource and Post Order in
        // Multiple Steps.
        CreateAndPostOrderResource(ServiceHeader);

        // 2. Exercise: Update Qty. to Invoice on Service Line equal Remaining Quantity, Save Service Line in Temporary Table and Post
        // Service Order as Invoice.
        UpdateSameQtyToInvoice(ServiceHeader);
        SaveServiceLineInTempTable(TempServiceLine, ServiceHeader);
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, false, false, true);

        // 3. Verify: Verify Values of Service Line after Posting.
        VerifyServiceLineAfterPosting(TempServiceLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoiceZeroQtyToInvoice()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Covers document number TC-PP-VR-14 - refer to TFS ID 20884.
        // Test error occurs on Posting Service Order as Invoice having Zero "Qty. to Invoice " with Type Item and Resource.

        // 1. Setup: Create Service Order - Service Header, Service Item Line, Service Line with Type Item, Resource and Post Order in
        // Multiple Steps.
        CreateAndPostOrderResource(ServiceHeader);

        // 2. Exercise: Update Zero Qty. to Invoice on Service Line.
        UpdateZeroQtyToInvoice(ServiceHeader);

        // 3. Verify: Verify error occurs "Nothing to Post" on Posting Service Order as Invoice.
        asserterror LibraryService.PostServiceOrder(ServiceHeader, false, false, true);
        Assert.AreEqual(StrSubstNo(DocumentErrorsMgt.GetNothingToPostErrorMsg()), GetLastErrorText, UnknownError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ConsumeEqualRemainingQty()
    var
        ServiceHeader: Record "Service Header";
        TempServiceLine: Record "Service Line" temporary;
    begin
        // Covers document number TC-PP-VR-15 - refer to TFS ID 20884.
        // Test Service Line values after Post Service Order as Ship and Consume having "Qty. to Consume" equal Remaining Quantity with Type
        // Item and Resource.

        // 1. Setup: Create Service Order - Service Header, Service Item Line, Service Line with Type Item, Resource and Post Order in
        // Multiple Steps.
        CreateAndPostOrderResource(ServiceHeader);

        // 2. Exercise: Update Qty. to Consume on Service Line equal Remaining Quantity, Save Service Line in Temporary Table and Post
        // Service Order as Ship and Consume.
        UpdateSameQtyToConsume(ServiceHeader);
        SaveServiceLineInTempTable(TempServiceLine, ServiceHeader);
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);

        // 3. Verify: Verify Values of Service Line after Posting.
        VerifyServiceLine(TempServiceLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ConsumeZeroQtyToConsume()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Covers document number TC-PP-VR-15 - refer to TFS ID 20884.
        // Test error occurs on Posting Service Order as Ship and Consume having Zero "Qty. to Consume" with Type Item and Resource.

        // 1. Setup: Create Service Order - Service Header, Service Item Line, Service Line with Type Item, Resource and Post Order in
        // Multiple Steps.
        CreateAndPostOrderResource(ServiceHeader);

        // 2. Exercise: Update Zero Qty. to Invoice on Service Line.
        UpdateZeroQtyToConsume(ServiceHeader);

        // 3. Verify: Verify error occurs "Nothing to Post" on Posting Service Order as Ship and Consume.
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, true, false);
        Assert.AreEqual(StrSubstNo(DocumentErrorsMgt.GetNothingToPostErrorMsg()), GetLastErrorText, UnknownError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipAndInvoiceZeroQtyToInvoice()
    var
        ServiceHeader: Record "Service Header";
        TempServiceLine: Record "Service Line" temporary;
    begin
        // Covers document number TC-PP-VR-16 - refer to TFS ID 20885.
        // Test Service Line values after Post Service Order as Ship and Invoice with Zero "Qty. to Invoice".

        // 1. Setup: Create Service Order - Service Header, Service Item Line, Service Line with Type Item, Resource and Post Order in
        // Multiple Steps.
        CreateAndPostOrderResource(ServiceHeader);

        // 2. Exercise: Update Qty. to Ship equal Remaining Quantity and Qty. to Invoice Zero on Service Line Save Service Line in
        // Temporary Table and Post Service Order as Ship and Invoice.
        UpdateEqualQtyToShip(ServiceHeader);
        UpdateZeroQtyToInvoice(ServiceHeader);
        SaveServiceLineInTempTable(TempServiceLine, ServiceHeader);
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // 3. Verify: Verify Values of Service Line after Posting.
        VerifyServiceLine(TempServiceLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipAndInvoiceWithoutQuantity()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Covers document number TC-PP-VR-16 - refer to TFS ID 20884.
        // Test error occurs on Posting Service Order as Ship and Invoice with Zero "Qty. to Ship" and "Qty. to Invoice".

        // 1. Setup: Create Service Order - Service Header, Service Item Line, Service Line with Type Item, Resource and Post Order in
        // Multiple Steps.
        CreateAndPostOrderResource(ServiceHeader);

        // 2. Exercise: Update Qty. to Ship and Qty. to Invoice Zero on Service Line.
        UpdateZeroQtyToShip(ServiceHeader);
        UpdateZeroQtyToInvoice(ServiceHeader);

        // 3. Verify: Verify error occurs "Nothing to Post" on Posting Service Order as Ship and Invoice.
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        Assert.AreEqual(StrSubstNo(DocumentErrorsMgt.GetNothingToPostErrorMsg()), GetLastErrorText, UnknownError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipAndInvoiceZeroQtyToShip()
    var
        ServiceHeader: Record "Service Header";
        TempServiceLine: Record "Service Line" temporary;
    begin
        // Covers document number TC-PP-VR-16 - refer to TFS ID 20884.
        // Test Service Line values after Post Service Order as Ship and Invoice with Zero "Qty. to Ship".

        // 1. Setup: Create Service Order - Service Header, Service Item Line, Service Line with Type Item, Resource and Post Order in
        // Multiple Steps.
        CreateAndPostOrderResource(ServiceHeader);

        // 2. Exercise: Update Qty. to Ship Zero and Qty. to Invoice equal Remaining Quantity on Service Line Save Service Line in
        // Temporary Table and Post Service Order as Ship and Invoice.
        UpdateZeroQtyToShip(ServiceHeader);
        UpdateSameQtyToInvoice(ServiceHeader);
        SaveServiceLineInTempTable(TempServiceLine, ServiceHeader);
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // 3. Verify: Verify Values of Service Line after Posting.
        VerifyServiceLine(TempServiceLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler')]
    [Scope('OnPrem')]
    procedure UndoShipmentPostedTwiceAsShip()
    var
        ServiceHeader: Record "Service Header";
        TempServiceLine: Record "Service Line" temporary;
        ServiceShipmentHeader: Record "Service Shipment Header";
        ServiceShipmentLine: Record "Service Shipment Line";
    begin
        // Covers document number TC-PP-VR-18 - refer to TFS ID 20884.
        // Test Service Line values after undo shipment Posted as Ship in Multiple Steps.

        // 1. Setup: Create Service Order - Service Header, Service Item Line, Service Line with Type Item. Update Qty. to Ship on Service
        // Line and Post Service Order as Ship two times.
        CreateServiceOrderWithItem(ServiceHeader);
        UpdatePartQtyToShip(ServiceHeader);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
        UpdateLessQtyToShip(ServiceHeader, LibraryUtility.GenerateRandomFraction());
        SaveServiceLineInTempTable(TempServiceLine, ServiceHeader);
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // 2. Exercise: Undo Shipment Service Shipment Line.
        ServiceShipmentHeader.SetRange("Order No.", ServiceHeader."No.");
        ServiceShipmentHeader.FindLast();
        ServiceShipmentLine.SetRange("Document No.", ServiceShipmentHeader."No.");
        CODEUNIT.Run(CODEUNIT::"Undo Service Shipment Line", ServiceShipmentLine);

        // 3. Verify: Verify Service Shipment Line and Service Line after Undo Shipment.
        VerifyShipmentLineAfterUndo(TempServiceLine);
        VerifyServiceLineAfterUndo(TempServiceLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler')]
    [Scope('OnPrem')]
    procedure UndoConsumptionPostedTwice()
    var
        ServiceHeader: Record "Service Header";
        TempServiceLine: Record "Service Line" temporary;
        ServiceShipmentHeader: Record "Service Shipment Header";
        ServiceShipmentLine: Record "Service Shipment Line";
    begin
        // Covers document number TC-PP-VR-19 - refer to TFS ID 20884.
        // Test Service Line values after undo consumption Posted as Ship and Consume in Multiple Steps.

        // 1. Setup: Create Service Order - Service Header, Service Item Line, Service Line with Type Item. Update Qty. to Ship on Service
        // Line and Post Service Order as Ship, Update Qty. to consume on Service Line and Post Service Order as Ship and Consume.
        CreateServiceOrderWithItem(ServiceHeader);
        UpdatePartQtyToShip(ServiceHeader);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
        UpdateLessQtyToConsume(ServiceHeader);
        SaveServiceLineInTempTable(TempServiceLine, ServiceHeader);
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);

        // 2. Exercise: Undo Consumption from Service Shipment Line.
        ServiceShipmentHeader.SetRange("Order No.", ServiceHeader."No.");
        ServiceShipmentHeader.FindLast();
        ServiceShipmentLine.SetRange("Document No.", ServiceShipmentHeader."No.");
        CODEUNIT.Run(CODEUNIT::"Undo Service Consumption Line", ServiceShipmentLine);

        // 3. Verify: Verify Service Shipment Line and Service Line after Undo Consumption.
        VerifyShipmentLineAfterUndo(TempServiceLine);
        VerifyServiceLineAfterUndo(TempServiceLine);
    end;

    [Normal]
    local procedure CreateAndPostOrderResource(var ServiceHeader: Record "Service Header")
    begin
        // Create Service Header with Document Type Order and Create Service Item Line, Create Service Line with Type Item, Resource, Update
        // Qty. to Ship and Post as Ship, Update Qty to Invoice and Post as Invoice, Update Qty. to Consume and Post as Ship and Consume.
        Initialize();
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, '');
        CreateServiceItemLine(ServiceHeader);
        CreateServiceLineForItem(ServiceHeader);
        CreateServiceLineForResource(ServiceHeader);
        UpdatePartQtyToShip(ServiceHeader);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        UpdatePartQtyToInvoice(ServiceHeader);
        LibraryService.PostServiceOrder(ServiceHeader, false, false, true);

        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        UpdatePartQtyToConsume(ServiceHeader);
        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);
    end;

    [Normal]
    local procedure CreateAndPostServiceOrder(var ServiceHeader: Record "Service Header")
    begin
        // 1. Setup: Create Service Header with Document Type Order and Create Service Item Line.
        Initialize();
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, '');
        CreateServiceItemLine(ServiceHeader);

        // 2. Exercise: Create Service Line with Type Item, Update Qty. to Ship and Post as Ship, Update Qty to Invoice and Post as Invoice,
        // Update Qty. to Consume and Post as Ship and Consume.
        CreateServiceLineForItem(ServiceHeader);
        UpdatePartQtyToShip(ServiceHeader);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        UpdatePartQtyToInvoice(ServiceHeader);
        LibraryService.PostServiceOrder(ServiceHeader, false, false, true);

        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        UpdatePartQtyToConsume(ServiceHeader);
        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);
    end;

    [Normal]
    local procedure CreateServiceOrder(var ServiceHeader: Record "Service Header")
    var
        Resource: Record Resource;
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        // 1. Setup: Create Service Header with Document Type Order and Create Service Item Line.
        Initialize();
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, '');
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');

        // 2. Exercise: Create Service Line with Type Item and Resource.
        LibraryResource.FindResource(Resource);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItemNo());
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Resource, Resource."No.");
    end;

    [Normal]
    local procedure CreateServiceOrderWithCurrency(var ServiceHeader: Record "Service Header")
    var
        Customer: Record Customer;
    begin
        // 1. Create Service Order - Service Header, Service Item Line and Service Line for Type Item.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Currency Code", LibraryERM.CreateCurrencyWithRandomExchRates());
        Customer.Modify(true);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");
        CreateServiceItemLine(ServiceHeader);
        CreateServiceLineForItem(ServiceHeader);
    end;

    [Normal]
    local procedure CreateServiceOrderWithItem(var ServiceHeader: Record "Service Header")
    begin
        // Create Service Order - Service Header, Service Item Line and Service Line for Type Item.
        Initialize();
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, '');
        CreateServiceItemLine(ServiceHeader);
        CreateServiceLineForItem(ServiceHeader);
    end;

    local procedure CreateServiceItemLine(ServiceHeader: Record "Service Header")
    var
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        Counter: Integer;
    begin
        // Create 2 to 10 Service Item Lines - Boundary 2 is important.
        for Counter := 2 to 2 + LibraryRandom.RandInt(8) do begin
            Clear(ServiceItem);
            LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
            LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        end;
    end;

    local procedure CreateServiceLineForItem(ServiceHeader: Record "Service Header")
    var
        ServiceLine: Record "Service Line";
        ServiceItemLine: Record "Service Item Line";
    begin
        ServiceItemLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceItemLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceItemLine.FindSet();
        repeat
            LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, '');
            ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
            ServiceLine.Modify(true);
        until ServiceItemLine.Next() = 0;
    end;

    local procedure CreateServiceLineForResource(ServiceHeader: Record "Service Header")
    var
        ServiceLine: Record "Service Line";
        ServiceItemLine: Record "Service Item Line";
    begin
        ServiceItemLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceItemLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceItemLine.FindSet();
        repeat
            LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Resource, '');
            ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
            ServiceLine.Modify(true);
        until ServiceItemLine.Next() = 0;
    end;

    [Normal]
    local procedure SaveServiceLineInTempTable(var TempServiceLine: Record "Service Line" temporary; ServiceHeader: Record "Service Header")
    var
        ServiceLine: Record "Service Line";
    begin
        SelectServiceLine(ServiceLine, ServiceHeader);
        repeat
            TempServiceLine := ServiceLine;
            TempServiceLine.Insert();
        until ServiceLine.Next() = 0;
    end;

    [Normal]
    local procedure SelectOldServiceLine(var TempServiceLine: Record "Service Line" temporary; var ServiceLine: Record "Service Line")
    begin
        TempServiceLine.FindSet();
        ServiceLine.SetRange("Document Type", TempServiceLine."Document Type");
        ServiceLine.SetRange("Document No.", TempServiceLine."Document No.");
        ServiceLine.FindSet();
    end;

    [Normal]
    local procedure SelectServiceLine(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header")
    begin
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.FindSet();
    end;

    [Normal]
    local procedure UpdateEqualQtyToShip(ServiceHeader: Record "Service Header")
    var
        ServiceLine: Record "Service Line";
    begin
        SelectServiceLine(ServiceLine, ServiceHeader);
        repeat
            ServiceLine.Validate("Qty. to Ship", ServiceLine.Quantity - ServiceLine."Quantity Shipped");
            ServiceLine.Validate("Qty. to Invoice", 0);
            ServiceLine.Modify(true);
        until ServiceLine.Next() = 0;
    end;

    [Normal]
    local procedure UpdateFractionQtyToShip(ServiceLine: Record "Service Line"; Quantity: Decimal)
    begin
        ServiceLine.SetRange("Document Type", ServiceLine."Document Type");
        ServiceLine.SetRange("Document No.", ServiceLine."Document No.");
        ServiceLine.FindSet();
        repeat
            ServiceLine.Validate(Quantity, Quantity);
            ServiceLine.Validate("Qty. to Ship", Quantity);
            ServiceLine.Modify(true);
        until ServiceLine.Next() = 0;
    end;

    [Normal]
    local procedure UpdateFractionQtyToInvoice(ServiceLine: Record "Service Line"; Quantity: Decimal)
    begin
        ServiceLine.SetRange("Document Type", ServiceLine."Document Type");
        ServiceLine.SetRange("Document No.", ServiceLine."Document No.");
        ServiceLine.FindSet();
        repeat
            ServiceLine.Validate(Quantity, Quantity);
            ServiceLine.Validate("Qty. to Invoice", Quantity);
            ServiceLine.Modify(true);
        until ServiceLine.Next() = 0;
    end;

    [Normal]
    local procedure UpdateFractionQtyToConsume(ServiceHeader: Record "Service Header"; Quantity: Decimal)
    var
        ServiceLine: Record "Service Line";
    begin
        SelectServiceLine(ServiceLine, ServiceHeader);
        repeat
            ServiceLine.Validate(Quantity, Quantity);
            ServiceLine.Validate("Qty. to Consume", Quantity);
            ServiceLine.Modify(true);
        until ServiceLine.Next() = 0;
    end;

    [Normal]
    local procedure UpdateFractionQuantity(ServiceLine: Record "Service Line"; Quantity: Decimal)
    begin
        ServiceLine.SetRange("Document Type", ServiceLine."Document Type");
        ServiceLine.SetRange("Document No.", ServiceLine."Document No.");
        ServiceLine.FindSet();
        repeat
            ServiceLine.Validate(Quantity, Quantity);
            ServiceLine.Modify(true);
        until ServiceLine.Next() = 0;
    end;

    [Normal]
    local procedure UpdateLessQtyToConsume(ServiceHeader: Record "Service Header")
    var
        ServiceLine: Record "Service Line";
    begin
        SelectServiceLine(ServiceLine, ServiceHeader);
        repeat
            ServiceLine.Validate("Qty. to Consume", ServiceLine.Quantity - ServiceLine."Quantity Shipped");
            ServiceLine.Modify(true);
        until ServiceLine.Next() = 0;
    end;

    [Normal]
    local procedure UpdateLessQtyToInvoice(ServiceHeader: Record "Service Header"; FractionFactor: Decimal)
    var
        ServiceLine: Record "Service Line";
    begin
        SelectServiceLine(ServiceLine, ServiceHeader);
        repeat
            ServiceLine.Validate(
              "Qty. to Invoice",
              (ServiceLine.Quantity - ServiceLine."Quantity Invoiced" - ServiceLine."Quantity Consumed") * FractionFactor);
            ServiceLine.Modify(true);
        until ServiceLine.Next() = 0;
    end;

    [Normal]
    local procedure UpdateLessQtyToShip(ServiceHeader: Record "Service Header"; FractionFactor: Decimal)
    var
        ServiceLine: Record "Service Line";
    begin
        SelectServiceLine(ServiceLine, ServiceHeader);
        repeat
            ServiceLine.Validate("Qty. to Ship", (ServiceLine.Quantity - ServiceLine."Quantity Shipped") * FractionFactor);
            ServiceLine.Modify(true);
        until ServiceLine.Next() = 0;
    end;

    [Normal]
    local procedure UpdatePartQtyToShip(ServiceHeader: Record "Service Header")
    var
        ServiceLine: Record "Service Line";
    begin
        SelectServiceLine(ServiceLine, ServiceHeader);
        repeat
            ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10));  // Use Random because value is not important.
            ServiceLine.Validate("Qty. to Ship", ServiceLine.Quantity * LibraryUtility.GenerateRandomFraction());
            ServiceLine.Validate("Qty. to Invoice", 0);
            ServiceLine.Modify(true);
        until ServiceLine.Next() = 0;
    end;

    [Normal]
    local procedure UpdatePartQtyToConsume(ServiceHeader: Record "Service Header")
    var
        ServiceLine: Record "Service Line";
    begin
        SelectServiceLine(ServiceLine, ServiceHeader);
        repeat
            ServiceLine.Validate(
              "Qty. to Consume", (ServiceLine.Quantity - ServiceLine."Quantity Shipped") * LibraryUtility.GenerateRandomFraction());
            ServiceLine.Modify(true);
        until ServiceLine.Next() = 0;
    end;

    [Normal]
    local procedure UpdatePartQtyToInvoice(ServiceHeader: Record "Service Header")
    var
        ServiceLine: Record "Service Line";
    begin
        SelectServiceLine(ServiceLine, ServiceHeader);
        repeat
            ServiceLine.Validate("Qty. to Invoice", ServiceLine."Quantity Shipped" * LibraryUtility.GenerateRandomFraction());
            ServiceLine.Modify(true);
        until ServiceLine.Next() = 0;
    end;

    [Normal]
    local procedure UpdateQtyEqualQuantityShipped(ServiceHeader: Record "Service Header")
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.FindSet();
        repeat
            ServiceLine.Validate(Quantity, ServiceLine."Quantity Shipped");
            ServiceLine.Modify(true);
        until ServiceLine.Next() = 0;
    end;

    [Normal]
    local procedure UpdateQtyOnServiceLine(ServiceHeader: Record "Service Header"; Quantity: Decimal)
    var
        ServiceLine: Record "Service Line";
    begin
        SelectServiceLine(ServiceLine, ServiceHeader);
        repeat
            ServiceLine.Validate(Quantity, ServiceLine.Quantity + Quantity);
            ServiceLine.Modify(true);
        until ServiceLine.Next() = 0;
    end;

    [Normal]
    local procedure UpdateQtyToConsume(ServiceHeader: Record "Service Header")
    var
        ServiceLine: Record "Service Line";
    begin
        SelectServiceLine(ServiceLine, ServiceHeader);
        repeat
            ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10));  // Use Random because value is not important.
            ServiceLine.Validate("Qty. to Consume", ServiceLine.Quantity * LibraryUtility.GenerateRandomFraction());
            ServiceLine.Modify(true);
        until ServiceLine.Next() = 0;
    end;

    [Normal]
    local procedure UpdateQtyToInvoice(ServiceHeader: Record "Service Header")
    var
        ServiceLine: Record "Service Line";
    begin
        SelectServiceLine(ServiceLine, ServiceHeader);
        repeat
            ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10));  // Use Random because value is not important.
            ServiceLine.Validate("Qty. to Invoice", ServiceLine.Quantity * LibraryUtility.GenerateRandomFraction());
            ServiceLine.Modify(true);
        until ServiceLine.Next() = 0;
    end;

    [Normal]
    local procedure UpdateSameQtyToConsume(ServiceHeader: Record "Service Header")
    var
        ServiceLine: Record "Service Line";
    begin
        SelectServiceLine(ServiceLine, ServiceHeader);
        repeat
            ServiceLine.Validate("Qty. to Consume", ServiceLine.Quantity - ServiceLine."Quantity Shipped");
            ServiceLine.Modify(true);
        until ServiceLine.Next() = 0;
    end;

    [Normal]
    local procedure UpdateSameQtyToInvoice(ServiceHeader: Record "Service Header")
    var
        ServiceLine: Record "Service Line";
    begin
        SelectServiceLine(ServiceLine, ServiceHeader);
        repeat
            ServiceLine.Validate(
              "Qty. to Invoice", ServiceLine."Quantity Shipped" - ServiceLine."Quantity Invoiced" - ServiceLine."Quantity Consumed");
            ServiceLine.Modify(true);
        until ServiceLine.Next() = 0;
    end;

    [Normal]
    local procedure UpdateUnitCostOnServiceLine(ServiceHeader: Record "Service Header"; UnitCost: Decimal)
    var
        ServiceLine: Record "Service Line";
    begin
        SelectServiceLine(ServiceLine, ServiceHeader);
        repeat
            ServiceLine.Validate("Unit Cost", UnitCost);
            ServiceLine.Modify(true);
        until ServiceLine.Next() = 0;
    end;

    [Normal]
    local procedure UpdateUnitPriceOnServiceLine(ServiceHeader: Record "Service Header"; UnitPrice: Decimal)
    var
        ServiceLine: Record "Service Line";
    begin
        SelectServiceLine(ServiceLine, ServiceHeader);
        repeat
            ServiceLine.Validate("Unit Price", UnitPrice);
            ServiceLine.Modify(true);
        until ServiceLine.Next() = 0;
    end;

    [Normal]
    local procedure UpdateZeroQtyToConsume(ServiceHeader: Record "Service Header")
    var
        ServiceLine: Record "Service Line";
    begin
        SelectServiceLine(ServiceLine, ServiceHeader);
        repeat
            ServiceLine.Validate("Qty. to Consume", 0);
            ServiceLine.Modify(true);
        until ServiceLine.Next() = 0;
    end;

    [Normal]
    local procedure UpdateZeroQtyToInvoice(ServiceHeader: Record "Service Header")
    var
        ServiceLine: Record "Service Line";
    begin
        SelectServiceLine(ServiceLine, ServiceHeader);
        repeat
            ServiceLine.Validate("Qty. to Invoice", 0);
            ServiceLine.Modify(true);
        until ServiceLine.Next() = 0;
    end;

    [Normal]
    local procedure UpdateZeroQtyToShip(ServiceHeader: Record "Service Header")
    var
        ServiceLine: Record "Service Line";
    begin
        SelectServiceLine(ServiceLine, ServiceHeader);
        repeat
            ServiceLine.Validate("Qty. to Ship", 0);
            ServiceLine.Modify(true);
        until ServiceLine.Next() = 0;
    end;

    [Normal]
    local procedure VerifyEqualQtyToShip(var TempServiceLine: Record "Service Line" temporary)
    var
        ServiceLine: Record "Service Line";
    begin
        SelectOldServiceLine(TempServiceLine, ServiceLine);
        repeat
            ServiceLine.TestField(Type, TempServiceLine.Type);
            ServiceLine.TestField("No.", TempServiceLine."No.");
            ServiceLine.TestField("Qty. to Ship", TempServiceLine.Quantity - TempServiceLine."Quantity Shipped");
            ServiceLine.Next();
        until TempServiceLine.Next() = 0;
    end;

    [Normal]
    local procedure VerifyFractionQuantity(ServiceLine: Record "Service Line"; Quantity: Decimal)
    begin
        ServiceLine.SetRange("Document Type", ServiceLine."Document Type");
        ServiceLine.SetRange("Document No.", ServiceLine."Document No.");
        ServiceLine.FindSet();
        repeat
            ServiceLine.TestField(Quantity, Quantity);
        until ServiceLine.Next() = 0;
    end;

    [Normal]
    local procedure VerifyFractionQtyToConsume(ServiceHeader: Record "Service Header"; Quantity: Decimal)
    var
        ServiceLine: Record "Service Line";
    begin
        SelectServiceLine(ServiceLine, ServiceHeader);
        repeat
            ServiceLine.TestField(Quantity, Quantity);
            ServiceLine.TestField("Qty. to Consume", Quantity);
        until ServiceLine.Next() = 0;
    end;

    [Normal]
    local procedure VerifyFractionQtyToInvoice(ServiceLine: Record "Service Line"; Quantity: Decimal)
    begin
        ServiceLine.SetRange("Document Type", ServiceLine."Document Type");
        ServiceLine.SetRange("Document No.", ServiceLine."Document No.");
        ServiceLine.FindSet();
        repeat
            ServiceLine.TestField(Quantity, Quantity);
            ServiceLine.TestField("Qty. to Invoice", Quantity);
        until ServiceLine.Next() = 0;
    end;

    [Normal]
    local procedure VerifyFractionQtyToShip(ServiceLine: Record "Service Line"; Quantity: Decimal)
    begin
        ServiceLine.SetRange("Document Type", ServiceLine."Document Type");
        ServiceLine.SetRange("Document No.", ServiceLine."Document No.");
        ServiceLine.FindSet();
        repeat
            ServiceLine.TestField(Quantity, Quantity);
            ServiceLine.TestField("Qty. to Ship", Quantity);
        until ServiceLine.Next() = 0;
    end;

    [Normal]
    local procedure VerifyGreaterQtyToConsume(ServiceHeader: Record "Service Header")
    var
        ServiceLine: Record "Service Line";
    begin
        SelectServiceLine(ServiceLine, ServiceHeader);
        repeat
            // Use Random to ensure Qty. to Consume greater than Remaining Quantity.
            asserterror
              ServiceLine.Validate(
                "Qty. to Consume",
                ServiceLine.Quantity - ServiceLine."Quantity Shipped" + LibraryRandom.RandInt(10));
            Assert.AreEqual(
              StrSubstNo(QtyToConsumeError, ServiceLine.Quantity - ServiceLine."Quantity Shipped"), GetLastErrorText, UnknownError);
        until ServiceLine.Next() = 0;
    end;

    [Normal]
    local procedure VerifyGreaterQtyToInvoice(ServiceHeader: Record "Service Header")
    var
        ServiceLine: Record "Service Line";
    begin
        SelectServiceLine(ServiceLine, ServiceHeader);
        repeat
            // Use Random to ensure Qty. to Invoice greater than Remaining Quantity.
            asserterror
              ServiceLine.Validate(
                "Qty. to Invoice",
                ServiceLine.Quantity - ServiceLine."Quantity Invoiced" - ServiceLine."Quantity Consumed" + LibraryRandom.RandInt(10));
            Assert.AreEqual(
              StrSubstNo(QtyToInvoiceError, ServiceLine.Quantity - ServiceLine."Quantity Invoiced" - ServiceLine."Quantity Consumed"),
              GetLastErrorText, UnknownError);
        until ServiceLine.Next() = 0;
    end;

    [Normal]
    local procedure VerifyGreaterQtyToShip(ServiceHeader: Record "Service Header")
    var
        ServiceLine: Record "Service Line";
    begin
        SelectServiceLine(ServiceLine, ServiceHeader);
        repeat
            // Use Random to ensure Qty. to Ship greater than Remaining Quantity.
            asserterror
              ServiceLine.Validate(
                "Qty. to Ship",
                ServiceLine.Quantity - ServiceLine."Quantity Shipped" + LibraryRandom.RandInt(10));
            Assert.AreEqual(
              StrSubstNo(QtyToShipError, ServiceLine.Quantity - ServiceLine."Quantity Shipped"), GetLastErrorText, UnknownError);
        until ServiceLine.Next() = 0;
    end;

    [Normal]
    local procedure VerifyLessQtyToConsume(var TempServiceLine: Record "Service Line" temporary)
    var
        ServiceLine: Record "Service Line";
    begin
        SelectOldServiceLine(TempServiceLine, ServiceLine);
        repeat
            ServiceLine.TestField(Type, TempServiceLine.Type);
            ServiceLine.TestField("No.", TempServiceLine."No.");
            ServiceLine.TestField("Qty. to Consume", TempServiceLine.Quantity - TempServiceLine."Quantity Shipped");
            ServiceLine.Next();
        until TempServiceLine.Next() = 0;
    end;

    [Normal]
    local procedure VerifyLessQtyToInvoice(var TempServiceLine: Record "Service Line" temporary; FractionFactor: Decimal)
    var
        ServiceLine: Record "Service Line";
    begin
        SelectOldServiceLine(TempServiceLine, ServiceLine);
        repeat
            ServiceLine.TestField(Type, TempServiceLine.Type);
            ServiceLine.TestField("No.", TempServiceLine."No.");
            ServiceLine.TestField(
              "Qty. to Invoice",
              (TempServiceLine.Quantity - TempServiceLine."Quantity Invoiced" - TempServiceLine."Quantity Consumed") * FractionFactor);
            ServiceLine.Next();
        until TempServiceLine.Next() = 0;
    end;

    [Normal]
    local procedure VerifyLessQtyToShipUpdation(var TempServiceLine: Record "Service Line" temporary; FractionFactor: Decimal)
    var
        ServiceLine: Record "Service Line";
    begin
        SelectOldServiceLine(TempServiceLine, ServiceLine);
        repeat
            ServiceLine.TestField(Type, TempServiceLine.Type);
            ServiceLine.TestField("No.", TempServiceLine."No.");
            ServiceLine.TestField("Qty. to Ship", (TempServiceLine.Quantity - TempServiceLine."Quantity Shipped") * FractionFactor);
            ServiceLine.Next();
        until TempServiceLine.Next() = 0;
    end;

    [Normal]
    local procedure VerifyLessQuantityUpdation(ServiceHeader: Record "Service Header")
    var
        ServiceLine: Record "Service Line";
    begin
        SelectServiceLine(ServiceLine, ServiceHeader);
        repeat
            asserterror ServiceLine.Validate(Quantity, ServiceLine."Quantity Shipped" * LibraryUtility.GenerateRandomFraction());
            Assert.AreEqual(
              StrSubstNo(
                QuantityError, ServiceLine.FieldCaption(Quantity), ServiceLine.FieldCaption("Quantity Shipped"),
                ServiceLine.TableCaption(), ServiceLine.FieldCaption("Document Type"), ServiceLine."Document Type",
                ServiceLine.FieldCaption("Document No."), ServiceLine."Document No.",
                ServiceLine.FieldCaption("Line No."), ServiceLine."Line No."),
              GetLastErrorText, UnknownError);
        until ServiceLine.Next() = 0;
    end;

    [Normal]
    local procedure VerifyNegativeQuantity(ServiceLine: Record "Service Line"; Quantity: Decimal)
    begin
        ServiceLine.SetRange("Document Type", ServiceLine."Document Type");
        ServiceLine.SetRange("Document No.", ServiceLine."Document No.");
        ServiceLine.FindSet();
        repeat
            asserterror ServiceLine.Validate(Quantity, -Quantity);
            Assert.AreEqual(
              StrSubstNo(
                NegativeQuantityError, ServiceLine.FieldCaption(Quantity), ServiceLine.TableCaption(),
                ServiceLine.FieldCaption("Document Type"),
                ServiceLine."Document Type", ServiceLine.FieldCaption("Document No."), ServiceLine."Document No.",
                ServiceLine.FieldCaption("Line No."), ServiceLine."Line No."),
              GetLastErrorText, UnknownError);
        until ServiceLine.Next() = 0;
    end;

    [Normal]
    local procedure VerifyNegativeQtyToConsume(ServiceLine: Record "Service Line"; Quantity: Decimal)
    begin
        ServiceLine.SetRange("Document Type", ServiceLine."Document Type");
        ServiceLine.SetRange("Document No.", ServiceLine."Document No.");
        ServiceLine.FindSet();
        repeat
            asserterror ServiceLine.Validate("Qty. to Consume", -Quantity);
            Assert.AreEqual(
              StrSubstNo(
                NegativeQuantityError, ServiceLine.FieldCaption("Qty. to Consume"), ServiceLine.TableCaption(),
                ServiceLine.FieldCaption("Document Type"), ServiceLine."Document Type", ServiceLine.FieldCaption("Document No."),
                ServiceLine."Document No.", ServiceLine.FieldCaption("Line No."), ServiceLine."Line No."),
              GetLastErrorText, UnknownError);
        until ServiceLine.Next() = 0;
    end;

    [Normal]
    local procedure VerifyNegativeQtyToInvoice(ServiceLine: Record "Service Line"; Quantity: Decimal)
    begin
        ServiceLine.SetRange("Document Type", ServiceLine."Document Type");
        ServiceLine.SetRange("Document No.", ServiceLine."Document No.");
        ServiceLine.FindSet();
        repeat
            asserterror ServiceLine.Validate("Qty. to Invoice", -Quantity);
            Assert.AreEqual(
              StrSubstNo(
                NegativeQuantityError, ServiceLine.FieldCaption("Qty. to Invoice"), ServiceLine.TableCaption(),
                ServiceLine.FieldCaption("Document Type"), ServiceLine."Document Type", ServiceLine.FieldCaption("Document No."),
                ServiceLine."Document No.", ServiceLine.FieldCaption("Line No."), ServiceLine."Line No."),
              GetLastErrorText, UnknownError);
        until ServiceLine.Next() = 0;
    end;

    [Normal]
    local procedure VerifyNegativeQtyToShip(ServiceLine: Record "Service Line"; Quantity: Decimal)
    begin
        ServiceLine.SetRange("Document Type", ServiceLine."Document Type");
        ServiceLine.SetRange("Document No.", ServiceLine."Document No.");
        ServiceLine.FindSet();
        repeat
            asserterror ServiceLine.Validate("Qty. to Ship", -Quantity);
            Assert.AreEqual(
              StrSubstNo(
                NegativeQuantityError, ServiceLine.FieldCaption("Qty. to Ship"), ServiceLine.TableCaption(),
                ServiceLine.FieldCaption("Document Type"), ServiceLine."Document Type", ServiceLine.FieldCaption("Document No."),
                ServiceLine."Document No.", ServiceLine.FieldCaption("Line No."), ServiceLine."Line No."),
              GetLastErrorText, UnknownError);
        until ServiceLine.Next() = 0;
    end;

    [Normal]
    local procedure VerifyQuantityUpdation(var TempServiceLine: Record "Service Line" temporary; Quantity: Decimal)
    var
        ServiceLine: Record "Service Line";
    begin
        SelectOldServiceLine(TempServiceLine, ServiceLine);
        repeat
            ServiceLine.TestField(Type, TempServiceLine.Type);
            ServiceLine.TestField("No.", TempServiceLine."No.");
            ServiceLine.TestField(Quantity, TempServiceLine.Quantity + Quantity);
            ServiceLine.Next();
        until TempServiceLine.Next() = 0;
    end;

    [Normal]
    local procedure VerifyQtyToShipUpdation(var TempServiceLine: Record "Service Line" temporary)
    var
        ServiceLine: Record "Service Line";
    begin
        SelectOldServiceLine(TempServiceLine, ServiceLine);
        repeat
            ServiceLine.TestField(Type, TempServiceLine.Type);
            ServiceLine.TestField("No.", TempServiceLine."No.");
            ServiceLine.TestField(Quantity, TempServiceLine."Quantity Shipped");
            ServiceLine.TestField("Qty. to Ship", 0);
            ServiceLine.Next();
        until TempServiceLine.Next() = 0;
    end;

    [Normal]
    local procedure VerifySameQtyToConsumeUpdation(var TempServiceLine: Record "Service Line" temporary)
    var
        ServiceLine: Record "Service Line";
    begin
        SelectOldServiceLine(TempServiceLine, ServiceLine);
        repeat
            ServiceLine.TestField(Type, TempServiceLine.Type);
            ServiceLine.TestField("No.", TempServiceLine."No.");
            ServiceLine.TestField("Qty. to Consume", TempServiceLine.Quantity - TempServiceLine."Quantity Shipped");
            ServiceLine.Next();
        until TempServiceLine.Next() = 0;
    end;

    [Normal]
    local procedure VerifySameQtyToInvoice(var TempServiceLine: Record "Service Line" temporary)
    var
        ServiceLine: Record "Service Line";
    begin
        SelectOldServiceLine(TempServiceLine, ServiceLine);
        repeat
            ServiceLine.TestField(Type, TempServiceLine.Type);
            ServiceLine.TestField("No.", TempServiceLine."No.");
            ServiceLine.TestField(
              "Qty. to Invoice",
              TempServiceLine."Quantity Shipped" - TempServiceLine."Quantity Invoiced" - TempServiceLine."Quantity Consumed");
            ServiceLine.Next();
        until TempServiceLine.Next() = 0;
    end;

    [Normal]
    local procedure VerifyServiceLine(var TempServiceLine: Record "Service Line" temporary)
    var
        ServiceLine: Record "Service Line";
    begin
        SelectOldServiceLine(TempServiceLine, ServiceLine);
        repeat
            ServiceLine.TestField(Type, TempServiceLine.Type);
            ServiceLine.TestField("No.", TempServiceLine."No.");
            ServiceLine.TestField(Quantity, TempServiceLine.Quantity);
            ServiceLine.TestField("Quantity Shipped", TempServiceLine."Qty. to Ship" + TempServiceLine."Quantity Shipped");
            ServiceLine.TestField("Quantity Invoiced", TempServiceLine."Qty. to Invoice" + TempServiceLine."Quantity Invoiced");
            ServiceLine.TestField("Quantity Consumed", TempServiceLine."Qty. to Consume" + TempServiceLine."Quantity Consumed");
            ServiceLine.Next();
        until TempServiceLine.Next() = 0;
    end;

    local procedure VerifyServiceLineAfterConsume(ServiceHeader: Record "Service Header")
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.FindSet();
        repeat
            ServiceLine.TestField(Quantity, ServiceLine.Quantity);
            ServiceLine.TestField("Quantity Shipped", ServiceLine.Quantity - ServiceLine."Qty. to Ship");
            ServiceLine.TestField("Quantity Consumed", ServiceLine.Quantity - ServiceLine."Qty. to Ship");
        until ServiceLine.Next() = 0;
    end;

    [Normal]
    local procedure VerifyServiceLineAfterInvoice(var TempServiceLine: Record "Service Line" temporary)
    var
        ServiceLine: Record "Service Line";
    begin
        SelectOldServiceLine(TempServiceLine, ServiceLine);
        repeat
            ServiceLine.TestField(Type, TempServiceLine.Type);
            ServiceLine.TestField("No.", TempServiceLine."No.");
            ServiceLine.TestField(Quantity, TempServiceLine.Quantity);
            ServiceLine.TestField("Quantity Shipped", TempServiceLine."Quantity Shipped");
            ServiceLine.TestField("Quantity Invoiced", TempServiceLine."Qty. to Invoice");
            ServiceLine.TestField("Quantity Consumed", TempServiceLine."Qty. to Consume");
            ServiceLine.Next();
        until TempServiceLine.Next() = 0;
    end;

    [Normal]
    local procedure VerifyServiceLineAfterPosting(var TempServiceLine: Record "Service Line" temporary)
    var
        ServiceLine: Record "Service Line";
    begin
        SelectOldServiceLine(TempServiceLine, ServiceLine);
        repeat
            ServiceLine.TestField(Type, TempServiceLine.Type);
            ServiceLine.TestField("No.", TempServiceLine."No.");
            ServiceLine.TestField(Quantity, TempServiceLine.Quantity);
            ServiceLine.TestField("Quantity Shipped", TempServiceLine."Quantity Shipped");
            ServiceLine.TestField("Quantity Invoiced", TempServiceLine."Qty. to Invoice" + TempServiceLine."Quantity Invoiced");
            ServiceLine.Next();
        until TempServiceLine.Next() = 0;
    end;

    local procedure VerifyServiceLineAfterShip(ServiceHeader: Record "Service Header")
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.FindSet();
        repeat
            ServiceLine.TestField(Quantity, ServiceLine.Quantity);
            ServiceLine.TestField("Quantity Shipped", ServiceLine.Quantity - ServiceLine."Qty. to Ship");
        until ServiceLine.Next() = 0;
    end;

    [Normal]
    local procedure VerifyServiceLineAfterUndo(var TempServiceLine: Record "Service Line" temporary)
    var
        ServiceLine: Record "Service Line";
    begin
        SelectOldServiceLine(TempServiceLine, ServiceLine);
        repeat
            ServiceLine.TestField(Type, TempServiceLine.Type);
            ServiceLine.TestField("No.", TempServiceLine."No.");
            ServiceLine.TestField(Quantity, TempServiceLine.Quantity);
            ServiceLine.TestField("Quantity Shipped", TempServiceLine."Quantity Shipped");
            ServiceLine.TestField("Quantity Consumed", TempServiceLine."Quantity Consumed");
            ServiceLine.Next();
        until TempServiceLine.Next() = 0;
    end;

    [Normal]
    local procedure VerifyShipmentLineAfterUndo(var TempServiceLine: Record "Service Line" temporary)
    var
        ServiceShipmentHeader: Record "Service Shipment Header";
        ServiceShipmentLine: Record "Service Shipment Line";
        TotalQuantity: Decimal;
        TotalConsumedQuantity: Decimal;
        TotalInvoicedQuantity: Decimal;
    begin
        TempServiceLine.FindSet();
        ServiceShipmentHeader.SetRange("Order No.", TempServiceLine."Document No.");
        ServiceShipmentHeader.FindLast();
        ServiceShipmentLine.SetRange("Document No.", ServiceShipmentHeader."No.");
        repeat
            TotalQuantity := 0;
            TotalConsumedQuantity := 0;
            TotalInvoicedQuantity := 0;
            ServiceShipmentLine.SetRange("Order Line No.", TempServiceLine."Line No.");
            ServiceShipmentLine.FindSet();
            repeat
                TotalQuantity += ServiceShipmentLine.Quantity;
                TotalConsumedQuantity += ServiceShipmentLine."Quantity Consumed";
                TotalInvoicedQuantity += ServiceShipmentLine."Quantity Invoiced";
            until ServiceShipmentLine.Next() = 0;
            Assert.AreEqual(
              TotalQuantity,
              0, StrSubstNo(
                ServiceShipmentLineError, ServiceShipmentLine.FieldCaption(Quantity), TotalQuantity, ServiceShipmentLine.TableCaption(),
                ServiceShipmentLine.FieldCaption("Document No."), ServiceShipmentLine."Document No."));
            Assert.AreEqual(
              TotalConsumedQuantity,
              0, StrSubstNo(
                ServiceShipmentLineError,
                ServiceShipmentLine.FieldCaption("Quantity Consumed"), TotalConsumedQuantity, ServiceShipmentLine.TableCaption(),
                ServiceShipmentLine.FieldCaption("Document No."), ServiceShipmentLine."Document No."));
            Assert.AreEqual(
              TotalInvoicedQuantity,
              0, StrSubstNo(
                ServiceShipmentLineError,
                ServiceShipmentLine.FieldCaption("Quantity Invoiced"), TotalInvoicedQuantity, ServiceShipmentLine.TableCaption(),
                ServiceShipmentLine.FieldCaption("Document No."), ServiceShipmentLine."Document No."));
        until TempServiceLine.Next() = 0;
    end;

    [Normal]
    local procedure VerifyUndoServiceLine(ServiceHeader: Record "Service Header")
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.FindSet();
        repeat
            ServiceLine.TestField(Quantity, ServiceLine.Quantity);
            ServiceLine.TestField("Quantity Shipped", 0);
            ServiceLine.TestField("Quantity Consumed", 0);
        until ServiceLine.Next() = 0;
    end;

    [Normal]
    local procedure VerifyZeroQtyToConsumeUpdation(ServiceHeader: Record "Service Header")
    var
        ServiceLine: Record "Service Line";
    begin
        SelectServiceLine(ServiceLine, ServiceHeader);
        repeat
            ServiceLine.TestField("Qty. to Consume", 0);
        until ServiceLine.Next() = 0;
    end;

    [Normal]
    local procedure VerifyZeroQtyToInvoice(var TempServiceLine: Record "Service Line" temporary)
    var
        ServiceLine: Record "Service Line";
    begin
        SelectOldServiceLine(TempServiceLine, ServiceLine);
        repeat
            ServiceLine.TestField(Type, TempServiceLine.Type);
            ServiceLine.TestField("No.", TempServiceLine."No.");
            ServiceLine.TestField(Quantity, TempServiceLine.Quantity);
            ServiceLine.TestField("Qty. to Invoice", 0);
            ServiceLine.Next();
        until TempServiceLine.Next() = 0;
    end;

    [Normal]
    local procedure VerifyZeroQtyToShip(var TempServiceLine: Record "Service Line" temporary)
    var
        ServiceLine: Record "Service Line";
    begin
        SelectOldServiceLine(TempServiceLine, ServiceLine);
        repeat
            ServiceLine.TestField(Type, TempServiceLine.Type);
            ServiceLine.TestField("No.", TempServiceLine."No.");
            ServiceLine.TestField(Quantity, TempServiceLine.Quantity);
            ServiceLine.TestField("Qty. to Ship", 0);
            ServiceLine.Next();
        until TempServiceLine.Next() = 0;
    end;

    [Normal]
    local procedure VerifyUnitCostOnServiceLine(ServiceHeader: Record "Service Header"; UnitCost: Decimal)
    var
        ServiceLine: Record "Service Line";
    begin
        SelectServiceLine(ServiceLine, ServiceHeader);
        repeat
            ServiceLine.TestField("Unit Cost", UnitCost);
        until ServiceLine.Next() = 0;
    end;

    [Normal]
    local procedure VerifyUnitPriceOnServiceLine(ServiceHeader: Record "Service Header"; UnitPrice: Decimal)
    var
        ServiceLine: Record "Service Line";
    begin
        SelectServiceLine(ServiceLine, ServiceHeader);
        repeat
            ServiceLine.TestField("Unit Price", UnitPrice);
        until ServiceLine.Next() = 0;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmMessageHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

