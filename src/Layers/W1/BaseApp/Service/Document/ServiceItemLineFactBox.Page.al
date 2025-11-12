// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.Service.Item;

page 9088 "Service Item Line FactBox"
{
    Caption = 'Service Item Line Details';
    PageType = CardPart;
    SourceTable = "Service Item Line";

    layout
    {
        area(content)
        {
            field("Service Item No."; Rec."Service Item No.")
            {
                ApplicationArea = Service;
                Lookup = false;
                ToolTip = 'Specifies the service item number registered in the Service Item table.';

                trigger OnDrillDown()
                begin
                    ShowDetails();
                end;
            }
            field(ComponentList; StrSubstNo('%1', ServInfoPaneMgt.CalcNoOfServItemComponents(Rec)))
            {
                ApplicationArea = Service;
                Caption = 'Component List';
                DrillDown = true;
                Editable = true;
                ToolTip = 'Specifies the list of components.';

                trigger OnDrillDown()
                begin
                    ServInfoPaneMgt.ShowServItemComponents(Rec);
                end;
            }
            field(Troubleshooting; StrSubstNo('%1', ServInfoPaneMgt.CalcNoOfTroubleshootings(Rec)))
            {
                ApplicationArea = Service;
                Caption = 'Troubleshooting';
                DrillDown = true;
                Editable = true;
                ToolTip = 'Specifies troubleshooting guidelines that have been assigned to service items.';

                trigger OnDrillDown()
                begin
                    ServInfoPaneMgt.ShowTroubleshootings(Rec);
                end;
            }
            field(SkilledResources; StrSubstNo('%1', ServInfoPaneMgt.CalcNoOfSkilledResources(Rec)))
            {
                ApplicationArea = Service;
                Caption = 'Skilled Resources';
                DrillDown = true;
                Editable = true;
                ToolTip = 'Specifies the number of skilled resources related to service items.';

                trigger OnDrillDown()
                begin
                    ServInfoPaneMgt.ShowSkilledResources(Rec);
                end;
            }
        }
    }

    actions
    {
    }

    var
        ServInfoPaneMgt: Codeunit "Service Info-Pane Management";

    local procedure ShowDetails()
    var
        ServiceItem: Record "Service Item";
    begin
        if ServiceItem.Get(Rec."Service Item No.") then
            PAGE.Run(PAGE::"Service Item Card", ServiceItem);
    end;
}

