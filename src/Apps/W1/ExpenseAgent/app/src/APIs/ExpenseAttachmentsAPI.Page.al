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

page 6950 "Expense Attachments API"
{
    APIGroup = 'expense';
    APIPublisher = 'microsoft';
    APIVersion = 'beta';
    EntityCaption = 'Expense Attachment';
    EntitySetCaption = 'Expense Attachments';
    DelayedInsert = true;
    EntityName = 'expenseAttachment';
    EntitySetName = 'expenseAttachments';
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
                field(expenseId; Rec."Document Id")
                {
                    Caption = 'Expense Id';
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
                field(contentHash; ContentHash)
                {
                    Caption = 'Content Hash';
                    Editable = false;
                }
            }
        }
    }

    var
        TempFieldBuffer: Record "Field Buffer" temporary;
        ExpAttachBufferHandler: Codeunit "Exp. Attach. Buffer Handler";
        AttachmentsLoaded: Boolean;
        AttachmentsFound: Boolean;
        ContentLoaded: Boolean;
        ContentHash: Text[64];

    trigger OnInit()
    var
        ExpenseAgentAPIValidation: Codeunit "Expense Agent API Validation";
    begin
        ExpenseAgentAPIValidation.VerifyAgentAccess();
    end;

    trigger OnAfterGetRecord()
    var
        DocumentAttachment: Record "Document Attachment";
    begin
        if DocumentAttachment.GetBySystemId(Rec.Id) then
            ContentHash := DocumentAttachment."Content Hash"
        else
            ContentHash := '';
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        ExpAttachBufferHandler.PropagateDeleteAttachment(Rec, Database::"Expense");
        exit(false);
    end;

    trigger OnFindRecord(Which: Text): Boolean
    var
        ExpenseIdFilter: Text;
        AttachmentIdFilter: Text;
        FilterView: Text;
    begin
        if not AttachmentsLoaded then begin
            FilterView := Rec.GetView();
            ExpenseIdFilter := Rec.GetFilter("Document Id");
            AttachmentIdFilter := Rec.GetFilter(Id);

            ExpAttachBufferHandler.LoadAttachments(Rec, Database::Expense, ExpenseIdFilter, AttachmentIdFilter);

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
        ExpenseIdFilter: Text;
    begin
        if IsNullGuid(Rec."Document Id") then begin
            FilterView := Rec.GetView();
            ExpenseIdFilter := Rec.GetFilter("Document Id");
            if ExpenseIdFilter <> '' then
                Rec.Validate("Document Id", ExpenseIdFilter);
            Rec.SetView(FilterView);
        end;

        // Validate mandatory fields for POST
        if IsNullGuid(Rec."Document Id") then
            Error(ExpenseIdRequiredErr);

        if Rec."File Name" = '' then
            Error(FileNameRequiredErr);

        if not FileManagement.IsValidFileName(Rec."File Name") then
            Rec.Validate("File Name", 'filename.txt');

        Rec.Validate("Created Date-Time", RoundDateTime(CurrentDateTime(), 1000));
        RegisterFieldSet(Rec.FieldNo("Created Date-Time"));

        // Only update byte size if content exists (for streaming approach, content comes later via PATCH)
        if Rec.Content.HasValue then
            ByteSizeFromContent();

        ExpAttachBufferHandler.PropagateInsertAttachment(Rec, TempFieldBuffer, Database::Expense);
        exit(false);
    end;

    trigger OnModifyRecord(): Boolean
    var
        DocumentAttachment: Record "Document Attachment";
        ContentInStream: InStream;
    begin
        if (xRec.Id <> Rec.Id) or (xRec."Document Id" <> Rec."Document Id") then
            Error(CannotModifyKeyFieldErr, 'id or expenseId');

        if ContentLoaded then begin
            // Content streaming: directly import the binary stream to Document Attachment
            if not DocumentAttachment.GetBySystemId(Rec.Id) then
                Error(DocumentAttachmentNotFoundErr, Rec.Id);

            Rec.CalcFields(Content);
            Rec.Content.CreateInStream(ContentInStream);
            DocumentAttachment.ImportAttachment(ContentInStream, Rec."File Name");

            // Reload the buffer with updated attachment
            ExpAttachBufferHandler.ReloadSingleAttachment(Rec, DocumentAttachment, Database::Expense);
        end else begin
            ExpAttachBufferHandler.PropagateModifyAttachment(Rec, TempFieldBuffer, Database::Expense);

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

    var
        CannotModifyKeyFieldErr: Label 'You cannot change the value of the key field %1.', Comment = '%1 = Field name';
        DocumentAttachmentNotFoundErr: Label 'Document attachment with ID %1 not found.', Comment = '%1 = Attachment ID';
        ExpenseIdRequiredErr: Label 'Expense ID is required.';
        FileNameRequiredErr: Label 'File Name is required.';
}
