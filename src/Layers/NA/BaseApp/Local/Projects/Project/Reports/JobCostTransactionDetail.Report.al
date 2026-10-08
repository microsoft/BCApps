// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Reports;

using Microsoft.Foundation.Company;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Ledger;

report 10220 "Job Cost Transaction Detail"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Projects/Project/Reports/JobCostTransactionDetail.rdlc';
    ApplicationArea = Jobs;
    Caption = 'Project Cost Transaction Detail';
    AdditionalSearchTerms = 'Job Cost Transaction Detail';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Job; Job)
        {
            DataItemTableView = sorting("No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", Status, "Posting Date Filter";
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
            column(TABLECAPTION_________FIELDCAPTION__No_____________No__; TableCaption + ' ' + FieldCaption("No.") + ' ' + "No.")
            {
            }
            column(Job_Description; Description)
            {
            }
            column(Job_No_; "No.")
            {
            }
            column(Job_Posting_Date_Filter; "Posting Date Filter")
            {
            }
            column(Job_Cost_Transaction_DetailCaption; Job_Cost_Transaction_DetailCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Job_Ledger_Entry__Posting_Date_Caption; "Job Ledger Entry".FieldCaption("Posting Date"))
            {
            }
            column(Job_Ledger_Entry_TypeCaption; "Job Ledger Entry".FieldCaption(Type))
            {
            }
            column(Job_Ledger_Entry__Document_No__Caption; "Job Ledger Entry".FieldCaption("Document No."))
            {
            }
            column(Job_Ledger_Entry__Entry_Type_Caption; "Job Ledger Entry".FieldCaption("Entry Type"))
            {
            }
            column(Job_Ledger_Entry__No__Caption; "Job Ledger Entry".FieldCaption("No."))
            {
            }
            column(Job_Ledger_Entry_QuantityCaption; "Job Ledger Entry".FieldCaption(Quantity))
            {
            }
            column(Job_Ledger_Entry__Unit_of_Measure_Code_Caption; "Job Ledger Entry".FieldCaption("Unit of Measure Code"))
            {
            }
            column(Job_Ledger_Entry__Total_Cost__LCY__Caption; "Job Ledger Entry".FieldCaption("Total Cost (LCY)"))
            {
            }
            column(Job_Ledger_Entry__Total_Price__LCY__Caption; "Job Ledger Entry".FieldCaption("Total Price (LCY)"))
            {
            }
            column(Job_Ledger_Entry__Amt__Posted_to_G_L_Caption; "Job Ledger Entry".FieldCaption("Amt. Posted to G/L"))
            {
            }
            column(Job_Ledger_Entry__Amt__Recognized_Caption; Job_Ledger_Entry__Amt__Recognized_CaptionLbl)
            {
            }
            dataitem("Job Ledger Entry"; "Job Ledger Entry")
            {
                DataItemLink = "Job No." = field("No."), "Posting Date" = field("Posting Date Filter");
                DataItemTableView = sorting("Job No.", "Posting Date");
                column(Job_Ledger_Entry__Posting_Date_; "Posting Date")
                {
                }
                column(Job_Ledger_Entry_Type; Type)
                {
                }
                column(Job_Ledger_Entry__Document_No__; "Document No.")
                {
                }
                column(Job_Ledger_Entry__Entry_Type_; "Entry Type")
                {
                }
                column(Job_Ledger_Entry__No__; "No.")
                {
                }
                column(Job_Ledger_Entry_Quantity; Quantity)
                {
                    DecimalPlaces = 2 : 5;
                }
                column(Job_Ledger_Entry__Unit_of_Measure_Code_; "Unit of Measure Code")
                {
                }
                column(Job_Ledger_Entry__Total_Cost__LCY__; "Total Cost (LCY)")
                {
                }
                column(Job_Ledger_Entry__Total_Price__LCY__; "Total Price (LCY)")
                {
                }
                column(Job_Ledger_Entry__Amt__Posted_to_G_L_; "Amt. Posted to G/L")
                {
                }
                column(TotalCost_1_; TotalCost[1])
                {
                }
                column(TotalPrice_1_; TotalPrice[1])
                {
                }
                column(AmtPostedToGL_1_; AmtPostedToGL[1])
                {
                }
                column(STRSUBSTNO_Text000_FIELDCAPTION__Job_No_____Job_No___; StrSubstNo(Text000, FieldCaption("Job No."), "Job No."))
                {
                }
                column(STRSUBSTNO_Text001_FIELDCAPTION__Job_No_____Job_No___; StrSubstNo(Text001, FieldCaption("Job No."), "Job No."))
                {
                }
                column(TotalCost_2_; TotalCost[2])
                {
                }
                column(TotalPrice_2_; TotalPrice[2])
                {
                }
                column(AmtPostedToGL_2_; AmtPostedToGL[2])
                {
                }
                column(Job_Ledger_Entry_Entry_No_; "Entry No.")
                {
                }
                column(Job_Ledger_Entry_Job_No_; "Job No.")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    IncrementTotals("Entry Type".AsInteger());
                end;

                trigger OnPreDataItem()
                begin
                    Clear(TotalCost);
                    Clear(TotalPrice);
                    Clear(AmtPostedToGL);
                end;
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
        CompanyInformation.Get();
        JobFilter := Job.GetFilters();
    end;

    var
        CompanyInformation: Record "Company Information";
        JobFilter: Text;
        TotalCost: array[2] of Decimal;
        TotalPrice: array[2] of Decimal;
        AmtPostedToGL: array[2] of Decimal;
        Text000: Label 'Total Usage for %1 %2';
        Text001: Label 'Total Sales for %1 %2';
        Job_Cost_Transaction_DetailCaptionLbl: Label 'Project Cost Transaction Detail';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Job_Ledger_Entry__Amt__Recognized_CaptionLbl: Label 'Project Ledger Entry - Amt. Recognized';

    procedure IncrementTotals(EntryType: Integer)
    var
        i: Integer;
    begin
        i := EntryType + 1;
        TotalCost[i] := TotalCost[i] + "Job Ledger Entry"."Total Cost (LCY)";
        TotalPrice[i] := TotalPrice[i] + "Job Ledger Entry"."Total Price (LCY)";
        AmtPostedToGL[i] := AmtPostedToGL[i] + "Job Ledger Entry"."Amt. Posted to G/L";
        // AmtRecognized[i] := AmtRecognized[i] + "Job Ledger Entry"."Amt. Recognized";
    end;
}

