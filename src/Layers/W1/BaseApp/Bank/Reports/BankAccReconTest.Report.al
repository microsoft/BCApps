// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reports;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Check;
using Microsoft.Bank.Ledger;
using Microsoft.Bank.Reconciliation;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Purchases.Payables;
using Microsoft.Sales.Receivables;
using System.Utilities;

report 1408 "Bank Acc. Recon. - Test"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Bank/Reports/BankAccReconTest.rdlc';
    Caption = 'Bank Acc. Recon. - Test';
    EnableHyperlinks = true;

    dataset
    {
        dataitem("Bank Acc. Reconciliation"; "Bank Acc. Reconciliation")
        {
            DataItemTableView = sorting("Bank Account No.", "Statement No.");
            RequestFilterFields = "Bank Account No.", "Statement No.";
            column(Bank_Acc__Reconciliation_Bank_Account_No_; "Bank Account No.")
            {
            }
            column(Bank_Acc__Reconciliation_Statement_No_; "Statement No.")
            {
            }
            dataitem(PageCounter; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
                {
                }
                column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
                {
                }
                column(Bank_Acc__Reconciliation__TABLECAPTION___________BankAccReconFilter; "Bank Acc. Reconciliation".TableCaption + ': ' + BankAccReconFilter)
                {
                }
                column(BankAccReconFilter; BankAccReconFilter)
                {
                }
                column(Bank_Acc__Reconciliation___Bank_Account_No____________Bank_Acc__Reconciliation___Statement_No__; "Bank Acc. Reconciliation"."Bank Account No." + ' ' + "Bank Acc. Reconciliation"."Statement No.")
                {
                }
                column(Bank_Acc__Reconciliation___Balance_Last_Statement_; "Bank Acc. Reconciliation"."Balance Last Statement")
                {
                }
                column(Bank_Acc__Reconciliation___Statement_Date_; Format("Bank Acc. Reconciliation"."Statement Date"))
                {
                }
                column(Bank_Acc__Reconciliation___Statement_Ending_Balance_; CalculatedStatementEndingBalance)
                {
                }
                column(Bank_Acc__Reconciliation___TotalBalOnBankAccount; BankAcc."Balance at Date")
                {
                }
                column(Bank_Acc__Reconciliation___TotalBalOnGLAccount; TotalBalOnGLAccount)
                {
                }
                column(Bank_Acc__Reconciliation___TotalBalOnGLAccountLCY; TotalBalOnGLAccountLCY)
                {
                }
                column(Bank_Acc__Reconciliation___TotalOutstdBankTransactions; TotalOutstdBankTransac)
                {
                }
                column(Bank_Acc__Reconciliation___TotalOutstdPayments; TotalOutstdPayments)
                {
                }
                column(ErrorLabel; ErrorLabel)
                {
                }
                column(HeaderError1; HeaderError1)
                {
                }
                column(HeaderError2; HeaderError2)
                {
                }
                column(HeaderError3; HeaderError3)
                {
                }
                column(DirectPostingURLLink; DirectPostingURLLinkLbl)
                {
                }
                column(Bank_Account_Statement___TestCaption; Bank_Account_Statement___TestCaptionLbl)
                {
                }
                column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
                {
                }
                column(Bank_Acc__Reconciliation___Balance_Last_Statement_Caption; Bank_Acc__Reconciliation___Balance_Last_Statement_CaptionLbl)
                {
                }
                column(Bank_Acc__Reconciliation___Statement_Date_Caption; Bank_Acc__Reconciliation___Statement_Date_CaptionLbl)
                {
                }
                column(Bank_Acc__Reconciliation___Statement_Ending_Balance_Caption; StatementEndingBalanceLbl)
                {
                }
                column(G_L_BalanceCaption; G_L_BalanceCaptionTxt)
                {
                }
                column(G_L_Balance_LCYCaption; G_L_BalanceLCYCaptionTxt)
                {
                }
                column(Bank_Acc_BalanceCaption; Bank_Acc_BalanceCaptionTxt)
                {
                }
                column(Ending_G_L_BalanceCaption; Ending_G_L_BalanceCaptionLbl)
                {
                }
                column(Subtotal_Caption; Subtotal_CaptionLbl)
                {
                }
                column(Difference_Caption; Difference_CaptionLbl)
                {
                }
                column(Ending_BalanceCaption; Ending_BalanceCaptionTxt)
                {
                }
                column(Outstanding_BankTransactionsCaption; Outstanding_BankTransactionsCaptionLbl)
                {
                }
                column(Total_Outstanding_BankTransactionsCaption; Total_Outstanding_BankTransactionsCaptionLbl)
                {
                }
                column(Outstanding_PaymentsCaption; Outstanding_PaymentsCaptionLbl)
                {
                }
                column(Total_Outstanding_PaymentsCaption; Total_Outstanding_PaymentsCaptionLbl)
                {
                }
                column(Print_Outstanding_Transactions; PrintOutstandingTransactions)
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
                column(GL_Subtotal; (BankAcc."Balance at Date"))
                {
                }
                column(Ending_GL_Balance; EndingGLBalance)
                {
                }
                column(Statement_Subtotal; (CalculatedStatementEndingBalance + TotalOutstdBankTransac))
                {
                }
                column(Adjusted_Statement_Ending_Balance; EndingStatementBalance)
                {
                }
                column(Sum_Of_Differences; SumOfDifferences)
                {
                }
                dataitem(HeaderErrorCounter; "Integer")
                {
                    DataItemTableView = sorting(Number);
                    column(ErrorText_Number_; ErrorText[Number])
                    {
                    }
                    column(ErrorText_Number_Caption; ErrorText_Number_CaptionLbl)
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
                dataitem("Bank Acc. Reconciliation Line"; "Bank Acc. Reconciliation Line")
                {
                    DataItemLink = "Statement Type" = field("Statement Type"), "Bank Account No." = field("Bank Account No."), "Statement No." = field("Statement No.");
                    DataItemLinkReference = "Bank Acc. Reconciliation";
                    DataItemTableView = sorting("Bank Account No.", "Statement No.", "Statement Line No.");
                    column(Bank_Acc__Reconciliation_Line__Transaction_Date_; Format("Transaction Date"))
                    {
                    }
                    column(Bank_Acc__Reconciliation_Line__Document_No__; "Document No.")
                    {
                    }
                    column(Bank_Acc__Reconciliation_Line_Description; Description)
                    {
                    }
                    column(Bank_Acc__Reconciliation_Line__Value_Date_; Format("Value Date"))
                    {
                    }
                    column(Bank_Acc__Reconciliation_Line__Applied_Entries_; "Applied Entries")
                    {
                    }
                    column(Bank_Acc__Reconciliation_Line__Applied_Amount_; "Applied Amount")
                    {
                    }
                    column(Bank_Acc__Reconciliation_Line__Statement_Amount_; "Statement Amount")
                    {
                    }
                    column(Bank_Acc__Reconciliation_Line_Type; '')
                    {
                    }
                    column(Bank_Acc__Reconciliation_Line_Statement_No; "Statement No.")
                    {
                    }
                    column(Bank_Acc__Reconciliation_Line_Statement_Line_No; "Statement Line No.")
                    {
                    }
                    column(Bank_Acc__Reconciliation_Line_Difference; Difference)
                    {
                    }
                    column(Bank_Acc__Reconciliation_Line__Applied_Amount__Control25; "Applied Amount")
                    {
                    }
                    column(Bank_Acc__Reconciliation_Line_Difference_Control29; Difference)
                    {
                    }
                    column(Bank_Acc__Reconciliation_Line__Transaction_Date_Caption; Bank_Acc__Reconciliation_Line__Transaction_Date_CaptionLbl)
                    {
                    }
                    column(Bank_Acc__Reconciliation_Line__Document_No__Caption; FieldCaption("Document No."))
                    {
                    }
                    column(Bank_Acc__Reconciliation_Line_DescriptionCaption; FieldCaption(Description))
                    {
                    }
                    column(Bank_Acc__Reconciliation_Line__Value_Date_Caption; Bank_Acc__Reconciliation_Line__Value_Date_CaptionLbl)
                    {
                    }
                    column(Bank_Acc__Reconciliation_Line__Applied_Entries_Caption; FieldCaption("Applied Entries"))
                    {
                    }
                    column(Bank_Acc__Reconciliation_Line__Statement_Amount_Caption; FieldCaption("Statement Amount"))
                    {
                    }
                    column(Bank_Acc__Reconciliation_Line__Applied_Amount_Caption; FieldCaption("Applied Amount"))
                    {
                    }
                    column(Bank_Acc__Reconciliation_Line_TypeCaption; '')
                    {
                    }
                    column(Bank_Acc__Reconciliation_Line_DifferenceCaption; FieldCaption(Difference))
                    {
                    }
                    column(TotalsCaption; TotalsCaptionLbl)
                    {
                    }
                    dataitem(LineErrorCounter; "Integer")
                    {
                        DataItemTableView = sorting(Number);
                        column(ErrorText_Number__Control97; ErrorText[Number])
                        {
                        }
                        column(ErrorText_Number__Control97Caption; ErrorText_Number__Control97CaptionLbl)
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
                    var
                        BankAccRecMatchBuffer: Record "Bank Acc. Rec. Match Buffer";
                        TableID: array[10] of Integer;
                        No: array[10] of Code[20];
                        IsManyToOne: Boolean;
                    begin
                        AppliedAmount := 0;
                        ErrorLabel := 1;

                        if "Bank Acc. Reconciliation"."Statement Type" =
                            "Bank Acc. Reconciliation"."Statement Type"::"Bank Reconciliation"
                        then begin
                            BankAccLedgEntry.SetFilterBankAccNoOpen("Bank Account No.");
                            BankAccLedgEntry.SetFilter("Statement Status", '=%1 | =%2',
                                BankAccLedgEntry."Statement Status"::"Bank Acc. Entry Applied",
                                BankAccLedgEntry."Statement Status"::"Check Entry Applied");
                            BankAccLedgEntry.SetRange("Statement No.", "Statement No.");

                            BankAccRecMatchBuffer.SetRange("Bank Account No.", "Bank Account No.");
                            BankAccRecMatchBuffer.SetRange("Statement No.", "Statement No.");
                            BankAccRecMatchBuffer.SetRange("Statement Line No.", "Statement Line No.");
                            if BankAccRecMatchBuffer.FindFirst() then begin
                                IsManyToOne := true;
                                BankAccLedgEntry.SetRange("Entry No.", BankAccRecMatchBuffer."Ledger Entry No.");
                            end else
                                BankAccLedgEntry.SetRange("Statement Line No.", "Statement Line No.");
                            OnBankAccReconciliationLineAfterGetRecordOnAfterBankAccLedgEntrySetFilters("Bank Acc. Reconciliation Line", BankAccLedgEntry);
                            if not BankAccLedgEntry.IsEmpty() then begin
                                BankAccLedgEntry.FindSet();
                                repeat
                                    AppliedAmount := AppliedAmount + BankAccLedgEntry.Amount;
                                    VerifyCheckLedgerEntry(BankAccLedgEntry);
                                until BankAccLedgEntry.Next() = 0;
                            end;
                        end else
                            AppliedAmount := GetPaymentReconciliationAppliedAmount("Bank Acc. Reconciliation Line");

                        OnBeforeCheckAppliedAmount("Bank Acc. Reconciliation Line", AppliedAmount);
                        if ("Applied Amount" <> AppliedAmount) and (not IsManyToOne) then
                            AddError(StrSubstNo(AmountWrongErr, FieldCaption("Applied Amount"), AppliedAmount));

                        if not DimensionManagement.CheckDimIDComb("Dimension Set ID") then
                            AddError(DimensionManagement.GetDimCombErr());

                        TableID[1] := DimensionManagement.TypeToTableID1("Account Type".AsInteger());
                        No[1] := "Account No.";
                        if not DimensionManagement.CheckDimValuePosting(TableID, No, "Dimension Set ID") then
                            AddError(DimensionManagement.GetDimValuePostingErr());

                        TotalAmount := TotalAmount + "Statement Amount";
                        if (not BankAccRecMatchBuffer."Is Processed") then
                            TotalAppliedAmount := TotalAppliedAmount + AppliedAmount;
                        MarkManyToOneMatchAsProcessed(BankAccRecMatchBuffer."Bank Account No.",
                                                        BankAccRecMatchBuffer."Statement No.",
                                                        BankAccRecMatchBuffer."Match ID");
                    end;

                    trigger OnPostDataItem()
                    var
                        BankAccRecMatchBuffer: Record "Bank Acc. Rec. Match Buffer";
                    begin
                        if TotalAmount <> TotalAppliedAmount then begin
                            AddError(ApplicationErr);
                            FooterError1 := ApplicationErr;
                        end;

                        if BankAccReconLine.Difference <> 0 then begin
                            AddError(
                              StrSubstNo(
                                TotalDifferenceErr, BankAccReconLine.Difference, 0));
                            FooterError2 := StrSubstNo(TotalDifferenceErr, BankAccReconLine.Difference, 0);
                        end;

                        BankAccRecMatchBuffer.SetRange("Bank Account No.", "Bank Account No.");
                        BankAccRecMatchBuffer.SetRange("Statement No.", "Statement No.");
                        if BankAccRecMatchBuffer.FindSet() then
                            repeat
                                BankAccRecMatchBuffer."Is Processed" := false;
                                BankAccRecMatchBuffer.Modify();
                            until BankAccRecMatchBuffer.Next() = 0;

                    end;

                    trigger OnPreDataItem()
                    begin
                        TotalAmount := 0;
                        TotalAppliedAmount := 0;
                        ErrorLabel := 1;
                    end;
                }
                dataitem(FooterErrorCounter; "Integer")
                {
                    DataItemTableView = sorting(Number);
                    column(FooterError1; FooterError1)
                    {
                    }
                    column(FooterError2; FooterError2)
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
                dataitem(OutstandingBankTransaction; "Outstanding Bank Transaction")
                {
                    UseTemporary = true;
                    column(Outstd_Bank_Transac_Amount; Amount)
                    {
                    }
                    column(Outstd_Bank_Transac_EntryNo_; "Entry No.")
                    {
                    }
                    column(Outstd_Bank_Transac_Posting_Date; Format("Posting Date"))
                    {
                    }
                    column(Outstd_Bank_Transac_Doc_Type; "Document Type")
                    {
                    }
                    column(Outstd_Bank_Transac_Doc_No_; "Document No.")
                    {
                    }
                    column(Outstd_Bank_Transac_Bank_Acc_No_; "Bank Account No.")
                    {
                    }
                    column(Outstd_Bank_Transac_Description; Description)
                    {
                    }
                    column(Outstd_Bank_Transac_Type; Type)
                    {
                    }
                    column(Outstd_Bank_Transac_Applied; Applied)
                    {
                    }
                }
                dataitem(OutstandingPayment; "Outstanding Bank Transaction")
                {
                    UseTemporary = true;
                    column(Outstd_Payment_Amount; Amount)
                    {
                    }
                    column(Outstd_Payment_Entry_No_; "Entry No.")
                    {
                    }
                    column(Outstd_Payment_Posting_Date; Format("Posting Date"))
                    {
                    }
                    column(Outstd_Payment_Doc_Type; "Document Type")
                    {
                    }
                    column(Outstd_Payment_Doc_No_; "Document No.")
                    {
                    }
                    column(Outstd_Payment_Bank_Acc_No_; "Bank Account No.")
                    {
                    }
                    column(Outstd_Payment_Description; Description)
                    {
                    }
                    column(Outstd_Payment_Type; Type)
                    {
                    }
                    column(Outstd_Payment_Applied; Applied)
                    {
                    }
                }
            }

            trigger OnAfterGetRecord()
            var
                BankAccPostingGroup: Record "Bank Account Posting Group";
                BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
            begin
                SetupRecord();
                StatementEndingBalanceLbl := Bank_Acc__Reconciliation___Statement_Ending_Balance_CaptionLbl;
                if "Bank Acc. Reconciliation"."Statement Type" = "Bank Acc. Reconciliation"."Statement Type"::"Payment Application" then
                    StatementEndingBalanceLbl += CalculatedFieldCaptionLbl;

                ErrorLabel := 1;
                if PrintOutstandingTransactions then begin
                    OutstandingBankTransaction.DeleteAll();
                    OutstandingPayment.DeleteAll();
                    CreateOutstandingBankTransactions();
                end;
                TotalOutstdBankTransac := BankAccReconTest.TotalOutstandingBankTransactions("Bank Acc. Reconciliation");

                BankAccReconLine.FilterBankRecLines("Bank Acc. Reconciliation");
                BankAccReconLine.CalcSums("Statement Amount", Difference);
                if "Statement Type" = "Statement Type"::"Bank Reconciliation" then
                    if BankAccReconLine."Statement Amount" <> "Statement Ending Balance" - "Balance Last Statement" then begin
                        AddError(
                        StrSubstNo(
                            StatementBalanceErr, FieldCaption("Statement Ending Balance")));
                        HeaderError1 := StrSubstNo(StatementBalanceErr, FieldCaption("Statement Ending Balance"));
                    end;

                if BankAcc.Get("Bank Account No.") then begin
                    CurrencyCode := BankAcc."Currency Code";
                    CurrencyCodeCaption := BankAcc.FieldCaption("Currency Code");
                    if BankAcc.Blocked then begin
                        AddError(
                          StrSubstNo(
                            TableValueWrongErr,
                            BankAcc.FieldCaption(Blocked), false, BankAcc.TableCaption(), "Bank Account No."));
                        HeaderError2 := StrSubstNo(TableValueWrongErr, BankAcc.FieldCaption(Blocked), false, BankAcc.TableCaption(), "Bank Account No.");
                    end;
                end else begin
                    AddError(
                      StrSubstNo(
                        TableValueMissingErr,
                        BankAcc.TableCaption(), "Bank Account No."));
                    HeaderError2 := StrSubstNo(TableValueMissingErr, BankAcc.TableCaption(), "Bank Account No.");
                end;
                if "Statement Type" = "Statement Type"::"Payment Application" then
                    // Bank Reconciliations done from the Payment Reconciliation Journal page, have no Statement Ending Date defined (unless set elsewhere by code e.g. tests)
                    // We take it as the last date of the entries
                    if "Statement Date" = 0D then begin
                        BankAccReconciliationLine.Reset();
                        BankAccReconciliationLine.SetRange("Statement No.", "Statement No.");
                        BankAccReconciliationLine.SetCurrentKey("Transaction Date");
                        BankAccReconciliationLine.SetAscending("Transaction Date", false);
                        if BankAccReconciliationLine.FindFirst() then
                            "Statement Date" := BankAccReconciliationLine."Transaction Date";
                    end;
                if "Statement Date" = 0D then
                    AddError(StrSubstNo(StatementDateErr, FieldCaption("Statement Date")));
                if BankAccPostingGroup.Get(BankAcc."Bank Acc. Posting Group") then begin
                    G_L_BalanceLCYCaptionTxt := StrSubstNo(G_L_BalanceLCYCaptionLbl, BankAccPostingGroup."G/L Account No.");
                    G_L_BalanceCaptionTxt := StrSubstNo(G_L_BalanceCaptionLbl, BankAccPostingGroup."G/L Account No.", BankAcc."Currency Code");
                    Bank_Acc_BalanceCaptionTxt := Bank_Acc_BalanceCaptionLbl;
                    Ending_BalanceCaptionTxt := BankAccountBalanceLbl;
                    if "Statement Date" <> 0D then begin
                        BankAcc.SetFilter("Date Filter", '..%1', "Statement Date");
                        G_L_BalanceCaptionTxt := G_L_BalanceCaptionTxt + AtLbl + format("Statement Date");
                        G_L_BalanceLCYCaptionTxt := G_L_BalanceLCYCaptionTxt + AtLbl + format("Statement Date");
                        Bank_Acc_BalanceCaptionTxt := Bank_Acc_BalanceCaptionTxt + AtLbl + format("Statement Date");
                    end;
                    TotalBalOnGLAccountLCY := BankAccReconTest.GetGLAccountBalanceLCY(BankAcc, BankAccPostingGroup, "Statement Date");
                    TotalBalOnGLAccount := BankAccReconTest.GetGLAccountBalance(TotalBalOnGLAccountLCY, "Statement Date", BankAcc."Currency Code");
                    CheckForDirectEntries(BankAcc, BankAccPostingGroup, "Statement Date");
                end;
                BankAcc.CalcFields("Balance at Date", "Balance at Date (LCY)");
                TotalOutstdPayments := BankAccReconTest.TotalOutstandingPayments("Bank Acc. Reconciliation");
                EndingGLBalance := BankAcc."Balance at Date";
                // Notice that BankAccReconLine had the sum of fields computed with CalcSums
                if "Bank Acc. Reconciliation"."Statement Type" = "Bank Acc. Reconciliation"."Statement Type"::"Bank Reconciliation" then
                    CalculatedStatementEndingBalance := "Bank Acc. Reconciliation"."Statement Ending Balance"
                else
                    CalculatedStatementEndingBalance := "Bank Acc. Reconciliation"."Balance Last Statement" + BankAccReconLine."Statement Amount";
                SumOfDifferences := BankAccReconLine.Difference;
                EndingStatementBalance := CalculatedStatementEndingBalance + TotalOutstdBankTransac + TotalOutstdPayments;
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
                    field(PrintOutstdTransac; PrintOutstandingTransactions)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print Outstanding Transactions';
                        ToolTip = 'Specifies if the report includes reconciliation lines for outstanding transactions.';
                        Visible = ShouldShowOutstandingBankTransactions;
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
        Warning = 'Warning!';
    }

    trigger OnPreReport()
    begin
        BankAccReconFilter := "Bank Acc. Reconciliation".GetFilters();
    end;

    trigger OnInitReport()
    begin
        OnBeforeInitReport(ShouldShowOutstandingBankTransactions);
    end;

    var
        BankAcc: Record "Bank Account";
        BankAccLedgEntry: Record "Bank Account Ledger Entry";
        CheckLedgEntry: Record "Check Ledger Entry";
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
        DimensionManagement: Codeunit DimensionManagement;
        BankAccReconTest: Codeunit "Bank Acc. Recon. Test";
        AppliedAmount: Decimal;
        TotalAmount: Decimal;
        TotalAppliedAmount: Decimal;
        TotalOutstdBankTransac: Decimal;
        TotalOutstdPayments: Decimal;
        EndingGLBalance: Decimal;
        EndingStatementBalance: Decimal;
        CalculatedStatementEndingBalance: Decimal;
        TotalBalOnGLAccount: Decimal;
        TotalBalOnGLAccountLCY: Decimal;
        SumOfDifferences: Decimal;
        BankAccReconFilter: Text;
        G_L_BalanceLCYCaptionTxt: Text;
        G_L_BalanceCaptionTxt: Text;
        Bank_Acc_BalanceCaptionTxt: Text;
        Ending_BalanceCaptionTxt: Text;
        ErrorCounter: Integer;
        ErrorText: array[99] of Text[250];
        ErrorLabel: Integer;
        HeaderError1: Text[250];
        HeaderError2: Text[250];
        HeaderError3: Text[250];
        FooterError1: Text[250];
        FooterError2: Text[250];
        CurrencyCodeCaption: Text[250];
        StatementEndingBalanceLbl: Text;
        CurrencyCode: Code[20];
        PrintOutstandingTransactions: Boolean;
        ShouldShowOutstandingBankTransactions: Boolean;
        StatementDateErr: Label '%1 must be specified.', Comment = '%1=Statement Date field caption';
        StatementBalanceErr: Label '%1 is not equal to Total Balance.', Comment = '%1=Statement Ending Balance field caption';
        TableValueWrongErr: Label '%1 must be %2 for %3 %4.', Comment = '%1=field caption;%2=field value;%3=table name caption;%4=field value';
        TableValueEmptyErr: Label '%1 must not be empty for %2 %3.', Comment = '%1=field caption;%2=table name caption;%3=field value';
        TableValueMissingErr: Label '%1 %2 does not exist.', Comment = '%1=table name caption;%2=table field name caption';
        AmountWrongErr: Label '%1 must be %2.', Comment = '%1=field name caption;%2=field value';
        ApplicationErr: Label 'Application is wrong.';
        TotalDifferenceErr: Label 'The total difference is %1. It must be %2.', Comment = '%1=field value;%2=field value';
        Bank_Account_Statement___TestCaptionLbl: Label 'Bank Account Statement';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Bank_Acc__Reconciliation___Balance_Last_Statement_CaptionLbl: Label 'Balance Last Statement';
        Bank_Acc__Reconciliation___Statement_Date_CaptionLbl: Label 'Statement Date';
        Bank_Acc__Reconciliation___Statement_Ending_Balance_CaptionLbl: Label 'Statement Ending Balance';
        ErrorText_Number_CaptionLbl: Label 'Warning!';
        CalculatedFieldCaptionLbl: Label ' (Calculated)';
        Bank_Acc__Reconciliation_Line__Transaction_Date_CaptionLbl: Label 'Transaction Date';
        Bank_Acc__Reconciliation_Line__Value_Date_CaptionLbl: Label 'Value Date';
        TotalsCaptionLbl: Label 'Totals';
        ErrorText_Number__Control97CaptionLbl: Label 'Warning!';
        Outstanding_BankTransactionsCaptionLbl: Label 'Outstanding Bank Transactions';
        Outstanding_PaymentsCaptionLbl: Label 'Outstanding Checks';
        Total_Outstanding_BankTransactionsCaptionLbl: Label 'Total Outstanding Bank Transactions';
        Total_Outstanding_PaymentsCaptionLbl: Label 'Total Outstanding Payments';
        G_L_BalanceCaptionLbl: Label 'G/L Account No. %1 Balance (%2) - Calculated', Comment = '%1= Account number; %2= Currency symbol';
        G_L_BalanceLCYCaptionLbl: Label 'G/L Account No. %1 Balance', Comment = '%1= Account number';
        Bank_Acc_BalanceCaptionLbl: Label 'Bank Account Balance';
        Ending_G_L_BalanceCaptionLbl: Label 'Ending G/L Balance';
        Subtotal_CaptionLbl: Label 'Subtotal';
        Difference_CaptionLbl: Label 'Sum of Differences';
        BankAccountBalanceLbl: Label 'Bank Account Balance';
        AtLbl: Label ' at ', Comment = 'used to build the construct a string like balance at 31-12-2020';
        Statement_BalanceCaptionLbl: Label 'Statement Balance';
        PotentialUnstabilityDueToDirectPostingEntriesLbl: Label 'Bank reconciliation might not be possible because there are direct posting entries. For more information, see %1.', Comment = '%1= URL link';
        DirectPostingURLLinkLbl: Label 'https://go.microsoft.com/fwlink/?linkid=2197950';

    local procedure AddError(Text: Text[250])
    begin
        ErrorCounter := ErrorCounter + 1;
        ErrorText[ErrorCounter] := Text;
    end;

    local procedure MarkManyToOneMatchAsProcessed(BankAccNo: Code[20]; StatementNo: Code[20]; MatchID: Integer)
    var
        BankAccRecMatchBuffer: Record "Bank Acc. Rec. Match Buffer";
    begin
        BankAccRecMatchBuffer.SetRange("Bank Account No.", BankAccNo);
        BankAccRecMatchBuffer.SetRange("Statement No.", StatementNo);
        BankAccRecMatchBuffer.SetRange("Match ID", MatchID);
        if BankAccRecMatchBuffer.FindSet() then
            repeat
                BankAccRecMatchBuffer."Is Processed" := true;
                BankAccRecMatchBuffer.Modify();
            until BankAccRecMatchBuffer.Next() = 0;
    end;

    local procedure CreateOutstandingBankTransactions()
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        LedgEntryRemainingAmount: Decimal;
        RemainingAmt: Decimal;
    begin
        BankAccReconTest.SetOutstandingFilters("Bank Acc. Reconciliation", BankAccountLedgerEntry);
        if BankAccountLedgerEntry.IsEmpty() then
            exit;

        BankAccountLedgerEntry.SetAutoCalcFields("Check Ledger Entries");
        if BankAccountLedgerEntry.FindSet() then
            repeat
                if BankAccReconTest.CheckBankAccountLedgerEntryFilters(BankAccountLedgerEntry, "Bank Acc. Reconciliation"."Statement No.", "Bank Acc. Reconciliation"."Statement Date") then
                    if BankAccountLedgerEntry."Check Ledger Entries" <> 0 then begin
                        RemainingAmt := BankAccountLedgerEntry.Amount -
                          OutstandingPayment.GetAppliedAmount(BankAccountLedgerEntry."Entry No.");
                        if RemainingAmt <> 0 then
                            OutstandingPayment.CopyFromBankAccLedgerEntry(BankAccountLedgerEntry, OutstandingPayment.Type::"Check Ledger Entry",
                              "Bank Acc. Reconciliation"."Statement Type".AsInteger(), "Bank Acc. Reconciliation"."Statement No.", RemainingAmt)
                    end else begin
                        LedgEntryRemainingAmount := OutstandingBankTransaction.GetRemainingAmount(BankAccountLedgerEntry."Entry No.");
                        if LedgEntryRemainingAmount = 0 then
                            LedgEntryRemainingAmount := BankAccountLedgerEntry.Amount;

                        RemainingAmt := LedgEntryRemainingAmount - OutstandingBankTransaction.GetAppliedAmount(BankAccountLedgerEntry."Entry No.");
                        if RemainingAmt <> 0 then
                            OutstandingBankTransaction.CopyFromBankAccLedgerEntry(BankAccountLedgerEntry,
                              OutstandingBankTransaction.Type::"Bank Account Ledger Entry",
                              "Bank Acc. Reconciliation"."Statement Type".AsInteger(), "Bank Acc. Reconciliation"."Statement No.", RemainingAmt)
                    end;
            until BankAccountLedgerEntry.Next() = 0;
    end;

    local procedure GetPaymentReconciliationAppliedAmount(BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"): Decimal
    var
        AppliedPaymentEntry: Record "Applied Payment Entry";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        AppliedAmountTemp: Decimal;
    begin
        AppliedPaymentEntry.SetRange("Statement Type", BankAccReconciliationLine."Statement Type");
        AppliedPaymentEntry.SetRange("Bank Account No.", BankAccReconciliationLine."Bank Account No.");
        AppliedPaymentEntry.SetRange("Statement No.", BankAccReconciliationLine."Statement No.");
        AppliedPaymentEntry.SetRange("Statement Line No.", BankAccReconciliationLine."Statement Line No.");
        if AppliedPaymentEntry.FindSet() then
            repeat
                if AppliedPaymentEntry."Applies-to Entry No." = 0 then
                    AppliedAmountTemp += AppliedPaymentEntry."Applied Amount"
                else
                    case AppliedPaymentEntry."Account Type" of
                        AppliedPaymentEntry."Account Type"::Customer:
                            if CustLedgerEntry.Get(AppliedPaymentEntry."Applies-to Entry No.") then begin
                                if not CustLedgerEntry.Open then
                                    AddError(
                                        StrSubstNo(
                                        TableValueWrongErr,
                                        CustLedgerEntry.FieldCaption(Open), true,
                                        CustLedgerEntry.TableCaption(), CustLedgerEntry."Entry No."));
                                CustLedgerEntry.CalcFields(Amount);
                                if Abs(AppliedPaymentEntry."Applied Amount") > Abs(CustLedgerEntry.Amount) then
                                    AddError(StrSubstNo(AmountWrongErr, AppliedPaymentEntry.FieldCaption("Applied Amount"), CustLedgerEntry.Amount));
                                AppliedAmountTemp += AppliedPaymentEntry."Applied Amount";
                            end else
                                AddError(
                                    StrSubstNo(
                                        TableValueMissingErr,
                                        CustLedgerEntry.TableCaption(),
                                        AppliedPaymentEntry."Applies-to Entry No."));
                        AppliedPaymentEntry."Account Type"::Vendor:
                            if VendorLedgerEntry.Get(AppliedPaymentEntry."Applies-to Entry No.") then begin
                                if not VendorLedgerEntry.Open then
                                    AddError(
                                        StrSubstNo(
                                            TableValueWrongErr,
                                            VendorLedgerEntry.FieldCaption(Open), true,
                                            VendorLedgerEntry.TableCaption(), VendorLedgerEntry."Entry No."));
                                VendorLedgerEntry.CalcFields(Amount);
                                if Abs(AppliedPaymentEntry."Applied Amount") > Abs(VendorLedgerEntry.Amount) then
                                    AddError(StrSubstNo(AmountWrongErr, AppliedPaymentEntry.FieldCaption("Applied Amount"), VendorLedgerEntry.Amount));
                                AppliedAmountTemp += AppliedPaymentEntry."Applied Amount";
                            end else
                                AddError(
                                    StrSubstNo(
                                    TableValueMissingErr,
                                    VendorLedgerEntry.TableCaption(),
                                    AppliedPaymentEntry."Applies-to Entry No."));
                        AppliedPaymentEntry."Account Type"::"Bank Account":
                            if BankAccountLedgerEntry.Get(AppliedPaymentEntry."Applies-to Entry No.") then begin
                                if not BankAccountLedgerEntry.Open then
                                    AddError(
                                        StrSubstNo(
                                        TableValueWrongErr,
                                        BankAccountLedgerEntry.FieldCaption(Open), true,
                                        BankAccountLedgerEntry.TableCaption(), BankAccountLedgerEntry."Entry No."));
                                AppliedAmountTemp += AppliedPaymentEntry."Applied Amount";
                            end else
                                AddError(
                                    StrSubstNo(
                                        TableValueMissingErr,
                                        BankAccountLedgerEntry.TableCaption(),
                                        AppliedPaymentEntry."Applies-to Entry No."));
                    end;
            until AppliedPaymentEntry.Next() = 0;
        exit(AppliedAmountTemp);
    end;

    local procedure VerifyCheckLedgerEntry(BankAccountLedgerEntry: Record "Bank Account Ledger Entry")
    begin
        CheckLedgEntry.Reset();
        CheckLedgEntry.SetCurrentKey("Bank Account Ledger Entry No.");
        CheckLedgEntry.SetRange("Bank Account Ledger Entry No.", BankAccountLedgerEntry."Entry No.");
        CheckLedgEntry.SetRange(Open, true);
        if not CheckLedgEntry.IsEmpty() then begin
            CheckLedgEntry.FindSet();
            repeat
                if not CheckLedgEntry.Open then
                    AddError(
                      StrSubstNo(
                        TableValueWrongErr,
                        CheckLedgEntry.FieldCaption(Open), true,
                        CheckLedgEntry.TableCaption(), CheckLedgEntry."Entry No."));
                if (CheckLedgEntry."Statement Status" <> CheckLedgEntry."Statement Status"::"Bank Acc. Entry Applied") and
                   (CheckLedgEntry."Statement Status" <> CheckLedgEntry."Statement Status"::"Check Entry Applied") then
                    AddError(
                      StrSubstNo(
                        TableValueWrongErr,
                        CheckLedgEntry.FieldCaption("Statement Status"),
                        CheckLedgEntry."Statement Status"::"Bank Acc. Entry Applied",
                        CheckLedgEntry.TableCaption(), CheckLedgEntry."Entry No."));
                if CheckLedgEntry."Statement No." = '' then
                    AddError(
                      StrSubstNo(
                        TableValueEmptyErr,
                        CheckLedgEntry.FieldCaption("Statement No."),
                        CheckLedgEntry.TableCaption(), CheckLedgEntry."Entry No."));
                if CheckLedgEntry."Statement Line No." = 0 then
                    AddError(
                      StrSubstNo(
                        TableValueEmptyErr,
                        CheckLedgEntry.FieldCaption("Statement Line No."),
                        CheckLedgEntry.TableCaption(), CheckLedgEntry."Entry No."));
            until CheckLedgEntry.Next() = 0;
        end;
    end;

    local procedure SetupRecord()
    begin
        "Bank Acc. Reconciliation".CalcFields(
            "Total Balance on Bank Account",
            "Bank Account Balance (LCY)",
            "Total Positive Adjustments",
            "Total Negative Adjustments",
            "Total Outstd Bank Transactions",
            "Total Outstd Payments",
            "Total Applied Amount",
            "Total Unposted Applied Amount");
    end;

    local procedure CheckForDirectEntries(BankAcc: Record "Bank Account"; BankAccPostingGroup: Record "Bank Account Posting Group"; StatementDate: Date)
    var
        GLAccount: Record "G/L Account";
        GLEntries: Record "G/L Entry";
    begin
        if BankAccPostingGroup."G/L Account No." = '' then
            exit;
        if not GLAccount.Get(BankAccPostingGroup."G/L Account No.") then
            exit;
        GLEntries.SetRange("G/L Account No.", BankAccPostingGroup."G/L Account No.");
        if (StatementDate <> 0D) then
            GLEntries.SetFilter("Posting Date", '<= %1', StatementDate);
        GLEntries.SetFilter("Source No.", ''''' |<>%1', BankAcc."No.");
        if not GLEntries.IsEmpty() then
            HeaderError3 := StrSubstNo(PotentialUnstabilityDueToDirectPostingEntriesLbl, DirectPostingURLLinkLbl);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBankAccReconciliationLineAfterGetRecordOnAfterBankAccLedgEntrySetFilters(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; var BankAccLedgEntry: Record "Bank Account Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckAppliedAmount(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; AppliedAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitReport(var ShouldShowOutstandingBankTransactions: Boolean)
    begin
    end;
}

