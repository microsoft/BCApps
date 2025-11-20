// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Reports;

using Microsoft.Finance.GeneralLedger.Budget;
using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Ledger;
using Microsoft.FixedAssets.Setup;
using Microsoft.Foundation.Period;
using System.Utilities;

report 5607 "Fixed Asset - Projected Value"
{
    DefaultLayout = RDLC;
    RDLCLayout = './FixedAssets/Reports/FixedAssetProjectedValue.rdlc';
    ApplicationArea = FixedAssets;
    Caption = 'Fixed Asset Projected Value';
    UsageCategory = ReportsAndAnalysis;
    AllowScheduling = false;

    dataset
    {
        dataitem("Fixed Asset"; "Fixed Asset")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "FA Class Code", "FA Subclass Code", "Budgeted Asset";
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(DeprBookText; DeprBookText)
            {
            }
            column(FixedAssetTabcaptFAFilter; TableCaption + ': ' + FAFilter)
            {
            }
            column(FAFilter; FAFilter)
            {
            }
            column(PrintDetails; PrintDetails)
            {
            }
            column(ProjectedDisposal; ProjectedDisposal)
            {
            }
            column(DeprBookUseCustom1Depr; DeprBook."Use Custom 1 Depreciation")
            {
            }
            column(DoProjectedDisposal; DoProjectedDisposal)
            {
            }
            column(GroupTotalsInt; GroupTotalsInt)
            {
            }
            column(IncludePostedFrom; Format(IncludePostedFrom))
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
            column(GroupHeadLine; GroupHeadLine)
            {
            }
            column(FixedAssetNo; "No.")
            {
            }
            column(Description_FixedAsset; Description)
            {
            }
            column(DeprText2; DeprText2)
            {
            }
            column(Text002GroupHeadLine; GroupTotalTxt + ': ' + GroupHeadLine)
            {
            }
            column(Custom1Text; Custom1Text)
            {
            }
            column(DeprCustom1Text; DeprCustom1Text)
            {
            }
            column(SalesPriceFieldname; SalesPriceFieldname)
            {
            }
            column(GainLossFieldname; GainLossFieldname)
            {
            }
            column(GroupAmounts3; GroupAmounts[3])
            {
                AutoFormatType = 1;
            }
            column(GroupAmounts4; GroupAmounts[4])
            {
                AutoFormatType = 1;
            }
            column(FAClassCode_FixedAsset; "FA Class Code")
            {
            }
            column(FASubclassCode_FixedAsset; "FA Subclass Code")
            {
            }
            column(GlobalDim1Code_FixedAsset; "Global Dimension 1 Code")
            {
            }
            column(GlobalDim2Code_FixedAsset; "Global Dimension 2 Code")
            {
            }
            column(FALocationCode_FixedAsset; "FA Location Code")
            {
            }
            column(CompofMainAss_FixedAsset; "Component of Main Asset")
            {
            }
            column(FAPostingGroup_FixedAsset; "FA Posting Group")
            {
            }
            column(CurrReportPAGENOCaption; PageNoLbl)
            {
            }
            column(FixedAssetProjectedValueCaption; FAProjectedValueLbl)
            {
            }
            column(FALedgerEntryFAPostingDateCaption; FAPostingDateLbl)
            {
            }
            column(BookValueCaption; BookValueLbl)
            {
            }
            dataitem("FA Ledger Entry"; "FA Ledger Entry")
            {
                DataItemTableView = sorting("FA No.", "Depreciation Book Code", "FA Posting Date");
                column(FAPostingDt_FALedgerEntry; Format("FA Posting Date"))
                {
                }
                column(PostingDt_FALedgerEntry; "FA Posting Type")
                {
                    IncludeCaption = true;
                }
                column(Amount_FALedgerEntry; Amount)
                {
                    IncludeCaption = true;
                }
                column(FANo_FALedgerEntry; "FA No.")
                {
                }
                column(BookValue; BookValue)
                {
                    AutoFormatType = 1;
                }
                column(NoofDeprDays_FALedgEntry; "No. of Depreciation Days")
                {
                    IncludeCaption = true;
                }
                column(FALedgerEntryEntryNo; "Entry No.")
                {
                }
                column(PostedEntryCaption; PostedEntryLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if "Part of Book Value" then
                        BookValue := BookValue + Amount;
                    if "FA Posting Date" < IncludePostedFrom then
                        CurrReport.Skip();
                    EntryPrinted := true;
                end;

                trigger OnPreDataItem()
                begin
                    SetRange("FA No.", "Fixed Asset"."No.");
                    SetRange("Depreciation Book Code", DeprBookCode);
                    BookValue := 0;
                    if (IncludePostedFrom = 0D) or not PrintDetails then
                        CurrReport.Break();
                end;
            }
            dataitem(ProjectedDepreciation; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = filter(1 .. 1000000));
                column(DeprAmount; DeprAmount)
                {
                    AutoFormatType = 1;
                }
                column(EntryAmt1Custom1Amt; EntryAmounts[1] - Custom1Amount)
                {
                    AutoFormatType = 1;
                }
                column(FormatUntilDate; Format(UntilDate))
                {
                }
                column(DeprText; DeprText)
                {
                }
                column(NumberOfDays; NumberOfDays)
                {
                }
                column(No1_FixedAsset; "Fixed Asset"."No.")
                {
                }
                column(Custom1Text_ProjectedDepr; Custom1Text)
                {
                }
                column(Custom1NumberOfDays; Custom1NumberOfDays)
                {
                }
                column(Custom1Amount; Custom1Amount)
                {
                    AutoFormatType = 1;
                }
                column(EntryAmounts1; EntryAmounts[1])
                {
                    AutoFormatType = 1;
                }
                column(AssetAmounts1; AssetAmounts[1])
                {
                    AutoFormatType = 1;
                }
                column(Description1_FixedAsset; "Fixed Asset".Description)
                {
                }
                column(AssetAmounts2; AssetAmounts[2])
                {
                    AutoFormatType = 1;
                }
                column(AssetAmt1AssetAmt2; AssetAmounts[1] + AssetAmounts[2])
                {
                    AutoFormatType = 1;
                }
                column(DeprCustom1Text_ProjectedDepr; DeprCustom1Text)
                {
                }
                column(AssetAmounts3; AssetAmounts[3])
                {
                    AutoFormatType = 1;
                }
                column(AssetAmounts4; AssetAmounts[4])
                {
                    AutoFormatType = 1;
                }
                column(SalesPriceFieldname_ProjectedDepr; SalesPriceFieldname)
                {
                }
                column(GainLossFieldname_ProjectedDepr; GainLossFieldname)
                {
                }
                column(GroupAmounts_1; GroupAmounts[1])
                {
                }
                column(GroupTotalBookValue; GroupTotalBookValue)
                {
                }
                column(TotalBookValue_1; TotalBookValue[1])
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if UntilDate >= EndingDate then
                        CurrReport.Break();
                    if Number = 1 then begin
                        CalculateFirstDeprAmount(Done);
                        if FADeprBook."Book Value" <> 0 then
                            Done := Done or not EntryPrinted;
                    end else
                        CalculateSecondDeprAmount(Done);
                    if Done then
                        UpdateTotals()
                    else
                        UpdateGroupTotals();

                    if Done then
                        if DoProjectedDisposal then
                            CalculateGainLoss();
                end;

                trigger OnPostDataItem()
                begin
                    if DoProjectedDisposal then begin
                        TotalAmounts[3] += AssetAmounts[3];
                        TotalAmounts[4] += AssetAmounts[4];
                    end;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                case GroupTotals of
                    GroupTotals::"FA Class":
                        NewValue := "FA Class Code";
                    GroupTotals::"FA Subclass":
                        NewValue := "FA Subclass Code";
                    GroupTotals::"FA Location":
                        NewValue := "FA Location Code";
                    GroupTotals::"Main Asset":
                        NewValue := "Component of Main Asset";
                    GroupTotals::"Global Dimension 1":
                        NewValue := "Global Dimension 1 Code";
                    GroupTotals::"Global Dimension 2":
                        NewValue := "Global Dimension 2 Code";
                    GroupTotals::"FA Posting Group":
                        NewValue := "FA Posting Group";
                end;

                if NewValue <> OldValue then begin
                    MakeGroupHeadLine();
                    InitGroupTotals();
                    OldValue := NewValue;
                end;

                if not FADeprBook.Get("No.", DeprBookCode) then
                    CurrReport.Skip();
                if SkipRecord() then
                    CurrReport.Skip();

                if GroupTotals = GroupTotals::"FA Posting Group" then
                    if "FA Posting Group" <> FADeprBook."FA Posting Group" then
                        Error(HasBeenModifiedInFAErr, FieldCaption("FA Posting Group"), "No.");

                StartingDate := StartingDate2;
                EndingDate := EndingDate2;
                DoProjectedDisposal := false;
                EntryPrinted := false;
                if ProjectedDisposal and
                   (FADeprBook."Projected Disposal Date" > 0D) and
                   (FADeprBook."Projected Disposal Date" <= EndingDate)
                then begin
                    EndingDate := FADeprBook."Projected Disposal Date";
                    if StartingDate > EndingDate then
                        StartingDate := EndingDate;
                    DoProjectedDisposal := true;
                end;

                TransferValues();
                OnAfterTransferValues(GroupAmounts, TotalBookValue);
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

                GroupTotalsInt := GroupTotals;
                MakeGroupHeadLine();
                InitGroupTotals();
            end;
        }
        dataitem(ProjectionTotal; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = const(1));
            column(TotalBookValue2; TotalBookValue[2])
            {
                AutoFormatType = 1;
            }
            column(TotalAmounts1; TotalAmounts[1])
            {
                AutoFormatType = 1;
            }
            column(DeprText2_ProjectionTotal; DeprText2)
            {
            }
            column(ProjectedDisposal_ProjectionTotal; ProjectedDisposal)
            {
            }
            column(DeprBookUseCustDepr_ProjectionTotal; DeprBook."Use Custom 1 Depreciation")
            {
            }
            column(Custom1Text_ProjectionTotal; Custom1Text)
            {
            }
            column(TotalAmounts2; TotalAmounts[2])
            {
                AutoFormatType = 1;
            }
            column(DeprCustom1Text_ProjectionTotal; DeprCustom1Text)
            {
            }
            column(TotalAmt1TotalAmt2; TotalAmounts[1] + TotalAmounts[2])
            {
                AutoFormatType = 1;
            }
            column(SalesPriceFieldname_ProjectionTotal; SalesPriceFieldname)
            {
            }
            column(GainLossFieldname_ProjectionTotal; GainLossFieldname)
            {
            }
            column(TotalAmounts3; TotalAmounts[3])
            {
                AutoFormatType = 1;
            }
            column(TotalAmounts4; TotalAmounts[4])
            {
                AutoFormatType = 1;
            }
            column(TotalCaption; TotalLbl)
            {
            }
        }
        dataitem(Buffer; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = filter(1 ..));
            column(DeprBookText_Buffer; DeprBookText)
            {
            }
            column(Custom1TextText_Buffer; Custom1Text)
            {
            }
            column(GroupCodeName2; GroupCodeName2)
            {
            }
            column(FAPostingDate_FABufferProjection; Format(TempFABufferProjection."FA Posting Date"))
            {
            }
            column(Desc_FABufferProjection; TempFABufferProjection.Depreciation)
            {
            }
            column(Cust1_FABufferProjection; TempFABufferProjection."Custom 1")
            {
            }
            column(CodeName_FABufferProj; TempFABufferProjection."Code Name")
            {
            }
            column(ProjectedAmountsperDateCaption; ProjectedAmountsPerDateLbl)
            {
            }
            column(FABufferProjectionFAPostingDateCaption; FABufferProjectionFAPostingDateLbl)
            {
            }
            column(FABufferProjectionDepreciationCaption; FABufferProjectionDepreciationLbl)
            {
            }
            column(FixedAssetProjectedValueCaption_Buffer; FABufferProjectedValueLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                if Number = 1 then begin
                    if not TempFABufferProjection.Find('-') then
                        CurrReport.Break();
                end else
                    if TempFABufferProjection.Next() = 0 then
                        CurrReport.Break();
            end;

            trigger OnPreDataItem()
            begin
                if not PrintAmountsPerDate then
                    CurrReport.Break();
                TempFABufferProjection.Reset();
            end;
        }
    }

    requestpage
    {
        SaveValues = true;
        AboutTitle = 'About Fixed Asset Projected Value';
        AboutText = '**Fixed Asset Projected Value** Report is a detailed analysis that forecasts the future value of an organization''s fixed assets over a specified period. This is specially useful where there are multiple depreciation methods and there is need to review the projected values of depreciation.';

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
                        AboutText = 'Choose the Depreciation Book and specify the First Depreciation Date, Last Depreciation Date for which details are to be seen and group the total with applicable option.';
                        ToolTip = 'Specifies the code for the depreciation book to be included in the report or batch job.';

                        trigger OnValidate()
                        begin
                            UpdateReqForm();
                        end;
                    }
                    field(FirstDeprDate; StartingDate)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'First Depreciation Date';
                        ToolTip = 'Specifies the date to be used as the first date in the period for which you want to calculate projected depreciation.';
                    }
                    field(LastDeprDate; EndingDate)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Last Depreciation Date';
                        ToolTip = 'Specifies the Fixed Asset posting date of the last posted depreciation.';
                    }
                    field(NumberOfDays; PeriodLength)
                    {
                        ApplicationArea = FixedAssets;
                        BlankZero = true;
                        Caption = 'Number of Days';
                        Editable = NumberOfDaysCtrlEditable;
                        MinValue = 0;
                        ToolTip = 'Specifies the length of the periods between the first depreciation date and the last depreciation date. The program then calculates depreciation for each period. If you leave this field blank, the program automatically sets the contents of this field to equal the number of days in a fiscal year, normally 360.';

                        trigger OnValidate()
                        begin
                            if PeriodLength > 0 then
                                UseAccountingPeriod := false;
                        end;
                    }
                    field(DaysInFirstPeriod; DaysInFirstPeriod)
                    {
                        ApplicationArea = FixedAssets;
                        BlankZero = true;
                        Caption = 'No. of Days in First Period';
                        MinValue = 0;
                        ToolTip = 'Specifies the number of days that must be used for calculating the depreciation as of the first depreciation date, regardless of the actual number of days from the last depreciation entry. The number you enter in this field does not affect the total number of days from the starting date to the ending date.';
                    }
                    field(IncludePostedFrom; IncludePostedFrom)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Posted Entries From';
                        ToolTip = 'Specifies the fixed asset posting date from which the report includes all types of posted entries.';
                    }
                    field(GroupTotals; GroupTotals)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Group Totals';
                        OptionCaption = ' ,FA Class,FA Subclass,FA Location,Main Asset,Global Dimension 1,Global Dimension 2,FA Posting Group';
                        ToolTip = 'Specifies if you want the report to group fixed assets and print totals using the category defined in this field. For example, maintenance expenses for fixed assets can be shown for each fixed asset class.';
                    }
                    field(CopyToGLBudgetName; BudgetNameCode)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Copy to G/L Budget Name';
                        TableRelation = "G/L Budget Name";
                        ToolTip = 'Specifies the name of the budget you want to copy projected values to.';

                        trigger OnValidate()
                        begin
                            if BudgetNameCode = '' then
                                BalAccount := false;
                        end;
                    }
                    field(InsertBalAccount; BalAccount)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Insert Bal. Account';
                        AboutTitle = 'Insert Balancing Account';
                        AboutText = 'Enable the applicable options to view the report details as required.';
                        ToolTip = 'Specifies if you want the batch job to automatically insert fixed asset entries with balancing accounts.';

                        trigger OnValidate()
                        begin
                            if BalAccount then
                                if BudgetNameCode = '' then
                                    Error(YouMustSpecifyErr, GLBudgetName.TableCaption());
                        end;
                    }
                    field(PrintPerFixedAsset; PrintDetails)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Print per Fixed Asset';
                        ToolTip = 'Specifies if you want the report to print information separately for each fixed asset.';
                    }
                    field(ProjectedDisposal; ProjectedDisposal)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Projected Disposal';
                        ToolTip = 'Specifies if you want the report to include projected disposals: the contents of the Projected Proceeds on Disposal field and the Projected Disposal Date field on the FA depreciation book.';
                    }
                    field(PrintAmountsPerDate; PrintAmountsPerDate)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Print Amounts per Date';
                        ToolTip = 'Specifies if you want the program to include on the last page of the report a summary of the calculated depreciation for all assets.';
                    }
                    field(UseAccountingPeriod; UseAccountingPeriod)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Use Accounting Period';
                        ToolTip = 'Specifies if you want the periods between the starting date and the ending date to correspond to the accounting periods you have specified in the Accounting Period table. When you select this field, the Number of Days field is cleared.';

                        trigger OnValidate()
                        begin
                            if UseAccountingPeriod then
                                PeriodLength := 0;

                            UpdateReqForm();
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
            NumberOfDaysCtrlEditable := true;
        end;

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
        Year365Days := DeprBook."Fiscal Year 365 Days";
        if GroupTotals = GroupTotals::"FA Posting Group" then
            FAGenReport.SetFAPostingGroup("Fixed Asset", DeprBook.Code);
        FAGenReport.AppendFAPostingFilter("Fixed Asset", StartingDate, EndingDate);
        FAFilter := "Fixed Asset".GetFilters();
        DeprBookText := StrSubstNo('%1%2 %3', DeprBook.TableCaption(), ':', DeprBookCode);
        MakeGroupTotalText();
        ValidateDates();
        if PrintDetails then begin
            FANo := "Fixed Asset".FieldCaption("No.");
            FADescription := "Fixed Asset".FieldCaption(Description);
        end;
        if DeprBook."No. of Days in Fiscal Year" > 0 then
            DaysInFiscalYear := DeprBook."No. of Days in Fiscal Year"
        else
            DaysInFiscalYear := 360;
        if Year365Days then
            DaysInFiscalYear := 365;
        if PeriodLength = 0 then
            PeriodLength := DaysInFiscalYear;
        if (PeriodLength <= 5) or (PeriodLength > DaysInFiscalYear) then
            Error(NumberOfDaysMustNotBeGreaterThanErr, DaysInFiscalYear);
        FALedgEntry2."FA Posting Type" := FALedgEntry2."FA Posting Type"::Depreciation;
        DeprText := StrSubstNo('%1', FALedgEntry2."FA Posting Type");
        if DeprBook."Use Custom 1 Depreciation" then begin
            DeprText2 := DeprText;
            FALedgEntry2."FA Posting Type" := FALedgEntry2."FA Posting Type"::"Custom 1";
            Custom1Text := StrSubstNo('%1', FALedgEntry2."FA Posting Type");
            DeprCustom1Text := StrSubstNo('%1 %2 %3', DeprText, '+', Custom1Text);
        end;
        SalesPriceFieldname := FADeprBook.FieldCaption("Projected Proceeds on Disposal");
        GainLossFieldname := ProjectedGainLossTxt;
    end;

    var
        GLBudgetName: Record "G/L Budget Name";
        FASetup: Record "FA Setup";
        DeprBook: Record "Depreciation Book";
        FADeprBook: Record "FA Depreciation Book";
        FA: Record "Fixed Asset";
        FALedgEntry2: Record "FA Ledger Entry";
        TempFABufferProjection: Record "FA Buffer Projection" temporary;
        FAGenReport: Codeunit "FA General Report";
        CalculateDepr: Codeunit "Calculate Depreciation";
        FADateCalculation: Codeunit "FA Date Calculation";
        DepreciationCalculation: Codeunit "Depreciation Calculation";
        FAFilter: Text;
        DeprBookText: Text[50];
        GroupCodeName: Text[50];
        GroupCodeName2: Text[50];
        GroupHeadLine: Text[50];
        DeprText: Text[50];
        DeprText2: Text[50];
        Custom1Text: Text[50];
        DeprCustom1Text: Text[50];
        IncludePostedFrom: Date;
        FANo: Text[50];
        FADescription: Text[100];
        GroupTotals: Option " ","FA Class","FA Subclass","FA Location","Main Asset","Global Dimension 1","Global Dimension 2","FA Posting Group";
        BookValue: Decimal;
        NewFiscalYear: Date;
        EndFiscalYear: Date;
        DaysInFiscalYear: Integer;
        Custom1DeprUntil: Date;
        PeriodLength: Integer;
        UseAccountingPeriod: Boolean;
        StartingDate2: Date;
        EndingDate2: Date;
        PrintAmountsPerDate: Boolean;
        UntilDate: Date;
        PrintDetails: Boolean;
        EntryAmounts: array[4] of Decimal;
        AssetAmounts: array[4] of Decimal;
        GroupAmounts: array[4] of Decimal;
        TotalAmounts: array[4] of Decimal;
        TotalBookValue: array[2] of Decimal;
        GroupTotalBookValue: Decimal;
        DateFromProjection: Date;
        DeprAmount: Decimal;
        Custom1Amount: Decimal;
        NumberOfDays: Integer;
        Custom1NumberOfDays: Integer;
        DaysInFirstPeriod: Integer;
        Done: Boolean;
        NotFirstGroupTotal: Boolean;
        SalesPriceFieldname: Text[80];
        GainLossFieldname: Text[50];
        ProjectedDisposal: Boolean;
        DoProjectedDisposal: Boolean;
        EntryPrinted: Boolean;
        GroupCodeNameTxt: Label ' ,FA Class,FA Subclass,FA Location,Main Asset,Global Dimension 1,Global Dimension 2,FA Posting Group';
        BudgetNameCode: Code[10];
        OldValue: Code[20];
        NewValue: Code[20];
        BalAccount: Boolean;
        TempDeprDate: Date;
        GroupTotalsInt: Integer;
        Year365Days: Boolean;
        NumberOfDaysCtrlEditable: Boolean;

#pragma warning disable AA0470
        NumberOfDaysMustNotBeGreaterThanErr: Label 'Number of Days must not be greater than %1 or less than 5.', Comment = '1 - Number of days in fiscal year';
#pragma warning restore AA0470
        ProjectedGainLossTxt: Label 'Projected Gain/Loss';
        GroupTotalTxt: Label 'Group Total';
        GroupTotalsTxt: Label 'Group Totals';
#pragma warning disable AA0470
        HasBeenModifiedInFAErr: Label '%1 has been modified in fixed asset %2.', Comment = '1 - FA Posting Group caption; 2- FA No.';
        YouMustSpecifyErr: Label 'You must specify %1.', Comment = '1 - G/L Budget Name caption';
        YouMustCreateAccPeriodsErr: Label 'You must create accounting periods until %1 to use 365 days depreciation and ''Use Accounting Periods''.', Comment = '1 - Date';
#pragma warning restore AA0470
        PageNoLbl: Label 'Page';
        FAProjectedValueLbl: Label 'Fixed Asset - Projected Value';
        FAPostingDateLbl: Label 'FA Posting Date';
        BookValueLbl: Label 'Book Value';
        PostedEntryLbl: Label 'Posted Entry';
        TotalLbl: Label 'Total';
        ProjectedAmountsPerDateLbl: Label 'Projected Amounts per Date';
        FABufferProjectionFAPostingDateLbl: Label 'FA Posting Date';
        FABufferProjectionDepreciationLbl: Label 'Depreciation';
        FABufferProjectedValueLbl: Label 'Fixed Asset - Projected Value';

    protected var
        DeprBookCode: Code[10];
        StartingDate: Date;
        EndingDate: Date;

    local procedure SkipRecord(): Boolean
    begin
        exit(
          "Fixed Asset".Inactive or
          (FADeprBook."Acquisition Date" = 0D) or
          (FADeprBook."Acquisition Date" > EndingDate) or
          (FADeprBook."Last Depreciation Date" > EndingDate) or
          (FADeprBook."Disposal Date" > 0D));
    end;

    local procedure TransferValues()
    begin
        FADeprBook.CalcFields("Book Value", "Custom 1");
        DateFromProjection := 0D;
        EntryAmounts[1] := FADeprBook."Book Value";
        EntryAmounts[2] := FADeprBook."Custom 1";
        EntryAmounts[3] := DepreciationCalculation.DeprInFiscalYear("Fixed Asset"."No.", DeprBookCode, StartingDate);
        TotalBookValue[1] := TotalBookValue[1] + FADeprBook."Book Value";
        TotalBookValue[2] := TotalBookValue[2] + FADeprBook."Book Value";
        GroupTotalBookValue += FADeprBook."Book Value";
        NewFiscalYear := FADateCalculation.GetFiscalYear(DeprBookCode, StartingDate);
        EndFiscalYear := FADateCalculation.CalculateDate(
            DepreciationCalculation.Yesterday(NewFiscalYear, Year365Days, DeprBook."Use Accounting Period"),
            DaysInFiscalYear, Year365Days);
        TempDeprDate := FADeprBook."Temp. Ending Date";

        if DeprBook."Use Custom 1 Depreciation" then
            Custom1DeprUntil := FADeprBook."Depr. Ending Date (Custom 1)"
        else
            Custom1DeprUntil := 0D;

        if Custom1DeprUntil > 0D then
            EntryAmounts[4] := GetDeprBasis();
        UntilDate := 0D;
        AssetAmounts[1] := 0;
        AssetAmounts[2] := 0;
        AssetAmounts[3] := 0;
        AssetAmounts[4] := 0;
    end;

    local procedure CalculateFirstDeprAmount(var Done: Boolean)
    var
        FirstTime: Boolean;
        IsHandled: Boolean;
    begin
        FirstTime := true;
        UntilDate := StartingDate;
        IsHandled := false;
        OnBeforeCalculateFirstDeprAmount("Fixed Asset", CalculateDepr, DepreciationCalculation, FirstTime, Done, UntilDate, StartingDate, DeprAmount, Custom1Amount, NumberOfDays, Custom1NumberOfDays, DeprBookCode, EntryAmounts, DaysInFirstPeriod, EndingDate, IsHandled);
        if IsHandled then
            exit;
        repeat
            if not FirstTime then
                GetNextDate();
            FirstTime := false;
            CalculateDepr.Calculate(
              DeprAmount, Custom1Amount, NumberOfDays, Custom1NumberOfDays,
              "Fixed Asset"."No.", DeprBookCode, UntilDate, EntryAmounts, 0D, DaysInFirstPeriod);
            Done := (DeprAmount <> 0) or (Custom1Amount <> 0);
        until (UntilDate >= EndingDate) or Done;
        EntryAmounts[3] :=
          DepreciationCalculation.DeprInFiscalYear("Fixed Asset"."No.", DeprBookCode, UntilDate);
    end;

    local procedure CalculateSecondDeprAmount(var Done: Boolean)
    begin
        GetNextDate();
        CalculateDepr.Calculate(
          DeprAmount, Custom1Amount, NumberOfDays, Custom1NumberOfDays,
          "Fixed Asset"."No.", DeprBookCode, UntilDate, EntryAmounts, DateFromProjection, 0);
        Done := CalculationDone(
            (DeprAmount <> 0) or (Custom1Amount <> 0), DateFromProjection);
    end;

    local procedure GetNextDate()
    var
        UntilDate2: Date;
    begin
        UntilDate2 := GetPeriodEndingDate(UseAccountingPeriod, UntilDate, PeriodLength);
        if Custom1DeprUntil > 0D then
            if (UntilDate < Custom1DeprUntil) and (UntilDate2 > Custom1DeprUntil) then
                UntilDate2 := Custom1DeprUntil;

        if TempDeprDate > 0D then
            if (UntilDate < TempDeprDate) and (UntilDate2 > TempDeprDate) then
                UntilDate2 := TempDeprDate;

        if (UntilDate < EndFiscalYear) and (UntilDate2 > EndFiscalYear) then
            UntilDate2 := EndFiscalYear;

        if UntilDate = EndFiscalYear then begin
            EntryAmounts[3] := 0;
            NewFiscalYear := DepreciationCalculation.ToMorrow(EndFiscalYear, Year365Days, DeprBook."Use Accounting Period");
            EndFiscalYear := FADateCalculation.CalculateDate(EndFiscalYear, DaysInFiscalYear, Year365Days);
        end;

        DateFromProjection := DepreciationCalculation.ToMorrow(UntilDate, Year365Days, DeprBook."Use Accounting Period");
        UntilDate := UntilDate2;
        if UntilDate >= EndingDate then
            UntilDate := EndingDate;
    end;

    local procedure GetPeriodEndingDate(UseAccountingPeriod: Boolean; PeriodEndingDate: Date; var PeriodLength: Integer): Date
    var
        AccountingPeriod: Record "Accounting Period";
        UntilDate2: Date;
    begin
        if not UseAccountingPeriod or AccountingPeriod.IsEmpty() then
            exit(FADateCalculation.CalculateDate(PeriodEndingDate, PeriodLength, Year365Days));
        AccountingPeriod.SetFilter(
          "Starting Date", '>=%1', DepreciationCalculation.ToMorrow(PeriodEndingDate, Year365Days) + 1);
        OnAfterAccountingPeriodSetFilter(PeriodEndingDate, Year365Days, DeprBook."Use Accounting Period", AccountingPeriod);
        if AccountingPeriod.FindFirst() then begin
            if Date2DMY(AccountingPeriod."Starting Date", 1) <> 31 then
                UntilDate2 := DepreciationCalculation.Yesterday(AccountingPeriod."Starting Date", Year365Days, DeprBook."Use Accounting Period")
            else
                UntilDate2 := AccountingPeriod."Starting Date" - 1;
            PeriodLength :=
              DepreciationCalculation.DeprDays(
                DepreciationCalculation.ToMorrow(PeriodEndingDate, Year365Days,
                DeprBook."Use Accounting Period"), UntilDate2, Year365Days, DeprBook."Use Accounting Period");
            if (PeriodLength <= 5) or (PeriodLength > DaysInFiscalYear) then
                PeriodLength := DaysInFiscalYear;
            exit(UntilDate2);
        end;
        if Year365Days then
            Error(YouMustCreateAccPeriodsErr,
              DepreciationCalculation.ToMorrow(EndingDate, Year365Days, DeprBook."Use Accounting Period") + 1);
        exit(FADateCalculation.CalculateDate(PeriodEndingDate, PeriodLength, Year365Days));
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
        if GroupCodeName <> '' then begin
            GroupCodeName2 := GroupCodeName;
            if GroupTotals = GroupTotals::"Main Asset" then
                GroupCodeName2 := StrSubstNo('%1', SelectStr(GroupTotals + 1, GroupCodeNameTxt));
            GroupCodeName := StrSubstNo('%1%2 %3', GroupTotalsTxt, ':', GroupCodeName2);
        end;
    end;

    local procedure ValidateDates()
    begin
        FAGenReport.ValidateDeprDates(StartingDate, EndingDate);
        EndingDate2 := EndingDate;
        StartingDate2 := StartingDate;
    end;

    local procedure MakeGroupHeadLine()
    begin
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
                      StrSubstNo('%1 %2', FA."Main Asset/Component", "Fixed Asset"."Component of Main Asset");
                    if "Fixed Asset"."Component of Main Asset" = '' then
                        GroupHeadLine := StrSubstNo('%1%2', GroupHeadLine, '*****');
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
    end;

    local procedure UpdateTotals()
    var
        BudgetDepreciation: Codeunit "Budget Depreciation";
        EntryNo: Integer;
        CodeName: Code[20];
    begin
        EntryAmounts[1] := EntryAmounts[1] + DeprAmount + Custom1Amount;
        if Custom1DeprUntil > 0D then
            if UntilDate <= Custom1DeprUntil then
                EntryAmounts[4] := EntryAmounts[4] + DeprAmount + Custom1Amount;
        EntryAmounts[2] := EntryAmounts[2] + Custom1Amount;
        EntryAmounts[3] := EntryAmounts[3] + DeprAmount + Custom1Amount;
        AssetAmounts[1] := AssetAmounts[1] + DeprAmount;
        AssetAmounts[2] := AssetAmounts[2] + Custom1Amount;
        GroupAmounts[1] := GroupAmounts[1] + DeprAmount;
        GroupAmounts[2] := GroupAmounts[2] + Custom1Amount;
        TotalAmounts[1] := TotalAmounts[1] + DeprAmount;
        TotalAmounts[2] := TotalAmounts[2] + Custom1Amount;
        TotalBookValue[1] := TotalBookValue[1] + DeprAmount + Custom1Amount;
        TotalBookValue[2] := TotalBookValue[2] + DeprAmount + Custom1Amount;
        GroupTotalBookValue += DeprAmount + Custom1Amount;
        if BudgetNameCode <> '' then
            BudgetDepreciation.CopyProjectedValueToBudget(
              FADeprBook, BudgetNameCode, UntilDate, DeprAmount, Custom1Amount, BalAccount);

        if (UntilDate > 0D) or PrintAmountsPerDate then begin
            TempFABufferProjection.Reset();
            if TempFABufferProjection.Find('+') then
                EntryNo := TempFABufferProjection."Entry No." + 1
            else
                EntryNo := 1;
            TempFABufferProjection.SetRange("FA Posting Date", UntilDate);
            if GroupTotals <> GroupTotals::" " then begin
                case GroupTotals of
                    GroupTotals::"FA Class":
                        CodeName := "Fixed Asset"."FA Class Code";
                    GroupTotals::"FA Subclass":
                        CodeName := "Fixed Asset"."FA Subclass Code";
                    GroupTotals::"FA Location":
                        CodeName := "Fixed Asset"."FA Location Code";
                    GroupTotals::"Main Asset":
                        CodeName := "Fixed Asset"."Component of Main Asset";
                    GroupTotals::"Global Dimension 1":
                        CodeName := "Fixed Asset"."Global Dimension 1 Code";
                    GroupTotals::"Global Dimension 2":
                        CodeName := "Fixed Asset"."Global Dimension 2 Code";
                    GroupTotals::"FA Posting Group":
                        CodeName := "Fixed Asset"."FA Posting Group";
                end;
                TempFABufferProjection.SetRange("Code Name", CodeName);
            end;
            if not TempFABufferProjection.Find('=><') then begin
                TempFABufferProjection.Init();
                TempFABufferProjection."Code Name" := CodeName;
                TempFABufferProjection."FA Posting Date" := UntilDate;
                TempFABufferProjection."Entry No." := EntryNo;
                TempFABufferProjection.Depreciation := DeprAmount;
                TempFABufferProjection."Custom 1" := Custom1Amount;
                TempFABufferProjection.Insert();
            end else begin
                TempFABufferProjection.Depreciation := TempFABufferProjection.Depreciation + DeprAmount;
                TempFABufferProjection."Custom 1" := TempFABufferProjection."Custom 1" + Custom1Amount;
                TempFABufferProjection.Modify();
            end;
        end;
    end;

    local procedure InitGroupTotals()
    begin
        GroupAmounts[1] := 0;
        GroupAmounts[2] := 0;
        GroupAmounts[3] := 0;
        GroupAmounts[4] := 0;
        GroupTotalBookValue := 0;
        if NotFirstGroupTotal then
            TotalBookValue[1] := 0
        else
            TotalBookValue[1] := EntryAmounts[1];
        NotFirstGroupTotal := true;
    end;

    local procedure GetDeprBasis(): Decimal
    var
        FALedgEntry: Record "FA Ledger Entry";
    begin
        FALedgEntry.SetCurrentKey("FA No.", "Depreciation Book Code", "Part of Book Value", "FA Posting Date");
        FALedgEntry.SetRange("FA No.", "Fixed Asset"."No.");
        FALedgEntry.SetRange("Depreciation Book Code", DeprBookCode);
        FALedgEntry.SetRange("Part of Book Value", true);
        FALedgEntry.SetRange("FA Posting Date", 0D, Custom1DeprUntil);
        FALedgEntry.CalcSums(Amount);
        exit(FALedgEntry.Amount);
    end;

    local procedure CalculateGainLoss()
    var
        CalculateDisposal: Codeunit "Calculate Disposal";
        EntryAmounts: array[14] of Decimal;
        PrevAmount: array[2] of Decimal;
    begin
        PrevAmount[1] := AssetAmounts[3];
        PrevAmount[2] := AssetAmounts[4];

        CalculateDisposal.CalcGainLoss("Fixed Asset"."No.", DeprBookCode, EntryAmounts);
        AssetAmounts[3] := FADeprBook."Projected Proceeds on Disposal";
        if EntryAmounts[1] <> 0 then
            AssetAmounts[4] := EntryAmounts[1]
        else
            AssetAmounts[4] := EntryAmounts[2];
        AssetAmounts[4] :=
          AssetAmounts[4] + AssetAmounts[1] + AssetAmounts[2] - FADeprBook."Projected Proceeds on Disposal";

        GroupAmounts[3] += AssetAmounts[3] - PrevAmount[1];
        GroupAmounts[4] += AssetAmounts[4] - PrevAmount[2];
    end;

    local procedure CalculationDone(Done: Boolean; FirstDeprDate: Date): Boolean
    var
        TableDeprCalculation: Codeunit "Table Depr. Calculation";
    begin
        if Done or
           (FADeprBook."Depreciation Method" <> FADeprBook."Depreciation Method"::"User-Defined")
        then
            exit(Done);
        exit(
          TableDeprCalculation.GetTablePercent(
            DeprBookCode, FADeprBook."Depreciation Table Code",
            FADeprBook."First User-Defined Depr. Date", FirstDeprDate, UntilDate) = 0);
    end;

    local procedure UpdateReqForm()
    begin
        PageUpdateReqForm();
    end;

    local procedure PageUpdateReqForm()
    var
        DeprBook: Record "Depreciation Book";
    begin
        if DeprBookCode <> '' then
            DeprBook.Get(DeprBookCode);

        PeriodLength := 0;
        if DeprBook."Fiscal Year 365 Days" and not UseAccountingPeriod then
            PeriodLength := 365;
    end;

    procedure SetMandatoryFields(DepreciationBookCodeFrom: Code[10]; StartingDateFrom: Date; EndingDateFrom: Date)
    begin
        DeprBookCode := DepreciationBookCodeFrom;
        StartingDate := StartingDateFrom;
        EndingDate := EndingDateFrom;
    end;

    procedure SetPeriodFields(PeriodLengthFrom: Integer; DaysInFirstPeriodFrom: Integer; IncludePostedFromFrom: Date; UseAccountingPeriodFrom: Boolean)
    begin
        PeriodLength := PeriodLengthFrom;
        DaysInFirstPeriod := DaysInFirstPeriodFrom;
        IncludePostedFrom := IncludePostedFromFrom;
        UseAccountingPeriod := UseAccountingPeriodFrom;
    end;

    procedure SetTotalFields(GroupTotalsFrom: Option; PrintDetailsFrom: Boolean)
    begin
        GroupTotals := GroupTotalsFrom;
        PrintDetails := PrintDetailsFrom;
    end;

    procedure SetBudgetField(BudgetNameCodeFrom: Code[10]; BalAccountFrom: Boolean; ProjectedDisposalFrom: Boolean; PrintAmountsPerDateFrom: Boolean)
    begin
        BudgetNameCode := BudgetNameCodeFrom;
        BalAccount := BalAccountFrom;
        ProjectedDisposal := ProjectedDisposalFrom;
        PrintAmountsPerDate := PrintAmountsPerDateFrom;
    end;

    procedure GetFASetup()
    begin
        if DeprBookCode = '' then begin
            FASetup.Get();
            DeprBookCode := FASetup."Default Depr. Book";
        end;
        UpdateReqForm();
    end;

    local procedure UpdateGroupTotals()
    begin
        GroupAmounts[1] := GroupAmounts[1] + DeprAmount;
        TotalAmounts[1] := TotalAmounts[1] + DeprAmount;
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCalculateFirstDeprAmount(var FixedAsset: Record "Fixed Asset"; var CalculateDepr: Codeunit "Calculate Depreciation"; var DepreciationCalculation: Codeunit "Depreciation Calculation"; var FirstTime: Boolean; var Done: Boolean; var UntilDate: Date; var StartingDate: Date; var DeprAmount: Decimal; var Custom1Amount: Decimal; var NumberOfDays: Integer; var Custom1NumberOfDays: Integer; var DeprBookCode: Code[10]; var EntryAmounts: array[4] of Decimal; var DaysInFirstPeriod: Integer; var EndingDate: Date; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAccountingPeriodSetFilter(var PeriodEndingDate: Date; var Year365Days: Boolean; UseAccountingPeriod: Boolean; var AccountingPeriod: Record "Accounting Period")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterTransferValues(GroupAmounts: array[4] of Decimal; TotalBookValue: array[2] of Decimal)
    begin
    end;
}

