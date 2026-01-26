// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.History;

page 12213 "Posted Serv. Cr. Memo - Update"
{
    Caption = 'Posted Service Credit Memo - Update';
    DeleteAllowed = false;
    Editable = true;
    InsertAllowed = false;
    ModifyAllowed = true;
    PageType = Card;
    ShowFilter = false;
    SourceTable = "Service Cr.Memo Header";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the posted credit memo number. You cannot change the number because the document has already been posted.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Service;
                    Caption = 'Customer';
                    Editable = false;
                    ToolTip = 'Specifies the name of the customer to whom you shipped the service on the credit memo.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the date when the credit memo was posted.';
                }
            }
            group(Invoicing)
            {
                Caption = 'Invoicing';
                field("Fattura Document Type"; Rec."Fattura Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = true;
                    ToolTip = 'Specifies the value to export into the TipoDocument XML node of the Fattura document.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        xServiceCrMemoHeader := Rec;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = Action::LookupOK then
            if RecordChanged() then
                Codeunit.Run(Codeunit::"Service Cr. Memo Header - Edit", Rec);
    end;

    var
        xServiceCrMemoHeader: Record "Service Cr.Memo Header";

    local procedure RecordChanged() RecordIsChanged: Boolean
    begin
        RecordIsChanged :=
          (Rec."Fattura Document Type" <> xServiceCrMemoHeader."Fattura Document Type");

        OnAfterRecordIsChanged(Rec, xServiceCrMemoHeader, RecordIsChanged);
    end;

    [Scope('OnPrem')]
    procedure SetRec(ServiceCrMemoHeader: Record "Service Cr.Memo Header")
    begin
        Rec := ServiceCrMemoHeader;
        Rec.Insert();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRecordIsChanged(var ServiceCrMemoHeader: Record "Service Cr.Memo Header"; xServiceCrMemoHeader: Record "Service Cr.Memo Header"; var RecordIsChanged: Boolean)
    begin
    end;
}

