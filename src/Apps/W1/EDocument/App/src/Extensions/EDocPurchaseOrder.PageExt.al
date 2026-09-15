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
                        EDocumentPage: Page "E-Document";
                        NoEDocumentForRecordMsg: Label 'No electronic document is linked to this record.';
                    begin
                        if EDocument.HasEDocument(Rec.RecordId()) then begin
                            EDocument.OpenEDocument(Rec.RecordId());
                            exit;
                        end;
                        if (not IsNullGuid(Rec."E-Document Link")) and EDocument.GetBySystemId(Rec."E-Document Link") then begin
                            EDocumentPage.SetRecord(EDocument);
                            EDocumentPage.RunModal();
                            exit;
                        end;
                        Message(NoEDocumentForRecordMsg);
                    end;
                }
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
        EDocumentExists: Boolean;

    trigger OnAfterGetCurrRecord()
    var
        EDocument: Record "E-Document";
        EDocumentServiceStatus: Record "E-Document Service Status";
        LinkedEDocumentFound: Boolean;
    begin
        ShowMapToEDocument := false;
        LinkedEDocumentFound := (not IsNullGuid(Rec."E-Document Link")) and EDocument.GetBySystemId(Rec."E-Document Link");
        EDocumentExists := EDocument.HasEDocument(Rec.RecordId()) or LinkedEDocumentFound;
        if LinkedEDocumentFound then begin
            EDocumentServiceStatus.SetRange("E-Document Entry No", EDocument."Entry No");
            if EDocumentServiceStatus.FindFirst() then
                ShowMapToEDocument := EDocumentServiceStatus.Status = Enum::"E-Document Service Status"::"Order Linked";
        end;

        CurrPage.EDocMessages.Page.SetSourceRecordId(Rec.RecordId());
        CurrPage.EDocStatusFactBox.Page.SetDocumentRecordId(Rec.RecordId());
    end;
}
