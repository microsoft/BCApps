// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Reports;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using System.Utilities;

report 11500 "Provisional Trial Balance"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Finance/GeneralLedger/Reports/ProvisionalTrialBalance.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Provisional Trial Balance';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("G/L Account"; "G/L Account")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Account Type", "Global Dimension 1 Filter", "Global Dimension 2 Filter";
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(USERID; UserId)
            {
            }
            column(GlAccFilter; GlAccFilter)
            {
            }
            column(JourNameFilter; JourNameFilter)
            {
            }
            column(ToDate; ToDate)
            {
            }
            column(G_L_Account_No_; "No.")
            {
            }
            column(Provisional_Trial_BalanceCaption; Provisional_Trial_BalanceCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(ProvBalance_Control11Caption; ProvBalance_Control11CaptionLbl)
            {
            }
            column(ProvBalanceCaption; ProvBalanceCaptionLbl)
            {
            }
            column(ProvAmtCaption; ProvAmtCaptionLbl)
            {
            }
            column(PADSTR_____G_L_Account__Indentation___2___G_L_Account__NameCaption; PADSTR_____G_L_Account__Indentation___2___G_L_Account__NameCaptionLbl)
            {
            }
            column(G_L_Account___No__Caption; G_L_Account___No__CaptionLbl)
            {
            }
            column(G_L_Account___Balance_at_Date__Control16Caption; G_L_Account___Balance_at_Date__Control16CaptionLbl)
            {
            }
            column(G_L_Account___Balance_at_Date_Caption; G_L_Account___Balance_at_Date_CaptionLbl)
            {
            }
            column(GlAccFilterCaption; GlAccFilterCaptionLbl)
            {
            }
            column(JourNameFilterCaption; JourNameFilterCaptionLbl)
            {
            }
            column(ToDateCaption; ToDateCaptionLbl)
            {
            }
            column(Provisional_BalanceCaption; Provisional_BalanceCaptionLbl)
            {
            }
            column(Posted_BalanceCaption; Posted_BalanceCaptionLbl)
            {
            }
            column(Unposted_VAT_and_indirect_postings_to_master_accounts_are_not_calculated_Caption; Unposted_VAT_and_indirect_postings_to_master_accounts_are_not_calculated_CaptionLbl)
            {
            }
            dataitem(EmtpyLineCtr; "Integer")
            {
                DataItemTableView = sorting(Number);

                trigger OnPreDataItem()
                begin
                    SetRange(Number, 1, "G/L Account"."No. of Blank Lines");
                end;
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(G_L_Account___No__; "G/L Account"."No.")
                {
                }
                column(PADSTR_____G_L_Account__Indentation___2___G_L_Account__Name; PadStr('', "G/L Account".Indentation * 2) + "G/L Account".Name)
                {
                }
                column(G_L_Account___Balance_at_Date_; -"G/L Account"."Balance at Date")
                {
                }
                column(ProvBalance; -ProvBalance)
                {
                }
                column(ProvAmt; ProvAmt)
                {
                }
                column(ProvBalance_Control11; ProvBalance)
                {
                }
                column(G_L_Account___Balance_at_Date__Control16; "G/L Account"."Balance at Date")
                {
                }
                column(AccountTypeInt; AccountTypeInt)
                {
                }
                column(PageGroupNo; PageGroupNo)
                {
                }
                column(BLankLineCounter; "G/L Account"."No. of Blank Lines")
                {
                }
                column(G_L_Account___No___Control25; "G/L Account"."No.")
                {
                }
                column(PADSTR_____G_L_Account__Indentation___2___G_L_Account__Name_Control26; PadStr('', "G/L Account".Indentation * 2) + "G/L Account".Name)
                {
                }
                column(ProvAmt_Control12; ProvAmt)
                {
                }
                column(ProvBalance_Control15; ProvBalance)
                {
                }
                column(ProvBalance_Control28; -ProvBalance)
                {
                }
                column(G_L_Account___Balance_at_Date__Control27; -"G/L Account"."Balance at Date")
                {
                }
                column(G_L_Account___Balance_at_Date__Control30; "G/L Account"."Balance at Date")
                {
                }
                column(Integer_Number; Number)
                {
                }
            }

            trigger OnAfterGetRecord()
            begin
                d.Update(1, "No.");
                CalcFields("Balance at Date");
                ProvAmt := 0;
                ProvBalance := 0;
                CreditEntries();
                DebitEntries();
                ProvBalance := "Balance at Date" + ProvAmt;

                AccountTypeInt := "Account Type".AsInteger();
                if NewPage then begin
                    PageGroupNo := PageGroupNo + 1;
                    NewPage := false;
                end;
                NewPage := "New Page";
            end;

            trigger OnPostDataItem()
            begin
                d.Close();
            end;

            trigger OnPreDataItem()
            begin
                PageGroupNo := 1;
                NewPage := false;

                if ToDate = 0D then
                    Error(Text000);

                "G/L Account".SetRange("Date Filter", 0D, ToDate);

                d.Open(Text001 +
                  Text002);
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
                group(Options)
                {
                    Caption = 'Options';
                    field(BalanceToDate; ToDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Balance to Date';
                        ToolTip = 'Specifies the provisional balance report date.';
                    }
                    field(WithJournal1; JourName1)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'With Journal 1';
                        Lookup = true;
                        ToolTip = 'Specifies the first journal batch name.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            if PAGE.RunModal(PAGE::"General Journal Batches", GlJourName) = ACTION::LookupOK then
                                JourName1 := GlJourName.Name;
                        end;
                    }
                    field(JourName2; JourName2)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'With Journal 2';
                        Lookup = true;
                        ToolTip = 'Specifies the second journal batch name.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            if PAGE.RunModal(PAGE::"General Journal Batches", GlJourName) = ACTION::LookupOK then
                                JourName2 := GlJourName.Name;
                        end;
                    }
                    field(JourName3; JourName3)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'With Journal 3';
                        Lookup = true;
                        ToolTip = 'Specifies the third journal batch name.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            if PAGE.RunModal(PAGE::"General Journal Batches", GlJourName) = ACTION::LookupOK then
                                JourName3 := GlJourName.Name;
                        end;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            if ToDate = 0D then
                ToDate := Today;
        end;

        trigger OnOpenPage()
        begin
            GenJourTemplate.SetRange(Type, GenJourTemplate.Type::General);
            GenJourTemplate.SetRange(Recurring, false);
            if GenJourTemplate.FindFirst() then;

            TemplateName := GenJourTemplate.Name;
            GlJourName.SetRange("Journal Template Name", TemplateName);
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        GlAccFilter := "G/L Account".GetFilters();
        JourNameFilter := JourName1 + '   ' + JourName2 + '   ' + JourName3;

        GLSetup.Get();
    end;

    var
        Text000: Label 'Ending Date must be defined.';
        Text001: Label 'Calculating Balance\';
        Text002: Label 'Acc   #1#############';
        GlJourName: Record "Gen. Journal Batch";
        GlLines: Record "Gen. Journal Line";
        GenJourTemplate: Record "Gen. Journal Template";
        GLSetup: Record "General Ledger Setup";
        d: Dialog;
        GlAccFilter: Text;
        JourNameFilter: Text[100];
        JourName1: Code[10];
        JourName2: Code[10];
        JourName3: Code[10];
        ProvAmt: Decimal;
        ProvBalance: Decimal;
        ToDate: Date;
        TemplateName: Text[30];
        PageGroupNo: Integer;
        NewPage: Boolean;
        AccountTypeInt: Integer;
        Provisional_Trial_BalanceCaptionLbl: Label 'Provisional Trial Balance';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        ProvBalance_Control11CaptionLbl: Label 'Debit';
        ProvBalanceCaptionLbl: Label 'Credit';
        ProvAmtCaptionLbl: Label 'Unposted';
        PADSTR_____G_L_Account__Indentation___2___G_L_Account__NameCaptionLbl: Label 'Name';
        G_L_Account___No__CaptionLbl: Label 'Account';
        G_L_Account___Balance_at_Date__Control16CaptionLbl: Label 'Debit';
        G_L_Account___Balance_at_Date_CaptionLbl: Label 'Credit';
        GlAccFilterCaptionLbl: Label 'GL Account  Filter:';
        JourNameFilterCaptionLbl: Label 'With Journal:';
        ToDateCaptionLbl: Label 'Balance to  Date:';
        Provisional_BalanceCaptionLbl: Label 'Provisional Balance';
        Posted_BalanceCaptionLbl: Label 'Posted Balance';
        Unposted_VAT_and_indirect_postings_to_master_accounts_are_not_calculated_CaptionLbl: Label 'Unposted VAT and indirect postings to master accounts are not calculated.';

    [Scope('OnPrem')]
    procedure CreditEntries()
    begin
        GlLines.Reset();
        GlLines.SetRange("Journal Template Name", TemplateName);
        GlLines.SetFilter("Journal Batch Name", '%1|%2|%3', JourName1, JourName2, JourName3);
        GlLines.SetRange("Account Type", GlLines."Account Type"::"G/L Account");
        GlLines.SetRange("Posting Date", 0D, ToDate);
        "G/L Account".CopyFilter("Global Dimension 1 Filter", GlLines."Shortcut Dimension 1 Code");
        "G/L Account".CopyFilter("Global Dimension 2 Filter", GlLines."Shortcut Dimension 2 Code");

        if "G/L Account".Totaling <> '' then
            GlLines.SetFilter("Account No.", "G/L Account".Totaling)
        else
            GlLines.SetFilter("Account No.", "G/L Account"."No.");

        GlLines.CalcSums("Amount (LCY)");
        ProvAmt := ProvAmt + GlLines."Amount (LCY)";
    end;

    [Scope('OnPrem')]
    procedure DebitEntries()
    begin
        GlLines.Reset();
        GlLines.SetRange("Journal Template Name", TemplateName);
        GlLines.SetFilter("Journal Batch Name", '%1|%2|%3', JourName1, JourName2, JourName3);
        GlLines.SetRange("Bal. Account Type", GlLines."Bal. Account Type"::"G/L Account");
        GlLines.SetRange("Posting Date", 0D, ToDate);
        "G/L Account".CopyFilter("Global Dimension 1 Filter", GlLines."Shortcut Dimension 1 Code");
        "G/L Account".CopyFilter("Global Dimension 2 Filter", GlLines."Shortcut Dimension 2 Code");

        if "G/L Account".Totaling <> '' then
            GlLines.SetFilter("Bal. Account No.", "G/L Account".Totaling)
        else
            GlLines.SetFilter("Bal. Account No.", "G/L Account"."No.");

        GlLines.CalcSums("Amount (LCY)");
        ProvAmt := ProvAmt - GlLines."Amount (LCY)";
    end;
}

