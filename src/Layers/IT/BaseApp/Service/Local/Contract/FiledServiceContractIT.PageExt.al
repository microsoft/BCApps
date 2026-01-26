// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Contract;

pageextension 12150 "Filed Service Contract IT" extends "Filed Service Contract"
{
    layout
    {
        addafter("Change Status")
        {
            field("Activity Code"; Rec."Activity Code")
            {
                ApplicationArea = Service;
                ToolTip = 'Specifies the code for the company''s primary activity.';
            }
        }
    }
}