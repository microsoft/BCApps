// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Maintenance;

using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Ledger;

report 5633 "Maintenance Register"
{
    DefaultLayout = RDLC;
    RDLCLayout = './FixedAssets/Maintenance/MaintenanceRegister.rdlc';
    ApplicationArea = FixedAssets;
    Caption = 'Maintenance Register';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("FA Register"; "FA Register")
        {
            DataItemTableView = sorting("No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.";
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(FA_Register__TABLECAPTION__________MaintenanceRegFilter; TableCaption + ': ' + MaintenanceRegFilter)
            {
            }
            column(MaintenanceRegFilter; MaintenanceRegFilter)
            {
            }
            column(FA_Register__No__; "No.")
            {
            }
            column(Maintenance_Ledger_Entry__Amount; "Maintenance Ledger Entry".Amount)
            {
            }
            column(Maintenance_RegisterCaption; Maintenance_RegisterCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Maintenance_Ledger_Entry_DescriptionCaption; "Maintenance Ledger Entry".FieldCaption(Description))
            {
            }
            column(Maintenance_Ledger_Entry__FA_No__Caption; "Maintenance Ledger Entry".FieldCaption("FA No."))
            {
            }
            column(Maintenance_Ledger_Entry__Document_No__Caption; "Maintenance Ledger Entry".FieldCaption("Document No."))
            {
            }
            column(Maintenance_Ledger_Entry__Document_Type_Caption; "Maintenance Ledger Entry".FieldCaption("Document Type"))
            {
            }
            column(Maintenance_Ledger_Entry__FA_Posting_Date_Caption; Maintenance_Ledger_Entry__FA_Posting_Date_CaptionLbl)
            {
            }
            column(Maintenance_Ledger_Entry__Depreciation_Book_Code_Caption; "Maintenance Ledger Entry".FieldCaption("Depreciation Book Code"))
            {
            }
            column(Maintenance_Ledger_Entry__Maintenance_Code_Caption; "Maintenance Ledger Entry".FieldCaption("Maintenance Code"))
            {
            }
            column(Maintenance_Ledger_Entry_AmountCaption; "Maintenance Ledger Entry".FieldCaption(Amount))
            {
            }
            column(Maintenance_Ledger_Entry__Entry_No__Caption; "Maintenance Ledger Entry".FieldCaption("Entry No."))
            {
            }
            column(FA_DescriptionCaption; FA_DescriptionCaptionLbl)
            {
            }
            column(Maintenance_Ledger_Entry__Posting_Date_Caption; Maintenance_Ledger_Entry__Posting_Date_CaptionLbl)
            {
            }
            column(Maintenance_Ledger_Entry__G_L_Entry_No__Caption; "Maintenance Ledger Entry".FieldCaption("G/L Entry No."))
            {
            }
            column(FA_Register__No__Caption; FA_Register__No__CaptionLbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }
            dataitem("Maintenance Ledger Entry"; "Maintenance Ledger Entry")
            {
                DataItemTableView = sorting("Entry No.");
                column(Maintenance_Ledger_Entry__FA_Posting_Date_; Format("FA Posting Date"))
                {
                }
                column(Maintenance_Ledger_Entry__Posting_Date_; Format("Posting Date"))
                {
                }
                column(Maintenance_Ledger_Entry__Document_Type_; "Document Type")
                {
                }
                column(Maintenance_Ledger_Entry__Document_No__; "Document No.")
                {
                }
                column(Maintenance_Ledger_Entry__FA_No__; "FA No.")
                {
                }
                column(FA_Description; FA.Description)
                {
                }
                column(Maintenance_Ledger_Entry_Description; Description)
                {
                }
                column(Maintenance_Ledger_Entry__Depreciation_Book_Code_; "Depreciation Book Code")
                {
                }
                column(Maintenance_Ledger_Entry__Maintenance_Code_; "Maintenance Code")
                {
                }
                column(Maintenance_Ledger_Entry_Amount; Amount)
                {
                }
                column(Maintenance_Ledger_Entry__Entry_No__; "Entry No.")
                {
                }
                column(Maintenance_Ledger_Entry__G_L_Entry_No__; "G/L Entry No.")
                {
                }
                column(MaintenanceAmountTotal; MaintenanceAmountTotal)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if not FA.Get("FA No.") then
                        FA.Init();
                    MaintenanceAmountTotal += Amount;
                end;

                trigger OnPreDataItem()
                begin
                    SetRange(
                      "Entry No.", "FA Register"."From Maintenance Entry No.",
                      "FA Register"."To Maintenance Entry No.");
                    Clear(Amount);
                end;
            }
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        MaintenanceRegFilter := "FA Register".GetFilters();
    end;

    var
        FA: Record "Fixed Asset";
        MaintenanceRegFilter: Text;
        MaintenanceAmountTotal: Decimal;
        Maintenance_RegisterCaptionLbl: Label 'Maintenance Register';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Maintenance_Ledger_Entry__FA_Posting_Date_CaptionLbl: Label 'FA Posting Date';
        FA_DescriptionCaptionLbl: Label 'FA Description';
        Maintenance_Ledger_Entry__Posting_Date_CaptionLbl: Label 'Posting Date';
        FA_Register__No__CaptionLbl: Label 'Register No.';
        TotalCaptionLbl: Label 'Total';
}

