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
}
