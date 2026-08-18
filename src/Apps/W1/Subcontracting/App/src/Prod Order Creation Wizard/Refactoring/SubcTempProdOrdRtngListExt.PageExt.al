// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Manufacturing.Wizard;

pageextension 99001565 SubcTempProdOrdRtngListExt extends "Temp Prod. Ord. Rtng List"
{
    layout
    {
        addafter("No.")
        {
            field(SubcVendorNoSubcPrice; Rec."Vendor No. Subc. Price")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Vendor No. (Subc. Price)';
                ToolTip = 'Specifies the vendor number used to look up the subcontracting price for this routing operation.';
            }
        }
    }
}