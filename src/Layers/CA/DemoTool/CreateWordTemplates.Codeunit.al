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
        // English (Canadian) - ENC
        InsertWordTemplate('EVENT-EN', CustomerEventLbl, Database::Customer, 'WordTemplates\WordTemplate_Customer_Event_ENC.docx', 'ENC');
        InsertWordTemplate('THANKSNOTE-EN', ContactThanksNoteLbl, Database::Contact, 'WordTemplates\WordTemplate_Contact_Thanksnote_ENC.docx', 'ENC');
        InsertWordTemplate('MEMO-EN', VendorMemoLbl, Database::Vendor, 'WordTemplates\WordTemplate_Vendor_Memo_ENC.docx', 'ENC');

        // French (Canadian) - FRC
        InsertWordTemplate('EVENT-FR', CustomerEventLbl, Database::Customer, 'WordTemplates\WordTemplate_Customer_Event_FRC.docx', 'FRC');
        InsertWordTemplate('THANKSNOTE-FR', ContactThanksNoteLbl, Database::Contact, 'WordTemplates\WordTemplate_Contact_Thanksnote_FRC.docx', 'FRC');
        InsertWordTemplate('MEMO-FR', VendorMemoLbl, Database::Vendor, 'WordTemplates\WordTemplate_Vendor_Memo_FRC.docx', 'FRC');
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
