// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

table 7420 "EA Card Expense Match Buffer"
{
    Access = Internal;
    TableType = Temporary;
    Caption = 'Card Expense Match Buffer';
    DataClassification = CustomerContent;

    fields
    {
        field(1; Id; Guid)
        {
            Caption = 'Id';
        }
        field(2; "Expense User SystemId"; Guid)
        {
            Caption = 'Expense User System Id';
        }
        field(10; "Expense Date"; Date)
        {
            Caption = 'Expense Date';
        }
        field(11; Amount; Decimal)
        {
            Caption = 'Amount';
            AutoFormatType = 1;
            AutoFormatExpression = Rec."Currency Code";
        }
        field(12; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
        }
        field(13; "Merchant Name"; Text[100])
        {
            Caption = 'Merchant Name';
        }
        field(20; "Expense SystemId"; Guid)
        {
            Caption = 'Expense System Id';
        }
    }

    keys
    {
        key(PK; Id)
        {
            Clustered = true;
        }
    }
}
