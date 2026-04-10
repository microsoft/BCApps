// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Document;

using Microsoft.Inventory.History;

codeunit 5852 "Invt. Doc.-Post + Print"
{
    TableNo = "Invt. Document Header";

    trigger OnRun()
    begin
        InvtDocHeader.Copy(Rec);
        Code();
        Rec := InvtDocHeader;
    end;

    var
        InvtDocHeader: Record "Invt. Document Header";
        InvtRcptHeader: Record "Invt. Receipt Header";
        InvtShptHeader: Record "Invt. Shipment Header";
        PostingConfirmationTxt: Label 'Do you want to post the %1?', Comment = '%1 - document type.';

    local procedure "Code"()
    var
        InvtDocPostReceipt: Codeunit "Invt. Doc.-Post Receipt";
        InvtDocPostShipment: Codeunit "Invt. Doc.-Post Shipment";
    begin
        if not Confirm(PostingConfirmationTxt, false, InvtDocHeader."Document Type") then
            exit;

        case InvtDocHeader."Document Type" of
            InvtDocHeader."Document Type"::Receipt:
                begin
                    InvtDocPostReceipt.Run(InvtDocHeader);
                    if InvtDocHeader."No. Series" = InvtDocHeader."Posting No. Series" then
                        InvtRcptHeader."No." := InvtDocHeader."No."
                    else
                        InvtRcptHeader."No." := InvtDocHeader."Posting No.";
                    InvtRcptHeader.SetRecFilter();
                    InvtRcptHeader.PrintRecords(false);
                end;
            InvtDocHeader."Document Type"::Shipment:
                begin
                    InvtDocPostShipment.Run(InvtDocHeader);
                    if InvtDocHeader."No. Series" = InvtDocHeader."Posting No. Series" then
                        InvtShptHeader."No." := InvtDocHeader."No."
                    else
                        InvtShptHeader."No." := InvtDocHeader."Posting No.";
                    InvtShptHeader.SetRecFilter();
                    InvtShptHeader.PrintRecords(false);
                end;
        end;
    end;
}

