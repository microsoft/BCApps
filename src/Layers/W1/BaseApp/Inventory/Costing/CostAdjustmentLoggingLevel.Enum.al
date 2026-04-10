// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

enum 5801 "Cost Adjustment Logging Level"
{
    Extensible = true;
    Caption = 'Cost Adjustment Logging Level';

    value(0; "Disabled")
    {
        Caption = 'Disabled';
    }
    value(1; "Errors Only")
    {
        Caption = 'Errors Only';
    }
    value(2; "All")
    {
        Caption = 'All';
    }
}
