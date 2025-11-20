// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

using Microsoft.Foundation.AuditCodes;
using System.Reflection;

table 354 "Default Dimension Priority"
{
    Caption = 'Default Dimension Priority';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            TableRelation = "Source Code";
        }
        field(2; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            NotBlank = true;
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table));

            trigger OnLookup()
            var
                TempAllObjWithCaption: Record AllObjWithCaption temporary;
            begin
                GetDefaultDimTableList(TempAllObjWithCaption);
                if PAGE.RunModal(PAGE::Objects, TempAllObjWithCaption) = ACTION::LookupOK then begin
                    "Table ID" := TempAllObjWithCaption."Object ID";
                    Validate("Table ID");
                end;
            end;

            trigger OnValidate()
            var
                TempAllObjWithCaption: Record AllObjWithCaption temporary;
            begin
                CalcFields("Table Caption");
                GetDefaultDimTableList(TempAllObjWithCaption);
                if not TempAllObjWithCaption.Get(TempAllObjWithCaption."Object Type"::Table, "Table ID") then
                    FieldError("Table ID");
            end;
        }
        field(3; "Table Caption"; Text[250])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Table),
                                                                           "Object ID" = field("Table ID")));
            Caption = 'Table Caption';
            Editable = false;
            FieldClass = FlowField;
        }
        field(4; Priority; Integer)
        {
            Caption = 'Priority';
            MinValue = 1;
        }
    }

    keys
    {
        key(Key1; "Source Code", "Table ID")
        {
            Clustered = true;
        }
        key(Key2; "Source Code", Priority)
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        if Priority = 0 then
            Priority := xRec.Priority + 1;
    end;

    var
        DimensionManagement: Codeunit DimensionManagement;

    local procedure GetDefaultDimTableList(var TempAllObjWithCaption: Record AllObjWithCaption temporary)
    begin
        DimensionManagement.DefaultDimObjectNoList(TempAllObjWithCaption);

        OnAfterGetDefaultDimTableList(TempAllObjWithCaption);
    end;

    procedure InitializeDefaultDimPrioritiesForSourceCode()
    var
        SourceCodeSetup: Record "Source Code Setup";
        IsHandled: Boolean;
    begin
        OnBeforeInitializeDefaultDimPriorities(Rec, IsHandled);
        if IsHandled then
            exit;

        SourceCodeSetup.Get();
        case Rec."Source Code" of
            SourceCodeSetup.Sales:
                begin
                    InsertDefaultDimensionPriority(SourceCodeSetup.Sales, 18, 1);
                    InsertDefaultDimensionPriority(SourceCodeSetup.Sales, 27, 2);
                end;
            SourceCodeSetup."Sales Journal":
                begin
                    InsertDefaultDimensionPriority(SourceCodeSetup."Sales Journal", 18, 1);
                    InsertDefaultDimensionPriority(SourceCodeSetup."Sales Journal", 27, 2);
                end;
            SourceCodeSetup.Purchases:
                begin
                    InsertDefaultDimensionPriority(SourceCodeSetup.Purchases, 23, 1);
                    InsertDefaultDimensionPriority(SourceCodeSetup.Purchases, 27, 2);
                end;
            SourceCodeSetup."Purchase Journal":
                begin
                    InsertDefaultDimensionPriority(SourceCodeSetup."Purchase Journal", 23, 1);
                    InsertDefaultDimensionPriority(SourceCodeSetup."Purchase Journal", 27, 2);
                end;
        end;
    end;

    local procedure InsertDefaultDimensionPriority(SourceCode: Code[20]; TableID: Integer; Priority: Integer)
    var
        DefaultDimensionPriority: Record "Default Dimension Priority";
    begin
        if DefaultDimensionPriority.Get(SourceCode, TableID) then
            exit;

        DefaultDimensionPriority.Init();
        DefaultDimensionPriority.Validate("Source Code", SourceCode);
        DefaultDimensionPriority.Validate("Table ID", TableID);
        DefaultDimensionPriority.Validate(Priority, Priority);
        DefaultDimensionPriority.Insert(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitializeDefaultDimPriorities(var DefaultDimPriority: Record "Default Dimension Priority"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetDefaultDimTableList(var TempAllObjWithCaption: Record AllObjWithCaption temporary)
    begin
    end;
}

