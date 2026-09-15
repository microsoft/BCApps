// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Reports;

using Microsoft.Foundation.Company;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Ledger;
using Microsoft.Projects.Project.Planning;

report 10212 "Completed Jobs"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Projects/Project/Reports/CompletedJobs.rdlc';
    ApplicationArea = Jobs;
    Caption = 'Completed Projects';
    AdditionalSearchTerms = 'Completed Jobs';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Job; Job)
        {
            DataItemTableView = where(Status = const(Completed));
            RequestFilterFields = "No.", "Bill-to Customer No.";
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
            column(TLGrouping; TLGrouping)
            {
            }
            column(Job__No__; "No.")
            {
            }
            column(Job_Description; Description)
            {
            }
            column(ScheduledPrice; ScheduledPrice)
            {
            }
            column(InvoicedPrice; InvoicedPrice)
            {
            }
            column(UsageCost; UsageCost)
            {
            }
            column(Profit; Profit)
            {
            }
            column(Profit__; "Profit%")
            {
                DecimalPlaces = 1 : 1;
            }
            column(Job__Bill_to_Customer_No__; "Bill-to Customer No.")
            {
            }
            column(ContractPrice; ContractPrice)
            {
            }
            column(Job__Bill_to_Customer_No___Control1480005; "Bill-to Customer No.")
            {
            }
            column(ScheduledPrice_Control1480006; ScheduledPrice)
            {
            }
            column(ContractPrice_Control1480007; ContractPrice)
            {
            }
            column(InvoicedPrice_Control1480008; InvoicedPrice)
            {
            }
            column(UsageCost_Control1480009; UsageCost)
            {
            }
            column(Profit_Control1480010; Profit)
            {
            }
            column(Profit___Control1480011; "Profit%")
            {
                DecimalPlaces = 1 : 1;
            }
            column(ScheduledPrice_Control22; ScheduledPrice)
            {
            }
            column(InvoicedPrice_Control23; InvoicedPrice)
            {
            }
            column(UsageCost_Control24; UsageCost)
            {
            }
            column(Profit_Control25; Profit)
            {
            }
            column(Profit___Control26; "Profit%")
            {
                DecimalPlaces = 1 : 1;
            }
            column(ContractPrice_Control1480002; ContractPrice)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Completed_JobsCaption; Completed_JobsCaptionLbl)
            {
            }
            column(Job__No__Caption; FieldCaption("No."))
            {
            }
            column(Job_DescriptionCaption; FieldCaption(Description))
            {
            }
            column(ScheduledPriceCaption; ScheduledPriceCaptionLbl)
            {
            }
            column(InvoicedPriceCaption; InvoicedPriceCaptionLbl)
            {
            }
            column(UsageCostCaption; UsageCostCaptionLbl)
            {
            }
            column(ProfitCaption; ProfitCaptionLbl)
            {
            }
            column(Profit__Caption; Profit__CaptionLbl)
            {
            }
            column(Job__Bill_to_Customer_No__Caption; FieldCaption("Bill-to Customer No."))
            {
            }
            column(ContractPriceCaption; ContractPriceCaptionLbl)
            {
            }
            column(Total_for_CustomerCaption; Total_for_CustomerCaptionLbl)
            {
            }
            column(Report_TotalCaption; Report_TotalCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                ScheduledPrice := 0;
                ContractPrice := 0;
                InvoicedPrice := 0;
                UsageCost := 0;
                Profit := 0;

                JobPlanningLine.Reset();
                JobPlanningLine.SetCurrentKey("Job No.", "Schedule Line", Type, "No.", "Planning Date");
                JobPlanningLine.SetRange("Job No.", "No.");
                CopyFilter("Planning Date Filter", JobPlanningLine."Planning Date");
                JobPlanningLine.SetFilter(Type, '<>%1', JobPlanningLine.Type::Text);
                if JobPlanningLine.FindSet() then
                    repeat
                        case JobPlanningLine."Line Type" of
                            JobPlanningLine."Line Type"::Budget:
                                ScheduledPrice := ScheduledPrice + JobPlanningLine."Total Price (LCY)";
                            JobPlanningLine."Line Type"::Billable:
                                ContractPrice := ContractPrice + JobPlanningLine."Total Price (LCY)";
                            JobPlanningLine."Line Type"::"Both Budget and Billable":
                                begin
                                    ScheduledPrice := ScheduledPrice + JobPlanningLine."Total Price (LCY)";
                                    ContractPrice := ContractPrice + JobPlanningLine."Total Price (LCY)";
                                end;
                        end;
                    until JobPlanningLine.Next() = 0;

                JobLedgerEntry.Reset();
                JobLedgerEntry.SetCurrentKey("Job No.", "Posting Date");
                JobLedgerEntry.SetRange("Job No.", "No.");
                CopyFilter("Posting Date Filter", JobLedgerEntry."Posting Date");
                if JobLedgerEntry.FindSet() then
                    repeat
                        case JobLedgerEntry."Entry Type" of
                            JobLedgerEntry."Entry Type"::Usage:
                                UsageCost := UsageCost + JobLedgerEntry."Total Cost (LCY)";
                            JobLedgerEntry."Entry Type"::Sale:
                                InvoicedPrice := InvoicedPrice - JobLedgerEntry."Total Price (LCY)";
                        end;
                    until JobLedgerEntry.Next() = 0;

                Profit := InvoicedPrice - UsageCost;
            end;

            trigger OnPreDataItem()
            begin
                Clear(ScheduledPrice);
                Clear(ContractPrice);
                Clear(InvoicedPrice);
                Clear(UsageCost);
                Clear(Profit);
                if StrPos(CurrentKey, FieldCaption("Bill-to Customer No.")) = 1 then
                    TLGrouping := true
                else
                    TLGrouping := false;
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
        JobPlanningLine: Record "Job Planning Line";
        JobLedgerEntry: Record "Job Ledger Entry";
        JobFilter: Text;
        ScheduledPrice: Decimal;
        ContractPrice: Decimal;
        InvoicedPrice: Decimal;
        UsageCost: Decimal;
        Profit: Decimal;
        "Profit%": Decimal;
        TLGrouping: Boolean;
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Completed_JobsCaptionLbl: Label 'Completed Projects';
        ScheduledPriceCaptionLbl: Label 'Scheduled Price';
        InvoicedPriceCaptionLbl: Label 'Invoiced Price';
        UsageCostCaptionLbl: Label 'Usage (Cost)';
        ProfitCaptionLbl: Label 'Profit';
        Profit__CaptionLbl: Label 'Percent Profit';
        ContractPriceCaptionLbl: Label 'Contract Price';
        Total_for_CustomerCaptionLbl: Label 'Total for Customer';
        Report_TotalCaptionLbl: Label 'Report Total';
}

