// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CashFlow.Account;

using Microsoft.CashFlow.Comment;
using Microsoft.CashFlow.Forecast;

page 851 "Chart of Cash Flow Accounts"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Chart of Cash Flow Accounts';
    CardPageID = "Cash Flow Account Card";
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = "Cash Flow Account";
    UsageCategory = Lists;

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
                    Style = Strong;
                    StyleExpr = NoEmphasize;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    Style = Strong;
                    StyleExpr = NameEmphasize;
                    ToolTip = 'Specifies the name of the cash flow account.';
                }
                field("Account Type"; Rec."Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the purpose of the cash flow account. Newly created cash flow accounts are automatically assigned the Entry account type, but you can change this.';
                }
                field(Totaling; Rec.Totaling)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an account interval or a list of account numbers. The entries of the account will be totaled to give a total balance. How entries are totaled depends on the value in the Account Type field.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        CFAccList: Page "Cash Flow Account List";
                    begin
                        CFAccList.LookupMode(true);
                        if not (CFAccList.RunModal() = ACTION::LookupOK) then
                            exit(false);

                        Text := CFAccList.GetSelectionFilter();
                        exit(true);
                    end;
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
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the cash flow amount.';
                }
                field("G/L Account Filter"; Rec."G/L Account Filter")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that only the cash flow entries that are registered to the filtered general ledger accounts are included in the cash flow forecast.';
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
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Indent Chart of Cash Flow Accounts")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Indent Chart of Cash Flow Accounts';
                    Image = IndentChartOfAccounts;
                    RunObject = Codeunit "Cash Flow Account - Indent";
                    ToolTip = 'Indent rows per the hierarchy and validate the chart of cash flow accounts.';
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Indent Chart of Cash Flow Accounts_Promoted"; "Indent Chart of Cash Flow Accounts")
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        NameIndent := 0;
        NoOnFormat();
        NameOnFormat();
    end;

    var
        NoEmphasize: Boolean;
        NameEmphasize: Boolean;
        NameIndent: Integer;

    local procedure NoOnFormat()
    begin
        NoEmphasize := Rec."Account Type" <> Rec."Account Type"::Entry;
    end;

    local procedure NameOnFormat()
    begin
        NameIndent := Rec.Indentation;
        NameEmphasize := Rec."Account Type" <> Rec."Account Type"::Entry;
    end;
}

