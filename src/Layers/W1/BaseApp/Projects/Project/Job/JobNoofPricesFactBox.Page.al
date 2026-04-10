// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Job;

using Microsoft.Pricing.Asset;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.Pricing.Source;
using Microsoft.Projects.Project.Pricing;

page 9098 "Job No. of Prices FactBox"
{
    Caption = 'Project Details - No. of Prices';
    PageType = CardPart;
    SourceTable = Job;

    layout
    {
        area(content)
        {
            field("No."; Rec."No.")
            {
                ApplicationArea = Jobs;
                Caption = 'Project No.';
                ToolTip = 'Specifies the project number.';

                trigger OnDrillDown()
                begin
                    ShowDetails();
                end;
            }
            field(NoOfResourcePrices; NoOfResourcePrices)
            {
                ApplicationArea = Jobs;
                Caption = 'Resource';
                Visible = not ExtendedPriceEnabled;
                ToolTip = 'Specifies prices for the resource.';

                trigger OnDrillDown()
                var
                    JobResPrice: Record "Job Resource Price";
                begin
                    JobResPrice.SetRange("Job No.", Rec."No.");

                    PAGE.Run(PAGE::"Job Resource Prices", JobResPrice);
                end;
            }
            field(NoOfItemPrices; NoOfItemPrices)
            {
                ApplicationArea = Jobs;
                Caption = 'Item';
                Visible = not ExtendedPriceEnabled;
                ToolTip = 'Specifies the total usage cost of items associated with this project.';

                trigger OnDrillDown()
                var
                    JobItPrice: Record "Job Item Price";
                begin
                    JobItPrice.SetRange("Job No.", Rec."No.");

                    PAGE.Run(PAGE::"Job Item Prices", JobItPrice);
                end;
            }
            field(NoOfAccountPrices; NoOfAccountPrices)
            {
                ApplicationArea = Jobs;
                Caption = 'G/L Account';
                Visible = not ExtendedPriceEnabled;
                ToolTip = 'Specifies the sum of values in the Project G/L Account Prices window.';

                trigger OnDrillDown()
                var
                    JobAccPrice: Record "Job G/L Account Price";
                begin
                    JobAccPrice.SetRange("Job No.", Rec."No.");

                    PAGE.Run(PAGE::"Job G/L Account Prices", JobAccPrice);
                end;
            }
            field(NoOfResPrices; NoOfResourcePrices)
            {
                ApplicationArea = Jobs;
                Caption = 'Resource';
                Visible = ExtendedPriceEnabled;
                ToolTip = 'Specifies prices for the resource.';

                trigger OnDrillDown()
                begin
                    Rec.ShowPriceListLines("Price Type"::Sale, "Price Asset Type"::Resource, "Price Amount Type"::Any);
                end;
            }
            field(NoOfItemsPrices; NoOfItemPrices)
            {
                ApplicationArea = Jobs;
                Caption = 'Item';
                Visible = ExtendedPriceEnabled;
                ToolTip = 'Specifies the total usage cost of items associated with this project.';

                trigger OnDrillDown()
                begin
                    Rec.ShowPriceListLines("Price Type"::Sale, "Price Asset Type"::Item, "Price Amount Type"::Any);
                end;
            }
            field(NoOfAccPrices; NoOfAccountPrices)
            {
                ApplicationArea = Jobs;
                Caption = 'G/L Account';
                Visible = ExtendedPriceEnabled;
                ToolTip = 'Specifies the sum of values in the Project G/L Account Prices window.';

                trigger OnDrillDown()
                begin
                    Rec.ShowPriceListLines("Price Type"::Sale, "Price Asset Type"::"G/L Account", "Price Amount Type"::Any);
                end;
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        CalcNoOfRecords();
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        NoOfResourcePrices := 0;
        NoOfItemPrices := 0;
        NoOfAccountPrices := 0;

        exit(Rec.Find(Which));
    end;

    trigger OnOpenPage()
    begin
        ExtendedPriceEnabled := PriceCalculationMgt.IsExtendedPriceCalculationEnabled();
        CalcNoOfRecords();
    end;

    var
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
        NoOfResourcePrices: Integer;
        NoOfItemPrices: Integer;
        NoOfAccountPrices: Integer;
        ExtendedPriceEnabled: Boolean;

    local procedure ShowDetails()
    begin
        PAGE.Run(PAGE::"Job Card", Rec);
    end;

    local procedure CalcNoOfRecords(): Boolean;
    var
        PriceListLine: Record "Price List Line";
    begin
        if CalcOldNoOfRecords() then
            exit;

        PriceListLine.SetRange(Status, "Price Status"::Active);
        PriceListLine.SetRange("Source Type", "Price Source Type"::Job);
        PriceListLine.SetRange("Source No.", Rec."No.");
        PriceListLine.SetRange("Price Type", PriceListLine."Price Type"::Sale);
        PriceListLine.SetRange("Asset Type", PriceListLine."Asset Type"::Resource);
        NoOfResourcePrices := PriceListLine.Count();

        PriceListLine.SetRange("Asset Type", "Price Asset Type"::Item);
        NoOfItemPrices := PriceListLine.Count();

        PriceListLine.SetRange("Asset Type", "Price Asset Type"::"G/L Account");
        NoOfAccountPrices := PriceListLine.Count();
    end;

    local procedure CalcOldNoOfRecords(): Boolean;
    var
        JobResourcePrice: Record "Job Resource Price";
        JobItemPrice: Record "Job Item Price";
        JobAccountPrice: Record "Job G/L Account Price";
    begin
        if PriceCalculationMgt.IsExtendedPriceCalculationEnabled() then
            exit(false);

        JobResourcePrice.Reset();
        JobResourcePrice.SetRange("Job No.", Rec."No.");
        NoOfResourcePrices := JobResourcePrice.Count();

        JobItemPrice.Reset();
        JobItemPrice.SetRange("Job No.", Rec."No.");
        NoOfItemPrices := JobItemPrice.Count();

        JobAccountPrice.Reset();
        JobAccountPrice.SetRange("Job No.", Rec."No.");
        NoOfAccountPrices := JobAccountPrice.Count();
        exit(true);
    end;
}

