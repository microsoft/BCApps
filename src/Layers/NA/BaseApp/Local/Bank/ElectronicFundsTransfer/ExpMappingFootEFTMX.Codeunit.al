// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.ElectronicFundsTransfer;

using System.IO;

codeunit 10337 "Exp. Mapping Foot EFT MX"
{
    TableNo = "Data Exch.";

    trigger OnRun()
    var
        ACHCecobanFooter: Record "ACH Cecoban Footer";
        DataExch: Record "Data Exch.";
        DataExchLineDef: Record "Data Exch. Line Def";
        EFTExportMgt: Codeunit "EFT Export Mgt";
        RecordRef: RecordRef;
        LineNo: Integer;
    begin
        // Range through the Footer record
        LineNo := 1;
        DataExchLineDef.Init();
        DataExchLineDef.SetRange("Data Exch. Def Code", Rec."Data Exch. Def Code");
        DataExchLineDef.SetRange("Line Type", DataExchLineDef."Line Type"::Footer);
        if DataExchLineDef.FindFirst() then begin
            DataExch.SetRange("Entry No.", Rec."Entry No.");
            if DataExch.FindFirst() then
                if ACHCecobanFooter.Get(Rec."Entry No.") then begin
                    RecordRef.GetTable(ACHCecobanFooter);
                    EFTExportMgt.InsertDataExchLineForFlatFile(
                      DataExch,
                      LineNo,
                      RecordRef);
                end;
        end;
    end;
}

