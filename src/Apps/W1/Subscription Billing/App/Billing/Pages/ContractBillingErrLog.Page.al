namespace Microsoft.SubscriptionBilling;

page 8113 "Contract Billing Err Log"
{
    Caption = 'Contract Billing Error Log';
    PageType = List;
    ApplicationArea = All;
    SourceTable = "Contract Billing Err Log";
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
                    ApplicationArea = All;
                    ToolTip = 'Specifies the unique entry number for the error log record.';
                }
                field("Billing Template Code"; Rec."Billing Template Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the billing template code that was being processed when the error occurred.';
                }
                field("Error Text"; Rec."Error Text")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the error message that occurred during the auto contract billing process.';
                }
                field("Subscription"; Rec."Subscription")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the subscription number that was being processed when the error occurred.';
                }
                field("Subscription Entry No."; Rec."Subscription Entry No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the subscription line entry number that was being processed when the error occurred.';
                }
                field("Subscription Contract No."; Rec."Subscription Contract No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the subscription contract number that was being processed when the error occurred.';
                }
                field("Contract Line No."; Rec."Contract Line No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the contract line number that was being processed when the error occurred.';
                }
                field("Contract Type"; Rec."Contract Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the contract type that was being processed when the error occurred.';
                }
                field("Assigned User ID"; Rec."Assigned User ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the user ID assigned to handle this error.';
                }
                field("Salesperson Code"; Rec."Salesperson Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the salesperson code associated with the contract that had an error.';
                }
            }
        }
    }
}
