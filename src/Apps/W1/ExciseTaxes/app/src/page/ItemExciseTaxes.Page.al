// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExciseTaxes;

using Microsoft.Inventory.Item;

page 7416 "Item Excise Taxes"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = "Item Excise Tax";
    Caption = 'Excise Taxes';
    DelayedInsert = true;
    DataCaptionExpression = GetCaption();

    layout
    {
        area(Content)
        {
            repeater(Setup)
            {
                field("Item No."; Rec."Item No.")
                {
                    ToolTip = 'Specifies the item number.';
                    Visible = false;
                }
                field("Excise Tax Type Code"; Rec."Excise Tax Type Code")
                {
                    ToolTip = 'Specifies the excise tax type that applies to this item.';
                }
                field("Excise Tax Type Description"; Rec."Excise Tax Type Description")
                {
                    ToolTip = 'Specifies the description of the excise tax type.';
                }
                field("Quantity for Excise Tax"; Rec."Quantity for Excise Tax")
                {
                    ToolTip = 'Specifies the amount per unit based on tax basis.';
                }
                field("Excise Unit of Measure Code"; Rec."Excise Unit of Measure Code")
                {
                    ToolTip = 'Specifies the unit of measure for tax basis.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(CopyFromItem)
            {
                Caption = 'Copy from Item';
                ToolTip = 'Copy the excise tax setup from another item to this item.';
                Image = Copy;

                trigger OnAction()
                var
                    Item: Record Item;
                    ItemExciseTax: Record "Item Excise Tax";
                    ToItemNo: Code[20];
                    CopiedCount: Integer;
                begin
                    ToItemNo := GetCurrentItemNo();
                    if ToItemNo = '' then
                        Error(NoTargetItemErr);

                    Item.SetFilter("No.", '<>%1', ToItemNo);
                    if Page.RunModal(Page::"Item List", Item) <> Action::LookupOK then
                        exit;

                    CopiedCount := ItemExciseTax.CopyExciseTaxesFromItem(Item."No.", ToItemNo);
                    CurrPage.Update(false);
                    Message(CopiedMsg, CopiedCount, Item."No.");
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref(CopyFromItem_Promoted; CopyFromItem)
                {
                }
            }
        }
    }

    var
        SetupCaptionLbl: Label '%1 for %2', Comment = '%1 = Table Caption, %2 = Item No.';
        NoTargetItemErr: Label 'Open this page from a specific item to copy excise taxes to it.';
        CopiedMsg: Label '%1 excise tax line(s) were copied from item %2.', Comment = '%1 = Number of lines copied, %2 = Source Item No.';

    local procedure GetCurrentItemNo(): Code[20]
    var
        ItemNoFilter: Text;
    begin
        if Rec."Item No." <> '' then
            exit(Rec."Item No.");

        ItemNoFilter := Rec.GetFilter("Item No.");
        if ItemNoFilter <> '' then
            exit(CopyStr(ItemNoFilter, 1, MaxStrLen(Rec."Item No.")));
    end;

    local procedure GetCaption(): Text
    begin
        if Rec.GetFilter("Item No.") = '' then
            exit(Rec.TableCaption());

        exit(StrSubstNo(SetupCaptionLbl, Rec.TableCaption(), Rec.GetFilter("Item No.")));
    end;
}