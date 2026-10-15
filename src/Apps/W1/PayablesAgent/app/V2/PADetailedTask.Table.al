// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using Microsoft.Purchases.Vendor;
using System.Agents;

/// <summary>
/// A Payables Agent task together with values resolved from the records it points to: the source table of task
/// lists (computed values become real, sortable columns) and the single record passed around to describe a task.
/// Populated by the "PA Task" and "PA Task Collection" facades, whatever backs the task (e-document in v1, Payables
/// Agent task in v2). Fields 1 to 7 mirror "Payables Agent Task" so the two can be copied with TransferFields.
/// The procedures load this record into a "PA Task" instance and delegate to it.
/// </summary>
table 3332 "PA Detailed Task"
{
    Caption = 'Payables Agent Task';
    Access = Internal;
    TableType = Temporary;
    DataClassification = CustomerContent;
    Extensible = false;

    fields
    {
        field(1; "Entry No."; BigInteger)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
        }
        field(2; "Source Data No."; BigInteger)
        {
            Caption = 'Source Data No.';
            DataClassification = SystemMetadata;
            TableRelation = "Payables Agent Task Source"."Entry No.";
        }
        field(3; "Task Data No."; BigInteger)
        {
            Caption = 'Task Data No.';
            DataClassification = SystemMetadata;
            TableRelation = "Payables Agent Task Data"."Entry No.";
        }
        field(4; "Agent Task ID"; BigInteger)
        {
            Caption = 'Agent Task ID';
            DataClassification = SystemMetadata;
            TableRelation = "Agent Task".ID;
        }
        field(5; Outcome; RecordId)
        {
            Caption = 'Outcome';
            DataClassification = CustomerContent;
        }
        field(6; "Received At"; DateTime)
        {
            Caption = 'Received At';
            DataClassification = SystemMetadata;
        }
        field(7; "Completed At"; DateTime)
        {
            Caption = 'Completed At';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// The vendor of the Purchase Invoice registered as the outcome. Blank for any other outcome.
        /// </summary>
        field(10; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            DataClassification = CustomerContent;
            TableRelation = Vendor."No.";
        }
        field(11; "Agent Task Status"; Enum "Agent Task Status")
        {
            Caption = 'Agent Task Status';
            DataClassification = SystemMetadata;
        }
        field(20; "Source Type"; Enum "PA Agent Source Type")
        {
            Caption = 'Source Type';
            DataClassification = SystemMetadata;
        }
        field(21; "Email From"; Text[250])
        {
            Caption = 'Email From';
            DataClassification = CustomerContent;
        }
        field(22; "Email Subject"; Text[250])
        {
            Caption = 'Email Subject';
            DataClassification = CustomerContent;
        }
        field(23; "File Name"; Text[250])
        {
            Caption = 'File Name';
            DataClassification = CustomerContent;
        }
        field(24; "Has Pdf"; Boolean)
        {
            Caption = 'Has PDF';
            DataClassification = SystemMetadata;
        }
        field(25; "Email Inbox Id"; BigInteger)
        {
            Caption = 'Email Inbox Id';
            DataClassification = SystemMetadata;
        }
        field(26; "Source Record Id"; RecordId)
        {
            Caption = 'Source Record Id';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }

    /// <summary>
    /// Body of the source email, read live from the Email module via "Email Inbox Id". Blank when the task did
    /// not come from an email or the email is no longer available.
    /// </summary>
    procedure GetSourceEmailBody(): Text
    begin
        PATask.LoadFromRecord(Rec);
        exit(PATask.GetSourceEmailBody());
    end;

    /// <summary>
    /// Outlook on the web link of the source email. Blank when there is no email or no external message id.
    /// </summary>
    procedure GetSourceEmailWebLink(): Text
    begin
        PATask.LoadFromRecord(Rec);
        exit(PATask.GetSourceEmailWebLink());
    end;

    /// <summary>
    /// Describes what the task came from.
    /// </summary>
    procedure DescribeSource(): Text
    begin
        PATask.LoadFromRecord(Rec);
        exit(PATask.DescribeSource());
    end;

    /// <summary>
    /// Describes the record registered as the task outcome.
    /// </summary>
    procedure DescribeOutcome(): Text
    begin
        PATask.LoadFromRecord(Rec);
        exit(PATask.DescribeOutcome());
    end;

    /// <summary>
    /// Opens what the task came from.
    /// </summary>
    procedure OpenSource()
    begin
        PATask.LoadFromRecord(Rec);
        PATask.OpenSource();
    end;

    /// <summary>
    /// Opens the email the task came from.
    /// </summary>
    procedure OpenSourceEmail()
    begin
        PATask.LoadFromRecord(Rec);
        PATask.OpenSourceEmail();
    end;

    /// <summary>
    /// Opens the source PDF in a page.
    /// </summary>
    procedure OpenSourcePdf()
    begin
        PATask.LoadFromRecord(Rec);
        PATask.OpenSourcePdf();
    end;

    /// <summary>
    /// Opens the source PDF in the client file viewer, from where it is persisted.
    /// </summary>
    procedure ViewSourcePdf()
    begin
        PATask.LoadFromRecord(Rec);
        PATask.ViewSourcePdf();
    end;

    /// <summary>
    /// Downloads the source PDF from where it is persisted.
    /// </summary>
    procedure DownloadSourcePdf()
    begin
        PATask.LoadFromRecord(Rec);
        PATask.DownloadSourcePdf();
    end;

    /// <summary>
    /// Registers the record the task produced as its outcome, and refreshes this record.
    /// </summary>
    procedure RegisterOutcome(OutcomeRecordId: RecordId)
    begin
        PATask.LoadFromRecord(Rec);
        PATask.RegisterOutcome(OutcomeRecordId);
        PATask.GetRecord(Rec);
    end;

    /// <summary>
    /// Opens the record registered as the task outcome.
    /// </summary>
    procedure OpenOutcome()
    begin
        PATask.LoadFromRecord(Rec);
        PATask.OpenOutcome();
    end;

    /// <summary>
    /// Re-reads this task from where it is persisted.
    /// </summary>
    procedure Refresh()
    begin
        PATask.LoadFromRecord(Rec);
        PATask.Refresh();
        PATask.GetRecord(Rec);
    end;

    /// <summary>
    /// Loads this task into a "PA Task" facade instance.
    /// </summary>
    procedure GetTask(var PATaskToLoad: Codeunit "PA Task")
    begin
        PATaskToLoad.LoadFromRecord(Rec);
    end;

    var
        PATask: Codeunit "PA Task";
}
