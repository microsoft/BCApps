// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

page 99001510 "Subc. Management Setup"
{
    ApplicationArea = Manufacturing;
    Caption = 'Subcontracting Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "Subc. Management Setup";
    UsageCategory = Administration;
    layout
    {
        area(Content)
        {
            group(Provision)
            {
                Caption = 'Purchase Provision';
                field("Preset Component Item No."; Rec."Preset Component Item No.")
                {
                    ToolTip = 'Specifies the item number of the preset component for purchase provision. This item will be used as a default when creating a purchase provision.';
                }
                field("Common Work Center No."; Rec."Common Work Center No.")
                {
                    ToolTip = 'Specifies the value of the Common Work Center No. for purchase provision.';
                }
                field("Put-Away Work Center No."; Rec."Put-Away Work Center No.")
                {
                    ToolTip = 'Specifies the work center number used for put-away operations in purchase provision. A second generic production order routing line is created for the put-away of the provision components.';
                }
                field("Default Provision Flushing Method"; Rec."Def. provision flushing method")
                {
                    ToolTip = 'Specifies the default flushing method used for purchase provision components. This determines how component consumption is automatically posted during production.';
                }
            }
            group("Prod. Order Create UI")
            {
                Caption = 'Purchase Provision Wizard UI';

                field("Save Modified Versions"; Rec."Always Save Modified Versions")
                {
                    ToolTip = 'Specifies whether modified versions of the routing and BOM should be saved when creating a production order.';
                }
                field(AllowEditUISelection; Rec.AllowEditUISelection)
                {
                    ToolTip = 'Specifies whether the user is allowed to change the display and editing options for Production BOM and Routing steps within the purchase provision wizard. If enabled, users can decide whether to hide, show, or fully edit BOM and Routing details during the process. If disabled, the options defined in the setup will be applied without allowing user modification at the wizard level.';
                }
                group("Both Available")
                {
                    Caption = 'Both Routing and BOM Available';
                    field(ShowRtngBOMSelect_Both; Rec.ShowRtngBOMSelect_Both)
                    {
                        Caption = 'BOM/Routing';
                        ToolTip = 'Specifies how the Routing/BOM selection dialog should be shown when both routing and BOM are available on the item.';
                    }
                    field(ShowProdRtngCompSelect_Both; Rec.ShowProdRtngCompSelect_Both)
                    {
                        Caption = 'Prod. Components/Prod. Operations';
                        ToolTip = 'Specifies how the production routing and component selection should be shown when both routing and BOM are available.';
                    }
                }
                group("Partially Available")
                {
                    Caption = 'Routing or BOM Partially Available';
                    field(ShowRtngBOMSelect_Partial; Rec.ShowRtngBOMSelect_Partial)
                    {
                        Caption = 'BOM/Routing';
                        ToolTip = 'Specifies how the Routing/BOM selection dialog should be shown when only routing or BOM is available on the item.';
                    }
                    field(ShowProdRtngCompSelect_Partial; Rec.ShowProdRtngCompSelect_Partial)
                    {
                        Caption = 'Prod. Components/Prod. Operations';
                        ToolTip = 'Specifies how the production routing and component selection should be shown when only routing or BOM is available.';
                    }
                }
                group("Nothing Available")
                {
                    Caption = 'Neither Routing nor BOM Available';
                    field(ShowRtngBOMSelect_Nothing; Rec.ShowRtngBOMSelect_Nothing)
                    {
                        Caption = 'BOM/Routing';
                        ToolTip = 'Specifies how the Routing/BOM selection dialog should be shown when neither routing nor BOM is available on the item.';
                    }
                    field(ShowProdRtngCompSelect_Nothing; Rec.ShowProdRtngCompSelect_Nothing)
                    {
                        Caption = 'Prod. Components/Prod. Operations';
                        ToolTip = 'Specifies how the production routing and component selection should be shown when neither routing nor BOM is available.';
                    }
                }
            }
        }
        area(FactBoxes)
        {
            systempart(SystemPartNotes; Notes)
            {
                Visible = false;
            }
            systempart(SystemPartLinks; Links)
            {
                Visible = false;
            }
        }
    }
    trigger OnOpenPage()
    begin
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
    end;
}
