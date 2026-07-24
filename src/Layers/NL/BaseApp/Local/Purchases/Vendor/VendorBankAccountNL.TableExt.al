// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Vendor;

using Microsoft.Foundation.Address;
using Microsoft.Utilities;

tableextension 11302 VendorBankAccountNL extends "Vendor Bank Account"
{
    fields
    {
        field(11000000; "Account Holder Name"; Text[100])
        {
            Caption = 'Account Holder Name';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(11000001; "Account Holder Address"; Text[100])
        {
            Caption = 'Account Holder Address';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(11000002; "Account Holder Post Code"; Code[20])
        {
            Caption = 'Account Holder Post Code';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = if ("Acc. Hold. Country/Region Code" = const('')) "Post Code"
            else
            if ("Acc. Hold. Country/Region Code" = filter(<> '')) "Post Code" where("Country/Region Code" = field("Acc. Hold. Country/Region Code"));
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                PostCode.ValidatePostCode("Account Holder City", "Account Holder Post Code", County, "Acc. Hold. Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(11000003; "Account Holder City"; Text[30])
        {
            Caption = 'Account Holder City';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = if ("Acc. Hold. Country/Region Code" = const('')) "Post Code".City
            else
            if ("Acc. Hold. Country/Region Code" = filter(<> '')) "Post Code".City where("Country/Region Code" = field("Acc. Hold. Country/Region Code"));
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                PostCode.ValidateCity("Account Holder City", "Account Holder Post Code", County, "Acc. Hold. Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(11000004; "Acc. Hold. Country/Region Code"; Code[10])
        {
            Caption = 'Acc. Hold. Country/Region Code';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "Country/Region";
        }
        field(11000005; "National Bank Code"; Code[10])
        {
            Caption = 'National Bank Code';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(11000007; "Abbrev. National Bank Code"; Code[3])
        {
            Caption = 'Abbrev. National Bank Code';
            DataClassification = EndUserIdentifiableInformation;
        }

        modify("Bank Account No.")
        {
            trigger OnAfterValidate()
            var
                LocalFunctionalityMgt: Codeunit "Local Functionality Mgt.";
            begin
                if not LocalFunctionalityMgt.CheckBankAccNo("Bank Account No.", "Country/Region Code", "Bank Account No.") then
                    Message(BankAccNoMayBeIncorrectMsg, "Bank Account No.");
            end;
        }
    }

    trigger OnInsert()
    var
        Vendor: Record Vendor;
    begin
        Vendor.SetLoadFields(Name, Address, "Post Code", City, "Country/Region Code");
        Vendor.Get("Vendor No.");
        "Account Holder Name" := Vendor.Name;
        "Account Holder Address" := Vendor.Address;
        "Account Holder Post Code" := Vendor."Post Code";
        "Account Holder City" := Vendor.City;
        "Acc. Hold. Country/Region Code" := Vendor."Country/Region Code";
    end;

    var
        PostCode: Record "Post Code";
        BankAccNoMayBeIncorrectMsg: Label 'Bank Account No. %1 may be incorrect.';
}
