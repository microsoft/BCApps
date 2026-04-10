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
                    Visible = ServicePriceGroupCodeVisible;
                }
                field("Fault Area Code"; Rec."Fault Area Code")
                {
                    ApplicationArea = Service;
                }
                field("Cust. Price Group Code"; Rec."Cust. Price Group Code")
                {
                    ApplicationArea = Service;
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Service;
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Service;
                }
                field("Serv. Price Adjmt. Gr. Code"; Rec."Serv. Price Adjmt. Gr. Code")
                {
                    ApplicationArea = Service;
                }
                field("Include Discounts"; Rec."Include Discounts")
                {
                    ApplicationArea = Service;
                }
                field("Adjustment Type"; Rec."Adjustment Type")
                {
                    ApplicationArea = Service;
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Service;
                }
                field("Include VAT"; Rec."Include VAT")
                {
                    ApplicationArea = Service;
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

