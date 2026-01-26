// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Reports;

using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Setup;

report 5606 "Fixed Asset - Book Value 02"
{
    DefaultLayout = RDLC;
    RDLCLayout = './FixedAssets/Reports/FixedAssetBookValue02.rdlc';
    ApplicationArea = FixedAssets;
    Caption = 'Fixed Asset Book Value 02';
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
            column(GroupCodeName; GroupCodeName)
            {
            }
            column(FixedAssetCaptionFilter; "Fixed Asset".TableCaption + ': ' + FAFilter)
            {
            }
            column(FAFilter; FAFilter)
            {
            }
            column(No_FixedAsset; "No.")
            {
            }
            column(Description_FixedAsset; Description)
            {
            }
            column(DeprBookInfo1; DeprBookInfo[1])
            {
            }
            column(DeprBookInfo2; DeprBookInfo[2])
            {
            }
            column(DeprBookInfo3; DeprBookInfo[3])
            {
            }
            column(DeprBookInfo4; DeprBookInfo[4])
            {
            }
            column(DeprBookInfo5; DeprBookInfo[5])
            {
            }
            column(PrintFASetup; PrintFASetup)
            {
            }
            column(DeprBookInfo51; DeprBookInfo5)
            {
            }
            column(DerogDeprBookInfo1; DerogDeprBookInfo[1])
            {
            }
            column(DerogDeprBookInfo2; DerogDeprBookInfo[2])
            {
            }
            column(DerogDeprBookInfo3; DerogDeprBookInfo[3])
            {
            }
            column(DerogDeprBookInfo4; DerogDeprBookInfo[4])
            {
            }
            column(DerogDeprBookInfo5; DerogDeprBookInfo[5])
            {
            }
            column(HasDerogatorySetup; HasDerogatorySetup)
            {
            }
            column(DerogDeprBookInfo51; DerogDeprBookInfo5)
            {
            }
            column(HeadLineText1; HeadLineText[1])
            {
            }
            column(HeadLineText6; HeadLineText[6])
            {
            }
            column(HeadLineText7; HeadLineText[7])
            {
            }
            column(StartText; StartText)
            {
            }
            column(EndText; EndText)
            {
            }
            column(StartAmt1; StartAmounts[1])
            {
                AutoFormatType = 1;
            }
            column(NetChangeAmt1; NetChangeAmounts[1])
            {
                AutoFormatType = 1;
            }
            column(DisposalAmt1; DisposalAmounts[1])
            {
                AutoFormatType = 1;
            }
            column(TotalEndingAmt1; TotalEndingAmounts[1])
            {
                AutoFormatType = 1;
            }
            column(ReclassStartAmt1; ReclassStartAmounts[1])
            {
                AutoFormatType = 1;
            }
            column(ReclassNetChangeAmt1; ReclassNetChangeAmounts[1])
            {
                AutoFormatType = 1;
            }
            column(ReclassDisposalAmt1; ReclassDisposalAmounts[1])
            {
                AutoFormatType = 1;
            }
            column(ReclassTotalEndingAmt1; ReclassTotalEndingAmounts[1])
            {
                AutoFormatType = 1;
            }
            column(HeadLineText5; HeadLineText[5])
            {
            }
            column(BookValueAtStartingDate; BookValueAtStartingDate)
            {
                AutoFormatType = 1;
            }
            column(ReclassificationText; ReclassificationText)
            {
            }
            column(PrintDetails; PrintDetails)
            {
            }
            column(HeadLineText2; HeadLineText[2])
            {
            }
            column(StartAmt2; StartAmounts[2])
            {
                AutoFormatType = 1;
            }
            column(NetChangeAmt2; NetChangeAmounts[2])
            {
                AutoFormatType = 1;
            }
            column(DisposalAmt2; DisposalAmounts[2])
            {
                AutoFormatType = 1;
            }
            column(TotalEndingAmt2; TotalEndingAmounts[2])
            {
                AutoFormatType = 1;
            }
            column(ReclassStartAmt2; ReclassStartAmounts[2])
            {
                AutoFormatType = 1;
            }
            column(ReclassNetChangeAmt2; ReclassNetChangeAmounts[2])
            {
                AutoFormatType = 1;
            }
            column(ReclassDisposalAmt2; ReclassDisposalAmounts[2])
            {
                AutoFormatType = 1;
            }
            column(ReclassTotalEndingAmt2; ReclassTotalEndingAmounts[2])
            {
                AutoFormatType = 1;
            }
            column(ShowSection02; ShowSection(0, 2))
            {
            }
            column(HeadLineText3; HeadLineText[3])
            {
            }
            column(StartAmt3; StartAmounts[3])
            {
                AutoFormatType = 1;
            }
            column(NetChangeAmt3; NetChangeAmounts[3])
            {
                AutoFormatType = 1;
            }
            column(DisposalAmt3; DisposalAmounts[3])
            {
                AutoFormatType = 1;
            }
            column(TotalEndingAmt3; TotalEndingAmounts[3])
            {
                AutoFormatType = 1;
            }
            column(ReclassStartAmt3; ReclassStartAmounts[3])
            {
                AutoFormatType = 1;
            }
            column(ReclassNetChangeAmt3; ReclassNetChangeAmounts[3])
            {
                AutoFormatType = 1;
            }
            column(ReclassDisposalAmt3; ReclassDisposalAmounts[3])
            {
                AutoFormatType = 1;
            }
            column(ReclassTotalEndingAmt3; ReclassTotalEndingAmounts[3])
            {
                AutoFormatType = 1;
            }
            column(ShowSection03; ShowSection(0, 3))
            {
            }
            column(HeadLineText4; HeadLineText[4])
            {
            }
            column(StartAmt4; StartAmounts[4])
            {
                AutoFormatType = 1;
            }
            column(NetChangeAmt4; NetChangeAmounts[4])
            {
                AutoFormatType = 1;
            }
            column(DisposalAmt4; DisposalAmounts[4])
            {
                AutoFormatType = 1;
            }
            column(TotalEndingAmt4; TotalEndingAmounts[4])
            {
                AutoFormatType = 1;
            }
            column(ReclassStartAmt4; ReclassStartAmounts[4])
            {
                AutoFormatType = 1;
            }
            column(ReclassNetChangeAmt4; ReclassNetChangeAmounts[4])
            {
                AutoFormatType = 1;
            }
            column(ReclassDisposalAmt4; ReclassDisposalAmounts[4])
            {
                AutoFormatType = 1;
            }
            column(ReclassTotalEndingAmt4; ReclassTotalEndingAmounts[4])
            {
                AutoFormatType = 1;
            }
            column(ShowSection04; ShowSection(0, 4))
            {
            }
            column(HeadLineText8; HeadLineText[8])
            {
            }
            column(StartAmt5; StartAmounts[5])
            {
                AutoFormatType = 1;
            }
            column(NetChangeAmt5; NetChangeAmounts[5])
            {
                AutoFormatType = 1;
            }
            column(DisposalAmt5; DisposalAmounts[5])
            {
                AutoFormatType = 1;
            }
            column(TotalEndingAmt5; TotalEndingAmounts[5])
            {
                AutoFormatType = 1;
            }
            column(ReclassStartAmt5; ReclassStartAmounts[5])
            {
                AutoFormatType = 1;
            }
            column(ReclassNetChangeAmt5; ReclassNetChangeAmounts[5])
            {
                AutoFormatType = 1;
            }
            column(ReclassDisposalAmt5; ReclassDisposalAmounts[5])
            {
                AutoFormatType = 1;
            }
            column(ReclassTotalEndingAmt5; ReclassTotalEndingAmounts[5])
            {
                AutoFormatType = 1;
            }
            column(ShowSection05; ShowSection(0, 5))
            {
            }
            column(HeadLineText9; HeadLineText[9])
            {
            }
            column(StartAmt6; StartAmounts[6])
            {
                AutoFormatType = 1;
            }
            column(NetChangeAmt6; NetChangeAmounts[6])
            {
                AutoFormatType = 1;
            }
            column(DisposalAmt6; DisposalAmounts[6])
            {
                AutoFormatType = 1;
            }
            column(TotalEndingAmt6; TotalEndingAmounts[6])
            {
                AutoFormatType = 1;
            }
            column(ReclassStartAmt6; ReclassStartAmounts[6])
            {
                AutoFormatType = 1;
            }
            column(ReclassNetChangeAmt6; ReclassNetChangeAmounts[6])
            {
                AutoFormatType = 1;
            }
            column(ReclassDisposalAmt6; ReclassDisposalAmounts[6])
            {
                AutoFormatType = 1;
            }
            column(ReclassTotalEndingAmt6; ReclassTotalEndingAmounts[6])
            {
                AutoFormatType = 1;
            }
            column(ShowSection06; ShowSection(0, 6))
            {
            }
            column(HeadLineText10; HeadLineText[10])
            {
            }
            column(HeadLineText11; HeadLineText[11])
            {
            }
            column(HeadLineText12; HeadLineText[12])
            {
            }
            column(NetChangeAmtType; NetChangeAmounts[Type])
            {
                AutoFormatType = 1;
            }
            column(TotalEndingAmtType; TotalEndingAmounts[Type])
            {
                AutoFormatType = 1;
            }
            column(ReclassNetChangeAmtType; ReclassNetChangeAmounts[Type])
            {
                AutoFormatType = 1;
            }
            column(ReclassTotalEndingAmtType; ReclassTotalEndingAmounts[Type])
            {
                AutoFormatType = 1;
            }
            column(ShowSection07; ShowSection(0, 7))
            {
            }
            column(ReclassTotalEndingAmt7; ReclassTotalEndingAmounts[7])
            {
            }
            column(TotalEndingAmt7; TotalEndingAmounts[7])
            {
            }
            column(ReclassDisposalAmt7; ReclassDisposalAmounts[7])
            {
                AutoFormatType = 1;
            }
            column(ReclassNetChangeAmt7; ReclassNetChangeAmounts[7])
            {
                AutoFormatType = 1;
            }
            column(NetChangeAmt7; NetChangeAmounts[7])
            {
                AutoFormatType = 1;
            }
            column(DisposalAmt7; DisposalAmounts[7])
            {
                AutoFormatType = 1;
            }
            column(StartAmt7; StartAmounts[7])
            {
                AutoFormatType = 1;
            }
            column(ReclassStartAmt7; ReclassStartAmounts[7])
            {
                AutoFormatType = 1;
            }
            column(BookValueAtEndingDate; BookValueAtEndingDate)
            {
                AutoFormatType = 1;
            }
            column(GroupHeadLineText; GroupHeadLineText)
            {
            }
            column(GroupStartAmt1; GroupStartAmounts[1])
            {
                AutoFormatType = 1;
            }
            column(GroupNetChangeAmt1; GroupNetChangeAmounts[1])
            {
                AutoFormatType = 1;
            }
            column(GroupDisposalAmt1; GroupDisposalAmounts[1])
            {
                AutoFormatType = 1;
            }
            column(ReclassGroupStartAmt1; ReclassGroupStartAmounts[1])
            {
                AutoFormatType = 1;
            }
            column(ReclassGroupNetChangeAmt1; ReclassGroupNetChangeAmounts[1])
            {
                AutoFormatType = 1;
            }
            column(ReclassGroupDisposalAmt1; ReclassGroupDisposalAmounts[1])
            {
                AutoFormatType = 1;
            }
            column(GroupTotals; GroupTotals)
            {
            }
            column(ShowSection12; ShowSection(1, 2))
            {
            }
            column(GroupStartAmt2; GroupStartAmounts[2])
            {
                AutoFormatType = 1;
            }
            column(GroupNetChangeAmt2; GroupNetChangeAmounts[2])
            {
                AutoFormatType = 1;
            }
            column(GroupDisposalAmt2; GroupDisposalAmounts[2])
            {
                AutoFormatType = 1;
            }
            column(ReclassGroupStartAmt2; ReclassGroupStartAmounts[2])
            {
                AutoFormatType = 1;
            }
            column(ReclassGroupNetChangeAmt2; ReclassGroupNetChangeAmounts[2])
            {
                AutoFormatType = 1;
            }
            column(ReclassGroupDisposalAmt2; ReclassGroupDisposalAmounts[2])
            {
                AutoFormatType = 1;
            }
            column(GroupStartAmt3; GroupStartAmounts[3])
            {
                AutoFormatType = 1;
            }
            column(GroupNetChangeAmt3; GroupNetChangeAmounts[3])
            {
                AutoFormatType = 1;
            }
            column(GroupDisposalAmt3; GroupDisposalAmounts[3])
            {
                AutoFormatType = 1;
            }
            column(ReclassGroupStartAmt3; ReclassGroupStartAmounts[3])
            {
                AutoFormatType = 1;
            }
            column(ReclassGroupNetChangeAmt3; ReclassGroupNetChangeAmounts[3])
            {
                AutoFormatType = 1;
            }
            column(ReclassGroupDisposalAmt3; ReclassGroupDisposalAmounts[3])
            {
                AutoFormatType = 1;
            }
            column(ShowSection13; ShowSection(1, 3))
            {
            }
            column(GroupStartAmt4; GroupStartAmounts[4])
            {
                AutoFormatType = 1;
            }
            column(GroupNetChangeAmt4; GroupNetChangeAmounts[4])
            {
                AutoFormatType = 1;
            }
            column(GroupDisposalAmt4; GroupDisposalAmounts[4])
            {
                AutoFormatType = 1;
            }
            column(ReclassGroupStartAmt4; ReclassGroupStartAmounts[4])
            {
                AutoFormatType = 1;
            }
            column(ReclassGroupNetChangeAmt4; ReclassGroupNetChangeAmounts[4])
            {
                AutoFormatType = 1;
            }
            column(ReclassGroupDisposalAmt4; ReclassGroupDisposalAmounts[4])
            {
                AutoFormatType = 1;
            }
            column(ShowSection14; ShowSection(1, 4))
            {
            }
            column(GroupStartAmt5; GroupStartAmounts[5])
            {
                AutoFormatType = 1;
            }
            column(GroupNetChangeAmt5; GroupNetChangeAmounts[5])
            {
                AutoFormatType = 1;
            }
            column(GroupDisposalAmt5; GroupDisposalAmounts[5])
            {
                AutoFormatType = 1;
            }
            column(ReclassGroupStartAmt5; ReclassGroupStartAmounts[5])
            {
                AutoFormatType = 1;
            }
            column(ReclassGroupNetChangeAmt5; ReclassGroupNetChangeAmounts[5])
            {
                AutoFormatType = 1;
            }
            column(ReclassGroupDisposalAmt5; ReclassGroupDisposalAmounts[5])
            {
                AutoFormatType = 1;
            }
            column(ShowSection15; ShowSection(1, 5))
            {
            }
            column(GroupStartAmt6; GroupStartAmounts[6])
            {
                AutoFormatType = 1;
            }
            column(GroupNetChangeAmt6; GroupNetChangeAmounts[6])
            {
                AutoFormatType = 1;
            }
            column(GroupDisposalAmt6; GroupDisposalAmounts[6])
            {
                AutoFormatType = 1;
            }
            column(ReclassGroupStartAmt6; ReclassGroupStartAmounts[6])
            {
                AutoFormatType = 1;
            }
            column(ReclassGroupNetChangeAmt6; ReclassGroupNetChangeAmounts[6])
            {
                AutoFormatType = 1;
            }
            column(ReclassGroupDisposalAmt6; ReclassGroupDisposalAmounts[6])
            {
                AutoFormatType = 1;
            }
            column(ShowSection16; ShowSection(1, 6))
            {
            }
            column(ReclassGroupDisposalAmtType; ReclassGroupDisposalAmounts[Type])
            {
                AutoFormatType = 1;
            }
            column(ReclassGrpNetChangeAmtType; ReclassGroupNetChangeAmounts[Type])
            {
                AutoFormatType = 1;
            }
            column(ReclassGroupStartAmtType; ReclassGroupStartAmounts[Type])
            {
                AutoFormatType = 1;
            }
            column(ShowSection17; ShowSection(1, 7))
            {
            }
            column(GroupNetChangeAmt7; GroupNetChangeAmounts[7])
            {
                AutoFormatType = 1;
            }
            column(GroupStartAmt7; GroupStartAmounts[7])
            {
                AutoFormatType = 1;
            }
            column(GroupDisposalAmt7; GroupDisposalAmounts[7])
            {
                AutoFormatType = 1;
            }
            column(ReclassGroupDisposalAmt7; ReclassGroupDisposalAmounts[7])
            {
                AutoFormatType = 1;
            }
            column(ReclassGroupNetChangeAmt7; ReclassGroupNetChangeAmounts[7])
            {
                AutoFormatType = 1;
            }
            column(ReclassGroupStartAmt7; ReclassGroupStartAmounts[7])
            {
                AutoFormatType = 1;
            }
            column(TotalStartAmt1; TotalStartAmounts[1])
            {
                AutoFormatType = 1;
            }
            column(TotalNetChangeAmt1; TotalNetChangeAmounts[1])
            {
                AutoFormatType = 1;
            }
            column(TotalDisposalAmt1; TotalDisposalAmounts[1])
            {
                AutoFormatType = 1;
            }
            column(ReclassTotalStartAmt1; ReclassTotalStartAmounts[1])
            {
                AutoFormatType = 1;
            }
            column(ReclassTotalNetChangeAmt1; ReclassTotalNetChangeAmounts[1])
            {
                AutoFormatType = 1;
            }
            column(ReclassTotalDisposalAmt1; ReclassTotalDisposalAmounts[1])
            {
                AutoFormatType = 1;
            }
            column(ShowSection22; ShowSection(2, 2))
            {
            }
            column(TotalStartAmt2; TotalStartAmounts[2])
            {
                AutoFormatType = 1;
            }
            column(TotalNetChangeAmt2; TotalNetChangeAmounts[2])
            {
                AutoFormatType = 1;
            }
            column(TotalDisposalAmt2; TotalDisposalAmounts[2])
            {
                AutoFormatType = 1;
            }
            column(ReclassTotalStartAmt2; ReclassTotalStartAmounts[2])
            {
                AutoFormatType = 1;
            }
            column(ReclassTotalNetChangeAmt2; ReclassTotalNetChangeAmounts[2])
            {
                AutoFormatType = 1;
            }
            column(ReclassTotalDisposalAmt2; ReclassTotalDisposalAmounts[2])
            {
                AutoFormatType = 1;
            }
            column(TotalStartAmt3; TotalStartAmounts[3])
            {
                AutoFormatType = 1;
            }
            column(TotalNetChangeAmt3; TotalNetChangeAmounts[3])
            {
                AutoFormatType = 1;
            }
            column(TotalDisposalAmt3; TotalDisposalAmounts[3])
            {
                AutoFormatType = 1;
            }
            column(ReclassTotalStartAmt3; ReclassTotalStartAmounts[3])
            {
                AutoFormatType = 1;
            }
            column(ReclassTotalNetChangeAmt3; ReclassTotalNetChangeAmounts[3])
            {
                AutoFormatType = 1;
            }
            column(ReclassTotalDisposalAmt3; ReclassTotalDisposalAmounts[3])
            {
                AutoFormatType = 1;
            }
            column(ShowSection23; ShowSection(2, 3))
            {
            }
            column(TotalStartAmt4; TotalStartAmounts[4])
            {
                AutoFormatType = 1;
            }
            column(TotalNetChangeAmt4; TotalNetChangeAmounts[4])
            {
                AutoFormatType = 1;
            }
            column(TotalDisposalAmt4; TotalDisposalAmounts[4])
            {
                AutoFormatType = 1;
            }
            column(ReclassTotalStartAmt4; ReclassTotalStartAmounts[4])
            {
                AutoFormatType = 1;
            }
            column(ReclassTotalNetChangeAmt4; ReclassTotalNetChangeAmounts[4])
            {
                AutoFormatType = 1;
            }
            column(ReclassTotalDisposalAmt4; ReclassTotalDisposalAmounts[4])
            {
                AutoFormatType = 1;
            }
            column(ShowSection24; ShowSection(2, 4))
            {
            }
            column(TotalStartAmt5; TotalStartAmounts[5])
            {
                AutoFormatType = 1;
            }
            column(TotalNetChangeAmt5; TotalNetChangeAmounts[5])
            {
                AutoFormatType = 1;
            }
            column(ReclassTotalStartAmt5; ReclassTotalStartAmounts[5])
            {
                AutoFormatType = 1;
            }
            column(ReclassTotalNetChangeAmt5; ReclassTotalNetChangeAmounts[5])
            {
                AutoFormatType = 1;
            }
            column(ReclassTotalDisposalAmt5; ReclassTotalDisposalAmounts[5])
            {
                AutoFormatType = 1;
            }
            column(TotalDisposalAmt5; TotalDisposalAmounts[5])
            {
                AutoFormatType = 1;
            }
            column(ShowSection25; ShowSection(2, 5))
            {
            }
            column(TotalStartAmt6; TotalStartAmounts[6])
            {
                AutoFormatType = 1;
            }
            column(TotalNetChangeAmt6; TotalNetChangeAmounts[6])
            {
                AutoFormatType = 1;
            }
            column(ReclassTotalStartAmt6; ReclassTotalStartAmounts[6])
            {
                AutoFormatType = 1;
            }
            column(ReclassTotalNetChangeAmt6; ReclassTotalNetChangeAmounts[6])
            {
                AutoFormatType = 1;
            }
            column(ReclassTotalDisposalAmt6; ReclassTotalDisposalAmounts[6])
            {
                AutoFormatType = 1;
            }
            column(TotalDisposalAmt6; TotalDisposalAmounts[6])
            {
                AutoFormatType = 1;
            }
            column(ShowSection26; ShowSection(2, 6))
            {
            }
            column(TotalDisposalAmtType; TotalDisposalAmounts[Type])
            {
                AutoFormatType = 1;
            }
            column(ReclassTotalNetChangeAmtType; ReclassTotalNetChangeAmounts[Type])
            {
                AutoFormatType = 1;
            }
            column(ReclassTotalStartAmtType; ReclassTotalStartAmounts[Type])
            {
                AutoFormatType = 1;
            }
            column(ShowSection27; ShowSection(2, 7))
            {
            }
            column(TotalNetChangeAmt7; TotalNetChangeAmounts[7])
            {
                AutoFormatType = 1;
            }
            column(TotalStartAmt7; TotalStartAmounts[7])
            {
                AutoFormatType = 1;
            }
            column(TotalDisposalAmt7; TotalDisposalAmounts[7])
            {
                AutoFormatType = 1;
            }
            column(ReclassTotalDisposalAmt7; ReclassTotalDisposalAmounts[7])
            {
                AutoFormatType = 1;
            }
            column(ReclassTotalNetChangeAmt7; ReclassTotalNetChangeAmounts[7])
            {
                AutoFormatType = 1;
            }
            column(ReclassTotalStartAmt7; ReclassTotalStartAmounts[7])
            {
                AutoFormatType = 1;
            }
            column(FAClassCode_FixedAsset; "FA Class Code")
            {
            }
            column(FASubclassCode_FixedAsset; "FA Subclass Code")
            {
            }
            column(FALocationCode_FixedAsset; "FA Location Code")
            {
            }
            column(CompofMainAsset_FixedAsset; "Component of Main Asset")
            {
            }
            column(GlobalDim1Code_FixedAsset; "Global Dimension 1 Code")
            {
            }
            column(GlobalDim2Code_FixedAsset; "Global Dimension 2 Code")
            {
            }
            column(FAPostingGroup_FixedAsset; "FA Posting Group")
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            var
                NumberOfTypesForThiSFA: Integer;
            begin
                if not FADeprBook.Get("No.", DeprBookCode) then
                    CurrReport.Skip();
                if SkipRecord() then
                    CurrReport.Skip();

                NumberOfTypesForThiSFA := NumberOfTypes;
                HasDerogatorySetup := false;
                FADeprBook2.SetRange("FA No.", "No.");
                FADeprBook2.SetRange("Depreciation Book Code", DerogDeprBook.Code);
                if FADeprBook2.Find('-') then begin
                    NumberOfTypesForThiSFA := NumberOfTypes - 1;
                    HasDerogatorySetup := true;
                end;

                if GroupTotals = GroupTotals::"FA Posting Group" then
                    if "FA Posting Group" <> FADeprBook."FA Posting Group" then
                        Error(Text007, FieldCaption("FA Posting Group"), "No.");

                BeforeAmount := 0;
                EndingAmount := 0;
                if BudgetReport then
                    BudgetDepreciation.Calculate(
                      "No.", GetStartingDate(StartingDate), EndingDate, DeprBookCode, BeforeAmount, EndingAmount);

                i := 0;
                while i < NumberOfTypesForThiSFA do begin
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
                            PostingType := FADeprBook.FieldNo(Derogatory);
                    end;
                    if StartingDate <= 00000101D then begin
                        StartAmounts[i] := 0;
                        ReclassStartAmounts[i] := 0;
                    end else begin
                        StartAmounts[i] :=
                          FAGenReport.CalcFAPostedAmount(
                            "No.", PostingType, Period1, StartingDate, EndingDate,
                            DeprBookCode, BeforeAmount, EndingAmount, false, true);
                        if Reclassify then
                            ReclassStartAmounts[i] :=
                              FAGenReport.CalcFAPostedAmount(
                                "No.", PostingType, Period1, StartingDate, EndingDate,
                                DeprBookCode, 0, 0, true, true);
                    end;
                    NetChangeAmounts[i] := FAGenReport.CalcFAPostedAmount("No.", PostingType, Period2, StartingDate, EndingDate,
                                                   DeprBookCode, BeforeAmount, EndingAmount, false, true);
                    if i = 7 then begin
                        FAGenReport.SetSign(true);
                        NetChangeAmounts[i] := -(FAGenReport.CalcFAPostedAmount("No.", PostingType, Period2, StartingDate, EndingDate,
                                                 DeprBookCode, BeforeAmount, EndingAmount, false, true));
                        FAGenReport.SetSign(false);
                        DisposalAmounts[i] := FAGenReport.CalcFAPostedAmount("No.", PostingType, Period2, StartingDate, EndingDate,
                                                DeprBookCode, BeforeAmount, EndingAmount, false, true);
                    end;
                    if Reclassify then
                        ReclassNetChangeAmounts[i] :=
                          FAGenReport.CalcFAPostedAmount(
                            "No.", PostingType, Period2, StartingDate, EndingDate,
                            DeprBookCode, 0, 0, true, true);

                    if GetPeriodDisposal() then begin
                        DisposalAmounts[i] := -(StartAmounts[i] + NetChangeAmounts[i]);
                        ReclassDisposalAmounts[i] := -(ReclassStartAmounts[i] + ReclassNetChangeAmounts[i]);
                    end else begin
                        if i <> 7 then
                            DisposalAmounts[i] := 0;
                        ReclassDisposalAmounts[i] := 0;
                    end;
                end;

                for J := 1 to NumberOfTypes do begin
                    TotalEndingAmounts[J] := StartAmounts[J] + NetChangeAmounts[J] + DisposalAmounts[J];
                    if Reclassify then
                        ReclassTotalEndingAmounts[J] :=
                          ReclassStartAmounts[J] + ReclassNetChangeAmounts[J] + ReclassDisposalAmounts[J];
                end;
                OnOnAfterGetRecordOnBeforeCalculateBookValues(StartingDate, EndingDate, "Fixed Asset", StartAmounts, NetChangeAmounts, TotalEndingAmounts);
                BookValueAtEndingDate := 0;
                BookValueAtStartingDate := 0;
                for J := 1 to NumberOfTypes do begin
                    BookValueAtEndingDate := BookValueAtEndingDate + TotalEndingAmounts[J];
                    BookValueAtStartingDate := BookValueAtStartingDate + StartAmounts[J];
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
                    GroupTotals::"Main Asset":
                        SetCurrentKey("Component of Main Asset");
                    GroupTotals::"FA Location":
                        SetCurrentKey("FA Location Code");
                    GroupTotals::"Global Dimension 1":
                        SetCurrentKey("Global Dimension 1 Code");
                    GroupTotals::"Global Dimension 2":
                        SetCurrentKey("Global Dimension 2 Code");
                    GroupTotals::"FA Posting Group":
                        SetCurrentKey("FA Posting Group");
                end;

                Type := 1;
            end;
        }
    }

    requestpage
    {
        SaveValues = true;
        AboutTitle = 'About Fixed Asset Book Value 02';
        AboutText = 'The **Fixed Asset Book Value 02** report is useful when the user wants to view the movement in valuation of assets over a period time. There is further breakdown of values under additions and disposals during the period , further grouped under classes/subclasses if needed.';

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
                    field(IncludeReclassification; Reclassify)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Include Reclassification';
                        ToolTip = 'Specifies if you want the report to include acquisition cost and depreciation entries that are marked as reclassification entries. These entries are then printed in a separate column.';
                    }
                    field(PrintFASetup; PrintFASetup)
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

    labels
    {
    }

    trigger OnPreReport()
    begin
        Clear(DerogDeprBook);
        FAGenReport.ValidateDates(StartingDate, EndingDate);
        DeprBook.Get(DeprBookCode);
        DerogDeprBook.SetRange("Derogatory Calculation", DeprBookCode);
        if DerogDeprBook.Find('-') then;
        if GroupTotals = GroupTotals::"FA Posting Group" then
            FAGenReport.SetFAPostingGroup("Fixed Asset", DeprBook.Code);
        FAGenReport.AppendFAPostingFilter("Fixed Asset", StartingDate, EndingDate);
        FAFilter := "Fixed Asset".GetFilters();
        MainHeadLineText := Text000;
        if BudgetReport then
            MainHeadLineText := StrSubstNo('%1 %2', MainHeadLineText, Text001);
        DeprBookText :=
          StrSubstNo('%1%2 %3', DeprBook.TableCaption(), ':', DeprBookCode);
        NumberOfTypes := 7;
        MakeHeadLineText();
        MakeGroupTotalText();
        Period1 := Period1::"Before Starting Date";
        Period2 := Period2::"Net Change";
    end;

    var
        FASetup: Record "FA Setup";
        DeprBook: Record "Depreciation Book";
        FADeprBook: Record "FA Depreciation Book";
        FA: Record "Fixed Asset";
        FAGenReport: Codeunit "FA General Report";
        BudgetDepreciation: Codeunit "Budget Depreciation";
        DeprBookCode: Code[10];
        NumberOfTypes: Integer;
        FAFilter: Text;
        MainHeadLineText: Text;
        GroupHeadLineText: Text;
        DeprBookText: Text;
        GroupCodeName: Text;
        GroupHeadLine: Text;
        GroupTotals: Option " ","FA Class","FA Subclass","FA Location","Main Asset","Global Dimension 1","Global Dimension 2","FA Posting Group";
        HeadLineText: array[12] of Text;
        StartText: Text;
        EndText: Text;
        StartAmounts: array[7] of Decimal;
        NetChangeAmounts: array[7] of Decimal;
        DisposalAmounts: array[7] of Decimal;
        GroupStartAmounts: array[7] of Decimal;
        GroupNetChangeAmounts: array[7] of Decimal;
        GroupDisposalAmounts: array[7] of Decimal;
        TotalStartAmounts: array[7] of Decimal;
        TotalNetChangeAmounts: array[7] of Decimal;
        TotalDisposalAmounts: array[7] of Decimal;
        ReclassStartAmounts: array[7] of Decimal;
        ReclassNetChangeAmounts: array[7] of Decimal;
        ReclassDisposalAmounts: array[7] of Decimal;
        ReclassGroupStartAmounts: array[7] of Decimal;
        ReclassGroupNetChangeAmounts: array[7] of Decimal;
        ReclassGroupDisposalAmounts: array[7] of Decimal;
        ReclassTotalStartAmounts: array[7] of Decimal;
        ReclassTotalNetChangeAmounts: array[7] of Decimal;
        ReclassTotalDisposalAmounts: array[7] of Decimal;
        TotalEndingAmounts: array[7] of Decimal;
        ReclassTotalEndingAmounts: array[7] of Decimal;
        BookValueAtStartingDate: Decimal;
        BookValueAtEndingDate: Decimal;
        i: Integer;
        J: Integer;
        Type: Integer;
        PostingType: Integer;
        Period1: Option "Before Starting Date","Net Change","at Ending Date";
        Period2: Option "Before Starting Date","Net Change","at Ending Date";
        StartingDate: Date;
        EndingDate: Date;
        PrintDetails: Boolean;
        BudgetReport: Boolean;
        Reclassify: Boolean;
        ReclassificationText: Text;
        BeforeAmount: Decimal;
        EndingAmount: Decimal;
        AcquisitionDate: Date;
        DisposalDate: Date;
        DerogDeprBook: Record "Depreciation Book";
        FADeprBook2: Record "FA Depreciation Book";
        DeprBookInfo: array[5] of Text[30];
        DerogDeprBookInfo: array[5] of Text[30];
        PrintFASetup: Boolean;
        HasDerogatorySetup: Boolean;
        DerogDeprBookInfo5: Decimal;
        DeprBookInfo5: Decimal;

#pragma warning disable AA0074
        Text000: Label 'Fixed Asset - Book Value 02';
        Text001: Label '(Budget Report)';
        Text002: Label 'Group Totals';
        Text003: Label 'Reclassification';
        Text004: Label 'Addition in Period';
        Text005: Label 'Disposal in Period';
        Text006: Label 'Group Total';
#pragma warning disable AA0470
        Text007: Label '%1 has been modified in fixed asset %2.';
        Text10800: Label 'Increased in Period';
        Text10801: Label 'Decreased in Period';
#pragma warning restore AA0470
#pragma warning restore AA0074
        PageCaptionLbl: Label 'Page';
        TotalCaptionLbl: Label 'Total';

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
                GroupCodeName := "Fixed Asset".FieldCaption("FA Class Code");
            GroupTotals::"FA Subclass":
                GroupCodeName := "Fixed Asset".FieldCaption("FA Subclass Code");
            GroupTotals::"FA Location":
                GroupCodeName := "Fixed Asset".FieldCaption("FA Location Code");
            GroupTotals::"Main Asset":
                GroupCodeName := "Fixed Asset".FieldCaption("Main Asset/Component");
            GroupTotals::"Global Dimension 1":
                GroupCodeName := "Fixed Asset".FieldCaption("Global Dimension 1 Code");
            GroupTotals::"Global Dimension 2":
                GroupCodeName := "Fixed Asset".FieldCaption("Global Dimension 2 Code");
            GroupTotals::"FA Posting Group":
                GroupCodeName := "Fixed Asset".FieldCaption("FA Posting Group");
        end;
        if GroupCodeName <> '' then
            GroupCodeName := StrSubstNo('%1%2 %3', Text002, ':', GroupCodeName);
    end;

    local procedure MakeHeadLineText()
    begin
        EndText := StrSubstNo('%1', EndingDate);
        StartText := StrSubstNo('%1', StartingDate - 1);
        if Reclassify then
            ReclassificationText := Text003;

        HeadLineText[1] := FADeprBook.FieldCaption("Acquisition Cost");
        HeadLineText[2] := FADeprBook.FieldCaption(Depreciation);
        HeadLineText[3] := FADeprBook.FieldCaption("Write-Down");
        HeadLineText[4] := FADeprBook.FieldCaption(Appreciation);
        HeadLineText[5] := FADeprBook.FieldCaption("Book Value");
        HeadLineText[6] := StrSubstNo('%1  %2', '', Text004);
        HeadLineText[7] := StrSubstNo('%1  %2', '', Text005);
        HeadLineText[8] := FADeprBook.FieldCaption("Custom 1");
        HeadLineText[9] := FADeprBook.FieldCaption("Custom 2");
        HeadLineText[10] := FADeprBook.FieldCaption(Derogatory);
        HeadLineText[11] := StrSubstNo('%1  %2', '', Text10800);
        HeadLineText[12] := StrSubstNo('%1  %2', '', Text10801);
    end;

    local procedure MakeGroupHeadLine()
    begin
        for J := 1 to NumberOfTypes do begin
            GroupStartAmounts[J] := 0;
            GroupNetChangeAmounts[J] := 0;
            GroupDisposalAmounts[J] := 0;
            ReclassGroupStartAmounts[J] := 0;
            ReclassGroupNetChangeAmounts[J] := 0;
            ReclassGroupDisposalAmounts[J] := 0;
        end;
        case GroupTotals of
            GroupTotals::"FA Class":
                GroupHeadLine := "Fixed Asset"."FA Class Code";
            GroupTotals::"FA Subclass":
                GroupHeadLine := "Fixed Asset"."FA Subclass Code";
            GroupTotals::"FA Location":
                GroupHeadLine := "Fixed Asset"."FA Location Code";
            GroupTotals::"Main Asset":
                begin
                    FA."Main Asset/Component" := FA."Main Asset/Component"::"Main Asset";
                    GroupHeadLine :=
                      StrSubstNo('%1 %2', Format(FA."Main Asset/Component"), "Fixed Asset"."Component of Main Asset");
                    if "Fixed Asset"."Component of Main Asset" = '' then
                        GroupHeadLine := StrSubstNo('%1 %2', GroupHeadLine, '*****');
                end;
            GroupTotals::"Global Dimension 1":
                GroupHeadLine := "Fixed Asset"."Global Dimension 1 Code";
            GroupTotals::"Global Dimension 2":
                GroupHeadLine := "Fixed Asset"."Global Dimension 2 Code";
            GroupTotals::"FA Posting Group":
                GroupHeadLine := "Fixed Asset"."FA Posting Group";
        end;
        if GroupHeadLine = '' then
            GroupHeadLine := '*****';

        GroupHeadLineText := StrSubstNo('%1%2 %3', Text006, ':', GroupHeadLine);
    end;

    local procedure UpdateTotals()
    begin
        for J := 1 to NumberOfTypes do begin
            GroupStartAmounts[J] := GroupStartAmounts[J] + StartAmounts[J];
            GroupNetChangeAmounts[J] := GroupNetChangeAmounts[J] + NetChangeAmounts[J];
            GroupDisposalAmounts[J] := GroupDisposalAmounts[J] + DisposalAmounts[J];
            TotalStartAmounts[J] := TotalStartAmounts[J] + StartAmounts[J];
            TotalNetChangeAmounts[J] := TotalNetChangeAmounts[J] + NetChangeAmounts[J];
            TotalDisposalAmounts[J] := TotalDisposalAmounts[J] + DisposalAmounts[J];
            if Reclassify then begin
                ReclassGroupStartAmounts[J] := ReclassGroupStartAmounts[J] + ReclassStartAmounts[J];
                ReclassGroupNetChangeAmounts[J] := ReclassGroupNetChangeAmounts[J] + ReclassNetChangeAmounts[J];
                ReclassGroupDisposalAmounts[J] := ReclassGroupDisposalAmounts[J] + ReclassDisposalAmounts[J];
                ReclassTotalStartAmounts[J] := ReclassTotalStartAmounts[J] + ReclassStartAmounts[J];
                ReclassTotalNetChangeAmounts[J] := ReclassTotalNetChangeAmounts[J] + ReclassNetChangeAmounts[J];
                ReclassTotalDisposalAmounts[J] := ReclassTotalDisposalAmounts[J] + ReclassDisposalAmounts[J];
            end;
        end;
    end;

    local procedure CreateGroupTotals()
    begin
        for J := 1 to NumberOfTypes do begin
            TotalEndingAmounts[J] := GroupStartAmounts[J] + GroupNetChangeAmounts[J] + GroupDisposalAmounts[J];
            if Reclassify then
                ReclassTotalEndingAmounts[J] :=
                  ReclassGroupStartAmounts[J] + ReclassGroupNetChangeAmounts[J] + ReclassGroupDisposalAmounts[J];
        end;
        BookValueAtEndingDate := 0;
        BookValueAtStartingDate := 0;
        for J := 1 to NumberOfTypes do begin
            BookValueAtEndingDate := BookValueAtEndingDate + TotalEndingAmounts[J];
            BookValueAtStartingDate := BookValueAtStartingDate + GroupStartAmounts[J];
        end;
    end;

    local procedure CreateTotals()
    begin
        for J := 1 to NumberOfTypes do begin
            TotalEndingAmounts[J] := TotalStartAmounts[J] + TotalNetChangeAmounts[J] + TotalDisposalAmounts[J];
            if Reclassify then
                ReclassTotalEndingAmounts[J] :=
                  ReclassTotalStartAmounts[J] + ReclassTotalNetChangeAmounts[J] + ReclassTotalDisposalAmounts[J];
        end;
        BookValueAtEndingDate := 0;
        BookValueAtStartingDate := 0;
        for J := 1 to NumberOfTypes do begin
            BookValueAtEndingDate := BookValueAtEndingDate + TotalEndingAmounts[J];
            BookValueAtStartingDate := BookValueAtStartingDate + TotalStartAmounts[J];
        end;
    end;

    local procedure GetStartingDate(StartingDate: Date): Date
    begin
        if StartingDate <= 00000101D then
            exit(0D);

        exit(StartingDate - 1);
    end;

    local procedure ShowSection(Section: Option Body,GroupFooter,Footer; Type: Integer): Boolean
    begin
        case Section of
            Section::Body:
                exit(
                  PrintDetails and
                  ((StartAmounts[Type] <> 0) or
                   (NetChangeAmounts[Type] <> 0) or
                   (DisposalAmounts[Type] <> 0) or
                   (TotalEndingAmounts[Type] <> 0) or
                   (ReclassStartAmounts[Type] <> 0) or
                   (ReclassNetChangeAmounts[Type] <> 0) or
                   (ReclassDisposalAmounts[Type] <> 0) or
                   (ReclassTotalEndingAmounts[Type] <> 0)));
            Section::GroupFooter:
                exit(
                  (GroupTotals <> GroupTotals::" ") and
                  ((GroupStartAmounts[Type] <> 0) or
                   (GroupNetChangeAmounts[Type] <> 0) or
                   (GroupDisposalAmounts[Type] <> 0) or
                   (TotalEndingAmounts[Type] <> 0) or
                   (ReclassGroupStartAmounts[Type] <> 0) or
                   (ReclassGroupNetChangeAmounts[Type] <> 0) or
                   (ReclassGroupDisposalAmounts[Type] <> 0) or
                   (ReclassTotalEndingAmounts[Type] <> 0)));
            Section::Footer:
                exit(
                  (TotalStartAmounts[Type] <> 0) or
                  (TotalNetChangeAmounts[Type] <> 0) or
                  (TotalDisposalAmounts[Type] <> 0) or
                  (TotalEndingAmounts[Type] <> 0) or
                  (ReclassTotalStartAmounts[Type] <> 0) or
                  (ReclassTotalNetChangeAmounts[Type] <> 0) or
                  (ReclassTotalDisposalAmounts[Type] <> 0) or
                  (ReclassTotalEndingAmounts[Type] <> 0));
        end;
    end;

    procedure SetMandatoryFields(DepreciationBookCodeFrom: Code[10]; StartingDateFrom: Date; EndingDateFrom: Date)
    begin
        DeprBookCode := DepreciationBookCodeFrom;
        StartingDate := StartingDateFrom;
        EndingDate := EndingDateFrom;
    end;

    procedure SetTotalFields(GroupTotalsFrom: Option; PrintDetailsFrom: Boolean; BudgetReportFrom: Boolean; ReclassifyFrom: Boolean)
    begin
        GroupTotals := GroupTotalsFrom;
        PrintDetails := PrintDetailsFrom;
        BudgetReport := BudgetReportFrom;
        Reclassify := ReclassifyFrom;
    end;

    procedure GetDepreciationBookCode()
    begin
        if DeprBookCode = '' then begin
            FASetup.Get();
            DeprBookCode := FASetup."Default Depr. Book";
        end;
    end;

    [Scope('OnPrem')]
    procedure GetDeprBookInfo()
    begin
        DeprBookInfo[1] := DeprBookCode;
        DeprBookInfo[2] := Format(FADeprBook."Depreciation Method");
        DeprBookInfo[3] := Format(FADeprBook."Depreciation Starting Date");
        DeprBookInfo[4] := Format(FADeprBook."Depreciation Ending Date");
        DeprBookInfo[5] := Format(FADeprBook."Declining-Balance %");
        DeprBookInfo5 := FADeprBook."Declining-Balance %";
    end;

    [Scope('OnPrem')]
    procedure GetDerogDeprBookInfo()
    begin
        DerogDeprBookInfo[1] := FADeprBook2."Depreciation Book Code";
        DerogDeprBookInfo[2] := Format(FADeprBook2."Depreciation Method");
        DerogDeprBookInfo[3] := Format(FADeprBook2."Depreciation Starting Date");
        DerogDeprBookInfo[4] := Format(FADeprBook2."Depreciation Ending Date");
        DerogDeprBookInfo[5] := Format(FADeprBook2."Declining-Balance %");
        DerogDeprBookInfo5 := FADeprBook2."Declining-Balance %";
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOnAfterGetRecordOnBeforeCalculateBookValues(StartingDate: Date; EndingDate: Date; var FixedAsset: Record "Fixed Asset"; var StartAmounts: array[6] of Decimal; var NetChangeAmounts: array[6] of Decimal; var TotalEndingAmounts: array[7] of Decimal)
    begin
    end;
}

