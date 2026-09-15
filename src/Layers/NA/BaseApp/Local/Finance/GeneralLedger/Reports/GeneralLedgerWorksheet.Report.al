// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Reports;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Company;

report 10018 "General Ledger Worksheet"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Finance/GeneralLedger/Reports/GeneralLedgerWorksheet.rdlc';
    ApplicationArea = Suite;
    Caption = 'General Ledger Worksheet';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("G/L Account"; "G/L Account")
        {
            DataItemTableView = sorting("No.") where("Account Type" = const(Posting));
            RequestFilterFields = "No.", "Date Filter";
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(TIME; Time)
            {
            }
            column(CompanyInformation_Name; CompanyInformation.Name)
            {
            }
            column(USERID; UserId)
            {
            }
            column(UseAddRptCurr; UseAddRptCurr)
            {
            }
            column(GLFilter; GLFilter)
            {
            }
            column(SubTitle; SubTitle)
            {
            }
            column(G_L_Account__TABLECAPTION__________GLFilter; "G/L Account".TableCaption + ': ' + GLFilter)
            {
            }
            column(G_L_Account__No__; "No.")
            {
            }
            column(G_L_Account_Name; Name)
            {
            }
            column(G_L_Account__Balance_at_Date_; "Balance at Date")
            {
            }
            column(Balance_at_Date_; -"Balance at Date")
            {
            }
            column(EmptyString; '')
            {
            }
            column(EmptyString_Control12; '')
            {
            }
            column(EmptyString_Control14; '')
            {
            }
            column(EmptyString_Control16; '')
            {
            }
            column(TotalDebits; TotalDebits)
            {
            }
            column(TotalCredits; TotalCredits)
            {
            }
            column(General_Ledger_WorksheetCaption; General_Ledger_WorksheetCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(G_L_Account__No__Caption; FieldCaption("No."))
            {
            }
            column(G_L_Account_NameCaption; FieldCaption(Name))
            {
            }
            column(G_L_Account__Balance_at_Date_Caption; G_L_Account__Balance_at_Date_CaptionLbl)
            {
            }
            column(Balance_at_Date_Caption; Balance_at_Date_CaptionLbl)
            {
            }
            column(EmptyStringCaption; EmptyStringCaptionLbl)
            {
            }
            column(EmptyString_Control12Caption; EmptyString_Control12CaptionLbl)
            {
            }
            column(EmptyString_Control14Caption; EmptyString_Control14CaptionLbl)
            {
            }
            column(EmptyString_Control16Caption; EmptyString_Control16CaptionLbl)
            {
            }
            column(Report_TotalCaption; Report_TotalCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                if UseAddRptCurr then begin
                    CalcFields("Add.-Currency Balance at Date");
                    "Balance at Date" := "Add.-Currency Balance at Date";
                end else
                    CalcFields("Balance at Date");
                if "Balance at Date" > 0 then
                    TotalDebits := TotalDebits + "Balance at Date"
                else
                    TotalCredits := TotalCredits - "Balance at Date";
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(UseAdditionalReportingCurrency; UseAddRptCurr)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Use Additional Reporting Currency';
                        MultiLine = true;
                        ToolTip = 'Specifies if you want all amounts to be printed by using the additional reporting currency. If you do not select the check box, then all amounts will be printed in US dollars.';
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
        CompanyInformation.Get();
        GLFilter := "G/L Account".GetFilters();
        TotalDebits := 0;
        TotalCredits := 0;
        if UseAddRptCurr then begin
            GLSetup.Get();
            Currency.Get(GLSetup."Additional Reporting Currency");
            SubTitle := StrSubstNo(Text000, Currency.Description);
        end;
    end;

    var
        CompanyInformation: Record "Company Information";
        GLSetup: Record "General Ledger Setup";
        Currency: Record Currency;
        GLFilter: Text;
        SubTitle: Text[132];
        TotalDebits: Decimal;
        TotalCredits: Decimal;
        UseAddRptCurr: Boolean;
        Text000: Label 'Amounts are in %1';
        General_Ledger_WorksheetCaptionLbl: Label 'General Ledger Worksheet';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        G_L_Account__Balance_at_Date_CaptionLbl: Label 'Trial Balance Debit';
        Balance_at_Date_CaptionLbl: Label 'Trial Balance Credit';
        EmptyStringCaptionLbl: Label 'Debit Adjustments';
        EmptyString_Control12CaptionLbl: Label 'Credit Adjustments';
        EmptyString_Control14CaptionLbl: Label 'Adjusted Trial Balance Debit';
        EmptyString_Control16CaptionLbl: Label 'Adjusted Trial Balance Credit';
        Report_TotalCaptionLbl: Label 'Report Total';
}

