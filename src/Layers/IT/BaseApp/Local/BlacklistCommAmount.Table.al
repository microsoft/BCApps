// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft;

table 12194 "Blacklist Comm. Amount"
{
    Caption = 'Blacklist Comm. Amount';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Start Date"; Date)
        {
            Caption = 'Start Date';
            NotBlank = true;
        }
        field(2; "Threshold Amount"; Decimal)
        {
            Caption = 'Threshold Amount';
        }
    }

    keys
    {
        key(Key1; "Start Date")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    [Scope('OnPrem')]
    procedure GetAmountAtDate(Date: Date): Decimal
    begin
        Reset();
        SetFilter("Start Date", '<=%1', Date);
        if FindLast() then
            exit("Threshold Amount");
        exit(0);
    end;
}

