// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Counting.Document;

using Microsoft.Inventory.Counting.History;

report 5882 "Copy Phys. Invt. Order"
{
    Caption = 'Copy Phys. Invt. Order';
    ProcessingOnly = true;

    dataset
    {
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(DocumentType; DocType)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Document Type';
                        OptionCaption = 'Phys. Invt. Order,Posted Phys. Invt. Order ';
                        ToolTip = 'Specifies the type of the document.';

                        trigger OnValidate()
                        begin
                            DocNo := '';
                            ValidateDocNo();
                        end;
                    }
                    field(DocumentNo; DocNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Document No.';
                        Lookup = true;
                        ToolTip = 'Specifies the number of the document.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            LookupDocNo();
                        end;

                        trigger OnValidate()
                        begin
                            ValidateDocNo();
                        end;
                    }
                    field(CalcQtyExpected; CalcQtyExpected)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Calculate Qty. Expected';
                        ToolTip = 'Specifies if you want the program to calculate and insert the contents of the field quantity expected for new created physical inventory order lines.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        PhysInvtOrderHeader.TestField(Status, PhysInvtOrderHeader.Status::Open);
        if DocNo = '' then
            Error(EnterDocumentNoErr);

        PhysInvtOrderHeader.Find();
        PhysInvtOrderHeader.LockTable();
        PhysInvtOrderLine.LockTable();
        PhysInvtOrderLine.Reset();
        PhysInvtOrderLine.SetRange("Document No.", PhysInvtOrderHeader."No.");
        if PhysInvtOrderLine.FindLast() then
            NextLineNo := PhysInvtOrderLine."Line No." + 10000
        else
            NextLineNo := 10000;

        NoOfInsertedLines := 0;
        NoOfNoInsertedLines := 0;
        case DocType of
            DocType::"Phys. Invt. Order":
                begin
                    FromPhysInvtOrderHeader.Get(DocNo);
                    if FromPhysInvtOrderHeader."No." = PhysInvtOrderHeader."No." then
                        Error(CannotCopyToItSelfErr, PhysInvtOrderHeader."No.");

                    FromPhysInvtOrderLine.Reset();
                    FromPhysInvtOrderLine.SetRange("Document No.", FromPhysInvtOrderHeader."No.");
                    FromPhysInvtOrderLine.ClearMarks();
                    if FromPhysInvtOrderLine.Find('-') then
                        repeat
                            if FromPhysInvtOrderLine."Item No." <> '' then begin
                                NoOfOrderLines := PhysInvtOrderHeader.GetSamePhysInvtOrderLine(FromPhysInvtOrderLine, ErrorText, PhysInvtOrderLine2);
                                OnAfterGetNoOfOrderLinesFromPhysInvtOrder(NoOfOrderLines, FromPhysInvtOrderLine, PhysInvtOrderHeader);
                                if NoOfOrderLines = 0 then begin
                                    InsertNewLine(
                                      FromPhysInvtOrderLine."Item No.", FromPhysInvtOrderLine."Variant Code",
                                      FromPhysInvtOrderLine."Location Code", FromPhysInvtOrderLine."Bin Code");
                                    NoOfInsertedLines := NoOfInsertedLines + 1;
                                end else begin
                                    FromPhysInvtOrderLine.Mark(true);
                                    NoOfNoInsertedLines := NoOfNoInsertedLines + 1;
                                end;
                            end;
                        until FromPhysInvtOrderLine.Next() = 0;
                end;
            DocType::"Posted Phys. Invt. Order":
                begin
                    FromPstdPhysInvtOrderHdr.Get(DocNo);
                    FromPstdPhysInvtOrderLine.Reset();
                    FromPstdPhysInvtOrderLine.SetRange("Document No.", FromPstdPhysInvtOrderHdr."No.");
                    FromPstdPhysInvtOrderLine.ClearMarks();
                    if FromPstdPhysInvtOrderLine.Find('-') then
                        repeat
                            if FromPstdPhysInvtOrderLine."Item No." <> '' then begin
                                NoOfOrderLines :=
                                  PhysInvtOrderHeader.GetSamePhysInvtOrderLine(
                                    FromPstdPhysInvtOrderLine."Item No.", FromPstdPhysInvtOrderLine."Variant Code",
                                    FromPstdPhysInvtOrderLine."Location Code", FromPstdPhysInvtOrderLine."Bin Code",
                                    ErrorText, PhysInvtOrderLine2);
                                OnAfterGetNoOfOrderLinesFromPostedPhysInvtOrder(NoOfOrderLines, FromPstdPhysInvtOrderLine, PhysInvtOrderHeader);
                                if NoOfOrderLines = 0 then begin
                                    InsertNewLine(
                                      FromPstdPhysInvtOrderLine."Item No.", FromPstdPhysInvtOrderLine."Variant Code",
                                      FromPstdPhysInvtOrderLine."Location Code", FromPstdPhysInvtOrderLine."Bin Code");
                                    NoOfInsertedLines := NoOfInsertedLines + 1;
                                end else begin
                                    FromPstdPhysInvtOrderLine.Mark(true);
                                    NoOfNoInsertedLines := NoOfNoInsertedLines + 1;
                                end;
                            end;
                        until FromPstdPhysInvtOrderLine.Next() = 0;
                end;
        end;

        Commit();

        if NoOfNoInsertedLines = 0 then
            Message(
              StrSubstNo(
                LinesInsertedToOrderMsg, NoOfInsertedLines, PhysInvtOrderHeader."No."))
        else
            Message(
              StrSubstNo(LinesInsertedMsg, NoOfInsertedLines, NoOfNoInsertedLines, PhysInvtOrderHeader."No."));
    end;

    var
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        PhysInvtOrderLine2: Record "Phys. Invt. Order Line";
        FromPhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        FromPhysInvtOrderLine: Record "Phys. Invt. Order Line";
        FromPstdPhysInvtOrderHdr: Record "Pstd. Phys. Invt. Order Hdr";
        FromPstdPhysInvtOrderLine: Record "Pstd. Phys. Invt. Order Line";
        ErrorText: Text[250];
        DocNo: Code[20];
        NoOfOrderLines: Integer;
        NextLineNo: Integer;
        NoOfInsertedLines: Integer;
        NoOfNoInsertedLines: Integer;
        DocType: Option "Phys. Invt. Order","Posted Phys. Invt. Order";
        CalcQtyExpected: Boolean;

        EnterDocumentNoErr: Label 'Please enter a Document No.';
        CannotCopyToItSelfErr: Label 'Order %1 cannot be copied onto itself.', Comment = '%1 = Order No.';
        LinesInsertedMsg: Label '%1 lines inserted and %2 lines not inserted into the order %3.', Comment = '%1,%2 = counters, %3 = Order No.';
        LinesInsertedToOrderMsg: Label '%1 lines inserted into the order %2.', Comment = '%1 = counters, %2 = Order No.';

    protected var
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";

    procedure SetPhysInvtOrderHeader(var NewPhysInvtOrderHeader: Record "Phys. Invt. Order Header")
    begin
        PhysInvtOrderHeader := NewPhysInvtOrderHeader;
    end;

    local procedure ValidateDocNo()
    begin
        if DocNo = '' then
            FromPhysInvtOrderHeader.Init()
        else
            if FromPhysInvtOrderHeader."No." = '' then begin
                FromPhysInvtOrderHeader.Init();
                case DocType of
                    DocType::"Phys. Invt. Order":
                        FromPhysInvtOrderHeader.Get(DocNo);
                    DocType::"Posted Phys. Invt. Order":
                        begin
                            FromPstdPhysInvtOrderHdr.Get(DocNo);
                            FromPhysInvtOrderHeader.TransferFields(FromPstdPhysInvtOrderHdr);
                        end;
                end;
            end;
        FromPhysInvtOrderHeader."No." := '';
    end;

    local procedure LookupDocNo()
    begin
        case DocType of
            DocType::"Phys. Invt. Order":
                begin
                    FromPhysInvtOrderHeader.SetFilter("No.", '<>%1', PhysInvtOrderHeader."No.");
                    FromPhysInvtOrderHeader."No." := DocNo;
                    if FromPhysInvtOrderHeader.Find('=><') then;
                    if PAGE.RunModal(0, FromPhysInvtOrderHeader) = ACTION::LookupOK then
                        DocNo := FromPhysInvtOrderHeader."No.";
                end;
            DocType::"Posted Phys. Invt. Order":
                begin
                    FromPstdPhysInvtOrderHdr."No." := DocNo;
                    if FromPstdPhysInvtOrderHdr.Find('=><') then;
                    if PAGE.RunModal(0, FromPstdPhysInvtOrderHdr) = ACTION::LookupOK then
                        DocNo := FromPstdPhysInvtOrderHdr."No.";
                end;
        end;
        ValidateDocNo();
    end;

    procedure InsertNewLine(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; BinCode: Code[20])
    begin
        PhysInvtOrderLine.Init();
        PhysInvtOrderLine."Document No." := PhysInvtOrderHeader."No.";
        PhysInvtOrderLine."Line No." := NextLineNo;
        PhysInvtOrderLine.Validate("Item No.", ItemNo);
        PhysInvtOrderLine.Validate("Variant Code", VariantCode);
        PhysInvtOrderLine.Validate("Location Code", LocationCode);
        PhysInvtOrderLine.Validate("Bin Code", BinCode);
        PhysInvtOrderLine.Insert(true);
        PhysInvtOrderLine.CreateDimFromDefaultDim();
        if CalcQtyExpected then
            PhysInvtOrderLine.CalcQtyAndTrackLinesExpected();
        PhysInvtOrderLine.Modify();
        NextLineNo := NextLineNo + 10000;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetNoOfOrderLinesFromPhysInvtOrder(var NoOfOrderLines: Integer; var FromPhysInvtOrderLine: Record "Phys. Invt. Order Line"; PhysInvtOrderHeader: Record "Phys. Invt. Order Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetNoOfOrderLinesFromPostedPhysInvtOrder(var NoOfOrderLines: Integer; var FromPstdPhysInvtOrderLine: Record "Pstd. Phys. Invt. Order Line"; PhysInvtOrderHeader: Record "Phys. Invt. Order Header")
    begin
    end;
}

