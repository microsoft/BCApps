// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

page 6512 "Item Tracking Code Card"
{
    Caption = 'Item Tracking Code Card';
    PageType = Card;
    SourceTable = "Item Tracking Code";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Code"; Rec.Code)
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the code of the record.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies a description of the item tracking code.';
                }
            }
            group("Serial No.")
            {
                Caption = 'Serial No.';
                group(Control64)
                {
                    Caption = 'General';
                    field("SN Specific Tracking"; Rec."SN Specific Tracking")
                    {
                        ApplicationArea = ItemTracking;
                        ToolTip = 'Specifies that when handling an outbound unit of the item in question, you must always specify which existing serial number to handle.';
                    }
                    field("Create SN Info on Posting"; Rec."Create SN Info on Posting")
                    {
                        ApplicationArea = ItemTracking;
                        ToolTip = 'Specifies that if the Serial No. Information card is missing for the document line, the card will be created during posting.';
                    }
                }
                group(Inbound)
                {
                    Caption = 'Inbound';
                    field("SN Info. Inbound Must Exist"; Rec."SN Info. Inbound Must Exist")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'SN No. Info. Must Exist';
                        ToolTip = 'Specifies that serial numbers on inbound document lines must have an information record in the Serial No. Information Card.';
                    }
                    field("SN Purchase Inbound Tracking"; Rec."SN Purchase Inbound Tracking")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'SN Purchase Tracking';
                        ToolTip = 'Specifies that inbound purchase document lines require serial numbers.';
                    }
                    field("SN Sales Inbound Tracking"; Rec."SN Sales Inbound Tracking")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'SN Sales Tracking';
                        ToolTip = 'Specifies that inbound sales document lines require serial numbers.';
                    }
                    field("SN Pos. Adjmt. Inb. Tracking"; Rec."SN Pos. Adjmt. Inb. Tracking")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'SN Positive Adjmt. Tracking';
                        ToolTip = 'Specifies that inbound item journal lines of type positive entry require serial numbers.';
                    }
                    field("SN Neg. Adjmt. Inb. Tracking"; Rec."SN Neg. Adjmt. Inb. Tracking")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'SN Negative Adjmt. Tracking';
                        ToolTip = 'Specifies that inbound item journal lines of type negative entry require serial numbers.';
                    }
                }
                group(Control82)
                {
                    ShowCaption = false;
                    field("SN Warehouse Tracking"; Rec."SN Warehouse Tracking")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'SN Warehouse Tracking';
                        ToolTip = 'Specifies that warehouse document lines require serial numbers.';
                    }
                    field("SN Transfer Tracking"; Rec."SN Transfer Tracking")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'SN Transfer Tracking';
                        ToolTip = 'Specifies that transfer order lines require serial numbers.';
                    }
                }
                group(Outbound)
                {
                    Caption = 'Outbound';
                    field("SN Info. Outbound Must Exist"; Rec."SN Info. Outbound Must Exist")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'SN No. Info. Must Exist';
                        ToolTip = 'Specifies that serial numbers on outbound document lines must have an information record in the Serial No. Information Card.';
                    }
                    field("SN Purchase Outbound Tracking"; Rec."SN Purchase Outbound Tracking")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'SN Purchase Tracking';
                        ToolTip = 'Specifies that outbound purchase document lines require serial numbers.';
                    }
                    field("SN Sales Outbound Tracking"; Rec."SN Sales Outbound Tracking")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'SN Sales Tracking';
                        ToolTip = 'Specifies that outbound sales document lines require serial numbers.';
                    }
                    field("SN Pos. Adjmt. Outb. Tracking"; Rec."SN Pos. Adjmt. Outb. Tracking")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'SN Positive Adjmt. Tracking';
                        ToolTip = 'Specifies that outbound item journal lines of type positive entry require serial numbers.';
                    }
                    field("SN Neg. Adjmt. Outb. Tracking"; Rec."SN Neg. Adjmt. Outb. Tracking")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'SN Negative Adjmt. Tracking';
                        ToolTip = 'Specifies that outbound item journal lines of type negative entry require serial numbers.';
                    }
                }
            }
            group("Lot No.")
            {
                Caption = 'Lot No.';
                group(Control74)
                {
                    Caption = 'General';
                    field("Lot Specific Tracking"; Rec."Lot Specific Tracking")
                    {
                        ApplicationArea = ItemTracking;
                        ToolTip = 'Specifies that when handling an outbound unit, always specify which existing lot number to handle.';
                    }
                    field("Create Lot No. Info on posting"; Rec."Create Lot No. Info on posting")
                    {
                        ApplicationArea = ItemTracking;
                        ToolTip = 'Specifies that if the Lot No. Information card is missing for the document line, the card will be created during posting.';
                    }
                }
                group(Control47)
                {
                    Caption = 'Inbound';
                    field("Lot Info. Inbound Must Exist"; Rec."Lot Info. Inbound Must Exist")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Lot No. Info. Must Exist';
                        ToolTip = 'Specifies that lot numbers on inbound document lines must have an information record in the Lot No. Information Card.';
                    }
                    field("Lot Purchase Inbound Tracking"; Rec."Lot Purchase Inbound Tracking")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Lot Purchase Tracking';
                        ToolTip = 'Specifies that inbound purchase document lines require a lot number.';
                    }
                    field("Lot Sales Inbound Tracking"; Rec."Lot Sales Inbound Tracking")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Lot Sales Tracking';
                        ToolTip = 'Specifies that inbound sales document lines require a lot number.';
                    }
                    field("Lot Pos. Adjmt. Inb. Tracking"; Rec."Lot Pos. Adjmt. Inb. Tracking")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Lot Positive Adjmt. Tracking';
                        ToolTip = 'Specifies that inbound item journal lines of type positive entry require a lot number.';
                    }
                    field("Lot Neg. Adjmt. Inb. Tracking"; Rec."Lot Neg. Adjmt. Inb. Tracking")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Lot Negative Adjmt. Tracking';
                        ToolTip = 'Specifies that inbound item journal lines of type negative entry require a lot number.';
                    }
                }
                group(Control81)
                {
                    ShowCaption = false;
                    field("Lot Warehouse Tracking"; Rec."Lot Warehouse Tracking")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Lot Warehouse Tracking';
                        ToolTip = 'Specifies that warehouse document lines require a lot number.';
                    }
                    field("Lot Transfer Tracking"; Rec."Lot Transfer Tracking")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Lot Transfer Tracking';
                        ToolTip = 'Specifies that transfer order lines require a lot number.';
                    }
                }
                group(Control48)
                {
                    Caption = 'Outbound';
                    field("Lot Info. Outbound Must Exist"; Rec."Lot Info. Outbound Must Exist")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Lot No. Info. Must Exist';
                        ToolTip = 'Specifies that lot numbers on outbound document lines must have an information record in the Lot No. Information Card.';
                    }
                    field("Lot Purchase Outbound Tracking"; Rec."Lot Purchase Outbound Tracking")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Lot Purchase Tracking';
                        ToolTip = 'Specifies that outbound purchase document lines require a lot number.';
                    }
                    field("Lot Sales Outbound Tracking"; Rec."Lot Sales Outbound Tracking")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Lot Sales Tracking';
                        ToolTip = 'Specifies that outbound sales document lines require a lot number.';
                    }
                    field("Lot Pos. Adjmt. Outb. Tracking"; Rec."Lot Pos. Adjmt. Outb. Tracking")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Lot Positive Adjmt. Tracking';
                        ToolTip = 'Specifies that outbound item journal lines of type positive entry require a lot number.';
                    }
                    field("Lot Neg. Adjmt. Outb. Tracking"; Rec."Lot Neg. Adjmt. Outb. Tracking")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Lot Negative Adjmt. Tracking';
                        ToolTip = 'Specifies that outbound item journal lines of type negative entry require a lot number.';
                    }
                }
            }
            group("Package Tracking")
            {
                Caption = 'Package Tracking';

                group(Control84)
                {
                    Caption = 'General';
                    field("Package Specific Tracking"; Rec."Package Specific Tracking")
                    {
                        ApplicationArea = ItemTracking;
                        ToolTip = 'Specifies that when handling an outbound unit, always specify which existing package number to handle.';
                    }
                }
                group(Control87)
                {
                    Caption = 'Inbound';
                    field("Package Info. Inb. Must Exist"; Rec."Package Info. Inb. Must Exist")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Package No. Info. Must Exist';
                        ToolTip = 'Specifies that package numbers on inbound document lines must have an information record in the Package No. Information Card.';
                    }
                    field("Package Purchase Inb. Tracking"; Rec."Package Purchase Inb. Tracking")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Package Purchase Tracking';
                        ToolTip = 'Specifies that inbound purchase document lines require a package number.';
                    }
                    field("Package Sales Inb. Tracking"; Rec."Package Sales Inbound Tracking")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Package Sales Tracking';
                        ToolTip = 'Specifies that inbound sales document lines require a package number.';
                    }
                    field("Package Pos. Inb. Tracking"; Rec."Package Pos. Inb. Tracking")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Package Positive Adjmt. Tracking';
                        ToolTip = 'Specifies that inbound item journal lines of type positive entry require a package number.';
                    }
                    field("Package Neg. Inb. Tracking"; Rec."Package Neg. Inb. Tracking")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Package Negative Adjmt. Tracking';
                        ToolTip = 'Specifies that inbound item journal lines of type negative entry require a package number.';
                    }
                }
                group(Control85)
                {
                    ShowCaption = false;
                    field("Package Warehouse Tracking"; Rec."Package Warehouse Tracking")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Package Warehouse Tracking';
                        ToolTip = 'Specifies that warehouse document lines require a package number.';
                    }
                    field("Package Transfer Tracking"; Rec."Package Transfer Tracking")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Package Transfer Tracking';
                        ToolTip = 'Specifies that transfer order lines require a package number.';
                    }
                }
                group(Control49)
                {
                    Caption = 'Outbound';
                    field("Package Info. Outb. Must Exist"; Rec."Package Info. Outb. Must Exist")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Package No. Info. Must Exist';
                        ToolTip = 'Specifies that package numbers on outbound document lines must have an information record in the Package No. Information Card.';
                    }
                    field("Package Purchase Outbound Tracking"; Rec."Package Purch. Outb. Tracking")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Package Purchase Tracking';
                        ToolTip = 'Specifies that outbound purchase document lines require a package number.';
                    }
                    field("Package Sales Outb. Tracking"; Rec."Package Sales Outb. Tracking")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Package Sales Tracking';
                        ToolTip = 'Specifies that outbound sales document lines require a package number.';
                    }
                    field("Package Pos. Outb. Tracking"; Rec."Package Pos. Outb. Tracking")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Package Positive Adjmt. Tracking';
                        ToolTip = 'Specifies that outbound item journal lines of type positive entry require a package number.';
                    }
                    field("Package Neg. Outb. Tracking"; Rec."Package Neg. Outb. Tracking")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Package Negative Adjmt. Tracking';
                        ToolTip = 'Specifies that outbound item journal lines of type negative entry require a package number.';
                    }
                }
            }
            group("Misc.")
            {
                Caption = 'Misc.';
                field("Warranty Date Formula"; Rec."Warranty Date Formula")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the formula that calculates the warranty date entered in the Warranty Date field on item tracking line.';
                }
                field("Man. Warranty Date Entry Reqd."; Rec."Man. Warranty Date Entry Reqd.")
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Require Warranty Date Entry';
                    ToolTip = 'Specifies that a warranty date must be entered manually.';
                }
                field("Use Expiration Dates"; Rec."Use Expiration Dates")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies that items that use this item tracking code can have an expiration date. This will enable checks for expiration dates, which can affect performance for documents with many Item Tracking Lines.';

                    trigger OnValidate()
                    begin
                        ManExpirDateEntryReqdEditable := Rec."Use Expiration Dates";
                        StrictExpirationPostingEditable := Rec."Use Expiration Dates";
                    end;
                }
                field("Man. Expir. Date Entry Reqd."; Rec."Man. Expir. Date Entry Reqd.")
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Require Expiration Date Entry';
                    Editable = ManExpirDateEntryReqdEditable;
                    ToolTip = 'Specifies that items that use this item tracking code must have an expiration date, and that you must enter the expiration date manually. The date formula specified in the Expiration Calculation field on the item card will be ignored.';
                }
                field("Strict Expiration Posting"; Rec."Strict Expiration Posting")
                {
                    ApplicationArea = ItemTracking;
                    Editable = StrictExpirationPostingEditable;
                    ToolTip = 'Specifies if the expiration date is considered when you sell items. For example, you cannot post a sales order for an item that has passed its expiration date.';
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
    }

    trigger OnAfterGetRecord()
    begin
        ManExpirDateEntryReqdEditable := Rec."Use Expiration Dates";
        StrictExpirationPostingEditable := Rec."Use Expiration Dates";
    end;

    trigger OnOpenPage()
    begin
    end;

    var
        StrictExpirationPostingEditable: Boolean;
        ManExpirDateEntryReqdEditable: Boolean;
}

