// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.Currency;
using Microsoft.Purchases.Vendor;

table 32000004 "Ref. Payment - Exported Buffer"
{
    Caption = 'Ref. Payment - Exported Buffer';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Integer)
        {
            Caption = 'No.';
        }
        field(2; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            TableRelation = Vendor."No.";
        }
        field(4; "Payment Account"; Code[20])
        {
            Caption = 'Payment Account';
            TableRelation = "Bank Account"."No.";
        }
        field(6; "Payment Date"; Date)
        {
            Caption = 'Payment Date';
        }
        field(7; "Document Type"; Option)
        {
            Caption = 'Document Type';
            OptionCaption = ' ,Invoice,Credit Memo';
            OptionMembers = " ",Invoice,"Credit Memo";
        }
        field(9; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency.Code;
        }
        field(10; Amount; Decimal)
        {
            Caption = 'Amount';
        }
        field(11; "Amount (LCY)"; Decimal)
        {
            Caption = 'Amount (LCY)';
        }
        field(12; "Vendor Account"; Code[20])
        {
            Caption = 'Vendor Account';
            TableRelation = "Vendor Bank Account".Code where("Vendor No." = field("Vendor No."));
        }
        field(13; "Message Type"; Option)
        {
            Caption = 'Message Type';
            InitValue = "Reference No.";
            OptionCaption = 'Reference No.,Invoice Information,Message,Long Message,Tax Message';
            OptionMembers = "Reference No.","Invoice Information",Message,"Long Message","Tax Message";
        }
        field(21; "Foreign Payment"; Boolean)
        {
            Caption = 'Foreign Payment';
            Editable = false;
        }
        field(31; "Affiliated to Line"; Integer)
        {
            Caption = 'Affiliated to Line';
        }
        field(36; "SEPA Payment"; Boolean)
        {
            Caption = 'SEPA Payment';
        }
    }

    keys
    {
        key(Key1; "Vendor No.", "Payment Account", "Currency Code", "Payment Date")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure AddLine(RefPmtExported: Record "Ref. Payment - Exported"): Integer
    begin
        TransferFields(RefPmtExported);
        if Find() then begin
            if "Affiliated to Line" = 0 then
                "Affiliated to Line" := RefPmtExported."No.";
            "No." := 0;
            Amount += RefPmtExported.Amount;
            "Amount (LCY)" += RefPmtExported."Amount (LCY)";
            Modify();
        end else begin
            "Affiliated to Line" := RefPmtExported."No.";
            "Message Type" := "Message Type"::Message;
            Insert();
        end;
        exit("Affiliated to Line");
    end;
}

