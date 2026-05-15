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
        modify("No.")
        {
            trigger OnAfterValidate()
            begin
                UpdateWIPEnabled();
            end;
        }
        modify(Type)
        {
            trigger OnAfterValidate()
            begin
                UpdateWIPEnabled();
            end;
        }
        addafter("Routing Link Code")
        {
            field("Transfer WIP Item"; Rec."Transfer WIP Item")
            {
                ApplicationArea = Manufacturing;
                Enabled = TransferWIPItemEnabled;
            }
            field("Transfer Description"; Rec."Transfer Description")
            {
                ApplicationArea = Manufacturing;
                Enabled = Rec."Transfer WIP Item";
            }
            field("Transfer Description 2"; Rec."Transfer Description 2")
            {
                ApplicationArea = Manufacturing;
                Enabled = Rec."Transfer WIP Item";
            }
        }
    }
    actions
    {
        addafter("&Quality Measures")
        {
            action("Subc. Prices")
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

    trigger OnAfterGetRecord()
    begin
        UpdateWIPEnabled();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        UpdateWIPEnabled();
    end;

    var
        TransferWIPItemEnabled: Boolean;

    local procedure UpdateWIPEnabled()
    begin
        Rec.Calcfields(Subcontracting);
        TransferWIPItemEnabled := Rec.Subcontracting;
    end;

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