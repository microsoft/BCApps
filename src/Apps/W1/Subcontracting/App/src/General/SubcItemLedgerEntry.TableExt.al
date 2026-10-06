// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Transfer;
using Microsoft.Purchases.Document;

tableextension 20500 "Subc. Item Ledger Entry" extends "Item Ledger Entry"
{
    AllowInCustomizations = AsReadOnly;
    fields
    {
        field(20510; "Subc. Prod. Order No."; Code[20])
        {
            Caption = 'Prod. Order No.';
            DataClassification = CustomerContent;
        }
        field(20511; "Subc. Prod. Order Line No."; Integer)
        {
            Caption = 'Prod. Order Line No.';
            DataClassification = CustomerContent;
        }
        field(20512; "Subc. Purch. Order No."; Code[20])
        {
            Caption = 'Subc. Purch. Order No.';
            DataClassification = CustomerContent;
            TableRelation = "Purchase Header"."No." where("Document Type" = const(Order));
        }
        field(20513; "Subc. Purch. Order Line No."; Integer)
        {
            Caption = 'Subc. Purch. Order Line No.';
            DataClassification = CustomerContent;
            TableRelation = "Purchase Line"."Line No." where("Document Type" = const(Order),
                                                              "Document No." = field("Subc. Purch. Order No."));
        }
        field(20514; "Subc. Operation No."; Code[10])
        {
            Caption = 'Subc. Operation No.';
            DataClassification = CustomerContent;
        }
        field(20515; "Subc. Component at Subcontr."; Boolean)
        {
            Caption = 'Component Transfer at Subcontractor';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }
    keys
    {
        key(Key99001500; "Subc. Prod. Order No.", "Subc. Prod. Order Line No.", "Subc. Purch. Order No.", "Subc. Purch. Order Line No.", "Subc. Component at Subcontr.") { }
    }

    internal procedure IsSubcontractorComponentTransfer(): Boolean
    var
        ComponentAtSubcontractor: Boolean;
        MissingTransferDocumentErrorInfo: ErrorInfo;
    begin
        if TryGetSubcontractorComponentTransfer(ComponentAtSubcontractor) then
            exit(ComponentAtSubcontractor);

        MissingTransferDocumentErrorInfo.Message := StrSubstNo(MissingTransferDocumentErr, "Entry No.", "Document Type", "Document No.");
        MissingTransferDocumentErrorInfo.DataClassification := DataClassification::CustomerContent;
        MissingTransferDocumentErrorInfo.ErrorType := ErrorType::Internal;
        Error(MissingTransferDocumentErrorInfo);
    end;

    internal procedure TryGetSubcontractorComponentTransfer(var ComponentAtSubcontractor: Boolean): Boolean
    var
        DirectTransHeader: Record "Direct Trans. Header";
        TransferReceiptHeader: Record "Transfer Receipt Header";
        TransferShipmentHeader: Record "Transfer Shipment Header";
    begin
        ComponentAtSubcontractor := false;
        if ("Entry Type" <> "Entry Type"::Transfer) or ("Subc. Prod. Order No." = '') or
           ("Subc. Prod. Order Line No." = 0) or ("Prod. Order Comp. Line No." = 0)
        then
            exit(true);

        // Use the posted direction, never the component's or vendor's current location.
        case "Document Type" of
            "Document Type"::"Direct Transfer":
                if DirectTransHeader.Get("Document No.") then begin
                    if DirectTransHeader."Return Order" then
                        ComponentAtSubcontractor := "Location Code" = DirectTransHeader."Transfer-from Code"
                    else
                        ComponentAtSubcontractor := "Location Code" = DirectTransHeader."Transfer-to Code";
                    exit(true);
                end;
            "Document Type"::"Transfer Shipment":
                if TransferShipmentHeader.Get("Document No.") then begin
                    ComponentAtSubcontractor := TransferShipmentHeader."Subc. Return Order" and
                      ("Location Code" = TransferShipmentHeader."Transfer-from Code");
                    exit(true);
                end;
            "Document Type"::"Transfer Receipt":
                if TransferReceiptHeader.Get("Document No.") then begin
                    ComponentAtSubcontractor := not TransferReceiptHeader."Subc. Return Order" and
                      ("Location Code" = TransferReceiptHeader."Transfer-to Code");
                    exit(true);
                end;
        end;

        exit(false);
    end;

    var
        MissingTransferDocumentErr: Label 'Cannot identify the subcontractor movement for item ledger entry %1. Posted %2 %3 is missing or unsupported. Restore the posted transfer document before upgrading subcontracting.', Comment = '%1 = item ledger entry number, %2 = document type, %3 = document number';
}
