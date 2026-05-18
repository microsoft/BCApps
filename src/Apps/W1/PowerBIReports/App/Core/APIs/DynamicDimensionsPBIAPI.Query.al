// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.PowerBIReports;

using Microsoft.Finance.Dimension;

query 37016 "Dynamic Dimensions - PBI API"
{
    QueryType = API;
    AboutText = 'Provides access to dimension set entries with dynamically resolved dimension codes, values, and names. Enables Power BI reports to retrieve flexible dimensional structures for custom analytics, supporting organizations with varying dimension configurations beyond the standard eight shortcut dimensions.';
    APIPublisher = 'microsoft';
    APIGroup = 'analytics';
    ApiVersion = 'v0.5', 'v1.0';
    Caption = 'Power BI Dynamic Dimensions';
    EntityName = 'dynamicDimension';
    EntitySetName = 'dynamicDimensions';
    DataAccessIntent = ReadOnly;

    elements
    {
        dataitem(DimSetEntry; Microsoft.Finance.Dimension."Dimension Set Entry")
        {
            column(dimensionSetID; "Dimension Set ID") { }
            column(customDimensionValueCode; "Dimension Value Code") { }
            column(modifiedAt; SystemModifiedAt) { }
            dataitem(dimensionValue; "Dimension Value")
            {
                DataItemLink = "Dimension Code" = DimSetEntry."Dimension Code", Code = DimSetEntry."Dimension Value Code";
                SqlJoinType = LeftOuterJoin;
                column(customDimensionValueName; Name) { }
                column(globalDimensionNo; "Global Dimension No.") { }
                dataitem(Dimension; Dimension)
                {
                    DataItemLink = "Code" = DimensionValue."Dimension Code";
                    SqlJoinType = LeftOuterJoin;
                    column(customDimensionName; Name) { }
                    column(customDimensionCode; Code) { }
                    column(modifiedAtDimensionValue; SystemModifiedAt) { }
                    column(noRows)
                    {
                        Method = Count;
                    }
                }
            }
        }
    }
}

