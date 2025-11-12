// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.AllocationAccount;

using Microsoft.Finance.Dimension;

table 2673 "Alloc. Acc. Manual Override"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Parent Table Id"; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Parent Table Id';
        }
        field(2; "Parent System Id"; Guid)
        {
            DataClassification = CustomerContent;
            Caption = 'Parent System Id';
        }
        field(3; "Line No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Line No.';
        }
        field(5; "Destination Account Type"; Enum "Destination Account Type")
        {
            DataClassification = CustomerContent;
            Caption = 'Destination Account Type';
        }
        field(6; "Destination Account Number"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Destination Account Number';
        }
        field(8; Amount; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            DataClassification = CustomerContent;
            Caption = 'Amount';
        }
        field(9; "Allocation Account No."; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Allocation Account No.';
        }
        field(15; Percentage; Decimal)
        {
            AutoFormatType = 0;
            DataClassification = CustomerContent;
            Caption = 'Percentage';
        }
        field(20; Quantity; Decimal)
        {
            AutoFormatType = 0;
            DataClassification = SystemMetadata;
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(37; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1),
                                                          Blocked = const(false));
            DataClassification = CustomerContent;
        }
        field(38; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2),
                                                          Blocked = const(false));
            DataClassification = CustomerContent;
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(Key1; "Parent Table Id", "Parent System Id", "Line No.")
        {
            Clustered = true;
        }
    }
}
