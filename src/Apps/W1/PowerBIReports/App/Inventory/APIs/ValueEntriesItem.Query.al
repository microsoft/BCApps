// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.PowerBIReports;

using Microsoft.Inventory.Ledger;

query 36967 "Value Entries - Item"
{
    Access = Internal;
    Caption = 'Power BI Inventory Value';
    QueryType = API;
    AboutText = 'Provides access to item value entries including actual and expected costs, cost posted to G/L, valuation dates, and entry types. Enables Power BI reports to analyze inventory valuation, cost of goods sold, and inventory value reconciliation with the general ledger.';
    APIPublisher = 'microsoft';
    APIGroup = 'analytics';
    ApiVersion = 'v0.5', 'v1.0';
    EntityName = 'itemValueEntry';
    EntitySetName = 'itemValueEntries';
    DataAccessIntent = ReadOnly;

    elements
    {
        dataitem(valueEntry; "Value Entry")
        {
            DataItemTableFilter = "Item No." = filter(<> '');

            column(entryNo; "Entry No.")
            {
            }
            column(valuationDate; "Valuation Date")
            {
            }
            column(itemNo; "Item No.")
            {
            }
            column(costAmountActual; "Cost Amount (Actual)")
            {
            }
            column(costAmountExpected; "Cost Amount (Expected)")
            {
            }
            column(costPostedToGL; "Cost Posted to G/L")
            {
            }
            column(invoicedQuantity; "Invoiced Quantity")
            {
            }
            column(expectedCostPostedToGL; "Expected Cost Posted to G/L")
            {
            }
            column(locationCode; "Location Code")
            {
            }
            column(itemLedgerEntryType; "Item Ledger Entry Type")
            {
            }
            column(postingDate; "Posting Date")
            {
            }
            column(documentType; "Document Type")
            {
            }
            column(type; Type)
            {
            }
            column(dimensionSetID; "Dimension Set ID")
            {
            }
        }
    }
}