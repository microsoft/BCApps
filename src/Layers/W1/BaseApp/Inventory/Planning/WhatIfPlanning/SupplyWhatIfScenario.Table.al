// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Planning;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Transfer;
using Microsoft.Purchases.Document;
using System.Reflection;

table 5440 "Supply What-If Scenario"
{
    Caption = 'Supply What-If Scenario';
    TableType = Temporary;
    DataCaptionFields = "Scenario Name";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Scenario Name"; Text[250])
        {
            Caption = 'Scenario Name';
        }
        field(3; "Document Type"; Integer)
        {
            Caption = 'Document Type';
        }
        field(4; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(5; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item;
        }
        field(6; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location;
        }
        field(7; "Original Quantity"; Decimal)
        {
            Caption = 'Original Quantity';
            DecimalPlaces = 0 : 5;
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(8; "What-If Quantity"; Decimal)
        {
            Caption = 'What-If Quantity';
            DecimalPlaces = 0 : 5;
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(9; "Original Date"; Date)
        {
            Caption = 'Original Date';
        }
        field(10; "What-If Date"; Date)
        {
            Caption = 'What-If Date';
        }
        field(13; "Document Table No."; Integer)
        {
            Caption = 'Document Table No.';
        }
        field(14; "Document Line No."; Integer)
        {
            Caption = 'Document Line No.';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(Document; "Document Type", "Document No.", "Item No.")
        {
        }
    }

    var
        InvalidRecordTypeErr: Label 'Unable to update what-if scenario. Invalid record type.';
        InvalidTableErr: Label '%1 is not a valid record type for creating what-if scenario.', Comment = '%1 - Record Table Name';
        PurchaseScenarioLbl: Label 'Purchase %1 %2 - %3 - %4', Comment = '%1 - Document Type, %2 - Document No., %3 - Item No., %4 - Document Line No.';
        TransferScenarioLbl: Label 'Transfer Receipt %1 - %2 - %3', Comment = '%1 - Document No., %2 - Item No., %3 - Line No.';

    procedure CreateScenario(Record: Variant)
    begin
        Rec.Init();
        Rec."Entry No." := 1;
        UpdateBySourceRecord(Record, Rec);
        Rec.Insert();
    end;

    local procedure UpdateBySourceRecord(Record: Variant; var WhatIfScenario: Record "Supply What-If Scenario")
    var
        PurchaseLine: Record "Purchase Line";
        TransferLine: Record "Transfer Line";
        DataTypeMgmt: Codeunit "Data Type Management";
        RecRef: RecordRef;
        IsHandled: Boolean;
    begin
        if not DataTypeMgmt.GetRecordRef(Record, RecRef) then
            Error(InvalidRecordTypeErr);

        case RecRef.Number of
            Database::"Purchase Line":
                begin
                    RecRef.SetTable(PurchaseLine);
                    UpdateFromPurchaseLine(WhatIfScenario, PurchaseLine);
                end;
            Database::"Transfer Line":
                begin
                    RecRef.SetTable(TransferLine);
                    UpdateFromTransferLine(WhatIfScenario, TransferLine);
                end;
            else begin
                OnUpdateBySourceRecordOnElseCase(Record, RecRef, WhatIfScenario, IsHandled);

                if not IsHandled then
                    Error(InvalidTableErr, RecRef.Name());
            end;
        end;
    end;

    local procedure UpdateFromPurchaseLine(var WhatIfScenario: Record "Supply What-If Scenario"; PurchaseLine: Record "Purchase Line")
    begin
        WhatIfScenario."Document Table No." := Database::"Purchase Line";
        WhatIfScenario."Scenario Name" := StrSubstNo(PurchaseScenarioLbl, PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."No.", PurchaseLine."Line No.");
        WhatIfScenario."Document Type" := PurchaseLine."Document Type".AsInteger();
        WhatIfScenario."Document No." := PurchaseLine."Document No.";
        WhatIfScenario."Document Line No." := PurchaseLine."Line No.";
        WhatIfScenario."Item No." := PurchaseLine."No.";
        WhatIfScenario."Location Code" := PurchaseLine."Location Code";
        WhatIfScenario."Original Quantity" := PurchaseLine.Quantity;
        WhatIfScenario."What-If Quantity" := PurchaseLine.Quantity;
        WhatIfScenario."Original Date" := PurchaseLine."Expected Receipt Date";
        WhatIfScenario."What-If Date" := PurchaseLine."Expected Receipt Date";
    end;

    local procedure UpdateFromTransferLine(var WhatIfScenario: Record "Supply What-If Scenario"; TransferLine: Record "Transfer Line")
    begin
        WhatIfScenario."Document Table No." := Database::"Transfer Line";
        WhatIfScenario."Scenario Name" := StrSubstNo(TransferScenarioLbl, TransferLine."Document No.", TransferLine."Item No.", TransferLine."Line No.");
        WhatIfScenario."Document No." := TransferLine."Document No.";
        WhatIfScenario."Document Line No." := TransferLine."Line No.";
        WhatIfScenario."Item No." := TransferLine."Item No.";
        WhatIfScenario."Location Code" := TransferLine."Transfer-to Code";
        WhatIfScenario."Original Quantity" := TransferLine.Quantity;
        WhatIfScenario."What-If Quantity" := TransferLine.Quantity;
        WhatIfScenario."Original Date" := TransferLine."Receipt Date";
        WhatIfScenario."What-If Date" := TransferLine."Receipt Date";
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateBySourceRecordOnElseCase(Record: Variant; RecRef: RecordRef; var WhatIfScenario: Record "Supply What-If Scenario"; var IsHandled: Boolean)
    begin
    end;
}