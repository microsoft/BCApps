// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

/// <summary>
/// One provider that takes part in a test configuration, together with its provider specific
/// settings (stored as JSON, for example { "seed": 2 } or { "formula": "1Y" }). Adding a line is how
/// a team extends a configuration with their own behavior.
/// </summary>
table 130468 "Test Configuration Line"
{
    DataClassification = CustomerContent;
    ReplicateData = false;
    Caption = 'Test Configuration Line';

    fields
    {
        field(1; "Configuration Code"; Code[20])
        {
            Caption = 'Configuration Code';
            TableRelation = "Test Configuration"."Code";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; "Provider"; Enum "Test Configuration Provider")
        {
            Caption = 'Provider';
        }
        field(4; "Enabled"; Boolean)
        {
            Caption = 'Enabled';
            InitValue = true;
        }
        field(5; "Settings"; Text[250])
        {
            Caption = 'Settings';
        }
    }

    keys
    {
        key(Key1; "Configuration Code", "Line No.")
        {
            Clustered = true;
        }
    }

    /// <summary>
    /// Returns the provider settings as a JSON object. Empty settings return an empty object.
    /// </summary>
    /// <returns>The settings JSON object.</returns>
    procedure GetSettings() Settings: JsonObject
    begin
        if "Settings" = '' then
            exit;
        Settings.ReadFrom("Settings");
    end;

    /// <summary>
    /// Stores the provider settings JSON object.
    /// </summary>
    /// <param name="Settings">The settings JSON object.</param>
    procedure SetSettings(Settings: JsonObject)
    var
        SettingsText: Text;
    begin
        Settings.WriteTo(SettingsText);
        "Settings" := CopyStr(SettingsText, 1, MaxStrLen("Settings"));
    end;
}
