// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

enum 104 "Cost Entry Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Direct Cost") { Caption = 'Direct Cost'; }
    value(1; "Revaluation") { Caption = 'Revaluation'; }
    value(2; "Rounding") { Caption = 'Rounding'; }
    value(3; "Indirect Cost") { Caption = 'Indirect Cost'; }
    value(4; "Variance") { Caption = 'Variance'; }
    value(5; "Total") { Caption = 'Total'; }
    value(10; "Direct Cost - Non Inventory") { Caption = 'Direct Cost - Non Inventory'; }
}
