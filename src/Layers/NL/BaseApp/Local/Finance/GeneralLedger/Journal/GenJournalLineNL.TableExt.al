// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

using Microsoft.Bank.Payment;

tableextension 11384 "Gen. Journal Line NL" extends "Gen. Journal Line"
{
    fields
    {
        field(11000000; "Transaction Mode Code"; Code[20])
        {
            Caption = 'Transaction Mode Code';
            DataClassification = CustomerContent;
            TableRelation = if ("Account Type" = const(Customer)) "Transaction Mode".Code where("Account Type" = const(Customer))
            else
            if ("Account Type" = const(Vendor)) "Transaction Mode".Code where("Account Type" = const(Vendor))
            else
            if ("Account Type" = const(Employee)) "Transaction Mode".Code where("Account Type" = const(Employee))
            else
            if ("Bal. Account Type" = const(Customer)) "Transaction Mode".Code where("Account Type" = const(Customer))
            else
            if ("Bal. Account Type" = const(Vendor)) "Transaction Mode".Code where("Account Type" = const(Vendor))
            else
            if ("Bal. Account Type" = const(Employee)) "Transaction Mode".Code where("Account Type" = const(Employee));

            trigger OnValidate()
            var
                TrMode: Record "Transaction Mode";
            begin
                if "Transaction Mode Code" <> '' then begin
                    case "Account Type" of
                        "Account Type"::Customer:
                            TrMode.Get(TrMode."Account Type"::Customer, "Transaction Mode Code");
                        "Account Type"::Vendor:
                            TrMode.Get(TrMode."Account Type"::Vendor, "Transaction Mode Code");
                        "Account Type"::Employee:
                            TrMode.Get(TrMode."Account Type"::Employee, "Transaction Mode Code");
                        else
                            case "Bal. Account Type" of
                                "Bal. Account Type"::Customer:
                                    TrMode.Get(TrMode."Account Type"::Customer, "Transaction Mode Code");
                                "Bal. Account Type"::Vendor:
                                    TrMode.Get(TrMode."Account Type"::Vendor, "Transaction Mode Code");
                                "Bal. Account Type"::Employee:
                                    TrMode.Get(TrMode."Account Type"::Employee, "Transaction Mode Code");
                                else
                                    Error(
                                      Text1000000, FieldCaption("Transaction Mode Code"), FieldCaption("Account Type"), FieldCaption("Bal. Account Type"));
                            end;
                    end;

                    if TrMode."Payment Terms Code" <> '' then
                        Validate("Payment Terms Code", TrMode."Payment Terms Code");
                end;
            end;
        }
    }

    var
        Text1000000: Label '%1 can only be filled in when %2 %3 is equal to Customer or Vendor.';
}

