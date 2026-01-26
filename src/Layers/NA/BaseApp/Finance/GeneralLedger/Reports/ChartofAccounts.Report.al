// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Reports;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Foundation.Company;
using System.Utilities;

/// <summary>
/// Generates comprehensive chart of accounts report displaying account structure and balances.
/// Provides hierarchical view of G/L accounts with account types, names, and current balance information.
/// </summary>
/// <remarks>
/// Data source: G/L Account table with sorting by account number and account type filtering.
/// Output format: RDLC layout supporting account hierarchy display with indentation and balance calculations.
/// Includes options for filtering by account number ranges and account types for customized reporting.
/// </remarks>
report 10002 "Chart of Accounts"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Finance/GeneralLedger/Reports/ChartofAccounts.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Chart of Accounts';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("G/L Account"; "G/L Account")
        {
            DataItemTableView = sorting("No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Account Type";
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
            column(G_L_Account__TABLECAPTION__________GLFilter; "G/L Account".TableCaption + ': ' + GLFilter)
            {
            }
            column(GLFilter; GLFilter)
            {
            }
            column(G_L_Account_No_; "No.")
            {
            }
            column(Chart_of_AccountsCaption; Chart_of_AccountsCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(G_L_Account___No__Caption; FieldCaption("No."))
            {
            }
            column(PADSTR_____G_L_Account__Indentation___2___G_L_Account__NameCaption; PADSTR_____G_L_Account__Indentation___2___G_L_Account__NameCaptionLbl)
            {
            }
            column(G_L_Account___Account_Type_Caption; FieldCaption("Account Type"))
            {
            }
            column(G_L_Account__TotalingCaption; FieldCaption(Totaling))
            {
            }
            column(G_L_Account___Balance_at_Date_Caption; FieldCaption("Balance at Date"))
            {
            }
            column(G_L_Account___GIFI_Code_Caption; FieldCaption("GIFI Code"))
            {
            }
            dataitem(BlankLineCounter; "Integer")
            {
                DataItemTableView = sorting(Number);

                trigger OnPreDataItem()
                begin
                    SetRange(Number, 1, "G/L Account"."No. of Blank Lines");
                    CurrReport.Break();
                end;
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(G_L_Account___No__; "G/L Account"."No.")
                {
                }
                column(PADSTR_____G_L_Account__Indentation___2___G_L_Account__Name; PadStr('', "G/L Account".Indentation * 2) + "G/L Account".Name)
                {
                }
                column(G_L_Account___Account_Type_; "G/L Account"."Account Type")
                {
                }
                column(G_L_Account__Totaling; "G/L Account".Totaling)
                {
                }
                column(G_L_Account___Balance_at_Date_; "G/L Account"."Balance at Date")
                {
                }
                column(G_L_Account___GIFI_Code_; "G/L Account"."GIFI Code")
                {
                }
                column(PageGroupNo; PageGroupNo)
                {
                }
                column(AccountType; "G/L Account"."Account Type")
                {
                }
                column(NoOfBlankLines; "G/L Account"."No. of Blank Lines")
                {
                }
                column(OptionPosting; GLAccPosting."Account Type")
                {
                }
                column(OptionHeading; GLAccHeading."Account Type")
                {
                }
                column(OptionBeginTotal; GLAccBeginTotal."Account Type")
                {
                }
                column(G_L_Account___No___Control24; "G/L Account"."No.")
                {
                }
                column(PADSTR_____G_L_Account__Indentation___2___G_L_Account__Name_Control25; PadStr('', "G/L Account".Indentation * 2) + "G/L Account".Name)
                {
                }
                column(G_L_Account___Account_Type__Control27; "G/L Account"."Account Type")
                {
                }
                column(G_L_Account__Totaling_Control28; "G/L Account".Totaling)
                {
                }
                column(G_L_Account___Balance_at_Date__Control29; "G/L Account"."Balance at Date")
                {
                }
                column(G_L_Account___GIFI_Code__Control1020002; "G/L Account"."GIFI Code")
                {
                }
                column(Integer_Number; Number)
                {
                }
            }

            trigger OnAfterGetRecord()
            begin
                PageGroupNo := NextPageGroupNo;
                if "G/L Account"."New Page" then
                    NextPageGroupNo := PageGroupNo + 1;
                "G/L Account".CalcFields("Balance at Date");
            end;

            trigger OnPreDataItem()
            begin
                PageGroupNo := 1;
                NextPageGroupNo := 1;
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Chart of Accounts';
        AboutText = 'The **Chart of Accounts** report provides a complete overview of all general ledger accounts, grouped by category, including balances and account types. Use it for setting up or reviewing your company’s account structure, verifying posting groups, and preparing for audits or financial reporting.';
        
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
        GLFilter := "G/L Account".GetFilters();
        CompanyInformation.Get();
        GLAccPosting."Account Type" := GLAccPosting."Account Type"::Posting;
        GLAccHeading."Account Type" := GLAccHeading."Account Type"::Heading;
        GLAccBeginTotal."Account Type" := GLAccBeginTotal."Account Type"::"Begin-Total";
    end;

    var
        CompanyInformation: Record "Company Information";
        GLAccPosting: Record "G/L Account";
        GLAccHeading: Record "G/L Account";
        GLAccBeginTotal: Record "G/L Account";
        Chart_of_AccountsCaptionLbl: Label 'Chart of Accounts';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        PADSTR_____G_L_Account__Indentation___2___G_L_Account__NameCaptionLbl: Label 'Name';
        PageGroupNo: Integer;
        NextPageGroupNo: Integer;

    protected var
        GLFilter: Text;
}

