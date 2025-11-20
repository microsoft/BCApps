// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Setup;

using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Comment;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Family;
using Microsoft.Manufacturing.Forecast;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.RoleCenters;
using Microsoft.Manufacturing.StandardCost;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Utilities;
using System.Privacy;

codeunit 1768 "Manuf.-Data Classification"
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
        ClassifyWorkCenter();
        ClassifyCapacityLedgerEntry();

        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Production Order");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Prod. Order Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Prod. Order Component");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Prod. Order Routing Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Prod. Order Capacity Need");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Prod. Order Routing Tool");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Prod. Order Routing Personnel");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Prod. Order Rtng Qlty Meas.");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Prod. Order Comment Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Prod. Order Rtng Comment Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Prod. Order Comp. Cmt Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Standard Cost Worksheet Name");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Standard Cost Worksheet");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Manufacturing Cue");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Work Shift");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Shop Calendar");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Shop Calendar Working Days");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Shop Calendar Holiday");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Work Center Group");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Machine Center");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::Stop);
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::Scrap);
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Routing Header");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Routing Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Manufacturing Setup");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Manufacturing Comment Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Production BOM Header");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Production BOM Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::Family);
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Family Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Routing Comment Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Production BOM Comment Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Routing Link");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Standard Task");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Production BOM Version");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Capacity Unit of Measure");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Standard Task Tool");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Standard Task Personnel");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Standard Task Description");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Standard Task Quality Measure");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Quality Measure");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Routing Version");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Production Matrix BOM Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Where-Used Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Routing Tool");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Routing Personnel");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Routing Quality Measure");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Planning Routing Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Registered Absence");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Production Forecast Name");
        DataClassificationMgt.SetTableFieldsToNormal(Database::"Forecast Item Variant Loc");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Capacity Constrained Resource");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Calendar Entry");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Calendar Absence Entry");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Production Matrix  BOM Entry");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Production Forecast Entry");
    end;

    local procedure ClassifyWorkCenter()
    var
        DummyWorkCenter: Record "Work Center";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Work Center";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyWorkCenter.FieldNo(County));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyWorkCenter.FieldNo("Post Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyWorkCenter.FieldNo(City));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyWorkCenter.FieldNo("Address 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyWorkCenter.FieldNo(Address));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyWorkCenter.FieldNo("Name 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyWorkCenter.FieldNo("Search Name"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyWorkCenter.FieldNo(Name));
    end;

    local procedure ClassifyCapacityLedgerEntry()
    var
        DummyCapacityLedgerEntry: Record "Capacity Ledger Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Capacity Ledger Entry";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Order No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo(Subcontracting));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Work Shift Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Work Center Group Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Scrap Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Stop Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("External Document No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Document Date"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Qty. per Unit of Measure"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Unit of Measure Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Variant Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Item No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Order Type"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Routing Reference No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Routing No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Ending Time"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Starting Time"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Completely Invoiced"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Last Output Line"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Dimension Set ID"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Global Dimension 2 Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Global Dimension 1 Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Qty. per Cap. Unit of Measure"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Cap. Unit of Measure Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Order Line No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Concurrent Capacity"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Scrap Quantity"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Output Quantity"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Invoiced Quantity"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Stop Time"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Run Time"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Setup Time"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo(Quantity));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Work Center No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Operation No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo(Description));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Document No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo(Type));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Posting Date"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Entry No."));
    end;
}
