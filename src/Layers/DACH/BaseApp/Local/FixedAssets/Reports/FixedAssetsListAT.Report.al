// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Reports;

using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Posting;
using Microsoft.FixedAssets.Setup;
using Microsoft.Purchases.Vendor;

report 11100 "Fixed Assets - List AT"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/FixedAssets/Reports/FixedAssetsListAT.rdlc';
    ApplicationArea = FixedAssets;
    Caption = 'List AT';
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
            column(FABookText; FABookText)
            {
            }
            column(GroupTotalsType; GroupTotalsType)
            {
            }
            column(BudgReport; BudgReport)
            {
            }
            column(PrintDetails; PrintDetails)
            {
            }
            column(Fixed_Asset__TABLECAPTION__________FAFilter; "Fixed Asset".TableCaption + ': ' + FAFilter)
            {
            }
            column(FAFilter; FAFilter)
            {
            }
            column(Header_1_; Header[1])
            {
            }
            column(Header_2_; Header[2])
            {
            }
            column(Header_3_; Header[3])
            {
            }
            column(Header_5_; Header[5])
            {
            }
            column(Header_6_; Header[6])
            {
            }
            column(Header_7_; Header[7])
            {
            }
            column(Header_9_; Header[9])
            {
            }
            column(Header_10_; Header[10])
            {
            }
            column(FANumber; FANumber)
            {
            }
            column(FADescription; FADescription)
            {
            }
            column(GroupCodeName; GroupCodeName)
            {
            }
            column(Header_4_; Header[4])
            {
            }
            column(Header_8_; Header[8])
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
            column(Vendor_Name; Vendor.Name)
            {
            }
            column(Vendor__No__; Vendor."No.")
            {
            }
            column(FADeprBook__Last_Custom_2_Date_; Format(FADeprBook."Last Custom 2 Date"))
            {
            }
            column(FADeprBook__Custom_2_; FADeprBook."Custom 2")
            {
            }
            column(NetChangeAmounts_1_; NetChangeAmounts[1])
            {
            }
            column(DisposalAmounts_1_; DisposalAmounts[1])
            {
            }
            column(TotalEndingAmounts_1_; TotalEndingAmounts[1])
            {
            }
            column(NetChangeAmounts_2_; NetChangeAmounts[2])
            {
            }
            column(DisposalAmounts_2_; DisposalAmounts[2])
            {
            }
            column(TotalEndingAmounts_2_; TotalEndingAmounts[2])
            {
            }
            column(BookValueAtStartingDate; BookValueAtStartingDate)
            {
            }
            column(BookValueAtEndingDate; BookValueAtEndingDate)
            {
            }
            column(Vendor_Address; Vendor.Address)
            {
            }
            column(STRSUBSTNO___1__2__Vendor__Post_Code__Vendor_City_; StrSubstNo('%1 %2', Vendor."Post Code", Vendor.City))
            {
            }
            column(UseTimeText; UseTimeText)
            {
            }
            column(Fixed_Asset__BWR_Depr__Book_Code_; "BWR Depr. Book Code")
            {
            }
            column(Fixed_Asset__Prem_Depr____; "Prem Depr. %")
            {
            }
            column(FADeprBook__Depreciation_Starting_Date_; Format(FADeprBook."Depreciation Starting Date"))
            {
            }
            column(StartAmounts_1_; StartAmounts[1])
            {
            }
            column(StartAmounts_2_; StartAmounts[2])
            {
            }
            column(Fixed_Asset__Prem__Depr__Amount_; "Prem. Depr. Amount")
            {
            }
            column(FORMAT_Text002__________GroupHeadLine_; Format(Text002 + ': ' + GroupHeadLine))
            {
            }
            column(GroupNetChange_1_; GroupNetChange[1])
            {
            }
            column(GroupDispAmounts_1_; GroupDispAmounts[1])
            {
            }
            column(TotalEndingAmounts_1__Control48; TotalEndingAmounts[1])
            {
            }
            column(GroupNetChange_2_; GroupNetChange[2])
            {
            }
            column(GroupDispAmounts_2_; GroupDispAmounts[2])
            {
            }
            column(TotalEndingAmounts_2__Control60; TotalEndingAmounts[2])
            {
            }
            column(BookValueAtStartingDate_Control63; BookValueAtStartingDate)
            {
            }
            column(BookValueAtEndingDate_Control66; BookValueAtEndingDate)
            {
            }
            column(GroupStartAmounts_1_; GroupStartAmounts[1])
            {
            }
            column(GroupStartAmounts_2_; GroupStartAmounts[2])
            {
            }
            column(TotalStartAmounts_1_; TotalStartAmounts[1])
            {
            }
            column(TotalNetChange_1_; TotalNetChange[1])
            {
            }
            column(TotalDispAmounts_1_; TotalDispAmounts[1])
            {
            }
            column(TotalEndingAmounts_1__Control49; TotalEndingAmounts[1])
            {
            }
            column(TotalStartAmounts_2_; TotalStartAmounts[2])
            {
            }
            column(TotalNetChange_2_; TotalNetChange[2])
            {
            }
            column(TotalDispAmounts_2_; TotalDispAmounts[2])
            {
            }
            column(TotalEndingAmounts_2__Control61; TotalEndingAmounts[2])
            {
            }
            column(BookValueAtStartingDate_Control64; BookValueAtStartingDate)
            {
            }
            column(BookValueAtEndingDate_Control67; BookValueAtEndingDate)
            {
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
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(IFB_AmountCaption; IFB_AmountCaptionLbl)
            {
            }
            column(IFB_DateCaption; IFB_DateCaptionLbl)
            {
            }
            column(Depr__StartdateCaption; Depr__StartdateCaptionLbl)
            {
            }
            column(GND___RNDCaption; GND___RNDCaptionLbl)
            {
            }
            column(VendorCaption; VendorCaptionLbl)
            {
            }
            column(Fixed_Asset__BWR_Depr__Book_Code_Caption; FieldCaption("BWR Depr. Book Code"))
            {
            }
            column(Fixed_Asset__Prem_Depr____Caption; FieldCaption("Prem Depr. %"))
            {
            }
            column(Fixed_Asset__Prem__Depr__Amount_Caption; FieldCaption("Prem. Depr. Amount"))
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

                AmountBefore := 0;
                AmountAfter := 0;
                if BudgReport then
                    BudgDepr.Calculate(
                      "No.", GetStartingDate(StartDate), EndDate, DeprBookCode, AmountBefore, AmountAfter);

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
                    if StartDate <= 00000101D then
                        StartAmounts[i] := 0
                    else
                        StartAmounts[i] := FAGenReport.CalcFAPostedAmount("No.", PostingType, Period1, StartDate,
                            EndDate, DeprBookCode, AmountBefore, AmountAfter, false, true);
                    NetChangeAmounts[i] :=
                      FAGenReport.CalcFAPostedAmount(
                        "No.", PostingType, Period2, StartDate, EndDate,
                        DeprBookCode, AmountBefore, AmountAfter, false, true);
                    if GetPeriodDisposal() then
                        DisposalAmounts[i] := -(StartAmounts[i] + NetChangeAmounts[i])
                    else
                        DisposalAmounts[i] := 0;
                    if i >= 3 then
                        AddPostingType(i - 3);
                end;
                for j := 1 to NumberOfTypes do
                    TotalEndingAmounts[j] := StartAmounts[j] + NetChangeAmounts[j] + DisposalAmounts[j];
                BookValueAtEndingDate := 0;
                BookValueAtStartingDate := 0;
                for j := 1 to NumberOfTypes do begin
                    BookValueAtEndingDate := BookValueAtEndingDate + TotalEndingAmounts[j];
                    BookValueAtStartingDate := BookValueAtStartingDate + StartAmounts[j];
                end;

                if "Fixed Asset"."Vendor No." <> '' then
                    Vendor.Get("Fixed Asset"."Vendor No.")
                else begin
                    Vendor.Init();
                    Vendor."No." := '';
                end;

                FADeprBook.CalcFields("Custom 2");
                if (FADeprBook."Depreciation Method" <> FADeprBook."Depreciation Method"::Manual) and
                   (FADeprBook."Depreciation Method" <> FADeprBook."Depreciation Method"::"User-Defined")
                then begin
                    TotalUseTimeYears := FADeprBook."No. of Depreciation Years";
                    RestUseTimeYears := Round((FADeprBook."Depreciation Ending Date" - EndDate) / 360, 1, '<');
                end else begin
                    TotalUseTimeYears := 999;
                    RestUseTimeYears := 999;
                end;
                if RestUseTimeYears < 0 then
                    RestUseTimeYears := 0;
                UseTimeText := StrSubstNo('%1 / %2', TotalUseTimeYears, RestUseTimeYears);

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
                    GroupTotals::"FA Location":
                        SetCurrentKey("FA Location Code");
                    GroupTotals::"Main Asset":
                        SetCurrentKey("Component of Main Asset");
                    GroupTotals::"Global Dimension 1":
                        SetCurrentKey("Global Dimension 1 Code");
                    GroupTotals::"Global Dimension 2":
                        SetCurrentKey("Global Dimension 2 Code");
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
                        Lookup = true;
                        TableRelation = "Depreciation Book";
                        ToolTip = 'Specifies the depreciation book that is assigned to the fixed asset.';
                    }
                    field(StartDate; StartDate)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Start Date';
                        ToolTip = 'Specifies the date from which the report or batch job processes information.';
                    }
                    field(EndDate; EndDate)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'End Date';
                        ToolTip = 'Specifies the last date that the report includes data for.';
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
                        Caption = 'Print Details';
                        ToolTip = 'Specifies the details of each fixed asset within the filter. If you do not select this check box, then only the totals will be printed on the report.';
                    }
                    field(BudgetReport; BudgReport)
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
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        NumberOfTypes := 6;
        FABook.Get(DeprBookCode);
        FAGenReport.AppendFAPostingFilter("Fixed Asset", StartDate, EndDate);
        FAFilter := "Fixed Asset".GetFilters();
        MainHeadLineText := Text000;
        if BudgReport then
            MainHeadLineText := StrSubstNo('%1 %2', MainHeadLineText, Text001);
        FABookText := StrSubstNo('%1%2 %3', FABook.TableCaption(), ':', DeprBookCode);
        MakeGroupTotalText();
        FAGenReport.ValidateDates(StartDate, EndDate);
        MakeDateText();
        MakeHeadLine();
        if PrintDetails then begin
            FANumber := "Fixed Asset".FieldCaption("No.");
            FADescription := "Fixed Asset".FieldCaption(Description);
        end;
        Period1 := Period1::"Before Starting Date";
        Period2 := Period2::"Net Change";
        GroupTotalsType := GroupTotals;
    end;

    var
        Text000: Label 'Fixed Assets List AT';
        Text001: Label '(budgeted)';
        Text002: Label 'Grouptotal';
        Text003: Label 'GroupTotals';
        Text004: Label 'in Period';
        Text005: Label 'Disposal';
        Text006: Label 'Appreciation';
        FASetup: Record "FA Setup";
        FABook: Record "Depreciation Book";
        FADeprBook: Record "FA Depreciation Book";
        FA: Record "Fixed Asset";
        FAPostingTypeSetup: Record "FA Posting Type Setup";
        Vendor: Record Vendor;
        FAGenReport: Codeunit "FA General Report";
        BudgDepr: Codeunit "Budget Depreciation";
        DeprBookCode: Code[10];
        FAFilter: Text;
        MainHeadLineText: Text[100];
        FABookText: Text[50];
        GroupCodeName: Text[50];
        GroupHeadLine: Text[50];
        FANumber: Text[50];
        FADescription: Text[100];
        GroupTotals: Option " ","FA Class","FA Subclass","FA Location","Main Asset","Global Dimension 1","Global Dimension 2","FA Posting Group";
        Header: array[10] of Text[50];
        StartAmounts: array[6] of Decimal;
        NetChangeAmounts: array[6] of Decimal;
        DisposalAmounts: array[6] of Decimal;
        GroupStartAmounts: array[6] of Decimal;
        GroupNetChange: array[6] of Decimal;
        GroupDispAmounts: array[6] of Decimal;
        TotalStartAmounts: array[6] of Decimal;
        TotalNetChange: array[6] of Decimal;
        TotalDispAmounts: array[6] of Decimal;
        TotalEndingAmounts: array[6] of Decimal;
        BookValueAtStartingDate: Decimal;
        BookValueAtEndingDate: Decimal;
        i: Integer;
        j: Integer;
        NumberOfTypes: Integer;
        PostingType: Integer;
        GroupTotalsType: Integer;
        Period1: Option "Before Starting Date","Net Change","At Ending Date";
        Period2: Option "Before Starting Date","Net Change","At Ending Date";
        StartDate: Date;
        EndDate: Date;
        PrintDetails: Boolean;
        BudgReport: Boolean;
        AmountBefore: Decimal;
        AmountAfter: Decimal;
        AcquisDate: Date;
        DispDate: Date;
        StartText: Text[30];
        EndText: Text[30];
        UseTimeText: Text[30];
        RestUseTimeYears: Decimal;
        TotalUseTimeYears: Decimal;
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        IFB_AmountCaptionLbl: Label 'IFB Amount';
        IFB_DateCaptionLbl: Label 'IFB Date';
        Depr__StartdateCaptionLbl: Label 'Depr. Startdate';
        GND___RNDCaptionLbl: Label 'GND / RND';
        VendorCaptionLbl: Label 'Vendor';
        TotalCaptionLbl: Label 'Total';

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
        AcquisDate := FADeprBook."Acquisition Date";
        DispDate := FADeprBook."Disposal Date";
        exit(
          "Fixed Asset".Inactive or
          (AcquisDate = 0D) or
          (AcquisDate > EndDate) and (EndDate > 0D) or
          (DispDate > 0D) and (DispDate < StartDate))
    end;

    local procedure GetPeriodDisposal(): Boolean
    begin
        if DispDate > 0D then
            if (EndDate = 0D) or (DispDate <= EndDate) then
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
        end;
        if GroupCodeName <> '' then
            GroupCodeName := Format(StrSubstNo('%1%2 %3', Text003, ':', GroupCodeName));
    end;

    local procedure MakeDateText()
    begin
        StartText := StrSubstNo('%1', StartDate - 1);
        EndText := StrSubstNo('%1', EndDate);
    end;

    local procedure MakeHeadLine()
    var
        InPeriodText: Text[30];
        DisposalText: Text[30];
    begin
        InPeriodText := Text004;
        DisposalText := Text005;
        Header[1] := StrSubstNo('%1 %2', FADeprBook.FieldCaption("Acquisition Cost"), StartText);
        Header[2] := StrSubstNo('%1 %2', Text006, InPeriodText);
        Header[3] := StrSubstNo('%1 %2', DisposalText, InPeriodText);
        Header[4] := StrSubstNo('%1 %2', FADeprBook.FieldCaption("Acquisition Cost"), EndText);
        Header[5] := StrSubstNo('%1 %2', FADeprBook.FieldCaption(Depreciation), StartText);
        Header[6] := StrSubstNo('%1 %2', FADeprBook.FieldCaption(Depreciation), InPeriodText);
        Header[7] := StrSubstNo(
            '%1 %2 %3', DisposalText, FADeprBook.FieldCaption(Depreciation), InPeriodText);
        Header[8] := StrSubstNo('%1 %2', FADeprBook.FieldCaption(Depreciation), EndText);
        Header[9] := StrSubstNo('%1 %2', FADeprBook.FieldCaption("Book Value"), StartText);
        Header[10] := StrSubstNo('%1 %2', FADeprBook.FieldCaption("Book Value"), EndText);
    end;

    local procedure MakeGroupHeadLine()
    begin
        for j := 1 to NumberOfTypes do begin
            GroupStartAmounts[j] := 0;
            GroupNetChange[j] := 0;
            GroupDispAmounts[j] := 0;
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
        end;

        if GroupHeadLine = '' then
            GroupHeadLine := Format('*****');
    end;

    local procedure UpdateTotals()
    begin
        for j := 1 to NumberOfTypes do begin
            GroupStartAmounts[j] := GroupStartAmounts[j] + StartAmounts[j];
            GroupNetChange[j] := GroupNetChange[j] + NetChangeAmounts[j];
            GroupDispAmounts[j] := GroupDispAmounts[j] + DisposalAmounts[j];
            TotalStartAmounts[j] := TotalStartAmounts[j] + StartAmounts[j];
            TotalNetChange[j] := TotalNetChange[j] + NetChangeAmounts[j];
            TotalDispAmounts[j] := TotalDispAmounts[j] + DisposalAmounts[j];
        end;
    end;

    local procedure CreateGroupTotals()
    begin
        for j := 1 to NumberOfTypes do
            TotalEndingAmounts[j] :=
              GroupStartAmounts[j] + GroupNetChange[j] + GroupDispAmounts[j];
        BookValueAtEndingDate := 0;
        BookValueAtStartingDate := 0;
        for j := 1 to NumberOfTypes do begin
            BookValueAtEndingDate := BookValueAtEndingDate + TotalEndingAmounts[j];
            BookValueAtStartingDate := BookValueAtStartingDate + GroupStartAmounts[j];
        end;
    end;

    local procedure CreateTotals()
    begin
        for j := 1 to NumberOfTypes do
            TotalEndingAmounts[j] :=
              TotalStartAmounts[j] + TotalNetChange[j] + TotalDispAmounts[j];
        BookValueAtEndingDate := 0;
        BookValueAtStartingDate := 0;
        for j := 1 to NumberOfTypes do begin
            BookValueAtEndingDate := BookValueAtEndingDate + TotalEndingAmounts[j];
            BookValueAtStartingDate := BookValueAtStartingDate + TotalStartAmounts[j];
        end;
    end;

    local procedure GetStartingDate(StartDate: Date): Date
    begin
        if StartDate <= 00000101D then
            exit(0D);

        exit(StartDate - 1);
    end;
}

