// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

table 387 "Allocation Policy"
{
    Caption = 'Allocation Policy';
    LookupPageId = "Allocation Policies";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Journal Batch Name"; Text[10])
        {
            Caption = 'Journal Batch Name';
            TableRelation = "Reservation Wksh. Batch";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; "Allocation Rule"; Enum "Allocation Rules Impl.")
        {
            Caption = 'Allocation Policy';
            NotBlank = true;
        }
    }

    keys
    {
        key(Key1; "Journal Batch Name", "Line No.")
        {
            Clustered = true;
        }
    }

    procedure GetAllocationPolicyDescription(): Text
    var
        AllocateReservation: Interface "Allocate Reservation";
    begin
        AllocateReservation := "Allocation Rule";
        exit(AllocateReservation.GetDescription());
    end;

    procedure GetNextLineNo(): Integer
    var
        AllocationPolicy: Record "Allocation Policy";
    begin
        AllocationPolicy.SetCurrentKey("Journal Batch Name", "Line No.");
        AllocationPolicy.SetRange("Journal Batch Name", Rec.GetRangeMin("Journal Batch Name"));
        if AllocationPolicy.FindLast() then
            exit(AllocationPolicy."Line No." + 1);

        exit(1);
    end;
}
