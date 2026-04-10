// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.Partner;

/// <summary>
/// Defines communication methods for receiving intercompany transactions from partners.
/// Determines how intercompany data is exchanged between related companies.
/// </summary>
/// <remarks>
/// Used in IC Partner setup to specify transfer mechanism for inbound transactions.
/// Supports file-based, database, email, and no-transfer scenarios for flexible deployment.
/// </remarks>
enum 108 "IC Partner Inbox Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// Partner sends transactions via file exchange in specified directory location.
    /// </summary>
    value(0; "File Location") { Caption = 'File Location'; }
    /// <summary>
    /// Partner is another company in the same database enabling direct transaction transfer.
    /// </summary>
    value(1; "Database") { Caption = 'Database'; }
    /// <summary>
    /// Partner sends transactions via email attachment for processing.
    /// </summary>
    value(2; "Email") { Caption = 'Email'; }
    /// <summary>
    /// Data collection only without actual transfer to partner for internal processing.
    /// </summary>
    value(3; "No IC Transfer") { Caption = 'No IC Transfer'; }
}
