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
                action(CreateEDocument)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Create Self-Billed E-Document';
                    Image = CreateDocument;
                    ToolTip = 'Creates a self-billed E-Document from this posted purchase invoice and sends it via service. Only available for vendors with a self-billing agreement and registered participant IDs.';
                    Enabled = (not SelfBillEDocumentExists) and CanSelfBill;

                    trigger OnAction()
                    var
                        EDocumentProcessing: Codeunit "E-Document Processing";
                    begin
                        if EDocumentProcessing.CreateEDocumentFromPostedDocumentPage(Rec, Enum::"E-Document Type"::"Self-Billed Purchase Invoice") then
                            Message(EDocumentCreatedMsg)
                        else
                            Message(EDocumentNotCreatedMsg);
                    end;
                }
            }
        }
    }

    var
        ShowEDocumentPdfPreview: Boolean;
        SelfBillEDocumentExists: Boolean;
        CanSelfBill: Boolean;
        EDocumentCreatedMsg: Label 'The e-document has been created.';
        EDocumentNotCreatedMsg: Label 'The e-document could not be created.';

    trigger OnAfterGetCurrRecord()
    var
        EDocument: Record "E-Document";
        EDocumentHelper: Codeunit "E-Document Helper";
        EDocumentSubscribers: Codeunit "E-Document Subscribers";
        EDocDataStorageEntryNo: Integer;
    begin
        EDocDataStorageEntryNo := EDocumentHelper.GetInboundPdfPreviewEntryNo(Rec.RecordId());
        ShowEDocumentPdfPreview := EDocDataStorageEntryNo <> 0;
        CurrPage.EDocumentPdfPreview.Page.SetRecFilterByEDocDataStorageEntryNo(EDocDataStorageEntryNo);

        EDocument.SetRange("Document Record ID", Rec.RecordId());
        SelfBillEDocumentExists := not EDocument.IsEmpty();
        CanSelfBill := EDocumentSubscribers.IsEligibleForSelfBilling(Rec."Buy-from Vendor No.");
    end;
}
