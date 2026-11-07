// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Request;

using Microsoft.Manufacturing.Document;

tableextension 99000781 "Mfg. Warehouse Source Filter" extends "Warehouse Source Filter"
{
    fields
    {
        field(5401; "Prod. Order No."; Code[20])
        {
            Caption = 'Prod. Order No.';
            DataClassification = CustomerContent;
            TableRelation = "Production Order"."No." where(Status = const(Released));
        }
        field(99000754; "Prod. Order Line No. Filter"; Text[100])
        {
            Caption = 'Prod. Order Line No. Filter';
            DataClassification = CustomerContent;
            TableRelation = "Prod. Order Line"."Line No." where(Status = filter(Released),
                                                                 "Prod. Order No." = field("Prod. Order No."));
            ValidateTableRelation = false;
        }
    }
}
