// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

using System.Reflection;

tableextension 31266 "Default Dimension CZA" extends "Default Dimension"
{
    fields
    {
#if not CLEANSCHEMA32
        field(31270; "Automatic Create CZA"; Boolean)
        {
            Caption = 'Automatic Create (Obsolete)';
            DataClassification = CustomerContent;
#if not CLEAN29
            ObsoleteState = Pending;
            ObsoleteTag = '29.0';
#else
            ObsoleteState = Removed;
            ObsoleteTag = '32.0';
#endif
            ObsoleteReason = 'Replaced by table "Auto. Create Default Dim. CZA".';

#if not CLEAN29
#pragma warning disable AL0432
            trigger OnValidate()
            var
                DimensionAutoCreateMgtCZA: Codeunit "Dimension Auto.Create Mgt. CZA";
            begin
                TestField("No.", '');
                DimensionAutoCreateMgtCZA.CreateAndSendSignOutNotificationAutoDim();
            end;
#pragma warning restore AL0432
#endif
        }
        field(31271; "Dim. Description Field ID CZA"; Integer)
        {
            Caption = 'Dim. Description Field ID (Obsolete)';
            TableRelation = Field."No." where(TableNo = field("Table ID"));
            DataClassification = CustomerContent;
#if not CLEAN29
            ObsoleteState = Pending;
            ObsoleteTag = '29.0';
#else
            ObsoleteState = Removed;
            ObsoleteTag = '32.0';
#endif
            ObsoleteReason = 'Replaced by table "Auto. Create Default Dim. CZA".';

#if not CLEAN29
#pragma warning disable AL0432
            trigger OnLookup()
            var
                RecField: Record "Field";
                FieldSelection: Codeunit "Field Selection";
            begin
                RecField.SetRange(TableNo, "Table ID");
                if RecField.Get("Table ID", "Dim. Description Field ID CZA") then;

                if FieldSelection.Open(RecField) then
                    Validate("Dim. Description Field ID CZA", RecField."No.");
            end;

            trigger OnValidate()
            var
                DimensionAutoCreateMgtCZA: Codeunit "Dimension Auto.Create Mgt. CZA";
            begin
                if "Dim. Description Field ID CZA" = 0 then
                    "Dim. Description Update CZA" := "Dim. Description Update CZA"::" "
                else begin
                    TestField("No.", '');
                    TestField("Automatic Create CZA", true);
                    DimensionAutoCreateMgtCZA.CreateAndSendSignOutNotificationAutoDim();
                end;
            end;
#pragma warning restore AL0432
#endif
        }
        field(31272; "Dim. Description Fld. Name CZA"; Text[100])
        {
            Caption = 'Dim. Description Field Name (Obsolete)';
            CalcFormula = Lookup(Field."Field Caption" where(TableNo = field("Table ID"),
                                                              "No." = field("Dim. Description Field ID CZA")));
            FieldClass = FlowField;
            Editable = false;
#if not CLEAN29
            ObsoleteState = Pending;
            ObsoleteTag = '29.0';
#else
            ObsoleteState = Removed;
            ObsoleteTag = '32.0';
#endif
            ObsoleteReason = 'Replaced by table "Auto. Create Default Dim. CZA".';
        }
        field(31273; "Dim. Description Update CZA"; Option)
        {
            Caption = 'Dimension Description Update (Obsolete)';
            OptionCaption = ' ,Create,Update';
            OptionMembers = " ",Create,Update;
            DataClassification = CustomerContent;
#if not CLEAN29
            ObsoleteState = Pending;
            ObsoleteTag = '29.0';
#else
            ObsoleteState = Removed;
            ObsoleteTag = '32.0';
#endif
            ObsoleteReason = 'Replaced by table "Auto. Create Default Dim. CZA".';

#if not CLEAN29
#pragma warning disable AL0432
            trigger OnValidate()
            begin
                if "Dim. Description Update CZA" <> "Dim. Description Update CZA"::" " then begin
                    TestField("Automatic Create CZA", true);
                    TestField("Dim. Description Field ID CZA");
                end;
            end;
#pragma warning restore AL0432
#endif
        }
        field(31274; "Dim. Description Format CZA"; Text[50])
        {
            Caption = 'Dim. Description Format (Obsolete)';
            DataClassification = CustomerContent;
#if not CLEAN29
            ObsoleteState = Pending;
            ObsoleteTag = '29.0';
#else
            ObsoleteState = Removed;
            ObsoleteTag = '32.0';
#endif
            ObsoleteReason = 'Replaced by table "Auto. Create Default Dim. CZA".';
        }
        field(31275; "Auto. Create Value Posting CZA"; Enum "Default Dimension Value Posting Type")
        {
            Caption = 'Auto. Create Value Posting (Obsolete)';
            DataClassification = CustomerContent;
#if not CLEAN29
            ObsoleteState = Pending;
            ObsoleteTag = '29.0';
#else
            ObsoleteState = Removed;
            ObsoleteTag = '32.0';
#endif
            ObsoleteReason = 'Replaced by table "Auto. Create Default Dim. CZA".';

#if not CLEAN29
#pragma warning disable AL0432
            trigger OnValidate()
            begin
                if Rec."Automatic Create CZA" then
                    TestField("No.", '');
            end;
#pragma warning restore AL0432
#endif
        }
#endif
    }
}
