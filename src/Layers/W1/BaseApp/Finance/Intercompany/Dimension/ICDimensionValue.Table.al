// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.Dimension;

using Microsoft.Finance.Dimension;
using Microsoft.Intercompany.GLAccount;
using System.Telemetry;

table 412 "IC Dimension Value"
{
    Caption = 'IC Dimension Value';
    LookupPageID = "IC Dimension Value List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Dimension Code"; Code[20])
        {
            Caption = 'Dimension Code';
            NotBlank = true;
            TableRelation = "IC Dimension";

            trigger OnValidate()
            begin
                UpdateMapToDimensionCode();
            end;
        }
        field(2; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(3; Name; Text[50])
        {
            Caption = 'Name';
        }
        field(4; "Dimension Value Type"; Option)
        {
            AccessByPermission = TableData Dimension = R;
            Caption = 'Dimension Value Type';
            OptionCaption = 'Standard,Heading,Total,Begin-Total,End-Total';
            OptionMembers = Standard,Heading,Total,"Begin-Total","End-Total";
        }
        field(5; Blocked; Boolean)
        {
            Caption = 'Blocked';
        }
        field(6; "Map-to Dimension Code"; Code[20])
        {
            Caption = 'Map-to Dimension Code';
            TableRelation = Dimension.Code;

            trigger OnValidate()
            begin
                if "Map-to Dimension Code" <> xRec."Map-to Dimension Code" then
                    Validate("Map-to Dimension Value Code", '');
            end;
        }
        field(7; "Map-to Dimension Value Code"; Code[20])
        {
            Caption = 'Map-to Dimension Value Code';
            TableRelation = "Dimension Value".Code where("Dimension Code" = field("Map-to Dimension Code"), Blocked = const(false));
        }
        field(8; Indentation; Integer)
        {
            Caption = 'Indentation';
        }
    }

    keys
    {
        key(Key1; "Dimension Code", "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ICMapping: Codeunit "IC Mapping";
    begin
        ICDimension.Get("Dimension Code");
        "Map-to Dimension Code" := ICDimension."Map-to Dimension Code";
        FeatureTelemetry.LogUptake('0000ILB', ICMapping.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::"Set up");
    end;

    trigger OnDelete()
    var
        DimensionValue: Record "Dimension Value";
    begin
        DimensionValue.SetRange("Map-to IC Dimension Value Code", Rec."Code");
        if not DimensionValue.IsEmpty() then
            DimensionValue.ModifyAll("Map-to IC Dimension Value Code", '');
    end;

    var
        ICDimension: Record "IC Dimension";

    local procedure UpdateMapToDimensionCode()
    var
        ICDimension: Record "IC Dimension";
    begin
        ICDimension.Get("Dimension Code");
        Validate("Map-to Dimension Code", ICDimension."Map-to Dimension Code");
    end;
}

