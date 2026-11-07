// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Account;

using System.Telemetry;

table 10015 "GIFI Code"
{
    Caption = 'GIFI Code';
    LookupPageID = "GIFI Codes";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
        }
        field(2; Name; Text[120])
        {
            Caption = 'Name';
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

    trigger OnInsert()
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        CanGIFITok: Label 'Canada GIDI Codes', Locked = true;
    begin
        FeatureTelemetry.LogUptake('1000HM7', CanGIFITok, Enum::"Feature Uptake Status"::"Set up");
    end;
}

