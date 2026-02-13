// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Configuration.SourceConfiguration;

using Microsoft.QualityManagement.Document;
using System.Reflection;

/// <summary>
/// A source configuration defines how to map a table, such as a production order line to an inspection.
/// Multiple tables can be defined because there are conditional filters that make this applicable.
/// For example, you could have a conditional filter on a warehouse pick line based on the source type or source document type.
/// When the to type is an inspection, the to table number is automatically associated with an inspection document.
/// When the to type is a chained table, that allows linking multiple tables together.
/// How you can use chained tables:
///     - take additional fields for related records:
///         - example 1 : take the item no. from the prod order line even though the inspection might be against a prod order routing line.)
///             (use case being: visibility into seeing the item no., without having to add a flowfield to fetch the item no.)
///         - example 2 : take the item category or item attribute from the item card or item attribute card.
///             (use case being: we only want to create an inspection when the item attributes or item category is xyz.)
///         - example 3 : take the customer card, for customer specific filters.
///             (Use case being: we only want this inspection for items made or shipped to a specific customer)
/// </summary>
table 20407 "Qlty. Inspect. Source Config."
{
    Caption = 'Quality Inspection Source Configuration';
    DrillDownPageId = "Qlty. Ins. Source Config. List";
    LookupPageId = "Qlty. Ins. Source Config. List";
    DataClassification = CustomerContent;
    Description = 'Use this page to configure what will automatically populate from other tables into quality inspections. This is also used to tell Business Central how to find one record from another, by setting which field in the ''From'' table connects to which field in the ''To'' table.';

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
            ToolTip = 'Specifies a short name for this configuration. There is typically one entry for each configuration that associated a table with a given template.';

            trigger OnValidate()
            begin
                Rec."Code" := DelChr(Rec."Code", '=', ' ><{}.@!`~''"|\/?&*()_+-=');
            end;
        }
        field(2; "From Table No."; Integer)
        {
            Caption = 'From Table No.';
            NotBlank = true;
            BlankZero = true;
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table));
            ToolTip = 'Specifies the from table. As an example for production related inspection this should be 5409.';

            trigger OnValidate()
            begin
                if (Rec."From Table No." = Rec."To Table No.") and (Rec."From Table No." <> Database::"Qlty. Inspection Header") then
                    Error(TheFromAndToCannotBeTheSameErr);
                if Rec."To Table No." <> xRec."To Table No." then
                    UpdateChildLines();
            end;
        }
        field(3; "From Table Caption"; Text[249])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Table),
                                                                          "Object ID" = field("From Table No.")));
            Caption = 'From Table';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the from table name. As an example for production related inspections this would typically be the Prod. Order Routing Line.';
        }
        field(4; "From Table Filter"; Text[250])
        {
            Caption = 'From Table Filter';
            ToolTip = 'Specifies a filter to specify specific criteria when to connect the From table to the To table';
        }
        field(5; "To Table No."; Integer)
        {
            Caption = 'To Table No.';
            InitValue = 20405;
            BlankZero = true;
            NotBlank = true;
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table));
            ToolTip = 'Specifies the destination table mapping.';

            trigger OnValidate()
            begin
                if Rec."To Table No." <> xRec."To Table No." then
                    UpdateChildLines();
            end;
        }
        field(6; "To Table Caption"; Text[249])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Table),
                                                                          "Object ID" = field("To Table No.")));
            Caption = 'To Table';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the table this is connected to. This can also be the Quality Inspection.';
        }
        field(7; "To Type"; Enum "Qlty. Target Type")
        {
            InitValue = Inspection;
            Caption = 'To Type';
            ToolTip = 'Specifies whether this connects to an inspection, or a chained table.';

            trigger OnValidate()
            begin
                if Rec."To Type" = Rec."To Type"::Inspection then
                    Rec.Validate("To Table No.", Database::"Qlty. Inspection Header");
            end;
        }
        field(8; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description of the the mapping.';
        }
        field(9; "Sort Order"; Integer)
        {
            BlankZero = true;
            Caption = 'Sort Order';
        }
        field(11; Enabled; Boolean)
        {
            Caption = 'Enabled';
            InitValue = true;
            ToolTip = 'Specifies whether this is enabled or disabled.';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
        key(Key2; "Sort Order")
        {
        }
        key(Key3; "Sort Order", "From Table No.", "To Table No.", Enabled)
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; Code, "From Table No.", "From Table Caption", "To Table No.", "To Table Caption")
        {
        }
    }

    var
        TheFromAndToCannotBeTheSameErr: Label 'The From Table and To Table cannot refer to the same table.';
        CannotHaveATemplateWithReversedFromAndToErr: Label 'There is another template ''%1'' that reverses the from table and to table. You cannot have this combination to prevent recursive logic. Please change either this source configuration, or please change ''%1''', Comment = '%1=The other template code with conflicting configuration';
        ExistingLinesQst: Label 'There are existing lines that refer to a different table. These lines will need to be reconfigured. Do you want to proceed?';

    trigger OnInsert()
    begin
        UpdateRunOrder();
        PreventRecursion();
    end;

    local procedure PreventRecursion()
    var
        OtherQltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
    begin
        OtherQltyInspectSourceConfig.SetRange("From Table No.", Rec."To Table No.");
        OtherQltyInspectSourceConfig.SetRange("To Table No.", Rec."From Table No.");
        OtherQltyInspectSourceConfig.SetFilter(Code, '<>%1', Rec.Code);
        if OtherQltyInspectSourceConfig.FindFirst() then
            Error(CannotHaveATemplateWithReversedFromAndToErr, OtherQltyInspectSourceConfig.Code);
    end;

    trigger OnModify()
    begin
        UpdateRunOrder();
        PreventRecursion();
    end;

    local procedure UpdateRunOrder()
    var
        FindHighestQltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
    begin
        if ("Sort Order" = 0) or ("Sort Order" = 1) then begin
            FindHighestQltyInspectSourceConfig.SetCurrentKey("Sort Order");
            FindHighestQltyInspectSourceConfig.Ascending(false);
            if FindHighestQltyInspectSourceConfig.FindFirst() then;
            Rec."Sort Order" := FindHighestQltyInspectSourceConfig."Sort Order" + 10;
        end;
    end;

    trigger OnDelete()
    var
        QltyInspectSrcFldConf: Record "Qlty. Inspect. Src. Fld. Conf.";
    begin
        QltyInspectSrcFldConf.SetRange(Code, Code);
        QltyInspectSrcFldConf.DeleteAll();
    end;

    local procedure UpdateChildLines()
    var
        QltyInspectSrcFldConf: Record "Qlty. Inspect. Src. Fld. Conf.";
        HasLinesWithDifferentTables: Boolean;
    begin
        QltyInspectSrcFldConf.SetRange(Code, Rec.Code);

        QltyInspectSrcFldConf.SetFilter("From Table No.", '<>%1&>0', Rec."From Table No.");
        HasLinesWithDifferentTables := HasLinesWithDifferentTables or (not QltyInspectSrcFldConf.IsEmpty());
        QltyInspectSrcFldConf.SetRange("From Table No.");

        QltyInspectSrcFldConf.SetFilter("To Table No.", '<>%1&>0', Rec."To Table No.");
        HasLinesWithDifferentTables := HasLinesWithDifferentTables or (not QltyInspectSrcFldConf.IsEmpty());
        QltyInspectSrcFldConf.SetRange("To Table No.");

        if HasLinesWithDifferentTables then
            if not Confirm(ExistingLinesQst) then
                Error('');

        QltyInspectSrcFldConf.ModifyAll("From Table No.", Rec."From Table No.");

        QltyInspectSrcFldConf.SetRange("To Type", QltyInspectSrcFldConf."To Type"::"Chained table");
        QltyInspectSrcFldConf.ModifyAll("To Table No.", Rec."To Table No.");
    end;
}
