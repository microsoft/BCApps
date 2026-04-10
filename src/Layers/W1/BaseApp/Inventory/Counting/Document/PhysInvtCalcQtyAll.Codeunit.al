// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Counting.Document;

codeunit 5887 "Phys. Invt.-Calc. Qty. All"
{
    TableNo = "Phys. Invt. Order Header";

    trigger OnRun()
    var
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        Selection: Integer;
        IsHandled: Boolean;
    begin
        PhysInvtOrderHeader.Copy(Rec);

        IsHandled := false;
        OnRunOnBeforeSelectSelection(PhysInvtOrderHeader, Selection, IsHandled);
        if not IsHandled then begin
            Selection := StrMenu(SelectionQst, 1);
            if Selection = 0 then
                exit;
        end;

        PhysInvtOrderLine.Reset();
        PhysInvtOrderLine.SetRange("Document No.", PhysInvtOrderHeader."No.");
        if PhysInvtOrderLine.Find('-') then
            repeat
                if (Selection = 1) or
                   ((Selection = 2) and not PhysInvtOrderLine."Qty. Exp. Calculated")
                then
                    if not PhysInvtOrderLine.EmptyLine() then begin
                        PhysInvtOrderLine.TestField("Item No.");
                        PhysInvtOrderLine.CalcQtyAndTrackLinesExpected();
                        PhysInvtOrderLine.Modify();
                    end;
            until PhysInvtOrderLine.Next() = 0;

        Rec := PhysInvtOrderHeader;
    end;

    var
        SelectionQst: Label 'All Order Lines,Only Not Calculated Lines';

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeSelectSelection(var PhysInvtOrderHeader: Record "Phys. Invt. Order Header"; var Selection: Integer; var IsHandled: Boolean)
    begin
    end;
}

