// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

using Microsoft.CashFlow.Account;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Foundation.Comment;
using Microsoft.Foundation.ExtendedText;

/// <summary>
/// Chart of accounts page designed for analysis view account selection and navigation.
/// Displays both G/L accounts and cash flow accounts in a unified view for analysis purposes.
/// </summary>
/// <remarks>
/// Temporary table-based page that consolidates G/L and cash flow accounts for analysis view configuration.
/// Enables account selection across different account sources in analysis by dimensions functionality.
/// </remarks>
page 569 "Chart of Accs. (Analysis View)"
{
    Caption = 'Chart of Accs. (Analysis View)';
    Editable = false;
    PageType = List;
    SourceTable = "G/L Account (Analysis View)";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                IndentationColumn = NameIndent;
                IndentationControls = Name;
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = Suite;
                    Style = Strong;
                    StyleExpr = Emphasize;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Suite;
                    Style = Strong;
                    StyleExpr = Emphasize;
                }
                field("Income/Balance"; Rec."Income/Balance")
                {
                    ApplicationArea = Suite;
                }
                field("Account Type"; Rec."Account Type")
                {
                    ApplicationArea = Suite;
                }
                field("Direct Posting"; Rec."Direct Posting")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field(Totaling; Rec.Totaling)
                {
                    ApplicationArea = Suite;
                }
                field("Gen. Posting Type"; Rec."Gen. Posting Type")
                {
                    ApplicationArea = Suite;
                }
                field("Gen. Bus. Posting Group"; Rec."Gen. Bus. Posting Group")
                {
                    ApplicationArea = Suite;
                }
                field("Gen. Prod. Posting Group"; Rec."Gen. Prod. Posting Group")
                {
                    ApplicationArea = Suite;
                }
                field("VAT Bus. Posting Group"; Rec."VAT Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("VAT Prod. Posting Group"; Rec."VAT Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Net Change"; Rec."Net Change")
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    DrillDownPageID = "Analysis View Entries";
                    LookupPageID = "Analysis View Entries";
                }
                field("Balance at Date"; Rec."Balance at Date")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    Visible = false;
                }
                field(Balance; Rec.Balance)
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    Visible = false;
                }
                field("Additional-Currency Net Change"; Rec."Additional-Currency Net Change")
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    Visible = false;
                }
                field("Add.-Currency Balance at Date"; Rec."Add.-Currency Balance at Date")
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    Visible = false;
                }
                field("Additional-Currency Balance"; Rec."Additional-Currency Balance")
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    Visible = false;
                }
                field("Budgeted Amount"; Rec."Budgeted Amount")
                {
                    ApplicationArea = Suite;
                    DrillDownPageID = "Analysis View Budget Entries";
                    LookupPageID = "Analysis View Budget Entries";
                }
                field("Consol. Debit Acc."; Rec."Consol. Debit Acc.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Consol. Credit Acc."; Rec."Consol. Credit Acc.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
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
                action(Card)
                {
                    ApplicationArea = Suite;
                    Caption = 'Card';
                    Image = EditLines;
                    RunObject = Page "G/L Account Card";
                    RunPageLink = "No." = field("No."),
                                  "Date Filter" = field("Date Filter"),
                                  "Global Dimension 1 Filter" = field("Global Dimension 1 Filter"),
                                  "Global Dimension 2 Filter" = field("Global Dimension 2 Filter"),
                                  "Budget Filter" = field("Budget Filter"),
                                  "Business Unit Filter" = field("Business Unit Filter");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or change detailed information about the record on the document or journal line.';
                }
                action("Ledger E&ntries")
                {
                    ApplicationArea = Suite;
                    Caption = 'Ledger E&ntries';
                    Image = GLRegisters;
                    //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedCategory = Process;
                    RunObject = Page "General Ledger Entries";
                    RunPageLink = "G/L Account No." = field("No.");
                    RunPageView = sorting("G/L Account No.");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View the history of transactions that have been posted for the selected record.';
                }
                action("Co&mments")
                {
                    ApplicationArea = Suite;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Comment Sheet";
                    RunPageLink = "Table Name" = const("G/L Account"),
                                  "No." = field("No.");
                    ToolTip = 'View or add comments for the record.';
                }
                group(Dimensions)
                {
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    action("Dimensions-Single")
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Dimensions-Single';
                        Image = Dimensions;
                        RunObject = Page "Default Dimensions";
                        RunPageLink = "Table ID" = const(15),
                                      "No." = field("No.");
                        ShortCutKey = 'Alt+D';
                        ToolTip = 'View or edit the single set of dimensions that are set up for the selected record.';
                    }
                    action("Dimensions-&Multiple")
                    {
                        AccessByPermission = TableData Dimension = R;
                        ApplicationArea = Dimensions;
                        Caption = 'Dimensions-&Multiple';
                        Image = DimensionSets;
                        ToolTip = 'View or edit dimensions for a group of records. You can assign dimension codes to transactions to distribute costs and analyze historical information.';

                        trigger OnAction()
                        var
                            GLAcc: Record "G/L Account";
                            DefaultDimMultiple: Page "Default Dimensions-Multiple";
                        begin
                            CurrPage.SetSelectionFilter(GLAcc);
                            DefaultDimMultiple.SetMultiRecord(GLAcc, Rec.FieldNo("No."));
                            DefaultDimMultiple.RunModal();
                        end;
                    }
                }
                action("E&xtended Texts")
                {
                    ApplicationArea = Suite;
                    Caption = 'E&xtended Texts';
                    Image = Text;
                    RunObject = Page "Extended Text List";
                    RunPageLink = "Table Name" = const("G/L Account"),
                                  "No." = field("No.");
                    RunPageView = sorting("Table Name", "No.", "Language Code", "All Language Codes", "Starting Date", "Ending Date");
                    ToolTip = 'View additional information about a general ledger account, this supplements the Description field.';
                }
                action("Receivables-Payables")
                {
                    ApplicationArea = Suite;
                    Caption = 'Receivables-Payables';
                    Image = ReceivablesPayables;
                    RunObject = Page "Receivables-Payables";
                    ToolTip = 'View a summary of the receivables and payables for the account, including customer and vendor balance due amounts.';
                }
            }
            group("&Balance")
            {
                Caption = '&Balance';
                Image = Balance;
                action("G/L &Account Balance")
                {
                    ApplicationArea = Suite;
                    Caption = 'G/L &Account Balance';
                    Image = GLAccountBalance;
                    RunObject = Page "G/L Account Balance";
                    RunPageLink = "No." = field("No."),
                                  "Global Dimension 1 Filter" = field("Global Dimension 1 Filter"),
                                  "Global Dimension 2 Filter" = field("Global Dimension 2 Filter"),
                                  "Business Unit Filter" = field("Business Unit Filter");
                    ToolTip = 'View a summary of the debit and credit balances for different time periods, for the account that you select in the chart of accounts.';
                }
                action("G/L &Balance")
                {
                    ApplicationArea = Suite;
                    Caption = 'G/L &Balance';
                    Image = GLBalance;
                    RunObject = Page "G/L Balance";
                    RunPageOnRec = true;
                    ToolTip = 'View a summary of the debit and credit balances for all the accounts in the chart of accounts, for the time period that you select.';
                }
                action("G/L Balance by &Dimension")
                {
                    ApplicationArea = Dimensions;
                    Caption = 'G/L Balance by &Dimension';
                    Image = GLBalanceDimension;
                    RunObject = Page "G/L Balance by Dimension";
                    ToolTip = 'View a summary of the debit and credit balances by dimensions for the current account.';
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Indent Chart of Accounts")
                {
                    ApplicationArea = Suite;
                    Caption = 'Indent Chart of Accounts';
                    Image = IndentChartOfAccounts;
                    RunObject = Codeunit "G/L Account-Indent";
                    ToolTip = 'Indent accounts between a Begin-Total and the matching End-Total one level to make the chart of accounts easier to read.';
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Indent Chart of Accounts_Promoted"; "Indent Chart of Accounts")
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        NameIndent := 0;
        FormatLine();
    end;

    var
        Emphasize: Boolean;
        NameIndent: Integer;

    /// <summary>
    /// Inserts G/L accounts into the temporary analysis view account table for unified display.
    /// Converts G/L account records to analysis view account format for account selection.
    /// </summary>
    /// <param name="GLAcc">G/L Account record set to insert into temporary table</param>
    procedure InsertTempGLAccAnalysisViews(var GLAcc: Record "G/L Account")
    begin
        if GLAcc.Find('-') then
            repeat
                Rec.Init();
                Rec.TransferFields(GLAcc, true);
                Rec."Account Source" := Rec."Account Source"::"G/L Account";
                Rec.Insert();
            until GLAcc.Next() = 0;
    end;

    /// <summary>
    /// Inserts cash flow accounts into the temporary analysis view account table for unified display.
    /// Converts cash flow account records to analysis view account format for account selection.
    /// </summary>
    /// <param name="CFAccount">Cash Flow Account record set to insert into temporary table</param>
    procedure InsertTempCFAccountAnalysisVie(var CFAccount: Record "Cash Flow Account")
    begin
        if CFAccount.Find('-') then
            repeat
                Rec.Init();
                Rec."No." := CFAccount."No.";
                Rec.Name := CFAccount.Name;
                Rec."Account Type" := CFAccount."Account Type";
                Rec.Blocked := CFAccount.Blocked;
                Rec."New Page" := CFAccount."New Page";
                Rec."No. of Blank Lines" := CFAccount."No. of Blank Lines";
                Rec.Validate(Indentation, CFAccount.Indentation);
                Rec."Last Date Modified" := CFAccount."Last Date Modified";
                Rec.Totaling := CFAccount.Totaling;
                Rec.Comment := CFAccount.Comment;
                Rec."Account Source" := Rec."Account Source"::"Cash Flow Account";
                Rec.Insert();
            until CFAccount.Next() = 0;
    end;

    local procedure FormatLine()
    begin
        NameIndent := Rec.Indentation;
        Emphasize := Rec."Account Type" <> Rec."Account Type"::Posting;
    end;
}

