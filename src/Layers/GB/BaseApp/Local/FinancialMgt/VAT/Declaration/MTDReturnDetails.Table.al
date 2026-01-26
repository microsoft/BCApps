#if not CLEANSCHEMA28 
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

table 10535 "MTD-Return Details"
{
    Caption = 'Submitted VAT Return';
    ObsoleteReason = 'Moved to extension';
    ObsoleteState = Removed;
    ObsoleteTag = '28.0';

    DataClassification = CustomerContent;

    fields
    {
        field(1; "Start Date"; Date)
        {
            Caption = 'Start Date';
        }
        field(2; "End Date"; Date)
        {
            Caption = 'End Date';
        }
        field(3; "Period Key"; Code[10])
        {
            Caption = 'Period Key';
        }
        field(4; "VAT Due Sales"; Decimal)
        {
            Caption = 'VAT Due Sales';
        }
        field(5; "VAT Due Acquisitions"; Decimal)
        {
            Caption = 'VAT Due Acquisitions';
        }
        field(6; "Total VAT Due"; Decimal)
        {
            Caption = 'Total VAT Due';
        }
        field(7; "VAT Reclaimed Curr Period"; Decimal)
        {
            Caption = 'VAT Reclaimed Curr Period';
        }
        field(8; "Net VAT Due"; Decimal)
        {
            Caption = 'Net VAT Due';
        }
        field(9; "Total Value Sales Excl. VAT"; Decimal)
        {
            Caption = 'Total Value Sales Excl. VAT';
        }
        field(10; "Total Value Purchases Excl.VAT"; Decimal)
        {
            Caption = 'Total Value Purchases Excl.VAT';
        }
        field(11; "Total Value Goods Suppl. ExVAT"; Decimal)
        {
            Caption = 'Total Value Goods Suppl. ExVAT';
        }
        field(12; "Total Acquisitions Excl. VAT"; Decimal)
        {
            Caption = 'Total Acquisitions Excl. VAT';
        }
        field(13; Finalised; Boolean)
        {
            Caption = 'Finalised';
        }
    }

    keys
    {
        key(Key1; "Start Date", "End Date")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

 
#endif