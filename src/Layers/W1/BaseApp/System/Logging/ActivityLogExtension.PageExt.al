// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

using System.Security.User;

pageextension 711 "Activity Log Extension" extends "Activity Log"
{
    layout
    {
        addafter("Activity Date")
        {
            field("User ID"; Rec."User ID")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the ID of the user who posted the entry, to be used, for example, in the change log.';

                trigger OnDrillDown()
                var
                    UserMgt: Codeunit "User Management";
                begin
                    UserMgt.DisplayUserInformation(Rec."User ID");
                end;
            }
        }
    }

    actions
    {
        addfirst(processing)
        {
            action(OpenRelatedRecord)
            {
                ApplicationArea = Invoicing, Suite;
                Caption = 'Open Related Record';
                Image = View;
                ToolTip = 'Open the record that is associated with this activity.';

                trigger OnAction()
                var
                    PageManagement: Codeunit "Page Management";
                begin
                    if not PageManagement.PageRun(Rec."Record ID") then
                        Message(NoRelatedRecordMsg);
                end;
            }
        }
        addfirst(Category_Process)
        {
            actionref(OpenRelatedRecord_Promoted; OpenRelatedRecord)
            {
            }
        }
    }

    var
        NoRelatedRecordMsg: Label 'There are no related records to display.';
}