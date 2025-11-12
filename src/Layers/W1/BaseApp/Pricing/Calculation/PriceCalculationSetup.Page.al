// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Pricing.Calculation;

page 7006 "Price Calculation Setup"
{
    Caption = 'Price Calculation Implementations';
    PageType = List;
    SourceTable = "Price Calculation Setup";
    DeleteAllowed = false;
    InsertAllowed = false;
    DataCaptionFields = Method, Type, "Asset Type";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    Visible = false;
                    ToolTip = 'Specifies a code that you can select.';
                }
                field(Details; Rec.Details)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the count of detailed price calculation setup records.';
                }
                field(CalculationMethod; Rec.Method)
                {
                    ApplicationArea = Suite;
                    Visible = false;
                    Editable = false;
                    ToolTip = 'Specifies a price calculation method.';
                }
                field(PriceType; Rec.Type)
                {
                    ApplicationArea = Suite;
                    Visible = false;
                    Editable = false;
                    ToolTip = 'Specifies what type of amount to calculate - price or cost.';
                }
                field(AssetType; Rec."Asset Type")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                    Editable = false;
                    ToolTip = 'Specifies an asset type.';
                }
                field(Implementation; Rec.Implementation)
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    ToolTip = 'Specifies a codeunit that can implement the calculation method.';
                }
                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    ToolTip = 'Specifies whether the implementation codeunit is enabled.';
                }
                field(DefaultImpl; Rec.Default)
                {
                    Visible = false;
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies if this is the default implementation. You cannot remove the Default check mark, instead pick another record for the same calculation method to become the default implementation.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    trigger OnOpenPage()
    var
        FeaturePriceCalculation: Codeunit "Feature - Price Calculation";
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
    begin
        FeaturePriceCalculation.FailIfFeatureDisabled();
        if PriceCalculationMgt.RefreshSetup() then
            Commit();
    end;
}