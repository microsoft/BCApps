// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.IO;

codeunit 1264 "Transform. Rule - Round" implements "Transformation Rule"
{
    procedure TransformText(TransformationRule: Record "Transformation Rule"; OldValue: Text; var NewValue: Text);
    begin
        NewValue := RoundValue(TransformationRule, OldValue);
    end;

    procedure IsDataFormatUpdateAllowed(): Boolean;
    begin
        exit(false)
    end;

    procedure CheckMandatoryFieldsInTransformationRule(TransformationRule: Record "Transformation Rule");
    begin
    end;

    procedure ValidateTransformationRuleField(FieldNo: Integer; var TransformationRule: Record "Transformation Rule"; var xTransformationRule: Record "Transformation Rule"): Boolean;
    begin
    end;

    procedure GetVisibleGroups(TransformationRule: Record "Transformation Rule"; var VisibleTransformationRuleGroups: List of [Enum "Transformation Rule Group"])
    begin
        VisibleTransformationRuleGroups.Add(Enum::"Transformation Rule Group"::Round);
    end;

    local procedure RoundValue(TransformationRule: Record "Transformation Rule"; OldValue: Text): Text
    var
        DecVar: Decimal;
    begin
        Evaluate(DecVar, OldValue);
        TransformationRule.TestField(Precision);
        TransformationRule.TestField(Direction);
        exit(Format(Round(DecVar, TransformationRule.Precision, TransformationRule.Direction)));
    end;
}