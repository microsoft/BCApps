// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item;

using Microsoft.Foundation.UOM;
using Microsoft.Integration.Dataverse;

page 5404 "Item Units of Measure"
{
    Caption = 'Item Units of Measure';
    DataCaptionFields = "Item No.";
    PageType = List;
    PopulateAllFields = true;
    SourceTable = "Item Unit of Measure";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the item card from which you opened the Item Units of Measure window.';
                    Visible = false;
                }
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    StyleExpr = StyleName;
                    ToolTip = 'Specifies a unit of measure code that has been set up in the Unit of Measure table.';
                }
                field("Qty. per Unit of Measure"; Rec."Qty. per Unit of Measure")
                {
                    ApplicationArea = Basic, Suite;
                    StyleExpr = StyleName;
                    ToolTip = 'Specifies how many of the base unit of measure are contained in one unit of the item.';
                }
                field(Height; Rec.Height)
                {
                    ApplicationArea = Basic, Suite;
                    StyleExpr = StyleName;
                    ToolTip = 'Specifies the height of one item unit when measured in the unit of measure in the Code field.';
                }
                field(Width; Rec.Width)
                {
                    ApplicationArea = Basic, Suite;
                    StyleExpr = StyleName;
                    ToolTip = 'Specifies the width of one item unit when measured in the specified unit of measure.';
                }
                field(Length; Rec.Length)
                {
                    ApplicationArea = Basic, Suite;
                    StyleExpr = StyleName;
                    ToolTip = 'Specifies the length of one item unit when measured in the specified unit of measure.';
                }
                field(Cubage; Rec.Cubage)
                {
                    ApplicationArea = Basic, Suite;
                    StyleExpr = StyleName;
                    ToolTip = 'Specifies the volume (cubage) of one item unit in the unit of measure in the Code field.';
                }
                field(Weight; Rec.Weight)
                {
                    ApplicationArea = Basic, Suite;
                    StyleExpr = StyleName;
                    ToolTip = 'Specifies the weight of one item unit when measured in the specified unit of measure.';
                }
                field("Coupled to Dataverse"; Rec."Coupled to Dataverse")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies that the item unit of measure is coupled to a unit of measure in Dynamics 365 Sales.';
                    Visible = CRMIntegrationEnabled;
                }
            }
            group("Current Base Unit of Measure")
            {
                Caption = 'Current Base Unit of Measure';
                field(ItemUnitOfMeasure; ItemBaseUOM)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Base Unit of Measure';
                    Lookup = true;
                    TableRelation = "Unit of Measure".Code;
                    ToolTip = 'Specifies the unit in which the item is held on inventory. The base unit of measure also serves as the conversion basis for alternate units of measure.';

                    trigger OnValidate()
                    begin
                        Item.TestField("No.");
                        Item.LockTable();
                        Item.Find();
                        Item.Validate("Base Unit of Measure", ItemBaseUOM);
                        Item.Modify(true);
                        if ItemBaseUnitOfMeasure.Get(Item."No.", ItemBaseUOM) then
                            ItemBaseUOMQtyPrecision := ItemBaseUnitOfMeasure."Qty. Rounding Precision";
                        CurrPage.Update();
                    end;
                }
                field(ItemBaseUOMQtyPrecision; ItemBaseUOMQtyPrecision)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Quantity Rounding Precision';
                    Tooltip = 'Specifies how to round quantities when converting the base unit of measure, such as from Box to Each, on an order. For example, Each is the base unit of measure but you also sell the item in a Box of 6. If you only have five of the items available and you must sell in boxes, enter 1 to ensure that after conversion you will get 5 each and not 4.99998.';
                    DecimalPlaces = 0 : 5;
                    MinValue = 0;
                    MaxValue = 1;

                    trigger OnValidate()
                    begin
                        ItemBaseUnitOfMeasure.Validate("Qty. Rounding Precision", ItemBaseUOMQtyPrecision);
                        ItemBaseUnitOfMeasure.Modify(true);
                        CurrPage.Update();
                    end;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group(ActionGroupCRM)
            {
                Caption = 'Dynamics 365 Sales';
                Image = Administration;
                Visible = CRMIntegrationEnabled;
                action(CRMGotoUnitOfMeasure)
                {
                    ApplicationArea = Suite;
                    Caption = 'Unit';
                    Image = CoupledUnitOfMeasure;
                    ToolTip = 'Open the coupled Dynamics 365 Sales unit of measure.';

                    trigger OnAction()
                    var
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                    begin
                        CRMIntegrationManagement.ShowCRMEntityFromRecordID(Rec.RecordId);
                    end;
                }
                action(CRMSynchronizeNow)
                {
                    AccessByPermission = TableData "CRM Integration Record" = IM;
                    ApplicationArea = Suite;
                    Caption = 'Synchronize';
                    Image = Refresh;
                    ToolTip = 'Send updated data to Dynamics 365 Sales.';

                    trigger OnAction()
                    var
                        ItemUnitOfMeasure: Record "Item Unit of Measure";
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                        ItemUnitOfMeasureRecordRef: RecordRef;
                    begin
                        CurrPage.SetSelectionFilter(ItemUnitOfMeasure);
                        ItemUnitOfMeasure.Next();

                        if ItemUnitOfMeasure.Count() = 1 then
                            CRMIntegrationManagement.UpdateOneNow(ItemUnitOfMeasure.RecordId)
                        else begin
                            ItemUnitOfMeasureRecordRef.GetTable(ItemUnitOfMeasure);
                            CRMIntegrationManagement.UpdateMultipleNow(ItemUnitOfMeasureRecordRef);
                        end
                    end;
                }
                group(Coupling)
                {
                    Caption = 'Coupling', Comment = 'Coupling is a noun';
                    Image = LinkAccount;
                    ToolTip = 'Create, change, or delete a coupling between the Business Central record and a Dynamics 365 Sales record.';
                    action(ManageCRMCoupling)
                    {
                        AccessByPermission = TableData "CRM Integration Record" = IM;
                        ApplicationArea = Suite;
                        Caption = 'Set Up Coupling';
                        Image = LinkAccount;
                        ToolTip = 'Create or modify the coupling to a Dynamics 365 Sales unit of measure.';

                        trigger OnAction()
                        var
                            CRMIntegrationManagement: Codeunit "CRM Integration Management";
                        begin
                            CRMIntegrationManagement.DefineCoupling(Rec.RecordId);
                        end;
                    }
                    action(DeleteCRMCoupling)
                    {
                        AccessByPermission = TableData "CRM Integration Record" = D;
                        ApplicationArea = Suite;
                        Caption = 'Delete Coupling';
                        Enabled = CRMIsCoupledToRecord;
                        Image = UnLinkAccount;
                        ToolTip = 'Delete the coupling to a Dynamics 365 Sales unit of measure.';

                        trigger OnAction()
                        var
                            ItemUnitOfMeasure: Record "Item Unit of Measure";
                            CRMCouplingManagement: Codeunit "CRM Coupling Management";
                            ItemUnitOfMeasureRecordRef: RecordRef;
                        begin
                            CurrPage.SetSelectionFilter(ItemUnitOfMeasure);
                            ItemUnitOfMeasureRecordRef.GetTable(ItemUnitOfMeasure);
                            CRMCouplingManagement.RemoveCoupling(ItemUnitOfMeasureRecordRef);
                        end;
                    }
                }
                action(ShowLog)
                {
                    ApplicationArea = Suite;
                    Caption = 'Synchronization Log';
                    Image = Log;
                    ToolTip = 'View integration synchronization jobs for the item unit of measure table.';

                    trigger OnAction()
                    var
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                    begin
                        CRMIntegrationManagement.ShowLog(Rec.RecordId);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Synchronize)
            {
                Caption = 'Synchronize';
                Visible = CRMIntegrationEnabled;

                group(Category_Coupling)
                {
                    Caption = 'Coupling';
                    ShowAs = SplitButton;

                    actionref(ManageCRMCoupling_Promoted; ManageCRMCoupling)
                    {
                    }
                    actionref(DeleteCRMCoupling_Promoted; DeleteCRMCoupling)
                    {
                    }
                }
                actionref(CRMGotoUnitOfMeasure_Promoted; CRMGotoUnitOfMeasure)
                {
                }
                actionref(CRMSynchronizeNow_Promoted; CRMSynchronizeNow)
                {
                }
                actionref(ShowLog_Promoted; ShowLog)
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        CRMCouplingManagement: Codeunit "CRM Coupling Management";
    begin
        CRMIsCoupledToRecord := CRMIntegrationEnabled;
        if CRMIsCoupledToRecord then
            CRMIsCoupledToRecord := CRMCouplingManagement.IsRecordCoupledToCRM(Rec.RecordId);
    end;

    trigger OnAfterGetRecord()
    begin
        SetStyle();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        if Rec."Item No." = '' then
            Rec."Item No." := Item."No.";
        SetStyle();
    end;

    trigger OnOpenPage()
    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        if Rec.GetFilter("Item No.") <> '' then begin
            Rec.CopyFilter("Item No.", Item."No.");
            if Item.FindFirst() then begin
                ItemBaseUOM := Item."Base Unit of Measure";
                if ItemBaseUnitOfMeasure.Get(Item."No.", ItemBaseUOM) then
                    ItemBaseUOMQtyPrecision := ItemBaseUnitOfMeasure."Qty. Rounding Precision";
            end;
        end;
        CRMIntegrationEnabled := CRMIntegrationManagement.IsCRMIntegrationEnabled() and CRMIntegrationManagement.IsUnitGroupMappingEnabled();
    end;

    var
        Item: Record Item;
        ItemBaseUnitOfMeasure: Record "Item Unit of Measure";
        CRMIntegrationEnabled: Boolean;
        CRMIsCoupledToRecord: Boolean;
        ItemBaseUOMQtyPrecision: Decimal;

    protected var
        StyleName: Text;
        ItemBaseUOM: Code[10];

    local procedure SetStyle()
    begin
        if Rec.Code = ItemBaseUOM then
            StyleName := 'Strong'
        else
            StyleName := '';

        OnAfterSetStyle(StyleName, ItemBaseUOM, Item);
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterSetStyle(var StyleName: Text; ItemBaseUOM: Code[10]; Item: Record Item)
    begin
    end;
}

