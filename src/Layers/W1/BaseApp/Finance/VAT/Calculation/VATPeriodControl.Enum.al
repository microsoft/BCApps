// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Calculation;

enum 260 "VAT Period Control"
{
    Extensible = false;

    value(0; "Block posting within closed and warn for released period")
    {
        Caption = 'Block posting within closed and warn for released period';
    }
    value(1; "Block posting within closed period")
    {
        Caption = 'Block posting within closed period';
    }
    value(2; "Warn when posting in closed period")
    {
        Caption = 'Warn when posting in closed period';
    }
    value(3; "Disabled")
    {
        Caption = 'Disabled';
    }
}
