// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.BOM.Tree;

using Microsoft.Inventory.Item;

codeunit 3688 "BOM Node"
{
    var
        LowLevelCodeParam: Codeunit "Low-Level Code Parameter";
        Type: Enum Microsoft.Manufacturing.ProductionBOM."Production BOM Line Type";
        "No.": Code[20];
        ExistingLowLevelCode: Integer;
        CalculatedLowLevelCode: Integer;
        Initialized: Boolean;
        ProdBomErr: Label 'The maximum number of BOM levels %1, was exceeded. The process stopped at %2 %3.', Comment = '%1 = max number of levels; %2 = BOM Type; %3 = BOM No.';
        KeyTemplateTxt: Label '%1: %2', Comment = '%1 = Type and %2 = No.', Locked = true;

    procedure GetType(): Enum Microsoft.Manufacturing.ProductionBOM."Production BOM Line Type"
    begin
        exit(Type);
    end;

    procedure GetNumber(): Code[20]
    begin
        exit("No.");
    end;

    procedure GetLowLevelCode(): Integer
    begin
        exit(CalculatedLowLevelCode);
    end;

    procedure CreateForItem(ItemNo: Code[20]; LowLevelCode: Integer; NewLowLevelCodeParam: Codeunit "Low-Level Code Parameter")
    begin
        Create(Microsoft.Manufacturing.ProductionBOM."Production BOM Line Type"::Item, ItemNo, LowLevelCode, NewLowLevelCodeParam);
    end;

    procedure CreateForProdBOM(ProdBOMNo: Code[20]; LowLevelCode: Integer; NewLowLevelCodeParam: Codeunit "Low-Level Code Parameter")
    begin
        Create(Microsoft.Manufacturing.ProductionBOM."Production BOM Line Type"::"Production BOM", ProdBOMNo, LowLevelCode, NewLowLevelCodeParam);
    end;

    local procedure Create(NewType: Enum Microsoft.Manufacturing.ProductionBOM."Production BOM Line Type"; NewBOMNo: Code[20]; ExistingLowLevel: Integer; NewLowLevelCodeParam: Codeunit "Low-Level Code Parameter")
    begin
        Type := NewType;
        "No." := NewBOMNo;
        ExistingLowLevelCode := ExistingLowLevel;
        LowLevelCodeParam := NewLowLevelCodeParam;

        Initialized := true;
    end;

    procedure IsInitialized(): Boolean
    begin
        exit(Initialized);
    end;

    procedure GetKey(): Text
    var
        JsonKey: JsonObject;
    begin
        JsonKey.Add('Type', Format(Type));
        JsonKey.Add('No.', "No.");
        exit(Format(JsonKey));
    end;

    procedure TraversedDown()
    var
        DummyParent: Codeunit "BOM Node";
        Handled: Boolean;
    begin
        OnReachedNode(DummyParent, Handled);
        if Handled then
            exit;

        LowLevelCodeParam.ShowDetails(StrSubstNo(KeyTemplateTxt, Type, "No."), 0, 0);

        case LowLevelCodeParam.GetRunMode() of
            "Low-Level Code Run Mode"::Calculate:
                // this is a root
                CalculatedLowLevelCode := 0;

            "Low-Level Code Run Mode"::"Write To Database":
                WriteToDatabase();
        end;
    end;

    procedure TraversedDown(FromParent: Codeunit "BOM Node")
    var
        ParentLowLevelCode: Integer;
        Handled: Boolean;
    begin
        OnReachedNode(FromParent, Handled);
        if Handled then
            exit;

        LowLevelCodeParam.ShowDetails(StrSubstNo(KeyTemplateTxt, Type, "No."), 0, 0);

        case LowLevelCodeParam.GetRunMode() of
            "Low-Level Code Run Mode"::Calculate:
                begin
                    ParentLowLevelCode := FromParent.GetLowLevelCode();
                    case FromParent.GetType() of
                        Microsoft.Manufacturing.ProductionBOM."Production BOM Line Type"::Item:
                            // if parent is an item, set to at least 1 more than the parent, if not already lower
                            if CalculatedLowLevelCode <= ParentLowLevelCode then
                                CalculatedLowLevelCode := ParentLowLevelCode + 1;
                        Microsoft.Manufacturing.ProductionBOM."Production BOM Line Type"::"Production BOM":
                            // if this is a production BOM, set the same low level code, if not already lower
                            if CalculatedLowLevelCode < ParentLowLevelCode then
                                CalculatedLowLevelCode := ParentLowLevelCode;
                    end;

                    if CalculatedLowLevelCode > 50 then
                        Error(ProdBomErr, 50, Type, "No.")
                end;

            "Low-Level Code Run Mode"::"Write To Database":
                WriteToDatabase();
        end;
    end;

    local procedure WriteToDatabase()
    var
        Item: Record Item;
    begin
        if ExistingLowLevelCode = CalculatedLowLevelCode then
            exit;

        // Call ModifyAll instead of GET for fewer SQL callbacks
        case Type of
            Microsoft.Manufacturing.ProductionBOM."Production BOM Line Type"::Item:
                begin
                    Item.SetRange("No.", "No.");
                    Item.ModifyAll("Low-Level Code", CalculatedLowLevelCode);
                end;
            Microsoft.Manufacturing.ProductionBOM."Production BOM Line Type"::"Production BOM":
                OnWriteToDatabaseOnProductionBOM("No.", CalculatedLowLevelCode);
            else
                OnWriteToDatabase();
        end;

        ExistingLowLevelCode := CalculatedLowLevelCode;
    end;

    [IntegrationEvent(true, false)]
    local procedure OnWriteToDatabase()
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnReachedNode(ParentBomNode: Codeunit "BOM Node"; var Handled: Boolean)
    begin
    end;

    [InternalEvent(false)]
    local procedure OnWriteToDatabaseOnProductionBOM(BOMNo: Code[20]; CalculateLowLevelCode: Integer)
    begin
    end;
}