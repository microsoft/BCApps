// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance;

using Microsoft.Utilities;
using System.Utilities;

table 31129 "EET Entry Status Log CZL"
{
    Caption = 'EET Entry Status Log';
    DrillDownPageId = "EET Entry Status Log CZL";
    LookupPageId = "EET Entry Status Log CZL";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            ToolTip = 'Specifies the number of the status log entry.';
        }
        field(5; "EET Entry No."; Integer)
        {
            Caption = 'EET Entry No.';
            TableRelation = "EET Entry CZL";
            ToolTip = 'Specifies the number of the EET entry that the status change belongs to.';
        }
        field(10; Description; Text[250])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the description of the status change, for example the response of the EET service. Select the field to display the related errors and warnings.';

            trigger OnLookup()
            begin
                ShowErrorMessages();
            end;
        }
        field(20; Status; Enum "EET Status CZL")
        {
            Caption = 'Status';
            ToolTip = 'Specifies the state of the EET entry that the entry was changed to.';
        }
        field(25; "Changed At"; DateTime)
        {
            Caption = 'Changed At';
            ToolTip = 'Specifies the date and time when the status of the EET entry was changed.';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "EET Entry No.")
        {
        }
    }

    trigger OnInsert()
    begin
        LockTable();
        "Entry No." := GetLastEntryNo() + 1;
    end;

    trigger OnDelete()
    begin
        ClearErrorMessages();
    end;

    procedure GetLastEntryNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("Entry No.")))
    end;

    procedure SetErrorMessage(var TempErrorMessage: Record "Error Message" temporary)
    var
        ErrorMessage: Record "Error Message";
    begin
        if TempErrorMessage.FindSet() then
            repeat
                ErrorMessage := TempErrorMessage;
                ErrorMessage.ID := 0;
                ErrorMessage.Validate("Record ID", RecordId());
                ErrorMessage.Validate("Context Record ID", RecordId());
                ErrorMessage.Insert(true);
            until TempErrorMessage.Next() = 0;
    end;

    procedure ShowErrorMessages()
    var
        ErrorMessage: Record "Error Message";
    begin
        ErrorMessage.SetContext(Rec);
        ErrorMessage.ShowErrorMessages(false);
    end;

    procedure ClearErrorMessages()
    var
        ErrorMessage: Record "Error Message";
    begin
        ErrorMessage.SetRange("Context Record ID", RecordId);
        ErrorMessage.DeleteAll();
    end;
}

