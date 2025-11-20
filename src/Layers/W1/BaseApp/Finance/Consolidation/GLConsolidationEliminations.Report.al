// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Consolidation;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using System.Utilities;

report 16 "G/L Consolidation Eliminations"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Finance/Consolidation/GLConsolidationEliminations.rdlc';
    ApplicationArea = Suite;
    Caption = 'G/L Consolidation Eliminations';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("G/L Account"; "G/L Account")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Global Dimension 1 Filter", "Global Dimension 2 Filter";
            column(PeriodTextCaption; StrSubstNo(Text003, PeriodText))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(GLAccountGLFilter; TableCaption + ': ' + GLFilter)
            {
            }
            column(GLFilter; GLFilter)
            {
            }
            column(GLAccType; Format("Account Type", 0, 2))
            {
            }
            column(GenJournalLineTableCaption; "Gen. Journal Line".TableCaption + ': ' + GenJnlLineFilter)
            {
            }
            column(GenJnlLineFilter; GenJnlLineFilter)
            {
            }
            column(NoOfBlankLines_GLAccount; "No. of Blank Lines")
            {
            }
            column(AmountType; AmountType)
            {
                OptionCaption = 'Net Change,Balance';
            }
            column(BusUnitCode; BusUnitCode)
            {
            }
            column(GenJournalLineAmount; "Gen. Journal Line".Amount)
            {
            }
            column(No_GLAccount; "No.")
            {
            }
            column(GLConsolidationEliminationsCaption; GLConsolidationEliminationsCaptionLbl)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(GLAcc2NoCaption; GLAcc2NoCaptionLbl)
            {
            }
            column(GLAccountNameIndentedCaption; GLAccountNameIndentedCaptionLbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }
            column(EliminationsCaption; EliminationsCaptionLbl)
            {
            }
            column(GenJournalLineDescCaption; "Gen. Journal Line".FieldCaption(Description))
            {
            }
            column(TotalInclEliminationsCaption; TotalInclEliminationsCaptionLbl)
            {
            }
            column(TotalEliminationsCaption; TotalEliminationsCaptionLbl)
            {
            }
            dataitem(BlankLineCounter; "Integer")
            {
                DataItemTableView = sorting(Number);

                trigger OnPreDataItem()
                begin
                    SetRange(Number, 1, "G/L Account"."No. of Blank Lines");
                end;
            }
            dataitem("Gen. Journal Line"; "Gen. Journal Line")
            {
                DataItemLink = "Account No." = field("No.");
                DataItemTableView = sorting("Journal Template Name");
                UseTemporary = true;
                column(GLAcc2No; GLAcc2."No.")
                {
                }
                column(GLAccountNameIndented; PadStr('', GLAcc2.Indentation * 2) + GLAcc2.Name)
                {
                }
                column(ConsolidAmount; ConsolidAmount)
                {
                    AutoFormatType = 1;
                }
                column(BusUnitAmount; BusUnitAmount)
                {
                    AutoFormatType = 1;
                }
                column(Amount_GenJournalLine; Amount)
                {
                }
                column(Desc_GenJournalLine; Description)
                {
                }
                column(FirstLine; Format(FirstLine, 0, 2))
                {
                }

                trigger OnAfterGetRecord()
                begin
                    GLAcc2 := "G/L Account";
                    if FirstLine then
                        FirstLine := false
                    else begin
                        GLAcc2."No." := '';
                        GLAcc2.Name := '';
                        ConsolidAmount := 0;
                        BusUnitAmount := 0;
                    end;
                end;

                trigger OnPostDataItem()
                var
                    GenJnlLine: Record "Gen. Journal Line";
                begin
                    TotalAmountLCY := TotalAmountLCY + Amount;
                    if ("G/L Account"."Account Type" <> "G/L Account"."Account Type"::Posting) and
                       ("G/L Account".Totaling <> '')
                    then begin
                        GenJnlLine.Reset();
                        GenJnlLine := "Gen. Journal Line";
                        GenJnlLine.SetRange("Journal Template Name", "Journal Template Name");
                        GenJnlLine.SetRange("Journal Batch Name", "Journal Batch Name");
                        GenJnlLine.SetFilter("Account No.", "G/L Account".Totaling);
                        GenJnlLine.CalcSums(Amount);
                        EliminationAmount := GenJnlLine.Amount;

                        GenJnlLine.SetFilter("Bal. Account No.", "G/L Account".Totaling);
                        GenJnlLine.CalcSums(Amount);
                        EliminationAmount -= GenJnlLine.Amount;
                    end;
                    TotalAmountLCY := TotalAmountLCY + EliminationAmount;
                end;

                trigger OnPreDataItem()
                begin
                    "G/L Account".SetRange("Business Unit Filter", BusUnit.Code);
                    if (BusUnit."Starting Date" <> 0D) or (BusUnit."Ending Date" <> 0D) then
                        "G/L Account".SetRange("Date Filter", BusUnit."Starting Date", BusUnit."Ending Date")
                    else
                        "G/L Account".SetRange("Date Filter", ConsolidStartDate, ConsolidEndDate);

                    if AmountType = AmountType::"Net Change" then begin
                        "G/L Account".CalcFields("Net Change");
                        BusUnitAmount := "G/L Account"."Net Change";
                    end else begin
                        "G/L Account".CalcFields("Balance at Date");
                        BusUnitAmount := "G/L Account"."Balance at Date";
                    end;

                    "G/L Account".SetRange("Date Filter", ConsolidStartDate, ConsolidEndDate);
                    "G/L Account".SetFilter("Business Unit Filter", '<>%1', BusUnit.Code);

                    if AmountType = AmountType::"Net Change" then begin
                        "G/L Account".CalcFields("Net Change");
                        ConsolidAmount := "G/L Account"."Net Change";
                    end else begin
                        "G/L Account".CalcFields("Balance at Date");
                        ConsolidAmount := "G/L Account"."Balance at Date";
                    end;

                    SetRange("Journal Template Name", "Journal Template Name");
                    SetRange("Journal Batch Name", "Journal Batch Name");
                    SetFilter(Amount, '<>0');

                    TotalAmountLCY := ConsolidAmount + BusUnitAmount;
                end;
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(No2__GLAccount; "G/L Account"."No.")
                {
                }
                column(GLAccountNameIndented2; PadStr('', "G/L Account".Indentation * 2) + "G/L Account".Name)
                {
                }
                column(ConsolidAmount2; ConsolidAmount)
                {
                    AutoFormatType = 1;
                }
                column(BusUnitAmount2; BusUnitAmount)
                {
                    AutoFormatType = 1;
                }
                column(EliminationAmount; EliminationAmount)
                {
                    AutoFormatType = 1;
                }
                column(FirstLine2; Format(FirstLine, 0, 2))
                {
                }
            }

            trigger OnAfterGetRecord()
            begin
                FirstLine := true;
                EliminationAmount := 0;
                CollectGenJournalLines("Gen. Journal Line", "G/L Account");
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About G/L Consolidation Eliminations';
        AboutText = 'The **G/L Consolidation Eliminations** report identifies and removes internal transactions between companies to prevent duplication in consolidated financial statements. Use it for intercompany financial consolidation to eliminate duplicate revenues and expenses, ensuring accurate and compliant group reporting.';
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    group("Consolidation Period")
                    {
                        Caption = 'Consolidation Period';
                        field(StartingDate; ConsolidStartDate)
                        {
                            ApplicationArea = Suite;
                            Caption = 'Starting Date';
                            ClosingDates = true;
                            ToolTip = 'Specifies the first date in the period from which posted entries in the consolidated company will be shown.';
                        }
                        field(EndingDate; ConsolidEndDate)
                        {
                            ApplicationArea = Suite;
                            Caption = 'Ending Date';
                            ClosingDates = true;
                            ToolTip = 'Specifies the last date in the period from which posted entries in the consolidated company will be shown.';
                        }
                    }
                    field("BusUnit.Code"; BusUnit.Code)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Business Unit Code';
                        TableRelation = "Business Unit";
                        ToolTip = 'Specifies the code for the business unit, in a company group structure.';
                    }
                    field(JournalTemplateName; "Gen. Journal Line"."Journal Template Name")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Journal Template Name';
                        NotBlank = true;
                        TableRelation = "Gen. Journal Template";
                        ToolTip = 'Specifies the journal template that will be used for the unposted eliminations.';
                    }
                    field(JournalBatch; "Gen. Journal Line"."Journal Batch Name")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Journal Batch';
                        Lookup = true;
                        NotBlank = true;
                        ToolTip = 'Specifies the journal batch that will be used for the unposted eliminations.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            "Gen. Journal Line".TestField("Journal Template Name");
                            GenJnlTemplate.Get("Gen. Journal Line"."Journal Template Name");
                            GenJnlBatch.FilterGroup(2);
                            GenJnlBatch.SetRange("Journal Template Name", "Gen. Journal Line"."Journal Template Name");
                            GenJnlBatch.FilterGroup(0);
                            GenJnlBatch.Name := "Gen. Journal Line"."Journal Batch Name";
                            if GenJnlBatch.Find('=><') then;
                            if PAGE.RunModal(0, GenJnlBatch) = ACTION::LookupOK then begin
                                Text := GenJnlBatch.Name;
                                exit(true);
                            end;
                        end;

                        trigger OnValidate()
                        begin
                            "Gen. Journal Line".TestField("Journal Template Name");
                            GenJnlBatch.Get("Gen. Journal Line"."Journal Template Name", "Gen. Journal Line"."Journal Batch Name");
                        end;
                    }
                    field(AmountType; AmountType)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Show';
                        OptionCaption = 'Net Change,Balance';
                        ToolTip = 'Specifies if the selected value is shown in the window.';
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

    trigger OnPreReport()
    begin
        GLFilter := "G/L Account".GetFilters();
        if ConsolidStartDate = 0D then
            Error(Text000);
        if ConsolidEndDate = 0D then
            Error(Text001);
        "G/L Account".SetRange("Date Filter", ConsolidStartDate, ConsolidEndDate);
        PeriodText := "G/L Account".GetFilter("Date Filter");

        "Gen. Journal Line".SetRange("Journal Template Name", "Gen. Journal Line"."Journal Template Name");
        "Gen. Journal Line".SetRange("Journal Batch Name", "Gen. Journal Line"."Journal Batch Name");
        GenJnlLineFilter := "Gen. Journal Line".GetFilters();

        if BusUnit.Code <> '' then begin
            BusUnitCode := BusUnit.Code;
            BusUnit.Get(BusUnit.Code);
        end else
            BusUnitCode := Text002;

        GenJnlBatch.Get("Gen. Journal Line"."Journal Template Name", "Gen. Journal Line"."Journal Batch Name");
    end;

    var
        BusUnit: Record "Business Unit";
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
        GLAcc2: Record "G/L Account";
        ConsolidStartDate: Date;
        ConsolidEndDate: Date;
        GLFilter: Text;
        GenJnlLineFilter: Text;
        AmountType: Option "Net Change",Balance;
        PeriodText: Text;
        BusUnitCode: Text[20];
        ConsolidAmount: Decimal;
        BusUnitAmount: Decimal;
        TotalAmountLCY: Decimal;
        FirstLine: Boolean;
        EliminationAmount: Decimal;

#pragma warning disable AA0074
        Text000: Label 'Enter the starting date for the consolidation period.';
        Text001: Label 'Enter the ending date for the consolidation period.';
        Text002: Label 'Posted Eliminations';
#pragma warning disable AA0470
        Text003: Label 'Period: %1';
#pragma warning restore AA0470
#pragma warning restore AA0074
        GLConsolidationEliminationsCaptionLbl: Label 'G/L Consolidation Eliminations';
        PageCaptionLbl: Label 'Page';
        GLAcc2NoCaptionLbl: Label 'No.';
        GLAccountNameIndentedCaptionLbl: Label 'Name';
        TotalCaptionLbl: Label 'Total';
        EliminationsCaptionLbl: Label 'Eliminations';
        TotalInclEliminationsCaptionLbl: Label 'Total Incl. Eliminations';
        TotalEliminationsCaptionLbl: Label 'Total Eliminations';

    local procedure CollectGenJournalLines(var TempGenJournalLine: Record "Gen. Journal Line" temporary; GLAccount: Record "G/L Account")
    var
        GenJournalLine: Record "Gen. Journal Line";
        LineNo: Integer;
    begin
        TempGenJournalLine.Reset();
        TempGenJournalLine.DeleteAll();

        GenJournalLine.Reset();
        GenJournalLine.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJnlBatch.Name);
        GenJournalLine.SetRange("Account Type", GenJournalLine."Account Type"::"G/L Account");
        GenJournalLine.SetRange("Account No.", GLAccount."No.");
        if GenJournalLine.FindSet() then
            repeat
                LineNo += 10000;
                TempGenJournalLine := GenJournalLine;
                TempGenJournalLine."Line No." := LineNo;
                TempGenJournalLine.Insert();
            until GenJournalLine.Next() = 0;

        GenJournalLine.SetRange("Account Type");
        GenJournalLine.SetRange("Account No.");
        GenJournalLine.SetRange("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.SetRange("Bal. Account No.", GLAccount."No.");
        if GenJournalLine.FindSet() then
            repeat
                LineNo += 10000;
                TempGenJournalLine := GenJournalLine;
                TempGenJournalLine."Line No." := LineNo;
                TempGenJournalLine."Account No." := TempGenJournalLine."Bal. Account No.";
                TempGenJournalLine.Description := GLAccount.Name;
                TempGenJournalLine.Amount *= -1;
                TempGenJournalLine.Insert();
            until GenJournalLine.Next() = 0;
    end;
}

