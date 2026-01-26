// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.AuditFileExport;

using Microsoft.Finance.GeneralLedger.Ledger;
using System.IO;
using System.Telemetry;
using System.Utilities;

report 10820 "Export G/L Entries to XML"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Export G/L Entries to XML';
    ProcessingOnly = true;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = const(1));

            trigger OnAfterGetRecord()
            begin
                OutputFile.TextMode(true);
                OutputFile.WriteMode(true);
                OutputFile.Create(FileName);
                OutputFile.CreateOutStream(OutputStream);

                ExportGLEntries.InitializeRequest(GLEntry, StartingDate, EndingDate);
                ExportGLEntries.SetDestination(OutputStream);
                ExportGLEntries.Export();

                OutputFile.Close();
                Clear(OutputStream);
            end;

            trigger OnPostDataItem()
            var
                FileMgt: Codeunit "File Management";
            begin
                ToFile := Text010 + '.xml';
                if not FileMgt.DownloadHandler(FileName, Text004, '', Text005, ToFile) then
                    exit;
                Message(Text006);
            end;

            trigger OnPreDataItem()
            begin
                if StartingDate = 0D then
                    Error(Text001);
                if EndingDate = 0D then
                    Error(Text002);
                if FileName = '' then
                    Error(Text003);

                GLEntry.SetRange("Posting Date", StartingDate, EndingDate);
                if GLEntry.Count = 0 then
                    Error(Text007);
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
                    field(StartingDate; StartingDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the first date for the time period to export general ledger entries from.';
                    }
                    field(EndingDate; EndingDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Ending Date';
                        ToolTip = 'Specifies the last date to include in the time interval that you export entries for.';
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
    var
        FileMgt: Codeunit "File Management";
    begin
        FeatureTelemetry.LogUptake('1000HO7', FRGeneralLedgerXMLTok, Enum::"Feature Uptake Status"::"Set up");
        FileName := FileMgt.ServerTempFileName('xml');
    end;

    trigger OnInitReport()
    begin
        FeatureTelemetry.LogUptake('1000HO6', FRGeneralLedgerXMLTok, Enum::"Feature Uptake Status"::Discovered);
    end;

    trigger OnPostReport()
    begin
        FeatureTelemetry.LogUptake('1000HO8', FRGeneralLedgerXMLTok, Enum::"Feature Uptake Status"::"Used");
        FeatureTelemetry.LogUsage('1000HO9', FRGeneralLedgerXMLTok, 'FR General Ledger Entries Tax Audits Exported to XML File');
    end;

    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        FRGeneralLedgerXMLTok: Label 'FR Export General Ledger Entries to XML File', Locked = true;
        Text001: Label 'You must enter a Starting Date.';
        Text002: Label 'You must enter an Ending Date.';
        Text003: Label 'You must enter a File Name.';
        Text004: Label 'Export to XML File';
        Text005: Label 'XML Files (*.xml)|*.xml|All Files (*.*)|*.*';
        Text006: Label 'XML File created successfully.';
        Text007: Label 'There are no entries to export within the defined filter. The file was not created.';
        GLEntry: Record "G/L Entry";
        ExportGLEntries: XMLport "Export G/L Entries";
        OutputStream: OutStream;
        StartingDate: Date;
        EndingDate: Date;
        FileName: Text[1024];
        ToFile: Text[1024];
        OutputFile: File;
        Text010: Label 'Default';
}

