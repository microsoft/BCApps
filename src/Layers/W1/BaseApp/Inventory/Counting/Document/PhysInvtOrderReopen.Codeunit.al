// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Counting.Document;

using Microsoft.Inventory.Tracking;

codeunit 5882 "Phys. Invt. Order-Reopen"
{
    TableNo = "Phys. Invt. Order Header";

    trigger OnRun()
    begin
        OnBeforeOnRun(Rec);
        PhysInvtOrderHeader.Copy(Rec);
        Code();
        Rec := PhysInvtOrderHeader;

        OnAfterOnRun(Rec);
    end;

    var
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        ReservEntry: Record "Reservation Entry";
        Window: Dialog;
        LineCount: Integer;

        ReopeningLinesMsg: Label 'Reopening lines              #2######', Comment = '%2 = counter';

    procedure "Code"()
    begin
        PhysInvtOrderHeader.TestField("No.");
        PhysInvtOrderHeader.TestField(Status, PhysInvtOrderHeader.Status::Finished);

        Window.Open(
          '#1#################################\\' + ReopeningLinesMsg);
        Window.Update(1, StrSubstNo('%1 %2', PhysInvtOrderHeader.TableCaption(), PhysInvtOrderHeader."No."));

        PhysInvtOrderHeader.LockTable();
        PhysInvtOrderLine.LockTable();

        LineCount := 0;
        PhysInvtOrderLine.Reset();
        PhysInvtOrderLine.SetRange("Document No.", PhysInvtOrderHeader."No.");
        if PhysInvtOrderLine.Find('-') then
            repeat
                if not PhysInvtOrderLine.EmptyLine() then begin
                    LineCount := LineCount + 1;
                    Window.Update(2, LineCount);

                    ReservEntry.Reset();
                    ReservEntry.SetSourceFilter(
                      DATABASE::"Phys. Invt. Order Line", 0, PhysInvtOrderLine."Document No.", PhysInvtOrderLine."Line No.", false);
                    ReservEntry.SetSourceFilter('', 0);
                    ReservEntry.DeleteAll();

                    PhysInvtOrderLine."Pos. Qty. (Base)" := 0;
                    PhysInvtOrderLine."Neg. Qty. (Base)" := 0;
                    PhysInvtOrderLine."Quantity (Base)" := 0;
                    PhysInvtOrderLine."Entry Type" := PhysInvtOrderLine."Entry Type"::" ";
                    OnBeforePhysInvtOrderLineModify(PhysInvtOrderLine);
                    PhysInvtOrderLine.Modify();
                end;
            until PhysInvtOrderLine.Next() = 0;

        OnCodeOnBeforeSetStatusToOpen(PhysInvtOrderHeader);
        PhysInvtOrderHeader.Status := PhysInvtOrderHeader.Status::Open;
        PhysInvtOrderHeader.Modify();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnRun(var PhysInvtOrderHeader: Record "Phys. Invt. Order Header");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var PhysInvtOrderHeader: Record "Phys. Invt. Order Header");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePhysInvtOrderLineModify(var PhysInvtOrderLine: Record "Phys. Invt. Order Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforeSetStatusToOpen(var PhysInvtOrderHeader: Record "Phys. Invt. Order Header")
    begin
    end;
}

