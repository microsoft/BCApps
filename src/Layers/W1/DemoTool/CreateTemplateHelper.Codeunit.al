codeunit 101996 "Create Template Helper"
{

    trigger OnRun()
    begin
    end;

    procedure CreateTemplateHeader(var ConfigTemplateHeader: Record "Config. Template Header"; "Code": Code[10]; Description: Text[50]; TableID: Integer)
    begin
        ConfigTemplateHeader.Init();
        ConfigTemplateHeader.Code := Code;
        ConfigTemplateHeader.Description := Description;
        ConfigTemplateHeader."Table ID" := TableID;
        ConfigTemplateHeader.Insert();
    end;

    procedure CreateTemplateLine(var ConfigTemplateHeader: Record "Config. Template Header"; FieldID: Integer; Value: Text[50])
    var
        ConfigTemplateLine: Record "Config. Template Line";
        NextLineNo: Integer;
    begin
        NextLineNo := 10000;
        ConfigTemplateLine.SetRange("Data Template Code", ConfigTemplateHeader.Code);
        if ConfigTemplateLine.FindLast() then
            NextLineNo := ConfigTemplateLine."Line No." + 10000;

        ConfigTemplateLine.Init();
        ConfigTemplateLine.Validate("Data Template Code", ConfigTemplateHeader.Code);
        ConfigTemplateLine.Validate("Line No.", NextLineNo);
        ConfigTemplateLine.Validate(Type, ConfigTemplateLine.Type::Field);
        ConfigTemplateLine.Validate("Table ID", ConfigTemplateHeader."Table ID");
        ConfigTemplateLine.Validate("Field ID", FieldID);
        ConfigTemplateLine."Default Value" := Value;
        ConfigTemplateLine.Insert(true);
    end;

    procedure CreateTemplateSelectionRule(TableID: Option; TemplateCode: Code[10]; ConditionText: Text; DefaultOrder: Integer; PageID: Option)
    var
        ConfigTmplSelectionRules: Record "Config. Tmpl. Selection Rules";
        FiltersOutStream: OutStream;
    begin
        ConfigTmplSelectionRules.Init();
        ConfigTmplSelectionRules.Validate("Table ID", TableID);
        ConfigTmplSelectionRules.Validate("Page ID", PageID);
        ConfigTmplSelectionRules.Validate("Template Code", TemplateCode);
        ConfigTmplSelectionRules.Validate(Order, DefaultOrder);
        ConfigTmplSelectionRules.Insert(true);

        ConfigTmplSelectionRules."Selection Criteria".CreateOutStream(FiltersOutStream);
        FiltersOutStream.WriteText(ConditionText);
        ConfigTmplSelectionRules.Modify(true);
    end;
}

