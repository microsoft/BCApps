// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

#pragma warning disable AS0072, AS0136
enum 20503 "Components at Location"
{
    Extensible = true;
    value(0; Empty)
    {
        Caption = ' ', Locked = true;
    }
    value(1; Purchase)
    {
        Caption = 'Purchase Line';
    }
    value(2; Company)
    {
        Caption = 'Company Info';
    }
    value(3; Manufacturing)
    {
        Caption = 'Manufacturing Setup';
    }
}
#pragma warning restore AS0072, AS0136
