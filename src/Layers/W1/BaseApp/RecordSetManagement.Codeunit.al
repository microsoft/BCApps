// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.IO;

using System.Reflection;

codeunit 8400 "Record Set Management"
{
    Permissions = TableData "Record Set Definition" = rimd,
                  TableData "Record Set Tree" = rimd;

    trigger OnRun()
    begin
    end;

    procedure SaveSetSingleTable(RecordsVariant: Variant): Integer
    var
        TempRecordSetBuffer: Record "Record Set Buffer" temporary;
        DataTypeManagement: Codeunit "Data Type Management";
        SetRecordRef: RecordRef;
        CurrentKey: Integer;
    begin
        DataTypeManagement.GetRecordRef(RecordsVariant, SetRecordRef);
        if SetRecordRef.IsEmpty() then
            exit;

        SortAscending(SetRecordRef);
        SetRecordRef.FindSet();

        CurrentKey := 0;
        repeat
            Clear(TempRecordSetBuffer);
            TempRecordSetBuffer."Value RecordID" := SetRecordRef.RecordId;
            TempRecordSetBuffer.No := CurrentKey;
            CurrentKey += 1;
            TempRecordSetBuffer.Insert();
        until SetRecordRef.Next() = 0;

        TempRecordSetBuffer.FindFirst();
        exit(SaveSet(TempRecordSetBuffer));
    end;

    procedure SaveSet(var TempRecordSetBuffer: Record "Record Set Buffer" temporary) SetID: Integer
    var
        RecordSetTree: Record "Record Set Tree";
        TempFoundRecordSetTree: Record "Record Set Tree" temporary;
        TempCurrentRecordSetBuffer: Record "Record Set Buffer" temporary;
        SavedRecordRef: RecordRef;
        ParentNodeID: Integer;
        NewSetNeeded: Boolean;
    begin
        if TempRecordSetBuffer.IsEmpty() then
            exit;

        TempCurrentRecordSetBuffer.Copy(TempRecordSetBuffer);
        TempRecordSetBuffer.SetCurrentKey("Value RecordID");
        TempRecordSetBuffer.Ascending(true);
        TempRecordSetBuffer.FindSet();

        SetID := 0;
        ParentNodeID := 0;

        repeat
            SavedRecordRef.Get(TempRecordSetBuffer."Value RecordID");

            if not FindNode(RecordSetTree, SavedRecordRef, ParentNodeID) then begin
                Clear(RecordSetTree);
                InsertNewNode(RecordSetTree, SavedRecordRef, ParentNodeID);
                NewSetNeeded := true;
            end;

            ParentNodeID := RecordSetTree."Node ID";
            TempFoundRecordSetTree := RecordSetTree;
            TempFoundRecordSetTree.Insert();
        until TempRecordSetBuffer.Next() = 0;

        if not NewSetNeeded then begin
            // Set might be a subset of existing set, we need to create a new one
            SetID := FindExistingSet(TempFoundRecordSetTree);
            NewSetNeeded := SetID = 0;
        end;

        if NewSetNeeded then
            SetID := CreateNewSet(TempFoundRecordSetTree);

        TempRecordSetBuffer.Copy(TempCurrentRecordSetBuffer);
    end;

    procedure GetSet(var TempRecordSetBuffer: Record "Record Set Buffer" temporary; SetID: Integer)
    var
        TempUnsortedRecordSetBuffer: Record "Record Set Buffer" temporary;
        RecordSetDefinition: Record "Record Set Definition";
        RecRef: RecordRef;
        CurrentKey: Integer;
    begin
        RecordSetDefinition.SetRange("Set ID", SetID);
        RecordSetDefinition.SetAutoCalcFields(Value);

        if not RecordSetDefinition.FindSet() then
            exit;

        repeat
            if RecRef.Get(RecordSetDefinition.Value) then begin
                CurrentKey := TempUnsortedRecordSetBuffer.No;
                Clear(TempUnsortedRecordSetBuffer);
                TempUnsortedRecordSetBuffer."Value RecordID" := RecRef.RecordId;
                TempUnsortedRecordSetBuffer.No := CurrentKey + 1;
                TempUnsortedRecordSetBuffer.Insert();
            end;
        until RecordSetDefinition.Next() = 0;

        TempUnsortedRecordSetBuffer.SetCurrentKey("Value RecordID");
        TempUnsortedRecordSetBuffer.Ascending(true);
        if not TempUnsortedRecordSetBuffer.FindSet() then
            exit;

        repeat
            CurrentKey := TempRecordSetBuffer.No;
            Clear(TempRecordSetBuffer);
            TempRecordSetBuffer.No := CurrentKey + 1;
            TempRecordSetBuffer."Value RecordID" := TempUnsortedRecordSetBuffer."Value RecordID";
            TempRecordSetBuffer.Insert();
        until TempUnsortedRecordSetBuffer.Next() = 0;
    end;

    procedure RenameRecord(RecRef: RecordRef; xRecRef: RecordRef)
    var
        RecordSetTree: Record "Record Set Tree";
    begin
        RecordSetTree.SetRange("Table No.", RecRef.Number);
        if RecordSetTree.IsEmpty() then
            exit;

        RecordSetTree.SetRange(Value, xRecRef.RecordId);
        RecordSetTree.ModifyAll(Value, RecRef.RecordId);
    end;

    local procedure SortAscending(var SetRecordRef: RecordRef)
    var
        TypeHelper: Codeunit "Type Helper";
        KeyString: Text;
    begin
        KeyString := TypeHelper.GetKeyAsString(SetRecordRef, 1);
        TypeHelper.SortRecordRef(SetRecordRef, KeyString, true);
    end;

    local procedure FindNode(var RecordSetTree: Record "Record Set Tree"; ValueRecordRef: RecordRef; ParentNodeID: Integer): Boolean
    begin
        RecordSetTree.SetRange("Table No.", ValueRecordRef.Number);
        RecordSetTree.SetRange("Parent Node ID", ParentNodeID);
        RecordSetTree.SetRange(Value, ValueRecordRef.RecordId);
        exit(RecordSetTree.FindFirst());
    end;

    local procedure InsertNewNode(var RecordSetTree: Record "Record Set Tree"; ValueRecordRef: RecordRef; ParentNodeID: Integer)
    begin
        RecordSetTree.Init();
        RecordSetTree."Table No." := ValueRecordRef.Number;
        RecordSetTree."Parent Node ID" := ParentNodeID;
        RecordSetTree.Value := ValueRecordRef.RecordId;
        RecordSetTree.Insert(true);
    end;

    local procedure CreateNewSet(var TempFoundRecordSetTree: Record "Record Set Tree" temporary): Integer
    var
        RecordSetDefinition: Record "Record Set Definition";
        SetID: Integer;
    begin
        TempFoundRecordSetTree.FindFirst();
        SetID := 0;
        repeat
            CreateSetDefinitionLine(RecordSetDefinition, SetID, TempFoundRecordSetTree);
            SetID := RecordSetDefinition."Set ID";
        until TempFoundRecordSetTree.Next() = 0;

        exit(RecordSetDefinition."Set ID");
    end;

    local procedure CreateSetDefinitionLine(var RecordSetDefinition: Record "Record Set Definition"; SetID: Integer; var TempFoundRecordSetTree: Record "Record Set Tree" temporary)
    begin
        Clear(RecordSetDefinition);
        RecordSetDefinition."Table No." := TempFoundRecordSetTree."Table No.";
        RecordSetDefinition."Set ID" := SetID;
        RecordSetDefinition."Node ID" := TempFoundRecordSetTree."Node ID";
        RecordSetDefinition.Insert(true);
    end;

    local procedure FindExistingSet(var TempFoundRecordSetTree: Record "Record Set Tree" temporary): Integer
    var
        RecordSetDefinition: Record "Record Set Definition";
        CurrentRecordSetDefinition: Record "Record Set Definition";
    begin
        FindSetsContainingValue(RecordSetDefinition, TempFoundRecordSetTree);

        repeat
            CurrentRecordSetDefinition := RecordSetDefinition;
            CurrentRecordSetDefinition.SetRange("Node ID");
            CurrentRecordSetDefinition.SetRange("Set ID", RecordSetDefinition."Set ID");
            if CurrentRecordSetDefinition.Find('+') then
                if (CurrentRecordSetDefinition.Next() = 0) and (CurrentRecordSetDefinition.Count = TempFoundRecordSetTree.Count) then
                    exit(CurrentRecordSetDefinition."Set ID");
        until RecordSetDefinition.Next() = 0;

        exit;
    end;

    local procedure FindSetsContainingValue(var RecordSetDefinition: Record "Record Set Definition"; var TempFoundRecordSetTree: Record "Record Set Tree" temporary)
    begin
        RecordSetDefinition.SetRange("Table No.", TempFoundRecordSetTree."Table No.");

        // Node ID Is unique for a given path, all sets containing a node ID will be part of the subpath
        RecordSetDefinition.SetRange("Node ID", TempFoundRecordSetTree."Node ID");
        RecordSetDefinition.FindSet();
    end;
}

