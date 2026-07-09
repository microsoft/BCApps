// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.History;

using Microsoft.eServices.EDocument;

pageextension 6146 "E-Doc. Posted Purch. Inv." extends "Posted Purchase Invoice"
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

    actions
    {
        addafter("&Invoice")
        {
            group("E-Document")
            {
                action("OpenEDocument")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Open';
                    Image = Open;
                    ToolTip = 'Opens the E-Document card page.';

                    trigger OnAction()
                    var
                        EDocument: Record "E-Document";
                    begin
                        EDocument.OpenEDocument(Rec.RecordId);
                    end;
                }
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
        CurrPage.EDocumentPdfPreview.Page.SetEDocDataStorage(EDocDataStorageEntryNo);
    end;
}
