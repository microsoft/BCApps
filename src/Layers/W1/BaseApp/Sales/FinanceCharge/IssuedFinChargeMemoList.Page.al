// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.FinanceCharge;

using Microsoft.Sales.Customer;
using Microsoft.Sales.Reports;

/// <summary>
/// Displays a list of posted finance charge memos with print, email, and cancellation capabilities.
/// </summary>
page 452 "Issued Fin. Charge Memo List"
{
    ApplicationArea = Suite;
    Caption = 'Issued Finance Charge Memos';
    CardPageID = "Issued Finance Charge Memo";
    DataCaptionFields = "Customer No.";
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Issued Fin. Charge Memo Header";
    SourceTableView = sorting("Posting Date")
                      order(descending);
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
                    ApplicationArea = Basic, Suite;
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                    ToolTip = 'Specifies the posting date that the finance charge memo was issued on.';
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Interest Amount"; Rec."Interest Amount")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                }
                field("Post Code"; Rec."Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field(City; Rec.City)
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("No. Printed"; Rec."No. Printed")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    Visible = false;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    Visible = false;
                }
                field(Canceled; Rec.Canceled)
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
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
            group("&Memo")
            {
                Caption = '&Memo';
                Image = Notes;
                action("Co&mments")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Fin. Charge Comment Sheet";
                    RunPageLink = Type = const("Issued Finance Charge Memo"),
                                  "No." = field("No.");
                    ToolTip = 'View or add comments for the record.';
                }
                action("C&ustomer")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'C&ustomer';
                    Image = Customer;
                    RunObject = Page "Customer List";
                    RunPageLink = "No." = field("Customer No.");
                    ToolTip = 'Open the card of the customer that the reminder or finance charge applies to. ';
                }
                separator(Action27)
                {
                }
                action(Statistics)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Statistics';
                    Image = Statistics;
                    RunObject = Page "Issued Fin. Charge Memo Stat.";
                    RunPageLink = "No." = field("No.");
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
                }
            }
        }
        area(processing)
        {
            action("&Print")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Print';
                Ellipsis = true;
                Image = Print;
                ToolTip = 'Prepare to print the document. The report request window for the document opens where you can specify what to include on the print-out.';

                trigger OnAction()
                var
                    IssuedFinChrgMemoHeader: Record "Issued Fin. Charge Memo Header";
                begin
                    CurrPage.SetSelectionFilter(IssuedFinChrgMemoHeader);
                    IssuedFinChrgMemoHeader.PrintRecords(true, false, false);
                end;
            }
            action("Send by &Email")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Send by &Email';
                Image = Email;
                ToolTip = 'Prepare to send the document by email. The Send Email window opens prefilled for the customer where you can add or change information before you send the email.';

                trigger OnAction()
                var
                    IssuedFinChrgMemoHeader: Record "Issued Fin. Charge Memo Header";
                begin
                    IssuedFinChrgMemoHeader := Rec;
                    CurrPage.SetSelectionFilter(IssuedFinChrgMemoHeader);
                    IssuedFinChrgMemoHeader.PrintRecords(false, true, false);
                end;
            }
            action("&Navigate")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Find entries...';
                Image = Navigate;
                ShortCutKey = 'Ctrl+Alt+Q';
                ToolTip = 'Find entries and documents that exist for the document number and posting date on the selected document. (Formerly this action was named Navigate.)';

                trigger OnAction()
                begin
                    Rec.Navigate();
                end;
            }
            action(Cancel)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Cancel';
                Ellipsis = true;
                Image = Cancel;
                ToolTip = 'Cancel the issued finance charge memo.';

                trigger OnAction()
                var
                    IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header";
                begin
                    CurrPage.SetSelectionFilter(IssuedFinChargeMemoHeader);
                    Rec.RunCancelIssuedFinChargeMemo(IssuedFinChargeMemoHeader);
                end;
            }
        }
        area(reporting)
        {
            action("Customer - Balance to Date")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Customer - Balance to Date';
                Image = "Report";
                RunObject = Report "Customer - Balance to Date";
                ToolTip = 'View a list with customers'' payment history up until a certain date. You can use the report to extract your total sales income at the close of an accounting period or fiscal year.';
            }
            action("Customer - Detail Trial Bal.")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Customer - Detail Trial Bal.';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Customer - Detail Trial Bal.";
                ToolTip = 'View the balance for customers with balances on a specified date. The report can be used at the close of an accounting period, for example, or for an audit.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("&Print_Promoted"; "&Print")
                {
                }
                actionref("Send by &Email_Promoted"; "Send by &Email")
                {
                }
                actionref("&Navigate_Promoted"; "&Navigate")
                {
                }
                actionref(Cancel_Promoted; Cancel)
                {
                }
            }
            group(Category_Memo)
            {
                Caption = 'Memo';

                actionref(Statistics_Promoted; Statistics)
                {
                }
                actionref("Co&mments_Promoted"; "Co&mments")
                {
                }
                actionref("C&ustomer_Promoted"; "C&ustomer")
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Reports';

                actionref("Customer - Balance to Date_Promoted"; "Customer - Balance to Date")
                {
                }
            }
        }
    }
}
