// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Maintenance;

using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Setup;

report 5630 "Maintenance - Analysis"
{
    DefaultLayout = RDLC;
    RDLCLayout = './FixedAssets/Maintenance/MaintenanceAnalysis.rdlc';
    ApplicationArea = FixedAssets;
    Caption = 'Fixed Asset Maintenance Analysis';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Fixed Asset"; "Fixed Asset")
        {
            RequestFilterFields = "No.", "FA Class Code", "FA Subclass Code";
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(DeprBookText; DeprBookText)
            {
            }
            column(FATablecaptionFAFilter; TableCaption + ': ' + FAFilter)
            {
            }
            column(HeadLineText1; HeadLineText[1])
            {
            }
            column(HeadLineText2; HeadLineText[2])
            {
            }
            column(HeadLineText3; HeadLineText[3])
            {
            }
            column(GroupCodeName; GroupCodeName)
            {
            }
            column(FANo; FANo)
            {
            }
            column(FADescription; FADescription)
            {
            }
            column(PrintDetails; PrintDetails)
            {
            }
            column(GroupHeadLine; GroupHeadLine)
            {
            }
            column(No_FA; "No.")
            {
            }
            column(Description_FA; Description)
            {
            }
            column(Amounts1; Amounts[1])
            {
                AutoFormatType = 1;
            }
            column(Amounts2; Amounts[2])
            {
                AutoFormatType = 1;
            }
            column(Amounts3; Amounts[3])
            {
                AutoFormatType = 1;
            }
            column(GroupAmounts1; GroupAmounts[1])
            {
                AutoFormatType = 1;
            }
            column(GroupAmounts2; GroupAmounts[2])
            {
                AutoFormatType = 1;
            }
            column(GroupAmounts3; GroupAmounts[3])
            {
                AutoFormatType = 1;
            }
            column(GroupTotalGroupHeadLine; Text000 + ': ' + GroupHeadLine)
            {
            }
            column(TotalAmounts1; TotalAmounts[1])
            {
                AutoFormatType = 1;
            }
            column(TotalAmounts2; TotalAmounts[2])
            {
                AutoFormatType = 1;
            }
            column(TotalAmounts3; TotalAmounts[3])
            {
                AutoFormatType = 1;
            }
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
            }
            column(MaintenanceAnalysisCaption; MaintenanceAnalysisCaptionLbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                if Inactive then
                    CurrReport.Skip();
                if not FADeprBook.Get("No.", DeprBookCode) then
                    CurrReport.Skip();

                if GroupTotals = GroupTotals::"FA Posting Group" then
                    if "FA Posting Group" <> FADeprBook."FA Posting Group" then
                        Error(Text005, FieldCaption("FA Posting Group"), "No.");

                MaintenanceLedgEntry.SetRange("FA No.", "No.");
                Amounts[1] := CalculateAmount(MaintenanceCode1, Period1);
                Amounts[2] := CalculateAmount(MaintenanceCode2, Period2);
                Amounts[3] := CalculateAmount(MaintenanceCode3, Period3);
                if (Amounts[1] = 0) and (Amounts[2] = 0) and (Amounts[3] = 0) then
                    CurrReport.Skip();
                for i := 1 to 3 do
                    GroupAmounts[i] := 0;
                MakeGroupHeadLine();
            end;

            trigger OnPreDataItem()
            begin
                case GroupTotals of
                    GroupTotals::"FA Class":
                        SetCurrentKey("FA Class Code");
                    GroupTotals::"FA SubClass":
                        SetCurrentKey("FA Subclass Code");
                    GroupTotals::"Main Asset":
                        SetCurrentKey("Component of Main Asset");
                    GroupTotals::"Global Dimension 1":
                        SetCurrentKey("Global Dimension 1 Code");
                    GroupTotals::"FA Location":
                        SetCurrentKey("FA Location Code");
                    GroupTotals::"Global Dimension 2":
                        SetCurrentKey("Global Dimension 2 Code");
                    GroupTotals::"FA Posting Group":
                        SetCurrentKey("FA Posting Group");
                end;
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
                    field(DeprBookCode; DeprBookCode)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Depreciation Book';
                        TableRelation = "Depreciation Book";
                        ToolTip = 'Specifies the code for the depreciation book to be included in the report or batch job.';
                    }
                    field(DateSelection; DateSelection)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Date Selection';
                        OptionCaption = 'FA Posting Date,Posting Date';
                        ToolTip = 'Specifies the date options that can be used in the report. You can choose between the posting date and the fixed asset posting date.';
                    }
                    field(StartingDate; StartingDate)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the date when you want the report to start.';
                    }
                    field(EndingDate; EndingDate)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Ending Date';
                        ToolTip = 'Specifies the last date to be included in the report.';
                    }
                    field(AmountField1; MaintenanceCode1)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Amount Field 1';
                        TableRelation = Maintenance;
                        ToolTip = 'Specifies an Amount field that you use to create your own analysis.';
                    }
                    field(Period1; Period1)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Period 1';
                        OptionCaption = 'before Starting Date,Net Change,at Ending Date';
                        ToolTip = 'Specifies how the report determines the nature of the amounts in the first amount field. (Blank): The amounts consist of fixed asset ledger entries with the posting type that corresponds to the option in the amount field. Disposal: The amounts consists of fixed asset ledger entries with the posting type that corresponds to the option in the amount field if these entries have been posted to disposal accounts. Bal. Disposal: The amounts consist of fixed asset ledger entries with the posting type that corresponds to the option in the amount field if these entries have been posted to balancing disposal accounts.';
                    }
                    field(AmountField2; MaintenanceCode2)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Amount Field 2';
                        TableRelation = Maintenance;
                        ToolTip = 'Specifies an Amount field that you use to create your own analysis.';
                    }
                    field(Period2; Period2)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Period 2';
                        OptionCaption = 'before Starting Date,Net Change,at Ending Date';
                        ToolTip = 'Specifies how the report determines the nature of the amounts in the second amount field. (Blank): The amounts consist of fixed asset ledger entries with the posting type that corresponds to the option in the amount field. Disposal: The amounts consists of fixed asset ledger entries with the posting type that corresponds to the option in the amount field if these entries have been posted to disposal accounts. Bal. Disposal: The amounts consist of fixed asset ledger entries with the posting type that corresponds to the option in the amount field if these entries have been posted to balancing disposal accounts.';
                    }
                    field(AmountField3; MaintenanceCode3)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Amount Field 3';
                        TableRelation = Maintenance;
                        ToolTip = 'Specifies an Amount field that you use to create your own analysis.';
                    }
                    field(Period3; Period3)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Period 3';
                        OptionCaption = 'before Starting Date,Net Change,at Ending Date';
                        ToolTip = 'Specifies how the report determines the nature of the amounts in the third amount field. (Blank): The amounts consist of fixed asset ledger entries with the posting type that corresponds to the option in the amount field. Disposal: The amounts consists of fixed asset ledger entries with the posting type that corresponds to the option in the amount field if these entries have been posted to disposal accounts. Bal. Disposal: The amounts consist of fixed asset ledger entries with the posting type that corresponds to the option in the amount field if these entries have been posted to balancing disposal accounts.';
                    }
                    field(GroupTotals; GroupTotals)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Group Totals';
                        OptionCaption = ' ,FA Class,FA SubClass,FA Location,Main Asset,Global Dimension 1,Global Dimension 2,FA Posting Group';
                        ToolTip = 'Specifies if you want the report to group fixed assets and print totals using the category defined in this field. For example, maintenance expenses for fixed assets can be shown for each fixed asset class.';
                    }
                    field(PrintPerFixedAsset; PrintDetails)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Print per Fixed Asset';
                        ToolTip = 'Specifies if you want the report to print information separately for each fixed asset.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if DeprBookCode = '' then begin
                FASetup.Get();
                DeprBookCode := FASetup."Default Depr. Book";
            end;
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        DeprBook.Get(DeprBookCode);
        if GroupTotals = GroupTotals::"FA Posting Group" then
            FAGenReport.SetFAPostingGroup("Fixed Asset", DeprBook.Code);

        if DateSelection = DateSelection::"FA Posting Date" then
            FAGenReport.AppendFAPostingFilter("Fixed Asset", StartingDate, EndingDate);

        FAFilter := "Fixed Asset".GetFilters();

        if DateSelection = DateSelection::"Posting Date" then
            FAGenReport.AppendPostingDateFilter(FAFilter, StartingDate, EndingDate);

        DeprBookText := StrSubstNo('%1%2 %3', DeprBook.TableCaption(), ':', DeprBookCode);
        MakeGroupTotalText();
        ValidateDates();
        MakeAmountHeadLine(1, MaintenanceCode1, Period1);
        MakeAmountHeadLine(2, MaintenanceCode2, Period2);
        MakeAmountHeadLine(3, MaintenanceCode3, Period3);
        if DateSelection = DateSelection::"Posting Date" then
            MaintenanceLedgEntry.SetCurrentKey(
              "FA No.", "Depreciation Book Code", "Maintenance Code", "Posting Date")
        else
            MaintenanceLedgEntry.SetCurrentKey(
              "FA No.", "Depreciation Book Code", "Maintenance Code", "FA Posting Date");
        MaintenanceLedgEntry.SetRange("Depreciation Book Code", DeprBookCode);
        if PrintDetails then begin
            FANo := "Fixed Asset".FieldCaption("No.");
            FADescription := "Fixed Asset".FieldCaption(Description);
        end;
    end;

    var
#pragma warning disable AA0074
        Text000: Label 'Group Total';
        Text001: Label 'Group Totals';
        Text002: Label 'You must specify the starting date and the ending date.';
        Text003: Label 'The starting date is later than the ending date.';
#pragma warning disable AA0470
        Text004: Label 'The starting date must be specified when you use the option %1.';
        Text005: Label '%1 has been modified in fixed asset %2';
#pragma warning restore AA0470
#pragma warning restore AA0074
        FASetup: Record "FA Setup";
        DeprBook: Record "Depreciation Book";
        FADeprBook: Record "FA Depreciation Book";
        MaintenanceLedgEntry: Record "Maintenance Ledger Entry";
        FAGenReport: Codeunit "FA General Report";
        FAFilter: Text;
        DeprBookText: Text[50];
        GroupCodeName: Text[80];
        GroupHeadLine: Text[50];
        FANo: Text[50];
        FADescription: Text[100];
        GroupTotals: Option " ","FA Class","FA SubClass","FA Location","Main Asset","Global Dimension 1","Global Dimension 2","FA Posting Group";
        GroupAmounts: array[3] of Decimal;
        TotalAmounts: array[3] of Decimal;
        HeadLineText: array[3] of Text[50];
        Amounts: array[3] of Decimal;
        MaintenanceCode1: Code[10];
        MaintenanceCode2: Code[10];
        MaintenanceCode3: Code[10];
        Period1: Option "before Starting Date","Net Change","at Ending Date";
        Period2: Option "before Starting Date","Net Change","at Ending Date";
        Period3: Option "before Starting Date","Net Change","at Ending Date";
        StartingDate: Date;
        EndingDate: Date;
        DeprBookCode: Code[10];
        PrintDetails: Boolean;
        DateSelection: Option "FA Posting Date","Posting Date";
        i: Integer;
#pragma warning disable AA0074
        Text006: Label 'before Starting Date,Net Change,at Ending Date';
        Text007: Label ' ,FA Class,FA SubClass,FA Location,Main Asset,Global Dimension 1,Global Dimension 2,FA Posting Group';
#pragma warning restore AA0074
        CurrReportPageNoCaptionLbl: Label 'Page';
        MaintenanceAnalysisCaptionLbl: Label 'Maintenance - Analysis';
        TotalCaptionLbl: Label 'Total';

    local procedure MakeGroupTotalText()
    begin
        case GroupTotals of
            GroupTotals::"FA Class":
                GroupCodeName := "Fixed Asset".FieldCaption("FA Class Code");
            GroupTotals::"FA SubClass":
                GroupCodeName := "Fixed Asset".FieldCaption("FA Subclass Code");
            GroupTotals::"Main Asset":
                GroupCodeName := "Fixed Asset".FieldCaption("Main Asset/Component");
            GroupTotals::"Global Dimension 1":
                GroupCodeName := "Fixed Asset".FieldCaption("Global Dimension 1 Code");
            GroupTotals::"FA Location":
                GroupCodeName := "Fixed Asset".FieldCaption("FA Location Code");
            GroupTotals::"Global Dimension 2":
                GroupCodeName := "Fixed Asset".FieldCaption("Global Dimension 2 Code");
            GroupTotals::"FA Posting Group":
                GroupCodeName := "Fixed Asset".FieldCaption("FA Posting Group");
        end;
        if GroupCodeName <> '' then
            GroupCodeName := Text001 + ': ' + GroupCodeName;
    end;

    local procedure ValidateDates()
    begin
        if (EndingDate = 0D) or (StartingDate = 0D) then
            Error(Text002);

        if (EndingDate > 0D) and (StartingDate > EndingDate) then
            Error(Text003);
    end;

    local procedure MakeAmountHeadLine(i: Integer; PostingType: Code[10]; Period: Option "before Starting Date","Net Change","at Ending Date")
    begin
        if Period = Period::"before Starting Date" then
            if StartingDate < 00020101D then
                Error(
                  Text004, SelectStr(Period + 1, Text006));
        if PostingType <> '' then
            HeadLineText[i] := StrSubstNo('%1 %2', PostingType, SelectStr(Period + 1, Text006))
        else
            HeadLineText[i] := StrSubstNo('%1', SelectStr(Period + 1, Text006));
    end;

    local procedure MakeGroupHeadLine()
    begin
        case GroupTotals of
            GroupTotals::"FA Class":
                GroupHeadLine := "Fixed Asset"."FA Class Code";
            GroupTotals::"FA SubClass":
                GroupHeadLine := "Fixed Asset"."FA Subclass Code";
            GroupTotals::"Main Asset":
                begin
                    GroupHeadLine := StrSubstNo('%1 %2', SelectStr(GroupTotals + 1, Text007), "Fixed Asset"."Component of Main Asset");
                    if "Fixed Asset"."Component of Main Asset" = '' then
                        GroupHeadLine := GroupHeadLine + '*****';
                end;
            GroupTotals::"Global Dimension 1":
                GroupHeadLine := "Fixed Asset"."Global Dimension 1 Code";
            GroupTotals::"FA Location":
                GroupHeadLine := "Fixed Asset"."FA Location Code";
            GroupTotals::"Global Dimension 2":
                GroupHeadLine := "Fixed Asset"."Global Dimension 2 Code";
            GroupTotals::"FA Posting Group":
                GroupHeadLine := "Fixed Asset"."FA Posting Group";
        end;
        if GroupHeadLine = '' then
            GroupHeadLine := '*****';
    end;

    local procedure CalculateAmount(MaintenanceCode: Code[10]; Period: Option "before Starting Date","Net Change","at Ending Date"): Decimal
    var
        EndingDate2: Date;
    begin
        EndingDate2 := EndingDate;
        if EndingDate2 = 0D then
            EndingDate2 := DMY2Date(31, 12, 9999);
        if DateSelection = DateSelection::"Posting Date" then
            case Period of
                Period::"before Starting Date":
                    MaintenanceLedgEntry.SetRange("Posting Date", 0D, StartingDate - 1);
                Period::"Net Change":
                    MaintenanceLedgEntry.SetRange("Posting Date", StartingDate, EndingDate2);
                Period::"at Ending Date":
                    MaintenanceLedgEntry.SetRange("Posting Date", 0D, EndingDate2);
            end;
        if DateSelection = DateSelection::"FA Posting Date" then
            case Period of
                Period::"before Starting Date":
                    MaintenanceLedgEntry.SetRange("FA Posting Date", 0D, StartingDate - 1);
                Period::"Net Change":
                    MaintenanceLedgEntry.SetRange("FA Posting Date", StartingDate, EndingDate2);
                Period::"at Ending Date":
                    MaintenanceLedgEntry.SetRange("FA Posting Date", 0D, EndingDate2);
            end;
        MaintenanceLedgEntry.SetRange("Maintenance Code");
        if MaintenanceCode <> '' then
            MaintenanceLedgEntry.SetRange("Maintenance Code", MaintenanceCode);
        MaintenanceLedgEntry.CalcSums(Amount);
        exit(MaintenanceLedgEntry.Amount);
    end;
}

