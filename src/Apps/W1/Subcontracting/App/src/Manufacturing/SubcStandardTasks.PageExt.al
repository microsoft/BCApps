// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Manufacturing.Routing;

pageextension 20515 "Subc. Standard Tasks" extends "Standard Tasks"
{
    actions
    {
        addafter(Description)
        {
            action("Subcontracting Comments")
            {
                ApplicationArea = Subcontracting;
                Caption = 'Subcontracting Comments';
                Image = ViewComments;
                RunObject = Page "Subc. Standard Task Comments";
                RunPageLink = "Standard Task Code" = field(Code);
                ToolTip = 'View or edit subcontracting comments for the standard task.';
            }
        }
        addafter(Description_Promoted)
        {
            actionref(SubcontractingComments_Promoted; "Subcontracting Comments")
            {
            }
        }
    }
}