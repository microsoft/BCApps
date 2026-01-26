// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.WithholdingTax;

using System.Telemetry;

table 28041 "WHT Product Posting Group"
{
    Caption = 'WHT Product Posting Group';
    LookupPageID = "WHT Product Posting Group";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
        }
        field(2; Description; Text[50])
        {
            Caption = 'Description';
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
        fieldgroup(DropDown; "Code", Description)
        {
        }
    }

    trigger OnInsert()
    begin
        FeatureTelemetry.LogUptake('0000HH2', APACWHTTok, Enum::"Feature Uptake Status"::"Set up");
    end;

    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        APACWHTTok: Label 'APAC Set Up Withholding Tax', Locked = true;
}
