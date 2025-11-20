// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Forecast;

page 99000921 "Demand Forecast Names"
{
    ApplicationArea = Planning;
    Caption = 'Demand Forecasts';
    PageType = List;
    SourceTable = "Production Forecast Name";
    UsageCategory = Lists;
    RefreshOnActivate = true;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Name; Rec.Name)
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the name of the demand forecast.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies a brief description of the demand forecast.';
                }
                field("View By"; Rec."View By")
                {
                    ApplicationArea = Planning;
                    Caption = 'View By';
                    ToolTip = 'Specifies by which period amounts are displayed.';
                    Visible = false;
                    Editable = false;
                }
                field("Quantity Type"; Rec."Quantity Type")
                {
                    ApplicationArea = Planning;
                    Caption = 'View as';
                    ToolTip = 'Specifies how amounts are displayed. Net Change: The net change in the balance for the selected period. Balance at Date: The balance as of the last day in the selected period.';
                    Visible = false;
                    Editable = false;
                }
                field("Forecast Type"; Rec."Forecast Type")
                {
                    ApplicationArea = Planning;
                    Caption = 'Forecast Type';
                    ToolTip = 'Specifies one of the following two types when you create a demand forecast entry: sales item or component item.';
                    Visible = false;
                    Editable = false;
                }
                field("Item Filter"; ItemFilter)
                {
                    ApplicationArea = Planning;
                    Caption = 'Item Filter';
                    ToolTip = 'Specifies an item filter to see specific items on the demand forecast matrix. Use this to reduce the demand forecast matrix entries.';
                    Visible = false;
                    Editable = false;
                }
                field("Forecast By Locations"; Rec."Forecast By Locations")
                {
                    ApplicationArea = Planning;
                    Caption = 'Forecast by Locations';
                    ToolTip = 'Use this if you want to create a forecast entry including the locations.';
                    Visible = false;
                    Editable = false;
                }
                field("Location Filter"; LocationFilter)
                {
                    ApplicationArea = Planning;
                    Caption = 'Location Filter';
                    ToolTip = 'Specifies a location code if you want to create a forecast entry for a specific location.';
                    Visible = false;
                    Editable = false;
                }
                field("Forecast By Variants"; Rec."Forecast By Variants")
                {
                    ApplicationArea = Planning;
                    Caption = 'Forecast by Variants';
                    ToolTip = 'Use this if you want to create a forecast entry including the variants.';
                    Visible = false;
                    Editable = false;
                }
                field("Variant Filter"; VariantFilter)
                {
                    ApplicationArea = Planning;
                    Caption = 'Variant Filter';
                    ToolTip = 'Specifies an item variant code if you want to create a forecast entry for a specific item variant.';
                    Importance = Additional;
                    Visible = false;
                    Editable = false;
                }
                field("Date Filter"; Rec."Date Filter")
                {
                    ApplicationArea = Planning;
                    Caption = 'Date Filter';
                    ToolTip = 'Specifies the dates that will be used to filter the amounts in the window.';
                    Visible = false;
                    Editable = false;
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

    actions
    {
        area(processing)
        {
            action("Edit Demand Forecast")
            {
                ApplicationArea = Planning;
                Caption = 'Edit Demand Forecast';
                Image = EditForecast;
                ShortCutKey = 'Return';
                ToolTip = 'Open the related demand forecast.';

                trigger OnAction()
                var
                    DemandForecastCard: Page "Demand Forecast Card";
                begin
                    DemandForecastCard.SetRecord(Rec);
                    DemandForecastCard.Run();
                end;
            }
            action("Copy Demand Forecast")
            {
                ApplicationArea = Planning;
                Caption = 'Copy Demand Forecast Entries';
                Ellipsis = true;
                Image = CopyForecast;
                RunObject = Report "Copy Production Forecast";
                ToolTip = 'Copy an existing demand forecast to quickly create a similar forecast.';
            }
        }
        area(Navigation)
        {
            action("Demand Forecast Entries")
            {
                ApplicationArea = Planning;
                Caption = 'Demand Forecast Entries';
                Image = Forecast;
                RunObject = Page "Demand Forecast Entries";
                RunPageMode = View;
                RunPageLink = "Production Forecast Name" = field(Name);
                ToolTip = 'Opens a page with the demand forecast entries for the specified production forecast.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Edit Demand Forecast_Promoted"; "Edit Demand Forecast")
                {
                }
                actionref("Copy Demand Forecast_Promoted"; "Copy Demand Forecast")
                {
                }
                actionref("Demand Forecast Entries_Promoted"; "Demand Forecast Entries")
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        ItemFilter := Rec.GetItemFilterAsDisplayText();
        LocationFilter := Rec.GetLocationFilterBlobAsText();
        VariantFilter := Rec.GetVariantFilterBlobAsText();
    end;

    var
        ItemFilter: Text;
        LocationFilter: Text;
        VariantFilter: Text;
}
