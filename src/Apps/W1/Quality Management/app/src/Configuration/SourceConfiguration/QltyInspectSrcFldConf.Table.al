// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Configuration.SourceConfiguration;

using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Utilities;
using System.Reflection;

/// <summary>
/// Used to map a specific source field to a specific target field.
/// </summary>
table 20409 "Qlty. Inspect. Src. Fld. Conf."
{
    Caption = 'Quality Inspection Source Field Configuration';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            TableRelation = "Qlty. Inspect. Source Config.";
            NotBlank = true;
        }
        field(2; "From Table No."; Integer)
        {
            Caption = 'From Table No.';
            NotBlank = true;
            BlankZero = true;
        }
        field(3; "To Table No."; Integer)
        {
            Caption = 'To Table No.';
            NotBlank = true;
            BlankZero = true;
        }
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(5; "From Field No."; Integer)
        {
            Caption = 'From Field No.';
            BlankZero = true;
            NotBlank = true;
            TableRelation = Field."No." where(TableNo = field("From Table No."));
            ToolTip = 'Specifies the from field.';

            trigger OnLookup()
            begin
                Rec.HandleOnLookupFromField();
            end;

            trigger OnValidate()
            begin
                Rec.CalcFields("From Field Name");
            end;
        }
        field(6; "From Field Name"; Text[250])
        {
            CalcFormula = lookup(Field."Field Caption" where(TableNo = field("From Table No."),
                                                             "No." = field("From Field No.")));
            Caption = 'From Field Name';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the from field name.';
        }
        field(7; "To Field No."; Integer)
        {
            Caption = 'To Field No.';
            NotBlank = true;
            BlankZero = true;
            TableRelation = Field."No." where(TableNo = field("To Table No."));
            ToolTip = 'Specifies the To Field No. When the target is an inspection this would be a test on the inspection itself.';

            trigger OnLookup()
            begin
                HandleOnLookupToField();
            end;

            trigger OnValidate()
            var
                CheckOtherUsesQltyInspectSrcFldConf: Record "Qlty. Inspect. Src. Fld. Conf.";
                CheckOtherUsesQltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
            begin
                if Rec."To Field No." > 0 then
                    Rec.CalcFields("To Field Name");

                if Rec."To Field Name".Contains(CustomTok) then begin
                    CheckOtherUsesQltyInspectSrcFldConf.SetFilter(Code, '<>%1', Rec.Code);
                    CheckOtherUsesQltyInspectSrcFldConf.SetFilter("Line No.", '<>%1', Rec."Line No.");
                    CheckOtherUsesQltyInspectSrcFldConf.SetRange("To Field No.", Rec."To Field No.");
                    CheckOtherUsesQltyInspectSrcFldConf.SetAutoCalcFields("From Field Name", "To Field Name");

                    if CheckOtherUsesQltyInspectSrcFldConf.FindFirst() then begin
                        CheckOtherUsesQltyInspectSourceConfig.SetAutoCalcFields("From Table Caption");
                        CheckOtherUsesQltyInspectSourceConfig.Get(CheckOtherUsesQltyInspectSrcFldConf.Code);
                        if not Confirm(StrSubstNo(TheConfigIsAlreadyUsingSourceAndInARelatedChainQst, CheckOtherUsesQltyInspectSrcFldConf.Code, CheckOtherUsesQltyInspectSrcFldConf."To Field Name", CheckOtherUsesQltyInspectSrcFldConf."From Field Name", CheckOtherUsesQltyInspectSourceConfig."From Table Caption")) then
                            Error('');
                    end;
                end;
            end;
        }
        field(8; "To Field Name"; Text[250])
        {
            CalcFormula = lookup(Field."Field Caption" where(TableNo = field("To Table No."),
                                                             "No." = field("To Field No.")));
            Caption = 'To Field Name';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the To Field Name. When the target is an inspection this would be a test on the inspection itself.';
        }
        field(9; "To Type"; Enum "Qlty. Target Type")
        {
            Caption = 'To Type';
            ToolTip = 'Specifies whether this connects to an inspection, or a chained table.';

            trigger OnValidate()
            var
                QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
            begin
                if QltyInspectSourceConfig.Get(Rec.Code) then
                    if QltyInspectSourceConfig."To Type" = QltyInspectSourceConfig."To Type"::Inspection then
                        if Rec."To Type" <> Rec."To Type"::Inspection then
                            Error(TargetConfigErr);

                if Rec."To Type" = Rec."To Type"::Inspection then
                    Rec."To Table No." := Database::"Qlty. Inspection Header";
            end;
        }
        field(10; "Display As"; Text[80])
        {
            Caption = 'Display in Control Information as';
            ToolTip = 'Specifies what to show in the caption for the Control Information section on an inspection.';

            trigger OnValidate()
            begin
                if (Rec."Display As" <> '') and (Rec."To Type" <> Rec."To Type"::Inspection) then
                    Error(CanOnlyBeSetWhenToTypeIsInspectionErr);
            end;
        }
        field(11; "Priority Test"; Enum "Qlty. Config. Test Priority")
        {
            Caption = 'Priority Test';
            ToolTip = 'Specifies if this test is a priority test. Priority tests will always overwrite existing values.';
        }
    }

    keys
    {
        key(Key1; "Code", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "From Table No.", "To Table No.", "From Field No.", "To Field No.")
        {
        }
    }

    var
        QltyFilterHelpers: Codeunit "Qlty. Filter Helpers";
        SourceTok: Label 'Source*', Locked = true;
        TargetConfigErr: Label 'When the target of the source configuration is an inspection, then all target fields must also refer to the inspection. Note that you can chain tables in another source configuration and still target inspection values. For example if you would like to ensure that a field from the Customer is included for a source configuration that is not directly related to a Customer then create another source configuration that links Customer to your record.';
        CanOnlyBeSetWhenToTypeIsInspectionErr: Label 'This is only used when the To Type is an inspection';
        ChooseAFromFieldFirstErr: Label 'Please choose a "from" field first before choosing a "to" field.';
        TheConfigIsAlreadyUsingSourceAndInARelatedChainQst: Label 'The configuration %1 already uses the field %2 to show %3 from the table %4. Are you sure you want to also map the same field here?', Comment = '%1=the config, %2=the field being mapped in the inspection, %3=the field it is coming from, %4=the table it is coming from.';
        CustomTok: Label 'Custom', Locked = true;

    trigger OnInsert()
    begin
        InitLineNoIfNeeded();
    end;

    procedure InitLineNoIfNeeded()
    var
        EnsureUniqueNoQltyInspectSrcFldConf: Record "Qlty. Inspect. Src. Fld. Conf.";
    begin
        if Rec."Line No." = 0 then begin
            EnsureUniqueNoQltyInspectSrcFldConf.SetRange(Code, Rec.Code);
            EnsureUniqueNoQltyInspectSrcFldConf.SetCurrentKey(Code, "Line No.");
            EnsureUniqueNoQltyInspectSrcFldConf.SetLoadFields("Line No.");
            if EnsureUniqueNoQltyInspectSrcFldConf.FindLast() then;
            Rec."Line No." := EnsureUniqueNoQltyInspectSrcFldConf."Line No." + 10000;
        end;
    end;

    internal procedure HandleOnLookupFromField()
    var
        CurrentField: Integer;
    begin
        CurrentField := QltyFilterHelpers.RunModalLookupAnyField(Rec."From Table No.", -1, '');
        if CurrentField > 0 then
            Rec.Validate("From Field No.", CurrentField);
    end;

    internal procedure HandleOnLookupToField()
    var
        CurrentField: Record Field;
        FieldNumber: Integer;
    begin
        if GetFromFieldRecord(CurrentField) then begin
            if (Rec."To Table No." = Database::"Qlty. Inspection Header") or (Rec."To Type" = Rec."To Type"::Inspection) then
                if CurrentField.Type = CurrentField.Type::Option then
                    FieldNumber := QltyFilterHelpers.RunModalLookupAnyField(Database::"Qlty. Inspection Header", -1, SourceTok)
                else
                    FieldNumber := QltyFilterHelpers.RunModalLookupAnyField(Database::"Qlty. Inspection Header", CurrentField.Type, SourceTok)
            else
                FieldNumber := QltyFilterHelpers.RunModalLookupAnyField(Rec."To Table No.", CurrentField.Type, '');

            if FieldNumber >= 0 then
                Rec.Validate("To Field No.", FieldNumber);
        end else begin
            Message(ChooseAFromFieldFirstErr);
            HandleOnLookupFromField();
        end;
    end;

    local procedure GetFromFieldRecord(var FromField: Record Field): Boolean;
    begin
        if (Rec."From Table No." = 0) or (Rec."From Field No." = 0) then
            exit(false);

        FromField.Reset();
        FromField.SetRange(TableNo, Rec."From Table No.");
        FromField.SetRange("No.", Rec."From Field No.");
        exit(FromField.FindFirst());
    end;
}
