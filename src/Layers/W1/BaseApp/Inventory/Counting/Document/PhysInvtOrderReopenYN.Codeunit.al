// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Counting.Document;

codeunit 5881 "Phys. Invt. Order-Reopen (Y/N)"
{
    TableNo = "Phys. Invt. Order Header";

    trigger OnRun()
    var
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
    begin
        PhysInvtOrderHeader.Copy(Rec);

        if Confirm(ConfirmReopenQst, false) then
            CODEUNIT.Run(CODEUNIT::"Phys. Invt. Order-Reopen", PhysInvtOrderHeader);

        Rec := PhysInvtOrderHeader;
    end;

    var
        ConfirmReopenQst: Label 'Do you want to reopen the order?';
}

