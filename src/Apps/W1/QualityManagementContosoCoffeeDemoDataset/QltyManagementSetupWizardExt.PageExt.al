// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft;

using Microsoft.DemoTool;
using Microsoft.QualityManagement.Setup.SetupWizard;

pageextension 5800 QltyManagementSetupWizardExt extends "Qlty. Management Setup Wizard"
{
    layout
    {
        modify(DemoDataInstructions)
        {
            Caption = 'Install demo data';
            InstructionalText = 'To install demo data, go to the Contoso Demo Tool page and select the Quality Management module.';
        }
        addafter(DemoDataInstructions)
        {
            field(LinkToContosoDemoToolPage; LinkToContosoDemoToolPageLbl)
            {
                Caption = 'Contoso Demo Tool page';
                ShowCaption = false;
                Editable = false;
                ApplicationArea = QualityManagement;

                trigger OnDrillDown()
                begin
                    Page.Run(Page::"Contoso Demo Tool");
                end;
            }
            // TODO: Preferred UX but requires Contoso Coffee Demo Dataset app to be INTERNAL VISIBLE TO this app
            // field(InstallDemoData; DoInstallDemoData)
            // {
            //     Caption = 'Install Quality Management demo data now';
            //     ToolTip = 'Select this option to install Quality Management demo data.';
            //     ApplicationArea = QualityManagement;

            //     trigger OnValidate()
            //     var
            //         DemoDataModule: Record "Contoso Demo Data Module";
            //         DemoTool: Codeunit "Contoso Demo Tool";
            //     begin
            //         if DoInstallDemoData then
            //             if Confirm(InstallConfirmMsg, false) then
            //                 if DemoDataModule.Get(Enum::"Contoso Demo Data Module"::"Quality Management") then
            //                     DemoTool.CreateDemoData(DemoDataModule, Enum::"Contoso Demo Data Level"::All);
            //     end;
            // }
        }
    }

    var
        LinkToContosoDemoToolPageLbl: Label 'Contoso Demo Tool';
    // InstallConfirmMsg: Label 'Are you sure you want to install Quality Management demo data now?';
    // DoInstallDemoData: Boolean;
}