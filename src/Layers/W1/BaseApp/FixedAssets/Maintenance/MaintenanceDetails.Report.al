// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Maintenance;

using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Setup;

report 5634 "Maintenance - Details"
{
    DefaultLayout = RDLC;
    RDLCLayout = './FixedAssets/Maintenance/MaintenanceDetails.rdlc';
    ApplicationArea = FixedAssets;
    Caption = 'Fixed Asset Maintenance Details';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Fixed Asset"; "Fixed Asset")
        {
            DataItemTableView = sorting("No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "FA Class Code", "FA Subclass Code", "FA Posting Date Filter";
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
            column(GroupCounter; GroupCounter)
            {
            }
            column(Fixed_Asset__No__; "No.")
            {
            }
            column(Fixed_Asset_Description; Description)
            {
            }
            column(Maintenance___DetailsCaption; Maintenance___DetailsCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Maintenance_Ledger_Entry__FA_Posting_Date_Caption; Maintenance_Ledger_Entry__FA_Posting_Date_CaptionLbl)
            {
            }
            column(Maintenance_Ledger_Entry__Document_Type_Caption; "Maintenance Ledger Entry".FieldCaption("Document Type"))
            {
            }
            column(Maintenance_Ledger_Entry__Document_No__Caption; "Maintenance Ledger Entry".FieldCaption("Document No."))
            {
            }
            column(Maintenance_Ledger_Entry_DescriptionCaption; "Maintenance Ledger Entry".FieldCaption(Description))
            {
            }
            column(Maintenance_Ledger_Entry_AmountCaption; "Maintenance Ledger Entry".FieldCaption(Amount))
            {
            }
            column(Maintenance_Ledger_Entry__Entry_No__Caption; "Maintenance Ledger Entry".FieldCaption("Entry No."))
            {
            }
            column(Maintenance_Ledger_Entry__User_ID_Caption; "Maintenance Ledger Entry".FieldCaption("User ID"))
            {
            }
            column(Maintenance_Ledger_Entry__Posting_Date_Caption; Maintenance_Ledger_Entry__Posting_Date_CaptionLbl)
            {
            }
            column(Maintenance_Ledger_Entry__G_L_Entry_No__Caption; "Maintenance Ledger Entry".FieldCaption("G/L Entry No."))
            {
            }
            column(Maintenance_Ledger_Entry__Maintenance_Code_Caption; "Maintenance Ledger Entry".FieldCaption("Maintenance Code"))
            {
            }
            dataitem("Maintenance Ledger Entry"; "Maintenance Ledger Entry")
            {
                DataItemTableView = sorting("FA No.", "Depreciation Book Code", "FA Posting Date");
                column(Maintenance_Ledger_Entry__FA_Posting_Date_; Format("FA Posting Date"))
                {
                }
                column(Maintenance_Ledger_Entry__Document_Type_; "Document Type")
                {
                }
                column(Maintenance_Ledger_Entry__Document_No__; "Document No.")
                {
                }
                column(Maintenance_Ledger_Entry_Description; Description)
                {
                }
                column(Maintenance_Ledger_Entry_Amount; Amount)
                {
                }
                column(Maintenance_Ledger_Entry__Entry_No__; "Entry No.")
                {
                }
                column(Maintenance_Ledger_Entry__User_ID_; "User ID")
                {
                }
                column(Maintenance_Ledger_Entry__Posting_Date_; Format("Posting Date"))
                {
                }
                column(Maintenance_Ledger_Entry__G_L_Entry_No__; "G/L Entry No.")
                {
                }
                column(Maintenance_Ledger_Entry__Maintenance_Code_; "Maintenance Code")
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
            begin
                if Inactive then
                    CurrReport.Skip();

                if PrintOnlyOnePerPage then
                    GroupCounter += 1;
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
                        TableRelation = "Depreciation Book";
                        ToolTip = 'Specifies the code for the depreciation book to be included in the report or batch job.';
                    }
                    field(NewPagePerFA; PrintOnlyOnePerPage)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'New Page per FA';
                        ToolTip = 'Specifies if you want the report to print data for each fixed asset on a separate page.';
                    }
                    field(IncludeReversedEntries; PrintReversedEntries)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Include Reversed Entries';
                        ToolTip = 'Specifies if you want to include reversed entries in the report.';
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
        GroupCounter := 0;
    end;

    var
        FASetup: Record "FA Setup";
        DeprBook: Record "Depreciation Book";
        DeprBookCode: Code[10];
        DeprBookText: Text[50];
        PrintOnlyOnePerPage: Boolean;
        FAFilter: Text;
        PrintReversedEntries: Boolean;
        GroupCounter: Integer;
        Maintenance___DetailsCaptionLbl: Label 'Maintenance - Details';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Maintenance_Ledger_Entry__FA_Posting_Date_CaptionLbl: Label 'FA Posting Date';
        Maintenance_Ledger_Entry__Posting_Date_CaptionLbl: Label 'Posting Date';

    procedure InitializeRequest(NewDeprBookCode: Code[10]; NewPrintOnlyOnePerPage: Boolean; NewPrintReversedEntries: Boolean)
    begin
        DeprBookCode := NewDeprBookCode;
        PrintOnlyOnePerPage := NewPrintOnlyOnePerPage;
        PrintReversedEntries := NewPrintReversedEntries;
    end;
}

