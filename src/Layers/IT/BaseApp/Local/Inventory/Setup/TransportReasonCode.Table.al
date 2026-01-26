// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Setup;

using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.NoSeries;

table 12154 "Transport Reason Code"
{
    Caption = 'Transport Reason Code';
    LookupPageID = "Transport Reason Codes";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
        }
        field(2; Description; Text[50])
        {
            Caption = 'Description';
        }
        field(5; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        field(10; "Posted Shpt. Nos."; Code[20])
        {
            Caption = 'Posted Shpt. Nos.';
            TableRelation = "No. Series";
        }
        field(11; "Posted Rcpt. Nos."; Code[20])
        {
            Caption = 'Posted Rcpt. Nos.';
            TableRelation = "No. Series";
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Code", Description, "Reason Code")
        {
        }
    }
}

