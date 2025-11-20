// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Journal;

using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Item;
using Microsoft.Manufacturing.Planning;
using System.Security.User;

page 99000886 "Subcontracting Worksheet"
{
    ApplicationArea = Manufacturing;
    AutoSplitKey = true;
    Caption = 'Subcontracting Worksheets';
    DataCaptionFields = "Journal Batch Name";
    DelayedInsert = true;
    PageType = Worksheet;
    SaveValues = true;
    SourceTable = "Requisition Line";
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            field(CurrentJnlBatchName; CurrentJnlBatchName)
            {
                ApplicationArea = Manufacturing;
                Caption = 'Name';
                Lookup = true;
                ToolTip = 'Specifies the name of the journal batch of the subcontracting worksheet.';

                trigger OnLookup(var Text: Text): Boolean
                begin
                    CurrPage.SaveRecord();
                    ReqJnlManagement.LookupName(CurrentJnlBatchName, Rec);
                    CurrPage.Update(false);
                end;

                trigger OnValidate()
                begin
                    ReqJnlManagement.CheckName(CurrentJnlBatchName, Rec);
                    CurrentJnlBatchNameOnAfterVali();
                end;
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field(Type; Rec.Type)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the type of requisition worksheet line you are creating.';

                    trigger OnValidate()
                    begin
                        ReqJnlManagement.GetDescriptionAndRcptName(Rec, Description2, BuyFromVendorName);
                    end;
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';

                    trigger OnValidate()
                    var
                        Item: Record "Item";
                    begin
                        ReqJnlManagement.GetDescriptionAndRcptName(Rec, Description2, BuyFromVendorName);
                        if Rec."Variant Code" = '' then
                            VariantCodeMandatory := Item.IsVariantMandatory(Rec.Type = Rec.Type::Item, Rec."No.");
                    end;
                }
                field("Accept Action Message"; Rec."Accept Action Message")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies whether to accept the action message proposed for the line.';
                }
                field("Action Message"; Rec."Action Message")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies an action to take to rebalance the demand-supply situation.';
                }
                field("Prod. Order No."; Rec."Prod. Order No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number of the related production order.';
                }
                field("Operation No."; Rec."Operation No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the operation number for this routing line.';
                }
                field("Work Center No."; Rec."Work Center No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the work center number of the journal line.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies text that describes the entry.';
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies additional text describing the entry, or a remark about the requisition worksheet line.';
                    Visible = false;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Manufacturing;
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
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies a code for an inventory location where the items that are being ordered will be registered.';
                    Visible = false;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number of units of the item.';
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number of the vendor who will ship the items in the purchase order.';

                    trigger OnValidate()
                    begin
                        ReqJnlManagement.GetDescriptionAndRcptName(Rec, Description2, BuyFromVendorName);
                    end;
                }
                field("Order Address Code"; Rec."Order Address Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the order address of the related vendor.';
                    Visible = false;
                }
                field("Vendor Item No."; Rec."Vendor Item No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number that the vendor uses for this item.';
                }
                field("Sell-to Customer No."; Rec."Sell-to Customer No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number of the customer.';
                    Visible = false;
                }
                field("Ship-to Code"; Rec."Ship-to Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies a code for an alternate shipment address if you want to ship to another address than the one that has been entered automatically. This field is also used in case of drop shipment.';
                    Visible = false;
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Manufacturing;
                    AssistEdit = true;
                    ToolTip = 'Specifies the currency code for the requisition lines.';
                    Visible = false;

                    trigger OnAssistEdit()
                    var
                        ChangeExchangeRate: Page "Change Exchange Rate";
                    begin
                        ChangeExchangeRate.SetParameter(Rec."Currency Code", Rec."Currency Factor", WorkDate());
                        if ChangeExchangeRate.RunModal() = ACTION::OK then
                            Rec.Validate("Currency Factor", ChangeExchangeRate.GetParameter());

                        Clear(ChangeExchangeRate);
                    end;
                }
                field("Direct Unit Cost"; Rec."Direct Unit Cost")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the cost of one unit of the selected item or resource.';
                }
                field("Line Discount %"; Rec."Line Discount %")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the discount percentage used to calculate the purchase line discount.';
                    Visible = false;
                }
                field("Order Date"; Rec."Order Date")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the order date that will apply to the requisition worksheet line.';
                    Visible = false;
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the date when you can expect to receive the items.';
                }
                field("Requester ID"; Rec."Requester ID")
                {
                    ApplicationArea = Manufacturing;
                    LookupPageID = "User Lookup";
                    ToolTip = 'Specifies the ID of the user who is ordering the items on the line.';
                    Visible = false;
                }
                field(Confirmed; Rec.Confirmed)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies whether the items on the line have been approved for purchase.';
                    Visible = false;
                }
            }
            group(Control20)
            {
                ShowCaption = false;
                fixed(Control1901776201)
                {
                    ShowCaption = false;
                    group(Control1902759801)
                    {
                        Caption = 'Description';
                        field(Description2; Description2)
                        {
                            ApplicationArea = Manufacturing;
                            Editable = false;
                            ShowCaption = false;
                            ToolTip = 'Specifies an additional part of the worksheet description.';
                        }
                    }
                    group("Buy-from Vendor Name")
                    {
                        Caption = 'Buy-from Vendor Name';
                        field(BuyFromVendorName; BuyFromVendorName)
                        {
                            ApplicationArea = Manufacturing;
                            Caption = 'Buy-from Vendor Name';
                            Editable = false;
                            ToolTip = 'Specifies the vendor''s name.';
                        }
                    }
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
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action(Card)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Card';
                    Image = EditLines;
                    RunObject = Codeunit "Req. Wksh.-Show Card";
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or change detailed information about the record on the document or journal line.';
                }
                action("Item &Tracking Lines")
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Item &Tracking Lines';
                    Image = ItemTrackingLines;
                    ShortCutKey = 'Ctrl+Alt+I';
                    ToolTip = 'View or edit serial, lot and package numbers that are assigned to the item on the document or journal line.';

                    trigger OnAction()
                    begin
                        Rec.OpenItemTrackingLines();
                    end;
                }
                action(Dimensions)
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        Rec.ShowDimensions();
                        CurrPage.SaveRecord();
                    end;
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Calculate Subcontracts")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Calculate Subcontracts';
                    Ellipsis = true;
                    Image = Calculate;
                    ToolTip = 'Calculate the external work centers that are managed by a supplier under contract.';

                    trigger OnAction()
                    var
                        CalculateSubContract: Report "Calculate Subcontracts";
                    begin
                        CalculateSubContract.SetWkShLine(Rec);
                        CalculateSubContract.RunModal();
                    end;
                }
                action(CarryOutActionMessage)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Carry &Out Action Message';
                    Ellipsis = true;
                    Image = CarryOutActionMessage;
                    ToolTip = 'Use a batch job to help you create actual supply orders from the order proposals.';

                    trigger OnAction()
                    begin
                        CarryOutActionMsg();
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref("Calculate Subcontracts_Promoted"; "Calculate Subcontracts")
                {
                }
                actionref(CarryOutActionMessage_Promoted; CarryOutActionMessage)
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Line', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref("Item &Tracking Lines_Promoted"; "Item &Tracking Lines")
                {
                }
                actionref(Dimensions_Promoted; Dimensions)
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        ReqJnlManagement.GetDescriptionAndRcptName(Rec, Description2, BuyFromVendorName);
    end;

    trigger OnAfterGetRecord()
    var
        Item: Record Item;
    begin
        if Rec."Variant Code" = '' then
            VariantCodeMandatory := Item.IsVariantMandatory(Rec.Type = Rec.Type::Item, Rec."No.");
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        ReqJnlManagement.SetUpNewLine(Rec, xRec);
    end;

    trigger OnOpenPage()
    var
        JnlSelected: Boolean;
    begin
        OpenedFromBatch := (Rec."Journal Batch Name" <> '') and (Rec."Worksheet Template Name" = '');
        if OpenedFromBatch then begin
            CurrentJnlBatchName := Rec."Journal Batch Name";
            ReqJnlManagement.OpenJnl(CurrentJnlBatchName, Rec);
            exit;
        end;
        ReqJnlManagement.WkshTemplateSelection(
            PAGE::"Subcontracting Worksheet", false, "Req. Worksheet Template Type"::"For. Labor", Rec, JnlSelected);
        if not JnlSelected then
            Error('');
        ReqJnlManagement.OpenJnl(CurrentJnlBatchName, Rec);
    end;

    var
        ReqJnlManagement: Codeunit ReqJnlManagement;
        CurrentJnlBatchName: Code[10];
        OpenedFromBatch: Boolean;
        VariantCodeMandatory: Boolean;

    protected var
        Description2: Text[100];
        BuyFromVendorName: Text[100];

    local procedure CurrentJnlBatchNameOnAfterVali()
    begin
        CurrPage.SaveRecord();
        ReqJnlManagement.SetName(CurrentJnlBatchName, Rec);
        CurrPage.Update(false);
    end;

    local procedure CarryOutActionMsg()
    var
        CarryOutActionMsgReq: Report "Carry Out Action Msg. - Req.";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCarryOutActionMsg(Rec, IsHandled);
        if IsHandled then
            exit;

        CarryOutActionMsgReq.SetReqWkshLine(Rec);
        CarryOutActionMsgReq.RunModal();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCarryOutActionMsg(var RequisitionLine: Record "Requisition Line"; var IsHandled: Boolean);
    begin
    end;
}

