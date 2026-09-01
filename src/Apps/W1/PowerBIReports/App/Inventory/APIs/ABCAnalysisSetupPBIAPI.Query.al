// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.PowerBIReports;

using Microsoft.Inventory.Analysis;

query 37022 "ABC Analysis Setup - PBI API"
{
    Access = Internal;
    Caption = 'Power BI ABC Analysis Setup';
    QueryType = API;
    APIPublisher = 'microsoft';
    APIGroup = 'analytics';
    ApiVersion = 'v1.0';
    EntityName = 'abcAnalysisSetup';
    EntitySetName = 'abcAnalysisSetups';
    DataAccessIntent = ReadOnly;

    elements
    {
        dataitem(abcAnalysisSetup; "ABC Analysis Setup")
        {
            column(categoryA; "Category A")
            {
            }
            column(categoryB; "Category B")
            {
            }
            column(categoryC; "Category C")
            {
            }
        }
    }
}