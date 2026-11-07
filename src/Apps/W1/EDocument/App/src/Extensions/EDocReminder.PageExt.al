// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Message;

pageextension 6141 "E-Doc. Reminder" extends Reminder
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
        addafter("&Issuing")
        {
            group("E-Document")
            {
                action("OpenEDocument")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Open';
                    Image = Open;
                    ToolTip = 'Opens the related E-Document card.';
                    Enabled = EDocumentExists;

                    trigger OnAction()
                    var
                        EDocument: Record "E-Document";
                    begin
                        EDocument.OpenEDocument(Rec.RecordId());
                    end;
                }
                action("PreviewEDocumentMapping")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Preview E-Document Mapping';
                    Image = ViewDetails;
                    ToolTip = 'Preview E-Document Mapping';
                    trigger OnAction()
                    var
                        ReminderLine: Record "Reminder Line";
                        EDocMapping: Codeunit "E-Doc. Mapping";
                    begin
                        ReminderLine.SetRange("Document No.", Rec."No.");
                        EDocMapping.PreviewMapping(Rec, ReminderLine, ReminderLine.FieldNo("Line No."));
                    end;
                }
            }
        }
    }

    var
        EDocumentExists: Boolean;

    trigger OnAfterGetCurrRecord()
    var
        EDocument: Record "E-Document";
    begin
        EDocumentExists := EDocument.HasEDocument(Rec.RecordId());
        CurrPage.EDocMessages.Page.SetSourceRecordId(Rec.RecordId());
        CurrPage.EDocStatusFactBox.Page.SetDocumentRecordId(Rec.RecordId());
    end;
}
