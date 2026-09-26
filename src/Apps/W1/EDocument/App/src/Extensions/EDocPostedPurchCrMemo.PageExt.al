// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.History;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Message;

pageextension 6147 "E-Doc. Posted Purch. Cr. Memo" extends "Posted Purchase Credit Memo"
{
    layout
    {
        addlast(FactBoxes)
        {
            part(EDocStatusFactBox; "E-Doc. Status FactBox")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'E-Document';
                ShowFilter = false;
            }
            part(EDocMessages; "E-Document Messages FactBox")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'E-Document Messages';
                ShowFilter = false;
            }
        }
    }
    actions
    {
        addafter("&Cr. Memo")
        {
            group("E-Document")
            {
                action("OpenEDocument")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Open';
                    Image = Open;
                    ToolTip = 'Opens the E-Document card page.';
                    Enabled = EDocumentExists;

                    trigger OnAction()
                    var
                        EDocument: Record "E-Document";
                    begin
                        EDocument.OpenEDocument(Rec.RecordId);
                    end;
                }
                action(CreateEDocument)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Create self-billed E-Document';
                    Image = CreateDocument;
                    ToolTip = 'Creates a self-billed E-Document from this posted purchase credit memo and sends it via service. Only available for vendors with a self-billing agreement and registered participant IDs.';
                    Enabled = (not SelfBillEDocumentExists) and CanSelfBill;

                    trigger OnAction()
                    var
                        EDocumentProcessing: Codeunit "E-Document Processing";
                    begin
                        if EDocumentProcessing.CreateEDocumentFromPostedDocumentPage(Rec, Enum::"E-Document Type"::"Self-Billed Purch. Cr. Memo") then
                            Message(EDocumentCreatedMsg)
                        else
                            Message(EDocumentNotCreatedMsg);
                    end;
                }
            }
        }
    }

    var
        CanSelfBill: Boolean;
        EDocumentExists: Boolean;
        SelfBillEDocumentExists: Boolean;
        EDocumentCreatedMsg: Label 'The e-document has been created.';
        EDocumentNotCreatedMsg: Label 'The e-document could not be created.';

    trigger OnAfterGetCurrRecord()
    var
        EDocument: Record "E-Document";
        EDocumentSubscribers: Codeunit "E-Document Subscribers";
    begin
        EDocumentExists := EDocument.HasEDocument(Rec.RecordId());
        CurrPage.EDocMessages.Page.SetSourceRecordId(Rec.RecordId());
        CurrPage.EDocStatusFactBox.Page.SetDocumentRecordId(Rec.RecordId());

        EDocument.SetRange("Document Record ID", Rec.RecordId());
        SelfBillEDocumentExists := not EDocument.IsEmpty();
        CanSelfBill := EDocumentSubscribers.IsEligibleForSelfBilling(Rec."Buy-from Vendor No.");
    end;
}

