namespace System.IO;

using Microsoft.Foundation.NoSeries;
using System.Reflection;

table 8618 "Config. Template Header"
{
    Caption = 'Config. Template Header';
    LookupPageID = "Config. Template List";
    ReplicateData = false;
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
        field(3; "Table ID"; Integer)
        {
            Caption = 'Table ID';

            trigger OnLookup()
            begin
                ConfigValidateMgt.LookupTable("Table ID");
                if "Table ID" <> 0 then
                    Validate("Table ID");
            end;

            trigger OnValidate()
            begin
                TestXRec();
                CalcFields("Table Name");
            end;
        }
        field(4; "Table Name"; Text[250])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Name" where("Object Type" = const(Table),
                                                                        "Object ID" = field("Table ID")));
            Caption = 'Table Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5; "Table Caption"; Text[250])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Table),
                                                                           "Object ID" = field("Table ID")));
            Caption = 'Table Caption';
            Editable = false;
            FieldClass = FlowField;
        }
        field(6; "Used In Hierarchy"; Boolean)
        {
            CalcFormula = exist("Config. Template Line" where("Data Template Code" = field(Code),
                                                               Type = const(Template)));
            Caption = 'Used In Hierarchy';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7; Enabled; Boolean)
        {
            Caption = 'Enabled';
            InitValue = true;
        }
        field(8; "Instance No. Series"; Code[20])
        {
            Caption = 'Instance No. Series';
            TableRelation = "No. Series";
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
        key(Key2; "Table ID")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        CalcFields("Used In Hierarchy");
        if not "Used In Hierarchy" then begin
            ConfigTemplateLine.SetRange("Data Template Code", Code);
            ConfigTemplateLine.DeleteAll();
        end;
    end;

    trigger OnRename()
    begin
        CalcFields("Used In Hierarchy");
        if not "Used In Hierarchy" then begin
            ConfigTemplateLine.SetRange("Data Template Code", xRec.Code);
            if ConfigTemplateLine.Find('-') then
                repeat
                    ConfigTemplateLine.Rename(Code, ConfigTemplateLine."Line No.");
                until ConfigTemplateLine.Next() = 0;
        end;
    end;

    var
        ConfigTemplateLine: Record "Config. Template Line";
        ConfigValidateMgt: Codeunit "Config. Validate Management";

#pragma warning disable AA0470
        DeleteLinesBeforeChangeTableIdErr: Label 'Template lines that relate to %1 exists. Delete the lines to change the Table ID.';
        NewInstanceCreatedMsg: Label 'A new instance %1 has been created in table %2 %3.', Comment = '%2 = Table ID, %3 = Table Caption';
#pragma warning restore AA0470

    local procedure TestXRec()
    var
        ConfigTemplateLine: Record "Config. Template Line";
    begin
        ConfigTemplateLine.SetRange("Data Template Code", Code);
        if ConfigTemplateLine.FindFirst() then
            if xRec."Table ID" <> "Table ID" then
                Error(DeleteLinesBeforeChangeTableIdErr, xRec."Table ID");
    end;

    procedure ConfirmNewInstance(var RecRef: RecordRef)
    var
        FieldRef: FieldRef;
        KeyRef: KeyRef;
        KeyFieldCount: Integer;
        MessageString: Text[1024];
    begin
        KeyRef := RecRef.KeyIndex(1);
        for KeyFieldCount := 1 to KeyRef.FieldCount do begin
            FieldRef := KeyRef.FieldIndex(KeyFieldCount);
            MessageString := MessageString + ' ' + Format(FieldRef.Value);
            MessageString := DelChr(MessageString, '<');
            Message(StrSubstNo(NewInstanceCreatedMsg, MessageString, RecRef.Number, RecRef.Caption));
        end;
    end;

    procedure SetTemplateEnabled(IsEnabled: Boolean)
    begin
        Validate(Enabled, IsEnabled);
        Modify(true);
    end;

    procedure SetNoSeries(NoSeries: Code[20])
    begin
        Validate("Instance No. Series", NoSeries);
        Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CopyConfigTemplate(FromConfigTemplateCode: Code[10])
    begin
        CopyConfigTemplateHeader(FromConfigTemplateCode);
        CopyConfigTemplateLines(FromConfigTemplateCode, Code);
    end;

    local procedure CopyConfigTemplateHeader(FromConfigTemplateCode: Code[10])
    var
        FromConfigTemplateHeader: Record "Config. Template Header";
    begin
        FromConfigTemplateHeader.Get(FromConfigTemplateCode);
        Validate("Table ID", FromConfigTemplateHeader."Table ID");
        Enabled := FromConfigTemplateHeader.Enabled;
        Modify();
    end;

    local procedure CopyConfigTemplateLines(FromConfigTemplateCode: Code[10]; ConfigTemplateCode: Code[10])
    var
        FromConfigTemplateLine: Record "Config. Template Line";
        ConfigTemplateLine: Record "Config. Template Line";
    begin
        ConfigTemplateLine.SetRange("Data Template Code", ConfigTemplateCode);
        ConfigTemplateLine.DeleteAll();
        FromConfigTemplateLine.SetRange("Data Template Code", FromConfigTemplateCode);
        if FromConfigTemplateLine.FindSet() then
            repeat
                ConfigTemplateLine.Init();
                ConfigTemplateLine.TransferFields(FromConfigTemplateLine);
                ConfigTemplateLine."Data Template Code" := ConfigTemplateCode;
                ConfigTemplateLine.Insert();
            until FromConfigTemplateLine.Next() = 0;
    end;
}

