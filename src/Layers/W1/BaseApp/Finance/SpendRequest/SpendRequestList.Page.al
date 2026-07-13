// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.SpendRequest;

page 6840 "Spend Request List"
{
    Caption = 'Spend Requests';
    PageType = List;
    ApplicationArea = Basic, Suite;
    UsageCategory = Lists;
    SourceTable = "Spend Request";
    CardPageId = "Spend Request Card";
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                field("No."; Rec."No.")
                {
                }
                field(Type; Rec.Type)
                {
                }
                field("Requested By"; Rec."Requested By")
                {
                }
                field(Purpose; Rec.Purpose)
                {
                }
                field(Status; Rec.Status)
                {
                }
                field("Total Expected Amount (LCY)"; Rec."Total Expected Amount (LCY)")
                {
                }
                field("Total Spent Amount (LCY)"; Rec."Total Spent Amount (LCY)")
                {
                }
                field(RemainingAmountLCY; Rec.GetRemainingAmountLCY())
                {
                    Caption = 'Remaining Amount (LCY)';
                    AutoFormatType = 1;
                    AutoFormatExpression = Rec."Currency Code";
                    ToolTip = 'Specifies the difference between estimated amount and actually spent amount.';
                    Importance = Additional;
                }
                field("Expected Start Date"; Rec."Expected Start Date")
                {
                }
                field("Expected End Date"; Rec."Expected End Date")
                {
                }
                field("Approved by User Name"; Rec."Approved/Rejected by User Name")
                {
                }
                field(ClosedAt; Rec."Closed At")
                {
                }
                field(ClosedByDoc; Rec."Closed By Document No.")
                {
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(RefreshCurrency)
            {
                Caption = 'Refresh Currency Exchange rate';
                ToolTip = 'Updates the currency exchange rate and Total Expected Amount (LCY).';
                Enabled = (Rec."Currency Code" <> '') and (Rec.Status <> Rec.Status::Closed);
                ApplicationArea = Basic, Suite;
                Image = Recalculate;

                trigger OnAction()
                begin
                    if Rec.Status = Rec.Status::Closed then
                        Error('A closed spend request cannot be updated.');
                    Rec.UpdateCurrencyExchangeRate();
                    Rec.Modify();
                end;
            }
        }
        area(Navigation)
        {
            action(Dimensions)
            {
                AccessByPermission = TableData Microsoft.Finance.Dimension.Dimension = R;
                ApplicationArea = Dimensions;
                Caption = 'Dimensions';
                Enabled = Rec."No." <> '';
                Image = Dimensions;
                ShortCutKey = 'Alt+D';
                ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to expenses to distribute costs and analyze transaction history.';

                trigger OnAction()
                begin
                    Rec.ShowDocDim();
                    CurrPage.SaveRecord();
                end;
            }
        }
        area(Reporting)
        {
            group(Report)
            {
                Caption = 'Report';
                Image = Print;

                action(Print)
                {
                    Caption = 'Print';
                    ToolTip = 'Prints the spend request so it can be sent to the requester.';
                    ApplicationArea = Basic, Suite;
                    Image = Print;
                    RunObject = Report "Spend Request Document";
                    RunPageOnRec = true;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(RefreshCurrency_Promoted; RefreshCurrency)
                {
                }
                group(Category_SpendRequest)
                {
                    Caption = 'Spend Request';

                    actionref(Dimensions_Promoted; Dimensions)
                    {
                    }
                }
            }
        }
    }
}
