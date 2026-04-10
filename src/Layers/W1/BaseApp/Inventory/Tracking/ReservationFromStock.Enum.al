// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

enum 342 "Reservation From Stock"
{
    Extensible = true;

    value(0; " ")
    {
        Caption = ' ';
    }
    value(1; None)
    {
        Caption = 'None';
    }
    value(2; Partial)
    {
        Caption = 'Partial';
    }
    value(3; "Full and Partial")
    {
        Caption = 'Full and Partial';
    }
    value(4; Full)
    {
        Caption = 'Full';
    }
}
