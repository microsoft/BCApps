// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item;

using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Setup;

page 729 "Copy Item"
{
    Caption = 'Copy Item';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = StandardDialog;
    SourceTable = "Copy Item Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            group(Options)
            {
                Caption = 'Options';
                field(SourceItemNo; Rec."Source Item No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Source Item No.';
                    Editable = false;
                    Lookup = true;
                    TableRelation = Item;
                    ToolTip = 'Specifies the number of the item that you want to copy the data from.';
                }
                field(TargetItemNo; Rec."Target Item No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Target Item No.';
                    ToolTip = 'Specifies the number of the new item that you want to copy the data to. \\To generate the new item number from a number series, fill in the Target No. Series field instead.';

                    trigger OnValidate()
                    begin
                        if Rec."Target Item No." <> '' then
                            Rec."Target No. Series" := '';
                    end;
                }
                field(TargetNoSeries; Rec."Target No. Series")
                {
                    ApplicationArea = Basic, Suite;
                    AssistEdit = true;
                    Caption = 'Target No. Series';
                    Editable = false;
                    ToolTip = 'Specifies the number series that is used to assign a number to the new item.';

                    trigger OnAssistEdit()
                    var
                        NoSeries: Codeunit "No. Series";
                    begin
                        InventorySetup.Get();
                        InventorySetup.TestField("Item Nos.");
                        NoSeries.LookupRelatedNoSeries(InventorySetup."Item Nos.", SourceItem."No. Series", Rec."Target No. Series");
                        Rec."Target Item No." := '';
                    end;
                }
                field(NumberOfCopies; Rec."Number of Copies")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Number of Copies';
                    MinValue = 1;
                    ToolTip = 'Specifies the number of new items that you want to create.';
                }
                field(CopyAllInformation; ShouldCopyAllInformation)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Copy All Information';
                    ToolTip = 'Specifies if all information is copied from the source item to the new item.';

                    trigger OnValidate()
                    begin
                        ValidateShouldCopyAllInformation();
                    end;
                }
                field(ShowCreatedItems; Rec."Show Created Items")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show Created Items';
                    ToolTip = 'Specifies if the copied items are showed after they are created.';
                }
            }
            group(General)
            {
                Caption = 'General';
                Visible = not ShouldCopyAllInformation;
                field(GeneralItemInformation; Rec."General Item Information")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Caption = 'General Item Information';
                    ToolTip = 'Specifies if the selected data type is also copied to the new item.';
                }
                field(UnitsOfMeasure; Rec."Units of Measure")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Units of measure';
                    ToolTip = 'Specifies if the selected data type is also copied to the new item.';
                }
                field(Dimensions; Rec.Dimensions)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Dimensions';
                    ToolTip = 'Specifies if the selected data type is also copied to the new item.';
                }
                field(Picture; Rec.Picture)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Picture';
                    ToolTip = 'Specifies if the selected data type is also copied to the new item.';
                }
                field(Comments; Rec.Comments)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Comments';
                    ToolTip = 'Specifies if the selected data type is also copied to the new item.';
                }
            }
            group(Sale)
            {
                Caption = 'Sale';
                Visible = not ShouldCopyAllInformation;
                field(SalesPrices; Rec."Sales Prices")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Prices';
                    ToolTip = 'Specifies if the selected data type is also copied to the new item.';
                }
                field(SalesLineDisc; Rec."Sales Line Discounts")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Line Disc.';
                    ToolTip = 'Specifies if the selected data type is also copied to the new item.';
                }
            }
            group(Purchase)
            {
                Caption = 'Purchase';
                Visible = not ShouldCopyAllInformation;
                field(PurchasePrices; Rec."Purchase Prices")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Purchase Prices';
                    ToolTip = 'Specifies if the selected data type is also copied to the new item.';
                }
                field(PurchaseLineDisc; Rec."Purchase Line Discounts")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Purchase Line Disc.';
                    ToolTip = 'Specifies if the selected data type is also copied to the new item.';
                }
            }
            group(Service)
            {
                Caption = 'Service';
                Visible = not ShouldCopyAllInformation;
                field(Troubleshooting; Rec.Troubleshooting)
                {
                    ApplicationArea = Service;
                    Caption = 'Troubleshooting';
                    ToolTip = 'Specifies if the selected data type is also copied to the new item.';
                }
                field(ResourceSkills; Rec."Resource Skills")
                {
                    ApplicationArea = Service;
                    Caption = 'Resource Skills';
                    ToolTip = 'Specifies if the selected data type is also copied to the new item.';
                }
            }
            group(Extended)
            {
                Caption = 'Extended';
                Visible = not ShouldCopyAllInformation;
                field(ItemVariants; Rec."Item Variants")
                {
                    ApplicationArea = Planning;
                    Caption = 'Item Variants';
                    ToolTip = 'Specifies if the selected data type is also copied to the new item.';
                }
                field(Translations; Rec.Translations)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Translations';
                    ToolTip = 'Specifies if the selected data type is also copied to the new item.';
                }
                field(ExtendedTexts; Rec."Extended Texts")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Extended Texts';
                    ToolTip = 'Specifies if the selected data type is also copied to the new item.';
                }
                field(BOMComponents; Rec."BOM Components")
                {
                    ApplicationArea = Assembly, Manufacturing;
                    Caption = 'Assembly BOM Components';
                    ToolTip = 'Specifies if the selected data type is also copied to the new item.';
                }
                field(ItemVendors; Rec."Item Vendors")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Item Vendors';
                    ToolTip = 'Specifies if the selected data type is also copied to the new item.';
                }
                field(Attributes; Rec.Attributes)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Attributes';
                    ToolTip = 'Specifies if the selected data type is also copied to the new item.';
                }
                field(ItemReferences; Rec."Item References")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Item References';
                    ToolTip = 'Specifies if the selected data type is also copied to the new item.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        InitCopyItemBuffer();
        ShouldCopyAllInformation := true;
        ValidateShouldCopyAllInformation();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction in [Action::OK, Action::LookupOK] then
            ValidateUserInput();
    end;

    var
        SourceItem: Record Item;
        TempItem: Record Item temporary;
        InventorySetup: Record "Inventory Setup";
        CopyItemParameters: Record "Copy Item Parameters";
        SpecifyTargetItemNoErr: Label 'You must specify the target item number.';
        TargetItemNoTxt: Label 'Target Item No.';
        UnincrementableStringErr: Label 'The value in the %1 field must have a number so that we can assign the next number in the series.', Comment = '%1 = New Field Name';
        ShouldCopyAllInformation: Boolean;

    procedure GetParameters(var CopyItemBuffer: Record "Copy Item Buffer")
    begin
        CopyItemBuffer := Rec;
    end;

    local procedure InitCopyItemBuffer()
    begin
        Rec.Init();
        if CopyItemParameters.Get(UserId()) then
            Rec.TransferFields(CopyItemParameters)
        else begin
            Rec."Number of Copies" := 1;
            InventorySetup.Get();
            Rec."Target No. Series" := InventorySetup."Item Nos.";
        end;
        Rec."Source Item No." := TempItem."No.";
        Rec."General Item Information" := true;
        Rec.Insert();

        OnAfterInitCopyItemBuffer(Rec);
    end;

    local procedure ValidateUserInput()
    var
        CurrUserId: Code[50];
    begin
        CheckTargetItemNo();

        if (Rec."Target Item No." = '') and (Rec."Target No. Series" = '') then
            Error(SpecifyTargetItemNoErr);

        CurrUserId := CopyStr(UserId(), 1, MaxStrLen(CopyItemParameters."User ID"));
        if CopyItemParameters.Get(CurrUserId) then begin
            CopyItemParameters.TransferFields(Rec);
            CopyItemParameters.Modify();
        end else begin
            CopyItemParameters.Init();
            CopyItemParameters.TransferFields(Rec);
            CopyItemParameters."User ID" := CurrUserId;
            CopyItemParameters.Insert();
        end;

        OnAfterValidateUserInput(Rec);
    end;

    procedure SetItem(var Item2: Record Item)
    begin
        TempItem := Item2;
    end;

    local procedure CheckTargetItemNo()
    begin
        if (Rec."Number of Copies" > 1) and (Rec."Target Item No." <> '') then
            if INCSTR(Rec."Target Item No.") = '' then
                Error(UnincrementableStringErr, TargetItemNoTxt);
    end;

    local procedure ValidateShouldCopyAllInformation()
    var
        InfoFieldRef: FieldRef;
        RecRef: RecordRef;
        i: Integer;
    begin
        RecRef.GetTable(Rec);
        for i := 11 to 99 do
            if RecRef.FieldExist(i) then begin
                InfoFieldRef := RecRef.Field(i);
                if InfoFieldRef.Type() = FieldType::Boolean then
                    InfoFieldRef.Value := ShouldCopyAllInformation;
            end;
        RecRef.Modify();
        RecRef.SetTable(Rec);

        OnAfterValidateShouldCopyAllInformation(Rec, ShouldCopyAllInformation);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitCopyItemBuffer(var CopyItemBuffer: Record "Copy Item Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateUserInput(var CopyItemBuffer: Record "Copy Item Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShouldCopyAllInformation(var CopyItemBuffer: Record "Copy Item Buffer"; ShouldCopyAllInfo: Boolean)
    begin
    end;
}
