// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Counting.Document;

using Microsoft.Foundation.Reporting;
using Microsoft.Inventory.Counting.History;

codeunit 5885 "Phys. Invt. Order-Post + Print"
{
    TableNo = "Phys. Invt. Order Header";

    trigger OnRun()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnRunOnBeforeConfirm(Rec, IsHandled);
        if IsHandled then
            exit;

        PhysInvtOrderHeader.Copy(Rec);

        if not Confirm(ConfirmPostQst, false) then
            exit;

        OnPhysInvtOrderPostPrintOnAfterConfirmBeforePost(PhysInvtOrderHeader, IsHandled);
        if IsHandled then
            exit;

        CODEUNIT.Run(CODEUNIT::"Phys. Invt. Order-Post", PhysInvtOrderHeader);

        OnAfterPostPhysInvtOrder(PhysInvtOrderHeader);

        PstdPhysInvtOrderHdr.Init();
        PstdPhysInvtOrderHdr."No." := PhysInvtOrderHeader."Last Posting No.";
        PstdPhysInvtOrderHdr.SetRecFilter();
        DocPrint.PrintPostedInvtOrder(PstdPhysInvtOrderHdr, false);

        Rec := PhysInvtOrderHeader;
    end;

    var
        ConfirmPostQst: Label 'Do you want to post and print the order?';
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PstdPhysInvtOrderHdr: Record "Pstd. Phys. Invt. Order Hdr";
        DocPrint: Codeunit "Document-Print";

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostPhysInvtOrder(var PhysInvtOrderHeader: Record "Phys. Invt. Order Header");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPhysInvtOrderPostPrintOnAfterConfirmBeforePost(var PhysInvtOrderHeader: Record "Phys. Invt. Order Header"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeConfirm(var PhysInvtOrderHeader: Record "Phys. Invt. Order Header"; var IsHandled: Boolean)
    begin
    end;
}

