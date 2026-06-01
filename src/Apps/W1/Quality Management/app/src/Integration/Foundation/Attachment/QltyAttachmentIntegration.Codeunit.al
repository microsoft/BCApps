// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Integration.Foundation.Attachment;

using Microsoft.Foundation.Attachment;
using Microsoft.QualityManagement.Configuration.Template;
using Microsoft.QualityManagement.Configuration.Template.Test;
using Microsoft.QualityManagement.Document;

/// <summary>
/// Includes event subscribers and tools to help deal with attachments to quality inspections.
/// </summary>
codeunit 20414 "Qlty. Attachment Integration"
{
    InherentPermissions = X;

    /// <summary>
    /// Used for taking pictures and attaching documents to a Quality Inspection.
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
        TempQltyTest: Record "Qlty. Test" temporary;
        TempQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr." temporary;
        TempQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line" temporary;
        TempQltyInspectionHeader: Record "Qlty. Inspection Header" temporary;
        TempQltyInspectionLine: Record "Qlty. Inspection Line" temporary;
    begin
        case TableNo of
            Database::"Qlty. Test":
                begin
                    FieldNo := TempQltyTest.FieldNo("Code");
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
            Database::"Qlty. Inspection Header":
                begin
                    FieldNo := TempQltyInspectionHeader.FieldNo("No.");
                    Result := true;
                end;
            Database::"Qlty. Inspection Line":
                begin
                    FieldNo := TempQltyInspectionLine.FieldNo("Inspection No.");
                    Result := true;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document Attachment Mgmt", 'OnAfterTableHasLineNumberPrimaryKey', '', true, true)]
    local procedure HandleOnAfterTableHasLineNumberPrimaryKey(TableNo: Integer; var Result: Boolean; var FieldNo: Integer)
    var
        TempQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line" temporary;
        TempQltyInspectionLine: Record "Qlty. Inspection Line" temporary;
    begin
        case TableNo of
            Database::"Qlty. Inspection Template Line":
                begin
                    FieldNo := TempQltyInspectionTemplateLine.FieldNo("Line No.");
                    Result := true;
                end;
            Database::"Qlty. Inspection Line":
                begin
                    FieldNo := TempQltyInspectionLine.FieldNo("Line No.");
                    Result := true;
                end;
        end;
    end;

    /// <summary>
    /// Used for taking pictures and attaching documents to a Quality Inspection.
    /// </summary>
    /// <param name="DocumentAttachment"></param>
    /// <param name="RecRef"></param>
    [EventSubscriber(ObjectType::Table, Database::"Document Attachment", 'OnBeforeInsertAttachment', '', true, true)]
    local procedure HandleOnBeforeInsertAttachment(var DocumentAttachment: Record "Document Attachment"; var RecRef: RecordRef)
    var
        TempQltyTest: Record "Qlty. Test" temporary;
        TempQltyInspectionHeader: Record "Qlty. Inspection Header" temporary;
        TempQltyInspectionLine: Record "Qlty. Inspection Line" temporary;
        TempQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr." temporary;
        TempQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line" temporary;
        TemplateCode: Code[20];
        InspectionNo: Code[20];
        QltyTestCode: Code[20];
        LineNo: Integer;
        ReinspectionNo: Integer;
    begin
        case RecRef.Number() of
            Database::"Qlty. Inspection Header":
                begin
                    InspectionNo := CopyStr(Format(RecRef.Field(TempQltyInspectionHeader.FieldNo("No.")).Value()), 1, MaxStrLen(InspectionNo));
                    ReinspectionNo := RecRef.Field(TempQltyInspectionHeader.FieldNo("Re-inspection No.")).Value();
                    DocumentAttachment."No." := InspectionNo;
                    DocumentAttachment."Line No." := ReinspectionNo;
                end;
            Database::"Qlty. Inspection Template Hdr.":
                begin
                    TemplateCode := CopyStr(Format(RecRef.Field(TempQltyInspectionTemplateHdr.FieldNo("Code")).Value()), 1, MaxStrLen(TemplateCode));
                    DocumentAttachment."No." := TemplateCode;
                end;
            Database::"Qlty. Test":
                begin
                    QltyTestCode := CopyStr(Format(RecRef.Field(TempQltyTest.FieldNo("Code")).Value()), 1, MaxStrLen(QltyTestCode));
                    DocumentAttachment."No." := QltyTestCode;
                end;
            Database::"Qlty. Inspection Line":
                begin
                    InspectionNo := CopyStr(Format(RecRef.Field(TempQltyInspectionLine.FieldNo("Inspection No.")).Value()), 1, MaxStrLen(InspectionNo));
                    LineNo := RecRef.Field(TempQltyInspectionLine.FieldNo("Line No.")).Value();
                    DocumentAttachment."No." := InspectionNo;
                    DocumentAttachment."Line No." := LineNo;
                end;
            Database::"Qlty. Inspection Template Line":
                begin
                    TemplateCode := CopyStr(Format(RecRef.Field(TempQltyInspectionTemplateLine.FieldNo("Template Code")).Value()), 1, MaxStrLen(TemplateCode));
                    LineNo := RecRef.Field(TempQltyInspectionTemplateLine.FieldNo("Line No.")).Value();
                    DocumentAttachment."No." := TemplateCode;
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
        TempQltyTest: Record "Qlty. Test" temporary;
        TempQltyInspectionHeader: Record "Qlty. Inspection Header" temporary;
        TempQltyInspectionLine: Record "Qlty. Inspection Line" temporary;
        TempQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr." temporary;
        TempQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line" temporary;
        CurrentField: Code[20];
        Template: Code[20];
        InspectionNo: Code[20];
        ReinspectionNo: Integer;
        LineNo: Integer;
    begin
        case RecordRef.Number() of
            Database::"Qlty. Test":
                begin
                    CurrentField := CopyStr(Format(RecordRef.Field(TempQltyTest.FieldNo("Code")).Value()), 1, MaxStrLen(CurrentField));
                    DocumentAttachment.SetRange("No.", CurrentField);
                end;
            Database::"Qlty. Inspection Header":
                begin
                    InspectionNo := CopyStr(Format(RecordRef.Field(TempQltyInspectionHeader.FieldNo("No.")).Value()), 1, MaxStrLen(InspectionNo));
                    ReinspectionNo := RecordRef.Field(TempQltyInspectionHeader.FieldNo("Re-inspection No.")).Value();
                    DocumentAttachment.SetRange("No.", InspectionNo);
                    DocumentAttachment.SetRange("Line No.", ReinspectionNo);
                end;
            Database::"Qlty. Inspection Line":
                begin
                    InspectionNo := CopyStr(Format(RecordRef.Field(TempQltyInspectionLine.FieldNo("Inspection No.")).Value()), 1, MaxStrLen(InspectionNo));
                    LineNo := RecordRef.Field(TempQltyInspectionLine.FieldNo("Line No.")).Value();
                    DocumentAttachment.SetRange("No.", InspectionNo);
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
        QltyTest: Record "Qlty. Test";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionLine: Record "Qlty. Inspection Line";
    begin
        case DocumentAttachment."Table ID" of
            Database::"Qlty. Test":
                begin
                    QltyTest.SetRange(Code, DocumentAttachment."No.");
                    if QltyTest.FindLast() then begin
                        QltyTest.SetRecFilter();
                        FoundRecordRef.GetTable(QltyTest);
                        DidGetRecord := true;
                    end;
                end;
            Database::"Qlty. Inspection Header":
                begin
                    QltyInspectionHeader.SetRange("No.", DocumentAttachment."No.");
                    QltyInspectionHeader.SetRange("Re-inspection No.", DocumentAttachment."Line No.");
                    if QltyInspectionHeader.FindLast() then begin
                        QltyInspectionHeader.SetRecFilter();
                        FoundRecordRef.GetTable(QltyInspectionHeader);
                        DidGetRecord := true;
                    end;
                end;
            Database::"Qlty. Inspection Line":
                begin
                    QltyInspectionLine.SetRange("Inspection No.", DocumentAttachment."No.");
                    QltyInspectionLine.SetRange("Line No.", DocumentAttachment."Line No.");
                    if QltyInspectionLine.FindLast() then begin
                        QltyInspectionLine.SetRecFilter();
                        FoundRecordRef.GetTable(QltyInspectionLine);
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
