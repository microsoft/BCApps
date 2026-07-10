// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Counting.Document;

codeunit 5888 "Phys. Invt.-Calc. Qty. One"
{
    TableNo = "Phys. Invt. Order Line";

    trigger OnRun()
    begin
        PhysInvtOrderLine.Get(Rec."Document No.", Rec."Line No.");

        if not Confirm(
             StrSubstNo(ConfirmCalculationQst, Rec.FieldCaption("Qty. Expected (Base)")), false)
        then
            exit;

        if not PhysInvtOrderLine.EmptyLine() then begin
            PhysInvtOrderLine.TestField("Item No.");
            PhysInvtOrderLine.CalcQtyAndTrackLinesExpected();
            OnOnRunOnBeforePhysInvtOrderLineModify(PhysInvtOrderLine);
            PhysInvtOrderLine.Modify();
        end;

        Rec := PhysInvtOrderLine;
    end;

    var
        ConfirmCalculationQst: Label 'Do you want to calculate %1 for this line?', Comment = '%1 = field caption';
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";

    [IntegrationEvent(false, false)]
    local procedure OnOnRunOnBeforePhysInvtOrderLineModify(var PhysInvtOrderLine: Record "Phys. Invt. Order Line")
    begin
    end;
}

