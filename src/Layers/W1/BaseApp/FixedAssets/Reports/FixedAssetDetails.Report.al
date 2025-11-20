// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Reports;

using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Ledger;
using Microsoft.FixedAssets.Setup;

report 5604 "Fixed Asset - Details"
{
    DefaultLayout = RDLC;
    RDLCLayout = './FixedAssets/Reports/FixedAssetDetails.rdlc';
    ApplicationArea = FixedAssets;
    Caption = 'Fixed Asset Details';
    UsageCategory = ReportsAndAnalysis;
    WordMergeDataItem = "Fixed Asset";

    dataset
    {
        dataitem("Fixed Asset"; "Fixed Asset")
        {
            DataItemTableView = sorting("No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "FA Class Code", "FA Subclass Code", "Budgeted Asset", "FA Posting Date Filter";
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(DeprBookText; DeprBookText)
            {
            }
            column(Fixed_Asset__TABLECAPTION__________FAFilter; TableCaption + ': ' + FAFilter)
            {
            }
            column(FAFilter; FAFilter)
            {
            }
            column(PrintOnlyOnePerPage; PrintOnlyOnePerPage)
            {
            }
            column(Fixed_Asset__No__; "No.")
            {
            }
            column(Fixed_Asset_Description; Description)
            {
            }
            column(Fixed_Asset___DetailsCaption; Fixed_Asset___DetailsCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(FA_Ledger_Entry__FA_Posting_Date_Caption; FA_Ledger_Entry__FA_Posting_Date_CaptionLbl)
            {
            }
            column(FA_Ledger_Entry__Document_Type_Caption; "FA Ledger Entry".FieldCaption("Document Type"))
            {
            }
            column(FA_Ledger_Entry__Document_No__Caption; "FA Ledger Entry".FieldCaption("Document No."))
            {
            }
            column(FA_Ledger_Entry_DescriptionCaption; "FA Ledger Entry".FieldCaption(Description))
            {
            }
            column(FA_Ledger_Entry_AmountCaption; "FA Ledger Entry".FieldCaption(Amount))
            {
            }
            column(FA_Ledger_Entry__Entry_No__Caption; "FA Ledger Entry".FieldCaption("Entry No."))
            {
            }
            column(FA_Ledger_Entry__FA_Posting_Type_Caption; "FA Ledger Entry".FieldCaption("FA Posting Type"))
            {
            }
            column(FA_Ledger_Entry__No__of_Depreciation_Days_Caption; "FA Ledger Entry".FieldCaption("No. of Depreciation Days"))
            {
            }
            column(FA_Ledger_Entry__User_ID_Caption; "FA Ledger Entry".FieldCaption("User ID"))
            {
            }
            column(FA_Ledger_Entry__Posting_Date_Caption; FA_Ledger_Entry__Posting_Date_CaptionLbl)
            {
            }
            column(FA_Ledger_Entry__G_L_Entry_No__Caption; "FA Ledger Entry".FieldCaption("G/L Entry No."))
            {
            }
            column(FA_Ledger_Entry__FA_Posting_Category_Caption; "FA Ledger Entry".FieldCaption("FA Posting Category"))
            {
            }
            dataitem("FA Ledger Entry"; "FA Ledger Entry")
            {
                DataItemTableView = sorting("FA No.", "Depreciation Book Code", "FA Posting Date");
                column(FA_Ledger_Entry__FA_Posting_Date_; Format("FA Posting Date"))
                {
                }
                column(FA_Ledger_Entry__Document_Type_; "Document Type")
                {
                }
                column(FA_Ledger_Entry__Document_No__; "Document No.")
                {
                }
                column(FA_Ledger_Entry_Description; Description)
                {
                }
                column(FA_Ledger_Entry_Amount; Amount)
                {
                }
                column(FA_Ledger_Entry__Entry_No__; "Entry No.")
                {
                }
                column(FA_Ledger_Entry__FA_Posting_Type_; "FA Posting Type")
                {
                }
                column(FA_Ledger_Entry__No__of_Depreciation_Days_; "No. of Depreciation Days")
                {
                }
                column(FA_Ledger_Entry__User_ID_; "User ID")
                {
                }
                column(FA_Ledger_Entry__Posting_Date_; Format("Posting Date"))
                {
                }
                column(FA_Ledger_Entry__G_L_Entry_No__; "G/L Entry No.")
                {
                }
                column(FA_Ledger_Entry__FA_Posting_Category_; "FA Posting Category")
                {
                }

                trigger OnPreDataItem()
                begin
                    SetRange("FA No.", "Fixed Asset"."No.");
                    SetRange("Depreciation Book Code", DeprBookCode);
                    SetFilter("FA Posting Date", "Fixed Asset".GetFilter("FA Posting Date Filter"));
                    if not PrintReversedEntries then
                        SetRange(Reversed, false);
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
            end;
        }
    }

    requestpage
    {
        SaveValues = true;
        AboutTitle = 'About Fixed Asset Details';
        AboutText = 'The **Fixed Asset Details** report provides a comprehensive overview of all relevant information pertaining to each fixed asset owned by an organization. This report serves as a detailed transaction information and reference tool for asset management.';

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
                        AboutText = 'Choose the Depreciation Book and specify the applicable options against which details are to be seen in the report.';
                        ToolTip = 'Specifies the code for the depreciation book to be included in the report or batch job.';
                    }
                    field(NewPagePerAsset; PrintOnlyOnePerPage)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'New Page per Asset';
                        ToolTip = 'Specifies if you want each fixed asset printed on a new page.';
                    }
                    field(IncludeReversedEntries; PrintReversedEntries)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Include Reversed Entries';
                        ToolTip = 'Specifies if you want to include reversed fixed asset entries in the report.';
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
        DeprBook.Get(DeprBookCode);
        FAFilter := "Fixed Asset".GetFilters();
        DeprBookText := StrSubstNo('%1%2 %3', DeprBook.TableCaption(), ':', DeprBookCode);
    end;

    var
        FASetup: Record "FA Setup";
        DeprBook: Record "Depreciation Book";
        DeprBookCode: Code[10];
        DeprBookText: Text[50];
        PrintOnlyOnePerPage: Boolean;
        FAFilter: Text;
        PrintReversedEntries: Boolean;
        Fixed_Asset___DetailsCaptionLbl: Label 'Fixed Asset - Details';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        FA_Ledger_Entry__FA_Posting_Date_CaptionLbl: Label 'FA Posting Date';
        FA_Ledger_Entry__Posting_Date_CaptionLbl: Label 'Posting Date';

    procedure InitializeRequest(NewDeprBookCode: Code[10]; NewPrintOnlyOnePerPage: Boolean; NewPrintReversedEntries: Boolean)
    begin
        DeprBookCode := NewDeprBookCode;
        PrintOnlyOnePerPage := NewPrintOnlyOnePerPage;
        PrintReversedEntries := NewPrintReversedEntries;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFixedAssetOnAfterGetRecordOnAfterCalcShouldSkipAsset(FixedAsset: Record "Fixed Asset"; var ShouldSkipAsset: Boolean)
    begin
    end;
}

