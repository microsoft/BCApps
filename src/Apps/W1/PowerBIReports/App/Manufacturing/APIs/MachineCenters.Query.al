// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.PowerBIReports;

using Microsoft.Manufacturing.MachineCenter;

#if not CLEAN28
#pragma warning disable AL0801
#endif
query 36985 "Machine Centers"
{
    Access = Internal;
    Caption = 'Power BI Machine Centers';
    QueryType = API;
    AboutText = 'Provides access to machine center master data including numbers, names, and associated work center assignments. Enables Power BI reports to analyze machine utilization, build capacity hierarchies, and track production resources for manufacturing capacity planning.';
    APIPublisher = 'microsoft';
    APIGroup = 'analytics';
    ApiVersion = 'v0.5', 'v1.0';
    EntityName = 'machineCenter';
    EntitySetName = 'machineCenters';
    DataAccessIntent = ReadOnly;

    elements
    {
        dataitem(MachineCenter; "Machine Center")
        {
            column(no; "No.") { }
            column(name; Name) { }
            column(workCenterNo; "Work Center No.") { }
        }
    }
}