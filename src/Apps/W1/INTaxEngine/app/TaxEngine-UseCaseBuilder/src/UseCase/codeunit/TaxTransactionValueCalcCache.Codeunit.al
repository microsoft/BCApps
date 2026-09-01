// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.TaxEngine.UseCaseBuilder;

using Microsoft.Finance.TaxEngine.TaxTypeHandler;

codeunit 20398 "Tax Trans. Value Calc. Cache"
{
    SingleInstance = true;

    procedure BeginRecalculation(TaxRecordID: RecordId; TaxType: Code[20])
    var
        ScopeKey: Text;
        Version: Integer;
    begin
        ScopeKey := GetScopeKey(TaxRecordID, TaxType);
        if ScopeVersions.Get(ScopeKey, Version) then begin
            ScopeVersions.Remove(ScopeKey);
            Version += 1;
        end else
            Version := 1;

        ScopeVersions.Add(ScopeKey, Version);
        SetActiveScope(ScopeKey, true);
    end;

    procedure EndRecalculation(TaxRecordID: RecordId; TaxType: Code[20])
    var
        ScopeKey: Text;
    begin
        ScopeKey := GetScopeKey(TaxRecordID, TaxType);
        SetActiveScope(ScopeKey, false);
    end;

    procedure IsRecalculationActive(TaxRecordID: RecordId; TaxType: Code[20]): Boolean
    var
        IsActive: Boolean;
        ScopeKey: Text;
    begin
        ScopeKey := GetScopeKey(TaxRecordID, TaxType);
        if ActiveScopes.Get(ScopeKey, IsActive) then
            exit(IsActive);
    end;

    procedure GetTransactionValueID(TaxRecordID: RecordId; TaxType: Code[20]; TransactionValueType: Enum "Transaction Value Type"; ValueID: Integer; var TransactionValueID: Integer): Boolean
    var
        CacheKey: Text;
    begin
        if not IsRecalculationActive(TaxRecordID, TaxType) then
            exit(false);

        CacheKey := GetTransactionValueKey(TaxRecordID, TaxType, TransactionValueType, ValueID);
        exit(TransactionValueIDs.Get(CacheKey, TransactionValueID));
    end;

    procedure SetTransactionValueID(TaxRecordID: RecordId; TaxType: Code[20]; TransactionValueType: Enum "Transaction Value Type"; ValueID: Integer; TransactionValueID: Integer)
    var
        CacheKey: Text;
    begin
        if not IsRecalculationActive(TaxRecordID, TaxType) then
            exit;

        CacheKey := GetTransactionValueKey(TaxRecordID, TaxType, TransactionValueType, ValueID);
        if TransactionValueIDs.ContainsKey(CacheKey) then
            TransactionValueIDs.Remove(CacheKey);

        TransactionValueIDs.Add(CacheKey, TransactionValueID);
    end;

    local procedure SetActiveScope(ScopeKey: Text; IsActive: Boolean)
    begin
        if ActiveScopes.ContainsKey(ScopeKey) then
            ActiveScopes.Remove(ScopeKey);

        ActiveScopes.Add(ScopeKey, IsActive);
    end;

    local procedure GetScopeKey(TaxRecordID: RecordId; TaxType: Code[20]): Text
    begin
        exit(StrSubstNo('%1|%2', Format(TaxRecordID, 0, 1), TaxType));
    end;

    local procedure GetTransactionValueKey(TaxRecordID: RecordId; TaxType: Code[20]; TransactionValueType: Enum "Transaction Value Type"; ValueID: Integer): Text
    var
        ScopeKey: Text;
        Version: Integer;
    begin
        ScopeKey := GetScopeKey(TaxRecordID, TaxType);
        ScopeVersions.Get(ScopeKey, Version);
        exit(StrSubstNo('%1|%2|%3|%4', ScopeKey, Version, TransactionValueType.AsInteger(), ValueID));
    end;

    var
        ActiveScopes: Dictionary of [Text, Boolean];
        ScopeVersions: Dictionary of [Text, Integer];
        TransactionValueIDs: Dictionary of [Text, Integer];
}