// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Manufacturing.WorkCenter;

pageextension 99001506 "Subc. Work Center Card" extends "Work Center Card"
{
    actions
    {
        addafter("Pla&nning")
        {
            group(Subcontracting)
            {
                Caption = 'Subcontracting';
                Image = SubcontractingWorksheet;

                action("Subcontractor Prices")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Subcontractor Prices';
                    Enabled = EnableSubcontractorPrices;
                    Image = Price;
                    RunObject = page "Subcontractor Prices";
                    RunPageLink = "Work Center No." = field("No.");
                    RunPageView = sorting("Vendor No.", "Item No.", "Standard Task Code", "Work Center No.", "Variant Code", "Starting Date", "Unit of Measure Code", "Minimum Quantity", "Currency Code");
                    ToolTip = 'Set up different prices for the work center and vendor in subcontracting.';
                }
            }
        }
    }
    trigger OnAfterGetCurrRecord()
    begin
        EnableSubcontractorPrices := Rec."Subcontractor No." <> '';
    end;

    trigger OnOpenPage()
    begin
        EnableSubcontractorPrices := Rec."Subcontractor No." <> '';
    end;

    var
        EnableSubcontractorPrices: Boolean;
}