// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Configuration.Result;

using Microsoft.QualityManagement.Document;

/// <summary>
/// A result in it's simplest form would be something like PASS,FAIL,INPROGRESS
/// You could have multiple passing results, and multiple failing results.
/// Results are effectively the incomplete/pass/fail state of an inspection. 
/// It is typical to have three results (incomplete, fail, pass), however you can configure as many results as you want, and in what circumstances. 
/// The results with a lower number for the priority tests are evaluated first. 
/// If you are not sure what to configure here then use the three defaults. 
/// The document specific item tracking blocking is for item+variant+item tracking combinations, and can be used for serial-only tracking, or package-only tracking.
/// </summary>
table 20411 "Qlty. Inspection Result"
{
    Caption = 'Quality Inspection Result';
    LookupPageId = "Qlty. Inspection Result List";
    DrillDownPageId = "Qlty. Inspection Result List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
            ToolTip = 'Specifies the short name for the result.';

            trigger OnValidate()
            begin
                Rec."Code" := DelChr(Rec."Code", '=', ' ><{}.@!`~''"|\/?&*()');
            end;
        }
        field(2; "Description"; Text[100])
        {
            Caption = 'Description';
            NotBlank = true;
            ToolTip = 'Specifies a friendly description for the result.';
        }
        field(3; "Evaluation Sequence"; Integer)
        {
            NotBlank = true;
            Caption = 'Evaluation Sequence';
            ToolTip = 'Specifies the effective priority of the result, this also defines the evaluation order. Results with lower numbers have higher priority and are evaluated first. Typically the pass conditions have a higher number than fail or inprogress conditions.';
        }
        field(4; "Copy Behavior"; Enum "Qlty. Result Copy Behavior")
        {
            Caption = 'Copy Behavior';
            ToolTip = 'Specifies whether to automatically configure this result on new tests and new templates.';
        }
        field(5; "Result Visibility"; Enum "Qlty. Result Visibility")
        {
            Caption = 'Result Visibility';
            ToolTip = 'Specifies whether to promote the visibility. Pass conditions are typically promoted. A promoted rule will show on some pages more than others, such as the Certificate of Analysis.';
        }
        field(10; "Default Number Condition"; Text[500])
        {
            Caption = 'Default Number Condition';
            NotBlank = true;
            ToolTip = 'Specifies the default condition of when this result is activated.';

            trigger OnValidate()
            begin
                if ((Rec."Default Number Condition" <> xRec."Default Number Condition") or
                   (Rec."Default Text Condition" <> xRec."Default Text Condition") or
                   (Rec."Default Boolean Condition" <> xRec."Default Boolean Condition")) and
                   (Rec."Copy Behavior" in [Rec."Copy Behavior"::"Automatically copy the result"])
                then
                    QltyResultConditionMgmt.PromptUpdateTestsFromResultIfApplicable(Rec.Code);
            end;
        }
        field(11; "Default Text Condition"; Text[500])
        {
            Caption = 'Default Text Condition';
            NotBlank = false;
            ToolTip = 'Specifies the default condition of when this result is activated.';

            trigger OnValidate()
            begin
                if ((Rec."Default Number Condition" <> xRec."Default Number Condition") or
                   (Rec."Default Text Condition" <> xRec."Default Text Condition") or
                   (Rec."Default Boolean Condition" <> xRec."Default Boolean Condition")) and
                   (Rec."Copy Behavior" in [Rec."Copy Behavior"::"Automatically copy the result"])
                then
                    QltyResultConditionMgmt.PromptUpdateTestsFromResultIfApplicable(Rec.Code);
            end;
        }
        field(12; "Default Boolean Condition"; Text[500])
        {
            Caption = 'Default Boolean Condition';
            NotBlank = false;
            ToolTip = 'Specifies the default condition of when this result is activated.';

            trigger OnValidate()
            begin
                if ((Rec."Default Number Condition" <> xRec."Default Number Condition") or
                   (Rec."Default Text Condition" <> xRec."Default Text Condition") or
                   (Rec."Default Boolean Condition" <> xRec."Default Boolean Condition")) and
                   (Rec."Copy Behavior" in [Rec."Copy Behavior"::"Automatically copy the result"])
                then
                    QltyResultConditionMgmt.PromptUpdateTestsFromResultIfApplicable(Rec.Code);
            end;
        }
        field(13; "Result Category"; Enum "Qlty. Result Category")
        {
            Caption = 'Result Category';
            ToolTip = 'Specifies a general categorization of whether this result represents a passing or failing result.';
        }
        field(14; "Finish Allowed"; Enum "Qlty. Result Finish Allowed")
        {
            Caption = 'Finish Allowed';
            ToolTip = 'Specifies if an inspection can be finished given the applicable result.';
            InitValue = "Allow Finish";
        }
        field(20; "Item Tracking Allow Sales"; Enum "Qlty. Item Trkg Block Behavior")
        {
            Caption = 'Allow Sales';
            ToolTip = 'Specifies whether an inspection for an item tracking with this result allows sales transactions.';
        }
        field(21; "Item Tracking Allow Asm. Cons."; Enum "Qlty. Item Trkg Block Behavior")
        {
            Caption = 'Allow Assembly Consumption';
            ToolTip = 'Specifies whether an inspection for an item tracking with this result allows Assembly Consumption transactions.';
        }
        field(22; "Item Tracking Allow Consump."; Enum "Qlty. Item Trkg Block Behavior")
        {
            Caption = 'Allow Consumption';
            ToolTip = 'Specifies whether an inspection for an item tracking with this result allows Consumption transactions.';
        }
        field(23; "Item Tracking Allow Output"; Enum "Qlty. Item Trkg Block Behavior")
        {
            Caption = 'Allow Output';
            ToolTip = 'Specifies whether an inspection for an item tracking with this result allows Output transactions.';
        }
        field(24; "Item Tracking Allow Purchase"; Enum "Qlty. Item Trkg Block Behavior")
        {
            Caption = 'Allow Purchase';
            ToolTip = 'Specifies whether an inspection for an item tracking with this result allows Purchase transactions.';
        }
        field(25; "Item Tracking Allow Transfer"; Enum "Qlty. Item Trkg Block Behavior")
        {
            Caption = 'Allow Transfer';
            ToolTip = 'Specifies whether an inspection for an item tracking with this result allows Transfer transactions.';
        }
        field(26; "Item Tracking Allow Asm. Out."; Enum "Qlty. Item Trkg Block Behavior")
        {
            Caption = 'Allow Assembly Output';
            ToolTip = 'Specifies whether an inspection for an item tracking with this result allows Assembly Output transactions.';
        }
        field(27; "Item Tracking Allow Invt. Mov."; Enum "Qlty. Item Trkg Block Behavior")
        {
            Caption = 'Allow Inventory Movement';
            ToolTip = 'Specifies whether an inspection for an item tracking with this result allows Inventory Movement transactions.';
        }
        field(28; "Item Tracking Allow Invt. Pick"; Enum "Qlty. Item Trkg Block Behavior")
        {
            Caption = 'Allow Inventory Pick';
            ToolTip = 'Specifies whether an inspection for an item tracking with this result allows Inventory Pick transactions.';
        }
        field(29; "Item Tracking Allow Invt. PA"; Enum "Qlty. Item Trkg Block Behavior")
        {
            Caption = 'Allow Inventory Put-Away';
            ToolTip = 'Specifies whether an inspection for an item tracking with this result allows Inventory Put-Away transactions.';
        }
        field(30; "Item Tracking Allow Movement"; Enum "Qlty. Item Trkg Block Behavior")
        {
            Caption = 'Allow Movement';
            ToolTip = 'Specifies whether an inspection for an item tracking with this result allows Inventory Movement transactions.';
        }
        field(31; "Item Tracking Allow Pick"; Enum "Qlty. Item Trkg Block Behavior")
        {
            Caption = 'Allow Pick';
            ToolTip = 'Specifies whether an inspection for an item tracking with this result allows Pick transactions.';
        }
        field(32; "Item Tracking Allow Put-Away"; Enum "Qlty. Item Trkg Block Behavior")
        {
            Caption = 'Allow Put-Away';
            ToolTip = 'Specifies whether an inspection for an item tracking with this result allows Put-Away transactions.';
        }
        field(50; "Override Style"; Text[100])
        {
            Caption = 'Override Style';
            ToolTip = 'Specifies a specific style for this result. Leave blank to use defaults.';
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
        key(Key3; "Result Visibility", "Evaluation Sequence")
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
        QltyResultConditionMgmt: Codeunit "Qlty. Result Condition Mgmt.";
        RowStyle: Option None,Standard,StandardAccent,Strong,StrongAccent,Attention,AttentionAccent,Favorable,Unfavorable,Ambiguous,Subordinate;
        RowStyleOptionsTok: Label 'None,Standard,StandardAccent,Strong,StrongAccent,Attention,AttentionAccent,Favorable,Unfavorable,Ambiguous,Subordinate', Locked = true;
        CannotBeRemovedExistingInspectionErr: Label 'This result cannot be removed because it is being used actively on at least one existing Quality Inspection. If you no longer want to use this result consider changing the description, or consider changing the visibility not to be promoted. You can also change the "Copy" setting on the result.';
        PromptFirstExistingInspectionQst: Label 'This result, although not set on an inspection, is available to previous inspections. Are you sure you want to remove this result? This cannot be undone.';
        PromptFirstExistingTemplateQst: Label 'This result is currently defined on some Quality Inspection Templates. Are you sure you want to remove this result? This cannot be undone.';
        PromptFirstExistingTestQst: Label 'This result is currently defined on some tests. Are you sure you want to remove this result? This cannot be undone.';
        DefaultResultInProgressCodeLbl: Label 'INPROGRESS', Locked = true, MaxLength = 20;
        ResultCodePassLbl: Label 'PASS', MaxLength = 20;
        ResultCodeGoodLbl: Label 'GOOD', MaxLength = 20;
        ResultCodeAcceptableLbl: Label 'ACCEPTABLE', MaxLength = 20;
        ResultCodeFailLbl: Label 'FAIL', MaxLength = 20;
        ResultCodeBadLbl: Label 'BAD', MaxLength = 20;
        ResultCodeUnacceptableLbl: Label 'UNACCEPTABLE', MaxLength = 20;
        ResultCodeErrorLbl: Label 'ERROR', MaxLength = 20;
        ResultCodeRejectLbl: Label 'REJECT', MaxLength = 20;

    trigger OnInsert()
    begin
        AutoSetResultCategoryFromName();

        if Rec.Code = DefaultResultInProgressCodeLbl then
            Rec."Finish Allowed" := Rec."Finish Allowed"::"Do Not Allow Finish";
    end;

    trigger OnModify()
    begin
        AutoSetResultCategoryFromName();
        UpdateExistingConditions();
    end;

    internal procedure AutoSetResultCategoryFromName()
    begin
        if Rec."Result Category" <> Rec."Result Category"::Uncategorized then
            exit;

        case Rec.Code of
            ResultCodePassLbl, ResultCodeGoodLbl, ResultCodeAcceptableLbl:
                Rec."Result Category" := Rec."Result Category"::Acceptable;
            ResultCodeFailLbl, ResultCodeBadLbl, ResultCodeUnacceptableLbl, ResultCodeErrorLbl, ResultCodeRejectLbl:
                Rec."Result Category" := Rec."Result Category"::"Not acceptable";
        end;
    end;

    trigger OnDelete()
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionLine: Record "Qlty. Inspection Line";
        QltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
    begin
        if Rec.Code = '' then
            exit;

        QltyInspectionLine.SetRange("Result Code", Rec.Code);
        if not QltyInspectionLine.IsEmpty() then
            Error(CannotBeRemovedExistingInspectionErr);

        QltyInspectionHeader.SetRange("Result Code", Rec.Code);
        if not QltyInspectionHeader.IsEmpty() then
            Error(CannotBeRemovedExistingInspectionErr);

        QltyIResultConditConf.SetRange("Condition Type", QltyIResultConditConf."Condition Type"::Inspection);
        QltyIResultConditConf.SetRange("Result Code", Rec.Code);
        if not QltyIResultConditConf.IsEmpty() then
            if not Confirm(PromptFirstExistingInspectionQst) then
                Error('');

        QltyIResultConditConf.Reset();
        QltyIResultConditConf.SetRange("Condition Type", QltyIResultConditConf."Condition Type"::Test);
        QltyIResultConditConf.SetRange("Result Code", Rec.Code);
        if not QltyIResultConditConf.IsEmpty() then
            if not Confirm(PromptFirstExistingTestQst) then
                Error('');

        QltyIResultConditConf.Reset();
        QltyIResultConditConf.SetRange("Condition Type", QltyIResultConditConf."Condition Type"::Template);
        QltyIResultConditConf.SetRange("Result Code", Rec.Code);
        if not QltyIResultConditConf.IsEmpty() then
            if not Confirm(PromptFirstExistingTemplateQst) then
                Error('');

        QltyIResultConditConf.Reset();
        QltyIResultConditConf.SetRange("Result Code", Rec.Code);
        QltyIResultConditConf.DeleteAll();
    end;

    local procedure UpdateExistingConditions()
    var
        QltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
    begin
        QltyIResultConditConf.SetRange("Result Code", Rec.Code);
        QltyIResultConditConf.ModifyAll(Priority, Rec."Evaluation Sequence", false);
        QltyIResultConditConf.ModifyAll("Result Visibility", Rec."Result Visibility", false);
    end;

    /// <summary>
    /// Provides an ability to assist edit the result style.
    /// The standard Business Central result styles will be shown.
    /// </summary>
    procedure AssistEditResultStyle()
    var
        Selection: Integer;
    begin
        Selection := StrMenu(RowStyleOptionsTok);
        if Selection > 0 then
            Rec."Override Style" := CopyStr(SelectStr(Selection, RowStyleOptionsTok), 1, MaxStrLen(Rec."Override Style"));
    end;

    /// <summary>
    /// Gets the result style to use for this result.
    /// If there is an override style then it will be used.
    /// If there is no override style then it will make an assumption based on the category.
    /// </summary>
    /// <returns></returns>
    procedure GetResultStyle(): Text
    begin
        if Rec."Override Style" <> '' then
            exit(Rec."Override Style");

        case Rec."Result Category" of
            Rec."Result Category"::"Not acceptable":
                exit(Format(RowStyle::Unfavorable));
            Rec."Result Category"::Acceptable:
                exit(Format(RowStyle::Favorable));
            else
                exit(Format(RowStyle::None));
        end;
    end;
}
