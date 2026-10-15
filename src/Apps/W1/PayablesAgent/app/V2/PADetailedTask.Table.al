// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

#pragma warning disable AS0007
namespace Microsoft.Agent.PayablesAgent;

using Microsoft.Purchases.Vendor;
using System.Agents;

/// <summary>
/// A Payables Agent Task together with values resolved from the records it points to, for display only.
/// Fields 1 to 7 mirror "Payables Agent Task" so the two can be copied with TransferFields.
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
    var
        PAV1V2Compatibility: Codeunit "PA V1V2 Compatibility";
    begin
        exit(PAV1V2Compatibility.GetSourceEmailBody(Rec));
    end;

    /// <summary>
    /// Outlook on the web link of the source email. Blank when there is no email or no external message id.
    /// </summary>
    procedure GetSourceEmailWebLink(): Text
    var
        PAV1V2Compatibility: Codeunit "PA V1V2 Compatibility";
    begin
        exit(PAV1V2Compatibility.GetSourceEmailWebLink(Rec));
    end;

    /// <summary>
    /// Opens the source PDF from where it is persisted (the Payables Agent task data in v2, the e-document in v1).
    /// </summary>
    procedure ViewSourcePdf()
    var
        PAV1V2Compatibility: Codeunit "PA V1V2 Compatibility";
    begin
        PAV1V2Compatibility.ViewSourcePdf(Rec);
    end;

    /// <summary>
    /// Downloads the source PDF from where it is persisted.
    /// </summary>
    procedure DownloadSourcePdf()
    var
        PAV1V2Compatibility: Codeunit "PA V1V2 Compatibility";
    begin
        PAV1V2Compatibility.DownloadSourcePdf(Rec);
    end;
}
