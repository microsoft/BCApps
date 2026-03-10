// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Email;

/// <summary>
/// An e-mail connector interface enhances the "Email Connector v4" with email category management.
/// </summary>
interface "Email Connector v5" extends "Email Connector v4"
{
    /// <summary>
    /// Get email categories from the provided account.
    /// </summary>
    /// <param name="AccountId">The email account ID.</param>
    /// <param name="EmailCategories">The email categories retrieved.</param>
    procedure GetEmailCategories(AccountId: Guid; var EmailCategories: Record "Email Categories" temporary);

    /// <summary>
    /// Create a new email category in the provided account.
    /// </summary>
    /// <param name="AccountId">The email account ID.</param>
    /// <param name="CategoryDisplayName">The display name of the category to create.</param>
    /// <param name="CategoryColor">The color of the category (optional).</param>
    /// <returns>The ID of the created category.</returns>
    procedure CreateEmailCategory(AccountId: Guid; CategoryDisplayName: Text; CategoryColor: Text): Text;

    /// <summary>
    /// Apply email categories to an email message.
    /// </summary>
    /// <param name="AccountId">The email account ID.</param>
    /// <param name="ExternalId">The external message ID of the email to update.</param>
    /// <param name="Categories">The list of category display names to apply to the email.</param>
    procedure ApplyEmailCategory(AccountId: Guid; ExternalId: Text; Categories: List of [Text]);
}
