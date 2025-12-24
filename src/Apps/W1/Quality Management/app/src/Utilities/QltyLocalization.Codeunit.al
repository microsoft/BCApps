// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Utilities;

codeunit 20598 "Qlty. Localization"
{
    var
        TranslatableYesLbl: Label 'Yes';
        TranslatableNoLbl: Label 'No';

    /// <summary>
    /// Returns the translatable "Yes" label with maximum length of 250 characters.
    /// Used for UI display and user-facing text where localization is required.
    /// </summary>
    /// <returns>The localized "Yes" text (up to 250 characters)</returns>
    procedure GetTranslatedYes(): Text[250]
    begin
        exit(TranslatableYesLbl);
    end;

    /// <summary>
    /// Returns the translatable "No" label with maximum length of 250 characters.
    /// Used for UI display and user-facing text where localization is required.
    /// </summary>
    /// <returns>The localized "No" text (up to 250 characters)</returns>
    procedure GetTranslatedNo(): Text[250]
    begin
        exit(TranslatableNoLbl);
    end;

    /// <summary>
    /// Formats a boolean value for user display using localized Yes/No text.
    /// </summary>
    /// <param name="Value">The boolean value to format</param>
    /// <returns>Localized "Yes" for true, "No" for false</returns>
    procedure FormatForUser(Value: Boolean): Text[250]
    begin
        if Value then
            exit(TranslatableYesLbl);
        exit(TranslatableNoLbl);
    end;

    /// <summary>
    /// Parses user input text to a boolean value using localized Yes/No interpretation.
    /// Supports localized Yes/No values as well as standard boolean representations.
    /// </summary>
    /// <param name="Input">The text value to parse</param>
    /// <param name="Value">Output: The parsed boolean value</param>
    /// <returns>True if parsing succeeded; False if input is not a recognized boolean representation</returns>
    procedure ParseFromUser(Input: Text; var Value: Boolean): Boolean
    begin
        Input := Input.Trim();
        if Input = '' then
            exit(false);

        case UpperCase(Input) of
            UpperCase(TranslatableYesLbl), 'Y', 'YES', 'T', 'TRUE', '1', 'ON':
                begin
                    Value := true;
                    exit(true);
                end;
            UpperCase(TranslatableNoLbl), 'N', 'NO', 'F', 'FALSE', '0', 'OFF':
                begin
                    Value := false;
                    exit(true);
                end;
        end;

        exit(Evaluate(Value, Input));
    end;
}
