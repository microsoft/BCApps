// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Counting.Recording;

codeunit 5875 "Phys. Invt. Rec.-Finish (Y/N)"
{
    TableNo = "Phys. Invt. Record Header";

    trigger OnRun()
    var
        PhysInvtRecordHeader: Record "Phys. Invt. Record Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnRun(Rec, IsHandled);
        if IsHandled then
            exit;

        PhysInvtRecordHeader.Copy(Rec);

        if Confirm(ConfirmFinishQst, false) then
            CODEUNIT.Run(CODEUNIT::"Phys. Invt. Rec.-Finish", PhysInvtRecordHeader);

        Rec := PhysInvtRecordHeader;
    end;

    var
        ConfirmFinishQst: Label 'Do you want to finish the recording?';

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var RecPhysInvtRecordHeader: Record "Phys. Invt. Record Header"; var IsHandled: Boolean)
    begin
    end;
}

