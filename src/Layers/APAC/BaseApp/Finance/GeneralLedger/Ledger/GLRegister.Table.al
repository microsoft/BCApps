// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Ledger;

using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.WithholdingTax;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Utilities;
using System.Security.AccessControl;

/// <summary>
/// Stores register information for G/L entry posting batches with audit trail and navigation capabilities.
/// Provides sequential numbering and date tracking for all G/L entry transactions.
/// </summary>
/// <remarks>
/// Key relationships: G/L Entry, VAT Entry, Source Code. Primary key: No.
/// Extensible via table extensions for additional posting batch tracking requirements.
/// Used for audit trail, batch navigation, and posting verification.
/// </remarks>
table 45 "G/L Register"
{
    Caption = 'G/L Register';
    LookupPageID = "G/L Registers";
    Permissions = TableData "G/L Register" = rimd;
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Sequential register number for G/L entry posting batches.
        /// </summary>
        field(1; "No."; Integer)
        {
            Caption = 'No.';
        }
        /// <summary>
        /// First G/L entry number in this posting batch.
        /// </summary>
        field(2; "From Entry No."; Integer)
        {
            Caption = 'From Entry No.';
            TableRelation = "G/L Entry";
        }
        /// <summary>
        /// Last G/L entry number in this posting batch.
        /// </summary>
        field(3; "To Entry No."; Integer)
        {
            Caption = 'To Entry No.';
            TableRelation = "G/L Entry";
        }
        /// <summary>
        /// The Creation Date field has been replaced with the SystemCreateAt field but needs to be kept for historical audit purposes.
        /// </summary>
        field(4; "Creation Date"; Date)
        {
            Caption = 'Creation Date';
        }
        /// <summary>
        /// Source code indicating the journal or process that created this register.
        /// </summary>
        field(5; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            TableRelation = "Source Code";
        }
        /// <summary>
        /// User ID of the person who posted this register.
        /// </summary>
        field(6; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
        /// <summary>
        /// Journal batch name from the original journal that created this register.
        /// </summary>
        field(7; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
        }
        /// <summary>
        /// First VAT entry number in this posting batch.
        /// </summary>
        field(8; "From VAT Entry No."; Integer)
        {
            Caption = 'From VAT Entry No.';
            TableRelation = "VAT Entry";
        }
        /// <summary>
        /// Last VAT entry number in this posting batch.
        /// </summary>
        field(9; "To VAT Entry No."; Integer)
        {
            Caption = 'To VAT Entry No.';
            TableRelation = "VAT Entry";
        }
        /// <summary>
        /// Indicates whether this register has been reversed.
        /// </summary>
        field(10; Reversed; Boolean)
        {
            Caption = 'Reversed';
        }
        /// <summary>
        /// The Creation Time field has been replaced with the SystemCreateAt field but needs to be kept for historical audit purposes.
        /// </summary>
        field(11; "Creation Time"; Time)
        {
            Caption = 'Creation Time';
        }
        /// <summary>
        /// Journal template name from the original journal that created this register.
        /// </summary>
        field(12; "Journal Templ. Name"; Code[10])
        {
            Caption = 'Journal Template Name';
        }
        field(28040; "From WHT Entry No."; Integer)
        {
            Caption = 'From WHT Entry No.';
            TableRelation = "WHT Entry";
        }
        field(28041; "To WHT Entry No."; Integer)
        {
            Caption = 'To WHT Entry No.';
            TableRelation = "WHT Entry";
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Creation Date")
        {
        }
        key(Key3; "Source Code", "Journal Batch Name", "Creation Date")
        {
        }
        key(key4; "From Entry No.", "To Entry No.")
        {
            IncludedFields = "Creation Date", SystemCreatedAt;
        }
        key(key5; "Source Code", "Journal Batch Name", SystemCreatedAt)
        {
        }
        key(key6; SystemCreatedAt)
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", "From Entry No.", "To Entry No.", SystemCreatedAt, "Source Code")
        {
        }

    }

    /// <summary>
    /// Retrieves the last (highest) register number from the G/L Register table.
    /// </summary>
    /// <returns>Integer: The highest register number, or 0 if no registers exist.</returns>
    [InherentPermissions(PermissionObjectType::TableData, Database::"G/L Register", 'r')]
    procedure GetLastEntryNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("No.")))
    end;

    /// <summary>
    /// Initializes a new G/L Register record with the specified parameters.
    /// </summary>
    /// <param name="NextRegNo">Next sequential register number to assign.</param>
    /// <param name="FromEntryNo">Starting G/L entry number for this register.</param>
    /// <param name="FromVATEntryNo">Starting VAT entry number for this register.</param>
    /// <param name="SourceCode">Source code identifying the posting process.</param>
    /// <param name="BatchName">Journal batch name from the posting process.</param>
    /// <param name="TemplateName">Journal template name from the posting process.</param>
    procedure Initialize(NextRegNo: Integer; FromEntryNo: Integer; FromVATEntryNo: Integer; SourceCode: Code[10]; BatchName: Code[10]; TemplateName: Code[10])
    begin
        Init();
        OnInitializeOnAfterGLRegisterInit(Rec, TemplateName);
        "No." := NextRegNo;
        "Source Code" := SourceCode;
        "User ID" := CopyStr(UserId(), 1, MaxStrLen("User ID"));
        "From Entry No." := FromEntryNo;
        "From VAT Entry No." := FromVATEntryNo;
        "Journal Batch Name" := BatchName;
        "Journal Templ. Name" := TemplateName;
    end;


    /// <summary>
    /// Integration event raised after initializing a G/L Register record.
    /// </summary>
    /// <param name="GLRegister">G/L Register record being initialized.</param>
    /// <param name="TemplateName">Journal template name used for initialization.</param>
    [IntegrationEvent(false, false)]
    local procedure OnInitializeOnAfterGLRegisterInit(var GLRegister: record "G/L Register"; TemplateName: Code[10])
    begin
    end;
}
