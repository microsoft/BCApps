// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Consolidation;

/// <summary>
/// Stores consolidation process execution data and status tracking for multi-company consolidation operations.
/// Manages consolidation workflow state, parameters, and error handling for business unit data processing.
/// </summary>
/// <remarks>
/// Central table for consolidation process management containing execution parameters and status monitoring.
/// Integrates with business unit consolidation workflow for tracking multi-step consolidation operations.
/// Used by consolidation wizards and automated consolidation job processing.
/// </remarks>
table 1830 "Consolidation Process"
{
    Caption = 'Consolidation Process';
    ReplicateData = false;
    Extensible = false;
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Unique identifier for consolidation process execution tracking and reference.
        /// </summary>
        field(1; Id; Integer)
        {
            AutoIncrement = true;
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Current status of consolidation process execution with workflow state tracking.
        /// </summary>
        field(2; Status; Option)
        {
            OptionMembers = NotStarted,InProgress,Failed,Completed;
            OptionCaption = 'Not started,In Progress,Failed,Completed';
            ToolTip = 'Status of the consolidation process';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Starting date for consolidation period defining the beginning of data extraction range.
        /// </summary>
        field(3; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
            ToolTip = 'Starting date for the entries in the consolidation';
            ClosingDates = true;
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Ending date for consolidation period defining the conclusion of data extraction range.
        /// </summary>
        field(4; "Ending Date"; Date)
        {
            Caption = 'Ending Date';
            ToolTip = 'Ending date for the entries in the consolidation';
            ClosingDates = true;
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Journal template name for posting consolidated transactions during process execution.
        /// </summary>
        field(5; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Journal batch name for organizing consolidated transaction postings by process.
        /// </summary>
        field(6; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Document number used for consolidated journal entries created during process execution.
        /// </summary>
        field(7; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Parent company currency code for consolidation transactions and currency conversion.
        /// </summary>
        field(8; "Parent Currency Code"; Code[10])
        {
            Caption = 'Parent Currency Code';
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// List of dimension codes to transfer during consolidation for multi-dimensional analysis.
        /// </summary>
        field(9; "Dimensions to Transfer"; Text[250])
        {
            Caption = 'Dimensions to Transfer';
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Error message text capturing consolidation process failures and exception details.
        /// </summary>
        field(10; "Error"; Text[2048])
        {
            Caption = 'Error';
            DataClassification = SystemMetadata;
        }
    }
    keys
    {
        key(Key1; Id)
        {
            Clustered = true;
        }
    }

    trigger OnDelete()
    var
        BusUnitInConsProcess: Record "Bus. Unit In Cons. Process";
    begin
        BusUnitInConsProcess.SetRange("Consolidation Process Id", Id);
        BusUnitInConsProcess.DeleteAll();
    end;

}
