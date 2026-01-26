// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reports;

using Microsoft.Sales.Customer;

report 10608 "Customer - Balance"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Sales/Reports/CustomerBalance.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Customer - Balance';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Customer; Customer)
        {
            DataItemTableView = sorting("Customer Posting Group");
            RequestFilterFields = "No.", "Search Name", "Date Filter", "Customer Posting Group";
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(CustomerFilter; CustomerFilter)
            {
            }
            column(ShowIfNetChange; ShowIfNetChange)
            {
            }
            column(ShowGroups; ShowGroups)
            {
            }
            column(CustomerCustomerFilter; Customer.TableName + ': ' + CustomerFilter)
            {
            }
            column(CustomerPostingGroup_Customer; "Customer Posting Group")
            {
            }
            column(No_Customer; "No.")
            {
            }
            column(Name_Customer; Name)
            {
            }
            column(PhoneNo_Customer; "Phone No.")
            {
            }
            column(BalanceLCY_Customer; "Balance (LCY)")
            {
            }
            column(NetChangeLCY_Customer; "Net Change (LCY)")
            {
            }
            column(BalanceDueLCY_Customer; "Balance Due (LCY)")
            {
            }
            column(TotalForCustomerPostingGroup; 'Total for ' + FieldName("Customer Posting Group") + ' ' + "Customer Posting Group")
            {
            }
            column(CustomerBalanceCaption; CustomerBalanceCaptionLbl)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(AllAmountsInLCYCaption; AllAmountsInLCYCaptionLbl)
            {
            }
            column(CustomersWithNetChangeCaption; CustomersWithNetChangeCaptionLbl)
            {
            }
            column(NoCaption_Customer; FieldCaption("No."))
            {
            }
            column(NameCaption_Customer; FieldCaption(Name))
            {
            }
            column(PhoneNoCaption_Customer; FieldCaption("Phone No."))
            {
            }
            column(BalanceLCYCaption_Customer; FieldCaption("Balance (LCY)"))
            {
            }
            column(NetChangeLCYCaption_Customer; FieldCaption("Net Change (LCY)"))
            {
            }
            column(BalanceDueLCYCaption_Customer; FieldCaption("Balance Due (LCY)"))
            {
            }
            column(CustomerPostingGroupCaption_Customer; FieldCaption("Customer Posting Group"))
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                CalcFields("Net Change (LCY)");
                if ShowIfNetChange and ("Net Change (LCY)" = 0) then
                    CurrReport.Skip();
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
                        ToolTip = 'Specifies if you want to include customers with a net change in the period.';
                    }
                    field(ShowGroups; ShowGroups)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show only Groups';
                        ToolTip = 'Specifies if you want to include a total balance for each customer posting group. If this field is not selected, a balance will not be shown for individual customers.';
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
        CustomerFilter := Customer.GetFilters();
    end;

    var
        CustomerFilter: Text[250];
        ShowIfNetChange: Boolean;
        ShowGroups: Boolean;
        CustomerBalanceCaptionLbl: Label 'Customer - Balance';
        PageCaptionLbl: Label 'Page';
        AllAmountsInLCYCaptionLbl: Label 'All amounts in LCY';
        CustomersWithNetChangeCaptionLbl: Label 'This report only includes customers with net change.';
        TotalCaptionLbl: Label 'Total';
}

