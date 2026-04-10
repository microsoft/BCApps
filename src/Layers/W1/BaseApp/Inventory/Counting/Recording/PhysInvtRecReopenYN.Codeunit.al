// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Counting.Recording;

codeunit 5877 "Phys. Invt. Rec.-Reopen (Y/N)"
{
    TableNo = "Phys. Invt. Record Header";

    trigger OnRun()
    var
        PhysInvtRecordHeader: Record "Phys. Invt. Record Header";
    begin
        PhysInvtRecordHeader.Copy(Rec);

        if Confirm(ConfirmReopenQst, false) then
            CODEUNIT.Run(CODEUNIT::"Phys. Invt. Rec.-Reopen", PhysInvtRecordHeader);

        Rec := PhysInvtRecordHeader;
    end;

    var
        ConfirmReopenQst: Label 'Do you want to reopen the recording?';
}

