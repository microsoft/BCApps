// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.AI.BusinessSkills;

/// <summary>
/// Append-only history of a business skill's text. Each change to the skill text inserts a new
/// entry; the entry with the highest <c>Entry No.</c> for a skill is always the current text.
/// </summary>
/// <remarks>
/// Entries are immutable once written. Older entries may be deleted from the history page, but the
/// latest (current) entry cannot be deleted. Restoring an older entry re-inserts its text as a new
/// latest entry rather than mutating history.
/// </remarks>
table 4160 "Business Skill Text Version"
{
    Caption = 'Business Skill Text Version';
    DataPerCompany = false;
    ReplicateData = false;
    DataClassification = CustomerContent;
    InherentPermissions = RIMDX;
    InherentEntitlements = RIMDX;

    fields
    {
        /// <summary>
        /// Unique auto-incrementing identifier for the version entry.
        /// </summary>
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            ToolTip = 'Specifies the unique identifier of the text version.';
            DataClassification = SystemMetadata;
            AutoIncrement = true;
        }
        /// <summary>
        /// ID of the skill this version belongs to.
        /// </summary>
        field(2; "Skill ID"; BigInteger)
        {
            Caption = 'Skill ID';
            ToolTip = 'Specifies the skill this text version belongs to.';
            DataClassification = SystemMetadata;
            TableRelation = "Business Skill"."ID";
        }
        /// <summary>
        /// Snapshot of the skill text for this version.
        /// </summary>
        field(3; "Skill Text"; Blob)
        {
            Caption = 'Skill Text';
            ToolTip = 'Specifies the immutable text captured in this version. Restoring it creates a new version.';
            DataClassification = CustomerContent;
        }
        field(4; Version; Text[50])
        {
            Caption = 'Version';
            ToolTip = 'Specifies the skill version when these instructions were recorded.';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(SkillID; "Skill ID", "Entry No.")
        {
        }
    }

    trigger OnModify()
    begin
        Error(ImmutableErr);
    end;

    trigger OnDelete()
    var
        SkillManagement: Codeunit "Business Skill Management";
    begin
        SkillManagement.VerifyCanDeleteTextVersion("Entry No.");
    end;

    /// <summary>
    /// Writes the given text into the version's BLOB. Call before Insert.
    /// </summary>
    procedure SetText(NewText: Text)
    var
        SkillText: Codeunit "Business Skill Text";
        OutStr: OutStream;
    begin
        SkillText.ValidateLength(NewText);
        Clear("Skill Text");
        "Skill Text".CreateOutStream(OutStr, SkillText.GetEncoding());
        OutStr.WriteText(NewText);
    end;

    /// <summary>
    /// Returns the version's text, preserving multiple lines.
    /// </summary>
    procedure GetText(): Text
    var
        SkillText: Codeunit "Business Skill Text";
        InStr: InStream;
    begin
        CalcFields("Skill Text");
        if not "Skill Text".HasValue() then
            exit('');
        "Skill Text".CreateInStream(InStr, SkillText.GetEncoding());
        exit(SkillText.ReadText(InStr));
    end;

    var
        ImmutableErr: Label 'Business skill text versions are immutable.';
}
