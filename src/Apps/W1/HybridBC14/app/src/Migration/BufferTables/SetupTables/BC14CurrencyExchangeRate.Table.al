// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14;

table 50194 "BC14 Currency Exchange Rate"
{
    Caption = 'BC14 Currency Exchange Rate';
    DataClassification = CustomerContent;
    ReplicateData = false;
    Extensible = false;

    fields
    {
        field(1; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
        }
        field(2; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
        }
        field(3; "Exchange Rate Amount"; Decimal)
        {
            Caption = 'Exchange Rate Amount';
            DecimalPlaces = 1 : 15;
            AutoFormatType = 0;
            AutoFormatExpression = '<Precision,1:15><Standard Format,0>';
            MinValue = 0;
        }
        field(4; "Adjustment Exch. Rate Amount"; Decimal)
        {
            Caption = 'Adjustment Exch. Rate Amount';
            DecimalPlaces = 1 : 15;
            AutoFormatType = 0;
            AutoFormatExpression = '<Precision,1:15><Standard Format,0>';
            MinValue = 0;
        }
        field(5; "Relational Currency Code"; Code[10])
        {
            Caption = 'Relational Currency Code';
        }
        field(6; "Relational Exch. Rate Amount"; Decimal)
        {
            Caption = 'Relational Exch. Rate Amount';
            DecimalPlaces = 1 : 15;
            AutoFormatType = 0;
            AutoFormatExpression = '<Precision,1:15><Standard Format,0>';
            MinValue = 0;
        }
        field(7; "Relational Adjmt Exch Rate Amt"; Decimal)
        {
            Caption = 'Relational Adjmt Exch Rate Amt';
            DecimalPlaces = 1 : 15;
            AutoFormatType = 0;
            AutoFormatExpression = '<Precision,1:15><Standard Format,0>';
            MinValue = 0;
        }
        field(8; "Fix Exchange Rate Amount"; Option)
        {
            Caption = 'Fix Exchange Rate Amount';
            OptionMembers = Currency,"Relational Currency",Both;
            OptionCaption = 'Currency,Relational Currency,Both';
        }
    }

    keys
    {
        key(Key1; "Currency Code", "Starting Date")
        {
            Clustered = true;
        }
    }
}
