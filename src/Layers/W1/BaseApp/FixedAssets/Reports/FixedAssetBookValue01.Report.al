// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Reports;

using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Posting;
using Microsoft.FixedAssets.Setup;

report 5605 "Fixed Asset - Book Value 01"
{
    ApplicationArea = FixedAssets;
    Caption = 'Fixed Asset Book Value 01';
    PreviewMode = PrintLayout;
    UsageCategory = ReportsAndAnalysis;
    DefaultRenderingLayout = RDLCLayout;

    dataset
    {
        dataitem("Fixed Asset"; "Fixed Asset")
        {
            RequestFilterFields = "No.", "FA Class Code", "FA Subclass Code", "Budgeted Asset";
            column(MainHeadLineText_FA; MainHeadLineText)
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(DeprBookText_FA; DeprBookText)
            {
            }
            column(TableFilter_FA; TableCaption + ': ' + FAFilter)
            {
            }
            column(Filter_FA; FAFilter)
            {
            }
            column(PrintDetails; PrintDetails)
            {
            }
            column(GroupTotals; SelectStr(GroupTotals + 1, GroupTotalsTxt))
            {
            }
            column(GroupCodeName; GroupCodeName)
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
            column(HeadLineText4; HeadLineText[4])
            {
            }
            column(HeadLineText5; HeadLineText[5])
            {
            }
            column(HeadLineText6; HeadLineText[6])
            {
            }
            column(HeadLineText7; HeadLineText[7])
            {
            }
            column(HeadLineText8; HeadLineText[8])
            {
            }
            column(HeadLineText9; HeadLineText[9])
            {
            }
            column(HeadLineText10; HeadLineText[10])
            {
            }
            column(FANo; FANo)
            {
            }
            column(Desc_FA; FADescription)
            {
            }
            column(DerogatoryOpeningHeading; HeadLineText[11])
            {
            }
            column(DerogatoryIncreaseHeading; HeadLineText[12])
            {
            }
            column(DerogatoryDecreaseHeading; HeadLineText[13])
            {
            }
            column(DerogatoryClosingHeading; HeadLineText[14])
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
            column(StartAmounts1; StartAmounts[1])
            {
                AutoFormatType = 1;
            }
            column(NetChangeAmounts1; NetChangeAmounts[1])
            {
                AutoFormatType = 1;
            }
            column(DisposalAmounts1; DisposalAmounts[1])
            {
                AutoFormatType = 1;
            }
            column(TotalEndingAmounts1; TotalEndingAmounts[1])
            {
                AutoFormatType = 1;
            }
            column(StartAmounts2; StartAmounts[2])
            {
                AutoFormatType = 1;
            }
            column(NetChangeAmounts2; NetChangeAmounts[2])
            {
                AutoFormatType = 1;
            }
            column(DisposalAmounts2; DisposalAmounts[2])
            {
                AutoFormatType = 1;
            }
            column(TotalEndingAmounts2; TotalEndingAmounts[2])
            {
                AutoFormatType = 1;
            }
            column(BookValueAtStartingDate; BookValueAtStartingDate)
            {
                AutoFormatType = 1;
            }
            column(BookValueAtEndingDate; BookValueAtEndingDate)
            {
                AutoFormatType = 1;
            }
            column(DerogatoryOpeningAmount; StartAmounts[7])
            {
                AutoFormatType = 1;
            }
            column(DerogatoryIncreaseAmount; NetChangeAmounts[7])
            {
                AutoFormatType = 1;
            }
            column(DerogatoryDecreaseAmount; DisposalAmounts[7])
            {
                AutoFormatType = 1;
            }
            column(DerogatoryClosingAmount; TotalEndingAmounts[7])
            {
                AutoFormatType = 1;
            }
            column(AccountingDeprBookCode; AccountingDeprBookCode)
            {
            }
            column(AccountingDeprMethod; AccountingDeprMethod)
            {
            }
            column(AccountingDeprStartingDate; AccountingDeprStartingDate)
            {
            }
            column(AccountingDeprEndingDate; AccountingDeprEndingDate)
            {
            }
            column(AccountingDecliningBalancePct; AccountingDecliningBalancePct)
            {
                AutoFormatType = 1;
            }
            column(PrintFASetup; PrintFASetup)
            {
            }
            column(DerogatoryDeprBookCode; DerogatoryDeprBookCode)
            {
            }
            column(DerogatoryDeprMethod; DerogatoryDeprMethod)
            {
            }
            column(DerogatoryDeprStartingDate; DerogatoryDeprStartingDate)
            {
            }
            column(DerogatoryDeprEndingDate; DerogatoryDeprEndingDate)
            {
            }
            column(DerogatoryDecliningBalancePct; DerogatoryDecliningBalancePct)
            {
                AutoFormatType = 1;
            }
            column(HasDerogatorySetup; HasDerogatorySetup)
            {
            }
            column(HasDerogatoryBook; HasDerogatoryBook)
            {
            }
            column(FormatGrpTotGroupHeadLine; Format(GroupTotalLbl + ': ' + GroupHeadLine))
            {
            }
            column(GroupStartAmounts1; GroupStartAmounts[1])
            {
                AutoFormatType = 1;
            }
            column(GroupNetChangeAmounts1; GroupNetChangeAmounts[1])
            {
                AutoFormatType = 1;
            }
            column(GroupDisposalAmounts1; GroupDisposalAmounts[1])
            {
                AutoFormatType = 1;
            }
            column(GroupStartAmounts2; GroupStartAmounts[2])
            {
                AutoFormatType = 1;
            }
            column(GroupNetChangeAmounts2; GroupNetChangeAmounts[2])
            {
                AutoFormatType = 1;
            }
            column(GroupDisposalAmounts2; GroupDisposalAmounts[2])
            {
                AutoFormatType = 1;
            }
            column(DerogatoryGroupOpeningAmount; GroupStartAmounts[7])
            {
                AutoFormatType = 1;
            }
            column(DerogatoryGroupIncreaseAmount; GroupNetChangeAmounts[7])
            {
                AutoFormatType = 1;
            }
            column(DerogatoryGroupDecreaseAmount; GroupDisposalAmounts[7])
            {
                AutoFormatType = 1;
            }
            column(TotalStartAmounts1; TotalStartAmounts[1])
            {
                AutoFormatType = 1;
            }
            column(TotalNetChangeAmounts1; TotalNetChangeAmounts[1])
            {
                AutoFormatType = 1;
            }
            column(TotalDisposalAmounts1; TotalDisposalAmounts[1])
            {
                AutoFormatType = 1;
            }
            column(TotalStartAmounts2; TotalStartAmounts[2])
            {
                AutoFormatType = 1;
            }
            column(TotalNetChangeAmounts2; TotalNetChangeAmounts[2])
            {
                AutoFormatType = 1;
            }
            column(TotalDisposalAmounts2; TotalDisposalAmounts[2])
            {
                AutoFormatType = 1;
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            var
                NumberOfTypesForThisFA: Integer;
            begin
                if not FADeprBook.Get("No.", DeprBookCode) then
                    CurrReport.Skip();
                if SkipRecord() then
                    CurrReport.Skip();

                NumberOfTypesForThisFA := NumberOfTypes - 1;
                HasDerogatorySetup := false;
                Clear(FADeprBook2);
                FADeprBook2.SetLoadFields(
                    "Depreciation Method", "Depreciation Starting Date", "Depreciation Ending Date", "Declining-Balance %");
                if HasDerogatoryBook and FADeprBook2.Get("No.", DerogDeprBook.Code) then begin
                    HasDerogatorySetup := true;
                    NumberOfTypesForThisFA := NumberOfTypes;
                end;

                Clear(StartAmounts[7]);
                Clear(NetChangeAmounts[7]);
                Clear(DisposalAmounts[7]);

                if GroupTotals = GroupTotals::"FA Posting Group" then
                    if "FA Posting Group" <> FADeprBook."FA Posting Group" then
                        Error(FAPostingGroupModifiedErr, FieldCaption("FA Posting Group"), "No.");

                BeforeAmount := 0;
                EndingAmount := 0;
                if BudgetReport then
                    BudgetDepreciation.Calculate(
                      "No.", GetStartingDate(StartingDate), EndingDate, DeprBookCode, BeforeAmount, EndingAmount);

                i := 0;
                while i < NumberOfTypesForThisFA do begin
                    i := i + 1;
                    case i of
                        1:
                            PostingType := FADeprBook.FieldNo("Acquisition Cost");
                        2:
                            PostingType := FADeprBook.FieldNo(Depreciation);
                        3:
                            PostingType := FADeprBook.FieldNo("Write-Down");
                        4:
                            PostingType := FADeprBook.FieldNo(Appreciation);
                        5:
                            PostingType := FADeprBook.FieldNo("Custom 1");
                        6:
                            PostingType := FADeprBook.FieldNo("Custom 2");
                        7:
                            PostingType := FADeprBook.FieldNo("Derogatory Amount");
                    end;
                    if StartingDate <= 00000101D then
                        StartAmounts[i] := 0
                    else
                        StartAmounts[i] := FAGenReport.CalcFAPostedAmount("No.", PostingType, Period1, StartingDate,
                            EndingDate, DeprBookCode, BeforeAmount, EndingAmount, false, true);
                    NetChangeAmounts[i] :=
                      FAGenReport.CalcFAPostedAmount(
                        "No.", PostingType, Period2, StartingDate, EndingDate,
                        DeprBookCode, BeforeAmount, EndingAmount, false, true);
                    if i = 7 then begin
                        FAGenReport.SetSign(true);
                        NetChangeAmounts[i] :=
                          -(FAGenReport.CalcFAPostedAmount(
                              "No.", PostingType, Period2, StartingDate, EndingDate,
                              DeprBookCode, BeforeAmount, EndingAmount, false, true));
                        FAGenReport.SetSign(false);
                        DisposalAmounts[i] :=
                          FAGenReport.CalcFAPostedAmount(
                            "No.", PostingType, Period2, StartingDate, EndingDate,
                            DeprBookCode, BeforeAmount, EndingAmount, false, true);
                        StartAmounts[i] :=
                          FAGenReport.CalcFAPostedAmount(
                            "No.", PostingType, Period1, StartingDate,
                            EndingDate, DeprBookCode, BeforeAmount, EndingAmount, false, true);
                    end;
                    if GetPeriodDisposal() then
                        DisposalAmounts[i] := -(StartAmounts[i] + NetChangeAmounts[i])
                    else
                        if i <> 7 then
                            DisposalAmounts[i] := 0;
                    if (i >= 3) and (i <> 7) then
                        AddPostingType(i - 3);
                end;
                for j := 1 to NumberOfTypes do
                    TotalEndingAmounts[j] := StartAmounts[j] + NetChangeAmounts[j] + DisposalAmounts[j];
                BookValueAtEndingDate := 0;
                BookValueAtStartingDate := 0;
                for j := 1 to NumberOfTypes - 1 do begin
                    BookValueAtEndingDate := BookValueAtEndingDate + TotalEndingAmounts[j];
                    BookValueAtStartingDate := BookValueAtStartingDate + StartAmounts[j];
                end;

                MakeGroupHeadLine();
                UpdateTotals();
                CreateGroupTotals();
                GetDeprBookInfo();
                GetDerogDeprBookInfo();
            end;

            trigger OnPostDataItem()
            begin
                CreateTotals();
            end;

            trigger OnPreDataItem()
            begin
                case GroupTotals of
                    GroupTotals::"FA Class":
                        SetCurrentKey("FA Class Code");
                    GroupTotals::"FA Subclass":
                        SetCurrentKey("FA Subclass Code");
                    GroupTotals::"FA Location":
                        SetCurrentKey("FA Location Code");
                    GroupTotals::"Main Asset":
                        SetCurrentKey("Component of Main Asset");
                    GroupTotals::"Global Dimension 1":
                        SetCurrentKey("Global Dimension 1 Code");
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
        AboutTitle = 'About Fixed Asset Book Value 01';
        AboutText = 'The **Fixed Asset - Book Value 01** report helps obtain detailed information for different groups of assets about acquisition cost, depreciation value and book value. The detailed information are also summarized at a group level if needed. The report shows the output structured over multiple columns.';

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
                        AboutText = 'Choose the Depreciation Book and specify the Starting Date, Ending Date for which details are to be seen and group the total with the applicable option.';
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
                    field(GroupTotals; GroupTotals)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Group Totals';
                        OptionCaption = ' ,FA Class,FA Subclass,FA Location,Main Asset,Global Dimension 1,Global Dimension 2,FA Posting Group';
                        ToolTip = 'Specifies if you want the report to group fixed assets and print totals using the category defined in this field. For example, maintenance expenses for fixed assets can be shown for each fixed asset class.';
                    }
                    field(PrintDetails; PrintDetails)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Print per Fixed Asset';
                        AboutTitle = 'Enable Print per Fixed Asset';
                        AboutText = 'Specify the applicable options to view the report details as required.';
                        ToolTip = 'Specifies if you want the report to print information separately for each fixed asset.';

                        trigger OnValidate()
                        begin
                            if not PrintDetails then
                                if PrintFASetup then
                                    PrintFASetup := false;
                        end;
                    }
                    field(BudgetReport; BudgetReport)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Budget Report';
                        ToolTip = 'Specifies if you want the report to calculate future depreciation and book value. This is valid only if you have selected Depreciation and Book Value for Amount Field 1, 2 or 3.';
                    }
                    field(Print_FASetup; PrintFASetup)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Print FA Setup';
                        ToolTip = 'Specifies whether the report must include the depreciation book setup information for each fixed asset.';

                        trigger OnValidate()
                        begin
                            if PrintFASetup then
                                if not PrintDetails then
                                    PrintDetails := true;
                        end;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            GetDepreciationBookCode();
        end;
    }

    rendering
    {
        layout(RDLCLayout)
        {
            Type = RDLC;
            LayoutFile = './FixedAssets/Reports/FixedAssetBookValue01.rdlc';
            Summary = 'Report layout made in the legacy RDLC format. Use an RDLC editor to modify the layout.';
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        NumberOfTypes := 7;
        Clear(DerogDeprBook);
        DeprBook.Get(DeprBookCode);
        HasDerogatoryBook := DerogatoryPostingMgt.GetDerogatoryBook(DeprBookCode, DerogDeprBook);

        if GroupTotals = GroupTotals::"FA Posting Group" then
            FAGenReport.SetFAPostingGroup("Fixed Asset", DeprBook.Code);
        FAGenReport.AppendFAPostingFilter("Fixed Asset", StartingDate, EndingDate);
        FAFilter := "Fixed Asset".GetFilters();
        MainHeadLineText := ReportTitleLbl;
        if BudgetReport then
            MainHeadLineText := StrSubstNo('%1 %2', MainHeadLineText, BudgetReportLbl);
        DeprBookText := StrSubstNo('%1%2 %3', DeprBook.TableCaption(), ':', DeprBookCode);
        MakeGroupTotalText();
        FAGenReport.ValidateDates(StartingDate, EndingDate);
        MakeDateText();
        MakeHeadLine();
        if PrintDetails then begin
            FANo := "Fixed Asset".FieldCaption("No.");
            FADescription := "Fixed Asset".FieldCaption(Description);
        end;
        Period1 := Period1::"Before Starting Date";
        Period2 := Period2::"Net Change";
    end;

    var
        FASetup: Record "FA Setup";
        DeprBook: Record "Depreciation Book";
        FA: Record "Fixed Asset";
        FAPostingTypeSetup: Record "FA Posting Type Setup";
        DerogDeprBook: Record "Depreciation Book";
        FADeprBook2: Record "FA Depreciation Book";
        DerogatoryPostingMgt: Codeunit "Derogatory Posting Mgt.";
        FAGenReport: Codeunit "FA General Report";
        BudgetDepreciation: Codeunit "Budget Depreciation";
        FAFilter: Text;
        MainHeadLineText: Text[100];
        DeprBookText: Text[50];
        GroupCodeName: Text[50];
        GroupHeadLine: Text[50];
        FANo: Text[50];
        FADescription: Text[100];
        GroupTotals: Option " ","FA Class","FA Subclass","FA Location","Main Asset","Global Dimension 1","Global Dimension 2","FA Posting Group";
        HeadLineText: array[14] of Text[50];
        StartAmounts: array[7] of Decimal;
        NetChangeAmounts: array[7] of Decimal;
        DisposalAmounts: array[7] of Decimal;
        GroupStartAmounts: array[7] of Decimal;
        GroupNetChangeAmounts: array[7] of Decimal;
        GroupDisposalAmounts: array[7] of Decimal;
        TotalStartAmounts: array[7] of Decimal;
        TotalNetChangeAmounts: array[7] of Decimal;
        TotalDisposalAmounts: array[7] of Decimal;
        TotalEndingAmounts: array[7] of Decimal;
        BookValueAtStartingDate: Decimal;
        BookValueAtEndingDate: Decimal;
        i: Integer;
        j: Integer;
        NumberOfTypes: Integer;
        PostingType: Integer;
        Period1: Option "Before Starting Date","Net Change","at Ending Date";
        Period2: Option "Before Starting Date","Net Change","at Ending Date";
        BudgetReport: Boolean;
        BeforeAmount: Decimal;
        EndingAmount: Decimal;
        AcquisitionDate: Date;
        DisposalDate: Date;
        StartText: Text[30];
        EndText: Text[30];
        AccountingDeprBookCode: Code[10];
        AccountingDeprMethod: Text[30];
        AccountingDeprStartingDate: Date;
        AccountingDeprEndingDate: Date;
        AccountingDecliningBalancePct: Decimal;
        DerogatoryDeprBookCode: Code[10];
        DerogatoryDeprMethod: Text[30];
        DerogatoryDeprStartingDate: Date;
        DerogatoryDeprEndingDate: Date;
        DerogatoryDecliningBalancePct: Decimal;
        PrintFASetup: Boolean;
        HasDerogatorySetup: Boolean;
        HasDerogatoryBook: Boolean;

        ReportTitleLbl: Label 'Fixed Asset - Book Value 01';
        BudgetReportLbl: Label '(Budget Report)';
        GroupTotalLbl: Label 'Group Total';
        GroupTotalsLbl: Label 'Group Totals';
        InPeriodLbl: Label 'in Period';
        DisposalLbl: Label 'Disposal';
        AdditionLbl: Label 'Addition';
        FAPostingGroupModifiedErr: Label '%1 has been modified in fixed asset %2.', Comment = '%1 = FA Posting Group field caption, %2 = Fixed Asset No.';
        IncreasedInPeriodTxt: Label 'Increased in Period';
        DecreasedInPeriodTxt: Label 'Decreased in Period';
        PageCaptionLbl: Label 'Page';
        TotalCaptionLbl: Label 'Total';
        GroupTotalsTxt: Label ' ,FA Class,FA Subclass,FA Location,Main Asset,Global Dimension 1,Global Dimension 2,FA Posting Group';

    protected var
        FADeprBook: Record "FA Depreciation Book";
        DeprBookCode: Code[10];
        PrintDetails: Boolean;
        StartingDate: Date;
        EndingDate: Date;

    local procedure AddPostingType(PostingType: Option "Write-Down",Appreciation,"Custom 1","Custom 2")
    var
        i: Integer;
        j: Integer;
    begin
        i := PostingType + 3;
        case PostingType of
            PostingType::"Write-Down":
                FAPostingTypeSetup.Get(DeprBookCode, FAPostingTypeSetup."FA Posting Type"::"Write-Down");
            PostingType::Appreciation:
                FAPostingTypeSetup.Get(DeprBookCode, FAPostingTypeSetup."FA Posting Type"::Appreciation);
            PostingType::"Custom 1":
                FAPostingTypeSetup.Get(DeprBookCode, FAPostingTypeSetup."FA Posting Type"::"Custom 1");
            PostingType::"Custom 2":
                FAPostingTypeSetup.Get(DeprBookCode, FAPostingTypeSetup."FA Posting Type"::"Custom 2");
        end;
        if FAPostingTypeSetup."Depreciation Type" then
            j := 2
        else
            if FAPostingTypeSetup."Acquisition Type" then
                j := 1;
        if j > 0 then begin
            StartAmounts[j] := StartAmounts[j] + StartAmounts[i];
            StartAmounts[i] := 0;
            NetChangeAmounts[j] := NetChangeAmounts[j] + NetChangeAmounts[i];
            NetChangeAmounts[i] := 0;
            DisposalAmounts[j] := DisposalAmounts[j] + DisposalAmounts[i];
            DisposalAmounts[i] := 0;
        end;
    end;

    local procedure SkipRecord(): Boolean
    begin
        AcquisitionDate := FADeprBook."Acquisition Date";
        DisposalDate := FADeprBook."Disposal Date";
        exit(
          "Fixed Asset".Inactive or
          (AcquisitionDate = 0D) or
          (AcquisitionDate > EndingDate) and (EndingDate > 0D) or
          (DisposalDate > 0D) and (DisposalDate < StartingDate))
    end;

    local procedure GetPeriodDisposal(): Boolean
    begin
        if DisposalDate > 0D then
            if (EndingDate = 0D) or (DisposalDate <= EndingDate) then
                exit(true);
        exit(false);
    end;

    local procedure MakeGroupTotalText()
    begin
        case GroupTotals of
            GroupTotals::"FA Class":
                GroupCodeName := Format("Fixed Asset".FieldCaption("FA Class Code"));
            GroupTotals::"FA Subclass":
                GroupCodeName := Format("Fixed Asset".FieldCaption("FA Subclass Code"));
            GroupTotals::"FA Location":
                GroupCodeName := Format("Fixed Asset".FieldCaption("FA Location Code"));
            GroupTotals::"Main Asset":
                GroupCodeName := Format("Fixed Asset".FieldCaption("Main Asset/Component"));
            GroupTotals::"Global Dimension 1":
                GroupCodeName := Format("Fixed Asset".FieldCaption("Global Dimension 1 Code"));
            GroupTotals::"Global Dimension 2":
                GroupCodeName := Format("Fixed Asset".FieldCaption("Global Dimension 2 Code"));
            GroupTotals::"FA Posting Group":
                GroupCodeName := Format("Fixed Asset".FieldCaption("FA Posting Group"));
        end;
        if GroupCodeName <> '' then
            GroupCodeName := Format(StrSubstNo('%1%2 %3', GroupTotalsLbl, ':', GroupCodeName));
    end;

    local procedure MakeDateText()
    begin
        StartText := StrSubstNo('%1', StartingDate - 1);
        EndText := StrSubstNo('%1', EndingDate);
    end;

    local procedure MakeHeadLine()
    var
        InPeriodText: Text[30];
        DisposalText: Text[30];
    begin
        InPeriodText := InPeriodLbl;
        DisposalText := DisposalLbl;
        HeadLineText[1] := StrSubstNo('%1 %2', FADeprBook.FieldCaption("Acquisition Cost"), StartText);
        HeadLineText[2] := StrSubstNo('%1 %2', AdditionLbl, InPeriodText);
        HeadLineText[3] := StrSubstNo('%1 %2', DisposalText, InPeriodText);
        HeadLineText[4] := StrSubstNo('%1 %2', FADeprBook.FieldCaption("Acquisition Cost"), EndText);
        HeadLineText[5] := StrSubstNo('%1 %2', FADeprBook.FieldCaption(Depreciation), StartText);
        HeadLineText[6] := StrSubstNo('%1 %2', FADeprBook.FieldCaption(Depreciation), InPeriodText);
        HeadLineText[7] := StrSubstNo(
            '%1 %2 %3', DisposalText, FADeprBook.FieldCaption(Depreciation), InPeriodText);
        HeadLineText[8] := StrSubstNo('%1 %2', FADeprBook.FieldCaption(Depreciation), EndText);
        HeadLineText[9] := StrSubstNo('%1 %2', FADeprBook.FieldCaption("Book Value"), StartText);
        HeadLineText[10] := StrSubstNo('%1 %2', FADeprBook.FieldCaption("Book Value"), EndText);
        HeadLineText[11] := StrSubstNo('%1 %2', FADeprBook.FieldCaption("Derogatory Amount"), StartText);
        HeadLineText[12] := StrSubstNo('%1 %2', FADeprBook.FieldCaption("Derogatory Amount"), IncreasedInPeriodTxt);
        HeadLineText[13] := StrSubstNo('%1 %2', FADeprBook.FieldCaption("Derogatory Amount"), DecreasedInPeriodTxt);
        HeadLineText[14] := StrSubstNo('%1 %2', FADeprBook.FieldCaption("Derogatory Amount"), EndText);
    end;

    local procedure MakeGroupHeadLine()
    begin
        for j := 1 to NumberOfTypes do begin
            GroupStartAmounts[j] := 0;
            GroupNetChangeAmounts[j] := 0;
            GroupDisposalAmounts[j] := 0;
        end;
        case GroupTotals of
            GroupTotals::"FA Class":
                GroupHeadLine := Format("Fixed Asset"."FA Class Code");
            GroupTotals::"FA Subclass":
                GroupHeadLine := Format("Fixed Asset"."FA Subclass Code");
            GroupTotals::"FA Location":
                GroupHeadLine := Format("Fixed Asset"."FA Location Code");
            GroupTotals::"Main Asset":
                begin
                    FA."Main Asset/Component" := FA."Main Asset/Component"::"Main Asset";
                    GroupHeadLine :=
                      Format(StrSubstNo('%1 %2', Format(FA."Main Asset/Component"), "Fixed Asset"."Component of Main Asset"));
                    if "Fixed Asset"."Component of Main Asset" = '' then
                        GroupHeadLine := Format(StrSubstNo('%1 %2', GroupHeadLine, '*****'));
                end;
            GroupTotals::"Global Dimension 1":
                GroupHeadLine := Format("Fixed Asset"."Global Dimension 1 Code");
            GroupTotals::"Global Dimension 2":
                GroupHeadLine := Format("Fixed Asset"."Global Dimension 2 Code");
            GroupTotals::"FA Posting Group":
                GroupHeadLine := Format("Fixed Asset"."FA Posting Group");
        end;
        if GroupHeadLine = '' then
            GroupHeadLine := Format('*****');
    end;

    local procedure UpdateTotals()
    begin
        for j := 1 to NumberOfTypes do begin
            GroupStartAmounts[j] := GroupStartAmounts[j] + StartAmounts[j];
            GroupNetChangeAmounts[j] := GroupNetChangeAmounts[j] + NetChangeAmounts[j];
            GroupDisposalAmounts[j] := GroupDisposalAmounts[j] + DisposalAmounts[j];
            TotalStartAmounts[j] := TotalStartAmounts[j] + StartAmounts[j];
            TotalNetChangeAmounts[j] := TotalNetChangeAmounts[j] + NetChangeAmounts[j];
            TotalDisposalAmounts[j] := TotalDisposalAmounts[j] + DisposalAmounts[j];
        end;
    end;

    local procedure CreateGroupTotals()
    begin
        for j := 1 to NumberOfTypes do
            TotalEndingAmounts[j] :=
              GroupStartAmounts[j] + GroupNetChangeAmounts[j] + GroupDisposalAmounts[j];
        BookValueAtEndingDate := 0;
        BookValueAtStartingDate := 0;
        for j := 1 to NumberOfTypes - 1 do begin
            BookValueAtEndingDate := BookValueAtEndingDate + TotalEndingAmounts[j];
            BookValueAtStartingDate := BookValueAtStartingDate + GroupStartAmounts[j];
        end;
    end;

    local procedure CreateTotals()
    begin
        for j := 1 to NumberOfTypes do
            TotalEndingAmounts[j] :=
              TotalStartAmounts[j] + TotalNetChangeAmounts[j] + TotalDisposalAmounts[j];
        BookValueAtEndingDate := 0;
        BookValueAtStartingDate := 0;
        for j := 1 to NumberOfTypes - 1 do begin
            BookValueAtEndingDate := BookValueAtEndingDate + TotalEndingAmounts[j];
            BookValueAtStartingDate := BookValueAtStartingDate + TotalStartAmounts[j];
        end;
    end;

    local procedure GetStartingDate(StartingDate: Date): Date
    begin
        if StartingDate <= 00000101D then
            exit(0D);

        exit(StartingDate - 1);
    end;

    procedure SetMandatoryFields(DepreciationBookCodeFrom: Code[10]; StartingDateFrom: Date; EndingDateFrom: Date)
    begin
        DeprBookCode := DepreciationBookCodeFrom;
        StartingDate := StartingDateFrom;
        EndingDate := EndingDateFrom;
    end;

    procedure SetTotalFields(GroupTotalsFrom: Option; PrintDetailsFrom: Boolean; BudgetReportFrom: Boolean)
    begin
        GroupTotals := GroupTotalsFrom;
        PrintDetails := PrintDetailsFrom;
        BudgetReport := BudgetReportFrom;
    end;

    procedure GetDepreciationBookCode()
    begin
        if DeprBookCode = '' then begin
            FASetup.Get();
            DeprBookCode := FASetup."Default Depr. Book";
        end;
    end;

    procedure GetDeprBookInfo()
    begin
        AccountingDeprBookCode := DeprBookCode;
        AccountingDeprMethod := Format(FADeprBook."Depreciation Method");
        AccountingDeprStartingDate := FADeprBook."Depreciation Starting Date";
        AccountingDeprEndingDate := FADeprBook."Depreciation Ending Date";
        AccountingDecliningBalancePct := FADeprBook."Declining-Balance %";
    end;

    procedure GetDerogDeprBookInfo()
    begin
        DerogatoryDeprBookCode := FADeprBook2."Depreciation Book Code";
        DerogatoryDeprMethod := Format(FADeprBook2."Depreciation Method");
        DerogatoryDeprStartingDate := FADeprBook2."Depreciation Starting Date";
        DerogatoryDeprEndingDate := FADeprBook2."Depreciation Ending Date";
        DerogatoryDecliningBalancePct := FADeprBook2."Declining-Balance %";
    end;
}
