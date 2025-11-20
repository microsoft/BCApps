// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

using Microsoft.Finance.GeneralLedger.Setup;

table 480 "Dimension Set Entry"
{
    Caption = 'Dimension Set Entry';
    DrillDownPageID = "Dimension Set Entries";
    LookupPageID = "Dimension Set Entries";
    Permissions = TableData "Dimension Set Entry" = rim,
                  TableData "Dimension Set Tree Node" = rim;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
        }
        field(2; "Dimension Code"; Code[20])
        {
            Caption = 'Dimension Code';
            NotBlank = true;
            TableRelation = Dimension;

            trigger OnValidate()
            begin
                if not DimMgt.CheckDim("Dimension Code") then
                    Error(DimMgt.GetDimErr());
                if "Dimension Code" <> xRec."Dimension Code" then begin
                    "Dimension Value Code" := '';
                    "Dimension Value ID" := 0;
                end;
            end;
        }
        field(3; "Dimension Value Code"; Code[20])
        {
            Caption = 'Dimension Value Code';
            NotBlank = true;
            TableRelation = "Dimension Value".Code where("Dimension Code" = field("Dimension Code"), Blocked = const(false));

            trigger OnValidate()
            begin
                if not DimMgt.CheckDimValue("Dimension Code", "Dimension Value Code") then
                    Error(DimMgt.GetDimErr());

                DimVal.Get("Dimension Code", "Dimension Value Code");
                "Dimension Value ID" := DimVal."Dimension Value ID";
            end;
        }
        field(4; "Dimension Value ID"; Integer)
        {
            Caption = 'Dimension Value ID';
        }
        field(5; "Dimension Name"; Text[30])
        {
            CalcFormula = lookup(Dimension.Name where(Code = field("Dimension Code")));
            Caption = 'Dimension Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(6; "Dimension Value Name"; Text[50])
        {
            CalcFormula = lookup("Dimension Value".Name where("Dimension Code" = field("Dimension Code"),
                                                               Code = field("Dimension Value Code")));
            Caption = 'Dimension Value Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(8; "Global Dimension No."; Integer)
        {
            Caption = 'Shortcut Dimension No.';
        }
    }

    keys
    {
        key(Key1; "Dimension Set ID", "Dimension Code")
        {
            Clustered = true;
        }
        key(Key2; "Dimension Value ID")
        {
        }
        key(Key3; "Dimension Code", "Dimension Value Code", "Dimension Set ID")
        {
        }
        key(Key4; SystemModifiedAt)
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        if DimVal.Get("Dimension Code", "Dimension Value Code") then
            "Dimension Value ID" := DimVal."Dimension Value ID"
        else
            "Dimension Value ID" := 0;

        "Global Dimension No." := GetGlobalDimNo();
    end;

    trigger OnModify()
    begin
        if DimVal.Get("Dimension Code", "Dimension Value Code") then
            "Dimension Value ID" := DimVal."Dimension Value ID"
        else
            "Dimension Value ID" := 0;

        "Global Dimension No." := GetGlobalDimNo();
    end;

    var
        DimVal: Record "Dimension Value";
        DimMgt: Codeunit DimensionManagement;

    procedure GetDimensionSetID(var DimSetEntry: Record "Dimension Set Entry"): Integer
    var
        DimSetEntry2: Record "Dimension Set Entry";
        DimSetTreeNode: Record "Dimension Set Tree Node";
        Found: Boolean;
    begin
        OnBeforeGetDimensionSetID(DimSetEntry);

        DimSetEntry2.Copy(DimSetEntry);
        if DimSetEntry."Dimension Set ID" > 0 then
            DimSetEntry.SetRange("Dimension Set ID", DimSetEntry."Dimension Set ID");

        DimSetEntry.SetCurrentKey("Dimension Value ID");
        DimSetEntry.SetFilter("Dimension Code", '<>%1', '');
        DimSetEntry.SetFilter("Dimension Value Code", '<>%1', '');

        if not DimSetEntry.FindSet() then begin
            DimSetEntry.Copy(DimSetEntry2);
            exit(0);
        end;

        Found := true;
        DimSetTreeNode."Dimension Set ID" := 0;
        repeat
            DimSetEntry.TestField("Dimension Value ID");
            if Found then
                if not DimSetTreeNode.Get(DimSetTreeNode."Dimension Set ID", DimSetEntry."Dimension Value ID") then begin
                    Found := false;
                    DimSetTreeNode.LockTable();
                end;
            OnGetDimensionSetIDOnBeforeInsertTreeNode(DimSetEntry, Found);
            if not Found then begin
                DimSetTreeNode."Parent Dimension Set ID" := DimSetTreeNode."Dimension Set ID";
                DimSetTreeNode."Dimension Value ID" := DimSetEntry."Dimension Value ID";
                DimSetTreeNode."Dimension Set ID" := 0;
                DimSetTreeNode."In Use" := false;
                if not DimSetTreeNode.Insert(true) then
                    DimSetTreeNode.Get(DimSetTreeNode."Parent Dimension Set ID", DimSetTreeNode."Dimension Value ID");
            end;
        until DimSetEntry.Next() = 0;
        if not DimSetTreeNode."In Use" then begin
            if Found then begin
                DimSetTreeNode.LockTable();
                DimSetTreeNode.Get(DimSetTreeNode."Parent Dimension Set ID", DimSetTreeNode."Dimension Value ID");
            end;
            DimSetTreeNode."In Use" := true;
            DimSetTreeNode.Modify();
            InsertDimSetEntries(DimSetEntry, DimSetTreeNode."Dimension Set ID");
        end;

        DimSetEntry.Copy(DimSetEntry2);

        exit(DimSetTreeNode."Dimension Set ID");
    end;

    local procedure InsertDimSetEntries(var DimSetEntry: Record "Dimension Set Entry"; NewID: Integer)
    var
        DimSetEntry2: Record "Dimension Set Entry";
    begin
        DimSetEntry2.LockTable();
        if DimSetEntry.FindSet() then
            repeat
                DimSetEntry2 := DimSetEntry;
                DimSetEntry2."Dimension Set ID" := NewID;
                DimSetEntry2."Global Dimension No." := DimSetEntry2.GetGlobalDimNo();
                DimSetEntry2.Insert();
            until DimSetEntry.Next() = 0;
    end;

    procedure UpdateGlobalDimensionNo(DimensionCode: Code[20]; GlobalDimensionNo: Integer)
    var
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        DimensionSetEntry.SetRange("Dimension Code", DimensionCode);
        DimensionSetEntry.ModifyAll("Global Dimension No.", GlobalDimensionNo);
    end;

    procedure GetGlobalDimNo(): Integer
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        if "Dimension Code" = GeneralLedgerSetup."Shortcut Dimension 3 Code" then
            exit(3);
        if "Dimension Code" = GeneralLedgerSetup."Shortcut Dimension 4 Code" then
            exit(4);
        if "Dimension Code" = GeneralLedgerSetup."Shortcut Dimension 5 Code" then
            exit(5);
        if "Dimension Code" = GeneralLedgerSetup."Shortcut Dimension 6 Code" then
            exit(6);
        if "Dimension Code" = GeneralLedgerSetup."Shortcut Dimension 7 Code" then
            exit(7);
        if "Dimension Code" = GeneralLedgerSetup."Shortcut Dimension 8 Code" then
            exit(8);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetDimensionSetID(var DimensionSetEntry: Record "Dimension Set Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetDimensionSetIDOnBeforeInsertTreeNode(var DimensionSetEntry: Record "Dimension Set Entry"; var Found: Boolean)
    begin
    end;
}

