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
using System.Globalization;
using System.Utilities;

/// <summary>
/// Reconciles customer and vendor account balances with corresponding G/L account balances for audit and validation purposes.
/// Provides detailed analysis of posting group account mappings and identifies balance discrepancies between subsidiary and general ledgers.
/// </summary>
/// <remarks>
/// Data sources: G/L Account, Customer/Vendor Posting Groups, Currency, and CV Ledger Entry tables.
/// Analyzes receivables accounts, payables accounts, payment discount accounts, tolerance accounts, and rounding accounts.
/// Critical for month-end reconciliation procedures, audit preparation, and maintaining subsidiary ledger integrity.
/// </remarks>
report 33 "Reconcile Cust. and Vend. Accs"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Reconcile Customer and Vendor Accounts';
    ToolTip = 'View if a certain general ledger account reconciles the balance on a certain date for the corresponding posting group. The report shows the accounts that are included in the reconciliation with the general ledger balance and the customer or the vendor ledger balance for each account and shows any differences between the general ledger balance and the customer or vendor ledger balance.';
    UsageCategory = ReportsAndAnalysis;
    DefaultRenderingLayout = RDLCLayout;

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
            column(GLAccTableCaptGLFilter; "G/L Account".TableCaption + ': ' + GLFilter)
            {
            }
            column(GLFilter; GLFilter)
            {
            }
            column(SimulationEntries; SimulationEntriesLbl)
            {
            }
            column(No_GLAccount; "No.")
            {
            }
            column(Name_GLAccount; Name)
            {
            }
            column(ReconcileCustomerandVendorAccountsCaption; ReconcileCustomerandVendorAccountsCaptionLbl)
            {
            }
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
            }
            column(GLAccountNetChangeCaption; GLAccountNetChangeCaptionLbl)
            {
            }
            column(AmountCaption; AmountCaptionLbl)
            {
            }
            column(ReconCustVendBufferPostingGroupCaption; ReconCustVendBufferPostingGroupCaptionLbl)
            {
            }
            column(ReconCustVendBufferCurrencycodeCaption; ReconCustVendBufferCurrencycodeCaptionLbl)
            {
            }
            column(AccountTypeCaption; AccountTypeCaptionLbl)
            {
            }
            column(GLAccountNameCaption; GLAccountNameCaptionLbl)
            {
            }
            column(GLAccountNoCaption; GLAccountNoCaptionLbl)
            {
            }
            column(AmountTotalGLAccountNetChangeCaption; AmountTotalGLAccountNetChangeCaptionLbl)
            {
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                column(ReconCustVendBuffCurrcode; ReconCustVendBuffer."Currency code")
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

    rendering
    {
        layout(RDLCLayout)
        {
            Type = RDLC;
            LayoutFile = './Finance/GeneralLedger/Reports/ReconcileCustandVendAccs.rdlc';
            Summary = 'Report layout made in the legacy RDLC format. Use an RDLC editor to modify the layout.';
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
        SimulationEntriesLbl: Label 'This report includes simulation entries.';
        ReconcileCustomerandVendorAccountsCaptionLbl: Label 'Reconcile Customer and Vendor Accounts';
        CurrReportPageNoCaptionLbl: Label 'Page';
        GLAccountNetChangeCaptionLbl: Label 'G/L Account Net Change';
        AmountCaptionLbl: Label 'Indirectly Posted Amount';
        ReconCustVendBufferPostingGroupCaptionLbl: Label 'Posting Group';
        ReconCustVendBufferCurrencycodeCaptionLbl: Label 'Currency Code';
        AccountTypeCaptionLbl: Label 'Type';
        GLAccountNameCaptionLbl: Label 'Name';
        GLAccountNoCaptionLbl: Label 'Account No.';
        AmountTotalGLAccountNetChangeCaptionLbl: Label 'Difference';

    protected var
        ReconCustVendBuffer: Record "Reconcile CV Acc Buffer" temporary;
        Amount: Decimal;
        AmountTotal: Decimal;
        AccountType: Text[1024];

    var
        CustBlankPGCachedGroups: Dictionary of [Code[20], Decimal];
        CustBlankPGCreditCache: Dictionary of [Text, Decimal];
        CustBlankPGDebitCache: Dictionary of [Text, Decimal];
        VendBlankPGCachedGroups: Dictionary of [Code[20], Decimal];
        VendBlankPGCreditCache: Dictionary of [Text, Decimal];
        VendBlankPGDebitCache: Dictionary of [Text, Decimal];

    local procedure EnsureCustBlankPGCache(PostingGr: Code[20])
    var
        ReconCustPostingGrSum: Query "Recon. Cust. Posting Gr. Sum";
        EntryTypeInt: Integer;
        CacheKey: Text;
        TotalAmount: Decimal;
    begin
        if CustBlankPGCachedGroups.ContainsKey(PostingGr) then
            exit;

        TotalAmount := 0;

        ReconCustPostingGrSum.SetRange(CustomerPostingGroup, PostingGr);
        ReconCustPostingGrSum.SetRange(PostingGroup, '');
        ReconCustPostingGrSum.SetFilter(PostingDate, "G/L Account".GetFilter("Date Filter"));
        ReconCustPostingGrSum.Open();
        while ReconCustPostingGrSum.Read() do begin
            EntryTypeInt := ReconCustPostingGrSum.EntryType.AsInteger();
            CacheKey := PostingGr + '|' + Format(EntryTypeInt);
            CustBlankPGCreditCache.Set(CacheKey, ReconCustPostingGrSum.SumCreditAmountLCY);
            CustBlankPGDebitCache.Set(CacheKey, ReconCustPostingGrSum.SumDebitAmountLCY);
            TotalAmount += ReconCustPostingGrSum.SumAmountLCY;
        end;
        ReconCustPostingGrSum.Close();

        CustBlankPGCachedGroups.Set(PostingGr, TotalAmount);
    end;

    local procedure EnsureVendBlankPGCache(PostingGr: Code[20])
    var
        ReconVendPostingGrSum: Query "Recon. Vend. Posting Gr. Sum";
        EntryTypeInt: Integer;
        CacheKey: Text;
        TotalAmount: Decimal;
    begin
        if VendBlankPGCachedGroups.ContainsKey(PostingGr) then
            exit;

        TotalAmount := 0;

        ReconVendPostingGrSum.SetRange(VendorPostingGroup, PostingGr);
        ReconVendPostingGrSum.SetRange(PostingGroup, '');
        ReconVendPostingGrSum.SetFilter(PostingDate, "G/L Account".GetFilter("Date Filter"));
        ReconVendPostingGrSum.Open();
        while ReconVendPostingGrSum.Read() do begin
            EntryTypeInt := ReconVendPostingGrSum.EntryType.AsInteger();
            CacheKey := PostingGr + '|' + Format(EntryTypeInt);
            VendBlankPGCreditCache.Set(CacheKey, ReconVendPostingGrSum.SumCreditAmountLCY);
            VendBlankPGDebitCache.Set(CacheKey, ReconVendPostingGrSum.SumDebitAmountLCY);
            TotalAmount += ReconVendPostingGrSum.SumAmountLCY;
        end;
        ReconVendPostingGrSum.Close();

        VendBlankPGCachedGroups.Set(PostingGr, TotalAmount);
    end;

    local procedure CalcCustAccAmount(PostingGr: Code[20]): Decimal
    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        CustAccAmount: Decimal;
        CachedAmount: Decimal;
    begin
        // Pass 1: detail entries explicitly stamped with this posting group (multi-posting-group customers).
        DtldCustLedgEntry.SetLoadFields("Amount (LCY)");
        DtldCustLedgEntry.SetRange("Posting Group", PostingGr);
        "G/L Account".CopyFilter("Date Filter", DtldCustLedgEntry."Posting Date");
        DtldCustLedgEntry.CalcSums("Amount (LCY)");
        CustAccAmount := DtldCustLedgEntry."Amount (LCY)";

        // Pass 2: detail entries with blank Posting Group attributed to the customer's current master
        // posting group. Uses multi-entry cached query result to avoid repeated SQL round-trips.
        EnsureCustBlankPGCache(PostingGr);
        if CustBlankPGCachedGroups.Get(PostingGr, CachedAmount) then
            CustAccAmount += CachedAmount;

        exit(CustAccAmount);
    end;

    local procedure CalcCustCreditAmount(PostingGr: Code[20]; EntryType: Enum "Detailed CV Ledger Entry Type"): Decimal
    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        CustCreditAmount: Decimal;
        CachedAmount: Decimal;
    begin
        // Pass 1: detail entries explicitly stamped with this posting group (multi-posting-group customers).
        DtldCustLedgEntry.SetLoadFields("Credit Amount (LCY)");
        DtldCustLedgEntry.SetRange("Posting Group", PostingGr);
        DtldCustLedgEntry.SetRange("Entry Type", EntryType);
        "G/L Account".CopyFilter("Date Filter", DtldCustLedgEntry."Posting Date");
        DtldCustLedgEntry.CalcSums("Credit Amount (LCY)");
        CustCreditAmount := DtldCustLedgEntry."Credit Amount (LCY)";

        // Pass 2: detail entries with blank Posting Group attributed to the customer's current master
        // posting group. Uses multi-entry cached query result to avoid repeated SQL round-trips.
        EnsureCustBlankPGCache(PostingGr);
        if CustBlankPGCreditCache.Get(PostingGr + '|' + Format(EntryType.AsInteger()), CachedAmount) then
            CustCreditAmount += CachedAmount;

        exit(CustCreditAmount);
    end;

    local procedure CalcCustDebitAmount(PostingGr: Code[20]; EntryType: Enum "Detailed CV Ledger Entry Type"): Decimal
    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        CustDebitAmount: Decimal;
        CachedAmount: Decimal;
    begin
        // Pass 1: detail entries explicitly stamped with this posting group (multi-posting-group customers).
        DtldCustLedgEntry.SetLoadFields("Debit Amount (LCY)");
        DtldCustLedgEntry.SetRange("Posting Group", PostingGr);
        DtldCustLedgEntry.SetRange("Entry Type", EntryType);
        "G/L Account".CopyFilter("Date Filter", DtldCustLedgEntry."Posting Date");
        DtldCustLedgEntry.CalcSums("Debit Amount (LCY)");
        CustDebitAmount := DtldCustLedgEntry."Debit Amount (LCY)";

        // Pass 2: detail entries with blank Posting Group attributed to the customer's current master
        // posting group. Uses multi-entry cached query result to avoid repeated SQL round-trips.
        EnsureCustBlankPGCache(PostingGr);
        if CustBlankPGDebitCache.Get(PostingGr + '|' + Format(EntryType.AsInteger()), CachedAmount) then
            CustDebitAmount += CachedAmount;

        exit(-CustDebitAmount);
    end;

    local procedure CalcVendAccAmount(PostingGr: Code[20]): Decimal
    var
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        VendAccAmount: Decimal;
        CachedAmount: Decimal;
    begin
        // Pass 1: detail entries explicitly stamped with this posting group (multi-posting-group vendors).
        DtldVendLedgEntry.SetLoadFields("Amount (LCY)");
        DtldVendLedgEntry.SetRange("Posting Group", PostingGr);
        "G/L Account".CopyFilter("Date Filter", DtldVendLedgEntry."Posting Date");
        DtldVendLedgEntry.CalcSums("Amount (LCY)");
        VendAccAmount := DtldVendLedgEntry."Amount (LCY)";

        // Pass 2: detail entries with blank Posting Group attributed to the vendor's current master
        // posting group. Uses multi-entry cached query result to avoid repeated SQL round-trips.
        EnsureVendBlankPGCache(PostingGr);
        if VendBlankPGCachedGroups.Get(PostingGr, CachedAmount) then
            VendAccAmount += CachedAmount;

        exit(VendAccAmount);
    end;

    local procedure CalcVendCreditAmount(PostingGr: Code[20]; EntryType: Enum "Detailed CV Ledger Entry Type"): Decimal
    var
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        VendCreditAmount: Decimal;
        CachedAmount: Decimal;
    begin
        // Pass 1: detail entries explicitly stamped with this posting group (multi-posting-group vendors).
        DtldVendLedgEntry.SetLoadFields("Credit Amount (LCY)");
        DtldVendLedgEntry.SetRange("Posting Group", PostingGr);
        DtldVendLedgEntry.SetRange("Entry Type", EntryType);
        "G/L Account".CopyFilter("Date Filter", DtldVendLedgEntry."Posting Date");
        DtldVendLedgEntry.CalcSums("Credit Amount (LCY)");
        VendCreditAmount := DtldVendLedgEntry."Credit Amount (LCY)";

        // Pass 2: detail entries with blank Posting Group attributed to the vendor's current master
        // posting group. Uses multi-entry cached query result to avoid repeated SQL round-trips.
        EnsureVendBlankPGCache(PostingGr);
        if VendBlankPGCreditCache.Get(PostingGr + '|' + Format(EntryType.AsInteger()), CachedAmount) then
            VendCreditAmount += CachedAmount;

        exit(VendCreditAmount);
    end;

    local procedure CalcVendDebitAmount(PostingGr: Code[20]; EntryType: Enum "Detailed CV Ledger Entry Type"): Decimal
    var
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        VendDebitAmount: Decimal;
        CachedAmount: Decimal;
    begin
        // Pass 1: detail entries explicitly stamped with this posting group (multi-posting-group vendors).
        DtldVendLedgEntry.SetLoadFields("Debit Amount (LCY)");
        DtldVendLedgEntry.SetRange("Posting Group", PostingGr);
        DtldVendLedgEntry.SetRange("Entry Type", EntryType);
        "G/L Account".CopyFilter("Date Filter", DtldVendLedgEntry."Posting Date");
        DtldVendLedgEntry.CalcSums("Debit Amount (LCY)");
        VendDebitAmount := DtldVendLedgEntry."Debit Amount (LCY)";

        // Pass 2: detail entries with blank Posting Group attributed to the vendor's current master
        // posting group. Uses multi-entry cached query result to avoid repeated SQL round-trips.
        EnsureVendBlankPGCache(PostingGr);
        if VendBlankPGDebitCache.Get(PostingGr + '|' + Format(EntryType.AsInteger()), CachedAmount) then
            VendDebitAmount += CachedAmount;

        exit(-VendDebitAmount);
    end;

    local procedure CalcCurrGainLossAmount(CurrencyCode: Code[20]; EntryType: Enum "Detailed CV Ledger Entry Type"): Decimal
    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        CurrGainLossAmount: Decimal;
    begin
        DtldCustLedgEntry.SetCurrentKey("Customer No.", "Posting Date", "Entry Type", "Currency Code");
        DtldCustLedgEntry.SetFilter("Customer No.", '<> %1', '');
        DtldCustLedgEntry.SetRange("Entry Type", EntryType);
        DtldCustLedgEntry.SetRange("Currency Code", CurrencyCode);
        "G/L Account".CopyFilter("Date Filter", DtldCustLedgEntry."Posting Date");
        DtldCustLedgEntry.CalcSums("Amount (LCY)");
        CurrGainLossAmount := CurrGainLossAmount + DtldCustLedgEntry."Amount (LCY)";

        DtldVendLedgEntry.SetCurrentKey("Vendor No.", "Posting Date", "Entry Type", "Currency Code");
        DtldVendLedgEntry.SetFilter("Vendor No.", '<> %1', '');
        DtldVendLedgEntry.SetRange("Entry Type", EntryType);
        DtldVendLedgEntry.SetRange("Currency Code", CurrencyCode);
        "G/L Account".CopyFilter("Date Filter", DtldVendLedgEntry."Posting Date");
        DtldVendLedgEntry.CalcSums("Amount (LCY)");
        CurrGainLossAmount := CurrGainLossAmount + DtldVendLedgEntry."Amount (LCY)";

        exit(-CurrGainLossAmount);
    end;

    local procedure GetTableName(): Text[100]
    var
        ObjTransl: Record "Object Translation";
    begin
        exit(ObjTransl.TranslateObject(ObjTransl."Object Type"::Table, ReconCustVendBuffer."Table ID"));
    end;
}

