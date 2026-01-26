// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.DirectDebit;
using Microsoft.Finance.GeneralLedger.Journal;

page 11000008 "Payment History Line Subform"
{
    Caption = 'Lines';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    PageType = ListPart;
    SourceTable = "Payment History Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Docket; Rec.Docket)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that a docket exists for this payment.';
                }
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the line''s number.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status of the payment history line.';

                    trigger OnValidate()
                    begin
                        StatusOnAfterValidate();
                    end;
                }
                field(Identification; Rec.Identification)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the identification number for the payment history line.';
                }
                field("Order"; Rec.Order)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the order type of the payment history line.';
                    Visible = false;
                }
                field("Payment/Receipt"; Rec."Payment/Receipt")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies whether the payment history line concerns a payment or a receipt.';
                }
                field("Account Type"; Rec."Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the type of the account you want to perform payments to, or collections from.';
                }
                field("Account No."; Rec."Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the account you want to perform payments to, or collections from.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies total amount (including VAT) for the entry.';
                }
                field(Date; Rec.Date)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the date when you want the payment or collection to be performed.';
                }
                field("Global Dimension 1 Code"; Rec."Global Dimension 1 Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                }
                field("Global Dimension 2 Code"; Rec."Global Dimension 2 Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                }
                field("Transaction Mode"; Rec."Transaction Mode")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the transaction mode used in telebanking.';
                    Visible = false;
                }
                field(Bank; Rec.Bank)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number for the bank you want to perform payments to, or collections from.';
                    Visible = false;
                }
                field("Bank Account No."; Rec."Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the bank account number you want to perform payments to, or collections from.';
                }
                field("Direct Debit Mandate ID"; Rec."Direct Debit Mandate ID")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    LookupPageID = "SEPA Direct Debit Mandates";
                    ToolTip = 'Specifies the direct debit mandate of the customer who made this payment.';
                }
                field("Description 1"; Rec."Description 1")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the payment history line.';
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an additional description of the payment history line.';
                    Visible = false;
                }
                field("Description 3"; Rec."Description 3")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an additional description of the payment history line.';
                    Visible = false;
                }
                field("Description 4"; Rec."Description 4")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an additional description of the payment history line.';
                    Visible = false;
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the currency code that the entry is linked to.';
                    Visible = false;
                }
                field("Account Holder Name"; Rec."Account Holder Name")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the bank account owner''s name.';
                    Visible = false;
                }
                field("Account Holder Address"; Rec."Account Holder Address")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the bank account owner''s address.';
                    Visible = false;
                }
                field("Account Holder Post Code"; Rec."Account Holder Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the bank account owner''s postal code.';
                    Visible = false;
                }
                field("Account Holder City"; Rec."Account Holder City")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the bank account owner''s city.';
                    Visible = false;
                }
                field("Acc. Hold. Country/Region Code"; Rec."Acc. Hold. Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the country/region code of the bank account holder.';
                    Visible = false;
                }
                field("Nature of the Payment"; Rec."Nature of the Payment")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the nature of the payment for the proposal line.';
                    Visible = false;
                }
                field("Registration No. DNB"; Rec."Registration No. DNB")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number issued by the Dutch Central Bank (DNB), to identify a number of types of foreign payments.';
                    Visible = false;
                }
                field("Description Payment"; Rec."Description Payment")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description related to the nature of the payment.';
                    Visible = false;
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number the Dutch Central Bank (DNB) issues to transito traders, to identify goods being sold and purchased by these traders.';
                    Visible = false;
                }
                field("Traders No."; Rec."Traders No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number the Dutch Central Bank (DNB) issued to transito trader.';
                    Visible = false;
                }
                field(Urgent; Rec.Urgent)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the payment should be performed urgently.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action(DetailInformation)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Detail Information';
                    Image = ViewDetails;
                    ShortCutKey = 'F7';
                    ToolTip = 'View invoice-level information for the line.';

                    trigger OnAction()
                    begin
                        Zoom();
                    end;
                }
                action(Dimension)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Dimension';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to journal lines to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        Rec.ShowDimensions();
                        CurrPage.SaveRecord();
                    end;
                }
                group("A&ccount")
                {
                    Caption = 'A&ccount';
                    Image = ChartOfAccounts;
                    action(Card)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = '&Card';
                        Image = EditLines;
                        ShortCutKey = 'Shift+F7';
                        ToolTip = 'View detailed information about the payment.';

                        trigger OnAction()
                        begin
                            ShowAccount();
                        end;
                    }
                    action(LedgerEntries)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Ledger E&ntries';
                        ShortCutKey = 'Ctrl+F7';
                        ToolTip = 'View the bank ledger entries.';

                        trigger OnAction()
                        begin
                            ShowEntries();
                        end;
                    }
                }
            }
        }
    }

    [Scope('OnPrem')]
    procedure Zoom()
    var
        SentLinesZoom: Page "Payment History Line Detail";
        PaymentHistLine: Record "Payment History Line";
    begin
        PaymentHistLine := Rec;
        PaymentHistLine.FilterGroup(10);
        PaymentHistLine.SetRange("Run No.", Rec."Run No.");
        PaymentHistLine.FilterGroup(0);
        PaymentHistLine.SetRange("Line No.", Rec."Line No.");
        SentLinesZoom.SetTableView(PaymentHistLine);
        SentLinesZoom.SetRecord(PaymentHistLine);
        SentLinesZoom.Run();
    end;

    [Scope('OnPrem')]
    procedure ShowAccount()
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        case Rec."Account Type" of
            Rec."Account Type"::Customer:
                GenJnlLine."Account Type" := GenJnlLine."Account Type"::Customer;
            Rec."Account Type"::Vendor:
                GenJnlLine."Account Type" := GenJnlLine."Account Type"::Vendor;
            Rec."Account Type"::Employee:
                GenJnlLine."Account Type" := GenJnlLine."Account Type"::Employee;
        end;
        GenJnlLine."Account No." := Rec."Account No.";
        CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Show Card", GenJnlLine);
    end;

    [Scope('OnPrem')]
    procedure ShowEntries()
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        case Rec."Account Type" of
            Rec."Account Type"::Customer:
                GenJnlLine."Account Type" := GenJnlLine."Account Type"::Customer;
            Rec."Account Type"::Vendor:
                GenJnlLine."Account Type" := GenJnlLine."Account Type"::Vendor;
            Rec."Account Type"::Employee:
                GenJnlLine."Account Type" := GenJnlLine."Account Type"::Employee;
        end;
        GenJnlLine."Account No." := Rec."Account No.";
        CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Show Entries", GenJnlLine);
    end;

    local procedure StatusOnAfterValidate()
    begin
        CurrPage.Update();
    end;
}

