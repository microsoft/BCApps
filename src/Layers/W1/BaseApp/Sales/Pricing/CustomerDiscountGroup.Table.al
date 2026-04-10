// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Pricing;

using Microsoft.Pricing.PriceList;
using Microsoft.Pricing.Source;
using Microsoft.Sales.Customer;

/// <summary>
/// Stores customer discount groups that allow grouping customers for shared line discount rules.
/// </summary>
table 340 "Customer Discount Group"
{
    Caption = 'Customer Discount Group';
    LookupPageID = "Customer Disc. Groups";
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Specifies the unique code that identifies the customer discount group.
        /// </summary>
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            ToolTip = 'Specifies a code for the customer discount group.';
            NotBlank = true;
        }
        /// <summary>
        /// Specifies a description of the customer discount group.
        /// </summary>
        field(2; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description for the customer discount group.';
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

    /// <summary>
    /// Converts this customer discount group to a price source record.
    /// </summary>
    /// <param name="PriceSource">The price source record to populate.</param>
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

