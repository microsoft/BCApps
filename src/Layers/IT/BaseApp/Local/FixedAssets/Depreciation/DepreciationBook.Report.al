// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Depreciation;

using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Ledger;
using Microsoft.FixedAssets.Posting;
using Microsoft.FixedAssets.Setup;
using Microsoft.Foundation.Company;
using System.Utilities;

report 12119 "Depreciation Book"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/FixedAssets/Depreciation/DepreciationBook.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Depreciation Book';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = const(1));
            column(CompanyName; CompanyInformation[1])
            {
            }
            column(CompanyAddress; CompanyInformation[2])
            {
            }
            column(CompanyPostCodeCityCounty; CompanyInformation[3])
            {
            }
            column(RegisterCompanyNo; CompanyInformation[4])
            {
            }
            column(CompanyVATRegNo; CompanyInformation[5])
            {
            }
            column(CompanyFiscalCode; CompanyInformation[6])
            {
            }
            column(ReportCaption; CompanyInformation[7])
            {
            }
            column(PrintCompanyInfoField; PrintCompanyInformation)
            {
            }
            column(RegisterCompanyNoCaption; RegisterCompanyNoCaptionLbl)
            {
            }
            column(VATRegNoCaption; VATRegNoCaptionLbl)
            {
            }
            column(FiscalCodeCaption; FiscalCodeCaptionLbl)
            {
            }
            column(Integer_Number; Number)
            {
            }

            trigger OnPreDataItem()
            var
                i: Integer;
            begin
                if not PrintCompanyInformation then
                    CurrReport.Break();

                for i := 1 to 6 do
                    if CompanyInformation[i] = '' then
                        Error(CompanyFieldsNotFilledErr);
            end;
        }
        dataitem("Fixed Asset"; "Fixed Asset")
        {
            RequestFilterFields = "No.", "FA Class Code", "FA Subclass Code", "Budgeted Asset";
            column(DeprBook_Code_______DeprBook_Description; DeprBook.Code + ' : ' + DeprBook.Description)
            {
            }
            column(StartText______EndText; StartText + '..' + EndText)
            {
            }
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(EndText; EndText)
            {
            }
            column(StartText; StartText)
            {
            }
            column(EndText_Control17; EndText)
            {
            }
            column(StartText_Control12; StartText)
            {
            }
            column(PrintDetails; PrintDetails)
            {
            }
            column(DeprBookCode; DeprBookCode)
            {
            }
            column(StartingDate; StartingDate)
            {
            }
            column(EndingDate; EndingDate)
            {
            }
            column(Source_FA_No__________ComingFromDescription; "Source FA No." + '    ' + ComingFromDescription)
            {
            }
            column(No_________Description; "No." + ' : ' + Description)
            {
            }
            column(Fixed_Asset___FA_Subclass_Code________FASubclassName; "Fixed Asset"."FA Subclass Code" + ' : ' + FASubclassName)
            {
            }
            column(FASource; FASource)
            {
            }
            column(InventoryYear; InventoryYear)
            {
            }
            column(EndText_Control1130045; EndText)
            {
            }
            column(StartText_Control1130055; StartText)
            {
            }
            column(EndText_Control1130057; EndText)
            {
            }
            column(StartText_Control1130062; StartText)
            {
            }
            column(FAsset2__Acquisition_Year_; FAsset2."Acquisition Year")
            {
                AutoFormatType = 1;
            }
            column(FAsset2__FA_Subclass_Code_; FAsset2."FA Subclass Code")
            {
                AutoFormatType = 1;
            }
            column(FAsset2__FA_Class_Code_; FAsset2."FA Class Code")
            {
                AutoFormatType = 1;
            }
            column(Fixed_Asset__FA_Class_Code_; "FA Class Code")
            {
                AutoFormatType = 1;
            }
            column(Fixed_Asset__FA_Subclass_Code_; "FA Subclass Code")
            {
                AutoFormatType = 1;
            }
            column(Fixed_Asset__Acquisition_Year_; "Acquisition Year")
            {
                AutoFormatType = 1;
            }
            column(TotalEndingAmounts_Type_; TotalEndingAmounts[Type])
            {
                AutoFormatType = 1;
            }
            column(DisposalAmounts_Type_; DisposalAmounts[Type])
            {
                AutoFormatType = 1;
            }
            column(NetChangeAmounts_Type_; NetChangeAmounts[Type])
            {
                AutoFormatType = 1;
            }
            column(StartAmounts_Type_; StartAmounts[Type])
            {
                AutoFormatType = 1;
            }
            column(HeadLineText_1_; HeadLineText[1])
            {
            }
            column(TotalEndingAmounts_1_; TotalEndingAmounts[1])
            {
                AutoFormatType = 1;
            }
            column(DisposalAmounts_1_; DisposalAmounts[1])
            {
                AutoFormatType = 1;
            }
            column(NetChangeAmounts_1_; NetChangeAmounts[1])
            {
                AutoFormatType = 1;
            }
            column(StartAmounts_1_; StartAmounts[1])
            {
                AutoFormatType = 1;
            }
            column(TotalEndingAmounts_Type__Control1130084; TotalEndingAmounts[Type])
            {
                AutoFormatType = 1;
            }
            column(DisposalAmounts_Type__Control1130085; DisposalAmounts[Type])
            {
                AutoFormatType = 1;
            }
            column(NetChangeAmounts_Type__Control1130086; NetChangeAmounts[Type])
            {
                AutoFormatType = 1;
            }
            column(StartAmounts_Type__Control1130087; StartAmounts[Type])
            {
                AutoFormatType = 1;
            }
            column(HeadLineText_4_; HeadLineText[4])
            {
            }
            column(StartAmounts_4_; StartAmounts[4])
            {
                AutoFormatType = 1;
            }
            column(NetChangeAmounts_4_; NetChangeAmounts[4])
            {
                AutoFormatType = 1;
            }
            column(DisposalAmounts_4_; DisposalAmounts[4])
            {
                AutoFormatType = 1;
            }
            column(TotalEndingAmounts_4_; TotalEndingAmounts[4])
            {
                AutoFormatType = 1;
            }
            column(TotalEndingAmounts_Type__Control1130089; TotalEndingAmounts[Type])
            {
                AutoFormatType = 1;
            }
            column(DisposalAmounts_Type__Control1130091; DisposalAmounts[Type])
            {
                AutoFormatType = 1;
            }
            column(NetChangeAmounts_Type__Control1130093; NetChangeAmounts[Type])
            {
                AutoFormatType = 1;
            }
            column(StartAmounts_Type__Control1130095; StartAmounts[Type])
            {
                AutoFormatType = 1;
            }
            column(HeadLineText_3_; HeadLineText[3])
            {
            }
            column(StartAmounts_3_; StartAmounts[3])
            {
                AutoFormatType = 1;
            }
            column(NetChangeAmounts_3_; NetChangeAmounts[3])
            {
                AutoFormatType = 1;
            }
            column(DisposalAmounts_3_; DisposalAmounts[3])
            {
                AutoFormatType = 1;
            }
            column(TotalEndingAmounts_3_; TotalEndingAmounts[3])
            {
                AutoFormatType = 1;
            }
            column(BookValueAtEndingDate; BookValueAtEndingDate)
            {
                AutoFormatType = 1;
            }
            column(StartAmounts_1__StartAmounts_3__StartAmounts_4_; StartAmounts[1] + StartAmounts[3] + StartAmounts[4])
            {
            }
            column(NetChangeAmounts_1__NetChangeAmounts_3__NetChangeAmounts_4_; NetChangeAmounts[1] + NetChangeAmounts[3] + NetChangeAmounts[4])
            {
            }
            column(DisposalAmounts_1__DisposalAmounts_3__DisposalAmounts_4_; DisposalAmounts[1] + DisposalAmounts[3] + DisposalAmounts[4])
            {
            }
            column(TotalEndingAmounts_1__TotalEndingAmounts_3__TotalEndingAmounts_4_; TotalEndingAmounts[1] + TotalEndingAmounts[3] + TotalEndingAmounts[4])
            {
            }
            column(StartingAccumulated; StartingAccumulated)
            {
            }
            column(DisposalAmounts_2__DisposalAmounts_5__DisposalAmounts_6_; DisposalAmounts[2] + DisposalAmounts[5] + DisposalAmounts[6])
            {
            }
            column(ABS_NetChangeAmounts_2__; Abs(NetChangeAmounts[2]))
            {
            }
            column(BasicDepreciationPerc; BasicDepreciationPerc)
            {
            }
            column(AntAccDepreciationPerc; AntAccDepreciationPerc)
            {
            }
            column(ABS_AntAccDepreciation_; Abs(AntAccDepreciation))
            {
            }
            column(BasicDepreciationPerc_AntAccDepreciationPerc; BasicDepreciationPerc + AntAccDepreciationPerc)
            {
            }
            column(ABS_NetChangeAmounts_2____AntAccDepreciation_; Abs(NetChangeAmounts[2] + AntAccDepreciation))
            {
            }
            column(ABS_TotalEndingAmounts_2__TotalEndingAmounts_5__TotalEndingAmounts_6__; Abs(TotalEndingAmounts[2] + TotalEndingAmounts[5] + TotalEndingAmounts[6]))
            {
            }
            column(ABS_ReclassDeprAmount_; Abs(ReclassDeprAmount))
            {
            }
            column(TotalInventoryYear_1_; TotalInventoryYear[1])
            {
            }
            column(TotalInventoryYear_2_; TotalInventoryYear[2])
            {
            }
            column(TotalInventoryYear_3_; TotalInventoryYear[3])
            {
            }
            column(TotalInventoryYear_4_; TotalInventoryYear[4])
            {
            }
            column(TotalInventoryYear_5_; TotalInventoryYear[5])
            {
            }
            column(TotalInventoryYear_6_; TotalInventoryYear[6])
            {
            }
            column(ABS_TotalInventoryYear_8__; Abs(TotalInventoryYear[8]))
            {
            }
            column(ABS_TotalInventoryYear_10__; Abs(TotalInventoryYear[10]))
            {
            }
            column(ABS_TotalInventoryYear_12__; Abs(TotalInventoryYear[12]))
            {
            }
            column(ABS_TotalInventoryYear_13__; Abs(TotalInventoryYear[13]))
            {
                AutoFormatType = 1;
            }
            column(TotalInventoryYear_14_; TotalInventoryYear[14])
            {
            }
            column(Text1130034___FORMAT__Acquisition_Year__; Text1130034 + Format("Acquisition Year"))
            {
            }
            column(ABS_ReclassDeprAmount__Control1130210; Abs(ReclassDeprAmount))
            {
            }
            column(TotalSubclass_1_; TotalSubclass[1])
            {
            }
            column(TotalSubclass_2_; TotalSubclass[2])
            {
            }
            column(TotalSubclass_3_; TotalSubclass[3])
            {
            }
            column(TotalSubclass_4_; TotalSubclass[4])
            {
            }
            column(TotalSubclass_5_; TotalSubclass[5])
            {
            }
            column(TotalSubclass_6_; TotalSubclass[6])
            {
            }
            column(ABS_TotalSubclass_8__; Abs(TotalSubclass[8]))
            {
            }
            column(ABS_TotalSubclass_10__; Abs(TotalSubclass[10]))
            {
            }
            column(ABS_TotalSubclass_12__; Abs(TotalSubclass[12]))
            {
            }
            column(ABS_TotalSubclass_13__; Abs(TotalSubclass[13]))
            {
                AutoFormatType = 1;
            }
            column(TotalSubclass_14_; TotalSubclass[14])
            {
            }
            column(Text1130033___FORMAT__FA_Subclass_Code__; Text1130033 + Format("FA Subclass Code"))
            {
            }
            column(ABS_ReclassDeprAmount__Control1130211; Abs(ReclassDeprAmount))
            {
            }
            column(TotalClass_1_; TotalClass[1])
            {
            }
            column(TotalClass_2_; TotalClass[2])
            {
            }
            column(TotalClass_3_; TotalClass[3])
            {
            }
            column(TotalClass_4_; TotalClass[4])
            {
            }
            column(TotalClass_5_; TotalClass[5])
            {
            }
            column(TotalClass_6_; TotalClass[6])
            {
            }
            column(ABS_TotalClass_8__; Abs(TotalClass[8]))
            {
            }
            column(ABS_TotalClass_10__; Abs(TotalClass[10]))
            {
            }
            column(ABS_TotalClass_12__; Abs(TotalClass[12]))
            {
            }
            column(ABS_TotalClass_13__; Abs(TotalClass[13]))
            {
                AutoFormatType = 1;
            }
            column(TotalClass_14_; TotalClass[14])
            {
            }
            column(Text1130033___FORMAT__FA_Class_Code__; Text1130033 + Format("FA Class Code"))
            {
            }
            column(ABS_ReclassDeprAmount__Control1130212; Abs(ReclassDeprAmount))
            {
            }
            column(BookValueAtEndingDate_Control169; EndTotalBookValueAtEndingDate)
            {
                AutoFormatType = 1;
            }
            column(TotalStartAmounts_1__TotalStartAmounts_3__TotalStartAmounts_4_; TotalStartAmounts[1] + TotalStartAmounts[3] + TotalStartAmounts[4] + TotalReclassAmount[1])
            {
            }
            column(TotalNetChangeAmounts_1__TotalNetChangeAmounts_3__TotalNetChangeAmounts_4_; TotalNetChangeAmounts[1] + TotalNetChangeAmounts[3] + TotalNetChangeAmounts[4] + TotalReclassAmount[2])
            {
            }
            column(TotalDisposalAmounts_1__TotalDisposalAmounts_3__TotalDisposalAmounts_4_; TotalDisposalAmounts[1] + TotalDisposalAmounts[3] + TotalDisposalAmounts[4] + TotalReclassAmount[3])
            {
            }
            column(TotalEndingAmounts_1__TotalEndingAmounts_3__TotalEndingAmounts_4__Control1130078; EndTotalEndingAmounts[1] + EndTotalEndingAmounts[3] + EndTotalEndingAmounts[4])
            {
            }
            column(TotalStartingAccumulated; TotalStartingAccumulated)
            {
            }
            column(ABS_TotalNetChangeAmounts_2__; Abs(TotalNetChangeAmounts[2]))
            {
            }
            column(ABS_TotalEndingAmounts_2__TotalEndingAmounts_5__TotalEndingAmounts_6___Control1130083; Abs(EndTotalEndingAmounts[2] + EndTotalEndingAmounts[5] + EndTotalEndingAmounts[6]))
            {
            }
            column(ABS_TotalNetChangeAmounts_2__TotalAntAccDepreciation_; Abs(TotalNetChangeAmounts[2] + TotalAntAccDepreciation))
            {
            }
            column(ABS_TotalAntAccDepreciation_; Abs(TotalAntAccDepreciation))
            {
            }
            column(TotalDisposalAmounts_2__TotalDisposalAmounts_5__TotalDisposalAmounts_6_; TotalDisposalAmounts[2] + TotalDisposalAmounts[5] + TotalDisposalAmounts[6])
            {
            }
            column(ABS_TotalReclassDeprAmount__Control1130213; Abs(TotalReclassDeprAmount))
            {
            }
            column(Fixed_Asset_No_; "No.")
            {
            }
            column(Fixed_Asset_FA_Location_Code; "FA Location Code")
            {
            }
            column(Fixed_Asset_Component_of_Main_Asset; "Component of Main Asset")
            {
            }
            column(Fixed_Asset_Global_Dimension_1_Code; "Global Dimension 1 Code")
            {
            }
            column(Fixed_Asset_Global_Dimension_2_Code; "Global Dimension 2 Code")
            {
            }
            column(Fixed_Asset_FA_Posting_Group; "FA Posting Group")
            {
            }
            column(Depreciation_BookCaption; Depreciation_BookCaptionLbl)
            {
            }
            column(PeriodCaption; PeriodCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Book_ValueCaption; Book_ValueCaptionLbl)
            {
            }
            column(Total_Depreciation_ExpenseCaption; Total_Depreciation_ExpenseCaptionLbl)
            {
            }
            column(Accumulated_Depreciation_atCaption; Accumulated_Depreciation_atCaptionLbl)
            {
            }
            column(Anticipato___Acc__Rid__Depreciation_ExpenseCaption; Anticipato___Acc__Rid__Depreciation_ExpenseCaptionLbl)
            {
            }
            column(Depreciation_ExpenseCaption; Depreciation_ExpenseCaptionLbl)
            {
            }
            column(Disposal_in_PeriodCaption; Disposal_in_PeriodCaptionLbl)
            {
            }
            column(Accumulated_Depreciation_atCaption_Control1130021; Accumulated_Depreciation_atCaption_Control1130021Lbl)
            {
            }
            column(Accumulated_DepreciationCaption; Accumulated_DepreciationCaptionLbl)
            {
            }
            column(Amount_atCaption; Amount_atCaptionLbl)
            {
            }
            column(Hystorical_CostCaption; Hystorical_CostCaptionLbl)
            {
            }
            column(Disposal_in_PeriodCaption_Control1130006; Disposal_in_PeriodCaption_Control1130006Lbl)
            {
            }
            column(Addition_in_PeriodCaption; Addition_in_PeriodCaptionLbl)
            {
            }
            column(Amount_atCaption_Control1130007; Amount_atCaption_Control1130007Lbl)
            {
            }
            column(Reclass__Depre__ciationCaption; Reclass__Depre__ciationCaptionLbl)
            {
            }
            column(DescriptionCaption; DescriptionCaptionLbl)
            {
            }
            column(DescriptionCaption_Control1130126; DescriptionCaption_Control1130126Lbl)
            {
            }
            column(Inventory_YearCaption; Inventory_YearCaptionLbl)
            {
            }
            column(Book_ValueCaption_Control1130044; Book_ValueCaption_Control1130044Lbl)
            {
            }
            column(Total_Depreciation_ExpenseCaption_Control1130046; Total_Depreciation_ExpenseCaption_Control1130046Lbl)
            {
            }
            column(Accumulated_Depreciation_atCaption_Control1130047; Accumulated_Depreciation_atCaption_Control1130047Lbl)
            {
            }
            column(Total_Depreciation__Caption; Total_Depreciation__CaptionLbl)
            {
            }
            column(Anticipato___Acc__Rid__Depreciation_ExpenseCaption_Control1130049; Anticipato___Acc__Rid__Depreciation_ExpenseCaption_Control1130049Lbl)
            {
            }
            column(Anticipato___Acc__Rid__Depreciation__Caption; Anticipato___Acc__Rid__Depreciation__CaptionLbl)
            {
            }
            column(Depreciation_ExpenseCaption_Control1130051; Depreciation_ExpenseCaption_Control1130051Lbl)
            {
            }
            column(Depreciation__Caption; Depreciation__CaptionLbl)
            {
            }
            column(Disposal_in_PeriodCaption_Control1130053; Disposal_in_PeriodCaption_Control1130053Lbl)
            {
            }
            column(Accumulated_Depreciation_atCaption_Control1130054; Accumulated_Depreciation_atCaption_Control1130054Lbl)
            {
            }
            column(Accumulated_DepreciationCaption_Control1130056; Accumulated_DepreciationCaption_Control1130056Lbl)
            {
            }
            column(Amount_atCaption_Control1130058; Amount_atCaption_Control1130058Lbl)
            {
            }
            column(Hystorical_CostCaption_Control1130059; Hystorical_CostCaption_Control1130059Lbl)
            {
            }
            column(Disposal_in_PeriodCaption_Control1130060; Disposal_in_PeriodCaption_Control1130060Lbl)
            {
            }
            column(Addition_in_PeriodCaption_Control1130061; Addition_in_PeriodCaption_Control1130061Lbl)
            {
            }
            column(Amount_atCaption_Control1130063; Amount_atCaption_Control1130063Lbl)
            {
            }
            column(Reclass__Depre__ciationCaption_Control1130208; Reclass__Depre__ciationCaption_Control1130208Lbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }
            column(End_TotalCaption; End_TotalCaptionLbl)
            {
            }
            column(ReclassificationCaption; ReclassificationCaptionLbl)
            {
            }
            column(ReclassAmount_1_; ReclassAmount[1])
            {
            }
            column(ReclassAmount_2_; ReclassAmount[2])
            {
            }
            column(ReclassAmount_3_; ReclassAmount[3])
            {
            }
            column(ReclassAmount_4_; ReclassAmount[4])
            {
            }
            column(CompanyDisplayName; CompanyProperty.DisplayName())
            {
            }

            trigger OnAfterGetRecord()
            var
                i: Integer;
            begin
                Clear(ReclassDeprAmount);
                if "Fixed Asset"."Source FA No." = '' then
                    FASource := ''
                else
                    FASource := Text008;
                if not FADeprBook.Get("No.", DeprBookCode) then
                    CurrReport.Skip();
                FixedAsset.Copy("Fixed Asset");
                if SkipRecord() then begin
                    if FixedAsset.Next() = 0 then
                        CreateTotals();
                    CurrReport.Skip();
                end;
                if "FA Posting Group" <> FADeprBook."FA Posting Group" then
                    Error(Text007, FieldCaption("FA Posting Group"), "No.");

                if FASubclass.Get("FA Subclass Code") then
                    FASubclassName := FASubclass.Name
                else
                    FASubclassName := '';

                if FixedAsset2.Get("Source FA No.") then
                    ComingFromDescription := FixedAsset2.Description
                else
                    ComingFromDescription := '';

                if FADeprBook."Depreciation Starting Date" <> 0D then
                    InventoryYear := Date2DMY(FADeprBook."Depreciation Starting Date", 3)
                else
                    InventoryYear := 0;

                CheckPrint("FA Subclass Code", "FA Class Code");

                BeforeAmount := 0;
                EndingAmount := 0;
                CalcAmounts("No.");

                BookValueAtEndingDate := 0;
                BookValueAtStartingDate := 0;
                for i := 1 to NumberOfTypes do begin
                    TotalEndingAmounts[i] := StartAmounts[i] + NetChangeAmounts[i] + DisposalAmounts[i];
                    if i = 2 then
                        TotalEndingAmounts[i] += ReclassDeprAmount;
                    BookValueAtEndingDate := BookValueAtEndingDate + TotalEndingAmounts[i];
                    BookValueAtStartingDate := BookValueAtStartingDate + StartAmounts[i];
                end;
                if GetPeriodDisposal() and (ReclassAmount[5] < 0) then
                    BookValueAtEndingDate := BookValueAtEndingDate + ReclassAmount[4] - ReclassAmount[5]
                else
                    BookValueAtEndingDate := BookValueAtEndingDate + ReclassAmount[4];

                if (PrintDetails and PrintTotalSubclass) or (PrintDetails and PrintTotalInventoryYear) then
                    for k := 1 to 14 do
                        TotalSubclass[k] := 0;

                if PrintDetails and PrintTotalInventoryYear then
                    for k := 1 to 14 do
                        TotalInventoryYear[k] := 0;

                FAsset2.Copy("Fixed Asset");
                FAsset2.Next();
                StartingAccumulated := StartAmounts[2] + StartAmounts[5] + StartAmounts[6];

                CalcDepreciationPercent();
                CalcTotalArray();

                for k := 1 to 14 do
                    TotalInventoryYear[k] += Total[k];
                for k := 1 to 4 do begin
                    TotalInventoryYear[k] += ReclassAmount[k];
                    TotalReclassAmount[k] += ReclassAmount[k];
                end;
                CalcTotals();
                UpdateTotals();
                CreateGroupTotals();
                if FixedAsset.Next() = 0 then
                    CreateTotals();
            end;

            trigger OnPreDataItem()
            begin
                SetCurrentKey("Acquisition Year", "FA Class Code", "FA Subclass Code");
                PrevFASubclassCode := '';
                PrevInventoryYear := 0;
                Printyear := false;
                NextFALedgEntryNo := 1;

                for k := 1 to 14 do begin
                    TotalSubclass[k] := 0;
                    TotalClass[k] := 0;
                    TotalInventoryYear[k] := 0;
                    TotalReclassAmount[k] := 0;
                end;
                Clear(ReclassDeprAmount);
                Type := 1;
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
                        ApplicationArea = Basic, Suite;
                        Caption = 'Depreciation Book';
                        TableRelation = "Depreciation Book";
                        ToolTip = 'Specifies the depreciation book.';
                    }
                    field(StartingDate; StartingDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the start date.';
                    }
                    field(EndingDate; EndingDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Ending Date';
                        ToolTip = 'Specifies the ending date.';
                    }
                    field(PrintPerFixedAsset; PrintDetails)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print per Fixed Asset';
                        ToolTip = 'Specifies if you want to print per fixed asset.';
                    }
                    field(PrintCompanyInfo; PrintCompanyInformation)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print Company Information';
                        MultiLine = true;
                        ToolTip = 'Specifies if you want to print your company information.';
                    }
                    field(Name; CompanyInformation[1])
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Name';
                        ToolTip = 'Specifies the company name.';
                    }
                    field(Address; CompanyInformation[2])
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Address';
                        ToolTip = 'Specifies the company address.';
                    }
                    field(PostCodeCityCounty; CompanyInformation[3])
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Post Code  City  County';
                        ToolTip = 'Specifies the post code, city, and county.';
                    }
                    field(RegisterCompanyNo; CompanyInformation[4])
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Register Company No.';
                        ToolTip = 'Specifies the register company number.';
                    }
                    field(VATRegistrationNo; CompanyInformation[5])
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'VAT Registration No.';
                        ToolTip = 'Specifies the VAT registration number of your company or your tax representative.';
                    }
                    field(FiscalCode; CompanyInformation[6])
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Fiscal Code';
                        ToolTip = 'Specifies the fiscal code.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            if StartingDate = 0D then
                StartingDate := CalcDate('<-CY>', WorkDate());
            if EndingDate = 0D then
                EndingDate := CalcDate('<CY>', WorkDate());
        end;

        trigger OnOpenPage()
        var
            CompanyInfo: Record "Company Information";
            IsCompanyInfoInitialized: Boolean;
        begin
            IsCompanyInfoInitialized := CompanyInformation[1] <> '';
            if IsCompanyInfoInitialized then    // to prevent error when Preview is pressed
                exit;

            if DeprBookCode = '' then begin
                FASetup.Get();
                DeprBookCode := FASetup."Default Depr. Book";
            end;
            PrintDetails := true;

            PrintCompanyInformation := true;
            CompanyInfo.Get();
            CompanyInformation[1] := CompanyInfo.Name;
            CompanyInformation[2] := CompanyInfo.Address;
            CompanyInformation[3] := CompanyInfo."Post Code" + '  ' + CompanyInfo.City + '  ' + CompanyInfo.County;
            CompanyInformation[4] := CompanyInfo."Register Company No.";
            CompanyInformation[6] := CompanyInfo."Fiscal Code";
            CompanyInformation[5] := CompanyInfo."VAT Registration No.";
            CompanyInformation[7] := Depreciation_BookCaptionLbl;
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        FAGenReport.ValidateDates(StartingDate, EndingDate);
        DeprBook.Get(DeprBookCode);
        FAGenReport.SetFAPostingGroup("Fixed Asset", DeprBook.Code);
        FAGenReport.SetAquisitionDate("Fixed Asset", DeprBook.Code);
        FAGenReport.AppendFAPostingFilter("Fixed Asset", StartingDate, EndingDate);
        MainHeadLineText := Text000;
        NumberOfTypes := 6;
        MakeHeadLineText();
        Period1 := Period1::"Before Starting Date";
        Period2 := Period2::"Net Change";
    end;

    var
        Text000: Label 'Fixed Asset - Book Value 02';
        Text004: Label 'Addition in Period';
        Text005: Label 'Disposal in Period';
        Text007: Label '%1 has been modified in fixed asset %2';
        FASetup: Record "FA Setup";
        DeprBook: Record "Depreciation Book";
        FADeprBook: Record "FA Depreciation Book";
        FASubclass: Record "FA Subclass";
        FixedAsset2: Record "Fixed Asset";
        FAsset2: Record "Fixed Asset";
        FixedAsset: Record "Fixed Asset";
        FAGenReport: Codeunit "FA General Report";
        DeprBookCode: Code[10];
        NumberOfTypes: Integer;
        MainHeadLineText: Text[50];
        HeadLineText: array[10] of Text[30];
        StartText: Text[30];
        EndText: Text[30];
        StartAmounts: array[6] of Decimal;
        NetChangeAmounts: array[6] of Decimal;
        DisposalAmounts: array[6] of Decimal;
        GroupStartAmounts: array[6] of Decimal;
        GroupNetChangeAmounts: array[6] of Decimal;
        GroupDisposalAmounts: array[6] of Decimal;
        TotalStartAmounts: array[6] of Decimal;
        TotalNetChangeAmounts: array[6] of Decimal;
        TotalDisposalAmounts: array[6] of Decimal;
        TotalEndingAmounts: array[7] of Decimal;
        BookValueAtStartingDate: Decimal;
        BookValueAtEndingDate: Decimal;
        Type: Integer;
        PostingType: Integer;
        Period1: Option "Before Starting Date","Net Change","at Ending Date";
        Period2: Option "Before Starting Date","Net Change","at Ending Date";
        StartingDate: Date;
        EndingDate: Date;
        PrintDetails: Boolean;
        BeforeAmount: Decimal;
        EndingAmount: Decimal;
        AcquisitionDate: Date;
        DisposalDate: Date;
        StartingAccumulated: Decimal;
        BasicDepreciationPerc: Decimal;
        AntAccDepreciationPerc: Decimal;
        AntAccDepreciation: Decimal;
        TotalStartingAccumulated: Decimal;
        TotalAntAccDepreciation: Decimal;
        FASubclassName: Text[50];
        ComingFromDescription: Text[100];
        InventoryYear: Integer;
        PrevFASubclassCode: Code[10];
        PrevFAclassCode: Code[10];
        PrevInventoryYear: Integer;
        PrintTotalSubclass: Boolean;
        PrintTotalInventoryYear: Boolean;
        Total: array[14] of Decimal;
        TotalSubclass: array[14] of Decimal;
        TotalClass: array[14] of Decimal;
        TotalInventoryYear: array[14] of Decimal;
        k: Integer;
        FASource: Text[30];
        Text008: Label 'Source FA';
        Printyear: Boolean;
        Text1130033: Label 'Total ';
        Text1130034: Label 'Total Year ';
        ReclassDeprAmount: Decimal;
        TotalReclassDeprAmount: Decimal;
        NextFALedgEntryNo: Integer;
        EndTotalEndingAmounts: array[7] of Decimal;
        EndTotalBookValueAtEndingDate: Decimal;
        Depreciation_BookCaptionLbl: Label 'Depreciation Book';
        PeriodCaptionLbl: Label 'Period';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Book_ValueCaptionLbl: Label 'Book Value';
        Total_Depreciation_ExpenseCaptionLbl: Label 'Total Depreciation Expense';
        Accumulated_Depreciation_atCaptionLbl: Label 'Accumulated Depreciation at';
        Anticipato___Acc__Rid__Depreciation_ExpenseCaptionLbl: Label 'Anticipated - Acc./Rid. Depreciation Expense';
        Depreciation_ExpenseCaptionLbl: Label 'Depreciation Expense';
        Disposal_in_PeriodCaptionLbl: Label 'Disposal in Period';
        Accumulated_Depreciation_atCaption_Control1130021Lbl: Label 'Accumulated Depreciation at';
        Accumulated_DepreciationCaptionLbl: Label 'Accumulated Depreciation';
        Amount_atCaptionLbl: Label 'Amount at';
        Hystorical_CostCaptionLbl: Label 'Historical Cost';
        Disposal_in_PeriodCaption_Control1130006Lbl: Label 'Disposal in Period';
        Addition_in_PeriodCaptionLbl: Label 'Addition in Period';
        Amount_atCaption_Control1130007Lbl: Label 'Amount at';
        Reclass__Depre__ciationCaptionLbl: Label 'Reclass.\Depre-\ciation';
        DescriptionCaptionLbl: Label 'Description';
        DescriptionCaption_Control1130126Lbl: Label 'Description';
        Inventory_YearCaptionLbl: Label 'Inventory Year';
        Book_ValueCaption_Control1130044Lbl: Label 'Book Value';
        Total_Depreciation_ExpenseCaption_Control1130046Lbl: Label 'Total Depreciation Expense';
        Accumulated_Depreciation_atCaption_Control1130047Lbl: Label 'Accumulated Depreciation at';
        Total_Depreciation__CaptionLbl: Label 'Total Depreciation %';
        Anticipato___Acc__Rid__Depreciation_ExpenseCaption_Control1130049Lbl: Label 'Anticipated - Acc./Rid. Depreciation Expense';
        Anticipato___Acc__Rid__Depreciation__CaptionLbl: Label 'Anticipated - Acc./Rid. Depreciation %';
        Depreciation_ExpenseCaption_Control1130051Lbl: Label 'Depreciation Expense';
        Depreciation__CaptionLbl: Label 'Depreciation %';
        Disposal_in_PeriodCaption_Control1130053Lbl: Label 'Disposal in Period';
        Accumulated_Depreciation_atCaption_Control1130054Lbl: Label 'Accumulated Depreciation at';
        Accumulated_DepreciationCaption_Control1130056Lbl: Label 'Accumulated Depreciation';
        Amount_atCaption_Control1130058Lbl: Label 'Amount at';
        Hystorical_CostCaption_Control1130059Lbl: Label 'Historical Cost';
        Disposal_in_PeriodCaption_Control1130060Lbl: Label 'Disposal in Period';
        Addition_in_PeriodCaption_Control1130061Lbl: Label 'Addition in Period';
        Amount_atCaption_Control1130063Lbl: Label 'Amount at';
        Reclass__Depre__ciationCaption_Control1130208Lbl: Label 'Reclass.\Depre-\ciation';
        TotalCaptionLbl: Label 'Total';
        End_TotalCaptionLbl: Label 'End Total';
        ReclassificationCaptionLbl: Label 'Reclassification';
        ReclassAmount: array[10] of Decimal;
        TotalReclassAmount: array[14] of Decimal;
        PrintCompanyInformation: Boolean;
        CompanyFieldsNotFilledErr: Label 'All Company Information related fields should be filled in on the request form.';
        RegisterCompanyNoCaptionLbl: Label 'Register Company No.';
        VATRegNoCaptionLbl: Label 'VAT Registration No.';
        FiscalCodeCaptionLbl: Label 'Fiscal Code';
        CompanyInformation: array[7] of Text[100];

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

    local procedure MakeHeadLineText()
    begin
        EndText := StrSubstNo('%1', EndingDate);
        StartText := StrSubstNo('%1', StartingDate);

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

    local procedure UpdateTotals()
    var
        i: Integer;
    begin
        for i := 1 to NumberOfTypes do begin
            GroupStartAmounts[i] := 0;
            GroupNetChangeAmounts[i] := 0;
            GroupDisposalAmounts[i] := 0;
        end;
        for i := 1 to NumberOfTypes do begin
            GroupStartAmounts[i] := GroupStartAmounts[i] + StartAmounts[i];
            GroupNetChangeAmounts[i] := GroupNetChangeAmounts[i] + NetChangeAmounts[i];
            GroupDisposalAmounts[i] := GroupDisposalAmounts[i] + DisposalAmounts[i];
            TotalStartAmounts[i] := TotalStartAmounts[i] + StartAmounts[i];
            TotalNetChangeAmounts[i] := TotalNetChangeAmounts[i] + NetChangeAmounts[i];
            TotalDisposalAmounts[i] := TotalDisposalAmounts[i] + DisposalAmounts[i];
            if i = 2 then
                TotalReclassDeprAmount := TotalReclassDeprAmount + ReclassDeprAmount;
        end;
    end;

    local procedure CreateGroupTotals()
    var
        i: Integer;
    begin
        BookValueAtEndingDate := 0;
        BookValueAtStartingDate := 0;
        for i := 1 to NumberOfTypes do begin
            TotalEndingAmounts[i] := GroupStartAmounts[i] + GroupNetChangeAmounts[i] + GroupDisposalAmounts[i];
            if i = 2 then
                TotalEndingAmounts[i] += ReclassDeprAmount;
            BookValueAtEndingDate := BookValueAtEndingDate + TotalEndingAmounts[i];
            BookValueAtStartingDate := BookValueAtStartingDate + GroupStartAmounts[i];
        end;
        if GetPeriodDisposal() and (ReclassAmount[5] < 0) then
            BookValueAtEndingDate := BookValueAtEndingDate + ReclassAmount[4] - ReclassAmount[5]
        else
            BookValueAtEndingDate := BookValueAtEndingDate + ReclassAmount[4];
    end;

    local procedure CreateTotals()
    var
        i: Integer;
    begin
        for i := 1 to NumberOfTypes do begin
            EndTotalEndingAmounts[i] := TotalStartAmounts[i] + TotalNetChangeAmounts[i] + TotalDisposalAmounts[i];
            if i = 2 then
                EndTotalEndingAmounts[i] := EndTotalEndingAmounts[i] + TotalReclassDeprAmount;
            EndTotalBookValueAtEndingDate := EndTotalBookValueAtEndingDate + EndTotalEndingAmounts[i];
        end;

        TotalStartingAccumulated := TotalStartAmounts[2] + TotalStartAmounts[5] + TotalStartAmounts[6];
        TotalAntAccDepreciation := TotalNetChangeAmounts[5] + TotalNetChangeAmounts[6];
    end;

    local procedure CalcTotals()
    var
        EntryType: Integer;
    begin
        for EntryType := 1 to 14 do begin
            TotalClass[EntryType] := TotalClass[EntryType] + Total[EntryType];
            TotalSubclass[EntryType] := TotalSubclass[EntryType] + Total[EntryType];
            if EntryType in [1 .. 4] then begin
                TotalClass[EntryType] += ReclassAmount[EntryType];
                TotalSubclass[EntryType] += ReclassAmount[EntryType];
            end;
        end;
    end;

    local procedure CalcAmounts(FANo: Code[20])
    var
        StartAmountForDisposal: Decimal;
        NetChangeAmountForDisposal: Decimal;
        i: Integer;
    begin
        Clear(ReclassAmount);
        if IsReclassifiedFA(FANo, DeprBookCode, false) then
            for i := 1 to NumberOfTypes do begin
                StartAmounts[i] := 0;
                NetChangeAmounts[i] := 0;
                DisposalAmounts[i] := 0;
                ReclassDeprAmount := 0;
            end;

        for i := 1 to NumberOfTypes do begin
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
                StartAmountForDisposal := 0;
            end else begin
                StartAmountForDisposal :=
                  FAGenReport.CalcFAPostedAmount(
                    FANo, PostingType, Period1, StartingDate, EndingDate,
                    DeprBookCode, BeforeAmount, EndingAmount, false, true);
                if PostingType = FADeprBook.FieldNo("Acquisition Cost") then
                    StartAmounts[i] :=
                      FAGenReport.CalcFAPostedOriginalAcqCostAmount(
                        FANo, Period1, StartingDate, EndingDate, DeprBookCode)
                else
                    StartAmounts[i] := StartAmountForDisposal;
            end;

            NetChangeAmountForDisposal := 0;
            if not IsReclassifiedFA(FANo, DeprBookCode, false) or (PostingType = FADeprBook.FieldNo(Depreciation)) then
                NetChangeAmountForDisposal :=
                  FAGenReport.CalcFAPostedAmount(
                    FANo, PostingType, Period2, StartingDate, EndingDate,
                    DeprBookCode, BeforeAmount, EndingAmount, false, true);

            if PostingType = FADeprBook.FieldNo("Acquisition Cost") then
                NetChangeAmounts[i] :=
                  FAGenReport.CalcFAPostedOriginalAcqCostAmount(
                    FANo, Period2, StartingDate, EndingDate, DeprBookCode)
            else
                NetChangeAmounts[i] := NetChangeAmountForDisposal;

            if PostingType = FADeprBook.FieldNo(Depreciation) then begin
                ReclassDeprAmount := FAGenReport.CalcFAPostedAmount(FANo, PostingType, Period2, StartingDate, EndingDate,
                    DeprBookCode, BeforeAmount, EndingAmount, true, true);
                NetChangeAmounts[i] -= ReclassDeprAmount;
            end;

            if GetPeriodDisposal() then
                DisposalAmounts[i] := -(StartAmountForDisposal + NetChangeAmountForDisposal)
            else
                DisposalAmounts[i] := 0;
        end;
        if not IsReclassifiedFA(FANo, DeprBookCode, true) then
            CalcReclassAmount(FANo);
    end;

    local procedure IsReclassifiedFA(FANo: Code[20]; DeprBookCode: Code[10]; Reclassification: Boolean): Boolean
    var
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        FALedgerEntry.SetRange("FA Posting Category", FALedgerEntry."FA Posting Category"::" ");
        FALedgerEntry.SetRange("FA No.", FANo);
        FALedgerEntry.SetRange("Depreciation Book Code", DeprBookCode);
        FALedgerEntry.SetRange("Part of Book Value", true);
        FALedgerEntry.SetRange("Reclassification Entry", Reclassification);
        exit(FALedgerEntry.IsEmpty());
    end;

    local procedure CalcReclassAmount(FANo: Code[20])
    begin
        ReclassAmount[1] :=
          FAGenReport.CalcFAPostedAmount(
            FANo, FADeprBook.FieldNo("Acquisition Cost"),
            Period1, StartingDate, EndingDate,
            DeprBookCode, BeforeAmount, EndingAmount, true, true);

        ReclassAmount[2] :=
          FAGenReport.CalcFAPostedAmount(
            FANo, FADeprBook.FieldNo("Acquisition Cost"),
            Period2, StartingDate, EndingDate,
            DeprBookCode, BeforeAmount, EndingAmount, true, true);

        if GetPeriodDisposal() and IsReclassifiedFA(FANo, DeprBookCode, false) then
            ReclassAmount[3] := -(ReclassAmount[1] + ReclassAmount[2])
        else
            ReclassAmount[3] := 0;

        ReclassAmount[4] := ReclassAmount[1] + ReclassAmount[2] + ReclassAmount[3];

        if not IsReclassifiedFA(FANo, DeprBookCode, false) then
            ReclassAmount[5] :=
              FAGenReport.CalcFAPostedAmount(FANo, FADeprBook.FieldNo(Depreciation),
                Period2, StartingDate, EndingDate,
                DeprBookCode, BeforeAmount, EndingAmount, true, true);

        if IsReclassifiedFA(FANo, DeprBookCode, false) then
            ReclassDeprAmount :=
              FAGenReport.CalcFAPostedAmount(FANo, FADeprBook.FieldNo(Depreciation),
                Period2, StartingDate, EndingDate,
                DeprBookCode, BeforeAmount, EndingAmount, true, true);
    end;

    local procedure CheckPrint(FASubclassCode: Code[10]; FAClassCode: Code[10])
    begin
        if PrevFASubclassCode <> FASubclassCode then begin
            PrintTotalSubclass := true;
            PrevFASubclassCode := FASubclassCode;
            Clear(TotalSubclass);
        end else
            PrintTotalSubclass := false;

        if PrevFAclassCode <> FAClassCode then begin
            PrevFAclassCode := FAClassCode;
            Clear(TotalClass);
        end else
            PrintTotalSubclass := false;

        if PrevInventoryYear <> InventoryYear then begin
            PrevInventoryYear := InventoryYear;
            PrintTotalInventoryYear := true;
            Clear(TotalInventoryYear);
            Clear(TotalClass);
            Clear(TotalSubclass);
        end else
            PrintTotalInventoryYear := false;
    end;

    local procedure CalcTotalArray()
    begin
        Total[1] := StartAmounts[1] + StartAmounts[3] + StartAmounts[4];
        Total[2] := NetChangeAmounts[1] + NetChangeAmounts[3] + NetChangeAmounts[4];
        Total[3] := DisposalAmounts[1] + DisposalAmounts[3] + DisposalAmounts[4];
        Total[4] := TotalEndingAmounts[1] + TotalEndingAmounts[3] + TotalEndingAmounts[4];
        Total[5] := StartingAccumulated;
        if IsReclassifiedFA("Fixed Asset"."No.", DeprBookCode, false) then
            Total[6] := DisposalAmounts[2] + DisposalAmounts[5] + DisposalAmounts[6] - ReclassAmount[5]
        else
            Total[6] := DisposalAmounts[2] + DisposalAmounts[5] + DisposalAmounts[6];
        Total[7] := BasicDepreciationPerc;
        Total[8] := NetChangeAmounts[2];
        Total[9] := AntAccDepreciationPerc;
        Total[10] := AntAccDepreciation;
        Total[11] := BasicDepreciationPerc + AntAccDepreciationPerc;
        Total[12] := NetChangeAmounts[2] + AntAccDepreciation;
        if IsReclassifiedFA("Fixed Asset"."No.", DeprBookCode, false) then
            Total[13] := TotalEndingAmounts[2] + TotalEndingAmounts[5] + TotalEndingAmounts[6] - ReclassAmount[5]
        else
            Total[13] := TotalEndingAmounts[2] + TotalEndingAmounts[5] + TotalEndingAmounts[6];
        Total[14] := BookValueAtEndingDate;
    end;

    local procedure CalcDepreciationPercent()
    var
        FAPostingTypeSetup: Record "FA Posting Type Setup";
        TotalEndingAppreciationAmount: Decimal;
        TotalEndingWriteDownAmount: Decimal;
    begin
        TotalEndingAppreciationAmount := TotalEndingAmounts[4];
        if not PartOfDepreciableBasis(DeprBook.Code, FAPostingTypeSetup."FA Posting Type"::Appreciation, true) then
            TotalEndingAppreciationAmount := 0;
        TotalEndingWriteDownAmount := TotalEndingAmounts[3];
        if not PartOfDepreciableBasis(DeprBook.Code, FAPostingTypeSetup."FA Posting Type"::"Write-Down", false) then
            TotalEndingWriteDownAmount := 0;

        AntAccDepreciation := NetChangeAmounts[5] + NetChangeAmounts[6];
        if (TotalEndingAmounts[1] + TotalEndingWriteDownAmount + TotalEndingAppreciationAmount) = 0 then
            if ReclassAmount[4] = 0 then begin
                BasicDepreciationPerc := 0;
                AntAccDepreciationPerc := 0;
            end else
                BasicDepreciationPerc := Abs(Round(((ReclassDeprAmount + TotalEndingAmounts[2]) / ReclassAmount[4]) * 100, 0.01))
        else begin
            if IsReclassifiedFA("Fixed Asset"."No.", DeprBookCode, true) then
                BasicDepreciationPerc :=
                  Abs(Round((NetChangeAmounts[2] + ReclassDeprAmount) /
                      (TotalEndingAmounts[1] + TotalEndingWriteDownAmount + TotalEndingAppreciationAmount) * 100, 0.01))
            else
                BasicDepreciationPerc :=
                  Abs(Round((NetChangeAmounts[2] + ReclassDeprAmount + ReclassAmount[5]) /
                      (TotalEndingAmounts[1] + TotalEndingWriteDownAmount + TotalEndingAppreciationAmount) * 100, 0.01));
            AntAccDepreciationPerc :=
              Abs(Round(AntAccDepreciation /
                  (TotalEndingAmounts[1] + TotalEndingWriteDownAmount + TotalEndingAppreciationAmount) * 100, 0.01));
        end;
    end;

    local procedure PartOfDepreciableBasis(DeprBookCode: Code[10]; FAPostingType: Enum "FA Posting Type Setup Type"; Default: Boolean): Boolean
    var
        FAPostingTypeSetup: Record "FA Posting Type Setup";
    begin
        if FAPostingTypeSetup.Get(DeprBookCode, FAPostingType) then
            exit(FAPostingTypeSetup."Part of Depreciable Basis");
        exit(Default);
    end;
}
