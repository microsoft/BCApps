// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Transfer;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Message;

pageextension 6106 "E-Doc. Posted Transfer Shpmnt." extends "Posted Transfer Shipment"
{
    layout
    {
        addlast(FactBoxes)
        {
            part(EDocStatusFactBox; "E-Doc. Status FactBox")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'E-Document';
                ShowFilter = false;
            }
            part(EDocMessages; "E-Document Messages FactBox")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'E-Document Messages';
                ShowFilter = false;
            }
        }
    }
    actions
    {
        addafter("&Shipment")
        {
            group("E-Document")
            {
                Caption = 'E-Document';

                action(OpenEDocument)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Open';
                    Image = Open;
                    ToolTip = 'Opens electronic document card.';
                    Enabled = EDocumentExists;

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
                    Caption = 'Create';
                    Image = CreateDocument;
                    ToolTip = 'Creates an E-Document from the posted document and sends it via service.';
                    Enabled = not EDocumentExists;

                    trigger OnAction()
                    var
                        EDocumentProcessing: Codeunit "E-Document Processing";
                    begin
                        if EDocumentProcessing.CreateEDocumentFromPostedDocumentPage(Rec, Enum::"E-Document Type"::"Transfer Shipment") then
                            Message(EDocumentCreatedMsg)
                        else
                            Message(EDocumentNotCreatedMsg);
                    end;
                }
            }
        }
    }

    var
        EDocumentExists: Boolean;
        EDocumentCreatedMsg: Label 'The e-document has been created.';
        EDocumentNotCreatedMsg: Label 'The e-document could not be created.';

    trigger OnAfterGetRecord()
    var
        EDocument: Record "E-Document";
    begin
        EDocument.SetRange("Document Record ID", Rec.RecordId());
        EDocumentExists := EDocument.FindLast();
        if EDocumentExists then
            CurrPage.EDocMessages.Page.SetEDocumentFilter(EDocument."Entry No")
        else
            CurrPage.EDocMessages.Page.SetEDocumentFilter(-1);
        CurrPage.EDocStatusFactBox.Page.SetDocumentRecordId(Rec.RecordId());
    end;

}