// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol;

using Microsoft.Purchases.Document;

interface "PEPPOL Purchase Document Info Provider"
{
    /// <summary>
    /// Gets general document information for BIS format from the purchase header.
    /// </summary>
    /// <param name="PurchaseHeader">The purchase header record containing the document information.</param>
    /// <param name="ID">Returns the document ID.</param>
    /// <param name="SalesOrderID">Returns the sales order ID reference.</param>
    /// <param name="IssueDate">Returns the issue date.</param>
    /// <param name="OrderTypeCode">Returns the order type code.</param>
    /// <param name="Note">Returns any additional notes.</param>
    /// <param name="DocumentCurrencyCode">Returns the document currency code.</param>
    /// <param name="AccountingCost">Returns the accounting cost reference.</param>
    /// <param name="CustomerReference">Returns the customer reference.</param>
    procedure GetGeneralInfoBIS(PurchaseHeader: Record "Purchase Header"; var ID: Text; var SalesOrderID: Text; var IssueDate: Text; var OrderTypeCode: Text; var Note: Text; var DocumentCurrencyCode: Text; var AccountingCost: Text; var CustomerReference: Text)
}
