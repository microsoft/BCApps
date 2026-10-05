// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.History;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Message;

pageextension 6147 "E-Doc. Posted Purch. Cr. Memo" extends "Posted Purchase Credit Memo"
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
        addafter("&Cr. Memo")
        {
            group("E-Document")
            {
                action("OpenEDocument")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Open';
                    Image = Open;
                    ToolTip = 'Opens the E-Document card page.';
                    Enabled = EDocumentExists;

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
