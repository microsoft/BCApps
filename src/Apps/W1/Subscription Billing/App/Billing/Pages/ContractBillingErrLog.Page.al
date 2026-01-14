namespace Microsoft.SubscriptionBilling;

page 8113 "Contract Billing Err. Log"
{
    Caption = 'Contract Billing Error Log';
    PageType = List;
    ApplicationArea = All;
    SourceTable = "Contract Billing Err. Log";
    UsageCategory = Lists;
    Editable = false;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ToolTip = 'Specifies the unique entry number for the error log record.';
                }
                field("Billing Template Code"; Rec."Billing Template Code")
                {
                    ToolTip = 'Specifies the billing template code that was being processed when the error occurred.';
                }
                field("Error Text"; Rec."Error Text")
                {
                    ToolTip = 'Specifies the error message that occurred during the auto contract billing process.';
                }
                field("Subscription"; Rec."Subscription")
                {
                    ToolTip = 'Specifies the subscription number that was being processed when the error occurred.';
                }
                field("Subscription Entry No."; Rec."Subscription Entry No.")
                {
                    ToolTip = 'Specifies the subscription line entry number that was being processed when the error occurred.';
                }
                field("Subscription Contract No."; Rec."Subscription Contract No.")
                {
                    ToolTip = 'Specifies the subscription contract number that was being processed when the error occurred.';
                }
                field("Contract Line No."; Rec."Contract Line No.")
                {
                    ToolTip = 'Specifies the contract line number that was being processed when the error occurred.';
                }
                field("Contract Type"; Rec."Contract Type")
                {
                    ToolTip = 'Specifies the contract type that was being processed when the error occurred.';
                }
                field("Assigned User ID"; Rec."Assigned User ID")
                {
                    ToolTip = 'Specifies the user ID assigned to handle this error.';
                }
                field("Salesperson Code"; Rec."Salesperson Code")
                {
                    ToolTip = 'Specifies the salesperson code associated with the contract that had an error.';
                }
                field(SystemCreatedAt; Rec.SystemCreatedAt)
                {
                    Caption = 'Created On';
                    ToolTip = 'Specifies when the entry was created.';
                }
                field(SystemCreatedBy; Rec.SystemCreatedBy)
                {
                    Caption = 'Created By';
                    ToolTip = 'Specifies the users who has created this entry.';
                }
            }
        }
    }
    actions
    {
        area(processing)
        {
            action(Delete7days)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Delete Entries Older Than 7 Days';
                Image = ClearLog;
                ToolTip = 'Clear the list of log entries that are older than 7 days.';

                trigger OnAction()
                begin
                    Rec.DeleteEntries(7);
                end;
            }
            action(Delete0days)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Delete All Entries';
                Image = Delete;
                ToolTip = 'Clear the list of all log entries.';

                trigger OnAction()
                begin
                    Rec.DeleteEntries(0);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';
                actionref(Delete0days_Promoted; Delete0days)
                {
                }
                actionref(Delete7days_Promoted; Delete7days)
                {
                }
            }
        }
    }
}