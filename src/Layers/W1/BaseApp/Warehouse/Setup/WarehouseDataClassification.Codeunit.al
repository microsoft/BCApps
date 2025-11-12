// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Setup;

using Microsoft.Warehouse.Activity.History;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.ADCS;
using Microsoft.Warehouse.Comment;
using Microsoft.Warehouse.CrossDock;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.History;
using Microsoft.Warehouse.InternalDocument;
using Microsoft.Warehouse.InventoryDocument;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.RoleCenters;
using Microsoft.Warehouse.Structure;
using Microsoft.Warehouse.Tracking;
using Microsoft.Warehouse.Worksheet;
using Microsoft.Utilities;
using System.Privacy;

codeunit 1769 "Warehouse-Data Classification"
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
        ClassifyRegisteredInvtMovementHdr();
        ClassifyPostedInvtPickHeader();
        ClassifyPostedInvtPutawayHeader();
        ClassifyWarehouseEntry();
        ClassifyWarehouseJournalLine();
        ClassifyWarehouseEmployee();
        ClassifyBinCreationWorksheetLine();
        ClassifyWarehouseActivityHeader();
        ClassifyWarehouseRegister();

        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Report Selection Warehouse");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Warehouse Request");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Warehouse Activity Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Warehouse Reason Code");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Whse. Cross-Dock Opportunity");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Warehouse Setup");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Warehouse Comment Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Warehouse Source Filter");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Registered Whse. Activity Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Whse. Item Tracking Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::Zone);
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Bin Content");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Bin Type");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Warehouse Class");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Special Equipment");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Put-away Template Header");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Put-away Template Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Warehouse Journal Template");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Warehouse Receipt Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Posted Whse. Receipt Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Warehouse Shipment Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Posted Whse. Shipment Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Whse. Put-away Request");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Whse. Pick Request");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Whse. Worksheet Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Whse. Worksheet Name");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Whse. Worksheet Template");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Whse. Internal Put-away Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Whse. Internal Pick Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Bin Template");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Bin Creation Wksh. Template");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Bin Creation Wksh. Name");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Posted Invt. Put-away Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Posted Invt. Pick Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Registered Invt. Movement Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Internal Movement Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::Bin);
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Miniform Header");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Miniform Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Miniform Function Group");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Miniform Function");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Item Identifier");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Warehouse Basic Cue");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Warehouse WMS Cue");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Warehouse Worker WMS Cue");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Registered Whse. Activity Hdr.");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Whse. Item Entry Relation");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Warehouse Journal Batch");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Warehouse Receipt Header");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Posted Whse. Receipt Header");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Warehouse Shipment Header");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Posted Whse. Shipment Header");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Whse. Internal Put-away Header");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Whse. Internal Pick Header");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Internal Movement Header");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"ADCS User");

    end;

    local procedure ClassifyRegisteredInvtMovementHdr()
    var
        DummyRegisteredInvtMovementHdr: Record "Registered Invt. Movement Hdr.";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Registered Invt. Movement Hdr.";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyRegisteredInvtMovementHdr.FieldNo("Assigned User ID"));
    end;

    local procedure ClassifyPostedInvtPickHeader()
    var
        DummyPostedInvtPickHeader: Record "Posted Invt. Pick Header";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Posted Invt. Pick Header";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPostedInvtPickHeader.FieldNo("Assigned User ID"));
    end;

    local procedure ClassifyPostedInvtPutawayHeader()
    var
        DummyPostedInvtPutAwayHeader: Record "Posted Invt. Put-away Header";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Posted Invt. Put-away Header";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPostedInvtPutAwayHeader.FieldNo("Assigned User ID"));
    end;

    local procedure ClassifyWarehouseEntry()
    var
        DummyWarehouseEntry: Record "Warehouse Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Warehouse Entry";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyWarehouseEntry.FieldNo(Dedicated));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyWarehouseEntry.FieldNo("Phys Invt Counting Period Type"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyWarehouseEntry.FieldNo("Phys Invt Counting Period Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyWarehouseEntry.FieldNo("User ID"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyWarehouseEntry.FieldNo("Serial No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyWarehouseEntry.FieldNo("Qty. per Unit of Measure"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyWarehouseEntry.FieldNo("Variant Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyWarehouseEntry.FieldNo("Reference No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyWarehouseEntry.FieldNo("Reference Document"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyWarehouseEntry.FieldNo("Warranty Date"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyWarehouseEntry.FieldNo("Entry Type"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyWarehouseEntry.FieldNo("Whse. Document Line No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyWarehouseEntry.FieldNo("Whse. Document Type"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyWarehouseEntry.FieldNo("Whse. Document No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyWarehouseEntry.FieldNo("Unit of Measure Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyWarehouseEntry.FieldNo("Journal Template Name"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyWarehouseEntry.FieldNo(Weight));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyWarehouseEntry.FieldNo(Cubage));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyWarehouseEntry.FieldNo("Lot No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyWarehouseEntry.FieldNo("Expiration Date"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyWarehouseEntry.FieldNo("Bin Type Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyWarehouseEntry.FieldNo("No. Series"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyWarehouseEntry.FieldNo("Reason Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyWarehouseEntry.FieldNo("Source Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyWarehouseEntry.FieldNo("Source Document"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyWarehouseEntry.FieldNo("Source Subline No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyWarehouseEntry.FieldNo("Source Line No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyWarehouseEntry.FieldNo("Source No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyWarehouseEntry.FieldNo("Source Subtype"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyWarehouseEntry.FieldNo("Source Type"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyWarehouseEntry.FieldNo("Qty. (Base)"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyWarehouseEntry.FieldNo(Quantity));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyWarehouseEntry.FieldNo("Item No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyWarehouseEntry.FieldNo(Description));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyWarehouseEntry.FieldNo("Bin Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyWarehouseEntry.FieldNo("Zone Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyWarehouseEntry.FieldNo("Location Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyWarehouseEntry.FieldNo("Registering Date"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyWarehouseEntry.FieldNo("Line No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyWarehouseEntry.FieldNo("Journal Batch Name"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyWarehouseEntry.FieldNo("Entry No."));
    end;

    local procedure ClassifyWarehouseJournalLine()
    var
        DummyWarehouseJournalLine: Record "Warehouse Journal Line";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Warehouse Journal Line";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyWarehouseJournalLine.FieldNo("User ID"));
    end;

    local procedure ClassifyWarehouseEmployee()
    var
        DummyWarehouseEmployee: Record "Warehouse Employee";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Warehouse Employee";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyWarehouseEmployee.FieldNo("ADCS User"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyWarehouseEmployee.FieldNo("User ID"));
    end;

    local procedure ClassifyBinCreationWorksheetLine()
    var
        DummyBinCreationWorksheetLine: Record "Bin Creation Worksheet Line";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Bin Creation Worksheet Line";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyBinCreationWorksheetLine.FieldNo("User ID"));
    end;

    local procedure ClassifyWarehouseActivityHeader()
    var
        DummyWarehouseActivityHeader: Record "Warehouse Activity Header";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Warehouse Activity Header";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyWarehouseActivityHeader.FieldNo("Assigned User ID"));
    end;

    local procedure ClassifyWarehouseRegister()
    var
        DummyWarehouseRegister: Record "Warehouse Register";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Warehouse Register";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyWarehouseRegister.FieldNo("User ID"));
    end;


}
