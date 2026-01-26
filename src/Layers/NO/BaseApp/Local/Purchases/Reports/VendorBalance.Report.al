// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Reports;

using Microsoft.Purchases.Vendor;

report 10609 "Vendor - Balance"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Purchases/Reports/VendorBalance.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Vendor - Balance';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Vendor; Vendor)
        {
            DataItemTableView = sorting("Vendor Posting Group");
            RequestFilterFields = "No.", "Search Name", "Date Filter", "Vendor Posting Group";
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(VendorVendorFilter; Vendor.TableName + ': ' + VendorFilter)
            {
            }
            column(ShowIfNetChange; ShowIfNetChange)
            {
            }
            column(VendorPostingGroup_Vendor; "Vendor Posting Group")
            {
            }
            column(ShowGroups; ShowGroups)
            {
            }
            column(VendorFilter; VendorFilter)
            {
            }
            column(No_Vendor; "No.")
            {
            }
            column(Name_Vendor; Name)
            {
            }
            column(PhoneNo_Vendor; "Phone No.")
            {
            }
            column(BalanceLCY; BalanceLCY)
            {
            }
            column(NetChangeLCY; NetChangeLCY)
            {
            }
            column(BalanceDueLCY; BalanceDueLCY)
            {
            }
            column(TotalForVendorPostingGroup; 'Total for ' + FieldName("Vendor Posting Group") + ' ' + "Vendor Posting Group")
            {
            }
            column(VendorBalanceCaption; VendorBalanceCaptionLbl)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(AllAmountsInLCYCaption; AllAmountsInLCYCaptionLbl)
            {
            }
            column(VendorsWithNetChangeCaption; VendorsWithNetChangeCaptionLbl)
            {
            }
            column(NoCaption_Vendor; FieldCaption("No."))
            {
            }
            column(NameCaption_Vendor; FieldCaption(Name))
            {
            }
            column(PhoneNoCaption_Vendor; FieldCaption("Phone No."))
            {
            }
            column(BalanceLCYCaption; BalanceLCYCaptionLbl)
            {
            }
            column(NetChangeLCYCaption; NetChangeLCYCaptionLbl)
            {
            }
            column(BalanceDueLCYCaption; BalanceDueLCYCaptionLbl)
            {
            }
            column(VendorPostingGroupCaption_Vendor; FieldCaption("Vendor Posting Group"))
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                CalcFields("Balance (LCY)", "Balance Due (LCY)", "Net Change (LCY)");
                if ShowIfNetChange and ("Net Change (LCY)" = 0) then
                    CurrReport.Skip();
                ReadAmount();
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
                    field(ShowIfNetChange; ShowIfNetChange)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show only if Net Change';
                        ToolTip = 'Specifies if you want to include vendors with a net change in the period.';
                    }
                    field(ShowGroups; ShowGroups)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show only Groups';
                        ToolTip = 'Specifies if you want to include a total balance for each vendor posting group. If this field is not selected, a balance will not be shown for individual vendors.';
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
        VendorFilter := Vendor.GetFilters();
    end;

    var
        VendorFilter: Text[250];
        ShowIfNetChange: Boolean;
        ShowGroups: Boolean;
        BalanceLCY: Decimal;
        BalanceDueLCY: Decimal;
        NetChangeLCY: Decimal;
        VendorBalanceCaptionLbl: Label 'Vendor - Balance';
        PageCaptionLbl: Label 'Page';
        AllAmountsInLCYCaptionLbl: Label 'All amounts in LCY';
        VendorsWithNetChangeCaptionLbl: Label 'This report only includes vendors with net change.';
        BalanceLCYCaptionLbl: Label 'Balance (LCY)';
        NetChangeLCYCaptionLbl: Label 'Net Change (LCY)';
        BalanceDueLCYCaptionLbl: Label 'Balance Due (LCY)';
        TotalCaptionLbl: Label 'Total';

    [Scope('OnPrem')]
    procedure ReadAmount()
    begin
        BalanceLCY := -Vendor."Balance (LCY)";
        BalanceDueLCY := -Vendor."Balance Due (LCY)";
        NetChangeLCY := -Vendor."Net Change (LCY)";
    end;
}

