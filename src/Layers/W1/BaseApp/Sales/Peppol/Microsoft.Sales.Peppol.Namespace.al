// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

/// <summary>
/// Provides functionality for exporting sales documents to PEPPOL electronic invoice formats.
/// </summary>
/// <remarks>
/// PEPPOL (Pan-European Public Procurement Online) is a European standard for electronic invoicing
/// that enables businesses to exchange documents in a standardized XML format. This namespace supports
/// multiple PEPPOL versions (2.0, 2.1, and BIS 3.0) for both sales invoices and credit memos.
///
/// The namespace includes:
/// - Export codeunits that orchestrate the XML generation process
/// - XMLport objects that define the UBL (Universal Business Language) document structure
/// - Validation codeunit to ensure documents meet PEPPOL requirements before export
/// - Management codeunit providing helper functions for data extraction and formatting
///
/// Note: PEPPOL versions 2.0 and 2.1 are deprecated and marked as obsolete. New implementations
/// should use PEPPOL BIS 3.0 format.
/// </remarks>
namespace Microsoft.Sales.Peppol;
