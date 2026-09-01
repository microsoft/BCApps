// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.PowerBIReports;

query 36954 "Account Categories"
{
    Access = Internal;
    QueryType = API;
    AboutText = 'Provides access to account category mappings linking category types to G/L account category entry numbers. Enables Power BI reports to classify accounts by category type and build hierarchical financial report structures for standardized financial statement presentation.';
    Caption = 'Power BI Account Categories';
    APIPublisher = 'microsoft';
    APIGroup = 'analytics';
    ApiVersion = 'v0.5', 'v1.0';
    EntityName = 'accountCategory';
    EntitySetName = 'accountCategories';
    DataAccessIntent = ReadOnly;

    elements
    {
        dataitem(PowerBIAccountCategory; "Account Category")
        {
            column(powerBIAccCategory; "Account Category Type")
            {
            }
            column(glAccCategoryEntryNo; "G/L Acc. Category Entry No.")
            {
            }
            column(parentAccCategoryEntryNo; "Parent Acc. Category Entry No.")
            {
            }
        }
    }
}