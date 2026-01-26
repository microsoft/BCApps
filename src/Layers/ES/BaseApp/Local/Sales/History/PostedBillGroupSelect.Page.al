// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.Currency;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Foundation.Navigate;
using Microsoft.Sales.Receivables;
using System.Text;

page 7000064 "Posted Bill Group Select."
{
    ApplicationArea = Basic, Suite;
    Caption = 'Posted Bill Groups (Batch)';
    DeleteAllowed = false;
    Editable = true;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = Worksheet;
    SaveValues = true;
    SourceTable = "Posted Bill Group";
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
                    ToolTip = 'Specifies the number of the posted bill group, which is assigned when you create the bill group.';
                }
                field("Bank Account No."; Rec."Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number or code of the bank to which you submitted this posted bill group.';
                }
                field("Posting Description"; Rec."Posting Description")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the posting description for the posted bill group.';
                }
                field("Dealing Type"; Rec."Dealing Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of payment. Collection: The document will be sent to the bank for processing as a receivable. Discount: The document will be sent to the bank for processing as a prepayment discount. When a document is submitted for discount, the bill group bank advances the amount of the document (or a portion of it, in the case of invoices). Later, the bank is responsible for processing the collection of the document on the due date.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the posting date for this bill group.';
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
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency code for the posted bill group.';
                }
                field("Amount Grouped (LCY)"; Rec."Amount Grouped (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the grouped amount of this posted bill group.';
                }
                field("Remaining Amount (LCY)"; Rec."Remaining Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount outstanding for collection, of the documents included in this bill group posted.';
                }
                field(Factoring; Rec.Factoring)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the factoring method to be applied to the invoices associated with this bill group.';
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
            group("&Bill Group")
            {
                Caption = '&Bill Group';
                Image = VoucherGroup;
                action(Card)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Card';
                    Image = EditLines;
                    RunObject = Page "Posted Bill Groups";
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
                    RunObject = Page "Posted Bill Groups Analysis";
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
                        CurrPage.SetSelectionFilter(PostedBillGr2);
                        if not PostedBillGr2.Find('=><') then
                            exit;
                        REPORT.RunModal(REPORT::"Batch Settl. Posted Bill Grs.", true, false, PostedBillGr2);
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

                actionref(BatchSettlement_Promoted; BatchSettlement)
                {
                }
                actionref("&Navigate_Promoted"; "&Navigate")
                {
                }
                actionref("Posted Bill Groups Maturity_Promoted"; "Posted Bill Groups Maturity")
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
        PostedBillGr: Record "Posted Bill Group";
        PostedBillGr2: Record "Posted Bill Group";
        Navigate: Page Navigate;
        CurrTotalAmountLCY: Decimal;
        ShowCurrent: Boolean;
        CurrCodeFilter: Code[250];
        BankAccFilter: Code[250];
        CurrTotalAmountVisible: Boolean;
        DueDateFilter: Text[30];

    procedure UpdateStatistics()
    begin
        PostedBillGr.Copy(Rec);
        CurrTotalAmountLCY := 0;
        UpdateStatistics2(PostedBillGr, CurrTotalAmountLCY, ShowCurrent);
        CurrTotalAmountVisible := true;
    end;

    procedure GetSelected(var NewPostedBillGr: Record "Posted Bill Group")
    begin
        CurrPage.SetSelectionFilter(NewPostedBillGr);
    end;

    procedure UpdateStatistics2(var PostedBillGr2: Record "Posted Bill Group"; var CurrTotalAmount: Decimal; var ShowCurrent: Boolean)
    begin
        PostedBillGr2.SetCurrentKey("Bank Account No.", "Posting Date", "Currency Code");
        if PostedBillGr2.Find('-') then;
        repeat
            PostedBillGr2.CalcFields("Remaining Amount (LCY)");
            CurrTotalAmount := CurrTotalAmount + PostedBillGr2."Remaining Amount (LCY)";
        until PostedBillGr2.Next() = 0;
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

