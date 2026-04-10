// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Automation;

using System.Security.User;

page 9104 "Approval Comments FactBox"
{
    Caption = 'Comments';
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = ListPart;
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
            }
        }
    }

    actions
    {
    }

    procedure SetFilterFromApprovalEntry(ApprovalEntry: Record "Approval Entry"): Boolean
    begin
        Rec.SetRange("Record ID to Approve", ApprovalEntry."Record ID to Approve");
        Rec.SetRange("Workflow Step Instance ID", ApprovalEntry."Workflow Step Instance ID");
        OnSetFilterFromApprovalEntryOnAfterSetFilters(Rec, ApprovalEntry);
        CurrPage.Update(false);
        exit(not Rec.IsEmpty);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetFilterFromApprovalEntryOnAfterSetFilters(var ApprovalCommentLine: Record "Approval Comment Line"; ApprovalEntry: Record "Approval Entry")
    begin
    end;
}

