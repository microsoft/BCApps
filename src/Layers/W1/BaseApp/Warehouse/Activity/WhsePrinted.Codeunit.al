// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Activity;

codeunit 5779 "Whse.-Printed"
{
    TableNo = "Warehouse Activity Header";

    trigger OnRun()
    begin
        OnBeforeOnRun(Rec, SuppressCommit);

        Rec.LockTable();
        Rec.Find();
        Rec."No. Printed" := Rec."No. Printed" + 1;
        Rec."Date of Last Printing" := Today;
        Rec."Time of Last Printing" := Time;
        OnBeforeModify(Rec);
        Rec.Modify();
        if not SuppressCommit then
            Commit();
    end;

    var
        SuppressCommit: Boolean;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModify(var WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var WarehouseActivityHeader: Record "Warehouse Activity Header"; var SuppressCommit: Boolean)
    begin
    end;
}

