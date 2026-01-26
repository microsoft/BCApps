// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.VAT.Ledger;
using System.IO;

report 28165 "GST Sales Report"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/FinancialMgt/VAT/GSTSalesReport.rdlc';
    Caption = 'GST Sales Report';

    dataset
    {
        dataitem("GST Sales Entry"; "GST Sales Entry")
        {
            DataItemTableView = sorting("Entry No.") where("GST Entry No." = filter(<> 0));
            column(USERID; UserId)
            {
            }
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(FORMAT_EndDate_0_4_; Format(EndDate, 0, 4))
            {
            }
            column(FORMAT_StartDate_0_4_; Format(StartDate, 0, 4))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(GST_Sales_Entry__Document_Line_Code_; "Document Line Code")
            {
            }
            column(LineTotal; LineTotal)
            {
            }
            column(GST_Sales_Entry_Amount; Amount)
            {
            }
            column(GST_Sales_Entry__GST_Base_; "GST Base")
            {
            }
            column(GSTPercent; GSTPercent)
            {
            }
            column(GST_Sales_Entry__VAT_Prod__Posting_Group_; "VAT Prod. Posting Group")
            {
            }
            column(GST_Sales_Entry__VAT_Bus__Posting_Group_; "VAT Bus. Posting Group")
            {
            }
            column(GST_Sales_Entry__Document_Line_Description_; "Document Line Description")
            {
            }
            column(GST_Sales_Entry__Customer_Name_; "Customer Name")
            {
            }
            column(GST_Sales_Entry__Customer_No__; "Customer No.")
            {
            }
            column(GST_Sales_Entry__Document_Type_; "Document Type")
            {
            }
            column(GST_Sales_Entry__Document_No__; "Document No.")
            {
            }
            column(GST_Sales_Entry__Posting_Date_; Format("Posting Date"))
            {
            }
            column(AmountTotal; AmountTotal)
            {
            }
            column(BaseTotal; BaseTotal)
            {
            }
            column(Linestotal; Linestotal)
            {
            }
            column(GST_Sales_Entry_Entry_No_; "Entry No.")
            {
            }
            column(CodeCaption; CodeCaptionLbl)
            {
            }
            column(Total_SaleCaption; Total_SaleCaptionLbl)
            {
            }
            column(GST_AmountCaption; GST_AmountCaptionLbl)
            {
            }
            column(GST_BaseCaption; GST_BaseCaptionLbl)
            {
            }
            column(GST__Caption; GST__CaptionLbl)
            {
            }
            column(GST_Prod__Posting_GroupCaption; GST_Prod__Posting_GroupCaptionLbl)
            {
            }
            column(GST_Bus__Posting_GroupCaption; GST_Bus__Posting_GroupCaptionLbl)
            {
            }
            column(DescriptionCaption; DescriptionCaptionLbl)
            {
            }
            column(Customer_NameCaption; Customer_NameCaptionLbl)
            {
            }
            column(Customer_CodeCaption; Customer_CodeCaptionLbl)
            {
            }
            column(Document_TypeCaption; Document_TypeCaptionLbl)
            {
            }
            column(Document_No_Caption; Document_No_CaptionLbl)
            {
            }
            column(Posting_DateCaption; Posting_DateCaptionLbl)
            {
            }
            column(GST_Sales_ReportCaption; GST_Sales_ReportCaptionLbl)
            {
            }
            column(Report_CreatedCaption; Report_CreatedCaptionLbl)
            {
            }
            column(CompanyCaption; CompanyCaptionLbl)
            {
            }
            column(Start_DateCaption; Start_DateCaptionLbl)
            {
            }
            column(End_DateCaption; End_DateCaptionLbl)
            {
            }
            column(UserCaption; UserCaptionLbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                AmountTotal := AmountTotal + Amount;
                BaseTotal := BaseTotal + "GST Base";

                if "GST Base" <> 0 then
                    GSTPercent := Format(Amount / "GST Base" * 100, 0, '<Precision,2:><Standard Format,0>')
                else
                    GSTPercent := '';

                LineTotal := Amount + "GST Base";

                if ExportToExcel then begin
                    RowNo := RowNo + 1;
                    ColumnNo := 1;
                    EnterCell(Format("Posting Date"), false, false, false, TempExcelBuffer."Cell Type"::Date);

                    ColumnNo := ColumnNo + 1;
                    EnterCell("Document No.", false, false, false, TempExcelBuffer."Cell Type"::Text);

                    ColumnNo := ColumnNo + 1;
                    EnterCell(Format("Document Type"), false, false, false, TempExcelBuffer."Cell Type"::Text);

                    ColumnNo := ColumnNo + 1;
                    EnterCell("Customer No.", false, false, false, TempExcelBuffer."Cell Type"::Text);

                    ColumnNo := ColumnNo + 1;
                    EnterCell("Customer Name", false, false, false, TempExcelBuffer."Cell Type"::Text);

                    ColumnNo := ColumnNo + 1;
                    EnterCell("Document Line Description", false, false, false, TempExcelBuffer."Cell Type"::Text);

                    ColumnNo := ColumnNo + 1;
                    EnterCell("VAT Bus. Posting Group", false, false, false, TempExcelBuffer."Cell Type"::Text);

                    ColumnNo := ColumnNo + 1;
                    EnterCell("VAT Prod. Posting Group", false, false, false, TempExcelBuffer."Cell Type"::Text);

                    ColumnNo := ColumnNo + 1;
                    EnterCell(GSTPercent, false, false, false, TempExcelBuffer."Cell Type"::Number);

                    ColumnNo := ColumnNo + 1;
                    EnterCell(Format("GST Base", 0, '<Precision,2:><Standard Format,0>'), false, false, false, TempExcelBuffer."Cell Type"::Number);

                    ColumnNo := ColumnNo + 1;
                    EnterCell(Format(Amount, 0, '<Precision,2:><Standard Format,0>'), false, false, false, TempExcelBuffer."Cell Type"::Number);

                    ColumnNo := ColumnNo + 1;
                    EnterCell(
                      Format(Amount + "GST Base", 0, '<Precision,2:><Standard Format,0>'), false, false, false, TempExcelBuffer."Cell Type"::Number);

                    ColumnNo := ColumnNo + 1;
                    EnterCell("Document Line Code", false, false, false, TempExcelBuffer."Cell Type"::Text);
                end;

                Linestotal := Linestotal + LineTotal;
            end;

            trigger OnPreDataItem()
            begin
                SetRange("Posting Date", StartDate, EndDate);
                AmountTotal := 0;
                BaseTotal := 0;
                Linestotal := 0;

                if ExportToExcel then begin
                    TempExcelBuffer.DeleteAll();
                    RowNo := 0;
                    ColumnNo := 0;

                    RowNo := RowNo + 1;
                    ColumnNo := 1;
                    EnterCell('Company Name', true, false, false, TempExcelBuffer."Cell Type"::Text);
                    ColumnNo := ColumnNo + 1;
                    EnterCell(CompanyName, false, false, false, TempExcelBuffer."Cell Type"::Text);

                    RowNo := RowNo + 1;

                    RowNo := RowNo + 1;
                    ColumnNo := 1;
                    EnterCell('Start date', true, false, false, TempExcelBuffer."Cell Type"::Text);
                    ColumnNo := ColumnNo + 1;
                    EnterCell(Format(StartDate), false, false, false, TempExcelBuffer."Cell Type"::Date);

                    RowNo := RowNo + 1;
                    ColumnNo := 1;
                    EnterCell('End date', true, false, false, TempExcelBuffer."Cell Type"::Text);
                    ColumnNo := ColumnNo + 1;
                    EnterCell(Format(EndDate), false, false, false, TempExcelBuffer."Cell Type"::Date);

                    RowNo := RowNo + 1;

                    RowNo := RowNo + 1;
                    ColumnNo := 1;
                    EnterCell('Report created', true, false, false, TempExcelBuffer."Cell Type"::Text);
                    ColumnNo := ColumnNo + 1;
                    EnterCell(Format(Today), false, false, false, TempExcelBuffer."Cell Type"::Date);

                    RowNo := RowNo + 1;
                    ColumnNo := 1;
                    EnterCell('Created by', true, false, false, TempExcelBuffer."Cell Type"::Text);
                    ColumnNo := ColumnNo + 1;
                    EnterCell(Format(UserId), false, false, false, TempExcelBuffer."Cell Type"::Text);

                    RowNo := RowNo + 1;

                    RowNo := RowNo + 1;
                    ColumnNo := 1;
                    EnterCell(FieldCaption("Posting Date"), true, false, false, TempExcelBuffer."Cell Type"::Text);

                    ColumnNo := ColumnNo + 1;
                    EnterCell(FieldCaption("Document No."), true, false, false, TempExcelBuffer."Cell Type"::Text);

                    ColumnNo := ColumnNo + 1;
                    EnterCell(FieldCaption("Document Type"), true, false, false, TempExcelBuffer."Cell Type"::Text);

                    ColumnNo := ColumnNo + 1;
                    EnterCell('Customer Code', true, false, false, TempExcelBuffer."Cell Type"::Text);

                    ColumnNo := ColumnNo + 1;
                    EnterCell('Customer Name', true, false, false, TempExcelBuffer."Cell Type"::Text);

                    ColumnNo := ColumnNo + 1;
                    EnterCell('Description', true, false, false, TempExcelBuffer."Cell Type"::Text);

                    ColumnNo := ColumnNo + 1;
                    EnterCell('GST Bus. Posting Group', true, false, false, TempExcelBuffer."Cell Type"::Text);

                    ColumnNo := ColumnNo + 1;
                    EnterCell('GST Prod. Posting Group', true, false, false, TempExcelBuffer."Cell Type"::Text);

                    ColumnNo := ColumnNo + 1;
                    EnterCell('GST%', true, false, false, TempExcelBuffer."Cell Type"::Text);

                    ColumnNo := ColumnNo + 1;
                    EnterCell(FieldCaption("GST Base"), true, false, false, TempExcelBuffer."Cell Type"::Text);

                    ColumnNo := ColumnNo + 1;
                    EnterCell('GST Amount', true, false, false, TempExcelBuffer."Cell Type"::Text);

                    ColumnNo := ColumnNo + 1;
                    EnterCell('Total Sale', true, false, false, TempExcelBuffer."Cell Type"::Text);

                    ColumnNo := ColumnNo + 1;
                    EnterCell('Code', true, false, false, TempExcelBuffer."Cell Type"::Text);
                end;
            end;
        }
        dataitem(Difference; "GST Sales Entry")
        {
            DataItemTableView = sorting("Entry No.") where("GST Entry No." = filter(0));
            PrintOnlyIfDetail = true;
            column(Difference__Document_Line_Code_; "Document Line Code")
            {
            }
            column(LineTotal_Control1000000053; LineTotal)
            {
            }
            column(Difference_Amount; Amount)
            {
            }
            column(Difference__GST_Base_; "GST Base")
            {
            }
            column(GSTPercent_Control1000000056; GSTPercent)
            {
            }
            column(Difference__VAT_Prod__Posting_Group_; "VAT Prod. Posting Group")
            {
            }
            column(Difference__VAT_Bus__Posting_Group_; "VAT Bus. Posting Group")
            {
            }
            column(Difference__Document_Line_Description_; "Document Line Description")
            {
            }
            column(Difference__Customer_Name_; "Customer Name")
            {
            }
            column(Difference__Customer_No__; "Customer No.")
            {
            }
            column(Difference__Document_Type_; "Document Type")
            {
            }
            column(Difference__Document_No__; "Document No.")
            {
            }
            column(Difference__Posting_Date_; Format("Posting Date"))
            {
            }
            column(Difference_Entry_No_; "Entry No.")
            {
            }
            column(VAT_EntryCaption; VAT_EntryCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                if "GST Base" <> 0 then
                    GSTPercent := Format(Amount / "GST Base" * 100, 0, '<Precision,2:><Standard Format,0>')
                else
                    GSTPercent := '';

                LineTotal := Amount + "GST Base";
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(StartDate; StartDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Start date';
                        ToolTip = 'Specifies the first date of the period.';
                    }
                    field(EndDate; EndDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'End date';
                        ToolTip = 'Specifies the last date for the report.';
                    }
                    field(ExportToExcel; ExportToExcel)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Export to Excel';
                        ToolTip = 'Specifies that you want to export the data to Excel for manual adjustment.';
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

    trigger OnPostReport()
    begin
        if ExportToExcel then begin
            TempExcelBuffer.CreateBookAndOpenExcel('', 'GST Sales', '', CompanyName, UserId);
            Error('');
        end;
    end;

    trigger OnPreReport()
    begin
        if EndDate = 0D then
            EndDate := WorkDate();
    end;

    var
        TempExcelBuffer: Record "Excel Buffer";
        StartDate: Date;
        EndDate: Date;
        ExportToExcel: Boolean;
        ColumnNo: Integer;
        RowNo: Integer;
        GSTPercent: Text[30];
        LineTotal: Decimal;
        AmountTotal: Decimal;
        BaseTotal: Decimal;
        Linestotal: Decimal;
        CodeCaptionLbl: Label 'Code';
        Total_SaleCaptionLbl: Label 'Total Sale';
        GST_AmountCaptionLbl: Label 'GST Amount';
        GST_BaseCaptionLbl: Label 'GST Base';
        GST__CaptionLbl: Label 'GST %';
        GST_Prod__Posting_GroupCaptionLbl: Label 'GST Prod. Posting Group';
        GST_Bus__Posting_GroupCaptionLbl: Label 'GST Bus. Posting Group';
        DescriptionCaptionLbl: Label 'Description';
        Customer_NameCaptionLbl: Label 'Customer Name';
        Customer_CodeCaptionLbl: Label 'Customer Code';
        Document_TypeCaptionLbl: Label 'Document Type';
        Document_No_CaptionLbl: Label 'Document No.';
        Posting_DateCaptionLbl: Label 'Posting Date';
        GST_Sales_ReportCaptionLbl: Label 'GST Sales Report';
        Report_CreatedCaptionLbl: Label 'Report Created';
        CompanyCaptionLbl: Label 'Company';
        Start_DateCaptionLbl: Label 'Start Date';
        End_DateCaptionLbl: Label 'End Date';
        UserCaptionLbl: Label 'User';
        TotalCaptionLbl: Label 'Total';
        VAT_EntryCaptionLbl: Label 'VAT Entry';

    [Scope('OnPrem')]
    procedure EnterCell(CellValue: Text[250]; Bold: Boolean; Italic: Boolean; Underline: Boolean; CellType: Option)
    begin
        TempExcelBuffer.Init();
        TempExcelBuffer.Validate("Row No.", RowNo);
        TempExcelBuffer.Validate("Column No.", ColumnNo);
        TempExcelBuffer."Cell Value as Text" := CellValue;
        TempExcelBuffer.Formula := '';
        TempExcelBuffer.Bold := Bold;
        TempExcelBuffer.Italic := Italic;
        TempExcelBuffer.Underline := Underline;
        TempExcelBuffer."Cell Type" := CellType;
        TempExcelBuffer.Insert();
    end;
}

