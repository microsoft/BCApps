// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.PositivePay;

using System.IO;

/// <summary>
/// Maps positive pay header records to data exchange fields for export file generation.
/// This codeunit handles the transformation of header identification data into the structured format required for bank files.
/// </summary>
/// <remarks>
/// The Export Mapping Header Positive Pay codeunit processes positive pay header records containing company and account
/// identification information. It maps header fields to the data exchange structure ensuring that file identification
/// data is properly formatted according to export definition requirements. The header mapping provides banks with
/// essential context for processing the positive pay file content.
/// </remarks>
codeunit 1703 "Exp. Mapping Head Pos. Pay"
{
    TableNo = "Data Exch.";

    trigger OnRun()
    var
        PositivePayHeader: Record "Positive Pay Header";
        DataExch: Record "Data Exch.";
        DataExchLineDef: Record "Data Exch. Line Def";
        PositivePayExportMgt: Codeunit "Positive Pay Export Mgt";
        RecordRef: RecordRef;
        Window: Dialog;
        LineNo: Integer;
    begin
        Window.Open(ProgressMsg);

        // Range through the Header record
        LineNo := 1;
        DataExchLineDef.Init();
        DataExchLineDef.SetRange("Data Exch. Def Code", Rec."Data Exch. Def Code");
        DataExchLineDef.SetRange("Line Type", DataExchLineDef."Line Type"::Header);
        if DataExchLineDef.FindFirst() then begin
            DataExch.SetRange("Entry No.", Rec."Entry No.");
            if DataExch.FindFirst() then begin
                PositivePayHeader.Init();
                PositivePayHeader.SetRange("Data Exch. Entry No.", Rec."Entry No.");
                if PositivePayHeader.FindFirst() then begin
                    Window.Update(1, LineNo);
                    RecordRef.GetTable(PositivePayHeader);
                    PositivePayExportMgt.InsertDataExchLineForFlatFile(
                      DataExch,
                      LineNo,
                      RecordRef);
                end;
            end;
        end;
        Window.Close();
    end;

    var
#pragma warning disable AA0470
        ProgressMsg: Label 'Processing line no. #1######.';
#pragma warning restore AA0470
}

