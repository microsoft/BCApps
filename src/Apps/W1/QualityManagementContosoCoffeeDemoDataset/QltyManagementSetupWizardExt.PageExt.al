// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft;

using Microsoft.DemoTool;
using Microsoft.QualityManagement.Setup.SetupWizard;

pageextension 5713 QltyManagementSetupWizardExt extends "Qlty. Management Setup Wizard"
{
    layout
    {
        addafter(DemoDataInstructions)
        {
            field(LinkToContosoDemoToolPage; LinkToContosoDemoToolPageLbl)
            {
                Caption = 'Open the Contoso Demo Tool page';
                ShowCaption = false;
                Editable = false;
                ApplicationArea = QualityManagement;

                trigger OnDrillDown()
                begin
                    Page.RunModal(Page::"Contoso Demo Tool");
                end;
            }
        }
    }

    var
        LinkToContosoDemoToolPageLbl: Label 'Contoso Demo Tool';
}