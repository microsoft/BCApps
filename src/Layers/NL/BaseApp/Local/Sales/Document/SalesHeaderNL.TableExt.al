// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Bank.Payment;
using Microsoft.Foundation.Company;
using Microsoft.Sales.Customer;

/// <summary>
/// Extends the Sales Header table with NL-specific telebanking fields.
/// </summary>
tableextension 11465 "Sales Header NL" extends "Sales Header"
{
    fields
    {
        /// <summary>
        /// Specifies the transaction mode used in telebanking for this sales document.
        /// </summary>
        field(11000000; "Transaction Mode Code"; Code[20])
        {
            Caption = 'Transaction Mode Code';
            DataClassification = CustomerContent;
            TableRelation = "Transaction Mode".Code where("Account Type" = const(Customer));

            trigger OnValidate()
            var
                TrMode: Record "Transaction Mode";
            begin
                if not IsDutchCompany() then
                    exit;

                if "Transaction Mode Code" <> '' then begin
                    TrMode.Get(TrMode."Account Type"::Customer, "Transaction Mode Code");
                    if TrMode."Payment Method Code" <> '' then
                        Validate("Payment Method Code", TrMode."Payment Method Code");
                    if TrMode."Payment Terms Code" <> '' then
                        Validate("Payment Terms Code", TrMode."Payment Terms Code");
                end;
            end;
        }
        /// <summary>
        /// Specifies the customer's bank account used for payments and collections through telebanking.
        /// </summary>
        field(11000001; "Bank Account Code"; Code[20])
        {
            Caption = 'Bank Account Code';
            DataClassification = CustomerContent;
            TableRelation = "Customer Bank Account".Code where("Customer No." = field("Bill-to Customer No."));
        }
    }

    local procedure IsDutchCompany(): Boolean
    var
        CompanyInformation: Record "Company Information";
    begin
        exit(CompanyInformation.Get() and (CompanyInformation."Country/Region Code" = 'NL'));
    end;
}
