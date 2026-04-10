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
                }
                field(Details; Rec.Details)
                {
                    ApplicationArea = Suite;
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
                }
                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = Suite;
                    Editable = false;
                }
                field(DefaultImpl; Rec.Default)
                {
                    Visible = false;
                    ApplicationArea = Suite;
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