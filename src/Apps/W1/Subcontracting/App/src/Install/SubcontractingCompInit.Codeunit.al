// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Requisition;
using Microsoft.Manufacturing.Journal;

codeunit 99001503 "Subcontracting Comp. Init."
{
    procedure CreateBasicSubcontractingMgtSetup()
    begin
        CreateSubcontractingManagementSetup();
    end;

    local procedure CreateSubcontractingManagementSetup()
    var
        SubcManagementSetup: Record "Subc. Management Setup";
    begin
        if not SubcManagementSetup.Get() then begin
            SubcManagementSetup.Init();
            CreateLaborReqWkshTemplateAndNameAndUpdateSetup(SubcManagementSetup);
            SubcManagementSetup."Direct Transfer" := true;
            SubcManagementSetup."Create Prod. Order Info Line" := true;
            Evaluate(SubcManagementSetup."Subc. Inb. Whse. Handling Time", GetDefaultInboundWhseHandlingTime());
            SubcManagementSetup.Insert(true);
        end;
    end;

    procedure CreateLaborReqWkshTemplateAndNameAndUpdateSetup(var SubcManagementSetup: Record "Subc. Management Setup")
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
    begin
        CreateReqWkshTemplate(ReqWkshTemplate, false);
        CreateRequisitionWkshName(RequisitionWkshName, ReqWkshTemplate.Name);
        SubcManagementSetup."Subcontracting Template Name" := ReqWkshTemplate.Name;
        SubcManagementSetup."Subcontracting Batch Name" := RequisitionWkshName.Name;
    end;

    procedure CreateReqWkshTemplate(var ReqWkshTemplate: Record "Req. Wksh. Template"; Recurring: Boolean)
    var
        ReqWkshTempDescLbl: Label 'Subcontracting', MaxLength = 80;
        ReqWkshTempNameLbl: Label 'SUBCONTR', MaxLength = 10;
    begin
        ReqWkshTemplate.SetRange(Type, ReqWkshTemplate.Type::"For. Labor");
        if ReqWkshTemplate.FindFirst() then
            exit;

        ReqWkshTemplate.Init();
        ReqWkshTemplate.Validate(Name, ReqWkshTempNameLbl);
        ReqWkshTemplate.Validate(Description, ReqWkshTempDescLbl);
        ReqWkshTemplate.Recurring := Recurring;
        ReqWkshTemplate.Validate(Type, ReqWkshTemplate.Type::"For. Labor");
        ReqWkshTemplate.Validate("Page ID", Page::"Subcontracting Worksheet");
        ReqWkshTemplate.Insert(true);
    end;

    procedure CreateRequisitionWkshName(var RequisitionWkshName: Record "Requisition Wksh. Name"; WorksheetTemplateName: Text)
    var
        ReqWkshDescLbl: Label 'Subcontracting', MaxLength = 100;
        ReqWkshNameLbl: Label 'SUBCONTR', MaxLength = 10;
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
    var
        DefaultInboundWhseHandlingTimeLbl: Label '<1D>', Locked = true;
    begin
        exit(DefaultInboundWhseHandlingTimeLbl);
    end;
}