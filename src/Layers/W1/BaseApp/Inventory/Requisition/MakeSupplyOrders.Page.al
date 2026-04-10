// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Requisition;

page 5526 "Make Supply Orders"
{
    Caption = 'Make Supply Orders';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = StandardDialog;
    SourceTable = "Manufacturing User Template";

    layout
    {
        area(content)
        {
            group("Order Planning")
            {
                Caption = 'Order Planning';
                field("Make Orders"; Rec."Make Orders")
                {
                    ApplicationArea = Planning;
                    Caption = 'Make Orders for';
                    ValuesAllowed = "The Active Line", "The Active Order", "All Lines";
                }
                group(Control4)
                {
                    InstructionalText = 'Multilevel production orders that are made with this function may generate new demand, which you can only see after you have recalculated a plan in the Order Planning window.';
                    ShowCaption = false;
                }
            }
            group(Options)
            {
                Caption = 'Options';
                field("Create Purchase Order"; Rec."Create Purchase Order")
                {
                    ApplicationArea = Planning;

                    trigger OnValidate()
                    begin
                        PurchaseReqWkshTemplateEnable :=
                          Rec."Create Purchase Order" = Rec."Create Purchase Order"::"Copy to Req. Wksh";
                        PurchaseWkshNameEnable :=
                          Rec."Create Purchase Order" = Rec."Create Purchase Order"::"Copy to Req. Wksh";
                        CreatePurchaseOrderOnAfterVali();
                    end;
                }
                field("Purchase Req. Wksh. Template"; Rec."Purchase Req. Wksh. Template")
                {
                    ApplicationArea = Planning;
                    Enabled = PurchaseReqWkshTemplateEnable;

                    trigger OnValidate()
                    begin
                        PurchaseReqWkshTemplateOnAfter();
                    end;
                }
                field("Purchase Wksh. Name"; Rec."Purchase Wksh. Name")
                {
                    ApplicationArea = Planning;
                    Enabled = PurchaseWkshNameEnable;

                    trigger OnValidate()
                    begin
                        PurchaseWkshNameOnAfterValidat();
                    end;
                }
                field("Create Production Order"; Rec."Create Production Order")
                {
                    ApplicationArea = Planning;

                    trigger OnValidate()
                    begin
                        ProdReqWkshTemplateEnable :=
                          Rec."Create Production Order" = Rec."Create Production Order"::"Copy to Req. Wksh";
                        ProdWkshNameEnable :=
                          Rec."Create Production Order" = Rec."Create Production Order"::"Copy to Req. Wksh";
                        CreateProductionOrderOnAfterVa();
                    end;
                }
                field("Prod. Req. Wksh. Template"; Rec."Prod. Req. Wksh. Template")
                {
                    ApplicationArea = Manufacturing;
                    Enabled = ProdReqWkshTemplateEnable;

                    trigger OnValidate()
                    begin
                        ProdReqWkshTemplateOnAfterVali();
                    end;
                }
                field("Prod. Wksh. Name"; Rec."Prod. Wksh. Name")
                {
                    ApplicationArea = Manufacturing;
                    Enabled = ProdWkshNameEnable;

                    trigger OnValidate()
                    begin
                        ProdWkshNameOnAfterValidate();
                    end;
                }
                field("Create Transfer Order"; Rec."Create Transfer Order")
                {
                    ApplicationArea = Location;

                    trigger OnValidate()
                    begin
                        TransferReqWkshTemplateEnable :=
                          Rec."Create Transfer Order" = Rec."Create Transfer Order"::"Copy to Req. Wksh";
                        TransferWkshNameEnable :=
                          Rec."Create Transfer Order" = Rec."Create Transfer Order"::"Copy to Req. Wksh";
                        CreateTransferOrderOnAfterVali();
                    end;
                }
                field("Transfer Req. Wksh. Template"; Rec."Transfer Req. Wksh. Template")
                {
                    ApplicationArea = Planning;
                    Enabled = TransferReqWkshTemplateEnable;

                    trigger OnValidate()
                    begin
                        TransferReqWkshTemplateOnAfter();
                    end;
                }
                field("Transfer Wksh. Name"; Rec."Transfer Wksh. Name")
                {
                    ApplicationArea = Planning;
                    Enabled = TransferWkshNameEnable;

                    trigger OnValidate()
                    begin
                        TransferWkshNameOnAfterValidat();
                    end;
                }
                field("Create Assembly Order"; Rec."Create Assembly Order")
                {
                    ApplicationArea = Assembly;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        PurchaseReqWkshTemplateEnable :=
          Rec."Create Purchase Order" = Rec."Create Purchase Order"::"Copy to Req. Wksh";
        PurchaseWkshNameEnable :=
          Rec."Create Purchase Order" = Rec."Create Purchase Order"::"Copy to Req. Wksh";

        ProdReqWkshTemplateEnable :=
          Rec."Create Production Order" = Rec."Create Production Order"::"Copy to Req. Wksh";
        ProdWkshNameEnable :=
          Rec."Create Production Order" = Rec."Create Production Order"::"Copy to Req. Wksh";

        TransferReqWkshTemplateEnable :=
          Rec."Create Transfer Order" = Rec."Create Transfer Order"::"Copy to Req. Wksh";
        TransferWkshNameEnable :=
          Rec."Create Transfer Order" = Rec."Create Transfer Order"::"Copy to Req. Wksh";
    end;

    trigger OnInit()
    begin
        TransferWkshNameEnable := true;
        TransferReqWkshTemplateEnable := true;
        ProdWkshNameEnable := true;
        ProdReqWkshTemplateEnable := true;
        PurchaseWkshNameEnable := true;
        PurchaseReqWkshTemplateEnable := true;
    end;

    var
        PurchaseReqWkshTemplateEnable: Boolean;
        PurchaseWkshNameEnable: Boolean;
        ProdReqWkshTemplateEnable: Boolean;
        ProdWkshNameEnable: Boolean;
        TransferReqWkshTemplateEnable: Boolean;
        TransferWkshNameEnable: Boolean;

    local procedure CreatePurchaseOrderOnAfterVali()
    begin
        Rec.Modify(true);
    end;

    local procedure CreateProductionOrderOnAfterVa()
    begin
        Rec.Modify(true);
    end;

    local procedure CreateTransferOrderOnAfterVali()
    begin
        Rec.Modify(true);
    end;

    local procedure PurchaseReqWkshTemplateOnAfter()
    begin
        Rec."Purchase Wksh. Name" := '';
        Rec.Modify(true);
    end;

    local procedure PurchaseWkshNameOnAfterValidat()
    begin
        Rec.Modify(true);
    end;

    local procedure ProdReqWkshTemplateOnAfterVali()
    begin
        Rec."Prod. Wksh. Name" := '';
        Rec.Modify(true);
    end;

    local procedure ProdWkshNameOnAfterValidate()
    begin
        Rec.Modify(true);
    end;

    local procedure TransferReqWkshTemplateOnAfter()
    begin
        Rec."Transfer Wksh. Name" := '';
        Rec.Modify(true);
    end;

    local procedure TransferWkshNameOnAfterValidat()
    begin
        Rec.Modify(true);
    end;
}

