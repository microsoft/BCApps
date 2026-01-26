// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

using Microsoft.Bank.Journal;
using Microsoft.Bank.Statement;

page 11403 "Cash Journal"
{
    Caption = 'Cash Journal';
    DelayedInsert = false;
    PageType = Document;
    PopulateAllFields = true;
    SourceTable = "CBG Statement";
    SourceTableView = sorting(Type)
                      where(Type = const(Cash));

    layout
    {
        area(content)
        {
            group(Control1)
            {
                ShowCaption = false;
                field("Account No."; Rec."Account No.")
                {
                    ApplicationArea = All;
                    CaptionClass = Format(StrSubstNo(Text1000000, Rec."Account Type"));
                    Editable = false;
                    Lookup = false;
                    ToolTip = 'Specifies the number of the account the CBG Statement is linked to.';
                    Visible = "Account No.Visible";
                }
                field(GetName; Rec.GetName())
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Account Name';
                    Editable = false;
                    ToolTip = 'Specifies the name of the balancing account that has been entered on the journal line.';
                }
                field(Currency; Rec.Currency)
                {
                    ApplicationArea = All;
                    Caption = 'Currency';
                    Editable = false;
                    ToolTip = 'Specifies the currency code for the amounts on the statement lines.';
                    Visible = CurrencyVisible;
                }
                field("Account No.2"; Rec.CLAccountNo())
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Account No.';
                    Editable = false;
                    ToolTip = 'Specifies the number of account according to the value in the Account Type field.';
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the statement.';
                }
                field("Opening Balance"; Rec."Opening Balance")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = Rec.Currency;
                    AutoFormatType = 1;
                    ToolTip = 'Specifies the current balance (LCY) of the bank/giro or cash account.';
                }
                field("Closing Balance"; Rec."Closing Balance")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = Rec.Currency;
                    AutoFormatType = 1;
                    ToolTip = 'Specifies the new closing balance, after you have entered all statements in the Bank/Giro journal or all payment/receipt entries.';
                }
            }
            part(Subform; "Cash Journal Subform")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Journal Template Name" = field("Journal Template Name"),
                              "No." = field("No.");
                SubPageView = sorting("Journal Template Name", "No.", "Line No.");
            }
        }
        area(factboxes)
        {
            part(Control1903886207; "Bank/Giro Jnl. Subf. Info")
            {
                ApplicationArea = Basic, Suite;
                Provider = Subform;
                SubPageLink = "Journal Template Name" = field("Journal Template Name"),
                              "No." = field("No."),
                              "Line No." = field("Line No.");
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
                action(Dimensions)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to journal lines to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        Rec.ShowDimensions();
                    end;
                }
            }
        }
        area(processing)
        {
            group("P&osting")
            {
                Caption = 'P&osting';
                Image = Post;
                action(Overview)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Overview';
                    Image = ViewDetails;
                    RunObject = Page "Cash Journal List";
                    RunPageLink = "Journal Template Name" = field("Journal Template Name");
                    ShortCutKey = 'Shift+Ctrl+L';
                    ToolTip = 'View all payment history entries for the bank accounts.';
                }
                action("Test Report")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Test Report';
                    Ellipsis = true;
                    Image = TestReport;
                    ToolTip = 'Preview the results of posting the journal.';

                    trigger OnAction()
                    var
                        GenJournalTemplate: Record "Gen. Journal Template";
                        CBGStatement: Record "CBG Statement";
                    begin
                        CBGStatement := Rec;
                        CBGStatement.SetRecFilter();
                        GenJournalTemplate.Get(Rec."Journal Template Name");
                        GenJournalTemplate.TestField("Test Report ID");
                        REPORT.Run(GenJournalTemplate."Test Report ID", true, false, CBGStatement);
                    end;
                }
                action(Post)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Post';
                    Image = Post;
                    ShortCutKey = 'F9';
                    ToolTip = 'Finalize the document or journal. The values and quantities are posted to the related accounts. A report request window where you can specify what to include on the print-out.';

                    trigger OnAction()
                    var
                        GenJournalTemplate: Record "Gen. Journal Template";
                    begin
                        if not Confirm(StrSubstNo(Text1000001, Rec.Type), false) then
                            exit;

                        GenJournalTemplate.Get(Rec."Journal Template Name");
                        GenJournalTemplate.TestField("Force Posting Report", false);
                        Rec.ProcessStatementASGenJournal();
                        CurrPage.Update(false);
                    end;
                }
                action("Post and &Print")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Post and &Print';
                    Image = PostPrint;
                    ShortCutKey = 'Shift+F9';
                    ToolTip = 'Finalize and prepare to print the document or journal. The values and quantities are posted to the related accounts. A report request window where you can specify what to include on the print-out.';

                    trigger OnAction()
                    var
                        GenJournalTemplate: Record "Gen. Journal Template";
                        CBGStatement: Record "CBG Statement";
                    begin
                        if not Confirm(StrSubstNo(Text1000002, Rec.Type), false) then
                            exit;

                        Rec.CheckBalance();
                        CBGStatement := Rec;
                        CBGStatement.SetRecFilter();
                        GenJournalTemplate.Get(Rec."Journal Template Name");
                        GenJournalTemplate.TestField("Posting Report ID");
                        REPORT.RunModal(GenJournalTemplate."Posting Report ID", false, false, CBGStatement);
                        Rec.ProcessStatementASGenJournal();
                        CurrPage.Update(false);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Post_Promoted; Post)
                {
                }
                actionref("Post and &Print_Promoted"; "Post and &Print")
                {
                }
            }
        }
    }

    trigger OnInit()
    begin
        "Account No.Visible" := true;
    end;

    trigger OnModifyRecord(): Boolean
    begin
        CurrPage.Subform.PAGE.ChangedHeader(Rec);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.FilterGroup(2);
        Rec.InitRecord(Rec.GetFilter("Journal Template Name"));
        Rec.FilterGroup(0);
        CurrPage.Subform.PAGE.ChangedHeader(Rec);
        "Account No.Visible" := Rec."Account Type" = Rec."Account Type"::"Bank Account";
        CurrencyVisible := Rec."Account Type" = Rec."Account Type"::"Bank Account";
    end;

    trigger OnOpenPage()
    var
        JnlSelected: Boolean;
    begin
        if (Rec."Journal Template Name" <> '') and (Rec."No." <> 0) then begin
            Rec.FilterGroup(2);
            Rec.SetRange("Journal Template Name", Rec."Journal Template Name");
            Rec.FilterGroup(0);
        end else begin
            Rec.FilterGroup(2);
            JnlSelected := (Rec.GetFilter("Journal Template Name") <> '');
            Rec.FilterGroup(0);
            if not JnlSelected then begin
                GenJnlManagement.TemplateSelectionCBG(PAGE::"Cash Journal", 11, Rec, JnlSelected);
                if not JnlSelected then
                    Error('');

                GenJnlManagement.CheckTemplateNameCBG(Rec.GetRangeMax("Journal Template Name"));
            end;
        end;

        "Account No.Visible" := Rec."Account Type" = Rec."Account Type"::"Bank Account";
        CurrencyVisible := Rec."Account Type" = Rec."Account Type"::"Bank Account";
    end;

    var
        Text1000000: Label '%1 Account No.';
        Text1000001: Label 'Do you want to post the %1 Journal?';
        Text1000002: Label 'Do you want to post and print the %1 Journal?';
        GenJnlManagement: Codeunit GenJnlManagement;
        "Account No.Visible": Boolean;
        CurrencyVisible: Boolean;
}

