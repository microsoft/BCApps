// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Pricing;

using Microsoft.Pricing.PriceList;
using Microsoft.Pricing.Source;
using Microsoft.Sales.Customer;

table 340 "Customer Discount Group"
{
    Caption = 'Customer Discount Group';
    LookupPageID = "Customer Disc. Groups";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(Brick; "Code", Description)
        {
        }
    }

    procedure ToPriceSource(var PriceSource: Record "Price Source")
    begin
        PriceSource.Init();
        PriceSource."Price Type" := "Price Type"::Sale;
        PriceSource.Validate("Source Type", PriceSource."Source Type"::"Customer Disc. Group");
        PriceSource.Validate("Source No.", Code);
    end;

    trigger OnDelete()
    var
        Customer: Record Customer;
    begin
        Customer.SetRange("Customer Disc. Group", Rec.Code);
        if not Customer.IsEmpty() then
            Error(CustDiscountGroupDeleteErr, Rec.Code);
    end;

    var
        CustDiscountGroupDeleteErr: Label 'You cannot delete the Customer Discount Group %1 because it is used in Customer.', Comment = '%1= Customer Discount Group Code.';

}

