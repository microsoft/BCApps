// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Ledger;

using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Company;
using Microsoft.Projects.Project.Job;

report 10217 "Job Register"
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
            RequestFilterFields = "No.", "Creation Date", "Source Code", "Journal Batch Name";
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
            column(JobRegFilter; JobRegFilter)
            {
            }
            column(JobEntryFilter; JobEntryFilter)
            {
            }
            column(Job_Register__TABLECAPTION__________JobRegFilter; "Job Register".TableCaption + ': ' + JobRegFilter)
            {
            }
            column(Job_Ledger_Entry__TABLECAPTION__________JobEntryFilter; "Job Ledger Entry".TableCaption + ': ' + JobEntryFilter)
            {
            }
            column(Register_No______FORMAT__No___; 'Register No: ' + Format("No."))
            {
            }
            column(SourceCodeText; SourceCodeText)
            {
            }
            column(SourceCode_Description; SourceCode.Description)
            {
            }
            column(Job_Register___No__; "Job Register"."No.")
            {
            }
            column(Job_RegisterCaption; Job_RegisterCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Job_Ledger_Entry__Job_No__Caption; "Job Ledger Entry".FieldCaption("Job No."))
            {
            }
            column(Job_Ledger_Entry__Document_No__Caption; "Job Ledger Entry".FieldCaption("Document No."))
            {
            }
            column(Job_Ledger_Entry__Entry_Type_Caption; "Job Ledger Entry".FieldCaption("Entry Type"))
            {
            }
            column(Job_Ledger_Entry__Posting_Date_Caption; "Job Ledger Entry".FieldCaption("Posting Date"))
            {
            }
            column(Job_Ledger_Entry__Unit_of_Measure_Code_Caption; "Job Ledger Entry".FieldCaption("Unit of Measure Code"))
            {
            }
            column(Job_Ledger_Entry_TypeCaption; "Job Ledger Entry".FieldCaption(Type))
            {
            }
            column(Job_Ledger_Entry__No__Caption; "Job Ledger Entry".FieldCaption("No."))
            {
            }
            column(Job_Ledger_Entry_QuantityCaption; "Job Ledger Entry".FieldCaption(Quantity))
            {
            }
            column(Job_Ledger_Entry__Unit_Cost__LCY__Caption; "Job Ledger Entry".FieldCaption("Unit Cost (LCY)"))
            {
            }
            column(Job_Ledger_Entry__Total_Cost__LCY__Caption; "Job Ledger Entry".FieldCaption("Total Cost (LCY)"))
            {
            }
            column(Job_Ledger_Entry__Total_Price__LCY__Caption; "Job Ledger Entry".FieldCaption("Total Price (LCY)"))
            {
            }
            column(Job_Ledger_Entry__Unit_Price__LCY__Caption; "Job Ledger Entry".FieldCaption("Unit Price (LCY)"))
            {
            }
            dataitem("Job Ledger Entry"; "Job Ledger Entry")
            {
                DataItemTableView = sorting("Entry No.");
                RequestFilterFields = "Job No.", "Posting Date", "Document No.";
                column(Job_Ledger_Entry__Job_No__; "Job No.")
                {
                }
                column(Job_Ledger_Entry__Posting_Date_; "Posting Date")
                {
                }
                column(Job_Ledger_Entry__Document_No__; "Document No.")
                {
                }
                column(Job_Ledger_Entry__Entry_Type_; "Entry Type")
                {
                }
                column(Job_Ledger_Entry_Type; Type)
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
                column(Job_Ledger_Entry__Unit_Cost__LCY__; "Unit Cost (LCY)")
                {
                }
                column(Job_Ledger_Entry__Total_Cost__LCY__; "Total Cost (LCY)")
                {
                }
                column(Job_Ledger_Entry__Unit_Price__LCY__; "Unit Price (LCY)")
                {
                }
                column(Job_Ledger_Entry__Total_Price__LCY__; "Total Price (LCY)")
                {
                }
                column(JobDescription; JobDescription)
                {
                }
                column(PrintJobDescriptions; PrintJobDescriptions)
                {
                }
                column(Job_Ledger_Entry___Entry_No__; "Job Ledger Entry"."Entry No.")
                {
                }
                column(Job_Register___No___Control43; "Job Register"."No.")
                {
                }
                column(Job_Register___To_Entry_No______Job_Register___From_Entry_No_____1; "Job Register"."To Entry No." - "Job Register"."From Entry No." + 1)
                {
                }
                column(Number_of_Entries_in_Register_No_Caption; Number_of_Entries_in_Register_No_CaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    JobDescription := Description;
                    if JobDescription = '' then begin
                        if not Job.Get("Job No.") then
                            Job.Init();
                        JobDescription := Job.Description;
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    SetRange("Entry No.", "Job Register"."From Entry No.", "Job Register"."To Entry No.")
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if "Source Code" <> '' then begin
                    SourceCodeText := 'Source Code: ' + "Source Code";
                    if not SourceCode.Get("Source Code") then
                        SourceCode.Init();
                end else begin
                    Clear(SourceCodeText);
                    SourceCode.Init();
                end;
            end;
        }
    }

    requestpage
    {
        SaveValues = true;
        AboutTitle = 'About Project Register';
        AboutText = 'Document a project register''s contents for internal or external audits.';

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(PrintJobDescriptions; PrintJobDescriptions)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Print Job Descriptions';
                        ToolTip = 'Specifies that you want to include a section with the job description based on the value in the Description field on the job ledger entry.';
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
        JobRegFilter := "Job Register".GetFilters();
        JobEntryFilter := "Job Ledger Entry".GetFilters();
        CompanyInformation.Get();
    end;

    var
        Job: Record Job;
        CompanyInformation: Record "Company Information";
        SourceCode: Record "Source Code";
        PrintJobDescriptions: Boolean;
        JobRegFilter: Text;
        JobEntryFilter: Text;
        JobDescription: Text[100];
        SourceCodeText: Text[50];
        Job_RegisterCaptionLbl: Label 'Project Register';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Number_of_Entries_in_Register_No_CaptionLbl: Label 'Number of Entries in Register No.';
}

