// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

enum 5800 "Cost Adjustment Run Status"
{
    Extensible = true;
    Caption = 'Cost Adjustment Run Status';

    value(0; "Not started")
    {
        Caption = 'Not started';
    }
    value(1; "Running")
    {
        Caption = 'Running';
    }
    value(2; "Success")
    {
        Caption = 'Success';
    }
    value(3; "Failed")
    {
        Caption = 'Failed';
    }
    value(4; "Timed out")
    {
        Caption = 'Timed out';
    }
    value(5; "Canceled")
    {
        Caption = 'Canceled';
    }
}
