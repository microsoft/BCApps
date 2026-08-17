// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Reports;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Foundation.Company;
using Microsoft.Inventory.Item;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Planning;
using Microsoft.Projects.Resources.Resource;
using System.Utilities;

report 10215 "Job Cost Budget"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Projects/Project/Reports/JobCostBudget.rdlc';
    ApplicationArea = Jobs;
    Caption = 'Project Cost Budget';
    AdditionalSearchTerms = 'Job Cost Budget';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Job; Job)
        {
            RequestFilterFields = "No.", "Bill-to Customer No.", Status;
            column(Job_No_; "No.")
            {
            }
            column(Job_Planning_Date_Filter; "Planning Date Filter")
            {
            }
            dataitem(PageHeader; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(BudgetOptionText; BudgetOptionText)
                {
                }
                column(CompanyInformation_Name; CompanyInformation.Name)
                {
                }
                column(Title; Title)
                {
                }
                column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
                {
                }
                column(USERID; UserId)
                {
                }
                column(TIME; Time)
                {
                }
                column(Job_TABLECAPTION_____Filters______JobFilter; Job.TableCaption + ' Filters: ' + JobFilter)
                {
                }
                column(JobFilter; JobFilter)
                {
                }
                column(Job__Description_2_; Job."Description 2")
                {
                }
                column(Job_Description; Job.Description)
                {
                }
                column(Job_FIELDCAPTION__Ending_Date____________FORMAT_Job__Ending_Date__; Job.FieldCaption("Ending Date") + ': ' + Format(Job."Ending Date"))
                {
                }
                column(Job_FIELDCAPTION__Starting_Date____________FORMAT_Job__Starting_Date__; Job.FieldCaption("Starting Date") + ': ' + Format(Job."Starting Date"))
                {
                }
                column(PageHeader_Number; Number)
                {
                }
                column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
                {
                }
                column(Job_DescriptionCaption; Job_DescriptionCaptionLbl)
                {
                }
                column(Job_Planning_Line__Job_Task_No__Caption; "Job Planning Line".FieldCaption("Job Task No."))
                {
                }
                column(PADSTR____2____Job_Task__Indentation_____Job_Task__DescriptionCaption; PADSTR____2____Job_Task__Indentation_____Job_Task__DescriptionCaptionLbl)
                {
                }
                column(Job_Planning_Line_TypeCaption; "Job Planning Line".FieldCaption(Type))
                {
                }
                column(Job_Planning_Line__No__Caption; "Job Planning Line".FieldCaption("No."))
                {
                }
                column(Job_Planning_Line_QuantityCaption; "Job Planning Line".FieldCaption(Quantity))
                {
                }
                column(Job_Planning_Line__Unit_Cost__LCY__Caption; "Job Planning Line".FieldCaption("Unit Cost (LCY)"))
                {
                }
                column(Job_Planning_Line__Total_Cost__LCY__Caption; "Job Planning Line".FieldCaption("Total Cost (LCY)"))
                {
                }
                column(Job_Planning_Line__Unit_Price__LCY__Caption; "Job Planning Line".FieldCaption("Unit Price (LCY)"))
                {
                }
                column(Job_Planning_Line__Total_Price__LCY__Caption; "Job Planning Line".FieldCaption("Total Price (LCY)"))
                {
                }
                dataitem("Job Task"; "Job Task")
                {
                    DataItemLink = "Job No." = field("No.");
                    DataItemLinkReference = Job;
                    DataItemTableView = sorting("Job No.", "Job Task No.");
                    column(Job_Task_Job_No_; "Job No.")
                    {
                    }
                    column(Job_Task_Job_Task_No_; "Job Task No.")
                    {
                    }
                    dataitem(BlankLine; "Integer")
                    {
                        DataItemTableView = sorting(Number);
                        column(Job_Task___No__of_Blank_Lines_; "Job Task"."No. of Blank Lines")
                        {
                        }
                        column(BlankLine_Number; Number)
                        {
                        }

                        trigger OnPreDataItem()
                        begin
                            SetRange(Number, 1, "Job Task"."No. of Blank Lines");
                        end;
                    }
                    dataitem("Job Planning Line"; "Job Planning Line")
                    {
                        DataItemLink = "Job No." = field("No."), "Planning Date" = field("Planning Date Filter");
                        DataItemLinkReference = Job;
                        DataItemTableView = sorting("Job No.", "Job Task No.", "Schedule Line", "Planning Date") where(Type = filter(<> Text));
                        column(Job_Planning_Line__Job_Task_No__; "Job Task No.")
                        {
                        }
                        column(PADSTR____2____Job_Task__Indentation_____Job_Task__Description; PadStr('', 2 * "Job Task".Indentation) + "Job Task".Description)
                        {
                        }
                        column(Job_Planning_Line_Type; Type)
                        {
                        }
                        column(Job_Planning_Line__No__; "No.")
                        {
                        }
                        column(Job_Planning_Line_Quantity; Quantity)
                        {
                        }
                        column(Job_Planning_Line__Unit_Cost__LCY__; "Unit Cost (LCY)")
                        {
                        }
                        column(Job_Planning_Line__Total_Cost__LCY__; "Total Cost (LCY)")
                        {
                        }
                        column(Job_Planning_Line__Unit_Price__LCY__; "Unit Price (LCY)")
                        {
                        }
                        column(Job_Planning_Line__Total_Price__LCY__; "Total Price (LCY)")
                        {
                        }
                        column(Job_Task___Job_Task_Type_; "Job Task"."Job Task Type")
                        {
                        }
                        column(Job_Planning_Line_Job_No_; "Job No.")
                        {
                        }
                        column(Job_Planning_Line_Line_No_; "Line No.")
                        {
                        }
                        column(Job_Planning_Line_Planning_Date; "Planning Date")
                        {
                        }

                        trigger OnPreDataItem()
                        begin
                            case "Job Task"."Job Task Type" of
                                "Job Task"."Job Task Type"::Posting:
                                    SetRange("Job Task No.", "Job Task"."Job Task No.");
                                "Job Task"."Job Task Type"::Heading, "Job Task"."Job Task Type"::"Begin-Total":
                                    CurrReport.Break();
                                "Job Task"."Job Task Type"::Total, "Job Task"."Job Task Type"::"End-Total":
                                    SetFilter("Job Task No.", "Job Task".Totaling);
                            end;
                            case BudgetAmountsPer of
                                BudgetAmountsPer::Schedule:
                                    SetFilter("Line Type", '%1|%2', "Line Type"::Budget, "Line Type"::"Both Budget and Billable");
                                BudgetAmountsPer::Contract:
                                    SetFilter("Line Type", '%1|%2', "Line Type"::Billable, "Line Type"::"Both Budget and Billable");
                            end;
                        end;
                    }
                    dataitem("Integer"; "Integer")
                    {
                        DataItemTableView = sorting(Number) where(Number = const(1));
                        column(PADSTR____2____Job_Task__Indentation_____Job_Task__Description_Control1480007; PadStr('', 2 * "Job Task".Indentation) + "Job Task".Description)
                        {
                        }
                        column(Job_Task___Job_Task_No__; "Job Task"."Job Task No.")
                        {
                        }
                        column(Job_Task___Job_Task_Type__Control1020002; "Job Task"."Job Task Type")
                        {
                        }
                        column(Job_Task___New_Page_; "Job Task"."New Page")
                        {
                        }
                        column(PADSTR____2____Job_Task__Indentation_____Job_Task__Description_Control1480009; PadStr('', 2 * "Job Task".Indentation) + "Job Task".Description)
                        {
                        }
                        column(Job_Task___Job_Task_No___Control1480010; "Job Task"."Job Task No.")
                        {
                        }
                        column(Job_Planning_Line___Total_Cost__LCY__; "Job Planning Line"."Total Cost (LCY)")
                        {
                        }
                        column(Job_Planning_Line___Total_Price__LCY__; "Job Planning Line"."Total Price (LCY)")
                        {
                        }
                        column(Integer_Number; Number)
                        {
                        }
                    }
                }
            }

            trigger OnAfterGetRecord()
            begin
                Title := StrSubstNo(Text000, "No.");
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
                    field(BudgetAmountsPer; BudgetAmountsPer)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Budget Amounts Per';
                        OptionCaption = 'Budget,Billable';
                        ToolTip = 'Specifies if the budget amounts must be based on budgets or billables.';
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
        CompanyInformation.Get();
        JobFilter := Job.GetFilters();
        if BudgetAmountsPer = BudgetAmountsPer::Schedule then
            BudgetOptionText := Text003
        else
            BudgetOptionText := Text004;
    end;

    var
        CompanyInformation: Record "Company Information";
        JobFilter: Text;
        Title: Text[100];
        Text000: Label 'Project Cost Budget for Project: %1';
        BudgetAmountsPer: Option Schedule,Contract;
        BudgetOptionText: Text[50];
        Text003: Label 'Budgeted Amounts are per the Budget';
        Text004: Label 'Budgeted Amounts are per the Contract';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Job_DescriptionCaptionLbl: Label 'Project Description';
        PADSTR____2____Job_Task__Indentation_____Job_Task__DescriptionCaptionLbl: Label 'Project Task Description';

    procedure GetItemDescription(Type: Option Resource,Item,"G/L Account"; No: Code[20]): Text[50]
    var
        Res: Record Resource;
        Item: Record Item;
        GLAcc: Record "G/L Account";
        Result: Text;
    begin
        case Type of
            Type::Resource:
                if Res.Get(No) then
                    Result := Res.Name;
            Type::Item:
                if Item.Get(No) then
                    Result := Item.Description;
            Type::"G/L Account":
                if GLAcc.Get(No) then
                    Result := GLAcc.Name;
        end;
        exit(CopyStr(Result, 1, 50))
    end;
}

