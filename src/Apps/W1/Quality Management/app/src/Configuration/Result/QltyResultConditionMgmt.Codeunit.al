// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Configuration.Result;

using Microsoft.QualityManagement.Configuration.Template;
using Microsoft.QualityManagement.Configuration.Template.Test;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Utilities;

/// <summary>
/// Used to copy result conditions from tests to templates, templates to inspections
/// </summary>
codeunit 20409 "Qlty. Result Condition Mgmt."
{
    var
        ChangedTestConditionsUpdateTemplatesQst: Label 'You have changed default conditions on the test %2, there are %1 template lines with earlier conditions for this result. Do you want to update the templates?', Comment = '%1=the amount of template lines that have other conditions, %2=the test name';
        ChangedResultConditionsUpdateDefaultsOnTestsQst: Label 'You have changed default conditions on the result %1, there are %2 tests with earlier conditions for this result. Do you want to update these tests?', Comment = '%1=the amount of tests that have other conditions, %2=the result name';

    /// <summary>
    /// Prompts if templates should be updated.
    /// </summary>
    /// <param name="CopyFromQltyIResultConditConf"></param>
    internal procedure PromptUpdateTemplatesFromTestsIfApplicable(CopyFromQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.")
    var
        CountsQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        CopyToQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        Continue: Boolean;
    begin
        CountsQltyInspectionTemplateLine.SetRange("Test Code", CopyFromQltyIResultConditConf."Test Code");

        CopyToQltyIResultConditConf.SetRange("Condition Type", CopyToQltyIResultConditConf."Condition Type"::Template);
        CopyToQltyIResultConditConf.SetRange("Test Code", CopyFromQltyIResultConditConf."Test Code");
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
                Continue := Confirm(StrSubstNo(ChangedTestConditionsUpdateTemplatesQst, CountsQltyInspectionTemplateLine.Count(), CopyFromQltyIResultConditConf."Test Code"));
            if Continue then begin
                CopyToQltyIResultConditConf.FindSet(true);
                repeat
                    CopyResultConditionsFromTestToTemplateLine(
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

    internal procedure PromptUpdateTestsFromResultIfApplicable(ResultCode: Code[20])
    var
        ExistingQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        Continue: Boolean;
    begin
        ExistingQltyIResultConditConf.SetRange("Result Code", ResultCode);
        ExistingQltyIResultConditConf.SetRange("Condition Type", ExistingQltyIResultConditConf."Condition Type"::Test);
        if not ExistingQltyIResultConditConf.IsEmpty() then begin
            if not GuiAllowed() then
                Continue := true
            else
                Continue := Confirm(StrSubstNo(ChangedResultConditionsUpdateDefaultsOnTestsQst, ResultCode, ExistingQltyIResultConditConf.Count()));
            if Continue then
                OverwriteExistingTestConditionsWithResultCondition(ResultCode);
        end;
    end;

    /// <summary>
    /// Used to copy result conditions from the default configuration to the template line.
    /// </summary>
    /// <param name="Template">The template</param>
    /// <param name="LineNo">The template line</param>
    /// <param name="OptionalSpecificResult">Leave empty to copy all applicable results</param>
    internal procedure CopyResultConditionsFromTestToTemplateLine(Template: Code[20]; LineNo: Integer; OptionalSpecificResult: Code[20]; OverwriteConditionIfExisting: Boolean)
    begin
        CopyResultConditionsFromTestToTemplateLine(Template, LineNo, OptionalSpecificResult, OverwriteConditionIfExisting, '', '');
    end;

    local procedure CopyResultConditionsFromTestToTemplateLine(Template: Code[20]; LineNo: Integer; OptionalSpecificResult: Code[20]; OverwriteConditionIfExisting: Boolean; OptionalSpecificCondition: Text; OptionalSpecificConditionDescription: Text)
    var
        QltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        QltyInspectionResult: Record "Qlty. Inspection Result";
        QltyTest: Record "Qlty. Test";
        CopyFromQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        CopyToQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
    begin
        case true of
            not QltyInspectionTemplateLine.Get(Template, LineNo),
            not QltyTest.Get(QltyInspectionTemplateLine."Test Code"),
            QltyTest."Test Value Type" in [QltyTest."Test Value Type"::"Value Type Label"]:
                exit;
        end;

        CopyFromQltyIResultConditConf.SetRange("Condition Type", CopyFromQltyIResultConditConf."Condition Type"::Test);
        CopyFromQltyIResultConditConf.SetRange("Test Code", QltyInspectionTemplateLine."Test Code");
        if OptionalSpecificResult <> '' then
            CopyFromQltyIResultConditConf.SetRange("Result Code", OptionalSpecificResult);

        if CopyFromQltyIResultConditConf.IsEmpty() then
            CopyResultConditionsFromDefaultToTest(QltyInspectionTemplateLine."Test Code");

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
    internal procedure CopyResultConditionsFromTemplateLineToTemplateLine(FromQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line"; TargetQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line")
    var
        FromQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        ToQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
    begin
        FromQltyIResultConditConf.SetRange("Condition Type", FromQltyIResultConditConf."Condition Type"::Template);
        FromQltyIResultConditConf.SetRange("Target Code", FromQltyInspectionTemplateLine."Template Code");
        FromQltyIResultConditConf.SetRange("Target Line No.", FromQltyInspectionTemplateLine."Line No.");
        FromQltyIResultConditConf.SetRange("Test Code", FromQltyInspectionTemplateLine."Test Code");
        if FromQltyIResultConditConf.FindSet() then
            repeat
                Clear(ToQltyIResultConditConf);
                ToQltyIResultConditConf.Reset();
                ToQltyIResultConditConf := FromQltyIResultConditConf;
                ToQltyIResultConditConf.SetRecFilter();
                ToQltyIResultConditConf.SetRange("Target Code", TargetQltyInspectionTemplateLine."Template Code");
                ToQltyIResultConditConf.SetRange("Test Code", TargetQltyInspectionTemplateLine."Test Code");
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
    internal procedure CopyResultConditionsFromTemplateToInspection(QltyInspectionTemplateLine: Record "Qlty. Inspection Template Line"; QltyInspectionLine: Record "Qlty. Inspection Line")
    var
        FromTemplateQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        ToCheckQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        QltyTest: Record "Qlty. Test";
    begin
        if QltyInspectionTemplateLine."Test Code" = '' then
            exit;

        FromTemplateQltyIResultConditConf.SetRange("Condition Type", FromTemplateQltyIResultConditConf."Condition Type"::Template);
        FromTemplateQltyIResultConditConf.SetRange("Target Code", QltyInspectionTemplateLine."Template Code");
        FromTemplateQltyIResultConditConf.SetRange("Target Line No.", QltyInspectionTemplateLine."Line No.");
        FromTemplateQltyIResultConditConf.SetRange("Test Code", QltyInspectionTemplateLine."Test Code");
        if not QltyTest.Get(QltyInspectionTemplateLine."Test Code") then
            exit;
        if QltyTest."Test Value Type" in [QltyTest."Test Value Type"::"Value Type Label"] then
            exit;

        if not FromTemplateQltyIResultConditConf.FindSet() then begin
            FromTemplateQltyIResultConditConf.Reset();
            FromTemplateQltyIResultConditConf.SetRange("Condition Type", FromTemplateQltyIResultConditConf."Condition Type"::Test);
            FromTemplateQltyIResultConditConf.SetRange("Test Code", QltyInspectionTemplateLine."Test Code");
            if not FromTemplateQltyIResultConditConf.FindSet() then
                exit;
        end;
        repeat
            Clear(ToCheckQltyIResultConditConf);
            ToCheckQltyIResultConditConf.Init();
            ToCheckQltyIResultConditConf := FromTemplateQltyIResultConditConf;
            ToCheckQltyIResultConditConf."Condition Type" := ToCheckQltyIResultConditConf."Condition Type"::Inspection;
            ToCheckQltyIResultConditConf."Target Code" := QltyInspectionLine."Inspection No.";
            ToCheckQltyIResultConditConf."Target Re-inspection No." := QltyInspectionLine."Re-inspection No.";
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
    /// This will copy any grade configurations configured to automatically copy to all existing templates.
    /// This leverages how CopyGradeConditionsFromFieldToTemplateLine will already update fields via CopyGradeConditionsFromDefaultToField 
    /// when a specific grade is supplied.
    /// </summary>
    internal procedure CopyGradeConditionsFromDefaultToAllTemplates()
    var
        QltyInspectionResult: Record "Qlty. Inspection Result";
        QltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
    begin
        QltyInspectionResult.SetRange("Copy Behavior", QltyInspectionResult."Copy Behavior"::"Automatically copy the result");
        if QltyInspectionResult.FindSet() then
            repeat
                if QltyInspectionTemplateLine.FindSet(false) then
                    repeat
                        // We're using 'false' here because we do not want to replace the conditions, only add new ones.
                        // We do not want to remove grades that were previously added to templates.
                        CopyResultConditionsFromTestToTemplateLine(QltyInspectionTemplateLine."Template Code", QltyInspectionTemplateLine."Line No.", QltyInspectionResult.Code, false);
                    until (QltyInspectionTemplateLine.Next() = 0);
            until (QltyInspectionResult.Next() = 0);
    end;

    /// <summary>
    /// Copies the default result conditions into the specified test.
    /// </summary>
    /// <param name="TestCode"></param>
    internal procedure CopyResultConditionsFromDefaultToTest(TestCode: Code[20])
    var
        QltyTest: Record "Qlty. Test";
    begin
        if TestCode = '' then
            exit;

        if not QltyTest.Get(TestCode) then
            exit;

        CopyResultConditionsFromDefaultToTest(TestCode, QltyTest."Test Value Type");
    end;

    internal procedure CopyResultConditionsFromDefaultToTest(TestCode: Code[20]; SpecificQltyTestValueType: Enum "Qlty. Test Value Type")
    begin
        if TestCode = '' then
            exit;

        InternalCopyResultConditionsFromDefaultToTestSpecificType(TestCode, '', false, true, SpecificQltyTestValueType);
    end;

    local procedure OverwriteExistingTestConditionsWithResultCondition(ResultCode: Code[20])
    var
        ExistingQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
    begin
        ExistingQltyIResultConditConf.SetRange("Result Code", ResultCode);
        ExistingQltyIResultConditConf.SetRange("Condition Type", ExistingQltyIResultConditConf."Condition Type"::Test);
        if ExistingQltyIResultConditConf.FindSet() then
            repeat
                InternalCopyResultConditionsFromDefaultToTest(ExistingQltyIResultConditConf."Test Code", ResultCode, true, false);
            until ExistingQltyIResultConditConf.Next() = 0;
    end;

    local procedure InternalCopyResultConditionsFromDefaultToTest(TestCode: Code[20]; OptionalSpecificResultCode: Code[20]; AlwaysUpdateExistingCondition: Boolean; OnlyOverwriteIfADefaultCondition: Boolean)
    var
        QltyTest: Record "Qlty. Test";
    begin
        if not QltyTest.Get(TestCode) then
            exit;

        InternalCopyResultConditionsFromDefaultToTestSpecificType(TestCode, OptionalSpecificResultCode, AlwaysUpdateExistingCondition, OnlyOverwriteIfADefaultCondition, QltyTest."Test Value Type");
    end;

    local procedure InternalCopyResultConditionsFromDefaultToTestSpecificType(TestCode: Code[20]; OptionalSpecificResultCode: Code[20]; AlwaysUpdateExistingCondition: Boolean; OnlyOverwriteIfADefaultCondition: Boolean; SpecificQltyTestValueType: Enum "Qlty. Test Value Type")
    var
        QltyTest: Record "Qlty. Test";
        QltyInspectionResult: Record "Qlty. Inspection Result";
        ToTestQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        Condition: Text;
    begin
        if not QltyTest.Get(TestCode) then
            exit;

        if OptionalSpecificResultCode <> '' then
            QltyInspectionResult.SetRange(Code, OptionalSpecificResultCode);
        QltyInspectionResult.SetRange("Copy Behavior", QltyInspectionResult."Copy Behavior"::"Automatically copy the result");
        if QltyInspectionResult.FindSet() then
            repeat
                QltyTest."Test Value Type" := SpecificQltyTestValueType;
                case true of
                    QltyTest.IsNumericFieldType():
                        Condition := QltyInspectionResult."Default Number Condition";
                    QltyTest."Test Value Type" = QltyTest."Test Value Type"::"Value Type Boolean":
                        Condition := QltyInspectionResult."Default Boolean Condition";
                    QltyTest."Test Value Type" = QltyTest."Test Value Type"::"Value Type Label":
                        Condition := '';
                    else
                        Condition := QltyInspectionResult."Default Text Condition";
                end;
                ToTestQltyIResultConditConf.Reset();
                ToTestQltyIResultConditConf.SetRange("Condition Type", ToTestQltyIResultConditConf."Condition Type"::Test);
                ToTestQltyIResultConditConf.SetRange("Target Code", TestCode);
                ToTestQltyIResultConditConf.SetRange("Test Code", TestCode);
                ToTestQltyIResultConditConf.SetRange("Result Code", QltyInspectionResult.Code);
                if not ToTestQltyIResultConditConf.FindFirst() then begin
                    ToTestQltyIResultConditConf."Result Code" := QltyInspectionResult.Code;
                    ToTestQltyIResultConditConf."Condition Type" := ToTestQltyIResultConditConf."Condition Type"::Test;
                    ToTestQltyIResultConditConf."Target Code" := TestCode;
                    ToTestQltyIResultConditConf."Test Code" := TestCode;
                    ToTestQltyIResultConditConf.Condition := CopyStr(Condition, 1, MaxStrLen(ToTestQltyIResultConditConf.Condition));
                    ToTestQltyIResultConditConf.Priority := QltyInspectionResult."Evaluation Sequence";
                    ToTestQltyIResultConditConf."Result Visibility" := QltyInspectionResult."Result Visibility";
                    ToTestQltyIResultConditConf."Condition Description" := CopyStr(Condition, 1, MaxStrLen(ToTestQltyIResultConditConf."Condition Description"));
                    ToTestQltyIResultConditConf.Insert();
                end else
                    if AlwaysUpdateExistingCondition or (OnlyOverwriteIfADefaultCondition and (ToTestQltyIResultConditConf.Condition in [QltyInspectionResult."Default Boolean Condition", QltyInspectionResult."Default Number Condition", QltyInspectionResult."Default Text Condition"])) then begin
                        ToTestQltyIResultConditConf.Validate(Condition, CopyStr(Condition, 1, MaxStrLen(ToTestQltyIResultConditConf.Condition)));
                        ToTestQltyIResultConditConf."Condition Description" := CopyStr(Condition, 1, MaxStrLen(ToTestQltyIResultConditConf."Condition Description"));
                        ToTestQltyIResultConditConf.Priority := QltyInspectionResult."Evaluation Sequence";
                        ToTestQltyIResultConditConf."Result Visibility" := QltyInspectionResult."Result Visibility";
                        ToTestQltyIResultConditConf.Modify();
                    end;
            until QltyInspectionResult.Next() = 0;
    end;

    /// <summary>
    /// Returns the promoted results for a test
    /// </summary>
    /// <param name="QltyTest"></param>
    /// <param name="MatrixArrayToSetConditionCellData"></param>
    /// <param name="MatrixArrayToSetCaptionSet"></param>
    /// <param name="MatrixVisibleStateToSet"></param>
    internal procedure GetPromotedResultsForTest(QltyTest: Record "Qlty. Test";
        var MatrixSourceRecordId: array[10] of RecordId;
        var MatrixArrayToSetConditionCellData: array[10] of Text;
        var MatrixArrayToSetConditionDescriptionCellData: array[10] of Text;
        var MatrixArrayToSetCaptionSet: array[10] of Text;
        var MatrixVisibleStateToSet: array[10] of Boolean)
    var
        QltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
    begin
        QltyIResultConditConf.SetRange("Condition Type", QltyIResultConditConf."Condition Type"::Test);
        QltyIResultConditConf.SetRange("Target Code", QltyTest.Code);
        QltyIResultConditConf.SetRange("Test Code", QltyTest.Code);
        if QltyIResultConditConf.IsEmpty() then
            CopyResultConditionsFromDefaultToTest(QltyTest.Code);

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
    internal procedure GetPromotedResultsForTemplateLine(QltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        var MatrixArraySourceRecordId: array[10] of RecordId;
        var MatrixArrayToSetConditionCellData: array[10] of Text;
        var MatrixArrayToSetConditionDescriptionCellData: array[10] of Text;
        var MatrixArrayToSetCaptionSet: array[10] of Text;
        var MatrixVisibleStateToSet: array[10] of Boolean)
    var
        QltyTest: Record "Qlty. Test";
        QltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
    begin
        Clear(MatrixArraySourceRecordId);
        Clear(MatrixArrayToSetConditionCellData);
        Clear(MatrixArrayToSetConditionDescriptionCellData);
        Clear(MatrixArrayToSetCaptionSet);
        Clear(MatrixVisibleStateToSet);

        if QltyInspectionTemplateLine."Test Code" <> '' then begin
            QltyIResultConditConf.SetRange("Condition Type", QltyIResultConditConf."Condition Type"::Template);
            QltyIResultConditConf.SetRange("Target Code", QltyInspectionTemplateLine."Template Code");
            QltyIResultConditConf.SetRange("Target Line No.", QltyInspectionTemplateLine."Line No.");
            QltyIResultConditConf.SetRange("Test Code", QltyInspectionTemplateLine."Test Code");
            if QltyIResultConditConf.IsEmpty() then begin
                if not QltyTest.Get(QltyInspectionTemplateLine."Test Code") then
                    exit;
                if not (QltyTest."Test Value Type" in [QltyTest."Test Value Type"::"Value Type Label"]) then
                    CopyResultConditionsFromTestToTemplateLine(QltyInspectionTemplateLine."Template Code", QltyInspectionTemplateLine."Line No.", '', false);
            end;
            GetPromotedResults(QltyIResultConditConf, MatrixArraySourceRecordId, MatrixArrayToSetConditionCellData, MatrixArrayToSetConditionDescriptionCellData, MatrixArrayToSetCaptionSet, MatrixVisibleStateToSet);
        end else
            GetDefaultPromotedResults(false, MatrixArraySourceRecordId, MatrixArrayToSetConditionCellData, MatrixArrayToSetConditionDescriptionCellData, MatrixArrayToSetCaptionSet, MatrixVisibleStateToSet);
    end;

    /// <summary>
    /// Gets the default promoted results in general regardless of what is configured
    /// for a specific test or a given test on a template (specification)
    /// This can be used to help determine the overall promoted results in the system.
    /// </summary>
    /// <param name="AllPromoted">If true this will return all promoted tests. If false, only those with autocopy.</param>
    /// <param name="MatrixArraySourceRecordId"></param>
    /// <param name="MatrixArrayToSetConditionCellData"></param>
    /// <param name="MatrixArrayToSetConditionDescriptionCellData"></param>
    /// <param name="MatrixArrayToSetCaptionSet"></param>
    /// <param name="MatrixVisibleStateToSet"></param>
    internal procedure GetDefaultPromotedResults(
        AllPromoted: Boolean;
        var MatrixArraySourceRecordId: array[10] of RecordId;
        var MatrixArrayToSetConditionCellData: array[10] of Text;
        var MatrixArrayToSetConditionDescriptionCellData: array[10] of Text;
        var MatrixArrayToSetCaptionSet: array[10] of Text;
        var MatrixVisibleStateToSet: array[10] of Boolean)
    var
        QltyInspectionResult: Record "Qlty. Inspection Result";
        Iterator: Integer;
        MaxResultConditions: Integer;
    begin
        Clear(MatrixArraySourceRecordId);
        Clear(MatrixArrayToSetConditionCellData);
        Clear(MatrixArrayToSetConditionDescriptionCellData);
        Clear(MatrixArrayToSetCaptionSet);
        Clear(MatrixVisibleStateToSet);

        MaxResultConditions := GetMaxResultConditions();

        QltyInspectionResult.SetRange("Result Visibility", QltyInspectionResult."Result Visibility"::Promoted);
        if not AllPromoted then
            QltyInspectionResult.SetRange("Copy Behavior", QltyInspectionResult."Copy Behavior"::"Automatically copy the result");
        QltyInspectionResult.SetCurrentKey("Result Visibility", "Evaluation Sequence");
        QltyInspectionResult.Ascending(false);
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
            until (QltyInspectionResult.Next() = 0) or (Iterator >= MaxResultConditions);
        end;
    end;

    internal procedure GetPromotedResultsForInspectionLine(QltyInspectionLine: Record "Qlty. Inspection Line"; var MatrixSourceRecordId: array[10] of RecordId; var MatrixArrayToSetConditionCellData: array[10] of Text; var MatrixArrayToSetConditionDescriptionCellData: array[10] of Text; var MatrixArrayToSetCaptionSet: array[10] of Text; var MatrixVisibleStateToSet: array[10] of Boolean)
    var
        QltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        QltyTest: Record "Qlty. Test";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
    begin
        Clear(MatrixArrayToSetConditionCellData);
        Clear(MatrixArrayToSetConditionDescriptionCellData);
        Clear(MatrixArrayToSetCaptionSet);
        Clear(MatrixVisibleStateToSet);

        if QltyInspectionHeader.Get(QltyInspectionLine."Inspection No.", QltyInspectionLine."Re-inspection No.") then;

        if QltyTest.Get(QltyInspectionLine."Test Code") then;
        if not (QltyTest."Test Value Type" in [QltyTest."Test Value Type"::"Value Type Label"]) then
            if not QltyInspectionTemplateLine.Get(QltyInspectionLine."Template Code", QltyInspectionLine."Template Line No.") then begin
                QltyInspectionTemplateLine.SetRange("Template Code", QltyInspectionLine."Template Code");
                QltyInspectionTemplateLine.SetRange("Test Code", QltyInspectionLine."Test Code");
                if not QltyInspectionTemplateLine.FindFirst() then
                    exit;
            end;

        QltyIResultConditConf.SetRange("Condition Type", QltyIResultConditConf."Condition Type"::Inspection);
        QltyIResultConditConf.SetRange("Target Code", QltyInspectionLine."Inspection No.");
        QltyIResultConditConf.SetRange("Target Re-inspection No.", QltyInspectionLine."Re-inspection No.");
        QltyIResultConditConf.SetRange("Target Line No.", QltyInspectionLine."Line No.");
        QltyIResultConditConf.SetRange("Test Code", QltyInspectionLine."Test Code");
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
        MaxResultConditions: Integer;
    begin
        Clear(MatrixArrayToSetConditionCellData);
        Clear(MatrixArrayToSetConditionDescriptionCellData);
        Clear(MatrixArrayToSetCaptionSet);
        Clear(MatrixVisibleStateToSet);

        MaxResultConditions := GetMaxResultConditions();

        QltyIResultConditConf.SetRange("Result Visibility", QltyIResultConditConf."Result Visibility"::Promoted);
        QltyIResultConditConf.SetCurrentKey("Condition Type", "Result Visibility", Priority, "Target Code", "Target Re-inspection No.", "Target Line No.");
        QltyIResultConditConf.Ascending(false);
        if QltyIResultConditConf.FindSet() then
            repeat
                if QltyInspectionResult.Get(QltyIResultConditConf."Result Code") then begin
                    Iterator += 1;
                    if Iterator <= GetMaxResultConditions() then begin
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
            until (QltyIResultConditConf.Next() = 0) or (Iterator >= MaxResultConditions);
    end;

    local procedure GetMaxResultConditions(): Integer
    begin
        exit(10);
    end;
}
