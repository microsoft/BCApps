// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Payables;

table 15000000 "Remittance Agreement"
{
    Caption = 'Remittance Agreement';
    LookupPageID = "Remittance Agreement Overview";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
        }
        field(2; Description; Text[30])
        {
            Caption = 'Description';
        }
        field(3; "Payment System"; Option)
        {
            Caption = 'Payment System';
            OptionCaption = 'DnB Telebank,K-LINK,SparNett,Fokus Bank,Postbanken,Other bank,BBS';
            OptionMembers = "DnB Telebank","K-LINK",SparNett,"Fokus Bank",Postbanken,"Other bank",BBS;
        }
        field(10; "Payment File Name"; Text[200])
        {
            Caption = 'Payment File Name';
        }
        field(15; "Save Return File"; Boolean)
        {
            Caption = 'Save Return File';
        }
        field(16; "Receipt Return Required"; Boolean)
        {
            Caption = 'Receipt Return Required';
        }
        field(17; "On Hold Rejection Code"; Code[3])
        {
            Caption = 'On Hold Rejection Code';
        }
        field(18; "Return File Is Not In Use"; Boolean)
        {
            Caption = 'Return File Is Not In Use';
        }
        field(21; Password; Code[10])
        {
            Caption = 'Password';
        }
        field(22; "Operator No."; Code[11])
        {
            Caption = 'Operator No.';
        }
        field(23; "Company/Agreement No."; Code[11])
        {
            Caption = 'Company/Agreement No.';
        }
        field(24; Division; Code[11])
        {
            Caption = 'Division';
        }
        field(25; "BBS Customer Unit ID"; Code[8])
        {
            Caption = 'BBS Customer Unit ID';
        }
        field(30; "Latest Sequence No."; Integer)
        {
            Caption = 'Latest Sequence No.';

            trigger OnValidate()
            begin
                if not EditWarning(FieldCaption("Latest Sequence No.")) then
                    "Latest Sequence No." := xRec."Latest Sequence No.";
            end;
        }
        field(31; "Latest Daily Sequence No."; Integer)
        {
            Caption = 'Latest Daily Sequence No.';

            trigger OnValidate()
            begin
                if not EditWarning(FieldCaption("Latest Daily Sequence No.")) then
                    "Latest Daily Sequence No." := xRec."Latest Daily Sequence No.";
            end;
        }
        field(32; "Latest Export"; Date)
        {
            Caption = 'Latest Export';

            trigger OnValidate()
            begin
                if not EditWarning(FieldCaption("Latest Export")) then
                    "Latest Export" := xRec."Latest Export";
            end;
        }
        field(33; "Latest BBS Payment Order No."; Integer)
        {
            Caption = 'Latest BBS Payment Order No.';

            trigger OnValidate()
            begin
                if not EditWarning(FieldCaption("Latest BBS Payment Order No.")) then
                    "Latest BBS Payment Order No." := xRec."Latest BBS Payment Order No.";
            end;
        }
        field(40; "New Document Per."; Option)
        {
            Caption = 'New Document Per.';
            OptionCaption = 'Date,Vendor,Specified for account';
            OptionMembers = Date,Vendor,"Specified for account";
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        ReturnFileSetup.SetRange("Agreement Code", Code);
        ReturnFileSetup.DeleteAll(true);
    end;

    var
        ReturnFileSetup: Record "Return File Setup";
        WarningQst: Label 'Typically, %1 should not be changed. Changing it could cause problems in remittance agreement. Do you want to change it anyway?';

    [Scope('OnPrem')]
    procedure EditWarning(FieldName: Text[50]): Boolean
    begin
        exit(
          Confirm(WarningQst, false, FieldName));
    end;

    [Scope('OnPrem')]
    procedure GetPaymentFileName(): Text[250]
    begin
        if "Payment File Name" = '' then
            exit(Code + '.txt')
        else
            exit("Payment File Name");
    end;
}

