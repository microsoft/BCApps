// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Reports;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Item.Substitution;

report 5701 "Item Substitutions"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Inventory/Reports/ItemSubstitutions.rdlc';
    ApplicationArea = Suite;
    Caption = 'Item Substitutions';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Item; Item)
        {
            DataItemTableView = sorting("No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.";
            column(Text000; Text000Lbl)
            {
            }
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(TIME; Time)
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(Item__No__; "No.")
            {
            }
            column(Item_Description; Description)
            {
            }
            column(Item__Unit_Cost_; "Unit Cost")
            {
            }
            column(Item__Base_Unit_of_Measure_; "Base Unit of Measure")
            {
            }
            column(Item_Inventory; Inventory)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Item__No__Caption; FieldCaption("No."))
            {
            }
            column(Item_DescriptionCaption; FieldCaption(Description))
            {
            }
            column(Item__Unit_Cost_Caption; FieldCaption("Unit Cost"))
            {
            }
            column(Base_Unit____of_MeasureCaption; Base_Unit____of_MeasureCaptionLbl)
            {
            }
            column(Item_Substitution__Substitute_No__Caption; "Item Substitution".FieldCaption("Substitute No."))
            {
            }
            column(Quantity__on_HandCaption; Quantity__on_HandCaptionLbl)
            {
            }
            column(Item_Substitution_ConditionCaption; "Item Substitution".FieldCaption(Condition))
            {
            }
            column(Item_Substitution_InterchangeableCaption; "Item Substitution".FieldCaption(Interchangeable))
            {
            }
            column(Item_Substitution__Substitute_Type_Caption; "Item Substitution".FieldCaption("Substitute Type"))
            {
            }
            dataitem("Item Substitution"; "Item Substitution")
            {
                DataItemLink = "No." = field("No.");
                DataItemTableView = sorting(Type, "No.", "Variant Code", "Substitute Type", "Substitute No.", "Substitute Variant Code") where(Type = const(Item));
                PrintOnlyIfDetail = false;
                column(Item_Substitution__Substitute_No__; "Substitute No.")
                {
                }
                column(Item_Substitution_Condition; Condition)
                {
                }
                column(Item_Substitution_Description; Description)
                {
                }
                column(Item_Substitution_Inventory; Inventory)
                {
                }
                column(UnitCost; UnitCost)
                {
                    AutoFormatType = 1;
                }
                column(Item_Substitution_Interchangeable; Interchangeable)
                {
                }
                column(Item_Substitution__Substitute_Type_; "Substitute Type")
                {
                }
                column(FORMAT_Interchangeable_; Format(Interchangeable))
                {
                }
                column(FORMAT_Condition_; Format(Condition))
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if "Substitute Type" = "Substitute Type"::Item then begin
                        Item2.Get("Substitute No.");
                        UnitCost := Item2."Unit Cost";
                        Item2.CalcFields(Inventory);
                        Inventory := Item2.Inventory;
                    end else begin
                        NonstockItem.Get("Substitute No.");
                        UnitCost := NonstockItem."Published Cost";
                    end;
                end;
            }
        }
    }

    requestpage
    {
        AboutTitle = 'About Item Substitutions';
        AboutText = 'Helps you manage and track item substitutions in production orders and bills of materials (BOMs). You can specify substitute items to use when the preferred items aren''t available, ensuring that production continues smoothly and without delays.';

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
        Item2: Record Item;
        NonstockItem: Record "Nonstock Item";
        UnitCost: Decimal;
        Text000Lbl: Label 'Item Substitutions';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Base_Unit____of_MeasureCaptionLbl: Label 'Base Unit of Measure';
        Quantity__on_HandCaptionLbl: Label 'Quantity on Hand';
}

