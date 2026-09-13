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
        field(5; "Settings"; Blob)
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
    var
        SettingsText: Text;
    begin
        SettingsText := GetSettingsText();
        if SettingsText = '' then
            exit;
        Settings.ReadFrom(SettingsText);
    end;

    /// <summary>
    /// Stores the provider settings JSON object. The full JSON is kept (no truncation).
    /// </summary>
    /// <param name="Settings">The settings JSON object.</param>
    procedure SetSettings(Settings: JsonObject)
    var
        SettingsText: Text;
    begin
        Settings.WriteTo(SettingsText);
        SetSettingsText(SettingsText);
    end;

    /// <summary>
    /// Returns the raw settings JSON text. Used by the page to edit the settings.
    /// </summary>
    /// <returns>The settings JSON text.</returns>
    procedure GetSettingsText(): Text
    var
        SettingsInStream: InStream;
        SettingsText: Text;
    begin
        CalcFields("Settings");
        if not "Settings".HasValue() then
            exit('');
        "Settings".CreateInStream(SettingsInStream, TextEncoding::UTF8);
        SettingsInStream.ReadText(SettingsText);
        exit(SettingsText);
    end;

    /// <summary>
    /// Stores the raw settings JSON text on the record without saving it, so it works for both new
    /// (delayed insert) and existing lines. The page persists it with the normal record save.
    /// </summary>
    /// <param name="SettingsText">The settings JSON text.</param>
    procedure SetSettingsText(SettingsText: Text)
    var
        SettingsOutStream: OutStream;
    begin
        Clear("Settings");
        if SettingsText = '' then
            exit;
        "Settings".CreateOutStream(SettingsOutStream, TextEncoding::UTF8);
        SettingsOutStream.WriteText(SettingsText);
    end;
}
