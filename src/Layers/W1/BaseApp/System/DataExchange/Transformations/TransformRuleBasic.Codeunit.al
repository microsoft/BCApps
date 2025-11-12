// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.IO;

using System.Text;
using System.Reflection;

codeunit 1244 "Transform. Rule - Basic" implements "Transformation Rule"
{
    procedure TransformText(TransformationRule: Record "Transformation Rule"; OldValue: Text; var NewValue: Text);
    begin
        case TransformationRule."Transformation Type" of
            TransformationRule."Transformation Type"::Uppercase:
                NewValue := UpperCase(OldValue);
            TransformationRule."Transformation Type"::Lowercase:
                NewValue := LowerCase(OldValue);
            TransformationRule."Transformation Type"::Trim:
                NewValue := DelChr(OldValue, '<>');
            TransformationRule."Transformation Type"::"Remove Non-Alphanumeric Characters":
                NewValue := RemoveNonAlphaNumericCharacters(OldValue);
            TransformationRule."Transformation Type"::Unixtimestamp:
                if not TryConvert2BigInteger(OldValue, NewValue) then
                    NewValue := '';
        end;
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
    end;

    local procedure RemoveNonAlphaNumericCharacters(OldValue: Text): Text
    var
        StringConversionManagement: Codeunit StringConversionManagement;
    begin
        exit(StringConversionManagement.RemoveNonAlphaNumericCharacters(OldValue));
    end;

    [TryFunction]
    local procedure TryConvert2BigInteger(OldValue: Text; var NewValue: Text)
    var
        TypeHelper: Codeunit "Type Helper";
        TempBinteger: BigInteger;
    begin
        Evaluate(TempBinteger, OldValue);
        NewValue := Format(TypeHelper.EvaluateUnixTimestamp(TempBinteger), 0, 9);
    end;
}