// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.ElectronicFundsTransfer;

using System.IO;
using System.Utilities;

codeunit 10323 "Exp. External Data EFT"
{
    Permissions = TableData "Data Exch." = rimd;
    TableNo = "Data Exch.";

    trigger OnRun()
    begin
    end;

    var
        ExternalContentErr: Label '%1 is empty.', Comment = '%1=File Content field caption.';
        DownloadFromStreamErr: Label 'The file has not been saved.';

    [Scope('OnPrem')]
    procedure CreateExportFile(DataExch: Record "Data Exch."; ShowDialog: Boolean)
    var
        TempBlob: Codeunit "Temp Blob";
        FileMgt: Codeunit "File Management";
        ExportFileName: Text;
    begin
        DataExch.CalcFields("File Content");
        if not DataExch."File Content".HasValue() then
            Error(ExternalContentErr, DataExch.FieldCaption("File Content"));

        TempBlob.FromRecord(DataExch, DataExch.FieldNo("File Content"));
        ExportFileName := DataExch."Data Exch. Def Code" + Format(Today, 0, '<Month,2><Day,2><Year4>') + '.txt';
        if FileMgt.BLOBExport(TempBlob, ExportFileName, ShowDialog) = '' then
            Error(DownloadFromStreamErr);
    end;
}

