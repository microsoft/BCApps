// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.UOM;

using Microsoft.Integration.Dataverse;
using Microsoft.Inventory.Item;
using System.DateTime;
using System.Globalization;

table 204 "Unit of Measure"
{
    Caption = 'Unit of Measure';
    DataCaptionFields = "Code", Description;
    DrillDownPageID = "Units of Measure";
    LookupPageID = "Units of Measure";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[50])
        {
            Caption = 'Description';
        }
        field(3; "International Standard Code"; Code[10])
        {
            Caption = 'International Standard Code';
        }
        field(4; Symbol; Text[10])
        {
            Caption = 'Symbol';
        }
        field(5; "Last Modified Date Time"; DateTime)
        {
            Caption = 'Last Modified Date Time';
            Editable = false;
        }
#if not CLEANSCHEMA26
        field(720; "Coupled to CRM"; Boolean)
        {
            Caption = 'Coupled to Dynamics 365 Sales';
            Editable = false;
            ObsoleteReason = 'Replaced by flow field Coupled to Dataverse';
            ObsoleteState = Removed;
            ObsoleteTag = '26.0';
        }
#endif
        field(721; "Coupled to Dataverse"; Boolean)
        {
            FieldClass = FlowField;
            Caption = 'Coupled to Dynamics 365 Sales';
            Editable = false;
            CalcFormula = exist("CRM Integration Record" where("Integration ID" = field(SystemId), "Table ID" = const(Database::"Unit of Measure")));
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
        key(Key2; Description)
        {
        }
        key(Key3; SystemModifiedAt)
        {
        }
    }

    fieldgroups
    {
        fieldgroup(Brick; "Code", Description, "International Standard Code")
        {
        }
    }

    var
#pragma warning disable AA0074
        UoMIsStillUsedError: Label 'You cannot delete the unit of measure because it is assigned to one or more records.';
#pragma warning restore AA0074

    trigger OnDelete()
    var
        Item: Record Item;
    begin
        Item.SetCurrentKey("Base Unit of Measure");
        Item.SetRange("Base Unit of Measure", Code);
        if not Item.IsEmpty() then
            Error(UoMIsStillUsedError);

        UnitOfMeasureTranslation.SetRange(Code, Code);
        UnitOfMeasureTranslation.DeleteAll();
    end;

    trigger OnInsert()
    begin
        SetLastDateTimeModified();
    end;

    trigger OnModify()
    begin
        SetLastDateTimeModified();
    end;

    trigger OnRename()
    begin
        UpdateItemBaseUnitOfMeasure();
    end;

    var
        UnitOfMeasureTranslation: Record "Unit of Measure Translation";

    local procedure UpdateItemBaseUnitOfMeasure()
    var
        Item: Record Item;
    begin
        Item.SetCurrentKey("Base Unit of Measure");
        Item.SetRange("Base Unit of Measure", xRec.Code);
        if not Item.IsEmpty() then
            Item.ModifyAll("Base Unit of Measure", Code, true);
    end;

    procedure GetDescriptionInCurrentLanguage(): Text[50]
    var
        UnitOfMeasureTranslation: Record "Unit of Measure Translation";
        Language: Codeunit Language;
    begin
        if UnitOfMeasureTranslation.Get(Code, Language.GetUserLanguageCode()) then
            exit(UnitOfMeasureTranslation.Description);
        exit(Description);
    end;

    procedure CreateListInCurrentLanguage(var TempUnitOfMeasure: Record "Unit of Measure" temporary)
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        if UnitOfMeasure.FindSet() then
            repeat
                TempUnitOfMeasure := UnitOfMeasure;
                TempUnitOfMeasure.Description := UnitOfMeasure.GetDescriptionInCurrentLanguage();
                TempUnitOfMeasure.Insert();
            until UnitOfMeasure.Next() = 0;
    end;

    local procedure SetLastDateTimeModified()
    var
        DotNet_DateTimeOffset: Codeunit DotNet_DateTimeOffset;
    begin
        "Last Modified Date Time" := DotNet_DateTimeOffset.ConvertToUtcDateTime(CurrentDateTime);
    end;
}
