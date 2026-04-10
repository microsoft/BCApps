// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CostAccounting.Allocation;

enum 1118 "Cost Allocation Target Period"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ' '; }
    value(1; "Week") { Caption = 'Week'; }
    value(2; "Last Week") { Caption = 'Last Week'; }
    value(3; "Month") { Caption = 'Month'; }
    value(4; "Last Month") { Caption = 'Last Month'; }
    value(5; "Month of Last Year") { Caption = 'Month of Last Year'; }
    value(6; "Year") { Caption = 'Year'; }
    value(7; "Last Year") { Caption = 'Last Year'; }
    value(8; "Period") { Caption = 'Period'; }
    value(9; "Last Period") { Caption = 'Last Period'; }
    value(10; "Period of Last Year") { Caption = 'Period of Last Year'; }
    value(11; "Fiscal Year") { Caption = 'Fiscal Year'; }
    value(12; "Last Fiscal Year") { Caption = 'Last Fiscal Year'; }
}
