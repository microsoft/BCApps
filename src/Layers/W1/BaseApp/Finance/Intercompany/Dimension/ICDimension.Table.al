// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.Dimension;

using Microsoft.Finance.Dimension;

/// <summary>
/// Stores intercompany dimension definitions for cross-company dimension mapping and synchronization.
/// Enables consistent dimension structure across multiple intercompany partners.
/// </summary>
table 411 "IC Dimension"
{
    Caption = 'IC Dimension';
    DataCaptionFields = "Code", Name;
    LookupPageID = "IC Dimension List";
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Unique code identifying the intercompany dimension.
        /// </summary>
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        /// <summary>
        /// Descriptive name for the intercompany dimension.
        /// </summary>
        field(2; Name; Text[30])
        {
            Caption = 'Name';
        }
        /// <summary>
        /// Indicates whether the intercompany dimension is blocked from use.
        /// </summary>
        field(3; Blocked; Boolean)
        {
            Caption = 'Blocked';
        }
        /// <summary>
        /// Local dimension code that this intercompany dimension maps to for transaction processing.
        /// </summary>
        field(4; "Map-to Dimension Code"; Code[20])
        {
            Caption = 'Map-to Dimension Code';
            TableRelation = Dimension;

            trigger OnValidate()
            begin
                if "Map-to Dimension Code" <> xRec."Map-to Dimension Code" then begin
                    ICDimensionValue.SetRange("Dimension Code", Code);
                    ICDimensionValue.ModifyAll("Map-to Dimension Code", "Map-to Dimension Code");
                    ICDimensionValue.ModifyAll("Map-to Dimension Value Code", '');
                end;
            end;
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Code", Name, Blocked, "Map-to Dimension Code")
        {
        }
    }

    trigger OnDelete()
    var
        ICDimValue: Record "IC Dimension Value";
    begin
        RemoveDimensionMappings();
        ICDimValue.SetRange("Dimension Code", Code);
        ICDimValue.DeleteAll();
    end;

    var
        ICDimensionValue: Record "IC Dimension Value";

    local procedure RemoveDimensionMappings()
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
    begin
        Dimension.SetRange("Map-to IC Dimension Code", Rec."Code");
        if not Dimension.IsEmpty() then begin
            Dimension.FindSet();
            repeat
                DimensionValue.SetRange("Dimension Code", Dimension.Code);
                if not DimensionValue.IsEmpty() then begin
                    DimensionValue.FindSet();
                    repeat
                        if DimensionValue."Map-to IC Dimension Code" <> '' then begin
                            DimensionValue."Map-to IC Dimension Code" := '';
                            DimensionValue."Map-to IC Dimension Value Code" := '';
                            DimensionValue.Modify();
                        end;
                    until DimensionValue.Next() = 0;
                end;
                Dimension."Map-to IC Dimension Code" := '';
                Dimension.Modify();
            until Dimension.Next() = 0;
        end;
    end;
}

