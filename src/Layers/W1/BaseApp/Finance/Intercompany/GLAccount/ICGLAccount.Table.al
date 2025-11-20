// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.GLAccount;

using Microsoft.Finance.GeneralLedger.Account;
using System.Telemetry;

table 410 "IC G/L Account"
{
    Caption = 'IC G/L Account';
    LookupPageID = "IC G/L Account List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            NotBlank = true;
        }
        field(2; Name; Text[100])
        {
            Caption = 'Name';
        }
        field(3; "Account Type"; Enum "G/L Account Type")
        {
            Caption = 'Account Type';
        }
        field(4; "Income/Balance"; Enum "G/L Account Report Type")
        {
            Caption = 'Income/Balance';
        }
        field(5; Blocked; Boolean)
        {
            Caption = 'Blocked';
        }
        field(6; "Map-to G/L Acc. No."; Code[20])
        {
            Caption = 'Map-to G/L Acc. No.';
            TableRelation = "G/L Account"."No.";
        }
        field(7; Indentation; Integer)
        {
            Caption = 'Indentation';
            MinValue = 0;

            trigger OnValidate()
            begin
                if Indentation < 0 then
                    Indentation := 0;
            end;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", Name, "Income/Balance", Blocked, "Map-to G/L Acc. No.")
        {
        }
    }

    trigger OnInsert()
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ICMapping: Codeunit "IC Mapping";
    begin
        if Indentation < 0 then
            Indentation := 0;

        FeatureTelemetry.LogUptake('0000IKM', ICMapping.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::"Set up");
    end;

    trigger OnModify()
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ICMapping: Codeunit "IC Mapping";
    begin
        if Indentation < 0 then
            Indentation := 0;

        FeatureTelemetry.LogUptake('0000IKN', ICMapping.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::"Set up");
    end;

    trigger OnDelete()
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.SetRange("Default IC Partner G/L Acc. No", Rec."No.");
        if not GLAccount.IsEmpty() then
            GLAccount.ModifyAll("Default IC Partner G/L Acc. No", '');
    end;
}

