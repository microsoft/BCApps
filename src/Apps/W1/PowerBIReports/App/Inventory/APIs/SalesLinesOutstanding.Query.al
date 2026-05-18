// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.PowerBIReports;

using Microsoft.Sales.Document;

query 36975 "Sales Lines - Outstanding"
{
    Access = Internal;
    Caption = 'Power BI Sales Lines';
    QueryType = API;
    AboutText = 'Provides access to outstanding sales order and return order lines for items including quantities, shipment dates, and customers. Enables Power BI reports to analyze pending sales demand and forecast inventory requirements for sales fulfillment.';
    APIPublisher = 'microsoft';
    APIGroup = 'analytics';
    ApiVersion = 'v0.5', 'v1.0';
    EntityName = 'outstandingSalesLine';
    EntitySetName = 'outstandingSalesLines';
    DataAccessIntent = ReadOnly;

    elements
    {

        dataitem(salesLines; "Sales Line")
        {
            DataItemTableFilter = Type = const(Item), "Outstanding Qty. (Base)" = filter(> 0), "Document Type" = filter(Order | "Return Order");
            column(documentNo; "Document No.")
            {
            }
            column(documentType; "Document Type")
            {
            }
            column(sellToCustomerNo; "Sell-to Customer No.")
            {
            }
            column(itemNo; "No.")
            {
            }
            column(outstandingQtyBase; "Outstanding Qty. (Base)")
            {
                Method = Sum;
            }
            column(shipmentDate; "Shipment Date")
            {
            }
            column(locationCode; "Location Code")
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