// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Pricing;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Inventory.Item;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Utilities;

table 6083 "Serv. Price Adjustment Detail"
{
    Caption = 'Serv. Price Adjustment Detail';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Serv. Price Adjmt. Gr. Code"; Code[10])
        {
            Caption = 'Serv. Price Adjmt. Gr. Code';
            NotBlank = true;
            TableRelation = "Service Price Adjustment Group";
        }
        field(2; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Item,Resource,Resource Group,Service Cost,G/L Account';
            OptionMembers = Item,Resource,"Resource Group","Service Cost","G/L Account";
        }
        field(3; "No."; Code[20])
        {
            Caption = 'No.';
            TableRelation = if (Type = const(Item)) Item
            else
            if (Type = const(Resource)) Resource
            else
            if (Type = const("Resource Group")) "Resource Group"
            else
            if (Type = const("Service Cost")) "Service Cost"
            else
            if (Type = const("G/L Account")) "G/L Account";

            trigger OnValidate()
            var
                Item: Record Item;
                Resource: Record Resource;
                ResourceGrp: Record "Resource Group";
                ServiceCost: Record "Service Cost";
            begin
                if "No." <> '' then
                    case Type of
                        Type::Item:
                            begin
                                Item.Get("No.");
                                Description := Item.Description;
                            end;
                        Type::Resource:
                            begin
                                Resource.Get("No.");
                                Description := Resource.Name;
                            end;
                        Type::"Resource Group":
                            begin
                                ResourceGrp.Get("No.");
                                Description := ResourceGrp.Name;
                            end;
                        Type::"Service Cost":
                            begin
                                ServiceCost.Get("No.");
                                Description := ServiceCost.Description;
                            end;
                    end;
            end;
        }
        field(4; "Work Type"; Code[10])
        {
            Caption = 'Work Type';
            TableRelation = "Work Type";

            trigger OnValidate()
            var
                ServPriceAdjmtDetail: Record "Serv. Price Adjustment Detail";
                ServPriceAdjmtDetail2: Record "Serv. Price Adjustment Detail";
            begin
                if not (Type in [Type::Resource, Type::"Resource Group"]) then begin
                    ServPriceAdjmtDetail.Type := Type::Resource;
                    ServPriceAdjmtDetail2.Type := Type::"Resource Group";
                    Error(Text003,
                      FieldCaption("Work Type"),
                      FieldCaption(Type),
                      ServPriceAdjmtDetail.Type,
                      ServPriceAdjmtDetail2.Type);
                end;
            end;
        }
        field(5; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";
        }
        field(6; Description; Text[100])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(Key1; "Serv. Price Adjmt. Gr. Code", Type, "No.", "Work Type", "Gen. Prod. Posting Group")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        ValidateRecord();
    end;

    trigger OnModify()
    begin
        ValidateRecord();
    end;

    trigger OnRename()
    begin
        ValidateRecord();
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label '%1 already exists with adjustments for specific %2 numbers. Delete these lines if you need an adjustment for all %2 records.';
        Text002: Label '%1 already exists for this %2 with %3 set to blank. Delete this line if you need adjustments for specific %4 numbers.';
        Text003: Label '%1 can only be entered when %2 is %3 or %4.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    local procedure ValidateRecord()
    var
        ServPriceAdjmtDetail: Record "Serv. Price Adjustment Detail";
    begin
        if "No." = '' then begin
            ServPriceAdjmtDetail.Reset();
            ServPriceAdjmtDetail.SetRange("Serv. Price Adjmt. Gr. Code", "Serv. Price Adjmt. Gr. Code");
            ServPriceAdjmtDetail.SetRange(Type, Type);
            ServPriceAdjmtDetail.SetRange("Work Type", "Work Type");
            ServPriceAdjmtDetail.SetRange("Gen. Prod. Posting Group", "Gen. Prod. Posting Group");
            if ServPriceAdjmtDetail.FindFirst() then
                if
                   (ServPriceAdjmtDetail."Serv. Price Adjmt. Gr. Code" <> "Serv. Price Adjmt. Gr. Code") or
                   (ServPriceAdjmtDetail.Type <> Type) or
                   (ServPriceAdjmtDetail."No." <> "No.") or
                   (ServPriceAdjmtDetail."Work Type" <> "Work Type") or
                   (ServPriceAdjmtDetail."Gen. Prod. Posting Group" <> "Gen. Prod. Posting Group")
                then
                    Error(Text001, ServPriceAdjmtDetail.TableCaption(), Format(Type));
        end else
            if ServPriceAdjmtDetail.Get(
                 "Serv. Price Adjmt. Gr. Code",
                 Type,
                 '',
                 "Work Type",
                 "Gen. Prod. Posting Group")
            then
                Error(Text002,
                  ServPriceAdjmtDetail.TableCaption(),
                  FieldCaption(Type),
                  FieldCaption("No."),
                  Format(Type));
    end;
}

