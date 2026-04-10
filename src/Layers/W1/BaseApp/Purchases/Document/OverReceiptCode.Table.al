// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

table 8510 "Over-Receipt Code"
{
    DataClassification = CustomerContent;
    LookupPageId = "Over-Receipt Codes";

    fields
    {
        field(1; Code; Code[20])
        {
            Caption = 'Code';
            ToolTip = 'Specifies a code for the over-receive policy.';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description of the over-receive policy.';
        }
        field(3; Default; Boolean)
        {
            Caption = 'Default';
            ToolTip = 'Specifies if the over-receipt code will be used by default.';

            trigger OnValidate()
            var
                OverReceiptCode: Record "Over-Receipt Code";
            begin
                if Default then begin
                    OverReceiptCode.SetRange(Default, true);
                    OverReceiptCode.ModifyAll(Default, false, false);
                end;
            end;
        }
        field(4; "Over-Receipt Tolerance %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Over-Receipt Tolerance %';
            ToolTip = 'Specifies the percentage by which the ordered quantity is allowed to be exceeded.';
            DecimalPlaces = 0 : 2;

            trigger OnValidate()
            begin
                CheckMinMaxValue();
            end;
        }
        field(5; "Required Approval"; Boolean)
        {
            Caption = 'Approval Required';
            ToolTip = 'Specifies if over-receiving items with this over-receipt-code code must first be approved.';
        }
    }

    keys
    {
        key(PK; Code)
        {
            Clustered = true;
        }
    }

    local procedure CheckMinMaxValue()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckMinMaxValue(Rec, IsHandled);
        if IsHandled then
            exit;

        if ("Over-Receipt Tolerance %" < 0) or ("Over-Receipt Tolerance %" > 100) then
            FieldError("Over-Receipt Tolerance %");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckMinMaxValue(var OverReceiptCode: Record "Over-Receipt Code"; var IsHandled: Boolean)
    begin
    end;
}
