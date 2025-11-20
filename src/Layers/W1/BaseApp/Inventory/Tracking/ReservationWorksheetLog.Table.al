// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

table 359 "Reservation Worksheet Log"
{
    Caption = 'Reservation Worksheet Log';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
            TableRelation = "Reservation Wksh. Batch";
        }
        field(2; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(17; "Record ID"; RecordId)
        {
            Caption = 'Record ID';
        }
        field(20; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
        }
    }

    keys
    {
        key(Key1; "Journal Batch Name", "Entry No.")
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    var
        ReservationWorksheetLog: Record "Reservation Worksheet Log";
    begin
        if "Entry No." = 0 then begin
            ReservationWorksheetLog.SetRange("Journal Batch Name", Rec."Journal Batch Name");
            if ReservationWorksheetLog.FindLast() then
                "Entry No." := ReservationWorksheetLog."Entry No.";
            "Entry No." += 1;
        end;
    end;
}
