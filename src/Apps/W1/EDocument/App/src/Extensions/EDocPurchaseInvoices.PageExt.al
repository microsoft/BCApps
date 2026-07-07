// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

using Microsoft.eServices.EDocument;

pageextension 6100 "E-Doc. Purchase Invoices" extends "Purchase Invoices"
{
    layout
    {
        addbefore(IncomingDocAttachFactBox)
        {
            part(EDocumentPdfPreview; "E-Doc. Purch. Doc. Preview")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Preview';
                Visible = ShowEDocumentPdfPreview;
                ShowFilter = false;
                SubPageLink = "Document Type" = field("Document Type"), "No." = field("No.");
            }
        }
    }

    var
        ShowEDocumentPdfPreview: Boolean;

    trigger OnAfterGetCurrRecord()
    var
        EDocumentHelper: Codeunit "E-Document Helper";
        EDocDataStorageEntryNo: Integer;
    begin
        ShowEDocumentPdfPreview := EDocumentHelper.GetInboundPdfPreviewEntryNo(Rec.RecordId(), Rec."E-Document Link", EDocDataStorageEntryNo);
    end;
}
