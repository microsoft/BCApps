// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

using Microsoft.eServices.EDocument.Processing.Message;
using Microsoft.eServices.EDocument.Service;
using Microsoft.Foundation.Attachment;

page 6122 "E-Documents"
{
    ApplicationArea = Basic, Suite;
    SourceTable = "E-Document";
    PageType = List;
    UsageCategory = Lists;
    AdditionalSearchTerms = 'Edoc,Electronic Document,EDocuments,E Documents,E invoices,Einvoices,Electronic';
    RefreshOnActivate = true;
    Editable = false;
    DeleteAllowed = true;
    InsertAllowed = false;
    SourceTableView = sorting("Entry No") order(descending);

    layout
    {
        area(Content)
        {
            repeater(DocumentList)
            {
                ShowCaption = false;
                field("Entry No"; Rec."Entry No")
                {
                    ToolTip = 'Specifies the entry number.';

                    trigger OnDrillDown()
                    var
                        EDocumentHelper: Codeunit "E-Document Helper";
                    begin
                        EDocumentHelper.OpenDraftPage(Rec);
                    end;
                }
                field("Bill-to/Pay-to No."; Rec."Bill-to/Pay-to No.")
                {
                    ToolTip = 'Specifies the customer/vendor of the electronic document.';
                }
                field("Bill-to/Pay-to Name"; Rec."Bill-to/Pay-to Name")
                {
                    ToolTip = 'Specifies the customer/vendor name of the electronic document.';
                }
                field("Document Type"; Rec."Document Type")
                {
                    ToolTip = 'Specifies the document type of the electronic document.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ToolTip = 'Specifies the document number of the electronic document.';
                }
                field("Document Date"; Rec."Document Date")
                {
                    ToolTip = 'Specifies the document date.';
                }
                field(Status; Rec.Status)
                {
                    ToolTip = 'Specifies the status of the electronic document.';
                }
            }
        }
        area(FactBoxes)
        {
            part("Attached Documents List"; "Doc. Attachment List Factbox")
            {
                ApplicationArea = All;
                Caption = 'Documents';
                UpdatePropagation = Both;
                SubPageLink = "E-Document Entry No." = field("Entry No"),
                              "E-Document Attachment" = const(true);
            }
            part(InboundEDocFactbox; "Inbound E-Doc. Factbox")
            {
                Caption = 'Details';
                SubPageLink = "E-Document Entry No" = field("Entry No");
                ShowFilter = false;
                Enabled = Rec.Direction = Rec.Direction::Incoming;
                Visible = Rec.Direction = Rec.Direction::Incoming;
            }
            part("Outbound E-Doc. Factbox"; "Outbound E-Doc. Factbox")
            {
                Caption = 'Details';
                SubPageLink = "E-Document Entry No" = field("Entry No");
                ShowFilter = false;
                Enabled = Rec.Direction = Rec.Direction::Outgoing;
                Visible = Rec.Direction = Rec.Direction::Outgoing;
            }
            part(EDocMessages; "E-Document Messages Part")
            {
                Caption = 'Messages';
                SubPageLink = "E-Document Entry No." = field("Entry No");
                ShowFilter = false;
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(ImportManually)
            {
                Caption = 'New from file';
                ToolTip = 'Create an electronic document by manually uploading a file.';
                Image = Import;

                trigger OnAction()
                begin
                    NewFromFile();
                end;
            }
            action(EDocumentServices)
            {
                RunObject = Page "E-Document Services";
                Caption = 'E-Document Services';
                ToolTip = 'Opens E-Document Services page.';
                Image = Server;
            }
            action(EDocumentLogs)
            {
                RunObject = Page "E-Document Logs";
                Caption = 'E-Document Logs';
                ToolTip = 'Opens E-Document Logs page.';
                Image = Log;
            }
            action(ViewFile)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'View file';
                ToolTip = 'View the source file.';
                Image = ViewDetails;

                trigger OnAction()
                begin
                    Rec.ViewSourceFile();
                end;
            }
        }
        area(Navigation)
        {
            action(InboundEDocuments)
            {
                Caption = 'Inbound';
                ToolTip = 'View inbound electronic documents.';
                RunObject = Page "Inbound E-Documents";
                RunPageMode = View;
                Image = InwardEntry;
            }
            action(OutboundEDocuments)
            {
                Caption = 'Outbound';
                ToolTip = 'View outbound electronic documents.';
                RunObject = Page "Outbound E-Documents";
                Image = OutboundEntry;
            }
        }
        area(Promoted)
        {
            actionref(Promoted_ImportManually; ImportManually) { }
            actionref(Promoted_ViewFile; ViewFile) { }
            actionref(Promoted_InboundEDocuments; InboundEDocuments) { }
            actionref(Promoted_OutboundEDocuments; OutboundEDocuments) { }
            actionref(Promoted_EDocumentServices; EDocumentServices) { }
        }
    }

    local procedure NewFromFile()
    var
        EDocument: Record "E-Document";
        EDocImport: Codeunit "E-Doc. Import";
    begin
        EDocImport.UploadDocument(EDocument);
        if EDocument."Entry No" = 0 then
            exit;
        if EDocument.Direction = EDocument.Direction::Outgoing then begin
            // File was classified as a message (e.g. OrderResponse) linked to this outbound document.
            Page.Run(Page::"E-Document", EDocument);
            exit;
        end;
        EDocImport.ProcessIncomingEDocument(EDocument, EDocument.GetEDocumentService().GetDefaultImportParameters());
        Page.Run(Page::"E-Document", EDocument);
    end;
}
