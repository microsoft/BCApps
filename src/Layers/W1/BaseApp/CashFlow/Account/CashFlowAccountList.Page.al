// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CashFlow.Account;

using Microsoft.CashFlow.Comment;
using Microsoft.CashFlow.Forecast;
using System.Text;

page 855 "Cash Flow Account List"
{
    Caption = 'Cash Flow Account List';
    CardPageID = "Cash Flow Account Card";
    Editable = false;
    PageType = List;
    SourceTable = "Cash Flow Account";

    layout
    {
        area(content)
        {
            repeater(Control1000)
            {
                IndentationColumn = NameIndent;
                IndentationControls = Name;
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the cash flow account.';
                }
                field("Account Type"; Rec."Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the purpose of the cash flow account. Newly created cash flow accounts are automatically assigned the Entry account type, but you can change this.';
                }
                field(Comment; Rec.Comment)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the comment for the record.';
                }
                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the related record is blocked from being posted in transactions, for example a customer that is declared insolvent or an item that is placed in quarantine.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the cash flow amount.';
                }
                field("Source Type"; Rec."Source Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the source type that applies to the source number that is shown in the Source No. field.';
                    Visible = false;
                }
                field("G/L Integration"; Rec."G/L Integration")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the cash flow account has integration with the general ledger. When a cash flow account has integration with the general ledger, either the balances of the general ledger accounts or their budgeted values are used in the cash flow forecast.';
                    Visible = false;
                }
                field("G/L Account Filter"; Rec."G/L Account Filter")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that only the cash flow entries that are registered to the filtered general ledger accounts are included in the cash flow forecast.';
                    Visible = false;
                }
            }
        }
        area(factboxes)
        {
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
            group("A&ccount")
            {
                Caption = 'A&ccount';
                Image = ChartOfAccounts;
                action(Entries)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Entries';
                    Image = Entries;
                    RunObject = Page "Cash Flow Forecast Entries";
                    RunPageLink = "Cash Flow Account No." = field("No.");
                    RunPageView = sorting("Cash Flow Account No.");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View the entries that exist for the cash flow account. ';
                }
                action("Co&mments")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Cash Flow Comment";
                    RunPageLink = "Table Name" = const("Cash Flow Account"),
                                  "No." = field("No.");
                    ToolTip = 'View or add comments for the record.';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        NameIndent := 0;
        NameOnFormat();
    end;

    var
        NameIndent: Integer;

    procedure SetSelection(var CFAccount: Record "Cash Flow Account")
    begin
        CurrPage.SetSelectionFilter(CFAccount);
    end;

    procedure GetSelectionFilter(): Text
    var
        CFAccount: Record "Cash Flow Account";
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
    begin
        CurrPage.SetSelectionFilter(CFAccount);
        exit(SelectionFilterManagement.GetSelectionFilterForCashFlowAccount(CFAccount));
    end;

    local procedure NameOnFormat()
    begin
        NameIndent := Rec.Indentation;
    end;
}

