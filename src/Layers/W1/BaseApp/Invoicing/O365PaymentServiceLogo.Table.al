// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#pragma warning disable AA0247
table 2119 "O365 Payment Service Logo"
{
    Caption = 'O365 Payment Service Logo';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            AutoIncrement = true;
            Caption = 'Entry No.';
        }
        field(2; "Payment Service ID"; Integer)
        {
            Caption = 'Payment Service ID';
        }
        field(4; "Media Resources Ref"; Code[50])
        {
            Caption = 'Media Resources Ref';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure FindO365Logo(PaymentReportingArgument: Record "Payment Reporting Argument"): Boolean
    begin
        SetRange("Payment Service ID", PaymentReportingArgument."Payment Service ID");
        exit(FindFirst());
    end;
}

