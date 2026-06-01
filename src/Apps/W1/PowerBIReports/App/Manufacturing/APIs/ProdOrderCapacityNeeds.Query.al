// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.PowerBIReports;

using Microsoft.Manufacturing.Document;

#if not CLEAN28
#pragma warning disable AL0801
#endif
query 36987 "Prod. Order Capacity Needs"
{
    Access = Internal;
    Caption = 'Power BI Production Order Capacity Need';
    QueryType = API;
    AboutText = 'Provides access to production order capacity requirements including allocated and needed time by work center, operation, and date. Enables Power BI reports to analyze capacity load, identify bottlenecks, and support production scheduling optimization.';
    APIPublisher = 'microsoft';
    APIGroup = 'analytics';
    ApiVersion = 'v0.5', 'v1.0';
    EntityName = 'prodOrderCapacityNeed';
    EntitySetName = 'prodOrderCapacityNeeds';
    DataAccessIntent = ReadOnly;

    elements
    {
        dataitem(ProdOrderCapacityNeed; "Prod. Order Capacity Need")
        {
            column(status; Status) { }
            column(prodOrderNo; "Prod. Order No.") { }
            column(routingNo; "Routing No.") { }
            column(routingReferenceNo; "Routing Reference No.") { }
            column(operationNo; "Operation No.") { }
            column(allocatedTime; "Allocated Time") { }
            column(requestedOnly; "Requested Only") { }
            column(workCenterNo; "Work Center No.") { }
            column(workCenterGroupCode; "Work Center Group Code") { }
            column(date; Date) { }
            column(no; "No.") { }
            column(type; Type) { }
            column(neededTimeMs; "Needed Time (ms)") { }
            column(neededTime; "Needed Time") { }
            column(lineNo; "Line No.") { }
        }
    }

    trigger OnBeforeOpen()
    begin
        CurrQuery.SetFilter(status, '<>%1', status::Finished);
    end;
}