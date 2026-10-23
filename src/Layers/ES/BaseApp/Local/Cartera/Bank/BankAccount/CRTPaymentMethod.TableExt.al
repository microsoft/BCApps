// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.BankAccount;

using Microsoft.Sales.Receivables;

tableextension 7000083 "CRT Payment Method" extends "Payment Method"
{
    fields
    {
        field(7000000; "Create Bills"; Boolean)
        {
            Caption = 'Create Bills';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if "Invoices to Cartera" and "Create Bills" then
                    Error(MustBeSetEqualToErr, FieldCaption("Invoices to Cartera"));
            end;
        }
        field(7000001; "Collection Agent"; Option)
        {
            Caption = 'Collection Agent';
            DataClassification = CustomerContent;
            OptionCaption = 'Direct,Bank';
            OptionMembers = Direct,Bank;
        }
        field(7000002; "Submit for Acceptance"; Boolean)
        {
            Caption = 'Submit for Acceptance';
            DataClassification = CustomerContent;
        }
        field(7000003; "Bill Type"; Enum "ES Bill Type")
        {
            Caption = 'Bill Type';
            DataClassification = CustomerContent;
        }
        field(7000004; "Invoices to Cartera"; Boolean)
        {
            Caption = 'Invoices to Cartera';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if "Create Bills" and "Invoices to Cartera" then
                    Error(MustBeSetEqualToErr, FieldCaption("Create Bills"));
            end;
        }
    }

    var
        MustBeSetEqualToErr: Label '%1 must be set equal to False', Comment = '%1 - field caption';
}