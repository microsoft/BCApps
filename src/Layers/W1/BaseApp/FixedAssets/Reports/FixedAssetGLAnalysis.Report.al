// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Reports;

using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Posting;
using Microsoft.FixedAssets.Setup;

report 5610 "Fixed Asset - G/L Analysis"
{
    DefaultLayout = RDLC;
    RDLCLayout = './FixedAssets/Reports/FixedAssetGLAnalysis.rdlc';
    ApplicationArea = FixedAssets;
    Caption = 'Fixed Asset G/L Analysis';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Fixed Asset"; "Fixed Asset")
        {
            RequestFilterFields = "No.", "FA Class Code", "FA Subclass Code", "Budgeted Asset";
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(DeprBookText; DeprBookText)
            {
            }
            column(FixedAssetCaption; TableCaption + ': ' + FAFilter)
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
            column(GroupTotalsPrintDetails; (GroupTotals = 0) or not PrintDetails)
            {
            }
            column(PrintDetailsGroupTotals; PrintDetails and (GroupTotals <> 0))
            {
            }
            column(GroupHeadLine; GroupHeadLine)
            {
            }
            column(No_FixedAsset; "No.")
            {
            }
            column(Description_FixedAsset; Description)
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
            column(PrintDetails; PrintDetails)
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
            column(GroupTotalGroupHeadLine; Text000 + ': ' + GroupHeadLine)
            {
            }
            column(GroupTotalsNotEqualZero; GroupTotals <> 0)
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
            column(FixedAssetGLAnalysisCptn; FixedAssetGLAnalysisCptnLbl)
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
                        Error(Text005, FieldCaption("FA Posting Group"), "No.");

                Date[1] :=
                  FAGenReport.GetLastDate(
                    "No.", DateTypeNo1, EndingDate, DeprBookCode, true);
                Date[2] :=
                  FAGenReport.GetLastDate(
                    "No.", DateTypeNo2, EndingDate, DeprBookCode, true);
                Amounts[1] :=
                  FAGenReport.CalcGLPostedAmount(
                    "No.", PostingTypeNo1, Period1, StartingDate, EndingDate, DeprBookCode);

                Amounts[2] :=
                  FAGenReport.CalcGLPostedAmount(
                    "No.", PostingTypeNo2, Period2, StartingDate, EndingDate, DeprBookCode);

                Amounts[3] :=
                  FAGenReport.CalcGLPostedAmount(
                    "No.", PostingTypeNo3, Period3, StartingDate, EndingDate, DeprBookCode);

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
        SaveValues = true;
        AboutTitle = 'About Fixed Asset G/L Analysis';
        AboutText = 'The **Fixed Assets G/L Analysis** report is essential for financial management and reporting, offering detailed insights into the accounting treatment and reconciliation of subledger with the general ledger mainly validating the disposal entries. Structurally it is similar to FA Analysis report but this one is focused on GL reconciliation purpose.';

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(DepreciationBook; DeprBookCode)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Depreciation Book';
                        TableRelation = "Depreciation Book";
                        AboutTitle = 'Select Depreciation Book';
                        AboutText = 'Choose the Depreciation Book and specify the Starting Date, Ending Date for which details are to be seen in the report.';
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
                    field(DateField1; DateType1)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Date Field 1';
                        TableRelation = "FA Date Type"."FA Date Type Name" where("G/L Entry" = const(true));
                        AboutTitle = 'Select Date Field';
                        AboutText = 'Specify the Date and Amount fields which need to be shown in the report output.';
                        ToolTip = 'Specifies the first type of date that the report must show. The report has two columns in which two types of dates can be displayed. In each of the fields, select one of the available date types.';
                    }
                    field(DateField2; DateType2)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Date Field 2';
                        TableRelation = "FA Date Type"."FA Date Type Name" where("G/L Entry" = const(true));
                        ToolTip = 'Specifies the second type of date that the report must show.';
                    }
                    field(AmountField1; PostingType1)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Amount Field 1';
                        TableRelation = "FA Posting Type"."FA Posting Type Name" where("G/L Entry" = const(true));
                        ToolTip = 'Specifies an Amount field that you use to create your own analysis. The report has three columns in which three types of amounts can be displayed. Choose the relevant FA posting type for each column.';
                    }
                    field(Period1; Period1)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Period 1';
                        OptionCaption = ' ,Disposal,Bal. Disposal';
                        ToolTip = 'Specifies how the report determines the nature of the amounts in the first amount field. (Blank): The amounts consist of fixed asset ledger entries with the posting type that corresponds to the option in the amount field. Disposal: The amounts consists of fixed asset ledger entries with the posting type that corresponds to the option in the amount field if these entries have been posted to disposal accounts. Bal. Disposal: The amounts consist of fixed asset ledger entries with the posting type that corresponds to the option in the amount field if these entries have been posted to balancing disposal accounts.';
                    }
                    field(AmountField2; PostingType2)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Amount Field 2';
                        TableRelation = "FA Posting Type"."FA Posting Type Name" where("G/L Entry" = const(true));
                        ToolTip = 'Specifies an Amount field that you use to create your own analysis.';
                    }
                    field(Period2; Period2)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Period 2';
                        OptionCaption = ' ,Disposal,Bal. Disposal';
                        ToolTip = 'Specifies how the report determines the nature of the amounts in the second amount field. (Blank): The amounts consist of fixed asset ledger entries with the posting type that corresponds to the option in the amount field. Disposal: The amounts consists of fixed asset ledger entries with the posting type that corresponds to the option in the amount field if these entries have been posted to disposal accounts. Bal. Disposal: The amounts consist of fixed asset ledger entries with the posting type that corresponds to the option in the amount field if these entries have been posted to balancing disposal accounts.';
                    }
                    field(AmountField3; PostingType3)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Amount Field 3';
                        TableRelation = "FA Posting Type"."FA Posting Type Name" where("G/L Entry" = const(true));
                        ToolTip = 'Specifies an Amount field that you use to create your own analysis.';
                    }
                    field(Period3; Period3)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Period 3';
                        OptionCaption = ' ,Disposal,Bal. Disposal';
                        ToolTip = 'Specifies how the report determines the nature of the amounts in the third amount field. (Blank): The amounts consist of fixed asset ledger entries with the posting type that corresponds to the option in the amount field. Disposal: The amounts consists of fixed asset ledger entries with the posting type that corresponds to the option in the amount field if these entries have been posted to disposal accounts. Bal. Disposal: The amounts consist of fixed asset ledger entries with the posting type that corresponds to the option in the amount field if these entries have been posted to balancing disposal accounts.';
                    }
                    field(GroupTotals; GroupTotals)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Group Totals';
                        OptionCaption = ' ,FA Class,FA Subclass,FA Location,Main Asset,Global Dimension 1,Global Dimension 2,FA Posting Group';
                        AboutTitle = 'Select Group Totals';
                        AboutText = 'Specifies a group type if you want the report to group the fixed assets and print group totals.';
                        ToolTip = 'Specifies a group type if you want the report to group the fixed assets and print group totals. For example, if you have set up six FA classes, then select the FA Class option to have group totals printed for each of the six class codes. Select to see the available options. If you do not want group totals to be printed, select the blank option.';
                    }
                    field(PrintperFixedAsset; PrintDetails)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Print per Fixed Asset';
                        AboutTitle = 'Enable Print per Fixed Asset';
                        AboutText = 'Specify the options to see the report details Per Fixed Asset- print information separately for each fixed asset, Only Sold Assets - show information only for sold fixed assets.';
                        ToolTip = 'Specifies if you want the report to print information separately for each fixed asset.';
                    }
                    field(OnlySoldAssets; SalesReport)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Only Sold Assets';
                        ToolTip = 'Specifies if you want the report to show information only for sold fixed assets.';
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
        FAFilter := "Fixed Asset".GetFilters();

        if GroupTotals = GroupTotals::"FA Posting Group" then
            FAGenReport.SetFAPostingGroup("Fixed Asset", DeprBook.Code);

        FAGenReport.AppendPostingDateFilter(FAFilter, StartingDate, EndingDate);
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
        FAFilter: Text;
        DeprBookText: Text[50];
        GroupCodeName: Text[80];
        GroupHeadLine: Text[50];
        FANo: Text[50];
        FADescription: Text[100];
        GroupTotals: Option " ","FA Class","FA Subclass","FA Location","Main Asset","Global Dimension 1","Global Dimension 2","FA Posting Group";
        GroupAmounts: array[3] of Decimal;
        TotalAmounts: array[3] of Decimal;
        HeadLineText: array[5] of Text[50];
        Amounts: array[3] of Decimal;
        Date: array[2] of Date;
        i: Integer;
        Period1: Option " ",Disposal,"Bal. Disposal";
        Period2: Option " ",Disposal,"Bal. Disposal";
        Period3: Option " ",Disposal,"Bal. Disposal";
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
        SalesReport: Boolean;
        TypeExist: Boolean;

#pragma warning disable AA0074
        Text000: Label 'Group Total';
        Text001: Label 'Group Totals';
#pragma warning disable AA0470
        Text002: Label '%1 must be specified only together with the types %2, %3, %4 or %5.';
        Text003: Label 'The date type %1 is not a valid option.';
        Text004: Label 'The posting type %1 is not a valid option.';
        Text005: Label '%1 has been modified in fixed asset %2.';
#pragma warning restore AA0470
        Text006: Label ' ,FA Class,FA Subclass,FA Location,Main Asset,Global Dimension 1,Global Dimension 2,FA Posting Group';
#pragma warning restore AA0074
        CurrReportPageNoCaptionLbl: Label 'Page';
        FixedAssetGLAnalysisCptnLbl: Label 'Fixed Asset - G/L Analysis';
        TotalCaptionLbl: Label 'Total';

    local procedure SkipRecord(): Boolean
    begin
        exit(
          "Fixed Asset".Inactive or
          (FADeprBook."Acquisition Date" = 0D) or
          SalesReport and (FADeprBook."Disposal Date" = 0D));
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
            GroupCodeName := StrSubstNo('%1%2 %3', Text001, ': ', GroupCodeName);
    end;

    local procedure MakeDateHeadLine()
    begin
        if not PrintDetails then
            exit;
        HeadLineText[1] := DateType1;
        HeadLineText[2] := DateType2;
    end;

    local procedure MakeAmountHeadLine(i: Integer; PostingType: Text[50]; PostingTypeNo: Integer; var Period: Option " ",Disposal,"Bal. Disposal")
    var
#pragma warning disable AA0074
        LocalText000: Label ' ,Disposal,Bal. Disposal';
#pragma warning restore AA0074
    begin
        if PostingTypeNo = 0 then
            exit;
        if Period = Period::"Bal. Disposal" then
            if (PostingTypeNo <> FADeprBook.FieldNo("Write-Down")) and
               (PostingTypeNo <> FADeprBook.FieldNo(Appreciation)) and
               (PostingTypeNo <> FADeprBook.FieldNo("Custom 1")) and
               (PostingTypeNo <> FADeprBook.FieldNo("Custom 2"))
            then
                Error(
                  Text002,
                  SelectStr(Period + 1, LocalText000),
                  FADeprBook.FieldCaption("Write-Down"),
                  FADeprBook.FieldCaption(Appreciation),
                  FADeprBook.FieldCaption("Custom 1"),
                  FADeprBook.FieldCaption("Custom 2"));

        case PostingTypeNo of
            FADeprBook.FieldNo("Proceeds on Disposal"),
          FADeprBook.FieldNo("Gain/Loss"):
                Period := Period::" ";
            FADeprBook.FieldNo("Book Value on Disposal"):
                Period := Period::Disposal;
        end;
        HeadLineText[i] := StrSubstNo('%1 %2', PostingType, SelectStr(Period + 1, LocalText000));
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
                    GroupHeadLine := StrSubstNo('%1 %2', SelectStr(GroupTotals + 1, Text006), "Fixed Asset"."Component of Main Asset");
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

    local procedure CheckDateType(DateType: Text[30]; var DateTypeNo: Integer)
    begin
        if DateType = '' then
            exit;
        FADateType.SetRange("G/L Entry", true);
        if FADateType.Find('-') then
            repeat
                TypeExist := DateType = FADateType."FA Date Type Name";
                if TypeExist then
                    DateTypeNo := FADateType."FA Date Type No.";
            until (FADateType.Next() = 0) or TypeExist;
        if FADateType.Find('-') then;

        if not TypeExist then
            Error(Text003, DateType);
    end;

    local procedure CheckPostingType(PostingType: Text[30]; var PostingTypeNo: Integer)
    begin
        if PostingType = '' then
            exit;
        FAPostingType.SetRange("G/L Entry", true);
        if FAPostingType.Find('-') then
            repeat
                TypeExist := PostingType = FAPostingType."FA Posting Type Name";
                if TypeExist then
                    PostingTypeNo := FAPostingType."FA Posting Type No.";
            until (FAPostingType.Next() = 0) or TypeExist;
        if FAPostingType.Find('-') then;
        if not TypeExist then
            Error(Text004, PostingType);
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

    procedure SetTotalFields(GroupTotalsFrom: Option; PrintDetailsFrom: Boolean; SalesReportFrom: Boolean)
    begin
        GroupTotals := GroupTotalsFrom;
        PrintDetails := PrintDetailsFrom;
        SalesReport := SalesReportFrom;
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

