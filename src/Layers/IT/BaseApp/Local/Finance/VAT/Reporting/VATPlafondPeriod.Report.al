// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.VAT.Setup;
using System.Utilities;

report 12182 "VAT Plafond Period"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Finance/VAT/Reporting/VATPlafondPeriod.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'VAT Plafond Period';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(VATPlafondPeriod; "VAT Plafond Period")
        {
            RequestFilterFields = Year;
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(Year_VATPlafondPeriod; Year)
            {
            }
            column(Amt_VATPlafondPeriod; Amount)
            {
            }
            column(VATPlafondPeriodCaption; VATPlafondPeriodCaptionLbl)
            {
            }
            column(PageNoCaption; PageCaptionLbl)
            {
            }
            column(YearCaption_VATPlafondPeriod; FieldCaption(Year))
            {
            }
            column(VATPlafondPeriodAmtCaption; PlafondAmtCaptionLbl)
            {
            }
            dataitem(Date; Date)
            {
                DataItemTableView = sorting("Period Type", "Period Start") where("Period Type" = const(Month));
                MaxIteration = 12;
                column(PeriodNameUpperCased; UpperCase("Period Name"))
                {
                }
                column(RemAmt; RemAmount)
                {
                }
                column(RemAmtUsedAmt; RemAmount - UsedAmount)
                {
                }
                column(NegUsedAmt; -UsedAmount)
                {
                }
                column(VATPlafondPeriodAmtUsedAmt; VATPlafondPeriod.Amount - UsedAmount)
                {
                }
                column(PeriodType_Date; "Period Type")
                {
                }
                column(PeriodStart_Date; "Period Start")
                {
                }
                column(PeriodNameUpperCasedCaption; MonthCaptionLbl)
                {
                }
                column(PreviousAmtCaption; PreviousAmtCaptionLbl)
                {
                }
                column(UsedAmtCaption; UsedAmtCaptionLbl)
                {
                }
                column(RemAmtUsedAmtCaption; RemAmtCaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    VATPlafondPeriod.CalcAmounts("Period Start", NormalDate("Period End"), UsedAmount, RemAmount);
                end;

                trigger OnPreDataItem()
                begin
                    SetRange("Period Start", DMY2Date(1, 1, VATPlafondPeriod.Year), DMY2Date(31, 12, VATPlafondPeriod.Year));
                    Clear(UsedAmount);
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

    var
        UsedAmount: Decimal;
        RemAmount: Decimal;
        VATPlafondPeriodCaptionLbl: Label 'VAT Plafond Period';
        PageCaptionLbl: Label 'Page';
        PlafondAmtCaptionLbl: Label 'Plafond Amount';
        MonthCaptionLbl: Label 'Month';
        PreviousAmtCaptionLbl: Label 'Previous Amount';
        UsedAmtCaptionLbl: Label 'Used Amount';
        RemAmtCaptionLbl: Label 'Remaining Amount';
}

