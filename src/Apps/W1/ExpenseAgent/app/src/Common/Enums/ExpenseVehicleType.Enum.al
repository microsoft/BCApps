// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

enum 6989 "Expense Vehicle Type"
{
    Caption = 'Vehicle Type';
    Extensible = true;

    value(0; " ") { Caption = 'All'; }
    value(1; Car) { Caption = 'Car'; }
    value(2; Motorcycle) { Caption = 'Motorcycle'; }
    value(3; Van) { Caption = 'Van'; }
    value(4; Truck) { Caption = 'Truck'; }
}
