// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Journal;

using Microsoft.Warehouse.Ledger;

codeunit 7300 "Whse. Jnl.-B.Register+Print"
{
    TableNo = "Warehouse Journal Batch";

    trigger OnRun()
    begin
        WhseJnlBatch.Copy(Rec);
        Code();
        Rec.Copy(WhseJnlBatch);
    end;

    var
        WhseJnlTemplate: Record "Warehouse Journal Template";
        WhseJnlBatch: Record "Warehouse Journal Batch";
        WhseJnlLine: Record "Warehouse Journal Line";
        WhseReg: Record "Warehouse Register";
        WhseJnlRegisterBatch: Codeunit "Whse. Jnl.-Register Batch";
        JnlWithErrors: Boolean;

#pragma warning disable AA0074
        Text000: Label 'Do you want to register the journals?';
        Text001: Label 'The journals were successfully registered.';
        Text002: Label 'It was not possible to register all of the journals. ';
        Text003: Label 'The journals that were not successfully registered are now marked.';
#pragma warning restore AA0074

    local procedure "Code"()
    begin
        WhseJnlTemplate.Get(WhseJnlBatch."Journal Template Name");
        WhseJnlTemplate.TestField("Registering Report ID");

        if not Confirm(Text000, false) then
            exit;

        WhseJnlBatch.Find('-');
        repeat
            WhseJnlLine."Journal Template Name" := WhseJnlBatch."Journal Template Name";
            WhseJnlLine."Journal Batch Name" := WhseJnlBatch.Name;
            WhseJnlLine."Location Code" := WhseJnlBatch."Location Code";
            WhseJnlLine."Line No." := 10000;
            Clear(WhseJnlRegisterBatch);
            if WhseJnlRegisterBatch.Run(WhseJnlLine) then begin
                OnAfterRegisterBatch(WhseJnlLine);
                WhseJnlBatch.Mark(false);
                if WhseReg.Get(WhseJnlLine."Line No.") then begin
                    WhseReg.SetRecFilter();
                    REPORT.Run(WhseJnlTemplate."Registering Report ID", false, false, WhseReg);
                end;
            end else begin
                WhseJnlBatch.Mark(true);
                JnlWithErrors := true;
            end;
        until WhseJnlBatch.Next() = 0;

        if not JnlWithErrors then
            Message(Text001)
        else
            Message(
              Text002 +
              Text003);

        if not WhseJnlBatch.Find('=><') then begin
            WhseJnlBatch.Reset();
            WhseJnlBatch.FilterGroup(2);
            WhseJnlBatch.SetRange("Journal Template Name", WhseJnlBatch."Journal Template Name");
            WhseJnlBatch.SetRange("Location Code", WhseJnlBatch."Location Code");
            WhseJnlBatch.FilterGroup(0);
            WhseJnlBatch.Name := '';
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRegisterBatch(var WarehouseJournalLine: Record "Warehouse Journal Line")
    begin
    end;
}

