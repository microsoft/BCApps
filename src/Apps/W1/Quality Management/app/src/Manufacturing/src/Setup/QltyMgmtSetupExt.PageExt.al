pageextension 20422 "Qlty. Mgmt. Setup - Mfg" extends "Qlty. Management Setup"
{
    layout
    {
        addbefore("Assembly Trigger")
        {
            field("Production Trigger"; Rec."Production Trigger")
            {
                Caption = 'Production - Create Test';
                ApplicationArea = Manufacturing;
                ShowCaption = true;
                AboutTitle = 'Production related trigger';
                AboutText = 'Optionally choose a production-related trigger to try and create a test.';
            }
            field("Auto Output Configuration"; Rec."Auto Output Configuration")
            {
                Caption = 'Auto Output Configuration';
                ApplicationArea = Manufacturing;
                ShowCaption = true;
                AboutTitle = 'Auto Output Configuration';
                AboutText = 'Provides granular options for when a test should be created automatically during the production process.';
            }
        }

        addafter("Assembly Trigger")
        {
            field(ChooseCreateNewRule_Production; 'Click here to create a new generation rule...')
            {
                ShowCaption = false;
                ApplicationArea = Assembly, Manufacturing;

                trigger OnDrillDown()
                var
                    QltyProdGenRuleWizard: Page "Qlty. Prod. Gen. Rule Wizard";
                begin
                    CurrPage.Update(true);
                    QltyProdGenRuleWizard.RunModal();
                    CurrPage.Update(false);
                end;
            }
            field("Production Update Control"; Rec."Production Update Control")
            {
                ApplicationArea = Manufacturing;
                ShowCaption = true;
                Caption = 'Control Source';
                Importance = Additional;
                Visible = false;
                AboutTitle = 'When to update on production related changes.';
                AboutText = 'Set to "Update when Source Changes" to alter source information as the source record changes (for example, such as when a Production Order changes status to Finished). Set to "Do Not Update" to prevent updating the original source that created the test.';
            }
        }
    }

    actions
    {
        // Add changes to page actions here
    }

    var
        myInt: Integer;
}
