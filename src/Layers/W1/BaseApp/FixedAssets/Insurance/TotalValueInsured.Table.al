// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Insurance;

using Microsoft.FixedAssets.FixedAsset;

table 5650 "Total Value Insured"
{
    Caption = 'Total Value Insured';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "FA No."; Code[20])
        {
            Caption = 'FA No.';
            TableRelation = "Fixed Asset";
        }
        field(2; "Insurance No."; Code[20])
        {
            Caption = 'Insurance No.';
            TableRelation = Insurance;
        }
        field(3; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(4; "Total Value Insured"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Total Value Insured';
        }
    }

    keys
    {
        key(Key1; "FA No.", "Insurance No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        TempInsTotValueInsured: Record "Total Value Insured" temporary;

    procedure CreateInsTotValueInsured(FANo: Code[20])
    var
        InsCoverageLedgEntry: Record "Ins. Coverage Ledger Entry";
        InsTotValueInsured2: Record "Total Value Insured";
        Insurance: Record Insurance;
    begin
        TempInsTotValueInsured.DeleteAll();
        Clear(TempInsTotValueInsured);
        InsCoverageLedgEntry.SetCurrentKey("FA No.", "Insurance No.");
        InsCoverageLedgEntry.SetRange("FA No.", FANo);
        if InsCoverageLedgEntry.Find('-') then
            repeat
                if not InsCoverageLedgEntry."Disposed FA" then begin
                    InsTotValueInsured2.Init();
                    InsTotValueInsured2."FA No." := InsCoverageLedgEntry."FA No.";
                    InsTotValueInsured2."Insurance No." := InsCoverageLedgEntry."Insurance No.";
                    InsTotValueInsured2."Total Value Insured" := InsCoverageLedgEntry.Amount;
                    TempInsTotValueInsured := InsTotValueInsured2;
                    if TempInsTotValueInsured.Find() then begin
                        TempInsTotValueInsured."Total Value Insured" :=
                          TempInsTotValueInsured."Total Value Insured" + InsTotValueInsured2."Total Value Insured";
                        TempInsTotValueInsured.Modify();
                    end else begin
                        Insurance.Get(InsCoverageLedgEntry."Insurance No.");
                        TempInsTotValueInsured.Description := Insurance.Description;
                        TempInsTotValueInsured.Insert();
                    end;
                end;
            until InsCoverageLedgEntry.Next() = 0;
    end;

    procedure FindFirst(SearchString: Text[3]): Boolean
    begin
        TempInsTotValueInsured := Rec;
        if not TempInsTotValueInsured.Find(SearchString) then
            exit(false);
        Rec := TempInsTotValueInsured;
        exit(true);
    end;

    procedure FindNext(NextStep: Integer): Integer
    begin
        TempInsTotValueInsured := Rec;
        NextStep := TempInsTotValueInsured.Next(NextStep);
        if NextStep <> 0 then
            Rec := TempInsTotValueInsured;
        exit(NextStep);
    end;
}

