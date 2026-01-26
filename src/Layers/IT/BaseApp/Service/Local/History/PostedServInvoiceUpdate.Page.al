#if not CLEAN27
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.History;

page 12212 "Posted Serv. Invoice - Update"
{
    Caption = 'Posted Service Invoice - Update';
    DeleteAllowed = false;
    Editable = true;
    InsertAllowed = false;
    ModifyAllowed = true;
    PageType = Card;
    ShowFilter = false;
    SourceTable = "Service Invoice Header";
    SourceTableTemporary = true;
    ObsoleteReason = 'Replaced by W1 page Posted Serv. Invoice Update and IT page extension';
    ObsoleteState = Pending;
    ObsoleteTag = '27.0';

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
                    ToolTip = 'Specifies the posted invoice number. You cannot change the number because the document has already been posted.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Service;
                    Caption = 'Customer';
                    Editable = false;
                    ToolTip = 'Specifies the name of the customer on the service invoice.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the date when the invoice was posted.';
                }
            }
            group(Invoicing)
            {
                Caption = 'Invoicing';
                field("Fattura Document Type"; Rec."Fattura Document Type")
                {
                    ApplicationArea = Service;
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
        xServiceInvoiceHeader := Rec;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = ACTION::LookupOK then
            if RecordChanged() then
                CODEUNIT.Run(CODEUNIT::"Service Invoice Header - Edit", Rec);
    end;

    var
        xServiceInvoiceHeader: Record "Service Invoice Header";

    local procedure RecordChanged() RecordIsChanged: Boolean
    begin
        RecordIsChanged :=
          (Rec."Fattura Document Type" <> xServiceInvoiceHeader."Fattura Document Type");

        OnAfterRecordIsChanged(Rec, xServiceInvoiceHeader, RecordIsChanged);
    end;

    [Scope('OnPrem')]
    procedure SetRec(ServiceInvoiceHeader: Record "Service Invoice Header")
    begin
        Rec := ServiceInvoiceHeader;
        Rec.Insert();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRecordIsChanged(var ServiceInvoiceHeader: Record "Service Invoice Header"; xServiceInvoiceHeader: Record "Service Invoice Header"; var RecordIsChanged: Boolean)
    begin
    end;
}
#endif
