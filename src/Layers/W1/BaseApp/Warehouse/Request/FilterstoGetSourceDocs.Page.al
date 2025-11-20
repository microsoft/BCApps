// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Request;

using Microsoft.Warehouse.Document;

page 5784 "Filters to Get Source Docs."
{
    Caption = 'Filters to Get Source Docs.';
    PageType = Worksheet;
    RefreshOnActivate = true;
    SourceTable = "Warehouse Source Filter";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(ShowRequestForm; ShowRequestForm)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Show Filter Request';
                    ToolTip = 'Specifies if the Filters to Get Source Docs. window appears when you choose Use Filters to Get Source Docs on a warehouse shipment or warehouse receipt document.';
                }
                field("Do Not Fill Qty. to Handle"; Rec."Do Not Fill Qty. to Handle")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies that inventory quantities are assigned when you get outbound source document lines for shipment.';
                }
            }
            repeater(Control1)
            {
                Editable = true;
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the code that identifies the filter record.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the description of filter combinations in the Source Document Filter Card window to retrieve lines from source documents.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Run)
            {
                ApplicationArea = Warehouse;
                Caption = '&Run';
                Image = Start;
                ToolTip = 'Get the specified source documents.';

                trigger OnAction()
                var
                    GetSourceBatch: Report "Get Source Documents";
                begin
                    case RequestType of
                        RequestType::Receive:
                            begin
                                GetSourceBatch.SetOneCreatedReceiptHeader(WhseReceiptHeader);
                                Rec.SetFilters(GetSourceBatch, WhseReceiptHeader."Location Code");
                            end;
                        RequestType::Ship:
                            begin
                                GetSourceBatch.SetOneCreatedShptHeader(WhseShptHeader);
                                Rec.SetFilters(GetSourceBatch, WhseShptHeader."Location Code");
                                GetSourceBatch.SetSkipBlocked(true);
                            end;
                    end;

                    GetSourceBatch.SetSkipBlockedItem(true);
                    GetSourceBatch.UseRequestPage(ShowRequestForm);
                    OnActionRunOnBeforeGetSourceBatchRunModal(Rec, GetSourceBatch);
                    GetSourceBatch.RunModal();
                    OnActionRunOnAfterGetSourceBatchRunModal(Rec, GetSourceBatch);
                    if GetSourceBatch.NotCancelled() then
                        CurrPage.Close();
                end;
            }
            action(Modify)
            {
                ApplicationArea = Warehouse;
                Caption = '&Modify';
                Image = EditFilter;
                ToolTip = 'Change the type of source documents that the function looks in.';

                trigger OnAction()
                var
                    SourceDocFilterCard: Page "Source Document Filter Card";
                begin
                    Rec.TestField(Code);
                    case RequestType of
                        RequestType::Receive:
                            SourceDocFilterCard.SetOneCreatedReceiptHeader(WhseReceiptHeader);
                        RequestType::Ship:
                            SourceDocFilterCard.SetOneCreatedShptHeader(WhseShptHeader);
                    end;
                    SourceDocFilterCard.SetRecord(Rec);
                    SourceDocFilterCard.SetTableView(Rec);
                    OnActionRunOnBeforeSourceDocFilterCardRunModal(Rec, SourceDocFilterCard);
                    SourceDocFilterCard.RunModal();
                    CurrPage.Close();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Run_Promoted; Run)
                {
                }
                actionref(Modify_Promoted; Modify)
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        ShowRequestForm := Rec."Show Filter Request";
    end;

    trigger OnOpenPage()
    begin
        DataCaption := CurrPage.Caption;
        Rec.FilterGroup := 2;
        if Rec.GetFilter(Type) <> '' then
            DataCaption := DataCaption + ' - ' + Rec.GetFilter(Type);
        Rec.FilterGroup := 0;
        CurrPage.Caption(DataCaption);
    end;

    var
        DataCaption: Text[250];
        ShowRequestForm: Boolean;

    protected var
        WhseReceiptHeader: Record "Warehouse Receipt Header";
        WhseShptHeader: Record "Warehouse Shipment Header";
        RequestType: Option Receive,Ship;

    procedure SetOneCreatedShptHeader(WhseShptHeader2: Record "Warehouse Shipment Header")
    begin
        RequestType := RequestType::Ship;
        WhseShptHeader := WhseShptHeader2;
    end;

    procedure SetOneCreatedReceiptHeader(WhseReceiptHeader2: Record "Warehouse Receipt Header")
    begin
        RequestType := RequestType::Receive;
        WhseReceiptHeader := WhseReceiptHeader2;
    end;

    [IntegrationEvent(true, false)]
    local procedure OnActionRunOnBeforeGetSourceBatchRunModal(var WarehouseSourceFilter: Record "Warehouse Source Filter"; var GetSourceBatch: Report "Get Source Documents")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnActionRunOnAfterGetSourceBatchRunModal(var WarehouseSourceFilter: Record "Warehouse Source Filter"; var GetSourceBatch: Report "Get Source Documents")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnActionRunOnBeforeSourceDocFilterCardRunModal(var WarehouseSourceFilter: Record "Warehouse Source Filter"; var SourceDocumentFilterCard: Page "Source Document Filter Card")
    begin
    end;
}

