// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Automation;

using System.Security.User;

page 660 "Approval Comments"
{
    Caption = 'Approval Comments';
    DataCaptionFields = "Record ID to Approve";
    DelayedInsert = true;
    DeleteAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Approval Comment Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Comment; Rec.Comment)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the comment. You can enter a maximum of 250 characters, both numbers and letters.';
                }
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the ID of the user who created this approval comment.';

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation(Rec."User ID");
                    end;
                }
                field("Date and Time"; Rec."Date and Time")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the date and time when the comment was made.';
                }
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = Comments;
                    ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Rec."Workflow Step Instance ID" := WorkflowStepInstanceID;
    end;

    var
        WorkflowStepInstanceID: Guid;

    procedure SetWorkflowStepInstanceID(NewWorkflowStepInstanceID: Guid)
    begin
        WorkflowStepInstanceID := NewWorkflowStepInstanceID;
    end;
}

