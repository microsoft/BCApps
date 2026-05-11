// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Requisition;
using Microsoft.Manufacturing.Setup;

codeunit 99001503 "Subcontracting Comp. Init."
{
    var
        ReqWkshTempDescLbl: Label 'Subcontracting', MaxLength = 80;
        ReqWkshTempNameLbl: Label 'SUBCONTR', MaxLength = 10;
        ReqWkshDescLbl: Label 'Subcontracting', MaxLength = 100;
        ReqWkshNameLbl: Label 'SUBCONTR', MaxLength = 10;
        DefaultInboundWhseHandlingTimeLbl: Label '<1D>', Locked = true;

    procedure CreateBasicSubcontractingMgtSetup()
    begin
        CreateSubcontractingManagementSetup();
    end;

    local procedure CreateSubcontractingManagementSetup()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
<<<<<<< w/grosss/MoveSubcontractingWorksheetTestsToSubcApp_FomMSMain
        if not SubcManagementSetup.Get() then begin
            SubcManagementSetup.Init();
            CreateSubcontrReqWkshTemplateAndNameAndUpdateSetup(SubcManagementSetup);
            SubcManagementSetup."Create Prod. Order Info Line" := true;
            Evaluate(SubcManagementSetup."Subc. Inb. Whse. Handling Time", GetDefaultInboundWhseHandlingTime());
            SubcManagementSetup.Insert(true);
=======
        if not ManufacturingSetup.Get() then begin
            ManufacturingSetup.Init();
            ManufacturingSetup.Insert(true);
>>>>>>> main
        end;

        if not CreateSubcontractingReqWkshTemplateAndNameAndUpdateSetup(ManufacturingSetup) then
            exit;

        ManufacturingSetup."Create Prod. Order Info Line" := true;
        Evaluate(ManufacturingSetup."Subc. Inb. Whse. Handling Time", GetDefaultInboundWhseHandlingTime());
        ManufacturingSetup.Modify(true);
    end;

<<<<<<< w/grosss/MoveSubcontractingWorksheetTestsToSubcApp_FomMSMain
    procedure CreateSubcontrReqWkshTemplateAndNameAndUpdateSetup(var SubcManagementSetup: Record "Subc. Management Setup")
=======
    procedure CreateSubcontractingReqWkshTemplateAndNameAndUpdateSetup(var ManufacturingSetup: Record "Manufacturing Setup"): Boolean
>>>>>>> main
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
    begin
        if not CreateReqWkshTemplate(ReqWkshTemplate, false) then
            exit(false);

        CreateRequisitionWkshName(RequisitionWkshName, ReqWkshTemplate.Name);
        ManufacturingSetup."Subcontracting Template Name" := ReqWkshTemplate.Name;
        ManufacturingSetup."Subcontracting Batch Name" := RequisitionWkshName.Name;
        exit(true);
    end;

    procedure CreateReqWkshTemplate(var ReqWkshTemplate: Record "Req. Wksh. Template"; Recurring: Boolean): Boolean
    begin
        ReqWkshTemplate.SetRange(Type, ReqWkshTemplate.Type::Subcontracting);
        if ReqWkshTemplate.FindFirst() then
            exit(false);

        ReqWkshTemplate.Init();
        ReqWkshTemplate.Validate(Name, ReqWkshTempNameLbl);
        ReqWkshTemplate.Validate(Description, ReqWkshTempDescLbl);
        ReqWkshTemplate.Recurring := Recurring;
        ReqWkshTemplate.Validate(Type, ReqWkshTemplate.Type::Subcontracting);
        ReqWkshTemplate.Validate("Page ID", Page::"Subc. Subcontracting Worksheet");
        ReqWkshTemplate.Insert(true);
        exit(true);
    end;

    procedure CreateRequisitionWkshName(var RequisitionWkshName: Record "Requisition Wksh. Name"; WorksheetTemplateName: Text)
    begin
        RequisitionWkshName.SetRange("Worksheet Template Name", WorksheetTemplateName);
        if RequisitionWkshName.FindFirst() then
            exit;

        RequisitionWkshName.Init();
        RequisitionWkshName.Validate("Worksheet Template Name", CopyStr(WorksheetTemplateName, 1, MaxStrLen(RequisitionWkshName."Worksheet Template Name")));
        RequisitionWkshName.Validate(Name, ReqWkshNameLbl);
        RequisitionWkshName.Description := ReqWkshDescLbl;
        RequisitionWkshName.Insert(true);
    end;

    local procedure GetDefaultInboundWhseHandlingTime(): Text
    begin
        exit(DefaultInboundWhseHandlingTimeLbl);
    end;
}
