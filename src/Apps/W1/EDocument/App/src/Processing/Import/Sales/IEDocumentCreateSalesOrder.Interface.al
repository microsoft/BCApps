// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument.Processing.Import.Sales;

using Microsoft.eServices.EDocument;
using Microsoft.Sales.Document;

/// <summary>
/// Interface for changing the way that sales orders get created from an E-Document.
/// </summary>
interface IEDocumentCreateSalesOrder
{
    /// <summary>
    /// Creates a sales order from an E-Document with a draft ready.
    /// </summary>
    /// <param name="EDocument">The E-Document record for which to create the sales order.</param>
    /// <returns>The created Sales Header record.</returns>
    procedure CreateSalesOrder(EDocument: Record "E-Document"): Record "Sales Header";
}
