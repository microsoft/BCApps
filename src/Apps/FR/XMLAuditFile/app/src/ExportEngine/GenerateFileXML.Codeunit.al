// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.AuditFileExport;

using Microsoft.Finance.GeneralLedger.Ledger;
using System.Telemetry;
using System.Utilities;

codeunit 10811 "Generate File XML"
{
    Access = Internal;
    InherentEntitlements = X;

    var
        StartingDate: Date;
        EndingDate: Date;
        FRGeneralLedgerXMLTok: Label 'FR Export General Ledger Entries to XML File', Locked = true;
        FRGLXMLFrameworkTok: Label 'FR General Ledger Entries XML generated via Audit File Export Framework', Locked = true;

    procedure GenerateXMLFile(AuditFileExportLine: Record "Audit File Export Line"; var TempBlob: Codeunit "Temp Blob")
    var
        AuditFileExportHeader: Record "Audit File Export Header";
        GLEntry: Record "G/L Entry";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ExportGLEntries: XmlPort "Export G/L Entries FR";
        OutStream: OutStream;
    begin
        AuditFileExportHeader.Get(AuditFileExportLine.ID);
        InitGlobalVariables(AuditFileExportHeader);

        FeatureTelemetry.LogUptake('0000V8T', FRGeneralLedgerXMLTok, Enum::"Feature Uptake Status"::"Set up");

        TempBlob.CreateOutStream(OutStream);
        GLEntry.SetRange("Posting Date", StartingDate, EndingDate);
        ExportGLEntries.InitializeRequest(GLEntry, StartingDate, EndingDate);
        ExportGLEntries.SetDestination(OutStream);
        ExportGLEntries.Export();

        FeatureTelemetry.LogUptake('0000QPP', FRGeneralLedgerXMLTok, Enum::"Feature Uptake Status"::"Used");
        FeatureTelemetry.LogUsage('0000QPQ', FRGeneralLedgerXMLTok, FRGLXMLFrameworkTok);
    end;

    procedure InitGlobalVariables(AuditFileExportHeader: Record "Audit File Export Header")
    begin
        StartingDate := AuditFileExportHeader."Starting Date";
        EndingDate := AuditFileExportHeader."Ending Date";
    end;
}
