// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Foundation.Attachment;
using Microsoft.Integration.Graph;
using System.IO;
using System.Reflection;
using System.Utilities;

page 6926 "Posted Exp. Rep. Line Att. API"
{
    APIGroup = 'expense';
    APIPublisher = 'microsoft';
    APIVersion = 'beta';
    EntityCaption = 'Posted Expense Report Line Attachment';
    EntitySetCaption = 'Posted Expense Report Line Attachments';
    EntityName = 'postedExpenseReportLineAttachment';
    EntitySetName = 'postedExpenseReportLineAttachments';
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    DataAccessIntent = ReadOnly;
    PageType = API;
    ODataKeyFields = Id;
    SourceTable = "Attachment Entity Buffer";
    SourceTableTemporary = true;
    Extensible = false;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(id; Rec.Id)
                {
                    Caption = 'Id';
                    Editable = false;
                }
                field(postedExpenseReportLineId; Rec."Document Id")
                {
                    Caption = 'Posted Expense Report Line Id';
                    ShowMandatory = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(Rec.FieldNo("Document Id"));
                    end;
                }
                field(fileName; Rec."File Name")
                {
                    Caption = 'File Name';
                    ShowMandatory = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(Rec.FieldNo("File Name"));
                    end;
                }
                field(byteSize; Rec."Byte Size")
                {
                    Caption = 'Byte Size';
                    Editable = false;
                }
                field(documentContent; Rec.Content)
                {
                    Caption = 'Document Content';

                    trigger OnValidate()
                    begin
                        if AttachmentsLoaded then begin
                            Rec.Modify();
                            ContentLoaded := true;
                        end;
                    end;
                }
                field(lastModifiedDateTime; Rec."Created Date-Time")
                {
                    Caption = 'Last Modified Date';
                    Editable = false;
                }
            }
        }
    }

    var
        TempFieldBuffer: Record "Field Buffer" temporary;
        ExpAttachmentBufferHandler: Codeunit "Exp. Attach. Buffer Handler";
        AttachmentsLoaded: Boolean;
        AttachmentsFound: Boolean;
        ContentLoaded: Boolean;
        CannotModifyKeyFieldErr: Label 'You cannot change the value of the key field %1.', Comment = '%1 = Field name';
        PostedExpenseReportLineIdRequiredErr: Label 'Posted Expense Report Line ID is required.';
        FileNameRequiredErr: Label 'File Name is required.';
        DocumentAttachmentNotFoundErr: Label 'Document attachment with ID %1 not found.', Comment = '%1 = Attachment ID';

    trigger OnInit()
    var
        ExpenseAgentAPIValidation: Codeunit "Expense Agent API Validation";
    begin
        ExpenseAgentAPIValidation.VerifyAgentAccess();
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        ExpAttachmentBufferHandler.PropagateDeleteAttachment(Rec, Database::"Posted Expense Report Line");
        exit(false);
    end;

    trigger OnFindRecord(Which: Text): Boolean
    var
        PostedExpenseReportLineIdFilter: Text;
        AttachmentIdFilter: Text;
        FilterView: Text;
    begin
        if not AttachmentsLoaded then begin
            FilterView := Rec.GetView();
            PostedExpenseReportLineIdFilter := Rec.GetFilter("Document Id");
            AttachmentIdFilter := Rec.GetFilter(Id);

            ExpAttachmentBufferHandler.LoadAttachments(Rec, Database::"Posted Expense Report Line", PostedExpenseReportLineIdFilter, AttachmentIdFilter);

            Rec.SetView(FilterView);
            AttachmentsFound := Rec.FindFirst();
            if not AttachmentsFound then
                exit(false);
            AttachmentsLoaded := true;
        end;
        exit(AttachmentsFound);
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        FileManagement: Codeunit "File Management";
        FilterView: Text;
        PostedExpenseReportLineIdFilter: Text;
    begin
        if IsNullGuid(Rec."Document Id") then begin
            FilterView := Rec.GetView();
            PostedExpenseReportLineIdFilter := Rec.GetFilter("Document Id");
            if PostedExpenseReportLineIdFilter <> '' then
                Rec.Validate("Document Id", PostedExpenseReportLineIdFilter);
            Rec.SetView(FilterView);
        end;

        // Validate mandatory fields for POST
        if IsNullGuid(Rec."Document Id") then
            Error(PostedExpenseReportLineIdRequiredErr);

        if Rec."File Name" = '' then
            Error(FileNameRequiredErr);

        if not FileManagement.IsValidFileName(Rec."File Name") then
            Rec.Validate("File Name", 'filename.txt');

        Rec.Validate("Created Date-Time", RoundDateTime(CurrentDateTime(), 1000));
        RegisterFieldSet(Rec.FieldNo("Created Date-Time"));

        // Only update byte size if content exists (for streaming approach, content comes later via PATCH)
        if Rec.Content.HasValue then
            ByteSizeFromContent();

        ExpAttachmentBufferHandler.PropagateInsertAttachment(Rec, TempFieldBuffer, Database::"Posted Expense Report Line");
        exit(false);
    end;

    trigger OnModifyRecord(): Boolean
    var
        DocumentAttachment: Record "Document Attachment";
        ContentInStream: InStream;
    begin
        if (xRec.Id <> Rec.Id) or (xRec."Document Id" <> Rec."Document Id") then
            Error(CannotModifyKeyFieldErr, 'id or postedExpenseReportLineId');

        if ContentLoaded then begin
            // Content streaming: directly import the binary stream to Document Attachment
            if not DocumentAttachment.GetBySystemId(Rec.Id) then
                Error(DocumentAttachmentNotFoundErr, Rec.Id);

            Rec.CalcFields(Content);
            Rec.Content.CreateInStream(ContentInStream);
            DocumentAttachment.ImportAttachment(ContentInStream, Rec."File Name");

            // Reload the buffer with updated attachment
            ExpAttachmentBufferHandler.ReloadSingleAttachment(Rec, DocumentAttachment, Database::"Posted Expense Report Line");
        end else begin
            ExpAttachmentBufferHandler.PropagateModifyAttachment(Rec, TempFieldBuffer, Database::"Posted Expense Report Line");

            if Rec.Content.HasValue then
                ByteSizeFromContent();
        end;

        exit(false);
    end;

    local procedure RegisterFieldSet(FieldNo: Integer)
    begin
        TempFieldBuffer.Reset();
        TempFieldBuffer.SetRange("Table ID", Database::"Attachment Entity Buffer");
        TempFieldBuffer.SetRange("Field ID", FieldNo);
        if not TempFieldBuffer.IsEmpty() then
            exit;

        TempFieldBuffer.Reset();
        if TempFieldBuffer.FindLast() then
            TempFieldBuffer.Order += 1
        else
            TempFieldBuffer.Order := 1;

        TempFieldBuffer.Init();
        TempFieldBuffer."Table ID" := Database::"Attachment Entity Buffer";
        TempFieldBuffer."Field ID" := FieldNo;
        TempFieldBuffer.Insert();
    end;

    local procedure ByteSizeFromContent()
    var
        TempBlob: Codeunit "Temp Blob";
    begin
        TempBlob.FromRecord(Rec, Rec.FieldNo(Content));
        Rec."Byte Size" := TempBlob.Length();
    end;
}