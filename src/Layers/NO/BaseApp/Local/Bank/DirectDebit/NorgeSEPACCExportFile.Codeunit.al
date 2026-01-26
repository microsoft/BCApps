// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.DirectDebit;

using Microsoft.Finance.GeneralLedger.Journal;

codeunit 10638 "Norge SEPA CC-Export File"
{
    TableNo = "Gen. Journal Line";

    trigger OnRun()
    var
        SEPACTExportFile: Codeunit "SEPA CT-Export File";
    begin
        if ExportToServerFile then
            SEPACTExportFile.EnableExportToServerFile();
        SEPACTExportFile.Run(Rec);
    end;

    var
        ExportToServerFile: Boolean;

    [Scope('OnPrem')]
    procedure EnableExportToServerFile()
    begin
        ExportToServerFile := true;
    end;
}

