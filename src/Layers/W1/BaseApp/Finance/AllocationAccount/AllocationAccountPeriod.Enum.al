// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.AllocationAccount;

enum 2674 "Allocation Account Period"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Balance at Date") { Caption = 'Balance at Date'; }
    value(1; "Fiscal Year") { Caption = 'Fiscal Year'; }
    value(2; "Week") { Caption = 'Week'; }
    value(3; "Last Week") { Caption = 'Last Week'; }
    value(4; "Month") { Caption = 'Month'; }
    value(5; "Last Month") { Caption = 'Last Month'; }
    value(6; "Quarter") { Caption = 'Quarter'; }
    value(7; "Last Quarter") { Caption = 'Last quarter'; }
    value(8; "Year") { Caption = 'Year'; }
    value(9; "Last Year") { Caption = 'Last Year'; }
    value(10; "Month of Last Year") { Caption = 'Month of Last Year'; }
    value(11; "Period") { Caption = 'Period'; }
    value(12; "Last Period") { Caption = 'Last Period'; }
    value(13; "Period of Last Year") { Caption = 'Period of Last Year'; }
    value(14; "Last Fiscal Year") { Caption = 'Last Fiscal Year'; }
}
