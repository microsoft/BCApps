// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Navigate;

using Microsoft.Purchases.Archive;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Sales.Archive;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;

page 6560 "Document Line Tracking"
{
    Caption = 'Document Line Tracking';
    DataCaptionExpression = DocumentCaption;
    Editable = false;
    PageType = List;
    SourceTable = "Document Entry";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(SourceDocLineNo; SourceDocLineNo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Line No.';
                    Editable = false;
                    ToolTip = 'Specifies the number of the tracked line.';
                }
                field(DocLineType; DocLineType)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Type';
                    Editable = false;
                    ToolTip = 'Specifies the type of the tracked document. ';
                }
                field(DocLineNo; DocLineNo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'No.';
                    Editable = false;
                    ToolTip = 'Specifies the number of the tracked document line.';
                }
                field(DocLineDescription; DocLineDescription)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Description';
                    Editable = false;
                    ToolTip = 'Specifies a description of the record.';
                }
                field(DocLineQuantity; DocLineQuantity)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Quantity';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the quantity on the tracked document line.';
                }
                field(DocLineUnit; DocLineUnit)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Unit of Measure Code';
                    Editable = false;
                    ToolTip = 'Specifies the unit of measure that the item is shown in.';
                }
            }
            repeater(Control5)
            {
                Editable = false;
                ShowCaption = false;
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number that is assigned to the entry.';
                    Visible = false;
                }
                field("Table ID"; Rec."Table ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the table that stores the tracked document line.';
                    Visible = false;
                }
                field("Table Name"; Rec."Table Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the table that stores the tracked document line.';
                }
                field("No. of Records"; Rec."No. of Records")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = true;
                    ToolTip = 'Specifies how many records contain the tracked document line.';

                    trigger OnDrillDown()
                    begin
                        ShowRecords();
                    end;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Show)
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Show';
                Enabled = ShowEnable;
                Image = View;
                ToolTip = 'Show related document.';

                trigger OnAction()
                begin
                    ShowRecords();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Show_Promoted; Show)
                {
                }
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    begin
        TempDocumentEntry := Rec;
        if not TempDocumentEntry.Find(Which) then
            exit(false);
        Rec := TempDocumentEntry;
        exit(true);
    end;

    trigger OnInit()
    begin
        ShowEnable := true;
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    var
        CurrentSteps: Integer;
    begin
        TempDocumentEntry := Rec;
        CurrentSteps := TempDocumentEntry.Next(Steps);
        if CurrentSteps <> 0 then
            Rec := TempDocumentEntry;
        exit(CurrentSteps);
    end;

    trigger OnOpenPage()
    begin
        if (SourceDocNo = '') or (SourceDocLineNo = 0) then
            exit;

        FindRecords(true);
    end;

    protected var
        TempDocumentEntry: Record "Document Entry" temporary;

    var
        SalesLine: Record "Sales Line";
        SalesShptLine: Record "Sales Shipment Line";
        SalesInvLine: Record "Sales Invoice Line";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        SalesLineArchive: Record "Sales Line Archive";
        PurchLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchInvLine: Record "Purch. Inv. Line";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        PurchLineArchive: Record "Purchase Line Archive";
        ReturnReceiptLine: Record "Return Receipt Line";
        ReturnShipmentLine: Record "Return Shipment Line";
        BlanketSalesOrderLine: Record "Sales Line";
        BlanketSalesOrderLineArchive: Record "Sales Line Archive";
        BlanketPurchOrderLine: Record "Purchase Line";
        BlanketPurchOrderLineArchive: Record "Purchase Line Archive";
        Window: Dialog;
        SourceDocType: Enum "Document Line Source Type";
        SourceDocNo: Code[20];
        SourceDocBlanketOrderNo: Code[20];
        SourceDocOrderNo: Code[20];
        SourceDocLineNo: Integer;
        SourceDocBlanketOrderLineNo: Integer;
        SourceDocOrderLineNo: Integer;
        DocumentCaption: Text[60];
        DocNo: Code[20];
        DocLineNo: Code[20];
        DocType: Text[30];
        DocArchive: Text[30];
        DocLineType: Text[30];
        DocLineDescription: Text[100];
        DocLineUnit: Code[10];
        DocLineQuantity: Decimal;
        DocExists: Boolean;
        ShowEnable: Boolean;
        UseBlanketOrderNo: Boolean;
        UseOrderNo: Boolean;

        CountingRecordsMsg: Label 'Counting records...';
        SalesOrderLinesTxt: Label 'Sales Order Lines';
        ArchivedSalesOrderLinesTxt: Label 'Archived Sales Order Lines';
        PostedSalesShipmentLinesTxt: Label 'Posted Sales Shipment Lines';
        PostedSalesInvoiceLinesTxt: Label 'Posted Sales Invoice Lines';
        PurchaseOrderLinesTxt: Label 'Purchase Order Lines';
        ArchivedPurchaseOrderLinesTxt: Label 'Archived Purchase Order Lines';
        PostedPurchaseReceiptLinesTxt: Label 'Posted Purchase Receipt Lines';
        PostedPurchaseInvoiceLinesTxt: Label 'Posted Purchase Invoice Lines';
        NoSalesOrderMsg: Label 'There is no Sales Order / Archived Sales Order with this Document Number and Document Line No.';
        NoPurchaseOrderMsg: Label 'There is no Purchase Order / Archived Purchase Order with this Document Number and Document Line No.';
        ArchivedTxt: Label 'Archived';
        BlanketSalesOrderLinesTxt: Label 'Blanket Sales Order Lines';
        ArchivedBlanketSalesOrderLinesTxt: Label 'Archived Blanket Sales Order Lines';
        BlanketPurchaseOrderLinesTxt: Label 'Blanket Purchase Order Lines';
        ArchivedBlanketPurchaseOrderLinesTxt: Label 'Archived Blanket Purchase Order Lines';
        SalesReturnOrderLinesTxt: Label 'Sales Return Order Lines';
        ArchivedSalesReturnOrderLinesTxt: Label 'Archived Sales Return Order Lines';
        PostedReturnReceiptLinesTxt: Label 'Posted Return Receipt Lines';
        PostedSalesCreditMemoLinesTxt: Label 'Posted Sales Credit Memo Lines';
        PurchaseReturnOrderLinesTxt: Label 'Purchase Return Order Lines';
        ArchivedPurchaseReturnOrderLinesTxt: Label 'Archived Purchase Return Order Lines';
        PostedReturnShipmentLinesTxt: Label 'Posted Return Shipment Lines';
        PostedPurchaseCreditMemoLinesTxt: Label 'Posted Purchase Credit Memo Lines';


    procedure SetSourceDoc(NewSourceDocType: Enum "Document Line Source Type"; NewDocNo: Code[20]; NewSourceDocLineNo: Integer; NewDocBlanketOrderNo: Code[20]; NewDocBlanketOrderLineNo: Integer; NewDocOrderNo: Code[20]; NewDocOrderLineNo: Integer)
    begin
        SourceDocType := NewSourceDocType;
        SourceDocNo := NewDocNo;
        SourceDocLineNo := NewSourceDocLineNo;
        SourceDocBlanketOrderNo := NewDocBlanketOrderNo;
        SourceDocBlanketOrderLineNo := NewDocBlanketOrderLineNo;
        SourceDocOrderNo := NewDocOrderNo;
        SourceDocOrderLineNo := NewDocOrderLineNo;

        UseBlanketOrderNo := ((SourceDocBlanketOrderNo <> '') and (SourceDocBlanketOrderLineNo <> 0));
        UseOrderNo := ((SourceDocOrderNo <> '') and (SourceDocOrderLineNo <> 0));

        Rec := Rec;
    end;

    protected procedure FindRecords(ClearSourceTable: Boolean)
    begin
        Window.Open(CountingRecordsMsg);
        if ClearSourceTable then
            TempDocumentEntry.DeleteAll();
        TempDocumentEntry."Entry No." := 0;

        case SourceDocType of
            SourceDocType::"Sales Order":
                FindRecordsForSalesOrder();
            SourceDocType::"Purchase Order":
                FindRecordsForPurchOrder();
            SourceDocType::"Blanket Sales Order":
                FindRecordsForBlanketSalesOrder();
            SourceDocType::"Blanket Purchase Order":
                FindRecordsForBlanketPurchOrder();
            SourceDocType::"Sales Shipment":
                FindRecordsForSalesShipment();
            SourceDocType::"Purchase Receipt":
                FindRecordsForPurchaseReceipt();
            SourceDocType::"Sales Invoice":
                FindRecordsForSalesInvoice();
            SourceDocType::"Purchase Invoice":
                FindRecordsForPurchInvoice();
            SourceDocType::"Sales Return Order":
                FindRecordsForSalesReturnOrder();
            SourceDocType::"Purchase Return Order":
                FindRecordsForPurchReturnOrder();
            SourceDocType::"Sales Credit Memo":
                FindRecordsForSalesCreditMemo();
            SourceDocType::"Purchase Credit Memo":
                FindRecordsForPurchCreditMemo();
            SourceDocType::"Return Receipt":
                FindRecordsForReturnReceipt();
            SourceDocType::"Return Shipment":
                FindRecordsForReturnShipment();
            else
                OnFindRecordsAfterCase(
                    TempDocumentEntry, SourceDocType, SourceDocNo, SourceDocLineNo, SourceDocBlanketOrderNo, SourceDocBlanketOrderLineNo);
        end;

        GetDocumentData();

        if DocNo = '' then
            case SourceDocType of
                SourceDocType::"Sales Order":
                    Message(NoSalesOrderMsg);
                SourceDocType::"Purchase Order":
                    Message(NoPurchaseOrderMsg);
            end;

        DocExists := TempDocumentEntry.Find('-');
        ShowEnable := DocExists;
        CurrPage.Update(false);
        DocExists := TempDocumentEntry.Find('-');
        if DocExists then;
        Window.Close();
    end;

    local procedure FindRecordsForSalesOrder()
    begin
        if UseBlanketOrderNo then
            FindRecordsRelatedToSalesBlanketOrder(SourceDocBlanketOrderNo, SourceDocBlanketOrderLineNo);

        FindRecordsRelatedToSalesOrder(SourceDocNo, SourceDocLineNo);
    end;

    local procedure FindRecordsForPurchOrder()
    begin
        if UseBlanketOrderNo then
            FindRecordsRelatedToPurchaseBlanketOrder(SourceDocBlanketOrderNo, SourceDocBlanketOrderLineNo);

        FindRecordsRelatedToPurchaseOrder(SourceDocNo, SourceDocLineNo);
    end;

    local procedure FindRecordsForBlanketSalesOrder()
    begin
        FindRecordsRelatedToSalesBlanketOrder(SourceDocNo, SourceDocLineNo);

        FindSalesOrderLinesByBlanketOrder(SourceDocNo, SourceDocLineNo);
        FindSalesOrderLinesArchiveByBlanketOrder(SourceDocNo, SourceDocLineNo);
        FindSalesShipmentLinesByBlanketOrder(SourceDocNo, SourceDocLineNo);
        FindSalesInvoiceLinesByBlanketOrder(SourceDocNo, SourceDocLineNo);
    end;

    local procedure FindRecordsForBlanketPurchOrder()
    begin
        FindRecordsRelatedToPurchaseBlanketOrder(SourceDocNo, SourceDocLineNo);

        FindPurchOrderLinesByBlanketOrder(SourceDocNo, SourceDocLineNo);
        FindPurchOrderLinesArchiveByBlanketOrder(SourceDocNo, SourceDocLineNo);
        FindPurchReceiptLinesByBlanketOrder(SourceDocNo, SourceDocLineNo);
        FindPurchInvoiceLinesByBlanketOrder(SourceDocNo, SourceDocLineNo);
    end;

    local procedure FindRecordsForSalesShipment()
    begin
        if UseBlanketOrderNo then
            FindRecordsRelatedToSalesBlanketOrder(SourceDocBlanketOrderNo, SourceDocBlanketOrderLineNo);

        if UseOrderNo then
            FindRecordsRelatedToSalesOrder(SourceDocOrderNo, SourceDocOrderLineNo);
    end;

    local procedure FindRecordsForPurchaseReceipt()
    begin
        if UseBlanketOrderNo then
            FindRecordsRelatedToPurchaseBlanketOrder(SourceDocBlanketOrderNo, SourceDocBlanketOrderLineNo);

        if UseOrderNo then
            FindRecordsRelatedToPurchaseOrder(SourceDocOrderNo, SourceDocOrderLineNo);
    end;

    local procedure FindRecordsForSalesInvoice()
    begin
        if UseBlanketOrderNo then
            FindRecordsRelatedToSalesBlanketOrder(SourceDocBlanketOrderNo, SourceDocBlanketOrderLineNo);

        if UseOrderNo then
            FindRecordsRelatedToSalesOrder(SourceDocOrderNo, SourceDocOrderLineNo);
    end;

    local procedure FindRecordsForPurchInvoice()
    begin
        if UseBlanketOrderNo then
            FindRecordsRelatedToPurchaseBlanketOrder(SourceDocBlanketOrderNo, SourceDocBlanketOrderLineNo);

        if UseOrderNo then
            FindRecordsRelatedToPurchaseOrder(SourceDocOrderNo, SourceDocOrderLineNo);
    end;

    local procedure FindRecordsForSalesReturnOrder()
    begin
        FindRecordsRelatedToSalesReturnOrder(SourceDocNo, SourceDocLineNo);
    end;

    local procedure FindRecordsForPurchReturnOrder()
    begin
        FindRecordsRelatedToPurchaseReturn(SourceDocNo, SourceDocLineNo);
    end;

    local procedure FindRecordsForSalesCreditMemo()
    begin
        if UseOrderNo then
            FindRecordsRelatedToSalesReturnOrder(SourceDocOrderNo, SourceDocOrderLineNo);
    end;

    local procedure FindRecordsForPurchCreditMemo()
    begin
        if UseOrderNo then
            FindRecordsRelatedToPurchaseReturn(SourceDocOrderNo, SourceDocOrderLineNo);
    end;

    local procedure FindRecordsForReturnReceipt()
    begin
        if UseBlanketOrderNo then
            FindRecordsRelatedToSalesReturnOrder(SourceDocBlanketOrderNo, SourceDocBlanketOrderLineNo);
    end;

    local procedure FindRecordsForReturnShipment()
    begin
        if UseBlanketOrderNo then
            FindRecordsRelatedToPurchaseReturn(SourceDocBlanketOrderNo, SourceDocBlanketOrderLineNo);
    end;

    local procedure FindRecordsRelatedToPurchaseBlanketOrder(DocNo2: Code[20]; DocLineNo2: Integer)
    begin
        FindPurchBlanketOrderLines(DocNo2, DocLineNo2);
        FindPurchBlanketOrderLinesArchive(DocNo2, DocLineNo2);
    end;

    local procedure FindRecordsRelatedToPurchaseOrder(DocNo2: Code[20]; DocLineNo2: Integer)
    begin
        FindPurchOrderLines(DocNo2, DocLineNo2);
        FindPurchOrderLinesArchive(DocNo2, DocLineNo2);
        FindPurchReceiptLinesByOrder(DocNo2, DocLineNo2);
        FindPurchInvoiceLinesByOrder(DocNo2, DocLineNo2);

        OnAfterFindRecordsRelatedToPurchaseOrder(DocNo2, DocLineNo2, TempDocumentEntry);
    end;

    local procedure FindRecordsRelatedToPurchaseReturn(DocNo2: Code[20]; DocLineNo2: Integer)
    begin
        FindPurchReturnOrderLines(DocNo2, DocLineNo2);
        FindPurchReturnOrderLinesArchive(DocNo2, DocLineNo2);
        FindReturnShipmentLines(DocNo2, DocLineNo2);
        FindPurchCreditMemoLines(DocNo2, DocLineNo2);

        OnAfterFindRecordsRelatedToPurchaseReturnOrder(DocNo2, DocLineNo2, TempDocumentEntry);
    end;

    local procedure FindRecordsRelatedToSalesBlanketOrder(DocNo2: Code[20]; DocLineNo2: Integer)
    begin
        FindSalesBlanketOrderLines(DocNo2, DocLineNo2);
        FindSalesBlanketOrderLinesArchive(DocNo2, DocLineNo2);
    end;

    local procedure FindRecordsRelatedToSalesOrder(DocNo2: Code[20]; DocLineNo2: Integer)
    begin
        FindSalesOrderLines(DocNo2, DocLineNo2);
        FindSalesOrderLinesArchive(DocNo2, DocLineNo2);
        FindSalesShipmentLinesByOrder(DocNo2, DocLineNo2);
        FindSalesInvoiceLinesByOrder(DocNo2, DocLineNo2);

        OnAfterFindRecordsRelatedToSalesOrder(DocNo2, DocLineNo2, TempDocumentEntry);
    end;

    local procedure FindRecordsRelatedToSalesReturnOrder(DocNo2: Code[20]; DocLineNo2: Integer)
    begin
        FindSalesReturnOrderLines(DocNo2, DocLineNo2);
        FindSalesReturnOrderLinesArchive(DocNo2, DocLineNo2);
        FindReturnReceiptLines(DocNo2, DocLineNo2);
        FindSalesCreditMemoLines(DocNo2, DocLineNo2);

        OnAfterFindRecordsRelatedToSalesReturnOrder(DocNo2, DocLineNo2, TempDocumentEntry);
    end;

    local procedure InsertIntoDocEntry(DocTableID: Integer; DocType2: Enum "Document Entry Document Type"; DocTableName: Text[50]; DocNoOfRecords: Integer)
    begin
        if DocNoOfRecords = 0 then
            exit;

        TempDocumentEntry.Init();
        TempDocumentEntry."Entry No." := TempDocumentEntry."Entry No." + 1;
        TempDocumentEntry."Table ID" := DocTableID;
        TempDocumentEntry."Document Type" := DocType2;
        TempDocumentEntry."Table Name" := CopyStr(DocTableName, 1, MaxStrLen(TempDocumentEntry."Table Name"));
        TempDocumentEntry."No. of Records" := DocNoOfRecords;
        TempDocumentEntry.Insert();
    end;

    local procedure GetDocumentData()
    begin
        DocType := '';
        DocNo := '';
        DocArchive := '';
        DocLineType := '';
        DocLineNo := '';
        DocLineDescription := '';
        DocLineQuantity := 0;
        DocLineUnit := '';

        AssignLineFieldFromDocument();

        DocumentCaption := CopyStr(DelChr(DocArchive + ' ' + DocType + ' ' + DocNo, '<', ' '), 1, MaxStrLen(DocumentCaption));
    end;

    local procedure ShowRecords()
    begin
        TempDocumentEntry := Rec;
        if TempDocumentEntry.Find() then
            Rec := TempDocumentEntry;

        case TempDocumentEntry."Table ID" of
            DATABASE::"Sales Line":
                if TempDocumentEntry."Document Type" = TempDocumentEntry."Document Type"::"Blanket Order" then
                    PAGE.RunModal(PAGE::"Sales Lines", BlanketSalesOrderLine)
                else
                    PAGE.RunModal(PAGE::"Sales Lines", SalesLine);
            DATABASE::"Sales Shipment Line":
                PAGE.RunModal(0, SalesShptLine);
            DATABASE::"Sales Invoice Line":
                PAGE.RunModal(0, SalesInvLine);
            DATABASE::"Sales Cr.Memo Line":
                PAGE.RunModal(0, SalesCrMemoLine);
            DATABASE::"Sales Line Archive":
                if TempDocumentEntry."Document Type" = TempDocumentEntry."Document Type"::"Blanket Order" then
                    PAGE.RunModal(PAGE::"Sales Line Archive List", BlanketSalesOrderLineArchive)
                else
                    PAGE.RunModal(PAGE::"Sales Line Archive List", SalesLineArchive);
            DATABASE::"Return Receipt Line":
                PAGE.RunModal(0, ReturnReceiptLine);
            DATABASE::"Purchase Line":
                if TempDocumentEntry."Document Type" = TempDocumentEntry."Document Type"::"Blanket Order" then
                    PAGE.RunModal(PAGE::"Purchase Lines", BlanketPurchOrderLine)
                else
                    PAGE.RunModal(PAGE::"Purchase Lines", PurchLine);
            DATABASE::"Purch. Rcpt. Line":
                PAGE.RunModal(0, PurchRcptLine);
            DATABASE::"Purch. Inv. Line":
                PAGE.RunModal(0, PurchInvLine);
            DATABASE::"Purch. Cr. Memo Line":
                PAGE.RunModal(0, PurchCrMemoLine);
            DATABASE::"Purchase Line Archive":
                if TempDocumentEntry."Document Type" = TempDocumentEntry."Document Type"::"Blanket Order" then
                    PAGE.RunModal(PAGE::"Purchase Line Archive List", BlanketPurchOrderLineArchive)
                else
                    PAGE.RunModal(PAGE::"Purchase Line Archive List", PurchLineArchive);
            DATABASE::"Return Shipment Line":
                PAGE.RunModal(0, ReturnShipmentLine);
            else
                OnShowRecordsOnElseCase(TempDocumentEntry);
        end;
    end;

    local procedure AssignLineFieldFromDocument();
    begin
        case SourceDocType of
            SourceDocType::"Sales Order":
                begin
                    if FilteredRecordExist(SalesLine.GetFilters(), SalesLine.IsEmpty()) then begin
                        SalesLine.FindFirst();
                        AssignLineFields(
                            Format(SalesLine."Document Type"), SalesLine."Document No.", '', Format(SalesLine.Type),
                            SalesLine."No.", SalesLine.Description, SalesLine.Quantity, SalesLine."Unit of Measure Code");
                        exit;
                    end;
                    if FilteredRecordExist(SalesLineArchive.GetFilters(), SalesLineArchive.IsEmpty()) then begin
                        SalesLineArchive.FindFirst();
                        AssignLineFields(
                            Format(SalesLineArchive."Document Type"), SalesLineArchive."Document No.", ArchivedTxt, Format(SalesLineArchive.Type),
                            SalesLineArchive."No.", SalesLineArchive.Description, SalesLineArchive.Quantity, SalesLineArchive."Unit of Measure Code");
                    end;
                end;
            SourceDocType::"Blanket Sales Order":
                begin
                    if FilteredRecordExist(BlanketSalesOrderLine.GetFilters(), BlanketSalesOrderLine.IsEmpty()) then begin
                        BlanketSalesOrderLine.FindFirst();
                        AssignLineFields(
                            Format(BlanketSalesOrderLine."Document Type"), BlanketSalesOrderLine."Document No.", '', Format(BlanketSalesOrderLine.Type),
                            BlanketSalesOrderLine."No.", BlanketSalesOrderLine.Description, BlanketSalesOrderLine.Quantity, BlanketSalesOrderLine."Unit of Measure Code");
                        exit;
                    end;
                    if FilteredRecordExist(BlanketSalesOrderLineArchive.GetFilters(), BlanketSalesOrderLineArchive.IsEmpty()) then begin
                        BlanketSalesOrderLineArchive.FindFirst();
                        AssignLineFields(
                            Format(BlanketSalesOrderLineArchive."Document Type"), BlanketSalesOrderLineArchive."Document No.", ArchivedTxt, Format(BlanketSalesOrderLineArchive.Type),
                            BlanketSalesOrderLineArchive."No.", BlanketSalesOrderLineArchive.Description, BlanketSalesOrderLineArchive.Quantity, BlanketSalesOrderLineArchive."Unit of Measure Code");
                    end;
                end;
            SourceDocType::"Purchase Order", SourceDocType::"Purchase Return Order":
                begin
                    if FilteredRecordExist(PurchLine.GetFilters(), PurchLine.IsEmpty()) then begin
                        PurchLine.FindFirst();
                        AssignLineFields(
                            Format(PurchLine."Document Type"), PurchLine."Document No.", '', Format(PurchLine.Type),
                            PurchLine."No.", PurchLine.Description, PurchLine.Quantity, PurchLine."Unit of Measure Code");
                        exit;
                    end;
                    if FilteredRecordExist(PurchLineArchive.GetFilters(), PurchLineArchive.IsEmpty()) then begin
                        PurchLineArchive.FindFirst();
                        AssignLineFields(
                            Format(PurchLineArchive."Document Type"), PurchLineArchive."Document No.", ArchivedTxt, Format(PurchLineArchive.Type),
                            PurchLineArchive."No.", PurchLineArchive.Description, PurchLineArchive.Quantity, PurchLineArchive."Unit of Measure Code");
                    end;
                end;
            SourceDocType::"Blanket Purchase Order":
                begin
                    if FilteredRecordExist(BlanketPurchOrderLine.GetFilters(), BlanketPurchOrderLine.IsEmpty()) then begin
                        BlanketPurchOrderLine.FindFirst();
                        AssignLineFields(
                            Format(BlanketPurchOrderLine."Document Type"), BlanketPurchOrderLine."Document No.", '', Format(BlanketPurchOrderLine.Type),
                            BlanketPurchOrderLine."No.", BlanketPurchOrderLine.Description, BlanketPurchOrderLine.Quantity, BlanketPurchOrderLine."Unit of Measure Code");
                        exit;
                    end;
                    if FilteredRecordExist(BlanketPurchOrderLineArchive.GetFilters(), BlanketPurchOrderLineArchive.IsEmpty()) then begin
                        BlanketPurchOrderLineArchive.FindFirst();
                        AssignLineFields(
                            Format(BlanketPurchOrderLineArchive."Document Type"), BlanketPurchOrderLineArchive."Document No.", ArchivedTxt, Format(BlanketPurchOrderLineArchive.Type),
                            BlanketPurchOrderLineArchive."No.", BlanketPurchOrderLineArchive.Description, BlanketPurchOrderLineArchive.Quantity, BlanketPurchOrderLineArchive."Unit of Measure Code");
                    end;
                end;
            SourceDocType::"Sales Shipment":
                if FilteredRecordExist(SalesShptLine.GetFilters(), SalesShptLine.IsEmpty()) then begin
                    SalesShptLine.FindFirst();
                    AssignLineFields(
                        SalesShptLine.TableCaption(), SalesShptLine."Document No.", '', Format(SalesShptLine.Type),
                        SalesShptLine."No.", SalesShptLine.Description, SalesShptLine.Quantity, SalesShptLine."Unit of Measure Code");
                end;
            SourceDocType::"Purchase Receipt":
                if FilteredRecordExist(PurchRcptLine.GetFilters(), PurchRcptLine.IsEmpty()) then begin
                    PurchRcptLine.FindFirst();
                    AssignLineFields(
                        PurchRcptLine.TableCaption(), PurchRcptLine."Document No.", '', Format(PurchRcptLine.Type),
                        PurchRcptLine."No.", PurchRcptLine.Description, PurchRcptLine.Quantity, PurchRcptLine."Unit of Measure Code");
                end;
            SourceDocType::"Sales Invoice":
                if FilteredRecordExist(SalesInvLine.GetFilters(), SalesInvLine.IsEmpty()) then begin
                    SalesInvLine.FindFirst();
                    AssignLineFields(
                        SalesInvLine.TableCaption(), SalesInvLine."Document No.", '', Format(SalesInvLine.Type),
                        SalesInvLine."No.", SalesInvLine.Description, SalesInvLine.Quantity, SalesInvLine."Unit of Measure Code");
                end;
            SourceDocType::"Purchase Invoice":
                if FilteredRecordExist(PurchInvLine.GetFilters(), PurchInvLine.IsEmpty()) then begin
                    PurchInvLine.FindFirst();
                    AssignLineFields(
                        PurchInvLine.TableCaption(), PurchInvLine."Document No.", '', Format(PurchInvLine.Type),
                        PurchInvLine."No.", PurchInvLine.Description, PurchInvLine.Quantity, PurchInvLine."Unit of Measure Code");
                end;
            SourceDocType::"Return Shipment":
                if FilteredRecordExist(ReturnShipmentLine.GetFilters(), ReturnShipmentLine.IsEmpty()) then begin
                    ReturnShipmentLine.FindFirst();
                    AssignLineFields(
                        ReturnShipmentLine.TableCaption(), ReturnShipmentLine."Document No.", '', Format(ReturnShipmentLine.Type),
                        ReturnShipmentLine."No.", ReturnShipmentLine.Description, ReturnShipmentLine.Quantity, ReturnShipmentLine."Unit of Measure Code");
                end;
            SourceDocType::"Purchase Credit Memo":
                if FilteredRecordExist(PurchCrMemoLine.GetFilters(), PurchCrMemoLine.IsEmpty()) then begin
                    PurchCrMemoLine.FindFirst();
                    AssignLineFields(PurchCrMemoLine.TableCaption(), PurchCrMemoLine."Document No.", '', Format(PurchCrMemoLine.Type),
                    PurchCrMemoLine."No.", PurchCrMemoLine.Description, PurchCrMemoLine.Quantity, PurchCrMemoLine."Unit of Measure Code");
                end;
            SourceDocType::"Sales Return Order":
                if FilteredRecordExist(SalesLine.GetFilters(), SalesLine.IsEmpty()) then begin
                    SalesLine.FindFirst();
                    AssignLineFields(
                        SalesLine.TableCaption(), SalesLine."Document No.", '', Format(SalesLine.Type),
                        SalesLine."No.", SalesLine.Description, SalesLine.Quantity, SalesLine."Unit of Measure Code");
                end;
            SourceDocType::"Return Receipt":
                if FilteredRecordExist(ReturnReceiptLine.GetFilters(), ReturnReceiptLine.IsEmpty()) then begin
                    ReturnReceiptLine.FindFirst();
                    AssignLineFields(
                        ReturnReceiptLine.TableCaption(), ReturnReceiptLine."Document No.", '', Format(ReturnReceiptLine.Type),
                        ReturnReceiptLine."No.", ReturnReceiptLine.Description, ReturnReceiptLine.Quantity, ReturnReceiptLine."Unit of Measure Code");
                end;
            SourceDocType::"Sales Credit Memo":
                if FilteredRecordExist(SalesCrMemoLine.GetFilters(), SalesCrMemoLine.IsEmpty()) then begin
                    SalesCrMemoLine.FindFirst();
                    AssignLineFields(
                        SalesCrMemoLine.TableCaption(), SalesCrMemoLine."Document No.", '', Format(SalesCrMemoLine.Type),
                        SalesCrMemoLine."No.", SalesCrMemoLine.Description, SalesCrMemoLine.Quantity, SalesCrMemoLine."Unit of Measure Code");
                end;
            else
                OnAssignLineFieldFromDocumentAfterCase(DocType, DocNo, DocArchive, DocLineType, DocLineNo, DocLineDescription, DocLineQuantity, DocLineUnit, SourceDocType);
        end;
    end;

    local procedure AssignLineFields(NewDocType: Text; NewDocNo: Code[20]; NewDocArchive: Text[30]; NewDocLineType: Text[30]; NewDocLineItemNo: Code[20]; NewDocLineDescription: Text[100]; NewDocLineQuantity: Decimal; NewDocLineUnit: Code[10])
    begin
        DocType := CopyStr(NewDocType, 1, MaxStrLen(DocType));
        DocNo := NewDocNo;
        DocArchive := NewDocArchive;
        DocLineType := NewDocLineType;
        DocLineNo := NewDocLineItemNo;
        DocLineDescription := NewDocLineDescription;
        DocLineQuantity := NewDocLineQuantity;
        DocLineUnit := NewDocLineUnit;
    end;

    local procedure FindPurchCreditMemoLines(OrderNo: Code[20]; OrderLineNo: Integer)
    begin
        if PurchCrMemoLine.ReadPermission then begin
            PurchCrMemoLine.Reset();
            PurchCrMemoLine.SetRange("Order No.", OrderNo);
            PurchCrMemoLine.SetRange("Order Line No.", OrderLineNo);
            InsertIntoDocEntry(
                DATABASE::"Purch. Cr. Memo Line", Enum::"Document Entry Document Type"::"Credit Memo", PostedPurchaseCreditMemoLinesTxt, PurchCrMemoLine.Count);
        end;
    end;

    local procedure FindPurchOrderLines(DocNo2: Code[20]; DocLineNo2: Integer)
    begin
        if PurchLine.ReadPermission then begin
            PurchLine.Reset();
            PurchLine.SetRange("Document Type", PurchLine."Document Type"::Order);
            PurchLine.SetRange("Document No.", DocNo2);
            PurchLine.SetRange("Line No.", DocLineNo2);
            InsertIntoDocEntry(
                DATABASE::"Purchase Line", Enum::"Document Entry Document Type"::Order,
                PurchaseOrderLinesTxt, PurchLine.Count);
        end;
    end;

    local procedure FindPurchOrderLinesByBlanketOrder(BlanketOrderNo: Code[20]; BlanketOrderLineNo: Integer)
    begin
        if PurchLine.ReadPermission then begin
            PurchLine.Reset();
            PurchLine.SetRange("Document Type", PurchLine."Document Type"::Order);
            PurchLine.SetRange("Blanket Order No.", BlanketOrderNo);
            PurchLine.SetRange("Blanket Order Line No.", BlanketOrderLineNo);
            InsertIntoDocEntry(
                DATABASE::"Purchase Line", Enum::"Document Entry Document Type"::Order,
                PurchaseOrderLinesTxt, PurchLine.Count);
        end;
    end;

    local procedure FindPurchBlanketOrderLines(DocNo2: Code[20]; DocLineNo2: Integer)
    begin
        if BlanketPurchOrderLine.ReadPermission then begin
            BlanketPurchOrderLine.Reset();
            BlanketPurchOrderLine.SetRange("Document Type", BlanketPurchOrderLine."Document Type"::"Blanket Order");
            BlanketPurchOrderLine.SetRange("Document No.", DocNo2);
            BlanketPurchOrderLine.SetRange("Line No.", DocLineNo2);
            InsertIntoDocEntry(
                DATABASE::"Purchase Line", Enum::"Document Entry Document Type"::"Blanket Order",
                BlanketPurchaseOrderLinesTxt, BlanketPurchOrderLine.Count);
        end;
    end;

    local procedure FindPurchReturnOrderLines(DocNo2: Code[20]; DocLineNo2: Integer)
    begin
        if PurchLine.ReadPermission then begin
            PurchLine.Reset();
            PurchLine.SetRange("Document Type", PurchLine."Document Type"::"Return Order");
            PurchLine.SetRange("Document No.", DocNo2);
            PurchLine.SetRange("Line No.", DocLineNo2);
            InsertIntoDocEntry(
                DATABASE::"Purchase Line", Enum::"Document Entry Document Type"::"Return Order",
                PurchaseReturnOrderLinesTxt, PurchLine.Count);
        end;
    end;

    local procedure FindPurchOrderLinesArchive(DocNo2: Code[20]; DocLineNo2: Integer)
    begin
        if PurchLineArchive.ReadPermission then begin
            PurchLineArchive.Reset();
            PurchLineArchive.SetRange("Document Type", PurchLineArchive."Document Type"::Order);
            PurchLineArchive.SetRange("Document No.", DocNo2);
            PurchLineArchive.SetRange("Line No.", DocLineNo2);
            InsertIntoDocEntry(
                DATABASE::"Purchase Line Archive", Enum::"Document Entry Document Type"::Order,
                ArchivedPurchaseOrderLinesTxt, PurchLineArchive.Count);
        end;
    end;

    local procedure FindPurchBlanketOrderLinesArchive(DocNo2: Code[20]; DocLineNo2: Integer)
    begin
        if BlanketPurchOrderLineArchive.ReadPermission then begin
            BlanketPurchOrderLineArchive.Reset();
            BlanketPurchOrderLineArchive.SetRange("Document Type", BlanketPurchOrderLineArchive."Document Type"::"Blanket Order");
            BlanketPurchOrderLineArchive.SetRange("Document No.", DocNo2);
            BlanketPurchOrderLineArchive.SetRange("Line No.", DocLineNo2);
            InsertIntoDocEntry(
              DATABASE::"Purchase Line Archive", Enum::"Document Entry Document Type"::"Blanket Order",
              ArchivedBlanketPurchaseOrderLinesTxt, BlanketPurchOrderLineArchive.Count);
        end;
    end;

    local procedure FindPurchReturnOrderLinesArchive(DocNo2: Code[20]; DocLineNo2: Integer)
    begin
        if PurchLineArchive.ReadPermission then begin
            PurchLineArchive.Reset();
            PurchLineArchive.SetRange("Document Type", PurchLineArchive."Document Type"::"Return Order");
            PurchLineArchive.SetRange("Document No.", DocNo2);
            PurchLineArchive.SetRange("Line No.", DocLineNo2);
            InsertIntoDocEntry(
                DATABASE::"Purchase Line Archive", Enum::"Document Entry Document Type"::"Return Order",
                ArchivedPurchaseReturnOrderLinesTxt, PurchLineArchive.Count);
        end;
    end;

    local procedure FindPurchOrderLinesArchiveByBlanketOrder(BlanketOrderNo: Code[20]; BlanketOrderLineNo: Integer)
    begin
        if PurchLineArchive.ReadPermission then begin
            PurchLineArchive.Reset();
            PurchLineArchive.SetRange("Document Type", PurchLineArchive."Document Type"::Order);
            PurchLineArchive.SetRange("Blanket Order No.", BlanketOrderNo);
            PurchLineArchive.SetRange("Blanket Order Line No.", BlanketOrderLineNo);
            InsertIntoDocEntry(
                DATABASE::"Purchase Line Archive", Enum::"Document Entry Document Type"::Order,
                ArchivedPurchaseOrderLinesTxt, PurchLineArchive.Count);
        end;
    end;

    local procedure FindPurchReceiptLinesByOrder(OrderNo: Code[20]; OrderLineNo: Integer)
    begin
        if PurchRcptLine.ReadPermission then begin
            PurchRcptLine.Reset();
            PurchRcptLine.SetCurrentKey("Order No.", "Order Line No.");
            PurchRcptLine.SetRange("Order No.", OrderNo);
            PurchRcptLine.SetRange("Order Line No.", OrderLineNo);
            InsertIntoDocEntry(
                DATABASE::"Purch. Rcpt. Line", Enum::"Document Entry Document Type"::" ",
                PostedPurchaseReceiptLinesTxt, PurchRcptLine.Count);
        end;
    end;

    local procedure FindPurchReceiptLinesByBlanketOrder(BlanketOrderNo: Code[20]; BlanketOrderLineNo: Integer)
    begin
        if PurchRcptLine.ReadPermission then begin
            PurchRcptLine.Reset();
            PurchRcptLine.SetRange("Blanket Order No.", BlanketOrderNo);
            PurchRcptLine.SetRange("Blanket Order Line No.", BlanketOrderLineNo);
            InsertIntoDocEntry(
                DATABASE::"Purch. Rcpt. Line", Enum::"Document Entry Document Type"::" ",
                PostedPurchaseReceiptLinesTxt, PurchRcptLine.Count);
        end;
    end;

    local procedure FindPurchInvoiceLinesByOrder(OrderNo: Code[20]; OrderLineNo: Integer)
    begin
        if PurchInvLine.ReadPermission then begin
            PurchInvLine.Reset();
            PurchInvLine.SetRange("Order No.", OrderNo);
            PurchInvLine.SetRange("Order Line No.", OrderLineNo);
            InsertIntoDocEntry(
                DATABASE::"Purch. Inv. Line", Enum::"Document Entry Document Type"::" ",
                PostedPurchaseInvoiceLinesTxt, PurchInvLine.Count);
        end;
    end;

    local procedure FindPurchInvoiceLinesByBlanketOrder(BlanketOrderNo: Code[20]; BlanketOrderLineNo: Integer)
    begin
        if PurchInvLine.ReadPermission then begin
            PurchInvLine.Reset();
            PurchInvLine.SetRange("Blanket Order No.", BlanketOrderNo);
            PurchInvLine.SetRange("Blanket Order Line No.", BlanketOrderLineNo);
            InsertIntoDocEntry(
                DATABASE::"Purch. Inv. Line", Enum::"Document Entry Document Type"::" ",
                PostedPurchaseInvoiceLinesTxt, PurchInvLine.Count);
        end;
    end;

    local procedure FindReturnReceiptLines(ReturnOrderNo: Code[20]; ReturnOrderLineNo: Integer)
    begin
        if ReturnReceiptLine.ReadPermission then begin
            ReturnReceiptLine.Reset();
            ReturnReceiptLine.SetRange("Return Order No.", ReturnOrderNo);
            ReturnReceiptLine.SetRange("Return Order Line No.", ReturnOrderLineNo);
            InsertIntoDocEntry(
                DATABASE::"Return Receipt Line", Enum::"Document Entry Document Type"::"Return Order",
                PostedReturnReceiptLinesTxt, ReturnReceiptLine.Count);
        end;
    end;

    local procedure FindReturnShipmentLines(ReturnOrderNo: Code[20]; ReturnOrderLineNo: Integer)
    begin
        if ReturnShipmentLine.ReadPermission then begin
            ReturnShipmentLine.Reset();
            ReturnShipmentLine.SetRange("Return Order No.", ReturnOrderNo);
            ReturnShipmentLine.SetRange("Return Order Line No.", ReturnOrderLineNo);
            InsertIntoDocEntry(
                DATABASE::"Return Shipment Line", Enum::"Document Entry Document Type"::"Return Order",
                PostedReturnShipmentLinesTxt, ReturnShipmentLine.Count);
        end;
    end;

    local procedure FindSalesCreditMemoLines(OrderNo: Code[20]; OrderLineNo: Integer)
    begin
        if SalesCrMemoLine.ReadPermission then begin
            SalesCrMemoLine.Reset();
            SalesCrMemoLine.SetRange("Order No.", OrderNo);
            SalesCrMemoLine.SetRange("Order Line No.", OrderLineNo);
            InsertIntoDocEntry(
                DATABASE::"Sales Cr.Memo Line", Enum::"Document Entry Document Type"::"Credit Memo",
                PostedSalesCreditMemoLinesTxt, SalesCrMemoLine.Count);
        end;
    end;

    local procedure FindSalesOrderLines(DocNo2: Code[20]; DocLineNo2: Integer)
    begin
        if SalesLine.ReadPermission then begin
            SalesLine.Reset();
            SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
            SalesLine.SetRange("Document No.", DocNo2);
            SalesLine.SetRange("Line No.", DocLineNo2);
            InsertIntoDocEntry(
                DATABASE::"Sales Line", Enum::"Document Entry Document Type"::Order,
                SalesOrderLinesTxt, SalesLine.Count);
        end;
    end;

    local procedure FindSalesOrderLinesByBlanketOrder(BlanketOrderNo: Code[20]; BlanketOrderLineNo: Integer)
    begin
        if SalesLine.ReadPermission then begin
            SalesLine.Reset();
            SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
            SalesLine.SetRange("Blanket Order No.", BlanketOrderNo);
            SalesLine.SetRange("Blanket Order Line No.", BlanketOrderLineNo);
            InsertIntoDocEntry(
                DATABASE::"Sales Line", Enum::"Document Entry Document Type"::Order,
                SalesOrderLinesTxt, SalesLine.Count);
        end;
    end;

    local procedure FindSalesBlanketOrderLines(DocNo2: Code[20]; DocLineNo2: Integer)
    begin
        if BlanketSalesOrderLine.ReadPermission then begin
            BlanketSalesOrderLine.Reset();
            BlanketSalesOrderLine.SetRange("Document Type", BlanketSalesOrderLine."Document Type"::"Blanket Order");
            BlanketSalesOrderLine.SetRange("Document No.", DocNo2);
            BlanketSalesOrderLine.SetRange("Line No.", DocLineNo2);
            InsertIntoDocEntry(
                DATABASE::"Sales Line", Enum::"Document Entry Document Type"::"Blanket Order",
                BlanketSalesOrderLinesTxt, BlanketSalesOrderLine.Count);
        end;
    end;

    local procedure FindSalesReturnOrderLines(DocNo2: Code[20]; DocLineNo2: Integer)
    begin
        if SalesLine.ReadPermission then begin
            SalesLine.Reset();
            SalesLine.SetRange("Document Type", SalesLine."Document Type"::"Return Order");
            SalesLine.SetRange("Document No.", DocNo2);
            SalesLine.SetRange("Line No.", DocLineNo2);
            InsertIntoDocEntry(
                DATABASE::"Sales Line", Enum::"Document Entry Document Type"::"Return Order",
                SalesReturnOrderLinesTxt, SalesLine.Count);
        end;
    end;

    local procedure FindSalesOrderLinesArchive(DocNo2: Code[20]; DocLineNo2: Integer)
    begin
        if SalesLineArchive.ReadPermission then begin
            SalesLineArchive.Reset();
            SalesLineArchive.SetRange("Document Type", SalesLineArchive."Document Type"::Order);
            SalesLineArchive.SetRange("Document No.", DocNo2);
            SalesLineArchive.SetRange("Line No.", DocLineNo2);
            InsertIntoDocEntry(
                DATABASE::"Sales Line Archive", Enum::"Document Entry Document Type"::Order,
                ArchivedSalesOrderLinesTxt, SalesLineArchive.Count);
        end;
    end;

    local procedure FindSalesBlanketOrderLinesArchive(DocNo2: Code[20]; DocLineNo2: Integer)
    begin
        if BlanketSalesOrderLineArchive.ReadPermission then begin
            BlanketSalesOrderLineArchive.Reset();
            BlanketSalesOrderLineArchive.SetRange("Document Type", BlanketSalesOrderLineArchive."Document Type"::"Blanket Order");
            BlanketSalesOrderLineArchive.SetRange("Document No.", DocNo2);
            BlanketSalesOrderLineArchive.SetRange("Line No.", DocLineNo2);
            InsertIntoDocEntry(
                DATABASE::"Sales Line Archive", Enum::"Document Entry Document Type"::"Blanket Order",
                ArchivedBlanketSalesOrderLinesTxt, BlanketSalesOrderLineArchive.Count);
        end;
    end;

    local procedure FindSalesReturnOrderLinesArchive(DocNo2: Code[20]; DocLineNo2: Integer)
    begin
        if SalesLineArchive.ReadPermission then begin
            SalesLineArchive.Reset();
            SalesLineArchive.SetRange("Document Type", SalesLineArchive."Document Type"::"Return Order");
            SalesLineArchive.SetRange("Document No.", DocNo2);
            SalesLineArchive.SetRange("Line No.", DocLineNo2);
            InsertIntoDocEntry(
                DATABASE::"Sales Line Archive", Enum::"Document Entry Document Type"::"Return Order",
                ArchivedSalesReturnOrderLinesTxt, SalesLineArchive.Count);
        end;
    end;

    local procedure FindSalesOrderLinesArchiveByBlanketOrder(BlanketOrderNo: Code[20]; BlanketOrderLineNo: Integer)
    begin
        if SalesLineArchive.ReadPermission then begin
            SalesLineArchive.Reset();
            SalesLineArchive.SetRange("Document Type", SalesLineArchive."Document Type"::Order);
            SalesLineArchive.SetRange("Blanket Order No.", BlanketOrderNo);
            SalesLineArchive.SetRange("Blanket Order Line No.", BlanketOrderLineNo);
            InsertIntoDocEntry(
                DATABASE::"Sales Line Archive", Enum::"Document Entry Document Type"::Order,
                ArchivedSalesOrderLinesTxt, SalesLineArchive.Count);
        end;
    end;

    local procedure FindSalesShipmentLinesByOrder(OrderNo: Code[20]; OrderLineNo: Integer)
    begin
        if SalesShptLine.ReadPermission then begin
            SalesShptLine.Reset();
            SalesShptLine.SetRange("Order No.", OrderNo);
            SalesShptLine.SetRange("Order Line No.", OrderLineNo);
            InsertIntoDocEntry(
                DATABASE::"Sales Shipment Line", Enum::"Document Entry Document Type"::" ",
                PostedSalesShipmentLinesTxt, SalesShptLine.Count);
        end;
    end;

    local procedure FindSalesShipmentLinesByBlanketOrder(BlanketOrderNo: Code[20]; BlanketOrderLineNo: Integer)
    begin
        if SalesShptLine.ReadPermission then begin
            SalesShptLine.Reset();
            SalesShptLine.SetRange("Blanket Order No.", BlanketOrderNo);
            SalesShptLine.SetRange("Blanket Order Line No.", BlanketOrderLineNo);
            InsertIntoDocEntry(
                DATABASE::"Sales Shipment Line", Enum::"Document Entry Document Type"::" ",
                PostedSalesShipmentLinesTxt, SalesShptLine.Count);
        end;
    end;

    local procedure FindSalesInvoiceLinesByOrder(OrderNo: Code[20]; OrderLineNo: Integer)
    begin
        if SalesInvLine.ReadPermission then begin
            SalesInvLine.Reset();
            SalesInvLine.SetRange("Order No.", OrderNo);
            SalesInvLine.SetRange("Order Line No.", OrderLineNo);
            InsertIntoDocEntry(
                DATABASE::"Sales Invoice Line", Enum::"Document Entry Document Type"::" ",
                PostedSalesInvoiceLinesTxt, SalesInvLine.Count);
        end;
    end;

    local procedure FindSalesInvoiceLinesByBlanketOrder(BlanketOrderNo: Code[20]; BlanketOrderLineNo: Integer)
    begin
        if SalesInvLine.ReadPermission then begin
            SalesInvLine.Reset();
            SalesInvLine.SetRange("Blanket Order No.", BlanketOrderNo);
            SalesInvLine.SetRange("Blanket Order Line No.", BlanketOrderLineNo);
            InsertIntoDocEntry(
                DATABASE::"Sales Invoice Line", "Document Entry Document Type"::" ",
                PostedSalesInvoiceLinesTxt, SalesInvLine.Count);
        end;
    end;

    local procedure FilteredRecordExist(Filters: Text; IsEmpty: Boolean): Boolean
    begin
        if Filters = '' then
            exit(false);

        exit(not IsEmpty);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindRecordsAfterCase(var TempDocumentEntry: Record "Document Entry" temporary; SourceDocType: Enum "Document Line Source Type"; SourceDocNo: Code[20]; SourceDocLineNo: Integer; SourceDocBlanketOrderNo: Code[20]; SourceDocBlanketOrderLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAssignLineFieldFromDocumentAfterCase(var DocType: Text[30]; var DocNo: Code[20]; var DocArchive: Text[30]; var DocLineType: Text[30]; var DocLineItemNo: Code[20]; var DocLineDescription: Text[100]; var DocLineQuantity: Decimal; var DocLineUnit: Code[10]; SourceDocType: Enum "Document Line Source Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindRecordsRelatedToSalesOrder(DocNo: Code[20]; DocLineNo: Integer; var TempDocumentEntry: Record "Document Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindRecordsRelatedToPurchaseOrder(DocNo: Code[20]; DocLineNo: Integer; var TempDocumentEntry: Record "Document Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindRecordsRelatedToSalesReturnOrder(DocNo: Code[20]; DocLineNo: Integer; var TempDocumentEntry: Record "Document Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindRecordsRelatedToPurchaseReturnOrder(DocNo: Code[20]; DocLineNo: Integer; var TempDocumentEntry: Record "Document Entry" temporary)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnShowRecordsOnElseCase(var TempDocumentEntry: Record "Document Entry" temporary)
    begin
    end;
}
