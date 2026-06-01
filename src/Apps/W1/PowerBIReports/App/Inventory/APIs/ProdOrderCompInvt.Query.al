// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.PowerBIReports;

using Microsoft.Manufacturing.Document;

#if not CLEAN28
#pragma warning disable AL0801
#endif
query 36971 "Prod. Order Comp. - Invt."
{
    Access = Internal;
    Caption = 'Power BI Qty. on Component Lines';
    QueryType = API;
    AboutText = 'Provides access to production order component data including item numbers, remaining quantities, due dates, and locations for planned to released orders. Enables Power BI reports to analyze production material requirements and component consumption for inventory availability planning.';
    APIPublisher = 'microsoft';
    APIGroup = 'analytics';
    ApiVersion = 'v0.5', 'v1.0';
    EntityName = 'inventoryProdOrderComponentLine';
    EntitySetName = 'inventoryProdOrderComponentLines';
    DataAccessIntent = ReadOnly;

    elements
    {
        dataitem(prodOrderComponent; "Prod. Order Component")
        {
            DataItemTableFilter = Status = filter(Planned .. Released);
            column(status; Status)
            {
            }
            column(documentNo; "Prod. Order No.")
            {
            }

            column(itemNo; "Item No.")
            {
            }
            column(locationCode; "Location Code")
            {
            }
            column(remainingQtyBase; "Remaining Qty. (Base)")
            {
                Method = Sum;
            }
            column(dueDate; "Due Date")
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