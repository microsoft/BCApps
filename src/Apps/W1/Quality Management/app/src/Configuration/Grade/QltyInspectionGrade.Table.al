// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Configuration.Grade;

using Microsoft.QualityManagement.Document;

/// <summary>
/// A grade in it's simplest form would be something like PASS,FAIL,INPROGRESS
/// You could have multiple passing grades, and multiple failing grades.
/// Grades are effectively the incomplete/pass/fail state of a test. 
/// It is typical to have three grades (incomplete, fail, pass), however you can configure as many grades as you want, and in what circumstances. 
/// The grades with a lower number for the priority field are evaluated first. 
/// If you are not sure what to configure here then use the three defaults. 
/// The document specific lot/serial/package blocking is for item+variant+lot+serial+package combinations, and can be used for serial-only tracking, or package-only tracking.
/// </summary>
table 20411 "Qlty. Inspection Grade"
{
    Caption = 'Quality Inspection Grade';
    DrillDownPageID = "Qlty. Inspection Grade List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
            Description = 'The short name for the grade.';
            ToolTip = 'Specifies the short name for the grade.';

            trigger OnValidate()
            begin
                Rec."Code" := DelChr(Rec."Code", '=', ' ><{}.@!`~''"|\/?&*()');
            end;
        }
        field(2; "Description"; Text[100])
        {
            Caption = 'Description';
            NotBlank = true;
            Description = 'A friendly description for the grade.';
            ToolTip = 'Specifies a friendly description for the grade.';
        }
        field(3; "Evaluation Sequence"; Integer)
        {
            Description = 'The priority of the grade, this also defines the evaluation order. 0 gets evaluated first, 1 would get evaluated after, 2 evaluated after that. 0 is typically used for an incomplete / unfilled state. Lower numbers should be used to evaluate error scenarios where the default of ''notblank'' followed by failing grades. Higher numbers would typically be used for passing grades.';
            NotBlank = true;
            Caption = 'Evaluation Sequence';
            ToolTip = 'Specifies the effective priority of the grade, this also defines the evaluation order. Grades with lower numbers have higher priority and are evaluated first. Typically the pass conditions have a higher number than fail or inprogress conditions. ';
        }
        field(4; "Copy Behavior"; Enum "Qlty. Grade Copy Behavior")
        {
            Description = 'Whether to automatically configure this grade on new fields and new templates.';
            Caption = 'Copy Behavior';
            ToolTip = 'Specifies whether to automatically configure this grade on new fields and new templates.';
        }
        field(5; "Grade Visibility"; Enum "Qlty. Grade Visibility")
        {
            Description = 'Whether to try and make this grade more prominent, this can optionally be used on some reports and forms. Typically only the passing grades are promoted.';
            Caption = 'Grade Visibility';
            ToolTip = 'Specifies whether to promote the visibility. Pass conditions are typically promoted. A promoted rule will show on some pages more than others, such as the Certificate of Analysis.';
        }
        field(10; "Default Number Condition"; Text[500])
        {
            Caption = 'Default Number Condition';
            NotBlank = true;
            Description = 'The numerical related validation, this is the default condition of when this grade is activated.';
            ToolTip = 'Specifies the default condition of when this grade is activated.';

            trigger OnValidate()
            begin
                if (Rec."Default Number Condition" <> xRec."Default Number Condition") or
                   (Rec."Default Text Condition" <> xRec."Default Text Condition") or
                   (Rec."Default Boolean Condition" <> xRec."Default Boolean Condition")
                then begin
                    Rec.Modify();
                    QltyGradeConditionMgmt.PromptUpdateFieldsFromGradeIfApplicable(Rec.Code);
                end;
            end;
        }
        field(11; "Default Text Condition"; Text[500])
        {
            Caption = 'Default Text Condition';
            NotBlank = false;
            Description = 'For text related validation this is the default condition of when this grade is activated.';
            ToolTip = 'Specifies the default condition of when this grade is activated.';

            trigger OnValidate()
            begin
                if (Rec."Default Number Condition" <> xRec."Default Number Condition") or
                   (Rec."Default Text Condition" <> xRec."Default Text Condition") or
                   (Rec."Default Boolean Condition" <> xRec."Default Boolean Condition")
                then begin
                    Rec.Modify();
                    QltyGradeConditionMgmt.PromptUpdateFieldsFromGradeIfApplicable(Rec.Code);
                end;
            end;
        }
        field(12; "Default Boolean Condition"; Text[500])
        {
            Caption = 'Default Boolean Condition';
            NotBlank = false;
            Description = 'For Boolean related validation this is the default condition of when this grade is activated.';
            ToolTip = 'Specifies the default condition of when this grade is activated.';

            trigger OnValidate()
            begin
                if (Rec."Default Number Condition" <> xRec."Default Number Condition") or
                   (Rec."Default Text Condition" <> xRec."Default Text Condition") or
                   (Rec."Default Boolean Condition" <> xRec."Default Boolean Condition")
                then begin
                    Rec.Modify();
                    QltyGradeConditionMgmt.PromptUpdateFieldsFromGradeIfApplicable(Rec.Code);
                end;
            end;
        }
        field(13; "Grade Category"; Enum "Qlty. Grade Category")
        {
            Caption = 'Grade Category';
            Description = 'A general categorization of whether this grade represents a passing or failing grade.';
            ToolTip = 'Specifies a general categorization of whether this grade represents good or bad.';
        }
        field(20; "Lot Allow Sales"; Enum "Qlty. Item Trkg Block Behavior")
        {
            Description = 'When a test for a lot/serial/package has this grade this determines whether or not to allow sales transactions.';
            Caption = 'Allow Sales';
            ToolTip = 'Specifies whether a test for a lot/serial/package with this grade allows sales transactions.';
        }
        field(21; "Lot Allow Assembly Consumption"; Enum "Qlty. Item Trkg Block Behavior")
        {
            Caption = 'Allow Assembly Consumption';
            ToolTip = 'Specifies whether a test for a lot/serial/package with this grade allows Assembly Consumption transactions.';
        }
        field(22; "Lot Allow Consumption"; Enum "Qlty. Item Trkg Block Behavior")
        {
            Caption = 'Allow Consumption';
            Description = 'When a test for a lot/serial/package has this grade this determines whether or not to allow Consumption transactions.';
            ToolTip = 'Specifies whether a test for a lot/serial/package with this grade allows Consumption transactions.';
        }
        field(23; "Lot Allow Output"; Enum "Qlty. Item Trkg Block Behavior")
        {
            Caption = 'Allow Output';
            Description = 'When a test for a lot/serial/package has this grade this determines whether or not to allow Output transactions.';
            ToolTip = 'Specifies whether a test for a lot/serial/package with this grade allows Output transactions.';
        }
        field(24; "Lot Allow Purchase"; Enum "Qlty. Item Trkg Block Behavior")
        {
            Description = 'When a test for a lot/serial/package has this grade this determines whether or not to allow Purchase transactions.';
            Caption = 'Allow Purchase';
            ToolTip = 'Specifies whether a test for a lot/serial/package with this grade allows Purchase transactions.';
        }
        field(25; "Lot Allow Transfer"; Enum "Qlty. Item Trkg Block Behavior")
        {
            Caption = 'Allow Transfer';
            Description = 'When a test for a lot/serial/package has this grade this determines whether or not to allow Transfer transactions.';
            ToolTip = 'Specifies whether a test for a lot/serial/package with this grade allows Transfer transactions.';
        }
        field(26; "Lot Allow Assembly Output"; Enum "Qlty. Item Trkg Block Behavior")
        {
            Description = 'When a test for a lot/serial/package has this grade this determines whether or not to allow Assembly Output transactions.';
            Caption = 'Allow Assembly Output';
            ToolTip = 'Specifies whether a test for a lot/serial/package with this grade allows Assembly Output transactions.';
        }
        field(27; "Lot Allow Invt. Movement"; Enum "Qlty. Item Trkg Block Behavior")
        {
            Description = 'When a test for a lot/serial/package has this grade this determines whether or not to allow Inventory Movement transactions.';
            Caption = 'Allow Inventory Movement';
            ToolTip = 'Specifies whether a test for a lot/serial/package with this grade allows Inventory Movement transactions.';
        }
        field(28; "Lot Allow Invt. Pick"; Enum "Qlty. Item Trkg Block Behavior")
        {
            Description = 'When a test for a lot/serial/package has this grade this determines whether or not to allow Inventory Pick transactions.';
            Caption = 'Allow Inventory Pick';
            ToolTip = 'Specifies whether a test for a lot/serial/package with this grade allows Inventory Pick transactions.';
        }
        field(29; "Lot Allow Invt. Put-Away"; Enum "Qlty. Item Trkg Block Behavior")
        {
            Description = 'When a test for a lot/serial/package has this grade this determines whether or not to allow Inventory Put-Away transactions.';
            Caption = 'Allow Inventory Put-Away';
            ToolTip = 'Specifies whether a test for a lot/serial/package with this grade allows Inventory Put-Away transactions.';
        }
        field(30; "Lot Allow Movement"; Enum "Qlty. Item Trkg Block Behavior")
        {
            Description = 'When a test for a lot/serial/package has this grade this determines whether or not to allow Warehouse Movement transactions.';
            Caption = 'Allow Movement';
            ToolTip = 'Specifies whether a test for a lot/serial/package with this grade allows Inventory Movement transactions.';
        }
        field(31; "Lot Allow Pick"; Enum "Qlty. Item Trkg Block Behavior")
        {
            Description = 'When a test for a lot/serial/package has this grade this determines whether or not to allow Pick transactions.';
            Caption = 'Allow Pick';
            ToolTip = 'Specifies whether a test for a lot/serial/package with this grade allows Pick transactions.';
        }
        field(32; "Lot Allow Put-Away"; Enum "Qlty. Item Trkg Block Behavior")
        {
            Description = 'When a test for a lot/serial/package has this grade this determines whether or not to allow Put-Away transactions.';
            Caption = 'Allow Put-Away';
            ToolTip = 'Specifies whether a test for a lot/serial/package with this grade allows Put-Away transactions.';
        }
        field(50; "Override Style"; Text[100])
        {
            Caption = 'Override Style';
            Description = 'Allows you to define a specific style for this grade. Leave blank to use defaults.';
            ToolTip = 'Specifies a specific style for this grade. Leave blank to use defaults.';
        }
    }

    keys
    {
        key(Key1; Code)
        {
            Clustered = true;
        }
        key(Key2; "Evaluation Sequence")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Evaluation Sequence", Code, Description)
        {
        }
    }

    var
        QltyGradeConditionMgmt: Codeunit "Qlty. Grade Condition Mgmt.";
        RowStyle: Option None,Standard,StandardAccent,Strong,StrongAccent,Attention,AttentionAccent,Favorable,Unfavorable,Ambiguous,Subordinate;
        RowStyleOptionsTok: Label 'None,Standard,StandardAccent,Strong,StrongAccent,Attention,AttentionAccent,Favorable,Unfavorable,Ambiguous,Subordinate', Locked = true;
        CannotBeRemovedExistingTestErr: Label 'This grade cannot be removed because it is being used actively on at least one existing Quality Inspection Test. If you no longer want to use this grade consider changing the description, or consider changing the visibility not to be promoted. You can also change the "Copy" setting on the grade.';
        PromptFirstExistingTestQst: Label 'This grade, although not set on a test, is available to previous tests. Are you sure you want to remove this grade? This cannot be undone.';
        PromptFirstExistingTemplateQst: Label 'This grade is currently defined on some Quality Inspection Templates. Are you sure you want to remove this grade? This cannot be undone.';
        PromptFirstExistingFieldQst: Label 'This grade is currently defined on some fields. Are you sure you want to remove this grade? This cannot be undone.';

    trigger OnInsert()
    begin
        AutoSetGradeCategoryFromName();
    end;

    trigger OnModify()
    begin
        AutoSetGradeCategoryFromName();
        UpdateExistingConditions();
    end;

    procedure AutoSetGradeCategoryFromName()
    begin
        if Rec."Grade Category" <> Rec."Grade Category"::Uncategorized then
            exit;

        case Rec.Code of
            'PASS', 'GOOD', 'ACCEPTABLE':
                Rec."Grade Category" := Rec."Grade Category"::Acceptable;
            'FAIL', 'BAD', 'UNACCEPTABLE', 'ERROR', 'REJECT':
                Rec."Grade Category" := Rec."Grade Category"::"Not acceptable";
        end;
    end;

    trigger OnDelete()
    var
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        QltyInspectionTestLine: Record "Qlty. Inspection Test Line";
        QltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
    begin
        if Rec.Code = '' then
            exit;

        QltyInspectionTestLine.SetRange("Grade Code", Rec.Code);
        if not QltyInspectionTestLine.IsEmpty() then
            Error(CannotBeRemovedExistingTestErr);

        QltyInspectionTestHeader.SetRange("Grade Code", Rec.Code);
        if not QltyInspectionTestHeader.IsEmpty() then
            Error(CannotBeRemovedExistingTestErr);

        QltyIGradeConditionConf.SetRange("Condition Type", QltyIGradeConditionConf."Condition Type"::Test);
        QltyIGradeConditionConf.SetRange("Grade Code", Rec.Code);
        if not QltyIGradeConditionConf.IsEmpty() then
            if not Confirm(PromptFirstExistingTestQst) then
                Error('');

        QltyIGradeConditionConf.Reset();
        QltyIGradeConditionConf.SetRange("Condition Type", QltyIGradeConditionConf."Condition Type"::Field);
        QltyIGradeConditionConf.SetRange("Grade Code", Rec.Code);
        if not QltyIGradeConditionConf.IsEmpty() then
            if not Confirm(PromptFirstExistingFieldQst) then
                Error('');

        QltyIGradeConditionConf.Reset();
        QltyIGradeConditionConf.SetRange("Condition Type", QltyIGradeConditionConf."Condition Type"::Template);
        QltyIGradeConditionConf.SetRange("Grade Code", Rec.Code);
        if not QltyIGradeConditionConf.IsEmpty() then
            if not Confirm(PromptFirstExistingTemplateQst) then
                Error('');

        QltyIGradeConditionConf.Reset();
        QltyIGradeConditionConf.SetRange("Grade Code", Rec.Code);
        QltyIGradeConditionConf.DeleteAll();
    end;

    local procedure UpdateExistingConditions()
    var
        QltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
    begin
        QltyIGradeConditionConf.SetRange("Grade Code", Rec.Code);
        QltyIGradeConditionConf.ModifyAll(Priority, Rec."Evaluation Sequence", false);
        QltyIGradeConditionConf.ModifyAll("Grade Visibility", Rec."Grade Visibility", false);
    end;

    /// <summary>
    /// Provides an ability to assist edit the grade style.
    /// The standard Business Central grade styles will be shown.
    /// </summary>
    procedure AssistEditGradeStyle()
    var
        Selection: Integer;
    begin
        Selection := StrMenu(RowStyleOptionsTok);
        if Selection > 0 then
            Rec."Override Style" := CopyStr(SelectStr(Selection, RowStyleOptionsTok), 1, MaxStrLen(Rec."Override Style"));
    end;

    /// <summary>
    /// Gets the grade style to use for this grade.
    /// If there is an override style then it will be used.
    /// If there is no override style then it will make an assumption based on the category.
    /// </summary>
    /// <returns></returns>
    procedure GetGradeStyle(): Text
    begin
        if Rec."Override Style" <> '' then
            exit(Rec."Override Style");

        case Rec."Grade Category" of
            Rec."Grade Category"::"Not acceptable":
                exit(Format(RowStyle::Unfavorable));
            Rec."Grade Category"::Acceptable:
                exit(Format(RowStyle::Favorable));
            else
                exit(Format(RowStyle::None));
        end;
    end;
}
