// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting.FileNaming;

table 8130 "Report Filename Setup"
{
    // No row means the defaults (disabled, 100 characters), so nothing is created at install.

    Caption = 'Report Filename Setup';
    DataClassification = CustomerContent;
    // Public, so other extensions can read the setting.
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
            ToolTip = 'Specifies whether file name patterns are used. When this is off, every report gets Business Central''s own file name, and your patterns are kept for when you turn it on again. Turning this off affects new output only. Existing Report Inbox entries keep their stored file names.';
        }
        field(3; "Max. File Name Length"; Integer)
        {
            Caption = 'Max. File Name Length';
            // Default 100 leaves room for the folder within Excel's 218-character path limit.
            // Max 245 keeps room for the extension in 250-character file name fields, such as
            // Report Inbox's File Name and Document Attachment's File Name.
            InitValue = 100;
            MinValue = 20;
            MaxValue = 245;
            ToolTip = 'Specifies the longest a file name may be, before the extension is added. Applies to every pattern. A longer name is cut at this length. Keep it short: Excel cannot open a file whose folder and name together are longer than 218 characters, and Windows programs stop at 260.';
        }
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
    /// The stored row, or the defaults. Never inserts: the setup page is the only place the row is created.
    /// </summary>
    internal procedure GetSettings()
    begin
        if not Get() then
            Init();
    end;
}
