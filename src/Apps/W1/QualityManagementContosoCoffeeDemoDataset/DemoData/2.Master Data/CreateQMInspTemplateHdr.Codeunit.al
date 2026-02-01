// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.DemoData.QualityManagement;

using Microsoft.DemoTool.Helpers;

codeunit 5596 "Create QM Insp. Template Hdr"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    var
        ContosoQualityManagement: Codeunit "Contoso Quality Management";
    begin
        ContosoQualityManagement.InsertQualityInspectionTemplateHdr(BicycleChecklist(), BicycleChecklistDescLbl);
        ContosoQualityManagement.InsertQualityInspectionTemplateHdr(Car(), CorrectiveActionDescLbl);
        ContosoQualityManagement.InsertQualityInspectionTemplateHdr(Packaging(), PackagingDescLbl);
        ContosoQualityManagement.InsertQualityInspectionTemplateHdr(Pathogen(), PathogenDescLbl);
        ContosoQualityManagement.InsertQualityInspectionTemplateHdr(Production(), ProductionDescLbl);
        ContosoQualityManagement.InsertQualityInspectionTemplateHdr(ProductionFood(), ProductionFoodDescLbl);
        ContosoQualityManagement.InsertQualityInspectionTemplateHdr(Receive(), ReceiveDescLbl);
        ContosoQualityManagement.InsertQualityInspectionTemplateHdr(ScheduleChange(), ScheduleChangeDescLbl);
    end;

    procedure BicycleChecklist(): Code[20]
    begin
        exit(BicycleChecklistTok);
    end;

    procedure BicycleChecklistDesc(): Text[100]
    begin
        exit(BicycleChecklistDescLbl);
    end;

    procedure Car(): Code[20]
    begin
        exit(CarTok);
    end;

    procedure Packaging(): Code[20]
    begin
        exit(PackagingTok);
    end;

    procedure Pathogen(): Code[20]
    begin
        exit(PathogenTok);
    end;

    procedure Production(): Code[20]
    begin
        exit(ProductionTok);
    end;

    procedure ProductionFood(): Code[20]
    begin
        exit(ProductionFoodTok);
    end;

    procedure Receive(): Code[20]
    begin
        exit(ReceiveTok);
    end;

    procedure ReceiveDesc(): Text[100]
    begin
        exit(ReceiveDescLbl);
    end;

    procedure ScheduleChange(): Code[20]
    begin
        exit(ScheduleChangeTok);
    end;

    var
        BicycleChecklistTok: Label 'BICYCLECHECKLIST', MaxLength = 20;
        CarTok: Label 'CAR', MaxLength = 20;
        PackagingTok: Label 'PACKAGING', MaxLength = 20;
        PathogenTok: Label 'PATHOGEN', MaxLength = 20;
        ProductionTok: Label 'PRODUCTION', MaxLength = 20;
        ProductionFoodTok: Label 'PRODUCTIONFOOD', MaxLength = 20;
        ReceiveTok: Label 'RECEIVE', MaxLength = 20;
        ScheduleChangeTok: Label 'SCHEDULECHANGE', MaxLength = 20;

        BicycleChecklistDescLbl: Label 'Bicycle Checklist', MaxLength = 100;
        CorrectiveActionDescLbl: Label 'Corrective Action', MaxLength = 100;
        PackagingDescLbl: Label 'Packaging', MaxLength = 100;
        PathogenDescLbl: Label 'Pathogen Test', MaxLength = 100;
        ProductionDescLbl: Label 'Production', MaxLength = 100;
        ProductionFoodDescLbl: Label 'Food Production Example', MaxLength = 100;
        ReceiveDescLbl: Label 'Receiving Example', MaxLength = 100;
        ScheduleChangeDescLbl: Label 'Scheduler Change', MaxLength = 100;
}
