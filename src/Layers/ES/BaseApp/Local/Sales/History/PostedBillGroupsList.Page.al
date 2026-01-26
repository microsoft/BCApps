// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

using Microsoft.Finance.ReceivablesPayables;

page 7000014 "Posted Bill Groups List"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Posted Bill Groups';
    CardPageID = "Posted Bill Groups";
    Editable = false;
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = "Posted Bill Group";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of the posted bill group, which is assigned when you create the bill group.';
                }
                field("Bank Account No."; Rec."Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number or code of the bank to which you submitted this posted bill group.';
                }
                field("Bank Account Name"; Rec."Bank Account Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number associated with the code or number of the bank, to which the bill group was submitted.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency code for the posted bill group.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total for all of the documents included in this bill group.';
                }
                field("Amount (LCY)"; Rec."Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total for all of the documents included in this posted bill group.';
                }
                field("Remaining Amount"; Rec."Remaining Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount outstanding for payment for the documents included in this posted bill group.';
                }
                field("Remaining Amount (LCY)"; Rec."Remaining Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount outstanding for collection, of the documents included in this bill group posted.';
                }
            }
        }
        area(factboxes)
        {
            part(Control1901420907; "Post. BG Analysis LCY Fact Box")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "No." = field("No.");
                Visible = true;
            }
            part(Control1901421007; "Post. BG Analysis Non LCY FB")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "No." = field("No.");
                Visible = true;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = true;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("Bill &Group")
            {
                Caption = 'Bill &Group';
                Image = VoucherGroup;
                action("Co&mments")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "BG/PO Comment Sheet";
                    RunPageLink = "BG/PO No." = field("No."),
                                  Type = filter(Receivable);
                    ToolTip = 'View or create a comment.';
                }
                separator(Action21)
                {
                }
                action(Analysis)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Analysis';
                    Image = "Report";
                    RunObject = Page "Posted Bill Groups Analysis";
                    RunPageLink = "No." = field("No."),
                                  "Due Date Filter" = field("Due Date Filter"),
                                  "Global Dimension 1 Filter" = field("Global Dimension 1 Filter"),
                                  "Global Dimension 2 Filter" = field("Global Dimension 2 Filter"),
                                  "Category Filter" = field("Category Filter");
                    ToolTip = 'View details about the related documents. First you define which document category and currency you want to analyze documents for.';
                }
                separator(Action24)
                {
                }
                action(Listing)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Listing';
                    Ellipsis = true;
                    Image = List;
                    ToolTip = 'View detailed information about the posted bill group or payment order.';

                    trigger OnAction()
                    begin
                        if Rec.Find() then begin
                            PostedBillGr.Copy(Rec);
                            PostedBillGr.SetRecFilter();
                            REPORT.Run(REPORT::"Posted Bill Group Listing", true, false, PostedBillGr);
                        end;
                    end;
                }
            }
        }
        area(processing)
        {
            action("Posted Bill Groups Maturity")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Posted Bill Groups Maturity';
                Image = DocumentsMaturity;
                RunObject = Page "Posted Bill Groups Maturity";
                RunPageLink = "No." = field("No."),
                              "Global Dimension 1 Filter" = field("Global Dimension 1 Filter"),
                              "Global Dimension 2 Filter" = field("Global Dimension 2 Filter"),
                              "Category Filter" = field("Category Filter");
                ToolTip = 'View the posted document lines that have matured. Maturity information can be viewed by period start date.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Posted Bill Groups Maturity_Promoted"; "Posted Bill Groups Maturity")
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Reports';

                actionref(Listing_Promoted; Listing)
                {
                }
            }
        }
    }

    var
        PostedBillGr: Record "Posted Bill Group";
}

