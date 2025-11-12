// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Pricing;

page 6081 "Serv. Price Group Setup"
{
    Caption = 'Serv. Price Group Setup';
    DataCaptionExpression = FormCaption();
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Serv. Price Group Setup";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Service Price Group Code"; Rec."Service Price Group Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the code of the Service Price Adjustment Group that was assigned to the service item linked to this service line.';
                    Visible = ServicePriceGroupCodeVisible;
                }
                field("Fault Area Code"; Rec."Fault Area Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a code for the fault area assigned to the given service price group.';
                }
                field("Cust. Price Group Code"; Rec."Cust. Price Group Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the code of the customer price group associated with the given service price group.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the currency code assigned to the service price group.';
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when the service hours become applicable to the service price group.';
                }
                field("Serv. Price Adjmt. Gr. Code"; Rec."Serv. Price Adjmt. Gr. Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the code of the service price adjustment group that applies to the posted service line.';
                }
                field("Include Discounts"; Rec."Include Discounts")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that any sales line or invoice discount set up for the customer will be deducted from the price of the item assigned to the service price group.';
                }
                field("Adjustment Type"; Rec."Adjustment Type")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the adjustment type for the service item line.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the amount to which the price on the service price group is going to be adjusted.';
                }
                field("Include VAT"; Rec."Include VAT")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that the amount to be adjusted for the given service price group should include VAT.';
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
    }

    trigger OnInit()
    begin
        ServicePriceGroupCodeVisible := true;
    end;

    trigger OnOpenPage()
    var
        ServPriceGroup: Record "Service Price Group";
        ShowColumn: Boolean;
    begin
        ShowColumn := true;
        if Rec.GetFilter("Service Price Group Code") <> '' then
            if ServPriceGroup.Get(Rec."Service Price Group Code") then
                ShowColumn := false
            else
                Rec.Reset();
        ServicePriceGroupCodeVisible := ShowColumn;
    end;

    var
        ServicePriceGroupCodeVisible: Boolean;

    local procedure FormCaption(): Text[180]
    var
        ServicePriceGroup: Record "Service Price Group";
    begin
        if Rec.GetFilter("Service Price Group Code") <> '' then
            if ServicePriceGroup.Get(Rec."Service Price Group Code") then
                exit(StrSubstNo('%1 %2', Rec."Service Price Group Code", ServicePriceGroup.Description));
    end;
}

