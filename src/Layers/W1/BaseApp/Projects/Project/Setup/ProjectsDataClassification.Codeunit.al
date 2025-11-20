// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Setup;

using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Archive;
using Microsoft.Projects.Project.Journal;
using Microsoft.Projects.Project.Ledger;
using Microsoft.Projects.Project.Planning;
using Microsoft.Projects.Project.Pricing;
using Microsoft.Projects.Project.WIP;
using Microsoft.Projects.Resources.Journal;
using Microsoft.Projects.Resources.Ledger;
using Microsoft.Projects.Resources.Pricing;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Projects.Resources.Setup;
using Microsoft.Projects.RoleCenters;
using Microsoft.Projects.TimeSheet;
using Microsoft.Utilities;
using System.Privacy;

codeunit 1765 "Projects-Data Classification"
{
    var
        DataClassificationMgt: Codeunit "Data Classification Mgt.";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Data Classification Eval. Data", 'OnCreateEvaluationDataOnAfterClassifyTablesToNormal', '', false, false)]
    local procedure OnClassifyTables()
    begin
        ClassifyTables();
    end;

    local procedure ClassifyTables()
    begin
        ClassifyMyJob();
        ClassifyTimeSheetLine();
        ClassifyJobRegister();
        ClassifyResourceRegister();
        ClassifyResLedgerEntry();
        ClassifyMyTimeSheets();
        ClassifyJobLedgerEntry();
        ClassifyTimeSheetLineArchive();
        ClassifyJob();
        ClassifyJobArchive();
        ClassifyResCapacityEntry();
        ClassifyResource();
        ClassifyJobPlanningLine();
        ClassifyJobPlanningLineArchive();
        ClassifyTimeSheetChartSetup();
        ClassifyUserTimeRegister();
        ClassifyTimeSheetHeaderArchive();
        ClassifyTimeSheetHeader();

        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Resource Group");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Resource Unit of Measure");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Res. Journal Template");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Res. Journal Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Job Posting Group");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Job Journal Template");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Job Journal Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Res. Journal Batch");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Job Journal Batch");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Job Journal Quantity");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Resources Setup");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Jobs Setup");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Time Sheet Detail");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Time Sheet Comment Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Time Sheet Detail Archive");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Time Sheet Cmt. Line Archive");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Time Sheet Posting Entry");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Job Task");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Job Task Archive");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Job Task Dimension");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Job WIP Method");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Job WIP Warning");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Job Resource Price");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Job Item Price");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Job G/L Account Price");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Job Usage Link");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Job WIP Total");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Job Planning Line Invoice");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Job Planning Line - Calendar");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Job Cue");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Job WIP Entry");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Job WIP G/L Entry");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Job Entry No.");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Resource Price");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Resource Cost");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Resource Price Change");
    end;

    local procedure ClassifyMyJob()
    var
        DummyMyJob: Record "My Job";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"My Job";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyMyJob.FieldNo("User ID"));
    end;

    local procedure ClassifyTimeSheetLine()
    var
        DummyTimeSheetLine: Record "Time Sheet Line";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Time Sheet Line";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyTimeSheetLine.FieldNo("Approved By"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyTimeSheetLine.FieldNo("Approver ID"));
    end;

    local procedure ClassifyJobRegister()
    var
        DummyJobRegister: Record "Job Register";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Job Register";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyJobRegister.FieldNo("User ID"));
    end;

    local procedure ClassifyResourceRegister()
    var
        DummyResourceRegister: Record "Resource Register";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Resource Register";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyResourceRegister.FieldNo("User ID"));
    end;

    local procedure ClassifyResLedgerEntry()
    var
        DummyResLedgerEntry: Record "Res. Ledger Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Res. Ledger Entry";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyResLedgerEntry.FieldNo("Order Line No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyResLedgerEntry.FieldNo("Order Type"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyResLedgerEntry.FieldNo("Order No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyResLedgerEntry.FieldNo("Dimension Set ID"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyResLedgerEntry.FieldNo("Quantity (Base)"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyResLedgerEntry.FieldNo("Qty. per Unit of Measure"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyResLedgerEntry.FieldNo("Source No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyResLedgerEntry.FieldNo("Source Type"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyResLedgerEntry.FieldNo("No. Series"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyResLedgerEntry.FieldNo("External Document No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyResLedgerEntry.FieldNo("Document Date"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyResLedgerEntry.FieldNo("Gen. Prod. Posting Group"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyResLedgerEntry.FieldNo("Gen. Bus. Posting Group"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyResLedgerEntry.FieldNo("Reason Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyResLedgerEntry.FieldNo("Journal Batch Name"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyResLedgerEntry.FieldNo(Chargeable));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyResLedgerEntry.FieldNo("Source Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyResLedgerEntry.FieldNo("User ID"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyResLedgerEntry.FieldNo("Global Dimension 2 Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyResLedgerEntry.FieldNo("Global Dimension 1 Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyResLedgerEntry.FieldNo("Total Price"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyResLedgerEntry.FieldNo("Unit Price"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyResLedgerEntry.FieldNo("Total Cost"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyResLedgerEntry.FieldNo("Unit Cost"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyResLedgerEntry.FieldNo("Direct Unit Cost"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyResLedgerEntry.FieldNo(Quantity));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyResLedgerEntry.FieldNo("Unit of Measure Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyResLedgerEntry.FieldNo("Job No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyResLedgerEntry.FieldNo("Work Type Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyResLedgerEntry.FieldNo(Description));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyResLedgerEntry.FieldNo("Resource Group No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyResLedgerEntry.FieldNo("Resource No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyResLedgerEntry.FieldNo("Posting Date"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyResLedgerEntry.FieldNo("Document No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyResLedgerEntry.FieldNo("Entry Type"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyResLedgerEntry.FieldNo("Entry No."));
    end;

    local procedure ClassifyMyTimeSheets()
    var
        DummyMyTimeSheets: Record "My Time Sheets";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"My Time Sheets";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyMyTimeSheets.FieldNo("User ID"));
    end;

    local procedure ClassifyJobLedgerEntry()
    var
        DummyJobLedgerEntry: Record "Job Ledger Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Job Ledger Entry";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Total Price"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Line Amount (LCY)"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Qty. per Unit of Measure"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Line Type"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Variant Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Transaction Specification"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Ledger Entry No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("External Document No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Description 2"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Quantity (Base)"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Bin Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Reason Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Add.-Currency Line Amount"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Add.-Currency Total Price"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Additional-Currency Total Cost"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("No. Series"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Dimension Set ID"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo(Area));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Unit Cost"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Document Date"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Entry/Exit Point"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Gen. Prod. Posting Group"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Gen. Bus. Posting Group"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Country/Region Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Transport Method"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Transaction Type"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Job Task No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Journal Batch Name"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Original Unit Cost (LCY)"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Entry Type"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Amt. Posted to G/L"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Amt. to Post to G/L"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Ledger Entry Type"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("DateTime Adjusted"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo(Adjusted));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Original Total Cost (ACY)"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Original Total Cost"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Original Unit Cost"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Original Total Cost (LCY)"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Source Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyJobLedgerEntry.FieldNo("User ID"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Line Discount %"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Lot No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Serial No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Customer Price Group"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Work Type Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Global Dimension 2 Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Global Dimension 1 Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Job Posting Group"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Currency Factor"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Currency Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Line Discount Amount (LCY)"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Line Discount Amount"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Line Amount"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Location Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Unit Price"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Total Cost"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Unit of Measure Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Resource Group No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Total Price (LCY)"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Unit Price (LCY)"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Total Cost (LCY)"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Unit Cost (LCY)"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Direct Unit Cost (LCY)"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo(Quantity));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo(Description));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo(Type));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Document No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Posting Date"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Job No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyJobLedgerEntry.FieldNo("Entry No."));
    end;

    local procedure ClassifyTimeSheetLineArchive()
    var
        DummyTimeSheetLineArchive: Record "Time Sheet Line Archive";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Time Sheet Line Archive";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyTimeSheetLineArchive.FieldNo("Approved By"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyTimeSheetLineArchive.FieldNo("Approver ID"));
    end;

    local procedure ClassifyJob()
    var
        DummyJob: Record Job;
        TableNo: Integer;
    begin
        TableNo := DATABASE::Job;
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyJob.FieldNo("Bill-to Name 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyJob.FieldNo("Bill-to Post Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyJob.FieldNo("Bill-to County"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyJob.FieldNo("Bill-to City"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyJob.FieldNo("Bill-to Address 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyJob.FieldNo("Bill-to Address"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyJob.FieldNo("Bill-to Name"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyJob.FieldNo("Bill-to Contact"));
    end;

    local procedure ClassifyJobArchive()
    var
        DummyJobArchive: Record "Job Archive";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Job Archive";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyJobArchive.FieldNo("Bill-to Name 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyJobArchive.FieldNo("Bill-to Post Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyJobArchive.FieldNo("Bill-to County"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyJobArchive.FieldNo("Bill-to City"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyJobArchive.FieldNo("Bill-to Address 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyJobArchive.FieldNo("Bill-to Address"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyJobArchive.FieldNo("Bill-to Name"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyJobArchive.FieldNo("Bill-to Contact"));
    end;

    local procedure ClassifyResCapacityEntry()
    var
        DummyResCapacityEntry: Record "Res. Capacity Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Res. Capacity Entry";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyResCapacityEntry.FieldNo(Capacity));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyResCapacityEntry.FieldNo(Date));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyResCapacityEntry.FieldNo("Resource Group No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyResCapacityEntry.FieldNo("Resource No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyResCapacityEntry.FieldNo("Entry No."));
    end;

    local procedure ClassifyResource()
    var
        DummyResource: Record Resource;
        TableNo: Integer;
    begin
        TableNo := DATABASE::Resource;
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyResource.FieldNo(Image));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyResource.FieldNo("Time Sheet Approver User ID"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyResource.FieldNo("Time Sheet Owner User ID"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyResource.FieldNo(County));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyResource.FieldNo("Post Code"));
        DataClassificationMgt.SetFieldToSensitive(TableNo, DummyResource.FieldNo("Employment Date"));
        DataClassificationMgt.SetFieldToSensitive(TableNo, DummyResource.FieldNo(Education));
        DataClassificationMgt.SetFieldToSensitive(TableNo, DummyResource.FieldNo("Social Security No."));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyResource.FieldNo(City));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyResource.FieldNo("Address 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyResource.FieldNo(Address));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyResource.FieldNo("Name 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyResource.FieldNo("Search Name"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyResource.FieldNo(Name));
    end;

    local procedure ClassifyJobPlanningLine()
    var
        DummyJobPlanningLine: Record "Job Planning Line";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Job Planning Line";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyJobPlanningLine.FieldNo("User ID"));
    end;

    local procedure ClassifyJobPlanningLineArchive()
    var
        DummyJobPlanningLineArchive: Record "Job Planning Line Archive";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Job Planning Line Archive";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyJobPlanningLineArchive.FieldNo("User ID"));
    end;

    local procedure ClassifyTimeSheetChartSetup()
    var
        DummyTimeSheetChartSetup: Record "Time Sheet Chart Setup";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Time Sheet Chart Setup";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyTimeSheetChartSetup.FieldNo("User ID"));
    end;

    local procedure ClassifyUserTimeRegister()
    var
        DummyUserTimeRegister: Record "User Time Register";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"User Time Register";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyUserTimeRegister.FieldNo("User ID"));
    end;

    local procedure ClassifyTimeSheetHeaderArchive()
    var
        DummyTimeSheetHeaderArchive: Record "Time Sheet Header Archive";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Time Sheet Header Archive";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyTimeSheetHeaderArchive.FieldNo("Approver User ID"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyTimeSheetHeaderArchive.FieldNo("Owner User ID"));
    end;

    local procedure ClassifyTimeSheetHeader()
    var
        DummyTimeSheetHeader: Record "Time Sheet Header";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Time Sheet Header";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyTimeSheetHeader.FieldNo("Approver User ID"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyTimeSheetHeader.FieldNo("Owner User ID"));
    end;



}
