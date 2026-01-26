// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Setup;

pageextension 12460 "Service Mgt. Setup IT" extends "Service Mgt. Setup"
{
    layout
    {
        addafter("Check Multiple Posting Groups")
        {
            field("Validate Document On Posting"; Rec."Validate Document On Posting")
            {
                ApplicationArea = Service;
                ToolTip = 'Specifies that you cannot post an invoice or credit memo that has Fattura PA errors.';
            }
            field("Notify On Occur. Date Change"; Rec."Notify On Occur. Date Change")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Posting Date after Operation Occurred Date notification';
                ToolTip = 'Specifies that you will get a notification when changing the Posting Date field to a date later than currently in the Operation Occurred Date field.';
            }
        }
    }
}