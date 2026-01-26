// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using System.Telemetry;

table 11306 "Electronic Banking Setup"
{
    Caption = 'Electronic Banking Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';

            trigger OnValidate()
            var
                FeatureTelemetry: Codeunit "Feature Telemetry";
                BEElecBankTok: Label 'BE Electronic Banking', Locked = true;
            begin
                FeatureTelemetry.LogUptake('1000HL5', BEElecBankTok, Enum::"Feature Uptake Status"::"Set up");
            end;
        }
        field(2; "Summarize Gen. Jnl. Lines"; Boolean)
        {
            Caption = 'Summarize Gen. Jnl. Lines';
            InitValue = true;
        }
        field(3; "Cut off Payment Message Texts"; Boolean)
        {
            Caption = 'Cut off Payment Message Texts';
            InitValue = false;
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}
