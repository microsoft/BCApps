// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

page 6187 "E-Doc. Status FactBox"
{
    PageType = ListPart;
    ApplicationArea = Basic, Suite;
    UsageCategory = None;
    Caption = 'E-Document';
    SourceTable = "E-Document";
    SourceTableView = sorting("Entry No") order(descending);
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(EDocuments)
            {
                field(Status; Rec.Status)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Status';
                    ToolTip = 'Specifies the overall status of the e-document.';
                }
                field(Direction; Rec.Direction)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Direction';
                    ToolTip = 'Specifies whether the e-document is outgoing or incoming.';
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Type';
                    ToolTip = 'Specifies the type of the e-document.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Document No.';
                    ToolTip = 'Specifies the document number of the e-document.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(OpenEDocument)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Open E-Document';
                ToolTip = 'Opens the E-Document card for the selected entry.';
                Image = Open;
                Scope = Repeater;

                trigger OnAction()
                begin
                    Page.Run(Page::"E-Document", Rec);
                end;
            }
            action(OpenLogs)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Document Logs';
                ToolTip = 'Opens the E-Document log entries for the selected e-document.';
                Image = Log;
                Scope = Repeater;

                trigger OnAction()
                var
                    EDocumentLog: Record "E-Document Log";
                begin
                    EDocumentLog.SetRange("E-Doc. Entry No", Rec."Entry No");
                    Page.Run(Page::"E-Document Logs", EDocumentLog);
                end;
            }
            action(OpenIntegrationLogs)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Integration Logs';
                ToolTip = 'Opens the integration communication log entries for the selected e-document.';
                Image = TransmitElectronicDoc;
                Scope = Repeater;

                trigger OnAction()
                var
                    EDocumentIntegrationLog: Record "E-Document Integration Log";
                begin
                    EDocumentIntegrationLog.SetRange("E-Doc. Entry No", Rec."Entry No");
                    Page.Run(Page::"E-Document Integration Logs", EDocumentIntegrationLog);
                end;
            }
        }
    }

    procedure SetDocumentRecordId(RecId: RecordId)
    begin
        Rec.SetRange("Document Record ID", RecId);
        CurrPage.Update(false);
    end;
}
