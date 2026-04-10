pageextension 134123 "ERM Tests Data Admin Guide" extends "Data Administration Guide"
{
    layout
    {
        addlast(Content)
        {
            group(ERMTestsDatAdminGuideGroup1)
            {
                Visible = ERMTestsCurrentPage = ERMTestsCurrentPage::TestGuidePage1;
                ShowCaption = false;
                InstructionalText = 'ERM Tests Page 1';

                field(ERMTestsField1; 'ERM Tests Field 1')
                {
                    ApplicationArea = all;
                    ShowCaption = false;
                }
            }
            group(ERMTestsDatAdminGuideGroup2)
            {
                Visible = ERMTestsCurrentPage = ERMTestsCurrentPage::TestGuidePage2;
                ShowCaption = false;
                InstructionalText = 'ERM Tests Page 2';

                field(ERMTestsField2; 'ERM Tests Field 2')
                {
                    ApplicationArea = all;
                    ShowCaption = false;
                }
            }
        }
    }

    actions
    {
        // Add changes to page actions here
    }

    var
        ERMTestsCurrentPage: Enum "Data Administration Guide Page";

    procedure ERMTestsSetCurrentPage(var CurrentPage: Enum "Data Administration Guide Page")
    begin
        ERMTestsCurrentPage := CurrentPage;
    end;
}