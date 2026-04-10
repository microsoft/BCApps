// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.IO;

codeunit 1243 "Transform. Rule - Custom" implements "Transformation Rule"
{
    procedure TransformText(TransformationRule: Record "Transformation Rule"; OldValue: Text; var NewValue: Text);
    begin
        TransformationRule.OnTransformation(TransformationRule.Code, OldValue, NewValue);
    end;

    procedure IsDataFormatUpdateAllowed(): Boolean;
    begin
        exit(true)
    end;

    procedure CheckMandatoryFieldsInTransformationRule(TransformationRule: Record "Transformation Rule");
    begin
    end;

    procedure ValidateTransformationRuleField(FieldNo: Integer; var TransformationRule: Record "Transformation Rule"; var xTransformationRule: Record "Transformation Rule"): Boolean;
    begin
    end;

    procedure GetVisibleGroups(TransformationRule: Record "Transformation Rule"; var VisibleTransformationRuleGroups: List of [Enum "Transformation Rule Group"])
    begin
    end;
}