// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument.Interfactura;

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
                field(CancellationReason; CancellationReason)
                {
                    ApplicationArea = All;
                    Caption = 'Reason';
                    OptionCaption = '01 - Issued with errors (substitution),02 - Issued with errors (no substitution),03 - Operation did not take place,04 - Nominative operation in global invoice';
                    ToolTip = 'Specifies the SAT cancellation reason code. Use 01 if you are replacing this document with another CFDI.';

                    trigger OnValidate()
                    begin
                        SubstitutionUUIDEditable := CancellationReason = CancellationReason::"01";
                        if not SubstitutionUUIDEditable then
                            SubstitutionUUID := '';
                    end;
                }
                field(SubstitutionUUID; SubstitutionUUID)
                {
                    ApplicationArea = All;
                    Caption = 'Substitution UUID';
                    Editable = SubstitutionUUIDEditable;
                    ToolTip = 'Specifies the UUID of the CFDI document that replaces this one. Required when reason is 01.';

                    trigger OnValidate()
                    begin
                        if (CancellationReason = CancellationReason::"01") and (SubstitutionUUID = '') then
                            Error(SubstitutionUUIDRequiredErr);
                    end;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        SubstitutionUUIDEditable := CancellationReason = CancellationReason::"01";
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction <> Action::OK then
            exit(true);
        if (CancellationReason = CancellationReason::"01") and (SubstitutionUUID = '') then
            Error(SubstitutionUUIDRequiredErr);
    end;

    procedure GetReasonCode(): Code[10]
    begin
        case CancellationReason of
            CancellationReason::"01":
                exit('01');
            CancellationReason::"02":
                exit('02');
            CancellationReason::"03":
                exit('03');
            CancellationReason::"04":
                exit('04');
        end;
    end;

    procedure GetSubstitutionUUID(): Text[50]
    begin
        exit(SubstitutionUUID);
    end;

    var
        SubstitutionUUID: Text[50];
        SubstitutionUUIDEditable: Boolean;
        SubstitutionUUIDRequiredErr: Label 'Substitution UUID is required when cancellation reason is 01.';
        CancellationReason: Option "01","02","03","04";
}
