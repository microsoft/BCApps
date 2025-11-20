// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Purchases.Document;
using Microsoft.Utilities;

table 6670 "Returns-Related Document"
{
    Caption = 'Returns-Related Document';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Document Type"; Enum "Returns Related Document Type")
        {
            Caption = 'Document Type';
        }
        field(3; "No."; Code[20])
        {
            Caption = 'No.';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure ShowDocumentCard()
    var
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
        IsHandled: Boolean;
    begin
        Clear(CopyDocumentMgt);
        case "Document Type" of
            "Document Type"::"Sales Order":
                SalesHeader.Get("Sales Document Type"::Order, "No.");
            "Document Type"::"Sales Invoice":
                SalesHeader.Get("Sales Document Type"::Invoice, "No.");
            "Document Type"::"Sales Return Order":
                SalesHeader.Get("Sales Document Type"::"Return Order", "No.");
            "Document Type"::"Sales Credit Memo":
                SalesHeader.Get("Sales Document Type"::"Credit Memo", "No.");
            "Document Type"::"Purchase Order":
                PurchaseHeader.Get("Purchase Document Type"::Order, "No.");
            "Document Type"::"Purchase Invoice":
                PurchaseHeader.Get("Purchase Document Type"::Invoice, "No.");
            "Document Type"::"Purchase Return Order":
                PurchaseHeader.Get("Purchase Document Type"::"Return Order", "No.");
            "Document Type"::"Purchase Credit Memo":
                PurchaseHeader.Get("Purchase Document Type"::"Credit Memo", "No.");
            else begin
                OnShowDocumentCardOnElseCase(Rec, IsHandled);
                if IsHandled then
                    exit;
            end;
        end;

        if IsSalesDocument() then
            CopyDocumentMgt.ShowSalesDoc(SalesHeader);
        if IsPurchaseDocument() then
            CopyDocumentMgt.ShowPurchDoc(PurchaseHeader);
    end;

    procedure IsPurchaseDocument() Result: Boolean
    begin
        Result :=
            "Document Type" in [
                "Document Type"::"Purchase Order", "Document Type"::"Purchase Invoice",
                "Document Type"::"Purchase Credit Memo", "Document Type"::"Purchase Return Order"];

        OnAfterIsPurchaseDocument("Document Type", Result);
    end;

    procedure IsSalesDocument() Result: Boolean
    begin
        Result :=
            "Document Type" in [
                "Document Type"::"Sales Order", "Document Type"::"Sales Invoice",
                "Document Type"::"Sales Credit Memo", "Document Type"::"Sales Return Order"];

        OnAfterIsSalesDocument("Document Type", Result);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsPurchaseDocument(DocumentType: Enum "Returns Related Document Type"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsSalesDocument(DocumentType: Enum "Returns Related Document Type"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowDocumentCardOnElseCase(ReturnsRelatedDocument: Record "Returns-Related Document"; var IsHandled: Boolean)
    begin
    end;
}

