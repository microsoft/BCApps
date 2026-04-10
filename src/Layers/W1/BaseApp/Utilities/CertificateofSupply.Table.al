// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

using Microsoft.Foundation.Enums;
using Microsoft.Inventory.Reports;
using Microsoft.Purchases.History;
using Microsoft.Sales.History;

table 780 "Certificate of Supply"
{
    Caption = 'Certificate of Supply';
    DataClassification = CustomerContent;
    LookupPageId = "Certificates of Supply";

    fields
    {
        field(1; "Document Type"; Enum "Supply Document Type")
        {
            Caption = 'Document Type';
            ToolTip = 'Specifies the type of the posted document to which the certificate of supply applies.';
        }
        field(2; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            ToolTip = 'Specifies the document number of the posted shipment document associated with the certificate of supply.';
            TableRelation = if ("Document Type" = filter("Sales Shipment")) "Sales Shipment Header"."No."
            else
            if ("Document Type" = filter("Return Shipment")) "Return Shipment Header"."No.";
        }
        field(3; Status; Option)
        {
            Caption = 'Status';
            ToolTip = 'Specifies the status for documents where you must receive a signed certificate of supply from the customer.';
            OptionCaption = 'Not Applicable,Required,Received,Not Received';
            OptionMembers = "Not Applicable",Required,Received,"Not Received";

            trigger OnValidate()
            begin
                if xRec.Status = Status then
                    exit;

                if "No." = '' then
                    "No." := "Document No.";

                if Status = Status::Received then
                    "Receipt Date" := WorkDate()
                else
                    "Receipt Date" := 0D;

                if Status = Status::"Not Applicable" then
                    "No." := ''
            end;
        }
        field(4; "No."; Code[20])
        {
            Caption = 'No.';
            ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';

            trigger OnValidate()
            begin
                if Status = Status::"Not Applicable" then begin
                    if "No." <> '' then
                        Error(NoCannotBeEnteredErr);
                end else
                    if "No." = '' then
                        Error(NoCannotBeEmptyErr)
            end;
        }
        field(5; "Receipt Date"; Date)
        {
            Caption = 'Receipt Date';
            ToolTip = 'Specifies the receipt date of the signed certificate of supply.';

            trigger OnValidate()
            begin
                CheckRcptDate();
            end;
        }
        field(6; Printed; Boolean)
        {
            Caption = 'Printed';
            ToolTip = 'Specifies whether the certificate of supply has been printed and sent to the customer.';
        }
        field(7; "Customer/Vendor Name"; Text[100])
        {
            Caption = 'Customer/Vendor Name';
            ToolTip = 'Specifies the name of the customer or vendor.';
            Editable = false;
        }
        field(8; "Shipment Method Code"; Code[10])
        {
            Caption = 'Shipment Method Code';
            ToolTip = 'Specifies the delivery conditions of the related shipment, such as free on board (FOB).';
            Editable = false;
        }
        field(9; "Shipment/Posting Date"; Date)
        {
            Caption = 'Shipment/Posting Date';
            ToolTip = 'Specifies the date that the posted shipment was shipped or posted.';
            Editable = false;
        }
        field(10; "Ship-to Country/Region Code"; Code[10])
        {
            Caption = 'Ship-to Country/Region Code';
            ToolTip = 'Specifies the country/region code of the address that the items are shipped to.';
            Editable = false;
        }
        field(11; "Customer/Vendor No."; Code[20])
        {
            Caption = 'Customer/Vendor No.';
            ToolTip = 'Specifies the number of the customer or vendor.';
        }
        field(12; "Vehicle Registration No."; Text[20])
        {
            Caption = 'Vehicle Registration No.';
            ToolTip = 'Specifies the vehicle registration number associated with the shipment.';

            trigger OnValidate()
            begin
                if (Status = Status::Received) and ("Vehicle Registration No." <> xRec."Vehicle Registration No.") then
                    Error(VehicleRegNoCannotBeChangedErr, FieldCaption("Vehicle Registration No."), Status::Received)
            end;
        }
    }

    keys
    {
        key(Key1; "Document Type", "Document No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        RecDateCannotBeEmptyErr: Label 'The Receipt Date cannot be empty when Status is Received.';
        RecDateCannotBeEnteredErr: Label 'You can enter the Receipt Date only if the status of the Certificate of Supply is Received.';
        CertRecDateBeforeShipmPostDateErr: Label 'The Receipt Date of the certificate cannot be earlier than the Shipment/Posting Date.';
        NoCannotBeEnteredErr: Label 'The No. field cannot be filled in when the status of the Certificate of Supply is set to Not Applicable.';
        NoCannotBeEmptyErr: Label 'The No. field cannot be empty when the status of the Certificate of Supply is set to Required, Received, or Not Received.';
#pragma warning disable AA0470
        VehicleRegNoCannotBeChangedErr: Label 'The %1 field cannot be changed when the status of the Certificate of Supply is set to %2.';
#pragma warning restore AA0470

    procedure Print()
    var
        DocumentType: Enum "Supply Document Type";
    begin
        DocumentType := "Document Type";

        if Rec.GetFilter("Document Type") <> '' then
            DocumentType := GetRangeMin("Document Type");

        case DocumentType of
            DocumentType::"Sales Shipment",
            DocumentType::"Return Shipment":
                REPORT.RunModal(REPORT::"Certificate of Supply", true, false, Rec);
            else
                OnPrint(Rec);
        end;
    end;

    procedure SetPrintedTrue()
    begin
        if Status = Status::"Not Applicable" then
            SetRequired("Document No.");
        Printed := true;

        Modify();
    end;

    procedure SetRequired(CertificateNo: Code[20])
    begin
        Status := Status::Required;
        "No." := CertificateNo;
        "Receipt Date" := 0D;
        Modify();
    end;

    local procedure CheckRcptDate()
    begin
        if Status = Status::Received then begin
            if "Receipt Date" = 0D then
                Error(RecDateCannotBeEmptyErr);
            if "Shipment/Posting Date" > "Receipt Date" then
                Error(CertRecDateBeforeShipmPostDateErr);
        end else
            if "Receipt Date" <> 0D then
                Error(RecDateCannotBeEnteredErr);
    end;

    procedure InitFromSales(var SalesShipmentHeader: Record "Sales Shipment Header")
    begin
        if not Get("Document Type"::"Sales Shipment", SalesShipmentHeader."No.") then begin
            Init();
            "Document Type" := "Document Type"::"Sales Shipment";
            "Document No." := SalesShipmentHeader."No.";
            "Customer/Vendor Name" := SalesShipmentHeader."Ship-to Name";
            "Shipment Method Code" := SalesShipmentHeader."Shipment Method Code";
            "Shipment/Posting Date" := SalesShipmentHeader."Shipment Date";
            "Ship-to Country/Region Code" := SalesShipmentHeader."Ship-to Country/Region Code";
            "Customer/Vendor No." := SalesShipmentHeader."Bill-to Customer No.";
            OnAfterInitFromSales(Rec, SalesShipmentHeader);
            Insert(true);
        end
    end;

    procedure InitFromPurchase(var ReturnShipmentHeader: Record "Return Shipment Header")
    begin
        if not Get("Document Type"::"Return Shipment", ReturnShipmentHeader."No.") then begin
            Init();
            "Document Type" := "Document Type"::"Return Shipment";
            "Document No." := ReturnShipmentHeader."No.";
            "Customer/Vendor Name" := ReturnShipmentHeader."Ship-to Name";
            "Shipment Method Code" := ReturnShipmentHeader."Shipment Method Code";
            "Shipment/Posting Date" := ReturnShipmentHeader."Posting Date";
            "Ship-to Country/Region Code" := ReturnShipmentHeader."Ship-to Country/Region Code";
            "Customer/Vendor No." := ReturnShipmentHeader."Pay-to Vendor No.";
            OnAfterInitFromPurchase(Rec, ReturnShipmentHeader);
            Insert(true);
        end
    end;


    procedure InitRecord(DocumentType: Option; DocumentNo: Code[20])
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        ReturnShipmentHeader: Record "Return Shipment Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitRecord(Rec, DocumentType, DocumentNo, IsHandled);
        if IsHandled then
            exit;

        case "Supply Document Type".FromInteger(DocumentType) of
            "Document Type"::"Sales Shipment":
                begin
                    SalesShipmentHeader.Get(DocumentNo);
                    InitFromSales(SalesShipmentHeader);
                end;
            "Document Type"::"Return Shipment":
                begin
                    ReturnShipmentHeader.Get(DocumentNo);
                    InitFromPurchase(ReturnShipmentHeader);
                end;
        end
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitFromSales(var CertificateOfSupply: Record "Certificate of Supply"; SalesShipmentHeader: Record "Sales Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitFromPurchase(var CertificateOfSupply: Record "Certificate of Supply"; ReturnShipmentHeader: Record "Return Shipment Header")
    begin
    end;


    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitRecord(var CertificateOfSupply: Record "Certificate of Supply"; DocumentType: Option; DocumentNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrint(var CertificateOfSupply: Record "Certificate of Supply")
    begin
    end;
}
