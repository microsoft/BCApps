// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CostAccounting.Allocation;

enum 1119 "Cost Allocation Target Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "All Costs") { Caption = 'All Costs'; }
    value(1; "Percent per Share") { Caption = 'Percent per Share'; }
    value(2; "Amount per Share") { Caption = 'Amount per Share'; }
}
