// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Reports;

using Microsoft.Foundation.Company;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Ledger;
using Microsoft.Projects.Project.Planning;
using Microsoft.Sales.Customer;

report 10219 "Job Cost Suggested Billing"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Projects/Project/Reports/JobCostSuggestedBilling.rdlc';
    Caption = 'Project Cost Suggested Billing';
    AdditionalSearchTerms = 'Job Cost Suggested Billing';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Job; Job)
        {
            DataItemTableView = sorting("Bill-to Customer No.") where(Status = const(Open), "Bill-to Customer No." = filter(<> ''));
            RequestFilterFields = "Bill-to Customer No.", "Posting Date Filter", "Planning Date Filter";
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
            column(Job__Bill_to_Customer_No__; Job."Bill-to Customer No.")
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
            column(ContractPrice; ContractPrice)
            {
            }
            column(UsagePrice; UsagePrice)
            {
            }
            column(InvoicedPrice; InvoicedPrice)
            {
            }
            column(SuggestedBilling; SuggestedBilling)
            {
            }
            column(STRSUBSTNO_Text000_Customer_TABLECAPTION_Customer_FIELDCAPTION__No_____Bill_to_Customer_No___; StrSubstNo(Text000, Customer.TableCaption(), Customer.FieldCaption("No."), "Bill-to Customer No."))
            {
            }
            column(ContractPrice_Control20; ContractPrice)
            {
            }
            column(UsagePrice_Control21; UsagePrice)
            {
            }
            column(InvoicedPrice_Control29; InvoicedPrice)
            {
            }
            column(SuggestedBilling_Control31; SuggestedBilling)
            {
            }
            column(ContractPrice_Control25; ContractPrice)
            {
            }
            column(UsagePrice_Control26; UsagePrice)
            {
            }
            column(InvoicedPrice_Control30; InvoicedPrice)
            {
            }
            column(SuggestedBilling_Control14; SuggestedBilling)
            {
            }
            column(Job_Cost_Suggested_BillingCaption; Job_Cost_Suggested_BillingCaptionLbl)
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
            column(ContractPriceCaption; ContractPriceCaptionLbl)
            {
            }
            column(UsagePriceCaption; UsagePriceCaptionLbl)
            {
            }
            column(InvoicedPriceCaption; InvoicedPriceCaptionLbl)
            {
            }
            column(SuggestedBillingCaption; SuggestedBillingCaptionLbl)
            {
            }
            column(Report_TotalCaption; Report_TotalCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                ContractPrice := 0;
                UsagePrice := 0;
                InvoicedPrice := 0;
                SuggestedBilling := 0;

                JobPlanningLine.Reset();
                JobPlanningLine.SetCurrentKey("Job No.", "Job Task No.", "Contract Line", "Planning Date");
                JobPlanningLine.SetRange("Contract Line", true);
                JobPlanningLine.SetRange("Job No.", "No.");
                CopyFilter("Planning Date Filter", JobPlanningLine."Planning Date");
                JobPlanningLine.CalcSums("Total Price (LCY)");
                ContractPrice := JobPlanningLine."Total Price (LCY)";

                JobLedgerEntry.Reset();
                JobLedgerEntry.SetCurrentKey("Job No.", "Job Task No.", "Entry Type", "Posting Date");
                JobLedgerEntry.SetRange("Job No.", "No.");
                CopyFilter("Posting Date Filter", JobLedgerEntry."Posting Date");
                if JobLedgerEntry.FindSet() then
                    repeat
                        if JobLedgerEntry."Entry Type" = JobLedgerEntry."Entry Type"::Sale then
                            InvoicedPrice := InvoicedPrice - JobLedgerEntry."Total Price (LCY)"
                        else
                            UsagePrice := UsagePrice + JobLedgerEntry."Total Price (LCY)";
                    until JobLedgerEntry.Next() = 0;

                if UsagePrice > InvoicedPrice then
                    SuggestedBilling := UsagePrice - InvoicedPrice;

                if not Customer.Get("Bill-to Customer No.") then
                    Customer.Init();
            end;

            trigger OnPreDataItem()
            begin
                Clear(ContractPrice);
                Clear(UsagePrice);
                Clear(InvoicedPrice);
                Clear(SuggestedBilling);
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
        SuggestedBilling: Decimal;
        Text000: Label 'Total for %1 %2 %3';
        ContractPrice: Decimal;
        UsagePrice: Decimal;
        InvoicedPrice: Decimal;
        Job_Cost_Suggested_BillingCaptionLbl: Label 'Project Cost Suggested Billing';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        ContractPriceCaptionLbl: Label 'Billable Price';
        UsagePriceCaptionLbl: Label 'Usage Amount';
        InvoicedPriceCaptionLbl: Label 'Invoiced Amount';
        SuggestedBillingCaptionLbl: Label 'Suggested Billing';
        Report_TotalCaptionLbl: Label 'Report Total';
}

