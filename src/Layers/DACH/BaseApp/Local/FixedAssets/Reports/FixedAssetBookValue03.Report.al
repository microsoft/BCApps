// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Reports;

using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Posting;
using Microsoft.FixedAssets.Setup;

report 11011 "Fixed Asset - Book Value 03"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/FixedAssets/Reports/FixedAssetBookValue03.rdlc';
    ApplicationArea = FixedAssets;
    Caption = 'FA Book Value 03';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Fixed Asset"; "Fixed Asset")
        {
            RequestFilterFields = "No.", "FA Class Code", "FA Subclass Code", "Budgeted Asset";
            column(MainHeadLineText; MainHeadLineText)
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(USERID; UserId)
            {
            }
            column(DeprBookText; DeprBookText)
            {
            }
            column(Fixed_Asset__TABLECAPTION__________FAFilter; "Fixed Asset".TableCaption + ': ' + Format(FAFilter))
            {
            }
            column(GroupTotals; Format(GroupTotals))
            {
            }
            column(BudgetReport; BudgetReport)
            {
            }
            column(PrintDetails; PrintDetails)
            {
            }
            column(GroupFieldIndex; GroupFieldIndex)
            {
            }
            column(GroupCodeName; GroupCodeName)
            {
            }
            column(HeadLineText_1_; HeadLineText[1])
            {
            }
            column(HeadLineText_2_; HeadLineText[2])
            {
            }
            column(HeadLineText_3_; HeadLineText[3])
            {
            }
            column(HeadLineText_4_; HeadLineText[4])
            {
            }
            column(HeadLineText_5_; HeadLineText[5])
            {
            }
            column(HeadLineText_6_; HeadLineText[6])
            {
            }
            column(HeadLineText_7_; HeadLineText[7])
            {
            }
            column(HeadLineText_8_; HeadLineText[8])
            {
            }
            column(HeadLineText_9_; HeadLineText[9])
            {
            }
            column(HeadLineText_10_; HeadLineText[10])
            {
            }
            column(FANo; FANo)
            {
            }
            column(FADescription; FADescription)
            {
            }
            column(GroupHeadLine; GroupHeadLine)
            {
            }
            column(Fixed_Asset__No__; "No.")
            {
            }
            column(Fixed_Asset_Description; Description)
            {
            }
            column(StartAmounts_1_; StartAmounts[1])
            {
                AutoFormatType = 1;
            }
            column(NetChangeAmounts_1; NetChangeAmounts[1] - ReclassAmount)
            {
                AutoFormatType = 1;
            }
            column(DisposalAmounts_1_; DisposalAmounts[1])
            {
                AutoFormatType = 1;
            }
            column(ReclassAmount; ReclassAmount)
            {
                AutoFormatType = 1;
            }
            column(NetChangeAmounts_4_; NetChangeAmounts[4])
            {
                AutoFormatType = 1;
            }
            column(StartAmounts_2_; StartAmounts[2])
            {
                AutoFormatType = 1;
            }
            column(NetChangeAmounts_2_; NetChangeAmounts[2])
            {
                AutoFormatType = 1;
            }
            column(DisposalAmounts_2_; DisposalAmounts[2])
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
            column(GroupTotal; Format(Text1140002 + ': ' + GroupHeadLine))
            {
            }
            column(GroupStartAmounts_1_; GroupStartAmounts[1])
            {
                AutoFormatType = 1;
            }
            column(GroupNetChangeAmounts_1; GroupNetChangeAmounts[1] - GroupReclassAmount)
            {
                AutoFormatType = 1;
            }
            column(GroupDisposalAmounts_1_; GroupDisposalAmounts[1])
            {
                AutoFormatType = 1;
            }
            column(GroupReclassAmount; GroupReclassAmount)
            {
                AutoFormatType = 1;
            }
            column(GroupNetChangeAmounts_4_; GroupNetChangeAmounts[4])
            {
                AutoFormatType = 1;
            }
            column(GroupStartAmounts_2_; GroupStartAmounts[2])
            {
                AutoFormatType = 1;
            }
            column(GroupNetChangeAmounts_2_; GroupNetChangeAmounts[2])
            {
                AutoFormatType = 1;
            }
            column(GroupDisposalAmounts_2_; GroupDisposalAmounts[2])
            {
                AutoFormatType = 1;
            }
            column(BookValueAtStartingDate_Control1140043; BookValueAtStartingDate)
            {
                AutoFormatType = 1;
            }
            column(BookValueAtEndingDate_Control1140044; BookValueAtEndingDate)
            {
                AutoFormatType = 1;
            }
            column(GroupHeadLine_Control1140059; Format(GroupHeadLine))
            {
            }
            column(SubGroupHeadLine; SubGroupHeadLine)
            {
            }
            column(SubGroupTotal; Format(SubGroupTotalLbl + ': ' + SubGroupHeadLine))
            {
            }
            column(SubGroupFieldIndex; SubGroupFieldIndex)
            {
            }
            column(TotalStartAmounts_1_; TotalStartAmounts[1])
            {
                AutoFormatType = 1;
            }
            column(TotalNetChangeAmounts_1; TotalNetChangeAmounts[1] - TotalReclassAmount)
            {
                AutoFormatType = 1;
            }
            column(TotalDisposalAmounts_1_; TotalDisposalAmounts[1])
            {
                AutoFormatType = 1;
            }
            column(TotalReclassAmount; TotalReclassAmount)
            {
                AutoFormatType = 1;
            }
            column(TotalNetChangeAmounts_4_; TotalNetChangeAmounts[4])
            {
                AutoFormatType = 1;
            }
            column(TotalStartAmounts_2_; TotalStartAmounts[2])
            {
                AutoFormatType = 1;
            }
            column(TotalNetChangeAmounts_2_; TotalNetChangeAmounts[2])
            {
                AutoFormatType = 1;
            }
            column(TotalDisposalAmounts_2_; TotalDisposalAmounts[2])
            {
                AutoFormatType = 1;
            }
            column(BookValueAtStartingDate_Control1140054; BookValueAtStartingDate)
            {
                AutoFormatType = 1;
            }
            column(BookValueAtEndingDate_Control1140055; BookValueAtEndingDate)
            {
                AutoFormatType = 1;
            }
            column(Fixed_Asset_FA_Class_Code; "FA Class Code")
            {
            }
            column(Fixed_Asset_FA_Subclass_Code; "FA Subclass Code")
            {
            }
            column(Fixed_Asset_Global_Dimension_1_Code; "Global Dimension 1 Code")
            {
            }
            column(Fixed_Asset_Global_Dimension_2_Code; "Global Dimension 2 Code")
            {
            }
            column(Fixed_Asset_FA_Location_Code; "FA Location Code")
            {
            }
            column(Fixed_Asset_Component_of_Main_Asset; "Component of Main Asset")
            {
            }
            column(Fixed_Asset_FA_Posting_Group; "FA Posting Group")
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
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
                        Error(Text1140007, FieldCaption("FA Posting Group"), "No.");

                BeforeAmount := 0;
                EndingAmount := 0;
                if BudgetReport then
                    BudgetDepreciation.Calculate(
                      "No.", GetStartingDate(StartingDate), EndingDate, DeprBookCode, BeforeAmount, EndingAmount);

                i := 0;
                while i < NumberOfTypes do begin
                    i := i + 1;
                    case i of
                        1:
                            begin
                                PostingType := FADeprBook.FieldNo("Acquisition Cost");
                                FAGenReport.SetExclReclEntries(false);
                            end;
                        2:
                            begin
                                PostingType := FADeprBook.FieldNo(Depreciation);
                                FAGenReport.SetExclReclEntries(false); // Set to FALSE for i >= 2
                            end;
                        3:
                            PostingType := FADeprBook.FieldNo("Write-Down");
                        4:
                            PostingType := FADeprBook.FieldNo(Appreciation);
                        5:
                            PostingType := FADeprBook.FieldNo("Custom 1");
                        6:
                            PostingType := FADeprBook.FieldNo("Custom 2");
                    end;
                    if StartingDate <= 00000101D then
                        StartAmounts[i] := 0
                    else
                        StartAmounts[i] := FAGenReport.CalcFAPostedAmount(
                            "No.", PostingType, Period1, StartingDate,
                            EndingDate, DeprBookCode, BeforeAmount, EndingAmount, false, true);
                    NetChangeAmounts[i] :=
                      FAGenReport.CalcFAPostedAmount(
                        "No.", PostingType, Period2, StartingDate, EndingDate,
                        DeprBookCode, BeforeAmount, EndingAmount, false, true);
                    if i = 1 then
                        ReclassAmount := FAGenReport.CalcFAPostedAmount(
                            "No.", PostingType, Period2, StartingDate, EndingDate,
                            DeprBookCode, 0, 0, true, true);

                    if GetPeriodDisposal() then
                        DisposalAmounts[i] := -(StartAmounts[i] + NetChangeAmounts[i])
                    else
                        DisposalAmounts[i] := 0;
                    if i >= 3 then
                        AddPostingType(i - 3);
                end;
                for j := 1 to NumberOfTypes do
                    TotalEndingAmounts[j] := StartAmounts[j] + NetChangeAmounts[j] + DisposalAmounts[j];

                MakeGroupHeadLine();
                MakeSubGroupHeadLine();
                UpdateTotals();
                CreateGroupTotals();
            end;

            trigger OnPreDataItem()
            begin
                // Indexes:
                // 1 - FA Class Code
                // 2 - FA Subclass Code
                // 3 - FA Location Code
                // 4 - Component of Main Asset
                // 5 - Global Dimension 1 Code
                // 6 - Global Dimension 2 Code
                // 7 - FA Posting Group

                case GroupTotals of
                    GroupTotals::"FA Class":
                        case SubGroupTotals of
                            SubGroupTotals::"FA Subclass":
                                begin
                                    SetCurrentKey("FA Class Code", "FA Subclass Code");
                                    GroupFieldIndex := 1;
                                    SubGroupFieldIndex := 2;
                                end;
                            SubGroupTotals::"FA Posting Group":
                                begin
                                    SetCurrentKey("FA Class Code", "FA Posting Group");
                                    GroupFieldIndex := 1;
                                    SubGroupFieldIndex := 7;
                                end;
                            else begin
                                SetCurrentKey("FA Class Code");
                                GroupFieldIndex := 1;
                                SubGroupFieldIndex := 0;
                            end;
                        end;
                    GroupTotals::"FA Subclass":
                        begin
                            SetCurrentKey("FA Subclass Code");
                            GroupFieldIndex := 2;
                            SubGroupFieldIndex := 0;
                        end;
                    GroupTotals::"FA Location":
                        begin
                            SetCurrentKey("FA Location Code");
                            GroupFieldIndex := 3;
                            SubGroupFieldIndex := 0;
                        end;
                    GroupTotals::"Main Asset":
                        begin
                            SetCurrentKey("Component of Main Asset");
                            GroupFieldIndex := 4;
                            SubGroupFieldIndex := 0;
                        end;
                    GroupTotals::"Global Dimension 1":
                        begin
                            SetCurrentKey("Global Dimension 1 Code");
                            GroupFieldIndex := 5;
                            SubGroupFieldIndex := 0;
                        end;
                    GroupTotals::"Global Dimension 2":
                        begin
                            SetCurrentKey("Global Dimension 2 Code");
                            GroupFieldIndex := 6;
                            SubGroupFieldIndex := 0;
                        end;
                    GroupTotals::"FA Posting Group":
                        begin
                            SetCurrentKey("FA Posting Group");
                            GroupFieldIndex := 7;
                            SubGroupFieldIndex := 0;
                        end;
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
                    field(DepreciationBook; DeprBookCode)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Depreciation Book';
                        Lookup = true;
                        TableRelation = "Depreciation Book";
                        ToolTip = 'Specifies the depreciation book that is assigned to the fixed asset.';
                    }
                    field(StartingDate; StartingDate)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the date from which the report or batch job processes information.';
                    }
                    field(EndingDate; EndingDate)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Ending Date';
                        ToolTip = 'Specifies the last date that the report includes data for.';
                    }
                    field(GroupTotals; GroupTotals)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Group Totals';
                        OptionCaption = ' ,FA Class,FA Subclass,FA Location,Main Asset,Global Dimension 1,Global Dimension 2,FA Posting Group';
                        ToolTip = 'Specifies if you want the report to group fixed assets and print totals using the category defined in this field. For example, maintenance expenses for fixed assets can be shown for each fixed asset class.';

                        trigger OnValidate()
                        begin
                            SetEnableSubGroupTotals(GroupTotals = GroupTotals::"FA Class");
                        end;
                    }
                    field(SubGroupTotals; SubGroupTotals)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Sub Group Totals';
                        Enabled = EnableSubGroupTotals;
                        ToolTip = 'Specifies if you want the report to group fixed assets and print totals using the sub category defined in this field. For example, maintenance expenses for fixed assets can be shown for each fixed asset class.';
                    }
                    field(PrintPerFixedAsset; PrintDetails)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Print per Fixed Asset';
                        ToolTip = 'Specifies that the information is shown separately for each fixed asset.';
                    }
                    field(BudgetReport; BudgetReport)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Budget Report';
                        ToolTip = 'Specifies that the calculated future depreciation and future book value are included. If you select this field, the Depreciation in Period column will contain both posted depreciation and depreciation that has been calculated until the specified end date. If you do not select the field, the column will only contain posted depreciation. In both cases, posted depreciation refers to depreciation that is posted in the period defined by the start date and the end date.';
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

            SetEnableSubGroupTotals(GroupTotals = GroupTotals::"FA Class");
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        NumberOfTypes := 6;
        DeprBook.Get(DeprBookCode);
        if GroupTotals = GroupTotals::"FA Posting Group" then
            FAGenReport.SetFAPostingGroup("Fixed Asset", DeprBook.Code);
        FAGenReport.AppendFAPostingFilter("Fixed Asset", StartingDate, EndingDate);
        FAFilter := "Fixed Asset".GetFilters();
        MainHeadLineText := Text1140000;
        if BudgetReport then
            MainHeadLineText := StrSubstNo('%1 %2', MainHeadLineText, Text1140001);
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
        Text1140000: Label 'Fixed Asset - Book Value 03';
        Text1140001: Label '(Budget Report)';
        Text1140002: Label 'Group Total';
        Text1140003: Label 'Group Totals';
        Text1140004: Label 'in Period';
        Text1140005: Label 'Disposal';
        Text1140006: Label 'Addition';
        Text1140007: Label '%1 has been modified in fixed asset %2';
        Text1140008: Label 'Reclassification';
        Text1140009: Label 'Appreciation';
        Text1140010: Label 'Accum. Depr. until';
        Text1140011: Label 'Depreciation';
        FASetup: Record "FA Setup";
        DeprBook: Record "Depreciation Book";
        FADeprBook: Record "FA Depreciation Book";
        FA: Record "Fixed Asset";
        FAPostingTypeSetup: Record "FA Posting Type Setup";
        FAGenReport: Codeunit "FA General Report";
        BudgetDepreciation: Codeunit "Budget Depreciation";
        DeprBookCode: Code[10];
        FAFilter: Text;
        MainHeadLineText: Text[100];
        DeprBookText: Text[50];
        GroupCodeName: Text[50];
        GroupHeadLine: Text[50];
        FANo: Text[50];
        FADescription: Text[100];
        StartText: Text[30];
        EndText: Text[30];
        HeadLineText: array[10] of Text[50];
        BookValueAtStartingDate: Decimal;
        BookValueAtEndingDate: Decimal;
        BeforeAmount: Decimal;
        EndingAmount: Decimal;
        ReclassAmount: Decimal;
        GroupReclassAmount: Decimal;
        TotalReclassAmount: Decimal;
        StartAmounts: array[6] of Decimal;
        NetChangeAmounts: array[6] of Decimal;
        DisposalAmounts: array[6] of Decimal;
        GroupStartAmounts: array[6] of Decimal;
        GroupNetChangeAmounts: array[6] of Decimal;
        GroupDisposalAmounts: array[6] of Decimal;
        TotalStartAmounts: array[6] of Decimal;
        TotalNetChangeAmounts: array[6] of Decimal;
        TotalDisposalAmounts: array[6] of Decimal;
        TotalEndingAmounts: array[6] of Decimal;
        i: Integer;
        j: Integer;
        NumberOfTypes: Integer;
        PostingType: Integer;
        GroupTotals: Option " ","FA Class","FA Subclass","FA Location","Main Asset","Global Dimension 1","Global Dimension 2","FA Posting Group";
        Period1: Option "Before Starting Date","Net Change","at Ending Date";
        Period2: Option "Before Starting Date","Net Change","at Ending Date";
        StartingDate: Date;
        EndingDate: Date;
        AcquisitionDate: Date;
        DisposalDate: Date;
        PrintDetails: Boolean;
        BudgetReport: Boolean;
        GroupFieldIndex: Integer;
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        TotalCaptionLbl: Label 'Total';
        EnableSubGroupTotals: Boolean;
        SubGroupTotals: Option " ","FA Subclass","FA Posting Group";
        SubGroupHeadLine: Text[50];
        SubGroupFieldIndex: Integer;
        SubGroupTotalLbl: Label 'Sub Group Total';

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
            GroupCodeName := Format(StrSubstNo('%1%2 %3', Text1140003, ':', GroupCodeName));
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
        InPeriodText := Text1140004;
        DisposalText := Text1140005;
        HeadLineText[1] := StrSubstNo('%1 %2', FADeprBook.FieldCaption("Acquisition Cost"), StartText);
        HeadLineText[2] := StrSubstNo('%1 %2', Text1140006, InPeriodText);
        HeadLineText[3] := StrSubstNo('%1 %2', DisposalText, InPeriodText);
        HeadLineText[4] := StrSubstNo('%1 %2', Text1140008, InPeriodText);
        HeadLineText[5] := StrSubstNo('%1 %2', Text1140009, InPeriodText);
        HeadLineText[6] := StrSubstNo('%1 %2', Text1140010, StartText);
        HeadLineText[7] := StrSubstNo('%1 %2', Text1140011, InPeriodText);
        HeadLineText[8] := StrSubstNo('%1 %2 %3', DisposalText, FADeprBook.FieldCaption(Depreciation), InPeriodText);
        HeadLineText[9] := StrSubstNo('%1 %2', FADeprBook.FieldCaption("Book Value"), StartText);
        HeadLineText[10] := StrSubstNo('%1 %2', FADeprBook.FieldCaption("Book Value"), EndText);
    end;

    local procedure MakeGroupHeadLine()
    begin
        for j := 1 to NumberOfTypes do begin
            GroupStartAmounts[j] := 0;
            GroupNetChangeAmounts[j] := 0;
            GroupDisposalAmounts[j] := 0;
        end;
        GroupReclassAmount := 0;
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

    local procedure MakeSubGroupHeadLine()
    begin
        case SubGroupTotals of
            SubGroupTotals::"FA Subclass":
                SubGroupHeadLine := Format("Fixed Asset"."FA Subclass Code");
            SubGroupTotals::"FA Posting Group":
                SubGroupHeadLine := Format("Fixed Asset"."FA Posting Group");
        end;

        if SubGroupHeadLine = '' then
            SubGroupHeadLine := Format('*****');
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
        GroupReclassAmount := GroupReclassAmount + ReclassAmount;
        TotalReclassAmount := TotalReclassAmount + ReclassAmount;
    end;

    local procedure CreateGroupTotals()
    begin
        for j := 1 to NumberOfTypes do
            TotalEndingAmounts[j] :=
              GroupStartAmounts[j] + GroupNetChangeAmounts[j] + GroupDisposalAmounts[j];
        BookValueAtEndingDate := 0;
        BookValueAtStartingDate := 0;
        for j := 1 to NumberOfTypes do begin
            BookValueAtEndingDate := BookValueAtEndingDate + TotalEndingAmounts[j];
            BookValueAtStartingDate := BookValueAtStartingDate + GroupStartAmounts[j];
        end;
    end;

    local procedure GetStartingDate(StartingDate: Date): Date
    begin
        if StartingDate <= 00000101D then
            exit(0D);

        exit(StartingDate - 1);
    end;

    local procedure SetEnableSubGroupTotals(Enable: Boolean)
    begin
        if Enable then
            EnableSubGroupTotals := true
        else begin
            EnableSubGroupTotals := false;
            SubGroupTotals := SubGroupTotals::" ";
        end;
    end;
}

