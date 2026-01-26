// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.ElectronicFundsTransfer;

using Microsoft.Purchases.Payables;

table 11609 "EFT Register"
{
    Caption = 'EFT Register';
    DrillDownPageID = "EFT Register";
    LookupPageID = "EFT Register";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Integer)
        {
            Caption = 'No.';
            NotBlank = true;
        }
        field(2; "EFT Payment"; Boolean)
        {
            Caption = 'EFT Payment';
        }
        field(3; "File Created"; Date)
        {
            Caption = 'File Created';
        }
        field(4; "Total Amount (LCY)"; Decimal)
        {
            Caption = 'Total Amount (LCY)';
        }
        field(5; Time; Time)
        {
            Caption = 'Time';
        }
        field(6; "File Description"; Text[12])
        {
            Caption = 'File Description';
        }
        field(7; "Bank Account Code"; Code[20])
        {
            Caption = 'Bank Account Code';
        }
        field(8; Canceled; Boolean)
        {
            Caption = 'Canceled';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        VendLedgerEntry.SetCurrentKey("EFT Register No.");
        VendLedgerEntry.SetRange("EFT Register No.", "No.");
        if VendLedgerEntry.FindFirst() then
            Error(Text11000, TableCaption(), FieldCaption("No."), VendLedgerEntry.TableCaption());
    end;

    var
        VendLedgerEntry: Record "Vendor Ledger Entry";
        Text11000: Label 'You cannot delete %1 %2 because there is at least one %3 associated with it.', Comment = '%1=table caption, %2=field value, %3=table caption';
}

