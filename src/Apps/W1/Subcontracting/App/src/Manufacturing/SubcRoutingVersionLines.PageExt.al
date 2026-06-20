// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Manufacturing.Routing;

pageextension 99001509 "Subc. Routing Version Lines" extends "Routing Version Lines"
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
        addafter(Description)
        {
            field("Transfer WIP Item"; Rec."Transfer WIP Item")
            {
                ApplicationArea = Subcontracting;
                Enabled = TransferWIPItemEnabled;
                ToolTip = 'Specifies whether a WIP item should be transferred for this subcontracting routing line.';
            }
            field("Transfer Description"; Rec."Transfer Description")
            {
                ApplicationArea = Subcontracting;
                Enabled = Rec."Transfer WIP Item";
                ToolTip = 'Specifies the description of the WIP item to transfer.';
            }
            field("Transfer Description 2"; Rec."Transfer Description 2")
            {
                ApplicationArea = Subcontracting;
                Enabled = Rec."Transfer WIP Item";
                ToolTip = 'Specifies an additional description of the WIP item to transfer.';
            }
        }
    }
    actions
    {
        addafter("Quality Measures")
        {
            action("Subc. Prices")
            {
                ApplicationArea = Subcontracting;
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

#if not CLEAN28
    trigger OnOpenPage()
    begin
#pragma warning disable AL0432
        SubcontractingEnabled := SubcFeatureFlagHandler.IsSubcontractingEnabled();
#pragma warning restore AL0432
        if not SubcontractingEnabled then
            exit;
    end;
#endif

    trigger OnAfterGetRecord()
    begin
#if not CLEAN28
        if not SubcontractingEnabled then
            exit;
#endif
        UpdateWIPEnabled();
    end;

    trigger OnAfterGetCurrRecord()
    begin
#if not CLEAN28
        if not SubcontractingEnabled then
            exit;
#endif
        UpdateWIPEnabled();
    end;

    var
#if not CLEAN28
#pragma warning disable AL0432
        SubcFeatureFlagHandler: Codeunit "Subc. Feature Flag Handler";
#pragma warning restore AL0432
        SubcontractingEnabled: Boolean;
#endif
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
#if not CLEAN28
        if not SubcontractingEnabled then
            exit;
#endif
        Rec.TestField(Type, Rec.Type::"Work Center");
        SubcontractorPrice.SetRange("Work Center No.", Rec."No.");
        if Rec."Standard Task Code" <> '' then
            SubcontractorPrice.SetRange("Standard Task Code", Rec."Standard Task Code")
        else
            SubcontractorPrice.SetRange("Standard Task Code");

        Page.Run(Page::"Subcontractor Prices", SubcontractorPrice);
    end;
}
