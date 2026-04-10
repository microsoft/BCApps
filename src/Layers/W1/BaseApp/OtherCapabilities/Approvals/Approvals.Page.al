// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Automation;

page 832 Approvals
{
    Caption = 'Approvals';
    Editable = false;
    PageType = List;
    SourceTable = "Workflows Entries Buffer";
    SourceTableTemporary = true;
    SourceTableView = sorting("Record ID", "Last Date-Time Modified")
                      order(ascending);

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Created by Application"; Rec."Created by Application")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the integrated app or product that the approval request comes from. ';
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when the approval is due.';
                }
                field("Record ID"; RecordIDText)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Record ID';
                    ToolTip = 'Specifies the Record ID field.';

                    trigger OnDrillDown()
                    var
                        ApprovalEntry: Record "Approval Entry";
                        WorkflowWebhookEntries: Page "Workflow Webhook Entries";
                    begin
                        if Rec."Created by Application" = Rec."Created by Application"::"Microsoft Flow" then begin
                            WorkflowWebhookEntries.Setfilters(Rec."Record ID");
                            WorkflowWebhookEntries.Run();
                        end else begin
                            ApprovalEntry.SetRange("Record ID to Approve", Rec."Record ID");
                            PAGE.Run(PAGE::"Approval Entries", ApprovalEntry);
                        end;
                    end;
                }
                field("Initiated By User ID"; Rec."Initiated By User ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the User ID which has initiated the approval.';
                }
                field("To Be Approved By User ID"; Rec."To Be Approved By User ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the user ID that needs to approve the action.';
                }
                field("Date-Time Initiated"; Rec."Date-Time Initiated")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date and time that the approvals were initiated.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status of the approval on the line.';
                }
                field(Response; Rec.Response)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the related workflow response.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        RecordIDText := Format(Rec."Record ID", 0, 1);
    end;

    trigger OnOpenPage()
    var
        WorkflowWebhookEntry: Record "Workflow Webhook Entry";
        ApprovalEntry: Record "Approval Entry";
        WorkflowsCounter: Integer;
    begin
        WorkflowsCounter := 0;

        // get all records from Workflow Webhook Entry table
        if WorkflowWebhookEntry.Find('-') then
            repeat
                Rec.AddWorkflowWebhookEntry(WorkflowWebhookEntry, WorkflowsCounter);
            until WorkflowWebhookEntry.Next() = 0;

        // add all records from Approval Entry table
        if ApprovalEntry.Find('-') then
            repeat
                Rec.AddApprovalEntry(ApprovalEntry, WorkflowsCounter);
            until ApprovalEntry.Next() = 0;
    end;

    var
        RecordIDText: Text;

    procedure Setfilters(RecordIDValue: RecordID)
    begin
        Rec.SetRange("Record ID", RecordIDValue);
    end;
}

