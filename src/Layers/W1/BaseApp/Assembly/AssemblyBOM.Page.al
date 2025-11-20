// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.BOM;

using Microsoft.Assembly.Costing;
using Microsoft.Assembly.Document;
using Microsoft.Inventory.Item;
using Microsoft.Projects.Resources.Resource;

page 36 "Assembly BOM"
{
    AutoSplitKey = true;
    Caption = 'Assembly BOM';
    DelayedInsert = true;
    DataCaptionFields = "Parent Item No.";
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = "BOM Component";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Type; Rec.Type)
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies if the assembly BOM component is an item or a resource.';

                    trigger OnValidate()
                    begin
                        IsEmptyOrItem := Rec.Type in [Rec.Type::" ", Rec.Type::Item];
                    end;
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';

                    trigger OnValidate()
                    var
                        Item: Record "Item";
                    begin
                        if Rec."Variant Code" = '' then
                            VariantCodeMandatory := Item.IsVariantMandatory(Rec.Type = Rec.Type::Item, Rec."No.");
                    end;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                    ShowMandatory = VariantCodeMandatory;

                    trigger OnValidate()
                    var
                        Item: Record "Item";
                    begin
                        if Rec."Variant Code" = '' then
                            VariantCodeMandatory := Item.IsVariantMandatory(Rec.Type = Rec.Type::Item, Rec."No.");
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies a description of the assembly BOM component.';
                }
                field("Assembly BOM"; Rec."Assembly BOM")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies if the assembly BOM component is an assembly BOM.';
                }
                field("Quantity per"; Rec."Quantity per")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies how many units of the component are required to produce or assemble the parent item.';
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                field("Installed in Item No."; Rec."Installed in Item No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies which service item the component on the line is used in.';
                }
                field(Position; Rec.Position)
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the position of the component on the bill of material.';
                }
                field("Position 2"; Rec."Position 2")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the component''s position in the assembly BOM structure.';
                    Visible = false;
                }
                field("Position 3"; Rec."Position 3")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the third reference number for the component position on a bill of material, such as the alternate position number of a component on a print card.';
                    Visible = false;
                }
                field("Machine No."; Rec."Machine No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies a machine that should be used when processing the component on this line of the assembly BOM.';
                    Visible = false;
                }
                field("Lead-Time Offset"; Rec."Lead-Time Offset")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the total number of days required to assemble the item on the assembly BOM line.';
                    Visible = false;
                }
                field("Resource Usage Type"; Rec."Resource Usage Type")
                {
                    ApplicationArea = Assembly;
                    Editable = not IsEmptyOrItem;
                    HideValue = IsEmptyOrItem;
                    ToolTip = 'Specifies how the cost of the resource on the assembly BOM is allocated during assembly.';
                    Visible = false;
                }
            }
        }
        area(factboxes)
        {
            part(Control18; "Assembly Item - Details")
            {
                ApplicationArea = Assembly;
                SubPageLink = "No." = field("Parent Item No.");
            }
            systempart(Control17; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control11; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
            part(Control13; "Component - Item Details")
            {
                ApplicationArea = Assembly;
                SubPageLink = "No." = field("No.");
                Visible = Rec.Type = Rec.Type::Item;
            }
            part(Control9; "Component - Resource Details")
            {
                ApplicationArea = Assembly;
                SubPageLink = "No." = field("No.");
                Visible = Rec.Type = Rec.Type::Resource;
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Show BOM")
            {
                ApplicationArea = Assembly;
                Caption = 'Show BOM';
                Image = Hierarchy;
                ToolTip = 'View the BOM structure.';

                trigger OnAction()
                var
                    Item: Record Item;
                    BOMStructure: Page "BOM Structure";
                begin
                    Item.Get(Rec."Parent Item No.");
                    BOMStructure.InitItem(Item);
                    BOMStructure.Run();
                end;
            }
            action("E&xplode BOM")
            {
                ApplicationArea = Assembly;
                Caption = 'E&xplode BOM';
                Enabled = Rec."Assembly BOM";
                Image = ExplodeBOM;
                RunObject = Codeunit "BOM-Explode BOM";
                ToolTip = 'Insert new lines for the components on the bill of materials, for example to sell the parent item as a kit. CAUTION: The line for the parent item will be deleted and represented by a description only. To undo, you must delete the component lines and add a line the parent item again.';
            }
            action(CalcStandardCost)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Calc. Standard Cost';
                Image = CalculateCost;
                ToolTip = 'Update the standard cost of the item based on the calculated costs of its underlying components.';

                trigger OnAction()
                var
                    CalculateAssemblyCost: Codeunit "Calculate Assembly Cost";
                begin
                    CalculateAssemblyCost.CalcItem(Rec."Parent Item No.");
                end;
            }
            action(CalcUnitPrice)
            {
                ApplicationArea = Assembly;
                Caption = 'Calc. Unit Price';
                Image = SuggestItemPrice;
                ToolTip = 'Calculate the unit price based on the unit cost and the profit percentage.';

                trigger OnAction()
                var
                    CalculateAssemblyCost: Codeunit "Calculate Assembly Cost";
                begin
                    CalculateAssemblyCost.CalcAssemblyItemPrice(Rec."Parent Item No.")
                end;
            }
            action("Cost Shares")
            {
                ApplicationArea = Assembly;
                Caption = 'Cost Shares';
                Image = CostBudget;
                ToolTip = 'View how the costs of underlying items in the BOM roll up to the parent item. The information is organized according to the BOM structure to reflect at which levels the individual costs apply. Each item level can be collapsed or expanded to obtain an overview or detailed view.';

                trigger OnAction()
                var
                    Item: Record Item;
                    BOMCostShares: Page "BOM Cost Shares";
                begin
                    Item.Get(Rec."Parent Item No.");
                    BOMCostShares.InitItem(Item);
                    BOMCostShares.Run();
                end;
            }
            action("Where-Used")
            {
                ApplicationArea = Assembly;
                Caption = 'Where-Used';
                Image = Track;
                RunObject = Page "Where-Used List";
                RunPageLink = "No." = field("No.");
                RunPageView = sorting(Type, "No.");
                ToolTip = 'View a list of BOMs in which the item is used.';
            }
            action(View)
            {
                ApplicationArea = Assembly;
                Caption = 'View';
                Image = Item;
                ToolTip = 'View and modify the selected component.';

                trigger OnAction()
                var
                    Item: Record Item;
                    Resource: Record Resource;
                begin
                    if Rec.Type = Rec.Type::Item then begin
                        Item.Get(Rec."No.");
                        PAGE.Run(PAGE::"Item Card", Item)
                    end else
                        if Rec.Type = Rec.Type::Resource then begin
                            Resource.Get(Rec."No.");
                            PAGE.Run(PAGE::"Resource Card", Resource);
                        end
                end;
            }
            action(AssemblyBOM)
            {
                ApplicationArea = Assembly;
                Caption = 'Assembly BOM';
                Enabled = false;
                Image = BOM;
                RunPageMode = View;
                ToolTip = 'View or edit the bill of material that specifies which items and resources are required to assemble the assembly item.';
                Visible = false;

                trigger OnAction()
                var
                    BOMComponent: Record "BOM Component";
                begin
                    if not Rec."Assembly BOM" then
                        exit;

                    Commit();
                    BOMComponent.SetRange("Parent Item No.", Rec."No.");
                    PAGE.Run(PAGE::"Assembly BOM", BOMComponent);
                    CurrPage.Update();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
            group(Category_Category4)
            {
                Caption = 'Item', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(View_Promoted; View)
                {
                }
                actionref("Where-Used_Promoted"; "Where-Used")
                {
                }
                actionref(AssemblyBOM_Promoted; AssemblyBOM)
                {
                }
            }
            group(Category_Category5)
            {
                Caption = 'BOM', Comment = 'Generated from the PromotedActionCategories property index 4.';

                actionref("Show BOM_Promoted"; "Show BOM")
                {
                }
                actionref(CalcStandardCost_Promoted; CalcStandardCost)
                {
                }
                actionref(CalcUnitPrice_Promoted; CalcUnitPrice)
                {
                }
                actionref("Cost Shares_Promoted"; "Cost Shares")
                {
                }
                actionref("E&xplode BOM_Promoted"; "E&xplode BOM")
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        IsEmptyOrItem := Rec.Type in [Rec.Type::" ", Rec.Type::Item];
    end;

    trigger OnAfterGetRecord()
    var
        Item: Record Item;
    begin
        IsEmptyOrItem := Rec.Type in [Rec.Type::" ", Rec.Type::Item];
        if Rec."Variant Code" = '' then
            VariantCodeMandatory := Item.IsVariantMandatory(Rec.Type = Rec.Type::Item, Rec."No.");
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        CheckMandatoryRecFieldsBeforePageInsert();

        IsEmptyOrItem := Rec.Type in [Rec.Type::" ", Rec.Type::Item];
    end;

    trigger OnModifyRecord(): Boolean
    begin
        CheckMandatoryRecFields();
    end;

    var
        IsEmptyOrItem: Boolean;
        VariantCodeMandatory: Boolean;

    local procedure CheckMandatoryRecFieldsBeforePageInsert()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckMandatoryRecFieldsBeforePageInsert(Rec, IsHandled);
        if IsHandled then
            exit;

        CheckMandatoryRecFields();
    end;

    local procedure CheckMandatoryRecFields()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckMandatoryRecFields(Rec, IsHandled);
        if IsHandled then
            exit;

        Rec.TestField("Parent Item No.");
        case Rec.Type of
            Rec.Type::" ":
                Rec.TestField("Description");
            Rec.Type::Item, Rec.Type::Resource:
                begin
                    Rec.TestField("No.");
                    Rec.TestField("Quantity per");
                end;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckMandatoryRecFieldsBeforePageInsert(var BOMComponent: Record "BOM Component"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckMandatoryRecFields(var BOMComponent: Record "BOM Component"; var IsHandled: Boolean)
    begin
    end;
}

