// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using System.IO;
using System.Threading;

table 7216 "EA Corp Card Provider"
{
    Access = Internal;
    Caption = 'Corp Card Provider';
    DataClassification = CustomerContent;
    LookupPageId = "EA Corp Card Providers";
    DrillDownPageId = "EA Corp Card Providers";
    ReplicateData = false;
    Permissions =
        tabledata "EA Corp Card" = rimd,
        tabledata "EA Corp Card Batch" = rimd,
        tabledata "EA Corp Card Exception" = rimd,
        tabledata "EA Corp Card Trans" = rimd,
        tabledata "EA Corp Card Trans Detail" = rimd,
        tabledata "Data Exch." = rimd,
        tabledata "Data Exch. Def" = rimd,
        tabledata "Data Exch. Mapping" = rimd,
        tabledata "Data Exch. Line Def" = rimd,
        tabledata "Data Exch. Column Def" = rimd,
        tabledata "Data Exch. Field Mapping" = rimd,
        tabledata "EA Corp Card Provider" = rimd;

    fields
    {
        field(1; Code; Code[20])
        {
            Caption = 'Code';
            ToolTip = 'Specifies the code of the corporate card provider.';
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the description of the corporate card provider.';
        }
        field(3; Enabled; Boolean)
        {
            Caption = 'Enabled';
            ToolTip = 'Specifies whether the corporate card provider is enabled.';
        }
        field(4; "Feed Type"; Enum "EA Corp Card Feed Type")
        {
            Caption = 'Feed Type';
            ToolTip = 'Specifies the feed type for the corporate card provider.';
        }
        field(5; "Auth Type"; Enum "EA Corp Card Auth Type")
        {
            Caption = 'Authentication Type';
            ToolTip = 'Specifies the authentication type for the corporate card provider.';
        }
        field(6; "Data Exch Def Code"; Code[20])
        {
            Caption = 'Data Exchange Definition Code';
            TableRelation = "Data Exch. Def";
            ToolTip = 'Specifies the data exchange definition code for the corporate card provider.';
        }
        field(7; "Data Exch Map Code"; Code[20])
        {
            Caption = 'Data Exchange Mapping Code';
            ToolTip = 'Specifies the data exchange mapping code for the corporate card provider.';
        }
        field(8; "API Endpoint"; Text[250])
        {
            Caption = 'API Endpoint';
            ToolTip = 'Specifies the API endpoint for the corporate card provider.';
        }
        field(9; "Secret Ref"; Text[250])
        {
            Caption = 'Secret Reference';
            ToolTip = 'Specifies the secret reference for the corporate card provider.';
        }
        field(10; "Import Frequency (Min)"; Integer)
        {
            Caption = 'Import Frequency (Min.)';
            MinValue = 0;
            ToolTip = 'Specifies the import frequency in minutes for the corporate card provider.';
        }
        field(11; "Last Import DT"; DateTime)
        {
            Caption = 'Last Import Date-Time';
            Editable = false;
            ToolTip = 'Specifies the date and time of the last import for the corporate card provider.';
        }
        field(12; "Last Batch No."; Integer)
        {
            Caption = 'Last Batch No.';
            Editable = false;
            ToolTip = 'Specifies the last batch number for the corporate card provider.';
        }
        field(13; "Source File Name"; Text[250])
        {
            Caption = 'Source File Name';
            ToolTip = 'Specifies the source file name for the corporate card provider.';
        }
        field(14; "Source Payload"; Blob)
        {
            Caption = 'Source Payload';
            Subtype = Memo;
            ToolTip = 'Specifies the source payload for the corporate card provider.';
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

    local procedure HasRelatedData(): Boolean
    var
        CorpCard: Record "EA Corp Card";
        CorpCardBatch: Record "EA Corp Card Batch";
        CorpCardTrans: Record "EA Corp Card Trans";
        DataExch: Record "Data Exch.";
        JobQueueEntry: Record "Job Queue Entry";
    begin
        CorpCard.SetRange("Provider Code", Code);
        if not CorpCard.IsEmpty() then
            exit(true);

        CorpCardBatch.SetRange("Provider Code", Code);
        if not CorpCardBatch.IsEmpty() then
            exit(true);

        CorpCardTrans.SetRange("Provider Code", Code);
        if not CorpCardTrans.IsEmpty() then
            exit(true);

        if "Data Exch Def Code" <> '' then
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
        CorpCardBatch: Record "EA Corp Card Batch";
        CorpCardException: Record "EA Corp Card Exception";
        CorpCardTrans: Record "EA Corp Card Trans";
        CorpCardTransDetail: Record "EA Corp Card Trans Detail";
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchColumnDef: Record "Data Exch. Column Def";
        DataExchMapping: Record "Data Exch. Mapping";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("Record ID to Process", RecordId);
        JobQueueEntry.DeleteAll(true);

        DataExch.SetRange("Related Record", RecordId);
        DataExch.DeleteAll(true);

        CorpCardBatch.SetRange("Provider Code", Code);
        if CorpCardBatch.FindSet() then
            repeat
                CorpCardTrans.SetRange("Batch No.", CorpCardBatch."Batch No.");
                CorpCardTrans.SetRange("Provider Code", Code);
                if CorpCardTrans.FindSet() then
                    repeat
                        CorpCardTransDetail.SetRange("Trans Entry No.", CorpCardTrans."Entry No.");
                        CorpCardTransDetail.DeleteAll(true);

                        CorpCardException.SetRange("Trans Entry No.", CorpCardTrans."Entry No.");
                        CorpCardException.DeleteAll(true);
                    until CorpCardTrans.Next() = 0;

                CorpCardTrans.DeleteAll(true);
                CorpCardException.SetRange("Batch No.", CorpCardBatch."Batch No.");
                CorpCardException.DeleteAll(true);
                CorpCardBatch.Delete(true);
            until CorpCardBatch.Next() = 0;

        CorpCard.SetRange("Provider Code", Code);
        CorpCard.DeleteAll(true);

        if "Data Exch Def Code" <> '' then begin
            DataExchFieldMapping.SetRange("Data Exch. Def Code", "Data Exch Def Code");
            DataExchFieldMapping.DeleteAll(true);

            DataExchMapping.SetRange("Data Exch. Def Code", "Data Exch Def Code");
            DataExchMapping.DeleteAll(true);

            DataExchColumnDef.SetRange("Data Exch. Def Code", "Data Exch Def Code");
            DataExchColumnDef.DeleteAll(true);

            DataExchLineDef.SetRange("Data Exch. Def Code", "Data Exch Def Code");
            DataExchLineDef.DeleteAll(true);

            if DataExchDef.Get("Data Exch Def Code") then
                DataExchDef.Delete(true);
        end;
    end;

    var
        DeleteProviderWithRelatedDataQst: Label 'Provider %1 has related corp card data or setup. Do you want to delete the provider and all related records?', Comment = '%1 = Provider code';
        DeleteProviderCanceledErr: Label 'Deletion canceled.';
}