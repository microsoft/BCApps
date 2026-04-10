// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.RateChange;

using System.Reflection;

/// <summary>
/// Log entries tracking all changes made during VAT rate change conversion operations.
/// Records original and new posting group values for audit and rollback purposes.
/// </summary>
table 552 "VAT Rate Change Log Entry"
{
    Caption = 'VAT Rate Change Log Entry';
    ReplicateData = true;
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Date when the VAT rate change conversion was performed.
        /// </summary>
        field(1; "Converted Date"; Date)
        {
            Caption = 'Converted Date';
            ToolTip = 'Specifies the date when the VAT rate change log entry was created.';
        }
        /// <summary>
        /// Unique sequential number identifying the log entry.
        /// </summary>
        field(2; "Entry No."; BigInteger)
        {
            AutoIncrement = true;
            Caption = 'Entry No.';
            ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
        }
        /// <summary>
        /// Table ID of the record that was modified during conversion.
        /// </summary>
        field(10; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            ToolTip = 'Specifies the table. This field is intended only for internal use.';
        }
        /// <summary>
        /// Caption of the table containing the modified record.
        /// </summary>
        field(11; "Table Caption"; Text[80])
        {
            CalcFormula = lookup(AllObj."Object Name" where("Object Type" = const(Table),
                                                             "Object ID" = field("Table ID")));
            Caption = 'Table Caption';
            ToolTip = 'Specifies the table. This field is intended only for internal use.';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Record ID identifying the specific record that was modified during conversion.
        /// </summary>
        field(20; "Record ID"; RecordID)
        {
            Caption = 'Record ID';
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// General product posting group value before the conversion.
        /// </summary>
        field(30; "Old Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Old Gen. Prod. Posting Group';
            ToolTip = 'Specifies the general product posting group before the VAT rate change conversion.';
        }
        /// <summary>
        /// General product posting group value after the conversion.
        /// </summary>
        field(31; "New Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'New Gen. Prod. Posting Group';
            ToolTip = 'Specifies the new general product posting group after the VAT rate change conversion.';
        }
        /// <summary>
        /// VAT product posting group value before the conversion.
        /// </summary>
        field(32; "Old VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'Old VAT Prod. Posting Group';
            ToolTip = 'Specifies the VAT product posting group before the VAT rate change conversion.';
        }
        /// <summary>
        /// VAT product posting group value after the conversion.
        /// </summary>
        field(33; "New VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'New VAT Prod. Posting Group';
            ToolTip = 'Specifies the new VAT product posting group after the VAT rate change conversion.';
        }
        /// <summary>
        /// Indicates whether the conversion was actually performed or logged for preview only.
        /// </summary>
        field(40; Converted; Boolean)
        {
            Caption = 'Converted';
            ToolTip = 'Specifies the status of the VAT rate change conversion.';
        }
        /// <summary>
        /// Additional information about the conversion, including any errors or special conditions encountered.
        /// </summary>
        field(50; Description; Text[250])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the description for the VAT rate change conversion.';
        }
    }

    keys
    {
        key(Key1; "Converted Date", "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Entry No.")
        {
            MaintainSIFTIndex = false;
            MaintainSQLIndex = false;
        }
        key(Key3; "Table ID")
        {
            MaintainSIFTIndex = false;
            MaintainSQLIndex = false;
        }
    }

    fieldgroups
    {
    }

    /// <summary>
    /// Updates the posting group fields in the log entry with old and new values.
    /// </summary>
    /// <param name="OldGenProdPostingGroup">Original general product posting group</param>
    /// <param name="NewGenProdPostingGroup">New general product posting group</param>
    /// <param name="OldVATProdPostingGroup">Original VAT product posting group</param>
    /// <param name="NewVATProdPostingGroup">New VAT product posting group</param>
    procedure UpdateGroups(OldGenProdPostingGroup: Code[20]; NewGenProdPostingGroup: Code[20]; OldVATProdPostingGroup: Code[20]; NewVATProdPostingGroup: Code[20])
    begin
        "Old Gen. Prod. Posting Group" := OldGenProdPostingGroup;
        "New Gen. Prod. Posting Group" := NewGenProdPostingGroup;
        "Old VAT Prod. Posting Group" := OldVATProdPostingGroup;
        "New VAT Prod. Posting Group" := NewVATProdPostingGroup;
    end;
}

