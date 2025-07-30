// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

enum 30138 "Shpfy Return Reason"
{

    value(0; " ")
    {
        Caption = ' ';
    }
    value(1; Color)
    {
        Caption = 'Color';
    }
    value(2; Defective)
    {
        Caption = 'Defective';
    }
    value(3; "Not as Described")
    {
        // Caption = 'Not as Described';
#pragma warning disable AL0424
        CaptionML = ENU = 'Not as Described', CSY = 'Not as Described';
#pragma warning restore AL0424
    }
    value(4; Other)
    {
        Caption = 'Other';
    }
    value(5; "Size Too Large")
    {
        Caption = 'Size Too Large';
    }
    value(6; "Size Too Small")
    {
        Caption = 'Size Too Small';
    }
    value(7; Style)
    {
        Caption = 'Style';
    }
    value(8; Unknown)
    {
        Caption = 'Unknown';
    }
    value(9; Unwanted)
    {
        Caption = 'Unwanted';
    }
    value(10; "Wrong Item")
    {
        Caption = 'Wrong Item';
    }
}