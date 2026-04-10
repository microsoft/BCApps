// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Clause;

/// <summary>
/// Defines document types that support VAT clause inclusion for regulatory compliance and customer communication.
/// Enables document-type-specific VAT clause text variations for different business scenarios and legal requirements.
/// </summary>
/// <remarks>
/// Extensible enum allowing custom document types to support VAT clause functionality.
/// Used for document-specific VAT clause processing in sales, finance charge, and reminder scenarios.
/// </remarks>
enum 562 "VAT Clause Document Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// Sales or purchase invoice documents requiring VAT clause disclosure for regulatory compliance.
    /// </summary>
    value(2; Invoice) { Caption = 'Invoice'; }
    /// <summary>
    /// Credit memo documents requiring VAT clause text for refund and adjustment transparency.
    /// </summary>
    value(3; "Credit Memo") { Caption = 'Credit Memo'; }
    /// <summary>
    /// Customer reminder documents that may include VAT clause information for outstanding amounts.
    /// </summary>
    value(4; Reminder) { Caption = 'Reminder'; }
    /// <summary>
    /// Finance charge memo documents requiring VAT clause details for fee calculation transparency.
    /// </summary>
    value(5; "Finance Charge Memo") { Caption = 'Finance Charge Memo'; }
}
