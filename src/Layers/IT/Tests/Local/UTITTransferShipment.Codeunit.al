// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Test;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Setup;

codeunit 144083 "UT IT Transfer Shipment"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryWarehouse: Codeunit "Library - Warehouse";

    [Test]
    [HandlerFunctions('SubcontractTransferShipmentRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoCommit)]
    [Scope('OnPrem')]
    procedure SubcontractTransferShipmentRunsWhenLegacySubcontractingIsDisabled()
    var
        FromLocation: Record Location;
        InTransitLocation: Record Location;
        Item: Record Item;
        ToLocation: Record Location;
        TransferHeader: Record "Transfer Header";
        TransferShipmentHeader: Record "Transfer Shipment Header";
        TransferLine: Record "Transfer Line";
#if not CLEAN28
        ManufacturingSetup: Record "Manufacturing Setup";
#endif
        Quantity: Decimal;
    begin
        // [SCENARIO 649580] The Italian transfer shipment report remains available when Legacy Subcontracting is disabled.
#if not CLEAN28
        ManufacturingSetup.Get();
        ManufacturingSetup.Validate("Legacy Subcontracting", false);
        ManufacturingSetup.Modify(true);
#endif
        LibraryERM.UpdateCompanyAddress();
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(FromLocation);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(ToLocation);
        LibraryWarehouse.CreateInTransitLocation(InTransitLocation);
        LibraryInventory.CreateItem(Item);
        Quantity := LibraryRandom.RandDec(10, 2);
        LibraryInventory.PostPositiveAdjustment(
            Item, FromLocation.Code, '', '', Quantity, WorkDate(), LibraryRandom.RandDec(100, 2));
        LibraryInventory.CreateTransferOrder(
            TransferHeader, TransferLine, Item, FromLocation, ToLocation, InTransitLocation, '', Quantity, WorkDate(), WorkDate());
        LibraryInventory.PostTransferHeader(TransferHeader, true, false);

        TransferShipmentHeader.Get(TransferHeader."Last Shipment No.");

        LibraryVariableStorage.Enqueue(TransferShipmentHeader."No.");

        Report.Run(Report::"Subcontract. Transfer Shipment");

        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(
            'Transfer_Shipment_Header_No_', TransferShipmentHeader."No.");
        LibraryVariableStorage.AssertEmpty();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SubcontractTransferShipmentRequestPageHandler(var SubcontractTransferShipment: TestRequestPage "Subcontract. Transfer Shipment")
    var
        TransferShipmentNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(TransferShipmentNo);
        SubcontractTransferShipment."Transfer Shipment Header".SetFilter("No.", TransferShipmentNo);
        SubcontractTransferShipment.SaveAsXml(
            LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}
