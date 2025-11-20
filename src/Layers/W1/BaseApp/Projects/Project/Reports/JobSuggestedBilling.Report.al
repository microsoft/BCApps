// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Reports;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Journal;
using Microsoft.Sales.Customer;
using System.Utilities;

report 1011 "Job Suggested Billing"
{
    AdditionalSearchTerms = 'Job Suggested Billing';
    DefaultLayout = RDLC;
    RDLCLayout = './Projects/Project/Reports/JobSuggestedBilling.rdlc';
    ApplicationArea = Jobs;
    Caption = 'Project Suggested Billing';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Job; Job)
        {
            RequestFilterFields = "No.", "Bill-to Customer No.", "Posting Date Filter", "Planning Date Filter";
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(JobTableCaptionJobFilter; TableCaption + ': ' + JobFilter)
            {
            }
            column(JobFilter; JobFilter)
            {
            }
            column(TableCaptionJobTaskFilter; "Job Task".TableCaption + ': ' + JobTaskFilter)
            {
            }
            column(JobTaskFilter; JobTaskFilter)
            {
            }
            column(EmptyString; '')
            {
            }
            column(JobNo; "No.")
            {
            }
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
            }
            column(JobSuggestedBillCaption; JobSuggestedBillCaptionLbl)
            {
            }
            column(JobTaskNoCaption; JobTaskNoCaptionLbl)
            {
            }
            column(TotalContractCaption; TotalContractCaptionLbl)
            {
            }
            column(CostCaption; CostCaptionLbl)
            {
            }
            column(SalesCaption; SalesCaptionLbl)
            {
            }
            column(ContractInvoicedCaption; ContractInvoicedCaptionLbl)
            {
            }
            column(SuggestedBillingCaption; SuggestedBillingCaptionLbl)
            {
            }
            column(CurrencyCodeCaption; FieldCaption("Currency Code"))
            {
            }
            dataitem("Job Task"; "Job Task")
            {
                DataItemLink = "Job No." = field("No.");
                DataItemTableView = sorting("Job No.", "Job Task No.") where("Job Task Type" = const(Posting));
                RequestFilterFields = "Job Task No.";
                column(JobDescription; Job.Description)
                {
                }
                column(CustTableCaption; Cust.TableCaption + ' :')
                {
                }
                column(Cust2Name; Cust2.Name)
                {
                }
                column(Cust2No; Cust2."No.")
                {
                }
                column(JobTableCaption; Job.TableCaption + ' :')
                {
                }
                column(JobTaskJobTaskNo; "Job Task No.")
                {
                }
                column(JobTaskJobTaskDescription; Description)
                {
                }
                column(Amt1; Amt[1])
                {
                }
                column(Amt2; Amt[2])
                {
                }
                column(Amt3; Amt[3])
                {
                }
                column(Amt4; Amt[4])
                {
                }
                column(Amt5; Amt[5])
                {
                }
                column(Amt6; Amt[6])
                {
                }

                trigger OnAfterGetRecord()
                begin
                    Clear(JobCalcStatistics);
                    JobCalcStatistics.ReportSuggBilling(Job, "Job Task", Amt, CurrencyField);
                    PrintJobTask := false;

                    for I := 1 to 6 do
                        if Amt[I] <> 0 then
                            PrintJobTask := true;
                    if not PrintJobTask then
                        CurrReport.Skip();
                    for I := 1 to 6 do
                        TotalAmt[I] := TotalAmt[I] + Amt[I];
                end;
            }
            dataitem(JobTaskTotal; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(JobTableCaptionJobNo; TotalForTxt + ' ' + Job.TableCaption + ' ' + Job."No.")
                {
                }
                column(TotalAmt4; TotalAmt[4])
                {
                }
                column(TotalAmt5; TotalAmt[5])
                {
                }
                column(TotalAmt6; TotalAmt[6])
                {
                }
                column(TotalAmt1; TotalAmt[1])
                {
                }
                column(TotalAmt2; TotalAmt[2])
                {
                }
                column(TotalAmt3; TotalAmt[3])
                {
                }
                column(CurrencyCode; CurrencyCode)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    PrintJobTask := false;

                    for I := 1 to 6 do
                        if TotalAmt[I] <> 0 then
                            PrintJobTask := true;
                    if not PrintJobTask then
                        CurrReport.Skip();

                    Clear(JobBuffer);
                    CurrencyCode := '';
                    if CurrencyField[1] = CurrencyField[1] ::"Foreign Currency" then
                        CurrencyCode := Job."Currency Code";
                    if CurrencyCode = '' then
                        CurrencyCode := GLSetup."LCY Code";
                    JobBuffer[1]."Account No. 1" := Job."Bill-to Customer No.";
                    JobBuffer[1]."Account No. 2" := CurrencyCode;
                    JobBuffer[1]."Amount 1" := TotalAmt[1];
                    JobBuffer[1]."Amount 2" := TotalAmt[2];
                    JobBuffer[1]."Amount 3" := TotalAmt[3];
                    JobBuffer[1]."Amount 4" := TotalAmt[4];
                    JobBuffer[2] := JobBuffer[1];
                    if JobBuffer[2].Find() then begin
                        JobBuffer[2]."Amount 1" := JobBuffer[2]."Amount 1" + JobBuffer[1]."Amount 1";
                        JobBuffer[2]."Amount 2" := JobBuffer[2]."Amount 2" + JobBuffer[1]."Amount 2";
                        JobBuffer[2]."Amount 3" := JobBuffer[2]."Amount 3" + JobBuffer[1]."Amount 3";
                        JobBuffer[2]."Amount 4" := JobBuffer[2]."Amount 4" + JobBuffer[1]."Amount 4";
                        JobBuffer[2].Modify();
                    end else
                        JobBuffer[1].Insert();
                end;
            }

            trigger OnAfterGetRecord()
            begin
                for I := 1 to 8 do
                    TotalAmt[I] := 0;
                Clear(Cust2);
                if "Bill-to Customer No." = '' then
                    CurrReport.Skip();
                if Cust2.Get("Bill-to Customer No.") then;
            end;
        }
        dataitem(TotalBilling; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = const(1));
            column(TotalForCustTableCaption; TotalForTxt + ' ' + Cust.TableCaption())
            {
            }
            column(DescriptionCaption; DescriptionCaptionLbl)
            {
            }
            column(CustomerNoCaption; CustomerNoCaptionLbl)
            {
            }
        }
        dataitem(TotalCustomer; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = filter(1 ..));
            column(CustTotalAmt1; TotalAmt[1])
            {
            }
            column(CustTotalAmt2; TotalAmt[2])
            {
            }
            column(CustTotalAmt3; TotalAmt[3])
            {
            }
            column(CustTotalAmt4; TotalAmt[4])
            {
            }
            column(CustTotalAmt5; TotalAmt[5])
            {
            }
            column(CustTotalAmt6; TotalAmt[6])
            {
            }
            column(CustName; Cust.Name)
            {
            }
            column(CustNo; Cust."No.")
            {
            }
            column(CurrencyCode1; CurrencyCode)
            {
            }

            trigger OnAfterGetRecord()
            begin
                if Number = 1 then begin
                    if not JobBuffer[1].Find('-') then
                        CurrReport.Break();
                end else
                    if JobBuffer[1].Next() = 0 then
                        CurrReport.Break();
                Clear(Cust);
                Clear(TotalAmt);
                if not Cust.Get(JobBuffer[1]."Account No. 1") then
                    CurrReport.Skip();
                TotalAmt[1] := JobBuffer[1]."Amount 1";
                TotalAmt[2] := JobBuffer[1]."Amount 2";
                TotalAmt[3] := JobBuffer[1]."Amount 3";
                TotalAmt[4] := JobBuffer[1]."Amount 4";
                TotalAmt[5] := TotalAmt[1] - TotalAmt[3];
                TotalAmt[6] := TotalAmt[2] - TotalAmt[4];
                CurrencyCode := JobBuffer[1]."Account No. 2"
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Project Suggested Billing';
        AboutText = 'Get an overview of your projects, with focus on invoiced amounts and remaining amounts to invoice for each customer.\\Note: In the US, Canada, and Mexico, this report is not available. Instead, use the Project Cost Suggested Billing (10219) report.';
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field("CurrencyField[1]"; CurrencyField[1])
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Currency';
                        OptionCaption = 'Local Currency,Foreign Currency';
                        ToolTip = 'Specifies the currency that amounts are shown in.';
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
        JobFilter := Job.GetFilters();
        JobTaskFilter := "Job Task".GetFilters();
        CurrencyField[2] := CurrencyField[1];
        CurrencyField[3] := CurrencyField[1];
        JobBuffer[1].DeleteAll();
        GLSetup.Get();
    end;

    var
        GLSetup: Record "General Ledger Setup";
        Cust: Record Customer;
        Cust2: Record Customer;
        JobBuffer: array[2] of Record "Job Buffer" temporary;
        JobCalcStatistics: Codeunit "Job Calculate Statistics";
        Amt: array[8] of Decimal;
        TotalAmt: array[8] of Decimal;
        CurrencyField: array[8] of Option "Local Currency","Foreign Currency";
        JobFilter: Text;
        JobTaskFilter: Text;
        PrintJobTask: Boolean;
        I: Integer;
        TotalForTxt: Label 'Total for';
        CurrencyCode: Code[20];
        CurrReportPageNoCaptionLbl: Label 'Page';
        JobSuggestedBillCaptionLbl: Label 'Project Suggested Billing';
        JobTaskNoCaptionLbl: Label 'Project Task No.';
        TotalContractCaptionLbl: Label 'Total Billable';
        CostCaptionLbl: Label 'Cost';
        SalesCaptionLbl: Label 'Sales';
        ContractInvoicedCaptionLbl: Label 'Billable (Invoiced) ';
        SuggestedBillingCaptionLbl: Label 'Suggested Billing';
        DescriptionCaptionLbl: Label 'Description';
        CustomerNoCaptionLbl: Label 'Customer No.';

    procedure InitializeRequest(NewCurrencyField: Option "Local Currency","Foreign Currency")
    begin
        CurrencyField[1] := NewCurrencyField;
    end;
}

