// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

/// <summary>
/// Updates the print counter on posted sales shipment headers when documents are printed.
/// </summary>
codeunit 314 "Sales Shpt.-Printed"
{
    Permissions = TableData "Sales Shipment Header" = rimd;
    TableNo = "Sales Shipment Header";

    trigger OnRun()
    begin
        OnBeforeOnRun(Rec, SuppressCommit);
        Rec.Find();
        Rec."No. Printed" := Rec."No. Printed" + 1;
        OnBeforeModify(Rec);
        Rec.Modify();
        if not SuppressCommit then
            Commit();
    end;

    var
        SuppressCommit: Boolean;

    /// <summary>
    /// Sets whether the commit operation should be suppressed after updating the print counter.
    /// </summary>
    /// <param name="NewSuppressCommit">Specifies whether to suppress the commit operation.</param>
    procedure SetSuppressCommit(NewSuppressCommit: Boolean)
    begin
        SuppressCommit := NewSuppressCommit;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModify(var SalesShipmentHeader: Record "Sales Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var SalesShipmentHeader: Record "Sales Shipment Header"; var SuppressCommit: Boolean)
    begin
    end;
}

