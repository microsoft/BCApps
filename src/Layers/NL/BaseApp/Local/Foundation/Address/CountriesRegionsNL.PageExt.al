// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Address;

pageextension 11381 "Countries/Regions NL" extends "Countries/Regions"
{
    layout
    {
        addafter("ISO Numeric Code")
        {
            field("SEPA Allowed"; Rec."SEPA Allowed")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies if the Single Euro Payments Area (SEPA) function is active for the country/region.';
            }
        }
    }
}
