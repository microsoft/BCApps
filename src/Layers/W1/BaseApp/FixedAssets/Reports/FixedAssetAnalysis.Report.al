// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Reports;

using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Posting;
using Microsoft.FixedAssets.Setup;

report 5600 "Fixed Asset - Analysis"
{
    DefaultLayout = RDLC;
    RDLCLayout = './FixedAssets/Reports/FixedAssetAnalysis.rdlc';
    ApplicationArea = FixedAssets;
    Caption = 'Fixed Asset Analysis';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Fixed Asset"; "Fixed Asset")
        {
            RequestFilterFields = "No.", "FA Class Code", "FA Subclass Code", "Budgeted Asset";
            column(MainHeadLineText; MainHeadLineText)
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(DeprBookText; DeprBookText)
            {
            }
            column(TblCptnFAFilter; TableCaption + ': ' + FAFilter)
            {
            }
            column(FAFilter; FAFilter)
            {
            }
            column(HeadLineText1; HeadLineText[1])
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
            column(HeadLineText2; HeadLineText[2])
            {
            }
            column(HeadLineText3; HeadLineText[3])
            {
            }
            column(HeadLineText4; HeadLineText[4])
            {
            }
            column(HeadLineText5; HeadLineText[5])
            {
            }
            column(PrintDetails; PrintDetails)
            {
            }
            column(GroupTotals; GroupTotals)
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
            column(Date1; Format(Date[1]))
            {
            }
            column(Date2; Format(Date[2]))
            {
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
            column(GroupTotalGroupHeadLine; Text002 + ': ' + GroupHeadLine)
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
            column(CurrReportPAGENOCaption; CurrReportPAGENOCaptionLbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                if not FADeprBook.Get("No.", DeprBookCode) then
                    CurrReport.Skip();
                if SkipRecord() then
                    CurrReport.Skip();

                if GroupTotals = GroupTotals::"FA Posting Group" then
                    if "FA Posting Group" <> FADeprBook."FA Posting Group" then
                        Error(Text009, FieldCaption("FA Posting Group"), "No.");

                Date[1] :=
                  FAGenReport.GetLastDate(
                    "No.", DateTypeNo1, EndingDate, DeprBookCode, false);
                Date[2] :=
                  FAGenReport.GetLastDate(
                    "No.", DateTypeNo2, EndingDate, DeprBookCode, false);

                BeforeAmount := 0;
                EndingAmount := 0;
                if BudgetReport then
                    BudgetDepreciation.Calculate(
                      "No.", GetStartDate(StartingDate), EndingDate, DeprBookCode, BeforeAmount, EndingAmount);

                if SetAmountToZero(PostingTypeNo1, Period1) then
                    Amounts[1] := 0
                else
                    Amounts[1] :=
                      FAGenReport.CalcFAPostedAmount(
                        "No.", PostingTypeNo1, Period1, StartingDate, EndingDate,
                        DeprBookCode, BeforeAmount, EndingAmount, false, false);

                if SetAmountToZero(PostingTypeNo2, Period2) then
                    Amounts[2] := 0
                else
                    Amounts[2] :=
                      FAGenReport.CalcFAPostedAmount(
                        "No.", PostingTypeNo2, Period2, StartingDate, EndingDate,
                        DeprBookCode, BeforeAmount, EndingAmount, false, false);

                if SetAmountToZero(PostingTypeNo3, Period3) then
                    Amounts[3] := 0
                else
                    Amounts[3] :=
                      FAGenReport.CalcFAPostedAmount(
                        "No.", PostingTypeNo3, Period3, StartingDate, EndingDate,
                        DeprBookCode, BeforeAmount, EndingAmount, false, false);

                for i := 1 to 3 do
                    GroupAmounts[i] := 0;
                MakeGroupHeadLine();
            end;

            trigger OnPreDataItem()
            begin
                case GroupTotals of
                    GroupTotals::"FA Class":
                        SetCurrentKey("FA Class Code");
                    GroupTotals::"FA Subclass":
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
                FAPostingType.CreateTypes();
                FADateType.CreateTypes();
                CheckDateType(DateType1, DateTypeNo1);
                CheckDateType(DateType2, DateTypeNo2);
                CheckPostingType(PostingType1, PostingTypeNo1);
                CheckPostingType(PostingType2, PostingTypeNo2);
                CheckPostingType(PostingType3, PostingTypeNo3);
                MakeGroupTotalText();
                FAGenReport.ValidateDates(StartingDate, EndingDate);
                MakeDateHeadLine();
                MakeAmountHeadLine(3, PostingType1, PostingTypeNo1, Period1);
                MakeAmountHeadLine(4, PostingType2, PostingTypeNo2, Period2);
                MakeAmountHeadLine(5, PostingType3, PostingTypeNo3, Period3);
            end;
        }
    }

    requestpage
    {
        Permissions = TableData "FA Setup" = r;
        SaveValues = true;
        AboutTitle = 'About Fixed Asset Analysis';
        AboutText = '**Fixed Asset Analysis** Report is a flexible reporting option that provides a comprehensive examination of an organization''s fixed assets, such as property, plant, and equipment (PP&E), for different purposes. If the purpose is to reconcile asset values with GL then fields like acquisition, depreciation can be selected. If the purpose is about reviewing net value along with write down value, users can use this report accordingly by choosing the relevant amount fields and amount fields for multiple periods.';

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
                        AboutTitle = 'Select Depreciation Book';
                        AboutText = 'Chose the Depreciation Book and specify the Starting Date, Ending Date for which details are to be seen , these are mandatory fields.';
                        ToolTip = 'Specifies the code for the depreciation book to be included in the report or batch job.';
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
                        ToolTip = 'Specifies the date when you want the report to end.';
                    }
                    field(DateType1; DateType1)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Date Field 1';
                        TableRelation = "FA Date Type"."FA Date Type Name" where("FA Entry" = const(true));
                        AboutTitle = 'Select Date Field';
                        AboutText = 'Specify the Date and Amount fields which need to be shown in the report depending on the purpose of the output.';
                        ToolTip = 'Specifies the first type of date that the report must show. The report has two columns in which two types of dates can be displayed. In each of the fields, select one of the available date types.';
                    }
                    field(DateType2; DateType2)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Date Field 2';
                        TableRelation = "FA Date Type"."FA Date Type Name" where("FA Entry" = const(true));
                        ToolTip = 'Specifies the second type of date that the report must show.';
                    }
                    field(PostingType1; PostingType1)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Amount Field 1';
                        TableRelation = "FA Posting Type"."FA Posting Type Name" where("FA Entry" = const(true));
                        ToolTip = 'Specifies an Amount field that you use to create your own analysis.';
                    }
                    field(Period1; Period1)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Period 1';
                        OptionCaption = 'before Starting Date,Net Change,at Ending Date';
                        ToolTip = 'Specifies how the report determines the nature of the amounts in the first amount field. (Blank): The amounts consist of fixed asset ledger entries with the posting type that corresponds to the option in the amount field. Disposal: The amounts consists of fixed asset ledger entries with the posting type that corresponds to the option in the amount field if these entries have been posted to disposal accounts. Bal. Disposal: The amounts consist of fixed asset ledger entries with the posting type that corresponds to the option in the amount field if these entries have been posted to balancing disposal accounts.';
                    }
                    field(PostingType2; PostingType2)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Amount Field 2';
                        TableRelation = "FA Posting Type"."FA Posting Type Name" where("FA Entry" = const(true));
                        ToolTip = 'Specifies an Amount field that you use to create your own analysis.';
                    }
                    field(Period2; Period2)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Period 2';
                        OptionCaption = 'before Starting Date,Net Change,at Ending Date';
                        ToolTip = 'Specifies how the report determines the nature of the amounts in the second amount field. (Blank): The amounts consist of fixed asset ledger entries with the posting type that corresponds to the option in the amount field. Disposal: The amounts consists of fixed asset ledger entries with the posting type that corresponds to the option in the amount field if these entries have been posted to disposal accounts. Bal. Disposal: The amounts consist of fixed asset ledger entries with the posting type that corresponds to the option in the amount field if these entries have been posted to balancing disposal accounts.';
                    }
                    field(PostingType3; PostingType3)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Amount Field 3';
                        TableRelation = "FA Posting Type"."FA Posting Type Name" where("FA Entry" = const(true));
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
                        OptionCaption = ' ,FA Class,FA Subclass,FA Location,Main Asset,Global Dimension 1,Global Dimension 2,FA Posting Group';
                        AboutTitle = 'Select Group Totals';
                        AboutText = 'Enter the grouping criteria as needed from the option values.Enable the options to see the report details Per Fixed Asset- print information separately for each fixed asset, Only Sold Assets - show information only for sold fixed assets, Budget Report - Calculate future depreciation and book value. This is valid only if you have selected Depreciation and Book Value for Amount Field 1, 2 or 3.';
                        ToolTip = 'Specifies if you want the report to group fixed assets and print totals using the category defined in this field. For example, maintenance expenses for fixed assets can be shown for each fixed asset class.';
                    }
                    field(PrintDetails; PrintDetails)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Print per Fixed Asset';
                        ToolTip = 'Specifies if you want the report to print information separately for each fixed asset.';
                    }
                    field(SalesReport; SalesReport)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Only Sold Assets';
                        ToolTip = 'Specifies if you want the report to show information only for sold fixed assets.';
                    }
                    field(BudgetReport; BudgetReport)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Budget Report';
                        ToolTip = 'Specifies if you want the report to calculate future depreciation and book value. This is valid only if you have selected Depreciation and Book Value for Amount Field 1, 2 or 3.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            GetFASetup();
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
        FAGenReport.AppendFAPostingFilter("Fixed Asset", StartingDate, EndingDate);
        FAFilter := "Fixed Asset".GetFilters();
        MainHeadLineText := Text000;
        if SalesReport then
            MainHeadLineText := StrSubstNo('%1 %2', MainHeadLineText, OnlySoldAssetsLbl);
        if BudgetReport then
            MainHeadLineText := StrSubstNo('%1 %2', MainHeadLineText, Text001);
        DeprBookText := StrSubstNo('%1%2 %3', DeprBook.TableCaption(), ':', DeprBookCode);
        if PrintDetails then begin
            FANo := "Fixed Asset".FieldCaption("No.");
            FADescription := "Fixed Asset".FieldCaption(Description);
        end;
    end;

    var
        FASetup: Record "FA Setup";
        DeprBook: Record "Depreciation Book";
        FADeprBook: Record "FA Depreciation Book";
        FAPostingType: Record "FA Posting Type";
        FADateType: Record "FA Date Type";
        FAGenReport: Codeunit "FA General Report";
        BudgetDepreciation: Codeunit "Budget Depreciation";
        FAFilter: Text;
        MainHeadLineText: Text[100];
        DeprBookText: Text[50];
        GroupCodeName: Text[80];
        GroupHeadLine: Text[50];
        FANo: Text[50];
        FADescription: Text[100];
        GroupTotals: Option " ","FA Class","FA Subclass","FA Location","Main Asset","Global Dimension 1","Global Dimension 2","FA Posting Group";
        GroupAmounts: array[3] of Decimal;
        TotalAmounts: array[3] of Decimal;
        Amounts: array[3] of Decimal;
        Date: array[2] of Date;
        i: Integer;
        Period1: Option "before Starting Date","Net Change","at Ending Date";
        Period2: Option "before Starting Date","Net Change","at Ending Date";
        Period3: Option "before Starting Date","Net Change","at Ending Date";
        PostingType1: Text[30];
        PostingType2: Text[30];
        PostingType3: Text[30];
        PostingTypeNo1: Integer;
        PostingTypeNo2: Integer;
        PostingTypeNo3: Integer;
        DateType1: Text[30];
        DateType2: Text[30];
        DateTypeNo1: Integer;
        DateTypeNo2: Integer;
        StartingDate: Date;
        EndingDate: Date;
        DeprBookCode: Code[10];
        PrintDetails: Boolean;
        BudgetReport: Boolean;
        BeforeAmount: Decimal;
        EndingAmount: Decimal;
        AcquisitionDate: Date;
        DisposalDate: Date;
        SalesReport: Boolean;
        TypeExist: Boolean;

#pragma warning disable AA0074
        Text000: Label 'Fixed Asset - Analysis';
        Text001: Label '(Budget Report)';
        Text002: Label 'Group Total';
        Text003: Label 'Sold';
#pragma warning disable AA0470
        Text004: Label 'Group Totals: %1';
        Text005: Label '%1 or %2 must be specified only together with the option %3.';
        Text006: Label 'The Starting Date must be specified when you use the option %1.';
        Text007: Label 'The date type %1 is not a valid option.';
        Text008: Label 'The posting type %1 is not a valid option.';
        Text009: Label '%1 has been modified in fixed asset %2.';
#pragma warning restore AA0470
        Text010: Label 'before Starting Date,Net Change,at Ending Date';
        Text011: Label ' ,FA Class,FA Subclass,FA Location,Main Asset,Global Dimension 1,Global Dimension 2,FA Posting Group';
#pragma warning restore AA0074
        CurrReportPAGENOCaptionLbl: Label 'Page';
        TotalCaptionLbl: Label 'Total';
        OnlySoldAssetsLbl: Label '(Only Sold Assets)';

    protected var
        HeadLineText: array[5] of Text[50];

    local procedure SkipRecord(): Boolean
    begin
        AcquisitionDate := FADeprBook."Acquisition Date";
        DisposalDate := FADeprBook."Disposal Date";

        if "Fixed Asset".Inactive then
            exit(true);
        if AcquisitionDate = 0D then
            exit(true);
        if (AcquisitionDate > EndingDate) and (EndingDate > 0D) then
            exit(true);
        if SalesReport and (DisposalDate = 0D) then
            exit(true);
        if SalesReport and (EndingDate > 0D) and
           ((DisposalDate > EndingDate) or (DisposalDate < StartingDate))
        then
            exit(true);

        if not SalesReport and (DisposalDate > 0D) and (DisposalDate < StartingDate) then
            exit(true);
        exit(false);
    end;

    local procedure SetSalesMark(): Text[30]
    begin
        if DisposalDate > 0D then
            if (EndingDate = 0D) or (DisposalDate <= EndingDate) then
                exit(Text003);
        exit('');
    end;

    local procedure MakeGroupTotalText()
    begin
        case GroupTotals of
            GroupTotals::"FA Class":
                GroupCodeName := "Fixed Asset".FieldCaption("FA Class Code");
            GroupTotals::"FA Subclass":
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
            GroupCodeName := StrSubstNo(Text004, GroupCodeName);
    end;

    local procedure MakeDateHeadLine()
    begin
        if not PrintDetails then
            exit;
        HeadLineText[1] := DateType1;
        HeadLineText[2] := DateType2;
    end;

    local procedure MakeAmountHeadLine(i: Integer; PostingType: Text[50]; PostingTypeNo: Integer; Period: Option "before Starting Date","Net Change","at Ending Date")
    begin
        if PostingTypeNo = 0 then
            exit;
        case PostingTypeNo of
            FADeprBook.FieldNo("Proceeds on Disposal"),
          FADeprBook.FieldNo("Gain/Loss"):
                if Period <> Period::"at Ending Date" then begin
                    Period := Period::"at Ending Date";
                    Error(
                      Text005,
                      FADeprBook.FieldCaption("Proceeds on Disposal"),
                      FADeprBook.FieldCaption("Gain/Loss"),
                      SelectStr(Period + 1, Text010));
                end;
        end;
        if Period = Period::"before Starting Date" then
            if StartingDate < 00020101D then
                Error(
                  Text006, SelectStr(Period + 1, Text010));

        HeadLineText[i] := StrSubstNo('%1 %2', PostingType, SelectStr(Period + 1, Text010));
    end;

    local procedure MakeGroupHeadLine()
    begin
        case GroupTotals of
            GroupTotals::"FA Class":
                GroupHeadLine := "Fixed Asset"."FA Class Code";
            GroupTotals::"FA Subclass":
                GroupHeadLine := "Fixed Asset"."FA Subclass Code";
            GroupTotals::"Main Asset":
                begin
                    GroupHeadLine := StrSubstNo('%1 %2', SelectStr(GroupTotals + 1, Text011), "Fixed Asset"."Component of Main Asset");
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

    local procedure SetAmountToZero(PostingTypeNo: Integer; Period: Option "before Starting Date","Net Change","at Ending Date"): Boolean
    begin
        case PostingTypeNo of
            FADeprBook.FieldNo("Proceeds on Disposal"),
          FADeprBook.FieldNo("Gain/Loss"):
                exit(false);
        end;
        if not SalesReport and (Period = Period::"at Ending Date") and (SetSalesMark() <> '') then
            exit(true);
        exit(false);
    end;

    local procedure GetStartDate(StartDate: Date): Date
    begin
        if StartDate <= 00000101D then
            exit(0D);

        exit(StartDate - 1);
    end;

    local procedure CheckDateType(DateType: Text[30]; var DateTypeNo: Integer)
    begin
        DateTypeNo := 0;
        if DateType = '' then
            exit;
        FADateType.SetRange("FA Entry", true);
        if FADateType.Find('-') then
            repeat
                TypeExist := DateType = FADateType."FA Date Type Name";
                if TypeExist then
                    DateTypeNo := FADateType."FA Date Type No.";
            until (FADateType.Next() = 0) or TypeExist;

        if not TypeExist then
            Error(Text007, DateType);
    end;

    local procedure CheckPostingType(PostingType: Text[30]; var PostingTypeNo: Integer)
    begin
        PostingTypeNo := 0;
        if PostingType = '' then
            exit;
        FAPostingType.SetRange("FA Entry", true);
        if FAPostingType.Find('-') then
            repeat
                TypeExist := PostingType = FAPostingType."FA Posting Type Name";
                if TypeExist then
                    PostingTypeNo := FAPostingType."FA Posting Type No.";
            until (FAPostingType.Next() = 0) or TypeExist;
        if not TypeExist then
            Error(Text008, PostingType);
    end;

    procedure SetMandatoryFields(DepreciationBookCodeFrom: Code[10]; StartingDateFrom: Date; EndingDateFrom: Date)
    begin
        DeprBookCode := DepreciationBookCodeFrom;
        StartingDate := StartingDateFrom;
        EndingDate := EndingDateFrom;
    end;

    procedure SetDateType(DateType1From: Text[30]; DateType2From: Text[30])
    begin
        DateType1 := DateType1From;
        DateType2 := DateType2From;
    end;

    procedure SetPostingType(PostingType1From: Text[30]; PostingType2From: Text[30]; PostingType3From: Text[30])
    begin
        PostingType1 := PostingType1From;
        PostingType2 := PostingType2From;
        PostingType3 := PostingType3From;
    end;

    procedure SetPeriod(Period1From: Option; Period2From: Option; Period3From: Option)
    begin
        Period1 := Period1From;
        Period2 := Period2From;
        Period3 := Period3From;
    end;

    procedure SetTotalFields(GroupTotalsFrom: Option; PrintDetailsFrom: Boolean; SalesReportFrom: Boolean; BudgetReportFrom: Boolean)
    begin
        GroupTotals := GroupTotalsFrom;
        PrintDetails := PrintDetailsFrom;
        SalesReport := SalesReportFrom;
        BudgetReport := BudgetReportFrom;
    end;

    procedure GetFASetup()
    begin
        if DeprBookCode = '' then begin
            FASetup.Get();
            DeprBookCode := FASetup."Default Depr. Book";
        end;
        FAPostingType.CreateTypes();
        FADateType.CreateTypes();
    end;
}

