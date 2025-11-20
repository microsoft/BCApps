// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Activity;

table 7308 "Put-away Template Line"
{
    Caption = 'Put-away Template Line';
    ReplicateData = true;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Put-away Template Code"; Code[10])
        {
            Caption = 'Put-away Template Code';
            NotBlank = true;
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(4; "Find Fixed Bin"; Boolean)
        {
            Caption = 'Find Fixed Bin';

            trigger OnValidate()
            begin
                if "Find Fixed Bin" then begin
                    "Find Same Item" := true;
                    "Find Floating Bin" := false;
                end else
                    "Find Floating Bin" := true;
            end;
        }
        field(5; "Find Floating Bin"; Boolean)
        {
            Caption = 'Find Floating Bin';
            InitValue = true;

            trigger OnValidate()
            begin
                if "Find Floating Bin" then begin
                    "Find Bin w. Less than Min. Qty" := false;
                    "Find Fixed Bin" := false;
                end else begin
                    "Find Fixed Bin" := true;
                    "Find Same Item" := true;
                end;
            end;
        }
        field(6; "Find Same Item"; Boolean)
        {
            Caption = 'Find Same Item';

            trigger OnValidate()
            begin
                if "Find Fixed Bin" then
                    "Find Same Item" := true;

                if not "Find Same Item" then
                    "Find Unit of Measure Match" := false;
            end;
        }
        field(7; "Find Unit of Measure Match"; Boolean)
        {
            Caption = 'Find Unit of Measure Match';

            trigger OnValidate()
            begin
                if "Find Unit of Measure Match" then
                    "Find Same Item" := true;
            end;
        }
        field(8; "Find Bin w. Less than Min. Qty"; Boolean)
        {
            Caption = 'Find Bin w. Less than Min. Qty';

            trigger OnValidate()
            begin
                if "Find Bin w. Less than Min. Qty" then begin
                    Validate("Find Fixed Bin", true);
                    "Find Empty Bin" := false;
                end;
            end;
        }
        field(9; "Find Empty Bin"; Boolean)
        {
            Caption = 'Find Empty Bin';

            trigger OnValidate()
            begin
                if "Find Empty Bin" then
                    "Find Bin w. Less than Min. Qty" := false;
            end;
        }
    }

    keys
    {
        key(Key1; "Put-away Template Code", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

