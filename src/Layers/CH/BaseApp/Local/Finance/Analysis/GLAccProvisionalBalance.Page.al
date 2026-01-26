// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;

page 11500 "G/L Acc. Provisional Balance"
{
    Caption = 'G/L Account temp. Balance';
    DataCaptionExpression = '';
    Editable = false;
    PageType = Card;
    SourceTable = "Gen. Journal Line";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(Text003; Text003)
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field(Control1150005; Text003)
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                fixed(Control1900886701)
                {
                    ShowCaption = false;
                    group(Account)
                    {
                        Caption = 'Account';
                        field(AccNumber; AccNumber)
                        {
                            ApplicationArea = All;
                            Caption = 'No.';
                            ToolTip = 'Specifies the number.';
                        }
                        field(AccName; AccName)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Description';
                            ToolTip = 'Specifies a description.';
                        }
                        field("GLSetup.""LCY Code"""; GLSetup."LCY Code")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Currency';
                            ToolTip = 'Specifies the currency. ';
                        }
                        field(AccBalance; AccBalance)
                        {
                            ApplicationArea = Basic, Suite;
                            BlankZero = true;
                            Caption = 'Balance';
                            DrillDown = false;
                            ToolTip = 'Specifies the balance. ';
                        }
                        field(AccNotPosted; AccNotPosted)
                        {
                            ApplicationArea = Basic, Suite;
                            BlankZero = true;
                            Caption = 'Not Posted (w/o VAT)';
                        }
                        field("AccBalance + AccNotPosted"; AccBalance + AccNotPosted)
                        {
                            ApplicationArea = Basic, Suite;
                            BlankZero = true;
                            Caption = 'Total';
                            ToolTip = 'Specifies the total.';
                        }
                    }
                    group(Control1901339601)
                    {
                        ShowCaption = false;
                        field(Control1150004; Text003)
                        {
                            ApplicationArea = Basic, Suite;
                            Visible = false;
                        }
                        field(Control1150015; Text003)
                        {
                            ApplicationArea = Basic, Suite;
                            Visible = false;
                        }
                        field(AccCurrency; AccCurrency)
                        {
                            ApplicationArea = Basic, Suite;
                        }
                        field(AccBalanceFC; AccBalanceFC)
                        {
                            ApplicationArea = Basic, Suite;
                            BlankZero = true;
                            DrillDown = false;
                        }
                        field(AccNotPostedFC; AccNotPostedFC)
                        {
                            ApplicationArea = Basic, Suite;
                            BlankZero = true;
                        }
                        field("AccBalanceFC + AccNotPostedFC"; AccBalanceFC + AccNotPostedFC)
                        {
                            ApplicationArea = Basic, Suite;
                            BlankZero = true;
                        }
                    }
                    group("Counter Acc.")
                    {
                        Caption = 'Counter Acc.';
                        field(BalAccNo; BalAccNo)
                        {
                            ApplicationArea = Basic, Suite;
                        }
                        field(BalAccName; BalAccName)
                        {
                            ApplicationArea = Basic, Suite;
                        }
                        field(Control1150013; GLSetup."LCY Code")
                        {
                            ApplicationArea = Basic, Suite;
                        }
                        field(BalAccBalance; BalAccBalance)
                        {
                            ApplicationArea = Basic, Suite;
                            BlankZero = true;
                        }
                        field(BalAccNotPosted; BalAccNotPosted)
                        {
                            ApplicationArea = Basic, Suite;
                            BlankZero = true;
                        }
                        field("BalAccBalance + BalAccNotPosted"; BalAccBalance + BalAccNotPosted)
                        {
                            ApplicationArea = Basic, Suite;
                            BlankZero = true;
                        }
                    }
                    group(Control1901850901)
                    {
                        ShowCaption = false;
                        field(Control1150014; Text003)
                        {
                            ApplicationArea = Basic, Suite;
                            Visible = false;
                        }
                        field(Control1150016; Text003)
                        {
                            ApplicationArea = Basic, Suite;
                            Visible = false;
                        }
                        field(BalAccCurrency; BalAccCurrency)
                        {
                            ApplicationArea = Basic, Suite;
                        }
                        field(BalAccBalanceFC; BalAccBalanceFC)
                        {
                            ApplicationArea = Basic, Suite;
                            BlankZero = true;
                        }
                        field(BalAccNotPostedFC; BalAccNotPostedFC)
                        {
                            ApplicationArea = Basic, Suite;
                            BlankZero = true;
                        }
                        field("BalAccBalanceFC + BalAccNotPostedFC"; BalAccBalanceFC + BalAccNotPostedFC)
                        {
                            ApplicationArea = Basic, Suite;
                            BlankZero = true;
                        }
                    }
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Balance")
            {
                Caption = '&Balance';
                action("&All Journals")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&All Journals';
                    Image = Journals;
                    ShortCutKey = 'F7';
                    ToolTip = 'Calculate and display the balance of the final posted entries and the balance of the postings entered in the current journal. The unposted balance for all general ledger registers is calculated. It also includes values from ledgers that have another journal name not shown at the time.';

                    trigger OnAction()
                    begin
                        AllJournals := AllJournals xor true;
                        if AllJournals then
                            CurrPage.Caption := Text000
                        else
                            CurrPage.Caption := Text001;
                        CalcBalance();
                    end;
                }
                action("A&ctual Journal")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'A&ctual Journal';
                    Image = Journals;
                    ToolTip = 'Calculate and display the balance of the final posted entries and the balance of the postings entered in the current journal. Only values from ledgers that have another journal name are shown.';

                    trigger OnAction()
                    begin
                        AllJournals := false;
                        CurrPage.Caption := Text002 + ' ' + Rec."Journal Batch Name";
                        CalcBalance();
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        CalcBalance();
    end;

    trigger OnOpenPage()
    begin
        GLSetup.Get();
        if not GenJnlLine2.Get(Rec."Journal Template Name", Rec."Journal Batch Name", Rec."Line No.") then
            Error('');
    end;

    var
        Text000: Label 'GL Account temp. Balance all Journals';
        Text001: Label 'GL Account temp. Balance actuals Journal';
        Text002: Label 'Balance Journal';
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlLine2: Record "Gen. Journal Line";
        GlAcc: Record "G/L Account";
        GLAccountSourceCurrency: Record "G/L Account Source Currency";
        Customer: Record Customer;
        Vendor: Record Vendor;
        Bank: Record "Bank Account";
        GLSetup: Record "General Ledger Setup";
        AccNumber: Code[20];
        AccName: Text[100];
        AccBalance: Decimal;
        AccBalanceFC: Decimal;
        AccNotPosted: Decimal;
        AccNotPostedFC: Decimal;
        AccCurrency: Code[10];
        BalAccNo: Code[20];
        BalAccName: Text[100];
        BalAccBalance: Decimal;
        BalAccBalanceFC: Decimal;
        BalAccNotPosted: Decimal;
        BalAccNotPostedFC: Decimal;
        BalAccCurrency: Code[10];
        JournalAmtLCY: Decimal;
        JournalAmtFCY: Decimal;
        AllJournals: Boolean;
        Text003: Label 'Placeholder';

    [Scope('OnPrem')]
    procedure CalcBalance()
    begin
        case Rec."Account Type" of
            Rec."Account Type"::"G/L Account":
                if GlAcc.Get(Rec."Account No.") then begin
                    GLAcc.CalcFields(Balance);
                    GLAccountSourceCurrency."G/L Account No." := GLAcc."No.";
                    GLAccountSourceCurrency."Currency Code" := GLAcc."Source Currency Code";
                    GLAccountSourceCurrency.CalcFields("Source Curr. Balance at Date");
                    AddNotPosted(Rec."Account No.", GlAcc."Source Currency Code", Rec."Account Type");
                    AccNumber := GlAcc."No.";
                    AccName := GlAcc.Name;
                    AccBalance := GlAcc.Balance;
                    AccCurrency := GlAcc."Source Currency Code";
                    AccBalanceFC := GLAccountSourceCurrency."Source Curr. Balance at Date";
                end;
            Rec."Account Type"::"Bank Account":
                if Bank.Get(Rec."Account No.") then begin
                    Bank.CalcFields(Balance, "Balance (LCY)");
                    AddNotPosted(Rec."Account No.", Bank."Currency Code", Rec."Account Type");
                    AccNumber := Bank."No.";
                    AccName := CopyStr(Bank.Name, 1, MaxStrLen(AccName));
                    AccBalance := Bank.Balance;
                    AccBalance := Bank."Balance (LCY)";
                    AccCurrency := Bank."Currency Code";
                    AccBalanceFC := Bank.Balance;
                end;
            Rec."Account Type"::Customer:
                if Customer.Get(Rec."Account No.") then begin
                    Customer.CalcFields("Balance (LCY)");
                    AddNotPosted(Rec."Account No.", '', Rec."Account Type");
                    AccNumber := Customer."No.";
                    AccName := CopyStr(Customer.Name, 1, MaxStrLen(AccName));
                    AccBalance := Customer."Balance (LCY)";
                end;
            Rec."Account Type"::Vendor:
                if Vendor.Get(Rec."Account No.") then begin
                    Vendor.CalcFields("Balance (LCY)");
                    AddNotPosted(Rec."Account No.", '', Rec."Account Type");
                    AccNumber := Vendor."No.";
                    AccName := CopyStr(Vendor.Name, 1, MaxStrLen(AccName));
                    AccBalance := -Vendor."Balance (LCY)";
                end;
        end;

        if AccNumber = '' then
            AddNotPosted('', '', Rec."Account Type");

        AccNotPosted := JournalAmtLCY;
        AccNotPostedFC := JournalAmtFCY;

        case Rec."Bal. Account Type" of
            Rec."Bal. Account Type"::"G/L Account":
                if GlAcc.Get(Rec."Bal. Account No.") then begin
                    GlAcc.CalcFields(Balance);
                    GLAccountSourceCurrency."G/L Account No." := GLAcc."No.";
                    GLAccountSourceCurrency."Currency Code" := GLAcc."Source Currency Code";
                    GLAccountSourceCurrency.CalcFields("Source Curr. Balance at Date");
                    AddNotPosted(Rec."Bal. Account No.", GlAcc."Source Currency Code", Rec."Bal. Account Type");
                    BalAccNo := GlAcc."No.";
                    BalAccName := GlAcc.Name;
                    BalAccBalance := GlAcc.Balance;
                    BalAccCurrency := GlAcc."Source Currency Code";
                    BalAccBalanceFC := GLAccountSourceCurrency."Source Curr. Balance at Date";
                end;
            Rec."Bal. Account Type"::"Bank Account":
                if Bank.Get(Rec."Bal. Account No.") then begin
                    Bank.CalcFields(Balance, "Balance (LCY)");
                    AddNotPosted(Rec."Bal. Account No.", Bank."Currency Code", Rec."Bal. Account Type");
                    BalAccNo := Bank."No.";
                    BalAccName := CopyStr(Bank.Name, 1, MaxStrLen(AccName));
                    BalAccBalance := Bank."Balance (LCY)";
                    BalAccCurrency := Bank."Currency Code";
                    BalAccBalanceFC := Bank.Balance;
                end;
            Rec."Bal. Account Type"::Customer:
                if Customer.Get(Rec."Bal. Account No.") then begin
                    Customer.CalcFields("Balance (LCY)");
                    AddNotPosted(Rec."Bal. Account No.", '', Rec."Bal. Account Type");
                    BalAccNo := Customer."No.";
                    BalAccName := CopyStr(Customer.Name, 1, MaxStrLen(AccName));
                    BalAccBalance := Customer."Balance (LCY)";
                end;
            Rec."Bal. Account Type"::Vendor:
                if Vendor.Get(Rec."Bal. Account No.") then begin
                    Vendor.CalcFields("Balance (LCY)");
                    AddNotPosted(Rec."Bal. Account No.", '', Rec."Bal. Account Type");
                    BalAccNo := Vendor."No.";
                    BalAccName := CopyStr(Vendor.Name, 1, MaxStrLen(AccName));
                    BalAccBalance := -Vendor."Balance (LCY)";
                end;
        end;

        if BalAccNo = '' then
            AddNotPosted('', '', Rec."Bal. Account Type");

        BalAccNotPosted := JournalAmtLCY;
        BalAccNotPostedFC := JournalAmtFCY;
    end;

    [Scope('OnPrem')]
    procedure AddNotPosted(AccountNo: Code[20]; CurrencyCode: Code[10]; AccountType: Enum "Gen. Journal Account Type")
    begin
        JournalAmtLCY := 0;
        JournalAmtFCY := 0;

        if AccountNo = '' then
            exit;

        GenJnlLine.Reset();
        if not AllJournals then begin
            GenJnlLine.SetRange("Journal Template Name", Rec."Journal Template Name");
            GenJnlLine.SetRange("Journal Batch Name", Rec."Journal Batch Name");
            GenJnlLine.SetRange("Line No.", 0, Rec."Line No.");
        end;

        GenJnlLine.SetRange("Account Type", AccountType);
        GenJnlLine.SetRange("Account No.", AccountNo);
        if GenJnlLine.Find('-') then
            repeat
                JournalAmtLCY := JournalAmtLCY + GenJnlLine."Amount (LCY)" - GenJnlLine."VAT Amount (LCY)";

                if (CurrencyCode <> '') and (GenJnlLine."Currency Code" = CurrencyCode) then
                    JournalAmtFCY := JournalAmtFCY + GenJnlLine.Amount - GenJnlLine."VAT Amount";

            until GenJnlLine.Next() = 0;
        GenJnlLine.SetRange("Account Type");
        GenJnlLine.SetRange("Account No.");

        GenJnlLine.SetRange("Bal. Account Type", AccountType);
        GenJnlLine.SetRange("Bal. Account No.", AccountNo);
        if GenJnlLine.Find('-') then
            repeat
                JournalAmtLCY := JournalAmtLCY - GenJnlLine."Amount (LCY)" - GenJnlLine."Bal. VAT Amount (LCY)";

                if (CurrencyCode <> '') and (GenJnlLine."Currency Code" = CurrencyCode) then
                    JournalAmtFCY := JournalAmtFCY - GenJnlLine.Amount - GenJnlLine."Bal. VAT Amount";

            until GenJnlLine.Next() = 0;
    end;
}
