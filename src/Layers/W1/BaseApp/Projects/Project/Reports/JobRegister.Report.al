// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Ledger;

report 1015 "Job Register"
{
    AdditionalSearchTerms = 'Job Register';
    DefaultLayout = RDLC;
    RDLCLayout = './Projects/Project/Reports/JobRegister.rdlc';
    ApplicationArea = Jobs;
    Caption = 'Project Register';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Job Register"; "Job Register")
        {
            DataItemTableView = sorting("No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.";
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(Job_Register__TABLECAPTION__________JobRegFilter; TableCaption + ': ' + JobRegFilter)
            {
            }
            column(JobRegFilter; JobRegFilter)
            {
            }
            column(Job_Register__No__; "No.")
            {
            }
            column(Job_Ledger_Entry___Total_Cost__LCY__; "Job Ledger Entry"."Total Cost (LCY)")
            {
            }
            column(Job_Ledger_Entry___Line_Amount__LCY__; "Job Ledger Entry"."Line Amount (LCY)")
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Job_RegisterCaption; Job_RegisterCaptionLbl)
            {
            }
            column(Job_Ledger_Entry__Line_Amount__LCY__Caption; "Job Ledger Entry".FieldCaption("Line Amount (LCY)"))
            {
            }
            column(Job_Ledger_Entry__Entry_No__Caption; "Job Ledger Entry".FieldCaption("Entry No."))
            {
            }
            column(Job_Ledger_Entry__Total_Cost__LCY__Caption; "Job Ledger Entry".FieldCaption("Total Cost (LCY)"))
            {
            }
            column(Job_Ledger_Entry__Work_Type_Code_Caption; "Job Ledger Entry".FieldCaption("Work Type Code"))
            {
            }
            column(Job_Ledger_Entry__Unit_of_Measure_Code_Caption; "Job Ledger Entry".FieldCaption("Unit of Measure Code"))
            {
            }
            column(Job_Ledger_Entry_QuantityCaption; "Job Ledger Entry".FieldCaption(Quantity))
            {
            }
            column(Job_Ledger_Entry__No__Caption; "Job Ledger Entry".FieldCaption("No."))
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
            column(Job_Ledger_Entry__Job_No__Caption; "Job Ledger Entry".FieldCaption("Job No."))
            {
            }
            column(Job_Ledger_Entry__Posting_Date_Caption; Job_Ledger_Entry__Posting_Date_CaptionLbl)
            {
            }
            column(Job_Register__No__Caption; Job_Register__No__CaptionLbl)
            {
            }
            column(Job_Ledger_Entry___Total_Cost__LCY__Caption; Job_Ledger_Entry___Total_Cost__LCY__CaptionLbl)
            {
            }
            dataitem("Job Ledger Entry"; "Job Ledger Entry")
            {
                DataItemTableView = sorting("Entry No.");
                column(Job_Ledger_Entry__Entry_No__; "Entry No.")
                {
                }
                column(Job_Ledger_Entry__Line_Amount__LCY__; "Line Amount (LCY)")
                {
                }
                column(Job_Ledger_Entry__Total_Cost__LCY__; "Total Cost (LCY)")
                {
                }
                column(Job_Ledger_Entry__Work_Type_Code_; "Work Type Code")
                {
                }
                column(Job_Ledger_Entry__Unit_of_Measure_Code_; "Unit of Measure Code")
                {
                }
                column(Job_Ledger_Entry_Quantity; Quantity)
                {
                }
                column(Job_Ledger_Entry__No__; "No.")
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
                column(Job_Ledger_Entry__Job_No__; "Job No.")
                {
                }
                column(Job_Ledger_Entry__Posting_Date_; Format("Posting Date"))
                {
                }

                trigger OnPreDataItem()
                begin
                    SetRange("Entry No.", "Job Register"."From Entry No.", "Job Register"."To Entry No.");
                end;
            }
        }
    }

    requestpage
    {
        AboutTitle = 'About Project Register';
        AboutText = 'Document a project register''s contents for internal or external audits.';

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
        JobRegFilter := "Job Register".GetFilters();
    end;

    var
        JobRegFilter: Text;
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Job_RegisterCaptionLbl: Label 'Project Register';
        Job_Ledger_Entry__Posting_Date_CaptionLbl: Label 'Posting Date';
        Job_Register__No__CaptionLbl: Label 'Register No.';
        Job_Ledger_Entry___Total_Cost__LCY__CaptionLbl: Label 'Total';
}

