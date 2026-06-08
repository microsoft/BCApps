// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Counting.Recording;

using Microsoft.Inventory.Counting.Document;

codeunit 5878 "Phys. Invt. Rec.-Reopen"
{
    TableNo = "Phys. Invt. Record Header";

    trigger OnRun()
    begin
        PhysInvtRecordHeader.Copy(Rec);
        Code();
        Rec := PhysInvtRecordHeader;

        OnAfterOnRun(Rec);
    end;

    var
        ReopeningLinesMsg: Label 'Reopening lines              #2######', Comment = '%2 = counter';
        PhysInvtRecordHeader: Record "Phys. Invt. Record Header";
        Window: Dialog;
        LineCount: Integer;

    procedure "Code"()
    var
        PhysInvtRecordLine: Record "Phys. Invt. Record Line";
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
    begin
        OnBeforeCode(PhysInvtRecordHeader);

        PhysInvtRecordHeader.TestField("Order No.");
        PhysInvtRecordHeader.TestField("Recording No.");
        PhysInvtRecordHeader.TestField(Status, PhysInvtRecordHeader.Status::Finished);

        Window.Open(
          '#1#################################\\' + ReopeningLinesMsg);
        Window.Update(1, StrSubstNo('%1 %2', PhysInvtRecordHeader.TableCaption(), PhysInvtRecordHeader."Order No."));

        PhysInvtOrderHeader.Get(PhysInvtRecordHeader."Order No.");
        PhysInvtOrderHeader.TestField(Status, PhysInvtOrderHeader.Status::Open);

        LineCount := 0;
        PhysInvtRecordLine.Reset();
        PhysInvtRecordLine.SetRange("Order No.", PhysInvtRecordHeader."Order No.");
        PhysInvtRecordLine.SetRange("Recording No.", PhysInvtRecordHeader."Recording No.");
        if PhysInvtRecordLine.Find('-') then
            repeat
                LineCount := LineCount + 1;
                Window.Update(2, LineCount);
                if PhysInvtRecordLine."Item No." <> '' then begin
                    PhysInvtOrderLine.Get(PhysInvtRecordLine."Order No.", PhysInvtRecordLine."Order Line No.");
                    PhysInvtOrderLine."Qty. Recorded (Base)" -= PhysInvtRecordLine."Quantity (Base)";
                    PhysInvtOrderLine."No. Finished Rec.-Lines" -= 1;
                    PhysInvtOrderLine."On Recording Lines" := PhysInvtOrderLine."No. Finished Rec.-Lines" <> 0;
                    OnBeforePhysInvtOrderLineModify(PhysInvtOrderLine, PhysInvtRecordLine, PhysInvtRecordHeader);
                    PhysInvtOrderLine.Modify();

                    PhysInvtRecordLine."Order Line No." := 0;
                    PhysInvtRecordLine."Recorded Without Order" := false;
                    PhysInvtRecordLine.Modify();
                end;
            until PhysInvtRecordLine.Next() = 0;

        PhysInvtRecordHeader.Status := PhysInvtRecordHeader.Status::Open;
        PhysInvtRecordHeader.Modify();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnRun(var PhysInvtRecordHeader: Record "Phys. Invt. Record Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePhysInvtOrderLineModify(var PhysInvtOrderLine: Record "Phys. Invt. Order Line"; PhysInvtRecordLine: Record "Phys. Invt. Record Line"; PhysInvtRecordHeader: Record "Phys. Invt. Record Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCode(var PhysInvtRecordHeader: Record "Phys. Invt. Record Header")
    begin
    end;
}

