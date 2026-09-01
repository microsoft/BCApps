// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.TDS.TDSBase;

using Microsoft.Finance.TaxBase;
using Microsoft.Purchases.Vendor;

table 18698 "TDS Concessional Code Archive"
{
    Caption = 'TDS Concessional Code Archive';
    DrillDownPageId = "TDS Concessional Code Archives";
    LookupPageId = "TDS Concessional Code Archives";
    DataCaptionFields = "Vendor No.", "Section";

    fields
    {
        field(1; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            TableRelation = Vendor;
            DataClassification = CustomerContent;
        }
        field(2; Section; Code[10])
        {
            Caption = 'Section';
            DataClassification = CustomerContent;
        }
        field(3; "Concessional Code"; Code[10])
        {
            Caption = 'Concessional Code';
            TableRelation = "Concessional Code";
            DataClassification = CustomerContent;
        }
        field(4; "Certificate No."; Code[20])
        {
            Caption = 'Certificate No.';
            DataClassification = CustomerContent;
        }
        field(5; "Start Date"; Date)
        {
            Caption = 'Start Date';
            DataClassification = CustomerContent;
        }
        field(6; "End Date"; Date)
        {
            Caption = 'End Date';
            DataClassification = CustomerContent;
        }
        field(7; "Certificate Value"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Certificate Value';
            DataClassification = CustomerContent;
        }
        field(8; "Remaining Certificate Value"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Remaining Certificate Value';
            DataClassification = CustomerContent;
        }
        field(9; "Used Certificate Value"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Used Certificate Value';
            DataClassification = CustomerContent;
        }
        field(20; "Archived On"; DateTime)
        {
            Caption = 'Archived On';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(21; "Archived By"; Code[50])
        {
            Caption = 'Archived By';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Vendor No.", Section, "Concessional Code", "Certificate No.", "Start Date", "End Date")
        {
            Clustered = true;
        }
        key(ArchivedOn; "Archived On")
        {
        }
    }
}
