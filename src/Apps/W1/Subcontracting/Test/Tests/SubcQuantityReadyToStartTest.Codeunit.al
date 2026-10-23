// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Requisition;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.Subcontracting;
using Microsoft.Manufacturing.WorkCenter;
using System.TestLibraries.Utilities;

codeunit 139999 "Subc. Quantity Ready Test"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    trigger OnRun()
    begin
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryMfgManagement: Codeunit "Subc. Library Mfg. Management";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        SubcontractingMgmtLibrary: Codeunit "Subc. Management Library";
        SubSetupLibrary: Codeunit "Subc. Setup Library";
        SubcWarehouseLibrary: Codeunit "Subc. Warehouse Library";
        IsInitialized: Boolean;

    [Test]
    procedure CalculateSubcontractsKeepsZeroReadinessLinesWhenToggleDisabled()
    var
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProductionOrder: Record "Production Order";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionLine: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        WorkCenter: array[2] of Record "Work Center";
        SubcCalculateSubContract: Report "Subc. Calculate Subcontracts";
    begin
        Initialize();
        CreateSubcontractingProductionOrder(Item, ProductionOrder, WorkCenter, MachineCenter);
        FindSubcontractingRoutingLine(ProdOrderRoutingLine, ProductionOrder, WorkCenter[2]);
        SetQuantityReadyToStart(ProdOrderRoutingLine, 0);
        SubcontractingMgmtLibrary.CreateReqWkshTemplateAndName(ReqWkshTemplate, RequisitionWkshName);

        RequisitionLine."Worksheet Template Name" := RequisitionWkshName."Worksheet Template Name";
        RequisitionLine."Journal Batch Name" := RequisitionWkshName.Name;
        SubcCalculateSubContract.SetWkShLine(RequisitionLine);
        SubcCalculateSubContract.UseRequestPage(false);
        SubcCalculateSubContract.RunModal();

        FilterRequisitionLine(RequisitionLine, RequisitionWkshName, ProductionOrder."No.");
        Assert.IsTrue(RequisitionLine.FindFirst(), 'The default report behavior must still include routing lines with zero Quantity Ready to Start.');
    end;

    [Test]
    procedure CalculateSubcontractsSkipsZeroReadinessLinesWhenToggleEnabled()
    var
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProductionOrder: Record "Production Order";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionLine: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        WorkCenter: array[2] of Record "Work Center";
        SubcCalculateSubContract: Report "Subc. Calculate Subcontracts";
    begin
        Initialize();
        CreateSubcontractingProductionOrder(Item, ProductionOrder, WorkCenter, MachineCenter);
        FindSubcontractingRoutingLine(ProdOrderRoutingLine, ProductionOrder, WorkCenter[2]);
        SetQuantityReadyToStart(ProdOrderRoutingLine, 0);
        SubcontractingMgmtLibrary.CreateReqWkshTemplateAndName(ReqWkshTemplate, RequisitionWkshName);

        RequisitionLine."Worksheet Template Name" := RequisitionWkshName."Worksheet Template Name";
        RequisitionLine."Journal Batch Name" := RequisitionWkshName.Name;
        SubcCalculateSubContract.SetWkShLine(RequisitionLine);
        SubcCalculateSubContract.SetOnlyReadyOperations(true);
        SubcCalculateSubContract.UseRequestPage(false);
        SubcCalculateSubContract.RunModal();

        FilterRequisitionLine(RequisitionLine, RequisitionWkshName, ProductionOrder."No.");
        Assert.IsFalse(RequisitionLine.FindFirst(), 'Only Ready Operations must exclude routing lines with zero Quantity Ready to Start.');
    end;

    [Test]
    procedure CalculateSubcontractsKeepsReadyLinesWhenToggleEnabled()
    var
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProductionOrder: Record "Production Order";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionLine: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        WorkCenter: array[2] of Record "Work Center";
        SubcCalculateSubContract: Report "Subc. Calculate Subcontracts";
    begin
        Initialize();
        CreateSubcontractingProductionOrder(Item, ProductionOrder, WorkCenter, MachineCenter);
        FindSubcontractingRoutingLine(ProdOrderRoutingLine, ProductionOrder, WorkCenter[2]);
        SetQuantityReadyToStart(ProdOrderRoutingLine, LibraryRandom.RandInt(10) + 1);
        SubcontractingMgmtLibrary.CreateReqWkshTemplateAndName(ReqWkshTemplate, RequisitionWkshName);

        RequisitionLine."Worksheet Template Name" := RequisitionWkshName."Worksheet Template Name";
        RequisitionLine."Journal Batch Name" := RequisitionWkshName.Name;
        SubcCalculateSubContract.SetWkShLine(RequisitionLine);
        SubcCalculateSubContract.SetOnlyReadyOperations(true);
        SubcCalculateSubContract.UseRequestPage(false);
        SubcCalculateSubContract.RunModal();

        FilterRequisitionLine(RequisitionLine, RequisitionWkshName, ProductionOrder."No.");
        Assert.IsTrue(RequisitionLine.FindFirst(), 'Only Ready Operations must keep routing lines with a non-zero Quantity Ready to Start.');
    end;

    local procedure Initialize()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Subc. Quantity Ready Test");
        LibrarySetupStorage.Restore();

        SubcontractingMgmtLibrary.Initialize();
        SubcontractingMgmtLibrary.UpdateSubMgmtSetup_ComponentAtLocation("Components at Location"::Purchase);
        LibraryMfgManagement.CreateSubcontractingReqWkshTemplateAndNameAndUpdateSetup();
        LibraryVariableStorage.Clear();
        LibraryMfgManagement.Initialize();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Subc. Quantity Ready Test");

        SubSetupLibrary.InitSetupFields();
        LibraryERMCountryData.CreateVATData();
        SubSetupLibrary.InitialSetupForGenProdPostingGroup();
        ManufacturingSetup.Get();
        if ManufacturingSetup."Planned Order Nos." = '' then
            ManufacturingSetup.Validate("Planned Order Nos.", LibraryERM.CreateNoSeriesCode());
        if ManufacturingSetup."Firm Planned Order Nos." = '' then
            ManufacturingSetup.Validate("Firm Planned Order Nos.", LibraryERM.CreateNoSeriesCode());
        if ManufacturingSetup."Released Order Nos." = '' then
            ManufacturingSetup.Validate("Released Order Nos.", LibraryERM.CreateNoSeriesCode());
        if ManufacturingSetup."Simulated Order Nos." = '' then
            ManufacturingSetup.Validate("Simulated Order Nos.", LibraryERM.CreateNoSeriesCode());
        ManufacturingSetup.Modify(true);

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Subc. Quantity Ready Test");
    end;

    local procedure CreateSubcontractingProductionOrder(var Item: Record Item; var ProductionOrder: Record "Production Order"; var WorkCenter: array[2] of Record "Work Center"; var MachineCenter: array[2] of Record "Machine Center")
    begin
        SubcontractingMgmtLibrary.Initialize();
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true, 1);
        SubcWarehouseLibrary.CreateItemForProductionWithCostOverrides(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLinkByBOMNo(Item, WorkCenter[2]."No.");
        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);
        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);
    end;

    local procedure FindSubcontractingRoutingLine(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; ProductionOrder: Record "Production Order"; WorkCenter: Record "Work Center")
    begin
        ProdOrderRoutingLine.SetRange(Status, ProdOrderRoutingLine.Status::Released);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.SetRange("Work Center No.", WorkCenter."No.");
        ProdOrderRoutingLine.FindFirst();
    end;

    local procedure SetQuantityReadyToStart(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; QuantityReadyToStart: Decimal)
    var
        RecordRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecordRef.GetTable(ProdOrderRoutingLine);
        FieldRef := RecordRef.Field(7308);
        FieldRef.Value := QuantityReadyToStart;
        RecordRef.SetTable(ProdOrderRoutingLine);
        ProdOrderRoutingLine.Modify(false);
    end;

    local procedure FilterRequisitionLine(var RequisitionLine: Record "Requisition Line"; RequisitionWkshName: Record "Requisition Wksh. Name"; ProdOrderNo: Code[20])
    begin
        RequisitionLine.SetRange("Worksheet Template Name", RequisitionWkshName."Worksheet Template Name");
        RequisitionLine.SetRange("Journal Batch Name", RequisitionWkshName.Name);
        RequisitionLine.SetRange("Prod. Order No.", ProdOrderNo);
    end;
}


