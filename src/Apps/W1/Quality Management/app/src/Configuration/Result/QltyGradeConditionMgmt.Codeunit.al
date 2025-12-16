// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Configuration.Result;

using Microsoft.QualityManagement.Configuration.Template;
using Microsoft.QualityManagement.Configuration.Template.Field;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Utilities;

/// <summary>
/// Used to copy grade conditions from fields to templates, templates to inspections
/// </summary>
codeunit 20409 "Qlty. Grade Condition Mgmt."
{
    var
        ChangedFieldConditionsUpdateTemplatesQst: Label 'You have changed default conditions on the field %2, there are %1 template lines with earlier conditions for this grade. Do you want to update the templates?', Comment = '%1=the amount of template lines that have other conditions, %2=the field name';
        ChangedGradeConditionsUpdateDefaultsOnFieldsQst: Label 'You have changed default conditions on the grade %1, there are %2 fields with earlier conditions for this grade. Do you want to update these fields?', Comment = '%1=the amount of fields that have other conditions, %2=the grade name';

    /// <summary>
    /// Prompts if templates should be updated.
    /// </summary>
    /// <param name="CopyFromQltyIGradeConditionConf"></param>
    internal procedure PromptUpdateTemplatesFromFieldsIfApplicable(CopyFromQltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.")
    var
        CountsQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        CopyToQltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
        Continue: Boolean;
    begin
        CountsQltyInspectionTemplateLine.SetRange("Field Code", CopyFromQltyIGradeConditionConf."Field Code");

        CopyToQltyIGradeConditionConf.SetRange("Condition Type", CopyToQltyIGradeConditionConf."Condition Type"::Template);
        CopyToQltyIGradeConditionConf.SetRange("Field Code", CopyFromQltyIGradeConditionConf."Field Code");
        if CopyFromQltyIGradeConditionConf."Grade Code" <> '' then
            CopyToQltyIGradeConditionConf.SetRange("Grade Code", CopyFromQltyIGradeConditionConf."Grade Code");
        CopyToQltyIGradeConditionConf.SetFilter(Condition, '<>%1', CopyFromQltyIGradeConditionConf.Condition);
        if CopyToQltyIGradeConditionConf.IsEmpty() then begin
            CopyToQltyIGradeConditionConf.SetRange(Condition);
            CopyToQltyIGradeConditionConf.SetFilter("Condition Description", '<>%1', CopyFromQltyIGradeConditionConf."Condition Description");
        end;
        if not CopyToQltyIGradeConditionConf.IsEmpty() then begin
            if not GuiAllowed() then
                Continue := true
            else
                Continue := Confirm(StrSubstNo(ChangedFieldConditionsUpdateTemplatesQst, CountsQltyInspectionTemplateLine.Count(), CopyFromQltyIGradeConditionConf."Field Code"));
            if Continue then begin
                CopyToQltyIGradeConditionConf.FindSet(true);
                repeat
                    CopyGradeConditionsFromFieldToTemplateLine(
                        CopyToQltyIGradeConditionConf."Target Code",
                        CopyToQltyIGradeConditionConf."Target Line No.",
                        CopyFromQltyIGradeConditionConf."Grade Code",
                        true,
                        CopyFromQltyIGradeConditionConf.Condition,
                        CopyFromQltyIGradeConditionConf."Condition Description");
                until CopyToQltyIGradeConditionConf.Next() = 0;
            end;
        end;
    end;

    internal procedure PromptUpdateFieldsFromGradeIfApplicable(GradeCode: Code[20])
    var
        ExistingQltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
        QltyInspectionGrade: Record "Qlty. Inspection Grade";
        Continue: Boolean;
    begin
        ExistingQltyIGradeConditionConf.SetRange("Grade Code", GradeCode);
        ExistingQltyIGradeConditionConf.SetRange("Condition Type", ExistingQltyIGradeConditionConf."Condition Type"::Field);

        QltyInspectionGrade.Get(GradeCode);
        if not (QltyInspectionGrade."Copy Behavior" in [QltyInspectionGrade."Copy Behavior"::"Automatically copy the grade"]) then
            exit;

        if not ExistingQltyIGradeConditionConf.IsEmpty() then begin
            if not GuiAllowed() then
                Continue := true
            else
                Continue := Confirm(StrSubstNo(ChangedGradeConditionsUpdateDefaultsOnFieldsQst, GradeCode, ExistingQltyIGradeConditionConf.Count()));
            if Continue then
                OverwriteExistingFieldConditionsWithGradeCondition(GradeCode);
        end;
    end;

    /// <summary>
    /// Used to copy grade conditions from the default configuration to the template line.
    /// </summary>
    /// <param name="Template">The template</param>
    /// <param name="LineNo">The template line</param>
    /// <param name="OptionalSpecificGrade">Leave empty to copy all applicable grades</param>
    procedure CopyGradeConditionsFromFieldToTemplateLine(Template: Code[20]; LineNo: Integer; OptionalSpecificGrade: Code[20]; OverwriteConditionIfExisting: Boolean)
    begin
        CopyGradeConditionsFromFieldToTemplateLine(Template, LineNo, OptionalSpecificGrade, OverwriteConditionIfExisting, '', '');
    end;

    local procedure CopyGradeConditionsFromFieldToTemplateLine(Template: Code[20]; LineNo: Integer; OptionalSpecificGrade: Code[20]; OverwriteConditionIfExisting: Boolean; OptionalSpecificCondition: Text; OptionalSpecificConditionDescription: Text)
    var
        QltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        QltyInspectionGrade: Record "Qlty. Inspection Grade";
        QltyField: Record "Qlty. Field";
        CopyFromQltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
        CopyToQltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
    begin
        case true of
            not QltyInspectionTemplateLine.Get(Template, LineNo),
            not QltyField.Get(QltyInspectionTemplateLine."Field Code"),
            QltyField."Field Type" in [QltyField."Field Type"::"Field Type Label"]:
                exit;
        end;

        CopyFromQltyIGradeConditionConf.SetRange("Condition Type", CopyFromQltyIGradeConditionConf."Condition Type"::Field);
        CopyFromQltyIGradeConditionConf.SetRange("Field Code", QltyInspectionTemplateLine."Field Code");
        if OptionalSpecificGrade <> '' then
            CopyFromQltyIGradeConditionConf.SetRange("Grade Code", OptionalSpecificGrade);

        if CopyFromQltyIGradeConditionConf.IsEmpty() then
            CopyGradeConditionsFromDefaultToField(QltyInspectionTemplateLine."Field Code");

        if CopyFromQltyIGradeConditionConf.FindSet() then
            repeat
                if QltyInspectionGrade.Get(CopyFromQltyIGradeConditionConf."Grade Code") then
                    if QltyInspectionGrade."Copy Behavior" = QltyInspectionGrade."Copy Behavior"::"Automatically copy the grade" then begin
                        CopyToQltyIGradeConditionConf.Reset();
                        CopyToQltyIGradeConditionConf := CopyFromQltyIGradeConditionConf;
                        CopyToQltyIGradeConditionConf."Condition Type" := CopyToQltyIGradeConditionConf."Condition Type"::Template;
                        CopyToQltyIGradeConditionConf."Target Code" := Template;
                        CopyToQltyIGradeConditionConf."Target Line No." := LineNo;
                        CopyToQltyIGradeConditionConf.Priority := QltyInspectionGrade."Evaluation Sequence";
                        CopyToQltyIGradeConditionConf."Grade Visibility" := QltyInspectionGrade."Grade Visibility";
                        CopyToQltyIGradeConditionConf.SetRecFilter();

                        if not CopyToQltyIGradeConditionConf.FindFirst() then begin
                            CopyToQltyIGradeConditionConf.TransferFields(CopyFromQltyIGradeConditionConf, false);
                            if OptionalSpecificCondition <> '' then
                                CopyToQltyIGradeConditionConf.Condition := CopyStr(OptionalSpecificCondition, 1, MaxStrLen(CopyToQltyIGradeConditionConf.Condition));
                            if OptionalSpecificConditionDescription <> '' then
                                CopyToQltyIGradeConditionConf."Condition Description" := CopyStr(OptionalSpecificConditionDescription, 1, MaxStrLen(CopyToQltyIGradeConditionConf."Condition Description"));
                            CopyToQltyIGradeConditionConf.Insert()
                        end else begin
                            if OverwriteConditionIfExisting then
                                CopyToQltyIGradeConditionConf.TransferFields(CopyFromQltyIGradeConditionConf, false)
                            else begin
                                CopyToQltyIGradeConditionConf.Priority := QltyInspectionGrade."Evaluation Sequence";
                                CopyToQltyIGradeConditionConf."Grade Visibility" := QltyInspectionGrade."Grade Visibility";
                            end;
                            if OptionalSpecificCondition <> '' then
                                CopyToQltyIGradeConditionConf.Condition := CopyStr(OptionalSpecificCondition, 1, MaxStrLen(CopyToQltyIGradeConditionConf.Condition));
                            if OptionalSpecificConditionDescription <> '' then
                                CopyToQltyIGradeConditionConf."Condition Description" := CopyStr(OptionalSpecificConditionDescription, 1, MaxStrLen(CopyToQltyIGradeConditionConf."Condition Description"));

                            CopyToQltyIGradeConditionConf.Modify();
                        end;
                    end;

            until CopyFromQltyIGradeConditionConf.Next() = 0;
    end;

    /// <summary>
    /// Used for cloning templates.
    /// </summary>
    /// <param name="FromQltyInspectionTemplateLine"></param>
    /// <param name="TargetQltyInspectionTemplateLine"></param>
    procedure CopyGradeConditionsFromTemplateLineToTemplateLine(FromQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line"; TargetQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line")
    var
        FromQltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
        ToQltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
    begin
        FromQltyIGradeConditionConf.SetRange("Condition Type", FromQltyIGradeConditionConf."Condition Type"::Template);
        FromQltyIGradeConditionConf.SetRange("Target Code", FromQltyInspectionTemplateLine."Template Code");
        FromQltyIGradeConditionConf.SetRange("Target Line No.", FromQltyInspectionTemplateLine."Line No.");
        FromQltyIGradeConditionConf.SetRange("Field Code", FromQltyInspectionTemplateLine."Field Code");
        if FromQltyIGradeConditionConf.FindSet() then
            repeat
                Clear(ToQltyIGradeConditionConf);
                ToQltyIGradeConditionConf.Reset();
                ToQltyIGradeConditionConf := FromQltyIGradeConditionConf;
                ToQltyIGradeConditionConf.SetRecFilter();
                ToQltyIGradeConditionConf.SetRange("Target Code", TargetQltyInspectionTemplateLine."Template Code");
                ToQltyIGradeConditionConf.SetRange("Field Code", TargetQltyInspectionTemplateLine."Field Code");
                ToQltyIGradeConditionConf.SetRange("Target Line No.", TargetQltyInspectionTemplateLine."Line No.");
                if ToQltyIGradeConditionConf.IsEmpty() then begin
                    Clear(ToQltyIGradeConditionConf);
                    ToQltyIGradeConditionConf.Init();
                    ToQltyIGradeConditionConf.TransferFields(FromQltyIGradeConditionConf, true);
                    ToQltyIGradeConditionConf."Target Code" := TargetQltyInspectionTemplateLine."Template Code";
                    ToQltyIGradeConditionConf."Target Line No." := TargetQltyInspectionTemplateLine."Line No.";
                    ToQltyIGradeConditionConf.Insert(false);
                end else begin
                    ToQltyIGradeConditionConf.FindFirst();
                    ToQltyIGradeConditionConf.Condition := FromQltyIGradeConditionConf.Condition;
                    ToQltyIGradeConditionConf."Condition Description" := FromQltyIGradeConditionConf."Condition Description";
                    ToQltyIGradeConditionConf.Modify(false);
                end;
            until FromQltyIGradeConditionConf.Next() = 0;
    end;

    /// <summary>
    /// Copy grade conditions from a template to an inspection.
    /// </summary>
    /// <param name="QltyInspectionTemplateLine"></param>
    /// <param name="QltyInspectionLine"></param>
    procedure CopyGradeConditionsFromTemplateToInspection(QltyInspectionTemplateLine: Record "Qlty. Inspection Template Line"; QltyInspectionLine: Record "Qlty. Inspection Line")
    var
        FromTemplateQltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
        ToCheckQltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
        QltyField: Record "Qlty. Field";
    begin
        if QltyInspectionTemplateLine."Field Code" = '' then
            exit;

        FromTemplateQltyIGradeConditionConf.SetRange("Condition Type", FromTemplateQltyIGradeConditionConf."Condition Type"::Template);
        FromTemplateQltyIGradeConditionConf.SetRange("Target Code", QltyInspectionTemplateLine."Template Code");
        FromTemplateQltyIGradeConditionConf.SetRange("Target Line No.", QltyInspectionTemplateLine."Line No.");
        FromTemplateQltyIGradeConditionConf.SetRange("Field Code", QltyInspectionTemplateLine."Field Code");
        if not QltyField.Get(QltyInspectionTemplateLine."Field Code") then
            exit;
        if QltyField."Field Type" in [QltyField."Field Type"::"Field Type Label"] then
            exit;

        if not FromTemplateQltyIGradeConditionConf.FindSet() then begin
            FromTemplateQltyIGradeConditionConf.Reset();
            FromTemplateQltyIGradeConditionConf.SetRange("Condition Type", FromTemplateQltyIGradeConditionConf."Condition Type"::Field);
            FromTemplateQltyIGradeConditionConf.SetRange("Field Code", QltyInspectionTemplateLine."Field Code");
            if not FromTemplateQltyIGradeConditionConf.FindSet() then
                exit;
        end;
        repeat
            Clear(ToCheckQltyIGradeConditionConf);
            ToCheckQltyIGradeConditionConf.Init();
            ToCheckQltyIGradeConditionConf := FromTemplateQltyIGradeConditionConf;
            ToCheckQltyIGradeConditionConf."Condition Type" := ToCheckQltyIGradeConditionConf."Condition Type"::Inspection;
            ToCheckQltyIGradeConditionConf."Target Code" := QltyInspectionLine."Inspection No.";
            ToCheckQltyIGradeConditionConf."Target Reinspection No." := QltyInspectionLine."Reinspection No.";
            ToCheckQltyIGradeConditionConf."Target Line No." := QltyInspectionLine."Line No.";
            ToCheckQltyIGradeConditionConf.SetRecFilter();
            if not ToCheckQltyIGradeConditionConf.FindFirst() then begin
                ToCheckQltyIGradeConditionConf.TransferFields(FromTemplateQltyIGradeConditionConf, false);
                ToCheckQltyIGradeConditionConf.Insert();
            end else begin
                ToCheckQltyIGradeConditionConf.TransferFields(FromTemplateQltyIGradeConditionConf, false);
                ToCheckQltyIGradeConditionConf.Modify();
            end;

        until FromTemplateQltyIGradeConditionConf.Next() = 0;
    end;

    /// <summary>
    /// Copies the default grade conditions into the specified field.
    /// </summary>
    /// <param name="FieldCode"></param>
    procedure CopyGradeConditionsFromDefaultToField(FieldCode: Code[20])
    var
        QltyField: Record "Qlty. Field";
    begin
        if FieldCode = '' then
            exit;

        if not QltyField.Get(FieldCode) then
            exit;

        CopyGradeConditionsFromDefaultToField(FieldCode, QltyField."Field Type");
    end;

    internal procedure CopyGradeConditionsFromDefaultToField(FieldCode: Code[20]; SpecificQltyFieldType: Enum "Qlty. Field Type")
    begin
        if FieldCode = '' then
            exit;

        InternalCopyGradeConditionsFromDefaultToFieldSpecificType(FieldCode, '', false, true, SpecificQltyFieldType);
    end;

    local procedure OverwriteExistingFieldConditionsWithGradeCondition(GradeCode: Code[20])
    var
        ExistingQltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
    begin
        ExistingQltyIGradeConditionConf.SetRange("Grade Code", GradeCode);
        ExistingQltyIGradeConditionConf.SetRange("Condition Type", ExistingQltyIGradeConditionConf."Condition Type"::Field);
        if ExistingQltyIGradeConditionConf.FindSet() then
            repeat
                InternalCopyGradeConditionsFromDefaultToField(ExistingQltyIGradeConditionConf."Field Code", GradeCode, true, false);
            until ExistingQltyIGradeConditionConf.Next() = 0;
    end;

    local procedure InternalCopyGradeConditionsFromDefaultToField(FieldCode: Code[20]; OptionalSpecificGradeCode: Code[20]; AlwaysUpdateExistingCondition: Boolean; OnlyOverwriteIfADefaultCondition: Boolean)
    var
        QltyField: Record "Qlty. Field";
    begin
        if not QltyField.Get(FieldCode) then
            exit;

        InternalCopyGradeConditionsFromDefaultToFieldSpecificType(FieldCode, OptionalSpecificGradeCode, AlwaysUpdateExistingCondition, OnlyOverwriteIfADefaultCondition, QltyField."Field Type");
    end;

    local procedure InternalCopyGradeConditionsFromDefaultToFieldSpecificType(FieldCode: Code[20]; OptionalSpecificGradeCode: Code[20]; AlwaysUpdateExistingCondition: Boolean; OnlyOverwriteIfADefaultCondition: Boolean; SpecificQltyFieldType: Enum "Qlty. Field Type")
    var
        QltyField: Record "Qlty. Field";
        QltyInspectionGrade: Record "Qlty. Inspection Grade";
        ToFieldQltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
        Condition: Text;
    begin
        if not QltyField.Get(FieldCode) then
            exit;

        if OptionalSpecificGradeCode <> '' then
            QltyInspectionGrade.SetRange(Code, OptionalSpecificGradeCode);
        QltyInspectionGrade.SetRange("Copy Behavior", QltyInspectionGrade."Copy Behavior"::"Automatically copy the grade");
        if QltyInspectionGrade.FindSet() then
            repeat
                QltyField."Field Type" := SpecificQltyFieldType;
                case true of
                    QltyField.IsNumericFieldType():
                        Condition := QltyInspectionGrade."Default Number Condition";
                    QltyField."Field Type" = QltyField."Field Type"::"Field Type Boolean":
                        Condition := QltyInspectionGrade."Default Boolean Condition";
                    QltyField."Field Type" = QltyField."Field Type"::"Field Type Label":
                        Condition := '';
                    else
                        Condition := QltyInspectionGrade."Default Text Condition";
                end;
                ToFieldQltyIGradeConditionConf.Reset();
                ToFieldQltyIGradeConditionConf.SetRange("Condition Type", ToFieldQltyIGradeConditionConf."Condition Type"::Field);
                ToFieldQltyIGradeConditionConf.SetRange("Target Code", FieldCode);
                ToFieldQltyIGradeConditionConf.SetRange("Field Code", FieldCode);
                ToFieldQltyIGradeConditionConf.SetRange("Grade Code", QltyInspectionGrade.Code);
                if not ToFieldQltyIGradeConditionConf.FindFirst() then begin
                    ToFieldQltyIGradeConditionConf."Grade Code" := QltyInspectionGrade.Code;
                    ToFieldQltyIGradeConditionConf."Condition Type" := ToFieldQltyIGradeConditionConf."Condition Type"::Field;
                    ToFieldQltyIGradeConditionConf."Target Code" := FieldCode;
                    ToFieldQltyIGradeConditionConf."Field Code" := FieldCode;
                    ToFieldQltyIGradeConditionConf.Condition := CopyStr(Condition, 1, MaxStrLen(ToFieldQltyIGradeConditionConf.Condition));
                    ToFieldQltyIGradeConditionConf.Priority := QltyInspectionGrade."Evaluation Sequence";
                    ToFieldQltyIGradeConditionConf."Grade Visibility" := QltyInspectionGrade."Grade Visibility";
                    ToFieldQltyIGradeConditionConf."Condition Description" := CopyStr(Condition, 1, MaxStrLen(ToFieldQltyIGradeConditionConf."Condition Description"));
                    ToFieldQltyIGradeConditionConf.Insert();
                end else
                    if AlwaysUpdateExistingCondition or (OnlyOverwriteIfADefaultCondition and (ToFieldQltyIGradeConditionConf.Condition in [QltyInspectionGrade."Default Boolean Condition", QltyInspectionGrade."Default Number Condition", QltyInspectionGrade."Default Text Condition"])) then begin
                        ToFieldQltyIGradeConditionConf.Validate(Condition, CopyStr(Condition, 1, MaxStrLen(ToFieldQltyIGradeConditionConf.Condition)));
                        ToFieldQltyIGradeConditionConf."Condition Description" := CopyStr(Condition, 1, MaxStrLen(ToFieldQltyIGradeConditionConf."Condition Description"));
                        ToFieldQltyIGradeConditionConf.Priority := QltyInspectionGrade."Evaluation Sequence";
                        ToFieldQltyIGradeConditionConf."Grade Visibility" := QltyInspectionGrade."Grade Visibility";
                        ToFieldQltyIGradeConditionConf.Modify();
                    end;
            until QltyInspectionGrade.Next() = 0;
    end;

    /// <summary>
    /// Returns the promoted grades for a field
    /// </summary>
    /// <param name="QltyField"></param>
    /// <param name="MatrixArrayToSetConditionCellData"></param>
    /// <param name="MatrixArrayToSetCaptionSet"></param>
    /// <param name="MatrixVisibleStateToSet"></param>

    procedure GetPromotedGradesForField(QltyField: Record "Qlty. Field";
        var MatrixSourceRecordId: array[10] of RecordId;
        var MatrixArrayToSetConditionCellData: array[10] of Text;
        var MatrixArrayToSetConditionDescriptionCellData: array[10] of Text;
        var MatrixArrayToSetCaptionSet: array[10] of Text;
        var MatrixVisibleStateToSet: array[10] of Boolean)
    var
        QltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
    begin
        QltyIGradeConditionConf.SetRange("Condition Type", QltyIGradeConditionConf."Condition Type"::Field);
        QltyIGradeConditionConf.SetRange("Target Code", QltyField.Code);
        QltyIGradeConditionConf.SetRange("Field Code", QltyField.Code);
        if QltyIGradeConditionConf.IsEmpty() then
            CopyGradeConditionsFromDefaultToField(QltyField.Code);

        GetPromotedGrades(QltyIGradeConditionConf, MatrixSourceRecordId, MatrixArrayToSetConditionCellData, MatrixArrayToSetConditionDescriptionCellData, MatrixArrayToSetCaptionSet, MatrixVisibleStateToSet);
    end;

    /// <summary>
    /// Sets the promoted grades for the template line. If the template line is being initialized then
    /// it will return the default promoted grades with the default number condition for the grades.
    /// </summary>
    /// <param name="QltyInspectionTemplateLine"></param>
    /// <param name="MatrixArraySourceRecordId"></param>
    /// <param name="MatrixArrayToSetConditionCellData"></param>
    /// <param name="MatrixArrayToSetConditionDescriptionCellData"></param>
    /// <param name="MatrixArrayToSetCaptionSet"></param>
    /// <param name="MatrixVisibleStateToSet"></param>
    procedure GetPromotedGradesForTemplateLine(QltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        var MatrixArraySourceRecordId: array[10] of RecordId;
        var MatrixArrayToSetConditionCellData: array[10] of Text;
        var MatrixArrayToSetConditionDescriptionCellData: array[10] of Text;
        var MatrixArrayToSetCaptionSet: array[10] of Text;
        var MatrixVisibleStateToSet: array[10] of Boolean)
    var
        QltyField: Record "Qlty. Field";
        QltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
    begin
        Clear(MatrixArraySourceRecordId);
        Clear(MatrixArrayToSetConditionCellData);
        Clear(MatrixArrayToSetConditionDescriptionCellData);
        Clear(MatrixArrayToSetCaptionSet);
        Clear(MatrixVisibleStateToSet);

        if QltyInspectionTemplateLine."Field Code" <> '' then begin
            QltyIGradeConditionConf.SetRange("Condition Type", QltyIGradeConditionConf."Condition Type"::Template);
            QltyIGradeConditionConf.SetRange("Target Code", QltyInspectionTemplateLine."Template Code");
            QltyIGradeConditionConf.SetRange("Target Line No.", QltyInspectionTemplateLine."Line No.");
            QltyIGradeConditionConf.SetRange("Field Code", QltyInspectionTemplateLine."Field Code");
            if QltyIGradeConditionConf.IsEmpty() then begin
                if not QltyField.Get(QltyInspectionTemplateLine."Field Code") then
                    exit;
                if not (QltyField."Field Type" in [QltyField."Field Type"::"Field Type Label"]) then
                    CopyGradeConditionsFromFieldToTemplateLine(QltyInspectionTemplateLine."Template Code", QltyInspectionTemplateLine."Line No.", '', false);
            end;
            GetPromotedGrades(QltyIGradeConditionConf, MatrixArraySourceRecordId, MatrixArrayToSetConditionCellData, MatrixArrayToSetConditionDescriptionCellData, MatrixArrayToSetCaptionSet, MatrixVisibleStateToSet);
        end else
            GetDefaultPromotedGrades(false, MatrixArraySourceRecordId, MatrixArrayToSetConditionCellData, MatrixArrayToSetConditionDescriptionCellData, MatrixArrayToSetCaptionSet, MatrixVisibleStateToSet);
    end;

    /// <summary>
    /// Gets the default promoted grades in general regardless of what is configured
    /// for a specific field or a given field on a template (specification)
    /// This can be used to help determine the overall promoted grades in the system.
    /// </summary>
    /// <param name="AllPromoted">If true this will return all promoted fields. If false, only those with autocopy.</param>
    /// <param name="MatrixArraySourceRecordId"></param>
    /// <param name="MatrixArrayToSetConditionCellData"></param>
    /// <param name="MatrixArrayToSetConditionDescriptionCellData"></param>
    /// <param name="MatrixArrayToSetCaptionSet"></param>
    /// <param name="MatrixVisibleStateToSet"></param>
    procedure GetDefaultPromotedGrades(
        AllPromoted: Boolean;
        var MatrixArraySourceRecordId: array[10] of RecordId;
        var MatrixArrayToSetConditionCellData: array[10] of Text;
        var MatrixArrayToSetConditionDescriptionCellData: array[10] of Text;
        var MatrixArrayToSetCaptionSet: array[10] of Text;
        var MatrixVisibleStateToSet: array[10] of Boolean)
    var
        QltyInspectionGrade: Record "Qlty. Inspection Grade";
        Iterator: Integer;
    begin
        Clear(MatrixArraySourceRecordId);
        Clear(MatrixArrayToSetConditionCellData);
        Clear(MatrixArrayToSetConditionDescriptionCellData);
        Clear(MatrixArrayToSetCaptionSet);
        Clear(MatrixVisibleStateToSet);
        QltyInspectionGrade.SetRange("Grade Visibility", QltyInspectionGrade."Grade Visibility"::Promoted);
        if not AllPromoted then
            QltyInspectionGrade.SetRange("Copy Behavior", QltyInspectionGrade."Copy Behavior"::"Automatically copy the grade");
        QltyInspectionGrade.SetCurrentKey("Evaluation Sequence");
        QltyInspectionGrade.Ascending();
        if QltyInspectionGrade.FindSet() then begin
            Iterator := 0;
            repeat
                Iterator += 1;
                MatrixVisibleStateToSet[Iterator] := true;
                if QltyInspectionGrade.Description <> '' then
                    MatrixArrayToSetCaptionSet[Iterator] := QltyInspectionGrade.Description
                else
                    MatrixArrayToSetCaptionSet[Iterator] := QltyInspectionGrade.Code;
                MatrixArrayToSetConditionCellData[Iterator] := QltyInspectionGrade."Default Number Condition";
                MatrixArrayToSetConditionDescriptionCellData[Iterator] := QltyInspectionGrade."Default Number Condition";
                if MatrixArrayToSetConditionDescriptionCellData[Iterator] = '' then
                    MatrixArrayToSetConditionDescriptionCellData[Iterator] := MatrixArrayToSetConditionCellData[Iterator];

                MatrixArraySourceRecordId[Iterator] := QltyInspectionGrade.RecordId();
            until (QltyInspectionGrade.Next() = 0) or (Iterator >= 10);
        end;
    end;

    procedure GetPromotedGradesForInspectionLine(QltyInspectionLine: Record "Qlty. Inspection Line"; var MatrixSourceRecordId: array[10] of RecordId; var MatrixArrayToSetConditionCellData: array[10] of Text; var MatrixArrayToSetConditionDescriptionCellData: array[10] of Text; var MatrixArrayToSetCaptionSet: array[10] of Text; var MatrixVisibleStateToSet: array[10] of Boolean)
    var
        QltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        QltyField: Record "Qlty. Field";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
    begin
        Clear(MatrixArrayToSetConditionCellData);
        Clear(MatrixArrayToSetConditionDescriptionCellData);
        Clear(MatrixArrayToSetCaptionSet);
        Clear(MatrixVisibleStateToSet);

        if QltyInspectionHeader.Get(QltyInspectionLine."Inspection No.", QltyInspectionLine."Reinspection No.") then;

        if QltyField.Get(QltyInspectionLine."Field Code") then;
        if not (QltyField."Field Type" in [QltyField."Field Type"::"Field Type Label"]) then
            if not QltyInspectionTemplateLine.Get(QltyInspectionLine."Template Code", QltyInspectionLine."Template Line No.") then begin
                QltyInspectionTemplateLine.SetRange("Template Code", QltyInspectionLine."Template Code");
                QltyInspectionTemplateLine.SetRange("Field Code", QltyInspectionLine."Field Code");
                if not QltyInspectionTemplateLine.FindFirst() then
                    exit;
            end;

        QltyIGradeConditionConf.SetRange("Condition Type", QltyIGradeConditionConf."Condition Type"::Inspection);
        QltyIGradeConditionConf.SetRange("Target Code", QltyInspectionLine."Inspection No.");
        QltyIGradeConditionConf.SetRange("Target Reinspection No.", QltyInspectionLine."Reinspection No.");
        QltyIGradeConditionConf.SetRange("Target Line No.", QltyInspectionLine."Line No.");
        QltyIGradeConditionConf.SetRange("Field Code", QltyInspectionLine."Field Code");
        if QltyIGradeConditionConf.IsEmpty() then
            CopyGradeConditionsFromTemplateToInspection(QltyInspectionTemplateLine, QltyInspectionLine);

        GetPromotedGrades(QltyIGradeConditionConf, MatrixSourceRecordId, MatrixArrayToSetConditionCellData, MatrixArrayToSetConditionDescriptionCellData, MatrixArrayToSetCaptionSet, MatrixVisibleStateToSet, QltyInspectionHeader, QltyInspectionLine);
    end;

    local procedure GetPromotedGrades(var QltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf."; var MatrixSourceRecordId: array[10] of RecordId; var MatrixArrayToSetConditionCellData: array[10] of Text; var MatrixArrayToSetConditionDescriptionCellData: array[10] of Text; var MatrixArrayToSetCaptionSet: array[10] of Text; var MatrixVisibleStateToSet: array[10] of Boolean)
    var
        TempNotUsedOptionalQltyInspectionHeader: Record "Qlty. Inspection Header" temporary;
        TempNotUsedOptionalQltyInspectionLine: Record "Qlty. Inspection Line" temporary;
    begin
        GetPromotedGrades(
            QltyIGradeConditionConf,
            MatrixSourceRecordId,
            MatrixArrayToSetConditionCellData,
            MatrixArrayToSetConditionDescriptionCellData,
            MatrixArrayToSetCaptionSet,
            MatrixVisibleStateToSet,
            TempNotUsedOptionalQltyInspectionHeader,
            TempNotUsedOptionalQltyInspectionLine);
    end;

    local procedure GetPromotedGrades(
        var QltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
        var MatrixSourceRecordId: array[10] of RecordId;
        var MatrixArrayToSetConditionCellData: array[10] of Text;
        var MatrixArrayToSetConditionDescriptionCellData: array[10] of Text;
        var MatrixArrayToSetCaptionSet: array[10] of Text;
        var MatrixVisibleStateToSet: array[10] of Boolean;
        var OptionalQltyInspectionHeader: Record "Qlty. Inspection Header";
        var OptionalQltyInspectionLine: Record "Qlty. Inspection Line")
    var
        QltyInspectionGrade: Record "Qlty. Inspection Grade";
        QltyExpressionMgmt: Codeunit "Qlty. Expression Mgmt.";
        Iterator: Integer;
    begin
        Clear(MatrixArrayToSetConditionCellData);
        Clear(MatrixArrayToSetConditionDescriptionCellData);
        Clear(MatrixArrayToSetCaptionSet);
        Clear(MatrixVisibleStateToSet);
        QltyIGradeConditionConf.SetRange("Grade Visibility", QltyIGradeConditionConf."Grade Visibility"::Promoted);
        QltyIGradeConditionConf.SetCurrentKey("Condition Type", "Grade Visibility", Priority, "Target Code", "Target Reinspection No.", "Target Line No.");
        QltyIGradeConditionConf.Ascending(false);
        if QltyIGradeConditionConf.FindSet() then
            repeat
                if QltyInspectionGrade.Get(QltyIGradeConditionConf."Grade Code") then begin
                    Iterator += 1;
                    if Iterator <= 10 then begin
                        MatrixVisibleStateToSet[Iterator] := true;
                        if QltyInspectionGrade.Description <> '' then
                            MatrixArrayToSetCaptionSet[Iterator] := QltyInspectionGrade.Description
                        else
                            MatrixArrayToSetCaptionSet[Iterator] := QltyInspectionGrade.Code;
                        MatrixArrayToSetConditionCellData[Iterator] := QltyIGradeConditionConf.Condition;
                        MatrixArrayToSetConditionDescriptionCellData[Iterator] := QltyIGradeConditionConf."Condition Description";
                        if MatrixArrayToSetConditionDescriptionCellData[Iterator] = '' then
                            MatrixArrayToSetConditionDescriptionCellData[Iterator] := MatrixArrayToSetConditionCellData[Iterator];

                        if (not OptionalQltyInspectionHeader.IsTemporary()) and (OptionalQltyInspectionHeader."No." <> '') then
                            if MatrixArrayToSetConditionDescriptionCellData[Iterator].Contains('[') then
                                MatrixArrayToSetConditionDescriptionCellData[Iterator] := QltyExpressionMgmt.EvaluateTextExpression(MatrixArrayToSetConditionDescriptionCellData[Iterator], OptionalQltyInspectionHeader, OptionalQltyInspectionLine);

                        MatrixSourceRecordId[Iterator] := QltyIGradeConditionConf.RecordId();
                    end else
                        break;
                end;
            until (QltyIGradeConditionConf.Next() = 0) or (Iterator >= 10);
    end;
}
