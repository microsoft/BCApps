// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

enum 99001502 "Direct Transfer Post. Type"
{
    Extensible = true;

    value(0; Empty)
    {
        Caption = ' ', Locked = true;
    }
    value(1; "Receipt and Shipment")
    {
        Caption = 'Receipt and Shipment';
    }
    value(2; "Direct Transfer")
    {
        Caption = 'Direct Transfer';
    }
}