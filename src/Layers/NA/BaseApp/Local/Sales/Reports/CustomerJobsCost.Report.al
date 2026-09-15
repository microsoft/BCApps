// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reports;

using Microsoft.Foundation.Company;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Ledger;
using Microsoft.Projects.Project.Planning;
using Microsoft.Sales.Customer;

report 10213 "Customer Jobs (Cost)"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Sales/Reports/CustomerJobsCost.rdlc';
    ApplicationArea = Jobs;
    Caption = 'Customer Projects (Cost)';
    AdditionalSearchTerms = 'Customer Jobs (Cost)';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Job; Job)
        {
            DataItemTableView = sorting("Bill-to Customer No.") where(Status = const(Open), "Bill-to Customer No." = filter(<> ''));
            RequestFilterFields = "Bill-to Customer No.", "Starting Date", "Ending Date";
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
            column(Job_TABLECAPTION__________JobFilter; Job.TableCaption + ': ' + JobFilter)
            {
            }
            column(JobFilter; JobFilter)
            {
            }
            column(Customer_TABLECAPTION_________Customer_FIELDCAPTION__No_____________Bill_to_Customer_No__; Customer.TableCaption + ' ' + Customer.FieldCaption("No.") + ' ' + "Bill-to Customer No.")
            {
            }
            column(Customer_Name; Customer.Name)
            {
            }
            column(Job__No__; "No.")
            {
            }
            column(Job_Description; Description)
            {
            }
            column(Job__Starting_Date_; "Starting Date")
            {
            }
            column(Job__Ending_Date_; "Ending Date")
            {
            }
            column(ScheduledCost; ScheduledCost)
            {
            }
            column(UsageCost; UsageCost)
            {
            }
            column(Percent_Completion_; "Percent Completion"())
            {
                DecimalPlaces = 1 : 1;
            }
            column(Total_for_____Customer_TABLECAPTION_________Customer_FIELDCAPTION__No_____________Bill_to_Customer_No__; 'Total for ' + Customer.TableCaption + ' ' + Customer.FieldCaption("No.") + ' ' + "Bill-to Customer No.")
            {
            }
            column(ScheduledCost_Control20; ScheduledCost)
            {
            }
            column(UsageCost_Control21; UsageCost)
            {
            }
            column(Percent_Completion__Control22; "Percent Completion"())
            {
                DecimalPlaces = 1 : 1;
            }
            column(ScheduledCost_Control25; ScheduledCost)
            {
            }
            column(UsageCost_Control26; UsageCost)
            {
            }
            column(Job_Bill_to_Customer_No_; "Bill-to Customer No.")
            {
            }
            column(Customer_Jobs___CostCaption; Customer_Jobs___CostCaptionLbl)
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
            column(Job__Starting_Date_Caption; FieldCaption("Starting Date"))
            {
            }
            column(Job__Ending_Date_Caption; FieldCaption("Ending Date"))
            {
            }
            column(ScheduledCostCaption; ScheduledCostCaptionLbl)
            {
            }
            column(UsageCostCaption; UsageCostCaptionLbl)
            {
            }
            column(Percent_Completion_Caption; Percent_Completion_CaptionLbl)
            {
            }
            column(Report_TotalCaption; Report_TotalCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                ScheduledCost := 0;
                UsageCost := 0;

                JobPlanningLine.Reset();
                JobPlanningLine.SetCurrentKey("Job No.", "Job Task No.", "Schedule Line", "Planning Date");
                JobPlanningLine.SetRange("Job No.", "No.");
                CopyFilter("Planning Date Filter", JobPlanningLine."Planning Date");
                JobPlanningLine.SetRange("Schedule Line", true);
                JobPlanningLine.CalcSums("Total Cost (LCY)");
                ScheduledCost := JobPlanningLine."Total Cost (LCY)";

                JobLedgerEntry.Reset();
                JobLedgerEntry.SetCurrentKey("Job No.", "Job Task No.", "Entry Type", "Posting Date");
                JobLedgerEntry.SetRange("Job No.", "No.");
                CopyFilter("Posting Date Filter", JobLedgerEntry."Posting Date");
                JobLedgerEntry.SetRange("Entry Type", JobLedgerEntry."Entry Type"::Usage);
                JobLedgerEntry.CalcSums("Total Cost (LCY)");
                UsageCost := JobLedgerEntry."Total Cost (LCY)";
                if not Customer.Get("Bill-to Customer No.") then
                    Customer.Init();
            end;

            trigger OnPreDataItem()
            begin
                Clear(ScheduledCost);
                Clear(UsageCost);
            end;
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

    trigger OnPreReport()
    begin
        CompanyInformation.Get();
        JobFilter := Job.GetFilters();
    end;

    var
        CompanyInformation: Record "Company Information";
        Customer: Record Customer;
        JobPlanningLine: Record "Job Planning Line";
        JobLedgerEntry: Record "Job Ledger Entry";
        JobFilter: Text;
        ScheduledCost: Decimal;
        UsageCost: Decimal;
        Customer_Jobs___CostCaptionLbl: Label 'Customer Projects - Cost';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        ScheduledCostCaptionLbl: Label 'Budget Cost';
        UsageCostCaptionLbl: Label 'Actual Cost';
        Percent_Completion_CaptionLbl: Label 'Percent Completion';
        Report_TotalCaptionLbl: Label 'Report Total';

    procedure "Percent Completion"(): Decimal
    begin
        if ScheduledCost = 0 then
            exit(0);

        exit(100 * UsageCost / ScheduledCost);
    end;
}

