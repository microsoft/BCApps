// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Reports;

using Microsoft.Foundation.Company;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Planning;
using Microsoft.Sales.Customer;

report 10216 "Job List"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Projects/Project/Reports/JobList.rdlc';
    ApplicationArea = Jobs;
    Caption = 'Project List';
    AdditionalSearchTerms = 'Job List';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Job; Job)
        {
            RequestFilterFields = "No.", "Search Description", "Bill-to Customer No.", Status, "Planning Date Filter";
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
            column(BudgetOptionText; BudgetOptionText)
            {
            }
            column(Job_TABLECAPTION__________JobFilter; Job.TableCaption + ': ' + JobFilter)
            {
            }
            column(JobFilter; JobFilter)
            {
            }
            column(Job__No__; "No.")
            {
            }
            column(Job_Description; Description)
            {
            }
            column(Job_Status; Status)
            {
            }
            column(Job__Bill_to_Customer_No__; "Bill-to Customer No.")
            {
            }
            column(Customer_Name; Customer.Name)
            {
            }
            column(JobPlanningLine__Total_Cost__LCY__; JobPlanningLine."Total Cost (LCY)")
            {
            }
            column(JobPlanningLine__Total_Price__LCY__; JobPlanningLine."Total Price (LCY)")
            {
            }
            column(Job__Description_2_; "Description 2")
            {
            }
            column(Job_ListCaption; Job_ListCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Job__No__Caption; FieldCaption("No."))
            {
            }
            column(Job_DescriptionCaption; FieldCaption(Description))
            {
            }
            column(Job_StatusCaption; FieldCaption(Status))
            {
            }
            column(Job__Bill_to_Customer_No__Caption; FieldCaption("Bill-to Customer No."))
            {
            }
            column(Customer_NameCaption; Customer_NameCaptionLbl)
            {
            }
            column(JobPlanningLine__Total_Cost__LCY__Caption; JobPlanningLine__Total_Cost__LCY__CaptionLbl)
            {
            }
            column(JobPlanningLine__Total_Price__LCY__Caption; JobPlanningLine__Total_Price__LCY__CaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                if not Customer.Get("Bill-to Customer No.") then
                    Customer.Init();
                JobPlanningLine.SetRange("Job No.", "No.");
                JobPlanningLine.CalcSums("Total Cost (LCY)", "Total Price (LCY)");
            end;

            trigger OnPreDataItem()
            begin
                case BudgetAmountsPer of
                    BudgetAmountsPer::Schedule:
                        begin
                            JobPlanningLine.SetCurrentKey("Job No.", "Job Task No.", "Schedule Line", "Planning Date");
                            JobPlanningLine.SetRange("Schedule Line", true);
                        end;
                    BudgetAmountsPer::Contract:
                        begin
                            JobPlanningLine.SetCurrentKey("Job No.", "Job Task No.", "Contract Line", "Planning Date");
                            JobPlanningLine.SetRange("Contract Line", true);
                        end;
                end;
                Job.CopyFilter("Planning Date Filter", JobPlanningLine."Planning Date");
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
                    field(BudgetAmountsPer; BudgetAmountsPer)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Budget Amounts Per';
                        OptionCaption = 'Budget,Billable';
                        ToolTip = 'Specifies if the budget amounts must be based on budgets or billables.';
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
        JobFilter := Job.GetFilters();
        if BudgetAmountsPer = BudgetAmountsPer::Schedule then
            BudgetOptionText := Text001
        else
            BudgetOptionText := Text002;
    end;

    var
        CompanyInformation: Record "Company Information";
        Customer: Record Customer;
        JobPlanningLine: Record "Job Planning Line";
        JobFilter: Text;
        BudgetAmountsPer: Option Schedule,Contract;
        BudgetOptionText: Text[50];
        Text001: Label 'Budgeted Amounts are per the Budget';
        Text002: Label 'Budgeted Amounts are per the Contract';
        Job_ListCaptionLbl: Label 'Project List';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Customer_NameCaptionLbl: Label 'Customer Name';
        JobPlanningLine__Total_Cost__LCY__CaptionLbl: Label 'Budgeted Cost';
        JobPlanningLine__Total_Price__LCY__CaptionLbl: Label 'Budgeted Price';
}

