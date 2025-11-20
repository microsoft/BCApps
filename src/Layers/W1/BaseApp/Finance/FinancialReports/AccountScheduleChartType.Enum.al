// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

enum 763 "Account Schedule Chart Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ' '; }
    value(1; "Line") { Caption = 'Line'; }
    value(2; "StepLine") { Caption = 'StepLine'; }
    value(3; "Column") { Caption = 'Column'; }
    value(4; "StackedColumn") { Caption = 'StackedColumn'; }
}
