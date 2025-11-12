// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.IO;

using System;
using System.Reflection;
using System.DateTime;
using System.Globalization;

codeunit 1245 "Transform. Rule - Formatting" implements "Transformation Rule"
{
    procedure TransformText(TransformationRule: Record "Transformation Rule"; OldValue: Text; var NewValue: Text);
    begin
        case TransformationRule."Transformation Type" of
            TransformationRule."Transformation Type"::"Title Case":
                NewValue := TextToTitleCase(OldValue, TransformationRule."Data Formatting Culture");
            TransformationRule."Transformation Type"::"Date Formatting":
                NewValue := DateFormatting(OldValue, TransformationRule."Data Format", TransformationRule."Data Formatting Culture");
            TransformationRule."Transformation Type"::"Date and Time Formatting":
                NewValue := DateTimeFormatting(OldValue, TransformationRule."Data Format", TransformationRule."Data Formatting Culture");
            TransformationRule."Transformation Type"::"Decimal Formatting":
                NewValue := DecimalFormatting(OldValue, TransformationRule."Data Formatting Culture");
        end;
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

    local procedure TextToTitleCase(OldValue: Text; DataFormattingCulture: Text[10]): Text
    var
        CultureInfo: DotNet CultureInfo;
    begin
        CultureInfo := CultureInfo.GetCultureInfo(DataFormattingCulture);
        exit(CultureInfo.TextInfo.ToTitleCase(OldValue));
    end;

    local procedure DateTimeFormatting(OldValue: Text; DataFormat: Text[100]; DataFormattingCulture: Text[10]): Text
    var
        DateTimeValue: DateTime;
        NewValue: Text;
    begin
        DateTimeValue := GetDateTime(OldValue, DataFormat, DataFormattingCulture, false);
        if DateTimeValue <> 0DT then
            NewValue := Format(DateTimeValue, 0, XmlFormat())
        else
            NewValue := OldValue;
        exit(NewValue);
    end;

    local procedure DateFormatting(OldValue: Text; DataFormat: Text[100]; DataFormattingCulture: Text[10]): Text
    var
        DateTimeValue: DateTime;
        DateValue: Date;
        NewValue: Text;
    begin
        DateTimeValue := GetDateTime(OldValue, DataFormat, DataFormattingCulture, true);
        DateValue := DT2Date(DateTimeValue);
        if DateValue <> 0D then
            NewValue := Format(DateValue, 0, XmlFormat())
        else
            NewValue := OldValue;
        exit(NewValue);
    end;

    local procedure DecimalFormatting(OldValue: Text; DataFormattingCulture: Text[10]): Text
    var
        TypeHelper: Codeunit "Type Helper";
        NewDecimalVariant: Variant;
        NewValue: Text;
        DummyDecimal: Decimal;
    begin
        NewValue := OldValue;
        DummyDecimal := 0;
        NewDecimalVariant := DummyDecimal;
        TypeHelper.Evaluate(NewDecimalVariant, OldValue, '', DataFormattingCulture);

        NewValue := Format(NewDecimalVariant, 0, XmlFormat());
        exit(NewValue);
    end;

    local procedure GetDateTime(TextValue: Text; DataFormat: Text[100]; DataFormattingCulture: Text[10]; SuppresTimeZone: Boolean): DateTime
    var
        DotNet_DateTime: Codeunit DotNet_DateTime;
        DotNet_CultureInfo: Codeunit DotNet_CultureInfo;
        DotNet_DateTimeStyles: Codeunit DotNet_DateTimeStyles;
        DateTimeValue: DateTime;
    begin
        DateTimeValue := 0DT;

        DotNet_DateTimeStyles.None();

        if DataFormattingCulture = '' then begin
            DotNet_CultureInfo.InvariantCulture();
            if not DotNet_DateTime.TryParseExact(TextValue, DataFormat, DotNet_CultureInfo, DotNet_DateTimeStyles) then
                exit(DateTimeValue);
        end else begin
            DotNet_CultureInfo.GetCultureInfoByName(DataFormattingCulture);
            if not DotNet_DateTime.TryParse(TextValue, DotNet_CultureInfo, DotNet_DateTimeStyles) then
                exit(DateTimeValue);
        end;

        if SuppresTimeZone then
            DateTimeValue := CreateDateTime(DMY2Date(DotNet_DateTime.Day(), DotNet_DateTime.Month(), DotNet_DateTime.Year()), 0T)
        else
            DateTimeValue := DotNet_DateTime.ToDateTime();

        exit(DateTimeValue);
    end;

    local procedure XmlFormat(): Integer
    begin
        exit(9);
    end;
}