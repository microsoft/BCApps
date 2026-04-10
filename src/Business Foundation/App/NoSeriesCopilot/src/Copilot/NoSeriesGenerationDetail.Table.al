// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

using System.Reflection;

table 392 "No. Series Generation Detail"
{
    TableType = Temporary;
    InherentEntitlements = X;
    InherentPermissions = X;

    fields
    {
        field(1; "Generation No."; Integer)
        {
            Caption = 'No.';
        }
        field(2; "Series Code"; Code[20])
        {
            Caption = 'Series Code';
        }

        field(4; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(5; "Starting No."; Code[20])
        {
            Caption = 'Starting No.';
            trigger OnValidate()
            begin
                UpdateGeneratedNoSeriesLine(Rec.FieldNo("Starting No."));
            end;
        }
        field(6; "Ending No."; Code[20])
        {
            Caption = 'Ending No.';

            trigger OnValidate()
            begin
                UpdateGeneratedNoSeriesLine(Rec.FieldNo("Ending No."));
            end;
        }
        field(7; "Warning No."; Code[20])
        {
            Caption = 'Warning No.';

            trigger OnValidate()
            begin
                UpdateGeneratedNoSeriesLine(Rec.FieldNo("Warning No."));
            end;
        }
        field(8; "Increment-by No."; Integer)
        {
            Caption = 'Increment-by No.';
        }
        field(9; "Setup Table No."; Integer)
        {
            Caption = 'Setup Table No.';
        }
        field(10; "Setup Field No."; Integer)
        {
            Caption = 'Setup Field No.';
        }
        field(11; "Is Next Year"; Boolean)
        {
            Caption = 'Is Next Year';
            trigger OnValidate()
            begin
                UpdateStartingDate();
            end;
        }
        field(12; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
        }
        field(13; "Exists"; Boolean)
        {
            Caption = 'Exists';
        }
        field(14; Message; Text[1024])
        {
            Caption = 'Message';
        }
        field(20; "Setup Table Name"; Text[80])
        {
            Caption = 'Setup Table';
            FieldClass = FlowField;
            CalcFormula = lookup("Table Metadata".Caption where(ID = field("Setup Table No.")));
            Editable = false;
        }
        field(21; "Setup Field Name"; Text[250])
        {
            Caption = 'Setup Field';
            FieldClass = FlowField;
            CalcFormula = lookup(Field."Field Caption" where(TableNo = field("Setup Table No."), "No." = field("Setup Field No.")));
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Generation No.", "Series Code")
        {
            Clustered = true;
        }
    }

    local procedure UpdateGeneratedNoSeriesLine(ChangedField: Integer)
    var
        TempNoSeriesLine: Record "No. Series Line" temporary;
    begin
        Initialize(TempNoSeriesLine);

        case ChangedField of
            Rec.FieldNo("Starting No."):
                TempNoSeriesLine.Validate("Starting No.", Rec."Starting No.");
            Rec.FieldNo("Ending No."):
                TempNoSeriesLine.Validate("Ending No.", Rec."Ending No.");
            Rec.FieldNo("Warning No."):
                TempNoSeriesLine.Validate("Warning No.", Rec."Warning No.");
        end;

        ApplyChanges(TempNoSeriesLine);
    end;

    local procedure Initialize(var TempNoSeriesLine: Record "No. Series Line" temporary)
    begin
        TempNoSeriesLine.Init();
        TempNoSeriesLine."Series Code" := Rec."Series Code";
        TempNoSeriesLine."Starting No." := Rec."Starting No.";
        TempNoSeriesLine."Ending No." := Rec."Ending No.";
        TempNoSeriesLine."Warning No." := Rec."Warning No.";
        TempNoSeriesLine."Increment-by No." := Rec."Increment-by No.";
        TempNoSeriesLine.Insert()
    end;

    local procedure ApplyChanges(var TempNoSeriesLine: Record "No. Series Line" temporary)
    begin
        Rec."Starting No." := TempNoSeriesLine."Starting No.";
        Rec."Ending No." := TempNoSeriesLine."Ending No.";
        Rec."Warning No." := TempNoSeriesLine."Warning No.";
    end;

    local procedure UpdateStartingDate()
    begin
        if not Rec."Is Next Year" then
            exit;

        Rec."Starting Date" := CalcDate('<-CY+1Y>', Today);
    end;
}
