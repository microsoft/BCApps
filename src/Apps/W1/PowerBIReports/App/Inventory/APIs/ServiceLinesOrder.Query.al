// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.PowerBIReports;

using Microsoft.Service.Document;

query 36976 "Service Lines - Order"
{
    Access = Internal;
    Caption = 'Power BI Qty. on Service Lines';
    QueryType = API;
    AboutText = 'Provides access to service order lines for items including outstanding quantities, needed-by dates, and locations. Enables Power BI reports to analyze service demand and forecast inventory requirements for service order fulfillment.';
    APIPublisher = 'microsoft';
    APIGroup = 'analytics';
    ApiVersion = 'v0.5', 'v1.0';
    EntityName = 'orderServiceLine';
    EntitySetName = 'orderServiceLines';
    DataAccessIntent = ReadOnly;

    elements
    {
        dataitem(serviceLine; "Service Line")
        {
            DataItemTableFilter = "Document Type" = const(Order), Type = const(Item);

            column(documentNo; "Document No.")
            {
            }

            column(itemNo; "No.")
            {
            }
            column(locationCode; "Location Code")
            {
            }
            column(outstandingQtyBase; "Outstanding Qty. (Base)")
            {
                Method = Sum;
            }
            column(neededByDate; "Needed by Date")
            {
            }
            column(dimensionSetID; "Dimension Set ID")
            {
            }
            column(qtyPerUnitOfMeasure; "Qty. per Unit of Measure")
            {
            }
            column(unitOfMeasureCode; "Unit of Measure Code")
            {
            }
        }
    }
}