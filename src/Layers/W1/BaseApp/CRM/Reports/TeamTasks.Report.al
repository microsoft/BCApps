// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Reports;

using Microsoft.CRM.Task;

report 5059 "Team - Tasks"
{
    DefaultLayout = RDLC;
    RDLCLayout = './CRM/Reports/TeamTasks.rdlc';
    ApplicationArea = RelationshipMgmt;
    Caption = 'Team Tasks';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("To-do"; "To-do")
        {
            DataItemTableView = sorting("Team Code", Date) where("System To-do Type" = const(Team));
            RequestFilterFields = "Team Code", Date, "Campaign No.";
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(Task__TABLECAPTION__________TaskFilter; TableCaption + ': ' + TaskFilter)
            {
            }
            column(TaskFilter; TaskFilter)
            {
            }
            column(Task__Team_Code_; "Team Code")
            {
            }
            column(Task__Team_Name_; "Team Name")
            {
            }
            column(Task__No__; "No.")
            {
            }
            column(Task_Date; Format(Date))
            {
            }
            column(Task_Type; Type)
            {
            }
            column(Task_Description; Description)
            {
            }
            column(Task__Contact_No__; "Contact No.")
            {
            }
            column(Task__Campaign_No__; "Campaign No.")
            {
            }
            column(Task_Status; Status)
            {
            }
            column(Task_Priority; Priority)
            {
            }
            column(Task__Salesperson_Code_; "Salesperson Code")
            {
            }
            column(Task__Opportunity_No__; "Opportunity No.")
            {
            }
            column(Task__Date_Closed_; Format("Date Closed"))
            {
            }
            column(Team___TaskCaption; Team___TaskCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Task__No__Caption; FieldCaption("No."))
            {
            }
            column(Task_DateCaption; Task_DateCaptionLbl)
            {
            }
            column(Task_TypeCaption; FieldCaption(Type))
            {
            }
            column(Task_DescriptionCaption; FieldCaption(Description))
            {
            }
            column(Task__Contact_No__Caption; FieldCaption("Contact No."))
            {
            }
            column(Task__Campaign_No__Caption; FieldCaption("Campaign No."))
            {
            }
            column(Task_StatusCaption; FieldCaption(Status))
            {
            }
            column(Task_PriorityCaption; FieldCaption(Priority))
            {
            }
            column(Task__Salesperson_Code_Caption; FieldCaption("Salesperson Code"))
            {
            }
            column(Task__Opportunity_No__Caption; FieldCaption("Opportunity No."))
            {
            }
            column(Task__Date_Closed_Caption; Task__Date_Closed_CaptionLbl)
            {
            }
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
        TaskFilter := "To-do".GetFilters();
    end;

    var
        TaskFilter: Text;
        Team___TaskCaptionLbl: Label 'Team - Task';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Task_DateCaptionLbl: Label 'Starting Date';
        Task__Date_Closed_CaptionLbl: Label 'Date Closed';
}

