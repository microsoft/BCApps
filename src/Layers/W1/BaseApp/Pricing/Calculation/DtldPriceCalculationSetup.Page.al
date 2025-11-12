// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Pricing.Calculation;

using Microsoft.Pricing.PriceList;

page 7008 "Dtld. Price Calculation Setup"
{
    Caption = 'Exceptions for';
    DataCaptionExpression = Heading;
    PageType = List;
    SourceTable = "Dtld. Price Calculation Setup";
    DelayedInsert = true;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(SetupCode; Rec."Setup Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a price calculation setup code.';
                    Visible = IsSetupCodeVisible;
                }
                field(CalculationMethod; Rec.Method)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a price calculation method.';
                    Visible = IsSetupCodeVisible;
                }
                field(PriceType; Rec.Type)
                {
                    Visible = IsSetupCodeVisible;
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies what type of amount to calculate - sale or purchase.';
                }
                field(AssetType; Rec."Asset Type")
                {
                    Visible = IsAssetNoEditable;
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a product type.';
                }
                field(AssetNo; Rec."Asset No.")
                {
                    Visible = AssetVisible;
                    Editable = IsAssetNoEditable;
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a product number.';
                }
                field(ProductNo; Rec."Product No.")
                {
                    Visible = ProductVisible;
                    Editable = IsAssetNoEditable;
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a product number.';
                }
                field(SourceGroup; Rec."Source Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the prices come from groups of customers, vendors or projects.';
                }
                field(SourceNo; Rec."Source No.")
                {
                    Visible = UseCustomLookup;
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the unique identifier of the source of the price on the price list line.';
                }
                field(AssignToNo; Rec."Assign-to No.")
                {
                    Visible = not UseCustomLookup;
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the unique identifier of the source of the price on the price list line.';
                }
                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the implementation codeunit is enabled.';
                }
                field(Implementation; Rec.Implementation)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a price calculation implementation name.';
                    Editable = false;
                    AssistEdit = true;

                    trigger OnAssistEdit()
                    begin
                        PriceUXManagement.PickAlternateImplementation(Rec);
                    end;
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        PriceListLine: Record "Price List Line";
    begin
        UseCustomLookup := PriceListLine.UseCustomizedLookup();
        PriceUXManagement.TestAlternateImplementation(CurrPriceCalculationSetup);
        Rec.FilterGroup(2);
        Rec.SetRange("Group Id", CurrPriceCalculationSetup."Group Id");
        Rec.FilterGroup(0);

        AssetVisible := IsAssetNoEditable and UseCustomLookup;
        ProductVisible := IsAssetNoEditable and not UseCustomLookup;
        IsSetupCodeVisible := CurrPriceCalculationSetup.Code = '';
        IsAssetNoEditable := CurrPriceCalculationSetup."Asset Type" <> CurrPriceCalculationSetup."Asset Type"::" ";
        Heading :=
            StrSubstNo('%1 %2 (%3) %4',
                CurrPriceCalculationSetup.Type, CurrPriceCalculationSetup."Asset Type",
                CurrPriceCalculationSetup.Method, CurrPriceCalculationSetup.Implementation);
    end;

    trigger OnNewRecord(BelowXRec: Boolean)
    begin
        Rec.Validate("Setup Code", PriceUXManagement.GetFirstAlternateSetupCode(CurrPriceCalculationSetup));
    end;

    var
        CurrPriceCalculationSetup: Record "Price Calculation Setup";
        PriceUXManagement: Codeunit "Price UX Management";
        AssetVisible: Boolean;
        ProductVisible: Boolean;
        IsSetupCodeVisible: Boolean;
        IsAssetNoEditable: Boolean;
        UseCustomLookup: Boolean;
        Heading: text;

    procedure Set(PriceCalculationSetup: Record "Price Calculation Setup")
    begin
        CurrPriceCalculationSetup := PriceCalculationSetup;
    end;
}