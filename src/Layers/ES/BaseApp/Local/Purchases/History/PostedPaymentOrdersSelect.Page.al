// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.History;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.Currency;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Foundation.Navigate;
using Microsoft.Purchases.Payables;
using Microsoft.Sales.History;
using System.Text;

page 7000065 "Posted Payment Orders Select."
{
    ApplicationArea = Basic, Suite;
    Caption = 'Posted Payment Orders';
    DeleteAllowed = false;
    Editable = true;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = Worksheet;
    Permissions = TableData "Posted Bill Group" = rm;
    SaveValues = true;
    SourceTable = "Posted Payment Order";
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            group(Options)
            {
                Caption = 'Options';
                field(DueDateFilter; DueDateFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Due Date Filter';
                    ToolTip = 'Specifies a due date or a range of due dates that documents must contain to be included in the selection.';

                    trigger OnValidate()
                    begin
                        DueDateFilterOnAfterValidate();
                    end;
                }
                field(BankAccFilter; BankAccFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Bank Account Filter';
                    TableRelation = "Bank Account"."No.";
                    ToolTip = 'Specifies which bank accounts the values are shown for.';

                    trigger OnValidate()
                    begin
                        BankAccFilterOnAfterValidate();
                    end;
                }
                field(CurrCodeFilter; CurrCodeFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Currency Code Filter';
                    TableRelation = Currency;
                    ToolTip = 'Specifies the currencies that the data is included for.';

                    trigger OnValidate()
                    begin
                        CurrCodeFilterOnAfterValidate();
                    end;
                }
            }
            repeater(Control1)
            {
                Editable = false;
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of this posted payment order.';
                }
                field("Bank Account No."; Rec."Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number or code of the bank where the posted payment order was delivered.';
                }
                field("Posting Description"; Rec."Posting Description")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the posting description related to this posted payment order.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payment order posting date.';
                }
                field("Amount Grouped"; Rec."Amount Grouped")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the grouped amount for this posted payment order.';
                }
                field("Remaining Amount"; Rec."Remaining Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the pending amounts left to pay for documents that are part of this posted payment order.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency code associated with this posted payment order.';
                }
                field("Amount Grouped (LCY)"; Rec."Amount Grouped (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the grouped amount for this posted payment order.';
                }
                field("Remaining Amount (LCY)"; Rec."Remaining Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the pending amounts yet to be paid for the documents associated with this posted payment order.';
                }
            }
            group(Control49)
            {
                ShowCaption = false;
                field(CurrTotalAmount; CurrTotalAmountLCY)
                {
                    ApplicationArea = All;
                    AutoFormatType = 1;
                    Caption = 'Total Rmg. Amt. (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies the sum of amounts that remain to be paid.';
                    Visible = CurrTotalAmountVisible;

                    trigger OnValidate()
                    begin
                        CurrTotalAmountLCYOnAfterValid();
                    end;
                }
            }
        }
        area(factboxes)
        {
            part(Control1901420407; "Post. PO Analysis LCY Fact Box")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "No." = field("No.");
                Visible = true;
            }
            part(Control1903433407; "Post. PO Analysis Non LCY FB")
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
            group("Pmt. O&rd.")
            {
                Caption = 'Pmt. O&rd.';
                action(Card)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Card';
                    Image = EditLines;
                    RunObject = Page "Posted Payment Orders";
                    RunPageLink = "No." = field("No."),
                                  "Due Date Filter" = field("Due Date Filter"),
                                  "Global Dimension 1 Filter" = field("Global Dimension 1 Filter"),
                                  "Global Dimension 2 Filter" = field("Global Dimension 2 Filter"),
                                  "Status Filter" = field("Status Filter");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or change detailed information about the record that is being processed on the document or journal line.';
                }
                action("Co&mments")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "BG/PO Comment Sheet";
                    RunPageLink = "BG/PO No." = field("No.");
                    ToolTip = 'View or create a comment.';
                }
                separator(Action39)
                {
                }
                action(Analysis)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Analysis';
                    Image = "Report";
                    RunObject = Page "Post. Payment Orders Analysis";
                    RunPageLink = "No." = field("No."),
                                  "Due Date Filter" = field("Due Date Filter"),
                                  "Global Dimension 1 Filter" = field("Global Dimension 1 Filter"),
                                  "Global Dimension 2 Filter" = field("Global Dimension 2 Filter"),
                                  "Category Filter" = field("Category Filter");
                    ToolTip = 'View details about the related documents. First you define which document category and currency you want to analyze documents for.';
                }
                separator(Action44)
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
                            PostedPmtOrd.Copy(Rec);
                            PostedPmtOrd.SetRecFilter();
                            REPORT.Run(REPORT::"Posted Payment Order Listing", true, false, PostedPmtOrd);
                        end;
                    end;
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(BatchSettlement)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Batch &Settlement';
                    Ellipsis = true;
                    Image = ApplyEntries;
                    ToolTip = 'Fully settle the documents that are included in the selected posted bill groups.';

                    trigger OnAction()
                    begin
                        CurrPage.SetSelectionFilter(PostedPmtOrd2);
                        if not PostedPmtOrd2.Find('=><') then
                            exit;
                        REPORT.RunModal(REPORT::"Batch Settl. Posted POs", true, false, PostedPmtOrd2);
                        UpdateStatistics();
                        CurrPage.Update(false);
                    end;
                }
            }
            action("&Navigate")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Find entries...';
                Image = Navigate;
                ToolTip = 'Find all entries and documents that exist for the document number and posting date on the selected entry or document.';

                trigger OnAction()
                begin
                    Navigate.SetDoc(Rec."Posting Date", Rec."No.");
                    Navigate.Run();
                end;
            }
            action("Posted Payment Orders Maturity")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Posted Payment Orders Maturity';
                Image = DocumentsMaturity;
                RunObject = Page "Posted Payment Orders Maturity";
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

                actionref(BatchSettlement_Promoted; BatchSettlement)
                {
                }
                actionref("&Navigate_Promoted"; "&Navigate")
                {
                }
                actionref("Posted Payment Orders Maturity_Promoted"; "Posted Payment Orders Maturity")
                {
                }
                actionref(Listing_Promoted; Listing)
                {
                }
            }
        }
    }

    trigger OnInit()
    begin
        CurrTotalAmountVisible := true;
    end;

    trigger OnOpenPage()
    begin
        Rec.SetCurrentKey("Bank Account No.", "Posting Date", "Currency Code");
        CurrCodeFilter := Rec.GetFilter("Currency Code");
        BankAccFilter := Rec.GetFilter("Bank Account No.");
        UpdateStatistics();
    end;

    var
        PostedPmtOrd: Record "Posted Payment Order";
        PostedPmtOrd2: Record "Posted Payment Order";
        Navigate: Page Navigate;
        CurrTotalAmountLCY: Decimal;
        ShowCurrent: Boolean;
        CurrCodeFilter: Code[250];
        BankAccFilter: Code[250];
        CurrTotalAmountVisible: Boolean;
        DueDateFilter: Text[30];

    procedure UpdateStatistics()
    begin
        PostedPmtOrd.Copy(Rec);
        CurrTotalAmountLCY := 0;
        UpdateStatistics2(PostedPmtOrd, CurrTotalAmountLCY, ShowCurrent);
        CurrTotalAmountVisible := true;
    end;

    procedure GetSelected(var NewPostedPmtOrd: Record "Posted Payment Order")
    begin
        CurrPage.SetSelectionFilter(NewPostedPmtOrd);
    end;

    procedure UpdateStatistics2(var PostedPmtOrd2: Record "Posted Payment Order"; var CurrTotalAmount: Decimal; var ShowCurrent: Boolean)
    begin
        PostedPmtOrd2.SetCurrentKey("Bank Account No.", "Posting Date", "Currency Code");
        if PostedPmtOrd2.Find('-') then;
        repeat
            PostedPmtOrd2.CalcFields("Remaining Amount (LCY)");
            CurrTotalAmount := CurrTotalAmount + PostedPmtOrd2."Remaining Amount (LCY)";
        until PostedPmtOrd2.Next() = 0;
        ShowCurrent := (CurrTotalAmount <> 0);
    end;

    local procedure CurrTotalAmountLCYOnAfterValid()
    begin
        UpdateStatistics();
    end;

    local procedure CurrCodeFilterOnAfterValidate()
    begin
        Rec.SetFilter("Currency Code", CurrCodeFilter);
        CurrPage.Update(false);
        UpdateStatistics();
    end;

    local procedure BankAccFilterOnAfterValidate()
    begin
        Rec.SetFilter("Bank Account No.", BankAccFilter);
        CurrPage.Update(false);
        UpdateStatistics();
    end;

    local procedure DueDateFilterOnAfterValidate()
    var
        FilterTokens: Codeunit "Filter Tokens";
    begin
        FilterTokens.MakeDateFilter(DueDateFilter);
        Rec.SetFilter("Due Date Filter", DueDateFilter);
        DueDateFilter := Rec.GetFilter("Due Date Filter");
        CurrPage.Update(false);
        UpdateStatistics();
        Rec.SetFilter(Amount, '<>0');
        CurrPage.Update(false);
    end;
}

