// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.CODA;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;

page 2000041 "CODA Statement Lines"
{
    Caption = 'CODA Statement Lines';
    DelayedInsert = true;
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = true;
    PageType = ListPart;
    SourceTable = "CODA Statement Line";
    SourceTableView = where(ID = const(Movement));

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Application Status"; Rec."Application Status")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the application status of the movement line.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the date when you want the movement to be posted.';
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document type to which the bank account statement line is linked.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document number, that the bank account statement line is linked to.';
                }
                field("Account Type"; Rec."Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the account type that the bank account statement line is linked to.';
                }
                field("Account No."; Rec."Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the G/L account, bank, customer, vendor or fixed asset, that the bank account statement line is linked to.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the movement.';
                }
                field(Information; Rec.Information)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies information from the CODA file, that this movement line is linked to.';
                    Visible = false;
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the amount of the movement, expressed in the currency code, that has been entered on the movement line.';
                }
                field("Statement Amount"; Rec."Statement Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the amount of this movement.';
                }
                field("Message Type"; Rec."Message Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the type of message that is used in the Statement Message field.';
                }
                field("Type Standard Format Message"; Rec."Type Standard Format Message")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the type of standard format message that will be used, when the Message Type field shows the option Standard format.';
                }
                field("Transaction Date"; Rec."Transaction Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the transaction date from the CODA file.';
                }
                field("Transaction Type"; Rec."Transaction Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the type of transaction linked to this movement line.';
                }
                field("Transaction Family"; Rec."Transaction Family")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the transaction family linked to this movement line.';
                }
                field(Transaction; Rec.Transaction)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the transaction linked to this movement line.';
                }
                field("Transaction Category"; Rec."Transaction Category")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the category of the transaction linked to the movement line.';
                }
                field("Bank Reference No."; Rec."Bank Reference No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the reference number of the bank.';
                }
            }
            group(Control16)
            {
                ShowCaption = false;
                field(AccName; AccName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Account Name';
                    Editable = false;
                    ToolTip = 'Specifies the name of the account that has been entered on the coded bank account statement line.';
                }
                field(UnappliedAmount; UnappliedAmount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Unapplied Amount';
                    Editable = false;
                    Enabled = UnappliedAmountEnable;
                    ToolTip = 'Specifies the total amount of the unapplied CODA statement lines.';
                }
                field("Balance + ""Statement Amount"""; Balance + Rec."Statement Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Balance';
                    Editable = false;
                    Enabled = BalanceEnable;
                    ToolTip = 'Specifies the balance that has accumulated in the Coded Bank Account Statement table on the line.';
                }
                field("TotalBalance + ""Statement Amount"""; TotalBalance + Rec."Statement Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Total Balance';
                    Editable = false;
                    Enabled = TotalBalanceEnable;
                    ToolTip = 'Specifies the total balance of the CODA statement lines.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    begin
        CalcBalance(Rec."Statement Line No.");
        GetAccount();
    end;

    trigger OnAfterGetRecord()
    begin
        InformationOnFormat(Format(Rec.Information));
    end;

    trigger OnInit()
    begin
        UnappliedAmountEnable := true;
        BalanceEnable := true;
        TotalBalanceEnable := true;
    end;

    var
        GLAcc: Record "G/L Account";
        Cust: Record Customer;
        Vend: Record Vendor;
        BankStmtMgmt: Codeunit "CODA Write Statements";
        UnappliedAmount: Decimal;
        TotalBalance: Decimal;
        Balance: Decimal;
        AccName: Text[100];
        TotalBalanceEnable: Boolean;
        BalanceEnable: Boolean;
        UnappliedAmountEnable: Boolean;

    local procedure CalcBalance(CodBankStmtLineNo: Integer)
    var
        CodBankStmt: Record "CODA Statement";
        TempCodBankStmtLine: Record "CODA Statement Line";
    begin
        if CodBankStmt.Get(Rec."Bank Account No.", Rec."Statement No.") then;

        TempCodBankStmtLine.SetCurrentKey("Bank Account No.", "Statement No.", ID, "Attached to Line No.", Type);
        TempCodBankStmtLine.CopyFilters(Rec);
        TempCodBankStmtLine.SetRange(Type, Rec.Type::Global);

        TotalBalance := CodBankStmt."Balance Last Statement" - Rec."Statement Amount";
        if TempCodBankStmtLine.CalcSums("Statement Amount") then begin
            TotalBalance := TotalBalance + TempCodBankStmtLine."Statement Amount";
            UnappliedAmount := TempCodBankStmtLine."Statement Amount";
            TotalBalanceEnable := true;
        end else
            TotalBalanceEnable := false;

        Balance := CodBankStmt."Balance Last Statement" - Rec."Statement Amount";
        TempCodBankStmtLine.SetRange("Statement Line No.", 0, CodBankStmtLineNo);
        if TempCodBankStmtLine.CalcSums("Statement Amount") then begin
            Balance := Balance + TempCodBankStmtLine."Statement Amount";
            BalanceEnable := true;
        end else
            BalanceEnable := false;

        TempCodBankStmtLine.Reset();
        TempCodBankStmtLine.SetCurrentKey("Bank Account No.", "Statement No.", "Application Status");
        TempCodBankStmtLine.SetRange("Bank Account No.", Rec."Bank Account No.");
        TempCodBankStmtLine.SetRange("Statement No.", Rec."Statement No.");
        TempCodBankStmtLine.SetRange("Application Status", Rec."Application Status"::Applied);
        if TempCodBankStmtLine.CalcSums(Amount) then begin
            UnappliedAmount := UnappliedAmount - TempCodBankStmtLine.Amount;
            UnappliedAmountEnable := true;
        end else
            UnappliedAmountEnable := false;
    end;

    [Scope('OnPrem')]
    procedure GetAccount()
    begin
        AccName := '';
        if Rec."Account No." <> '' then
            case Rec."Account Type" of
                Rec."Account Type"::"G/L Account":
                    if GLAcc.Get(Rec."Account No.") then
                        AccName := GLAcc.Name;
                Rec."Account Type"::Customer:
                    if Cust.Get(Rec."Account No.") then
                        AccName := Cust.Name;
                Rec."Account Type"::Vendor:
                    if Vend.Get(Rec."Account No.") then
                        AccName := Vend.Name;
            end;
    end;

    [Scope('OnPrem')]
    procedure Apply()
    begin
        BankStmtMgmt.Apply(Rec);
    end;

    local procedure InformationOnFormat(Text: Text[1024])
    begin
        if Rec.Information > 0 then
            Text := '***'
    end;
}

