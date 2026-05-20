// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Ledger;

using Microsoft.Finance.VAT.Ledger;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.NoSeries;
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
            ToolTip = 'Specifies the number of the general ledger register.';
        }
        /// <summary>
        /// First G/L entry number in this posting batch.
        /// </summary>
        field(2; "From Entry No."; Integer)
        {
            Caption = 'From Entry No.';
            ToolTip = 'Specifies the first general ledger entry number in the register.';
            TableRelation = "G/L Entry";
        }
        /// <summary>
        /// Last G/L entry number in this posting batch.
        /// </summary>
        field(3; "To Entry No."; Integer)
        {
            Caption = 'To Entry No.';
            ToolTip = 'Specifies the last general ledger entry number in the register.';
            TableRelation = "G/L Entry";
        }
        /// <summary>
        /// The Creation Date field has been replaced with the SystemCreateAt field but needs to be kept for historical audit purposes.
        /// </summary>
        field(4; "Creation Date"; Date)
        {
            Caption = 'Creation Date';
            ToolTip = 'Specifies the date when the entries in the register were posted.';
        }
        /// <summary>
        /// Source code indicating the journal or process that created this register.
        /// </summary>
        field(5; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            ToolTip = 'Specifies the source code for the entries in the register.';
            TableRelation = "Source Code";
        }
        /// <summary>
        /// User ID of the person who posted this register.
        /// </summary>
        field(6; "User ID"; Code[50])
        {
            Caption = 'User ID';
            ToolTip = 'Specifies the ID of the user who posted the entry, to be used, for example, in the change log.';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
        /// <summary>
        /// Journal batch name from the original journal that created this register.
        /// </summary>
        field(7; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
            ToolTip = 'Specifies the batch name of the general journal that the entries were posted from.';
        }
        /// <summary>
        /// First VAT entry number in this posting batch.
        /// </summary>
        field(8; "From VAT Entry No."; Integer)
        {
            Caption = 'From VAT Entry No.';
            ToolTip = 'Specifies the first VAT entry number in the register.';
            TableRelation = "VAT Entry";
        }
        /// <summary>
        /// Last VAT entry number in this posting batch.
        /// </summary>
        field(9; "To VAT Entry No."; Integer)
        {
            Caption = 'To VAT Entry No.';
            ToolTip = 'Specifies the last entry number in the register.';
            TableRelation = "VAT Entry";
        }
        /// <summary>
        /// Indicates whether this register has been reversed.
        /// </summary>
        field(10; Reversed; Boolean)
        {
            Caption = 'Reversed';
            ToolTip = 'Specifies if the register has been reversed (undone) from the Reverse Entries window.';
        }
        /// <summary>
        /// The Creation Time field has been replaced with the SystemCreateAt field but needs to be kept for historical audit purposes.
        /// </summary>
        field(11; "Creation Time"; Time)
        {
            Caption = 'Creation Time';
            ToolTip = 'Specifies the time when the entries in the register were posted.';
        }
        /// <summary>
        /// Journal template name from the original journal that created this register.
        /// </summary>
        field(12; "Journal Templ. Name"; Code[10])
        {
            Caption = 'Journal Template Name';
        }
        /// <summary>
        /// Number of G/L transactions in this register.
        /// </summary>
        field(13; "No. of Transactions"; Integer)
        {
            CalcFormula = count("G/L Transaction" where("G/L Register No." = field("No.")));
            Caption = 'No. of Transactions';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the number of general ledger transactions in this register.';
        }
        field(10700; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            ClosingDates = true;
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
        key(Key4; "Posting Date")
        {
        }
        key(key6; "From Entry No.", "To Entry No.")
        {
            IncludedFields = "Creation Date", SystemCreatedAt;
        }
        key(key7; "Source Code", "Journal Batch Name", SystemCreatedAt)
        {
        }
        key(key8; SystemCreatedAt)
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", "From Entry No.", "To Entry No.", SystemCreatedAt, "Source Code")
        {
        }

    }

    procedure GetNextEntryNo(UseLegacyPosting: Boolean): Integer
    begin
        if not UseLegacyPosting then
            exit(GetNextEntryNo());
        Rec.LockTable();
        exit(GetLastEntryNo() + 1);
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"G/L Register", 'r')]
    procedure GetNextEntryNo(): Integer
    var
        SequenceNoMgt: Codeunit "Sequence No. Mgt.";
    begin
        exit(SequenceNoMgt.GetNextSeqNo(DATABASE::"G/L Register"));
    end;

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

    procedure UpdateGLEntriesWithRegisterNo()
    var
        GLEntry: Record "G/L Entry";
        GLTransaction: Record "G/L Transaction";
    begin
        GLEntry.SetLoadFields("Entry No.", "G/L Register No.", "Transaction No.");
        GLEntry.SetRange("Entry No.", Rec."From Entry No.", Rec."To Entry No.");
        if GLEntry.FindSet(true) then
            repeat
                if GLEntry."G/L Register No." = 0 then begin
                    GLEntry."G/L Register No." := Rec."No.";
                    GLEntry.Modify();
                    if not GLTransaction.Get(GLEntry."Transaction No.") then begin
                        GLTransaction.Init();
                        GLTransaction."No." := GLEntry."Transaction No.";
                        GLTransaction."G/L Register No." := Rec."No.";
                        GLTransaction.Insert();
                    end;
                end;
            until GLEntry.Next() = 0;
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