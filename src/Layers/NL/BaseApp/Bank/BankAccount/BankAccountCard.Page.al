// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.BankAccount;

using Microsoft.Bank.Check;
using Microsoft.Bank.Ledger;
using Microsoft.Bank.PositivePay;
using Microsoft.Bank.Reconciliation;
using Microsoft.Bank.Reports;
using Microsoft.Bank.Setup;
using Microsoft.Bank.Statement;
using Microsoft.CRM.Contact;
using Microsoft.Finance.Analysis;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Reports;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Comment;
using Microsoft.Utilities;
using System.Email;

/// <summary>
/// Primary interface for managing bank account master data and configuration.
/// Provides comprehensive bank account setup including contact information, posting groups, and payment settings.
/// </summary>
/// <remarks>
/// Source Table: Bank Account (270). Includes actions for bank reconciliation, statement import, and balance display.
/// Key features: Multi-currency support, dimension setup, payment export configuration.
/// </remarks>
page 370 "Bank Account Card"
{
    Caption = 'Bank Account Card';
    PageType = Card;
    SourceTable = "Bank Account";

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
                    Importance = Standard;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                    Visible = NoFieldVisible;

                    trigger OnAssistEdit()
                    begin
                        if Rec.AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the name of the bank where you have the bank account.';
                }
                field("Bank Branch No."; Rec."Bank Branch No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Bank Branch No.';
                    ToolTip = 'Specifies a number of the bank branch.';
                    MaskType = Concealed;
                }
                field("Bank Account No."; Rec."Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Bank Account No.';
                    Importance = Promoted;
                    ToolTip = 'Specifies the number used by the bank for the bank account.';
                    MaskType = Concealed;
                }
                field("Search Name"; Rec."Search Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an alternate name that you can use to search for the record in question when you cannot remember the value in the Name field.';
                    Visible = false;
                }
                field(Balance; Rec.Balance)
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the bank account''s current balance denominated in the applicable foreign currency.';
                }
                field("Balance (LCY)"; Rec."Balance (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the bank account''s current balance in LCY.';
                }
                field("Min. Balance"; Rec."Min. Balance")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a minimum balance for the bank account.';
                }
                field("Our Contact Code"; Rec."Our Contact Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies a code to specify the employee who is responsible for this bank account.';
                }
                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the related record is blocked from being posted in transactions, for example a customer that is declared insolvent or an item that is placed in quarantine.';
                }
                field("SEPA Direct Debit Exp. Format"; Rec."SEPA Direct Debit Exp. Format")
                {
                    ApplicationArea = Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the SEPA format of the bank file that will be exported when you choose the Create Direct Debit File button in the Direct Debit Collect. Entries window.';
                }
                field("Credit Transfer Msg. Nos."; Rec."Credit Transfer Msg. Nos.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the number series for bank instruction messages that are created with the export file that you create from the Direct Debit Collect. Entries window.';
                }
                field("Direct Debit Msg. Nos."; Rec."Direct Debit Msg. Nos.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the number series that will be used on the direct debit file that you export for a direct-debit collection entry in the Direct Debit Collect. Entries window.';
                }
                field("Creditor No."; Rec."Creditor No.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies your company as the creditor in connection with payment collection from customers using SEPA Direct Debit.';
                }
                field("Bank Clearing Standard"; Rec."Bank Clearing Standard")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the format standard to be used in bank transfers if you use the Bank Clearing Code field to identify you as the sender.';
                }
                field("Bank Clearing Code"; Rec."Bank Clearing Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the code for bank clearing that is required according to the format standard you selected in the Bank Clearing Standard field.';
                }
                field("Use as Default for Currency"; Rec."Use as Default for Currency")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies whether this is the default company account for payments in sales and service documents in the currency specified for this account. Each currency can have only one default bank account.';
                }
                field(IntercompanyEnable; Rec.IntercompanyEnable)
                {
                    ApplicationArea = Intercompany;
                    Importance = Additional;
                    ToolTip = 'Specifies whether this bank account is enabled to be copied by IC Partners to make intercompany transactions.';
                }
                group(Control45)
                {
                    ShowCaption = false;
                    Visible = ShowBankLinkingActions;
                    field(OnlineFeedStatementStatus; OnlineFeedStatementStatus)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Bank Account Linking Status';
                        Editable = false;
                        ToolTip = 'Specifies if the bank account is linked to an online bank account through the bank statement service.';

                        trigger OnValidate()
                        begin
                            if not Linked then
                                Rec.UnlinkStatementProvider()
                            else
                                Error(OnlineBankAccountLinkingErr);
                        end;
                    }
                }
                field("Last Date Modified"; Rec."Last Date Modified")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the date when the Bank Account card was last modified.';
                }
                group("Payment Matching")
                {
                    Caption = 'Payment Matching';
                    field("Disable Automatic Pmt Matching"; Rec."Disable Automatic Pmt Matching")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Disable Automatic Payment Matching';
                        Importance = Additional;
                        ToolTip = 'Specifies whether to disable automatic payment matching after importing bank transactions for this bank account.';
                    }
                    field("Disable Bank Rec. Optimization"; Rec."Disable Bank Rec. Optimization")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Disable Bank Reconciliation Optimization';
                        Importance = Additional;
                        ToolTip = 'Specifies whether to disable bank reconciliation optimization for this bank account. It will result in more precise matches, but it will be slower. Disabling the optimization is useful when there are several bank ledger entries with the same amount and date that need to be automatched.';
                    }
                }
                group("Payment Match Tolerance")
                {
                    Caption = 'Payment Match Tolerance';
                    field("Match Tolerance Type"; Rec."Match Tolerance Type")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        ToolTip = 'Specifies by which tolerance the automatic payment application function will apply the Amount Incl. Tolerance Matched rule for this bank account.';
                    }
                    field("Match Tolerance Value"; Rec."Match Tolerance Value")
                    {
                        ApplicationArea = Basic, Suite;
                        DecimalPlaces = 0 : 2;
                        Importance = Additional;
                        ToolTip = 'Specifies if the automatic payment application function will apply the Amount Incl. Tolerance Matched rule by Percentage or Amount.';
                    }
                }
            }
            group(Communication)
            {
                Caption = 'Communication';
                field(Address; Rec.Address)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the address of the bank where you have the bank account.';
                }
                field("Address 2"; Rec."Address 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies additional address information.';
                }
                field("Post Code"; Rec."Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the postal code.';
                }
                field(City; Rec.City)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the city of the bank where you have the bank account.';
                }
                field("Country/Region Code"; Rec."Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the country/region of the address.';

                    trigger OnValidate()
                    begin
                        IsCountyVisible := FormatAddress.UseCounty(Rec."Country/Region Code");
                    end;
                }
                group(CountyGroup)
                {
                    ShowCaption = false;
                    Visible = IsCountyVisible;
                    field(County; Rec.County)
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the state, province or county as a part of the address.';
                    }
                }
                field("Phone No."; Rec."Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    ExtendedDatatype = PhoneNo;
                    ToolTip = 'Specifies the telephone number of the bank where you have the bank account.';
                }
                field(MobilePhoneNo; Rec."Mobile Phone No.")
                {
                    Caption = 'Mobile Phone No.';
                    ApplicationArea = Basic, Suite;
                    ExtendedDatatype = PhoneNo;
                    ToolTip = 'Specifies the mobile telephone number of the bank where you have the bank account.';
                }
                field(Contact; Rec.Contact)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the bank employee regularly contacted in connection with this bank account.';
                }
                field("Phone No.2"; Rec."Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Phone No.';
                    Importance = Promoted;
                    ToolTip = 'Specifies the telephone number of the bank where you have the bank account.';
                    Visible = false;
                }
                field("Fax No."; Rec."Fax No.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the fax number of the bank where you have the bank account.';
                }
                field("E-Mail"; Rec."E-Mail")
                {
                    ApplicationArea = Basic, Suite;
                    ExtendedDatatype = EMail;
                    Importance = Promoted;
                    ToolTip = 'Specifies the email address associated with the bank account.';
                }
                field("Home Page"; Rec."Home Page")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank web site.';
                }
            }
            group(Posting)
            {
                Caption = 'Posting';
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the relevant currency code for the bank account.';
                }
                field("Last Check No."; Rec."Last Check No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the check number of the last check issued from the bank account.';
                }
                field("Transit No."; Rec."Transit No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a bank identification number of your own choice.';
                    MaskType = Concealed;
                }
                field("Last Statement No."; Rec."Last Statement No.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of the last bank account statement that was reconciled with this bank account.';
                }
                field("Last Payment Statement No."; Rec."Last Payment Statement No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last bank statement that was imported.';
                }
                field("Pmt. Rec. No. Series"; Rec."Pmt. Rec. No. Series")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number series for payment reconciliation journals.';
                }
                field("Balance Last Statement"; Rec."Balance Last Statement")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the balance amount of the last statement reconciliation on the bank account.';

                    trigger OnValidate()
                    begin
                        if Rec."Balance Last Statement" <> xRec."Balance Last Statement" then
                            if not Confirm(ChangeBalanceLastStatementQst, false, Rec."No.") then
                                Error(CanceledErr);
                    end;
                }
                field("Bank Acc. Posting Group"; Rec."Bank Acc. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies a code for the bank account posting group for the bank account.';

                    trigger OnValidate()
                    var
                        BankAccPostingGroup: Record "Bank Account Posting Group";
                        GLAccount: Record "G/L Account";
                    begin
                        BankAccPostingGroup.SetRange(Code, Rec."Bank Acc. Posting Group");
                        if (not BankAccPostingGroup.IsEmpty() and GuiAllowed()) then begin
                            BankAccPostingGroup.Get(Rec."Bank Acc. Posting Group");
                            GLAccount.SetRange("No.", BankAccPostingGroup."G/L Account No.");
                            if not GLAccount.IsEmpty() then begin
                                GLAccount.Get(BankAccPostingGroup."G/L Account No.");
                                if GLAccount."Direct Posting" then
                                    if Confirm(RisksOfDirectPostingOnGLAccountsLbl) then
                                        HyperLink(RisksOfDirectPostingOnGLAccountsForwardLinkLbl);
                            end;
                        end;
                    end;
                }
            }
            group(Transfer)
            {
                Caption = 'Transfer';
                field("Bank Branch No.2"; Rec."Bank Branch No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Bank Branch No.';
                    Importance = Promoted;
                    ToolTip = 'Specifies a number of the bank branch.';
                    Visible = false;
                }
                field("Bank Account No.2"; Rec."Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Bank Account No.';
                    Importance = Promoted;
                    ToolTip = 'Specifies the number used by the bank for the bank account.';
                    Visible = false;
                }
                field("Transit No.2"; Rec."Transit No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Transit No.';
                    ToolTip = 'Specifies a bank identification number of your own choice.';
                }
                field("SWIFT Code"; Rec."SWIFT Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the international bank identifier code (SWIFT) of the bank where you have the account.';
                }
                field(IBAN; Rec.IBAN)
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the bank account''s international bank account number.';
                    MaskType = Concealed;
                }
                field("Creditor Identifier"; Rec."Creditor Identifier")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Creditor Identifier';
                    ToolTip = 'Specifies the creditor identifier.';
                }
            }
            group("Account Holder")
            {
                Caption = 'Account Holder';
                field("Account Holder Name"; Rec."Account Holder Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank account owner''s name.';
                }
                field("Account Holder Address"; Rec."Account Holder Address")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank account owner''s address.';
                }
                field("Account Holder Post Code"; Rec."Account Holder Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Account Holder Post Code/City';
                    ToolTip = 'Specifies the bank account owner''s postal code.';
                }
                field("Account Holder City"; Rec."Account Holder City")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank account owner''s city.';
                }
                field("Acc. Hold. Country/Region Code"; Rec."Acc. Hold. Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the country/region of the bank account holder.';
                }
                field("Bank Statement Import Format"; Rec."Bank Statement Import Format")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the format of the bank statement file that can be imported into this bank account.';
                }
                field("Payment Export Format"; Rec."Payment Export Format")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the format of the bank file that will be exported when you choose the Export Payments to File button in the Payment Journal window.';
                }
                field(CheckTransmitted; Rec."Check Transmitted")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Positive Pay Export Code"; Rec."Positive Pay Export Code")
                {
                    ApplicationArea = Basic, Suite;
                    LookupPageID = "Bank Export/Import Setup";
                    ToolTip = 'Specifies a code for the data exchange definition that manages the export of positive-pay files.';
                    Visible = false;
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
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Bank Acc.")
            {
                Caption = '&Bank Acc.';
                Image = Bank;
                action(Statistics)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Statistics';
                    Image = Statistics;
                    RunObject = Page "Bank Account Statistics";
                    RunPageLink = "No." = field("No."),
                                  "Date Filter" = field("Date Filter"),
                                  "Global Dimension 1 Filter" = field("Global Dimension 1 Filter"),
                                  "Global Dimension 2 Filter" = field("Global Dimension 2 Filter");
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
                }
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Comment Sheet";
                    RunPageLink = "Table Name" = const("Bank Account"),
                                  "No." = field("No.");
                    ToolTip = 'View or add comments for the record.';
                }
                action(Dimensions)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    RunObject = Page "Default Dimensions";
                    RunPageLink = "Table ID" = const(270),
                                  "No." = field("No.");
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';
                }
                action("Bank Account Balance")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Balance';
                    Image = Balance;
                    RunObject = Page "Bank Account Balance";
                    RunPageLink = "No." = field("No."),
                                  "Global Dimension 1 Filter" = field("Global Dimension 1 Filter"),
                                  "Global Dimension 2 Filter" = field("Global Dimension 2 Filter");
                    ToolTip = 'View a summary of the bank account balance in different periods.';
                }
                action(Statements)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'St&atements';
                    Image = "Report";
                    RunObject = Page "Bank Account Statement List";
                    RunPageLink = "Bank Account No." = field("No.");
                    ToolTip = 'View posted bank statements and reconciliations.';
                }
                action("Ledger E&ntries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ledger E&ntries';
                    Image = BankAccountLedger;
                    RunObject = Page "Bank Account Ledger Entries";
                    RunPageLink = "Bank Account No." = field("No.");
                    RunPageView = sorting("Bank Account No.")
                                  order(descending);
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View the history of transactions that have been posted for the selected record.';
                }
                action("Chec&k Ledger Entries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Chec&k Ledger Entries';
                    Image = CheckLedger;
                    RunObject = Page "Check Ledger Entries";
                    RunPageLink = "Bank Account No." = field("No.");
                    RunPageView = sorting("Bank Account No.")
                                  order(descending);
                    ToolTip = 'View check ledger entries that result from posting transactions in a payment journal for the relevant bank account.';
                }
                action("C&ontact")
                {
                    ApplicationArea = All;
                    Caption = 'C&ontact';
                    Image = ContactPerson;
                    ToolTip = 'View or edit detailed information about the contact person at the bank.';
                    Visible = ContactActionVisible;

                    trigger OnAction()
                    begin
                        Rec.ShowContact();
                    end;
                }
                separator(Action81)
                {
                }
                action("Online Map")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Online Map';
                    Image = Map;
                    ToolTip = 'View the address on an online map.';

                    trigger OnAction()
                    begin
                        Rec.DisplayMap();
                    end;
                }
                action(PagePositivePayEntries)
                {
                    ApplicationArea = Suite;
                    Caption = 'Positive Pay Entries';
                    Image = CheckLedger;
                    RunObject = Page "Positive Pay Entries";
                    RunPageLink = "Bank Account No." = field("No.");
                    RunPageView = sorting("Bank Account No.", "Upload Date-Time")
                                  order(descending);
                    ToolTip = 'View the bank ledger entries that are related to Positive Pay transactions.';
                    Visible = false;
                }
            }
            group(History)
            {
                Caption = 'History';
                Image = History;
                action("Sent Emails")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sent Emails';
                    Image = ShowList;
                    ToolTip = 'View a list of emails that you have sent to the contact person for this bank account.';

                    trigger OnAction()
                    var
                        Email: Codeunit Email;
                    begin
                        Email.OpenSentEmails(Database::"Bank Account", Rec.SystemId);
                    end;
                }
            }
            action(BankAccountReconciliations)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Payment Reconciliation Journals';
                Image = BankAccountRec;
                RunObject = Page "Pmt. Reconciliation Journals";
                RunPageLink = "Bank Account No." = field("No.");
                RunPageView = sorting("Bank Account No.");
                ToolTip = 'Reconcile your bank account by importing transactions and applying them, automatically or manually, to open customer ledger entries, open vendor ledger entries, or open bank account ledger entries.';
            }
            action("Receivables-Payables")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Receivables-Payables';
                Image = ReceivablesPayables;
                RunObject = Page "Receivables-Payables Lines";
                ToolTip = 'View a summary of the receivables and payables for the account, including customer and vendor balance due amounts.';
            }
            action(LinkToOnlineBankAccount)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Link to Online Bank Account';
                Enabled = not Linked;
                Image = LinkAccount;
                ToolTip = 'Create a link to an online bank account from the selected bank account.';
                Visible = ShowBankLinkingActions;

                trigger OnAction()
                begin
                    Rec.LinkStatementProvider(Rec);
                end;
            }
            action(UnlinkOnlineBankAccount)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Unlink Online Bank Account';
                Enabled = Linked;
                Image = UnLinkAccount;
                ToolTip = 'Remove a link to an online bank account from the selected bank account.';
                Visible = ShowBankLinkingActions;

                trigger OnAction()
                begin
                    Rec.UnlinkStatementProvider();
                    CurrPage.Update(true);
                end;
            }
            action(RefreshOnlineBankAccount)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Refresh Online Bank Account';
                Enabled = Linked;
                Image = RefreshRegister;
                ToolTip = 'Refresh the online bank account for the selected bank account.';
                Visible = ShowBankLinkingActions;

                trigger OnAction()
                begin
                    Rec.RefreshStatementProvider(Rec);
                end;
            }
            action(EditOnlineBankAccount)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Edit Online Bank Account Information';
                Enabled = Linked;
                Image = EditCustomer;
                ToolTip = 'Edit the information about the online bank account linked to the selected bank account.';
                Visible = ShowBankLinkingActions;

                trigger OnAction()
                begin
                    Rec.EditAccountStatementProvider(Rec);
                end;
            }
            action(RenewAccessConsentOnlineBankAccount)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Manage Access Consent for Online Bank Account';
                Enabled = Linked;
                Image = Approve;
                ToolTip = 'Manage access consent for the online bank account linked to the selected bank account.';
                Visible = ShowBankLinkingActions;

                trigger OnAction()
                begin
                    Rec.RenewAccessConsentStatementProvider(Rec);
                end;
            }
            action(AutomaticBankStatementImportSetup)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Automatic Bank Statement Import Setup';
                Enabled = Linked;
                Image = ElectronicBanking;
                RunObject = Page "Auto. Bank Stmt. Import Setup";
                RunPageOnRec = true;
                ToolTip = 'Set up the information for importing bank statement files.';
                Visible = ShowBankLinkingActions;
            }
        }
        area(processing)
        {
            action("Cash Receipt Journals")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Cash Receipt Journals';
                Image = Journals;
                RunObject = Page "Cash Receipt Journal";
                ToolTip = 'Create a cash receipt journal line for the bank account, for example, to post a payment receipt.';
            }
            action("Payment Journals")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Payment Journals';
                Image = Journals;
                RunObject = Page "Payment Journal";
                ToolTip = 'Open the list of payment journals where you can register payments to vendors.';
            }
            action(PagePosPayExport)
            {
                ApplicationArea = Suite;
                Caption = 'Positive Pay Export';
                Image = Export;
                RunObject = Page "Positive Pay Export";
                RunPageLink = "No." = field("No.");
                ToolTip = 'Export a Positive Pay file with relevant payment information that you then send to the bank for reference when you process payments to make sure that your bank only clears validated checks and amounts.';
                Visible = false;
            }
            action(Email)
            {
                ApplicationArea = All;
                Caption = 'Send Email';
                Image = Email;
                ToolTip = 'Send an email to the contact person for this bank account.';

                trigger OnAction()
                var
                    TempEmailItem: Record "Email Item" temporary;
                    EmailScenario: Enum "Email Scenario";
                begin
                    TempEmailItem.AddSourceDocument(Database::"Bank Account", Rec.SystemId);
                    TempEmailitem."Send to" := Rec."E-Mail";
                    TempEmailItem.Send(false, EmailScenario::Default);
                end;
            }
        }
        area(reporting)
        {
            action(List)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'List';
                Image = "Report";
                ToolTip = 'View a list of general information about bank accounts, such as posting group, currency code, minimum balance, and balance.';

                trigger OnAction()
                begin
                    RunReport(REPORT::"Bank Account - List", Rec."No.");
                end;
            }
            action("Detail Trial Balance")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Detail Trial Balance';
                Image = "Report";
                ToolTip = 'View a detailed trial balance for selected checks.';

                trigger OnAction()
                begin
                    RunReport(REPORT::"Bank Acc. - Detail Trial Bal.", Rec."No.");
                end;
            }
            action(Action1906306806)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Receivables-Payables';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Receivables-Payables";
                ToolTip = 'View a summary of the receivables and payables for the account, including customer and vendor balance due amounts.';
            }
            action("Check Details")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Check Details';
                Image = "Report";
                ToolTip = 'View a detailed trial balance for selected checks.';

                trigger OnAction()
                begin
                    RunReport(REPORT::"Bank Account - Check Details", Rec."No.");
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(PagePosPayExport_Promoted; PagePosPayExport)
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Bank Statement Service', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(LinkToOnlineBankAccount_Promoted; LinkToOnlineBankAccount)
                {
                }
                actionref(RefreshOnlineBankAccount_Promoted; RefreshOnlineBankAccount)
                {
                }
                actionref(UnlinkOnlineBankAccount_Promoted; UnlinkOnlineBankAccount)
                {
                }
                actionref(EditOnlineBankAccount_Promoted; EditOnlineBankAccount)
                {
                }
                actionref(RenewAccessConsentOnlineBankAccount_Promoted; RenewAccessConsentOnlineBankAccount)
                {
                }
                actionref(AutomaticBankStatementImportSetup_Promoted; AutomaticBankStatementImportSetup)
                {
                }
            }
            group(Category_Category5)
            {
                Caption = 'Bank Account', Comment = 'Generated from the PromotedActionCategories property index 4.';

                actionref(Dimensions_Promoted; Dimensions)
                {
                }
                actionref(Statistics_Promoted; Statistics)
                {
                }
                actionref("Co&mments_Promoted"; "Co&mments")
                {
                }
                actionref("C&ontact_Promoted"; "C&ontact")
                {
                }
                actionref("Bank Account Balance_Promoted"; "Bank Account Balance")
                {
                }
                actionref("Receivables-Payables_Promoted"; "Receivables-Payables")
                {
                }
                actionref(Statements_Promoted; Statements)
                {
                }
                actionref("Ledger E&ntries_Promoted"; "Ledger E&ntries")
                {
                }
                actionref("Chec&k Ledger Entries_Promoted"; "Chec&k Ledger Entries")
                {
                }
            }
            group(Category_Category6)
            {
                Caption = 'Navigate', Comment = 'Generated from the PromotedActionCategories property index 5.';

                actionref("Cash Receipt Journals_Promoted"; "Cash Receipt Journals")
                {
                }
                actionref("Payment Journals_Promoted"; "Payment Journals")
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';

                actionref("Detail Trial Balance_Promoted"; "Detail Trial Balance")
                {
                }
                actionref("Check Details_Promoted"; "Check Details")
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        Rec.GetOnlineFeedStatementStatus(OnlineFeedStatementStatus, Linked);
        ShowBankLinkingActions := Rec.StatementProvidersExist();
    end;

    trigger OnAfterGetRecord()
    begin
        Rec.GetOnlineFeedStatementStatus(OnlineFeedStatementStatus, Linked);
        Rec.CalcFields("Check Report Name");
        IsCountyVisible := FormatAddress.UseCounty(Rec."Country/Region Code");
    end;

    trigger OnOpenPage()
    var
        Contact: Record Contact;
    begin
        OnBeforeOnOpenPage();
        ContactActionVisible := Contact.ReadPermission;
        SetNoFieldVisible();
    end;

    var
        FormatAddress: Codeunit "Format Address";
#pragma warning disable AA0470
        ChangeBalanceLastStatementQst: Label 'There may be a statement using the %1.\\Do you want to change Balance Last Statement?';
#pragma warning restore AA0470
        CanceledErr: Label 'Canceled.';
        ContactActionVisible: Boolean;
        Linked: Boolean;
        OnlineBankAccountLinkingErr: Label 'You must link the bank account to an online bank account.\\Choose the Link to Online Bank Account action.';
        IsCountyVisible: Boolean;
        ShowBankLinkingActions: Boolean;
        NoFieldVisible: Boolean;
        OnlineFeedStatementStatus: Option "Not Linked",Linked,"Linked and Auto. Bank Statement Enabled";
        RisksOfDirectPostingOnGLAccountsLbl: Label 'The selected bank account posting group is linked to a general ledger account that allows direct posting. The bank account reconciliation process might become problematic if the instructions in the documentation are not followed. Do you want to know more?';
        RisksOfDirectPostingOnGLAccountsForwardLinkLbl: Label 'https://go.microsoft.com/fwlink/?linkid=2197950';

    local procedure SetNoFieldVisible()
    var
        DocumentNoVisibility: Codeunit DocumentNoVisibility;
    begin
        NoFieldVisible := DocumentNoVisibility.BankAccountNoIsVisible();
    end;

    local procedure RunReport(ReportNumber: Integer; BankActNumber: Code[20])
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount.SetRange("No.", BankActNumber);
        REPORT.RunModal(ReportNumber, true, true, BankAccount);
    end;

    /// <summary>
    /// Integration event raised before opening the Bank Account Card page.
    /// Enables custom initialization or setup before page display.
    /// </summary>
    /// <remarks>
    /// Raised during page OnOpenPage trigger before standard page initialization.
    /// </remarks>
    [IntegrationEvent(true, false)]
    local procedure OnBeforeOnOpenPage()
    begin
    end;
}

