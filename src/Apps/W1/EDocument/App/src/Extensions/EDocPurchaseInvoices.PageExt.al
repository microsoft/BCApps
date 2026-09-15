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
            part(EDocumentPdfPreview; "Inbound E-Doc. Picture")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Preview';
                Visible = ShowEDocumentPdfPreview;
                ShowFilter = false;
            }
        }
        addlast(Control1)
        {
            field(EDocumentStatus; EDocumentStatusText)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'E-Document Status';
                ToolTip = 'Specifies the status of the latest electronic document linked to this record. Hidden by default; add it via Personalize to make it visible.';
                Visible = false;
                Editable = false;
            }
        }
    }

    trigger OnOpenPage()
    var
        EDocument: Record "E-Document";
    begin
        HasAnyEDocument := GuiAllowed() and EDocument.HasEDocument();
    end;

    trigger OnAfterGetRecord()
    var
        EDocumentLookup: Record "E-Document";
    begin
        EDocumentStatusText := '';
        if HasAnyEDocument then
            EDocumentStatusText := EDocumentLookup.GetLatestStatus(Rec.RecordId());
    end;

    trigger OnAfterGetCurrRecord()
    var
        EDocumentHelper: Codeunit "E-Document Helper";
        EDocDataStorageEntryNo: Integer;
    begin
        EDocDataStorageEntryNo := EDocumentHelper.GetInboundPdfPreviewEntryNo(Rec.RecordId(), Rec."E-Document Link");
        ShowEDocumentPdfPreview := EDocDataStorageEntryNo <> 0;
        CurrPage.EDocumentPdfPreview.Page.SetRecFilterByEDocDataStorageEntryNo(EDocDataStorageEntryNo);
    end;

    var
        HasAnyEDocument: Boolean;
        ShowEDocumentPdfPreview: Boolean;
        EDocumentStatusText: Text;
}
