// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Document;

report 99003802 "Copy Production Order Document"
{
    Caption = 'Copy Production Order Document';
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
                    field(Status; StatusType)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Status';
                        ToolTip = 'Specifies the status of the production order that you want to copy from. Click the field to see the existing production order status types.';

                        trigger OnValidate()
                        begin
                            DocNo := '';
                        end;
                    }
                    field(DocumentNo; DocNo)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Document No.';
                        ToolTip = 'Specifies the relevant production order number that you want to copy from. ';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            LookupDocNo();
                        end;
                    }
                    field(IncludeHeader; IncludeHeader)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Include Header';
                        ToolTip = 'Specifies if you also want to copy the existing header information to the new production order record.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if DocNo <> '' then begin
                case StatusType of
                    StatusType::Simulated:
                        if FromProdOrder.Get(FromProdOrder.Status::Simulated, DocNo) then
                            ;
                    StatusType::Planned:
                        if FromProdOrder.Get(FromProdOrder.Status::Planned, DocNo) then
                            ;
                    StatusType::"Firm Planned":
                        if FromProdOrder.Get(FromProdOrder.Status::"Firm Planned", DocNo) then
                            ;
                    StatusType::Released:
                        if FromProdOrder.Get(FromProdOrder.Status::Released, DocNo) then
                            ;
                    StatusType::Finished:
                        if FromProdOrder.Get(FromProdOrder.Status::Finished, DocNo) then
                            ;
                    else
                        OnOpenPageOnCaseElse(StatusType, DocNo, FromProdOrder);
                end;
                if FromProdOrder."No." = '' then
                    DocNo := '';
            end;
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        if ToProdOrder."No." = '' then
            Error(Text000);

        if (ToProdOrder.Status = StatusType) and (ToProdOrder."No." = DocNo) then
            Error(Text002, FromProdOrder.TableCaption());

        if IncludeHeader then
            CopyProdOrder();

        CopyProdLines();
    end;

    var
        FromProdOrder: Record "Production Order";

#pragma warning disable AA0074
        Text000: Label 'You must enter a document number. ';
#pragma warning disable AA0470
        Text002: Label 'The %1 cannot be copied onto itself.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    protected var
        ToProdOrder: Record "Production Order";
        StatusType: Enum "Production Order Status";
        DocNo: Code[20];
        IncludeHeader: Boolean;

    procedure SetProdOrder(var NewProdOrder: Record "Production Order")
    begin
        ToProdOrder := NewProdOrder;
    end;

    local procedure LookupDocNo()
    begin
        FromProdOrder.SetRange(Status, StatusType);
        FromProdOrder."No." := DocNo;
        if PAGE.RunModal(0, FromProdOrder) = ACTION::LookupOK then
            DocNo := FromProdOrder."No.";
    end;

    local procedure CopyProdOrder()
    var
        FromProdOrder: Record "Production Order";
    begin
        FromProdOrder.SetRange(Status, StatusType);
        FromProdOrder.SetRange("No.", DocNo);
        if FromProdOrder.FindFirst() then begin
            ToProdOrder.Description := FromProdOrder.Description;
            ToProdOrder."Search Description" := FromProdOrder."Search Description";
            ToProdOrder."Description 2" := FromProdOrder."Description 2";
            ToProdOrder."Last Date Modified" := FromProdOrder."Last Date Modified";
            ToProdOrder."Source Type" := FromProdOrder."Source Type";
            ToProdOrder."Source No." := FromProdOrder."Source No.";
            ToProdOrder."Routing No." := FromProdOrder."Routing No.";
            ToProdOrder."Inventory Posting Group" := FromProdOrder."Inventory Posting Group";
            ToProdOrder."Gen. Prod. Posting Group" := FromProdOrder."Gen. Prod. Posting Group";
            ToProdOrder."Gen. Bus. Posting Group" := FromProdOrder."Gen. Bus. Posting Group";
            ToProdOrder."Starting Time" := FromProdOrder."Starting Time";
            ToProdOrder."Starting Date" := FromProdOrder."Starting Date";
            ToProdOrder."Ending Time" := FromProdOrder."Ending Time";
            ToProdOrder."Ending Date" := FromProdOrder."Ending Date";
            ToProdOrder."Due Date" := FromProdOrder."Due Date";
            ToProdOrder.Blocked := FromProdOrder.Blocked;
            ToProdOrder."Shortcut Dimension 1 Code" := FromProdOrder."Shortcut Dimension 1 Code";
            ToProdOrder."Shortcut Dimension 2 Code" := FromProdOrder."Shortcut Dimension 2 Code";
            ToProdOrder."Dimension Set ID" := FromProdOrder."Dimension Set ID";
            ToProdOrder."Location Code" := FromProdOrder."Location Code";
            ToProdOrder."Bin Code" := FromProdOrder."Bin Code";
            ToProdOrder."Low-Level Code" := FromProdOrder."Low-Level Code";
            ToProdOrder.Quantity := FromProdOrder.Quantity;
            ToProdOrder."Unit Cost" := FromProdOrder."Unit Cost";
            ToProdOrder."Cost Amount" := FromProdOrder."Cost Amount";
            ToProdOrder."Planned Order No." := FromProdOrder."Planned Order No.";
            ToProdOrder."Firm Planned Order No." := FromProdOrder."Firm Planned Order No.";
            ToProdOrder."Simulated Order No." := FromProdOrder."Simulated Order No.";
            ToProdOrder."Work Center Filter" := FromProdOrder."Work Center Filter";
            ToProdOrder."Capacity Type Filter" := FromProdOrder."Capacity Type Filter";
            ToProdOrder."Capacity No. Filter" := FromProdOrder."Capacity No. Filter";
            ToProdOrder."Date Filter" := FromProdOrder."Date Filter";
            ToProdOrder.Comment := FromProdOrder.Comment;
            OnBeforeToProdOrderModify(ToProdOrder, FromProdOrder);
            ToProdOrder.Modify();
        end;
    end;

    local procedure CopyProdLines()
    var
        FromProdOrderLine: Record "Prod. Order Line";
        ToProdOrderLine: Record "Prod. Order Line";
        LineNo: Integer;
    begin
        ToProdOrderLine.SetRange(Status, ToProdOrder.Status);
        ToProdOrderLine.SetRange("Prod. Order No.", ToProdOrder."No.");
        if ToProdOrderLine.FindLast() then
            LineNo := ToProdOrderLine."Line No." + 10000
        else
            LineNo := 10000;

        FromProdOrderLine.SetRange(Status, StatusType);
        FromProdOrderLine.SetRange("Prod. Order No.", DocNo);
        OnCopyProdLinesOnAfterFilterFromProdOrderLine(FromProdOrderLine, StatusType, DocNo);
        if FromProdOrderLine.Find('-') then
            repeat
                ToProdOrderLine."Line No." := LineNo;
                ToProdOrderLine.Status := ToProdOrder.Status;
                ToProdOrderLine."Prod. Order No." := ToProdOrder."No.";
                ToProdOrderLine."Item No." := FromProdOrderLine."Item No.";
                ToProdOrderLine."Variant Code" := FromProdOrderLine."Variant Code";
                ToProdOrderLine.Description := FromProdOrderLine.Description;
                ToProdOrderLine."Description 2" := FromProdOrderLine."Description 2";
                ToProdOrderLine."Location Code" := FromProdOrderLine."Location Code";
                ToProdOrderLine."Shortcut Dimension 1 Code" := FromProdOrderLine."Shortcut Dimension 1 Code";
                ToProdOrderLine."Shortcut Dimension 2 Code" := FromProdOrderLine."Shortcut Dimension 2 Code";
                ToProdOrderLine."Dimension Set ID" := FromProdOrderLine."Dimension Set ID";
                ToProdOrderLine."Bin Code" := FromProdOrderLine."Bin Code";
                ToProdOrderLine.Quantity := FromProdOrderLine.Quantity;
                ToProdOrderLine."Quantity (Base)" := FromProdOrderLine."Quantity (Base)";
                ToProdOrderLine."Remaining Quantity" := ToProdOrderLine.Quantity;
                ToProdOrderLine."Remaining Qty. (Base)" := ToProdOrderLine."Quantity (Base)";
                if ToProdOrder."Source Type" = ToProdOrder."Source Type"::Family then
                    ToProdOrderLine."Routing Reference No." := 0
                else
                    ToProdOrderLine."Routing Reference No." := ToProdOrderLine."Line No.";
                ToProdOrderLine."Due Date" := FromProdOrderLine."Due Date";
                ToProdOrderLine."Starting Date" := FromProdOrderLine."Starting Date";
                ToProdOrderLine."Starting Time" := FromProdOrderLine."Starting Time";
                ToProdOrderLine."Ending Date" := FromProdOrderLine."Ending Date";
                ToProdOrderLine."Ending Time" := FromProdOrderLine."Ending Time";
                ToProdOrderLine."Planning Level Code" := FromProdOrderLine."Planning Level Code";
                ToProdOrderLine.Priority := FromProdOrderLine.Priority;
                ToProdOrderLine."Production BOM No." := FromProdOrderLine."Production BOM No.";
                ToProdOrderLine."Routing No." := FromProdOrderLine."Routing No.";
                ToProdOrderLine."Inventory Posting Group" := FromProdOrderLine."Inventory Posting Group";
                ToProdOrderLine."Unit Cost" := FromProdOrderLine."Unit Cost";
                ToProdOrderLine."Cost Amount" := FromProdOrderLine."Cost Amount";
                ToProdOrderLine."Unit of Measure Code" := FromProdOrderLine."Unit of Measure Code";
                ToProdOrderLine."Production BOM Version Code" := FromProdOrderLine."Production BOM Version Code";
                ToProdOrderLine."Routing Version Code" := FromProdOrderLine."Routing Version Code";
                ToProdOrderLine."Routing Type" := FromProdOrderLine."Routing Type";
                ToProdOrderLine."Qty. per Unit of Measure" := FromProdOrderLine."Qty. per Unit of Measure";
                ToProdOrderLine."Capacity Type Filter" := FromProdOrderLine."Capacity Type Filter";
                ToProdOrderLine."Capacity No. Filter" := FromProdOrderLine."Capacity No. Filter";
                ToProdOrderLine."Scrap %" := FromProdOrderLine."Scrap %";
                ToProdOrderLine."Date Filter" := FromProdOrderLine."Date Filter";
                OnBeforeToProdOrderLineInsert(ToProdOrderLine, FromProdOrderLine);
                ToProdOrderLine.Insert();
                LineNo := LineNo + 10000;
            until FromProdOrderLine.Next() = 0;

        OnAfterCopyProdLines(ToProdOrderLine, FromProdOrderLine, IncludeHeader);
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCopyProdLines(var ToProdOrderLine: Record "Prod. Order Line"; FromProdOrderLine: Record "Prod. Order Line"; IncludeHeader: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeToProdOrderModify(var ToProdOrder: Record "Production Order"; FromProdOrder: Record "Production Order")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeToProdOrderLineInsert(var ToProdOrderLine: Record "Prod. Order Line"; FromProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCopyProdLinesOnAfterFilterFromProdOrderLine(var FromProdOrderLine: Record "Prod. Order Line"; StatusType: Enum "Production Order Status"; DocNo: Code[20])
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnOpenPageOnCaseElse(StatusType: Enum "Production Order Status"; DocNo: Code[20]; var FromProductionOrder: Record "Production Order")
    begin
    end;
}

