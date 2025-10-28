// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Integration.Foundation.Attachment;

using Microsoft.Foundation.Attachment;
using Microsoft.QualityManagement.Configuration.Template;
using Microsoft.QualityManagement.Configuration.Template.Field;
using Microsoft.QualityManagement.Document;

codeunit 20414 "Qlty. Attachment Integration"
{
    /// <summary>
    /// Used for taking pictures and attaching documents to a Quality Inspection Test.
    /// </summary>
    /// <param name="DocumentAttachment"></param>
    /// <param name="RecRef"></param>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document Attachment Mgmt", 'OnAfterSetDocumentAttachmentFiltersForRecRef', '', true, true)]
    local procedure HandleOnAfterSetDocumentAttachmentFiltersForRecRef(var DocumentAttachment: Record "Document Attachment"; RecRef: RecordRef)
    begin
        FilterDocumentAttachment(DocumentAttachment, RecRef);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document Attachment Mgmt", 'OnAfterTableHasNumberFieldPrimaryKey', '', true, true)]
    local procedure HandleOnAfterTableHasNumberFieldPrimaryKey(TableNo: Integer; var Result: Boolean; var FieldNo: Integer)
    var
        TempQltyField: Record "Qlty. Field" temporary;
        TempQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr." temporary;
        TempQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line" temporary;
        TempQltyInspectionTestHeader: Record "Qlty. Inspection Test Header" temporary;
        TempQltyInspectionTestLine: Record "Qlty. Inspection Test Line" temporary;
    begin
        case TableNo of
            Database::"Qlty. Field":
                begin
                    FieldNo := TempQltyField.FieldNo("Code");
                    Result := true;
                end;
            Database::"Qlty. Inspection Template Hdr.":
                begin
                    FieldNo := TempQltyInspectionTemplateHdr.FieldNo("Code");
                    Result := true;
                end;
            Database::"Qlty. Inspection Template Line":
                begin
                    FieldNo := TempQltyInspectionTemplateLine.FieldNo("Template Code");
                    Result := true;
                end;
            Database::"Qlty. Inspection Test Header":
                begin
                    FieldNo := TempQltyInspectionTestHeader.FieldNo("No.");
                    Result := true;
                end;
            Database::"Qlty. Inspection Test Line":
                begin
                    FieldNo := TempQltyInspectionTestLine.FieldNo("Test No.");
                    Result := true;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document Attachment Mgmt", 'OnAfterTableHasLineNumberPrimaryKey', '', true, true)]
    local procedure HandleOnAfterTableHasLineNumberPrimaryKey(TableNo: Integer; var Result: Boolean; var FieldNo: Integer)
    var
        TempQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line" temporary;
        TempQltyInspectionTestLine: Record "Qlty. Inspection Test Line" temporary;
    begin
        case TableNo of
            Database::"Qlty. Inspection Template Line":
                begin
                    FieldNo := TempQltyInspectionTemplateLine.FieldNo("Line No.");
                    Result := true;
                end;
            Database::"Qlty. Inspection Test Line":
                begin
                    FieldNo := TempQltyInspectionTestLine.FieldNo("Line No.");
                    Result := true;
                end;
        end;
    end;

    /// <summary>
    /// Used for taking pictures and attaching documents to a Quality Inspection Test.
    /// </summary>
    /// <param name="DocumentAttachment"></param>
    /// <param name="RecRef"></param>
    [EventSubscriber(ObjectType::Table, Database::"Document Attachment", 'OnBeforeInsertAttachment', '', true, true)]
    local procedure HandleOnBeforeInsertAttachment(var DocumentAttachment: Record "Document Attachment"; var RecRef: RecordRef)
    var
        TempQltyField: Record "Qlty. Field" temporary;
        TempQltyInspectionTestHeader: Record "Qlty. Inspection Test Header" temporary;
        TempQltyInspectionTestLine: Record "Qlty. Inspection Test Line" temporary;
        TempQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr." temporary;
        TempQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line" temporary;
        Template: Code[20];
        TestNo: Code[20];
        CurrentField: Code[20];
        LineNo: Integer;
        RetestNo: Integer;
    begin
        case RecRef.Number() of
            Database::"Qlty. Inspection Test Header":
                begin
                    TestNo := CopyStr(Format(RecRef.Field(TempQltyInspectionTestHeader.FieldNo("No.")).Value()), 1, MaxStrLen(TestNo));
                    RetestNo := RecRef.Field(TempQltyInspectionTestHeader.FieldNo("Retest No.")).Value();
                    DocumentAttachment."No." := TestNo;
                    DocumentAttachment."Line No." := RetestNo;
                end;
            Database::"Qlty. Inspection Template Hdr.":
                begin
                    Template := CopyStr(Format(RecRef.Field(TempQltyInspectionTemplateHdr.FieldNo("Code")).Value()), 1, MaxStrLen(Template));
                    DocumentAttachment."No." := Template;
                end;
            Database::"Qlty. Field":
                begin
                    CurrentField := CopyStr(Format(RecRef.Field(TempQltyField.FieldNo("Code")).Value()), 1, MaxStrLen(CurrentField));
                    DocumentAttachment."No." := CurrentField;
                end;
            Database::"Qlty. Inspection Test Line":
                begin
                    TestNo := CopyStr(Format(RecRef.Field(TempQltyInspectionTestLine.FieldNo("Test No.")).Value()), 1, MaxStrLen(TestNo));
                    LineNo := RecRef.Field(TempQltyInspectionTestLine.FieldNo("Line No.")).Value();
                    DocumentAttachment."No." := TestNo;
                    DocumentAttachment."Line No." := LineNo;
                end;
            Database::"Qlty. Inspection Template Line":
                begin
                    Template := CopyStr(Format(RecRef.Field(TempQltyInspectionTemplateLine.FieldNo("Template Code")).Value()), 1, MaxStrLen(Template));
                    LineNo := RecRef.Field(TempQltyInspectionTemplateLine.FieldNo("Line No.")).Value();
                    DocumentAttachment."No." := Template;
                    DocumentAttachment."Line No." := LineNo;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Document Attachment Details", 'OnAfterOpenForRecRef', '', true, true)]
    local procedure HandleOnAfterOpenForRecRef(var DocumentAttachment: Record "Document Attachment"; var RecRef: RecordRef);
    begin
        FilterDocumentAttachment(DocumentAttachment, RecRef);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document Attachment Mgmt", 'OnAfterGetRefTable', '', true, true)]
    local procedure HandleOnAfterGetRefTable(var RecRef: RecordRef; DocumentAttachment: Record "Document Attachment")
    begin
        GetQltyInspectionRecordRefFromDocumentAttachment(DocumentAttachment, RecRef);
    end;

    local procedure FilterDocumentAttachment(var DocumentAttachment: Record "Document Attachment"; RecordRef: RecordRef)
    var
        TempQltyField: Record "Qlty. Field" temporary;
        TempQltyInspectionTestHeader: Record "Qlty. Inspection Test Header" temporary;
        TempQltyInspectionTestLine: Record "Qlty. Inspection Test Line" temporary;
        TempQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr." temporary;
        TempQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line" temporary;
        CurrentField: Code[20];
        Template: Code[20];
        TestNo: Code[20];
        RetestNo: Integer;
        LineNo: Integer;
    begin
        case RecordRef.Number() of
            Database::"Qlty. Field":
                begin
                    CurrentField := CopyStr(Format(RecordRef.Field(TempQltyField.FieldNo("Code")).Value()), 1, MaxStrLen(CurrentField));
                    DocumentAttachment.SetRange("No.", CurrentField);
                end;
            Database::"Qlty. Inspection Test Header":
                begin
                    TestNo := CopyStr(Format(RecordRef.Field(TempQltyInspectionTestHeader.FieldNo("No.")).Value()), 1, MaxStrLen(TestNo));
                    RetestNo := RecordRef.Field(TempQltyInspectionTestHeader.FieldNo("Retest No.")).Value();
                    DocumentAttachment.SetRange("No.", TestNo);
                    DocumentAttachment.SetRange("Line No.", RetestNo);
                end;
            Database::"Qlty. Inspection Test Line":
                begin
                    TestNo := CopyStr(Format(RecordRef.Field(TempQltyInspectionTestLine.FieldNo("Test No.")).Value()), 1, MaxStrLen(TestNo));
                    LineNo := RecordRef.Field(TempQltyInspectionTestLine.FieldNo("Line No.")).Value();
                    DocumentAttachment.SetRange("No.", TestNo);
                    DocumentAttachment.SetRange("Line No.", LineNo);
                end;
            Database::"Qlty. Inspection Template Hdr.":
                begin
                    Template := CopyStr(Format(RecordRef.Field(TempQltyInspectionTemplateHdr.FieldNo("Code")).Value()), 1, MaxStrLen(Template));
                    DocumentAttachment.SetRange("No.", Template);
                end;
            Database::"Qlty. Inspection Template Line":
                begin
                    Template := CopyStr(Format(RecordRef.Field(TempQltyInspectionTemplateLine.FieldNo("Template Code")).Value()), 1, MaxStrLen(Template));
                    LineNo := RecordRef.Field(TempQltyInspectionTemplateLine.FieldNo("Line No.")).Value();
                    DocumentAttachment.SetRange("No.", Template);
                    DocumentAttachment.SetRange("Line No.", LineNo);
                end;
        end;
    end;

    local procedure GetQltyInspectionRecordRefFromDocumentAttachment(DocumentAttachment: Record "Document Attachment"; var FoundRecordRef: RecordRef) DidGetRecord: Boolean
    var
        QltyField: Record "Qlty. Field";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        QltyInspectionTestLine: Record "Qlty. Inspection Test Line";
    begin
        case DocumentAttachment."Table ID" of
            Database::"Qlty. Field":
                begin
                    QltyField.SetRange(Code, DocumentAttachment."No.");
                    if QltyField.FindLast() then begin
                        QltyField.SetRecFilter();
                        FoundRecordRef.GetTable(QltyField);
                        DidGetRecord := true;
                    end;
                end;
            Database::"Qlty. Inspection Test Header":
                begin
                    QltyInspectionTestHeader.SetRange("No.", DocumentAttachment."No.");
                    QltyInspectionTestHeader.SetRange("Retest No.", DocumentAttachment."Line No.");
                    if QltyInspectionTestHeader.FindLast() then begin
                        QltyInspectionTestHeader.SetRecFilter();
                        FoundRecordRef.GetTable(QltyInspectionTestHeader);
                        DidGetRecord := true;
                    end;
                end;
            Database::"Qlty. Inspection Test Line":
                begin
                    QltyInspectionTestLine.SetRange("Test No.", DocumentAttachment."No.");
                    QltyInspectionTestLine.SetRange("Line No.", DocumentAttachment."Line No.");
                    if QltyInspectionTestLine.FindLast() then begin
                        QltyInspectionTestLine.SetRecFilter();
                        FoundRecordRef.GetTable(QltyInspectionTestLine);
                        DidGetRecord := true;
                    end;
                end;
            Database::"Qlty. Inspection Template Hdr.":
                begin
                    QltyInspectionTemplateHdr.SetRange("Code", DocumentAttachment."No.");
                    if QltyInspectionTemplateHdr.FindFirst() then begin
                        QltyInspectionTemplateHdr.SetRecFilter();
                        FoundRecordRef.GetTable(QltyInspectionTemplateHdr);
                        DidGetRecord := true;
                    end;
                end;
            Database::"Qlty. Inspection Template Line":
                begin
                    QltyInspectionTemplateLine.SetRange("Template Code", DocumentAttachment."No.");
                    QltyInspectionTemplateLine.SetRange("Line No.", DocumentAttachment."Line No.");
                    if QltyInspectionTemplateLine.FindFirst() then begin
                        QltyInspectionTemplateLine.SetRecFilter();
                        FoundRecordRef.GetTable(QltyInspectionTemplateLine);
                        DidGetRecord := true;
                    end;
                end;
        end;
    end;
}
