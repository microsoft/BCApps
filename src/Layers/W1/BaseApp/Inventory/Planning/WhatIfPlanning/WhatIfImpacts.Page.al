// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Planning;

using Microsoft.Inventory.Transfer;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;
using Microsoft.Utilities;
using System.Reflection;

page 5443 "What-If Impacts"
{
    PageType = ListPart;
    SourceTable = "What-If Impact";
    SourceTableTemporary = true;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field("Impact Type"; Rec."Impact Type")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field(SourceTableName; SourceTableName)
                {
                    Caption = 'Source';
                    ToolTip = 'Specifies the source of the impact.';
                    ApplicationArea = Basic, Suite;
                }
                field(SourceTableStatus; SourceTableStatus)
                {
                    Caption = 'Document Type';
                    ToolTip = 'Specifies the document type of the impacted document.';
                    ApplicationArea = Basic, Suite;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Document Line No."; Rec."Document Line No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Impacted Item No."; Rec."Impacted Item No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Description"; Rec."Description")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Document Quantity (Base)"; Rec."Document Quantity (Base)")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(ShowDocuments)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Show Document';
                Image = View;
                ToolTip = 'View the document that is impacted by the change in supply planning.';

                trigger OnAction()
                begin
                    ShowDocument();
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        FormatLine();
    end;

    trigger OnAfterGetRecord()
    begin
        FormatLine();
    end;

    var
        SourceTableName: Text[100];
        SourceTableStatus: Text;

    procedure UpdateWhatIfImpacts(var TempWhatIfImpacts: Record "What-If Impact" temporary)
    begin
        Rec.Reset();
        Rec.DeleteAll();

        if TempWhatIfImpacts.FindSet() then
            repeat
                Rec.Init();
                Rec := TempWhatIfImpacts;
                Rec.Insert();
            until TempWhatIfImpacts.Next() = 0;
    end;

    local procedure FormatLine()
    var
        AllObj: Record AllObj;
    begin
        SourceTableName := '';
        SourceTableStatus := '';
        if Rec."Impact Table Id" <> 0 then
            if AllObj.Get(AllObj."Object Type"::Table, Rec."Impact Table Id") then begin
                SourceTableName := AllObj."Object Name";
                SourceTableStatus := Enum2Str(Rec."Impact Table Id", Rec."Document Status");
            end;
    end;

    local procedure Enum2Str(TableId: Integer; Status: Integer): Text
    var
        Result: Text;
    begin
        case TableId of
            Database::"Purchase Line":
                Result := Format(Enum::"Purchase Document Type".FromInteger(Status));
            Database::"Sales Line":
                Result := Format(Enum::"Sales Document Type".FromInteger(Status));
            else
                OnEnum2StrOnElseCase(TableId, Status, Result);
        end;

        exit(Result);
    end;

    local procedure ShowDocument()
    var
        PurchaseHeader: Record "Purchase Header";
        TransferHeader: Record "Transfer Header";
        SalesHeader: Record "Sales Header";
        PageMgmt: Codeunit "Page Management";
    begin
        case Rec."Impact Table Id" of
            Database::"Purchase Line":
                begin
                    PurchaseHeader.Get(Enum::"Purchase Document Type".FromInteger(Rec."Document Status"), Rec."Document No.");
                    Page.Run(PageMgmt.GetPageId(PurchaseHeader), PurchaseHeader);
                end;
            Database::"Transfer Line":
                begin
                    TransferHeader.Get(Rec."Document No.");
                    Page.Run(PageMgmt.GetPageId(TransferHeader), TransferHeader);
                end;
            Database::"Sales Line":
                begin
                    SalesHeader.Get(Enum::"Sales Document Type".FromInteger(Rec."Document Status"), Rec."Document No.");
                    Page.Run(PageMgmt.GetPageId(SalesHeader), SalesHeader);
                end
            else
                OnShowDocumentOnElseCase(Rec);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnEnum2StrOnElseCase(TableId: Integer; Status: Integer; var Result: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowDocumentOnElseCase(var WhatIfImpact: Record "What-If Impact")
    begin
    end;
}