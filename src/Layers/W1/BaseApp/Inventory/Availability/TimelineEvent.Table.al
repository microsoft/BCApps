// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Availability;

table 5540 "Timeline Event"
{
    Caption = 'Timeline Event';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Transaction Type"; Option)
        {
            Caption = 'Transaction Type';
            OptionCaption = 'None,Initial,Fixed Supply,Adjustable Supply,New Supply,Fixed Demand,Expected Demand';
            OptionMembers = "None",Initial,"Fixed Supply","Adjustable Supply","New Supply","Fixed Demand","Expected Demand";
        }
        field(3; Description; Text[250])
        {
            Caption = 'Description';
        }
        field(4; "Original Date"; Date)
        {
            Caption = 'Original Date';
        }
        field(5; "New Date"; Date)
        {
            Caption = 'New Date';
        }
        field(6; ChangeRefNo; Text[250])
        {
            Caption = 'ChangeRefNo';
        }
        field(9; "Source Line ID"; RecordID)
        {
            Caption = 'Source Line ID';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(10; "Source Document ID"; RecordID)
        {
            Caption = 'Source Document ID';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(20; "Original Quantity"; Decimal)
        {
            Caption = 'Original Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(21; "New Quantity"; Decimal)
        {
            Caption = 'New Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(1000; ID; Integer)
        {
            AutoIncrement = false;
            Caption = 'ID';
            MinValue = 0;
            NotBlank = true;
        }
    }

    keys
    {
        key(Key1; ID)
        {
            Clustered = true;
        }
        key(Key2; "New Date", ID)
        {
        }
    }

    fieldgroups
    {
    }
}

