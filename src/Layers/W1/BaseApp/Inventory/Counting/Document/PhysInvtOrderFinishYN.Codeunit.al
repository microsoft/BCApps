// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Counting.Document;

codeunit 5879 "Phys. Invt. Order-Finish (Y/N)"
{
    TableNo = "Phys. Invt. Order Header";

    trigger OnRun()
    var
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnRun(Rec, IsHandled);
        if IsHandled then
            exit;

        PhysInvtOrderHeader.Copy(Rec);

        if Confirm(ConfirmFinishQst, false) then
            CODEUNIT.Run(CODEUNIT::"Phys. Invt. Order-Finish", PhysInvtOrderHeader);

        Rec := PhysInvtOrderHeader;
    end;

    var
        ConfirmFinishQst: Label 'Do you want to finish the order?';

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var Rec: Record "Phys. Invt. Order Header"; var IsHandled: Boolean)
    begin
    end;
}

