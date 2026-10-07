/// <summary>
/// Insert demo word templates.
/// </summary>
codeunit 101403 "Create Word Templates"
{
    Permissions = tabledata "Word Template" = ri;

    trigger OnRun()
    begin
        InsertWordTemplates();
    end;

    local procedure InsertWordTemplates()
    var
        DemoDataSetup: Record "Demo Data Setup";
    begin
        DemoDataSetup.Get();
        InsertWordTemplate('EVENT', CustomerEventLbl, Database::Customer, DemoDataSetup."Path to Picture Folder" + 'WordTemplates\WordTemplate_Customer_Event.docx');
        InsertWordTemplate('THANKSNOTE', ContactThanksNoteLbl, Database::Contact, DemoDataSetup."Path to Picture Folder" + 'WordTemplates\WordTemplate_Contact_Thanksnote.docx');
        InsertWordTemplate('MEMO', VendorMemoLbl, Database::Vendor, DemoDataSetup."Path to Picture Folder" + 'WordTemplates\WordTemplate_Vendor_Memo.docx');
    end;

    local procedure InsertWordTemplate(Code: Code[30]; Name: Text[250]; TableId: Integer; TemplateFile: Text)
    var
        WordTemplate: Record "Word Template";
        Language: Codeunit Language;
    begin
        if WordTemplate.Get(Code) then
            exit;

        WordTemplate.Init();
        WordTemplate.Code := Code;
        WordTemplate.Name := Name;
        WordTemplate."Table ID" := TableId;
        WordTemplate."Language Code" := Language.GetUserLanguageCode();
        WordTemplate.Template.ImportFile(TemplateFile, 'Template');

        WordTemplate.Insert();
    end;

    var
        CustomerEventLbl: Label 'Customer Event';
        ContactThanksNoteLbl: Label 'Contact Thanks Note';
        VendorMemoLbl: Label 'Vendor Memo';
}
