// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Foundation.Attachment;
using System.Integration;
using System.Security.Encryption;
using System.Utilities;

codeunit 6989 "Expense Attachment Mgt."
{
    Access = Internal;

    var
        ExpenseRuleValidation: Codeunit "Expense Rule Validation";
        DocumentAttachmentMgmt: Codeunit "Document Attachment Mgmt";
        CannotUpdateAndDeleteAttachmentIfOpenStatusErr: Label 'You can only import and delete attachments on %1 %2 when the %3 is Open.', Comment = '%1 = Expense No., %2 = EXP100001, %3 = Status';
        CannotUpdateAndDeleteAttachmentOnExpenseReportIfOpenStatusErr: Label 'You can only import and delete attachments on %1 %2, %3 %4 when the %5 is Open.', Comment = '%1 = Expense Report No., %2 = ER100001, %3 = Line No., %4 = 10000, %5 = Status';
        CannotImportAndDeleteAttachmentOnPostedExpenseReportErr: Label 'You cannot import and delete attachments on %1 %2, %3 %4.', Comment = '%1 = Posted Expense Report No., %2 = P-ER000001, %3 = Line No., %4 = 10000';
        CannotUpdateAndDeleteAttachmentOnExpenseErr: Label 'You cannot update and delete attachment on an %1 %2 that is part of an %3 %4.', Comment = '%1 = Expense No., %2 = EXP100001, %3 = Expense Report No., %4 = ER100001';
        CannotUpdateAndDeleteAttachmentOnExpenseReportErr: Label 'You cannot update and delete attachment on an %1 %2, %3 %4 that is part of an %5 %6.', Comment = '%1 = Expense Report No., %2 = ER100001, %3 = Line No., %4 = 10000, %5 = Expense No., %6 = EXP100001';

    [EventSubscriber(ObjectType::Table, Database::"Document Attachment", OnAfterInsertEvent, '', true, true)]
    local procedure OnAfterInsertEvent(var Rec: Record "Document Attachment")
    begin
        UpdateContentHash(Rec);
        CheckAndUpdateAttachmentOnExpenseAndExpenseReportLine(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Document Attachment", OnBeforeImportFromStream, '', true, true)]
    local procedure OnBeforeImportFromStream(var DocumentAttachment: Record "Document Attachment"; var AttachmentInStream: InStream; var FileName: Text; var IsHandled: Boolean)
    begin
        RestrictAttachment(DocumentAttachment);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Document Attachment", OnBeforeDeleteEvent, '', true, true)]
    local procedure OnBeforeDeleteAttachment(var Rec: Record "Document Attachment"; RunTrigger: Boolean)
    begin
        if RunTrigger then
            RestrictAttachment(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Document Attachment", OnAfterModifyEvent, '', true, true)]
    local procedure OnAfterModifyEvent(var Rec: Record "Document Attachment"; RunTrigger: Boolean)
    begin
        UpdateContentHash(Rec);
        CheckAndUpdateAttachmentOnExpenseAndExpenseReportLine(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Document Attachment", OnAfterDeleteEvent, '', true, true)]
    local procedure OnAfterDeleteEvent(var Rec: Record "Document Attachment"; RunTrigger: Boolean)
    begin
        CheckAndUpdateAttachmentOnExpenseAndExpenseReportLine(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Document Attachment", OnBeforeOpenInOneDrive, '', true, true)]
    local procedure OnBeforeOpenInOneDrive(var Rec: Record "Document Attachment"; DocumentSharingIntent: Enum "Document Sharing Intent")
    begin
        if DocumentSharingIntent <> DocumentSharingIntent::Edit then
            exit;

        RestrictAttachment(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::Expense, 'OnAfterDeleteEvent', '', false, false)]
    local procedure DeleteAttachedDocumentsOnAfterDeleteExpense(var Rec: Record Expense; RunTrigger: Boolean)
    begin
        DocumentAttachmentMgmt.DeleteAttachedDocuments(Rec, false);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Expense Report Line", 'OnAfterDeleteEvent', '', false, false)]
    local procedure DeleteAttachedDocumentsOnAfterDeleteExpenseReportLine(var Rec: Record "Expense Report Line"; RunTrigger: Boolean)
    begin
        DocumentAttachmentMgmt.DeleteAttachedDocuments(Rec, false);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document Attachment Mgmt", OnAfterGetRefTable, '', true, true)]
    local procedure OnAfterGetRefTable(var RecRef: RecordRef; DocumentAttachment: Record "Document Attachment")
    var
        Expense: Record Expense;
        ExpenseReportLine: Record "Expense Report Line";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
    begin
        case DocumentAttachment."Table ID" of
            Database::Expense:
                begin
                    RecRef.Open(Database::Expense);
                    if Expense.Get(DocumentAttachment."No.") then
                        RecRef.GetTable(Expense);
                end;
            Database::"Expense Report Line":
                begin
                    RecRef.Open(Database::"Expense Report Line");
                    if ExpenseReportLine.Get(DocumentAttachment."No.", DocumentAttachment."Line No.") then
                        RecRef.GetTable(ExpenseReportLine);
                end;
            Database::"Posted Expense Report Line":
                begin
                    RecRef.Open(Database::"Posted Expense Report Line");
                    if PostedExpenseReportLine.Get(DocumentAttachment."No.", DocumentAttachment."Line No.") then
                        RecRef.GetTable(PostedExpenseReportLine);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Document Attachment", OnAfterInitFieldsFromRecRef, '', true, true)]
    local procedure OnAfterInitFieldsFromRecRef(var DocumentAttachment: Record "Document Attachment"; var RecRef: RecordRef)
    begin
        case RecRef.Number of
            Database::Expense,
            Database::"Expense Report Line",
            Database::"Posted Expense Report Line":
                DocumentAttachment."Document Type" := DocumentAttachment."Document Type"::Expense;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document Attachment Mgmt", OnAfterSetDocumentAttachmentFiltersForRecRefInternal, '', true, true)]
    local procedure OnAfterSetDocumentAttachmentFiltersForRecRefInternal(var DocumentAttachment: Record "Document Attachment")
    begin
        case DocumentAttachment."Table ID" of
            Database::Expense,
            Database::"Expense Report Line",
            Database::"Posted Expense Report Line":
                DocumentAttachment.SetRange("Document Type", DocumentAttachment."Document Type"::Expense);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document Attachment Mgmt", OnAfterTableHasNumberFieldPrimaryKey, '', true, true)]
    local procedure OnAfterTableHasNumberFieldPrimaryKey(TableNo: Integer; var Result: Boolean; var FieldNo: Integer)
    var
        Expense: Record Expense;
        ExpenseReportLine: Record "Expense Report Line";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
    begin
        case TableNo of
            Database::Expense:
                begin
                    FieldNo := Expense.FieldNo("No.");
                    Result := true;
                end;
            Database::"Expense Report Line":
                begin
                    FieldNo := ExpenseReportLine.FieldNo("Document No.");
                    Result := true;
                end;
            Database::"Posted Expense Report Line":
                begin
                    FieldNo := PostedExpenseReportLine.FieldNo("Document No.");
                    Result := true;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document Attachment Mgmt", OnAfterTableHasLineNumberPrimaryKey, '', true, true)]
    local procedure OnAfterTableHasLineNumberPrimaryKey(TableNo: Integer; var Result: Boolean; var FieldNo: Integer)
    var
        ExpenseReportLine: Record "Expense Report Line";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
    begin
        case TableNo of
            Database::"Expense Report Line":
                begin
                    FieldNo := ExpenseReportLine.FieldNo("Line No.");
                    Result := true;
                end;
            Database::"Posted Expense Report Line":
                begin
                    FieldNo := PostedExpenseReportLine.FieldNo("Line No.");
                    Result := true;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document Attachment Mgmt", OnCopyAttachmentsOnAfterSetFromParameters, '', true, true)]
    local procedure OnCopyAttachmentsOnAfterSetFromParameters(FromRecRef: RecordRef; var FromDocumentAttachment: Record "Document Attachment")
    var
        Expense: Record Expense;
        ExpenseReportLine: Record "Expense Report Line";
    begin
        case FromRecRef.Number of
            Database::Expense:
                begin
                    FromRecRef.SetTable(Expense);
                    FromDocumentAttachment.SetRange("Document Type", FromDocumentAttachment."Document Type"::Expense);
                    FromDocumentAttachment.SetRange("No.", Expense."No.");
                end;
            Database::"Expense Report Line":
                begin
                    FromRecRef.SetTable(ExpenseReportLine);
                    FromDocumentAttachment.SetRange("Document Type", FromDocumentAttachment."Document Type"::Expense);
                    FromDocumentAttachment.SetRange("No.", ExpenseReportLine."Document No.");
                    FromDocumentAttachment.SetRange("Line No.", ExpenseReportLine."Line No.");
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document Attachment Mgmt", OnCopyAttachmentsOnAfterSetToParameters, '', true, true)]
    local procedure OnCopyAttachmentsOnAfterSetToParameters(ToRecRef: RecordRef; var ToAttachmentDocumentType: Enum "Attachment Document Type"; var ToNo: Code[20]; var ToLineNo: Integer)
    var
        ExpenseReportLine: Record "Expense Report Line";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
    begin
        case ToRecRef.Number of
            Database::"Expense Report Line":
                begin
                    ToRecRef.SetTable(ExpenseReportLine);
                    ToAttachmentDocumentType := ToAttachmentDocumentType::Expense;
                    ToNo := ExpenseReportLine."Document No.";
                    ToLineNo := ExpenseReportLine."Line No.";
                end;
            Database::"Posted Expense Report Line":
                begin
                    ToRecRef.SetTable(PostedExpenseReportLine);
                    ToAttachmentDocumentType := ToAttachmentDocumentType::Expense;
                    ToNo := PostedExpenseReportLine."Document No.";
                    ToLineNo := PostedExpenseReportLine."Line No.";
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document Attachment Mgmt", OnCopyAttachmentsOnAfterSetToDocumentFilters, '', true, true)]
    local procedure OnCopyAttachmentsOnAfterSetToDocumentFilters(var ToDocumentAttachment: Record "Document Attachment"; ToRecRef: RecordRef; ToAttachmentDocumentType: Enum "Attachment Document Type"; ToNo: Code[20]; ToLineNo: Integer)
    begin
        case ToRecRef.Number of
            Database::"Expense Report Line",
            Database::"Posted Expense Report Line":
                begin
                    ToDocumentAttachment.Validate("Document Type", ToAttachmentDocumentType);
                    ToDocumentAttachment.Validate("Line No.", ToLineNo);
                end;
        end;
    end;

    internal procedure RestrictAttachment(DocumentAttachment: Record "Document Attachment")
    begin
        case DocumentAttachment."Table ID" of
            Database::Expense:
                RestrictExpenseAttachment(DocumentAttachment);
            Database::"Expense Report Line":
                RestrictExpenseReportAttachment(DocumentAttachment);
            Database::"Posted Expense Report Line":
                RestrictPostedExpenseReportAttachment(DocumentAttachment);
        end;
    end;

    local procedure RestrictExpenseAttachment(DocumentAttachment: Record "Document Attachment")
    var
        Expense: Record Expense;
        ExpenseReportLine: Record "Expense Report Line";
    begin
        Expense.SetLoadFields("No.", "Expense Report No.", Status);
        if not Expense.Get(DocumentAttachment."No.") then
            exit;

        if Expense."Expense Report No." <> '' then
            Error(
                CannotUpdateAndDeleteAttachmentOnExpenseErr,
                ExpenseReportLine.FieldCaption("Expense No."),
                Expense."No.",
                Expense.FieldCaption("Expense Report No."),
                Expense."Expense Report No.");

        if Expense.Status <> Expense.Status::Open then
            Error(CannotUpdateAndDeleteAttachmentIfOpenStatusErr, ExpenseReportLine.FieldCaption("Expense No."), Expense."No.", Expense.FieldCaption(Status));
    end;

    local procedure RestrictExpenseReportAttachment(DocumentAttachment: Record "Document Attachment")
    var
        Expense: Record Expense;
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
    begin
        ExpenseReportLine.SetLoadFields("Document No.", "Line No.", "Expense No.");
        if not ExpenseReportLine.Get(DocumentAttachment."No.", DocumentAttachment."Line No.") then
            exit;

        ExpenseReportHeader.SetLoadFields(Status);
        ExpenseReportHeader.Get(ExpenseReportLine."Document No.");
        if ExpenseReportHeader.Status <> ExpenseReportHeader.Status::Open then
            Error(
                CannotUpdateAndDeleteAttachmentOnExpenseReportIfOpenStatusErr,
                Expense.FieldCaption("Expense Report No."),
                ExpenseReportLine."Document No.",
                ExpenseReportLine.FieldCaption("Line No."),
                ExpenseReportLine."Line No.",
                ExpenseReportHeader.FieldCaption(Status));

        if ExpenseReportLine."Expense No." <> '' then
            if DocumentReferenceIDExistOnExpense(DocumentAttachment, ExpenseReportLine."Expense No.") then
                Error(
                    CannotUpdateAndDeleteAttachmentOnExpenseReportErr,
                    Expense.FieldCaption("Expense Report No."),
                    ExpenseReportLine."Document No.",
                    ExpenseReportLine.FieldCaption("Line No."),
                    ExpenseReportLine."Line No.",
                    ExpenseReportLine.FieldCaption("Expense No."),
                    ExpenseReportLine."Expense No.");
    end;

    local procedure RestrictPostedExpenseReportAttachment(DocumentAttachment: Record "Document Attachment")
    var
        Expense: Record Expense;
        PostedExpenseReportLine: Record "Posted Expense Report Line";
    begin
        PostedExpenseReportLine.SetLoadFields("Document No.", "Line No.", "Expense No.");
        if not PostedExpenseReportLine.Get(DocumentAttachment."No.", DocumentAttachment."Line No.") then
            exit;

        Error(
            CannotImportAndDeleteAttachmentOnPostedExpenseReportErr,
            Expense.FieldCaption("Posted Expense Report No."),
            PostedExpenseReportLine."Document No.",
            PostedExpenseReportLine.FieldCaption("Line No."),
            PostedExpenseReportLine."Line No.");
    end;

    local procedure DocumentReferenceIDExistOnExpense(DocumentAttachment: Record "Document Attachment"; ExpenseNo: Code[20]): Boolean
    var
        ExpenseDocumentAttachment: Record "Document Attachment";
    begin
        ExpenseDocumentAttachment.SetRange("Table ID", Database::Expense);
        ExpenseDocumentAttachment.SetRange("No.", ExpenseNo);
        ExpenseDocumentAttachment.SetRange("Document Reference ID", DocumentAttachment."Document Reference ID");

        exit(not ExpenseDocumentAttachment.IsEmpty());
    end;

    local procedure CheckAndUpdateAttachmentOnExpenseAndExpenseReportLine(DocumentAttachment: Record "Document Attachment")
    begin
        case DocumentAttachment."Table ID" of
            Database::Expense:
                CheckAndUpdateAttachmentOnExpense(DocumentAttachment);
            Database::"Expense Report Line":
                CheckAndUpdateAttachmentOnExpenseReportLine(DocumentAttachment);
        end;
    end;

    local procedure CheckAndUpdateAttachmentOnExpense(DocumentAttachment: Record "Document Attachment")
    var
        Expense: Record Expense;
    begin
        if not Expense.Get(DocumentAttachment."No.") then
            exit;

        ExpenseRuleValidation.ValidateExpenseAgainstRule(Expense);
        UpdateReceiptAttachedOnExpense(Expense, DocumentAttachment);
    end;

    local procedure CheckAndUpdateAttachmentOnExpenseReportLine(DocumentAttachment: Record "Document Attachment")
    var
        ExpenseReportLine: Record "Expense Report Line";
    begin
        if not ExpenseReportLine.Get(DocumentAttachment."No.", DocumentAttachment."Line No.") then
            exit;

        ExpenseRuleValidation.ValidateExpenseReportLineAgainstRule(ExpenseReportLine);
        UpdateReceiptAttachedOnExpenseReportLine(ExpenseReportLine, DocumentAttachment);
    end;

    local procedure UpdateReceiptAttachedOnExpense(var Expense: Record Expense; DocumentAttachment: Record "Document Attachment")
    var
        RecRef: RecordRef;
        HasAttachments: Boolean;
    begin
        RecRef.GetTable(Expense);
        HasAttachments := DocumentAttachmentMgmt.AttachedDocumentsExist(RecRef);

        if DocumentAttachment.HasContent() then
            if Expense."Receipt Attached" <> HasAttachments then begin
                Expense."Receipt Attached" := HasAttachments;

                if Expense."Receipt Attached" then
                    Expense."Receipt Entry" := DocumentAttachment.ID
                else
                    Expense."Receipt Entry" := 0;

                Expense.Modify(true);
            end;
    end;

    local procedure UpdateReceiptAttachedOnExpenseReportLine(var ExpenseReportLine: Record "Expense Report Line"; DocumentAttachment: Record "Document Attachment")
    var
        RecRef: RecordRef;
        HasAttachments: Boolean;
    begin
        RecRef.GetTable(ExpenseReportLine);
        HasAttachments := DocumentAttachmentMgmt.AttachedDocumentsExist(RecRef);

        if DocumentAttachment.HasContent() then
            if ExpenseReportLine."Receipt Attached" <> HasAttachments then begin
                ExpenseReportLine."Receipt Attached" := HasAttachments;

                if ExpenseReportLine."Receipt Attached" then
                    ExpenseReportLine."Receipt Entry" := DocumentAttachment.ID
                else
                    ExpenseReportLine."Receipt Entry" := 0;

                ExpenseReportLine.Modify(true);
            end;
    end;

    local procedure UpdateContentHash(var DocumentAttachment: Record "Document Attachment")
    var
        TempBlob: Codeunit "Temp Blob";
        CryptographyManagement: Codeunit "Cryptography Management";
        HashAlgorithmType: Option MD5,SHA1,SHA256,SHA384,SHA512;
        HashInStream: InStream;
        NewHash: Text[64];
    begin
        case DocumentAttachment."Table ID" of
            Database::Expense,
            Database::"Expense Report Line",
            Database::"Posted Expense Report Line":
                ;
            else
                exit;
        end;

        if not DocumentAttachment.HasContent() then begin
            if DocumentAttachment."Content Hash" = '' then
                exit;
            DocumentAttachment."Content Hash" := '';
            DocumentAttachment.Modify(false);
            exit;
        end;

        DocumentAttachment.GetAsTempBlob(TempBlob);
        if not TempBlob.HasValue() then begin
            if DocumentAttachment."Content Hash" = '' then
                exit;
            DocumentAttachment."Content Hash" := '';
            DocumentAttachment.Modify(false);
            exit;
        end;

        TempBlob.CreateInStream(HashInStream);
        NewHash :=
            CopyStr(
                LowerCase(CryptographyManagement.GenerateHash(HashInStream, HashAlgorithmType::SHA256)),
                1,
                MaxStrLen(DocumentAttachment."Content Hash"));

        if DocumentAttachment."Content Hash" = NewHash then
            exit;

        DocumentAttachment."Content Hash" := NewHash;
        DocumentAttachment.Modify(false);
    end;

    internal procedure HasPDFAttachment(TableID: Integer; DocumentNo: Code[20]; LineNo: Integer): Boolean
    var
        DocumentAttachment: Record "Document Attachment";
    begin
        DocumentAttachment.SetRange("Document Type", DocumentAttachment."Document Type"::Expense);
        DocumentAttachment.SetRange("Table ID", TableID);
        DocumentAttachment.SetRange("No.", DocumentNo);
        DocumentAttachment.SetRange("Line No.", LineNo);
        DocumentAttachment.SetRange("File Type", DocumentAttachment."File Type"::PDF);

        exit(not DocumentAttachment.IsEmpty());
    end;
}