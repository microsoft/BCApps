// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument.Processing.Import.Sales;

using Microsoft.eServices.EDocument;
using Microsoft.Sales.Customer;

/// <summary>
/// Interface for retrieving customer information based on an E-Document.
/// </summary>
interface ICustomerProvider
{
    /// <summary>
    /// Retrieves the customer associated with the given E-Document.
    /// </summary>
    /// <param name="EDocument">The E-Document record containing relevant details.</param>
    /// <returns>A Customer record matching the E-Document.</returns>
    procedure GetCustomer(EDocument: Record "E-Document"): Record Customer;
}
