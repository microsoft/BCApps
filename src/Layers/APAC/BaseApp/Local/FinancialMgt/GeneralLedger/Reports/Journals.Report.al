// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Reports;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Period;
using System.Utilities;

report 28161 Journals
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/FinancialMgt/GeneralLedger/Reports/Journals.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Journals';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Date; Date)
        {
            DataItemTableView = sorting("Period Type", "Period Start");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "Period Type", "Period Start";
            column(Title; Title)
            {
            }
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(STRSUBSTNO_Text006_USERID_; StrSubstNo(Text006, UserId))
            {
            }
            column(GLEntry2_TABLECAPTION__________Filter; GLEntry2.TableCaption + ': ' + Filter)
            {
            }
            column("Filter"; Filter)
            {
            }
            column(FiscalYearStatusText; FiscalYearStatusText)
            {
            }
            column(SourceCode_TABLECAPTION__________Filter2; SourceCode.TableCaption + ': ' + Filter2)
            {
            }
            column(Filter2; Filter2)
            {
            }
            column(DebitTotal; DebitTotal)
            {
            }
            column(CreditTotal; CreditTotal)
            {
            }
            column(Date_Period_Type; "Period Type")
            {
            }
            column(Date_Period_Start; "Period Start")
            {
            }
            column(Posting_DateCaption; Posting_DateCaptionLbl)
            {
            }
            column(Document_No_Caption; Document_No_CaptionLbl)
            {
            }
            column(External_Document_No_Caption; External_Document_No_CaptionLbl)
            {
            }
            column(G_L_Account_No_Caption; G_L_Account_No_CaptionLbl)
            {
            }
            column(DescriptionCaption; DescriptionCaptionLbl)
            {
            }
            column(DebitCaption; DebitCaptionLbl)
            {
            }
            column(CreditCaption; CreditCaptionLbl)
            {
            }
            column(Grand_Total__Caption; Grand_Total__CaptionLbl)
            {
            }
            dataitem(SourceCode; "Source Code")
            {
                DataItemTableView = sorting(Code);
                PrintOnlyIfDetail = true;
                RequestFilterFields = "Code";
                column(Date__Period_Type_; Date."Period Type")
                {
                }
                column(Date__Period_Name____YearString; Date."Period Name" + YearString)
                {
                }
                column(SourceCode_Code; Code)
                {
                }
                column(SourceCode_Description; Description)
                {
                }
                dataitem("G/L Entry"; "G/L Entry")
                {
                    DataItemLink = "Source Code" = field(Code);
                    DataItemTableView = sorting("Source Code", "Posting Date");
                    column(SourceCode2_Code; SourceCode2.Code)
                    {
                    }
                    column(SourceCode2_Description; SourceCode2.Description)
                    {
                    }
                    column(G_L_Entry__Debit_Amount_; "Debit Amount")
                    {
                    }
                    column(G_L_Entry__Credit_Amount_; "Credit Amount")
                    {
                    }
                    column(FORMAT__Posting_Date__; Format("Posting Date"))
                    {
                    }
                    column(G_L_Entry__Document_No__; "Document No.")
                    {
                    }
                    column(G_L_Entry__External_Document_No__; "External Document No.")
                    {
                    }
                    column(G_L_Entry__G_L_Account_No__; "G/L Account No.")
                    {
                    }
                    column(G_L_Entry_Description; Description)
                    {
                    }
                    column(G_L_Entry__Debit_Amount__Control1500056; "Debit Amount")
                    {
                    }
                    column(G_L_Entry__Credit_Amount__Control1500059; "Credit Amount")
                    {
                    }
                    column(SourceCode2_Code_Control1500067; SourceCode2.Code)
                    {
                    }
                    column(SourceCode2_Description_Control1500069; SourceCode2.Description)
                    {
                    }
                    column(G_L_Entry__Debit_Amount__Control1500071; "Debit Amount")
                    {
                    }
                    column(G_L_Entry__Credit_Amount__Control1500073; "Credit Amount")
                    {
                    }
                    column(STRSUBSTNO_Text008_FIELDCAPTION__Document_No_____Document_No___; StrSubstNo(Text008, FieldCaption("Document No."), "Document No."))
                    {
                    }
                    column(G_L_Entry__Debit_Amount__Control1500063; "Debit Amount")
                    {
                    }
                    column(G_L_Entry__Credit_Amount__Control1500065; "Credit Amount")
                    {
                    }
                    column(SortingByNo; SortingByNo)
                    {
                    }
                    column(DisplayNo; DisplayNo)
                    {
                    }
                    column(DisplayEntries; DisplayEntries)
                    {
                    }
                    column(SourceCode2_Code_Control1500075; SourceCode2.Code)
                    {
                    }
                    column(SourceCode2_Description_Control1500077; SourceCode2.Description)
                    {
                    }
                    column(G_L_Entry__Debit_Amount__Control1500079; "Debit Amount")
                    {
                    }
                    column(G_L_Entry__Credit_Amount__Control1500081; "Credit Amount")
                    {
                    }
                    column(G_L_Entry_Entry_No_; "Entry No.")
                    {
                    }
                    column(G_L_Entry_Source_Code; "Source Code")
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if DisplayEntries then begin
                            DebitTotal := DebitTotal + "Debit Amount";
                            CreditTotal := CreditTotal + "Credit Amount";
                        end;
                    end;

                    trigger OnPostDataItem()
                    begin
                        if Date."Period Type" = Date."Period Type"::Date then
                            Finished := true;
                    end;

                    trigger OnPreDataItem()
                    begin
                        if not DisplayEntries then
                            CurrReport.Break();

                        if DisplayEntries then
                            case SortingBy of
                                SortingBy::"Posting Date":
                                    SetCurrentKey("Source Code", "Posting Date", "Document No.");
                                SortingBy::"Document No.":
                                    SetCurrentKey("Source Code", "Document No.", "Posting Date");
                            end;

                        if StartDate > Date."Period Start" then
                            Date."Period Start" := StartDate;
                        if EndDate < Date."Period End" then
                            Date."Period End" := EndDate;
                        if Date."Period Type" <> Date."Period Type"::Date then
                            SetRange("Posting Date", Date."Period Start", Date."Period End")
                        else
                            SetRange("Posting Date", StartDate, EndDate);
                    end;
                }
                dataitem("G/L Account"; "G/L Account")
                {
                    DataItemTableView = sorting("No.");
                    PrintOnlyIfDetail = true;
                    column(SourceCode2_Code_Control1500095; SourceCode2.Code)
                    {
                    }
                    column(SourceCode2_Description_Control1500097; SourceCode2.Description)
                    {
                    }
                    column(GLEntry2__Debit_Amount_; GLEntry2."Debit Amount")
                    {
                    }
                    column(GLEntry2__Credit_Amount_; GLEntry2."Credit Amount")
                    {
                    }
                    column(G_L_Account_No_; "No.")
                    {
                    }
                    dataitem(GLEntry2; "G/L Entry")
                    {
                        DataItemTableView = sorting("G/L Account No.", "Posting Date", "Source Code");
                        column(G_L_Account___No__; "G/L Account"."No.")
                        {
                        }
                        column(G_L_Account__Name; "G/L Account".Name)
                        {
                        }
                        column(GLEntry2__Debit_Amount__Control1500090; "Debit Amount")
                        {
                        }
                        column(GLEntry2__Credit_Amount__Control1500093; "Credit Amount")
                        {
                        }
                        column(DisplayCentral; DisplayCentral)
                        {
                        }
                        column(GLEntry2_Entry_No_; "Entry No.")
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            if not DisplayEntries then begin
                                DebitTotal := DebitTotal + "Debit Amount";
                                CreditTotal := CreditTotal + "Credit Amount";
                            end;
                        end;

                        trigger OnPostDataItem()
                        begin
                            if Date."Period Type" = Date."Period Type"::Date then
                                Finished := true;
                        end;

                        trigger OnPreDataItem()
                        begin
                            SetCurrentKey("G/L Account No.", "Posting Date", "Source Code");
                            SetRange("G/L Account No.", "G/L Account"."No.");
                            if Date."Period Type" <> Date."Period Type"::Date then
                                SetRange("Posting Date", Date."Period Start", Date."Period End")
                            else
                                SetRange("Posting Date", StartDate, EndDate);
                            SetRange("Source Code", SourceCode.Code);
                        end;
                    }

                    trigger OnPreDataItem()
                    begin
                        if not DisplayCentral then
                            CurrReport.Break();
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    SourceCode2 := SourceCode;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                YearString := '';
                if Date."Period Type" <> Date."Period Type"::Year then begin
                    Year := Date2DMY("Period End", 3);
                    YearString := ' ' + Format(Year);
                end;
                if Finished then
                    CurrReport.Break();
            end;

            trigger OnPreDataItem()
            var
                Period: Record Date;
            begin
                if GetFilter("Period Type") = '' then
                    Error(Text004, FieldCaption("Period Type"));
                if GetFilter("Period Start") = '' then
                    Error(Text004, FieldCaption("Period Start"));
                if CopyStr(GetFilter("Period Start"), 1, 1) = '.' then
                    Error(Text005);
                StartDate := GetRangeMin("Period Start");
                CopyFilter("Period Type", Period."Period Type");
                Period.SetRange("Period Start", StartDate);
                if not Period.FindFirst() then
                    Error(Text009, StartDate, GetFilter("Period Type"));
                PreviousEndDate := ClosingDate(StartDate - 1);
                FiltreDateCalc.CreateFiscalYearFilter(TextDate, TextDate, StartDate, 0);
                TextDate := ConvertStr(TextDate, '.', ',');
                FiltreDateCalc.VerifiyDateFilter(TextDate);
                TextDate := CopyStr(TextDate, 1, 8);
                Evaluate(PreviousStartDate, TextDate);
                if CopyStr(GetFilter("Period Start"), StrLen(GetFilter("Period Start")), 1) = '.' then
                    EndDate := 0D
                else
                    EndDate := GetRangeMax("Period Start");
                if EndDate = StartDate then
                    EndDate := FiltreDateCalc.ReturnEndingPeriod(StartDate, Date.GetRangeMin("Period Type"));
                Clear(Period);
                CopyFilter("Period Type", Period."Period Type");
                Period.SetRange("Period End", ClosingDate(EndDate));
                if not Period.FindFirst() then
                    Error(Text010, EndDate, GetFilter("Period Type"));
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
                    field(Journals; Display)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Display';
                        OptionCaption = 'Journals,Centralized Journals,Journals and Centralization';
                        ToolTip = 'Specifies how you want to view the information. Choose Journals to view the amounts for each transaction. Choose Centralized Journals to view the amounts for each account by period. Choose Journals and Centralization to display both.';

                        trigger OnValidate()
                        begin
                            PageRefresh();
                        end;
                    }
                    field("Posting Date"; SortingBy)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sorted by';
                        OptionCaption = 'Posting Date,Document No.';
                        ToolTip = 'Specifies how you want to view the information.';

                        trigger OnValidate()
                        begin
                            if SortingBy = SortingBy::"Document No." then
                                if not "Document No.Visible" then
                                    Error(Text666, SortingBy);
                            if SortingBy = SortingBy::"Posting Date" then
                                if not "Posting DateVisible" then
                                    Error(Text666, SortingBy);
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
            "Document No.Visible" := true;
            "Posting DateVisible" := true;
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        Filter := Date.GetFilters();
        Filter2 := SourceCode.GetFilters();

        case Display of
            Display::Journals:
                begin
                    DisplayEntries := true;
                    Title := Text001
                end;
            Display::"Centralized Journals":
                begin
                    DisplayCentral := true;
                    Title := Text002
                end;
            Display::"Journals and Centralization":
                begin
                    DisplayEntries := true;
                    DisplayCentral := true;
                    Title := Text003
                end;
        end;
    end;

    var
        SourceCode2: Record "Source Code";
        FiltreDateCalc: Codeunit "DateFilter-Calc";
        StartDate: Date;
        EndDate: Date;
        PreviousStartDate: Date;
        PreviousEndDate: Date;
        TextDate: Text[30];
        DebitTotal: Decimal;
        CreditTotal: Decimal;
        Filter2: Text[250];
        Title: Text[50];
        SortingBy: Option "Posting Date","Document No.";
        Display: Option Journals,"Centralized Journals","Journals and Centralization";
        DisplayEntries: Boolean;
        DisplayCentral: Boolean;
        "Filter": Text[250];
        Year: Integer;
        YearString: Text[10];
        Finished: Boolean;
        FiscalYearStatusText: Text[80];
        Text001: Label 'Journals';
        Text002: Label 'Centralized journals';
        Text003: Label 'Journals and Centralization';
        Text004: Label 'You must fill in the %1 field.';
        Text005: Label 'You must specify a Starting Date.';
        Text006: Label 'Printed by %1';
        Text008: Label 'Total %1 %2';
        Text009: Label 'The selected starting date %1 is not the start of a %2.';
        Text010: Label 'The selected ending date %1 is not the end of a %2.';
        SortingByNo: Integer;
        DisplayNo: Integer;
        "Posting DateVisible": Boolean;
        "Document No.Visible": Boolean;
        Text666: Label '%1 is not a valid selection.';
        Posting_DateCaptionLbl: Label 'Posting Date';
        Document_No_CaptionLbl: Label 'Document No.';
        External_Document_No_CaptionLbl: Label 'External Document No.';
        G_L_Account_No_CaptionLbl: Label 'G/L Account No.';
        DescriptionCaptionLbl: Label 'Description';
        DebitCaptionLbl: Label 'Debit';
        CreditCaptionLbl: Label 'Credit';
        Grand_Total__CaptionLbl: Label 'Grand Total :';

    local procedure PageRefresh()
    begin
        "Posting DateVisible" := (Display = Display::Journals) or (Display = Display::"Journals and Centralization");
        "Document No.Visible" := (Display = Display::Journals) or (Display = Display::"Journals and Centralization");
        // REQUESTOPTIONSPAGE.Activate();
    end;
}

