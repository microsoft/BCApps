// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.OrderMatch;
using Microsoft.eServices.EDocument.Processing.Message;

pageextension 6132 "E-Doc. Purchase Order" extends "Purchase Order"
{
    layout
    {
        addlast(General)
        {
#pragma warning disable AA0218
            field(PurchaseOrderLinkedToEdoc; (not IsNullGuid(Rec."E-Document Link")))
#pragma warning restore AA0218
            {
                ApplicationArea = All;
                Caption = 'Linked with E-Document';
                Editable = false;
                Visible = true;
            }
        }
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
        addafter("P&osting")
        {
            group("E-Document")
            {
                action(MatchToOrder)
                {
                    Caption = 'Map E-Document Lines';
                    ToolTip = 'Map received E-Document to the Purchase Order';
                    ApplicationArea = All;
                    Image = Reconcile;
                    Visible = ShowMapToEDocument;

                    trigger OnAction()
                    var
                        EDocument: Record "E-Document";
                        EDocOrderMatch: Codeunit "E-Doc. Line Matching";
                    begin
                        EDocument.GetBySystemId(Rec."E-Document Link");
                        EDocOrderMatch.RunMatching(EDocument);
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
                        PurchaseLine: Record "Purchase Line";
                        EDocMapping: Codeunit "E-Doc. Mapping";
                    begin
                        PurchaseLine.SetRange("Document No.", Rec."No.");
                        EDocMapping.PreviewMapping(Rec, PurchaseLine, PurchaseLine.FieldNo("Line No."));
                    end;
                }
            }
        }
        addlast(Prompting)
        {
#if not CLEAN29
            action(MatchToOrderCopilotEnabled)
            {
                Caption = 'Map E-Document Lines';
                ToolTip = 'Map received E-Document to the Purchase Order';
                ApplicationArea = All;
                Image = SparkleFilled;
                Visible = false;
                ObsoleteState = Pending;
                ObsoleteReason = 'The E-Document Purchase Order Matching Copilot has been deprecated. AI-assisted line matching is now handled at import time in the E-Document Purchase Draft experience by codeunit "E-Doc. AI Tool Processor".';
                ObsoleteTag = '29.0';

                trigger OnAction()
                var
                    EDocument: Record "E-Document";
                    EDocOrderMatch: Codeunit "E-Doc. Line Matching";
                begin
                    EDocument.GetBySystemId(Rec."E-Document Link");
                    EDocOrderMatch.RunMatching(EDocument);
                end;
            }
#endif
        }
        addlast(Category_Process)
        {
#if not CLEAN29
            actionref(MapEDocumentCE_Promoted; MatchToOrderCopilotEnabled)
            {
                Visible = false;
                ObsoleteState = Pending;
                ObsoleteReason = 'The E-Document Purchase Order Matching Copilot has been deprecated. AI-assisted line matching is now handled at import time in the E-Document Purchase Draft experience by codeunit "E-Doc. AI Tool Processor".';
                ObsoleteTag = '29.0';
            }
#endif
            actionref(MapEDocument_Promoted; MatchToOrder)
            {
            }
        }
    }


    var
        ShowMapToEDocument: Boolean;

    trigger OnAfterGetCurrRecord()
    var
        EDocument: Record "E-Document";
        OutboundEDocument: Record "E-Document";
        EDocumentServiceStatus: Record "E-Document Service Status";
    begin
        ShowMapToEDocument := false;
        if not IsNullGuid(Rec."E-Document Link") then begin
            EDocument.GetBySystemId(Rec."E-Document Link");
            EDocumentServiceStatus.SetRange("E-Document Entry No", EDocument."Entry No");
            EDocumentServiceStatus.FindFirst();
            ShowMapToEDocument := EDocumentServiceStatus.Status = Enum::"E-Document Service Status"::"Order Linked";
        end;

        OutboundEDocument.SetRange("Document Record ID", Rec.RecordId());
        OutboundEDocument.SetRange(Direction, OutboundEDocument.Direction::Outgoing);
        if OutboundEDocument.FindLast() then
            CurrPage.EDocMessages.Page.SetEDocumentFilter(OutboundEDocument."Entry No")
        else
            CurrPage.EDocMessages.Page.SetEDocumentFilter(-1);
        CurrPage.EDocStatusFactBox.Page.SetDocumentRecordId(Rec.RecordId());
    end;

}
