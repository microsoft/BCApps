// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.IO;

codeunit 1265 "Transform. Rule - Ex. Fr. Date" implements "Transformation Rule"
{
    procedure TransformText(TransformationRule: Record "Transformation Rule"; OldValue: Text; var NewValue: Text);
    begin
        NewValue := ExtractFromDate(TransformationRule, OldValue);
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
        VisibleTransformationRuleGroups.Add(Enum::"Transformation Rule Group"::"Extract from Date");
    end;

    local procedure ExtractFromDate(TransformationRule: Record "Transformation Rule"; OldValue: Text): Text
    var
        DateVar: Date;
    begin
        Evaluate(DateVar, OldValue);
        exit(Format(Date2DMY(DateVar, TransformationRule."Extract From Date Type".AsInteger())));
    end;
}