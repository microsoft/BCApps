// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.IO;

using System;

codeunit 1257 "Transform. Rule - Match" implements "Transformation Rule"
{
    procedure TransformText(TransformationRule: Record "Transformation Rule"; OldValue: Text; var NewValue: Text);
    begin
        NewValue := RegularExpressionMatch(OldValue, TransformationRule."Find Value");
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
    end;

    local procedure RegularExpressionMatch(StringToMatch: Text; Pattern: Text): Text
    var
        Regex: DotNet Regex;
        RegexOptions: DotNet RegexOptions;
        MatchCollection: DotNet MatchCollection;
        Match: DotNet Match;
        Group: DotNet Group;
        Capture: DotNet Capture;
        NewString: Text;
        WholeExpressionGroup: Boolean;
    begin
        NewString := '';

        Regex := Regex.Regex(Pattern, RegexOptions.IgnoreCase);
        MatchCollection := Regex.Matches(StringToMatch);
        if IsNull(MatchCollection) then
            exit(NewString);

        if MatchCollection.Count = 0 then
            exit(NewString);

        WholeExpressionGroup := true;
        foreach Match in MatchCollection do
            foreach Group in Match.Groups do
                if WholeExpressionGroup then
                    WholeExpressionGroup := false
                else
                    foreach Capture in Group.Captures do
                        NewString += Capture.Value;

        exit(NewString);
    end;
}