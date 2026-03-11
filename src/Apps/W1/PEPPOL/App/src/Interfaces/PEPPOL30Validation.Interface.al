// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol;

/// <summary>
/// Interface for validating sales documents against PEPPOL 3.0 compliance requirements.
/// Provides comprehensive validation methods for sales headers, lines, and posted documents
/// to ensure they meet PEPPOL electronic document standards and business rules.
/// </summary>
interface "PEPPOL30 Validation"
{
    /// <summary>
    /// Validates a sales document for PEPPOL compliance.
    /// Checks required fields, currency codes, addresses, VAT registration numbers, and other PEPPOL requirements.
    /// </summary>
    procedure ValidateDocument(RecordVariant: Variant)

    /// <summary>
    /// Validates all sales document lines for PEPPOL compliance.
    /// Checks line-specific requirements for electronic document transmission.
    /// </summary>
    procedure ValidateDocumentLines(RecordVariant: Variant)

    /// <summary>
    /// Validates an individual sales document line for PEPPOL compliance.
    /// Checks unit of measure codes, descriptions, tax categories, and other line-specific requirements.
    /// </summary>
    procedure ValidateDocumentLine(RecordVariant: Variant)

    /// <summary>
    /// Checks if a line has the required type and description for PEPPOL electronic documents.
    /// Validates that the line type and description meet PEPPOL requirements.
    /// </summary>
    procedure ValidateLineTypeAndDescription(RecordVariant: Variant): Boolean

    /// <summary>
    /// Validates a posted sales credit memo for PEPPOL compliance.
    /// Performs validation checks on the credit memo header and related data.
    /// </summary>
    procedure ValidatePostedDocument(RecordVariant: Variant)

}