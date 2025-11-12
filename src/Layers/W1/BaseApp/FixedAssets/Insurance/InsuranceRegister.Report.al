// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Insurance;

using Microsoft.FixedAssets.FixedAsset;

report 5623 "Insurance Register"
{
    DefaultLayout = RDLC;
    RDLCLayout = './FixedAssets/Insurance/InsuranceRegister.rdlc';
    ApplicationArea = FixedAssets;
    Caption = 'Insurance Register';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Insurance Register"; "Insurance Register")
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
            column(Insurance_Register__TABLECAPTION__________InsuranceRegFilter; TableCaption + ': ' + InsuranceRegFilter)
            {
            }
            column(InsuranceRegFilter; InsuranceRegFilter)
            {
            }
            column(Insurance_Register__No__; "No.")
            {
            }
            column(Ins__Coverage_Ledger_Entry__Amount; "Ins. Coverage Ledger Entry".Amount)
            {
            }
            column(Insurance_RegisterCaption; Insurance_RegisterCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Ins__Coverage_Ledger_Entry_DescriptionCaption; "Ins. Coverage Ledger Entry".FieldCaption(Description))
            {
            }
            column(Ins__Coverage_Ledger_Entry__Document_No__Caption; "Ins. Coverage Ledger Entry".FieldCaption("Document No."))
            {
            }
            column(Ins__Coverage_Ledger_Entry__Document_Type_Caption; "Ins. Coverage Ledger Entry".FieldCaption("Document Type"))
            {
            }
            column(Ins__Coverage_Ledger_Entry__Posting_Date_Caption; Ins__Coverage_Ledger_Entry__Posting_Date_CaptionLbl)
            {
            }
            column(Ins__Coverage_Ledger_Entry_AmountCaption; "Ins. Coverage Ledger Entry".FieldCaption(Amount))
            {
            }
            column(Ins__Coverage_Ledger_Entry__Entry_No__Caption; "Ins. Coverage Ledger Entry".FieldCaption("Entry No."))
            {
            }
            column(Ins__Coverage_Ledger_Entry__Insurance_No__Caption; "Ins. Coverage Ledger Entry".FieldCaption("Insurance No."))
            {
            }
            column(Insurance_DescriptionCaption; Insurance_DescriptionCaptionLbl)
            {
            }
            column(Ins__Coverage_Ledger_Entry__FA_No__Caption; "Ins. Coverage Ledger Entry".FieldCaption("FA No."))
            {
            }
            column(FA_DescriptionCaption; FA_DescriptionCaptionLbl)
            {
            }
            column(Insurance_Register__No__Caption; Insurance_Register__No__CaptionLbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }
            dataitem("Ins. Coverage Ledger Entry"; "Ins. Coverage Ledger Entry")
            {
                DataItemTableView = sorting("Entry No.");
                column(Ins__Coverage_Ledger_Entry__Posting_Date_; Format("Posting Date"))
                {
                }
                column(Ins__Coverage_Ledger_Entry__Document_Type_; "Document Type")
                {
                }
                column(Ins__Coverage_Ledger_Entry__Document_No__; "Document No.")
                {
                }
                column(Ins__Coverage_Ledger_Entry__FA_No__; "FA No.")
                {
                }
                column(FA_Description; FA.Description)
                {
                }
                column(Ins__Coverage_Ledger_Entry_Description; Description)
                {
                }
                column(Ins__Coverage_Ledger_Entry_Amount; Amount)
                {
                }
                column(Ins__Coverage_Ledger_Entry__Entry_No__; "Entry No.")
                {
                }
                column(Ins__Coverage_Ledger_Entry__Insurance_No__; "Insurance No.")
                {
                }
                column(Insurance_Description; Insurance.Description)
                {
                }
                column(Ins__Coverage_Ledger_Entry_Amount_Control33; Amount)
                {
                }
                column(InsuranceAmountTotal; InsuranceAmountTotal)
                {
                }
                column(TotalCaption_Control32; TotalCaption_Control32Lbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if not FA.Get("FA No.") then
                        FA.Init();
                    if not Insurance.Get("Insurance No.") then
                        Insurance.Init();
                    InsuranceAmountTotal := InsuranceAmountTotal + Amount;
                end;

                trigger OnPreDataItem()
                begin
                    SetRange(
                      "Entry No.", "Insurance Register"."From Entry No.", "Insurance Register"."To Entry No.");
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
        InsuranceRegFilter := "Insurance Register".GetFilters();
    end;

    var
        FA: Record "Fixed Asset";
        Insurance: Record Insurance;
        InsuranceRegFilter: Text;
        InsuranceAmountTotal: Decimal;
        Insurance_RegisterCaptionLbl: Label 'Insurance Register';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Ins__Coverage_Ledger_Entry__Posting_Date_CaptionLbl: Label 'Posting Date';
        Insurance_DescriptionCaptionLbl: Label 'Insurance Description';
        FA_DescriptionCaptionLbl: Label 'FA Description';
        Insurance_Register__No__CaptionLbl: Label 'Register No.';
        TotalCaptionLbl: Label 'Total';
        TotalCaption_Control32Lbl: Label 'Total';
}

