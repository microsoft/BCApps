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
    begin
        // German (Swiss) - DES
        InsertWordTemplate('EVENT-DE', CustomerEventLbl, Database::Customer, 'WordTemplates\WordTemplate_Customer_Event_DES.docx', 'DES');
        InsertWordTemplate('THANKSNOTE-DE', ContactThanksNoteLbl, Database::Contact, 'WordTemplates\WordTemplate_Contact_Thanksnote_DES.docx', 'DES');
        InsertWordTemplate('MEMO-DE', VendorMemoLbl, Database::Vendor, 'WordTemplates\WordTemplate_Vendor_Memo_DES.docx', 'DES');

        // French (Swiss) - FRS
        InsertWordTemplate('EVENT-FR', CustomerEventLbl, Database::Customer, 'WordTemplates\WordTemplate_Customer_Event_FRS.docx', 'FRS');
        InsertWordTemplate('THANKSNOTE-FR', ContactThanksNoteLbl, Database::Contact, 'WordTemplates\WordTemplate_Contact_Thanksnote_FRS.docx', 'FRS');
        InsertWordTemplate('MEMO-FR', VendorMemoLbl, Database::Vendor, 'WordTemplates\WordTemplate_Vendor_Memo_FRS.docx', 'FRS');

        // Italian (Swiss) - ITS
        InsertWordTemplate('EVENT-IT', CustomerEventLbl, Database::Customer, 'WordTemplates\WordTemplate_Customer_Event_ITS.docx', 'ITS');
        InsertWordTemplate('THANKSNOTE-IT', ContactThanksNoteLbl, Database::Contact, 'WordTemplates\WordTemplate_Contact_Thanksnote_ITS.docx', 'ITS');
        InsertWordTemplate('MEMO-IT', VendorMemoLbl, Database::Vendor, 'WordTemplates\WordTemplate_Vendor_Memo_ITS.docx', 'ITS');
    end;

    local procedure InsertWordTemplate(Code: Code[30]; Name: Text[250]; TableId: Integer; TemplateFile: Text; LanguageCode: Code[10])
    var
        WordTemplate: Record "Word Template";
    begin
        if WordTemplate.Get(Code) then
            exit;

        WordTemplate.Init();
        WordTemplate.Code := Code;
        WordTemplate.Name := Name;
        WordTemplate."Table ID" := TableId;
        WordTemplate."Language Code" := LanguageCode;
        WordTemplate.Template.ImportFile(TemplateFile, 'Template');

        WordTemplate.Insert();
    end;

    var
        CustomerEventLbl: Label 'Customer Event';
        ContactThanksNoteLbl: Label 'Contact Thanks Note';
        VendorMemoLbl: Label 'Vendor Memo';
}
