// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sustainability.EUDR;

enum 6234 "EUDR Commodity"
{
    Extensible = false;

    value(0; " ")
    {
        Caption = ' ';
    }
    value(1; Cattle)
    {
        Caption = 'Cattle';
    }
    value(2; Cocoa)
    {
        Caption = 'Cocoa';
    }
    value(3; Coffee)
    {
        Caption = 'Coffee';
    }
    value(4; "Oil palm")
    {
        Caption = 'Oil palm';
    }
    value(5; Rubber)
    {
        Caption = 'Rubber';
    }
    value(6; Soya)
    {
        Caption = 'Soya';
    }
    value(7; Wood)
    {
        Caption = 'Wood';
    }
}