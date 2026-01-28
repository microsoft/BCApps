// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.DemoData.QualityManagement;

using Microsoft.DemoTool.Helpers;

codeunit 5597 "Create QM Insp. Template Line"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    var
        ContosoQualityManagement: Codeunit "Contoso Quality Management";
        CreateQualityTest: Codeunit "Create Quality Test";
        CreateQMInspTemplateHdr: Codeunit "Create QM Insp. Template Hdr";
    begin
        ContosoQualityManagement.InsertQualityInspectionTemplateLine(CreateQMInspTemplateHdr.BicycleChecklist(), 10000, CreateQualityTest.GearShiftCheck(), '');
        ContosoQualityManagement.InsertQualityInspectionTemplateLine(CreateQMInspTemplateHdr.BicycleChecklist(), 20000, CreateQualityTest.BrakesCheck(), '');
        ContosoQualityManagement.InsertQualityInspectionTemplateLine(CreateQMInspTemplateHdr.BicycleChecklist(), 30000, CreateQualityTest.VisualWeldCheck(), '');
        ContosoQualityManagement.InsertQualityInspectionTemplateLine(CreateQMInspTemplateHdr.BicycleChecklist(), 40000, CreateQualityTest.HandlebarAligned(), '');

        ContosoQualityManagement.InsertQualityInspectionTemplateLine(CreateQMInspTemplateHdr.Car(), 10000, CreateQualityTest.CarType(), '');
        ContosoQualityManagement.InsertQualityInspectionTemplateLine(CreateQMInspTemplateHdr.Car(), 20000, CreateQualityTest.CarRequestedDate(), '');
        ContosoQualityManagement.InsertQualityInspectionTemplateLine(CreateQMInspTemplateHdr.Car(), 25000, CreateQualityTest.LblNcrDetail(), '');
        ContosoQualityManagement.InsertQualityInspectionTemplateLine(CreateQMInspTemplateHdr.Car(), 30000, CreateQualityTest.NcrRequirement(), '');
        ContosoQualityManagement.InsertQualityInspectionTemplateLine(CreateQMInspTemplateHdr.Car(), 40000, CreateQualityTest.NcrClassification(), '');
        ContosoQualityManagement.InsertQualityInspectionTemplateLine(CreateQMInspTemplateHdr.Car(), 50000, CreateQualityTest.DescriptionOfNonConf(), '');
        ContosoQualityManagement.InsertQualityInspectionTemplateLine(CreateQMInspTemplateHdr.Car(), 60000, CreateQualityTest.NcrObjectiveEvidence(), '');
        ContosoQualityManagement.InsertQualityInspectionTemplateLine(CreateQMInspTemplateHdr.Car(), 65000, CreateQualityTest.LblNcrPlannedAction(), '');
        ContosoQualityManagement.InsertQualityInspectionTemplateLine(CreateQMInspTemplateHdr.Car(), 70000, CreateQualityTest.CarContainment(), '');
        ContosoQualityManagement.InsertQualityInspectionTemplateLine(CreateQMInspTemplateHdr.Car(), 80000, CreateQualityTest.RootCauseFindings(), '');
        ContosoQualityManagement.InsertQualityInspectionTemplateLine(CreateQMInspTemplateHdr.Car(), 90000, CreateQualityTest.CorrectiveAction(), '');
        ContosoQualityManagement.InsertQualityInspectionTemplateLine(CreateQMInspTemplateHdr.Car(), 95000, CreateQualityTest.LblVerification(), '');
        ContosoQualityManagement.InsertQualityInspectionTemplateLine(CreateQMInspTemplateHdr.Car(), 100000, CreateQualityTest.VerificationOfEffecti(), '');
        ContosoQualityManagement.InsertQualityInspectionTemplateLine(CreateQMInspTemplateHdr.Car(), 110000, CreateQualityTest.CustomerServiceRepre(), '');

        ContosoQualityManagement.InsertQualityInspectionTemplateLine(CreateQMInspTemplateHdr.Packaging(), 10000, CreateQualityTest.PackagingVisual(), '');
        ContosoQualityManagement.InsertQualityInspectionTemplateLine(CreateQMInspTemplateHdr.Packaging(), 20000, CreateQualityTest.PackageWidth(), '');
        ContosoQualityManagement.InsertQualityInspectionTemplateLine(CreateQMInspTemplateHdr.Packaging(), 30000, CreateQualityTest.PackageLength(), '');
        ContosoQualityManagement.InsertQualityInspectionTemplateLine(CreateQMInspTemplateHdr.Packaging(), 40000, CreateQualityTest.PackageHeight(), '');
        ContosoQualityManagement.InsertQualityInspectionTemplateLine(CreateQMInspTemplateHdr.Packaging(), 50000, CreateQualityTest.ShippingLabel(), '');

        ContosoQualityManagement.InsertQualityInspectionTemplateLine(CreateQMInspTemplateHdr.Pathogen(), 10000, CreateQualityTest.ApcPerGram(), '');
        ContosoQualityManagement.InsertQualityInspectionTemplateLine(CreateQMInspTemplateHdr.Pathogen(), 20000, CreateQualityTest.ColiformCount(), '');
        ContosoQualityManagement.InsertQualityInspectionTemplateLine(CreateQMInspTemplateHdr.Pathogen(), 30000, CreateQualityTest.EcoliPresent(), '');

        ContosoQualityManagement.InsertQualityInspectionTemplateLine(CreateQMInspTemplateHdr.ProductionFood(), 10000, CreateQualityTest.Odor(), '');
        ContosoQualityManagement.InsertQualityInspectionTemplateLine(CreateQMInspTemplateHdr.ProductionFood(), 20000, CreateQualityTest.PackagingVisual(), '');
        ContosoQualityManagement.InsertQualityInspectionTemplateLine(CreateQMInspTemplateHdr.ProductionFood(), 30000, CreateQualityTest.Temperature(), '');

        ContosoQualityManagement.InsertQualityInspectionTemplateLine(CreateQMInspTemplateHdr.Receive(), 10000, CreateQualityTest.PackageHeight(), '');
        ContosoQualityManagement.InsertQualityInspectionTemplateLine(CreateQMInspTemplateHdr.Receive(), 20000, CreateQualityTest.PackageLength(), '');
        ContosoQualityManagement.InsertQualityInspectionTemplateLine(CreateQMInspTemplateHdr.Receive(), 30000, CreateQualityTest.PackageWidth(), '');
        ContosoQualityManagement.InsertQualityInspectionTemplateLine(CreateQMInspTemplateHdr.Receive(), 40000, CreateQualityTest.PackagingVisual(), '');

        ContosoQualityManagement.InsertQualityInspectionTemplateLine(CreateQMInspTemplateHdr.ScheduleChange(), 10000, CreateQualityTest.ReasonCode(), '');
        ContosoQualityManagement.InsertQualityInspectionTemplateLine(CreateQMInspTemplateHdr.ScheduleChange(), 20000, CreateQualityTest.Explanation(), '');
    end;
}
