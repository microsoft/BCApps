// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

table 350 "Dimension Combination"
{
    Caption = 'Dimension Combination';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Dimension 1 Code"; Code[20])
        {
            Caption = 'Dimension 1 Code';
            NotBlank = true;
            TableRelation = Dimension.Code;
        }
        field(2; "Dimension 2 Code"; Code[20])
        {
            Caption = 'Dimension 2 Code';
            NotBlank = true;
            TableRelation = Dimension.Code;
        }
        field(3; "Combination Restriction"; Option)
        {
            Caption = 'Combination Restriction';
            NotBlank = true;
            OptionCaption = 'Limited,Blocked';
            OptionMembers = Limited,Blocked;
        }
    }

    keys
    {
        key(Key1; "Dimension 1 Code", "Dimension 2 Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        DimValueComb: Record "Dimension Value Combination";
    begin
        if "Dimension 1 Code" < "Dimension 2 Code" then begin
            DimValueComb.SetRange("Dimension 1 Code", "Dimension 1 Code");
            DimValueComb.SetRange("Dimension 2 Code", "Dimension 2 Code");
        end else begin
            DimValueComb.SetRange("Dimension 1 Code", "Dimension 2 Code");
            DimValueComb.SetRange("Dimension 2 Code", "Dimension 1 Code");
        end;
        if DimValueComb.FindFirst() then
            DimValueComb.DeleteAll(true);
    end;
}

