// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Foundation.Company;

report 10004 "Account Balances by GIFI Code"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Finance/Analysis/AccountBalancesbyGIFICode.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Account Balances by GIFI Code';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("G/L Account"; "G/L Account")
        {
            CalcFields = "Balance at Date", "Add.-Currency Balance at Date";
            DataItemTableView = sorting("GIFI Code") where("GIFI Code" = filter(<> ''));
            RequestFilterFields = "GIFI Code";
            column(Subtitle; Subtitle)
            {
            }
            column(CompanyInfoName; CompanyInformation.Name)
            {
            }
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(TblCaptionFilterString; TableCaption + ': ' + FilterString)
            {
            }
            column(AccountFilters; FilterString)
            {
            }
            column(GIFICode_GLAccount; "GIFI Code")
            {
            }
            column(GIFICodeName; GIFICode.Name)
            {
            }
            column(No_GLAccount; "No.")
            {
            }
            column(Name_GLAccount; Name)
            {
            }
            column(BalAtDate_GLAccount; "Balance at Date")
            {
            }
            column(AddCurrBalAtDate_GLAccount; "Add.-Currency Balance at Date")
            {
            }
            column(PrintDetails; PrintDetails)
            {
            }
            column(AccountBalByGIFICodeCaption; AccountBalancesbyGIFICodeCaptionLbl)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(GIFICodeCaption_GLAccount; FieldCaption("GIFI Code"))
            {
            }
            column(NameCaption; NameCaptionLbl)
            {
            }
            column(GLAccountBalAtDateCaption; CaptionClassTranslate('101,0,' + Text002))
            {
            }
            column(GLAccountAddCurrBalAtDateCaption; CaptionClassTranslate('101,2,' + Text002))
            {
            }
            column(GLAccountNoCaption; GLAccountNoCaptionLbl)
            {
            }
            column(NameCaption_GLAccount; FieldCaption(Name))
            {
            }

            trigger OnAfterGetRecord()
            begin
                if ("Balance at Date" = 0) and ("Add.-Currency Balance at Date" = 0) then
                    CurrReport.Skip();
                if "GIFI Code" <> GIFICode.Code then
                    GIFICode.Get("GIFI Code");
            end;

            trigger OnPreDataItem()
            begin
                SetRange("Date Filter", 0D, AsOfDate);
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
                    field(BalanceAsOfDate; AsOfDate)
                    {
                        ApplicationArea = BasicCA;
                        Caption = 'Balance As Of Date';
                        ToolTip = 'Specifies, in MMDDYY format, the date that the financial information will be based on. The financial information will be based on the account balances as of this date.';
                    }
                    field(PrintDetails; PrintDetails)
                    {
                        ApplicationArea = BasicCA;
                        Caption = 'Print Details';
                        ToolTip = 'Specifies if you want to see the individual G/L Account balances that make up the total for each GIFI code balance that is reported. Otherwise, only the GIFI code balances will be reported.';
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
        FilterString := "G/L Account".GetFilters();
        if AsOfDate = 0D then
            Error(Text001);

        Subtitle := StrSubstNo(Text000, AsOfDate);
    end;

    var
        CompanyInformation: Record "Company Information";
        GIFICode: Record "GIFI Code";
        AsOfDate: Date;
        PrintDetails: Boolean;
        FilterString: Text;
        Text000: Label 'As Of %1';
        Subtitle: Text[30];
        Text001: Label 'You must enter an As Of Date.';
        Text002: Label 'Balance at Date (%1)';
        AccountBalancesbyGIFICodeCaptionLbl: Label 'Account Balances by GIFI Code';
        PageCaptionLbl: Label 'Page';
        NameCaptionLbl: Label 'Name';
        GLAccountNoCaptionLbl: Label 'G/L Account No.';
}

