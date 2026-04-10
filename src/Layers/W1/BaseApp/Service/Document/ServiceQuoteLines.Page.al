// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Attachment;
using Microsoft.Foundation.ExtendedText;
using Microsoft.Inventory.Availability;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Location;
using Microsoft.Service.Setup;

page 5966 "Service Quote Lines"
{
    AutoSplitKey = true;
    Caption = 'Service Quote Lines';
    DataCaptionFields = "Document Type", "Document No.";
    DelayedInsert = true;
    PageType = Worksheet;
    PopulateAllFields = true;
    SourceTable = "Service Line";

    layout
    {
        area(content)
        {
            field(SelectionFilter; SelectionFilter)
            {
                ApplicationArea = Service;
                Caption = 'Service Quote Lines Filter';
                OptionCaption = 'All,Per Selected Service Item Line,Service Item Line Non-Related';
                ToolTip = 'Specifies a selection filter.';

                trigger OnValidate()
                begin
                    SelectionFilterOnAfterValidate();
                end;
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field("Service Item Line No."; Rec."Service Item Line No.")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Service Item No."; Rec."Service Item No.")
                {
                    ApplicationArea = Service;
                }
                field("Service Item Serial No."; Rec."Service Item Serial No.")
                {
                    ApplicationArea = ItemTracking;
                    Visible = false;
                }
                field("Service Item Line Description"; Rec."Service Item Line Description")
                {
                    ApplicationArea = Service;
                    DrillDown = false;
                    Visible = false;
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Service;

                    trigger OnValidate()
                    begin
                        NoOnAfterValidate();
                    end;
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Service;

                    trigger OnValidate()
                    var
                        Item: Record "Item";
                    begin
                        if Rec."Variant Code" = '' then
                            VariantCodeMandatory := Item.IsVariantMandatory(Rec.Type = Rec.Type::Item, Rec."No.");
                        NoOnAfterValidate();
                    end;
                }
                field("Item Reference No."; Rec."Item Reference No.")
                {
                    AccessByPermission = tabledata "Item Reference" = R;
                    ApplicationArea = Service, ItemReferences;
                    QuickEntry = false;
                    Visible = ItemReferenceVisible;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        ServItemReferenceMgt: Codeunit "Serv. Item Reference Mgt.";
                    begin
                        ServItemReferenceMgt.ServiceReferenceNoLookup(Rec);
                        NoOnAfterValidate();
                        CurrPage.Update();
                    end;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
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
                    ApplicationArea = Service;
                }
                field(Nonstock; Rec.Nonstock)
                {
                    ApplicationArea = Service;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Service;
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies an additional description of the item, resource, or cost.';
                    Visible = false;
                }
                field("Substitution Available"; Rec."Substitution Available")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Work Type Code"; Rec."Work Type Code")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Service;
                    BlankZero = true;
                    DecimalPlaces = 0 : 5;

                    trigger OnValidate()
                    begin
                        QuantityOnAfterValidate();
                    end;
                }
                field("Fault Reason Code"; Rec."Fault Reason Code")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Fault Area Code"; Rec."Fault Area Code")
                {
                    ApplicationArea = Service;
                    Visible = FaultAreaCodeVisible;
                }
                field("Symptom Code"; Rec."Symptom Code")
                {
                    ApplicationArea = Service;
                    Visible = SymptomCodeVisible;
                }
                field("Fault Code"; Rec."Fault Code")
                {
                    ApplicationArea = Service;
                    Visible = FaultCodeVisible;
                }
                field("Resolution Code"; Rec."Resolution Code")
                {
                    ApplicationArea = Service;
                    Visible = ResolutionCodeVisible;
                }
                field("Serv. Price Adjmt. Gr. Code"; Rec."Serv. Price Adjmt. Gr. Code")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Unit Price"; Rec."Unit Price")
                {
                    ApplicationArea = Service;
                    BlankZero = true;
                }
                field("Line Discount %"; Rec."Line Discount %")
                {
                    ApplicationArea = Service;
                    BlankZero = true;
                }
                field("Line Discount Amount"; Rec."Line Discount Amount")
                {
                    ApplicationArea = Service;
                    BlankZero = true;
                }
                field("Line Discount Type"; Rec."Line Discount Type")
                {
                    ApplicationArea = Service;
                }
                field("Allow Invoice Disc."; Rec."Allow Invoice Disc.")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Inv. Discount Amount"; Rec."Inv. Discount Amount")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Line Amount"; Rec."Line Amount")
                {
                    ApplicationArea = Service;
                    BlankZero = true;
                }
                field("Tax Liable"; Rec."Tax Liable")
                {
                    ApplicationArea = SalesTax;
                    Editable = false;
                    Visible = false;
                }
                field("Tax Area Code"; Rec."Tax Area Code")
                {
                    ApplicationArea = SalesTax;
                    Visible = false;
                }
                field("Tax Group Code"; Rec."Tax Group Code")
                {
                    ApplicationArea = SalesTax;
                }
                field("Exclude Warranty"; Rec."Exclude Warranty")
                {
                    ApplicationArea = Service;
                }
                field("Exclude Contract Discount"; Rec."Exclude Contract Discount")
                {
                    ApplicationArea = Service;
                }
                field(Warranty; Rec.Warranty)
                {
                    ApplicationArea = Service;
                }
                field("Warranty Disc. %"; Rec."Warranty Disc. %")
                {
                    ApplicationArea = Service;
                    BlankZero = true;
                    Visible = false;
                }
                field("Contract No."; Rec."Contract No.")
                {
                    ApplicationArea = Service;
                    Editable = false;
                }
                field("Contract Disc. %"; Rec."Contract Disc. %")
                {
                    ApplicationArea = Service;
                    BlankZero = true;
                    Visible = false;
                }
                field("VAT %"; Rec."VAT %")
                {
                    ApplicationArea = Service;
                    BlankZero = true;
                    Visible = false;
                }
                field("VAT Base Amount"; Rec."VAT Base Amount")
                {
                    ApplicationArea = Service;
                    BlankZero = true;
                    Visible = false;
                }
                field("Amount Including VAT"; Rec."Amount Including VAT")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Unit Cost (LCY)"; Rec."Unit Cost (LCY)")
                {
                    ApplicationArea = Service;
                    BlankZero = true;
                    ToolTip = 'Specifies the cost, in LCY, of one unit of the item or resource on the line.';
                    Visible = false;
                }
                field("Gen. Bus. Posting Group"; Rec."Gen. Bus. Posting Group")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Gen. Prod. Posting Group"; Rec."Gen. Prod. Posting Group")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Posting Group"; Rec."Posting Group")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Service;
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    Visible = false;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    Visible = false;
                }
                field("ShortcutDimCode[3]"; ShortcutDimCode[3])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,3';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(3),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(3, ShortcutDimCode[3]);
                    end;
                }
                field("ShortcutDimCode[4]"; ShortcutDimCode[4])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,4';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(4),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(4, ShortcutDimCode[4]);
                    end;
                }
                field("ShortcutDimCode[5]"; ShortcutDimCode[5])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,5';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(5),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(5, ShortcutDimCode[5]);
                    end;
                }
                field("ShortcutDimCode[6]"; ShortcutDimCode[6])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,6';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(6),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(6, ShortcutDimCode[6]);
                    end;
                }
                field("ShortcutDimCode[7]"; ShortcutDimCode[7])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,7';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(7),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(7, ShortcutDimCode[7]);
                    end;
                }
                field("ShortcutDimCode[8]"; ShortcutDimCode[8])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,8';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(8),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(8, ShortcutDimCode[8]);
                    end;
                }
            }
        }
        area(factboxes)
        {
            part("Attached Documents List"; "Doc. Attachment List Factbox")
            {
                ApplicationArea = Service;
                Caption = 'Documents';
                UpdatePropagation = Both;
                SubPageLink = "Table ID" = const(Database::"Service Line"),
                              "No." = field("Document No."),
                              "Document Type" = field("Document Type"),
                              "Line No." = field("Line No.");
                Visible = false;
            }
            part(Control1904739907; "Service Line FactBox")
            {
                ApplicationArea = Service;
                SubPageLink = "Document Type" = field("Document Type"),
                              "Document No." = field("Document No."),
                              "Line No." = field("Line No.");
                Visible = false;
            }
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
                group("Item Availability by")
                {
                    Caption = 'Item Availability by';
                    Image = ItemAvailability;
                    action("Event")
                    {
                        ApplicationArea = Service;
                        Caption = 'Event';
                        Image = "Event";
                        ToolTip = 'View how the actual and the projected available balance of an item will develop over time according to supply and demand events.';

                        trigger OnAction()
                        begin
                            ServAvailabilityMgt.ShowItemAvailabilityFromServLine(Rec, "Item Availability Type"::"Event");
                        end;
                    }
                    action(Period)
                    {
                        ApplicationArea = Service;
                        Caption = 'Period';
                        Image = Period;
                        ToolTip = 'View the projected quantity of the item over time according to time periods, such as day, week, or month.';

                        trigger OnAction()
                        begin
                            ServAvailabilityMgt.ShowItemAvailabilityFromServLine(Rec, "Item Availability Type"::Period);
                        end;
                    }
                    action(Variant)
                    {
                        ApplicationArea = Planning;
                        Caption = 'Variant';
                        Image = ItemVariant;
                        ToolTip = 'View or edit the item''s variants. Instead of setting up each color of an item as a separate item, you can set up the various colors as variants of the item.';

                        trigger OnAction()
                        begin
                            ServAvailabilityMgt.ShowItemAvailabilityFromServLine(Rec, "Item Availability Type"::Variant);
                        end;
                    }
                    action(Location)
                    {
                        AccessByPermission = TableData Location = R;
                        ApplicationArea = Location;
                        Caption = 'Location';
                        Image = Warehouse;
                        ToolTip = 'View the actual and projected quantity of the item per location.';

                        trigger OnAction()
                        begin
                            ServAvailabilityMgt.ShowItemAvailabilityFromServLine(Rec, "Item Availability Type"::Location);
                        end;
                    }
                    action(Lot)
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Lot';
                        Image = LotInfo;
                        RunObject = Page "Item Availability by Lot No.";
                        RunPageLink = "No." = field("No."),
                            "Location Filter" = field("Location Code"),
                            "Variant Filter" = field("Variant Code");
                        ToolTip = 'View the current and projected quantity of the item in each lot.';
                    }
                    action("BOM Level")
                    {
                        ApplicationArea = Service;
                        Caption = 'BOM Level';
                        Image = BOMLevel;
                        ToolTip = 'View availability figures for items on bills of materials that show how many units of a parent item you can make based on the availability of child items.';

                        trigger OnAction()
                        begin
                            ServAvailabilityMgt.ShowItemAvailabilityFromServLine(Rec, "Item Availability Type"::BOM);
                        end;
                    }
                }
                action(ItemTrackingLines)
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
                action("Select Item &Substitution")
                {
                    ApplicationArea = Service;
                    Caption = 'Select Item &Substitution';
                    Image = SelectItemSubstitution;
                    ToolTip = 'Select another item that has been set up to be sold instead of the original item if it is unavailable.';

                    trigger OnAction()
                    begin
                        Rec.ShowItemSub();
                        CurrPage.Update(true);
                    end;
                }
                action(DocAttach)
                {
                    ApplicationArea = Service;
                    Caption = 'Attachments';
                    Image = Attach;
                    ToolTip = 'Add a file as an attachment. You can attach images as well as documents.';

                    trigger OnAction()
                    var
                        DocumentAttachmentDetails: Page "Document Attachment Details";
                        RecRef: RecordRef;
                    begin
                        RecRef.GetTable(Rec);
                        DocumentAttachmentDetails.OpenForRecRef(RecRef);
                        DocumentAttachmentDetails.RunModal();
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
                action(CalculateInvoiceDiscount)
                {
                    ApplicationArea = Service;
                    Caption = 'Calculate &Invoice Discount';
                    Image = CalculateInvoiceDiscount;
                    ToolTip = 'Calculate the invoice discount that applies to the service order.';

                    trigger OnAction()
                    begin
                        CODEUNIT.Run(CODEUNIT::"Service-Disc. (Yes/No)", Rec);
                    end;
                }
                action("Get Price")
                {
                    ApplicationArea = Service;
                    Caption = 'Get Price';
                    Image = Price;
                    ToolTip = 'Insert the lowest possible price in the Unit Price field according to any special price that you have set up.';

                    trigger OnAction()
                    begin
                        Rec.PickPrice();
                        CurrPage.Update();
                    end;
                }
                action("Get Li&ne Discount")
                {
                    ApplicationArea = Service;
                    Caption = 'Get Li&ne Discount';
                    Image = LineDiscount;
                    ToolTip = 'Insert the best possible discount in the Line Discount field according to any special discounts that you have set up.';

                    trigger OnAction()
                    begin
                        Rec.PickDiscount();
                        CurrPage.Update();
                    end;
                }
                action("Insert &Ext. Texts")
                {
                    AccessByPermission = TableData "Extended Text Header" = R;
                    ApplicationArea = Service;
                    Caption = 'Insert &Ext. Texts';
                    Image = Text;
                    ToolTip = 'Insert the extended item description that is set up for the item that is being processed on the line.';

                    trigger OnAction()
                    begin
                        InsertExtendedText(true);
                    end;
                }
                action("Insert &Starting Fee")
                {
                    ApplicationArea = Service;
                    Caption = 'Insert &Starting Fee';
                    Image = InsertStartingFee;
                    ToolTip = 'Add a general starting fee for the service order.';

                    trigger OnAction()
                    begin
                        InsertStartFee();
                    end;
                }
                action("Insert &Travel Fee")
                {
                    ApplicationArea = Service;
                    Caption = 'Insert &Travel Fee';
                    Image = InsertTravelFee;
                    ToolTip = 'Add a general travel fee for the service order.';

                    trigger OnAction()
                    begin
                        InsertTravelFee();
                    end;
                }
                action(SelectMultiItems)
                {
                    AccessByPermission = TableData Item = R;
                    ApplicationArea = Service;
                    Caption = 'Select items';
                    Ellipsis = true;
                    Image = NewItem;
                    ToolTip = 'Add two or more items from the full list of available items.';

                    trigger OnAction()
                    begin
                        Rec.SelectMultipleItems();
                    end;
                }
                action("Split &Resource Line")
                {
                    ApplicationArea = Service;
                    Caption = 'Split &Resource Line';
                    Image = Split;
                    ToolTip = 'Split planning lines of type Budget and Billable into two separate planning lines: Budget and Billable.';

                    trigger OnAction()
                    begin
                        Rec.SplitResourceLine();
                    end;
                }
                action("Ca&talog Items")
                {
                    AccessByPermission = TableData "Nonstock Item" = R;
                    ApplicationArea = Service;
                    Caption = 'Ca&talog Items';
                    Image = NonStockItem;
                    ToolTip = 'View the list of items that you do not carry in inventory. ';

                    trigger OnAction()
                    begin
                        Rec.ShowNonstock();
                        CurrPage.Update();
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Insert &Ext. Texts_Promoted"; "Insert &Ext. Texts")
                {
                }
                actionref("Insert &Travel Fee_Promoted"; "Insert &Travel Fee")
                {
                }
                actionref("Get Price_Promoted"; "Get Price")
                {
                }
                actionref(SelectMultiItems_Promoted; SelectMultiItems)
                {
                }
            }
            group(Category_Line)
            {
                Caption = 'Line';

                actionref(ItemTrackingLines_Promoted; ItemTrackingLines)
                {
                }
                actionref(Dimensions_Promoted; Dimensions)
                {
                }
                actionref("Select Item &Substitution_Promoted"; "Select Item &Substitution")
                {
                }
                actionref(DocAttach_Promoted; DocAttach)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        Item: Record Item;
    begin
        Rec.ShowShortcutDimCode(ShortcutDimCode);
        if Rec."Variant Code" = '' then
            VariantCodeMandatory := Item.IsVariantMandatory(Rec.Type = Rec.Type::Item, Rec."No.");
    end;

    trigger OnDeleteRecord(): Boolean
    var
        ServiceLineReserve: Codeunit "Service Line-Reserve";
    begin
        if (Rec.Quantity <> 0) and Rec.ItemExists(Rec."No.") then begin
            Commit();
            if not ServiceLineReserve.DeleteLineConfirm(Rec) then
                exit(false);
            ServiceLineReserve.DeleteLine(Rec);
        end;
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Rec."Line No." := Rec.GetLineNo();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Clear(ShortcutDimCode);

        ServHeader.Get(Rec."Document Type", Rec."Document No.");
        if ServHeader."Link Service to Service Item" then
            if SelectionFilter <> SelectionFilter::"Lines Not Item Related" then
                Rec.Validate("Service Item Line No.", ServItemLineNo)
            else
                Rec.Validate("Service Item Line No.", 0)
        else
            Rec.Validate("Service Item Line No.", 0);
    end;

    trigger OnOpenPage()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnOpenPage(Rec, FaultAreaCodeVisible, SymptomCodeVisible, FaultCodeVisible, ResolutionCodeVisible, IsHandled);
        if not IsHandled then begin
            Clear(SelectionFilter);
            OnOpenPageOnBeforeSetSelectionFilter(SelectionFilter);
            SetSelectionFilter();
            SetItemReferenceVisibility();

            ServMgtSetup.Get();
            case ServMgtSetup."Fault Reporting Level" of
                ServMgtSetup."Fault Reporting Level"::None:
                    begin
                        FaultAreaCodeVisible := false;
                        SymptomCodeVisible := false;
                        FaultCodeVisible := false;
                        ResolutionCodeVisible := false;
                    end;
                ServMgtSetup."Fault Reporting Level"::Fault:
                    begin
                        FaultAreaCodeVisible := false;
                        SymptomCodeVisible := false;
                        FaultCodeVisible := true;
                        ResolutionCodeVisible := true;
                    end;
                ServMgtSetup."Fault Reporting Level"::"Fault+Symptom":
                    begin
                        FaultAreaCodeVisible := false;
                        SymptomCodeVisible := true;
                        FaultCodeVisible := true;
                        ResolutionCodeVisible := true;
                    end;
                ServMgtSetup."Fault Reporting Level"::"Fault+Symptom+Area (IRIS)":
                    begin
                        FaultAreaCodeVisible := true;
                        SymptomCodeVisible := true;
                        FaultCodeVisible := true;
                        ResolutionCodeVisible := true;
                    end;
            end;
        end;

        OnAfterOnOpenPage(ServMgtSetup, FaultAreaCodeVisible, SymptomCodeVisible, FaultCodeVisible, ResolutionCodeVisible);
    end;

    var
        ServMgtSetup: Record "Service Mgt. Setup";
        ServHeader: Record "Service Header";
        ServAvailabilityMgt: Codeunit "Serv. Availability Mgt.";
        ServItemLineNo: Integer;
        SelectionFilter: Option "All Service Lines","Lines per Selected Service Item","Lines Not Item Related";
        ItemReferenceVisible: Boolean;
        VariantCodeMandatory: Boolean;

    protected var
        ShortcutDimCode: array[8] of Code[20];
        FaultAreaCodeVisible: Boolean;
        SymptomCodeVisible: Boolean;
        FaultCodeVisible: Boolean;
        ResolutionCodeVisible: Boolean;

    procedure Initialize(ServItemLine: Integer)
    begin
        ServItemLineNo := ServItemLine;
        OnAfterInitialize(Rec, ServItemLineNo, SelectionFilter);
    end;

    procedure SetSelectionFilter()
    begin
        case SelectionFilter of
            SelectionFilter::"All Service Lines":
                Rec.SetRange("Service Item Line No.");
            SelectionFilter::"Lines per Selected Service Item":
                Rec.SetRange("Service Item Line No.", ServItemLineNo);
            SelectionFilter::"Lines Not Item Related":
                Rec.SetRange("Service Item Line No.", 0);
        end;
        CurrPage.Update(false);
    end;

    procedure InsertExtendedText(Unconditionally: Boolean)
    var
        ServiceTransferExtText: Codeunit "Service Transfer Ext. Text";
    begin
        OnBeforeInsertExtendedText(Rec);
        if ServiceTransferExtText.ServCheckIfAnyExtText(Rec, Unconditionally) then begin
            CurrPage.SaveRecord();
            ServiceTransferExtText.InsertServExtText(Rec);
        end;
        if ServiceTransferExtText.MakeUpdate() then
            CurrPage.Update();
    end;

    local procedure InsertStartFee()
    var
        ServOrderMgt: Codeunit ServOrderManagement;
    begin
        Clear(ServOrderMgt);
        if ServOrderMgt.InsertServCost(Rec, 1, false) then
            CurrPage.Update();
    end;

    local procedure InsertTravelFee()
    var
        ServOrderMgt: Codeunit ServOrderManagement;
    begin
        Clear(ServOrderMgt);
        if ServOrderMgt.InsertServCost(Rec, 0, false) then
            CurrPage.Update();
    end;

    protected procedure NoOnAfterValidate()
    begin
        InsertExtendedText(false);
    end;

    protected procedure QuantityOnAfterValidate()
    begin
        if Rec.Reserve = Rec.Reserve::Always then begin
            CurrPage.SaveRecord();
            Rec.AutoReserve();
        end;
    end;

    local procedure SelectionFilterOnAfterValidate()
    begin
        CurrPage.Update();
        SetSelectionFilter();
    end;

    local procedure SetItemReferenceVisibility()
    var
        ItemReference: Record "Item Reference";
    begin
        ItemReferenceVisible := not ItemReference.IsEmpty();
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeOnOpenPage(var ServiceLine: Record "Service Line"; var FaultAreaCodeVisible: Boolean; var SymptomCodeVisible: Boolean; var FaultCodeVisible: Boolean; var ResolutionCodeVisible: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterOnOpenPage(var ServMgtSetup: Record "Service Mgt. Setup"; var FaultAreaCodeVisible: Boolean; var SymptomCodeVisible: Boolean; var FaultCodeVisible: Boolean; var ResolutionCodeVisible: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertExtendedText(var ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterInitialize(var ServiceLine: Record "Service Line"; var ServItemLineNo: Integer; var SelectionFilter: Option "All Service Lines","Lines per Selected Service Item","Lines Not Item Related");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOpenPageOnBeforeSetSelectionFilter(var SelectionFilter: Option "All Service Lines","Lines per Selected Service Item","Lines Not Item Related");
    begin
    end;
}
