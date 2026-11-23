// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.AI.BusinessSkills;

/// <summary>
/// Append-only history of a business skill's content. Each change to the skill content inserts a new
/// entry; the entry with the highest <c>Entry No.</c> for a skill is always the current content.
/// </summary>
/// <remarks>
/// Entries are immutable once written. Older entries may be deleted from the history page, but the
/// latest (current) entry cannot be deleted. Restoring an older entry re-inserts its content as a new
/// latest entry rather than mutating history.
/// </remarks>
table 4160 "Bus Skill Content Version"
{
    Caption = 'Business Skill Content Version';
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
            ToolTip = 'Specifies the unique identifier of the content version.';
            DataClassification = SystemMetadata;
            AutoIncrement = true;
        }
        /// <summary>
        /// ID of the skill this version belongs to.
        /// </summary>
        field(2; "Skill ID"; BigInteger)
        {
            Caption = 'Skill ID';
            ToolTip = 'Specifies the skill this content version belongs to.';
            DataClassification = SystemMetadata;
            TableRelation = "Business Skill"."ID";
        }
        /// <summary>
        /// Snapshot of the skill content for this version.
        /// </summary>
        field(3; Content; Blob)
        {
            Caption = 'Content';
            ToolTip = 'Specifies the immutable content captured in this version. Restoring it creates a new version.';
            DataClassification = CustomerContent;
        }
        field(4; "Content Version"; Text[50])
        {
            Caption = 'Content Version';
            ToolTip = 'Specifies the content version when these instructions were recorded.';
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
        BusinessSkillContentHistory: Codeunit "Business Skill Content History";
    begin
        BusinessSkillContentHistory.VerifyCanDeleteVersion("Entry No.");
    end;

    /// <summary>
    /// Writes the given content into the version's BLOB. Call before Insert.
    /// </summary>
    procedure SetContent(NewContent: SecretText)
    var
        BusinessSkillImpl: Codeunit "Business Skill Impl.";
        OutStr: OutStream;
    begin
        BusinessSkillImpl.ValidateLength(NewContent);
        Clear(Content);
        Content.CreateOutStream(OutStr, BusinessSkillImpl.GetEncoding());
        BusinessSkillImpl.WriteText(OutStr, NewContent);
    end;

    /// <summary>
    /// Returns the version's content, preserving multiple lines.
    /// </summary>
    procedure GetContent(): SecretText
    var
        BusinessSkillImpl: Codeunit "Business Skill Impl.";
        InStr: InStream;
    begin
        CalcFields(Content);
        if not Content.HasValue() then
            exit;
        Content.CreateInStream(InStr, BusinessSkillImpl.GetEncoding());
        exit(BusinessSkillImpl.ReadText(InStr));
    end;

    var
        ImmutableErr: Label 'Business skill content versions are immutable.';
}
