namespace System.IO;


codeunit 1204 "Map Data Exch. To RapidStart"
{

    trigger OnRun()
    begin
    end;

    var
        TempDataExchRapidStartBuffer: Record "DataExch-RapidStart Buffer" temporary;
        TargetTableFieldDefinitionMustBeSpecifiedErr: Label 'You must specify a target table for the column definition.';

    procedure ProcessAllLinesColumnMapping(DataExch: Record "Data Exch."; TargetRapidstartPackageCode: Code[20])
    var
        DataExchLineDef: Record "Data Exch. Line Def";
    begin
        TempDataExchRapidStartBuffer.Reset();
        TempDataExchRapidStartBuffer.DeleteAll();

        DataExchLineDef.SetRange("Data Exch. Def Code", DataExch."Data Exch. Def Code");
        DataExchLineDef.SetRange("Parent Code", '');
        if DataExchLineDef.FindSet() then
            repeat
                ProcessColumnMapping(DataExch, DataExchLineDef, TargetRapidstartPackageCode);
            until DataExchLineDef.Next() = 0;
    end;

    local procedure ProcessColumnMapping(DataExch: Record "Data Exch."; DataExchLineDef: Record "Data Exch. Line Def"; TargetRapidstartPackageCode: Code[20])
    var
        DataExchField: Record "Data Exch. Field";
        NewConfigPackageRecord: Record "Config. Package Record";
        ChildDataExchLineDef: Record "Data Exch. Line Def";
        CurrentLineNo: Integer;
    begin
        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        DataExchField.SetRange("Data Exch. Line Def Code", DataExchLineDef.Code);

        if not DataExchField.FindSet() then
            exit;

        CurrentLineNo := -1;

        repeat
            InsertRecordDefinition(DataExchField, DataExchLineDef, NewConfigPackageRecord, CurrentLineNo, TargetRapidstartPackageCode);
            InsertDataValues(DataExchField, DataExchLineDef, TargetRapidstartPackageCode, NewConfigPackageRecord);
        until DataExchField.Next() = 0;

        // Process Child Line Definitions
        ChildDataExchLineDef.SetRange("Data Exch. Def Code", DataExchLineDef."Data Exch. Def Code");
        ChildDataExchLineDef.SetRange("Parent Code", DataExchLineDef.Code);

        if not ChildDataExchLineDef.FindSet() then
            exit;

        repeat
            ProcessColumnMapping(DataExch, ChildDataExchLineDef, TargetRapidstartPackageCode);
        until ChildDataExchLineDef.Next() = 0;
    end;

    local procedure InsertRecordDefinition(DataExchField: Record "Data Exch. Field"; DataExchLineDef: Record "Data Exch. Line Def"; var NewConfigPackageRecord: Record "Config. Package Record"; var CurrentLineNo: Integer; TargetRapidstartPackageCode: Code[20])
    var
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        PreviousConfigPackageRecord: Record "Config. Package Record";
    begin
        // Check if definition is already inserted
        if CurrentLineNo = DataExchField."Line No." then
            exit;

        // Find the table definition we need to write to.
        DataExchFieldMapping.SetRange("Data Exch. Def Code", DataExchLineDef."Data Exch. Def Code");
        DataExchFieldMapping.SetRange("Data Exch. Line Def Code", DataExchLineDef.Code);
        DataExchFieldMapping.SetRange("Table ID", DATABASE::"Config. Package Data");
        DataExchFieldMapping.SetFilter("Column No.", '>0');
        if not DataExchFieldMapping.FindFirst() then
            Error(TargetTableFieldDefinitionMustBeSpecifiedErr);

        CurrentLineNo := DataExchField."Line No.";

        // Initialize new record
        Clear(NewConfigPackageRecord);
        NewConfigPackageRecord.Init();
        NewConfigPackageRecord.Validate("Package Code", TargetRapidstartPackageCode);
        NewConfigPackageRecord.Validate("Table ID", DataExchFieldMapping."Target Table ID");

        // Get last used No.
        PreviousConfigPackageRecord.Init();
        PreviousConfigPackageRecord.SetRange("Table ID", DataExchFieldMapping."Target Table ID");
        PreviousConfigPackageRecord.SetRange("Package Code", TargetRapidstartPackageCode);
        if PreviousConfigPackageRecord.FindLast() then
            NewConfigPackageRecord.Validate("No.", PreviousConfigPackageRecord."No." + 1)
        else
            NewConfigPackageRecord.Validate("No.", 1);

        if DataExchField."Parent Node ID" <> '' then begin
            TempDataExchRapidStartBuffer.SetRange("Node ID", DataExchField."Parent Node ID");
            TempDataExchRapidStartBuffer.FindFirst();
            NewConfigPackageRecord.Validate("Parent Record No.", TempDataExchRapidStartBuffer."RapidStart No.");
        end;

        NewConfigPackageRecord.Insert();

        // Update buffer with new line
        TempDataExchRapidStartBuffer.Init();
        TempDataExchRapidStartBuffer."Node ID" := DataExchField."Node ID";
        TempDataExchRapidStartBuffer."RapidStart No." := NewConfigPackageRecord."No.";
        TempDataExchRapidStartBuffer.Insert();
    end;

    local procedure InsertDataValues(DataExchField: Record "Data Exch. Field"; DataExchLineDef: Record "Data Exch. Line Def"; TargetRapidstartPackageCode: Code[20]; ConfigPackageRecord: Record "Config. Package Record")
    var
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        ConfigPackageData: Record "Config. Package Data";
    begin
        if DataExchField."Column No." < 1 then
            exit;

        DataExchFieldMapping.Get(
          DataExchLineDef."Data Exch. Def Code", DataExchLineDef.Code, DATABASE::"Config. Package Data", DataExchField."Column No.");

        ConfigPackageData.Init();
        ConfigPackageData.Validate("Package Code", TargetRapidstartPackageCode);
        ConfigPackageData.Validate("Table ID", DataExchFieldMapping."Target Table ID");
        ConfigPackageData.Validate("No.", ConfigPackageRecord."No.");
        ConfigPackageData.Validate("Field ID", DataExchFieldMapping."Target Field ID");
        ConfigPackageData.Validate(Value, DataExchField.Value);
        ConfigPackageData.Insert(true);
    end;
}

