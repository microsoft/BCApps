// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;
using Microsoft.Foundation.Navigate;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using System.Reflection;

/// <summary>
/// Copies the French payment data from the base application into the Payment Management FR app.
/// This is the single implementation shared by the data update that is started from Feature Management
/// (codeunit "Feature - PaymentMgt FR") and by the forced upgrade to version 31 (codeunit
/// "Upgrade Payment Management FR"), so that both scenarios migrate exactly the same data.
/// The legacy base application objects are referenced by ID because they are obsolete and are removed
/// in version 31.
/// </summary>
codeunit 10844 "Payment Data Migration FR"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    /// <summary>
    /// Copies all French payment data of the current company from the base application tables and fields
    /// into the tables and fields of the Payment Management FR app.
    /// </summary>
    internal procedure MigratePaymentData()
    var
        LegacyTableIds: List of [Integer];
        AppTableIds: List of [Integer];
        TableIndex: Integer;
    begin
        GetTableMapping(LegacyTableIds, AppTableIds);
        for TableIndex := 1 to LegacyTableIds.Count() do
            TransferRecords(LegacyTableIds.Get(TableIndex), AppTableIds.Get(TableIndex));

        TransferBankAccountFields(Database::"Bank Account");
        TransferBankAccountFields(Database::"Customer Bank Account");
        TransferBankAccountFields(Database::"Vendor Bank Account");
    end;

    /// <summary>
    /// Points the payment steps at the report and XMLport objects of the Payment Management FR app.
    /// The migrated payment steps still refer to the object IDs of the base application objects, which
    /// were re-created in the app under new IDs. Object IDs that are not mapped, and the value 0, are
    /// left untouched. The mapping is idempotent, so the remapping can safely be repeated.
    /// </summary>
    internal procedure RemapPaymentStepObjectIDs()
    var
        PaymentStepFR: Record "Payment Step FR";
        ReportMap: Dictionary of [Integer, Integer];
        XmlPortMap: Dictionary of [Integer, Integer];
        LegacyReportNo: Integer;
        LegacyExportNo: Integer;
    begin
        BuildPaymentStepObjectIDMaps(ReportMap, XmlPortMap);

        if PaymentStepFR.FindSet(true) then
            repeat
                LegacyReportNo := PaymentStepFR."Report No.";
                LegacyExportNo := PaymentStepFR."Export No.";

                case PaymentStepFR."Action Type" of
                    PaymentStepFR."Action Type"::Report:
                        if ReportMap.ContainsKey(LegacyReportNo) then
                            PaymentStepFR."Report No." := ReportMap.Get(LegacyReportNo);
                    PaymentStepFR."Action Type"::File:
                        case PaymentStepFR."Export Type" of
                            PaymentStepFR."Export Type"::Report:
                                if ReportMap.ContainsKey(LegacyExportNo) then
                                    PaymentStepFR."Export No." := ReportMap.Get(LegacyExportNo);
                            PaymentStepFR."Export Type"::XMLport:
                                if XmlPortMap.ContainsKey(LegacyExportNo) then
                                    PaymentStepFR."Export No." := XmlPortMap.Get(LegacyExportNo);
                        end;
                end;

                OnAfterRemapPaymentStepObjectIDs(PaymentStepFR, LegacyReportNo, LegacyExportNo);

                PaymentStepFR.Modify();
            until PaymentStepFR.Next() = 0;
    end;

    /// <summary>
    /// Counts the records that the data update will migrate, so that they can be reviewed before the
    /// update is started. The counted tables are the tables that <see cref="MigratePaymentData"/> migrates.
    /// </summary>
    /// <param name="TempDocumentEntry">The buffer that receives one entry per non-empty table.</param>
    internal procedure CountRecordsToMigrate(var TempDocumentEntry: Record "Document Entry" temporary)
    var
        LegacyTableIds: List of [Integer];
        AppTableIds: List of [Integer];
        LegacyTableId: Integer;
    begin
        TempDocumentEntry.Reset();
        TempDocumentEntry.DeleteAll();

        GetTableMapping(LegacyTableIds, AppTableIds);
        foreach LegacyTableId in LegacyTableIds do
            InsertDocumentEntry(TempDocumentEntry, LegacyTableId);

        InsertDocumentEntry(TempDocumentEntry, Database::"Bank Account");
        InsertDocumentEntry(TempDocumentEntry, Database::"Customer Bank Account");
        InsertDocumentEntry(TempDocumentEntry, Database::"Vendor Bank Account");
    end;

    local procedure GetTableMapping(var LegacyTableIds: List of [Integer]; var AppTableIds: List of [Integer])
    begin
        AddTableMapping(LegacyTableIds, AppTableIds, 10869, Database::"Bank Account Buffer FR"); // 10869 - "Bank Account Buffer"
        AddTableMapping(LegacyTableIds, AppTableIds, 10860, Database::"Payment Class FR"); // 10860 - "Payment Class"
        AddTableMapping(LegacyTableIds, AppTableIds, 10865, Database::"Payment Header FR"); // 10865 - "Payment Header"
        AddTableMapping(LegacyTableIds, AppTableIds, 10867, Database::"Payment Header Archive FR"); // 10867 - "Payment Header Archive"
        AddTableMapping(LegacyTableIds, AppTableIds, 10866, Database::"Payment Line FR"); // 10866 - "Payment Line"
        AddTableMapping(LegacyTableIds, AppTableIds, 10868, Database::"Payment Line Archive FR"); // 10868 - "Payment Line Archive"
        AddTableMapping(LegacyTableIds, AppTableIds, 10864, Database::"Payment Post. Buffer FR"); // 10864 - "Payment Post. Buffer"
        AddTableMapping(LegacyTableIds, AppTableIds, 10861, Database::"Payment Status FR"); // 10861 - "Payment Status"
        AddTableMapping(LegacyTableIds, AppTableIds, 10862, Database::"Payment Step FR"); // 10862 - "Payment Step"
        AddTableMapping(LegacyTableIds, AppTableIds, 10863, Database::"Payment Step Ledger FR"); // 10863 - "Payment Step Ledger"
        AddTableMapping(LegacyTableIds, AppTableIds, 10870, Database::"Payment Address FR"); // 10870 - "Payment Address"
    end;

    local procedure AddTableMapping(var LegacyTableIds: List of [Integer]; var AppTableIds: List of [Integer]; LegacyTableId: Integer; AppTableId: Integer)
    begin
        LegacyTableIds.Add(LegacyTableId);
        AppTableIds.Add(AppTableId);
    end;

    local procedure InsertDocumentEntry(var TempDocumentEntry: Record "Document Entry" temporary; TableId: Integer)
    var
        RecRef: RecordRef;
        RecordCount: Integer;
        TableName: Text;
    begin
        RecRef.Open(TableId, false);
        RecordCount := RecRef.Count();
        TableName := RecRef.Caption();
        RecRef.Close();

        if RecordCount = 0 then
            exit;

        TempDocumentEntry.Init();
        TempDocumentEntry."Entry No." := TempDocumentEntry.Count() + 1;
        TempDocumentEntry."Table ID" := TableId;
        TempDocumentEntry."Table Name" := CopyStr(TableName, 1, MaxStrLen(TempDocumentEntry."Table Name"));
        TempDocumentEntry."No. of Records" := RecordCount;
        TempDocumentEntry.Insert();
    end;

    local procedure TransferRecords(SourceTableId: Integer; TargetTableId: Integer)
    var
        SourceRecRef: RecordRef;
        TargetRecRef: RecordRef;
        ExistingRecRef: RecordRef;
        SourceFieldRef: FieldRef;
        TargetFieldRef: FieldRef;
        TransferableFieldNos: List of [Integer];
        FieldNo: Integer;
    begin
        SourceRecRef.Open(SourceTableId, false);
        TargetRecRef.Open(TargetTableId, false);
        ExistingRecRef.Open(TargetTableId, false);

        GetTransferableFieldNos(SourceTableId, TargetRecRef, TransferableFieldNos);

        if SourceRecRef.FindSet() then
            repeat
                TargetRecRef.Init();
                foreach FieldNo in TransferableFieldNos do begin
                    SourceFieldRef := SourceRecRef.Field(FieldNo);
                    TargetFieldRef := TargetRecRef.Field(FieldNo);
                    TargetFieldRef.Value := SourceFieldRef.Value;
                end;

                // Records that were already migrated, for example by a previous run that failed halfway, are kept.
                if not TargetRecordExists(TargetRecRef, ExistingRecRef) then
                    TargetRecRef.Insert();
            until SourceRecRef.Next() = 0;

        SourceRecRef.Close();
        TargetRecRef.Close();
        ExistingRecRef.Close();
    end;

    local procedure GetTransferableFieldNos(SourceTableId: Integer; var TargetRecRef: RecordRef; var TransferableFieldNos: List of [Integer])
    var
        SourceField: Record Field;
    begin
        SourceField.SetRange(TableNo, SourceTableId);
        SourceField.SetRange(Class, SourceField.Class::Normal);
        SourceField.SetRange(Enabled, true);

        if SourceField.FindSet() then
            repeat
                // The app tables do not necessarily have every field of the base application table.
                if TargetRecRef.FieldExist(SourceField."No.") then
                    TransferableFieldNos.Add(SourceField."No.");
            until SourceField.Next() = 0;
    end;

    local procedure TargetRecordExists(var TargetRecRef: RecordRef; var ExistingRecRef: RecordRef): Boolean
    var
        PrimaryKeyFieldRef: FieldRef;
        ExistingFieldRef: FieldRef;
        PrimaryKeyRef: KeyRef;
        FieldIndex: Integer;
    begin
        ExistingRecRef.Reset();
        PrimaryKeyRef := TargetRecRef.KeyIndex(1);
        for FieldIndex := 1 to PrimaryKeyRef.FieldCount() do begin
            PrimaryKeyFieldRef := PrimaryKeyRef.FieldIndex(FieldIndex);
            ExistingFieldRef := ExistingRecRef.Field(PrimaryKeyFieldRef.Number());
            ExistingFieldRef.SetRange(PrimaryKeyFieldRef.Value());
        end;
        exit(not ExistingRecRef.IsEmpty());
    end;

    local procedure TransferBankAccountFields(TableId: Integer)
    var
        RecRef: RecordRef;
    begin
        // The bank account tables carry the French fields both in the base application ("Agency Code" 10851,
        // "RIB Key" 10852 and "RIB Checked" 10853) and in the table extensions of this app ("Agency Code FR"
        // 10805, "RIB Key FR" 10806 and "RIB Checked FR" 10807). The field numbers are the same on
        // "Bank Account", "Customer Bank Account" and "Vendor Bank Account".
        RecRef.Open(TableId, false);
        if RecRef.FindSet(true) then
            repeat
                CopyFieldValue(RecRef, 10851, 10805);
                CopyFieldValue(RecRef, 10852, 10806);
                CopyFieldValue(RecRef, 10853, 10807);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure CopyFieldValue(var RecRef: RecordRef; SourceFieldNo: Integer; TargetFieldNo: Integer)
    var
        SourceFieldRef: FieldRef;
        TargetFieldRef: FieldRef;
    begin
        SourceFieldRef := RecRef.Field(SourceFieldNo);
        TargetFieldRef := RecRef.Field(TargetFieldNo);
        TargetFieldRef.Value := SourceFieldRef.Value;
    end;

    local procedure BuildPaymentStepObjectIDMaps(var ReportMap: Dictionary of [Integer, Integer]; var XmlPortMap: Dictionary of [Integer, Integer])
    begin
        ReportMap.Set(10843, 10846); // Recapitulation Form
        ReportMap.Set(10860, 10845); // Payment List
        ReportMap.Set(10862, 10850); // Suggest Vendor Payments FR
        ReportMap.Set(10864, 10849); // Suggest Customer Payments
        ReportMap.Set(10865, 10834); // Bill
        ReportMap.Set(10866, 10836); // Draft
        ReportMap.Set(10867, 10847); // Remittance
        ReportMap.Set(10868, 10837); // Draft notice
        ReportMap.Set(10869, 10838); // Draft recapitulation
        ReportMap.Set(10870, 10852); // Withdraw notice
        ReportMap.Set(10871, 10853); // Withdraw recapitulation
        ReportMap.Set(10872, 10839); // Duplicate parameter
        ReportMap.Set(10873, 10831); // Archive Payment Slips
        ReportMap.Set(10880, 10840); // ETEBAC Files
        ReportMap.Set(10881, 10851); // Withdraw
        ReportMap.Set(10883, 10848); // SEPA ISO20022

        XmlPortMap.Set(10863, 10831); // Import/Export Parameters
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRemapPaymentStepObjectIDs(var PaymentStepFR: Record "Payment Step FR"; LegacyReportNo: Integer; LegacyExportNo: Integer)
    begin
    end;
}
