// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Utilities;

/// <summary>
/// Provides utilities for parsing and interpreting text values as boolean values.
/// Supports quality-specific terminology like "Pass", "Fail", "Good", "Bad" in addition to standard boolean representations.
/// </summary>
codeunit 20436 "Qlty. Boolean Parsing"
{
    Access = Internal;

    var
        TranslatableYesLbl: Label 'Yes';
        TranslatableNoLbl: Label 'No';
        LockedYesLbl: Label 'Yes', Locked = true;
        LockedNoLbl: Label 'No', Locked = true;
        QltyGoodLbl: Label 'GOOD';
        QltyPassLbl: Label 'PASS';
        QltyAcceptableLbl: Label 'ACCEPTABLE';
        QltyPassedLbl: Label 'PASSED';
        QltyBadLbl: Label 'BAD';
        QltyFailLbl: Label 'FAIL';
        QltyUnacceptableLbl: Label 'UNACCEPTABLE';
        QltyFailedLbl: Label 'FAILED';
        QltyNotOkLbl: Label 'NOTOK';
        PositiveLbl: Label 'POSITIVE';
        EnabledLbl: Label 'ENABLED';
        CheckLbl: Label 'CHECK';
        CheckedLbl: Label 'CHECKED';
        YesLbl: Label 'YES';
        OnLbl: Label 'ON';

    /// <summary>
    /// Converts text input to a boolean value using flexible interpretation rules.
    /// Treats any positive boolean representation as true, everything else as false.
    /// 
    /// Recognized as TRUE (case-insensitive):
    /// - Standard: "Yes", "Y", "True", "T", "1", "On"
    /// - Quality-specific: "Positive", "Check", "Checked", "Good", "Pass", "Passed", "Acceptable", "OK"
    /// - Special: "V" (checkmark), ":SELECTED:"
    /// 
    /// All other values (including empty string) return FALSE.
    /// 
    /// Note: This does NOT validate if input looks like a boolean - it converts any input to boolean.
    /// </summary>
    /// <param name="Input">The text value to convert to boolean</param>
    /// <returns>True if input matches any positive boolean representation; False otherwise</returns>
    procedure GetBooleanFor(Input: Text) IsTrue: Boolean
    begin
        if Input <> '' then begin
            if not Evaluate(IsTrue, Input) then
                exit(IsTextValuePositiveBoolean(Input));

            case UpperCase(Input) of
                UpperCase(TranslatableYesLbl), UpperCase(LockedYesLbl),
                'Y', YesLbl, 'T', 'TRUE', '1', PositiveLbl, EnabledLbl, CheckLbl, CheckedLbl,
                QltyGoodLbl, QltyPassLbl, QltyAcceptableLbl, QltyPassedLbl, 'OK', OnLbl,
                'V', ':SELECTED:':
                    IsTrue := true;
            end;
        end;
    end;

    /// <summary>
    /// Checks if a text value represents a "positive" or "true-ish" boolean value.
    /// 
    /// IMPORTANT: This does NOT validate whether the text is boolean-like.
    /// It ONLY returns true if the text matches a positive boolean representation.
    /// Non-boolean text and negative boolean values both return false.
    /// 
    /// Use case: Quality inspection where "Pass", "Good", "Acceptable" should be treated as true.
    /// 
    /// See GetBooleanFor() for the complete list of recognized positive values.
    /// </summary>
    /// <param name="ValueToCheckIfPositiveBoolean">The text value to check</param>
    /// <returns>True if the value represents a positive/affirmative boolean; False otherwise</returns>
    procedure IsTextValuePositiveBoolean(ValueToCheckIfPositiveBoolean: Text): Boolean
    var
        ConvertedBoolean: Boolean;
    begin
        ValueToCheckIfPositiveBoolean := ValueToCheckIfPositiveBoolean.Trim();

        if Evaluate(ConvertedBoolean, ValueToCheckIfPositiveBoolean) then
            if ConvertedBoolean then
                exit(true);

        case UpperCase(ValueToCheckIfPositiveBoolean) of
            UpperCase(TranslatableYesLbl),
            UpperCase(LockedYesLbl),
            'Y',
            YesLbl,
            'T',
            'TRUE',
            '1',
            PositiveLbl,
            EnabledLbl,
            CheckLbl,
            CheckedLbl,
            QltyGoodLbl,
            QltyPassLbl,
            QltyAcceptableLbl,
            QltyPassedLbl,
            'OK',
            OnLbl,
            'V',
            ':SELECTED:':
                exit(true);
        end;
    end;

    /// <summary>
    /// Checks if text represents a negative/false boolean value.
    /// Only returns true for negative boolean representations; does NOT validate if text is boolean-like.
    /// 
    /// Recognized negative values (case-insensitive):
    /// - Standard: "No", "N", "False", "F", "0"
    /// - Quality-specific: "Bad", "Fail", "Failed", "Unacceptable", "NotOK"
    /// - UI states: "Disabled", "Off", "Uncheck", "Unchecked", ":UNSELECTED:"
    /// - Other: "Negative"
    /// 
    /// Important: Returns false for positive values AND for non-boolean text.
    /// Use CanTextBeInterpretedAsBooleanIsh() first to validate if text is boolean-like.
    /// 
    /// Common usage: Evaluating Inspection results for failure conditions.
    /// </summary>
    /// <param name="ValueToCheckIfNegativeBoolean">The text value to check for negative boolean representation</param>
    /// <returns>True if text represents a negative boolean value; False otherwise (including positive values)</returns>
    procedure IsTextValueNegativeBoolean(ValueToCheckIfNegativeBoolean: Text): Boolean
    var
        ConvertedBoolean: Boolean;
    begin
        ValueToCheckIfNegativeBoolean := ValueToCheckIfNegativeBoolean.Trim();

        if Evaluate(ConvertedBoolean, ValueToCheckIfNegativeBoolean) then
            if not ConvertedBoolean then
                exit(true);

        case UpperCase(ValueToCheckIfNegativeBoolean) of
            UpperCase(TranslatableNoLbl),
            UpperCase(LockedNoLbl),
            'N',
            'NO',
            'F',
            'FALSE',
            '0',
            'NEGATIVE',
            'DISABLED',
            'UNCHECK',
            'UNCHECKED',
            QltyBadLbl,
            QltyFailLbl,
            QltyUnacceptableLbl,
            QltyFailedLbl,
            QltyNotOkLbl,
            'OFF',
            ':UNSELECTED:':
                exit(true);
        end;
    end;

    /// <summary>
    /// Checks if text can be interpreted as a boolean-like value (positive or negative).
    /// Detects whether input looks like a boolean representation, regardless of its value.
    /// 
    /// Returns true if input matches any boolean representation:
    /// - Positive: "Yes", "True", "Pass", "Good", etc.
    /// - Negative: "No", "False", "Fail", "Bad", etc.
    /// 
    /// Use case: Validating user input before conversion or determining field data type hints.
    /// 
    /// Note: This checks if text LOOKS like a boolean, not what boolean value it represents.
    /// For conversion, use GetBooleanFor() instead.
    /// </summary>
    /// <param name="InputText">The text to check for boolean-like characteristics</param>
    /// <returns>True if text appears to be a boolean representation; False otherwise</returns>
    procedure CanTextBeInterpretedAsBooleanIsh(InputText: Text): Boolean
    begin
        exit(IsTextValuePositiveBoolean(InputText) or IsTextValueNegativeBoolean(InputText));
    end;
}
