// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Document;

using Microsoft.Foundation.UOM;
using Microsoft.QualityManagement.AccessControl;
using Microsoft.QualityManagement.Configuration.Result;
using Microsoft.QualityManagement.Configuration.Template;
using Microsoft.QualityManagement.Configuration.Template.Test;
using Microsoft.QualityManagement.Utilities;
using System.Environment.Configuration;
using System.Utilities;

/// <summary>
/// Contains the document lines for a quality order.
/// </summary>
table 20406 "Qlty. Inspection Line"
{
    Caption = 'Quality Inspection Line';
    LookupPageId = "Qlty. Inspection Lines";
    DrillDownPageId = "Qlty. Inspection Lines";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Inspection No."; Code[20])
        {
            Editable = false;
            OptimizeForTextSearch = true;
            Caption = 'Inspection No.';
            ToolTip = 'Specifies which inspection this is.';
        }
        field(2; "Re-inspection No."; Integer)
        {
            Caption = 'Re-inspection No.';
            ToolTip = 'Specifies the re-inspection counter.';
            Editable = false;
            BlankZero = true;
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
            ToolTip = 'Specifies the line no. of the inspection in this template.';
        }
        field(4; "Template Code"; Code[20])
        {
            Caption = 'Template Code';
            Editable = false;
            TableRelation = "Qlty. Inspection Header"."Template Code";
            ToolTip = 'Specifies which template this inspection was created from.';
        }
        field(5; "Template Line No."; Integer)
        {
            Caption = 'Quality Inspection Template Line No.';
            TableRelation = "Qlty. Inspection Template Line"."Line No." where("Template Code" = field("Template Code"));
            Editable = false;
            BlankZero = true;
        }
        field(12; "Test Code"; Code[20])
        {
            Caption = 'Test Code';
            NotBlank = true;
            TableRelation = "Qlty. Test".Code;
            OptimizeForTextSearch = true;
            ToolTip = 'Specifies the field/question/metric in this test.';

            trigger OnValidate()
            var
                QltyTest: Record "Qlty. Test";
            begin
                if "Test Code" = '' then
                    Rec.Description := ''
                else
                    if QltyTest.Get("Test Code") then begin
                        Rec.Description := QltyTest.Description;
                        Rec."Allowable Values" := QltyTest."Allowable Values";
                        if Rec."Test Value" = '' then
                            Rec."Test Value" := QltyTest."Default Value";
                    end;
            end;
        }
        field(13; Description; Text[100])
        {
            Caption = 'Description';
            OptimizeForTextSearch = true;
            ToolTip = 'Specifies a description of the field as it is used on the test.';
        }
        field(14; "Test Value Type"; Enum "Qlty. Test Value Type")
        {
            CalcFormula = lookup("Qlty. Test"."Test Value Type" where(Code = field("Test Code")));
            Caption = 'Test Value Type';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the data type of the values you can enter or select for this test. Use Decimal for numerical measurements. Use Choice to give a list of options to choose from. If you want to choose options from an existing table, use Table Lookup.';
        }
        field(16; "Allowable Values"; Text[500])
        {
            Caption = 'Allowable Values';
            Editable = false;
            ToolTip = 'Specifies an expression for the range of values you can enter or select for the Test. Depending on the Test Value Type, the expression format varies. For example if you want a measurement such as a percentage that collects between 0 and 100 you would enter 0..100. This is not the pass or acceptable condition, these are just the technically possible values that the inspector can enter. You would then enter a passing condition in your result conditions. If you had a result of Pass being 80 to 100, you would then configure 80..100 for that result.';
        }
        field(18; "Test Value"; Text[250])
        {
            Caption = 'Test Value';
            OptimizeForTextSearch = true;
            ToolTip = 'Specifies the recorded test value.';

            trigger OnValidate()
            var
                QltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
                IsHandled: Boolean;
            begin
                QltyInspectionTemplateLine.Get(Rec."Template Code", Rec."Template Line No.");
                ValidateTestValue();
                Rec."Derived Numeric Value" := 0;
                OnBeforeEvaluateNumericTestValue(Rec, IsHandled);
                if not IsHandled then
                    if Evaluate(Rec."Derived Numeric Value", Rec."Test Value") then;

                SetLargeText(Rec."Test Value", false, true);

                UpdateExpressionsInOtherInspectionLinesInSameInspection();
            end;
        }
        field(19; "Test Value Blob"; Blob)
        {
            Caption = 'Test Value Blob';
            ToolTip = 'Specifies large test value data. Typically used for larger text that is captured.';
        }
        field(25; "Derived Numeric Value"; Decimal)
        {
            Caption = 'Derived Numeric Value';
            ToolTip = 'Specifies an evaluated numeric value of Test Value for use in calculations and analysis. This value is automatically calculated when the Test Value is entered or modified based on the configuration of the Test Value and is not directly editable.';
            Editable = false;
            AutoFormatType = 0;
            DecimalPlaces = 0 : 5;
            BlankZero = true;
        }
        field(28; "Result Code"; Code[20])
        {
            Editable = false;
            TableRelation = "Qlty. Inspection Result".Code;
            Caption = 'Result Code';
            ToolTip = 'Specifies the result is automatically determined based on the test value and result configuration.';

            trigger OnValidate()
            var
                QltyResult: Record "Qlty. Inspection Result";
            begin
                if QltyResult.Get(Rec."Result Code") then begin
                    Rec."Evaluation Sequence" := QltyResult."Evaluation Sequence";
                    Rec.CalcFields("Result Description");
                end;
            end;
        }
        field(29; "Result Description"; Text[100])
        {
            Caption = 'Result';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Qlty. Inspection Result"."Description" where("Code" = field("Result Code")));
            ToolTip = 'Specifies the result description for this test result. The result is automatically determined based on the test value and result configuration.';
        }
        field(30; "Evaluation Sequence"; Integer)
        {
            Editable = false;
            Caption = 'Evaluation Sequence';
            ToolTip = 'Specifies the associated evaluation sequence for this test result. The result is automatically determined based on the test value and result configuration.';
        }
        field(33; "Failure State"; Enum "Qlty. Line Failure State")
        {
            Caption = 'Failure State';
            Editable = false;
        }
        field(34; "Non-Conformance Inspection No."; Code[20])
        {
            Caption = 'Non-Conformance Inspection No.';
            ToolTip = 'Specifies a free text editable reference to a Non-Conformance Inspection No.';
        }
        field(35; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            ToolTip = 'Specifies the unit of measure for the measurement.';
            TableRelation = "Unit of Measure".Code;
        }
    }

    keys
    {
        key(Key1; "Inspection No.", "Re-inspection No.", "Line No.")
        {
            Clustered = true;
        }
        key(byResult; "Template Code", "Inspection No.", "Re-inspection No.", "Test Code", "Result Code")
        {
            SumIndexFields = "Evaluation Sequence";
        }
        key(byEvaluationSequence; "Template Code", "Inspection No.", "Re-inspection No.", "Evaluation Sequence")
        {
        }
        key(byDate; "Template Code", "Inspection No.", "Re-inspection No.", "Test Code", SystemCreatedAt, SystemModifiedAt)
        {
        }
    }

    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        BooleanChoiceListLbl: Label 'No,Yes';

    trigger OnModify()
    begin
        if not Rec.IsTemporary() then
            TestStatusOpen();

        Rec."Derived Numeric Value" := 0;
        if Evaluate(Rec."Derived Numeric Value", Rec."Test Value") then;
    end;

    trigger OnDelete()
    var
        QltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
    begin
        QltyIResultConditConf.SetRange("Condition Type", QltyIResultConditConf."Condition Type"::Inspection);
        QltyIResultConditConf.SetRange("Target Code", Rec."Inspection No.");
        QltyIResultConditConf.SetRange("Target Re-inspection No.", Rec."Re-inspection No.");
        QltyIResultConditConf.SetRange("Target Line No.", Rec."Line No.");
        QltyIResultConditConf.DeleteAll();
    end;

    protected procedure ValidateTestValue()
    var
        QltyResultEvaluation: Codeunit "Qlty. Result Evaluation";
    begin
        GetInspection();
        QltyResultEvaluation.ValidateQltyInspectionLine(Rec, QltyInspectionHeader, true);
    end;

    local procedure GetInspection(): Boolean
    begin
        if Rec.IsTemporary() then
            exit(false);

        exit(QltyInspectionHeader.Get(Rec."Inspection No.", Rec."Re-inspection No."));
    end;

    local procedure TestStatusOpen()
    begin
        if GetInspection() then
            QltyInspectionHeader.TestField(Status, QltyInspectionHeader.Status::Open);
    end;

    /// <summary>
    /// Starts the appropriate 'assist edit' dialog for the given data type and conditions.
    /// </summary>
    procedure AssistEditTestValue()
    var
        QltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
    begin
        Rec.CalcFields("Test Value Type");
        if QltyInspectionTemplateLine.Get(Rec."Template Code", Rec."Template Line No.") then;

        if Rec."Allowable Values" = '' then
            if QltyInspectionTemplateLine."Template Code" <> '' then begin
                QltyInspectionTemplateLine.CalcFields("Allowable Values");
                Rec."Allowable Values" := QltyInspectionTemplateLine."Allowable Values";
            end;

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

    internal procedure AssistEditFreeText()
    var
        QltyEditLargeText: Page "Qlty. Edit Large Text";
        ExistingText: Text;
    begin
        ExistingText := GetLargeText();

        if QltyEditLargeText.RunModalWith(ExistingText) in [Action::LookupOK, Action::OK, Action::Yes] then
            SetLargeText(ExistingText, true, false);
    end;

    internal procedure GetLargeText() Result: Text
    var
        InStreamForText: InStream;
    begin
        Result := Rec."Test Value";

        if not Rec.CalcFields("Test Value Blob") then
            exit;

        if not Rec."Test Value Blob".HasValue() then
            exit;

        Rec."Test Value Blob".CreateInStream(InStreamForText);
        InStreamForText.Read(Result);
        if (StrLen(Result) < 1) and (StrLen(Rec."Test Value") > 0) then
            Result := Rec."Test Value";
    end;

    internal procedure SetLargeText(LargeText: Text; ValidateValue: Boolean; OnlySetBlob: Boolean)
    var
        OutStreamForText: OutStream;
    begin
        if not OnlySetBlob then
            if ValidateValue then
                Rec.Validate("Test Value", CopyStr(LargeText, 1, MaxStrLen(Rec."Test Value")))
            else
                Rec."Test Value" := CopyStr(LargeText, 1, MaxStrLen(Rec."Test Value"));

        if Rec."Test Value Type" in [Rec."Test Value Type"::"Value Type Text"] then begin
            Clear(Rec."Test Value Blob");
            Rec."Test Value Blob".CreateOutStream(OutStreamForText);
            OutStreamForText.WriteText(LargeText);
            Rec.Modify();
        end;
    end;

    local procedure AssistEditChooseFromList(Options: Text)
    var
        Selection: Integer;
    begin
        Selection := StrMenu(Options.Replace(', ', ','));
        if Selection > 0 then
            Rec.Validate("Test Value", SelectStr(Selection, Options));
    end;

    local procedure AssistEditChooseFromTableLookup()
    var
        TempBufferQltyTestLookupValue: Record "Qlty. Test Lookup Value" temporary;
    begin
        CollectAllowableValues(TempBufferQltyTestLookupValue);

        if Page.RunModal(Page::"Qlty. Lookup Field Choose", TempBufferQltyTestLookupValue) = Action::LookupOK then
            Rec.Validate("Test Value", CopyStr(TempBufferQltyTestLookupValue."Custom 1", 1, MaxStrLen(Rec."Test Value")));
    end;

    /// <summary>
    /// Code = the unique code
    /// Description = raw description.
    /// Custom 1 = original value
    /// Custom 2 = lowercase value
    /// Custom 3 = uppercase value.
    /// </summary>
    /// <param name="TempBufferQltyTestLookupValue"></param>
    internal procedure CollectAllowableValues(var TempBufferQltyTestLookupValue: Record "Qlty. Test Lookup Value" temporary)
    var
        QltyTest: Record "Qlty. Test";
    begin
        Rec.CalcFields("Test Value Type");
        if not QltyTest.Get(Rec."Test Code") then
            exit;

        if not GetInspection() then;
        QltyTest.CollectAllowableValues(QltyInspectionHeader, Rec, TempBufferQltyTestLookupValue, Rec."Test Value");
    end;

    /// <summary>
    /// Returns true if the test is a numeric field type.
    /// </summary>
    /// <returns></returns>
    internal procedure IsNumericFieldType(): Boolean
    var
        QltyTest: Record "Qlty. Test";
    begin
        if Rec."Test Code" <> '' then
            if QltyTest.Get(Rec."Test Code") then
                exit(QltyTest.IsNumericFieldType());
    end;

    internal procedure GetFailedSampleCount() FailedSamples: Integer
    begin
    end;

    /// <summary>
    /// Gets the preferred result style to use.
    /// </summary>
    procedure GetResultStyle(): Text
    var
        QltyInspectionResult: Record "Qlty. Inspection Result";
    begin
        if QltyInspectionResult.Get(Rec."Result Code") then
            exit(QltyInspectionResult.GetResultStyle());
    end;

    internal procedure UpdateExpressionsInOtherInspectionLinesInSameInspection()
    var
        OthersInSameQltyInspectionLine: Record "Qlty. Inspection Line";
        QltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        QltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        QltyResultEvaluation: Codeunit "Qlty. Result Evaluation";
        OfConsideredTestCodes: List of [Text];
    begin
        if not GetInspection() then
            exit;

        OthersInSameQltyInspectionLine.SetRange("Inspection No.", Rec."Inspection No.");
        OthersInSameQltyInspectionLine.SetRange("Re-inspection No.", Rec."Re-inspection No.");
        OthersInSameQltyInspectionLine.SetFilter("Test Value Type", '%1', QltyInspectionTemplateLine."Test Value Type"::"Value Type Text Expression");
        OthersInSameQltyInspectionLine.SetFilter("Line No.", '<>%1', Rec."Line No.");
        OthersInSameQltyInspectionLine.SetAutoCalcFields("Test Value Type");

        QltyInspectionTemplateLine.SetRange("Template Code", Rec."Template Code");
        QltyInspectionTemplateLine.SetFilter("Test Value Type", '%1', QltyInspectionTemplateLine."Test Value Type"::"Value Type Text Expression");
        QltyInspectionTemplateLine.SetFilter("Test Code", '<>%1', Rec."Test Code");
        QltyInspectionTemplateLine.SetFilter("Expression Formula", '<>''''');
        QltyInspectionTemplateLine.SetAutoCalcFields("Test Value Type");
        if QltyInspectionTemplateLine.FindSet() then
            repeat
                OthersInSameQltyInspectionLine.SetRange("Template Line No.", QltyInspectionTemplateLine."Line No.");
                OthersInSameQltyInspectionLine.SetRange("Test Code", QltyInspectionTemplateLine."Test Code");
                if OthersInSameQltyInspectionLine.FindSet() then
                    repeat
                        OfConsideredTestCodes.Add(OthersInSameQltyInspectionLine."Test Code");
                        case OthersInSameQltyInspectionLine."Test Value Type" of
                            OthersInSameQltyInspectionLine."Test Value Type"::"Value Type Text Expression":
                                OthersInSameQltyInspectionLine.EvaluateTextExpression(QltyInspectionHeader);
                        end;
                    until OthersInSameQltyInspectionLine.Next() = 0;
            until QltyInspectionTemplateLine.Next() = 0;

        QltyResultEvaluation.GetInspectionLineConfigFilters(Rec, QltyIResultConditConf);
        QltyIResultConditConf.SetFilter("Target Line No.", '<>%1', Rec."Line No.");
        QltyIResultConditConf.SetFilter("Test Code", '<>%1', Rec."Test Code");
        QltyIResultConditConf.SetFilter("Condition", StrSubstNo('@*[%1]*', Rec."Test Code"));
        QltyIResultConditConf.SetLoadFields("Target Line No.", "Test Code");
        OthersInSameQltyInspectionLine.Reset();
        if QltyIResultConditConf.FindSet() then
            repeat
                OthersInSameQltyInspectionLine.SetRange("Inspection No.", Rec."Inspection No.");
                OthersInSameQltyInspectionLine.SetRange("Re-inspection No.", Rec."Re-inspection No.");
                OthersInSameQltyInspectionLine.SetRange("Line No.", QltyIResultConditConf."Target Line No.");
                OthersInSameQltyInspectionLine.SetRange("Test Code", QltyIResultConditConf."Test Code");
                if OthersInSameQltyInspectionLine.FindFirst() then begin
                    OfConsideredTestCodes.Add(OthersInSameQltyInspectionLine."Test Code");
                    OthersInSameQltyInspectionLine.ValidateTestValue();
                end;
            until QltyIResultConditConf.Next() = 0;

        OthersInSameQltyInspectionLine.Reset();
        OthersInSameQltyInspectionLine.SetRange("Inspection No.", Rec."Inspection No.");
        OthersInSameQltyInspectionLine.SetRange("Re-inspection No.", Rec."Re-inspection No.");
        OthersInSameQltyInspectionLine.SetFilter("Line No.", '<>%1', Rec."Line No.");
        OthersInSameQltyInspectionLine.SetFilter("Allowable Values", StrSubstNo('@*[%1]*', Rec."Test Code"));
        if OthersInSameQltyInspectionLine.FindSet(true) then
            repeat
                if not OfConsideredTestCodes.Contains(OthersInSameQltyInspectionLine."Test Code") then
                    OthersInSameQltyInspectionLine.ValidateTestValue();

            until OthersInSameQltyInspectionLine.Next() = 0;
    end;

    internal procedure EvaluateTextExpression(var EvaluateAgainstQltyInspectionHeader: Record "Qlty. Inspection Header")
    var
        QltyExpressionMgmt: Codeunit "Qlty. Expression Mgmt.";
    begin
        QltyExpressionMgmt.EvaluateTextExpression(Rec, EvaluateAgainstQltyInspectionHeader);
    end;

    /// <summary>
    /// Reads the last measurement note for the specific inspection line.
    /// If there are multiple notes it only reads the last one.
    /// </summary>
    /// <returns></returns>
    procedure GetMeasurementNote() Note: Text
    var
        RecordLink: Record "Record Link";
        RecordLinkManagement: Codeunit "Record Link Management";
    begin
        RecordLink.SetRange(Type, RecordLink.Type::Note);
        RecordLink.SetRange("Record ID", Rec.RecordId());
        if RecordLink.FindLast() then begin
            RecordLink.CalcFields(Note);
            Note := RecordLinkManagement.ReadNote(RecordLink);
        end;
    end;

    /// <summary>
    /// Sets the measurement note on the last associated note line for the inspection line.
    /// If there is no note record yet (record link) then it will create a new one.
    /// </summary>
    /// <param name="Note"></param>
    procedure SetMeasurementNote(Note: Text)
    var
        RecordLink: Record "Record Link";
        RecordLinkManagement: Codeunit "Record Link Management";
        QltyPermissionMgmt: Codeunit "Qlty. Permission Mgmt.";
    begin
        QltyPermissionMgmt.VerifyCanEditLineComments();

        GetInspection();
        QltyInspectionHeader.TestField(Status, QltyInspectionHeader.Status::Open);

        RecordLink.SetRange(Type, RecordLink.Type::Note);
        RecordLink.SetRange("Record ID", Rec.RecordId());
        if not RecordLink.FindLast() then begin
            RecordLink.Init();
            RecordLink."Link ID" := 0;
            RecordLink."Record ID" := Rec.RecordId();
            RecordLink.URL1 := '';
            RecordLink.Type := RecordLink.Type::Note;
            RecordLink.Created := CurrentDateTime();
            RecordLink."User ID" := CopyStr(UserId(), 1, MaxStrLen(RecordLink."User ID"));
            RecordLink.Company := CopyStr(CompanyName(), 1, MaxStrLen(RecordLink.Company));
            RecordLink.Notify := true;
            RecordLinkManagement.WriteNote(RecordLink, Note);
            RecordLink.Insert(false);
        end else begin
            Clear(RecordLink.Note);
            RecordLinkManagement.WriteNote(RecordLink, Note);
            RecordLink.Modify();
        end;
    end;

    /// <summary>
    /// Opens up a dialog to collect note text.
    /// </summary>
    internal procedure RunModalEditMeasurementNote()
    var
        QltyEditLargeText: Page "Qlty. Edit Large Text";
        Note: Text;
    begin
        GetInspection();
        QltyInspectionHeader.TestField(Status, QltyInspectionHeader.Status::Open);

        Note := GetMeasurementNote();
        if QltyEditLargeText.RunModalWith(Note) in [Action::LookupOK, Action::OK, Action::Yes] then
            SetMeasurementNote(Note);
    end;

    /// <summary>
    /// Opens up a dialog to collect note text.
    /// </summary>
    internal procedure RunModalReadOnlyComment()
    var
        QltyEditLargeText: Page "Qlty. Edit Large Text";
        Note: Text;
    begin
        Note := GetMeasurementNote();
        QltyEditLargeText.RunModalWith(Note);
    end;

    /// <summary>
    /// Provides an opportunity to modify the evaluation of the Numeric Test Value from the Test Value.
    /// </summary>
    /// <param name="QltyInspectionLine">Qlty. Inspection Line</param>
    /// <param name="IsHandled">Provides an opportunity to replace the default behavior</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeEvaluateNumericTestValue(var QltyInspectionLine: Record "Qlty. Inspection Line"; var IsHandled: Boolean)
    begin
    end;
}
