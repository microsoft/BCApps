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
            column(USERID; UserId)
            {
            }
            column(DeprBookText; DeprBookText)
            {
            }
            column(GroupCodeName; GroupCodeName)
            {
            }
            column(FixedAssetCaptionFilter; TableCaption + ': ' + FAFilter)
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
            column(HeadLineText1; HeadLineText[1])
            {
            }
            column(HeadLineText6; HeadLineText[6])
            {
            }
            column(HeadLineText7; HeadLineText[7])
            {
            }
            column(HeadLineText_1__Control7; HeadLineText[1])
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
            column(StartText_Control23; StartText)
            {
            }
            column(BookValueAtStartingDate; BookValueAtStartingDate)
            {
                AutoFormatType = 1;
            }
            column(ReclassificationText; ReclassificationText)
            {
            }
            column(BudgetReport; BudgetReport)
            {
            }
            column(PrintDetails; PrintDetails)
            {
            }
            column(Reclassify; Reclassify)
            {
            }
            column(HeadLineText2; HeadLineText[2])
            {
            }
            column(HeadLineText_6__Control9; HeadLineText[6])
            {
            }
            column(HeadLineText_7__Control10; HeadLineText[7])
            {
            }
            column(HeadLineText_2__Control11; HeadLineText[2])
            {
            }
            column(StartText_Control25; StartText)
            {
            }
            column(EndText_Control31; EndText)
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
            column(HeadLineText_6__Control47; HeadLineText[6])
            {
            }
            column(HeadLineText_7__Control50; HeadLineText[7])
            {
            }
            column(HeadLineText_3__Control53; HeadLineText[3])
            {
            }
            column(StartText_Control45; StartText)
            {
            }
            column(EndText_Control56; EndText)
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
            column(HeadLineText_6__Control70; HeadLineText[6])
            {
            }
            column(HeadLineText_7__Control71; HeadLineText[7])
            {
            }
            column(HeadLineText_4__Control72; HeadLineText[4])
            {
            }
            column(StartText_Control73; StartText)
            {
            }
            column(EndText_Control74; EndText)
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
            column(HeadLineText_6__Control49; HeadLineText[6])
            {
            }
            column(HeadLineText_7__Control51; HeadLineText[7])
            {
            }
            column(HeadLineText_8__Control52; HeadLineText[8])
            {
            }
            column(StartText_Control54; StartText)
            {
            }
            column(EndText_Control55; EndText)
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
            column(HeadLineText_6__Control218; HeadLineText[6])
            {
            }
            column(HeadLineText_7__Control219; HeadLineText[7])
            {
            }
            column(HeadLineText_9__Control220; HeadLineText[9])
            {
            }
            column(StartText_Control221; StartText)
            {
            }
            column(EndText_Control222; EndText)
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
            column(HeadLineText_5__Control79; HeadLineText[5])
            {
            }
            column(EndText_Control80; EndText)
            {
            }
            column(BookValueAtEndingDate; BookValueAtEndingDate)
            {
                AutoFormatType = 1;
            }
            column(GroupHeadLineText; GroupHeadLineText)
            {
            }
            column(HeadLineText_1__Control83; HeadLineText[1])
            {
            }
            column(HeadLineText_6__Control84; HeadLineText[6])
            {
            }
            column(HeadLineText_7__Control85; HeadLineText[7])
            {
            }
            column(HeadLineText_1__Control86; HeadLineText[1])
            {
            }
            column(StartText_Control87; StartText)
            {
            }
            column(EndText_Control88; EndText)
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
            column(TotalEndingAmounts_1__Control92; TotalEndingAmounts[1])
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
            column(ReclassTotalEndingAmounts_1__Control189; ReclassTotalEndingAmounts[1])
            {
                AutoFormatType = 1;
            }
            column(HeadLineText_5__Control14; HeadLineText[5])
            {
            }
            column(StartText_Control16; StartText)
            {
            }
            column(BookValueAtStartingDate_Control26; BookValueAtStartingDate)
            {
                AutoFormatType = 1;
            }
            column(ReclassificationText_Control42; ReclassificationText)
            {
            }
            column(GroupTotals; GroupTotals)
            {
            }
            column(ShowSection12; ShowSection(1, 2))
            {
            }
            column(HeadLineText_2__Control93; HeadLineText[2])
            {
            }
            column(HeadLineText_6__Control94; HeadLineText[6])
            {
            }
            column(HeadLineText_7__Control95; HeadLineText[7])
            {
            }
            column(HeadLineText_2__Control96; HeadLineText[2])
            {
            }
            column(StartText_Control97; StartText)
            {
            }
            column(EndText_Control98; EndText)
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
            column(TotalEndingAmounts_2__Control102; TotalEndingAmounts[2])
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
            column(ReclassTotalEndingAmounts_2__Control193; ReclassTotalEndingAmounts[2])
            {
                AutoFormatType = 1;
            }
            column(ShowSection_1_2__Control369; ShowSection(1, 2))
            {
            }
            column(GroupTotals_Control370; GroupTotals)
            {
            }
            column(HeadLineText_3__Control103; HeadLineText[3])
            {
            }
            column(HeadLineText_6__Control104; HeadLineText[6])
            {
            }
            column(HeadLineText_7__Control105; HeadLineText[7])
            {
            }
            column(HeadLineText_3__Control106; HeadLineText[3])
            {
            }
            column(StartText_Control107; StartText)
            {
            }
            column(EndText_Control108; EndText)
            {
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
            column(TotalEndingAmounts_3__Control112; TotalEndingAmounts[3])
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
            column(ReclassTotalEndingAmounts_3__Control197; ReclassTotalEndingAmounts[3])
            {
                AutoFormatType = 1;
            }
            column(GroupTotals_Control381; GroupTotals)
            {
            }
            column(ShowSection13; ShowSection(1, 3))
            {
            }
            column(HeadLineText_4__Control113; HeadLineText[4])
            {
            }
            column(HeadLineText_6__Control114; HeadLineText[6])
            {
            }
            column(HeadLineText_7__Control115; HeadLineText[7])
            {
            }
            column(HeadLineText_4__Control116; HeadLineText[4])
            {
            }
            column(StartText_Control117; StartText)
            {
            }
            column(EndText_Control118; EndText)
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
            column(TotalEndingAmounts_4__Control122; TotalEndingAmounts[4])
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
            column(ReclassTotalEndingAmounts_4__Control201; ReclassTotalEndingAmounts[4])
            {
                AutoFormatType = 1;
            }
            column(GroupTotals_Control391; GroupTotals)
            {
            }
            column(ShowSection14; ShowSection(1, 4))
            {
            }
            column(HeadLineText_8__Control232; HeadLineText[8])
            {
            }
            column(HeadLineText_6__Control233; HeadLineText[6])
            {
            }
            column(HeadLineText_7__Control234; HeadLineText[7])
            {
            }
            column(HeadLineText_8__Control235; HeadLineText[8])
            {
            }
            column(StartText_Control236; StartText)
            {
            }
            column(EndText_Control237; EndText)
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
            column(TotalEndingAmounts_5__Control241; TotalEndingAmounts[5])
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
            column(ReclassTotalEndingAmounts_5__Control245; ReclassTotalEndingAmounts[5])
            {
                AutoFormatType = 1;
            }
            column(GroupTotals_Control401; GroupTotals)
            {
            }
            column(ShowSection15; ShowSection(1, 5))
            {
            }
            column(HeadLineText_9__Control246; HeadLineText[9])
            {
            }
            column(HeadLineText_6__Control247; HeadLineText[6])
            {
            }
            column(HeadLineText_7__Control248; HeadLineText[7])
            {
            }
            column(HeadLineText_9__Control249; HeadLineText[9])
            {
            }
            column(StartText_Control250; StartText)
            {
            }
            column(EndText_Control251; EndText)
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
            column(TotalEndingAmounts_6__Control255; TotalEndingAmounts[6])
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
            column(ReclassTotalEndingAmounts_6__Control259; ReclassTotalEndingAmounts[6])
            {
                AutoFormatType = 1;
            }
            column(GroupTotals_Control414; GroupTotals)
            {
            }
            column(ShowSection16; ShowSection(1, 6))
            {
            }
            column(HeadLineText_5__Control123; HeadLineText[5])
            {
            }
            column(EndText_Control124; EndText)
            {
            }
            column(BookValueAtEndingDate_Control125; BookValueAtEndingDate)
            {
                AutoFormatType = 1;
            }
            column(HeadLineText_1__Control127; HeadLineText[1])
            {
            }
            column(HeadLineText_6__Control128; HeadLineText[6])
            {
            }
            column(HeadLineText_7__Control129; HeadLineText[7])
            {
            }
            column(HeadLineText_1__Control130; HeadLineText[1])
            {
            }
            column(StartText_Control131; StartText)
            {
            }
            column(EndText_Control132; EndText)
            {
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
            column(TotalEndingAmounts_1__Control136; TotalEndingAmounts[1])
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
            column(ReclassTotalEndingAmounts_1__Control205; ReclassTotalEndingAmounts[1])
            {
                AutoFormatType = 1;
            }
            column(HeadLineText_5__Control27; HeadLineText[5])
            {
            }
            column(StartText_Control29; StartText)
            {
            }
            column(BookValueAtStartingDate_Control30; BookValueAtStartingDate)
            {
                AutoFormatType = 1;
            }
            column(ReclassificationText_Control46; ReclassificationText)
            {
            }
            column(ShowSection22; ShowSection(2, 2))
            {
            }
            column(HeadLineText_2__Control137; HeadLineText[2])
            {
            }
            column(HeadLineText_6__Control138; HeadLineText[6])
            {
            }
            column(HeadLineText_7__Control139; HeadLineText[7])
            {
            }
            column(HeadLineText_2__Control140; HeadLineText[2])
            {
            }
            column(StartText_Control141; StartText)
            {
            }
            column(EndText_Control142; EndText)
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
            column(TotalEndingAmounts_2__Control146; TotalEndingAmounts[2])
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
            column(ReclassTotalEndingAmounts_2__Control209; ReclassTotalEndingAmounts[2])
            {
                AutoFormatType = 1;
            }
            column(ShowSection_2_2__Control433; ShowSection(2, 2))
            {
            }
            column(HeadLineText_3__Control147; HeadLineText[3])
            {
            }
            column(HeadLineText_6__Control148; HeadLineText[6])
            {
            }
            column(HeadLineText_7__Control149; HeadLineText[7])
            {
            }
            column(HeadLineText_3__Control150; HeadLineText[3])
            {
            }
            column(StartText_Control151; StartText)
            {
            }
            column(EndText_Control152; EndText)
            {
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
            column(TotalEndingAmounts_3__Control156; TotalEndingAmounts[3])
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
            column(ReclassTotalEndingAmounts_3__Control213; ReclassTotalEndingAmounts[3])
            {
                AutoFormatType = 1;
            }
            column(ShowSection23; ShowSection(2, 3))
            {
            }
            column(HeadLineText_4__Control157; HeadLineText[4])
            {
            }
            column(HeadLineText_6__Control158; HeadLineText[6])
            {
            }
            column(HeadLineText_7__Control159; HeadLineText[7])
            {
            }
            column(HeadLineText_4__Control160; HeadLineText[4])
            {
            }
            column(StartText_Control161; StartText)
            {
            }
            column(EndText_Control162; EndText)
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
            column(TotalEndingAmounts_4__Control166; TotalEndingAmounts[4])
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
            column(ReclassTotalEndingAmounts_4__Control217; ReclassTotalEndingAmounts[4])
            {
                AutoFormatType = 1;
            }
            column(ShowSection24; ShowSection(2, 4))
            {
            }
            column(HeadLineText_8__Control272; HeadLineText[8])
            {
            }
            column(HeadLineText_6__Control273; HeadLineText[6])
            {
            }
            column(HeadLineText_7__Control274; HeadLineText[7])
            {
            }
            column(HeadLineText_8__Control275; HeadLineText[8])
            {
            }
            column(StartText_Control276; StartText)
            {
            }
            column(EndText_Control277; EndText)
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
            column(TotalEndingAmounts_5__Control280; TotalEndingAmounts[5])
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
            column(ReclassTotalEndingAmounts_5__Control284; ReclassTotalEndingAmounts[5])
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
            column(HeadLineText_9__Control3; HeadLineText[9])
            {
            }
            column(HeadLineText_6__Control15; HeadLineText[6])
            {
            }
            column(HeadLineText_7__Control261; HeadLineText[7])
            {
            }
            column(HeadLineText_9__Control262; HeadLineText[9])
            {
            }
            column(StartText_Control263; StartText)
            {
            }
            column(EndText_Control264; EndText)
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
            column(TotalEndingAmounts_6__Control267; TotalEndingAmounts[6])
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
            column(ReclassTotalEndingAmounts_6__Control271; ReclassTotalEndingAmounts[6])
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
            column(HeadLineText_5__Control167; HeadLineText[5])
            {
            }
            column(EndText_Control168; EndText)
            {
            }
            column(BookValueAtEndingDate_Control169; BookValueAtEndingDate)
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
                        Error(Text007, FieldCaption("FA Posting Group"), "No.");

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
                    if Reclassify then
                        ReclassNetChangeAmounts[i] :=
                          FAGenReport.CalcFAPostedAmount(
                            "No.", PostingType, Period2, StartingDate, EndingDate,
                            DeprBookCode, 0, 0, true, true);

                    if GetPeriodDisposal() then begin
                        DisposalAmounts[i] := -(StartAmounts[i] + NetChangeAmounts[i]);
                        ReclassDisposalAmounts[i] := -(ReclassStartAmounts[i] + ReclassNetChangeAmounts[i]);
                    end else begin
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
        FAGenReport.ValidateDates(StartingDate, EndingDate);
        DeprBook.Get(DeprBookCode);
        if GroupTotals = GroupTotals::"FA Posting Group" then
            FAGenReport.SetFAPostingGroup("Fixed Asset", DeprBook.Code);
        FAGenReport.AppendFAPostingFilter("Fixed Asset", StartingDate, EndingDate);
        FAFilter := "Fixed Asset".GetFilters();
        MainHeadLineText := Text000;
        if BudgetReport then
            MainHeadLineText := StrSubstNo('%1 %2', MainHeadLineText, Text001);
        DeprBookText :=
          StrSubstNo('%1%2 %3', DeprBook.TableCaption(), ':', DeprBookCode);
        NumberOfTypes := 6;
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
        HeadLineText: array[10] of Text;
        StartText: Text;
        EndText: Text;
        StartAmounts: array[6] of Decimal;
        NetChangeAmounts: array[6] of Decimal;
        DisposalAmounts: array[6] of Decimal;
        GroupStartAmounts: array[6] of Decimal;
        GroupNetChangeAmounts: array[6] of Decimal;
        GroupDisposalAmounts: array[6] of Decimal;
        TotalStartAmounts: array[6] of Decimal;
        TotalNetChangeAmounts: array[6] of Decimal;
        TotalDisposalAmounts: array[6] of Decimal;
        ReclassStartAmounts: array[6] of Decimal;
        ReclassNetChangeAmounts: array[6] of Decimal;
        ReclassDisposalAmounts: array[6] of Decimal;
        ReclassGroupStartAmounts: array[6] of Decimal;
        ReclassGroupNetChangeAmounts: array[6] of Decimal;
        ReclassGroupDisposalAmounts: array[6] of Decimal;
        ReclassTotalStartAmounts: array[6] of Decimal;
        ReclassTotalNetChangeAmounts: array[6] of Decimal;
        ReclassTotalDisposalAmounts: array[6] of Decimal;
        TotalEndingAmounts: array[7] of Decimal;
        ReclassTotalEndingAmounts: array[6] of Decimal;
        BookValueAtStartingDate: Decimal;
        BookValueAtEndingDate: Decimal;
        i: Integer;
        J: Integer;
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
#pragma warning restore AA0470
#pragma warning restore AA0074
        CurrReport_PAGENOCaptionLbl: Label 'Page';
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

    [IntegrationEvent(false, false)]
    local procedure OnOnAfterGetRecordOnBeforeCalculateBookValues(StartingDate: Date; EndingDate: Date; var FixedAsset: Record "Fixed Asset"; var StartAmounts: array[6] of Decimal; var NetChangeAmounts: array[6] of Decimal; var TotalEndingAmounts: array[7] of Decimal)
    begin
    end;
}

