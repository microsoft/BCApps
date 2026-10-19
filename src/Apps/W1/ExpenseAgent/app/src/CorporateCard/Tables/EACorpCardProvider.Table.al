// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Bank.BankAccount;
using System.IO;
using System.Threading;

table 7426 "EA Corp Card Provider"
{
    Access = Internal;
    Caption = 'Corp Card Provider';
    DataClassification = CustomerContent;
    LookupPageId = "EA Corp Card Providers";
    DrillDownPageId = "EA Corp Card Providers";
    ReplicateData = false;
    Permissions =
        tabledata "EA Corp Card" = rimd,
        tabledata "EA Corp Card Statement" = rimd,
        tabledata "EA Corp Card Exception" = rimd,
        tabledata "EA Corp Card Trans" = rimd,
        tabledata "EA Corp Card Trans Detail" = rimd,
        tabledata "Data Exch." = rimd,
        tabledata "EA Corp Card Provider" = rimd,
        tabledata "Expense Agent Setup" = rm;

    fields
    {
        field(1; Code; Code[20])
        {
            Caption = 'Code';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies the code of the corporate card provider.';
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the description of the corporate card provider.';
        }
        field(3; Enabled; Boolean)
        {
            Caption = 'Enabled';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies whether the corporate card provider is enabled.';
        }
        field(4; "Feed Type"; Enum "EA Corp Card Feed Type")
        {
            Caption = 'Feed Type';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies the feed type for the corporate card provider.';
        }
        field(6; "Data Exch Def Code"; Code[20])
        {
            Caption = 'Data Exchange Definition Code';
            DataClassification = SystemMetadata;
            TableRelation = "Data Exch. Def";
            ToolTip = 'Specifies the data exchange definition code for the corporate card provider.';
        }
        field(7; "Data Exch Map Code"; Code[20])
        {
            Caption = 'Data Exchange Mapping Code';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies the data exchange mapping code for the corporate card provider.';
        }
        field(10; "Import Frequency (Min)"; Integer)
        {
            Caption = 'Import Frequency (Min.)';
            DataClassification = SystemMetadata;
            MinValue = 0;
            ToolTip = 'Specifies the import frequency in minutes for the corporate card provider.';
        }
        field(11; "Last Import DT"; DateTime)
        {
            Caption = 'Last Import Date-Time';
            DataClassification = SystemMetadata;
            Editable = false;
            ToolTip = 'Specifies the date and time of the last import for the corporate card provider.';
        }
        field(12; "Last Statement Entry No."; Integer)
        {
            Caption = 'Last Statement Entry No.';
            DataClassification = SystemMetadata;
            Editable = false;
            ToolTip = 'Specifies the last imported statement entry for the corporate card provider.';
        }
        field(16; "Corp Card Bank Account No."; Code[20])
        {
            Caption = 'Corporate Card Bank Account No.';
            DataClassification = AccountData;
            TableRelation = "Bank Account"."No.";
            ToolTip = 'Specifies the bank account that represents the provider liability and receives corporate card settlement transfers.';

            trigger OnValidate()
            begin
                CheckSettlementAccountsDiffer();
            end;
        }
        field(17; "Payment Bank Account No."; Code[20])
        {
            Caption = 'Payment Bank Account No.';
            DataClassification = AccountData;
            TableRelation = "Bank Account"."No.";
            ToolTip = 'Specifies the real bank account from which settlements for this provider are paid.';

            trigger OnValidate()
            begin
                CheckSettlementAccountsDiffer();
            end;
        }
    }

    keys
    {
        key(PK; Code)
        {
            Clustered = true;
        }
    }

    trigger OnDelete()
    begin
        if HasRelatedData() then
            if not Confirm(DeleteProviderWithRelatedDataQst, false, Code) then
                Error(DeleteProviderCanceledErr);

        DeleteRelatedData();
    end;

    internal procedure IsFileBasedImport(): Boolean
    begin
        exit("Feed Type" in ["Feed Type"::DataExch, "Feed Type"::CSV, "Feed Type"::XML]);
    end;

    local procedure CheckSettlementAccountsDiffer()
    begin
        if ("Corp Card Bank Account No." <> '') and
           ("Corp Card Bank Account No." = "Payment Bank Account No.")
        then
            Error(SettlementAccountsMustDifferErr);
    end;

    local procedure HasRelatedData(): Boolean
    var
        CorpCard: Record "EA Corp Card";
        CorpCardSettlement: Record "EA Corp Card Settlement";
        CorpCardStatement: Record "EA Corp Card Statement";
        CorpCardTrans: Record "EA Corp Card Trans";
        DataExch: Record "Data Exch.";
        JobQueueEntry: Record "Job Queue Entry";
    begin
        CorpCard.SetRange("Provider Code", Code);
        if not CorpCard.IsEmpty() then
            exit(true);

        CorpCardSettlement.SetRange("Provider Code", Code);
        if not CorpCardSettlement.IsEmpty() then
            exit(true);

        CorpCardStatement.SetRange("Provider Code", Code);
        if not CorpCardStatement.IsEmpty() then
            exit(true);

        CorpCardTrans.SetRange("Provider Code", Code);
        if not CorpCardTrans.IsEmpty() then
            exit(true);

        DataExch.SetRange("Related Record", RecordId);
        if not DataExch.IsEmpty() then
            exit(true);

        JobQueueEntry.SetRange("Record ID to Process", RecordId);
        exit(not JobQueueEntry.IsEmpty());
    end;

    local procedure DeleteRelatedData()
    var
        CorpCard: Record "EA Corp Card";
        CorpCardSettlement: Record "EA Corp Card Settlement";
        CorpCardStatement: Record "EA Corp Card Statement";
        CorpCardTrans: Record "EA Corp Card Trans";
        DataExch: Record "Data Exch.";
        ExpenseAgentSetup: Record "Expense Agent Setup";
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("Record ID to Process", RecordId);
        JobQueueEntry.DeleteAll(true);

        if ExpenseAgentSetup.Get() then
            if ExpenseAgentSetup."Corp Card Default Provider" = Code then begin
                ExpenseAgentSetup."Corp Card Default Provider" := '';
                ExpenseAgentSetup.Modify();
            end;

        DataExch.SetRange("Related Record", RecordId);
        DataExch.DeleteAll(true);

        CorpCardSettlement.SetRange("Provider Code", Code);
        CorpCardSettlement.DeleteAll(true);

        CorpCardStatement.SetRange("Provider Code", Code);
        CorpCardStatement.DeleteAll(true);

        CorpCardTrans.SetRange("Provider Code", Code);
        CorpCardTrans.DeleteAll(true);

        CorpCard.SetRange("Provider Code", Code);
        CorpCard.DeleteAll(true);
    end;

    var
        DeleteProviderWithRelatedDataQst: Label 'Provider %1 has related corp card data or setup. Do you want to delete the provider and all related records?', Comment = '%1 = Provider code';
        DeleteProviderCanceledErr: Label 'Deletion canceled.';
        SettlementAccountsMustDifferErr: Label 'The corporate card bank account and payment bank account must be different.';
}