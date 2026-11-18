// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Payables;

using Microsoft.Finance.Currency;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Purchases.History;

table 8843 "Purchase Installment Plan"
{
    Caption = 'Purchase Installment Plan';
    DataClassification = CustomerContent;

    fields
    {
        field(1; ID; Guid)
        {
            Caption = 'ID';
        }
        field(2; Status; Enum "Purchase Installment Plan Status")
        {
            Caption = 'Status';
        }
        field(3; "Source Record ID"; RecordId)
        {
            Caption = 'Source Record ID';
        }
        field(4; "Source SystemId"; Guid)
        {
            Caption = 'Source SystemId';
        }
        field(5; "Source Document No."; Code[20])
        {
            Caption = 'Source Document No.';
        }
        field(6; "Payment Terms Code"; Code[10])
        {
            Caption = 'Payment Terms Code';
            TableRelation = "Payment Terms";
        }
        field(7; "Document Date"; Date)
        {
            Caption = 'Document Date';
        }
        field(8; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(9; "Posted Invoice No."; Code[20])
        {
            Caption = 'Posted Invoice No.';
            TableRelation = "Purch. Inv. Header";
            Editable = false;
        }
        field(10; "Posted Invoice SystemId"; Guid)
        {
            Caption = 'Posted Invoice SystemId';
            Editable = false;
        }
        field(11; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            Editable = false;
        }
        field(12; Amount; Decimal)
        {
            Caption = 'Amount';
            AutoFormatType = 1;
            AutoFormatExpression = Rec."Currency Code";
            Editable = false;
        }
        field(13; "Amount (LCY)"; Decimal)
        {
            Caption = 'Amount (LCY)';
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Editable = false;
        }
    }

    keys
    {
        key(PK; ID)
        {
            Clustered = true;
        }
        key(Source; "Source SystemId")
        {
            Unique = true;
        }
    }

    trigger OnDelete()
    var
        PlanLine: Record "Purchase Installment Plan Line";
    begin
        if IsTemporary() then
            exit;
        TestField(Status, Status::Draft);
        PlanLine.SetRange("Plan ID", ID);
        PlanLine.DeleteAll();
    end;
}
