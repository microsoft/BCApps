// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

table 375 "Dimension Code Amount Buffer"
{
    Caption = 'Dimension Code Amount Buffer';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Line Code"; Code[20])
        {
            Caption = 'Line Code';
            DataClassification = SystemMetadata;
        }
        field(2; "Column Code"; Code[20])
        {
            Caption = 'Column Code';
            DataClassification = SystemMetadata;
        }
        field(3; Amount; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Amount';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Line Code", "Column Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}
