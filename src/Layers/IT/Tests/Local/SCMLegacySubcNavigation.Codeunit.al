#if not CLEAN28
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Test;

using Microsoft.Inventory.Location;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Setup;

codeunit 137505 "SCM Legacy Subc Navigation"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        SubcontractTransferOrderOpened: Boolean;

    [Test]
    [HandlerFunctions('SubcontrTransferOrderPageHandler')]
    [Scope('OnPrem')]
    procedure ShowDocumentOpensSubcontractingTransferOrder()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationInTransit: Record Location;
        TransferLines: TestPage "Transfer Lines";
    begin
        // [SCENARIO 650429] Show Document opens the subcontracting transfer order for a legacy subcontracting transfer line
        LibraryApplicationArea.EnablePremiumSetup();
        ManufacturingSetup.Get();
        ManufacturingSetup."Legacy Subcontracting" := true;
        ManufacturingSetup.Modify();

        // [GIVEN] A transfer order whose line is linked to a production order
        LibraryWarehouse.CreateLocation(LocationFrom);
        LibraryWarehouse.CreateLocation(LocationTo);
        LibraryWarehouse.CreateInTransitLocation(LocationInTransit);
        LibraryWarehouse.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, LocationInTransit.Code);
        TransferLine.Init();
        TransferLine."Document No." := TransferHeader."No.";
        TransferLine."Line No." := 10000;
        TransferLine."Prod. Order No." := 'TEST-LEGACYSUBC';
        TransferLine.Insert();

        // [WHEN] Show Document is invoked from Transfer Lines
        TransferLines.OpenView();
        TransferLines.GoToRecord(TransferLine);
        TransferLines."Show Document".Invoke();

        // [THEN] The Subcontr. Transfer Order page opens for the selected transfer order
        if not SubcontractTransferOrderOpened then
            Error('The subcontracting transfer order page was not opened.');
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure SubcontrTransferOrderPageHandler(var SubcontrTransferOrder: TestPage "Subcontr. Transfer Order")
    begin
        SubcontractTransferOrderOpened := true;
    end;
}
#endif
