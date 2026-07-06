// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Insurance;

using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Setup;

report 5625 "Insurance - Tot. Value Insured"
{
    DefaultLayout = RDLC;
    RDLCLayout = './FixedAssets/Insurance/InsuranceTotValueInsured.rdlc';
    ApplicationArea = FixedAssets;
    Caption = 'Fixed Asset Total Value Insured';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Fixed Asset"; "Fixed Asset")
        {
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "FA Class Code", "FA Subclass Code";
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(Fixed_Asset__TABLECAPTION__________FAFilter; TableCaption + ': ' + FAFilter)
            {
            }
            column(FAFilter; FAFilter)
            {
            }
            column(FAFieldname; FAFieldname)
            {
            }
            column(InsuranceDescription; InsuranceDescription)
            {
            }
            column(TotalValueInsured; TotalValueInsured)
            {
            }
            column(Insurance___Tot__Value_InsuredCaption; Insurance___Tot__Value_InsuredCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Ins__Coverage_Ledger_Entry__Insurance_No__Caption; "Ins. Coverage Ledger Entry".FieldCaption("Insurance No."))
            {
            }
            column(Fixed_Asset__DescriptionCaption; FieldCaption(Description))
            {
            }
            dataitem("Ins. Coverage Ledger Entry"; "Ins. Coverage Ledger Entry")
            {
                DataItemTableView = sorting("FA No.", "Insurance No.", "Disposed FA");
                column(Ins__Coverage_Ledger_Entry__Insurance_No__; "Insurance No.")
                {
                }
                column(Insurance_Description; Insurance.Description)
                {
                }
                column(Insurance__Total_Value_Insured_; Insurance."Total Value Insured")
                {
                }
                column(FANo; FANo)
                {
                }
                column(Fixed_Asset__Description; "Fixed Asset".Description)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if Insurance.Get("Insurance No.") then;
                    TempInsurance."No." := "Insurance No.";
                    if TempInsurance.Insert() then begin
                        InsCoverageLedgEntry.SetRange("Insurance No.", "Insurance No.");
                        InsCoverageLedgEntry.CalcSums(Amount);
                        if InsCoverageLedgEntry.Amount = 0 then
                            CurrReport.Skip();
                        Insurance."Total Value Insured" := InsCoverageLedgEntry.Amount;
                    end else
                        CurrReport.Skip();
                    if not FirstTime then begin
                        "Fixed Asset".Description := '';
                        FANo := '';
                    end;
                    FirstTime := false;
                end;

                trigger OnPreDataItem()
                begin
                    SetRange("FA No.", "Fixed Asset"."No.");
                    InsCoverageLedgEntry.SetRange("FA No.", "Fixed Asset"."No.");
                    TempInsurance.DeleteAll();
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if not FADeprBook.Get("No.", DeprBook.Code) then
                    CurrReport.Skip();
                if (FADeprBook."Disposal Date" > 0D) or Inactive then
                    CurrReport.Skip();
                FirstTime := true;
                FANo := "No.";
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

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
        FAFilter := "Fixed Asset".GetFilters();
        FASetup.Get();
        FASetup.TestField("Insurance Depr. Book");
        DeprBook.Get(FASetup."Insurance Depr. Book");
        FAFieldname := "Fixed Asset".FieldCaption("No.");
        InsuranceDescription := Insurance.FieldCaption(Description);
        TotalValueInsured := Insurance.FieldCaption("Total Value Insured");
        InsCoverageLedgEntry.SetCurrentKey("FA No.", "Insurance No.", "Disposed FA");
        InsCoverageLedgEntry.SetRange("Disposed FA", false);
    end;

    var
        FASetup: Record "FA Setup";
        DeprBook: Record "Depreciation Book";
        FADeprBook: Record "FA Depreciation Book";
        Insurance: Record Insurance;
        TempInsurance: Record Insurance temporary;
        InsCoverageLedgEntry: Record "Ins. Coverage Ledger Entry";
        FAFilter: Text;
        FANo: Code[20];
        FAFieldname: Text[100];
        InsuranceDescription: Text[100];
        TotalValueInsured: Text[80];
        FirstTime: Boolean;
        Insurance___Tot__Value_InsuredCaptionLbl: Label 'Insurance - Tot. Value Insured';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
}

