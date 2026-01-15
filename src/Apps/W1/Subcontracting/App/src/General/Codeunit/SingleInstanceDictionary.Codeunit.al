// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

codeunit 99001500 "Single Instance Dictionary"
{
    SingleInstance = true;

    var
        CodeDictionary: Dictionary of [Text, Code[1024]];
        DateDictionary: Dictionary of [Text, Date];
        RecordIDDictionary: Dictionary of [Text, RecordId];

    procedure ClearAllDictionariesForKey(StoredKey: Text)
    begin

        if CodeDictionary.ContainsKey(StoredKey) then
            CodeDictionary.Remove(StoredKey);

        if DateDictionary.ContainsKey(StoredKey) then
            DateDictionary.Remove(StoredKey);

        if RecordIDDictionary.ContainsKey(StoredKey) then
            RecordIDDictionary.Remove(StoredKey);
    end;

    procedure SetCode(KeyToStore: Text; CodeToStore: Code[1024])
    begin
        if CodeDictionary.ContainsKey(KeyToStore) then
            CodeDictionary.Set(KeyToStore, CodeToStore)
        else
            CodeDictionary.Add(KeyToStore, CodeToStore);
    end;

    procedure SetDate(KeyToStore: Text; DateToStore: Date)
    begin
        if DateDictionary.ContainsKey(KeyToStore) then
            DateDictionary.Set(KeyToStore, DateToStore)
        else
            DateDictionary.Add(KeyToStore, DateToStore);
    end;

    procedure SetRecordID(KeyToStore: Text; RecordIDToStore: RecordId)
    begin
        if RecordIDDictionary.ContainsKey(KeyToStore) then
            RecordIDDictionary.Set(KeyToStore, RecordIDToStore)
        else
            RecordIDDictionary.Add(KeyToStore, RecordIDToStore);
    end;

    procedure GetCode(StoredKey: Text): Code[1024]
    begin
        if CodeDictionary.ContainsKey(StoredKey) then
            exit(CodeDictionary.Get(StoredKey));
    end;

    procedure GetDate(StoredKey: Text): Date
    begin
        if DateDictionary.ContainsKey(StoredKey) then
            exit(DateDictionary.Get(StoredKey));
    end;

    procedure GetRecordID(StoredKey: Text; var ReturnRecordID: RecordId)
    begin
        Clear(ReturnRecordID);
        if RecordIDDictionary.ContainsKey(StoredKey) then
            ReturnRecordID := RecordIDDictionary.Get(StoredKey);
    end;
}