// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Agents;

table 4349 "Agent AI Consumption Buffer"
{
    Access = Internal;
    TableType = Temporary;
    Caption = 'Agent AI Consumption';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; BigInteger) { Caption = 'Entry ID'; }
        field(2; "Task ID"; BigInteger) { Caption = 'Task ID'; }
        field(3; "Consumption DateTime"; DateTime) { Caption = 'Created at'; }
        field(4; "Resource Name"; Text[256]) { Caption = 'Resource name'; }
        field(5; "Company Name"; Text[30]) { Caption = 'Company name'; }
        field(6; "AI Credits"; Decimal)
        {
            Caption = 'AI credits';
            AutoFormatType = 0;
            DecimalPlaces = 0 : 2;
        }
        field(7; "Reporting State"; Text[30]) { Caption = 'Reporting state'; }
        field(8; "Pricing Pending"; Boolean) { Caption = 'Pricing pending'; }
        field(9; Description; Blob) { Caption = 'Description'; }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
        key(ConsumptionDate; "Consumption DateTime", Id) { }
    }
}
