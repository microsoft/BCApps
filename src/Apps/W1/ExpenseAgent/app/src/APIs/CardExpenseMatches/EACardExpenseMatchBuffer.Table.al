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
            ToolTip = 'Specifies the identifier of the match request.';
        }
        field(2; "Expense User SystemId"; Guid)
        {
            Caption = 'Expense User System Id';
            ToolTip = 'Specifies the expense user whose card expenses are searched.';
        }
        field(10; "Expense Date"; Date)
        {
            Caption = 'Expense Date';
            ToolTip = 'Specifies the date on the receipt.';
        }
        field(11; Amount; Decimal)
        {
            Caption = 'Amount';
            ToolTip = 'Specifies the total amount on the receipt.';
            AutoFormatType = 1;
            AutoFormatExpression = Rec."Currency Code";
        }
        field(12; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            ToolTip = 'Specifies the currency on the receipt. Leave blank for the local currency.';
        }
        field(13; "Merchant Name"; Text[100])
        {
            Caption = 'Merchant Name';
            ToolTip = 'Specifies the merchant name on the receipt.';
        }
        field(20; "Expense SystemId"; Guid)
        {
            Caption = 'Expense System Id';
            ToolTip = 'Specifies the card expense to check the receipt against. Leave blank to find the best match. Returns the matching card expense, or an empty GUID when there is no match.';
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
