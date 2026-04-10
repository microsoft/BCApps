// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Activity;

table 7390 "Create Pick Parameters"
{
    Caption = 'Create Pick Parameters';
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
            DataClassification = SystemMetadata;
        }
        field(2; "Assigned ID"; Code[50])
        {
            Caption = 'Assigned ID';
            DataClassification = SystemMetadata;
        }
        field(3; "Whse. Document"; Option)
        {
            Caption = 'Whse. Document';
            OptionCaption = 'Pick Worksheet,Shipment,Movement Worksheet,Internal Pick,Production,Assembly,Project';
            OptionMembers = "Pick Worksheet",Shipment,"Movement Worksheet","Internal Pick",Production,Assembly,Job;
            DataClassification = SystemMetadata;
        }
        field(4; "Sorting Method"; Enum "Whse. Activity Sorting Method")
        {
            Caption = 'Sorting Method';
            DataClassification = SystemMetadata;
        }
        field(5; "Whse. Document Type"; Option)
        {
            Caption = 'Whse. Document Type';
            OptionMembers = "Put-away",Pick,Movement;
            DataClassification = SystemMetadata;
        }
        field(6; "Max No. of Source Doc."; Integer)
        {
            Caption = 'Max No. of Source Doc.';
            DataClassification = SystemMetadata;
        }
        field(7; "Max No. of Lines"; Integer)
        {
            Caption = 'Max No. of Lines';
            DataClassification = SystemMetadata;
        }
        field(8; "Per Zone"; Boolean)
        {
            Caption = 'Per Zone';
            DataClassification = SystemMetadata;
        }
        field(9; "Do Not Fill Qty. to Handle"; Boolean)
        {
            Caption = 'Do Not Fill Qty. to Handle';
            DataClassification = SystemMetadata;
        }
        field(10; "Breakbulk Filter"; Boolean)
        {
            Caption = 'Breakbulk Filter';
            DataClassification = SystemMetadata;
        }
        field(11; "Per Bin"; Boolean)
        {
            Caption = 'Per Bin';
            DataClassification = SystemMetadata;
        }
    }
}
