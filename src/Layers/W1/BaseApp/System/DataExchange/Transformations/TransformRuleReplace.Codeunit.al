// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.IO;

using System.Text;
using System.Utilities;

codeunit 1249 "Transform. Rule - Replace" implements "Transformation Rule"
{
    procedure TransformText(TransformationRule: Record "Transformation Rule"; OldValue: Text; var NewValue: Text);
    begin
        case TransformationRule."Transformation Type" of
            TransformationRule."Transformation Type"::Replace:
                NewValue := StringReplace(OldValue, TransformationRule."Find Value", TransformationRule."Replace Value");
            TransformationRule."Transformation Type"::"Regular Expression - Replace":
                NewValue := RegularExpressionReplace(OldValue, TransformationRule."Find Value", TransformationRule."Replace Value");
        end;
    end;

    procedure IsDataFormatUpdateAllowed(): Boolean;
    begin
        exit(false)
    end;

    procedure CheckMandatoryFieldsInTransformationRule(TransformationRule: Record "Transformation Rule");
    begin
        TransformationRule.TestField("Find Value");
    end;

    procedure ValidateTransformationRuleField(FieldNo: Integer; var TransformationRule: Record "Transformation Rule"; var xTransformationRule: Record "Transformation Rule"): Boolean;
    begin
    end;

    procedure GetVisibleGroups(TransformationRule: Record "Transformation Rule"; var VisibleTransformationRuleGroups: List of [Enum "Transformation Rule Group"])
    begin
        VisibleTransformationRuleGroups.Add(Enum::"Transformation Rule Group"::"Find Value");
        VisibleTransformationRuleGroups.Add(Enum::"Transformation Rule Group"::"Replace Value");
    end;

    local procedure StringReplace(StringToReplace: Text; OldValue: Text; NewValue: Text): Text
    var
        DotNet_String: Codeunit DotNet_String;
    begin
        if OldValue = '' then
            exit(StringToReplace);
        DotNet_String.Set(StringToReplace);
        exit(DotNet_String.Replace(OldValue, NewValue));
    end;

    local procedure RegularExpressionReplace(StringToReplace: Text; Pattern: Text; NewValue: Text) Result: Text
    var
        RegexOptions: Record "Regex Options";
        Regex: Codeunit Regex;
    begin
        RegexOptions.IgnoreCase := true;
        Result := Regex.Replace(StringToReplace, Pattern, NewValue, RegexOptions);
    end;
}