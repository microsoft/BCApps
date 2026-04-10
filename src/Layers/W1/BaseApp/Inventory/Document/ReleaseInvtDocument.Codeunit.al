// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Document;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Setup;

codeunit 5855 "Release Invt. Document"
{
    TableNo = "Invt. Document Header";

    trigger OnRun()
    var
        Item: Record Item;
        IsHandled: Boolean;
    begin
        if Rec.Status = Rec.Status::Released then
            exit;

        InvtSetup.Get();
        if InvtSetup."Location Mandatory" then
            Rec.TestField("Location Code");
        Rec.TestField(Status, Rec.Status::Open);

        IsHandled := false;
        OnRunOnBeforeCheckInvtDocLines(Rec, IsHandled);
        if not IsHandled then begin
            InvtDocLine.SetRange("Document Type", Rec."Document Type");
            InvtDocLine.SetRange("Document No.", Rec."No.");
            InvtDocLine.SetFilter(Quantity, '<>0');
            if not InvtDocLine.FindFirst() then
                Error(NothingToReleaseErr, Rec."No.");

            InvtDocLine.SetFilter("Item No.", '<>%1', '');
            if InvtDocLine.FindSet() then
                repeat
                    Item.Get(InvtDocLine."Item No.");
                    if Item.IsInventoriableType() then
                        InvtDocLine.TestField("Unit of Measure Code");
                until InvtDocLine.Next() = 0;
            InvtDocLine.Reset();
        end;

        Rec.Validate(Status, Rec.Status::Released);
        Rec.Modify();
    end;

    var
        InvtDocLine: Record "Invt. Document Line";
        InvtSetup: Record "Inventory Setup";
        NothingToReleaseErr: Label 'There is nothing to release for item document %1.', Comment = '%1 - document number';

    procedure Reopen(var InvtDocHeader: Record "Invt. Document Header")
    begin
        if InvtDocHeader.Status = InvtDocHeader.Status::Open then
            exit;
        InvtDocHeader.Validate(Status, InvtDocHeader.Status::Open);
        InvtDocHeader.Modify();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeCheckInvtDocLines(var InvtDocumentHeader: Record "Invt. Document Header"; var IsHandled: Boolean)
    begin
    end;
}
