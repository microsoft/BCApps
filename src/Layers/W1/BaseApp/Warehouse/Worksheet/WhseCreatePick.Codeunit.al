// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Worksheet;

using Microsoft.Warehouse.Activity;

codeunit 5778 "Whse. Create Pick"
{
    TableNo = "Whse. Worksheet Line";

    trigger OnRun()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnRun(Rec, IsHandled);
        if IsHandled then
            exit;

        WkshPickLine.Copy(Rec);
        WhseCreatePick.SetWkshPickLine(WkshPickLine);
        WhseCreatePick.RunModal();
        if WhseCreatePick.GetResultMessage() then
            Rec.AutofillQtyToHandle(Rec);
        Clear(WhseCreatePick);

        Rec.Reset();
        Rec.SetCurrentKey("Worksheet Template Name", Name, "Location Code", "Sorting Sequence No.");
        Rec.FilterGroup := 2;
        Rec.SetRange("Worksheet Template Name", Rec."Worksheet Template Name");
        Rec.SetRange(Name, Rec.Name);
        Rec.SetRange("Location Code", Rec."Location Code");
        Rec.FilterGroup := 0;
    end;

    var
        WkshPickLine: Record "Whse. Worksheet Line";
        WhseCreatePick: Report "Create Pick";

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var WhseWorksheetLine: Record "Whse. Worksheet Line"; var IsHandled: Boolean);
    begin
    end;
}

