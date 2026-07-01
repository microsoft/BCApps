// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Utilities;

using System;

codeunit 708 "Dictionary Wrapper"
{

    trigger OnRun()
    begin
    end;

    var
        Dictionary: DotNet GenericDictionary2;
        KeysArray: DotNet Array;
        DictionaryInitialized: Boolean;
        KeysArrayInitialized: Boolean;

    procedure TryGetValue("Key": Variant; var Value: Variant): Boolean
    var
        Found: Boolean;
    begin
        InitializeDictionary();
        SYSTEM.Clear(Value);

        if not Dictionary.ContainsKey(Key) then
            exit(false);

        Found := Dictionary.TryGetValue(Key, Value);
        exit(Found);
    end;

    procedure TryGetKey(Index: Integer; var "Key": Variant): Boolean
    var
        "Count": Integer;
    begin
        InitializeDictionary();
        InitializeKeysArray();
        SYSTEM.Clear(Key);

        Count := Dictionary.Count();
        if (Index >= Count) or (Index < 0) then
            exit(false);

        Key := KeysArray.GetValue(Index);

        exit(true);
    end;

    procedure TryGetKeyValue(Index: Integer; var "Key": Variant; var Value: Variant): Boolean
    begin
        if TryGetKey(Index, Key) then
            if TryGetValue(Key, Value) then
                exit(true);

        exit(false);
    end;

    procedure ContainsKey("Key": Variant): Boolean
    begin
        InitializeDictionary();

        exit(Dictionary.ContainsKey(Key));
    end;

    procedure "Count"(): Integer
    begin
        InitializeDictionary();

        exit(Dictionary.Count);
    end;

    procedure Set("Key": Variant; Value: Variant)
    begin
        InitializeDictionary();

        if not Dictionary.ContainsKey(Key) then begin
            KeysArrayInitialized := false;
            Dictionary.Add(Key, Value);
            exit;
        end;

        Dictionary.Remove(Key);
        Dictionary.Add(Key, Value);
    end;

    procedure Remove("Key": Variant)
    begin
        InitializeDictionary();

        if Dictionary.ContainsKey(Key) then begin
            KeysArrayInitialized := false;
            Dictionary.Remove(Key);
        end;
    end;

    procedure Clear()
    begin
        InitializeDictionary();

        KeysArrayInitialized := false;
        Dictionary.Clear();
    end;

    local procedure InitializeDictionary()
    begin
        if DictionaryInitialized then
            exit;

        Dictionary := Dictionary.Dictionary();
        DictionaryInitialized := true;
        KeysArrayInitialized := false;
    end;

    local procedure InitializeKeysArray()
    var
        KeyCollection: DotNet GenericDictionary2_KeyCollection;
        "Object": DotNet Object;
        "Count": Integer;
    begin
        if KeysArrayInitialized then
            exit;

        Count := Dictionary.Count();
        KeysArray := KeysArray.CreateInstance(GetDotNetType(Object), Count);
        KeyCollection := Dictionary.Keys;
        KeyCollection.CopyTo(KeysArray, 0);

        KeysArrayInitialized := true;
    end;
}

