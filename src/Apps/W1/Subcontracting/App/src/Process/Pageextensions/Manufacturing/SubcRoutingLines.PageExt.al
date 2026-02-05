// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Manufacturing.Routing;

pageextension 99001508 "Subc. Routing Lines" extends "Routing Lines"
{
    layout
    {
        modify("Routing Link Code")
        {
            Visible = true;
        }
    }
    actions
    {
        addafter("&Quality Measures")
        {
            action("Subcontracting Prices")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Subcontracting Prices';
                Image = Price;
                ToolTip = 'View the related subcontracting prices.';

                trigger OnAction()
                begin
                    ShowRelatedSubcontractorPrices();
                end;
            }
        }
    }
    procedure ShowRelatedSubcontractorPrices()
    var
        SubcontractorPrice: Record "Subcontractor Price";
    begin
        Rec.TestField(Type, Rec.Type::"Work Center");
        SubcontractorPrice.SetRange("Work Center No.", Rec."No.");
        if Rec."Standard Task Code" <> '' then
            SubcontractorPrice.SetRange("Standard Task Code", Rec."Standard Task Code")
        else
            SubcontractorPrice.SetRange("Standard Task Code");

        Page.Run(Page::"Subcontractor Prices", SubcontractorPrice);
    end;
}