// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Setup;

using Microsoft.Inventory.Item;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using System.IO;

table 1878 "VAT Assisted Setup Templates"
{
    Caption = 'VAT Assisted Setup Templates';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(3; "Default VAT Bus. Posting Grp"; Code[20])
        {
            Caption = 'Default VAT Bus. Posting Grp';
            TableRelation = "VAT Assisted Setup Bus. Grp.".Code where(Selected = const(true),
                                                                       Default = const(false));
        }
        field(4; "Default VAT Prod. Posting Grp"; Code[20])
        {
            Caption = 'Default VAT Prod. Posting Grp';
            TableRelation = "VAT Setup Posting Groups"."VAT Prod. Posting Group" where(Selected = const(true),
                                                                                        Default = const(false));
        }
        field(5; "Table ID"; Integer)
        {
            Caption = 'Table ID';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure PopulateRecFromTemplates()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        Customer: Record Customer;
        Item: Record Item;
        ConfigTemplateLine: Record "Config. Template Line";
        VATAssistedSetupBusGrp: Record "VAT Assisted Setup Bus. Grp.";
        VATSetupPostingGroups: Record "VAT Setup Posting Groups";
    begin
        DeleteAll();
        if ConfigTemplateHeader.FindSet() then
            repeat
                Code := ConfigTemplateHeader.Code;
                Description := ConfigTemplateHeader.Description;
                "Table ID" := ConfigTemplateHeader."Table ID";

                if
                   (ConfigTemplateHeader."Table ID" = Database::Customer) or
                   (ConfigTemplateHeader."Table ID" = Database::Vendor)
                then
                    if ConfigTemplateLine.GetLine(ConfigTemplateLine, ConfigTemplateHeader.Code, Customer.FieldNo("VAT Bus. Posting Group")) then
                        if
                           VATAssistedSetupBusGrp.Get(
                             CopyStr(ConfigTemplateLine."Default Value", 1, MaxStrLen("Default VAT Bus. Posting Grp")), false)
                        then
                            "Default VAT Bus. Posting Grp" :=
                              CopyStr(ConfigTemplateLine."Default Value", 1, MaxStrLen("Default VAT Bus. Posting Grp"));

                if ConfigTemplateHeader."Table ID" = Database::Item then
                    if ConfigTemplateLine.GetLine(ConfigTemplateLine, ConfigTemplateHeader.Code, Item.FieldNo("VAT Prod. Posting Group")) then
                        if
                           VATSetupPostingGroups.Get(
                             CopyStr(ConfigTemplateLine."Default Value", 1, MaxStrLen("Default VAT Prod. Posting Grp")), false)
                        then
                            "Default VAT Prod. Posting Grp" :=
                              CopyStr(ConfigTemplateLine."Default Value", 1, MaxStrLen("Default VAT Prod. Posting Grp"));

                Insert();
            until ConfigTemplateHeader.Next() = 0;
    end;

    procedure ValidateCustomerTemplate(var VATValidationError: Text): Boolean
    begin
        exit(ValidateTemplates(Database::Customer, VATValidationError));
    end;

    procedure ValidateVendorTemplate(var VATValidationError: Text): Boolean
    begin
        exit(ValidateTemplates(Database::Vendor, VATValidationError));
    end;

    procedure ValidateItemTemplate(var VATValidationError: Text): Boolean
    begin
        exit(ValidateTemplates(Database::Item, VATValidationError));
    end;

    local procedure ValidateTemplates(TableID: Integer; var VATValidationError: Text): Boolean
    var
        VATAssistedSetupBusGrp: Record "VAT Assisted Setup Bus. Grp.";
        VATSetupPostingGroups: Record "VAT Setup Posting Groups";
        VATAssistedSetupTemplates: Record "VAT Assisted Setup Templates";
    begin
        VATAssistedSetupTemplates.SetRange("Table ID", TableID);
        VATAssistedSetupBusGrp.SetRange(Selected, true);
        VATAssistedSetupBusGrp.SetRange(Default, false);
        VATSetupPostingGroups.SetRange(Selected, true);
        VATSetupPostingGroups.SetRange(Default, false);

        if VATAssistedSetupTemplates.FindSet() then
            repeat
                if (VATAssistedSetupTemplates."Default VAT Bus. Posting Grp" <> '') and
                   ((VATAssistedSetupTemplates."Table ID" = Database::Customer) or (VATAssistedSetupTemplates."Table ID" = Database::Vendor))
                then begin
                    VATAssistedSetupBusGrp.SetRange(Code, VATAssistedSetupTemplates."Default VAT Bus. Posting Grp");
                    if not VATAssistedSetupBusGrp.FindFirst() then begin
                        VATValidationError := VATAssistedSetupTemplates."Default VAT Bus. Posting Grp";
                        exit(false);
                    end;
                end;

                if (VATAssistedSetupTemplates."Default VAT Prod. Posting Grp" <> '') and
                   (VATAssistedSetupTemplates."Table ID" = Database::Item)
                then begin
                    VATSetupPostingGroups.SetRange("VAT Prod. Posting Group", VATAssistedSetupTemplates."Default VAT Prod. Posting Grp");
                    if not VATSetupPostingGroups.FindFirst() then begin
                        VATValidationError := VATAssistedSetupTemplates."Default VAT Prod. Posting Grp";
                        exit(false);
                    end;
                end;
            until VATAssistedSetupTemplates.Next() = 0;
        exit(true);
    end;
}

