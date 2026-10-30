#if INTERCOMPANY_NA
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Customer;

pageextension 8559 "IC Customer Collections NA" extends "Customer List - Collections"
{
    layout
    {
        addafter("Fax No.")
        {
            field("IC Partner Code"; Rec."IC Partner Code")
            {
                Editable = false;
                ToolTip = 'Specifies the code for the company''s intercompany (IC) partner.';
                Visible = false;
            }
        }
    }
}
#endif
