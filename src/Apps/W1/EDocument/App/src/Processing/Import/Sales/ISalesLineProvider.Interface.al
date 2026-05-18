#pragma warning disable AL0749
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import.Sales;

/// <summary>
/// Interface for determining the item/resource assignment for a sales line in an E-Document.
/// </summary>
interface ISalesLineProvider
{
    /// <summary>
    /// Determines the sales line fields for a given E-Document sales line.
    /// </summary>
    /// <param name="EDocumentSalesLine">The sales line record from the E-Document.</param>
    procedure GetSalesLine(var EDocumentSalesLine: Record "E-Document Sales Line");
}
#pragma warning restore AL0749
