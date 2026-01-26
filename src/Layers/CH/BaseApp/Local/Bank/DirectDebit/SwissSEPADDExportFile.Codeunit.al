// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.DirectDebit;

codeunit 11530 "Swiss SEPA DD-Export File"
{
    TableNo = "Direct Debit Collection Entry";

    trigger OnRun()
    var
        SEPADDExportFile: Codeunit "SEPA DD-Export File";
    begin
        if ExportToServerFile then
            SEPADDExportFile.EnableExportToServerFile();
        SEPADDExportFile.Run(Rec);
    end;

    var
        ExportToServerFile: Boolean;

    procedure EnableExportToServerFile()
    begin
        ExportToServerFile := true;
    end;
}

