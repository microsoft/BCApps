// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Purchases.Document;
using Microsoft.Utilities;

/// <summary>
/// Stores links between return documents and their related sales or purchase documents.
/// </summary>
table 6670 "Returns-Related Document"
{
    Caption = 'Returns-Related Document';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Specifies the unique entry number for this related document record.
        /// </summary>
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        /// <summary>
        /// Specifies the type of the related document such as sales order, invoice, or return order.
        /// </summary>
        field(2; "Document Type"; Enum "Returns Related Document Type")
        {
            Caption = 'Document Type';
            ToolTip = 'Specifies the type of the related document.';
        }
        /// <summary>
        /// Specifies the document number of the related sales or purchase document.
        /// </summary>
        field(3; "No."; Code[20])
        {
            Caption = 'No.';
            ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
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

    /// <summary>
    /// Opens the document card page for the related document.
    /// </summary>
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

    /// <summary>
    /// Determines whether this related document is a purchase document.
    /// </summary>
    /// <returns>True if this is a purchase document type.</returns>
    procedure IsPurchaseDocument() Result: Boolean
    begin
        Result :=
            "Document Type" in [
                "Document Type"::"Purchase Order", "Document Type"::"Purchase Invoice",
                "Document Type"::"Purchase Credit Memo", "Document Type"::"Purchase Return Order"];

        OnAfterIsPurchaseDocument("Document Type", Result);
    end;

    /// <summary>
    /// Determines whether this related document is a sales document.
    /// </summary>
    /// <returns>True if this is a sales document type.</returns>
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

