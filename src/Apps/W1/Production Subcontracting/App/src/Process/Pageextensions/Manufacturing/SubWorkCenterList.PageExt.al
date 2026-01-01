// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Manufacturing.WorkCenter;

pageextension 99001507 "Sub. Work Center List" extends "Work Center List"
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
                    ApplicationArea = All;
                    Caption = 'Subcontractor Prices';
                    Image = Price;
                    ToolTip = 'Set up different prices for the work center and vendor in subcontracting.';
                    trigger OnAction()
                    var
                        SubcontractorPrices: Record "Subcontractor Price";
                        SubcPriceForm: Page "Subcontractor Prices";
                    begin
                        if Rec."Subcontractor No." <> '' then begin
                            SubcontractorPrices.SetRange("Work Center No.", Rec."No.");
                            SubcPriceForm.SetTableView(SubcontractorPrices);
                            SubcPriceForm.RunModal();
                        end;
                    end;
                }
            }
        }
    }
    procedure GetCurrSelectionFilter(): Text
    var
        WorkCenter: Record "Work Center";
        SubSelectionFilterMgmt: Codeunit "Sub. SelectionFilterMgmt";
    begin
        CurrPage.SetSelectionFilter(WorkCenter);
        exit(SubSelectionFilterMgmt.GetSelectionFilterForWorkCenter(WorkCenter));
    end;
}