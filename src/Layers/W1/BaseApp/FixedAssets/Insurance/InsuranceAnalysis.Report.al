// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Insurance;

report 5620 "Insurance - Analysis"
{
    DefaultLayout = RDLC;
    RDLCLayout = './FixedAssets/Insurance/InsuranceAnalysis.rdlc';
    ApplicationArea = FixedAssets;
    Caption = 'Fixed Asset Insurance Analysis';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Insurance; Insurance)
        {
            RequestFilterFields = "No.", "FA Class Code", "FA Subclass Code";
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(Insurance_TABLECAPTION___________InsuranceFilter; TableCaption + ': ' + InsuranceFilter)
            {
            }
            column(InsuranceFilter; InsuranceFilter)
            {
            }
            column(Insurance__No__; "No.")
            {
            }
            column(Insurance_Description; Description)
            {
            }
            column(Insurance__Annual_Premium_; "Annual Premium")
            {
            }
            column(Insurance__Policy_Coverage_; "Policy Coverage")
            {
            }
            column(Insurance__Total_Value_Insured_; "Total Value Insured")
            {
            }
            column(OverUnderInsured; OverUnderInsured)
            {
                AutoFormatType = 1;
            }
            column(UnderInsured; UnderInsured)
            {
            }
            column(PrintDetails; PrintDetails)
            {
            }
            column(TotalAmounts_1_; TotalAmounts[1])
            {
                AutoFormatType = 1;
            }
            column(TotalAmounts_2_; TotalAmounts[2])
            {
                AutoFormatType = 1;
            }
            column(TotalAmounts_3_; TotalAmounts[3])
            {
                AutoFormatType = 1;
            }
            column(TotalAmounts_4_; TotalAmounts[4])
            {
                AutoFormatType = 1;
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Insurance___AnalysisCaption; Insurance___AnalysisCaptionLbl)
            {
            }
            column(Insurance__No__Caption; FieldCaption("No."))
            {
            }
            column(Insurance_DescriptionCaption; FieldCaption(Description))
            {
            }
            column(Insurance__Annual_Premium_Caption; FieldCaption("Annual Premium"))
            {
            }
            column(Insurance__Policy_Coverage_Caption; FieldCaption("Policy Coverage"))
            {
            }
            column(Insurance__Total_Value_Insured_Caption; FieldCaption("Total Value Insured"))
            {
            }
            column(OverUnderInsuredCaption; OverUnderInsuredCaptionLbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                OverUnderInsured := "Policy Coverage" - "Total Value Insured";
                if OverUnderInsured < 0
                then
                    UnderInsured := Text000
                else
                    UnderInsured := '';
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
                    field(PrintDetails; PrintDetails)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Print per Insurance No.';
                        ToolTip = 'Specifies if you want the report to show amounts for each insurance policy.';
                    }
                }
            }
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
        InsuranceFilter := Insurance.GetFilters();
    end;

    var
#pragma warning disable AA0074
        Text000: Label 'U';
#pragma warning restore AA0074
        InsuranceFilter: Text;
        OverUnderInsured: Decimal;
        TotalAmounts: array[4] of Decimal;
        PrintDetails: Boolean;
        UnderInsured: Text[5];
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Insurance___AnalysisCaptionLbl: Label 'Insurance - Analysis';
        OverUnderInsuredCaptionLbl: Label 'Over-/Underinsured';
        TotalCaptionLbl: Label 'Total';

    procedure InitializeRequest(PrintDetailsFrom: Boolean)
    begin
        PrintDetails := PrintDetailsFrom;
    end;
}

