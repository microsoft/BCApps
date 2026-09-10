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

codeunit 6952 "Exp. Attach. Buffer Handler"
{
    var
        DocumentAttachmentNotFoundErr: Label 'Document attachment with ID %1 not found.', Comment = '%1 = Attachment ID';
        ExpenseNotFoundErr: Label 'Expense with ID %1 not found.', Comment = '%1 = Expense ID';
        ExpenseReportLineNotFoundErr: Label 'Expense Report Line with ID %1 not found.', Comment = '%1 = Expense Report Line ID';
        PostedExpenseReportLineNotFoundErr: Label 'Posted Expense Report Line with ID %1 not found.', Comment = '%1 = Posted Expense Report Line ID';
        DocumentAttachmentCannotDeletedForExpenseFromReportLineErr: Label 'You cannot delete attachment from Expense Report Line when it is attached to Expense.';

    procedure LoadAttachments(var AttachmentEntityBuffer: Record "Attachment Entity Buffer"; TableID: Integer; SystemIdFilter: Text; AttachmentIdFilter: Text)
    var
        DocumentAttachment: Record "Document Attachment";
        Expense: Record Expense;
        ExpenseReportLine: Record "Expense Report Line";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        SystemId: Guid;
        LoadContent: Boolean;
    begin
        AttachmentEntityBuffer.Reset();
        AttachmentEntityBuffer.DeleteAll();

        // Only load content when fetching a specific attachment (for efficiency)
        LoadContent := (AttachmentIdFilter <> '');

        if SystemIdFilter <> '' then begin
            Evaluate(SystemId, SystemIdFilter);

            case TableID of
                Database::Expense:
                    begin
                        if not Expense.GetBySystemId(SystemId) then
                            Error(ExpenseNotFoundErr, SystemId);

                        DocumentAttachment.SetRange("Document Type", DocumentAttachment."Document Type"::Expense);
                        DocumentAttachment.SetRange("Table ID", TableID);
                        DocumentAttachment.SetRange("No.", Expense."No.");
                    end;
                Database::"Expense Report Line":
                    begin
                        if not ExpenseReportLine.GetBySystemId(SystemId) then
                            Error(ExpenseReportLineNotFoundErr, SystemId);

                        DocumentAttachment.SetRange("Document Type", DocumentAttachment."Document Type"::Expense);
                        DocumentAttachment.SetRange("Table ID", Database::"Expense Report Line");
                        DocumentAttachment.SetRange("No.", ExpenseReportLine."Document No.");
                        DocumentAttachment.SetRange("Line No.", ExpenseReportLine."Line No.");
                    end;
                Database::"Posted Expense Report Line":
                    begin
                        if not PostedExpenseReportLine.GetBySystemId(SystemId) then
                            Error(PostedExpenseReportLineNotFoundErr, SystemId);

                        DocumentAttachment.SetRange("Document Type", DocumentAttachment."Document Type"::Expense);
                        DocumentAttachment.SetRange("Table ID", Database::"Posted Expense Report Line");
                        DocumentAttachment.SetRange("No.", PostedExpenseReportLine."Document No.");
                        DocumentAttachment.SetRange("Line No.", PostedExpenseReportLine."Line No.");
                    end;
            end;
        end;

        if AttachmentIdFilter <> '' then
            DocumentAttachment.SetFilter(SystemId, AttachmentIdFilter);

        if DocumentAttachment.FindSet() then
            repeat
                TransferToAttachmentBuffer(DocumentAttachment, AttachmentEntityBuffer, LoadContent, TableID);
            until DocumentAttachment.Next() = 0;
    end;

    procedure PropagateInsertAttachment(var AttachmentEntityBuffer: Record "Attachment Entity Buffer"; var TempFieldBuffer: Record "Field Buffer" temporary; TableId: Integer)
    var
        DocumentAttachment: Record "Document Attachment";
        Expense: Record Expense;
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        FileManagement: Codeunit "File Management";
        ExpDocAttSubscribers: Codeunit "Expense Doc. Att. Subscribers";
    begin
        // Validate file name
        if not FileManagement.IsValidFileName(AttachmentEntityBuffer."File Name") then
            AttachmentEntityBuffer.Validate("File Name", 'filename.txt');

        // Create Document Attachment record
        DocumentAttachment.Init();
        DocumentAttachment."Attached Date" := AttachmentEntityBuffer."Created Date-Time";

        case TableId of
            Database::Expense:
                begin
                    if not Expense.GetBySystemId(AttachmentEntityBuffer."Document Id") then
                        Error(ExpenseNotFoundErr, AttachmentEntityBuffer."Document Id");

                    Expense.TestField(Status, Expense.Status::Open);

                    DocumentAttachment."Document Type" := DocumentAttachment."Document Type"::Expense;
                    DocumentAttachment."Table ID" := TableId;
                    DocumentAttachment."No." := Expense."No.";
                end;
            Database::"Expense Report Line":
                begin
                    if not ExpenseReportLine.GetBySystemId(AttachmentEntityBuffer."Document Id") then
                        Error(ExpenseReportLineNotFoundErr, AttachmentEntityBuffer."Document Id");

                    ExpenseReportHeader.Get(ExpenseReportLine."Document No.");
                    ExpenseReportHeader.TestField(Status, ExpenseReportHeader.Status::Open);

                    DocumentAttachment."Document Type" := DocumentAttachment."Document Type"::Expense;
                    DocumentAttachment."Table ID" := Database::"Expense Report Line";
                    DocumentAttachment."No." := ExpenseReportLine."Document No.";
                    DocumentAttachment."Line No." := ExpenseReportLine."Line No.";
                end;
            Database::"Posted Expense Report Line":
                begin
                    if not PostedExpenseReportLine.GetBySystemId(AttachmentEntityBuffer."Document Id") then
                        Error(PostedExpenseReportLineNotFoundErr, AttachmentEntityBuffer."Document Id");

                    DocumentAttachment."Document Type" := DocumentAttachment."Document Type"::Expense;
                    DocumentAttachment."Table ID" := Database::"Posted Expense Report Line";
                    DocumentAttachment."No." := PostedExpenseReportLine."Document No.";
                    DocumentAttachment."Line No." := PostedExpenseReportLine."Line No.";
                end;
        end;

        // Split filename into name and extension
        DocumentAttachment.Validate("File Extension", FileManagement.GetExtension(AttachmentEntityBuffer."File Name"));
        DocumentAttachment.Validate("File Name", CopyStr(FileManagement.GetFileNameWithoutExtension(AttachmentEntityBuffer."File Name"), 1, MaxStrLen(DocumentAttachment."File Name")));

        BindSubscription(ExpDocAttSubscribers);
        DocumentAttachment.Insert(true);
        UnbindSubscription(ExpDocAttSubscribers);

        // Transfer back to buffer with Document Attachment's SystemId
        AttachmentEntityBuffer.Id := DocumentAttachment.SystemId;
        TransferToAttachmentBuffer(DocumentAttachment, AttachmentEntityBuffer, false, TableId);
    end;

    procedure PropagateModifyAttachment(var AttachmentEntityBuffer: Record "Attachment Entity Buffer"; var TempFieldBuffer: Record "Field Buffer" temporary; TableIdForBuffer: Integer)
    var
        DocumentAttachment: Record "Document Attachment";
        FileManagement: Codeunit "File Management";
        ExpenseAttachmentMgt: Codeunit "Expense Attachment Mgt.";
        ModifyRecord: Boolean;
    begin
        if not DocumentAttachment.GetBySystemId(AttachmentEntityBuffer.Id) then
            Error(DocumentAttachmentNotFoundErr, AttachmentEntityBuffer.Id);

        if not (DocumentAttachment."Table ID" in [Database::Expense, Database::"Expense Report Line", Database::"Posted Expense Report Line"]) then
            exit;

        // Handle file name changes
        if HasRegisteredField(AttachmentEntityBuffer.FieldNo("File Name"), TempFieldBuffer) then begin
            ExpenseAttachmentMgt.RestrictAttachment(DocumentAttachment);

            DocumentAttachment.Validate("File Extension", FileManagement.GetExtension(AttachmentEntityBuffer."File Name"));
            DocumentAttachment.Validate("File Name", CopyStr(FileManagement.GetFileNameWithoutExtension(AttachmentEntityBuffer."File Name"), 1, MaxStrLen(DocumentAttachment."File Name")));
            ModifyRecord := true;
        end;

        if ModifyRecord then
            DocumentAttachment.Modify(true);

        TransferToAttachmentBuffer(DocumentAttachment, AttachmentEntityBuffer, false, TableIdForBuffer);
    end;

    procedure PropagateDeleteAttachment(var AttachmentEntityBuffer: Record "Attachment Entity Buffer"; TableId: Integer)
    var
        DocumentAttachment: Record "Document Attachment";
        Expense: Record Expense;
        ExpenseReportLine: Record "Expense Report Line";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
    begin
        if not DocumentAttachment.GetBySystemId(AttachmentEntityBuffer.Id) then
            Error(DocumentAttachmentNotFoundErr, AttachmentEntityBuffer.Id);

        if (DocumentAttachment."Table ID" <> Database::Expense) and
           (DocumentAttachment."Table ID" <> Database::"Expense Report Line") and
           (DocumentAttachment."Table ID" <> Database::"Posted Expense Report Line")
        then
            exit;

        case DocumentAttachment."Table ID" of
            Database::Expense:
                if Expense.Get(DocumentAttachment."No.") then begin
                    if TableId = Database::"Expense Report Line" then
                        Error(DocumentAttachmentCannotDeletedForExpenseFromReportLineErr);

                    DocumentAttachment.Delete(true);
                end;
            Database::"Expense Report Line":
                if ExpenseReportLine.Get(DocumentAttachment."No.", DocumentAttachment."Line No.") then
                    DocumentAttachment.Delete(true);
            Database::"Posted Expense Report Line":
                if PostedExpenseReportLine.Get(DocumentAttachment."No.", DocumentAttachment."Line No.") then
                    DocumentAttachment.Delete(true);
            else
                DocumentAttachment.Delete(true);
        end;
    end;

    local procedure TransferToAttachmentBuffer(var DocumentAttachment: Record "Document Attachment"; var AttachmentEntityBuffer: Record "Attachment Entity Buffer"; LoadContent: Boolean; TableIdForBuffer: Integer)
    var
        TempBlob: Codeunit "Temp Blob";
        FileManagement: Codeunit "File Management";
        InStream: InStream;
        OutStream: OutStream;
        RecordExists: Boolean;
    begin
        RecordExists := AttachmentEntityBuffer.Get(DocumentAttachment.SystemId);

        if not RecordExists then
            AttachmentEntityBuffer.Init();

        AttachmentEntityBuffer.Id := DocumentAttachment.SystemId;

        // Combine file name and extension back to full filename
        AttachmentEntityBuffer."File Name" := CopyStr(
            FileManagement.CreateFileNameWithExtension(DocumentAttachment."File Name", DocumentAttachment."File Extension"),
            1, MaxStrLen(AttachmentEntityBuffer."File Name"));

        AttachmentEntityBuffer."Created Date-Time" := DocumentAttachment."Attached Date";

        // Get expense SystemId
        case TableIdForBuffer of
            Database::Expense:
                AttachmentEntityBuffer."Document Id" := GetExpenseSystemId(DocumentAttachment."No.");
            Database::"Expense Report Line":
                AttachmentEntityBuffer."Document Id" := GetExpenseReportLineSystemId(DocumentAttachment."No.", DocumentAttachment."Line No.");
            Database::"Posted Expense Report Line":
                AttachmentEntityBuffer."Document Id" := GetPostedExpenseReportLineSystemId(DocumentAttachment."No.", DocumentAttachment."Line No.");
        end;

        // Transfer content and calculate byte size
        if DocumentAttachment."Document Reference ID".HasValue then begin
            DocumentAttachment.GetAsTempBlob(TempBlob);
            if TempBlob.HasValue() then begin
                AttachmentEntityBuffer."Byte Size" := TempBlob.Length();
                if LoadContent then begin
                    TempBlob.CreateInStream(InStream);
                    AttachmentEntityBuffer.Content.CreateOutStream(OutStream);
                    CopyStream(OutStream, InStream);
                end;
            end;
        end;

        if RecordExists then
            AttachmentEntityBuffer.Modify(true)
        else
            AttachmentEntityBuffer.Insert(true);
    end;

    local procedure GetExpenseSystemId(ExpenseNo: Code[20]): Guid
    var
        Expense: Record Expense;
        NullGuid: Guid;
    begin
        if Expense.Get(ExpenseNo) then
            exit(Expense.SystemId);
        exit(NullGuid);
    end;

    local procedure GetExpenseReportLineSystemId(DocumentNo: Code[20]; LineNo: Integer): Guid
    var
        ExpenseReportLine: Record "Expense Report Line";
        NullGuid: Guid;
    begin
        if ExpenseReportLine.Get(DocumentNo, LineNo) then
            exit(ExpenseReportLine.SystemId);

        exit(NullGuid);
    end;

    local procedure GetPostedExpenseReportLineSystemId(DocumentNo: Code[20]; LineNo: Integer): Guid
    var
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        NullGuid: Guid;
    begin
        if PostedExpenseReportLine.Get(DocumentNo, LineNo) then
            exit(PostedExpenseReportLine.SystemId);

        exit(NullGuid);
    end;

    procedure ReloadSingleAttachment(var AttachmentEntityBuffer: Record "Attachment Entity Buffer"; var DocumentAttachment: Record "Document Attachment"; TableIdForBuffer: Integer)
    begin
        DocumentAttachment.SetRecFilter();
        DocumentAttachment.FindFirst();
        TransferToAttachmentBuffer(DocumentAttachment, AttachmentEntityBuffer, true, TableIdForBuffer);
    end;

    local procedure HasRegisteredField(FieldNo: Integer; var TempFieldBuffer: Record "Field Buffer" temporary): Boolean
    begin
        TempFieldBuffer.SetRange("Field ID", FieldNo);
        TempFieldBuffer.SetRange("Table ID", Database::"Attachment Entity Buffer");
        exit(TempFieldBuffer.FindFirst());
    end;
}
