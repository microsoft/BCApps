// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.StandardCost;

using Microsoft.Inventory.Item;

report 5854 "Roll Up Standard Cost"
{
    Caption = 'Roll Up Standard Cost';
    ProcessingOnly = true;

    dataset
    {
        dataitem(Item; Item)
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Costing Method";

            trigger OnPostDataItem()
            begin
                if not NoMessage then
                    if RolledUp then
                        Message(Text000)
                    else
                        Message(Text001);
            end;

            trigger OnPreDataItem()
            begin
                StdCostWksh.LockTable();
                Clear(CalcStdCost);
                CalcStdCost.SetProperties(CalculationDate, true, false, false, ToStdCostWkshName, true);
                CalcStdCost.CalcItems(Item, TempItem);

                TempItem.SetFilter("Replenishment System", '%1|%2',
                  TempItem."Replenishment System"::"Prod. Order",
                  TempItem."Replenishment System"::Assembly);
                OnPreDataItemOnAfterSetTempItemFilter(TempItem);
                if TempItem.Find('-') then
                    repeat
                        UpdateStdCostWksh();
                        RolledUp := true;
                    until TempItem.Next() = 0;
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(CalculationDate; CalculationDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Calculation Date';
                        ToolTip = 'Specifies the date you want the cost shares to be calculated.';

                        trigger OnValidate()
                        begin
                            if CalculationDate = 0D then
                                Error(Text002);
                        end;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if CalculationDate = 0D then
                CalculationDate := WorkDate();
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    var
        StdCostWkshName: Record "Standard Cost Worksheet Name";
    begin
        RolledUp := false;

        if ToStdCostWkshName = '' then
            Error(Text003);
        StdCostWkshName.Get(ToStdCostWkshName);
    end;

    var
        TempItem: Record Item temporary;
        StdCostWksh: Record "Standard Cost Worksheet";
        CalcStdCost: Codeunit "Calculate Standard Cost";
        CalculationDate: Date;
        ToStdCostWkshName: Code[10];
        RolledUp: Boolean;
#pragma warning disable AA0074
        Text000: Label 'The standard costs have been rolled up successfully.';
        Text001: Label 'There is nothing to roll up.';
        Text002: Label 'You must enter a calculation date.';
        Text003: Label 'You must specify a worksheet name to roll up to.';
#pragma warning restore AA0074
        NoMessage: Boolean;

    local procedure UpdateStdCostWksh()
    var
        Found: Boolean;
    begin
        Found := StdCostWksh.Get(ToStdCostWkshName, StdCostWksh.Type::Item, TempItem."No.");
        StdCostWksh.Validate("Standard Cost Worksheet Name", ToStdCostWkshName);
        StdCostWksh.Validate(Type, StdCostWksh.Type::Item);
        StdCostWksh.Validate("No.", TempItem."No.");
        StdCostWksh."New Standard Cost" := TempItem."Standard Cost";

        StdCostWksh."New Single-Lvl Material Cost" := TempItem."Single-Level Material Cost";
        StdCostWksh."New Single-Lvl Cap. Cost" := TempItem."Single-Level Capacity Cost";
        StdCostWksh."New Single-Lvl Subcontrd Cost" := TempItem."Single-Level Subcontrd. Cost";
        StdCostWksh."New Single-Lvl Cap. Ovhd Cost" := TempItem."Single-Level Cap. Ovhd Cost";
        StdCostWksh."New Single-Lvl Mfg. Ovhd Cost" := TempItem."Single-Level Mfg. Ovhd Cost";

        StdCostWksh."New Rolled-up Material Cost" := TempItem."Rolled-up Material Cost";
        StdCostWksh."New Rolled-up Cap. Cost" := TempItem."Rolled-up Capacity Cost";
        StdCostWksh."New Rolled-up Subcontrd Cost" := TempItem."Rolled-up Subcontracted Cost";
        StdCostWksh."New Rolled-up Cap. Ovhd Cost" := TempItem."Rolled-up Cap. Overhead Cost";
        StdCostWksh."New Rolled-up Mfg. Ovhd Cost" := TempItem."Rolled-up Mfg. Ovhd Cost";
        OnUpdateStdCostWkshOnAfterFieldsPopulated(StdCostWksh, TempItem);

        if Found then
            StdCostWksh.Modify(true)
        else
            StdCostWksh.Insert(true);
    end;

    procedure SetStdCostWksh(NewStdCostWkshName: Code[10])
    begin
        ToStdCostWkshName := NewStdCostWkshName;
    end;

    procedure Initialize(StdCostWkshName2: Code[10]; NoMessage2: Boolean)
    begin
        ToStdCostWkshName := StdCostWkshName2;
        NoMessage := NoMessage2;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateStdCostWkshOnAfterFieldsPopulated(var StdCostWksh: Record "Standard Cost Worksheet"; TempItem: Record Item temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPreDataItemOnAfterSetTempItemFilter(var TempItem: Record Item temporary)
    begin
    end;
}

