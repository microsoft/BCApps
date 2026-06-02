// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Manufacturing.WorkCenter;

pageextension 99001507 "Subc. Work Center List" extends "Work Center List"
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
                    ApplicationArea = Subcontracting;
                    Caption = 'Subcontractor Prices';
                    Enabled = IsSubcontractingWorkCenter;
                    Image = Price;
                    ToolTip = 'Set up different prices for the work center and vendor in subcontracting.';
                    trigger OnAction()
                    var
                        SubcontractorPrice: Record "Subcontractor Price";
                        SubcontractorPrices: Page "Subcontractor Prices";
                    begin
                        SubcontractorPrice.SetRange("Work Center No.", Rec."No.");
                        SubcontractorPrices.SetTableView(SubcontractorPrice);
                        SubcontractorPrices.RunModal();
                    end;
                }
                action("WIP Ledger Entries")
                {
                    ApplicationArea = Subcontracting;
                    Caption = 'WIP Ledger Entries';
                    Image = LedgerEntries;
                    RunObject = page "Subc. WIP Ledger Entries";
                    RunPageLink = "Work Center No." = field("No.");
                    ToolTip = 'View the Subcontractor WIP Ledger Entries that track work-in-progress quantities at this work center''s subcontracting location.';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        SubcontractingEnabled := SubcFeatureFlagHandler.IsSubcontractingEnabled();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        if not SubcontractingEnabled then
            exit;

        IsSubcontractingWorkCenter := Rec."Subcontractor No." <> '';
    end;

    var
        SubcFeatureFlagHandler: Codeunit "Subc. Feature Flag Handler";
        SubcontractingEnabled: Boolean;
        IsSubcontractingWorkCenter: Boolean;
}
