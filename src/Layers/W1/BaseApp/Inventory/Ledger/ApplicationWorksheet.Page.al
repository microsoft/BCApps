// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Ledger;

using Microsoft.Finance.Dimension;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Posting;
using Microsoft.Inventory.Setup;
using System.Text;

page 521 "Application Worksheet"
{
    AdditionalSearchTerms = 'undo application';
    ApplicationArea = Basic, Suite;
    Caption = 'Application Worksheet';
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = true;
    PageType = Worksheet;
    SaveValues = true;
    SourceTable = "Item Ledger Entry";
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(DateFilter; DateFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Date Filter';
                    ToolTip = 'Specifies the date interval by which values are filtered.';

                    trigger OnValidate()
                    var
                        FilterTokens: Codeunit "Filter Tokens";
                    begin
                        FilterTokens.MakeDateFilter(DateFilter);
                        Rec.SetFilter("Posting Date", DateFilter);
                        DateFilter := Rec.GetFilter("Posting Date");
                        DateFilterOnAfterValidate();
                    end;
                }
                field("Item Filter"; ItemFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Item Filter';
                    TableRelation = Item;
                    ToolTip = 'Specifies a filter to limit the item ledger entries in the first table of the application worksheet to those that have item numbers.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        ItemList: Page "Item List";
                    begin
                        ItemList.LookupMode(true);
                        if ItemList.RunModal() = ACTION::LookupOK then begin
                            Text := ItemList.GetSelectionFilter();
                            exit(true);
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        ItemFilterOnAfterValidate();
                    end;
                }
                field(DocumentFilter; DocumentFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Document No. Filter';
                    ToolTip = 'Specifies a filter to limit the item ledger entries in the first table of the application worksheet, to those that have document numbers.';

                    trigger OnValidate()
                    begin
                        Rec.SetFilter("Document No.", DocumentFilter);
                        DocumentFilter := Rec.GetFilter("Document No.");
                        DocumentFilterOnAfterValidate();
                    end;
                }
                field(LocationFilter; LocationFilter)
                {
                    ApplicationArea = Location;
                    Caption = 'Location Filter';
                    TableRelation = Location;
                    ToolTip = 'Specifies a filter to limit the item ledger entries in the first table of the application worksheet to those that have locations.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        LocationList: Page "Location List";
                    begin
                        LocationList.LookupMode(true);
                        if LocationList.RunModal() = ACTION::LookupOK then begin
                            Text := LocationList.GetSelectionFilter();
                            exit(true);
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        Rec.SetFilter("Location Code", LocationFilter);
                        LocationFilter := Rec.GetFilter("Location Code");
                        LocationFilterOnAfterValidate();
                    end;
                }
            }
            repeater(Control1)
            {
                Editable = false;
                Enabled = true;
                ShowCaption = false;
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the item in the entry.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document number on the entry. The document is the voucher that the entry was based on, for example, a receipt.';
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the code for the location that the entry is linked to.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry''s posting date.';
                }
                field("Entry Type"; Rec."Entry Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies which type of transaction that the entry is created from.';
                }
                field("Source Type"; Rec."Source Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the source type that applies to the source number, shown in the Source No. field.';
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies what type of document was posted to create the item ledger entry.';
                }
                field("Document Line No."; Rec."Document Line No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the line on the posted document that corresponds to the item ledger entry.';
                    Visible = false;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                }
                field("Serial No."; Rec."Serial No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies a serial number if the posted item carries such a number.';
                    Visible = false;
                }
                field("Lot No."; Rec."Lot No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies a lot number if the posted item carries such a number.';
                    Visible = false;
                }
                field("Source No."; Rec."Source No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies where the entry originated.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the entry.';
                    Visible = false;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of units of the item in the item entry.';
                }
                field("Remaining Quantity"; Rec."Remaining Quantity")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the quantity in the Quantity field that remains to be processed.';
                }
                field("Invoiced Quantity"; Rec."Invoiced Quantity")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how many units of the item on the line have been invoiced.';
                }
                field("Reserved Quantity"; Rec."Reserved Quantity")
                {
                    ApplicationArea = Reservation;
                    ToolTip = 'Specifies how many units of the item on the line have been reserved.';
                }
                field("Shipped Qty. Not Returned"; Rec."Shipped Qty. Not Returned")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the quantity for this item ledger entry that was shipped and has not yet been returned.';
                }
                field("Cost Amount (Actual)"; Rec."Cost Amount (Actual)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the adjusted cost, in LCY, of the quantity posting.';
                }
                field(GetUnitCostLCY; Rec.GetUnitCostLCY())
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Unit Cost(LCY)';
                    ToolTip = 'Specifies the cost of one unit of the item. ';
                    Visible = false;
                }
                field(Open; Rec.Open)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the entry has been fully applied to.';
                }
                field(Positive; Rec.Positive)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the item in the item ledge entry is positive.';
                }
                field("Applies-to Entry"; Rec."Applies-to Entry")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the quantity on the journal line must be applied to an already-posted entry. In that case, enter the entry number that the quantity will be applied to.';
                    Visible = false;
                }
                field("Applied Entry to Adjust"; Rec."Applied Entry to Adjust")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether there is one or more applied entries, which need to be adjusted.';
                    Visible = false;
                }
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
                }
            }
        }
        area(factboxes)
        {
            part(Control1903523907; "Item Application FactBox")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Entry No." = field("Entry No.");
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("V&iew")
            {
                Caption = 'V&iew';
                Image = View;
                action(AppliedEntries)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Applied Entries';
                    Image = Approve;
                    ShortCutKey = 'F9';
                    ToolTip = 'View the ledger entries that have been applied to this record.';

                    trigger OnAction()
                    begin
                        Clear(ApplicationsForm);
                        ApplicationsForm.SetRecordToShow(Rec, Apply, true);
                        ApplicationsForm.Run();
                        InsertUnapplyItem(Rec."Item No.");
                        CurrPage.Update();
                    end;
                }
                action(UnappliedEntries)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Unapplied Entries';
                    Image = Entries;
                    ShortCutKey = 'Ctrl+F9';
                    ToolTip = 'View entries that you have unapplied.';

                    trigger OnAction()
                    begin
                        Clear(ApplicationsForm);
                        ApplicationsForm.SetRecordToShow(Rec, Apply, false);
                        ApplicationsForm.LookupMode := true;
                        if ApplicationsForm.RunModal() = ACTION::LookupOK then
                            ApplicationsForm.ApplyRec();

                        CurrPage.Update();
                    end;
                }
            }
            group("Ent&ry")
            {
                Caption = 'Ent&ry';
                Image = Entry;
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
                action("&Value Entries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Value Entries';
                    Image = ValueLedger;
                    RunObject = Page "Value Entries";
                    RunPageLink = "Item Ledger Entry No." = field("Entry No.");
                    RunPageView = sorting("Item Ledger Entry No.");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View the history of posted amounts that affect the value of the item. Value entries are created for every transaction with the item.';
                }
                action("Reservation Entries")
                {
                    AccessByPermission = TableData Item = R;
                    ApplicationArea = Reservation;
                    Caption = 'Reservation Entries';
                    Image = ReservationLedger;
                    ToolTip = 'View the entries for every reservation that is made, either manually or automatically.';

                    trigger OnAction()
                    begin
                        Rec.ShowReservationEntries(true);
                    end;
                }
            }
        }
        area(processing)
        {
            group(Functions)
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(Reapply)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Rea&pply';
                    Image = "Action";
                    ToolTip = 'Reapply entries that you have removed.';

                    trigger OnAction()
                    begin
                        UnblockItems();
                        Reapplyall();
                    end;
                }
                action(UndoApplications)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Undo Manual Changes';
                    Image = Restore;
                    ToolTip = 'Undo your previous application change.';

                    trigger OnAction()
                    begin
                        if Apply.ApplicationLogIsEmpty() then begin
                            Message(NothingToRevertMsg);
                            exit;
                        end;

                        if Confirm(RevertAllQst) then begin
                            Apply.UndoApplications();
                            Message(RevertCompletedMsg);
                        end
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(AppliedEntries_Promoted; AppliedEntries)
                {
                }
                actionref(UnappliedEntries_Promoted; UnappliedEntries)
                {
                }
                actionref(Reapply_Promoted; Reapply)
                {
                }
                actionref(UndoApplications_Promoted; UndoApplications)
                {
                }
            }
            group(Category_Category5)
            {
                Caption = 'Entry', Comment = 'Generated from the PromotedActionCategories property index 4.';

                actionref("Reservation Entries_Promoted"; "Reservation Entries")
                {
                }
                actionref(Dimensions_Promoted; Dimensions)
                {
                }
                actionref("&Value Entries_Promoted"; "&Value Entries")
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Navigate', Comment = 'Generated from the PromotedActionCategories property index 3.';
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        UpdateFilterFields();
    end;

    trigger OnFindRecord(Which: Text): Boolean
    var
        Found: Boolean;
    begin
        Found := Rec.Find(Which);
        if not Found then;
        exit(Found);
    end;

    trigger OnOpenPage()
    begin
        Apply.SetCalledFromApplicationWorksheet(true);
        ReapplyTouchedEntries(); // in case OnQueryClosePage trigger was not executed due to a sudden crash

        InventoryPeriod.IsValidDate(InventoryOpenedFrom);
        if InventoryOpenedFrom <> 0D then
            if Rec.GetFilter("Posting Date") = '' then
                Rec.SetFilter("Posting Date", '%1..', CalcDate('<+1D>', InventoryOpenedFrom))
            else
                if Rec.GetFilter("Posting Date") <> StrSubstNo('%1..', CalcDate('<+1D>', InventoryOpenedFrom)) then
                    Rec.SetFilter("Posting Date",
                      StrSubstNo('%2&%1..', CalcDate('<+1D>', InventoryOpenedFrom), Rec.GetFilter("Posting Date")));

        UpdateFilterFields();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if Apply.AnyTouchedEntries() then begin
            if not Confirm(Text003) then
                exit(false);

            UnblockItems();
            Reapplyall();
        end;

        exit(true);
    end;

    var
        InventoryPeriod: Record "Inventory Period";
        ApplicationsForm: Page "View Applied Entries";
        InventoryOpenedFrom: Date;
        DateFilter: Text;
        ItemFilter: Text;
        LocationFilter: Text;
        DocumentFilter: Text;
#pragma warning disable AA0074
        Text003: Label 'After the window is closed, the system will check for and reapply open entries.\Do you want to close the window?';
#pragma warning restore AA0074
        RevertAllQst: Label 'Are you sure that you want to undo all changes?';
        NothingToRevertMsg: Label 'Nothing to undo.';
        RevertCompletedMsg: Label 'The changes have been undone.';

    protected var
        TempUnapplyItem: Record Item temporary;
        Apply: Codeunit "Item Jnl.-Post Line";

    local procedure UpdateFilterFields()
    begin
        ItemFilter := Rec.GetFilter("Item No.");
        LocationFilter := Rec.GetFilter("Location Code");
        DateFilter := Rec.GetFilter("Posting Date");
        DocumentFilter := Rec.GetFilter("Document No.");
    end;

    local procedure Reapplyall()
    begin
        Apply.RedoApplications();
        Apply.CostAdjust();
        Apply.ClearApplicationLog();
    end;

    local procedure ReapplyTouchedEntries()
    begin
        Apply.RestoreTouchedEntries(TempUnapplyItem);

        if Apply.AnyTouchedEntries() then begin
            UnblockItems();
            Reapplyall();
        end;
    end;

    procedure SetRecordToShow(RecordToSet: Record "Item Ledger Entry")
    begin
        Rec := RecordToSet;
    end;

    local procedure LocationFilterOnAfterValidate()
    begin
        CurrPage.Update();
    end;

    local procedure DateFilterOnAfterValidate()
    begin
        CurrPage.Update();
    end;

    local procedure ItemFilterOnAfterValidate()
    begin
        Rec.SetFilter("Item No.", ItemFilter);
        ItemFilter := Rec.GetFilter("Item No.");
        CurrPage.Update();
    end;

    local procedure InsertUnapplyItem(ItemNo: Code[20])
    begin
        if not TempUnapplyItem.Get(ItemNo) then begin
            TempUnapplyItem.Init();
            TempUnapplyItem."No." := ItemNo;
            TempUnapplyItem.Insert();
        end;
    end;

    local procedure UnblockItems()
    var
        Item: Record Item;
    begin
        if TempUnapplyItem.FindSet() then
            repeat
                Item.Get(TempUnapplyItem."No.");
                if Item."Application Wksh. User ID" = UpperCase(UserId) then begin
                    Item."Application Wksh. User ID" := '';
                    Item.Modify();
                end;
            until TempUnapplyItem.Next() = 0;

        TempUnapplyItem.DeleteAll();
    end;

    local procedure DocumentFilterOnAfterValidate()
    begin
        CurrPage.Update();
    end;
}

