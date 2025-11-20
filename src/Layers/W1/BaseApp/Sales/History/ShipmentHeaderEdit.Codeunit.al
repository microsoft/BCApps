// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

codeunit 391 "Shipment Header - Edit"
{
    Permissions = TableData "Sales Shipment Header" = rm;
    TableNo = "Sales Shipment Header";

    trigger OnRun()
    begin
        SalesShptHeader := Rec;
        SalesShptHeader.LockTable();
        SalesShptHeader.Find();
        OnRunOnBeforeAssignValues(SalesShptHeader, Rec);
        SalesShptHeader."Shipping Agent Code" := Rec."Shipping Agent Code";
        SalesShptHeader."Shipping Agent Service Code" := Rec."Shipping Agent Service Code";
        SalesShptHeader."Package Tracking No." := Rec."Package Tracking No.";
        OnBeforeSalesShptHeaderModify(SalesShptHeader, Rec);
        SalesShptHeader.TestField("No.", Rec."No.");
        SalesShptHeader.Modify();
        Rec := SalesShptHeader;

        OnRunOnAfterSalesShptHeaderEdit(Rec);
    end;

    var
        SalesShptHeader: Record "Sales Shipment Header";

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesShptHeaderModify(var SalesShptHeader: Record "Sales Shipment Header"; FromSalesShptHeader: Record "Sales Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterSalesShptHeaderEdit(var SalesShptHeader: Record "Sales Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeAssignValues(var SalesShipmentHeader: Record "Sales Shipment Header"; SalesShipmentHeaderRec: Record "Sales Shipment Header")
    begin
    end;
}

