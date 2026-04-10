// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

/// <summary>
/// Represents the confidence level of automatic matching between bank statement lines and ledger entries during bank reconciliation.
/// This enum is used to indicate how certain the system is about a proposed match, allowing users to review and approve
/// matches based on their confidence levels. Higher confidence matches may be automatically applied, while lower confidence
/// matches require manual review.
/// </summary>
enum 1252 "Bank Rec. Match Confidence"
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// No automatic matching has been performed or no confidence can be determined.
    /// Used as the default state before matching algorithms are applied.
    /// </summary>
    value(0; "None") { Caption = 'None'; }

    /// <summary>
    /// Low confidence match based on limited criteria such as partial amount matching.
    /// Requires manual review and approval before application.
    /// </summary>
    value(1; "Low") { Caption = 'Low'; }

    /// <summary>
    /// Medium confidence match based on multiple matching criteria such as amount and approximate date.
    /// May require manual review depending on application rules configuration.
    /// </summary>
    value(2; "Medium") { Caption = 'Medium'; }

    /// <summary>
    /// High confidence match based on strong criteria such as exact amount, date, and reference matching.
    /// Can typically be automatically applied based on application rules.
    /// </summary>
    value(3; "High") { Caption = 'High'; }

    /// <summary>
    /// High confidence match specifically achieved through text-to-account mapping rules.
    /// Indicates the match was made using predefined mapping rules that match transaction text to specific accounts.
    /// </summary>
    value(4; "High - Text-to-Account Mapping") { Caption = 'High - Text-to-Account Mapping'; }

    /// <summary>
    /// Manual match created by user intervention rather than automatic matching algorithms.
    /// Indicates the user has explicitly chosen to match these entries.
    /// </summary>
    value(5; "Manual") { Caption = 'Manual'; }

    /// <summary>
    /// Match that has been reviewed and accepted by the user.
    /// Represents a confirmed match ready for posting or already posted.
    /// </summary>
    value(6; "Accepted") { Caption = 'Accepted'; }
}
