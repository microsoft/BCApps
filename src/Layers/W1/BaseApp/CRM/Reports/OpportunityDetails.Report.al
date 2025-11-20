// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Reports;

using Microsoft.CRM.Opportunity;
using Microsoft.CRM.Task;

report 5068 "Opportunity - Details"
{
    DefaultLayout = RDLC;
    RDLCLayout = './CRM/Reports/OpportunityDetails.rdlc';
    ApplicationArea = RelationshipMgmt;
    Caption = 'Opportunity - Details';
    UsageCategory = ReportsAndAnalysis;
    WordMergeDataItem = Opportunity;

    dataset
    {
        dataitem(Opportunity; Opportunity)
        {
            RequestFilterFields = "No.";
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(Filter_Opportunity; TableCaption + OppFilter)
            {
            }
            column(OppFilter; OppFilter)
            {
            }
            column(Desc_Opportunity; TableCaption + ': ' + "No." + ', ' + Description)
            {
            }
            column(DateClosed_Opp; Format("Date Closed"))
            {
            }
            column(No_Opp; "No.")
            {
            }
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
            }
            column(OpportunityDetailsCaption; OpportunityDetailsCaptionLbl)
            {
            }
            column(OpportunityDateClosedCaption; OpportunityDateClosedCaptionLbl)
            {
            }
            dataitem(PreTodo; "To-do")
            {
                DataItemLink = "Opportunity No." = field("No.");
                DataItemTableView = sorting("Opportunity No.", Date, Closed) order(ascending) where("Opportunity Entry No." = const(0), "System To-do Type" = filter(Team | Organizer));
                column(Status_Pretodo; Status)
                {
                    IncludeCaption = true;
                }
                column(Date_PreTodo; Format(Date))
                {
                }
                column(Desc_PreTodo; Description)
                {
                    IncludeCaption = true;
                }
                column(Priority_Pretodo; Priority)
                {
                    IncludeCaption = true;
                }
                column(Type_PreTodo; Type)
                {
                    IncludeCaption = true;
                }
                column(No_PreTodo; "No.")
                {
                }
                column(InitialTasksCaption; InitialTasksCaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if ("Team Code" <> '') and ("System To-do Type" <> "System To-do Type"::Team) then
                        CurrReport.Skip();
                end;
            }
            dataitem("Opportunity Entry"; "Opportunity Entry")
            {
                DataItemLink = "Opportunity No." = field("No.");
                DataItemTableView = sorting("Opportunity No.") order(ascending) where("Sales Cycle Stage" = filter(<> 0));
                column(SalesCycleStage_OppEntry; "Sales Cycle Stage")
                {
                }
                column(Desc_SalesCycleStage; SalesCycleStage.Description)
                {
                }
                column(DateChange_OppEntry; Format("Date of Change"))
                {
                }
                column(Estimated_OppEntry; Format("Estimated Close Date"))
                {
                }
                column(Active_OppEntry; Active)
                {
                    IncludeCaption = true;
                }
                column(QuoteFormat_OppEntry; Format(SalesCycleStage."Quote Required"))
                {
                }
                column(Skip2_SalesCycleStage; Format(SalesCycleStage."Allow Skip"))
                {
                }
                column(Active2_OppEntry; Format(Active))
                {
                }
                column(StageCaption; StageCaptionLbl)
                {
                }
                column(SalesCycleStageDescriptionCaption; SalesCycleStageDescriptionCaptionLbl)
                {
                }
                column(SalesCycleStageQuoteRequiredCaption; SalesCycleStageQuoteRequiredCaptionLbl)
                {
                }
                column(SalesCycleStageAllowSkipCaption; SalesCycleStageAllowSkipCaptionLbl)
                {
                }
                column(OpportunityEntryDateofChangeCaption; OpportunityEntryDateofChangeCaptionLbl)
                {
                }
                column(OpportunityEntryEstimatedCloseDateCaption; OpportunityEntryEstimatedCloseDateCaptionLbl)
                {
                }
                dataitem("To-do"; "To-do")
                {
                    DataItemLink = "Opportunity No." = field("Opportunity No."), "Opportunity Entry No." = field("Entry No.");
                    DataItemTableView = sorting("Opportunity No.", Date, Closed) order(ascending) where("System To-do Type" = filter(Team | Organizer));
                    column(Status_Todo; Status)
                    {
                        IncludeCaption = true;
                    }
                    column(Date_Todo; Format(Date))
                    {
                    }
                    column(Desc_Todo; Description)
                    {
                        IncludeCaption = true;
                    }
                    column(Priority_Todo; Priority)
                    {
                        IncludeCaption = true;
                    }
                    column(Type_Todo; Type)
                    {
                        IncludeCaption = true;
                    }
                    column(No_Todo; "No.")
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if ("Team Code" <> '') and ("System To-do Type" <> "System To-do Type"::Team) then
                            CurrReport.Skip();
                        if PlannedStartingDate = 0D then
                            PlannedStartingDate := Date;
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    if SalesCycleStage.Get("Sales Cycle Code", "Sales Cycle Stage") then
                        CurrStage := "Sales Cycle Stage";
                    if not ("Sales Cycle Stage" = LastSalesCycleStage) then
                        PlannedStartingDate := 0D;
                    LastSalesCycleStage := "Sales Cycle Stage";
                end;
            }
            dataitem("Sales Cycle Stage"; "Sales Cycle Stage")
            {
                DataItemLink = "Sales Cycle Code" = field("Sales Cycle Code");
                DataItemTableView = sorting("Sales Cycle Code", Stage);
                PrintOnlyIfDetail = true;
                column(Stage_SalesCycleStage; Stage)
                {
                    IncludeCaption = true;
                }
                column(Quote2_SalesCycleStage; "Quote Required")
                {
                    IncludeCaption = true;
                }
                column(Skip3_SalesCycleStage; "Allow Skip")
                {
                    IncludeCaption = true;
                }
                column(Desc_SalescCycleStage; Description)
                {
                    IncludeCaption = true;
                }
                column(Quote_SalesCycleStage; Format("Quote Required"))
                {
                }
                column(Skip1_SalesCycleStage; Format("Allow Skip"))
                {
                }
                dataitem("Activity Step"; "Activity Step")
                {
                    DataItemLink = "Activity Code" = field("Activity Code");
                    DataItemTableView = sorting("Activity Code", "Step No.");
                    column(Desc_ActivityStep; Description)
                    {
                        IncludeCaption = true;
                    }
                    column(Priority_ActivityStep; Priority)
                    {
                        IncludeCaption = true;
                    }
                    column(Type_ActivityStep; Type)
                    {
                        IncludeCaption = true;
                    }
                    column(StartDate_ActivityStep; Format(ActivityStartDate))
                    {
                    }
                    column(PlannedActivityStatus; SelectStr(ActivityStatus + 1, Text001))
                    {
                    }
                    column(StepNo_ActivityStep; "Step No.")
                    {
                    }
                    column(StatusCaption; StatusCaptionLbl)
                    {
                    }
                    column(ActivityStartDateCaption; ActivityStartDateCaptionLbl)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        ActivityStartDate := CalcDate("Date Formula", StageStartDate);
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    if PlannedStartingDate <> 0D then
                        StageStartDate := CalcDate("Date Formula", PlannedStartingDate);
                    PlannedStartingDate := StageStartDate;
                end;

                trigger OnPreDataItem()
                begin
                    SetFilter(Stage, '>%1', CurrStage);
                    if CurrStage = 0 then
                        PlannedStartingDate := WorkDate();
                end;
            }
        }
    }

    requestpage
    {
        AboutTitle = 'About Opportunity - Details';
        AboutText = 'Get an overview of sales stages, to-dos, and planned to-dos for an opportunity.';

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
        PreTodoDateCaption = 'Starting Date';
        PreTodoNoCaption = 'To-do No.';
    }

    trigger OnPreReport()
    begin
        OppFilter := Opportunity.GetFilters();
    end;

    var
        SalesCycleStage: Record "Sales Cycle Stage";
        OppFilter: Text;
        StageStartDate: Date;
        ActivityStartDate: Date;
        ActivityStatus: Option Planned;
        CurrStage: Integer;
#pragma warning disable AA0074
        Text001: Label 'Planned';
#pragma warning restore AA0074
        LastSalesCycleStage: Integer;
        PlannedStartingDate: Date;
        CurrReportPageNoCaptionLbl: Label 'Page';
        OpportunityDetailsCaptionLbl: Label 'Opportunity - Details';
        OpportunityDateClosedCaptionLbl: Label 'Date Closed';
        InitialTasksCaptionLbl: Label 'Initial Tasks';
        StageCaptionLbl: Label 'Stage';
        SalesCycleStageDescriptionCaptionLbl: Label 'Description';
        SalesCycleStageQuoteRequiredCaptionLbl: Label 'Quote Required';
        SalesCycleStageAllowSkipCaptionLbl: Label 'Allow Skip';
        OpportunityEntryDateofChangeCaptionLbl: Label 'Date of Change';
        OpportunityEntryEstimatedCloseDateCaptionLbl: Label 'Estimated Close Date';
        StatusCaptionLbl: Label 'Status';
        ActivityStartDateCaptionLbl: Label 'Date';
}

