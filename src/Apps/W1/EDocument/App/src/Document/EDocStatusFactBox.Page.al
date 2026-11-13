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
    SourceTableView = sorting("Document Record ID", "Entry No") order(descending);
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
                field(ServiceStatus; ServiceStatusText)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Service Status';
                    ToolTip = 'Specifies the status of the e-document service that processed this e-document.';
                }
                field(LastActivityAt; LastActivityAt)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Last Activity';
                    ToolTip = 'Specifies the date and time of the most recent log activity for this e-document.';
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

    var
        LastActivityAt: DateTime;
        ServiceStatusText: Text;

    trigger OnAfterGetRecord()
    begin
        ServiceStatusText := this.GetServiceStatus();
        LastActivityAt := this.GetLastActivityAt();
    end;

    local procedure GetServiceStatus(): Text
    var
        EDocumentServiceStatus: Record "E-Document Service Status";
        ServiceStatusTextBuilder: TextBuilder;
    begin
        EDocumentServiceStatus.SetRange("E-Document Entry No", Rec."Entry No");
        EDocumentServiceStatus.SetLoadFields(Status);
        if EDocumentServiceStatus.FindSet() then
            repeat
                if ServiceStatusTextBuilder.Length() > 0 then
                    ServiceStatusTextBuilder.Append(', ');
                ServiceStatusTextBuilder.Append(Format(EDocumentServiceStatus.Status));
            until EDocumentServiceStatus.Next() = 0;
        exit(ServiceStatusTextBuilder.ToText());
    end;

    local procedure GetLastActivityAt(): DateTime
    var
        EDocumentLog: Record "E-Document Log";
    begin
        EDocumentLog.SetRange("E-Doc. Entry No", Rec."Entry No");
        EDocumentLog.SetCurrentKey("Entry No.");
        EDocumentLog.SetAscending("Entry No.", false);
        EDocumentLog.SetLoadFields(SystemCreatedAt);
        if EDocumentLog.FindFirst() then
            exit(EDocumentLog.SystemCreatedAt);
    end;

    internal procedure SetDocumentRecordId(RecId: RecordId)
    begin
        Rec.SetRange("Document Record ID", RecId);
        CurrPage.Update(false);
    end;

    internal procedure SetDocumentIdentity(DocumentNo: Code[20]; PostingDate: Date; PartnerNo: Code[20]; EDocumentDirection: Enum "E-Document Direction"; DocumentType: Enum "E-Document Type")
    var
        EDocument: Record "E-Document";
    begin
        Rec.SetCurrentKey("Document No.", "Posting Date", "Bill-to/Pay-to No.", "Document Type", "Entry No");
        EDocument.SetDocumentIdentityFilters(Rec, DocumentNo, PostingDate, PartnerNo, EDocumentDirection, DocumentType);
        CurrPage.Update(false);
    end;
}
