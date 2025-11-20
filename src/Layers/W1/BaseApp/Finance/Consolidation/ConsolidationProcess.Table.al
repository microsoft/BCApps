// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Consolidation;

table 1830 "Consolidation Process"
{
    Caption = 'Consolidation Process';
    ReplicateData = false;
    Extensible = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; Id; Integer)
        {
            AutoIncrement = true;
            DataClassification = SystemMetadata;
        }
        field(2; Status; Option)
        {
            OptionMembers = NotStarted,InProgress,Failed,Completed;
            OptionCaption = 'Not started,In Progress,Failed,Completed';
            DataClassification = SystemMetadata;
        }
        field(3; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
            ClosingDates = true;
            DataClassification = CustomerContent;
        }
        field(4; "Ending Date"; Date)
        {
            Caption = 'Ending Date';
            ClosingDates = true;
            DataClassification = CustomerContent;
        }
        field(5; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            DataClassification = CustomerContent;
        }
        field(6; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
            DataClassification = CustomerContent;
        }
        field(7; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            DataClassification = CustomerContent;
        }
        field(8; "Parent Currency Code"; Code[10])
        {
            Caption = 'Parent Currency Code';
            DataClassification = CustomerContent;
        }
        field(9; "Dimensions to Transfer"; Text[250])
        {
            Caption = 'Dimensions to Transfer';
            DataClassification = CustomerContent;
        }
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
