// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

/// <summary>
/// Defines the printing options for unposted sales invoices.
/// </summary>
enum 230 "Sales Invoice Print Option"
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// Specifies printing a draft version of the sales invoice for internal review.
    /// </summary>
    value(1; "Draft Invoice")
    {
        Caption = 'Draft Invoice';
    }
    /// <summary>
    /// Specifies printing a pro forma invoice to provide customers with a preliminary billing document.
    /// </summary>
    value(2; "Pro Forma Invoice")
    {
        Caption = 'Pro Forma Invoice';
    }
}
