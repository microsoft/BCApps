// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Depreciation;

table 5642 "Depreciation Table Header"
{
    Caption = 'Depreciation Table Header';
    DataCaptionFields = "Code", Description;
    LookupPageID = "Depreciation Table List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            ToolTip = 'Specifies a code for the depreciation table.';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description of the depreciation table.';
        }
        field(3; "Period Length"; Option)
        {
            Caption = 'Period Length';
            ToolTip = 'Specifies the length of period that each of the depreciation table lines will apply to.';
            OptionCaption = 'Month,Period,Quarter,Year';
            OptionMembers = Month,Period,Quarter,Year;
        }
        field(4; "Total No. of Units"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Total No. of Units';
            ToolTip = 'Specifies the total number of units the asset is expected to produce in its lifetime.';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
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
    }

    trigger OnDelete()
    begin
        DeprTableLine.LockTable();
        DeprTableLine.SetRange("Depreciation Table Code", Code);
        DeprTableLine.DeleteAll(true);
    end;

    var
        DeprTableLine: Record "Depreciation Table Line";
}

