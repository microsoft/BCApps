// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Foundation.Navigate;
using Microsoft.Sales.Receivables;

page 7000012 "Posted Bill Groups"
{
    Caption = 'Posted Bill Groups';
    DataCaptionExpression = Rec.Caption();
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Document;
    RefreshOnActivate = true;
    SourceTable = "Posted Bill Group";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the number of the posted bill group, which is assigned when you create the bill group.';
                }
                field("Bank Account No."; Rec."Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number or code of the bank to which you submitted this posted bill group.';
                }
                field("Bank Account Name"; Rec."Bank Account Name")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number associated with the code or number of the bank, to which the bill group was submitted.';
                }
                field("Dealing Type"; Rec."Dealing Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the type of payment. Collection: The document will be sent to the bank for processing as a receivable. Discount: The document will be sent to the bank for processing as a prepayment discount. When a document is submitted for discount, the bill group bank advances the amount of the document (or a portion of it, in the case of invoices). Later, the bank is responsible for processing the collection of the document on the due date.';
                }
                field("Partner Type"; Rec."Partner Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the posted bill group is a person or company.';
                }
                field(Factoring; Rec.Factoring)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the factoring method to be applied to the invoices associated with this bill group.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the posting date for this bill group.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency code for the posted bill group.';
                }
                field("Amount Grouped"; Rec."Amount Grouped")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the grouped amount in this posted bill group.';
                }
                field("Remaining Amount"; Rec."Remaining Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount outstanding for payment for the documents included in this posted bill group.';
                }
                field("Amount Grouped (LCY)"; Rec."Amount Grouped (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the grouped amount of this posted bill group.';
                }
                field("Remaining Amount (LCY)"; Rec."Remaining Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the amount outstanding for collection, of the documents included in this bill group posted.';
                }
            }
            part(Docs; "Docs. in Posted BG Subform")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Bill Gr./Pmt. Order No." = field("No.");
                SubPageView = sorting("Bill Gr./Pmt. Order No.")
                              where(Type = const(Receivable));
            }
            group(Expenses)
            {
                Caption = 'Expenses';
                field("Collection Expenses Amt."; Rec."Collection Expenses Amt.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the amount of fees and commission for processing the collection of bills for the posted bill group.';
                }
                field("Discount Expenses Amt."; Rec."Discount Expenses Amt.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the amount of fees and commissions, in order to process this posted bill group for discount.';
                }
                field("Discount Interests Amt."; Rec."Discount Interests Amt.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the total interest charged, to discount the documents for this posted bill group.';
                }
                field("Rejection Expenses Amt."; Rec."Rejection Expenses Amt.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the amount of the expenses associated with the rejection of bills for this bill group.';
                }
                field("Risked Factoring Exp. Amt."; Rec."Risked Factoring Exp. Amt.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Enabled = true;
                    ToolTip = 'Specifies the financial institution''s charges and commission for risked factoring.';
                }
                field("Unrisked Factoring Exp. Amt."; Rec."Unrisked Factoring Exp. Amt.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the financial institution''s charges and commission for unrisked factoring.';
                }
            }
            group(Auditing)
            {
                Caption = 'Auditing';
                field("Reason Code"; Rec."Reason Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies why the entry is created. When reason codes are assigned to journal line or sales and purchase documents, all entries with a reason code will be marked during posting.';
                }
                field("No. Printed"; Rec."No. Printed")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of copies printed of this posted bill group.';
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
                    RunPageLink = Type = filter(Receivable),
                                  "BG/PO No." = field("No.");
                    ToolTip = 'View or create a comment.';
                }
                separator(Action20)
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
                separator(Action58)
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
            action("&Navigate")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Find entries...';
                Image = Navigate;
                ToolTip = 'Find all entries and documents that exist for the document number and posting date on the selected entry or document.';

                trigger OnAction()
                var
                begin
                    Navigate.SetDoc(Rec."Posting Date", Rec."No.");
                    Navigate.Run();
                end;
            }
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

                actionref("&Navigate_Promoted"; "&Navigate")
                {
                }
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
        Navigate: Page Navigate;
}

