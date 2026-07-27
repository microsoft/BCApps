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
            part(EDocumentPdfPreview; "Inbound E-Doc. Picture")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Preview';
                Visible = ShowEDocumentPdfPreview;
                ShowFilter = false;
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
        EDocDataStorageEntryNo := EDocumentHelper.GetInboundPdfPreviewEntryNo(Rec.RecordId());
        ShowEDocumentPdfPreview := EDocDataStorageEntryNo <> 0;
        CurrPage.EDocumentPdfPreview.Page.SetRecFilterByEDocDataStorageEntryNo(EDocDataStorageEntryNo);
    end;
}
