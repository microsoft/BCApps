// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Reports;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using System.IO;
using System.Utilities;

report 11109 "Paragraph 131 Export"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Finance/GeneralLedger/Reports/Paragraph131Export.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Paragraph 131 Export';
    UsageCategory = Tasks;

    dataset
    {
        dataitem("G/L Account"; "G/L Account")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.";
            column(GETFILTERS; GetFilters)
            {
            }
            column(Filename; Filename)
            {
            }
            column(G_L_Account__No__; "No.")
            {
            }
            column(G_L_Account_Name; Name)
            {
            }
            column(GETFILTERSCaption; GETFILTERSCaptionLbl)
            {
            }
            column(FilenameCaption; FilenameCaptionLbl)
            {
            }
            column(G_L_Account__No__Caption; FieldCaption("No."))
            {
            }
            column(G_L_Account_NameCaption; FieldCaption(Name))
            {
            }
            column(G_L_Entry__Posting_Date_Caption; G_L_Entry__Posting_Date_CaptionLbl)
            {
            }
            column(G_L_Entry__Document_No__Caption; "G/L Entry".FieldCaption("Document No."))
            {
            }
            column(G_L_Entry_DescriptionCaption; "G/L Entry".FieldCaption(Description))
            {
            }
            column(G_L_Entry__VAT_Amount_Caption; "G/L Entry".FieldCaption("VAT Amount"))
            {
            }
            column(G_L_Entry__Debit_Amount_Caption; "G/L Entry".FieldCaption("Debit Amount"))
            {
            }
            column(G_L_Entry__Credit_Amount_Caption; "G/L Entry".FieldCaption("Credit Amount"))
            {
            }
            column(G_L_Entry__G_L_Account_No__Caption; "G/L Entry".FieldCaption("G/L Account No."))
            {
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(CreditToDate; CreditToDate)
                {
                }
                column(DebitToDate; DebitToDate)
                {
                }
                column(VATToDate; VATToDate)
                {
                }
                column(DescToDate; DescToDate)
                {
                }
                column(DocNoToDate; DocNoToDate)
                {
                }
                column(DateToDate; Format(DateToDate))
                {
                }
                column(G_L_Account___No__; "G/L Account"."No.")
                {
                }
                column(Integer_Number; Number)
                {
                }
            }
            dataitem("G/L Entry"; "G/L Entry")
            {
                DataItemLink = "G/L Account No." = field("No.");
                DataItemTableView = sorting("G/L Account No.", "Posting Date");
                column(G_L_Entry__Posting_Date_; Format("Posting Date"))
                {
                }
                column(G_L_Entry__Document_No__; "Document No.")
                {
                }
                column(G_L_Entry_Description; Description)
                {
                }
                column(G_L_Entry__VAT_Amount_; "VAT Amount")
                {
                }
                column(G_L_Entry__Debit_Amount_; "Debit Amount")
                {
                }
                column(G_L_Entry__Credit_Amount_; "Credit Amount")
                {
                }
                column(G_L_Entry__G_L_Account_No__; "G/L Account No.")
                {
                }
                column(G_L_Entry_Entry_No_; "Entry No.")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    ExportFile.Write(StrSubstNo('%1;%2;%3;%4;%5;%6;%7',
                        "G/L Account No.",
                        "Posting Date",
                        "Document No.",
                        Description,
                        "Debit Amount",
                        "Credit Amount",
                        "VAT Amount"));
                end;

                trigger OnPreDataItem()
                begin
                    "G/L Entry".SetRange("Posting Date", FromDate, ToDate);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                "G/L Account".SetRange("Date Filter", 00000101D, ClosingDate(FromDate - 1));
                "G/L Account".CalcFields("Debit Amount", "Credit Amount", "VAT Amount");
                DebitToDate := "Debit Amount";
                CreditToDate := "Credit Amount";
                VATToDate := "VAT Amount";
                DateToDate := FromDate;
                DocNoToDate := 'SYSEB';
                DescToDate := '-------';

                ExportFile.Write(StrSubstNo('%1;%2;%3;%4;%5;%6;%7',
                    "G/L Account"."No.",
                    DateToDate,
                    DocNoToDate,
                    DescToDate,
                    DebitToDate,
                    CreditToDate,
                    VATToDate));
            end;

            trigger OnPreDataItem()
            begin
                if FromDate = 0D then
                    FromDate := 00010101D;

                if ToDate = 0D then
                    ToDate := 99991231D;

                ExportFile.TextMode(true);
                ExportFile.WriteMode(true);
                ExportFile.Create(Filename);
                ExportFile.Write(StrSubstNo('%1;%2;%3;%4;%5;%6;%7',
                    Text001,
                    Text002,
                    Text003,
                    Text004,
                    Text005,
                    Text006,
                    Text007));
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
                    field(FromDate; FromDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the date from which the report or batch job processes information.';
                    }
                    field(ToDate; ToDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Ending Date';
                        ToolTip = 'Specifies the last date that the report includes data for.';
                    }
                    field(FileName; Filename)
                    {
                        ApplicationArea = All;
                        Caption = 'File Name';
                        ToolTip = 'Specifies data according to the Paragraph 131 requirements.';
                        Visible = FileNameVisible;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            FileNameVisible := true;
        end;

        trigger OnOpenPage()
        begin
            FileNameVisible := false;
        end;
    }

    labels
    {
    }

    trigger OnPostReport()
    var
        ToFile: Text[1024];
    begin
        ExportFile.Close();

        ToFile := Text106;
        Download(Filename, Text104, '', Text105, ToFile);
        Filename := Format(ToFile, -MaxStrLen(Filename));
    end;

    trigger OnPreReport()
    var
        RBMgt: Codeunit "File Management";
    begin
        Filename := RBMgt.ServerTempFileName('');
    end;

    var
        ExportFile: File;
        FromDate: Date;
        ToDate: Date;
        DebitToDate: Decimal;
        CreditToDate: Decimal;
        DateToDate: Date;
        VATToDate: Decimal;
        DocNoToDate: Code[10];
        DescToDate: Text[30];
        Filename: Text[250];
        Text001: Label 'Account Number';
        Text002: Label 'Posting Date';
        Text003: Label 'Document Number';
        Text004: Label 'Posting Text';
        Text005: Label 'Debit Amount';
        Text006: Label 'Credit Amount';
        Text007: Label 'VAT Amount';
        Text104: Label 'Export';
        Text105: Label 'All Files (*.*)|*.*';
        Text106: Label 'Default.txt';
        FileNameVisible: Boolean;
        GETFILTERSCaptionLbl: Label 'Table filter';
        FilenameCaptionLbl: Label 'Filename';
        G_L_Entry__Posting_Date_CaptionLbl: Label 'Posting Date';
}

