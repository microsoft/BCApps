// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.PowerBIReports;

using Microsoft.Inventory.Analysis;

query 37002 "Item Budget Names"
{
    Access = Internal;
    QueryType = API;
    AboutText = 'Provides access to item budget names and descriptions for sales and purchase analysis areas. Enables Power BI reports to list available budgets and filter budget entries by budget name.';
    Caption = 'Power BI Item Budgets';
    APIPublisher = 'microsoft';
    APIGroup = 'analytics';
    ApiVersion = 'v0.5', 'v1.0';
    EntityName = 'itemBudget';
    EntitySetName = 'itemBudgets';
    DataAccessIntent = ReadOnly;

    elements
    {
        dataitem(ItemBudgetName; "Item Budget Name")
        {
            column(analysisArea; "Analysis Area")
            {
            }
            column(budgetName; Name)
            {
            }
            column(budgetDescription; Description)
            {
            }
        }
    }
}