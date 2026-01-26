// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.DirectDebit;

using System.IO;

codeunit 11408 "Imp. Bank Trans. Data Updates"
{
    Permissions = TableData "Data Exch. Field" = rimd;

    trigger OnRun()
    begin
    end;

    [Scope('OnPrem')]
    procedure FindColumnNoOfPath(DataExchDefCode: Code[20]; DataExchLineDefCode: Code[20]; Path: Text) ColumnNumber: Integer
    var
        DataExchFindColumnNo: Query "Data Exch. Find Column No.";
    begin
        DataExchFindColumnNo.SetRange(Data_Exch_Def_Code, DataExchDefCode);
        DataExchFindColumnNo.SetRange(Data_Exch_Line_Def_Code, DataExchLineDefCode);
        DataExchFindColumnNo.SetRange(Path, Path);
        DataExchFindColumnNo.Open();
        if DataExchFindColumnNo.Read() then
            ColumnNumber := DataExchFindColumnNo.Column_No;
        DataExchFindColumnNo.Close();
    end;

    [Scope('OnPrem')]
    procedure InheritDataFromParentToChildNodes(DataExchEntryNo: Integer)
    var
        DataExch: Record "Data Exch.";
        ParentDataExchField: Record "Data Exch. Field";
        ChildDataExchField: Record "Data Exch. Field";
        TempChildDataExchField: Record "Data Exch. Field" temporary;
        ParentLookupDataExchField: Record "Data Exch. Field";
        ParentDataExchColumnDef: Record "Data Exch. Column Def";
        ChildDataExchColumnDef: Record "Data Exch. Column Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        CurrentLineNo: Integer;
    begin
        DataExch.Get(DataExchEntryNo);

        // Find parent nodes
        ParentDataExchField.SetRange("Data Exch. No.", DataExchEntryNo);
        ParentDataExchField.SetRange("Data Exch. Line Def Code", DataExch."Data Exch. Line Def Code");
        // Need to sort unique on ParentDataExchField. To guarantee uniqueness, filter by a mandatory column no.
        DataExchLineDef.SetRange("Data Exch. Def Code", DataExch."Data Exch. Def Code");
        DataExchLineDef.FindFirst();
        ParentDataExchField.SetRange(
          "Column No.",
          FindColumnNoOfPath(DataExchLineDef."Data Exch. Def Code", DataExchLineDef.Code, '/Document/BkToCstmrStmt/Stmt/Ntry/Amt'));

        if not ParentDataExchField.FindSet() then
            exit;

        // General filters
        ParentLookupDataExchField.SetRange("Data Exch. No.", DataExchEntryNo);
        ParentDataExchColumnDef.SetRange("Data Exch. Def Code", DataExch."Data Exch. Def Code");
        ParentDataExchColumnDef.SetRange("Data Exch. Line Def Code", DataExch."Data Exch. Line Def Code");

        ChildDataExchField.SetRange("Data Exch. No.", DataExchEntryNo);
        ChildDataExchField.SetFilter("Data Exch. Line Def Code", '<>%1', DataExch."Data Exch. Line Def Code");

        // Copy columns from parent to child nodes

        // For each parent
        repeat
            ParentLookupDataExchField.SetRange("Line No.", ParentDataExchField."Line No.");

            ChildDataExchField.SetFilter("Node ID", CopyStr(ParentDataExchField."Node ID", 1, 12) + '*');
            CurrentLineNo := -1;
            if ChildDataExchField.FindSet() then begin
                // Find all children
                repeat
                    if CurrentLineNo <> ChildDataExchField."Line No." then begin
                        CurrentLineNo := ChildDataExchField."Line No.";
                        TempChildDataExchField.Copy(ChildDataExchField);
                        TempChildDataExchField.Insert();
                    end;
                until ChildDataExchField.Next() = 0;
                TempChildDataExchField.FindSet();

                // For each child of current parent
                repeat
                    // Find all column definitions of the child
                    ChildDataExchColumnDef.SetRange("Data Exch. Def Code", DataExch."Data Exch. Def Code");
                    ChildDataExchColumnDef.SetRange("Data Exch. Line Def Code", TempChildDataExchField."Data Exch. Line Def Code");

                    if ChildDataExchColumnDef.FindSet() then
                        repeat
                            // For each column def of the child
                            ParentDataExchColumnDef.SetRange(Path, ChildDataExchColumnDef.Path);
                            if ParentDataExchColumnDef.FindFirst() then begin
                                ParentLookupDataExchField.SetRange("Column No.", ParentDataExchColumnDef."Column No.");
                                // If the parent has the same attribute then inherit it to the child
                                if ParentLookupDataExchField.FindFirst() then
                                    CopyParentFieldToChild(
                                      ParentLookupDataExchField, TempChildDataExchField, ChildDataExchColumnDef."Column No.");
                            end;
                        until ChildDataExchColumnDef.Next() = 0;
                until TempChildDataExchField.Next() = 0;
                TempChildDataExchField.DeleteAll();

                // Remove parent line (which is now a subset of the child lines created above)
                DeleteLines(ParentDataExchField);
            end;
        until ParentDataExchField.Next() = 0;

        CorrectSequence(DataExch."Entry No.");
    end;

    local procedure CorrectSequence(DataExchNo: Integer)
    var
        DataExchField: Record "Data Exch. Field";
        OldLineNo: Integer;
        NewLineNo: Integer;
    begin
        OldLineNo := 0;
        NewLineNo := 0;
        DataExchField.SetRange("Data Exch. No.", DataExchNo);
        if DataExchField.FindSet() then
            repeat
                if DataExchField."Line No." <> OldLineNo then begin
                    NewLineNo += 1;
                    OldLineNo := DataExchField."Line No.";
                end;
                if DataExchField."Line No." <> NewLineNo then begin
                    DataExchField.Delete(true);
                    DataExchField.Validate("Line No.", NewLineNo);
                    DataExchField.Insert(true);
                end;
            until DataExchField.Next() = 0;
    end;

    local procedure CopyParentFieldToChild(ParentLookupDataExchField: Record "Data Exch. Field"; ChildDataExchField: Record "Data Exch. Field"; ColumnNo: Integer)
    var
        NewChildDataExchField: Record "Data Exch. Field";
    begin
        NewChildDataExchField.Init();
        NewChildDataExchField.Copy(ParentLookupDataExchField);
        NewChildDataExchField."Line No." := ChildDataExchField."Line No.";
        NewChildDataExchField."Data Exch. Line Def Code" := ChildDataExchField."Data Exch. Line Def Code";
        NewChildDataExchField."Column No." := ColumnNo;
        NewChildDataExchField.Insert(true);
    end;

    local procedure DeleteLines(DataExchField: Record "Data Exch. Field")
    var
        DeletionDataExchField: Record "Data Exch. Field";
    begin
        DeletionDataExchField.SetRange("Data Exch. No.", DataExchField."Data Exch. No.");
        DeletionDataExchField.SetRange("Data Exch. Line Def Code", DataExchField."Data Exch. Line Def Code");
        DeletionDataExchField.SetRange("Line No.", DataExchField."Line No.");
        DeletionDataExchField.DeleteAll(true);
    end;
}

