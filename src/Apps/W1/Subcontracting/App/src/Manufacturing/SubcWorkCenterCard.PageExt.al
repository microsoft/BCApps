// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Document;

pageextension 99001506 "Subc. Work Center Card" extends "Work Center Card"
{
    layout
    {
        modify("Subcontractor No.")
        {
            trigger OnAfterValidate()
            begin
                CurrPage.Update(false);
            end;
        }
    }
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
                    RunObject = page "Subcontractor Prices";
                    RunPageLink = "Work Center No." = field("No.");
                    RunPageView = sorting("Vendor No.", "Item No.", "Standard Task Code", "Work Center No.", "Variant Code", "Starting Date", "Unit of Measure Code", "Minimum Quantity", "Currency Code");
                    ToolTip = 'Set up different prices for the work center and vendor in subcontracting.';
                }
                action("WIP Ledger Entries")
                {
                    ApplicationArea = Subcontracting;
                    Caption = 'Subcontracting WIP Entries';
                    Enabled = IsSubcontractingWorkCenter;
                    Image = LedgerEntries;
                    RunObject = page "Subc. WIP Ledger Entries";
                    RunPageLink = "Work Center No." = field("No.");
                    ToolTip = 'View the Subcontracting WIP Entries that track work-in-progress quantities at this work center''s subcontracting location.';
                }
                action("Subcontractor - Dispatch List")
                {
                    ApplicationArea = Subcontracting;
                    Caption = 'Subcontractor - Dispatch List';
                    Enabled = IsSubcontractingWorkCenter;
                    Image = Print;
                    ToolTip = 'Print the dispatching list for the subcontractor assigned to this work center.';

                    trigger OnAction()
                    var
                        PurchaseHeader: Record "Purchase Header";
                    begin
                        PurchaseHeader.SetRange("Buy-from Vendor No.", Rec."Subcontractor No.");
                        Report.Run(Report::"Subc. Dispatching List", true, false, PurchaseHeader);
                    end;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
#if not CLEAN28
#pragma warning disable AL0432
        SubcontractingEnabled := SubcFeatureFlagHandler.IsSubcontractingEnabled();
#pragma warning restore AL0432
#endif
    end;

    trigger OnAfterGetCurrRecord()
    begin
#if not CLEAN28
        if not SubcontractingEnabled then
            exit;

#endif
        IsSubcontractingWorkCenter := Rec."Subcontractor No." <> '';
    end;

    var
#if not CLEAN28
#pragma warning disable AL0432
        SubcFeatureFlagHandler: Codeunit "Subc. Feature Flag Handler";
#pragma warning restore AL0432
        SubcontractingEnabled: Boolean;
#endif
        IsSubcontractingWorkCenter: Boolean;
}
