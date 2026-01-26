// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Finance.GeneralLedger.Reports;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;

report 11521 "SR G/L Entries Foreign Currenc"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Finance/Finance/GeneralLedger/Reports/SRGLEntriesForeignCurrenc.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'G/L Entries with Foreign Currency';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("G/L Register"; "G/L Register")
        {
            DataItemTableView = sorting("No.");
            MaxIteration = 1;
        }
        dataitem("G/L Entry"; "G/L Entry")
        {
            //The property 'DataItemTableView' shouldn't have an empty value.
            //DataItemTableView = '';
            RequestFilterFields = "Entry No.", "G/L Account No.", "Posting Date", "Document No.", "Bal. Account No.", "Global Dimension 1 Code", "Global Dimension 2 Code", "System-Created Entry", "Prior-Year Entry", "User ID", "Journal Batch Name";
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(FilterGetFilters; Text003 + GetFilters)
            {
            }
            column(LayoutForeignCurrency; Text004 + Text005)
            {
            }
            column(DebitAmount_GLEntry; "Debit Amount")
            {
            }
            column(CreditAmount_GLEntry; "Credit Amount")
            {
            }
            column(Amount_GLEntry; Amount)
            {
            }
            column(EntryNo_GLEntry; "Entry No.")
            {
            }
            column(Description_GLEntry; Description)
            {
            }
            column(BalAccountNo_GLEntry; "Bal. Account No.")
            {
            }
            column(GLAccountNo_GLEntry; "G/L Account No.")
            {
            }
            column(DocumentNo_GLEntry; "Document No.")
            {
            }
            column(PostingDate_GLEntry; Format("Posting Date"))
            {
            }
            column(AdditionalCurrencyAmount_GLEntry; "Additional-Currency Amount")
            {
            }
            column(Amount_GLEntryFCY; "Source Currency Amount")
            {
            }
            column(Exrate; Exrate)
            {
                DecimalPlaces = 2 : 3;
            }
            column(GlAccCurrencyCode; GlAcc."Source Currency Code")
            {
            }
            column(BalAccType; BalAccType)
            {
            }
            column(BalanceLCY; BalanceLCY)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(GLEntriesCaption; GLEntriesCaptionLbl)
            {
            }
            column(AmtLCYCaption; AmtLCYCaptionLbl)
            {
            }
            column(EntryNoCaption; EntryNoCaptionLbl)
            {
            }
            column(BalAccCaption; BalAccCaptionLbl)
            {
            }
            column(AccountCaption; AccountCaptionLbl)
            {
            }
            column(DocNoCaption; DocNoCaptionLbl)
            {
            }
            column(PostDateCaption; PostDateCaptionLbl)
            {
            }
            column(AmountACYCaption; AmountACYCaptionLbl)
            {
            }
            column(AmtFCYCaption; AmtFCYCaptionLbl)
            {
            }
            column(ExrateCaption; ExrateCaptionLbl)
            {
            }
            column(TextCaption; TextCaptionLbl)
            {
            }
            column(CurrCaption; CurrCaptionLbl)
            {
            }
            column(TotalDebitCreditBalanceCaption; TotalDebitCreditBalanceCaptionLbl)
            {
            }
            column(TranferCreditDebitCaption; TranferCreditDebitCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                CalcExrate("Source Currency Amount", Amount);

                if not GlAcc.Get("G/L Account No.") then
                    GlAcc.Init();

                if "Bal. Account No." <> '' then
                    BalAccType := CopyStr(Format("Bal. Account Type"), 1, 1)
                else
                    BalAccType := '';

                Entryno := Entryno + 1;
                BalanceLCY := BalanceLCY + Amount;
            end;

            trigger OnPostDataItem()
            begin
                if Entryno = 0 then
                    Message(Text002, GetFilters);
            end;

            trigger OnPreDataItem()
            begin
                if "G/L Register".GetFilter("No.") <> '' then begin
                    Reset();
                    SetRange("Entry No.", "G/L Register"."From Entry No.", "G/L Register"."To Entry No.");
                end;

                if ((FromGlRegister."No." > 0) and (ToGlRegister."No." = 0) or
                    (ToGlRegister."No." > 0) and (FromGlRegister."No." = 0))
                then
                    Error(Text000);

                if FromGlRegister."No." > 0 then begin
                    FromGlRegister.Get(FromGlRegister."No.");
                    ToGlRegister.Get(ToGlRegister."No.");
                    SetRange("Entry No.", FromGlRegister."From Entry No.", ToGlRegister."To Entry No.");
                end;
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field("FromGlRegister.""No."""; FromGlRegister."No.")
                    {
                        ApplicationArea = Basic, Suite;
                        BlankZero = true;
                        Caption = 'From GL Register No.';
                        TableRelation = "G/L Register";
                        ToolTip = 'Specifies the starting general ledger register number to include in the report.';

                        trigger OnValidate()
                        begin
                            FromGlRegisterNoOnAfterValidate();
                        end;
                    }
                    field("ToGlRegister.""No."""; ToGlRegister."No.")
                    {
                        ApplicationArea = Basic, Suite;
                        BlankZero = true;
                        Caption = 'To G/L Register No.';
                        TableRelation = "G/L Register";
                        ToolTip = 'Specifies the ending general ledger register number to include in the report.';
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
    }

    var
        Text000: Label 'When a filter is set to the G/L Register No., the first and last Register No. must be defined.';
        Text002: Label 'No G/L accounts within the filter %1.';
        Text005: Label 'Foreign Currency';
        FromGlRegister: Record "G/L Register";
        ToGlRegister: Record "G/L Register";
        GlAcc: Record "G/L Account";
        BalAccType: Text[1];
        BalanceLCY: Decimal;
        Entryno: Integer;
        Exrate: Decimal;
        Text003: Label 'Filter: ';
        Text004: Label 'Layout ';
        PageCaptionLbl: Label 'Page';
        GLEntriesCaptionLbl: Label 'G/L Entries';
        AmtLCYCaptionLbl: Label 'Amt. LCY';
        EntryNoCaptionLbl: Label 'Entryno.';
        BalAccCaptionLbl: Label 'Bal. Acc.';
        AccountCaptionLbl: Label 'Account';
        DocNoCaptionLbl: Label 'Doc. No.';
        PostDateCaptionLbl: Label 'Post Date';
        AmountACYCaptionLbl: Label 'Amount ACY';
        AmtFCYCaptionLbl: Label 'Amt. FCY';
        ExrateCaptionLbl: Label 'Exrate';
        TextCaptionLbl: Label 'Text';
        CurrCaptionLbl: Label 'Curr.';
        TranferCreditDebitCaptionLbl: Label 'Tranfer / Credit / Debit';
        TotalDebitCreditBalanceCaptionLbl: Label 'Total Debit / Credit / Balance';

    [Scope('OnPrem')]
    procedure CalcExrate(FcyAmt: Decimal; LcyAmt: Decimal): Decimal
    begin
        if FcyAmt <> 0 then
            exit(Round(LcyAmt * 100 / FcyAmt, 0.001));
        exit(0);
    end;

    local procedure FromGlRegisterNoOnAfterValidate()
    begin
        if (FromGlRegister."No." > 0) and (ToGlRegister."No." = 0) then
            ToGlRegister."No." := FromGlRegister."No.";
    end;
}
