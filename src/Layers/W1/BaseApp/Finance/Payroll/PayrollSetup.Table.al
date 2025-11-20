// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Payroll;

using Microsoft.EServices.EDocument;
using Microsoft.Finance.GeneralLedger.Journal;

/// <summary>
/// Configuration table for payroll import functionality and default journal assignments.
/// Stores user preferences and journal template settings for payroll processing.
/// </summary>
/// <remarks>
/// Single-record setup table with validation for journal template types and batch relationships.
/// Integrates with General Journal for payroll transaction posting.
/// </remarks>
table 1660 "Payroll Setup"
{
    Caption = 'Payroll Setup';
    DrillDownPageID = "Incoming Documents Setup";
    LookupPageID = "Incoming Documents Setup";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Integer)
        {
            AutoIncrement = true;
            Caption = 'Primary Key';
        }
        /// <summary>
        /// Default journal template for payroll imports.
        /// Restricted to specific journal types with validation for non-recurring templates.
        /// </summary>
        field(2; "General Journal Template Name"; Code[10])
        {
            Caption = 'General Journal Template Name';
            TableRelation = "Gen. Journal Template" where(Type = filter(General),
                                                           Recurring = const(false));

            trigger OnValidate()
            var
                GenJournalTemplate: Record "Gen. Journal Template";
                xGenJournalTemplate: Record "Gen. Journal Template";
            begin
                if "General Journal Template Name" = '' then begin
                    "General Journal Batch Name" := '';
                    exit;
                end;
                GenJournalTemplate.Get("General Journal Template Name");
                if not (GenJournalTemplate.Type in
                        [GenJournalTemplate.Type::General, GenJournalTemplate.Type::Purchases, GenJournalTemplate.Type::Payments,
                         GenJournalTemplate.Type::Sales, GenJournalTemplate.Type::"Cash Receipts"])
                then
                    Error(
                      TemplateTypeErr,
                      GenJournalTemplate.Type::General, GenJournalTemplate.Type::Purchases, GenJournalTemplate.Type::Payments,
                      GenJournalTemplate.Type::Sales, GenJournalTemplate.Type::"Cash Receipts");
                if xRec."General Journal Template Name" <> '' then
                    if xGenJournalTemplate.Get(xRec."General Journal Template Name") then;
                if GenJournalTemplate.Type <> xGenJournalTemplate.Type then
                    "General Journal Batch Name" := '';
            end;
        }
        /// <summary>
        /// Default journal batch for payroll imports within the selected template.
        /// Validates against non-recurring batches only.
        /// </summary>
        field(3; "General Journal Batch Name"; Code[10])
        {
            Caption = 'General Journal Batch Name';
            TableRelation = "Gen. Journal Batch".Name where("Journal Template Name" = field("General Journal Template Name"));

            trigger OnValidate()
            var
                GenJournalBatch: Record "Gen. Journal Batch";
            begin
                if "General Journal Batch Name" <> '' then
                    TestField("General Journal Template Name");
                GenJournalBatch.Get("General Journal Template Name", "General Journal Batch Name");
                GenJournalBatch.TestField(Recurring, false);
            end;
        }
        /// <summary>
        /// User account associated with payroll processing.
        /// </summary>
        field(10; "User Name"; Code[50])
        {
            Caption = 'User Name';
            DataClassification = EndUserIdentifiableInformation;
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        Fetched: Boolean;
#pragma warning disable AA0470
        TemplateTypeErr: Label 'Only General Journal Templates of type %1, %2, %3, %4, or %5 are allowed.', Comment = '%1..5 lists Type=General,Purchases,Payments,Sales,Cash Receipts';
#pragma warning restore AA0470

    /// <summary>
    /// Retrieves setup record, creating default values if no record exists.
    /// </summary>
    procedure Fetch()
    begin
        if Fetched then
            exit;
        Fetched := true;
        if not Get() then
            Init();
    end;
}

