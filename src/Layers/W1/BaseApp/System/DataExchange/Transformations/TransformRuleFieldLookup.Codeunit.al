// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.IO;

codeunit 1246 "Transform. Rule - Field Lookup" implements "Transformation Rule"
{
    procedure TransformText(TransformationRule: Record "Transformation Rule"; OldValue: Text; var NewValue: Text);
    begin
        NewValue := FieldLookup(TransformationRule, OldValue);
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
        VisibleTransformationRuleGroups.Add(Enum::"Transformation Rule Group"::"Field Lookup");
    end;

    local procedure FieldLookup(TransformationRule: Record "Transformation Rule"; OldValue: Text): Text
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        TransformationRule.TestField("Table ID");
        TransformationRule.TestField("Source Field ID");
        TransformationRule.TestField("Target Field ID");
        RecRef.Open(TransformationRule."Table ID");
        FieldRef := RecRef.Field(TransformationRule."Source Field ID");
        FieldRef.SetRange(OldValue);
        if not RecRef.FindFirst() then
            exit('');

        FieldRef := RecRef.Field(TransformationRule."Target Field ID");
        case TransformationRule."Field Lookup Rule" of
            TransformationRule."Field Lookup Rule"::Target:
                exit(FieldRef.Value);
            TransformationRule."Field Lookup Rule"::"Original If Target Is Blank":
                begin
                    if Format(FieldRef.Value) = '' then
                        exit(OldValue);
                    exit(FieldRef.Value);
                end;
        end;
    end;
}