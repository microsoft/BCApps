// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Reports;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Planning;
using Microsoft.Projects.Project.Setup;
using System.Utilities;

report 1017 "Job Task Quote"
{
    DefaultRenderingLayout = "JobTaskQuote.rdlc";
    Caption = 'Project Task Quote';
    PreviewMode = PrintLayout;
    WordMergeDataItem = "Job Task";

    dataset
    {
        dataitem("Job Task"; "Job Task")
        {
            DataItemTableView = sorting("Job No.", "Job Task No.") where("Job Task Type" = const(Posting));
            RequestFilterFields = "Job No.", "Job Task No.";
            PrintOnlyIfDetail = true;
            column(CompanyAddress1; CompanyAddr[1])
            {
            }
            column(CompanyAddress2; CompanyAddr[2])
            {
            }
            column(CompanyAddress3; CompanyAddr[3])
            {
            }
            column(CompanyAddress4; CompanyAddr[4])
            {
            }
            column(CompanyAddress5; CompanyAddr[5])
            {
            }
            column(CompanyAddress6; CompanyAddr[6])
            {
            }
            column(CompanyAddress7; CompanyAddr[7])
            {
            }
            column(CompanyAddress8; CompanyAddr[8])
            {
            }
            column(CompanyPicture; CompanyInfo.Picture)
            {
            }
            column(CompanyLogoPosition; CompanyLogoPosition)
            {
            }
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(BillToAddress1; BillToAddr[1])
            {
            }
            column(BillToAddress2; BillToAddr[2])
            {
            }
            column(BillToAddress3; BillToAddr[3])
            {
            }
            column(BillToAddress4; BillToAddr[4])
            {
            }
            column(BillToAddress5; BillToAddr[5])
            {
            }
            column(BillToAddress6; BillToAddr[6])
            {
            }
            column(QuantityCaption; QuantityLbl)
            {
            }
            column(UnitPriceCaption; UnitPriceLbl)
            {
            }
            column(TotalPriceCaption; TotalPriceLbl)
            {
            }
            column(JobTaskTypeCaption; JobTaskTypeLbl)
            {
            }
            column(NoCaption; NoLbl)
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
            column(JobTasktableCaptFilter; "Job Task".TableCaption + ': ' + JobTaskFilter)
            {
            }
            column(JobTaskFilter; JobTaskFilter)
            {
            }
            column(No_Job; "Job No.")
            {
            }
            column(Task_No_Job; "Job Task No.")
            {
            }
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
            }
            column(JobTaskQuoteCaptLbl; JobTaskQuoteCaptLbl)
            {
            }
            dataitem("Job Planning Line"; "Job Planning Line")
            {
                DataItemLink = "Job No." = field("Job No."), "Job Task No." = field("Job Task No.");
                DataItemLinkReference = "Job Task";
                DataItemTableView = sorting("Job No.", "Job Task No.", "Line No.");
                RequestFilterFields = "Job Task No.";
                column(Quantity; Quantity)
                {
                }
                column(UnitPriceLCY; "Unit Price (LCY)")
                {
                }
                column(UnitPrice; "Unit Price")
                {
                }
                column(TotalPriceLCY; "Total Price (LCY)")
                {
                    AutoFormatExpression = CurrencyFormat;
                    AutoFormatType = 10;
                }
                column(TotalPrice; "Total Price")
                {
                }
                column(Type; Type)
                {
                }
                column(Number; "No.")
                {
                }
                column(JobPlanningLine_JobTaskNo; "Job Task No.")
                {
                }
                column(JobPlanningLine_Type; Type)
                {
                }
                column(JobPlanningLine_LineType; "Line Type")
                {
                }
                column(Indentation_JobTask; PadStr('', 2 * "Job Task".Indentation) + Description)
                {
                }
                column(ShowIntBody3; ("Job Task"."Job Task Type" in ["Job Task"."Job Task Type"::Posting]) and PrintSection)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    PrintSection := true;
                    if "Line Type" = "Line Type"::Budget then begin
                        PrintSection := false;
                        CurrReport.Skip();
                    end;
                    JobTotalValue += ("Unit Price" * Quantity);

                    if FirstLineHasBeenOutput then
                        Clear(CompanyInfo.Picture);
                    FirstLineHasBeenOutput := true;

                    ConstructCurrencyFormatString();
                end;

                trigger OnPreDataItem()
                begin
                    FirstLineHasBeenOutput := false;
                    CompanyInfo.CalcFields(Picture);
                end;
            }
            dataitem(Totals; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(JobTotalValue; JobTotalValue)
                {
                }
            }

            trigger OnAfterGetRecord()
            begin
                JobTotalValue := 0;
                Job.Get("Job No.");
                FormatAddr.Company(CompanyAddr, CompanyInfo);

                FormatAddr.FormatAddr(
                    BillToAddr, "Job Task"."Bill-to Name", "Job Task"."Bill-to Name 2", "Job Task"."Bill-to Contact",
                    "Job Task"."Bill-to Address", "Job Task"."Bill-to Address 2", "Job Task"."Bill-to City",
                    "Job Task"."Bill-to Post Code", "Job Task"."Bill-to County", "Job Task"."Bill-to Country/Region Code");
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
            }
        }
    }

    rendering
    {
        layout("JobTaskQuote.rdlc")
        {
            Type = RDLC;
            LayoutFile = './Projects/Project/Reports/JobTaskQuote.rdlc';
            Caption = 'Project Task Quote (RDLC)';
            Summary = 'The Project Task Quote (RDLC) provides a detailed layout.';
        }
        layout("JobTaskQuote.docx")
        {
            Type = Word;
            LayoutFile = './Projects/Project/JobTaskQuote.docx';
            Caption = 'Project Task Quote (Word)';
            Summary = 'The Project Task Quote (Word) provides a basic layout.';
        }
    }

    labels
    {
        JobNoLbl = 'Project No.';
        JobDescriptionLbl = 'Description';
    }

    trigger OnInitReport()
    begin
        CompanyInfo.SetAutoCalcFields(Picture);
        CompanyInfo.Get();
        JobsSetup.Get();
    end;

    trigger OnPreReport()
    begin
        JobTaskFilter := "Job Planning Line".GetFilters();
        CompanyLogoPosition := JobsSetup."Logo Position on Documents";
    end;

    local procedure ConstructCurrencyFormatString()
    var
        Currency: Record Currency;
        GLSetup: Record "General Ledger Setup";
        CurrencySymbol: Text[10];
        CurrencyLbl: Label '%1<precision, 2:2><standard format, 0>', Comment = '%1=CurrencySymbol';
    begin
        if Job."Currency Code" = '' then begin
            GLSetup.Get();
            CurrencySymbol := GLSetup.GetCurrencySymbol();
        end else begin
            if Currency.Get(Job."Currency Code") then;
            CurrencySymbol := Currency.GetCurrencySymbol();
        end;
        CurrencyFormat := StrSubstNo(CurrencyLbl, CurrencySymbol);
    end;

    var
        Job: Record "Job";
        JobsSetup: Record "Jobs Setup";
        FormatAddr: Codeunit "Format Address";
        JobTaskFilter: Text;
        FirstLineHasBeenOutput: Boolean;
        PrintSection: Boolean;
        CurrReportPageNoCaptionLbl: Label 'Page';
        JobTaskQuoteCaptLbl: Label 'Project Task Quote';
        DescriptionCaptionLbl: Label 'Description';
        JobTaskNoCaptLbl: Label 'Project Task No.';
        QuantityLbl: Label 'Quantity';
        UnitPriceLbl: Label 'Unit Price';
        TotalPriceLbl: Label 'Total Price';
        JobTaskTypeLbl: Label 'Project Task Type';
        NoLbl: Label 'No.';
        CompanyLogoPosition: Integer;
        JobTotalValue: Decimal;
        CompanyAddr: array[8] of Text[100];
        BillToAddr: array[8] of Text[100];
        CurrencyFormat: Text;

    protected var
        CompanyInfo: Record "Company Information";
}

