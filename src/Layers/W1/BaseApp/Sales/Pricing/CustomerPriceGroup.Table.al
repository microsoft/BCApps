// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Pricing;

using Microsoft.Finance.VAT.Setup;
using Microsoft.Integration.Dataverse;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.Pricing.Source;
using Microsoft.Sales.Setup;

/// <summary>
/// Stores customer price groups that define shared pricing rules for multiple customers, including VAT handling and discount settings.
/// </summary>
table 6 "Customer Price Group"
{
    Caption = 'Customer Price Group';
    LookupPageID = "Customer Price Groups";
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Specifies the unique code that identifies the customer price group.
        /// </summary>
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            ToolTip = 'Specifies a code to identify the price group.';
            NotBlank = true;
        }
        /// <summary>
        /// Indicates whether sales prices for customers in this group include VAT.
        /// </summary>
        field(2; "Price Includes VAT"; Boolean)
        {
            Caption = 'Price Includes VAT';
            ToolTip = 'Specifies whether the prices given for this price group will include VAT.';

            trigger OnValidate()
            var
                SalesSetup: Record "Sales & Receivables Setup";
            begin
                if "Price Includes VAT" then begin
                    SalesSetup.Get();
                    if SalesSetup."VAT Bus. Posting Gr. (Price)" <> '' then
                        Validate("VAT Bus. Posting Gr. (Price)", SalesSetup."VAT Bus. Posting Gr. (Price)");
                end;
            end;
        }
        /// <summary>
        /// Indicates whether invoice discounts can be applied to sales for customers in this price group.
        /// </summary>
        field(5; "Allow Invoice Disc."; Boolean)
        {
            Caption = 'Allow Invoice Disc.';
            ToolTip = 'Specifies whether the ordinary invoice discount calculation will apply to customers in this price group.';
            InitValue = true;
        }
        /// <summary>
        /// Specifies the VAT business posting group used for price calculations when prices include VAT.
        /// </summary>
        field(6; "VAT Bus. Posting Gr. (Price)"; Code[20])
        {
            Caption = 'VAT Bus. Posting Gr. (Price)';
            TableRelation = "VAT Business Posting Group";
        }
        /// <summary>
        /// Specifies a description of the customer price group.
        /// </summary>
        field(10; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the description of the customer price group.';
        }
#if not CLEANSCHEMA26
        field(720; "Coupled to CRM"; Boolean)
        {
            Caption = 'Coupled to Dynamics 365 Sales';
            Editable = false;
            ObsoleteReason = 'Replaced by flow field Coupled to Dataverse';
            ObsoleteState = Removed;
            ObsoleteTag = '26.0';
        }
#endif
        /// <summary>
        /// Indicates whether the customer price group is coupled to a record in Dynamics 365 Sales.
        /// </summary>
        field(721; "Coupled to Dataverse"; Boolean)
        {
            FieldClass = FlowField;
            Caption = 'Coupled to Dynamics 365 Sales';
            ToolTip = 'Specifies that the customer price group is coupled to a price list in Dynamics 365 Sales.';
            Editable = false;
            CalcFormula = exist("CRM Integration Record" where("Integration ID" = field(SystemId), "Table ID" = const(Database::"Customer Price Group")));
        }
        /// <summary>
        /// Specifies the method used to calculate sales prices for customers in this price group.
        /// </summary>
        field(7000; "Price Calculation Method"; Enum "Price Calculation Method")
        {
            Caption = 'Price Calculation Method';
            ToolTip = 'Specifies the price calculation method that will override the method set in the sales setup for customers in this group.';

            trigger OnValidate()
            var
                PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
                PriceType: Enum "Price Type";
            begin
                if "Price Calculation Method" <> "Price Calculation Method"::" " then
                    PriceCalculationMgt.VerifyMethodImplemented("Price Calculation Method", PriceType::Sale);
            end;
        }
        /// <summary>
        /// Indicates whether line discounts can be applied to sales for customers in this price group.
        /// </summary>
        field(7001; "Allow Line Disc."; Boolean)
        {
            Caption = 'Allow Line Disc.';
            ToolTip = 'Specifies if a line discount will be calculated when the sales price is offered.';
            InitValue = true;
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
        key(Key2; SystemModifiedAt)
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Code", Description, "Allow Invoice Disc.", "Allow Line Disc.")
        {
        }
    }

    /// <summary>
    /// Converts this customer price group to a price source record.
    /// </summary>
    /// <param name="PriceSource">The price source record to populate.</param>
    procedure ToPriceSource(var PriceSource: Record "Price Source")
    begin
        PriceSource.Init();
        PriceSource."Price Type" := PriceSource."Price Type"::Sale;
        PriceSource.Validate("Source Type", PriceSource."Source Type"::"Customer Price Group");
        PriceSource.Validate("Source No.", Code);
    end;
}

