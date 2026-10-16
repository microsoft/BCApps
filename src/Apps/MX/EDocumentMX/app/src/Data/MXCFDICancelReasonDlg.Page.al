// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument.Interfactura;

using Microsoft.eServices.EDocument;

page 3367 "MX CFDI Cancel Reason Dlg"
{
    Caption = 'CFDI Cancellation Request';
    PageType = StandardDialog;
    DataCaptionExpression = '';

    layout
    {
        area(Content)
        {
            group(Reason)
            {
                Caption = 'Cancellation Details';
                field(CancellationReasonCode; CancellationReasonCode)
                {
                    ApplicationArea = All;
                    Caption = 'Reason';
                    TableRelation = "CFDI Cancellation Reason";
                    ToolTip = 'Specifies the SAT cancellation reason code. Use 01 if you are replacing this document with another CFDI.';

                    trigger OnValidate()
                    var
                        CFDICancellationReason: Record "CFDI Cancellation Reason";
                    begin
                        SubstitutionRequired := false;
                        SubstitutionDocumentNo := '';
                        SubstitutionUUID := '';
                        if CancellationReasonCode <> '' then
                            if CFDICancellationReason.Get(CancellationReasonCode) then
                                SubstitutionRequired := CFDICancellationReason."Substitution Number Required";
                        CurrPage.Update(false);
                    end;
                }
                field(SubstitutionDocumentNo; SubstitutionDocumentNo)
                {
                    ApplicationArea = All;
                    Caption = 'Substitution Document';
                    Editable = SubstitutionRequired;
                    ToolTip = 'Specifies the document number of the CFDI that replaces this one. Required when the cancellation reason requires a substitution.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        EDocument: Record "E-Document";
                        EDocuments: Page "E-Documents";
                        CFDIWriteBackMX: Codeunit "CFDI Write-Back MX";
                        UUID: Text;
                    begin
                        EDocument.SetRange(Direction, EDocument.Direction::Outgoing);
                        EDocuments.SetTableView(EDocument);
                        EDocuments.LookupMode := true;
                        if EDocuments.RunModal() <> Action::LookupOK then
                            exit(false);
                        EDocuments.GetRecord(EDocument);
                        UUID := CFDIWriteBackMX.GetUUIDForDocument(EDocument."Document Record ID");
                        if UUID = '' then
                            Error(SubstitutionDocNotStampedErr);
                        SubstitutionDocumentNo := CopyStr(EDocument."Document No.", 1, MaxStrLen(SubstitutionDocumentNo));
                        SubstitutionUUID := CopyStr(UUID, 1, MaxStrLen(SubstitutionUUID));
                        Text := SubstitutionDocumentNo;
                        exit(true);
                    end;
                }
                field(SubstitutionUUID; SubstitutionUUID)
                {
                    ApplicationArea = All;
                    Caption = 'Substitution UUID';
                    Editable = false;
                    ToolTip = 'Specifies the UUID of the CFDI that replaces this one, as assigned by SAT.';
                }
            }
        }
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction <> Action::OK then
            exit(true);
        if CancellationReasonCode = '' then
            Error(CancellationReasonRequiredErr);
        if SubstitutionRequired and (SubstitutionUUID = '') then
            Error(SubstitutionDocRequiredErr);
    end;

    procedure GetReasonCode(): Code[10]
    begin
        exit(CancellationReasonCode);
    end;

    procedure GetSubstitutionUUID(): Text[50]
    begin
        exit(SubstitutionUUID);
    end;

    var
        CancellationReasonCode: Code[10];
        SubstitutionDocumentNo: Text[50];
        SubstitutionUUID: Text[50];
        SubstitutionRequired: Boolean;
        CancellationReasonRequiredErr: Label 'You must select a cancellation reason before proceeding.';
        SubstitutionDocRequiredErr: Label 'A substitution document is required for this cancellation reason. Use the lookup to select a stamped CFDI document.';
        SubstitutionDocNotStampedErr: Label 'The selected document has not been stamped and does not have a UUID. Select a document with a stamped CFDI.';
}
