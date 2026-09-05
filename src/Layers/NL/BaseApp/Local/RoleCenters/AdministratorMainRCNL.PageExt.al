// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.RoleCenters;

using Microsoft.Foundation.Address;

pageextension 11350 "Administrator Main RC NL" extends "Administrator Main Role Center"
{
    actions
    {
        addafter("Electronic Document Formats")
        {
            action("Post Code Updates")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Post Code Updates';
                Image = UpdateDescription;
                RunObject = page "Post Code Updates";
                ToolTip = 'View and manage post code updates.';
            }
        }
        modify("Post Codes")
        {
            Visible = false;
        }
    }
}