// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.IO;

codeunit 1263 "Transform. Rule - Substring" implements "Transformation Rule"
{
    procedure TransformText(TransformationRule: Record "Transformation Rule"; OldValue: Text; var NewValue: Text);
    begin
        NewValue := Substring(TransformationRule, OldValue);
    end;

    procedure IsDataFormatUpdateAllowed(): Boolean;
    begin
        exit(false)
    end;

    procedure CheckMandatoryFieldsInTransformationRule(TransformationRule: Record "Transformation Rule");
    begin
    end;

    procedure ValidateTransformationRuleField(FieldNo: Integer; var TransformationRule: Record "Transformation Rule"; var xTransformationRule: Record "Transformation Rule"): Boolean;
    var
        MustBeGreaterThanZeroErr: Label 'The Value entered must be greater than zero.';
    begin
        case FieldNo of
            TransformationRule.FieldNo("Starting Text"):
                begin
                    if TransformationRule."Starting Text" <> '' then
                        TransformationRule.Validate("Start Position", 0);
                    exit(true);
                end;
            TransformationRule.FieldNo("Ending Text"):
                begin
                    if TransformationRule."Ending Text" <> '' then
                        TransformationRule.Validate(Length, 0);
                    exit(true);
                end;
            TransformationRule.FieldNo("Start Position"):
                begin
                    if TransformationRule."Start Position" < 0 then
                        Error(MustBeGreaterThanZeroErr);
                    if TransformationRule."Start Position" <> 0 then
                        TransformationRule.Validate("Starting Text", '');
                    exit(true);
                end;
            TransformationRule.FieldNo(Length):
                begin
                    if TransformationRule.Length < 0 then
                        Error(MustBeGreaterThanZeroErr);
                    if TransformationRule.Length <> 0 then
                        TransformationRule.Validate("Ending Text", '');
                    exit(true);
                end;
        end;
    end;

    procedure GetVisibleGroups(TransformationRule: Record "Transformation Rule"; var VisibleTransformationRuleGroups: List of [Enum "Transformation Rule Group"])
    begin
        VisibleTransformationRuleGroups.Add(Enum::"Transformation Rule Group"::"Start Position");
        VisibleTransformationRuleGroups.Add(Enum::"Transformation Rule Group"::"End Position");
    end;

    local procedure Substring(TransformationRule: Record "Transformation Rule"; OldValue: Text): Text
    var
        StartPosition: Integer;
        NewLength: Integer;
    begin
        StartPosition := SubstringGetStartPosition(TransformationRule, OldValue);
        if StartPosition <= 0 then
            exit('');

        NewLength := SubstringGetLength(TransformationRule, OldValue, StartPosition);

        if NewLength <= 0 then
            exit('');

        exit(CopyStr(OldValue, StartPosition, NewLength));
    end;

    local procedure SubstringGetLength(TransformationRule: Record "Transformation Rule"; OldValue: Text; StartPosition: Integer): Integer
    var
        SearchableText: Text;
    begin
        if (TransformationRule.Length <= 0) and (TransformationRule."Ending Text" = '') then
            exit(StrLen(OldValue) - StartPosition + 1);

        if TransformationRule.Length > 0 then
            exit(TransformationRule.Length);

        if TransformationRule."Ending Text" <> '' then begin
            SearchableText := CopyStr(OldValue, StartPosition, StrLen(OldValue) - StartPosition + 1);
            exit(StrPos(SearchableText, RemoveLeadingAndEndingQuotes(TransformationRule."Ending Text")) - 1);
        end;

        exit(-1);
    end;

    local procedure SubstringGetStartPosition(TransformationRule: Record "Transformation Rule"; OldValue: Text): Integer
    var
        StartingText: Text;
        StartIndex: Integer;
    begin
        if (TransformationRule."Start Position" <= 0) and (TransformationRule."Starting Text" = '') then
            exit(1);

        if TransformationRule."Start Position" > 0 then
            exit(TransformationRule."Start Position");

        StartingText := RemoveLeadingAndEndingQuotes(TransformationRule."Starting Text");
        if StartingText <> '' then begin
            StartIndex := StrPos(OldValue, StartingText);
            if StartIndex > 0 then
                exit(StartIndex + StrLen(StartingText));
        end;

        exit(-1);
    end;

    local procedure RemoveLeadingAndEndingQuotes(InputText: Text): Text
    var
        QuotedText: Boolean;
        InputTextLength: Integer;
    begin
        InputTextLength := StrLen(InputText);
        if InputTextLength < 2 then
            exit(InputText);

        QuotedText := (InputText[1] = '''') and (InputText[InputTextLength] = '''');
        if not QuotedText then
            QuotedText := (InputText[1] = '"') and (InputText[InputTextLength] = '"');

        if QuotedText then
            exit(CopyStr(InputText, 2, InputTextLength - 2));

        exit(InputText);
    end;
}