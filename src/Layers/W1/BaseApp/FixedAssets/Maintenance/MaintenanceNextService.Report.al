// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Maintenance;

using Microsoft.FixedAssets.FixedAsset;

report 5635 "Maintenance - Next Service"
{
    DefaultLayout = RDLC;
    RDLCLayout = './FixedAssets/Maintenance/MaintenanceNextService.rdlc';
    ApplicationArea = FixedAssets;
    Caption = 'Fixed Asset Maintenance Next Service';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Fixed Asset"; "Fixed Asset")
        {
            PrintOnlyIfDetail = false;
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
            column(Fixed_Asset__No__; "No.")
            {
            }
            column(Fixed_Asset_Description; Description)
            {
            }
            column(Fixed_Asset__Next_Service_Date_; Format("Next Service Date"))
            {
            }
            column(Maintenance___Next_ServiceCaption; Maintenance___Next_ServiceCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Fixed_Asset__No__Caption; FieldCaption("No."))
            {
            }
            column(Fixed_Asset_DescriptionCaption; FieldCaption(Description))
            {
            }
            column(Fixed_Asset__Next_Service_Date_Caption; Fixed_Asset__Next_Service_Date_CaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                if "Budgeted Asset" or Inactive or ("Next Service Date" = 0D) then
                    CurrReport.Skip();
                if (StartingDate > 0D) or (EndingDate > 0D) then begin
                    if (StartingDate > 0D) and ("Next Service Date" < StartingDate) then
                        CurrReport.Skip();
                    if (EndingDate > 0D) and ("Next Service Date" > EndingDate) then
                        CurrReport.Skip();
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
                    field(StartingDate; StartingDate)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the first date to be included in the report. Fixed assets that have a next service date before the date in this field will not be included.';
                    }
                    field(EndingDate; EndingDate)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Ending Date';
                        ToolTip = 'Specifies the last date to be included in the report. Fixed assets that have a next service date after the date in this field will not be included.';
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
        if (EndingDate > 0D) and (StartingDate > EndingDate) then
            Error(Text000);

        FAGenReport.AppendFAPostingFilter("Fixed Asset", StartingDate, EndingDate);
        FAFilter := "Fixed Asset".GetFilters();
    end;

    var
#pragma warning disable AA0074
        Text000: Label 'The Starting Date is later than the Ending Date.';
#pragma warning restore AA0074
        FAGenReport: Codeunit "FA General Report";
        StartingDate: Date;
        EndingDate: Date;
        FAFilter: Text;
        Maintenance___Next_ServiceCaptionLbl: Label 'Maintenance - Next Service';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Fixed_Asset__Next_Service_Date_CaptionLbl: Label 'Next Service Date';

    procedure InitializeRequest(StartingDateFrom: Date; EndingDateFrom: Date)
    begin
        StartingDate := StartingDateFrom;
        EndingDate := EndingDateFrom;
    end;
}

