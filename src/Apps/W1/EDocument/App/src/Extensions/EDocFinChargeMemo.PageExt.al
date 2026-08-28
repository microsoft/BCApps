// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.FinanceCharge;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Message;

pageextension 6140 "E-Doc. Fin. Charge Memo" extends "Finance Charge Memo"
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
                action("PreviewEDocumentMapping")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Preview E-Document Mapping';
                    Image = ViewDetails;
                    ToolTip = 'Preview E-Document Mapping';
                    trigger OnAction()
                    var
                        FinChargeMemoLine: Record "Finance Charge Memo Line";
                        EDocMapping: Codeunit "E-Doc. Mapping";
                    begin
                        FinChargeMemoLine.SetRange("Document No.", Rec."No.");
                        EDocMapping.PreviewMapping(Rec, FinChargeMemoLine, FinChargeMemoLine.FieldNo("Line No."));
                    end;
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        EDocument: Record "E-Document";
    begin
        EDocument.SetRange("Document Record ID", Rec.RecordId());
        if EDocument.FindLast() then
            CurrPage.EDocMessages.Page.SetEDocumentFilter(EDocument."Entry No")
        else
            CurrPage.EDocMessages.Page.SetEDocumentFilter(-1);
        CurrPage.EDocStatusFactBox.Page.SetDocumentRecordId(Rec.RecordId());
    end;
}
