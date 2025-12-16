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
/// Used to copy result conditions from fields to templates, templates to inspections
/// </summary>
codeunit 20409 "Qlty. Result Condition Mgmt."
{
    var
        ChangedFieldConditionsUpdateTemplatesQst: Label 'You have changed default conditions on the field %2, there are %1 template lines with earlier conditions for this result. Do you want to update the templates?', Comment = '%1=the amount of template lines that have other conditions, %2=the field name';
        ChangedResultConditionsUpdateDefaultsOnFieldsQst: Label 'You have changed default conditions on the result %1, there are %2 fields with earlier conditions for this result. Do you want to update these fields?', Comment = '%1=the amount of fields that have other conditions, %2=the result name';

    /// <summary>
    /// Prompts if templates should be updated.
    /// </summary>
    /// <param name="CopyFromQltyIResultConditConf"></param>
    internal procedure PromptUpdateTemplatesFromFieldsIfApplicable(CopyFromQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.")
    var
        CountsQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        CopyToQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        Continue: Boolean;
    begin
        CountsQltyInspectionTemplateLine.SetRange("Field Code", CopyFromQltyIResultConditConf."Field Code");

        CopyToQltyIResultConditConf.SetRange("Condition Type", CopyToQltyIResultConditConf."Condition Type"::Template);
        CopyToQltyIResultConditConf.SetRange("Field Code", CopyFromQltyIResultConditConf."Field Code");
        if CopyFromQltyIResultConditConf."Result Code" <> '' then
            CopyToQltyIResultConditConf.SetRange("Result Code", CopyFromQltyIResultConditConf."Result Code");
        CopyToQltyIResultConditConf.SetFilter(Condition, '<>%1', CopyFromQltyIResultConditConf.Condition);
        if CopyToQltyIResultConditConf.IsEmpty() then begin
            CopyToQltyIResultConditConf.SetRange(Condition);
            CopyToQltyIResultConditConf.SetFilter("Condition Description", '<>%1', CopyFromQltyIResultConditConf."Condition Description");
        end;
        if not CopyToQltyIResultConditConf.IsEmpty() then begin
            if not GuiAllowed() then
                Continue := true
            else
                Continue := Confirm(StrSubstNo(ChangedFieldConditionsUpdateTemplatesQst, CountsQltyInspectionTemplateLine.Count(), CopyFromQltyIResultConditConf."Field Code"));
            if Continue then begin
                CopyToQltyIResultConditConf.FindSet(true);
                repeat
                    CopyResultConditionsFromFieldToTemplateLine(
                        CopyToQltyIResultConditConf."Target Code",
                        CopyToQltyIResultConditConf."Target Line No.",
                        CopyFromQltyIResultConditConf."Result Code",
                        true,
                        CopyFromQltyIResultConditConf.Condition,
                        CopyFromQltyIResultConditConf."Condition Description");
                until CopyToQltyIResultConditConf.Next() = 0;
            end;
        end;
    end;

    internal procedure PromptUpdateFieldsFromResultIfApplicable(ResultCode: Code[20])
    var
        ExistingQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        Continue: Boolean;
    begin
        ExistingQltyIResultConditConf.SetRange("Result Code", ResultCode);
        ExistingQltyIResultConditConf.SetRange("Condition Type", ExistingQltyIResultConditConf."Condition Type"::Field);
        if not ExistingQltyIResultConditConf.IsEmpty() then begin
            if not GuiAllowed() then
                Continue := true
            else
                Continue := Confirm(StrSubstNo(ChangedResultConditionsUpdateDefaultsOnFieldsQst, ResultCode, ExistingQltyIResultConditConf.Count()));
            if Continue then
                OverwriteExistingFieldConditionsWithResultCondition(ResultCode);
        end;
    end;

    /// <summary>
    /// Used to copy result conditions from the default configuration to the template line.
    /// </summary>
    /// <param name="Template">The template</param>
    /// <param name="LineNo">The template line</param>
    /// <param name="OptionalSpecificResult">Leave empty to copy all applicable results</param>
    procedure CopyResultConditionsFromFieldToTemplateLine(Template: Code[20]; LineNo: Integer; OptionalSpecificResult: Code[20]; OverwriteConditionIfExisting: Boolean)
    begin
        CopyResultConditionsFromFieldToTemplateLine(Template, LineNo, OptionalSpecificResult, OverwriteConditionIfExisting, '', '');
    end;

    local procedure CopyResultConditionsFromFieldToTemplateLine(Template: Code[20]; LineNo: Integer; OptionalSpecificResult: Code[20]; OverwriteConditionIfExisting: Boolean; OptionalSpecificCondition: Text; OptionalSpecificConditionDescription: Text)
    var
        QltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        QltyInspectionResult: Record "Qlty. Inspection Result";
        QltyField: Record "Qlty. Field";
        CopyFromQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        CopyToQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
    begin
        case true of
            not QltyInspectionTemplateLine.Get(Template, LineNo),
            not QltyField.Get(QltyInspectionTemplateLine."Field Code"),
            QltyField."Field Type" in [QltyField."Field Type"::"Field Type Label"]:
                exit;
        end;

        CopyFromQltyIResultConditConf.SetRange("Condition Type", CopyFromQltyIResultConditConf."Condition Type"::Field);
        CopyFromQltyIResultConditConf.SetRange("Field Code", QltyInspectionTemplateLine."Field Code");
        if OptionalSpecificResult <> '' then
            CopyFromQltyIResultConditConf.SetRange("Result Code", OptionalSpecificResult);

        if CopyFromQltyIResultConditConf.IsEmpty() then
            CopyResultConditionsFromDefaultToField(QltyInspectionTemplateLine."Field Code");

        if CopyFromQltyIResultConditConf.FindSet() then
            repeat
                if QltyInspectionResult.Get(CopyFromQltyIResultConditConf."Result Code") then
                    if QltyInspectionResult."Copy Behavior" = QltyInspectionResult."Copy Behavior"::"Automatically copy the result" then begin
                        CopyToQltyIResultConditConf.Reset();
                        CopyToQltyIResultConditConf := CopyFromQltyIResultConditConf;
                        CopyToQltyIResultConditConf."Condition Type" := CopyToQltyIResultConditConf."Condition Type"::Template;
                        CopyToQltyIResultConditConf."Target Code" := Template;
                        CopyToQltyIResultConditConf."Target Line No." := LineNo;
                        CopyToQltyIResultConditConf.Priority := QltyInspectionResult."Evaluation Sequence";
                        CopyToQltyIResultConditConf."Result Visibility" := QltyInspectionResult."Result Visibility";
                        CopyToQltyIResultConditConf.SetRecFilter();

                        if not CopyToQltyIResultConditConf.FindFirst() then begin
                            CopyToQltyIResultConditConf.TransferFields(CopyFromQltyIResultConditConf, false);
                            if OptionalSpecificCondition <> '' then
                                CopyToQltyIResultConditConf.Condition := CopyStr(OptionalSpecificCondition, 1, MaxStrLen(CopyToQltyIResultConditConf.Condition));
                            if OptionalSpecificConditionDescription <> '' then
                                CopyToQltyIResultConditConf."Condition Description" := CopyStr(OptionalSpecificConditionDescription, 1, MaxStrLen(CopyToQltyIResultConditConf."Condition Description"));
                            CopyToQltyIResultConditConf.Insert()
                        end else begin
                            if OverwriteConditionIfExisting then
                                CopyToQltyIResultConditConf.TransferFields(CopyFromQltyIResultConditConf, false)
                            else begin
                                CopyToQltyIResultConditConf.Priority := QltyInspectionResult."Evaluation Sequence";
                                CopyToQltyIResultConditConf."Result Visibility" := QltyInspectionResult."Result Visibility";
                            end;
                            if OptionalSpecificCondition <> '' then
                                CopyToQltyIResultConditConf.Condition := CopyStr(OptionalSpecificCondition, 1, MaxStrLen(CopyToQltyIResultConditConf.Condition));
                            if OptionalSpecificConditionDescription <> '' then
                                CopyToQltyIResultConditConf."Condition Description" := CopyStr(OptionalSpecificConditionDescription, 1, MaxStrLen(CopyToQltyIResultConditConf."Condition Description"));

                            CopyToQltyIResultConditConf.Modify();
                        end;
                    end;

            until CopyFromQltyIResultConditConf.Next() = 0;
    end;

    /// <summary>
    /// Used for cloning templates.
    /// </summary>
    /// <param name="FromQltyInspectionTemplateLine"></param>
    /// <param name="TargetQltyInspectionTemplateLine"></param>
    procedure CopyResultConditionsFromTemplateLineToTemplateLine(FromQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line"; TargetQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line")
    var
        FromQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        ToQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
    begin
        FromQltyIResultConditConf.SetRange("Condition Type", FromQltyIResultConditConf."Condition Type"::Template);
        FromQltyIResultConditConf.SetRange("Target Code", FromQltyInspectionTemplateLine."Template Code");
        FromQltyIResultConditConf.SetRange("Target Line No.", FromQltyInspectionTemplateLine."Line No.");
        FromQltyIResultConditConf.SetRange("Field Code", FromQltyInspectionTemplateLine."Field Code");
        if FromQltyIResultConditConf.FindSet() then
            repeat
                Clear(ToQltyIResultConditConf);
                ToQltyIResultConditConf.Reset();
                ToQltyIResultConditConf := FromQltyIResultConditConf;
                ToQltyIResultConditConf.SetRecFilter();
                ToQltyIResultConditConf.SetRange("Target Code", TargetQltyInspectionTemplateLine."Template Code");
                ToQltyIResultConditConf.SetRange("Field Code", TargetQltyInspectionTemplateLine."Field Code");
                ToQltyIResultConditConf.SetRange("Target Line No.", TargetQltyInspectionTemplateLine."Line No.");
                if ToQltyIResultConditConf.IsEmpty() then begin
                    Clear(ToQltyIResultConditConf);
                    ToQltyIResultConditConf.Init();
                    ToQltyIResultConditConf.TransferFields(FromQltyIResultConditConf, true);
                    ToQltyIResultConditConf."Target Code" := TargetQltyInspectionTemplateLine."Template Code";
                    ToQltyIResultConditConf."Target Line No." := TargetQltyInspectionTemplateLine."Line No.";
                    ToQltyIResultConditConf.Insert(false);
                end else begin
                    ToQltyIResultConditConf.FindFirst();
                    ToQltyIResultConditConf.Condition := FromQltyIResultConditConf.Condition;
                    ToQltyIResultConditConf."Condition Description" := FromQltyIResultConditConf."Condition Description";
                    ToQltyIResultConditConf.Modify(false);
                end;
            until FromQltyIResultConditConf.Next() = 0;
    end;

    /// <summary>
    /// Copy result conditions from a template to an inspection.
    /// </summary>
    /// <param name="QltyInspectionTemplateLine"></param>
    /// <param name="QltyInspectionLine"></param>
    procedure CopyResultConditionsFromTemplateToInspection(QltyInspectionTemplateLine: Record "Qlty. Inspection Template Line"; QltyInspectionLine: Record "Qlty. Inspection Line")
    var
        FromTemplateQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        ToCheckQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        QltyField: Record "Qlty. Field";
    begin
        if QltyInspectionTemplateLine."Field Code" = '' then
            exit;

        FromTemplateQltyIResultConditConf.SetRange("Condition Type", FromTemplateQltyIResultConditConf."Condition Type"::Template);
        FromTemplateQltyIResultConditConf.SetRange("Target Code", QltyInspectionTemplateLine."Template Code");
        FromTemplateQltyIResultConditConf.SetRange("Target Line No.", QltyInspectionTemplateLine."Line No.");
        FromTemplateQltyIResultConditConf.SetRange("Field Code", QltyInspectionTemplateLine."Field Code");
        if not QltyField.Get(QltyInspectionTemplateLine."Field Code") then
            exit;
        if QltyField."Field Type" in [QltyField."Field Type"::"Field Type Label"] then
            exit;

        if not FromTemplateQltyIResultConditConf.FindSet() then begin
            FromTemplateQltyIResultConditConf.Reset();
            FromTemplateQltyIResultConditConf.SetRange("Condition Type", FromTemplateQltyIResultConditConf."Condition Type"::Field);
            FromTemplateQltyIResultConditConf.SetRange("Field Code", QltyInspectionTemplateLine."Field Code");
            if not FromTemplateQltyIResultConditConf.FindSet() then
                exit;
        end;
        repeat
            Clear(ToCheckQltyIResultConditConf);
            ToCheckQltyIResultConditConf.Init();
            ToCheckQltyIResultConditConf := FromTemplateQltyIResultConditConf;
            ToCheckQltyIResultConditConf."Condition Type" := ToCheckQltyIResultConditConf."Condition Type"::Inspection;
            ToCheckQltyIResultConditConf."Target Code" := QltyInspectionLine."Inspection No.";
            ToCheckQltyIResultConditConf."Target Reinspection No." := QltyInspectionLine."Reinspection No.";
            ToCheckQltyIResultConditConf."Target Line No." := QltyInspectionLine."Line No.";
            ToCheckQltyIResultConditConf.SetRecFilter();
            if not ToCheckQltyIResultConditConf.FindFirst() then begin
                ToCheckQltyIResultConditConf.TransferFields(FromTemplateQltyIResultConditConf, false);
                ToCheckQltyIResultConditConf.Insert();
            end else begin
                ToCheckQltyIResultConditConf.TransferFields(FromTemplateQltyIResultConditConf, false);
                ToCheckQltyIResultConditConf.Modify();
            end;

        until FromTemplateQltyIResultConditConf.Next() = 0;
    end;

    /// <summary>
    /// Copies the default result conditions into the specified field.
    /// </summary>
    /// <param name="FieldCode"></param>
    procedure CopyResultConditionsFromDefaultToField(FieldCode: Code[20])
    var
        QltyField: Record "Qlty. Field";
    begin
        if FieldCode = '' then
            exit;

        if not QltyField.Get(FieldCode) then
            exit;

        CopyResultConditionsFromDefaultToField(FieldCode, QltyField."Field Type");
    end;

    internal procedure CopyResultConditionsFromDefaultToField(FieldCode: Code[20]; SpecificQltyFieldType: Enum "Qlty. Field Type")
    begin
        if FieldCode = '' then
            exit;

        InternalCopyResultConditionsFromDefaultToFieldSpecificType(FieldCode, '', false, true, SpecificQltyFieldType);
    end;

    local procedure OverwriteExistingFieldConditionsWithResultCondition(ResultCode: Code[20])
    var
        ExistingQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
    begin
        ExistingQltyIResultConditConf.SetRange("Result Code", ResultCode);
        ExistingQltyIResultConditConf.SetRange("Condition Type", ExistingQltyIResultConditConf."Condition Type"::Field);
        if ExistingQltyIResultConditConf.FindSet() then
            repeat
                InternalCopyResultConditionsFromDefaultToField(ExistingQltyIResultConditConf."Field Code", ResultCode, true, false);
            until ExistingQltyIResultConditConf.Next() = 0;
    end;

    local procedure InternalCopyResultConditionsFromDefaultToField(FieldCode: Code[20]; OptionalSpecificResultCode: Code[20]; AlwaysUpdateExistingCondition: Boolean; OnlyOverwriteIfADefaultCondition: Boolean)
    var
        QltyField: Record "Qlty. Field";
    begin
        if not QltyField.Get(FieldCode) then
            exit;

        InternalCopyResultConditionsFromDefaultToFieldSpecificType(FieldCode, OptionalSpecificResultCode, AlwaysUpdateExistingCondition, OnlyOverwriteIfADefaultCondition, QltyField."Field Type");
    end;

    local procedure InternalCopyResultConditionsFromDefaultToFieldSpecificType(FieldCode: Code[20]; OptionalSpecificResultCode: Code[20]; AlwaysUpdateExistingCondition: Boolean; OnlyOverwriteIfADefaultCondition: Boolean; SpecificQltyFieldType: Enum "Qlty. Field Type")
    var
        QltyField: Record "Qlty. Field";
        QltyInspectionResult: Record "Qlty. Inspection Result";
        ToFieldQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        Condition: Text;
    begin
        if not QltyField.Get(FieldCode) then
            exit;

        if OptionalSpecificResultCode <> '' then
            QltyInspectionResult.SetRange(Code, OptionalSpecificResultCode);
        QltyInspectionResult.SetRange("Copy Behavior", QltyInspectionResult."Copy Behavior"::"Automatically copy the result");
        if QltyInspectionResult.FindSet() then
            repeat
                QltyField."Field Type" := SpecificQltyFieldType;
                case true of
                    QltyField.IsNumericFieldType():
                        Condition := QltyInspectionResult."Default Number Condition";
                    QltyField."Field Type" = QltyField."Field Type"::"Field Type Boolean":
                        Condition := QltyInspectionResult."Default Boolean Condition";
                    QltyField."Field Type" = QltyField."Field Type"::"Field Type Label":
                        Condition := '';
                    else
                        Condition := QltyInspectionResult."Default Text Condition";
                end;
                ToFieldQltyIResultConditConf.Reset();
                ToFieldQltyIResultConditConf.SetRange("Condition Type", ToFieldQltyIResultConditConf."Condition Type"::Field);
                ToFieldQltyIResultConditConf.SetRange("Target Code", FieldCode);
                ToFieldQltyIResultConditConf.SetRange("Field Code", FieldCode);
                ToFieldQltyIResultConditConf.SetRange("Result Code", QltyInspectionResult.Code);
                if not ToFieldQltyIResultConditConf.FindFirst() then begin
                    ToFieldQltyIResultConditConf."Result Code" := QltyInspectionResult.Code;
                    ToFieldQltyIResultConditConf."Condition Type" := ToFieldQltyIResultConditConf."Condition Type"::Field;
                    ToFieldQltyIResultConditConf."Target Code" := FieldCode;
                    ToFieldQltyIResultConditConf."Field Code" := FieldCode;
                    ToFieldQltyIResultConditConf.Condition := CopyStr(Condition, 1, MaxStrLen(ToFieldQltyIResultConditConf.Condition));
                    ToFieldQltyIResultConditConf.Priority := QltyInspectionResult."Evaluation Sequence";
                    ToFieldQltyIResultConditConf."Result Visibility" := QltyInspectionResult."Result Visibility";
                    ToFieldQltyIResultConditConf."Condition Description" := CopyStr(Condition, 1, MaxStrLen(ToFieldQltyIResultConditConf."Condition Description"));
                    ToFieldQltyIResultConditConf.Insert();
                end else
                    if AlwaysUpdateExistingCondition or (OnlyOverwriteIfADefaultCondition and (ToFieldQltyIResultConditConf.Condition in [QltyInspectionResult."Default Boolean Condition", QltyInspectionResult."Default Number Condition", QltyInspectionResult."Default Text Condition"])) then begin
                        ToFieldQltyIResultConditConf.Validate(Condition, CopyStr(Condition, 1, MaxStrLen(ToFieldQltyIResultConditConf.Condition)));
                        ToFieldQltyIResultConditConf."Condition Description" := CopyStr(Condition, 1, MaxStrLen(ToFieldQltyIResultConditConf."Condition Description"));
                        ToFieldQltyIResultConditConf.Priority := QltyInspectionResult."Evaluation Sequence";
                        ToFieldQltyIResultConditConf."Result Visibility" := QltyInspectionResult."Result Visibility";
                        ToFieldQltyIResultConditConf.Modify();
                    end;
            until QltyInspectionResult.Next() = 0;
    end;

    /// <summary>
    /// Returns the promoted results for a field
    /// </summary>
    /// <param name="QltyField"></param>
    /// <param name="MatrixArrayToSetConditionCellData"></param>
    /// <param name="MatrixArrayToSetCaptionSet"></param>
    /// <param name="MatrixVisibleStateToSet"></param>

    procedure GetPromotedResultsForField(QltyField: Record "Qlty. Field";
        var MatrixSourceRecordId: array[10] of RecordId;
        var MatrixArrayToSetConditionCellData: array[10] of Text;
        var MatrixArrayToSetConditionDescriptionCellData: array[10] of Text;
        var MatrixArrayToSetCaptionSet: array[10] of Text;
        var MatrixVisibleStateToSet: array[10] of Boolean)
    var
        QltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
    begin
        QltyIResultConditConf.SetRange("Condition Type", QltyIResultConditConf."Condition Type"::Field);
        QltyIResultConditConf.SetRange("Target Code", QltyField.Code);
        QltyIResultConditConf.SetRange("Field Code", QltyField.Code);
        if QltyIResultConditConf.IsEmpty() then
            CopyResultConditionsFromDefaultToField(QltyField.Code);

        GetPromotedResults(QltyIResultConditConf, MatrixSourceRecordId, MatrixArrayToSetConditionCellData, MatrixArrayToSetConditionDescriptionCellData, MatrixArrayToSetCaptionSet, MatrixVisibleStateToSet);
    end;

    /// <summary>
    /// Sets the promoted results for the template line. If the template line is being initialized then
    /// it will return the default promoted results with the default number condition for the results.
    /// </summary>
    /// <param name="QltyInspectionTemplateLine"></param>
    /// <param name="MatrixArraySourceRecordId"></param>
    /// <param name="MatrixArrayToSetConditionCellData"></param>
    /// <param name="MatrixArrayToSetConditionDescriptionCellData"></param>
    /// <param name="MatrixArrayToSetCaptionSet"></param>
    /// <param name="MatrixVisibleStateToSet"></param>
    procedure GetPromotedResultsForTemplateLine(QltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        var MatrixArraySourceRecordId: array[10] of RecordId;
        var MatrixArrayToSetConditionCellData: array[10] of Text;
        var MatrixArrayToSetConditionDescriptionCellData: array[10] of Text;
        var MatrixArrayToSetCaptionSet: array[10] of Text;
        var MatrixVisibleStateToSet: array[10] of Boolean)
    var
        QltyField: Record "Qlty. Field";
        QltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
    begin
        Clear(MatrixArraySourceRecordId);
        Clear(MatrixArrayToSetConditionCellData);
        Clear(MatrixArrayToSetConditionDescriptionCellData);
        Clear(MatrixArrayToSetCaptionSet);
        Clear(MatrixVisibleStateToSet);

        if QltyInspectionTemplateLine."Field Code" <> '' then begin
            QltyIResultConditConf.SetRange("Condition Type", QltyIResultConditConf."Condition Type"::Template);
            QltyIResultConditConf.SetRange("Target Code", QltyInspectionTemplateLine."Template Code");
            QltyIResultConditConf.SetRange("Target Line No.", QltyInspectionTemplateLine."Line No.");
            QltyIResultConditConf.SetRange("Field Code", QltyInspectionTemplateLine."Field Code");
            if QltyIResultConditConf.IsEmpty() then begin
                if not QltyField.Get(QltyInspectionTemplateLine."Field Code") then
                    exit;
                if not (QltyField."Field Type" in [QltyField."Field Type"::"Field Type Label"]) then
                    CopyResultConditionsFromFieldToTemplateLine(QltyInspectionTemplateLine."Template Code", QltyInspectionTemplateLine."Line No.", '', false);
            end;
            GetPromotedResults(QltyIResultConditConf, MatrixArraySourceRecordId, MatrixArrayToSetConditionCellData, MatrixArrayToSetConditionDescriptionCellData, MatrixArrayToSetCaptionSet, MatrixVisibleStateToSet);
        end else
            GetDefaultPromotedResults(false, MatrixArraySourceRecordId, MatrixArrayToSetConditionCellData, MatrixArrayToSetConditionDescriptionCellData, MatrixArrayToSetCaptionSet, MatrixVisibleStateToSet);
    end;

    /// <summary>
    /// Gets the default promoted results in general regardless of what is configured
    /// for a specific field or a given field on a template (specification)
    /// This can be used to help determine the overall promoted results in the system.
    /// </summary>
    /// <param name="AllPromoted">If true this will return all promoted fields. If false, only those with autocopy.</param>
    /// <param name="MatrixArraySourceRecordId"></param>
    /// <param name="MatrixArrayToSetConditionCellData"></param>
    /// <param name="MatrixArrayToSetConditionDescriptionCellData"></param>
    /// <param name="MatrixArrayToSetCaptionSet"></param>
    /// <param name="MatrixVisibleStateToSet"></param>
    procedure GetDefaultPromotedResults(
        AllPromoted: Boolean;
        var MatrixArraySourceRecordId: array[10] of RecordId;
        var MatrixArrayToSetConditionCellData: array[10] of Text;
        var MatrixArrayToSetConditionDescriptionCellData: array[10] of Text;
        var MatrixArrayToSetCaptionSet: array[10] of Text;
        var MatrixVisibleStateToSet: array[10] of Boolean)
    var
        QltyInspectionResult: Record "Qlty. Inspection Result";
        Iterator: Integer;
    begin
        Clear(MatrixArraySourceRecordId);
        Clear(MatrixArrayToSetConditionCellData);
        Clear(MatrixArrayToSetConditionDescriptionCellData);
        Clear(MatrixArrayToSetCaptionSet);
        Clear(MatrixVisibleStateToSet);
        QltyInspectionResult.SetRange("Result Visibility", QltyInspectionResult."Result Visibility"::Promoted);
        if not AllPromoted then
            QltyInspectionResult.SetRange("Copy Behavior", QltyInspectionResult."Copy Behavior"::"Automatically copy the result");
        QltyInspectionResult.SetCurrentKey("Evaluation Sequence");
        QltyInspectionResult.Ascending();
        if QltyInspectionResult.FindSet() then begin
            Iterator := 0;
            repeat
                Iterator += 1;
                MatrixVisibleStateToSet[Iterator] := true;
                if QltyInspectionResult.Description <> '' then
                    MatrixArrayToSetCaptionSet[Iterator] := QltyInspectionResult.Description
                else
                    MatrixArrayToSetCaptionSet[Iterator] := QltyInspectionResult.Code;
                MatrixArrayToSetConditionCellData[Iterator] := QltyInspectionResult."Default Number Condition";
                MatrixArrayToSetConditionDescriptionCellData[Iterator] := QltyInspectionResult."Default Number Condition";
                if MatrixArrayToSetConditionDescriptionCellData[Iterator] = '' then
                    MatrixArrayToSetConditionDescriptionCellData[Iterator] := MatrixArrayToSetConditionCellData[Iterator];

                MatrixArraySourceRecordId[Iterator] := QltyInspectionResult.RecordId();
            until (QltyInspectionResult.Next() = 0) or (Iterator >= 10);
        end;
    end;

    procedure GetPromotedResultsForInspectionLine(QltyInspectionLine: Record "Qlty. Inspection Line"; var MatrixSourceRecordId: array[10] of RecordId; var MatrixArrayToSetConditionCellData: array[10] of Text; var MatrixArrayToSetConditionDescriptionCellData: array[10] of Text; var MatrixArrayToSetCaptionSet: array[10] of Text; var MatrixVisibleStateToSet: array[10] of Boolean)
    var
        QltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        QltyField: Record "Qlty. Field";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
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

        QltyIResultConditConf.SetRange("Condition Type", QltyIResultConditConf."Condition Type"::Inspection);
        QltyIResultConditConf.SetRange("Target Code", QltyInspectionLine."Inspection No.");
        QltyIResultConditConf.SetRange("Target Reinspection No.", QltyInspectionLine."Reinspection No.");
        QltyIResultConditConf.SetRange("Target Line No.", QltyInspectionLine."Line No.");
        QltyIResultConditConf.SetRange("Field Code", QltyInspectionLine."Field Code");
        if QltyIResultConditConf.IsEmpty() then
            CopyResultConditionsFromTemplateToInspection(QltyInspectionTemplateLine, QltyInspectionLine);

        GetPromotedResults(QltyIResultConditConf, MatrixSourceRecordId, MatrixArrayToSetConditionCellData, MatrixArrayToSetConditionDescriptionCellData, MatrixArrayToSetCaptionSet, MatrixVisibleStateToSet, QltyInspectionHeader, QltyInspectionLine);
    end;

    local procedure GetPromotedResults(var QltyIResultConditConf: Record "Qlty. I. Result Condit. Conf."; var MatrixSourceRecordId: array[10] of RecordId; var MatrixArrayToSetConditionCellData: array[10] of Text; var MatrixArrayToSetConditionDescriptionCellData: array[10] of Text; var MatrixArrayToSetCaptionSet: array[10] of Text; var MatrixVisibleStateToSet: array[10] of Boolean)
    var
        TempNotUsedOptionalQltyInspectionHeader: Record "Qlty. Inspection Header" temporary;
        TempNotUsedOptionalQltyInspectionLine: Record "Qlty. Inspection Line" temporary;
    begin
        GetPromotedResults(
            QltyIResultConditConf,
            MatrixSourceRecordId,
            MatrixArrayToSetConditionCellData,
            MatrixArrayToSetConditionDescriptionCellData,
            MatrixArrayToSetCaptionSet,
            MatrixVisibleStateToSet,
            TempNotUsedOptionalQltyInspectionHeader,
            TempNotUsedOptionalQltyInspectionLine);
    end;

    local procedure GetPromotedResults(
        var QltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        var MatrixSourceRecordId: array[10] of RecordId;
        var MatrixArrayToSetConditionCellData: array[10] of Text;
        var MatrixArrayToSetConditionDescriptionCellData: array[10] of Text;
        var MatrixArrayToSetCaptionSet: array[10] of Text;
        var MatrixVisibleStateToSet: array[10] of Boolean;
        var OptionalQltyInspectionHeader: Record "Qlty. Inspection Header";
        var OptionalQltyInspectionLine: Record "Qlty. Inspection Line")
    var
        QltyInspectionResult: Record "Qlty. Inspection Result";
        QltyExpressionMgmt: Codeunit "Qlty. Expression Mgmt.";
        Iterator: Integer;
    begin
        Clear(MatrixArrayToSetConditionCellData);
        Clear(MatrixArrayToSetConditionDescriptionCellData);
        Clear(MatrixArrayToSetCaptionSet);
        Clear(MatrixVisibleStateToSet);
        QltyIResultConditConf.SetRange("Result Visibility", QltyIResultConditConf."Result Visibility"::Promoted);
        QltyIResultConditConf.SetCurrentKey("Condition Type", "Result Visibility", Priority, "Target Code", "Target Reinspection No.", "Target Line No.");
        QltyIResultConditConf.Ascending(false);
        if QltyIResultConditConf.FindSet() then
            repeat
                if QltyInspectionResult.Get(QltyIResultConditConf."Result Code") then begin
                    Iterator += 1;
                    if Iterator <= 10 then begin
                        MatrixVisibleStateToSet[Iterator] := true;
                        if QltyInspectionResult.Description <> '' then
                            MatrixArrayToSetCaptionSet[Iterator] := QltyInspectionResult.Description
                        else
                            MatrixArrayToSetCaptionSet[Iterator] := QltyInspectionResult.Code;
                        MatrixArrayToSetConditionCellData[Iterator] := QltyIResultConditConf.Condition;
                        MatrixArrayToSetConditionDescriptionCellData[Iterator] := QltyIResultConditConf."Condition Description";
                        if MatrixArrayToSetConditionDescriptionCellData[Iterator] = '' then
                            MatrixArrayToSetConditionDescriptionCellData[Iterator] := MatrixArrayToSetConditionCellData[Iterator];

                        if (not OptionalQltyInspectionHeader.IsTemporary()) and (OptionalQltyInspectionHeader."No." <> '') then
                            if MatrixArrayToSetConditionDescriptionCellData[Iterator].Contains('[') then
                                MatrixArrayToSetConditionDescriptionCellData[Iterator] := QltyExpressionMgmt.EvaluateTextExpression(MatrixArrayToSetConditionDescriptionCellData[Iterator], OptionalQltyInspectionHeader, OptionalQltyInspectionLine);

                        MatrixSourceRecordId[Iterator] := QltyIResultConditConf.RecordId();
                    end else
                        break;
                end;
            until (QltyIResultConditConf.Next() = 0) or (Iterator >= 10);
    end;
}
