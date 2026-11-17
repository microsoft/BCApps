// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.History;

pageextension 13410 "Posted Service Invoice FI" extends "Posted Service Invoice"
{
    layout
    {
#if not CLEAN30
        addafter("Your Reference")
        {
            field("Reference No."; Rec."Reference No.")
            {
                ApplicationArea = Service;
                Editable = false;
                ToolTip = 'Specifies the reference number that is calculated from a reference number sequence.';
                ObsoleteState = Pending;
                ObsoleteReason = 'Moved to Banking and Payments FI app.';
                ObsoleteTag = '30.0';
            }
        }
#endif
    }
}
