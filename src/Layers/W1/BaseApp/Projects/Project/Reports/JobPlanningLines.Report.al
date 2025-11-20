// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Planning;

using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Journal;
using System.Utilities;

report 1006 "Job - Planning Lines"
{
    AdditionalSearchTerms = 'Job - Planning Lines';
    DefaultLayout = RDLC;
    RDLCLayout = './Projects/Project/Reports/JobPlanningLines.rdlc';
    ApplicationArea = Jobs;
    Caption = 'Project - Planning Lines';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Job; Job)
        {
            DataItemTableView = sorting("No.");
            PrintOnlyIfDetail = true;
            column(No_Job; StrSubstNo('%1 %2 %3 %4', TableCaption(), FieldCaption("No."), "No.", Description))
            {
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(CompanyName; COMPANYPROPERTY.DisplayName())
                {
                }
                column(TodayFormatted; Format(Today, 0, 4))
                {
                }
                column(JobTaskCaption; "Job Task".TableCaption + ': ' + JTFilter)
                {
                }
                column(ShowJTFilter; JTFilter)
                {
                }
                column(Desc_Job; Job.Description)
                {
                }
                column(CurrCodeJob0Fld; JobCalcBatches.GetCurrencyCode(Job, 0, CurrencyField))
                {
                }
                column(CurrCodeJob2Fld; JobCalcBatches.GetCurrencyCode(Job, 2, CurrencyField))
                {
                }
                column(CurrCodeJob3Fld; JobCalcBatches.GetCurrencyCode(Job, 3, CurrencyField))
                {
                }
                column(JobPlanningLinesCaption; JobPlanningLinesCaptionLbl)
                {
                }
                column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
                {
                }
                column(JobPlannLinePlannDtCptn; JobPlannLinePlannDtCptnLbl)
                {
                }
                column(LineTypeCaption; LineTypeCaptionLbl)
                {
                }
            }
            dataitem("Job Task"; "Job Task")
            {
                DataItemLink = "Job No." = field("No.");
                DataItemTableView = sorting("Job No.", "Job Task No.");
                PrintOnlyIfDetail = true;
                RequestFilterFields = "Job No.", "Job Task No.";
                column(JobTaskNo_JobTask; "Job Task No.")
                {
                }
                column(Desc_JobTask; Description)
                {
                }
                column(TotalCost1_JobTask; TotalCost[1])
                {
                }
                column(TotalCost2_JobTask; TotalCost[2])
                {
                }
                column(FooterTotalCost1_JobTask; FooterTotalCost1)
                {
                }
                column(FooterTotalCost2_JobTask; FooterTotalCost2)
                {
                }
                column(FooterLineDisAmt1_JobTask; FooterLineDiscountAmount1)
                {
                }
                column(FooterLineDisAmt2_JobTask; FooterLineDiscountAmount2)
                {
                }
                column(FooterLineAmt1_JobTask; FooterLineAmount1)
                {
                }
                column(FooterLineAmt2_JobTask; FooterLineAmount2)
                {
                }
                column(JobTaskNo_JobTaskCaption; FieldCaption("Job Task No."))
                {
                }
                column(TotalScheduleCaption; TotalScheduleCaptionLbl)
                {
                }
                column(TotalContractCaption; TotalContractCaptionLbl)
                {
                }
                dataitem("Job Planning Line"; "Job Planning Line")
                {
                    DataItemLink = "Job No." = field("Job No."), "Job Task No." = field("Job Task No."), "Planning Date" = field("Planning Date Filter");
                    DataItemLinkReference = "Job Task";
                    DataItemTableView = sorting("Job No.", "Job Task No.", "Line No.");
                    column(TotCostLCY_JobPlanningLine; "Total Cost (LCY)")
                    {
                    }
                    column(Qty_JobPlanningLine; Quantity)
                    {
                        IncludeCaption = false;
                    }
                    column(Desc_JobPlanningLine; Description)
                    {
                        IncludeCaption = false;
                    }
                    column(No_JobPlanningLine; "No.")
                    {
                        IncludeCaption = false;
                    }
                    column(Type_JobPlanningLine; Type)
                    {
                        IncludeCaption = false;
                    }
                    column(PlannDate_JobPlanningLine; Format("Planning Date"))
                    {
                    }
                    column(DocNo_JobPlanningLine; "Document No.")
                    {
                        IncludeCaption = false;
                    }
                    column(UOMCode_JobPlanningLine; "Unit of Measure Code")
                    {
                        IncludeCaption = false;
                    }
                    column(LineDiscAmLCY_JobPlanningLine; "Line Discount Amount (LCY)")
                    {
                    }
                    column(AmtLCY_JobPlanningLine; "Line Amount (LCY)")
                    {
                    }
                    column(LineType_JobPlanningLine; SelectStr(ConvertToJobLineType().AsInteger(), Text000))
                    {
                    }
                    column(FieldLocalCurr_JobPlanningLine; CurrencyField = CurrencyField::"Local Currency")
                    {
                    }
                    column(TotalCost_JobPlanningLine; "Total Cost")
                    {
                    }
                    column(LineDiscAmt_JobPlanningLine; "Line Discount Amount")
                    {
                    }
                    column(LineAmt_JobPlanningLine; "Line Amount")
                    {
                    }
                    column(ForeignCurr_JobPlanningLine; CurrencyField = CurrencyField::"Foreign Currency")
                    {
                    }
                    column(TotalCost1_JobPlanningLine; TotalCost[1])
                    {
                    }
                    column(LineAmt1_JobPlanningLine; LineAmount[1])
                    {
                    }
                    column(LineDisAmt1_JobPlanningLine; LineDiscountAmount[1])
                    {
                    }
                    column(LineAmt2_JobPlanningLine; LineAmount[2])
                    {
                    }
                    column(LineDisAmt2_JobPlanningLine; LineDiscountAmount[2])
                    {
                    }
                    column(TotalCost2_JobPlanningLine; TotalCost[2])
                    {
                    }
                    column(JobNo_JobPlanningLine; "Job No.")
                    {
                    }
                    column(JobTaskNo_JobPlanningLine; "Job Task No.")
                    {
                    }
                    column(ScheduleCaption; ScheduleCaptionLbl)
                    {
                    }
                    column(ContractCaption; ContractCaptionLbl)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if CurrencyField = CurrencyField::"Local Currency" then begin
                            if "Schedule Line" then begin
                                FooterTotalCost1 += "Total Cost (LCY)";
                                TotalCost[1] += "Total Cost (LCY)";
                                FooterLineDiscountAmount1 += "Line Discount Amount (LCY)";
                                LineDiscountAmount[1] += "Line Discount Amount (LCY)";
                                FooterLineAmount1 += "Line Amount (LCY)";
                                LineAmount[1] += "Line Amount (LCY)";
                            end;
                            if "Contract Line" then begin
                                FooterTotalCost2 += "Total Cost (LCY)";
                                TotalCost[2] += "Total Cost (LCY)";
                                FooterLineDiscountAmount2 += "Line Discount Amount (LCY)";
                                LineDiscountAmount[2] += "Line Discount Amount (LCY)";
                                FooterLineAmount2 += "Line Amount (LCY)";
                                LineAmount[2] += "Line Amount (LCY)";
                            end;
                        end else begin
                            if "Schedule Line" then begin
                                FooterTotalCost1 += "Total Cost";
                                TotalCost[1] += "Total Cost";
                                FooterLineDiscountAmount1 += "Line Discount Amount";
                                LineDiscountAmount[1] += "Line Discount Amount";
                                FooterLineAmount1 += "Line Amount";
                                LineAmount[1] += "Line Amount";
                            end;
                            if "Contract Line" then begin
                                FooterTotalCost2 += "Total Cost";
                                TotalCost[2] += "Total Cost";
                                FooterLineDiscountAmount2 += "Line Discount Amount";
                                LineDiscountAmount[2] += "Line Discount Amount";
                                FooterLineAmount2 += "Line Amount";
                                LineAmount[2] += "Line Amount";
                            end;
                        end;
                    end;
                }

                trigger OnPreDataItem()
                begin
                    Clear(TotalCost);
                    Clear(LineDiscountAmount);
                    Clear(LineAmount);
                end;
            }

            trigger OnAfterGetRecord()
            var
                JobPlanningLine: Record "Job Planning Line";
            begin
                JobPlanningLine.SetRange("Job No.", "No.");
                JobPlanningLine.SetFilter("Planning Date", JobPlanningDateFilter);
                if not JobPlanningLine.FindFirst() then
                    CurrReport.Skip();

                FooterTotalCost1 := 0;
                FooterTotalCost2 := 0;
                FooterLineDiscountAmount1 := 0;
                FooterLineDiscountAmount2 := 0;
                FooterLineAmount1 := 0;
                FooterLineAmount2 := 0;
            end;

            trigger OnPreDataItem()
            begin
                SetFilter("No.", JobFilter);
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Project - Planning Lines';
        AboutText = 'Get an overview of planning and tasks for a project.';

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(CurrencyField; CurrencyField)
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
        JobPlannLineTypeCaption = 'Type';
        JobPlannLineDocNoCaption = 'Document No.';
        JobPlannLineNoCaption = 'No.';
        JobPlannLineDescCaption = 'Description';
        JobPlannLineQtyCaption = 'Quantity';
        JobPlannLineUOMCodeCptn = 'Unit of Measure Code';
        JobTaskNo_JobTaskCptn = 'Project Task No.';
    }

    trigger OnPreReport()
    begin
        JTFilter := "Job Task".GetFilters();
        JobFilter := "Job Task".GetFilter("Job No.");
        JobPlanningDateFilter := "Job Task".GetFilter("Planning Date Filter");
    end;

    var
        JobCalcBatches: Codeunit "Job Calculate Batches";
        TotalCost: array[2] of Decimal;
        LineDiscountAmount: array[2] of Decimal;
        LineAmount: array[2] of Decimal;
        JobFilter: Text;
        JTFilter: Text;
        CurrencyField: Option "Local Currency","Foreign Currency";
#pragma warning disable AA0074
        Text000: Label 'Budget,Billable,Bud.+Bill.';
#pragma warning restore AA0074
        FooterTotalCost1: Decimal;
        FooterTotalCost2: Decimal;
        FooterLineDiscountAmount1: Decimal;
        FooterLineDiscountAmount2: Decimal;
        FooterLineAmount1: Decimal;
        FooterLineAmount2: Decimal;
        JobPlanningLinesCaptionLbl: Label 'Project Planning Lines';
        CurrReportPageNoCaptionLbl: Label 'Page';
        JobPlannLinePlannDtCptnLbl: Label 'Planning Date';
        LineTypeCaptionLbl: Label 'Line Type';
        TotalScheduleCaptionLbl: Label 'Total Budget';
        TotalContractCaptionLbl: Label 'Total Billable';
        ScheduleCaptionLbl: Label 'Budget';
        ContractCaptionLbl: Label 'Billable';
        JobPlanningDateFilter: Text;

    procedure InitializeRequest(NewCurrencyField: Option "Local Currency","Foreign Currency")
    begin
        CurrencyField := NewCurrencyField;
    end;
}

