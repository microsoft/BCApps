// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.VAT.Ledger;
using System.IO;

report 28164 "GST Purchase Report"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/FinancialMgt/VAT/GSTPurchaseReport.rdlc';
    Caption = 'GST Purchase Report';

    dataset
    {
        dataitem("GST Purchase Entry"; "GST Purchase Entry")
        {
            DataItemTableView = sorting("Entry No.") where("GST Entry No." = filter(<> 0));
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
            column(USERID; UserId)
            {
            }
            column(GST_Purchase_Entry__Posting_Date_; Format("Posting Date"))
            {
            }
            column(GST_Purchase_Entry__Document_No__; "Document No.")
            {
            }
            column(GST_Purchase_Entry__Document_Type_; "Document Type")
            {
            }
            column(GST_Purchase_Entry__Vendor_No__; "Vendor No.")
            {
            }
            column(GST_Purchase_Entry__Vendor_Name_; "Vendor Name")
            {
            }
            column(GST_Purchase_Entry__Document_Line_Code_; "Document Line Code")
            {
            }
            column(LineTotal; LineTotal)
            {
            }
            column(GST_Purchase_Entry_Amount; Amount)
            {
            }
            column(GST_Purchase_Entry__GST_Base_; "GST Base")
            {
            }
            column(GSTPercent; GSTPercent)
            {
            }
            column(GST_Purchase_Entry__VAT_Prod__Posting_Group_; "VAT Prod. Posting Group")
            {
            }
            column(GST_Purchase_Entry__VAT_Bus__Posting_Group_; "VAT Bus. Posting Group")
            {
            }
            column(GST_Purchase_Entry__Document_Line_Description_; "Document Line Description")
            {
            }
            column(BaseTotal; BaseTotal)
            {
            }
            column(AmountTotal; AmountTotal)
            {
            }
            column(LinesTotal; LinesTotal)
            {
            }
            column(GST_Purchase_Entry_Entry_No_; "Entry No.")
            {
            }
            column(GST_Purchase_Entry__Posting_Date_Caption; GST_Purchase_Entry__Posting_Date_CaptionLbl)
            {
            }
            column(GST_Purchase_Entry__Document_No__Caption; FieldCaption("Document No."))
            {
            }
            column(GST_Purchase_Entry__Document_Type_Caption; FieldCaption("Document Type"))
            {
            }
            column(GST_Purchase_Entry__Vendor_No__Caption; FieldCaption("Vendor No."))
            {
            }
            column(GST_Purchase_Entry__Vendor_Name_Caption; FieldCaption("Vendor Name"))
            {
            }
            column(GST_Purchase_ReportCaption; GST_Purchase_ReportCaptionLbl)
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
            column(GST_Bus__Posting_GroupCaption; GST_Bus__Posting_GroupCaptionLbl)
            {
            }
            column(GST_Prod__Posting_GroupCaption; GST_Prod__Posting_GroupCaptionLbl)
            {
            }
            column(GST__Caption; GST__CaptionLbl)
            {
            }
            column(GST_BaseCaption; GST_BaseCaptionLbl)
            {
            }
            column(GST_AmountCaption; GST_AmountCaptionLbl)
            {
            }
            column(Total_PurchaseCaption; Total_PurchaseCaptionLbl)
            {
            }
            column(CodeCaption; CodeCaptionLbl)
            {
            }
            column(DescriptionCaption; DescriptionCaptionLbl)
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
                    EnterCell("Vendor No.", false, false, false, TempExcelBuffer."Cell Type"::Text);

                    ColumnNo := ColumnNo + 1;
                    EnterCell("Vendor Name", false, false, false, TempExcelBuffer."Cell Type"::Text);

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

                LinesTotal := LinesTotal + LineTotal;
            end;

            trigger OnPreDataItem()
            begin
                SetRange("Posting Date", StartDate, EndDate);
                AmountTotal := 0;
                BaseTotal := 0;
                LinesTotal := 0;
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
                    EnterCell('Vendor Code', true, false, false, TempExcelBuffer."Cell Type"::Text);

                    ColumnNo := ColumnNo + 1;
                    EnterCell('Vendor Name', true, false, false, TempExcelBuffer."Cell Type"::Text);

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
                    EnterCell('Total Purchase', true, false, false, TempExcelBuffer."Cell Type"::Text);

                    ColumnNo := ColumnNo + 1;
                    EnterCell('Code', true, false, false, TempExcelBuffer."Cell Type"::Text);
                end;
            end;
        }
        dataitem(Difference; "GST Purchase Entry")
        {
            DataItemTableView = sorting("Entry No.") where("GST Entry No." = filter(0));
            PrintOnlyIfDetail = true;
            column(Difference__Document_Line_Code_; "Document Line Code")
            {
            }
            column(LineTotal_Control1500005; LineTotal)
            {
            }
            column(Difference_Amount; Amount)
            {
            }
            column(Difference__GST_Base_; "GST Base")
            {
            }
            column(GSTPercent_Control1500024; GSTPercent)
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
            column(Difference__Vendor_Name_; "Vendor Name")
            {
            }
            column(Difference__Vendor_No__; "Vendor No.")
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
            TempExcelBuffer.CreateBookAndOpenExcel('', 'GST Purchases', '', CompanyName, UserId);
            Error('');
        end;
    end;

    trigger OnPreReport()
    begin
        if EndDate = 0D then
            EndDate := WorkDate();
    end;

    var
        TempExcelBuffer: Record "Excel Buffer" temporary;
        StartDate: Date;
        EndDate: Date;
        ExportToExcel: Boolean;
        ColumnNo: Integer;
        RowNo: Integer;
        GSTPercent: Text[30];
        LineTotal: Decimal;
        AmountTotal: Decimal;
        BaseTotal: Decimal;
        LinesTotal: Decimal;
        GST_Purchase_Entry__Posting_Date_CaptionLbl: Label 'Posting Date';
        GST_Purchase_ReportCaptionLbl: Label 'GST Purchase Report';
        Report_CreatedCaptionLbl: Label 'Report Created';
        CompanyCaptionLbl: Label 'Company';
        Start_DateCaptionLbl: Label 'Start Date';
        End_DateCaptionLbl: Label 'End Date';
        UserCaptionLbl: Label 'User';
        GST_Bus__Posting_GroupCaptionLbl: Label 'GST Bus. Posting Group';
        GST_Prod__Posting_GroupCaptionLbl: Label 'GST Prod. Posting Group';
        GST__CaptionLbl: Label 'GST %';
        GST_BaseCaptionLbl: Label 'GST Base';
        GST_AmountCaptionLbl: Label 'GST Amount';
        Total_PurchaseCaptionLbl: Label 'Total Purchase';
        CodeCaptionLbl: Label 'Code';
        DescriptionCaptionLbl: Label 'Description';
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

