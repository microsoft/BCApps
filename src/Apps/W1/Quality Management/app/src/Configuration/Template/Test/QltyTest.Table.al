// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Configuration.Template.Test;

using Microsoft.Foundation.UOM;
using Microsoft.QualityManagement.Configuration.Result;
using Microsoft.QualityManagement.Configuration.Template;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Utilities;
using System.IO;
using System.Reflection;

/// <summary>
/// This table lets you define data points, questions, measurements, and entries with their allowable values and default passing thresholds. You can later use these tests in Quality Inspection Templates.
/// </summary>
table 20401 "Qlty. Test"
{
    Caption = 'Quality Test';
    DrillDownPageId = "Qlty. Tests";
    LookupPageId = "Qlty. Test Lookup";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            ToolTip = 'Specifies the short code to identify the test. You can enter a maximum of 20 characters, both numbers and letters.';
            NotBlank = true;

            trigger OnValidate()
            begin
                Rec."Code" := DelChr(Rec."Code", '=', ' ><{}.@!`~''"|\/?&*()');
            end;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the friendly description for the test. You can enter a maximum of 100 characters, both numbers and letters.';
        }
        field(3; "Test Value Type"; Enum "Qlty. Test Value Type")
        {
            Caption = 'Test Value Type';
            ToolTip = 'Specifies the data type of the values you can enter or select for this test. Use Decimal for numerical measurements. Use Choice to give a list of options to choose from. If you want to choose options from an existing table, use Table Lookup.';

            trigger OnValidate()
            begin
                HandleOnValidateTestValueType(true);
            end;
        }
        field(5; "Allowable Values"; Text[500])
        {
            Caption = 'Allowable Values';
            ToolTip = 'Specifies an expression for the range of values you can enter or select for the Test. Depending on the Test Value Type, the expression format varies. For example if you want a measurement such as a percentage that collects between 0 and 100 you would enter 0..100. This is not the pass or acceptable condition, these are just the technically possible values that the inspector can enter. You would then enter a passing condition in your result conditions. If you had a result of Pass being 80 to 100, you would then configure 80..100 for that result.';
            trigger OnValidate()
            begin
                if Rec."Test Value Type" in [Rec."Test Value Type"::"Value Type Option", Rec."Test Value Type"::"Value Type Table Lookup"] then
                    Rec."Allowable Values" := CopyStr(Rec."Allowable Values".Replace(', ', ','), 1, MaxStrLen(Rec."Allowable Values"));
            end;
        }
        field(6; "Lookup Table No."; Integer)
        {
            BlankZero = true;
            Caption = 'Lookup Table No.';
            ToolTip = 'Specifies which table you are looking up when using a table lookup as a data type. For example, if you want to show a list of available reason codes from the reason code table, then you would use table 231 "Reason Code" here.';
            MinValue = 0;
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table));

            trigger OnValidate()
            var
                TempFilteringOnlyQltyTestLookupValue: Record "Qlty. Test Lookup Value" temporary;
                QltyFilterHelpers: Codeunit "Qlty. Filter Helpers";
                LookupFilter: Text;
            begin
                if Rec."Lookup Table No." <> xRec."Lookup Table No." then begin
                    Rec.Validate("Lookup Field No.", 0);
                    Rec."Lookup Table Filter" := '';
                    Rec."Allowable Values" := '';
                    if Rec."Lookup Table No." = Database::"Qlty. Test Lookup Value" then begin
                        TempFilteringOnlyQltyTestLookupValue.SetRange("Lookup Group Code", Rec."Code");
                        LookupFilter := QltyFilterHelpers.CleanUpWhereClause(TempFilteringOnlyQltyTestLookupValue.GetView());
                        Rec.Validate("Lookup Table Filter", CopyStr(LookupFilter, 1, MaxStrLen(Rec."Lookup Table Filter")));
                        Rec.Validate("Lookup Field No.", TempFilteringOnlyQltyTestLookupValue.FieldNo("Value"));
                    end;
                end;

                Rec.CalcFields("Lookup Table Caption", "Lookup Field Caption");
            end;
        }
        field(7; "Lookup Table Caption"; Text[250])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Table),
                                                                          "Object ID" = field("Lookup Table No.")));
            Caption = 'Lookup Table Caption';
            ToolTip = 'Specifies the name of the lookup table. When using a table lookup as a data type then this is the name of the table that you are looking up. For example, if you want to show a list of available reason codes from the reason code table then you would use table 231 "Reason Code" here.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(8; "Lookup Field No."; Integer)
        {
            BlankZero = true;
            Caption = 'Lookup Field No.';
            ToolTip = 'Specifies the field within the Lookup Table to use for the lookup. For example if you had table 231 "Reason Code" as your lookup table, then you could use from the "Reason Code" table field "1" which represents the field "Code" on that table. When someone is recording an inspection, and choosing the test value they would then see as options the values from this field.';
            MinValue = 0;
            TableRelation = Field."No." where(TableNo = field("Lookup Table No."));

            trigger OnLookup()
            var
                CurrentField: Record "Field";
            begin
                if Rec."Lookup Table No." <> 0 then begin
                    CurrentField.FilterGroup(50);
                    CurrentField.SetRange(TableNo, "Lookup Table No.");
                    CurrentField.SetFilter(Class, '%1|%2', CurrentField.Class::Normal, CurrentField.Class::FlowField);
                    if FieldSelection.Open(CurrentField) then
                        Rec.Validate("Lookup Field No.", CurrentField."No.");
                end;
            end;

            trigger OnValidate()
            begin
                Rec.CalcFields("Lookup Field Caption");
                Rec.UpdateAllowedValuesFromTableLookup();
            end;
        }
        field(9; "Lookup Field Caption"; Text[250])
        {
            CalcFormula = lookup(Field."Field Caption" where(TableNo = field("Lookup Table No."),
                                                             "No." = field("Lookup Field No.")));
            Caption = 'Lookup Field Name';
            ToolTip = 'Specifies the name of the field within the Lookup Table to use for the lookup. For example if you had table 231 "Reason Code" as your lookup table, and also were using field "1" as the Lookup Field (which represents the field "Code" on that table) then this would show "Code"';
            Editable = false;
            FieldClass = FlowField;
        }
        field(10; "Lookup Table Filter"; Text[400])
        {
            Caption = 'Lookup Table Filter';
            ToolTip = 'Specifies which data are available from the Lookup Table by using a standard Business Central filter expression. For example, if you were using table 231 "Reason Code" as your lookup table and wanted to restrict the options to codes that started with "R", then you could enter: where("Code"=filter(R*))';

            trigger OnValidate()
            begin
                Rec.UpdateAllowedValuesFromTableLookup();
            end;
        }
        field(16; "Default Value"; Text[250])
        {
            Caption = 'Default Value';
            ToolTip = 'Specifies a default value to set on the inspection.';

            trigger OnValidate()
            begin
                Rec.ValidateAllowableValuesOnDefault();
            end;
        }
        field(17; "Case Sensitive"; Enum "Qlty. Case Sensitivity")
        {
            Caption = 'Case Sensitivity';
            ToolTip = 'Specifies if case sensitivity will be enabled for text-based fields.';
        }
        field(18; "Expression Formula"; Text[500])
        {
            Caption = 'Expression Formula';
            ToolTip = 'Specifies the formula for the expression content when using expression field types.';

            trigger OnValidate()
            begin
                if (Rec."Expression Formula" <> '') and not (Rec."Test Value Type" in [Rec."Test Value Type"::"Value Type Text Expression"]) then
                    Error(OnlyFieldExpressionErr);
            end;
        }
        field(22; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            ToolTip = 'Specifies the unit of measure for the measurement.';
            TableRelation = "Unit of Measure".Code;
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; Code, Description, "Allowable Values", "Test Value Type")
        {
        }
        fieldgroup(Brick; Code, Description, "Allowable Values", "Test Value Type")
        {
        }
    }

    var
        FieldSelection: Codeunit "Field Selection";
        GenericTestTok: Label 'MYTEST', Locked = true;
        ThereIsNoResultErr: Label 'There is no result called "%1". Please add the result, or change the existing result conditions.', Comment = '%1=the result';
        ReviewResultsErr: Label 'Advanced configuration required. Please review the result configurations for test "%1", for result "%2".', Comment = '%1=the test, %2=the result';
        OnlyFieldExpressionErr: Label 'The Expression Formula can only be used with fields that are a type of Expression';
        BooleanChoiceListLbl: Label 'No,Yes';
        ExistingInspectionErr: Label 'The test %1 exists on %2 inspections (such as %3 with template %4). The test can not be deleted if it is being used on a Quality Inspection.', Comment = '%1=the test, %2=count of inspections, %3=one example inspection, %4=example template.';
        DeleteQst: Label 'The test %3 exists on %1 Quality Inspection Template(s) (such as template %2) that will be deleted. Do you wish to proceed?', Comment = '%1 = the lines, %2= the Template Code, %3=the test';
        DeleteErr: Label 'The test %3 exists on %1 Quality Inspection Template(s) (such as template %2) and can not be deleted until it is no longer used on templates.', Comment = '%1 = the lines, %2= the Template Code, %3=the test';
        TestValueTypeErrTitleMsg: Label 'Test Value Type cannot be changed for a test that has been used in inspections.';
        TestValueTypeErrInfoMsg: Label '%1Consider replacing this test in the template with a new one, or deleting existing inspections (if allowed). The test was last used on inspection %2.', Comment = '%1 = Error Title, %2 = Quality Inspection No.';

    /// <summary>
    /// Set a specific result for the test. If AllowError is set to true it will error
    /// when a problem occurs. If AllowError is set to false it will just return false
    /// when a problem occurs.
    /// </summary>
    /// <param name="Result"></param>
    /// <param name="Condition"></param>
    /// <param name="AllowError"></param>
    /// <returns></returns>
    procedure SetResultCondition(Result: Text; Condition: Text; AllowError: Boolean): Boolean
    var
        ExistingQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        QltyInspectionResult: Record "Qlty. Inspection Result";
        QltyResultConditionMgmt: Codeunit "Qlty. Result Condition Mgmt.";
    begin
        if not QltyInspectionResult.Get(CopyStr(Result, 1, MaxStrLen(QltyInspectionResult.Code))) then
            if AllowError then
                Error(ThereIsNoResultErr, Result)
            else
                exit(false);

        QltyResultConditionMgmt.CopyResultConditionsFromDefaultToTest(Rec.Code, Rec."Test Value Type");
        ExistingQltyIResultConditConf.SetRange("Test Code", Rec.Code);
        ExistingQltyIResultConditConf.SetRange("Target Code", Rec.Code);
        ExistingQltyIResultConditConf.SetRange("Result Code", QltyInspectionResult.Code);
        ExistingQltyIResultConditConf.SetRange("Condition Type", ExistingQltyIResultConditConf."Condition Type"::Test);

        if ExistingQltyIResultConditConf.Count() <> 1 then
            if AllowError then
                Error(ReviewResultsErr, Rec.Code, QltyInspectionResult.Code)
            else
                exit(false);

        if ExistingQltyIResultConditConf.FindFirst() then begin
            ExistingQltyIResultConditConf.Validate(Condition, CopyStr(Condition, 1, MaxStrLen(ExistingQltyIResultConditConf.Condition)));

            exit(ExistingQltyIResultConditConf.Modify());
        end else
            exit(false);
    end;

    /// <summary>
    /// Starts the appropriate 'assist edit' dialog for the given data type and conditions.
    /// </summary>
    procedure AssistEditDefaultValue()
    var
        IsHandled: Boolean;
    begin
        OnBeforeAssistEditDefaultValue(Rec, IsHandled);
        if IsHandled then
            exit;

        case Rec."Test Value Type" of
            Rec."Test Value Type"::"Value Type Option":
                AssistEditChooseFromList(Rec."Allowable Values");
            Rec."Test Value Type"::"Value Type Table Lookup":
                AssistEditChooseFromTableLookup();
            Rec."Test Value Type"::"Value Type Boolean":
                AssistEditChooseFromList(BooleanChoiceListLbl);
            Rec."Test Value Type"::"Value Type Text":
                AssistEditFreeText();
        end;
    end;

    local procedure AssistEditChooseFromList(Options: Text)
    var
        Selection: Integer;
    begin
        Selection := StrMenu(Options.Replace(', ', ','));
        if Selection > 0 then
            Rec.Validate("Default Value", SelectStr(Selection, Options));
    end;

    local procedure AssistEditChooseFromTableLookup()
    var
        TempBufferQltyTestLookupValue: Record "Qlty. Test Lookup Value" temporary;
    begin
        Rec.CollectAllowableValues(TempBufferQltyTestLookupValue, Rec."Default Value");
        if Page.RunModal(Page::"Qlty. Lookup Field Choose", TempBufferQltyTestLookupValue) = Action::LookupOK then
            Rec.Validate("Default Value", CopyStr(TempBufferQltyTestLookupValue."Custom 1", 1, MaxStrLen(Rec."Default Value")));
    end;

    internal procedure AssistEditFreeText()
    var
        QltyEditLargeText: Page "Qlty. Edit Large Text";
        ExistingValue: Text;
    begin
        ExistingValue := Rec."Default Value";

        if QltyEditLargeText.RunModalWith(ExistingValue) in [Action::LookupOK, Action::OK, Action::Yes] then
            Rec."Default Value" := CopyStr(ExistingValue, 1, MaxStrLen(Rec."Default Value"));
    end;

    procedure AssistEditLookupTable()
    var
        ConfigValidateManagement: Codeunit "Config. Validate Management";
        LookupTableNo: Integer;
    begin
        LookupTableNo := Rec."Lookup Table No.";
        ConfigValidateManagement.LookupTable(LookupTableNo);
        Rec.Validate("Lookup Table No.", LookupTableNo);
        Rec.CalcFields("Lookup Table Caption");
    end;

    procedure AssistEditLookupField()
    var
        QltyFilterHelpers: Codeunit "Qlty. Filter Helpers";
        CurrentField: Integer;
    begin
        CurrentField := QltyFilterHelpers.RunModalLookupAnyField(Rec."Lookup Table No.", -1, '');
        if CurrentField >= 0 then
            Rec.Validate("Lookup Field No.", CurrentField);
    end;

    procedure AssistEditLookupTableFilter()
    var
        QltyFilterHelpers: Codeunit "Qlty. Filter Helpers";
        LookupFilter: Text;
    begin
        LookupFilter := Rec."Lookup Table Filter";
        QltyFilterHelpers.BuildFilter(Rec."Lookup Table No.", true, LookupFilter);
        if (LookupFilter <> Rec."Lookup Table Filter") and (LookupFilter <> '') then
            Rec."Lookup Table Filter" := CopyStr(LookupFilter, 1, MaxStrLen(Rec."Lookup Table Filter"));

        Rec.UpdateAllowedValuesFromTableLookup();
    end;

    /// <summary>
    /// This is basically to make a summary for the human to see more easily when configuring templates and tests.
    /// This data isn't actually used during execution.
    /// </summary>
    procedure UpdateAllowedValuesFromTableLookup()
    var
        QltyMiscHelpers: Codeunit "Qlty. Misc Helpers";
        AllowableValues: Text;
    begin
        if Rec."Test Value Type" <> Rec."Test Value Type"::"Value Type Table Lookup" then
            exit;

        AllowableValues := QltyMiscHelpers.GetCSVOfValuesFromRecord(Rec."Lookup Table No.", Rec."Lookup Field No.", Rec."Lookup Table Filter");
        Rec."Allowable Values" := CopyStr(AllowableValues, 1, MaxStrLen(Rec."Allowable Values"));
    end;

    trigger OnModify()
    begin
        if Rec."Test Value Type" = Rec."Test Value Type"::"Value Type Table Lookup" then
            UpdateAllowedValuesFromTableLookup();
    end;

    trigger OnInsert()
    begin
        if Rec."Test Value Type" = Rec."Test Value Type"::"Value Type Table Lookup" then
            UpdateAllowedValuesFromTableLookup();
    end;

    trigger OnDelete()
    begin
        CheckDeleteConstraints(false);
    end;

    procedure CheckDeleteConstraints(AskQuestion: Boolean)
    var
        QltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        QltyInspectionLine: Record "Qlty. Inspection Line";
        LineCount: Integer;
        CanBeDeleted: Boolean;
    begin
        QltyInspectionLine.SetRange("Test Code", Rec.Code);
        LineCount := QltyInspectionLine.Count();
        if LineCount > 0 then begin
            QltyInspectionLine.FindFirst();
            Error(ExistingInspectionErr,
                QltyInspectionLine."Test Code",
                LineCount,
                QltyInspectionLine."Inspection No.",
                QltyInspectionLine."Template Code");
        end;

        QltyInspectionTemplateLine.SetRange("Test Code", Rec.Code);
        LineCount := QltyInspectionTemplateLine.Count();
        if LineCount > 0 then begin
            QltyInspectionTemplateLine.FindFirst();
            if GuiAllowed() and AskQuestion then
                CanBeDeleted := Dialog.Confirm(StrSubstNo(DeleteQst, LineCount, QltyInspectionTemplateLine."Template Code", Rec.Code));
            if CanBeDeleted then
                QltyInspectionTemplateLine.DeleteAll(true)
            else
                Error(DeleteErr, LineCount, QltyInspectionTemplateLine."Template Code", Rec.Code);
        end;
    end;

    internal procedure SuggestUnusedTestCodeFromDescription(InputDescription: Text; var SuggestionCode: Code[20])
    var
        DummyListOptionalAdditionalUsed: List of [Text];
    begin
        SuggestUnusedTestCodeFromDescriptionAndList(InputDescription, DummyListOptionalAdditionalUsed, SuggestionCode);
    end;

    internal procedure SuggestUnusedTestCodeFromDescriptionAndList(InputDescription: Text; IgnoredListOptionalAdditionalUsed: List of [Text]; var SuggestionCode: Code[20])
    begin
        GenerateShortTestCodeFromLongerText(InputDescription, SuggestionCode);
        EnsureTestCodeIsUnused(SuggestionCode, IgnoredListOptionalAdditionalUsed);
    end;

    internal procedure GenerateShortTestCodeFromLongerText(Input: Text; var SuggestionCode: Code[20])
    var
        Temp: Text;
    begin
        Temp := Input;

        Temp := DelChr(Temp, '=', ' ><{}.@!`~''"|\/?&*()-_$#-=,%%:');
        if StrLen(Temp) > MaxStrLen(SuggestionCode) then
            Temp := DelChr(Temp, '=', 'AEIOUY');

        SuggestionCode := CopyStr(Temp, 1, MaxStrLen(SuggestionCode));
    end;

    /// <summary>
    /// Takes the supplied test code, and ensures it's unique.
    /// If the supplied test code has already been used then it will suggest an alternative.
    /// </summary>
    /// <param name="Suggestion"></param>
    local procedure EnsureTestCodeIsUnused(var Suggestion: Code[20]; OptionalAdditionalUsed: List of [Text])
    var
        QltyTest: Record "Qlty. Test";
        TempNumber: Text;
        OriginalSuggestion: Text;
        Iterator: Integer;
        TestAlreadyExists: Boolean;
    begin
        if Suggestion = '' then
            Suggestion := GenericTestTok;
        OriginalSuggestion := Suggestion;

        Iterator := 1;
        repeat
            Iterator += 1;
            TestAlreadyExists := false;
            TestAlreadyExists := OptionalAdditionalUsed.Contains(Suggestion);
            if not TestAlreadyExists then begin
                QltyTest.Reset();
                QltyTest.SetRange(Code, Suggestion);
                TestAlreadyExists := QltyTest.FindFirst();
            end;
            if TestAlreadyExists then begin
                TempNumber := Format(Iterator, 0, 9);
                TempNumber := PadStr('', 4 - StrLen(TempNumber), '0') + TempNumber;
                Suggestion := CopyStr(CopyStr(OriginalSuggestion, 1, MaxStrLen(Suggestion) - StrLen(TempNumber)), 1, MaxStrLen(Suggestion));
                Suggestion := CopyStr(Suggestion + TempNumber, 1, MaxStrLen(Suggestion));
            end;
        until (not TestAlreadyExists) or (Iterator >= 9999);
    end;

    /// <summary>
    /// Validates that the default value is allowable.
    /// </summary>
    procedure ValidateAllowableValuesOnDefault()
    var
        QltyResultEvaluation: Codeunit "Qlty. Result Evaluation";
    begin
        QltyResultEvaluation.ValidateAllowableValuesOnTest(Rec);
    end;

    /// <summary>
    /// Code = the unique code
    /// Description = raw description.
    /// Custom 1 = original value
    /// Custom 2 = lowercase value
    /// Custom 3 = uppercase value.
    /// </summary>
    /// <param name="ContextQltyInspectionHeader">Supply if you want to give an inspection, this is useful for table lookups which can have additional values.</param>
    /// <param name="TempBufferQltyTestLookupValue"></param>
    /// <param name="OptionalSetToValue">Leave empty to ignore. Supply a value to have the record auto-filtered to the supplied record that matches</param>
    procedure CollectAllowableValues(var TempBufferQltyTestLookupValue: Record "Qlty. Test Lookup Value" temporary; OptionalSetToValue: Text)
    var
        TempDummyContextQltyInspectionHeader: Record "Qlty. Inspection Header" temporary;
        TempDummyContextQltyInspectionLine: Record "Qlty. Inspection Line" temporary;
    begin
        CollectAllowableValues(TempDummyContextQltyInspectionHeader, TempDummyContextQltyInspectionLine, TempBufferQltyTestLookupValue, OptionalSetToValue);
    end;

    procedure CollectAllowableValues(var OptionalContextQltyInspectionHeader: Record "Qlty. Inspection Header"; var OptionalContextQltyInspectionLine: Record "Qlty. Inspection Line"; var TempBufferQltyTestLookupValue: Record "Qlty. Test Lookup Value" temporary; OptionalSetToValue: Text)
    var
        QltyMiscHelpers: Codeunit "Qlty. Misc Helpers";
        OfChoices: List of [Text];
        Choice: Text;
    begin
        case Rec."Test Value Type" of
            Rec."Test Value Type"::"Value Type Table Lookup":
                begin
                    QltyMiscHelpers.GetRecordsForTableField(Rec, OptionalContextQltyInspectionHeader, OptionalContextQltyInspectionLine, TempBufferQltyTestLookupValue);
                    if TempBufferQltyTestLookupValue.FindSet() then begin
                        if OptionalSetToValue <> '' then begin
                            TempBufferQltyTestLookupValue.SetRange("Value", CopyStr(OptionalSetToValue, 1, MaxStrLen(TempBufferQltyTestLookupValue."Value")));
                            if not TempBufferQltyTestLookupValue.FindSet() then begin
                                TempBufferQltyTestLookupValue.SetRange(Description, CopyStr(OptionalSetToValue, 1, MaxStrLen(TempBufferQltyTestLookupValue.Description)));
                                if not TempBufferQltyTestLookupValue.FindSet() then;
                            end;
                        end;
                        TempBufferQltyTestLookupValue.SetRange("Value");
                        TempBufferQltyTestLookupValue.SetRange(Description);
                    end;
                end;
            Rec."Test Value Type"::"Value Type Option":
                begin
                    TempBufferQltyTestLookupValue.Reset();
                    OfChoices := Rec."Allowable Values".Split(',');
                    foreach Choice in OfChoices do begin
                        Choice := Choice.Trim();
                        if not TempBufferQltyTestLookupValue.Get(Rec.Code, CopyStr(Choice, 1, MaxStrLen(TempBufferQltyTestLookupValue."Value"))) then begin
                            TempBufferQltyTestLookupValue.Init();
                            TempBufferQltyTestLookupValue."Lookup Group Code" := Rec.Code;
                            TempBufferQltyTestLookupValue."Value" := CopyStr(Choice, 1, MaxStrLen(TempBufferQltyTestLookupValue."Value"));
                            TempBufferQltyTestLookupValue.Description := CopyStr(Choice, 1, MaxStrLen(TempBufferQltyTestLookupValue.Description));
                            TempBufferQltyTestLookupValue."Custom 1" := CopyStr(Choice, 1, MaxStrLen(TempBufferQltyTestLookupValue."Custom 1"));
                            TempBufferQltyTestLookupValue."Custom 2" := TempBufferQltyTestLookupValue."Custom 1".ToLower();
                            TempBufferQltyTestLookupValue."Custom 3" := TempBufferQltyTestLookupValue."Custom 1".ToUpper();
                            TempBufferQltyTestLookupValue.Insert();
                        end;
                    end;
                end;
        end;
    end;

    internal procedure HandleOnValidateTestValueType(AllowActionableError: Boolean)
    var
        QltyInspectionLine: Record "Qlty. Inspection Line";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyResultConditionMgmt: Codeunit "Qlty. Result Condition Mgmt.";
    begin
        QltyInspectionLine.SetRange("Test Code", Rec.Code);
        if QltyInspectionLine.FindLast() then begin
            if QltyInspectionHeader.Get(QltyInspectionLine."Inspection No.", QltyInspectionLine."Re-inspection No.") then;
            if AllowActionableError then
                Error(TestValueTypeErrInfoMsg, TestValueTypeErrTitleMsg, QltyInspectionHeader."No.")
            else
                Error(TestValueTypeErrInfoMsg, TestValueTypeErrTitleMsg, QltyInspectionHeader."No.");
        end;

        if Rec."Test Value Type" <> xRec."Test Value Type" then begin
            Rec."Allowable Values" := '';
            Rec.Validate("Lookup Table No.", 0);
            Rec.Validate("Lookup Field No.", 0);
            Rec."Lookup Table Filter" := '';

            if Rec."Test Value Type" = Rec."Test Value Type"::"Value Type Table Lookup" then
                Rec.Validate("Lookup Table No.", Database::"Qlty. Test Lookup Value");
        end;

        QltyResultConditionMgmt.CopyResultConditionsFromDefaultToTest(Rec.Code, Rec."Test Value Type");
    end;

    procedure AssistEditExpressionFormula()
    var
        QltyInspectionTemplateEdit: Page "Qlty. Inspection Template Edit";
        Expression: Text;
    begin
        if not (Rec."Test Value Type" in [Rec."Test Value Type"::"Value Type Text Expression"]) then
            Error(OnlyFieldExpressionErr);

        Expression := Rec."Expression Formula";

        if QltyInspectionTemplateEdit.RunModalWith(Database::"Qlty. Inspection Header", '', Expression) in [Action::LookupOK, Action::OK, Action::Yes] then begin
            Rec."Expression Formula" := CopyStr(Expression, 1, MaxStrLen(Rec."Expression Formula"));
            Rec.Modify();
        end;
    end;

    procedure AssistEditAllowableValues()
    var
        QltyTestLookupValue: Record "Qlty. Test Lookup Value";
        QltyInspectionTemplateEdit: Page "Qlty. Inspection Template Edit";
        Expression: Text;
        IsHandled: Boolean;
    begin
        OnBeforeAssistAllowableValues(Rec, QltyInspectionTemplateEdit, IsHandled);
        if IsHandled then
            exit;

        if Rec."Test Value Type" = Rec."Test Value Type"::"Value Type Table Lookup" then begin
            if (Rec.Code <> '') and (Rec."Lookup Table No." = Database::"Qlty. Test Lookup Value") then begin
                QltyTestLookupValue.SetRange("Lookup Group Code", Rec.Code);
                Page.RunModal(Page::"Qlty. Test Lookup Values", QltyTestLookupValue);
            end;
            Rec.UpdateAllowedValuesFromTableLookup();
        end else begin
            Expression := Rec."Allowable Values";
            if QltyInspectionTemplateEdit.RunModalWith(Database::"Qlty. Inspection Header", '', Expression) in [Action::LookupOK, Action::OK, Action::Yes] then begin
                Rec."Allowable Values" := CopyStr(Expression, 1, MaxStrLen(Rec."Allowable Values"));
                Rec.Modify();
            end;
        end;
    end;

    /// <summary>
    /// Returns true if the field type is numeric in nature.
    /// </summary>
    /// <returns></returns>
    procedure IsNumericFieldType() IsNumeric: Boolean
    var
        IsHandled: Boolean;
    begin
        OnBeforeIsNumericFieldType(Rec, IsNumeric, IsHandled);
        if IsHandled then
            exit;

        IsNumeric := Rec."Test Value Type" in [Rec."Test Value Type"::"Value Type Decimal",
                        Rec."Test Value Type"::"Value Type Integer"
                        ];
    end;

    /// <summary>
    /// Provides an opportunity to allow determining if the field is intended to be numeric or not.
    /// Use this if you are extending the data type enumeration and adding your own numeric field.
    /// </summary>
    /// <param name="QltyTest"></param>
    /// <param name="IsNumeric"></param>
    /// <param name="IsHandled"></param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsNumericFieldType(var QltyTest: Record "Qlty. Test"; var IsNumeric: Boolean; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Provides an opportunity to extend or replace editing allowable values.
    /// </summary>
    /// <param name="QltyTest"></param>
    /// <param name="QltyInspectionTemplateEdit"></param>
    /// <param name="IsHandled"></param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeAssistAllowableValues(var QltyTest: Record "Qlty. Test"; QltyInspectionTemplateEdit: Page "Qlty. Inspection Template Edit"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Provides an ability to extend or replace assist editing the default value.
    /// </summary>
    /// <param name="QltyTest"></param>
    /// <param name="IsHandled">Set to true to prevent base behavior from occurring.</param>
    [IntegrationEvent(false, false)]
    procedure OnBeforeAssistEditDefaultValue(var QltyTest: Record "Qlty. Test"; var IsHandled: Boolean)
    begin
    end;
}
