namespace System.IO;

using Microsoft.Utilities;

codeunit 1214 "Map DataExch To Intermediate"
{
    TableNo = "Data Exch.";

    trigger OnRun()
    begin
        ProcessAllLinesColumnMapping(Rec);
    end;

    var
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
        TargetTableFieldDefinitionMustBeSpecifiedErr: Label 'You must specify a target table for the column definition.';

    [Scope('OnPrem')]
    procedure ProcessAllLinesColumnMapping(DataExch: Record "Data Exch.")
    var
        DataExchLineDef: Record "Data Exch. Line Def";
    begin
        // TempNameValueBuffer - used to "keep track" of node id - record No. relation for determining parent/child relation
        TempNameValueBuffer.Reset();
        TempNameValueBuffer.DeleteAll();

        DataExchLineDef.SetRange("Data Exch. Def Code", DataExch."Data Exch. Def Code");
        DataExchLineDef.SetRange("Parent Code", '');
        if DataExchLineDef.FindSet() then
            repeat
                ProcessColumnMapping(DataExch, DataExchLineDef);
            until DataExchLineDef.Next() = 0;
    end;

    local procedure ProcessColumnMapping(DataExch: Record "Data Exch."; DataExchLineDef: Record "Data Exch. Line Def")
    var
        DataExchField: Record "Data Exch. Field";
        ChildDataExchLineDef: Record "Data Exch. Line Def";
        CurrentLineNo: Integer;
    begin
        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        DataExchField.SetRange("Data Exch. Line Def Code", DataExchLineDef.Code);

        if not DataExchField.FindSet() then
            exit;

        CurrentLineNo := -1;

        repeat
            InsertRecordDefinition(DataExchField, DataExchLineDef, CurrentLineNo);
            InsertDataValues(DataExchField, DataExchLineDef, CurrentLineNo);
        until DataExchField.Next() = 0;

        // Process Child Line Definitions
        ChildDataExchLineDef.SetRange("Data Exch. Def Code", DataExchLineDef."Data Exch. Def Code");
        ChildDataExchLineDef.SetRange("Parent Code", DataExchLineDef.Code);

        if not ChildDataExchLineDef.FindSet() then
            exit;

        repeat
            ProcessColumnMapping(DataExch, ChildDataExchLineDef);
        until ChildDataExchLineDef.Next() = 0;
    end;

    local procedure InsertRecordDefinition(DataExchField: Record "Data Exch. Field"; DataExchLineDef: Record "Data Exch. Line Def"; var CurrentLineNo: Integer)
    var
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
    begin
        // Check if definition is already inserted
        if CurrentLineNo = DataExchField."Line No." then
            exit;

        // Find the table definition we need to write to.
        DataExchFieldMapping.SetRange("Data Exch. Def Code", DataExchLineDef."Data Exch. Def Code");
        DataExchFieldMapping.SetRange("Data Exch. Line Def Code", DataExchLineDef.Code);
        DataExchFieldMapping.SetRange("Table ID", DATABASE::"Intermediate Data Import");
        DataExchFieldMapping.SetFilter("Column No.", '>0');
        if DataExchFieldMapping.IsEmpty() then
            Error(TargetTableFieldDefinitionMustBeSpecifiedErr);

        CurrentLineNo := DataExchField."Line No.";

        // Save Node ID / Line No relation
        AddNodeIDLineNoPair(DataExchField."Node ID", CurrentLineNo);
    end;

    local procedure InsertDataValues(DataExchField: Record "Data Exch. Field"; DataExchLineDef: Record "Data Exch. Line Def"; LineNo: Integer)
    var
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        IntermediateDataImport: Record "Intermediate Data Import";
        TransformationRule: Record "Transformation Rule";
        ParentLineNo: Integer;
    begin
        if DataExchField."Column No." < 1 then
            exit;

        // Skip if no mapping
        if not DataExchFieldMapping.Get(
             DataExchLineDef."Data Exch. Def Code", DataExchLineDef.Code,
             DATABASE::"Intermediate Data Import", DataExchField."Column No.")
        then
            exit;

        IntermediateDataImport.Init();
        IntermediateDataImport.Validate("Data Exch. No.", DataExchField."Data Exch. No.");
        IntermediateDataImport.Validate("Table ID", DataExchFieldMapping."Target Table ID");
        IntermediateDataImport.Validate("Record No.", LineNo);
        IntermediateDataImport.Validate("Field ID", DataExchFieldMapping."Target Field ID");
        if TransformationRule.Get(DataExchFieldMapping."Transformation Rule") then
            IntermediateDataImport.SetValueWithoutModifying(TransformationRule.TransformText(DataExchField.GetValue()))
        else
            IntermediateDataImport.SetValueWithoutModifying(DataExchField.GetValue());
        IntermediateDataImport.Validate("Validate Only", DataExchFieldMapping.Optional);
        if DataExchField."Parent Node ID" <> '' then begin
            TempNameValueBuffer.SetRange(Name, DataExchField."Parent Node ID");
            TempNameValueBuffer.FindFirst();
            Evaluate(ParentLineNo, TempNameValueBuffer.Value);
            IntermediateDataImport.Validate("Parent Record No.", ParentLineNo);
        end;

        OnBeforeIntermediateDataImportInsert(DataExchField, DataExchLineDef, TempNameValueBuffer, IntermediateDataImport);
        IntermediateDataImport.Insert(true);
    end;

    local procedure AddNodeIDLineNoPair(NodeID: Text[250]; LineNo: Integer)
    var
        ID: Integer;
    begin
        TempNameValueBuffer.Reset();
        ID := 1;
        if TempNameValueBuffer.FindLast() then
            ID := TempNameValueBuffer.ID + 1;

        Clear(TempNameValueBuffer);
        TempNameValueBuffer.ID := ID;
        TempNameValueBuffer.Name := NodeID;
        TempNameValueBuffer.Value := Format(LineNo);
        TempNameValueBuffer.Insert(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIntermediateDataImportInsert(DataExchField: Record "Data Exch. Field"; DataExchLineDef: Record "Data Exch. Line Def"; var TempNameValueBuffer: Record "Name/Value Buffer" temporary; var IntermediateDataImport: Record "Intermediate Data Import")
    begin
    end;
}

