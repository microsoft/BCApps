codeunit 110001 "Create Resource Template"
{

    trigger OnRun()
    begin
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        Resource: Record Resource;
        CreateTemplateHelper: Codeunit "Create Template Helper";
        xPersonDescriptionTxt: Label 'Resource PERSON', Comment = 'Translate.';
        UOMHourTxt: Label 'HOUR', Comment = 'Number of hours.';

    procedure InsertResourceData()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        CreateTemplateHelper: Codeunit "Create Template Helper";
    begin
        DemoDataSetup.Get();
        // Resource PERSON template
        InsertTemplate(ConfigTemplateHeader, xPersonDescriptionTxt, DemoDataSetup.ServicesCode(), DemoDataSetup.ServicesVATCode(), UOMHourTxt);

        CreateTemplateHelper.CreateTemplateSelectionRule(
          DATABASE::Resource, ConfigTemplateHeader.Code, '', 0, 0);
    end;

    local procedure InsertTemplate(var ConfigTemplateHeader: Record "Config. Template Header"; Description: Text[50]; GenProdGroup: Code[20]; VATProdGroup: Code[20]; BaseUOM: Code[10])
    var
        ConfigTemplateManagement: Codeunit "Config. Template Management";
    begin
        CreateTemplateHelper.CreateTemplateHeader(
          ConfigTemplateHeader, ConfigTemplateManagement.GetNextAvailableCode(DATABASE::Resource), Description, DATABASE::Resource);
        CreateTemplateHelper.CreateTemplateLine(ConfigTemplateHeader, Resource.FieldNo("Gen. Prod. Posting Group"), GenProdGroup);
        CreateTemplateHelper.CreateTemplateLine(ConfigTemplateHeader, Resource.FieldNo("VAT Prod. Posting Group"), VATProdGroup);
        CreateTemplateHelper.CreateTemplateLine(ConfigTemplateHeader, Resource.FieldNo("Base Unit of Measure"), BaseUOM);
    end;
}

