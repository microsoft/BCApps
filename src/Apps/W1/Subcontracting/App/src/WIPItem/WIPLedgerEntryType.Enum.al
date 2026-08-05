// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

#pragma warning disable AS0072, AS0136
enum 20508 "WIP Ledger Entry Type"
{
    Extensible = true;
    value(0; "Positive Adjustment")
    {
        Caption = 'Positive Adjustment';
    }
    value(1; "Negative Adjustment")
    {
        Caption = 'Negative Adjustment';
    }
}
#pragma warning restore AS0072, AS0136
