// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

using Microsoft.Inventory.Item;

pageextension 99000759 "Mfg. Cost Adjustment Overview" extends "Cost Adjustment Overview"
{
    actions
    {
        addafter("Import Item Data")
        {
            action("Mfg. Export Item Data")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Export productionitem data';
                ToolTip = 'Use this function to export production item related data to text file (you can attach this file to support requests in case you may have issues with costing calculation).';
                Image = Export;

                trigger OnAction()
                var
                    Item: Record Item;
                begin
                    Item.SetRange("No.", Rec."No.");
                    Xmlport.Run(XmlPort::"Mfg. Export Item Data", false, false, Item);
                end;
            }
            action("Mfg. Import Item Data")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Import production item data';
                ToolTip = 'Use this function to import production item related data from text file.';
                Image = Import;
                Visible = SandboxActionsVisible;

                trigger OnAction()
                begin
                    if not SandboxActionsVisible then
                        Error(GetNotTestEnvironmentErr());
                    Xmlport.
                    Run(XmlPort::"Mfg. Export Item Data", false, true);
                end;
            }
        }
    }

    var
        SandboxActionsVisible: Boolean;

    trigger OnOpenPage()
    begin
        SandboxActionsVisible := IsSandboxActionsVisible();
    end;
}
