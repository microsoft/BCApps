// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.DemoTool.Helpers;

using Microsoft.QualityManagement.Configuration.GenerationRule;
using Microsoft.QualityManagement.Configuration.Result;
using Microsoft.QualityManagement.Configuration.Template;
using Microsoft.QualityManagement.Configuration.Template.Test;

codeunit 5710 "Contoso Quality Management"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    Permissions = tabledata "Qlty. Test" = rim,
                    tabledata "Qlty. Test Lookup Value" = rim,
                    tabledata "Qlty. Inspection Result" = rim,
                    tabledata "Qlty. Inspection Template Hdr." = rim,
                    tabledata "Qlty. Inspection Template Line" = rim,
                    tabledata "Qlty. Inspection Gen. Rule" = rim,
                    tabledata "Qlty. I. Result Condit. Conf." = rim;

    var
        OverwriteData: Boolean;

    procedure SetOverwriteData(Overwrite: Boolean)
    begin
        OverwriteData := Overwrite;
    end;

    procedure InsertQualityTest(Code: Code[20]; Description: Text[100]; TestValueType: Enum "Qlty. Test Value Type"; AllowableValues: Text[500]; LookupTableNo: Integer; LookupFieldNo: Integer; LookupTableFilter: Text[500]; DefaultValue: Text[250]; UnitOfMeasureCode: Code[10])
    var
        QltyTest: Record "Qlty. Test";
        Exists: Boolean;
    begin
        if QltyTest.Get(Code) then begin
            Exists := true;

            if not OverwriteData then
                exit;
        end;

        QltyTest.Validate(Code, Code);
        QltyTest.Validate(Description, Description);
        QltyTest.Validate("Test Value Type", TestValueType);

        if AllowableValues <> '' then
            QltyTest.Validate("Allowable Values", AllowableValues);

        if LookupTableNo <> 0 then
            QltyTest.Validate("Lookup Table No.", LookupTableNo);

        if LookupFieldNo <> 0 then
            QltyTest.Validate("Lookup Field No.", LookupFieldNo);

        if LookupTableFilter <> '' then
            QltyTest.Validate("Lookup Table Filter", LookupTableFilter);

        if DefaultValue <> '' then
            QltyTest.Validate("Default Value", DefaultValue);

        if UnitOfMeasureCode <> '' then
            QltyTest.Validate("Unit of Measure Code", UnitOfMeasureCode);

        if Exists then
            QltyTest.Modify(true)
        else
            QltyTest.Insert(true);
    end;

    procedure InsertQualityTestLookupValue(LookupGroupCode: Code[20]; LookupValue: Code[100]; Description: Text[250])
    var
        QltyTestLookupValue: Record "Qlty. Test Lookup Value";
        Exists: Boolean;
    begin
        if QltyTestLookupValue.Get(LookupGroupCode, LookupValue) then begin
            Exists := true;

            if not OverwriteData then
                exit;
        end;

        QltyTestLookupValue.Validate("Lookup Group Code", LookupGroupCode);
        QltyTestLookupValue.Validate("Value", LookupValue);
        QltyTestLookupValue.Validate(Description, Description);

        if Exists then
            QltyTestLookupValue.Modify(true)
        else
            QltyTestLookupValue.Insert(true);
    end;

    procedure InsertQualityInspectionResult(Code: Code[20]; Description: Text[100]; EvaluationSequence: Integer; CopyBehavior: Enum "Qlty. Result Copy Behavior"; ResultVisibility: Enum "Qlty. Result Visibility"; DefaultNumberCondition: Text[500]; DefaultTextCondition: Text[500]; DefaultBooleanCondition: Text[500]; ResultCategory: Enum "Qlty. Result Category"; FinishAllowed: Enum "Qlty. Result Finish Allowed")
    var
        QltyInspectionResult: Record "Qlty. Inspection Result";
        Exists: Boolean;
    begin
        if QltyInspectionResult.Get(Code) then begin
            Exists := true;

            if not OverwriteData then
                exit;
        end;

        QltyInspectionResult.Validate(Code, Code);
        QltyInspectionResult.Validate(Description, Description);
        QltyInspectionResult.Validate("Evaluation Sequence", EvaluationSequence);
        QltyInspectionResult.Validate("Copy Behavior", CopyBehavior);
        QltyInspectionResult.Validate("Result Visibility", ResultVisibility);
        QltyInspectionResult.Validate("Default Number Condition", DefaultNumberCondition);

        if DefaultTextCondition <> '' then
            QltyInspectionResult.Validate("Default Text Condition", DefaultTextCondition);

        if DefaultBooleanCondition <> '' then
            QltyInspectionResult.Validate("Default Boolean Condition", DefaultBooleanCondition);

        QltyInspectionResult.Validate("Result Category", ResultCategory);
        QltyInspectionResult.Validate("Finish Allowed", FinishAllowed);

        if Exists then
            QltyInspectionResult.Modify(true)
        else
            QltyInspectionResult.Insert(true);
    end;

    procedure InsertQualityInspectionTemplateHdr(Code: Code[20]; Description: Text[100])
    var
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        Exists: Boolean;
    begin
        if QltyInspectionTemplateHdr.Get(Code) then begin
            Exists := true;

            if not OverwriteData then
                exit;
        end;

        QltyInspectionTemplateHdr.Validate(Code, Code);
        QltyInspectionTemplateHdr.Validate(Description, Description);

        if Exists then
            QltyInspectionTemplateHdr.Modify(true)
        else
            QltyInspectionTemplateHdr.Insert(true);
    end;

    procedure InsertQualityInspectionTemplateLine(TemplateCode: Code[20]; LineNo: Integer; TestCode: Code[20]; Description: Text[100])
    var
        QltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        Exists: Boolean;
    begin
        if QltyInspectionTemplateLine.Get(TemplateCode, LineNo) then begin
            Exists := true;

            if not OverwriteData then
                exit;
        end;

        QltyInspectionTemplateLine.Validate("Template Code", TemplateCode);
        QltyInspectionTemplateLine.Validate("Line No.", LineNo);
        QltyInspectionTemplateLine.Validate("Test Code", TestCode);

        if Description <> '' then
            QltyInspectionTemplateLine.Validate(Description, Description);

        if Exists then
            QltyInspectionTemplateLine.Modify(true)
        else
            QltyInspectionTemplateLine.Insert(true);
    end;

    procedure InsertQualityInspectionGenRule(EntryNo: Integer; SortOrder: Integer; Intent: Enum "Qlty. Gen. Rule Intent"; TemplateCode: Code[20]; SourceTableNo: Integer; ConditionFilter: Text[400]; Description: Text[100]; ActivationTrigger: Enum "Qlty. Gen. Rule Act. Trigger")
    var
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        Exists: Boolean;
    begin
        if QltyInspectionGenRule.Get(EntryNo) then begin
            Exists := true;

            if not OverwriteData then
                exit;
        end;

        QltyInspectionGenRule.Validate("Entry No.", EntryNo);
        QltyInspectionGenRule.Validate("Sort Order", SortOrder);
        QltyInspectionGenRule.Validate(Intent, Intent);
        QltyInspectionGenRule.Validate("Template Code", TemplateCode);
        QltyInspectionGenRule.Validate("Source Table No.", SourceTableNo);

        if ConditionFilter <> '' then
            QltyInspectionGenRule.Validate("Condition Filter", ConditionFilter);

        if Description <> '' then
            QltyInspectionGenRule.Validate(Description, Description);

        QltyInspectionGenRule.Validate("Activation Trigger", ActivationTrigger);

        if Exists then
            QltyInspectionGenRule.Modify(true)
        else
            QltyInspectionGenRule.Insert(true);
    end;

    procedure InsertQltyIResultConditConf(ConditionType: Enum "Qlty. Result Condition Type"; TargetCode: Code[20]; TargetReinspectionNo: Integer; TargetLineNo: Integer; TestCode: Code[20]; ResultCode: Code[20]; Condition: Text[500]; Priority: Integer; ResultVisibility: Enum "Qlty. Result Visibility")
    var
        QltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        Exists: Boolean;
    begin
        if QltyIResultConditConf.Get(ConditionType, TargetCode, TargetReinspectionNo, TargetLineNo, TestCode, ResultCode) then begin
            Exists := true;

            if not OverwriteData then
                exit;
        end;

        QltyIResultConditConf.Validate("Condition Type", ConditionType);
        QltyIResultConditConf.Validate("Target Code", TargetCode);
        QltyIResultConditConf.Validate("Target Re-inspection No.", TargetReinspectionNo);
        QltyIResultConditConf.Validate("Target Line No.", TargetLineNo);
        QltyIResultConditConf.Validate("Test Code", TestCode);
        QltyIResultConditConf.Validate("Result Code", ResultCode);

        if Condition <> '' then
            QltyIResultConditConf.Validate(Condition, Condition);

        QltyIResultConditConf.Validate(Priority, Priority);
        QltyIResultConditConf.Validate("Result Visibility", ResultVisibility);

        if Exists then
            QltyIResultConditConf.Modify(true)
        else
            QltyIResultConditConf.Insert(true);
    end;
}
