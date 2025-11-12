namespace System.Email;

using Microsoft.Utilities;
using Microsoft.Foundation.Attachment;
using System.Utilities;

codeunit 8898 "Map Email Source"
{
    Access = Internal;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::Email, 'OnShowSource', '', false, false)]
    local procedure OnGetPageForSourceRecord(SourceTableId: Integer; SourceSystemId: Guid; var IsHandled: Boolean)
    var
        PageManagement: Codeunit "Page Management";
        SourceRecordRef: RecordRef;
    begin
        SourceRecordRef.Open(SourceTableId);
        if not SourceRecordRef.GetBySystemId(SourceSystemId) then
            exit;

        if PageManagement.PageRun(SourceRecordRef) then
            IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::Email, 'OnFindRelatedAttachments', '', false, false)]
    local procedure FindRelatedAttachments(SourceTableId: Integer; SourceSystemID: Guid; var EmailRelatedAttachments: Record "Email Related Attachment")
    var
        DocumentAttachment: Record "Document Attachment";
        DocumentAttachmentMgmt: Codeunit "Document Attachment Mgmt";
        SourceRecordRef: RecordRef;
    begin
        SourceRecordRef.Open(SourceTableId);
        if not SourceRecordRef.GetBySystemId(SourceSystemID) then
            exit;

        DocumentAttachmentMgmt.SetDocumentAttachmentRelatedFiltersForRecRef(DocumentAttachment, SourceRecordRef);
        if DocumentAttachment.FindSet() then
            repeat
                EmailRelatedAttachments."Attachment Name" :=
                        CopyStr(StrSubstNo(FileFormatTxt, DocumentAttachment."File Name", DocumentAttachment."File Extension"),
                            1,
                            MaxStrLen(EmailRelatedAttachments."Attachment Name")
                        );
                EmailRelatedAttachments."Attachment Table ID" := Database::"Document Attachment";
                EmailRelatedAttachments."Attachment System ID" := DocumentAttachment.SystemId;
                EmailRelatedAttachments.Insert();
            until DocumentAttachment.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::Email, 'OnGetAttachment', '', false, false)]
    local procedure InsertAttachment(AttachmentTableID: Integer; AttachmentSystemID: Guid; MessageID: Guid)
    var
        DocAttachment: Record "Document Attachment";
        EmailMessage: Codeunit "Email Message";
        TempBlob: Codeunit "Temp Blob";
        AttachmentInStream: InStream;
        FileName: Text;
    begin
        if (AttachmentTableID <> Database::"Document Attachment") then
            exit;

        if not DocAttachment.GetBySystemId(AttachmentSystemID) then
            exit;

        EmailMessage.Get(MessageID);
        FileName := StrSubstNo(FileFormatTxt, DocAttachment."File Name", DocAttachment."File Extension");

        DocAttachment.GetAsTempBlob(TempBlob);

        if not TempBlob.HasValue() then
            exit;

        TempBlob.CreateInStream(AttachmentInStream);
        EmailMessage.AddAttachment(CopyStr(FileName, 1, 250), DocAttachment.GetContentType(), AttachmentInStream);
    end;

    var
        FileFormatTxt: Label '%1.%2', Comment = '%1=File Name, %2=File Extension', Locked = true;
}