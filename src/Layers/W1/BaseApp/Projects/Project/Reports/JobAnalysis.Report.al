// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Reports;

using Microsoft.Projects.Project.Job;
using System.Utilities;

report 1008 "Job Analysis"
{
    AdditionalSearchTerms = 'project overview, Job Analysis';
    DefaultLayout = RDLC;
    RDLCLayout = './Projects/Project/Reports/JobAnalysis.rdlc';
    ApplicationArea = Jobs;
    Caption = 'Project Analysis';
    UsageCategory = ReportsAndAnalysis;
    DataAccessIntent = ReadOnly;

    dataset
    {
        dataitem(Job; Job)
        {
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Posting Date Filter", "Planning Date Filter";
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(JobtableCaptJobFilter; TableCaption + ': ' + JobFilter)
            {
            }
            column(JobFilter; JobFilter)
            {
            }
            column(JobTasktableCaptFilter; "Job Task".TableCaption + ': ' + JobTaskFilter)
            {
            }
            column(JobTaskFilter; JobTaskFilter)
            {
            }
            column(No_Job; "No.")
            {
            }
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
            }
            column(JobAnalysisCapt; JobAnalysisCaptLbl)
            {
            }
            dataitem("Job Task"; "Job Task")
            {
                DataItemLink = "Job No." = field("No.");
                DataItemTableView = sorting("Job No.", "Job Task No.");
                RequestFilterFields = "Job Task No.";
                column(HeadLineText8; HeadLineText[8])
                {
                }
                column(HeadLineText7; HeadLineText[7])
                {
                }
                column(HeadLineText6; HeadLineText[6])
                {
                }
                column(HeadLineText5; HeadLineText[5])
                {
                }
                column(HeadLineText4; HeadLineText[4])
                {
                }
                column(HeadLineText3; HeadLineText[3])
                {
                }
                column(HeadLineText2; HeadLineText[2])
                {
                }
                column(HeadLineText1; HeadLineText[1])
                {
                }
                column(Description_Job; Job.Description)
                {
                }
                column(DescriptionCaption; DescriptionCaptionLbl)
                {
                }
                column(JobTaskNoCapt; JobTaskNoCaptLbl)
                {
                }
                dataitem(BlankLine; "Integer")
                {
                    DataItemTableView = sorting(Number);

                    trigger OnPreDataItem()
                    begin
                        SetRange(Number, 1, "Job Task"."No. of Blank Lines");
                    end;
                }
                dataitem("Integer"; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = const(1));
                    column(JobTaskNo_JobTask; "Job Task"."Job Task No.")
                    {
                    }
                    column(Indentation_JobTask; PadStr('', 2 * "Job Task".Indentation) + "Job Task".Description)
                    {
                    }
                    column(ShowIntBody1; "Job Task"."Job Task Type" in ["Job Task"."Job Task Type"::Heading, "Job Task"."Job Task Type"::"Begin-Total"])
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
                    column(Amt7; Amt[7])
                    {
                    }
                    column(Amt8; Amt[8])
                    {
                    }
                    column(ShowIntBody2; "Job Task"."Job Task Type" in ["Job Task"."Job Task Type"::Total, "Job Task"."Job Task Type"::"End-Total"])
                    {
                    }
                    column(ShowIntBody3; ("Job Task"."Job Task Type" in ["Job Task"."Job Task Type"::Posting]) and PrintSection)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        PrintSection := true;
                        if ExcludeJobTask then begin
                            PrintSection := false;
                            for I := 1 to 8 do
                                if (Amt[I] <> 0) and (AmountField[I] <> AmountField[I] ::" ") then
                                    PrintSection := true;
                        end;
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    Clear(JobCalcStatistics);
                    JobCalcStatistics.ReportAnalysis(Job, "Job Task", Amt, AmountField, CurrencyField, false);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                JobCalcStatistics.GetHeadLineText(AmountField, CurrencyField, HeadLineText, Job);
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Project Analysis';
        AboutText = 'Get a financial overview of your projects based on your input.';
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field("AmountField[1]"; AmountField[1])
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Amount Field 1 ';
                        OptionCaption = ' ,Budget Price,Usage Price,Billable Price,Invoiced Price,Budget Cost,Usage Cost,Billable Cost,Invoiced Cost,Budget Profit,Usage Profit,Billable Profit,Invoiced Profit';
                        ToolTip = 'Specifies that you want to use a combination of the available Amount fields to create your own analysis. For each field, select one of the following prices, costs, or profit values: Budget, Usage, Billable, and Invoiced.';
                    }
                    field("CurrencyField[1]"; CurrencyField[1])
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Currency Field 1';
                        OptionCaption = 'Local Currency,Foreign Currency';
                        ToolTip = 'Specifies if the currency is specified in the local currency or in a foreign currency.';
                    }
                    field("AmountField[2]"; AmountField[2])
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Amount Field 2';
                        OptionCaption = ' ,Budget Price,Usage Price,Billable Price,Invoiced Price,Budget Cost,Usage Cost,Billable Cost,Invoiced Cost,Budget Profit,Usage Profit,Billable Profit,Invoiced Profit';
                        ToolTip = 'Specifies an Amount field that you use to create your own analysis. For each field, select one of the following prices, costs, or profit values: Budget, Usage, Billable, and Invoiced.';
                    }
                    field("CurrencyField[2]"; CurrencyField[2])
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Currency Field 2';
                        OptionCaption = 'Local Currency,Foreign Currency';
                        ToolTip = 'Specifies if the currency is specified in the local currency or in a foreign currency.';
                    }
                    field("AmountField[3]"; AmountField[3])
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Amount Field 3';
                        OptionCaption = ' ,Budget Price,Usage Price,Billable Price,Invoiced Price,Budget Cost,Usage Cost,Billable Cost,Invoiced Cost,Budget Profit,Usage Profit,Billable Profit,Invoiced Profit';
                        ToolTip = 'Specifies an Amount field that you use to create your own analysis. For each field, select one of the following prices, costs, or profit values: Budget, Usage, Billable, and Invoiced.';
                    }
                    field("CurrencyField[3]"; CurrencyField[3])
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Currency Field 3';
                        OptionCaption = 'Local Currency,Foreign Currency';
                        ToolTip = 'Specifies if the currency is specified in the local currency or in a foreign currency.';
                    }
                    field("AmountField[4]"; AmountField[4])
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Amount Field 4';
                        OptionCaption = ' ,Budget Price,Usage Price,Billable Price,Invoiced Price,Budget Cost,Usage Cost,Billable Cost,Invoiced Cost,Budget Profit,Usage Profit,Billable Profit,Invoiced Profit';
                        ToolTip = 'Specifies an Amount field that you use to create your own analysis. For each field, select one of the following prices, costs, or profit values: Budget, Usage, Billable, and Invoiced.';
                    }
                    field("CurrencyField[4]"; CurrencyField[4])
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Currency Field 4';
                        OptionCaption = 'Local Currency,Foreign Currency';
                        ToolTip = 'Specifies if the currency is specified in the local currency or in a foreign currency.';
                    }
                    field("AmountField[5]"; AmountField[5])
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Amount Field 5';
                        OptionCaption = ' ,Budget Price,Usage Price,Billable Price,Invoiced Price,Budget Cost,Usage Cost,Billable Cost,Invoiced Cost,Budget Profit,Usage Profit,Billable Profit,Invoiced Profit';
                        ToolTip = 'Specifies an Amount field that you use to create your own analysis. For each field, select one of the following prices, costs, or profit values: Budget, Usage, Billable, and Invoiced.';
                    }
                    field("CurrencyField[5]"; CurrencyField[5])
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Currency Field 5';
                        OptionCaption = 'Local Currency,Foreign Currency';
                        ToolTip = 'Specifies if the currency is specified in the local currency or in a foreign currency.';
                    }
                    field("AmountField[6]"; AmountField[6])
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Amount Field 6';
                        OptionCaption = ' ,Budget Price,Usage Price,Billable Price,Invoiced Price,Budget Cost,Usage Cost,Billable Cost,Invoiced Cost,Budget Profit,Usage Profit,Billable Profit,Invoiced Profit';
                        ToolTip = 'Specifies an Amount field that you use to create your own analysis. For each field, select one of the following prices, costs, or profit values: Budget, Usage, Billable, and Invoiced.';
                    }
                    field("CurrencyField[6]"; CurrencyField[6])
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Currency Field 6';
                        OptionCaption = 'Local Currency,Foreign Currency';
                        ToolTip = 'Specifies if the currency is specified in the local currency or in a foreign currency.';
                    }
                    field("AmountField[7]"; AmountField[7])
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Amount Field 7';
                        OptionCaption = ' ,Budget Price,Usage Price,Billable Price,Invoiced Price,Budget Cost,Usage Cost,Billable Cost,Invoiced Cost,Budget Profit,Usage Profit,Billable Profit,Invoiced Profit';
                        ToolTip = 'Specifies an Amount field that you use to create your own analysis. For each field, select one of the following prices, costs, or profit values: Budget, Usage, Billable, and Invoiced.';
                    }
                    field("CurrencyField[7]"; CurrencyField[7])
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Currency Field 7';
                        OptionCaption = 'Local Currency,Foreign Currency';
                        ToolTip = 'Specifies if the currency is specified in the local currency or in a foreign currency.';
                    }
                    field("AmountField[8]"; AmountField[8])
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Amount Field 8';
                        OptionCaption = ' ,Budget Price,Usage Price,Billable Price,Invoiced Price,Budget Cost,Usage Cost,Billable Cost,Invoiced Cost,Budget Profit,Usage Profit,Billable Profit,Invoiced Profit';
                        ToolTip = 'Specifies an Amount field that you use to create your own analysis. For each field, select one of the following prices, costs, or profit values: Budget, Usage, Billable, and Invoiced.';
                    }
                    field("CurrencyField[8]"; CurrencyField[8])
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Currency Field 8';
                        OptionCaption = 'Local Currency,Foreign Currency';
                        ToolTip = 'Specifies if the currency is specified in the local currency or in a foreign currency.';
                    }
                    field(ExcludeJobTask; ExcludeJobTask)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Exclude Zero-Lines';
                        MultiLine = true;
                        ToolTip = 'Specifies that lines with zero content are excluded from the view.';
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
        JobCalcStatistics: Codeunit "Job Calculate Statistics";
        HeadLineText: array[8] of Text[50];
        Amt: array[8] of Decimal;
        AmountField: array[8] of Option " ","Budget Price","Usage Price","Billable Price","Invoiced Price","Budget Cost","Usage Cost","Billable Cost","Invoiced Cost","Budget Profit","Usage Profit","Billable Profit","Invoiced Profit";
        CurrencyField: array[8] of Option "Local Currency","Foreign Currency";
        JobFilter: Text;
        JobTaskFilter: Text;
        ExcludeJobTask: Boolean;
        PrintSection: Boolean;
        I: Integer;
        CurrReportPageNoCaptionLbl: Label 'Page';
        JobAnalysisCaptLbl: Label 'Project Analysis';
        DescriptionCaptionLbl: Label 'Description';
        JobTaskNoCaptLbl: Label 'Project Task No.';

    procedure InitializeRequest(NewAmountField: array[8] of Option " ","Budget Price","Usage Price","Billable Price","Invoiced Price","Budget Cost","Usage Cost","Billable Cost","Invoiced Cost","Budget Profit","Usage Profit","Billable Profit","Invoiced Profit"; NewCurrencyField: array[8] of Option "Local Currency","Foreign Currency"; NewExcludeJobTask: Boolean)
    begin
        AmountField[1] := NewAmountField[1];
        CurrencyField[1] := NewCurrencyField[1];
        AmountField[2] := NewAmountField[2];
        CurrencyField[2] := NewCurrencyField[2];
        AmountField[3] := NewAmountField[3];
        CurrencyField[3] := NewCurrencyField[3];
        AmountField[4] := NewAmountField[4];
        CurrencyField[4] := NewCurrencyField[4];
        AmountField[5] := NewAmountField[5];
        CurrencyField[5] := NewCurrencyField[5];
        AmountField[6] := NewAmountField[6];
        CurrencyField[6] := NewCurrencyField[6];
        AmountField[7] := NewAmountField[7];
        CurrencyField[7] := NewCurrencyField[7];
        AmountField[8] := NewAmountField[8];
        CurrencyField[8] := NewCurrencyField[8];
        ExcludeJobTask := NewExcludeJobTask;
    end;
}

