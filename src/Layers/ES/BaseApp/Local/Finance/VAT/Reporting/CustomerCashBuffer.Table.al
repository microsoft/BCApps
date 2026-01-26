// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

table 10743 "Customer Cash Buffer"
{
    Caption = 'Customer Cash Buffer';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "VAT Registration No."; Text[20])
        {
            Caption = 'VAT Registration No.';
            DataClassification = SystemMetadata;
        }
        field(2; "Operation Year"; Code[4])
        {
            Caption = 'Operation Year';
            DataClassification = SystemMetadata;
        }
        field(21; "Operation Amount"; Decimal)
        {
            Caption = 'Operation Amount';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "VAT Registration No.", "Operation Year")
        {
            Clustered = true;
            MaintainSIFTIndex = false;
        }
    }

    fieldgroups
    {
    }
}

