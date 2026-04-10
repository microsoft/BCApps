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
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = ItemTracking;
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
                    }
                    field("Create SN Info on Posting"; Rec."Create SN Info on Posting")
                    {
                        ApplicationArea = ItemTracking;
                    }
                }
                group(Inbound)
                {
                    Caption = 'Inbound';
                    field("SN Info. Inbound Must Exist"; Rec."SN Info. Inbound Must Exist")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'SN No. Info. Must Exist';
                    }
                    field("SN Purchase Inbound Tracking"; Rec."SN Purchase Inbound Tracking")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'SN Purchase Tracking';
                    }
                    field("SN Sales Inbound Tracking"; Rec."SN Sales Inbound Tracking")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'SN Sales Tracking';
                    }
                    field("SN Pos. Adjmt. Inb. Tracking"; Rec."SN Pos. Adjmt. Inb. Tracking")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'SN Positive Adjmt. Tracking';
                    }
                    field("SN Neg. Adjmt. Inb. Tracking"; Rec."SN Neg. Adjmt. Inb. Tracking")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'SN Negative Adjmt. Tracking';
                    }
                }
                group(Control82)
                {
                    ShowCaption = false;
                    field("SN Warehouse Tracking"; Rec."SN Warehouse Tracking")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'SN Warehouse Tracking';
                    }
                    field("SN Transfer Tracking"; Rec."SN Transfer Tracking")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'SN Transfer Tracking';
                    }
                }
                group(Outbound)
                {
                    Caption = 'Outbound';
                    field("SN Info. Outbound Must Exist"; Rec."SN Info. Outbound Must Exist")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'SN No. Info. Must Exist';
                    }
                    field("SN Purchase Outbound Tracking"; Rec."SN Purchase Outbound Tracking")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'SN Purchase Tracking';
                    }
                    field("SN Sales Outbound Tracking"; Rec."SN Sales Outbound Tracking")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'SN Sales Tracking';
                    }
                    field("SN Pos. Adjmt. Outb. Tracking"; Rec."SN Pos. Adjmt. Outb. Tracking")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'SN Positive Adjmt. Tracking';
                    }
                    field("SN Neg. Adjmt. Outb. Tracking"; Rec."SN Neg. Adjmt. Outb. Tracking")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'SN Negative Adjmt. Tracking';
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
                    }
                    field("Create Lot No. Info on posting"; Rec."Create Lot No. Info on posting")
                    {
                        ApplicationArea = ItemTracking;
                    }
                }
                group(Control47)
                {
                    Caption = 'Inbound';
                    field("Lot Info. Inbound Must Exist"; Rec."Lot Info. Inbound Must Exist")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Lot No. Info. Must Exist';
                    }
                    field("Lot Purchase Inbound Tracking"; Rec."Lot Purchase Inbound Tracking")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Lot Purchase Tracking';
                    }
                    field("Lot Sales Inbound Tracking"; Rec."Lot Sales Inbound Tracking")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Lot Sales Tracking';
                    }
                    field("Lot Pos. Adjmt. Inb. Tracking"; Rec."Lot Pos. Adjmt. Inb. Tracking")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Lot Positive Adjmt. Tracking';
                    }
                    field("Lot Neg. Adjmt. Inb. Tracking"; Rec."Lot Neg. Adjmt. Inb. Tracking")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Lot Negative Adjmt. Tracking';
                    }
                }
                group(Control81)
                {
                    ShowCaption = false;
                    field("Lot Warehouse Tracking"; Rec."Lot Warehouse Tracking")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Lot Warehouse Tracking';
                    }
                    field("Lot Transfer Tracking"; Rec."Lot Transfer Tracking")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Lot Transfer Tracking';
                    }
                }
                group(Control48)
                {
                    Caption = 'Outbound';
                    field("Lot Info. Outbound Must Exist"; Rec."Lot Info. Outbound Must Exist")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Lot No. Info. Must Exist';
                    }
                    field("Lot Purchase Outbound Tracking"; Rec."Lot Purchase Outbound Tracking")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Lot Purchase Tracking';
                    }
                    field("Lot Sales Outbound Tracking"; Rec."Lot Sales Outbound Tracking")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Lot Sales Tracking';
                    }
                    field("Lot Pos. Adjmt. Outb. Tracking"; Rec."Lot Pos. Adjmt. Outb. Tracking")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Lot Positive Adjmt. Tracking';
                    }
                    field("Lot Neg. Adjmt. Outb. Tracking"; Rec."Lot Neg. Adjmt. Outb. Tracking")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Lot Negative Adjmt. Tracking';
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
                    }
                }
                group(Control87)
                {
                    Caption = 'Inbound';
                    field("Package Info. Inb. Must Exist"; Rec."Package Info. Inb. Must Exist")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Package No. Info. Must Exist';
                    }
                    field("Package Purchase Inb. Tracking"; Rec."Package Purchase Inb. Tracking")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Package Purchase Tracking';
                    }
                    field("Package Sales Inb. Tracking"; Rec."Package Sales Inbound Tracking")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Package Sales Tracking';
                    }
                    field("Package Pos. Inb. Tracking"; Rec."Package Pos. Inb. Tracking")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Package Positive Adjmt. Tracking';
                    }
                    field("Package Neg. Inb. Tracking"; Rec."Package Neg. Inb. Tracking")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Package Negative Adjmt. Tracking';
                    }
                }
                group(Control85)
                {
                    ShowCaption = false;
                    field("Package Warehouse Tracking"; Rec."Package Warehouse Tracking")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Package Warehouse Tracking';
                    }
                    field("Package Transfer Tracking"; Rec."Package Transfer Tracking")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Package Transfer Tracking';
                    }
                }
                group(Control49)
                {
                    Caption = 'Outbound';
                    field("Package Info. Outb. Must Exist"; Rec."Package Info. Outb. Must Exist")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Package No. Info. Must Exist';
                    }
                    field("Package Purchase Outbound Tracking"; Rec."Package Purch. Outb. Tracking")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Package Purchase Tracking';
                    }
                    field("Package Sales Outb. Tracking"; Rec."Package Sales Outb. Tracking")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Package Sales Tracking';
                    }
                    field("Package Pos. Outb. Tracking"; Rec."Package Pos. Outb. Tracking")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Package Positive Adjmt. Tracking';
                    }
                    field("Package Neg. Outb. Tracking"; Rec."Package Neg. Outb. Tracking")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Package Negative Adjmt. Tracking';
                    }
                }
            }
            group("Misc.")
            {
                Caption = 'Misc.';
                field("Warranty Date Formula"; Rec."Warranty Date Formula")
                {
                    ApplicationArea = ItemTracking;
                }
                field("Man. Warranty Date Entry Reqd."; Rec."Man. Warranty Date Entry Reqd.")
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Require Warranty Date Entry';
                }
                field("Use Expiration Dates"; Rec."Use Expiration Dates")
                {
                    ApplicationArea = ItemTracking;

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
                }
                field("Strict Expiration Posting"; Rec."Strict Expiration Posting")
                {
                    ApplicationArea = ItemTracking;
                    Editable = StrictExpirationPostingEditable;
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

