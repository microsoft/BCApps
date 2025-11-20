// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Document;

using Microsoft.Inventory.Item;

report 99001014 "Update Unit Cost"
{
    ApplicationArea = Manufacturing;
    Caption = 'Update Unit Costs';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem("Production Order"; "Production Order")
        {
            DataItemTableView = sorting(Status, "No.") where(Status = filter(.. Released));
            RequestFilterFields = Status, "No.";
            dataitem("Prod. Order Line"; "Prod. Order Line")
            {
                DataItemLink = Status = field(Status), "Prod. Order No." = field("No.");
                DataItemTableView = sorting(Status, "Prod. Order No.", "Planning Level Code") order(descending);

                trigger OnAfterGetRecord()
                var
                    UpdateProdOrderCost: Codeunit "Update Prod. Order Cost";
                begin
                    if not Item.Get("Item No.") then
                        CurrReport.Skip();

                    if Item."Costing Method".AsInteger() > Item."Costing Method"::Average.AsInteger() then
                        CurrReport.Skip();

                    UpdateProdOrderCost.UpdateUnitCostOnProdOrder("Prod. Order Line", CalcMethod = CalcMethod::"All Levels", UpdateReservations);
                end;

                trigger OnPreDataItem()
                begin
                    SetFilter(Quantity, '<>0');
                end;
            }
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(CalcMethod; CalcMethod)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Calculate';
                        OptionCaption = 'One Level,All Levels';
                        ToolTip = 'Specifies whether you want to calculate the unit cost based on the top item alone or based on a roll-up of the item''s BOM levels.';
                    }
                    field(UpdateReservations; UpdateReservations)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Update Reservations';
                        ToolTip = 'Specifies whether you want to enter the recalculated unit cost on all document lines where the item is reserved.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
        Item: Record Item;

    protected var
        CalcMethod: Option "One Level","All Levels";
        UpdateReservations: Boolean;

    procedure InitializeRequest(NewCalcMethod: Option; NewUpdateReservations: Boolean)
    begin
        CalcMethod := NewCalcMethod;
        UpdateReservations := NewUpdateReservations;

        OnAfterInitializeRequest();
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterInitializeRequest()
    begin
    end;
}

