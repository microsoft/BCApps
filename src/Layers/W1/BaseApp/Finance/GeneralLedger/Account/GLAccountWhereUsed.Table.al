// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Account;

using Microsoft.Utilities;

/// <summary>
/// Stores information about where G/L accounts are being used throughout the system.
/// This table tracks references to G/L accounts in various setup tables and fields, providing visibility into account usage.
/// </summary>
table 180 "G/L Account Where-Used"
{
    Caption = 'G/L Account Where-Used';
    LookupPageID = "G/L Account Where-Used List";
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Unique identifier for each where-used entry.
        /// </summary>
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        /// <summary>
        /// The ID of the table where the G/L account is being used.
        /// </summary>
        field(2; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            ToolTip = 'Specifies the object number of the setup table where the G/L account is used.';
        }
        /// <summary>
        /// The name of the table where the G/L account is being used.
        /// </summary>
        field(3; "Table Name"; Text[150])
        {
            Caption = 'Table Name';
            ToolTip = 'Specifies the Table Name of the setup table where the G/L account is used.';
        }
        /// <summary>
        /// The name of the field in the table where the G/L account is being used.
        /// </summary>
        field(5; "Field Name"; Text[150])
        {
            Caption = 'Field Name';
            ToolTip = 'Specifies the name of the field in the setup table where the G/L account is used.';
        }
        /// <summary>
        /// A reference to the specific line or record in the setup table where the G/L account is used.
        /// </summary>
        field(6; Line; Text[250])
        {
            Caption = 'Line';
            ToolTip = 'Specifies a reference to Line in the setup table, where the G/L account is used. For example, the reference could be a posting group code.';
        }
        /// <summary>
        /// The G/L account number that is being referenced.
        /// </summary>
        field(7; "G/L Account No."; Code[20])
        {
            Caption = 'G/L Account No.';
        }
        /// <summary>
        /// The name of the G/L account that is being referenced.
        /// </summary>
        field(8; "G/L Account Name"; Text[100])
        {
            Caption = 'G/L Account Name';
        }
        /// <summary>
        /// First key field used to identify the specific record in the setup table.
        /// </summary>
        field(9; "Key 1"; Text[50])
        {
            Caption = 'Key 1';
        }
        /// <summary>
        /// Second key field used to identify the specific record in the setup table.
        /// </summary>
        field(10; "Key 2"; Text[50])
        {
            Caption = 'Key 2';
        }
        /// <summary>
        /// Third key field used to identify the specific record in the setup table.
        /// </summary>
        field(11; "Key 3"; Text[50])
        {
            Caption = 'Key 3';
        }
        /// <summary>
        /// Fourth key field used to identify the specific record in the setup table.
        /// </summary>
        field(12; "Key 4"; Text[50])
        {
            Caption = 'Key 4';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Table Name")
        {
        }
    }

    fieldgroups
    {
    }

    /// <summary>
    /// Returns a caption combining the G/L account number and name.
    /// </summary>
    /// <returns>A formatted string containing the G/L account number and name.</returns>
    procedure Caption(): Text
    begin
        exit(StrSubstNo('%1 %2', "G/L Account No.", "G/L Account Name"));
    end;

    /// <summary>
    /// Gets the last entry number used in the table to generate the next sequential entry number.
    /// </summary>
    /// <returns>The highest entry number currently in use.</returns>
    procedure GetLastEntryNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("Entry No.")))
    end;
}

