// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.PowerBIReports;

using Microsoft.Manufacturing.Routing;

#if not CLEAN28
#pragma warning disable AL0801
#endif
query 37010 "Routings - PBI API"
{
    Access = Internal;
    Caption = 'Power BI Routings';
    QueryType = API;
    AboutText = 'Provides access to routing header master data including routing type, status, and description. Enables Power BI reports to list manufacturing routings and filter production data by routing characteristics.';
    APIPublisher = 'microsoft';
    APIGroup = 'analytics';
    ApiVersion = 'v0.5', 'v1.0';
    EntityName = 'routing';
    EntitySetName = 'routings';
    DataAccessIntent = ReadOnly;

    elements
    {
        dataitem(routing; "Routing Header")
        {
            column(no; "No.") { }
            column(type; Type) { }
            column(status; Status) { }
            column(description; Description) { }
        }
    }
}