// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Integration.Manufacturing;

using Microsoft.QualityManagement.Setup.Setup;

pageextension 20473 "Qlty. Management Setup" extends "Qlty. Management Setup"
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
                ApplicationArea = Manufacturing;

                trigger OnDrillDown()
                begin
                    CurrPage.Update(true);
                    OnDrillDownCreateNewProductionRule();
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

    local procedure OnDrillDownCreateNewProductionRule()
    begin
    end;
}
