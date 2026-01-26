// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.CODA;

using Microsoft.Bank.BankAccount;
using System.Utilities;

report 2000040 "CODA Statement - Test"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/BankMgt/Statement/CODAStatementTest.rdlc';
    Caption = 'CODA Statement - Test';

    dataset
    {
        dataitem(CodBankStmt; "CODA Statement")
        {
            DataItemTableView = sorting("Bank Account No.", "Statement No.");
            RequestFilterFields = "Bank Account No.", "Statement No.";
            column(BankAccountNo_CodBankStmt; "Bank Account No.")
            {
            }
            column(StatementNo_CodBankStmt; "Statement No.")
            {
            }
            dataitem(PageCounter; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(TodayFormatted; Format(Today, 0, 4))
                {
                }
                column(CompanyName; COMPANYPROPERTY.DisplayName())
                {
                }
                column(CodBankStmtBankAccountNoStmtNo; CodBankStmt."Bank Account No." + ' ' + CodBankStmt."Statement No.")
                {
                }
                column(CodBankStmtBalanceLastStmt; CodBankStmt."Balance Last Statement")
                {
                }
                column(CodBankStmtStatementDate; CodBankStmt."Statement Date")
                {
                }
                column(CodBankStmtStatementEndingBalance; CodBankStmt."Statement Ending Balance")
                {
                }
                column(CODAStatementTestCaption; CODAStatementTestCaptionLbl)
                {
                }
                column(PageCaption; PageCaptionLbl)
                {
                }
                column(BalanceLastStatementCaption; BalanceLastStatementCaptionLbl)
                {
                }
                column(StatementDateCaption; StatementDateCaptionLbl)
                {
                }
                column(StatementEndingBalanceCaption; StatementEndingBalanceCaptionLbl)
                {
                }
                dataitem(HeaderErrorCounter; "Integer")
                {
                    DataItemTableView = sorting(Number);
                    column(ErrorTextNumber; ErrorText[Number])
                    {
                    }
                    column(ErrorTextNumberCaption; WarningCaptionLbl)
                    {
                    }

                    trigger OnPostDataItem()
                    begin
                        ErrorCounter := 0;
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetRange(Number, 1, ErrorCounter);
                    end;
                }
                dataitem(CodBankStmtLine; "CODA Statement Line")
                {
                    DataItemLink = "Bank Account No." = field("Bank Account No."), "Statement No." = field("Statement No.");
                    DataItemLinkReference = CodBankStmt;
                    DataItemTableView = sorting("Bank Account No.", "Statement No.", ID, "Attached to Line No.", Type) where(ID = const(Movement), Type = const(Global));
                    column(TransactionDate_CodBankStmtLine; "Transaction Date")
                    {
                    }
                    column(Description_CodBankStmtLine; Description)
                    {
                    }
                    column(PostingDate_CodBankStmtLine; "Posting Date")
                    {
                    }
                    column(StatementAmount_CodBankStmtLine; "Statement Amount")
                    {
                    }
                    column(BankReferenceNo_CodBankStmtLine; "Bank Reference No.")
                    {
                    }
                    column(ExtReferenceNo_CodBankStmtLine; "Ext. Reference No.")
                    {
                    }
                    column(TransactionDateCaption_CodBankStmtLine; FieldCaption("Transaction Date"))
                    {
                    }
                    column(DescriptionCaption_CodBankStmtLine; FieldCaption(Description))
                    {
                    }
                    column(PostingDateCaption_CodBankStmtLine; FieldCaption("Posting Date"))
                    {
                    }
                    column(StatementAmountCaption_CodBankStmtLine; FieldCaption("Statement Amount"))
                    {
                    }
                    column(ExtReferenceNoCaption_CodBankStmtLine; FieldCaption("Ext. Reference No."))
                    {
                    }
                    column(BankReferenceNoCaption_CodBankStmtLine; FieldCaption("Bank Reference No."))
                    {
                    }
                    column(TotalsCaption; TotalsCaptionLbl)
                    {
                    }
                    column(StatementNo_CodBankStmtLine; "Statement No.")
                    {
                    }
                    dataitem(LineErrorCounter; "Integer")
                    {
                        DataItemTableView = sorting(Number);
                        column(ErrorTextNumberLineErrorCounter; ErrorText[Number])
                        {
                        }
                        column(WarningCaption; WarningCaptionLbl)
                        {
                        }

                        trigger OnPostDataItem()
                        begin
                            ErrorCounter := 0;
                        end;

                        trigger OnPreDataItem()
                        begin
                            SetRange(Number, 1, ErrorCounter);
                        end;
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if not CodBankStmtPost.FetchCodedTransaction(CodBankStmtLine) then
                            AddError(
                              StrSubstNo(Text004,
                                "Transaction Family", Transaction, "Transaction Category",
                                  FieldCaption("Bank Account No."), "Bank Account No."));
                        ErrorMsg := CodBankStmtPost.InterpretStandardFormat(CodBankStmtLine);
                        if ErrorMsg <> '' then
                            AddError(ErrorMsg);
                    end;
                }
                dataitem(FooterErrorCounter; "Integer")
                {
                    DataItemTableView = sorting(Number);
                    column(WarningCaptionFooterErrorCounter; WarningCaptionLbl)
                    {
                    }

                    trigger OnPostDataItem()
                    begin
                        ErrorCounter := 0;
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetRange(Number, 1, ErrorCounter);
                    end;
                }
            }

            trigger OnAfterGetRecord()
            begin
                if "Statement Date" = 0D then
                    AddError(Text000);

                CodBankStmtLine.Reset();
                CodBankStmtLine.SetCurrentKey("Bank Account No.", "Statement No.", ID, "Attached to Line No.", Type);
                CodBankStmtLine.SetRange("Bank Account No.", "Bank Account No.");
                CodBankStmtLine.SetRange("Statement No.", "Statement No.");
                CodBankStmtLine.SetRange(ID, CodBankStmtLine.ID::Movement);
                CodBankStmtLine.SetRange(Type, CodBankStmtLine.Type::Global);
                CodBankStmtLine.CalcSums("Statement Amount");

                if CodBankStmtLine."Statement Amount" <> "Statement Ending Balance" - "Balance Last Statement" then
                    AddError(Text001);

                if BankAcc.Get("Bank Account No.") then begin
                    if BankAcc.Blocked then
                        AddError(StrSubstNo(Text002, "Bank Account No."));
                end else
                    AddError(StrSubstNo(Text003, "Bank Account No."));
            end;
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        CodBankStmtPost.InitCodeunit(false, false)
    end;

    var
        Text000: Label 'The statement date must be specified.';
        Text001: Label 'Statement ending balance is not equal to total balance.';
        Text002: Label 'The Blocked field must be No for bank account %1.';
        Text003: Label 'Bank account %1 does not exist.';
        Text004: Label 'Transaction %1 %2 %3 for bank account %4 was not found.', Comment = 'Parameters 1-3 - integer numbers , 4 - bank account number.';
        BankAcc: Record "Bank Account";
        CodBankStmtPost: Codeunit "Post Coded Bank Statement";
        ErrorCounter: Integer;
        ErrorText: array[99] of Text[250];
        ErrorMsg: Text[250];
        CODAStatementTestCaptionLbl: Label 'CODA Statement - Test';
        PageCaptionLbl: Label 'Page';
        BalanceLastStatementCaptionLbl: Label 'Balance Last Statement';
        StatementDateCaptionLbl: Label 'Statement Date';
        StatementEndingBalanceCaptionLbl: Label 'Statement Ending Balance';
        WarningCaptionLbl: Label 'Warning !';
        TotalsCaptionLbl: Label 'Totals';

    local procedure AddError(Text: Text[250])
    begin
        ErrorCounter := ErrorCounter + 1;
        ErrorText[ErrorCounter] := Text;
    end;
}

