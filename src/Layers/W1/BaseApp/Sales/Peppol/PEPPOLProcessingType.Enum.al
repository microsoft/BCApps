// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Peppol;

/// <summary>
/// Defines the document processing types supported for PEPPOL electronic invoice export.
/// </summary>
enum 1610 "PEPPOL Processing Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// Specifies that the PEPPOL document is processed as a sales transaction.
    /// </summary>
    value(0; "Sale") { Caption = 'Sale'; }
    /// <summary>
    /// Specifies that the PEPPOL document is processed as a service transaction.
    /// </summary>
    value(1; "Service") { Caption = 'Service'; }
}
