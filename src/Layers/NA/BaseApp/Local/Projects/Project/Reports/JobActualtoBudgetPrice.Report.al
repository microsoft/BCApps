// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Reports;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Foundation.Company;
using Microsoft.Inventory.Item;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Journal;
using Microsoft.Projects.Project.Ledger;
using Microsoft.Projects.Project.Planning;
using Microsoft.Projects.Resources.Resource;
using System.IO;
using System.Utilities;

report 10211 "Job Actual to Budget (Price)"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Projects/Project/Reports/JobActualtoBudgetPrice.rdlc';
    ApplicationArea = Jobs;
    Caption = 'Project Actual to Budget (Price)';
    AdditionalSearchTerms = 'Job Actual to Budget (Price)';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Job; Job)
        {
            RequestFilterFields = "No.", "Bill-to Customer No.", "Posting Date Filter", "Planning Date Filter", Status;
            column(Job_No_; "No.")
            {
            }
            column(Job_Planning_Date_Filter; "Planning Date Filter")
            {
            }
            column(Job_Posting_Date_Filter; "Posting Date Filter")
            {
            }
            dataitem(PageHeader; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(USERID; UserId)
                {
                }
                column(TIME; Time)
                {
                }
                column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
                {
                }
                column(STRSUBSTNO_Text000_Job__No___; StrSubstNo(Text000, Job."No."))
                {
                }
                column(CompanyInformation_Name; CompanyInformation.Name)
                {
                }
                column(BudgetOptionText; BudgetOptionText)
                {
                }
                column(ActualOptionText; ActualOptionText)
                {
                }
                column(PageGroupNo; PageGroupNo)
                {
                }
                column(Job_Task___No__of_Blank_Lines_; "Job Task"."No. of Blank Lines")
                {
                }
                column(PrintToExcel; PrintToExcel)
                {
                }
                column(Job_TABLECAPTION_____Filters______JobFilter; Job.TableCaption + ' Filters: ' + JobFilter)
                {
                }
                column(JobFilter; JobFilter)
                {
                }
                column(Job_Task__TABLECAPTION_____Filters______JobTaskFilter; "Job Task".TableCaption + ' Filters: ' + JobTaskFilter)
                {
                }
                column(JobTaskFilter; JobTaskFilter)
                {
                }
                column(Job__Description_2_; Job."Description 2")
                {
                }
                column(Job_FIELDCAPTION__Ending_Date____________FORMAT_Job__Ending_Date__; Job.FieldCaption("Ending Date") + ': ' + Format(Job."Ending Date"))
                {
                }
                column(Job_Description; Job.Description)
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
                column(VarianceCaption; VarianceCaptionLbl)
                {
                }
                column(JobDiffBuff__Budgeted_Line_Amount_Caption; JobDiffBuff__Budgeted_Line_Amount_CaptionLbl)
                {
                }
                column(JobDiffBuff__Line_Amount_Caption; JobDiffBuff__Line_Amount_CaptionLbl)
                {
                }
                column(JobDiffBuff__No__Caption; JobDiffBuff__No__CaptionLbl)
                {
                }
                column(FORMAT_JobDiffBuff_Type_Caption; FORMAT_JobDiffBuff_Type_CaptionLbl)
                {
                }
                column(Variance__Caption; Variance__CaptionLbl)
                {
                }
                column(PADSTR____2____Job_Task__Indentation_____Job_Task__Description_Control1480005Caption; PADSTR____2____Job_Task__Indentation_____Job_Task__Description_Control1480005CaptionLbl)
                {
                }
                column(Job_Task___Job_Task_No___Control1480006Caption; Job_Task___Job_Task_No___Control1480006CaptionLbl)
                {
                }
                column(JobDiffBuff_DescriptionCaption; JobDiffBuff_DescriptionCaptionLbl)
                {
                }
                dataitem("Job Task"; "Job Task")
                {
                    DataItemLink = "Job No." = field("No.");
                    DataItemLinkReference = Job;
                    DataItemTableView = sorting("Job No.", "Job Task No.");
                    RequestFilterFields = "Job Task No.";
                    column(Job_Task_Job_No_; "Job No.")
                    {
                    }
                    column(Job_Task_Job_Task_No_; "Job Task No.")
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
                    dataitem("Job Planning Line"; "Job Planning Line")
                    {
                        DataItemLink = "Job No." = field("No."), "Planning Date" = field("Planning Date Filter");
                        DataItemLinkReference = Job;
                        DataItemTableView = sorting("Job No.", "Job Task No.", "Schedule Line", "Planning Date") where(Type = filter(<> Text));

                        trigger OnAfterGetRecord()
                        begin
                            Job.SetJobDiffBuff(
                              JobDiffBuff, "Job No.", "Job Task"."Job Task No.", "Job Task"."Job Task Type".AsInteger(), Type.AsInteger(), "No.",
                              "Location Code", "Variant Code", "Unit of Measure Code", "Work Type Code");
                            if JobDiffBuff.Find() then begin
                                JobDiffBuff."Budgeted Quantity" := JobDiffBuff."Budgeted Quantity" + Quantity;
                                JobDiffBuff."Budgeted Line Amount" := JobDiffBuff."Budgeted Line Amount" + "Total Price (LCY)";
                                JobDiffBuff.Modify();
                            end else begin
                                if "Job Task"."Job Task Type" = "Job Task"."Job Task Type"::Posting then
                                    JobDiffBuff.Description := GetItemDescription(Type.AsInteger(), "No.");
                                JobDiffBuff."Budgeted Quantity" := Quantity;
                                JobDiffBuff."Budgeted Line Amount" := "Total Price (LCY)";
                                JobDiffBuff.Insert();
                            end;
                        end;

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
                    dataitem("Job Ledger Entry"; "Job Ledger Entry")
                    {
                        DataItemLink = "Job No." = field("No."), "Posting Date" = field("Posting Date Filter");
                        DataItemLinkReference = Job;
                        DataItemTableView = sorting("Job No.", "Job Task No.", "Entry Type", "Posting Date");

                        trigger OnAfterGetRecord()
                        begin
                            Job.SetJobDiffBuff(
                              JobDiffBuff, "Job No.", "Job Task"."Job Task No.", "Job Task"."Job Task Type".AsInteger(), Type.AsInteger(), "No.",
                              "Location Code", "Variant Code", "Unit of Measure Code", "Work Type Code");

                            if JobDiffBuff.Find() then begin
                                if "Entry Type" = "Entry Type"::Sale then begin
                                    JobDiffBuff.Quantity := JobDiffBuff.Quantity - Quantity;
                                    JobDiffBuff."Line Amount" := JobDiffBuff."Line Amount" - "Total Price (LCY)";
                                end else begin
                                    JobDiffBuff.Quantity := JobDiffBuff.Quantity + Quantity;
                                    JobDiffBuff."Line Amount" := JobDiffBuff."Line Amount" + "Total Price (LCY)";
                                end;
                                JobDiffBuff.Modify();
                            end else begin
                                if "Job Task"."Job Task Type" = "Job Task"."Job Task Type"::Posting then
                                    JobDiffBuff.Description := GetItemDescription(Type.AsInteger(), "No.");
                                if "Entry Type" = "Entry Type"::Sale then begin
                                    JobDiffBuff.Quantity := -Quantity;
                                    JobDiffBuff."Line Amount" := -"Total Price (LCY)";
                                end else begin
                                    JobDiffBuff.Quantity := Quantity;
                                    JobDiffBuff."Line Amount" := "Total Price (LCY)";
                                end;
                                JobDiffBuff.Insert();
                            end;
                        end;

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
                            case ActualAmountsPer of
                                ActualAmountsPer::Usage:
                                    SetRange("Entry Type", "Entry Type"::Usage);
                                ActualAmountsPer::Invoices:
                                    SetRange("Entry Type", "Entry Type"::Sale);
                            end;
                        end;
                    }
                    dataitem("Integer"; "Integer")
                    {
                        DataItemTableView = sorting(Number);
                        column(PADSTR____2____Job_Task__Indentation_____Job_Task__Description; PadStr('', 2 * "Job Task".Indentation) + "Job Task".Description)
                        {
                        }
                        column(Job_Task___Job_Task_No__; "Job Task"."Job Task No.")
                        {
                        }
                        column(Job_Task___Job_Task_Type__IN___Job_Task___Job_Task_Type___Heading__Job_Task___Job_Task_Type____Begin_Total__; "Job Task"."Job Task Type" in ["Job Task"."Job Task Type"::Heading, "Job Task"."Job Task Type"::"Begin-Total"])
                        {
                        }
                        column(PADSTR____2____Job_Task__Indentation_____Job_Task__Description_Control1480005; PadStr('', 2 * "Job Task".Indentation) + "Job Task".Description)
                        {
                        }
                        column(Job_Task___Job_Task_No___Control1480006; "Job Task"."Job Task No.")
                        {
                        }
                        column(JobDiffBuff__Line_Amount_; JobDiffBuff."Line Amount")
                        {
                            AutoFormatType = 1;
                        }
                        column(JobDiffBuff__Budgeted_Line_Amount_; JobDiffBuff."Budgeted Line Amount")
                        {
                            AutoFormatType = 1;
                        }
                        column(Variance; Variance)
                        {
                            AutoFormatType = 1;
                        }
                        column(Variance__; "Variance%")
                        {
                            DecimalPlaces = 1 : 1;
                        }
                        column(FORMAT_JobDiffBuff_Type_; Format(JobDiffBuff.Type))
                        {
                        }
                        column(JobDiffBuff__No__; JobDiffBuff."No.")
                        {
                        }
                        column(JobDiffBuff_Description; JobDiffBuff.Description)
                        {
                        }
                        column(Job_Task___Job_Task_Type_____Job_Task___Job_Task_Type___Posting; "Job Task"."Job Task Type" = "Job Task"."Job Task Type"::Posting)
                        {
                        }
                        column(PADSTR____2____Job_Task__Indentation_____Job_Task__Description_Control1480007; PadStr('', 2 * "Job Task".Indentation) + "Job Task".Description)
                        {
                        }
                        column(Job_Task___Job_Task_No___Control1480008; "Job Task"."Job Task No.")
                        {
                        }
                        column(JobDiffBuff__Line_Amount__Control1480013; JobDiffBuff."Line Amount")
                        {
                            AutoFormatType = 1;
                        }
                        column(JobDiffBuff__Budgeted_Line_Amount__Control1480014; JobDiffBuff."Budgeted Line Amount")
                        {
                            AutoFormatType = 1;
                        }
                        column(Variance_Control1480015; Variance)
                        {
                            AutoFormatType = 1;
                        }
                        column(Variance___Control1480016; "Variance%")
                        {
                            DecimalPlaces = 1 : 1;
                        }
                        column(Job_Task___Job_Task_Type__IN___Job_Task___Job_Task_Type___Total__Job_Task___Job_Task_Type____End_Total__; "Job Task"."Job Task Type" in ["Job Task"."Job Task Type"::Total, "Job Task"."Job Task Type"::"End-Total"])
                        {
                        }
                        column(Integer_Number; Number)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            case Number of
                                0:
                                    exit;
                                1:
                                    JobDiffBuff.Find('-');
                                else
                                    JobDiffBuff.Next();
                            end;

                            Variance := JobDiffBuff."Line Amount" - JobDiffBuff."Budgeted Line Amount";
                            if JobDiffBuff."Budgeted Line Amount" = 0 then
                                "Variance%" := 0
                            else
                                "Variance%" := 100 * Variance / JobDiffBuff."Budgeted Line Amount";

                            if PrintToExcel then
                                MakeExcelDataBody();
                        end;

                        trigger OnPreDataItem()
                        begin
                            JobDiffBuff.Reset();
                            JobDiffBuff.SetRange("Job No.", "Job Task"."Job No.");
                            JobDiffBuff.SetRange("Job Task No.", "Job Task"."Job Task No.");
                            if "Job Task"."Job Task Type" in ["Job Task"."Job Task Type"::Heading, "Job Task"."Job Task Type"::"Begin-Total"] then
                                SetRange(Number, 0, JobDiffBuff.Count)
                            else
                                SetRange(Number, 1, JobDiffBuff.Count)
                        end;
                    }

                    trigger OnAfterGetRecord()
                    begin
                        JobDiffBuff.Reset();

                        JobTaskTypeNo := "Job Task"."Job Task Type".AsInteger();
                        PageGroupNo := NextPageGroupNo;
                        if "New Page" and ((JobTaskTypeNo = 1) or (JobTaskTypeNo = 3)) then
                            NextPageGroupNo := PageGroupNo + 1;
                    end;
                }
            }

            trigger OnAfterGetRecord()
            begin
                JobDiffBuff.DeleteAll();

                if PrintToExcel then
                    MakeExcelInfo();
            end;

            trigger OnPostDataItem()
            begin
                if PrintToExcel then
                    CreateExcelbook();
            end;

            trigger OnPreDataItem()
            begin
                if (Count > 1) and PrintToExcel then
                    Error(Text005);
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
                    field(ActualAmountsPer; ActualAmountsPer)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Actual Amounts Per';
                        OptionCaption = 'Usage,Invoices';
                        ToolTip = 'Specifies if the actual amounts must be based on time used or invoiced. ';
                    }
                    field(PrintToExcel; PrintToExcel)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Print to Excel';
                        ToolTip = 'Specifies if you want to export the data to an Excel spreadsheet for additional analysis or formatting before printing.';
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
        JobTaskFilter := "Job Task".GetFilters();
        if BudgetAmountsPer = BudgetAmountsPer::Schedule then
            BudgetOptionText := Text001
        else
            BudgetOptionText := Text002;
        if ActualAmountsPer = ActualAmountsPer::Invoices then
            ActualOptionText := Text004
        else
            ActualOptionText := Text003;
    end;

    var
        CompanyInformation: Record "Company Information";
        JobDiffBuff: Record "Job Difference Buffer" temporary;
        ExcelBuf: Record "Excel Buffer" temporary;
        JobFilter: Text;
        JobTaskFilter: Text;
        Variance: Decimal;
        "Variance%": Decimal;
        Text000: Label 'Actual Price to Budget Price for Project %1';
        Text001: Label 'Budgeted Amounts are per the Budget';
        Text002: Label 'Budgeted Amounts are per the Contract';
        BudgetAmountsPer: Option Schedule,Contract;
        BudgetOptionText: Text[50];
        ActualAmountsPer: Option Usage,Invoices;
        ActualOptionText: Text[50];
        Text003: Label 'Actual Amounts are per Project Usage';
        Text004: Label 'Actual Amounts are per Sales Invoices';
        PrintToExcel: Boolean;
        Text005: Label 'When printing to Excel, you must select only one Project.';
        Text101: Label 'Data';
        Text102: Label 'Project Actual to Budget (Price)';
        Text103: Label 'Company Name';
        Text104: Label 'Report No.';
        Text105: Label 'Report Name';
        Text106: Label 'User ID';
        Text107: Label 'Date / Time';
        Text108: Label 'Project Filters';
        Text109: Label 'Project Task Filters';
        Text110: Label 'Variance';
        Text111: Label 'Percent Variance';
        Text112: Label 'Budget Option';
        Text113: Label 'Project Information:';
        Text114: Label 'Starting / Ending Dates';
        Text115: Label 'Actual Total Price';
        Text116: Label 'Actual Option';
        Text117: Label 'Budgeted Total Price';
        PageGroupNo: Integer;
        NextPageGroupNo: Integer;
        JobTaskTypeNo: Integer;
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Job_DescriptionCaptionLbl: Label 'Project Description';
        VarianceCaptionLbl: Label 'Variance';
        JobDiffBuff__Budgeted_Line_Amount_CaptionLbl: Label 'Budgeted Total Price';
        JobDiffBuff__Line_Amount_CaptionLbl: Label 'Actual Total Price';
        JobDiffBuff__No__CaptionLbl: Label 'No.';
        FORMAT_JobDiffBuff_Type_CaptionLbl: Label 'Type';
        Variance__CaptionLbl: Label 'Percent Variance';
        PADSTR____2____Job_Task__Indentation_____Job_Task__Description_Control1480005CaptionLbl: Label 'Project Task Description';
        Job_Task___Job_Task_No___Control1480006CaptionLbl: Label 'Project Task No.';
        JobDiffBuff_DescriptionCaptionLbl: Label 'Description';

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

    local procedure MakeExcelInfo()
    begin
        ExcelBuf.SetUseInfoSheet();
        ExcelBuf.AddInfoColumn(Format(Text103), false, true, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddInfoColumn(CompanyInformation.Name, false, false, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.NewRow();
        ExcelBuf.AddInfoColumn(Format(Text105), false, true, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddInfoColumn(StrSubstNo(Text000, Job."No."), false, false, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.NewRow();
        ExcelBuf.AddInfoColumn(Format(Text104), false, true, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddInfoColumn(REPORT::"Job Actual to Budget (Price)", false, false, false, false, '', ExcelBuf."Cell Type"::Number);
        ExcelBuf.NewRow();
        ExcelBuf.AddInfoColumn(Format(Text106), false, true, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddInfoColumn(UserId, false, false, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.NewRow();
        ExcelBuf.AddInfoColumn(Format(Text107), false, true, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddInfoColumn(Today, false, false, false, false, '', ExcelBuf."Cell Type"::Date);
        ExcelBuf.AddInfoColumn(Time, false, false, false, false, '', ExcelBuf."Cell Type"::Time);
        ExcelBuf.NewRow();
        ExcelBuf.AddInfoColumn(Format(Text112), false, true, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddInfoColumn(BudgetOptionText, false, false, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.NewRow();
        ExcelBuf.AddInfoColumn(Format(Text116), false, true, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddInfoColumn(ActualOptionText, false, false, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.NewRow();
        ExcelBuf.AddInfoColumn(Format(Text108), false, true, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddInfoColumn(JobFilter, false, false, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.NewRow();
        ExcelBuf.AddInfoColumn(Format(Text109), false, true, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddInfoColumn(JobTaskFilter, false, false, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.NewRow();
        ExcelBuf.AddInfoColumn(Format(Text113), false, true, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.NewRow();
        ExcelBuf.AddInfoColumn(
          '  ' + Job.TableCaption + ' ' + Job.FieldCaption("No."), false, true, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddInfoColumn(Job."No.", false, false, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.NewRow();
        ExcelBuf.AddInfoColumn('  ' + Job.FieldCaption(Description), false, true, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddInfoColumn(Job.Description + ' ' + Job."Description 2", false, false, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.NewRow();
        ExcelBuf.AddInfoColumn('  ' + Format(Text114), false, true, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddInfoColumn(Format(Job."Starting Date"), false, false, false, false, '', ExcelBuf."Cell Type"::Date);
        ExcelBuf.AddInfoColumn(Format(Job."Ending Date"), false, false, false, false, '', ExcelBuf."Cell Type"::Date);
        ExcelBuf.ClearNewRow();
        MakeExcelDataHeader();
    end;

    local procedure MakeExcelDataHeader()
    begin
        ExcelBuf.NewRow();
        ExcelBuf.AddColumn("Job Task".FieldCaption("Job Task No."), false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn(
          "Job Task".TableCaption + ' ' + "Job Task".FieldCaption(Description), false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn(JobDiffBuff.FieldCaption(Type), false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn(JobDiffBuff.FieldCaption("No."), false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn(JobDiffBuff.FieldCaption(Description), false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn(Format(Text115), false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn(Format(Text117), false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn(Format(Text110), false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn(Format(Text111), false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
    end;

    local procedure MakeExcelDataBody()
    begin
        ExcelBuf.NewRow();
        ExcelBuf.AddColumn("Job Task"."Job Task No.", false, '', false, false, false, '', ExcelBuf."Cell Type"::Text);
        case "Job Task"."Job Task Type" of
            "Job Task"."Job Task Type"::Heading, "Job Task"."Job Task Type"::"Begin-Total":
                ExcelBuf.AddColumn(
                  PadStr('', 2 * "Job Task".Indentation) + "Job Task".Description, false, '', true, false, false, '', ExcelBuf."Cell Type"::Text);
            "Job Task"."Job Task Type"::Posting:
                begin
                    ExcelBuf.AddColumn(
                      PadStr('', 2 * "Job Task".Indentation) + "Job Task".Description, false, '', false, false, false, '', ExcelBuf."Cell Type"::Text);
                    ExcelBuf.AddColumn(Format(JobDiffBuff.Type), false, '', false, false, false, '', ExcelBuf."Cell Type"::Text);
                    ExcelBuf.AddColumn(JobDiffBuff."No.", false, '', false, false, false, '', ExcelBuf."Cell Type"::Text);
                    ExcelBuf.AddColumn(JobDiffBuff.Description, false, '', false, false, false, '', ExcelBuf."Cell Type"::Text);
                    ExcelBuf.AddColumn(JobDiffBuff."Line Amount", false, '', false, false, false, '#,##0.00', ExcelBuf."Cell Type"::Number);
                    ExcelBuf.AddColumn(JobDiffBuff."Budgeted Line Amount", false, '', false, false, false, '#,##0.00', ExcelBuf."Cell Type"::Number);
                    ExcelBuf.AddColumn(Variance, false, '', false, false, false, '#,##0.00', ExcelBuf."Cell Type"::Number);
                    ExcelBuf.AddColumn("Variance%" / 100, false, '', false, false, false, '0.0%', ExcelBuf."Cell Type"::Number);
                end;
            "Job Task"."Job Task Type"::Total, "Job Task"."Job Task Type"::"End-Total":
                begin
                    ExcelBuf.AddColumn(
                      PadStr('', 2 * "Job Task".Indentation) + "Job Task".Description, false, '', true, false, false, '', ExcelBuf."Cell Type"::Text);
                    ExcelBuf.AddColumn('', false, '', false, false, false, '', ExcelBuf."Cell Type"::Text);
                    ExcelBuf.AddColumn('', false, '', false, false, false, '', ExcelBuf."Cell Type"::Text);
                    ExcelBuf.AddColumn('', false, '', false, false, false, '', ExcelBuf."Cell Type"::Text);
                    ExcelBuf.AddColumn(JobDiffBuff."Line Amount", false, '', true, false, false, '#,##0.00', ExcelBuf."Cell Type"::Number);
                    ExcelBuf.AddColumn(JobDiffBuff."Budgeted Line Amount", false, '', true, false, false, '#,##0.00', ExcelBuf."Cell Type"::Number);
                    ExcelBuf.AddColumn(Variance, false, '', true, false, false, '#,##0.00', ExcelBuf."Cell Type"::Number);
                    ExcelBuf.AddColumn("Variance%" / 100, false, '', true, false, false, '0.0%', ExcelBuf."Cell Type"::Number);
                end;
        end;
    end;

    local procedure CreateExcelbook()
    begin
        ExcelBuf.CreateBookAndOpenExcel('', Text101, Text102, CompanyName, UserId);
        Error('');
    end;
}

