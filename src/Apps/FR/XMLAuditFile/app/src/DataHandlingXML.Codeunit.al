// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.AuditFileExport;

using System.Utilities;

codeunit 10806 "Data Handling XML" implements "Audit File Export Data Handling"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        GLEntriesXMLLbl: Label 'G/L Entries XML';

    procedure GenerateFileContentForAuditFileExportLine(var AuditFileExportLine: Record "Audit File Export Line"; var TempBlob: Codeunit "Temp Blob")
    var
        GenerateFileXML: Codeunit "Generate File XML";
    begin
        GenerateFileXML.GenerateXMLFile(AuditFileExportLine, TempBlob);
    end;

    procedure LoadStandardAccounts(StandardAccountType: Enum "Standard Account Type") Result: Boolean;
    begin
    end;

    procedure CreateAuditFileExportLines(var Header: Record "Audit File Export Header")
    var
        AuditFileExportLine: Record "Audit File Export Line";
        AuditFileExportMgt: Codeunit "Audit File Export Mgt.";
        LineNo: Integer;
    begin
        AuditFileExportLine.SetRange(ID, Header.ID);
        AuditFileExportLine.DeleteAll(true);

        AuditFileExportMgt.InsertAuditFileExportLine(AuditFileExportLine, LineNo, Header.ID, "Audit File Export Data Class"::Custom, GLEntriesXMLLbl, Header."Starting Date", Header."Ending Date");
    end;

    procedure GetFileNameForAuditFileExportLine(var AuditFileExportLine: Record "Audit File Export Line"): Text[1024]
    begin
        exit('GLEntries_' + Format(AuditFileExportLine."Ending Date") + '.xml');
    end;

    procedure InitAuditExportDataTypeSetup();
    begin
    end;
}
