// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Reports;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using System.Utilities;
using System.Globalization;

report 33 "Reconcile Cust. and Vend. Accs"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Finance/GeneralLedger/Reports/ReconcileCustandVendAccs.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Reconcile Customer and Vendor Accounts';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("G/L Account"; "G/L Account")
        {
            DataItemTableView = sorting("No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "Date Filter";
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(GLAccountTableCaption; TableCaption + ': ' + GLFilter)
            {
            }
            column(GLFilter; GLFilter)
            {
            }
            column(No_GLAccount; "No.")
            {
            }
            column(Name_GLAccount; Name)
            {
            }
            column(ReconcileCustVendAccCaption; ReconcileCustVendAccCaptionLbl)
            {
            }
            column(PageNoCaption; PageNoCaptionLbl)
            {
            }
            column(NetChange_GLAccountCaption; NetChange_GLAccountCaptionLbl)
            {
            }
            column(IndirectlyPostedAmtCaption; IndirectlyPostedAmtCaptionLbl)
            {
            }
            column(PostingGrpCaption; PostingGrpCaptionLbl)
            {
            }
            column(CurrCodeCaption; CurrCodeCaptionLbl)
            {
            }
            column(TypeCaption; TypeCaptionLbl)
            {
            }
            column(NameCaption; NameCaptionLbl)
            {
            }
            column(No_GLAccountCaption; No_GLAccountCaptionLbl)
            {
            }
            column(DifferenceCaption; DifferenceCaptionLbl)
            {
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                column(ReconCustVendBufferCurrcode; ReconCustVendBuffer."Currency code")
                {
                }
                column(Amount; Amount)
                {
                    AutoFormatType = 1;
                }
                column(AccountType; AccountType)
                {
                }
                column(GetTableName; GetTableName())
                {
                }
                column(ReconCustVendBufferPostingGroup; ReconCustVendBuffer."Posting Group")
                {
                }
                column(NetChange_GLAccount; "G/L Account"."Net Change")
                {
                }

                trigger OnAfterGetRecord()
                var
                    Currency: Record Currency;
                    CustPostingGr: Record "Customer Posting Group";
                    VendPostingGr: Record "Vendor Posting Group";
                    DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
                    DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
                    Found: Boolean;
                begin
                    AmountTotal := AmountTotal + Amount;
                    Amount := 0;
                    Found := false;

                    if Number = 1 then
                        Found := ReconCustVendBuffer.Find('-')
                    else
                        Found := ReconCustVendBuffer.Next() <> 0;

                    if not Found then
                        CurrReport.Break();

                    case true of
                        (ReconCustVendBuffer."Table ID" = DATABASE::"Customer Posting Group") and
                        (ReconCustVendBuffer."Field No." = CustPostingGr.FieldNo("Receivables Account")):
                            begin
                                AccountType := CustPostingGr.FieldCaption("Receivables Account");
                                Amount := CalcCustAccAmount(ReconCustVendBuffer."Posting Group");
                            end;
                        (ReconCustVendBuffer."Table ID" = DATABASE::"Customer Posting Group") and
                        (ReconCustVendBuffer."Field No." = CustPostingGr.FieldNo("Payment Disc. Debit Acc.")):
                            begin
                                AccountType := CustPostingGr.FieldCaption("Payment Disc. Debit Acc.");
                                Amount :=
                                  CalcCustCreditAmount(ReconCustVendBuffer."Posting Group", DtldCustLedgEntry."Entry Type"::"Payment Discount");
                            end;
                        (ReconCustVendBuffer."Table ID" = DATABASE::"Customer Posting Group") and
                        (ReconCustVendBuffer."Field No." = CustPostingGr.FieldNo("Payment Disc. Credit Acc.")):
                            begin
                                AccountType := CustPostingGr.FieldCaption("Payment Disc. Credit Acc.");
                                Amount :=
                                  CalcCustDebitAmount(ReconCustVendBuffer."Posting Group", DtldCustLedgEntry."Entry Type"::"Payment Discount");
                            end;
                        (ReconCustVendBuffer."Table ID" = DATABASE::"Customer Posting Group") and
                        (ReconCustVendBuffer."Field No." = CustPostingGr.FieldNo("Payment Tolerance Debit Acc.")):
                            begin
                                AccountType := CustPostingGr.FieldCaption("Payment Tolerance Debit Acc.");
                                Amount :=
                                  CalcCustCreditAmount(ReconCustVendBuffer."Posting Group", DtldCustLedgEntry."Entry Type"::"Payment Tolerance") +
                                  CalcCustCreditAmount(ReconCustVendBuffer."Posting Group", DtldCustLedgEntry."Entry Type"::"Payment Discount Tolerance");
                            end;
                        (ReconCustVendBuffer."Table ID" = DATABASE::"Customer Posting Group") and
                        (ReconCustVendBuffer."Field No." = CustPostingGr.FieldNo("Payment Tolerance Credit Acc.")):
                            begin
                                AccountType := CustPostingGr.FieldCaption("Payment Tolerance Credit Acc.");
                                Amount :=
                                  CalcCustDebitAmount(ReconCustVendBuffer."Posting Group", DtldCustLedgEntry."Entry Type"::"Payment Tolerance") +
                                  CalcCustDebitAmount(ReconCustVendBuffer."Posting Group", DtldCustLedgEntry."Entry Type"::"Payment Discount Tolerance");
                            end;
                        (ReconCustVendBuffer."Table ID" = DATABASE::"Customer Posting Group") and
                        (ReconCustVendBuffer."Field No." = CustPostingGr.FieldNo("Debit Curr. Appln. Rndg. Acc.")):
                            begin
                                AccountType := CustPostingGr.FieldCaption("Debit Curr. Appln. Rndg. Acc.");
                                Amount :=
                                  CalcCustCreditAmount(ReconCustVendBuffer."Posting Group", DtldCustLedgEntry."Entry Type"::"Appln. Rounding");
                            end;
                        (ReconCustVendBuffer."Table ID" = DATABASE::"Customer Posting Group") and
                        (ReconCustVendBuffer."Field No." = CustPostingGr.FieldNo("Credit Curr. Appln. Rndg. Acc.")):
                            begin
                                AccountType := CustPostingGr.FieldCaption("Credit Curr. Appln. Rndg. Acc.");
                                Amount :=
                                  CalcCustDebitAmount(ReconCustVendBuffer."Posting Group", DtldCustLedgEntry."Entry Type"::"Appln. Rounding");
                            end;
                        (ReconCustVendBuffer."Table ID" = DATABASE::"Customer Posting Group") and
                        (ReconCustVendBuffer."Field No." = CustPostingGr.FieldNo("Debit Rounding Account")):
                            begin
                                AccountType := CustPostingGr.FieldCaption("Debit Rounding Account");
                                Amount :=
                                  CalcCustCreditAmount(
                                    ReconCustVendBuffer."Posting Group", DtldCustLedgEntry."Entry Type"::"Correction of Remaining Amount");
                            end;
                        (ReconCustVendBuffer."Table ID" = DATABASE::"Customer Posting Group") and
                        (ReconCustVendBuffer."Field No." = CustPostingGr.FieldNo("Credit Rounding Account")):
                            begin
                                AccountType := CustPostingGr.FieldCaption("Credit Rounding Account");
                                Amount :=
                                  CalcCustDebitAmount(
                                    ReconCustVendBuffer."Posting Group", DtldCustLedgEntry."Entry Type"::"Correction of Remaining Amount");
                            end;
                        (ReconCustVendBuffer."Table ID" = DATABASE::"Vendor Posting Group") and
                        (ReconCustVendBuffer."Field No." = VendPostingGr.FieldNo("Payables Account")):
                            begin
                                AccountType := VendPostingGr.FieldCaption("Payables Account");
                                Amount := CalcVendAccAmount(ReconCustVendBuffer."Posting Group");
                            end;
                        (ReconCustVendBuffer."Table ID" = DATABASE::"Vendor Posting Group") and
                        (ReconCustVendBuffer."Field No." = VendPostingGr.FieldNo("Payment Disc. Debit Acc.")):
                            begin
                                AccountType := VendPostingGr.FieldCaption("Payment Disc. Debit Acc.");
                                Amount :=
                                  CalcVendCreditAmount(ReconCustVendBuffer."Posting Group", DtldVendLedgEntry."Entry Type"::"Payment Discount");
                            end;
                        (ReconCustVendBuffer."Table ID" = DATABASE::"Vendor Posting Group") and
                        (ReconCustVendBuffer."Field No." = VendPostingGr.FieldNo("Payment Disc. Credit Acc.")):
                            begin
                                AccountType := VendPostingGr.FieldCaption("Payment Disc. Credit Acc.");
                                Amount :=
                                  CalcVendDebitAmount(ReconCustVendBuffer."Posting Group", DtldVendLedgEntry."Entry Type"::"Payment Discount");
                            end;
                        (ReconCustVendBuffer."Table ID" = DATABASE::"Vendor Posting Group") and
                        (ReconCustVendBuffer."Field No." = VendPostingGr.FieldNo("Payment Tolerance Debit Acc.")):
                            begin
                                AccountType := VendPostingGr.FieldCaption("Payment Tolerance Debit Acc.");
                                Amount :=
                                  CalcVendDebitAmount(ReconCustVendBuffer."Posting Group", DtldVendLedgEntry."Entry Type"::"Payment Tolerance") +
                                  CalcVendDebitAmount(ReconCustVendBuffer."Posting Group", DtldVendLedgEntry."Entry Type"::"Payment Discount Tolerance");
                            end;
                        (ReconCustVendBuffer."Table ID" = DATABASE::"Vendor Posting Group") and
                        (ReconCustVendBuffer."Field No." = VendPostingGr.FieldNo("Payment Tolerance Credit Acc.")):
                            begin
                                AccountType := VendPostingGr.FieldCaption("Payment Tolerance Credit Acc.");
                                Amount :=
                                  CalcVendCreditAmount(ReconCustVendBuffer."Posting Group", DtldVendLedgEntry."Entry Type"::"Payment Tolerance") +
                                  CalcVendCreditAmount(ReconCustVendBuffer."Posting Group", DtldVendLedgEntry."Entry Type"::"Payment Discount Tolerance");
                            end;
                        (ReconCustVendBuffer."Table ID" = DATABASE::"Vendor Posting Group") and
                        (ReconCustVendBuffer."Field No." = VendPostingGr.FieldNo("Debit Curr. Appln. Rndg. Acc.")):
                            begin
                                AccountType := VendPostingGr.FieldCaption("Debit Curr. Appln. Rndg. Acc.");
                                Amount :=
                                  CalcVendCreditAmount(ReconCustVendBuffer."Posting Group", DtldVendLedgEntry."Entry Type"::"Appln. Rounding");
                            end;
                        (ReconCustVendBuffer."Table ID" = DATABASE::"Vendor Posting Group") and
                        (ReconCustVendBuffer."Field No." = VendPostingGr.FieldNo("Credit Curr. Appln. Rndg. Acc.")):
                            begin
                                AccountType := VendPostingGr.FieldCaption("Credit Curr. Appln. Rndg. Acc.");
                                Amount :=
                                  CalcVendDebitAmount(ReconCustVendBuffer."Posting Group", DtldVendLedgEntry."Entry Type"::"Appln. Rounding");
                            end;
                        (ReconCustVendBuffer."Table ID" = DATABASE::"Vendor Posting Group") and
                        (ReconCustVendBuffer."Field No." = VendPostingGr.FieldNo("Debit Rounding Account")):
                            begin
                                AccountType := VendPostingGr.FieldCaption("Debit Rounding Account");
                                Amount :=
                                  CalcVendCreditAmount(
                                    ReconCustVendBuffer."Posting Group", DtldVendLedgEntry."Entry Type"::"Correction of Remaining Amount");
                            end;
                        (ReconCustVendBuffer."Table ID" = DATABASE::"Vendor Posting Group") and
                        (ReconCustVendBuffer."Field No." = VendPostingGr.FieldNo("Credit Rounding Account")):
                            begin
                                AccountType := VendPostingGr.FieldCaption("Credit Rounding Account");
                                Amount :=
                                  CalcVendDebitAmount(
                                    ReconCustVendBuffer."Posting Group", DtldVendLedgEntry."Entry Type"::"Correction of Remaining Amount");
                            end;
                        (ReconCustVendBuffer."Table ID" = DATABASE::Currency) and
                        (ReconCustVendBuffer."Field No." = Currency.FieldNo("Unrealized Gains Acc.")):
                            begin
                                AccountType := Currency.FieldCaption("Unrealized Gains Acc.");
                                Amount :=
                                  CalcCurrGainLossAmount(ReconCustVendBuffer."Currency code", DtldVendLedgEntry."Entry Type"::"Unrealized Gain");
                            end;
                        (ReconCustVendBuffer."Table ID" = DATABASE::Currency) and
                        (ReconCustVendBuffer."Field No." = Currency.FieldNo("Realized Gains Acc.")):
                            begin
                                AccountType := Currency.FieldCaption("Realized Gains Acc.");
                                Amount :=
                                  CalcCurrGainLossAmount(ReconCustVendBuffer."Currency code", DtldVendLedgEntry."Entry Type"::"Realized Gain");
                            end;
                        (ReconCustVendBuffer."Table ID" = DATABASE::Currency) and
                        (ReconCustVendBuffer."Field No." = Currency.FieldNo("Unrealized Losses Acc.")):
                            begin
                                AccountType := Currency.FieldCaption("Unrealized Losses Acc.");
                                Amount :=
                                  CalcCurrGainLossAmount(ReconCustVendBuffer."Currency code", DtldVendLedgEntry."Entry Type"::"Unrealized Loss");
                            end;
                        (ReconCustVendBuffer."Table ID" = DATABASE::Currency) and
                        (ReconCustVendBuffer."Field No." = Currency.FieldNo("Realized Losses Acc.")):
                            begin
                                AccountType := Currency.FieldCaption("Realized Losses Acc.");
                                Amount :=
                                  CalcCurrGainLossAmount(ReconCustVendBuffer."Currency code", DtldVendLedgEntry."Entry Type"::"Realized Loss");
                            end;
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    ReconCustVendBuffer.SetCurrentKey("G/L Account No.");
                    ReconCustVendBuffer.SetRange("G/L Account No.", "G/L Account"."No.");
                end;
            }

            trigger OnAfterGetRecord()
            begin
                AmountTotal := 0;
                CalcFields("Net Change")
            end;

            trigger OnPreDataItem()
            var
                Currency: Record Currency;
                CustPostingGr: Record "Customer Posting Group";
                VendPostingGr: Record "Vendor Posting Group";
            begin
                if CustPostingGr.Find('-') then begin
                    Clear(ReconCustVendBuffer);
                    repeat
                        ReconCustVendBuffer."Table ID" := DATABASE::"Customer Posting Group";
                        ReconCustVendBuffer."Posting Group" := CustPostingGr.Code;

                        ReconCustVendBuffer."Field No." := CustPostingGr.FieldNo("Receivables Account");
                        ReconCustVendBuffer."G/L Account No." := CustPostingGr."Receivables Account";
                        ReconCustVendBuffer.Insert();

                        ReconCustVendBuffer."Field No." := CustPostingGr.FieldNo("Payment Disc. Debit Acc.");
                        ReconCustVendBuffer."G/L Account No." := CustPostingGr."Payment Disc. Debit Acc.";
                        ReconCustVendBuffer.Insert();

                        ReconCustVendBuffer."Field No." := CustPostingGr.FieldNo("Payment Disc. Credit Acc.");
                        ReconCustVendBuffer."G/L Account No." := CustPostingGr."Payment Disc. Credit Acc.";
                        ReconCustVendBuffer.Insert();

                        ReconCustVendBuffer."Field No." := CustPostingGr.FieldNo("Payment Tolerance Debit Acc.");
                        ReconCustVendBuffer."G/L Account No." := CustPostingGr."Payment Tolerance Debit Acc.";
                        ReconCustVendBuffer.Insert();

                        ReconCustVendBuffer."Field No." := CustPostingGr.FieldNo("Payment Tolerance Credit Acc.");
                        ReconCustVendBuffer."G/L Account No." := CustPostingGr."Payment Tolerance Credit Acc.";
                        ReconCustVendBuffer.Insert();

                        ReconCustVendBuffer."Field No." := CustPostingGr.FieldNo("Debit Curr. Appln. Rndg. Acc.");
                        ReconCustVendBuffer."G/L Account No." := CustPostingGr."Debit Curr. Appln. Rndg. Acc.";
                        ReconCustVendBuffer.Insert();

                        ReconCustVendBuffer."Field No." := CustPostingGr.FieldNo("Credit Curr. Appln. Rndg. Acc.");
                        ReconCustVendBuffer."G/L Account No." := CustPostingGr."Credit Curr. Appln. Rndg. Acc.";
                        ReconCustVendBuffer.Insert();

                        ReconCustVendBuffer."Field No." := CustPostingGr.FieldNo("Debit Rounding Account");
                        ReconCustVendBuffer."G/L Account No." := CustPostingGr."Debit Rounding Account";
                        ReconCustVendBuffer.Insert();

                        ReconCustVendBuffer."Field No." := CustPostingGr.FieldNo("Credit Rounding Account");
                        ReconCustVendBuffer."G/L Account No." := CustPostingGr."Credit Rounding Account";
                        ReconCustVendBuffer.Insert();

                    until CustPostingGr.Next() = 0;
                end;

                if VendPostingGr.Find('-') then begin
                    Clear(ReconCustVendBuffer);
                    repeat
                        ReconCustVendBuffer."Table ID" := DATABASE::"Vendor Posting Group";
                        ReconCustVendBuffer."Posting Group" := VendPostingGr.Code;

                        ReconCustVendBuffer."Field No." := VendPostingGr.FieldNo("Payables Account");
                        ReconCustVendBuffer."G/L Account No." := VendPostingGr."Payables Account";
                        ReconCustVendBuffer.Insert();

                        ReconCustVendBuffer."Field No." := VendPostingGr.FieldNo("Payment Disc. Debit Acc.");
                        ReconCustVendBuffer."G/L Account No." := VendPostingGr."Payment Disc. Debit Acc.";
                        ReconCustVendBuffer.Insert();

                        ReconCustVendBuffer."Field No." := VendPostingGr.FieldNo("Payment Disc. Credit Acc.");
                        ReconCustVendBuffer."G/L Account No." := VendPostingGr."Payment Disc. Credit Acc.";
                        ReconCustVendBuffer.Insert();

                        ReconCustVendBuffer."Field No." := VendPostingGr.FieldNo("Payment Tolerance Debit Acc.");
                        ReconCustVendBuffer."G/L Account No." := VendPostingGr."Payment Tolerance Debit Acc.";
                        ReconCustVendBuffer.Insert();

                        ReconCustVendBuffer."Field No." := VendPostingGr.FieldNo("Payment Tolerance Credit Acc.");
                        ReconCustVendBuffer."G/L Account No." := VendPostingGr."Payment Tolerance Credit Acc.";
                        ReconCustVendBuffer.Insert();

                        ReconCustVendBuffer."Field No." := VendPostingGr.FieldNo("Debit Curr. Appln. Rndg. Acc.");
                        ReconCustVendBuffer."G/L Account No." := VendPostingGr."Debit Curr. Appln. Rndg. Acc.";
                        ReconCustVendBuffer.Insert();

                        ReconCustVendBuffer."Field No." := VendPostingGr.FieldNo("Credit Curr. Appln. Rndg. Acc.");
                        ReconCustVendBuffer."G/L Account No." := VendPostingGr."Credit Curr. Appln. Rndg. Acc.";
                        ReconCustVendBuffer.Insert();

                        ReconCustVendBuffer."Field No." := VendPostingGr.FieldNo("Debit Rounding Account");
                        ReconCustVendBuffer."G/L Account No." := VendPostingGr."Debit Rounding Account";
                        ReconCustVendBuffer.Insert();

                        ReconCustVendBuffer."Field No." := VendPostingGr.FieldNo("Credit Rounding Account");
                        ReconCustVendBuffer."G/L Account No." := VendPostingGr."Credit Rounding Account";
                        ReconCustVendBuffer.Insert();

                    until VendPostingGr.Next() = 0;
                end;

                if Currency.Find('-') then begin
                    Clear(ReconCustVendBuffer);
                    repeat
                        ReconCustVendBuffer."Table ID" := DATABASE::Currency;
                        ReconCustVendBuffer."Currency code" := Currency.Code;

                        ReconCustVendBuffer."Field No." := Currency.FieldNo("Unrealized Gains Acc.");
                        ReconCustVendBuffer."G/L Account No." := Currency."Unrealized Gains Acc.";
                        ReconCustVendBuffer.Insert();

                        ReconCustVendBuffer."Field No." := Currency.FieldNo("Realized Gains Acc.");
                        ReconCustVendBuffer."G/L Account No." := Currency."Realized Gains Acc.";
                        ReconCustVendBuffer.Insert();

                        ReconCustVendBuffer."Field No." := Currency.FieldNo("Unrealized Losses Acc.");
                        ReconCustVendBuffer."G/L Account No." := Currency."Unrealized Losses Acc.";
                        ReconCustVendBuffer.Insert();

                        ReconCustVendBuffer."Field No." := Currency.FieldNo("Realized Losses Acc.");
                        ReconCustVendBuffer."G/L Account No." := Currency."Realized Losses Acc.";
                        ReconCustVendBuffer.Insert();

                    until Currency.Next() = 0;
                end;

                if ReconCustVendBuffer.Find('-') then begin
                    repeat
                        "No." := ReconCustVendBuffer."G/L Account No.";
                        Mark(true);
                    until ReconCustVendBuffer.Next() = 0;
                    MarkedOnly(true);
                end else
                    CurrReport.Break();
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Reconcile Customer and Vendor Accounts';
        AboutText = 'Understand the difference in net change to control the G/L accounts setup on customer and vendor posting group tables. Highlight discrepancies between G/L and customer/vendor ledger balances.';

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
        GLFilter := "G/L Account".GetFilters();
    end;

    var
        GLFilter: Text;
        ReconcileCustVendAccCaptionLbl: Label 'Reconcile Customer and Vendor Accounts';
        PageNoCaptionLbl: Label 'Page';
        NetChange_GLAccountCaptionLbl: Label 'G/L Account Net Change';
        IndirectlyPostedAmtCaptionLbl: Label 'Indirectly Posted Amount';
        PostingGrpCaptionLbl: Label 'Posting Group';
        CurrCodeCaptionLbl: Label 'Currency Code';
        TypeCaptionLbl: Label 'Type';
        NameCaptionLbl: Label 'Name';
        No_GLAccountCaptionLbl: Label 'Account No.';
        DifferenceCaptionLbl: Label 'Difference';

    protected var
        ReconCustVendBuffer: Record "Reconcile CV Acc Buffer" temporary;
        Amount: Decimal;
        AmountTotal: Decimal;
        AccountType: Text[1024];

    local procedure CalcCustAccAmount(PostingGr: Code[20]): Decimal
    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        CustAccAmount: Decimal;
    begin
        DtldCustLedgEntry.SetCurrentKey("Posting Group", "Posting Date");
        DtldCustLedgEntry.SetRange("Posting Group", PostingGr);
        "G/L Account".CopyFilter("Date Filter", DtldCustLedgEntry."Posting Date");
        DtldCustLedgEntry.CalcSums("Amount (LCY)");
        CustAccAmount := CustAccAmount + DtldCustLedgEntry."Amount (LCY)";

        exit(CustAccAmount);
    end;

    local procedure CalcCustCreditAmount(PostingGr: Code[20]; EntryType: Enum "Detailed CV Ledger Entry Type"): Decimal
    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        CustCreditAmount: Decimal;
    begin
        DtldCustLedgEntry.SetCurrentKey("Posting Group", "Posting Date", "Entry Type");
        DtldCustLedgEntry.SetRange("Posting Group", PostingGr);
        DtldCustLedgEntry.SetRange("Entry Type", EntryType);
        "G/L Account".CopyFilter("Date Filter", DtldCustLedgEntry."Posting Date");
        DtldCustLedgEntry.CalcSums("Credit Amount (LCY)");
        CustCreditAmount := CustCreditAmount + DtldCustLedgEntry."Credit Amount (LCY)";

        exit(CustCreditAmount);
    end;

    local procedure CalcCustDebitAmount(PostingGr: Code[20]; EntryType: Enum "Detailed CV Ledger Entry Type"): Decimal
    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        CustDebitAmount: Decimal;
    begin
        DtldCustLedgEntry.SetCurrentKey("Posting Group", "Posting Date", "Entry Type");
        DtldCustLedgEntry.SetRange("Posting Group", PostingGr);
        DtldCustLedgEntry.SetRange("Entry Type", EntryType);
        "G/L Account".CopyFilter("Date Filter", DtldCustLedgEntry."Posting Date");
        DtldCustLedgEntry.CalcSums("Debit Amount (LCY)");
        CustDebitAmount := CustDebitAmount + DtldCustLedgEntry."Debit Amount (LCY)";

        exit(-CustDebitAmount);
    end;

    local procedure CalcVendAccAmount(PostingGr: Code[20]): Decimal
    var
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        VendAccAmount: Decimal;
    begin
        DtldVendLedgEntry.SetCurrentKey("Posting Group", "Posting Date");
        DtldVendLedgEntry.SetRange("Posting Group", PostingGr);
        "G/L Account".CopyFilter("Date Filter", DtldVendLedgEntry."Posting Date");
        DtldVendLedgEntry.CalcSums("Amount (LCY)");
        VendAccAmount := VendAccAmount + DtldVendLedgEntry."Amount (LCY)";

        exit(VendAccAmount);
    end;

    local procedure CalcVendCreditAmount(PostingGr: Code[20]; EntryType: Enum "Detailed CV Ledger Entry Type"): Decimal
    var
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        VendCreditAmount: Decimal;
    begin
        DtldVendLedgEntry.SetCurrentKey("Posting Group", "Posting Date", "Entry Type");
        DtldVendLedgEntry.SetRange("Posting Group", PostingGr);
        DtldVendLedgEntry.SetRange("Entry Type", EntryType);
        "G/L Account".CopyFilter("Date Filter", DtldVendLedgEntry."Posting Date");
        DtldVendLedgEntry.CalcSums("Credit Amount (LCY)");
        VendCreditAmount := VendCreditAmount + DtldVendLedgEntry."Credit Amount (LCY)";

        exit(VendCreditAmount);
    end;

    local procedure CalcVendDebitAmount(PostingGr: Code[20]; EntryType: Enum "Detailed CV Ledger Entry Type"): Decimal
    var
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        VendDebitAmount: Decimal;
    begin
        DtldVendLedgEntry.SetCurrentKey("Posting Group", "Posting Date", "Entry Type");
        DtldVendLedgEntry.SetRange("Posting Group", PostingGr);
        DtldVendLedgEntry.SetRange("Entry Type", EntryType);
        "G/L Account".CopyFilter("Date Filter", DtldVendLedgEntry."Posting Date");
        DtldVendLedgEntry.CalcSums("Debit Amount (LCY)");
        VendDebitAmount := VendDebitAmount + DtldVendLedgEntry."Debit Amount (LCY)";

        exit(-VendDebitAmount);
    end;

    local procedure CalcCurrGainLossAmount(CurrencyCode: Code[20]; EntryType: Enum "Detailed CV Ledger Entry Type"): Decimal
    var
        Cust: Record Customer;
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        Vend: Record Vendor;
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        CurrGainLossAmount: Decimal;
    begin
        if Cust.Find('-') then
            repeat
                DtldCustLedgEntry.SetCurrentKey("Customer No.", "Posting Date", "Entry Type", "Currency Code");
                DtldCustLedgEntry.SetRange("Customer No.", Cust."No.");
                DtldCustLedgEntry.SetRange("Entry Type", EntryType);
                DtldCustLedgEntry.SetRange("Currency Code", CurrencyCode);
                "G/L Account".CopyFilter("Date Filter", DtldCustLedgEntry."Posting Date");
                DtldCustLedgEntry.CalcSums("Amount (LCY)");
                CurrGainLossAmount := CurrGainLossAmount + DtldCustLedgEntry."Amount (LCY)";
            until Cust.Next() = 0;

        if Vend.Find('-') then
            repeat
                DtldVendLedgEntry.SetCurrentKey("Vendor No.", "Posting Date", "Entry Type", "Currency Code");
                DtldVendLedgEntry.SetRange("Vendor No.", Vend."No.");
                DtldVendLedgEntry.SetRange("Entry Type", EntryType);
                DtldVendLedgEntry.SetRange("Currency Code", CurrencyCode);
                "G/L Account".CopyFilter("Date Filter", DtldVendLedgEntry."Posting Date");
                DtldVendLedgEntry.CalcSums("Amount (LCY)");
                CurrGainLossAmount := CurrGainLossAmount + DtldVendLedgEntry."Amount (LCY)";
            until Vend.Next() = 0;

        exit(-CurrGainLossAmount);
    end;

    local procedure GetTableName(): Text[100]
    var
        ObjTransl: Record "Object Translation";
    begin
        exit(ObjTransl.TranslateObject(ObjTransl."Object Type"::Table, ReconCustVendBuffer."Table ID"));
    end;
}

