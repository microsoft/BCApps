// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.History;

using Microsoft.EServices.EDocument;

pageextension 10616 "Posted Service Credit Memo NO" extends "Posted Service Credit Memo"
{
    layout
    {
        addbefore("Shortcut Dimension 1 Code")
        {
            field(GLN; Rec.GLN)
            {
                ApplicationArea = Service;
                Editable = false;
                ToolTip = 'Specifies the global location number of the customer.';
            }
            field("Account Code"; Rec."Account Code")
            {
                ApplicationArea = Service;
                Editable = false;
                ToolTip = 'Specifies the account code of the customer.';
            }
            field("E-Invoice"; Rec."E-Invoice")
            {
                ApplicationArea = Service;
                Editable = false;
                ToolTip = 'Specifies whether the customer is part of the EHF system and requires an electronic service invoice.';
            }
            field("E-Invoice Created"; Rec."E-Invoice Created")
            {
                ApplicationArea = Service;
                ToolTip = 'Specifies whether an electronic service invoice has been created and copied to the location specified in Service Mgt. Setup window.';
            }
        }
        addafter("Location Code")
        {
            field("Delivery Date"; Rec."Delivery Date")
            {
                ApplicationArea = Service;
                ToolTip = 'Specifies the date that the item was requested for delivery in the service invoice.';
            }
        }
    }

    actions
    {
        addbefore(SendCustom)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                action("Create Electronic Credit Memo")
                {
                    ApplicationArea = Service;
                    Caption = 'Create Electronic Credit Memo';
                    Ellipsis = true;
                    Image = CreateDocument;
                    ToolTip = 'Create one or more XML documents that you can send to the customer. You can run the batch job for multiple credit memos or you can run it for an individual credit memo. The document number is used as the file name. The files are stored at the location that has been specified in the Sales & Receivables Setup window.';
                    Visible = false;

                    trigger OnAction()
                    var
                        ServCrMemoHeader: Record "Service Cr.Memo Header";
                    begin
                        ServCrMemoHeader := Rec;
                        ServCrMemoHeader.SetRecFilter();
                        REPORT.RunModal(REPORT::"Create Elec. Service Cr. Memos", true, false, ServCrMemoHeader);
                    end;
                }
            }
        }
    }
}