// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.BankAccount;

using Microsoft.Finance.Currency;
using Microsoft.Foundation.Company;

table 422 "IC Bank Account"
{
    Caption = 'IC Bank Account';
    LookupPageID = "IC Bank Account List";
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(2; "IC Partner Code"; Code[20])
        {
            Caption = 'Partner Code';
        }
        field(3; Name; Text[100])
        {
            Caption = 'Name';
        }
        field(4; "Bank Account No."; Text[30])
        {
            Caption = 'Bank Account No.';
        }
        field(5; Blocked; Boolean)
        {
            Caption = 'Blocked';
        }
        field(6; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(7; IBAN; Code[50])
        {
            Caption = 'IBAN';

            trigger OnValidate()
            var
                CompanyInfo: Record "Company Information";
            begin
                CompanyInfo.CheckIBAN(IBAN);
            end;
        }
    }

    keys
    {
        key(Key1; "No.", "IC Partner Code")
        {
            Clustered = true;
        }
    }
}

