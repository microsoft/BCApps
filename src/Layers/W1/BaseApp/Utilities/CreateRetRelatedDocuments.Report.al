// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Document;

report 6697 "Create Ret.-Related Documents"
{
    Caption = 'Create Ret.-Related Documents';
    ProcessingOnly = true;

    dataset
    {
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    group("Return to Vendor")
                    {
                        Caption = 'Return to Vendor';
                        field(VendorNo; VendorNo)
                        {
                            ApplicationArea = SalesReturnOrder;
                            Caption = 'Vendor No.';
                            Lookup = true;
                            ToolTip = 'Specifies the vendor. Enter the vendor number or select the vendor from the Vendor List. To create vendor-related documents, you must specify the vendor number.';

                            trigger OnLookup(var Text: Text): Boolean
                            begin
                                if PAGE.RunModal(0, Vend) = ACTION::LookupOK then
                                    VendorNo := Vend."No.";
                            end;

                            trigger OnValidate()
                            begin
                                if VendorNo <> '' then
                                    Vend.Get(VendorNo);
                            end;
                        }
                        field(CreatePurchRetOrder; CreatePRO)
                        {
                            ApplicationArea = PurchReturnOrder;
                            Caption = 'Create Purch. Ret. Order';
                            ToolTip = 'Specifies if an item needs to be ordered from the vendor.';
                        }
                        field(CreatePurchaseOrder; CreatePO)
                        {
                            ApplicationArea = PurchReturnOrder;
                            Caption = 'Create Purchase Order';
                            ToolTip = 'Specifies if an item needs to be ordered from the vendor.';
                        }
                    }
                    group(Replacement)
                    {
                        Caption = 'Replacement';
                        field(CreateSalesOrder; CreateSO)
                        {
                            ApplicationArea = SalesReturnOrder;
                            Caption = 'Create Sales Order';
                            ToolTip = 'Specifies if a replacement sales order needs to be created.';
                        }
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            CreatePRO := true;
            CreatePO := true;
            CreateSO := true;
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    var
        IsHandled: Boolean;
    begin
        TempRetRelDoc.DeleteAll();

        if CreateSO then begin
            SOSalesHeader."Document Type" := SOSalesHeader."Document Type"::Order;
            Clear(CopyDocMgt);
            CopyDocMgt.SetProperties(true, false, false, true, true, false, false);
            OnPreReportOnBeforeCopySalesDoc(CopyDocMgt, SROSalesHeader, SOSalesHeader);
            CopyDocMgt.CopySalesDoc("Sales Document Type From"::"Return Order", SROSalesHeader."No.", SOSalesHeader);
            OnPreReportOnAfterCopySalesDoc(SROSalesHeader, SOSalesHeader);
            TempRetRelDoc."Entry No." := 3;
            TempRetRelDoc."Document Type" := TempRetRelDoc."Document Type"::"Sales Order";
            TempRetRelDoc."No." := SOSalesHeader."No.";
            TempRetRelDoc.Insert();
        end;

        if CreatePRO then begin
            PROPurchHeader."Document Type" := PROPurchHeader."Document Type"::"Return Order";
            Clear(CopyDocMgt);
            CopyDocMgt.SetProperties(true, false, false, false, true, false, false);
            IsHandled := false;
            OnPreReportOnBeforeCopyPurchReturnDoc(CopyDocMgt, SROSalesHeader, PROPurchHeader, TempRetRelDoc, IsHandled);
            if not IsHandled then begin
                CopyDocMgt.CopyFromSalesToPurchDoc(VendorNo, SROSalesHeader, PROPurchHeader);
                OnPreReportOnAfterCopyPurchReturnDoc(SROSalesHeader, PROPurchHeader);
                TempRetRelDoc."Entry No." := 1;
                TempRetRelDoc."Document Type" := TempRetRelDoc."Document Type"::"Purchase Return Order";
                TempRetRelDoc."No." := PROPurchHeader."No.";
                TempRetRelDoc.Insert();
            end;
        end;

        if CreatePO then begin
            POPurchHeader."Document Type" := POPurchHeader."Document Type"::Order;
            Clear(CopyDocMgt);
            CopyDocMgt.SetProperties(true, false, false, false, true, false, false);
            OnPreReportOnBeforeCopyPurchDoc(CopyDocMgt, SROSalesHeader, POPurchHeader);
            CopyDocMgt.CopyFromSalesToPurchDoc(VendorNo, SROSalesHeader, POPurchHeader);
            OnPreReportOnAfterCopyPurchDoc(SROSalesHeader, POPurchHeader);
            TempRetRelDoc."Entry No." := 2;
            TempRetRelDoc."Document Type" := TempRetRelDoc."Document Type"::"Purchase Order";
            TempRetRelDoc."No." := POPurchHeader."No.";
            TempRetRelDoc.Insert();
        end;
    end;

    var
        Vend: Record Vendor;
        CopyDocMgt: Codeunit "Copy Document Mgt.";

    protected var
        TempRetRelDoc: Record "Returns-Related Document" temporary;
        POPurchHeader: Record "Purchase Header";
        PROPurchHeader: Record "Purchase Header";
        SOSalesHeader: Record "Sales Header";
        SROSalesHeader: Record "Sales Header";
        CreatePRO: Boolean;
        CreatePO: Boolean;
        CreateSO: Boolean;
        VendorNo: Code[20];

    procedure SetSalesHeader(NewSROSalesHeader: Record "Sales Header")
    begin
        SROSalesHeader := NewSROSalesHeader;
    end;

    procedure ShowDocuments()
    begin
        if TempRetRelDoc.FindFirst() then
            Page.Run(Page::"Returns-Related Documents", TempRetRelDoc);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPreReportOnAfterCopySalesDoc(var SROSalesHeader: Record "Sales Header"; var SOSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPreReportOnAfterCopyPurchReturnDoc(var SROSalesHeader: Record "Sales Header"; var PROPurchHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPreReportOnAfterCopyPurchDoc(var SROSalesHeader: Record "Sales Header"; var POPurchHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPreReportOnBeforeCopySalesDoc(var CopyDocumentMgt: Codeunit "Copy Document Mgt."; var SROSalesHeader: Record "Sales Header"; var SOSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPreReportOnBeforeCopyPurchReturnDoc(var CopyDocumentMgt: Codeunit "Copy Document Mgt."; var SROSalesHeader: Record "Sales Header"; var PROPurchHeader: Record "Purchase Header"; var TempReturnsRelatedDocument: Record "Returns-Related Document" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPreReportOnBeforeCopyPurchDoc(var CopyDocumentMgt: Codeunit "Copy Document Mgt."; var SROSalesHeader: Record "Sales Header"; var POPurchHeader: Record "Purchase Header")
    begin
    end;
}

