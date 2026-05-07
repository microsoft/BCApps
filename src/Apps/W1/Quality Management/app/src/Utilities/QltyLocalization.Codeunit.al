// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Utilities;

/// <summary>
/// Provides localization utilities for Quality Management.
/// 
/// This codeunit follows the Single Responsibility Principle by focusing solely
/// on localization concern: translations.
/// </summary>
codeunit 20431 "Qlty. Localization"
{
    Access = Internal;

    var
        TranslatableYesLbl: Label 'Yes';
        TranslatableNoLbl: Label 'No';

    #region Translated Yes/No

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

    #endregion
}