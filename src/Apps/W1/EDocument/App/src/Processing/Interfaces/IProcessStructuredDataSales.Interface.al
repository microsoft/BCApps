// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Interfaces;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.Sales.Customer;

/// <summary>
/// Extends IProcessStructuredData for sales document processing, adding customer resolution.
/// </summary>
interface IProcessStructuredDataSales extends IProcessStructuredData
{

    /// <summary>
    /// Get the customer for the E-Document
    /// </summary>
    procedure GetCustomer(EDocument: Record "E-Document"; Customizations: Enum "E-Doc. Proc. Customizations"): Record Customer;
}
