// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reports;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Ledger;
using Microsoft.Bank.Reconciliation;
using Microsoft.Bank.Statement;

report 1407 "Bank Account Statement"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Bank/Reports/BankAccountStatement.rdlc';
    Caption = 'Bank Account Statement';
    WordMergeDataItem = "Bank Account Statement";

    dataset
    {
        dataitem("Bank Account Statement"; "Bank Account Statement")
        {
            DataItemTableView = sorting("Bank Account No.", "Statement No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "Bank Account No.", "Statement No.";
            column(ComanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(BankAccStmtTableCaptFltr; TableCaption + ': ' + BankAccStmtFilter)
            {
            }
            column(BankAccStmtFilter; BankAccStmtFilter)
            {
            }
            column(StmtNo_BankAccStmt; "Statement No.")
            {
                IncludeCaption = true;
            }
            column(Bank_Acc__Reconciliation___Statement_Date_Caption; Bank_Acc__Reconciliation___Statement_Date_CaptionLbl)
            {
            }
            column(Bank_Acc__Reconciliation___Statement_Date_; Format("Bank Account Statement"."Statement Date"))
            {
            }
            column(Bank_Acc__Reconciliation___Balance_Last_Statement_Caption; Bank_Acc__Reconciliation___Balance_Last_Statement_CaptionLbl)
            {
            }
            column(Bank_Acc__Reconciliation___Balance_Last_Statement_; "Bank Account Statement"."Balance Last Statement")
            {
            }
            column(Bank_Acc__Reconciliation___Statement_Ending_Balance_Caption; Bank_Acc__Reconciliation___Statement_Ending_Balance_CaptionLbl)
            {
            }
            column(Bank_Acc__Reconciliation___Statement_Ending_Balance_; "Bank Account Statement"."Statement Ending Balance")
            {
            }
            column(G_L_BalanceCaption; G_L_BalanceCaptionTxt)
            {
            }
            column(Bank_Acc__Reconciliation___TotalBalOnBankAccount; GLBalanceAtPostingDate)
            {
            }
            column(Subtotal_Caption; Subtotal_CaptionLbl)
            {
            }
            column(GL_Subtotal; GLBalanceAtPostingDate + "Bank Account Statement"."Total Pos. Diff. at Posting")
            {
            }
            column(Ending_G_L_BalanceCaption; BankAccountBalanceLbl)
            {
            }
            column(Ending_GL_Balance; GLBalanceAtPostingDate + "Bank Account Statement"."Total Pos. Diff. at Posting" + "Bank Account Statement"."Total Neg. Diff. at Posting")
            {
            }
            column(Currency_CodeCaption; CurrencyCodeCaption)
            {
            }
            column(Currency_Code; CurrencyCode)
            {
            }
            column(Statement_BalanceCaption; Statement_BalanceCaptionLbl)
            {
            }
            column(Outstanding_BankTransactionsCaption; Outstanding_BankTransactionsCaptionLbl)
            {
            }
            column(Bank_Acc__Reconciliation___TotalOutstdBankTransactions; "Bank Account Statement"."Outstd. Transact. at Posting")
            {
            }
            column(Statement_Subtotal; "Bank Account Statement"."Statement Ending Balance" + "Bank Account Statement"."Outstd. Transact. at Posting")
            {
            }
            column(Outstanding_PaymentsCaption; Outstanding_PaymentsCaptionLbl)
            {
            }
            column(Bank_Acc__Reconciliation___TotalOutstdPayments; "Bank Account Statement"."Outstd. Payments at Posting")
            {
            }
            column(Ending_BalanceCaption; BankAccountBalanceLbl)
            {
            }
            column(Adjusted_Statement_Ending_Balance; "Bank Account Statement"."Statement Ending Balance" + "Bank Account Statement"."Outstd. Payments at Posting" + "Bank Account Statement"."Outstd. Transact. at Posting")
            {
            }
            column(Amt_BankAccStmtLineStmt; "Bank Account Statement Line"."Statement Amount")
            {
            }
            column(AppliedAmt_BankAccStmtLine; "Bank Account Statement Line"."Applied Amount")
            {
            }
            column(BankAccNo_BankAccStmt; "Bank Account No.")
            {
            }
            column(BankAccStmtCapt; BankAccStmtCaptLbl)
            {
            }
            column(CurrReportPAGENOCapt; CurrReportPAGENOCaptLbl)
            {
            }
            column(BnkAccStmtLinTrstnDteCapt; BnkAccStmtLinTrstnDteCaptLbl)
            {
            }
            column(BnkAcStmtLinValDteCapt; BnkAcStmtLinValDteCaptLbl)
            {
            }
            column(GLBalanceCaption; GLBalanceCaptionLbl)
            {
            }
            column(CompletedPayments_SectionTitleCaption; CompletedPayments_SectionTitleLbl)
            {
            }
            dataitem("Bank Account Statement Line"; "Bank Account Statement Line")
            {
                DataItemLink = "Bank Account No." = field("Bank Account No."), "Statement No." = field("Statement No.");
                DataItemTableView = sorting("Bank Account No.", "Statement No.", "Statement Line No.");
                column(Statement_No_BnkAcStmtLine; "Statement No.")
                {
                }
                column(Statement_Line_No_BnkAcStmtLine; "Statement Line No.")
                {
                }
                column(TrnsctnDte_BnkAcStmtLin; Format("Transaction Date"))
                {
                }
                column(Type_BankAccStmtLine; Type)
                {
                    IncludeCaption = true;
                }
                column(LineDocNo_BankAccStmt; "Document No.")
                {
                    IncludeCaption = true;
                }
                column(AppliedEntr_BankAccStmtLine; "Applied Entries")
                {
                    IncludeCaption = true;
                }
                column(Amt1_BankAccStmtLineStmt; "Statement Amount")
                {
                    IncludeCaption = true;
                }
                column(AppliedAmt1_BankAccStmtLine; "Applied Amount")
                {
                    IncludeCaption = true;
                }
                column(Desc_BankAccStmtLine; Description)
                {
                    IncludeCaption = true;
                }
                column(ValueDate_BankAccStmtLine; Format("Value Date"))
                {
                }
            }
            #region [Outstanding Bank Transaction]
            column(Print_Outstanding_Transactions; PrintOutstandingTransactions)
            {
            }
            column(Outstanding_BankTransaction_SectionTitleCaption; Outstanding_BankTransaction_SectionTitleLbl)
            {
            }
            column(Outstanding_BankTransaction_PostingDateCaption; Outstanding_BankTransaction_PostingDateLbl)
            {
            }
            column(Outstanding_BankTransaction_DocTypeCaption; Outstanding_BankTransaction_DocTypeLbl)
            {
            }
            column(Outstanding_BankTransaction_DocNoCaption; Outstanding_BankTransaction_DocNoLbl)
            {
            }
            column(Outstanding_BankTransaction_DescriptionCaption; Outstanding_BankTransaction_DescriptionLbl)
            {
            }
            column(Outstanding_BankTransaction_AmountCaption; Outstanding_BankTransaction_AmountLbl)
            {
            }
            dataitem(OutstandingBankTransaction; "Bank Account Ledger Entry")
            {
                DataItemTableView = sorting("Entry No.");
                UseTemporary = true;
                column(Outstanding_BankTransaction_PostingDate; Format("Posting Date"))
                {
                }
                column(Outstanding_BankTransaction_DocType; "Document Type")
                {
                }
                column(Outstanding_BankTransaction_DocNo; "Document No.")
                {
                }
                column(Outstanding_BankTransaction_Description; Description)
                {
                }
                column(Outstanding_BankTransaction_Amount; Amount)
                {
                }

            }
            #endregion
            #region [Outstanding Checks]
            column(Outstanding_Check_SectionTitleCaption; Outstanding_Check_SectionTitleLbl)
            {
            }
            column(Outstanding_Check_PostingDateCaption; Outstanding_Check_PostingDateLbl)
            {
            }
            column(Outstanding_Check_DocTypeCaption; Outstanding_Check_DocTypeLbl)
            {
            }
            column(Outstanding_Check_CheckNoCaption; Outstanding_Check_CheckNoLbl)
            {
            }
            column(Outstanding_Check_DescriptionCaption; Outstanding_Check_DescriptionLbl)
            {
            }
            column(Outstanding_Check_AmountCaption; Outstanding_Check_AmountLbl)
            {
            }
            dataitem(OutstandingCheck; "Bank Account Ledger Entry")
            {
                DataItemTableView = sorting("Entry No.");
                UseTemporary = true;
                column(Outstanding_Check_PostingDate; Format("Posting Date"))
                {
                }
                column(Outstanding_Check_DocType; "Document Type")
                {
                }
                column(Outstanding_Check_CheckNo; "Document No.")
                {
                }
                column(Outstanding_Check_Description; Description)
                {
                }
                column(Outstanding_Check_Amount; Amount)
                {
                }
            }
            #endregion
            trigger OnAfterGetRecord()
            var
                BankAcc: Record "Bank Account";
            begin
                if BankAcc.Get("Bank Account Statement"."Bank Account No.") then begin
                    CurrencyCode := BankAcc."Currency Code";
                    CurrencyCodeCaption := BankAcc.FieldCaption("Currency Code");
                end;
                G_L_BalanceCaptionTxt := G_L_BalanceCaptionLbl;
                if "Bank Account Statement"."Statement Date" <> 0D then
                    G_L_BalanceCaptionTxt := G_L_BalanceCaptionTxt + AtLbl + format("Statement Date");

                GLBalanceAtPostingDate := BankAccReconTest.GetGLAccountBalanceLCYForBankStatement("Bank Account Statement");

                if PrintOutstandingTransactions then
                    GatherOutstandingTransactions("Bank Account No.");
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Control2)
                {
                    ShowCaption = false;
                    field(PrintOutstandingTransaction; PrintOutstandingTransactions)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print Outstanding Transactions';
                        ToolTip = 'Specifies if the report includes lines for outstanding transactions.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
        TotalCaption = 'Total';
        QuantityCaption = 'Quantity';
    }

    trigger OnPreReport()
    begin
        BankAccStmtFilter := "Bank Account Statement".GetFilters();
    end;

    var
        BankAccReconTest: Codeunit "Bank Acc. Recon. Test";
        BankAccStmtFilter: Text;
        G_L_BalanceCaptionTxt: Text;
        CurrencyCodeCaption: Text;
        BankAccStmtCaptLbl: Label 'Bank Account Statement';
        CurrReportPAGENOCaptLbl: Label 'Page';
        BnkAccStmtLinTrstnDteCaptLbl: Label 'Transaction Date';
        BnkAcStmtLinValDteCaptLbl: Label 'Value Date';
        GLBalanceCaptionLbl: Label 'G/L Balance';
        Bank_Acc__Reconciliation___Statement_Date_CaptionLbl: Label 'Statement Date';
        Bank_Acc__Reconciliation___Balance_Last_Statement_CaptionLbl: Label 'Balance Last Statement';
        Bank_Acc__Reconciliation___Statement_Ending_Balance_CaptionLbl: Label 'Statement Ending Balance';
        G_L_BalanceCaptionLbl: Label 'G/L Balance';
        Subtotal_CaptionLbl: Label 'Subtotal';
        BankAccountBalanceLbl: Label 'Bank Account Balance';
        Statement_BalanceCaptionLbl: Label 'Statement Balance';
        CompletedPayments_SectionTitleLbl: Label 'Completed Payments';
        Outstanding_PaymentsCaptionLbl: Label 'Outstanding Checks';
        Outstanding_BankTransaction_SectionTitleLbl: Label 'Outstanding Payments';
        Outstanding_BankTransactionsCaptionLbl: Label 'Outstanding Bank Transactions';
        Outstanding_BankTransaction_PostingDateLbl: Label 'Posting Date';
        Outstanding_BankTransaction_DocTypeLbl: Label 'Document Type';
        Outstanding_BankTransaction_DocNoLbl: Label 'Document No.';
        Outstanding_BankTransaction_DescriptionLbl: Label 'Description';
        Outstanding_BankTransaction_AmountLbl: Label 'Statement Amount';
        Outstanding_Check_SectionTitleLbl: Label 'Outstanding Checks';
        Outstanding_Check_PostingDateLbl: Label 'Posting Date';
        Outstanding_Check_DocTypeLbl: Label 'Document Type';
        Outstanding_Check_CheckNoLbl: Label 'Check No.';
        Outstanding_Check_DescriptionLbl: Label 'Description';
        Outstanding_Check_AmountLbl: Label 'Statement Amount';
        AtLbl: Label ' at ', Comment = 'used to build the construct a string like balance at 31-12-2020';
        CurrencyCode: Code[20];
        PrintOutstandingTransactions: Boolean;
        GLBalanceAtPostingDate: Decimal;

    local procedure GatherOutstandingTransactions(BankAccountNo: Code[20])
    var
        TempBankAccountReconciliation: Record "Bank Acc. Reconciliation" temporary;
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
    begin
        TempBankAccountReconciliation."Bank Account No." := BankAccountNo;
        TempBankAccountReconciliation."Statement No." := "Bank Account Statement"."Statement No.";
        TempBankAccountReconciliation."Statement Date" := "Bank Account Statement"."Statement Date";
        BankAccReconTest.SetOutstandingFilters(TempBankAccountReconciliation, BankAccountLedgerEntry);
        BankAccountLedgerEntry.SetFilter(SystemCreatedAt, '..%1', "Bank Account Statement".SystemCreatedAt);
        if BankAccountLedgerEntry.IsEmpty() then
            exit;

        BankAccountLedgerEntry.SetAutoCalcFields("Check Ledger Entries");
        if BankAccountLedgerEntry.FindSet() then
            repeat
                if BankAccReconTest.CheckBankAccountLedgerEntryFilters(BankAccountLedgerEntry, TempBankAccountReconciliation."Statement No.", TempBankAccountReconciliation."Statement Date") then
                    if (BankAccountLedgerEntry."Closed at Date" = 0D) or BankAccountLedgerEntry.Open or (BankAccountLedgerEntry."Closed at Date" > "Bank Account Statement"."Statement Date") then
                        if BankAccountLedgerEntry."Check Ledger Entries" <> 0 then
                            OutstandingCheck.CopyFromBankAccLedgerEntry(BankAccountLedgerEntry, "Bank Account Statement"."Statement No.")
                        else
                            OutstandingBankTransaction.CopyFromBankAccLedgerEntry(BankAccountLedgerEntry, "Bank Account Statement"."Statement No.")
            until BankAccountLedgerEntry.Next() = 0;
    end;
}
