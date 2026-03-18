// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Job;

using Microsoft.Projects.Project.Journal;

report 1087 "Change Job Dates"
{
    AdditionalSearchTerms = 'Change Job Planning Line Dates';
    ApplicationArea = Jobs;
    Caption = 'Change Project Planning Line Dates';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem("Job Task"; "Job Task")
        {
            DataItemTableView = sorting("Job No.", "Job Task No.");
            RequestFilterFields = "Job No.", "Job Task No.";

            trigger OnAfterGetRecord()
            begin
                Clear(CalculateBatches);
                if ChangePlanningDate then
                    if Linetype2 <> Linetype2::" " then
                        CalculateBatches.ChangePlanningDates(
                          "Job Task", ScheduleLine2, ContractLine2, PeriodLength2, FixedDate2, StartingDate2, EndingDate2);
                Clear(CalculateBatches);
                if ChangeCurrencyDate then
                    if Linetype <> Linetype::" " then
                        CalculateBatches.ChangeCurrencyDates(
                          "Job Task", ScheduleLine, ContractLine,
                          PeriodLength, FixedDate, StartingDate, EndingDate);
            end;

            trigger OnPostDataItem()
            begin
                CalculateBatches.ChangeDatesEnd();
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
                    group("Currency Date")
                    {
                        Caption = 'Currency Date';
                        field(ChangeCurrencyDate; ChangeCurrencyDate)
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Change Currency Date';
                            ToolTip = 'Specifies that currencies will be updated on the projects that are included in the batch job.';
                        }
                        field(ChangeDateExpressionCurrency; PeriodLength)
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Change Date Expression';
                            ToolTip = 'Specifies how the dates on the entries that are copied will be changed by using a date formula.';

                            trigger OnValidate()
                            begin
                                FixedDate := 0D;
                            end;
                        }
                        field(FixedDateCurrency; FixedDate)
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Fixed Date';
                            ToolTip = 'Specifies a date that the currency date on all planning lines will be moved to.';

                            trigger OnValidate()
                            begin
                                Clear(PeriodLength);
                            end;
                        }
                        field(IncludeLineTypeCurrency; Linetype)
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Include Line type';
                            OptionCaption = ' ,Budget,Billable,Budget+Billable';
                            ToolTip = 'Specifies the project planning line type you want to change the currency date for.';
                        }
                        field(IncludeCurrDateFrom; StartingDate)
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Include Curr. Date From';
                            ToolTip = 'Specifies the starting date of the period for which you want currency dates to be moved. Only planning lines with a currency date on or after this date are included.';
                        }
                        field(IncludeCurrDateTo; EndingDate)
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Include Curr. Date To';
                            ToolTip = 'Specifies the ending date of the period for which you want currency dates to be moved. Only planning lines with a currency date on or before this date are included.';
                        }
                    }
                    group("Planning Date")
                    {
                        Caption = 'Planning Date';
                        field(ChangePlanningDate; ChangePlanningDate)
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Change Planning Date';
                            ToolTip = 'Specifies that planning dates will be changed on the projects that are included in the batch job.';
                        }
                        field(ChangeDateExpressionPlanning; PeriodLength2)
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Change Date Expression';
                            ToolTip = 'Specifies how the dates on the entries that are copied will be changed by using a date formula.';

                            trigger OnValidate()
                            begin
                                FixedDate2 := 0D;
                            end;
                        }
                        field(FixedDatePlanning; FixedDate2)
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Fixed Date';
                            ToolTip = 'Specifies a date that the planning date on all planning lines will be moved to.';

                            trigger OnValidate()
                            begin
                                Clear(PeriodLength2);
                            end;
                        }
                        field(IncludeLineTypePlanning; Linetype2)
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Include Line type';
                            OptionCaption = ' ,Budget,Billable,Budget+Billable';
                            ToolTip = 'Specifies the project planning line type you want to change the planning date for.';
                        }
                        field(IncludePlanDateFrom; StartingDate2)
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Include Plan. Date From';
                            ToolTip = 'Specifies the starting date of the period for which you want a Planning Date to be moved. Only planning lines with a Planning Date on or after this date are included.';
                        }
                        field(IncludePlanDateTo; EndingDate2)
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Include Plan. Date To';
                            ToolTip = 'Specifies the ending date of the period for which you want a Planning Date to be moved. Only planning lines with a Planning Date on or before this date are included.';
                        }
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
        ScheduleLine := false;
        ContractLine := false;
        if Linetype = Linetype::Budget then
            ScheduleLine := true;
        if Linetype = Linetype::Billable then
            ContractLine := true;
        if Linetype = Linetype::"Budget+Billable" then begin
            ScheduleLine := true;
            ContractLine := true;
        end;

        ScheduleLine2 := false;
        ContractLine2 := false;
        if Linetype2 = Linetype2::Budget then
            ScheduleLine2 := true;
        if Linetype2 = Linetype2::Billable then
            ContractLine2 := true;
        if Linetype2 = Linetype2::"Budget+Billable" then begin
            ScheduleLine2 := true;
            ContractLine2 := true;
        end;
        if (Linetype = Linetype::" ") and (Linetype2 = Linetype2::" ") then
            Error(Text000);
        if not ChangePlanningDate and not ChangeCurrencyDate then
            Error(Text000);
        if ChangeCurrencyDate and (Linetype = Linetype::" ") then
            Error(Text001);
        if ChangePlanningDate and (Linetype2 = Linetype2::" ") then
            Error(Text002);
    end;

    var
        CalculateBatches: Codeunit "Job Calculate Batches";
        PeriodLength: DateFormula;
        PeriodLength2: DateFormula;
        ScheduleLine: Boolean;
        ContractLine: Boolean;
        ScheduleLine2: Boolean;
        ContractLine2: Boolean;
        Linetype: Option " ",Budget,Billable,"Budget+Billable";
        Linetype2: Option " ",Budget,Billable,"Budget+Billable";
        FixedDate: Date;
        FixedDate2: Date;
        StartingDate: Date;
        EndingDate: Date;
        StartingDate2: Date;
        EndingDate2: Date;
#pragma warning disable AA0074
        Text000: Label 'There is nothing to change.';
#pragma warning restore AA0074
        ChangePlanningDate: Boolean;
        ChangeCurrencyDate: Boolean;
#pragma warning disable AA0074
        Text001: Label 'You must specify a Line Type for changing the currency date.';
        Text002: Label 'You must specify a Line Type for changing the planning date.';
#pragma warning restore AA0074
}

