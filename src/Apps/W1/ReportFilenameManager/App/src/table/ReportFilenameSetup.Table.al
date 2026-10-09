// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
table 50115 "Report Filename Setup"
{
    // The company-wide settings for the feature, in the single-row shape every Setup table in Base
    // Application has.
    //
    // Enabled is the one switch for the whole feature. It starts off, so installing the app changes
    // nothing until an administrator decides it should - and switching it off again puts every file
    // back to the name Business Central gives it, without deleting a single pattern.
    //
    // The maximum length is one value for every file name. It used to be a field on each pattern,
    // which let two patterns for the same kind of document disagree about how long a name may be.
    //
    // No row means the defaults: switched off, 100 characters. Nothing has to be created at install
    // for the feature to behave correctly, which is what keeps it safe in a company nobody has set up.

    Caption = 'Report Filename Setup';
    DataClassification = CustomerContent;
    // Public: Base Application code that names a report reads this, once the design is implemented
    // in place.
    Access = Public;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            DataClassification = SystemMetadata;
        }
        field(2; Enabled; Boolean)
        {
            Caption = 'Enabled';
            ToolTip = 'Specifies whether file name patterns are used. When this is off, every report gets Business Central''s own file name, and your patterns are kept for when you turn it on again.';
        }
        field(3; "Max. File Name Length"; Integer)
        {
            Caption = 'Max. File Name Length';
            // 100 by default, decided with the user on 28 September. The limit that bites is not a
            // file name's own 255 characters but the whole path: Excel refuses to save or open a
            // file whose folder and name together pass 218 characters, and Windows applications
            // stop at 260 unless long paths are turned on (Microsoft Learn, both). 100 leaves about
            // 110 characters of folder for an Excel file - a Downloads folder is about 25, a deep
            // OneDrive folder 90 to 100. The ceiling is 245 so that Business Central's own
            // 250-character name fields always keep room for the extension (.xlsx, .docx: 5).
            InitValue = 100;
            MinValue = 20;
            MaxValue = 245;
            ToolTip = 'Specifies the longest a file name may be, before the extension is added. Applies to every pattern. A longer name is cut at this length. Keep it short: Excel cannot open a file whose folder and name together are longer than 218 characters, and Windows programs stop at 260.';
        }
        // What Enabled puts to work. Patterns are turned on one by one while this switch is off, so
        // an administrator turning it on could not otherwise see what would start naming files.
        // Drilling down opens the patterns list, the pattern table's DrillDownPageId.
        field(4; "Enabled Patterns"; Integer)
        {
            Caption = 'Enabled Patterns';
            ToolTip = 'Specifies how many patterns are turned on. These are the patterns that name files while file name patterns are used. Choose the number to see them.';
            FieldClass = FlowField;
            CalcFormula = count("Report Filename Pattern" where(Enabled = const(true)));
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }

    /// <summary>
    /// The settings in force: the stored row, or the defaults when nobody has opened the setup yet.
    /// Never inserts - it is read on every report render, by users who may not write here.
    /// </summary>
    internal procedure GetSettings()
    begin
        if not Get() then
            Init();
    end;
}
