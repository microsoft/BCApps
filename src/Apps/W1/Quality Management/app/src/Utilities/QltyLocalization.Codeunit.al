// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Utilities;

/// <summary>
/// Provides localization and translation utilities for Quality Management.
/// Handles translation of common UI elements and user-facing text with proper localization support.
/// </summary>
codeunit 20596 "Qlty. Localization"
{
    var
        TranslatableYesLbl: Label 'Yes';
        TranslatableNoLbl: Label 'No';

    /// <summary>
    /// Returns the translatable "Yes" label with maximum length of 250 characters.
    /// Used for UI display and user-facing text where localization is required.
    /// </summary>
    /// <returns>The localized "Yes" text (up to 250 characters)</returns>
    procedure GetTranslatedYes250(): Text[250]
    begin
        exit(TranslatableYesLbl);
    end;

    /// <summary>
    /// Returns the translatable "No" label with maximum length of 250 characters.
    /// Used for UI display and user-facing text where localization is required.
    /// </summary>
    /// <returns>The localized "No" text (up to 250 characters)</returns>
    procedure GetTranslatedNo250(): Text[250]
    begin
        exit(TranslatableNoLbl);
    end;
}
