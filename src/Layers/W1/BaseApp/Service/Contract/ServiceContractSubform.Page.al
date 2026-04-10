// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Contract;

using Microsoft.Foundation.Attachment;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Service.Item;

page 6052 "Service Contract Subform"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    DelayedInsert = true;
    LinksAllowed = false;
    MultipleNewLines = true;
    PageType = ListPart;
    SourceTable = "Service Contract Line";
    SourceTableView = where("Contract Type" = filter(Contract));

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Service Item No."; Rec."Service Item No.")
                {
                    ApplicationArea = Service;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        ServContractMgt: Codeunit ServContractManagement;
                    begin
                        OnBeforeServiceItemNoLookup();
                        ServContractMgt.LookupServItemNo(Rec);
                        if xRec.Get(Rec."Contract Type", Rec."Contract No.", Rec."Line No.") then;
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Service;
                }
                field("Ship-to Code"; Rec."Ship-to Code")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Service;
                }
                field("Serial No."; Rec."Serial No.")
                {
                    ApplicationArea = ItemTracking;

                    trigger OnAssistEdit()
                    begin
                        Clear(ItemLedgerEntry);
                        ItemLedgerEntry.SetRange("Item No.", Rec."Item No.");
                        ItemLedgerEntry.SetRange("Variant Code", Rec."Variant Code");
                        ItemLedgerEntry.SetRange("Serial No.", Rec."Serial No.");
                        PAGE.Run(PAGE::"Item Ledger Entries", ItemLedgerEntry);
                    end;
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Service;
                    Caption = 'Item No.';

                    trigger OnValidate()
                    var
                        Item: Record "Item";
                    begin
                        if Rec."Variant Code" = '' then
                            VariantCodeMandatory := Item.IsVariantMandatory(true, Rec."Item No.");
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
                            VariantCodeMandatory := Item.IsVariantMandatory(true, Rec."Item No.");
                    end;
                }
                field("Response Time (Hours)"; Rec."Response Time (Hours)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the response time for the service item associated with the service contract.';
                }
                field("Line Cost"; Rec."Line Cost")
                {
                    ApplicationArea = Service;
                }
                field("Line Value"; Rec."Line Value")
                {
                    ApplicationArea = Service;
                }
                field("Line Discount %"; Rec."Line Discount %")
                {
                    ApplicationArea = Service;
                }
                field("Line Discount Amount"; Rec."Line Discount Amount")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Line Amount"; Rec."Line Amount")
                {
                    ApplicationArea = Service;
                }
                field(Profit; Rec.Profit)
                {
                    ApplicationArea = Service;
                }
                field("Service Period"; Rec."Service Period")
                {
                    ApplicationArea = Service;
                }
                field("Next Planned Service Date"; Rec."Next Planned Service Date")
                {
                    ApplicationArea = Service;
                }
                field("Last Planned Service Date"; Rec."Last Planned Service Date")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Last Preventive Maint. Date"; Rec."Last Preventive Maint. Date")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Last Service Date"; Rec."Last Service Date")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Service;
                }
                field("Contract Expiration Date"; Rec."Contract Expiration Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when a service item must be removed from the service contract. The default value is copied from the Expiration Date field in the header section. You can change it to a value that is earlier than the value in the Expiration Date field and later than the value in the Starting Date field in the header section of the service contract.';
                }
                field("Credit Memo Date"; Rec."Credit Memo Date")
                {
                    ApplicationArea = Service;
                }
                field(Credited; Rec.Credited)
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("New Line"; Rec."New Line")
                {
                    ApplicationArea = Service;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(SelectMultiItems)
            {
                AccessByPermission = TableData "Service Item" = R;
                ApplicationArea = Service;
                Caption = 'Select service items';
                Ellipsis = true;
                Image = NewItem;
                ToolTip = 'Add two or more service items from the full list of available service items.';

                trigger OnAction()
                begin
                    Rec.SelectMultipleServiceItems();
                end;
            }

            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action("&Comments")
                {
                    ApplicationArea = Comments;
                    Caption = '&Comments';
                    Image = ViewComments;
                    ToolTip = 'View or create a comment.';

                    trigger OnAction()
                    begin
                        Rec.ShowComments();
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
    }

    trigger OnDeleteRecord(): Boolean
    begin
        if Rec."Contract Status" = Rec."Contract Status"::Signed then begin
            ServContractLine.CopyFilters(Rec);
            CurrPage.SetSelectionFilter(ServContractLine);
            NoOfSelectedLines := ServContractLine.Count();
            if NoOfSelectedLines = 1 then
                CreateCreditfromContractLines.SetSelectionFilterNo(NoOfSelectedLines);
        end;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.SetUpNewLine();
    end;

    trigger OnAfterGetRecord()
    var
        Item: Record Item;
    begin
        if Rec."Variant Code" = '' then
            VariantCodeMandatory := Item.IsVariantMandatory(true, Rec."Item No.");
    end;

    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ServContractLine: Record "Service Contract Line";
        CreateCreditfromContractLines: Codeunit CreateCreditfromContractLines;
        NoOfSelectedLines: Integer;
        VariantCodeMandatory: Boolean;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeServiceItemNoLookup()
    begin
    end;
}

