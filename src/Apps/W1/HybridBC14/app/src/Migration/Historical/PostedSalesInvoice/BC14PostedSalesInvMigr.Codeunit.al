// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14;

codeunit 50180 "BC14 Posted Sales Inv Migr." implements "IHistoricalMigrator"
{
    var
        MigratorNameLbl: Label 'Posted Sales Invoice Migrator';

    procedure GetName(): Text[250]
    begin
        exit(MigratorNameLbl);
    end;

    procedure IsEnabled(): Boolean
    var
        BC14CompanySettings: Record "BC14CompanyMigrationSettings";
    begin
        if not BC14CompanySettings.GetReceivablesModuleEnabled() then
            exit(false);

        exit(GetRecordCount() > 0);
    end;

    procedure GetSourceTableId(): Integer
    begin
        exit(Database::"BC14 Posted Sales Inv Header");
    end;

    procedure InitializeSourceRecords(var SourceRecordRef: RecordRef)
    begin
        // No special filters needed for Posted Sales Invoice migration
    end;

    procedure MigrateRecord(var SourceRecordRef: RecordRef): Boolean
    var
        BC14PostedSalesInvHeader: Record "BC14 Posted Sales Inv Header";
    begin
        SourceRecordRef.SetTable(BC14PostedSalesInvHeader);
        exit(TryMigrateInvoice(BC14PostedSalesInvHeader));
    end;

    procedure GetSourceRecordKey(var SourceRecordRef: RecordRef): Text[250]
    var
        NoFieldRef: FieldRef;
    begin
        NoFieldRef := SourceRecordRef.Field(1); // No. field
        exit(Format(NoFieldRef.Value()));
    end;

    procedure GetRecordCount(): Integer
    var
        BC14PostedSalesInvHeader: Record "BC14 Posted Sales Inv Header";
    begin
        exit(BC14PostedSalesInvHeader.Count());
    end;

    [TryFunction]
    local procedure TryMigrateInvoice(BC14PostedSalesInvHeader: Record "BC14 Posted Sales Inv Header")
    begin
        MigrateInvoice(BC14PostedSalesInvHeader);
    end;

    local procedure MigrateInvoice(BC14PostedSalesInvHeader: Record "BC14 Posted Sales Inv Header")
    var
        BC14ArchSalesInvHeader: Record "BC14 Arch. Sales Inv. Header";
        BC14HelperFunctions: Codeunit "BC14 Helper Functions";
        SkippedAlreadyMigratedLbl: Label 'Posted Sales Invoice %1 skipped - already migrated to Archive.', Comment = '%1 = Document No.';
    begin
        // Check if already migrated to Archive
        if BC14ArchSalesInvHeader.Get(BC14PostedSalesInvHeader."No.") then begin
            Session.LogMessage('0000ROU', StrSubstNo(SkippedAlreadyMigratedLbl, BC14PostedSalesInvHeader."No."), Verbosity::Verbose, DataClassification::CustomerContent, TelemetryScope::ExtensionPublisher, 'Category', BC14HelperFunctions.GetTelemetryCategory());
            exit;
        end;

        // Create Archived Sales Invoice Header - manual field assignment to avoid field number mismatch
        BC14ArchSalesInvHeader.Init();
        BC14ArchSalesInvHeader."No." := BC14PostedSalesInvHeader."No.";
        BC14ArchSalesInvHeader."Sell-to Customer No." := BC14PostedSalesInvHeader."Sell-to Customer No.";
        BC14ArchSalesInvHeader."Sell-to Customer Name" := BC14PostedSalesInvHeader."Sell-to Customer Name";
        BC14ArchSalesInvHeader."Bill-to Customer No." := BC14PostedSalesInvHeader."Bill-to Customer No.";
        BC14ArchSalesInvHeader."Bill-to Name" := BC14PostedSalesInvHeader."Bill-to Name";
        BC14ArchSalesInvHeader."Bill-to Address" := BC14PostedSalesInvHeader."Bill-to Address";
        BC14ArchSalesInvHeader."Bill-to City" := BC14PostedSalesInvHeader."Bill-to City";
        BC14ArchSalesInvHeader."Bill-to Post Code" := BC14PostedSalesInvHeader."Bill-to Post Code";
        BC14ArchSalesInvHeader."Bill-to Country/Region Code" := BC14PostedSalesInvHeader."Bill-to Country/Region Code";
        BC14ArchSalesInvHeader."Posting Date" := BC14PostedSalesInvHeader."Posting Date";
        BC14ArchSalesInvHeader."Document Date" := BC14PostedSalesInvHeader."Document Date";
        BC14ArchSalesInvHeader."Due Date" := BC14PostedSalesInvHeader."Due Date";
        BC14ArchSalesInvHeader."External Document No." := BC14PostedSalesInvHeader."External Document No.";
        BC14ArchSalesInvHeader."Your Reference" := BC14PostedSalesInvHeader."Your Reference";
        BC14ArchSalesInvHeader."Currency Code" := BC14PostedSalesInvHeader."Currency Code";
        BC14ArchSalesInvHeader."Currency Factor" := BC14PostedSalesInvHeader."Currency Factor";
        BC14ArchSalesInvHeader."Salesperson Code" := BC14PostedSalesInvHeader."Salesperson Code";
        BC14ArchSalesInvHeader."Shortcut Dimension 1 Code" := BC14PostedSalesInvHeader."Shortcut Dimension 1 Code";
        BC14ArchSalesInvHeader."Shortcut Dimension 2 Code" := BC14PostedSalesInvHeader."Shortcut Dimension 2 Code";
        BC14ArchSalesInvHeader."Payment Terms Code" := BC14PostedSalesInvHeader."Payment Terms Code";
        BC14ArchSalesInvHeader."Payment Method Code" := BC14PostedSalesInvHeader."Payment Method Code";
        BC14ArchSalesInvHeader."Ship-to Name" := BC14PostedSalesInvHeader."Ship-to Name";
        BC14ArchSalesInvHeader."Ship-to Address" := BC14PostedSalesInvHeader."Ship-to Address";
        BC14ArchSalesInvHeader."Ship-to City" := BC14PostedSalesInvHeader."Ship-to City";
        BC14ArchSalesInvHeader."Ship-to Post Code" := BC14PostedSalesInvHeader."Ship-to Post Code";
        BC14ArchSalesInvHeader."Ship-to Country/Region Code" := BC14PostedSalesInvHeader."Ship-to Country/Region Code";
        BC14ArchSalesInvHeader.Amount := BC14PostedSalesInvHeader.Amount;
        BC14ArchSalesInvHeader."Amount Including VAT" := BC14PostedSalesInvHeader."Amount Including VAT";
        BC14ArchSalesInvHeader."Order No." := BC14PostedSalesInvHeader."Order No.";
        BC14ArchSalesInvHeader."Pre-Assigned No." := BC14PostedSalesInvHeader."Pre-Assigned No.";
        BC14ArchSalesInvHeader."User ID" := BC14PostedSalesInvHeader."User ID";
        BC14ArchSalesInvHeader."Source Code" := BC14PostedSalesInvHeader."Source Code";
        BC14ArchSalesInvHeader."Remaining Amount" := BC14PostedSalesInvHeader."Remaining Amount";
        BC14ArchSalesInvHeader.Closed := BC14PostedSalesInvHeader.Closed;
        BC14ArchSalesInvHeader."Migrated On" := CurrentDateTime();

        // Allow extensions to map custom fields
        OnTransferSalesInvHeaderCustomFields(BC14PostedSalesInvHeader, BC14ArchSalesInvHeader);

        BC14ArchSalesInvHeader.Insert(false);

        // Migrate Lines to Archive
        MigrateInvoiceLines(BC14PostedSalesInvHeader."No.");
    end;

    local procedure MigrateInvoiceLines(DocumentNo: Code[20])
    var
        BC14PostedSalesInvLine: Record "BC14 Posted Sales Inv Line";
        BC14ArchSalesInvLine: Record "BC14 Arch. Sales Inv. Line";
    begin
        BC14PostedSalesInvLine.SetRange("Document No.", DocumentNo);
        if not BC14PostedSalesInvLine.FindSet() then
            exit;

        repeat
            // Manual field assignment to avoid field number mismatch
            BC14ArchSalesInvLine.Init();
            BC14ArchSalesInvLine."Document No." := BC14PostedSalesInvLine."Document No.";
            BC14ArchSalesInvLine."Line No." := BC14PostedSalesInvLine."Line No.";
            BC14ArchSalesInvLine.Type := BC14PostedSalesInvLine.Type;
            BC14ArchSalesInvLine."No." := BC14PostedSalesInvLine."No.";
            BC14ArchSalesInvLine.Description := BC14PostedSalesInvLine.Description;
            BC14ArchSalesInvLine."Description 2" := BC14PostedSalesInvLine."Description 2";
            BC14ArchSalesInvLine.Quantity := BC14PostedSalesInvLine.Quantity;
            BC14ArchSalesInvLine."Unit of Measure Code" := BC14PostedSalesInvLine."Unit of Measure Code";
            BC14ArchSalesInvLine."Qty. per Unit of Measure" := BC14PostedSalesInvLine."Qty. per Unit of Measure";
            BC14ArchSalesInvLine."Unit Price" := BC14PostedSalesInvLine."Unit Price";
            BC14ArchSalesInvLine."Line Discount %" := BC14PostedSalesInvLine."Line Discount %";
            BC14ArchSalesInvLine."Line Discount Amount" := BC14PostedSalesInvLine."Line Discount Amount";
            BC14ArchSalesInvLine.Amount := BC14PostedSalesInvLine.Amount;
            BC14ArchSalesInvLine."Amount Including VAT" := BC14PostedSalesInvLine."Amount Including VAT";
            BC14ArchSalesInvLine."Shortcut Dimension 1 Code" := BC14PostedSalesInvLine."Shortcut Dimension 1 Code";
            BC14ArchSalesInvLine."Shortcut Dimension 2 Code" := BC14PostedSalesInvLine."Shortcut Dimension 2 Code";
            BC14ArchSalesInvLine."VAT %" := BC14PostedSalesInvLine."VAT %";
            BC14ArchSalesInvLine."VAT Base Amount" := BC14PostedSalesInvLine."VAT Base Amount";
            BC14ArchSalesInvLine."Location Code" := BC14PostedSalesInvLine."Location Code";

            // Allow extensions to map custom fields
            OnTransferSalesInvLineCustomFields(BC14PostedSalesInvLine, BC14ArchSalesInvLine);

            BC14ArchSalesInvLine.Insert(false);
        until BC14PostedSalesInvLine.Next() = 0;
    end;

    /// <summary>
    /// Integration event raised during posted sales invoice header migration to allow mapping of custom fields.
    /// Subscribe to this event to transfer TableExtension fields from BC14 Posted Sales Inv Header to Archive.
    /// </summary>
    [IntegrationEvent(false, false)]
    local procedure OnTransferSalesInvHeaderCustomFields(BC14PostedSalesInvHeader: Record "BC14 Posted Sales Inv Header"; var BC14ArchSalesInvHeader: Record "BC14 Arch. Sales Inv. Header")
    begin
    end;

    /// <summary>
    /// Integration event raised during posted sales invoice line migration to allow mapping of custom fields.
    /// Subscribe to this event to transfer TableExtension fields from BC14 Posted Sales Inv Line to Archive.
    /// </summary>
    [IntegrationEvent(false, false)]
    local procedure OnTransferSalesInvLineCustomFields(BC14PostedSalesInvLine: Record "BC14 Posted Sales Inv Line"; var BC14ArchSalesInvLine: Record "BC14 Arch. Sales Inv. Line")
    begin
    end;
}
