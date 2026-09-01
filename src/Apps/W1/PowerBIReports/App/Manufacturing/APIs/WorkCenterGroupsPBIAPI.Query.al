// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.PowerBIReports;

using Microsoft.Manufacturing.WorkCenter;

#if not CLEAN28
#pragma warning disable AL0801
#endif
query 37012 "Work Center Groups - PBI API"
{
    Access = Internal;
    Caption = 'Power BI Work Center Groups';
    QueryType = API;
    AboutText = 'Provides access to work center group master data including codes and names. Work center groups organize work centers for aggregate capacity planning and reporting. Enables Power BI reports to analyze capacity utilization at the group level.';
    APIPublisher = 'microsoft';
    APIGroup = 'analytics';
    ApiVersion = 'v0.5', 'v1.0';
    EntityName = 'workCenterGroup';
    EntitySetName = 'workCenterGroups';
    DataAccessIntent = ReadOnly;

    elements
    {
        dataitem(workCenterGroup; "Work Center Group")
        {
            column(code; Code) { }
            column(name; Name) { }
        }
    }
}