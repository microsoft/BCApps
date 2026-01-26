// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Journal;

using Microsoft.Bank.Payment;
using Microsoft.Bank.Reconciliation;
using Microsoft.Bank.Statement;
using Microsoft.Finance.GeneralLedger.Journal;

page 11400 "Bank/Giro Journal"
{
    Caption = 'Bank/Giro Journal';
    PageType = Document;
    PopulateAllFields = true;
    SourceTable = "CBG Statement";
    SourceTableView = sorting(Type)
                      where(Type = const("Bank/Giro"));

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
                    CaptionClass = Format(StrSubstNo(Text1000001, Rec."Account Type"));
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
                    ToolTip = 'Specifies the name of the account the CBG Statement is linked to.';
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
                    ToolTip = 'Specifies the number of the G/L account the CBG Statement is linked to.';
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the statement.';
                }
                field("Document Date"; Rec.Date)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when you create the CBG statement.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    AssistEdit = true;
                    ToolTip = 'Specifies a document number for the CBG statement of type Bank/Giro.';

                    trigger OnAssistEdit()
                    begin
                        if Rec.AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
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
            part(Subform; "Bank/Giro Journal Subform")
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
            group("&Telebank")
            {
                Caption = '&Telebank';
                Image = ElectronicBanking;
                action("Bank Account List")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Bank Account List';
                    Image = BankAccount;
                    RunObject = Page "Telebank - Bank Overview";
                    RunPageView = sorting("No.");
                    ShortCutKey = 'F7';
                    ToolTip = 'View general information about bank accounts, such as posting group, currency code, minimum balance, and balance. You can choose to see all the balances in the report in local currency (LCY). For example, the information in the different bank accounts from this report can also be accumulated in the Bank Account window.';
                }
                action(Proposal)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Proposal';
                    Image = SuggestElectronicDocument;
                    RunObject = Page "Telebank Proposal";
                    RunPageLink = "Our Bank No." = field("Account No.");
                    RunPageView = sorting("Our Bank No.", "Line No.");
                    ShortCutKey = 'Shift+F11';
                    ToolTip = 'Create a new payment or collection proposal for the selected bank.';
                }
            }
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
                        CurrPage.SaveRecord();
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
                    RunObject = Page "Bank/Giro Journal List";
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
                        if not Confirm(StrSubstNo(Text1000002, Rec.Type), false) then
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
                        if not Confirm(StrSubstNo(Text1000003, Rec.Type), false) then
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
            action(InsertPaymentHistory)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Insert Payment History';
                Image = PaymentHistory;
                ShortCutKey = 'Ctrl+F11';
                ToolTip = 'Select the payment history that you want to process in the journal.';

                trigger OnAction()
                var
                    TelebankInterface: Codeunit "CBG Journal Telebank Interface";
                begin
                    Rec.TestField("No.");
                    TelebankInterface.InsertPaymentHistory(Rec);
                end;
            }
            action(Reconciliation)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Reconciliation';
                Image = Reconcile;
                ToolTip = 'Reconcile entries in your bank account ledger entries with the actual transactions in your bank account, according to the latest bank statement.';

                trigger OnAction()
                begin
                    "CGB Statement reconciliation".MatchCBGStatement(Rec);
                end;
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

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        CurrPage.Update(false);
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
                GenJnlManagement.TemplateSelectionCBG(PAGE::"Bank/Giro Journal", 12, Rec, JnlSelected);
                if not JnlSelected then
                    Error('');
                GenJnlManagement.CheckTemplateNameCBG(Rec.GetRangeMax("Journal Template Name"));
            end;
        end;

        "Account No.Visible" := Rec."Account Type" = Rec."Account Type"::"Bank Account";
        CurrencyVisible := Rec."Account Type" = Rec."Account Type"::"Bank Account";
    end;

    var
        Text1000001: Label '%1 No.';
        Text1000002: Label 'Do you want to post the %1 Journal?';
        Text1000003: Label 'Do you want to post and print the %1 Journal?';
        "CGB Statement reconciliation": Codeunit "CBG Statement Reconciliation";
        GenJnlManagement: Codeunit GenJnlManagement;
        "Account No.Visible": Boolean;
        CurrencyVisible: Boolean;
}

