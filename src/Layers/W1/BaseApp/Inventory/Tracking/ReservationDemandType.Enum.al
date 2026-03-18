// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

enum 301 "Reservation Demand Type"
{
    Extensible = true;

    value(0; All) { Caption = 'All'; }
    value(1; "Sales Orders") { Caption = 'Sales Orders'; }
    value(2; "Transfer Orders") { Caption = 'Transfer Orders'; }
    value(3; "Service Orders") { Caption = 'Service Orders'; }
    value(4; "Job Usage") { Caption = 'Project Usage'; }
    value(5; "Production Components") { Caption = 'Production Components'; }
    value(6; "Assembly Components") { Caption = 'Assembly Components'; }
}
