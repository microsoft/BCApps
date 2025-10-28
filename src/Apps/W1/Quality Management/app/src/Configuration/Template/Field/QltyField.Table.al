// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Configuration.Template.Field;

using Microsoft.Foundation.UOM;
using Microsoft.QualityManagement.Configuration.Grade;
using Microsoft.QualityManagement.Configuration.Template;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Utilities;
using System.IO;
using System.Reflection;

/// <summary>
/// This table lets you define data points, questions, measurements, and entries with their allowable values and default passing thresholds. You can later use these test fields in Quality Inspection Templates.
/// </summary>
table 20401 "Qlty. Field"
{
    Caption = 'Quality Field';
    DrillDownPageID = "Qlty. Fields";
    LookupPageID = "Qlty. Field Lookup";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            ToolTip = 'Specifies the short code to identify the test field. You can enter a maximum of 20 characters, both numbers and letters.';
            NotBlank = true;

            trigger OnValidate()
            begin
                Rec."Code" := DelChr(Rec."Code", '=', ' ><{}.@!`~''"|\/?&*()');
            end;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the friendly description for the test field. You can enter a maximum of 100 characters, both numbers and letters.';
        }
        field(3; "Field Type"; Enum "Qlty. Field Type")
        {
            Caption = 'Field Type';
            ToolTip = 'Specifies the data type of the values you can enter or select for this field. Use Decimal for numerical measurements. Use Choice to give a list of options to choose from. If you want to choose options from an existing table, use Table Lookup.';

            trigger OnValidate()
            begin
                HandleOnValidateFieldType(true);
            end;
        }
        field(5; "Allowable Values"; Text[500])
        {
            Caption = 'Allowable Values';
            ToolTip = 'Specifies an expression for the range of values you can enter or select for the Field. Depending on the Field Type, the expression format varies. For example if you want a measurement such as a percentage that collects between 0 and 100 you would enter 0..100. This is not the pass or acceptable condition, these are just the technically possible values that the inspector can enter. You would then enter a passing condition in your grade conditions. If you had a grade of Pass being 80 to 100, you would then configure 80..100 for that grade.';
        }
        field(6; "Lookup Table No."; Integer)
        {
            BlankZero = true;
            Caption = 'Lookup Table No.';
            ToolTip = 'Specifies which table you are looking up when using a table lookup as a data type. For example, if you want to show a list of available reason codes from the reason code table, then you would use table 231 "Reason Code" here.';
            MinValue = 0;
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table));

            trigger OnValidate()
            begin
                if "Lookup Table No." <> xRec."Lookup Table No." then begin
                    Rec.Validate("Lookup Field No.", 0);
                    Rec."Lookup Table Filter" := '';
                end;
                Rec.CalcFields("Lookup Table Caption");
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
            ToolTip = 'Specifies the field within the Lookup Table to use for the lookup. For example if you had table 231 "Reason Code" as your lookup table, then you could use from the "Reason Code" table field "1" which represents the field "Code" on that table. When someone is recording a test, and choosing the test value they would then see as options the values from this field.';
            MinValue = 0;
            TableRelation = Field."No." where(TableNo = field("Lookup Table No."));

            trigger OnLookup()
            var
                CurrentField: Record "Field";
            begin
                if "Lookup Table No." <> 0 then begin
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
        }
        field(14; "Wizard Internal"; Enum "Qlty. Field Wizard State")
        {
            Caption = '(internal use) Field Wizard State';
            Description = '(internal use) Field Wizard State';
            DataClassification = SystemMetadata;
        }
        field(15; "Example Value"; Text[250])
        {
            Caption = 'Example Value';
            Description = '(internal) Used for a variety of buffers.';
        }
        field(16; "Default Value"; Text[250])
        {
            Caption = 'Default Value';
            ToolTip = 'Specifies a default value to set on the test.';

            trigger OnValidate()
            begin
                Rec.ValidateAllowableValuesOnDefault();
            end;
        }
        field(17; "Case Sensitive"; Enum "Qlty. Case Sensitivity")
        {
            Caption = 'Case Sensitivity';
            Description = 'Specifies if case sensitivity will be enabled for text-based fields.';
            ToolTip = 'Specifies if case sensitivity will be enabled for text-based fields.';
        }
        field(18; "Expression Formula"; Text[500])
        {
            Caption = 'Expression Formula';
            Description = 'Used with expression field types, this contains the formula for the expression content.';
            ToolTip = 'Specifies the formula for the expression content when using expression field types.';

            trigger OnValidate()
            begin
                if (Rec."Expression Formula" <> '') and not (Rec."Field Type" in [Rec."Field Type"::"Field Type Text Expression"]) then
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
        fieldgroup(DropDown; Code, Description, "Allowable Values", "Field Type")
        {
        }
        fieldgroup(Brick; Code, Description, "Example Value", "Allowable Values", "Field Type")
        {
        }
    }

    var
        FieldSelection: Codeunit "Field Selection";
        GenericFieldTok: Label 'MYFIELD', Locked = true;
        ThereIsNoGradeErr: Label 'There is no grade called "%1". Please add the grade, or change the existing grade conditions.', Comment = '%1=the grade';
        ReviewGradesErr: Label 'Advanced configuration required. Please review the grade configurations for field "%1", for grade "%2".', Comment = '%1=the field, %2=the grade';
        OnlyFieldExpressionErr: Label 'The Expression Formula can only be used with fields that are a type of Expression';
        BooleanChoiceListLbl: Label 'No,Yes';
        ExistingTestErr: Label 'The field %1 exists on %2 tests (such as %3 with template %4). The field can not be deleted if it is being used on a Quality Inspection Test.', Comment = '%1=the field, %2=count of tests, %3=one example test, %4=example template.';
        DeleteQst: Label 'The field %3 exists on %1 Quality Inspection Template(s) (such as template %2) that will be deleted. Do you wish to proceed? ', Comment = '%1 = the lines, %2= the Template Code, %3=the field';
        DeleteErr: Label 'The field %3 exists on %1 Quality Inspection Template(s) (such as template %2) and can not be deleted until it is no longer used on templates.', Comment = '%1 = the lines, %2= the Template Code, %3=the field';
        FieldTypeErrTitleMsg: Label 'Field Type cannot be changed for a field that has been used in tests. ';
        FieldTypeErrInfoMsg: Label '%1Consider replacing this field in the template with a new one, or deleting existing tests (if allowed). The field was last used on test %2.', Comment = '%1 = Error Title, %2 = Quality Inspection Test No.';

    /// <summary>
    /// Set a specific grade for the field. If AllowError is set to true it will error
    /// when a problem occurs. If AllowError is set to false it will just return false
    /// when a problem occurs.
    /// </summary>
    /// <param name="Grade"></param>
    /// <param name="Condition"></param>
    /// <param name="AllowError"></param>
    /// <returns></returns>
    procedure SetGradeCondition(Grade: Text; Condition: Text; AllowError: Boolean): Boolean
    var
        ExistingQltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
        QltyInspectionGrade: Record "Qlty. Inspection Grade";
        QltyGradeConditionMgmt: Codeunit "Qlty. Grade Condition Mgmt.";
    begin
        if not QltyInspectionGrade.Get(CopyStr(Grade, 1, MaxStrLen(QltyInspectionGrade.Code))) then
            if AllowError then
                Error(ThereIsNoGradeErr, Grade)
            else
                exit(false);

        QltyGradeConditionMgmt.CopyGradeConditionsFromDefaultToField(Rec.Code, Rec."Field Type");
        ExistingQltyIGradeConditionConf.SetRange("Field Code", Rec.Code);
        ExistingQltyIGradeConditionConf.SetRange("Target Code", Rec.Code);
        ExistingQltyIGradeConditionConf.SetRange("Grade Code", QltyInspectionGrade.Code);
        ExistingQltyIGradeConditionConf.SetRange("Condition Type", ExistingQltyIGradeConditionConf."Condition Type"::Field);

        if ExistingQltyIGradeConditionConf.Count() <> 1 then
            if AllowError then
                Error(ReviewGradesErr, Rec.Code, QltyInspectionGrade.Code)
            else
                exit(false);

        if ExistingQltyIGradeConditionConf.FindFirst() then begin
            ExistingQltyIGradeConditionConf.Validate(Condition, CopyStr(Condition, 1, MaxStrLen(ExistingQltyIGradeConditionConf.Condition)));

            exit(ExistingQltyIGradeConditionConf.Modify());
        end else
            exit(false);
    end;

    /// <summary>
    /// Starts the appropriate 'assist edit' dialog for the given data type and conditions.
    /// </summary>
    procedure AssistEditDefaultValue()
    var
        Handled: Boolean;
    begin
        OnBeforeAssistEditDefaultValue(Rec, Handled);
        if Handled then
            exit;

        case Rec."Field Type" of
            Rec."Field Type"::"Field Type Option":
                AssistEditChooseFromList(Rec."Allowable Values");
            Rec."Field Type"::"Field Type Table Lookup":
                AssistEditChooseFromTableLookup();
            Rec."Field Type"::"Field Type Boolean":
                AssistEditChooseFromList(BooleanChoiceListLbl);
            Rec."Field Type"::"Field Type Text":
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
        TempBufferQltyLookupCode: Record "Qlty. Lookup Code" temporary;
    begin
        Rec.CollectAllowableValues(TempBufferQltyLookupCode, Rec."Default Value");
        if Page.RunModal(Page::"Qlty. Lookup Field Choose", TempBufferQltyLookupCode) = Action::LookupOK then
            Rec.Validate("Default Value", CopyStr(TempBufferQltyLookupCode."Custom 1", 1, MaxStrLen(Rec."Default Value")));
    end;

    internal procedure AssistEditFreeText()
    var
        QltyEditLargeText: Page "Qlty. Edit Large Text";
        ExistingText: Text;
    begin
        ExistingText := Rec."Default Value";

        if QltyEditLargeText.RunModalWith(ExistingText) in [Action::LookupOK, Action::OK, Action::Yes] then
            Rec."Default Value" := CopyStr(ExistingText, 1, MaxStrLen(Rec."Default Value"));
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
        Value: Text;
    begin
        Value := Rec."Lookup Table Filter";
        QltyFilterHelpers.BuildFilter(Rec."Lookup Table No.", true, Value);
        if (Value <> Rec."Lookup Table Filter") and (Value <> '') then
            Rec."Lookup Table Filter" := CopyStr(Value, 1, MaxStrLen(Rec."Lookup Table Filter"));
    end;

    /// <summary>
    /// This is basically to make a summary for the human to see more easily when configuring templates and fields.
    /// This data isn't actually used during execution.
    /// </summary>
    procedure UpdateAllowedValuesFromTableLookup()
    var
        QltyMiscHelpers: Codeunit "Qlty. Misc Helpers";
        EntireList: Text;
    begin
        if Rec."Field Type" <> Rec."Field Type"::"Field Type Table Lookup" then
            exit;

        EntireList := QltyMiscHelpers.GetCSVOfValuesFromRecord(Rec."Lookup Table No.", Rec."Lookup Field No.", Rec."Lookup Table Filter");
        Rec."Allowable Values" := CopyStr(EntireList, 1, MaxStrLen(Rec."Allowable Values"));
    end;

    trigger OnModify()
    begin
        if Rec."Field Type" = Rec."Field Type"::"Field Type Table Lookup" then
            UpdateAllowedValuesFromTableLookup();
    end;

    trigger OnInsert()
    begin
        if Rec."Field Type" = Rec."Field Type"::"Field Type Table Lookup" then
            UpdateAllowedValuesFromTableLookup();
    end;

    trigger OnDelete()
    begin
        EnsureCanBeDeleted(false);
    end;

    procedure EnsureCanBeDeleted(AskQuestion: Boolean)
    var
        QltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        QltyInspectionTestLine: Record "Qlty. Inspection Test Line";
        LineCount: Integer;
        CanBeDeleted: Boolean;
    begin
        QltyInspectionTestLine.SetRange("Field Code", Rec.Code);
        LineCount := QltyInspectionTestLine.Count();
        if LineCount > 0 then begin
            QltyInspectionTestLine.FindFirst();
            Error(ExistingTestErr,
                QltyInspectionTestLine."Field Code",
                LineCount,
                QltyInspectionTestLine."Test No.",
                QltyInspectionTestLine."Template Code");
        end;

        QltyInspectionTemplateLine.SetRange("Field Code", Rec.Code);
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

    internal procedure SuggestUnusedFieldCodeFromDescription(InputDescription: Text; var SuggestionCode: Code[20])
    var
        DummyListOptionalAdditionalUsed: List of [Text];
    begin
        SuggestUnusedFieldCodeFromDescriptionAndList(InputDescription, DummyListOptionalAdditionalUsed, SuggestionCode);
    end;

    internal procedure SuggestUnusedFieldCodeFromDescriptionAndList(InputDescription: Text; IgnoredListOptionalAdditionalUsed: List of [Text]; var SuggestionCode: Code[20])
    begin
        GenerateShortFieldCodeFromLongerText(InputDescription, SuggestionCode);
        EnsureUnusedCode(SuggestionCode, IgnoredListOptionalAdditionalUsed);
    end;

    internal procedure GenerateShortFieldCodeFromLongerText(Input: Text; var SuggestionCode: Code[20])
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
    /// Takes the supplied field code, and ensures it's unique.
    /// If the supplied field code has already been used then it will suggest an alternative.
    /// </summary>
    /// <param name="Suggestion"></param>
    local procedure EnsureUnusedCode(var Suggestion: Code[20]; OptionalAdditionalUSed: List of [Text])
    var
        QltyField: Record "Qlty. Field";
        TempNumber: Text;
        OriginalSuggestion: Text;
        Iterator: Integer;
        FieldAlreadyExists: Boolean;
    begin
        if Suggestion = '' then
            Suggestion := GenericFieldTok;
        OriginalSuggestion := Suggestion;

        Iterator := 1;
        repeat
            Iterator += 1;
            FieldAlreadyExists := false;
            FieldAlreadyExists := OptionalAdditionalUSed.Contains(Suggestion);
            if not FieldAlreadyExists then begin
                QltyField.Reset();
                QltyField.SetRange(Code, Suggestion);
                FieldAlreadyExists := QltyField.FindFirst();
            end;
            if FieldAlreadyExists then begin
                TempNumber := Format(Iterator, 0, 9);
                TempNumber := PadStr('', 4 - StrLen(TempNumber), '0') + TempNumber;
                Suggestion := CopyStr(CopyStr(OriginalSuggestion, 1, MaxStrLen(Suggestion) - StrLen(TempNumber)), 1, MaxStrLen(Suggestion));
                Suggestion := CopyStr(Suggestion + TempNumber, 1, MaxStrLen(Suggestion));
            end;
        until (not FieldAlreadyExists) or (Iterator >= 9999);
    end;

    /// <summary>
    /// Validates that the default value is allowable.
    /// </summary>
    procedure ValidateAllowableValuesOnDefault()
    var
        QltyGradeEvaluation: Codeunit "Qlty. Grade Evaluation";
    begin
        QltyGradeEvaluation.ValidateAllowableValuesOnField(Rec);
    end;

    /// <summary>
    /// Code = the unique code
    /// Description = raw description.
    /// Custom 1 = original value
    /// Custom 2 = lowercase value
    /// Custom 3 = uppercase value.
    /// </summary>
    /// <param name="ContextQltyInspectionTestHeader">Supply if you want to give a test, this is useful for table lookups which can have additional values.</param>
    /// <param name="TempBufferQltyLookupCode"></param>
    /// <param name="OptionalSetToValue">Leave empty to ignore. Supply a value to have the record auto-filtered to the supplied record that matches</param>
    procedure CollectAllowableValues(var TempBufferQltyLookupCode: Record "Qlty. Lookup Code" temporary; OptionalSetToValue: Text)
    var
        TempDummyContextQltyInspectionTestHeader: Record "Qlty. Inspection Test Header" temporary;
        TempDummyContextQltyInspectionTestLine: Record "Qlty. Inspection Test Line" temporary;
    begin
        CollectAllowableValues(TempDummyContextQltyInspectionTestHeader, TempDummyContextQltyInspectionTestLine, TempBufferQltyLookupCode, OptionalSetToValue);
    end;

    procedure CollectAllowableValues(var OptionalContextQltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; var OptionalContextQltyInspectionTestLine: Record "Qlty. Inspection Test Line"; var TempBufferQltyLookupCode: Record "Qlty. Lookup Code" temporary; OptionalSetToValue: Text)
    var
        QltyMiscHelpers: Codeunit "Qlty. Misc Helpers";
        OfChoices: List of [Text];
        Choice: Text;
    begin
        case Rec."Field Type" of
            Rec."Field Type"::"Field Type Table Lookup":
                begin
                    QltyMiscHelpers.GetRecordsForTableField(Rec, OptionalContextQltyInspectionTestHeader, OptionalContextQltyInspectionTestLine, TempBufferQltyLookupCode);
                    if TempBufferQltyLookupCode.FindSet() then begin
                        if OptionalSetToValue <> '' then begin
                            TempBufferQltyLookupCode.SetRange(Code, CopyStr(OptionalSetToValue, 1, MaxStrLen(TempBufferQltyLookupCode.Code)));
                            if not TempBufferQltyLookupCode.FindSet() then begin
                                TempBufferQltyLookupCode.SetRange(Description, CopyStr(OptionalSetToValue, 1, MaxStrLen(TempBufferQltyLookupCode.Description)));
                                if not TempBufferQltyLookupCode.FindSet() then;
                            end;
                        end;
                        TempBufferQltyLookupCode.SetRange(Code);
                        TempBufferQltyLookupCode.SetRange(Description);
                    end;
                end;
            Rec."Field Type"::"Field Type Option":
                begin
                    TempBufferQltyLookupCode.Reset();
                    OfChoices := Rec."Allowable Values".Split(',');
                    foreach Choice in OfChoices do begin
                        Choice := Choice.Trim();
                        TempBufferQltyLookupCode.Code := CopyStr(Choice, 1, MaxStrLen(TempBufferQltyLookupCode.Code));
                        TempBufferQltyLookupCode.Description := CopyStr(Choice, 1, MaxStrLen(TempBufferQltyLookupCode.Description));
                        TempBufferQltyLookupCode."Custom 1" := CopyStr(Choice, 1, MaxStrLen(TempBufferQltyLookupCode."Custom 1"));
                        TempBufferQltyLookupCode."Custom 2" := TempBufferQltyLookupCode."Custom 1".ToLower();
                        TempBufferQltyLookupCode."Custom 3" := TempBufferQltyLookupCode."Custom 1".ToUpper();
                        if TempBufferQltyLookupCode.Insert() then;
                    end;
                end;
        end;
    end;

    internal procedure HandleOnValidateFieldType(AllowActionableError: Boolean)
    var
        QltyInspectionTestLine: Record "Qlty. Inspection Test Line";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        QltyGradeConditionMgmt: Codeunit "Qlty. Grade Condition Mgmt.";
    begin
        Rec."Allowable Values" := '';
        Rec.Validate("Lookup Table No.", 0);
        Rec.Validate("Lookup Field No.", 0);
        Rec."Lookup Table Filter" := '';
        QltyInspectionTestLine.SetRange("Field Code", Rec.Code);
        if QltyInspectionTestLine.FindLast() then begin
            if QltyInspectionTestHeader.Get(QltyInspectionTestLine."Test No.", QltyInspectionTestLine."Retest No.") then;
            if AllowActionableError then
                Error(FieldTypeErrInfoMsg, FieldTypeErrTitleMsg, QltyInspectionTestHeader."No.")
            else
                Error(FieldTypeErrInfoMsg, FieldTypeErrTitleMsg, QltyInspectionTestHeader."No.");
        end;
        QltyGradeConditionMgmt.CopyGradeConditionsFromDefaultToField(Rec.Code, Rec."Field Type");
    end;

    procedure AssistEditExpressionFormula()
    var
        QltyInspectionTemplateEdit: Page "Qlty. Inspection Template Edit";
        Expression: Text;
    begin
        if not (Rec."Field Type" in [Rec."Field Type"::"Field Type Text Expression"]) then
            Error(OnlyFieldExpressionErr);

        Expression := Rec."Expression Formula";

        if QltyInspectionTemplateEdit.RunModalWith(Database::"Qlty. Inspection Test Header", '', Expression) in [Action::LookupOK, Action::OK, Action::Yes] then begin
            Rec."Expression Formula" := CopyStr(Expression, 1, MaxStrLen(Rec."Expression Formula"));
            Rec.Modify();
        end;
    end;

    procedure AssistEditAllowableValues()
    var
        QltyLookupCode: Record "Qlty. Lookup Code";
        QltyInspectionTemplateEdit: Page "Qlty. Inspection Template Edit";
        Expression: Text;
        Handled: Boolean;
    begin
        OnBeforeAssistAllowableValues(Rec, QltyInspectionTemplateEdit, Handled);
        if Handled then
            exit;

        if Rec."Field Type" = Rec."Field Type"::"Field Type Table Lookup" then begin
            if (Rec.Code <> '') and (Rec."Lookup Table No." = Database::"Qlty. Lookup Code") then begin
                QltyLookupCode.SetRange("Group Code", Rec.Code);
                Page.RunModal(Page::"Qlty. Lookup Code List", QltyLookupCode);
            end;
            Rec.UpdateAllowedValuesFromTableLookup();
        end else begin
            Expression := Rec."Allowable Values";
            if QltyInspectionTemplateEdit.RunModalWith(Database::"Qlty. Inspection Test Header", '', Expression) in [Action::LookupOK, Action::OK, Action::Yes] then begin
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
        Handled: Boolean;
    begin
        OnGetIsNumericFieldType(Rec, IsNumeric, Handled);
        if Handled then
            exit;

        IsNumeric := Rec."Field Type" in [Rec."Field Type"::"Field Type Decimal",
                        Rec."Field Type"::"Field Type Integer"
                        ];
    end;

    /// <summary>
    /// Provides an opportunity to allow determining if the field is intended to be numeric or not.
    /// Use this if you are extending the data type enumeration and adding your own numeric field.
    /// </summary>
    /// <param name="QltyField"></param>
    /// <param name="IsNumeric"></param>
    /// <param name="Handled"></param>
    [IntegrationEvent(false, false)]
    local procedure OnGetIsNumericFieldType(var QltyField: Record "Qlty. Field"; var IsNumeric: Boolean; var Handled: Boolean)
    begin
    end;

    /// <summary>
    /// Provides an opportunity to extend or replace editing allowable values.
    /// </summary>
    /// <param name="QltyField"></param>
    /// <param name="QltyInspectionTemplateEdit"></param>
    /// <param name="Handled"></param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeAssistAllowableValues(var QltyField: Record "Qlty. Field"; QltyInspectionTemplateEdit: Page "Qlty. Inspection Template Edit"; var Handled: Boolean)
    begin
    end;

    /// <summary>
    /// Provides an ability to extend or replace assist editing the default value.
    /// </summary>
    /// <param name="QltyField"></param>
    /// <param name="Handled">Set to true to prevent base behavior from occurring.</param>
    [IntegrationEvent(false, false)]
    procedure OnBeforeAssistEditDefaultValue(var QltyField: Record "Qlty. Field"; var Handled: Boolean)
    begin
    end;
}
