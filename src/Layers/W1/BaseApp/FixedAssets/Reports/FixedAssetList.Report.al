// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Reports;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Setup;

report 5601 "Fixed Asset - List"
{
    DefaultLayout = RDLC;
    RDLCLayout = './FixedAssets/Reports/FixedAssetList.rdlc';
    ApplicationArea = FixedAssets;
    Caption = 'Fixed Asset List';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Fixed Asset"; "Fixed Asset")
        {
            DataItemTableView = sorting("No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "FA Class Code", "FA Subclass Code", "Budgeted Asset";
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(DeprBookText; DeprBookText)
            {
            }
            column(FATableCaptionFAFilter; TableCaption + ': ' + FAFilter)
            {
            }
            column(FAFilter; FAFilter)
            {
            }
            column(FANo; "No.")
            {
                IncludeCaption = true;
            }
            column(FADesc; Description)
            {
            }
            column(FAMainAssetComponent; "Main Asset/Component")
            {
            }
            column(BudgetedAssetFieldname; BudgetedAssetFieldname)
            {
            }
            column(FASerialNo; "Serial No.")
            {
            }
            column(FAComponentofMainAsset; "Component of Main Asset")
            {
            }
            column(ComponentFieldname; ComponentFieldname)
            {
            }
            column(GlobalDim1CodeCaption; GlobalDim1CodeCaption)
            {
            }
            column(FAGlobalDim1Code; "Global Dimension 1 Code")
            {
            }
            column(GlobalDim2CodeCaption; GlobalDim2CodeCaption)
            {
            }
            column(FAGlobalDim2Code; "Global Dimension 2 Code")
            {
            }
            column(FAClassCode; "FA Class Code")
            {
                IncludeCaption = true;
            }
            column(FASubclassCode; "FA Subclass Code")
            {
                IncludeCaption = true;
            }
            column(FALocationCode; "FA Location Code")
            {
                IncludeCaption = true;
            }
            column(PageGroupNo; PageGroupNo)
            {
            }
            column(FAListCaption; FAListCaptionLbl)
            {
            }
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
            }
            dataitem("FA Depreciation Book"; "FA Depreciation Book")
            {
                DataItemTableView = sorting("FA No.", "Depreciation Book Code");
                column(FADeprBookDeprMethod; "Depreciation Method")
                {
                    IncludeCaption = true;
                }
                column(FADeprBookDeprStartingDate; Format("Depreciation Starting Date"))
                {
                }
                column(FADeprBookFAPostingGroup; "FA Posting Group")
                {
                    IncludeCaption = true;
                }
                column(FADeprBookStraightLine; "Straight-Line %")
                {
                    IncludeCaption = true;
                }
                column(FADeprBookNoofDeprYrs; "No. of Depreciation Years")
                {
                    IncludeCaption = true;
                }
                column(FADeprBookNoofDeprMonths; "No. of Depreciation Months")
                {
                    IncludeCaption = true;
                }
                column(FADeprBookDeprEndingDate; Format("Depreciation Ending Date"))
                {
                }
                column(FADeprBookFixedDeprAmt; "Fixed Depr. Amount")
                {
                    IncludeCaption = true;
                }
                column(FADeprBookDecliningBalance; "Declining-Balance %")
                {
                    IncludeCaption = true;
                }
                column(FADeprBookDeprTableCode; "Depreciation Table Code")
                {
                    IncludeCaption = true;
                }
                column(FADeprBookUserDefinedDeprDt; Format("First User-Defined Depr. Date"))
                {
                }
                column(FADeprBookFinalRoundingAmt; "Final Rounding Amount")
                {
                    IncludeCaption = true;
                }
                column(FADeprBookEndingBookValue; "Ending Book Value")
                {
                    IncludeCaption = true;
                }
                column(FADeprBookFAExchangeRate; "FA Exchange Rate")
                {
                    IncludeCaption = true;
                }
                column(FADeprBookUseFALedgCheck; "Use FA Ledger Check")
                {
                    IncludeCaption = true;
                }
                column(FADeprBookDeprbelowZero; "Depr. below Zero %")
                {
                    IncludeCaption = true;
                }
                column(FADeprBookFDeprAmtbelowZero; "Fixed Depr. Amount below Zero")
                {
                    IncludeCaption = true;
                }
                column(FADeprBookProjProceedDspsl; "Projected Proceeds on Disposal")
                {
                    IncludeCaption = true;
                }
                column(FADeprBookProjDisposalDate; Format("Projected Disposal Date"))
                {
                }
                column(FADeprBookStartingDateCustom; Format("Depr. Starting Date (Custom 1)"))
                {
                }
                column(FADeprBookAccumDeprCustom; "Accum. Depr. % (Custom 1)")
                {
                    IncludeCaption = true;
                }
                column(FADeprBookThisYrCustom; "Depr. This Year % (Custom 1)")
                {
                    IncludeCaption = true;
                }
                column(FADeprBookEndingDateCustom; Format("Depr. Ending Date (Custom 1)"))
                {
                }
                column(FADeprBookPropertyClassCustom; "Property Class (Custom 1)")
                {
                    IncludeCaption = true;
                }
                column(FADeprBookDeprStartDateCaption; FADeprBookDeprStartDateCaptionLbl)
                {
                }
                column(FADeprBookDeprEndDateCaption; FADeprBookDeprEndDateCaptionLbl)
                {
                }
                column(FADeprBookUsrDfndDeprDtCaption; FADeprBookUsrDfndDeprDtCaptionLbl)
                {
                }
                column(FADeprBookProjDisplDateCaption; FADeprBookProjDisplDateCaptionLbl)
                {
                }
                column(FADeprBookStartDateCustomCaption; FADeprBookStartDateCustomCaptionLbl)
                {
                }
                column(FADeprBookEndDateCustomCptn; FADeprBookEndDateCustomCptnLbl)
                {
                }

                trigger OnPreDataItem()
                begin
                    SetRange("FA No.", "Fixed Asset"."No.");
                    SetRange("Depreciation Book Code", DeprBookCode);
                end;
            }

            trigger OnAfterGetRecord()
            var
                ShouldSkipAsset: Boolean;
            begin
                ShouldSkipAsset := Inactive;
                OnFixedAssetOnAfterGetRecordOnAfterCalcShouldSkipAsset("Fixed Asset", ShouldSkipAsset);
                if ShouldSkipAsset then
                    CurrReport.Skip();
                if "Main Asset/Component" <> "Main Asset/Component"::" " then
                    ComponentFieldname := FieldCaption("Component of Main Asset")
                else
                    ComponentFieldname := '';
                if "Budgeted Asset" then
                    BudgetedAssetFieldname := FieldCaption("Budgeted Asset")
                else
                    BudgetedAssetFieldname := '';
                if PrintOnlyOnePerPage then
                    PageGroupNo := PageGroupNo + 1;
            end;

            trigger OnPreDataItem()
            begin
                PageGroupNo := 1;
            end;
        }
    }

    requestpage
    {
        SaveValues = true;
        AboutTitle = 'About Fixed Asset List';
        AboutText = 'The **Fixed Asset List** report provides a comprehensive listing of all fixed assets owned by an organization at a specific point in time. This report is crucial for asset management, financial reporting, and compliance purposes.';

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
                        AboutText = 'Choose the Depreciation Book and specify New Page per Asset if you want each fixed asset printed on a new page.';
                        ToolTip = 'Specifies the code for the depreciation book to be included in the report or batch job.';
                    }
                    field(PrintOnlyOnePerPage; PrintOnlyOnePerPage)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'New Page per Asset';
                        ToolTip = 'Specifies if you want each fixed asset printed on a new page.';
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
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        Dimension: Record Dimension;
    begin
        DeprBook.Get(DeprBookCode);
        FAFilter := "Fixed Asset".GetFilters();
        DeprBookText := StrSubstNo('%1%2 %3', DeprBook.TableCaption(), ':', DeprBookCode);
        GlobalDim1CodeCaption := '';
        GlobalDim2CodeCaption := '';
        GeneralLedgerSetup.Get();
        if GeneralLedgerSetup."Global Dimension 1 Code" <> '' then begin
            Dimension.Get(GeneralLedgerSetup."Global Dimension 1 Code");
            GlobalDim1CodeCaption := Dimension."Code Caption";
        end;
        if GeneralLedgerSetup."Global Dimension 2 Code" <> '' then begin
            Dimension.Get(GeneralLedgerSetup."Global Dimension 2 Code");
            GlobalDim2CodeCaption := Dimension."Code Caption";
        end;
    end;

    var
        FASetup: Record "FA Setup";
        DeprBook: Record "Depreciation Book";
        PrintOnlyOnePerPage: Boolean;
        DeprBookCode: Code[10];
        FAFilter: Text;
        ComponentFieldname: Text[100];
        BudgetedAssetFieldname: Text[100];
        DeprBookText: Text[50];
        PageGroupNo: Integer;
        FAListCaptionLbl: Label 'Fixed Asset - List';
        CurrReportPageNoCaptionLbl: Label 'Page';
        FADeprBookDeprStartDateCaptionLbl: Label 'Depreciation Starting Date';
        FADeprBookDeprEndDateCaptionLbl: Label 'Depreciation Ending Date';
        FADeprBookUsrDfndDeprDtCaptionLbl: Label 'First User-Defined Depr. Date';
        FADeprBookProjDisplDateCaptionLbl: Label 'Projected Disposal Date';
        FADeprBookStartDateCustomCaptionLbl: Label 'Depr. Starting Date (Custom 1)';
        FADeprBookEndDateCustomCptnLbl: Label 'Depr. Ending Date (Custom 1)';
        GlobalDim1CodeCaption: Text[80];
        GlobalDim2CodeCaption: Text[80];

    [IntegrationEvent(false, false)]
    local procedure OnFixedAssetOnAfterGetRecordOnAfterCalcShouldSkipAsset(FixedAsset: Record "Fixed Asset"; var ShouldSkipAsset: Boolean)
    begin
    end;
}

