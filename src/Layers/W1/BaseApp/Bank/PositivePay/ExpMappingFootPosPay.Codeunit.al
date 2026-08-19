// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.PositivePay;

using System.IO;

/// <summary>
/// Maps positive pay footer records to data exchange fields for export file generation.
/// This codeunit handles the transformation of footer summary data into the structured format required for bank files.
/// </summary>
/// <remarks>
/// The Export Mapping Footer Positive Pay codeunit processes positive pay footer records containing summary totals
/// and count information. It maps footer fields to the data exchange structure ensuring that summary information
/// is properly formatted according to export definition requirements. The footer mapping provides banks with
/// validation data to verify the completeness and accuracy of transmitted check information.
/// </remarks>
codeunit 1707 "Exp. Mapping Foot Pos. Pay"
{
    TableNo = "Data Exch.";

    trigger OnRun()
    var
        PositivePayFooter: Record "Positive Pay Footer";
        DataExch: Record "Data Exch.";
        DataExchLineDef: Record "Data Exch. Line Def";
        PositivePayExportMgt: Codeunit "Positive Pay Export Mgt";
        RecordRef: RecordRef;
        Window: Dialog;
        LineNo: Integer;
    begin
        Window.Open(ProgressMsg);

        // Range through the Footer record
        LineNo := 1;
        DataExchLineDef.Init();
        DataExchLineDef.SetRange("Data Exch. Def Code", Rec."Data Exch. Def Code");
        DataExchLineDef.SetRange("Line Type", DataExchLineDef."Line Type"::Footer);
        if DataExchLineDef.FindFirst() then begin
            DataExch.SetRange("Entry No.", Rec."Entry No.");
            if DataExch.FindFirst() then begin
                PositivePayFooter.Init();
                PositivePayFooter.SetRange("Data Exch. Entry No.", Rec."Entry No.");
                if PositivePayFooter.FindFirst() then begin
                    Window.Update(1, LineNo);
                    RecordRef.GetTable(PositivePayFooter);
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

