// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.ForNAV;

using Microsoft.EServices.EDocument;
using System.Threading;

page 6417 "ForNAV Incoming E-Docs Api"
{
    PageType = API;
    APIPublisher = 'microsoft';
    EntityName = 'eDocConnectorForNav';
    EntitySetName = 'eDocConnectorsForNav';
    APIGroup = 'peppol';
    APIVersion = 'v1.0';
    SourceTable = "ForNAV Incoming E-Document";
    DelayedInsert = true;
    Caption = 'ForNavPeppolE-Doc';
    InsertAllowed = true;
    DeleteAllowed = false;
    ModifyAllowed = false;
    Extensible = false;
    Permissions = TableData "Job Queue Entry" = rimd,
                  TableData "Job Queue Log Entry" = RIMD,
                  TableData "Job Queue Category" = rimd;
    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(iD; Rec.ID)
                {
                    ApplicationArea = All;
                }
                field(docNo; Rec.DocNo)
                {
                    ApplicationArea = All;

                }
                field(docType; Rec.DocType)
                {
                    ApplicationArea = All;

                }
                field(docCode; Rec.DocCode)
                {
                    ApplicationArea = All;
                }
                field(doc; Document)
                {
                    ApplicationArea = All;
                }
                field(message; Message)
                {
                    ApplicationArea = All;
                }
                field(status; Rec.Status)
                {
                    ApplicationArea = All;
                }
                field(eDocumentType; Rec.EDocumentType)
                {
                    ApplicationArea = All;
                }
                field(schemeID; Rec.SchemeID)
                {
                    ApplicationArea = All;
                }
                field(endpointID; Rec.EndpointID)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    var
        Document, Message : BigText;

    [TryFunction]
    local procedure CreateJob(JobQueueCodeunit: Integer; RecId: RecordId)
    var
        Setup: Record "ForNAV Peppol Setup";
        QueueEntry: Record "Job Queue Entry";
    begin
        QueueEntry.ID := CreateGuid();
        QueueEntry."Record ID to Process" := RecId;
        QueueEntry."Object ID to Run" := JobQueueCodeunit;
        QueueEntry."Object Type to Run" := QueueEntry."Object Type to Run"::Codeunit;
        QueueEntry."Job Queue Category Code" := Setup.GetForNAVCode();
        QueueEntry.Description := 'Used by ForNAV to process incoming e-documents';
        QueueEntry.Status := QueueEntry.Status::"On Hold";
        QueueEntry.Insert();
    end;

    local procedure SetErrorMessage(var NewMessage: BigText)
    var
        Error: ErrorInfo;
    begin
        Clear(NewMessage);
        NewMessage.AddText('Error\n');
        NewMessage.AddText(GetLastErrorText() + '\n');
        NewMessage.AddText(GetLastErrorCallStack() + '\n');
        foreach Error in GetCollectedErrors() do
            NewMessage.AddText(Error.Message + '\n');
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        EDocumentService: Record "E-Document Service";
        Setup: Record "ForNAV Peppol Setup";
        BlankRecordId: RecordId;
        DocumentOutStream, MessageOutStream : OutStream;
    begin
        case Rec.DocType of
            Rec.DocType::Evidence:
                if not CreateJob(Codeunit::"E-Document Get Response", BlankRecordId) then
                    SetErrorMessage(Message);
            Rec.DocType::ApplicationResponse:
                if not CreateJob(Codeunit::"ForNAV App. Resp. Handler", Rec.RecordId()) then
                    SetErrorMessage(Message);
            Rec.DocType::Invoice, Rec.DocType::CreditNote:
                begin
                    if not Setup.GetEDocumentService(EDocumentService) then
                        exit(false);

                    if not CreateJob(6147, EDocumentService.RecordId()) then // Codeunit 6147 "E-Document Import Job"
                        SetErrorMessage(Message);
                end;
        end;

        Rec.Doc.CreateOutStream(DocumentOutStream, TextEncoding::UTF8);
        Document.Write(DocumentOutStream);
        Rec.Message.CreateOutStream(MessageOutStream, TextEncoding::UTF8);
        Message.Write(MessageOutStream);
        exit(true);
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        exit(false);
    end;
}