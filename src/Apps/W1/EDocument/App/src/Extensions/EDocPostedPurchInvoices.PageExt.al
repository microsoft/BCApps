// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.History;

using Microsoft.eServices.EDocument;

pageextension 6109 "E-Doc. Posted Purch. Invoices" extends "Posted Purchase Invoices"
{
    layout
    {
        addbefore(IncomingDocAttachFactBox)
        {
            part(EDocumentPdfPreview; "E-Doc. Posted Purch. Preview")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Preview';
                Visible = ShowEDocumentPdfPreview;
                ShowFilter = false;
                SubPageLink = "No." = field("No.");
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
        ShowEDocumentPdfPreview := EDocumentHelper.GetInboundPdfPreviewEntryNo(Rec.RecordId(), EDocDataStorageEntryNo);
    end;
}
