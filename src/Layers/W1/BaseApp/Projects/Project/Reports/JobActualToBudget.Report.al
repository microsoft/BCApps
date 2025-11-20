// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Reports;

using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Journal;
using System.Utilities;

report 1009 "Job Actual To Budget"
{
    AdditionalSearchTerms = 'Job Actual To Budget';
    DefaultLayout = RDLC;
    RDLCLayout = './Projects/Project/Reports/JobActualToBudget.rdlc';
    ApplicationArea = Jobs;
    Caption = 'Project Actual To Budget';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Job; Job)
        {
            RequestFilterFields = "No.", "Posting Date Filter", "Planning Date Filter";
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(JobTableCaptionFilter; TableCaption + ': ' + JobFilter)
            {
            }
            column(JobFilter; JobFilter)
            {
            }
            column(JobTaskTableCaptionFilter; "Job Task".TableCaption + ': ' + JobTaskFilter)
            {
            }
            column(JobTaskFilter; JobTaskFilter)
            {
            }
            column(EmptyString; '')
            {
            }
            column(JobCalcBatchesCurrencyField; JobCalcBatches.GetCurrencyCode(Job, 0, CurrencyFieldReq))
            {
            }
            column(JobCalcBatches3CurrencyField; JobCalcBatches.GetCurrencyCode(Job, 3, CurrencyFieldReq))
            {
            }
            column(No_Job; "No.")
            {
            }
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
            }
            column(JobActualToBudgetCaption; JobActualToBudgetCaptionLbl)
            {
            }
            column(QuantityCaption; QuantityCaptionLbl)
            {
            }
            column(ScheduleCaption; ScheduleCaptionLbl)
            {
            }
            column(UsageCaption; UsageCaptionLbl)
            {
            }
            column(DifferenceCaption; DifferenceCaptionLbl)
            {
            }
            dataitem("Job Task"; "Job Task")
            {
                DataItemLink = "Job No." = field("No.");
                DataItemTableView = sorting("Job No.", "Job Task No.");
                RequestFilterFields = "Job Task No.";
                column(Desc_Job; Job.Description)
                {
                }
                column(JobTaskNo_JobTask; "Job Task No.")
                {
                }
                column(Description_JobTask; Description)
                {
                }
                column(JobTaskNoCaption; JobTaskNoCaptionLbl)
                {
                }
                dataitem(FirstBuffer; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                    column(Amt1; Amt[1])
                    {
                        DecimalPlaces = 0 : 5;
                    }
                    column(Amt2; Amt[2])
                    {
                        DecimalPlaces = 0 : 5;
                    }
                    column(Amt3; Amt[3])
                    {
                        DecimalPlaces = 0 : 5;
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
                    column(Amt7; Amt[7])
                    {
                    }
                    column(Amt8; Amt[8])
                    {
                    }
                    column(Amt9; Amt[9])
                    {
                    }
                    column(JobDiffBufferType1; TempJobDiffBuffer.Type)
                    {
                    }
                    column(JobDiffBufferNo; TempJobDiffBuffer."No.")
                    {
                    }
                    column(JobDiffBufferUOMcode; TempJobDiffBuffer."Unit of Measure code")
                    {
                    }
                    column(JobDiffBufferWorkTypeCode; TempJobDiffBuffer."Work Type Code")
                    {
                    }
                    column(ShowFirstBuffer; ShowFirstBuffer)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        Clear(ShowFirstBuffer);

                        Clear(Amt);
                        if Number = 1 then begin
                            if not TempJobDiffBuffer.Find('-') then
                                CurrReport.Break();
                        end else
                            if TempJobDiffBuffer.Next() = 0 then
                                CurrReport.Break();
                        Amt[1] := TempJobDiffBuffer.Quantity;
                        Amt[4] := TempJobDiffBuffer."Total Cost";
                        Amt[7] := TempJobDiffBuffer."Line Amount";

                        TempJobDiffBuffer2 := TempJobDiffBuffer;
                        if TempJobDiffBuffer2.Find() then begin
                            Amt[2] := TempJobDiffBuffer2.Quantity;
                            Amt[5] := TempJobDiffBuffer2."Total Cost";
                            Amt[8] := TempJobDiffBuffer2."Line Amount";
                            TempJobDiffBuffer2.Delete();
                        end;
                        Amt[3] := Amt[1] - Amt[2];
                        Amt[6] := Amt[4] - Amt[5];
                        Amt[9] := Amt[7] - Amt[8];

                        PrintJobTask := false;
                        for I := 1 to 9 do
                            if Amt[I] <> 0 then
                                PrintJobTask := true;
                        if not PrintJobTask then
                            CurrReport.Skip();
                        for I := 2 to 9 do begin
                            JTTotalAmt[I] := JTTotalAmt[I] + Amt[I];
                            JobTotalAmt[I] := JobTotalAmt[I] + Amt[I];
                        end;

                        ShowFirstBuffer := 1;
                    end;
                }
                dataitem(SecondBuffer; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                    column(JobDiffBuffer2Type1; TempJobDiffBuffer2.Type)
                    {
                    }
                    column(JobDiffBuffer2No; TempJobDiffBuffer2."No.")
                    {
                    }
                    column(JobDiffBuffer2UOMcode; TempJobDiffBuffer2."Unit of Measure code")
                    {
                    }
                    column(JobDiffBuffer2WorkTypeCode; TempJobDiffBuffer2."Work Type Code")
                    {
                    }
                    column(Amt12; Amt[1])
                    {
                        DecimalPlaces = 0 : 5;
                    }
                    column(Amt21; Amt[2])
                    {
                        DecimalPlaces = 0 : 5;
                    }
                    column(Amt39; Amt[3])
                    {
                        DecimalPlaces = 0 : 5;
                    }
                    column(Amt40; Amt[4])
                    {
                    }
                    column(Amt55; Amt[5])
                    {
                    }
                    column(Amt66; Amt[6])
                    {
                    }
                    column(Amt77; Amt[7])
                    {
                    }
                    column(Amt88; Amt[8])
                    {
                    }
                    column(Amt99; Amt[9])
                    {
                    }
                    column(ShowSecondBuffer; ShowSecondBuffer)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        Clear(ShowSecondBuffer);

                        Clear(Amt);
                        if Number = 1 then begin
                            if not TempJobDiffBuffer2.Find('-') then
                                CurrReport.Break();
                        end else
                            if TempJobDiffBuffer2.Next() = 0 then
                                CurrReport.Break();
                        Amt[2] := TempJobDiffBuffer2.Quantity;
                        Amt[5] := TempJobDiffBuffer2."Total Cost";
                        Amt[8] := TempJobDiffBuffer2."Line Amount";
                        Amt[3] := Amt[1] - Amt[2];
                        Amt[6] := Amt[4] - Amt[5];
                        Amt[9] := Amt[7] - Amt[8];

                        PrintJobTask := false;
                        for I := 1 to 9 do
                            if Amt[I] <> 0 then
                                PrintJobTask := true;
                        if not PrintJobTask then
                            CurrReport.Skip();
                        for I := 2 to 9 do begin
                            JTTotalAmt[I] := JTTotalAmt[I] + Amt[I];
                            JobTotalAmt[I] := JobTotalAmt[I] + Amt[I];
                        end;

                        ShowSecondBuffer := 2;
                    end;
                }
                dataitem(JobTaskTotal; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = const(1));
                    column(JTTotalAmt4; JTTotalAmt[4])
                    {
                    }
                    column(JTTotalAmt5; JTTotalAmt[5])
                    {
                    }
                    column(JTTotalAmt6; JTTotalAmt[6])
                    {
                    }
                    column(JTTotalAmt7; JTTotalAmt[7])
                    {
                    }
                    column(JTTotalAmt8; JTTotalAmt[8])
                    {
                    }
                    column(JTTotalAmt9; JTTotalAmt[9])
                    {
                    }
                    column(JobTaskTableCaptionJobTask; TotalForTxt + ' ' + "Job Task".TableCaption + ' ' + "Job Task"."Job Task No.")
                    {
                    }
                    column(ShowTotalJobTask; (TotalForTxt + ' ' + "Job Task".TableCaption + ' ' + "Job Task"."Job Task No.") <> '')
                    {
                    }
                }

                trigger OnAfterGetRecord()
                begin
                    if "Job Task Type" <> "Job Task Type"::Posting then
                        CurrReport.Skip();
                    Clear(JobCalcBatches);
                    JobCalcBatches.CalculateActualToBudget(
                      Job, "Job Task", TempJobDiffBuffer, TempJobDiffBuffer2, CurrencyFieldReq);
                    if not TempJobDiffBuffer.Find('-') then
                        if not TempJobDiffBuffer2.Find('-') then
                            CurrReport.Skip();
                    for I := 1 to 9 do
                        JTTotalAmt[I] := 0;
                end;
            }
            dataitem(JobTotal; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(JobTotalAmt4; JobTotalAmt[4])
                {
                }
                column(JobTotalAmt5; JobTotalAmt[5])
                {
                }
                column(JobTotalAmt6; JobTotalAmt[6])
                {
                }
                column(JobTotalAmt7; JobTotalAmt[7])
                {
                }
                column(JobTotalAmt8; JobTotalAmt[8])
                {
                }
                column(JobTotalAmt9; JobTotalAmt[9])
                {
                }
                column(ShowTotalJob; TotalForTxt + ' ' + Job.TableCaption + ' ' + Job."No." <> '')
                {
                }
                column(JobTableCaptionNo_Job; TotalForTxt + ' ' + Job.TableCaption + ' ' + Job."No.")
                {
                }
            }

            trigger OnAfterGetRecord()
            begin
                for I := 1 to 9 do
                    JobTotalAmt[I] := 0;
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Project Actual To Budget';
        AboutText = 'Get an overview of actual vs. budgeted amounts for selected projects.\\Note: This report is not available in the US, Canada, and Mexico. Instead, use the Project Actual to Budget (Cost) (10210) or Project Actual to Budget (Price) (10211) reports.';
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(CurrencyField; CurrencyFieldReq)
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
    end;

    var
        TempJobDiffBuffer: Record "Job Difference Buffer" temporary;
        TempJobDiffBuffer2: Record "Job Difference Buffer" temporary;
        JobCalcBatches: Codeunit "Job Calculate Batches";
        Amt: array[9] of Decimal;
        JTTotalAmt: array[9] of Decimal;
        JobTotalAmt: array[9] of Decimal;
        CurrencyFieldReq: Option "Local Currency","Foreign Currency";
        JobFilter: Text;
        JobTaskFilter: Text;
        PrintJobTask: Boolean;
        I: Integer;
        TotalForTxt: Label 'Total for';
        ShowFirstBuffer: Integer;
        ShowSecondBuffer: Integer;
        CurrReportPageNoCaptionLbl: Label 'Page';
        JobActualToBudgetCaptionLbl: Label 'Project Actual To Budget';
        QuantityCaptionLbl: Label 'Quantity';
        ScheduleCaptionLbl: Label 'Budget';
        UsageCaptionLbl: Label 'Usage';
        DifferenceCaptionLbl: Label 'Difference';
        JobTaskNoCaptionLbl: Label 'Project Task No.';

    procedure InitializeRequest(NewCurrencyField: Option "Local Currency","Foreign Currency")
    begin
        CurrencyFieldReq := NewCurrencyField;
    end;
}

