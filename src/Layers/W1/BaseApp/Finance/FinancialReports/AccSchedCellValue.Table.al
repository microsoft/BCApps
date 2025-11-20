// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

table 342 "Acc. Sched. Cell Value"
{
    Caption = 'Acc. Sched. Cell Value';
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Row No."; Integer)
        {
            Caption = 'Row No.';
        }
        field(2; "Column No."; Integer)
        {
            Caption = 'Column No.';
        }
        field(3; Value; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Value';
        }
        field(4; "Has Error"; Boolean)
        {
            Caption = 'Has Error';
        }
        field(5; "Period Error"; Boolean)
        {
            Caption = 'Period Error';
        }
    }

    keys
    {
        key(Key1; "Row No.", "Column No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}
