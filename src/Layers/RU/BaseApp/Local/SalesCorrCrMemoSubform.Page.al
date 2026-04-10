#pragma warning disable AA0247
page 14974 "Sales Corr. Cr. Memo Subform"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    DelayedInsert = true;
    LinksAllowed = false;
    MultipleNewLines = true;
    PageType = ListPart;
    SourceTable = "Sales Line";
    SourceTableView = where("Document Type" = filter("Credit Memo"));

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Original Type"; Rec."Original Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the corrected document.';
                }
                field("Original No."; Rec."Original No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the record.';
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';

                    trigger OnValidate()
                    begin
                        Rec.ShowShortcutDimCode(ShortcutDimCode);
                        NoOnAfterValidate();
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with this line.';
                }
                field("Quantity (Before)"; Rec."Quantity (Before)")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Quantity (After)"; Rec."Quantity (After)")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Unit Price (Before)"; Rec."Unit Price (Before)")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Unit Price (After)"; Rec."Unit Price (After)")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Amount (Before)"; Rec."Amount (Before)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount before the correction.';
                }
                field("Amount (After)"; Rec."Amount (After)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount after the correction.';
                }
                field("Amount Including VAT (Before)"; Rec."Amount Including VAT (Before)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount, including VAT, before the correction.';
                }
                field("Amount Including VAT (After)"; Rec."Amount Including VAT (After)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount, including VAT, after the correction.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("E&xplode BOM")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'E&xplode BOM';
                    Image = ExplodeBOM;

                    trigger OnAction()
                    begin
                        ExplodeBOM();
                    end;
                }
                action("Insert &Ext. Texts")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Insert &Ext. Texts';
                    Image = Text;
                    ToolTip = 'Insert the extended item description that is set up for the item that is being processed on the line.';

                    trigger OnAction()
                    begin
                        InsertExtendedText(true);
                    end;
                }
                action("Get Return &Receipt Lines")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Get Return &Receipt Lines';
                    Ellipsis = true;
                    Image = ReturnReceipt;
                    ToolTip = 'Select a posted return receipt for the item that you want to assign the item charge to, for example, if you received an invoice for the item charge after you posted the original return receipt.';

                    trigger OnAction()
                    begin
                        GetReturnReceipt();
                    end;
                }
            }
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                group("Item Availability by")
                {
                    Caption = 'Item Availability by';
                    Image = ItemAvailability;
                    action("Event")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Event';
                        Image = "Event";

                        trigger OnAction()
                        begin
                            SalesAvailabilityMgt.ShowItemAvailabilityFromSalesLine(Rec, "Item Availability Type"::"Event")
                        end;
                    }
                    action(Period)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Period';
                        Image = Period;

                        trigger OnAction()
                        begin
                            SalesAvailabilityMgt.ShowItemAvailabilityFromSalesLine(Rec, "Item Availability Type"::Period)
                        end;
                    }
                    action(Variant)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Variant';
                        Image = ItemVariant;
                        ToolTip = 'View or edit the item''s variants. Instead of setting up each color of an item as a separate item, you can set up the various colors as variants of the item.';

                        trigger OnAction()
                        begin
                            SalesAvailabilityMgt.ShowItemAvailabilityFromSalesLine(Rec, "Item Availability Type"::Variant)
                        end;
                    }
                    action(Location)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Location';
                        Image = Warehouse;
                        ToolTip = 'View the actual and projected quantity of the item per location.';

                        trigger OnAction()
                        begin
                            SalesAvailabilityMgt.ShowItemAvailabilityFromSalesLine(Rec, "Item Availability Type"::Location)
                        end;
                    }
                    action("BOM Level")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'BOM Level';
                        Image = BOMLevel;

                        trigger OnAction()
                        begin
                            SalesAvailabilityMgt.ShowItemAvailabilityFromSalesLine(Rec, "Item Availability Type"::BOM)
                        end;
                    }
                }
                action(Dimensions)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Shift+Ctrl+D';

                    trigger OnAction()
                    begin
                        Rec.ShowDimensions();
                    end;
                }
                action("Co&mments")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Co&mments';
                    Image = ViewComments;

                    trigger OnAction()
                    begin
                        Rec.ShowLineComments();
                    end;
                }
                action("Item Charge &Assignment")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Item Charge &Assignment';
                    ToolTip = 'Record additional direct costs, for example for freight. This action is available only for Charge (Item) line types.';

                    trigger OnAction()
                    begin
                        ItemChargeAssgnt();
                    end;
                }
                action(ItemTrackingLines)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Item &Tracking Lines';
                    Image = ItemTrackingLines;
                    ShortCutKey = 'Ctrl+Alt+I';
                    ToolTip = 'View or edit serial, lot and package numbers for the selected item. This action is available only for lines that contain an item.';

                    trigger OnAction()
                    begin
                        Rec.OpenItemTrackingLines();
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Rec.ShowShortcutDimCode(ShortcutDimCode);
    end;

    trigger OnDeleteRecord(): Boolean
    var
        SalesLineReserve: Codeunit "Sales Line-Reserve";
    begin
        if (Rec.Quantity <> 0) and Rec.ItemExists(Rec."No.") then begin
            Commit();
            if not SalesLineReserve.DeleteLineConfirm(Rec) then
                exit(false);
            SalesLineReserve.DeleteLine(Rec);
        end;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.InitType();
        Clear(ShortcutDimCode);
    end;

    var
        TransferExtendedText: Codeunit "Transfer Extended Text";
        SalesAvailabilityMgt: Codeunit "Sales Availability Mgt.";
        ShortcutDimCode: array[8] of Code[20];

    [Scope('OnPrem')]
    procedure ApproveCalcInvDisc()
    begin
        CODEUNIT.Run(CODEUNIT::"Sales-Disc. (Yes/No)", Rec);
    end;

    [Scope('OnPrem')]
    procedure ExplodeBOM()
    begin
        CODEUNIT.Run(CODEUNIT::"Sales-Explode BOM", Rec);
    end;

    [Scope('OnPrem')]
    procedure GetReturnReceipt()
    begin
        CODEUNIT.Run(CODEUNIT::"Sales-Get Return Receipts", Rec);
    end;

    [Scope('OnPrem')]
    procedure InsertExtendedText(Unconditionally: Boolean)
    begin
        if TransferExtendedText.SalesCheckIfAnyExtText(Rec, Unconditionally) then begin
            CurrPage.SaveRecord();
            TransferExtendedText.InsertSalesExtText(Rec);
        end;
        if TransferExtendedText.MakeUpdate() then
            UpdateForm(true);
    end;

    [Scope('OnPrem')]
    procedure ItemChargeAssgnt()
    begin
        Rec.ShowItemChargeAssgnt();
    end;

    [Scope('OnPrem')]
    procedure UpdateForm(SetSaveRecord: Boolean)
    begin
        CurrPage.Update(SetSaveRecord);
    end;

    local procedure NoOnAfterValidate()
    begin
        InsertExtendedText(false);
        if (Rec.Type = Rec.Type::"Charge (Item)") and (Rec."No." <> xRec."No.") and
           (xRec."No." <> '')
        then
            CurrPage.SaveRecord();
    end;
}

