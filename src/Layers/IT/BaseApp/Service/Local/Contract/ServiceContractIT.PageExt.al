// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Contract;

pageextension 12143 "Service Contract IT" extends "Service Contract"
{
    layout
    {
        addafter("Change Status")
        {
#if not CLEAN30
            field("Activity Code"; Rec."Activity Code")
            {
                ApplicationArea = Service;
                ToolTip = 'Specifies the code for the company''s primary activity.';
                Visible = false;
                ObsoleteReason = 'Replaced by the Business Activity Code field.';
                ObsoleteState = Pending;
                ObsoleteTag = '30.0';
            }
#endif
        }        
    }
}
