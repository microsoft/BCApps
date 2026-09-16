// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

using System.Reflection;

table 31284 "Auto. Create Default Dim. CZA"
{
    Caption = 'Auto. Create Default Dimension';
    LookupPageId = "Auto. Create Default Dim. CZA";
    DrillDownPageId = "Auto. Create Default Dim. CZA";

    fields
    {
        field(1; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            DataClassification = CustomerContent;
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table));
            NotBlank = true;

            trigger OnLookup()
            var
                TempAllObjWithCaption: Record AllObjWithCaption temporary;
                DimensionManagement: Codeunit DimensionManagement;
            begin
                Clear(TempAllObjWithCaption);
                DimensionManagement.DefaultDimObjectNoList(TempAllObjWithCaption);
                if Page.RunModal(Page::Objects, TempAllObjWithCaption) = Action::LookupOK then begin
                    "Table ID" := TempAllObjWithCaption."Object ID";
                    Validate("Table ID");
                end;
            end;

            trigger OnValidate()
            var
                TempAllObjWithCaption: Record AllObjWithCaption temporary;
                DimensionManagement: Codeunit DimensionManagement;
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateTableID(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                CalcFields("Table Caption");
                DimensionManagement.DefaultDimObjectNoList(TempAllObjWithCaption);
                TempAllObjWithCaption.SetRange("Object Type", TempAllObjWithCaption."Object Type"::Table);
                TempAllObjWithCaption.SetRange("Object ID", "Table ID");
                if TempAllObjWithCaption.IsEmpty() then
                    FieldError("Table ID");
            end;
        }
        field(2; "Dimension Code"; Code[20])
        {
            Caption = 'Dimension Code';
            DataClassification = CustomerContent;
            TableRelation = Dimension;
            NotBlank = true;
        }
        field(3; "Table Caption"; Text[249])
        {
            Caption = 'Table Caption';
            FieldClass = FlowField;
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Table),
                                                                          "Object ID" = field("Table ID")));
            Editable = false;
        }
        field(10; "Dim. Description Field ID"; Integer)
        {
            Caption = 'Dim. Description Field ID';
            DataClassification = CustomerContent;
            TableRelation = Field."No." where(TableNo = field("Table ID"));

            trigger OnLookup()
            var
                RecField: Record "Field";
                FieldSelection: Codeunit "Field Selection";
            begin
                RecField.SetRange(TableNo, "Table ID");
                if RecField.Get("Table ID", "Dim. Description Field ID") then;

                if FieldSelection.Open(RecField) then
                    Validate("Dim. Description Field ID", RecField."No.");
            end;

            trigger OnValidate()
            var
                DimensionAutoCreateMgtCZA: Codeunit "Dimension Auto.Create Mgt. CZA";
            begin
                if "Dim. Description Field ID" = 0 then
                    "Dim. Description Update" := "Dim. Description Update"::" "
                else
                    DimensionAutoCreateMgtCZA.CreateAndSendSignOutNotificationAutoDim();
            end;
        }
        field(11; "Dim. Description Fld. Name"; Text[100])
        {
            Caption = 'Dim. Description Field Name';
            FieldClass = FlowField;
            CalcFormula = lookup(Field."Field Caption" where(TableNo = field("Table ID"),
                                                              "No." = field("Dim. Description Field ID")));
            Editable = false;
        }
        field(12; "Dim. Description Update"; Option)
        {
            Caption = 'Dimension Description Update';
            DataClassification = CustomerContent;
            OptionCaption = ' ,Create,Update';
            OptionMembers = " ",Create,Update;

            trigger OnValidate()
            begin
                if "Dim. Description Update" <> "Dim. Description Update"::" " then
                    TestField("Dim. Description Field ID");
            end;
        }
        field(13; "Dim. Description Format"; Text[50])
        {
            Caption = 'Dim. Description Format';
            DataClassification = CustomerContent;
        }
        field(14; "Auto. Create Value Posting"; Enum "Default Dimension Value Posting Type")
        {
            Caption = 'Auto. Create Value Posting';
            DataClassification = CustomerContent;
        }
        field(15; "Not Create Default Dimension"; Boolean)
        {
            Caption = 'Not Create Default Dimension';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Table ID", "Dimension Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Table ID", "Dimension Code", "Table Caption")
        {
        }
    }

    trigger OnInsert()
    var
        DimensionAutoCreateMgtCZA: Codeunit "Dimension Auto.Create Mgt. CZA";
        DimensionAutoUpdateMgtCZA: Codeunit "Dimension Auto.Update Mgt. CZA";
    begin
        DimensionAutoUpdateMgtCZA.ForceSetDimChangeSetupRead();
        DimensionAutoCreateMgtCZA.CreateAndSendSignOutNotificationAutoDim();
    end;

    trigger OnModify()
    var
        DimensionAutoCreateMgtCZA: Codeunit "Dimension Auto.Create Mgt. CZA";
        DimensionAutoUpdateMgtCZA: Codeunit "Dimension Auto.Update Mgt. CZA";
    begin
        DimensionAutoUpdateMgtCZA.ForceSetDimChangeSetupRead();
        DimensionAutoCreateMgtCZA.CreateAndSendSignOutNotificationAutoDim();
    end;

    trigger OnDelete()
    var
        DimensionAutoCreateMgtCZA: Codeunit "Dimension Auto.Create Mgt. CZA";
        DimensionAutoUpdateMgtCZA: Codeunit "Dimension Auto.Update Mgt. CZA";
    begin
        DimensionAutoUpdateMgtCZA.ForceSetDimChangeSetupRead();
        DimensionAutoCreateMgtCZA.CreateAndSendSignOutNotificationAutoDim();
    end;

    /// <summary>
    /// Integration event raised before validating Table ID field assignment.
    /// Enables custom table ID validation logic and table existence verification.
    /// </summary>
    /// <param name="AutoCreateDefaultDimCZA">Auto. Create Default Dim. CZA record being validated</param>
    /// <param name="xRecAutoCreateDefaultDimCZA">Previous version of Auto. Create Default Dim. CZA record</param>
    /// <param name="IsHandled">Set to true to skip standard table ID validation</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateTableID(var AutoCreateDefaultDimCZA: Record "Auto. Create Default Dim. CZA"; xRecAutoCreateDefaultDimCZA: Record "Auto. Create Default Dim. CZA"; var IsHandled: Boolean)
    begin
    end;
}
