// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

table 10754 "SII Missing Entries State"
{
    Caption = 'SII Missing Entries State';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Integer)
        {
            Caption = 'Primary Key';
        }
        field(2; "Last CLE No."; Integer)
        {
            Caption = 'Last Cust. Ledg. Entry No.';
        }
        field(3; "Last VLE No."; Integer)
        {
            Caption = 'Last Vend. Ledg. Entry No.';
        }
        field(4; "Last DCLE No."; Integer)
        {
            Caption = 'Last Dtld. Cust. Ledg. Entry No.';
        }
        field(5; "Last DVLE No."; Integer)
        {
            Caption = 'Last Dtld. Vend. Ledg. Entry No.';
        }
        field(6; "Entries Missing"; Integer)
        {
            Caption = 'Entries Missing';
        }
        field(7; "Last Missing Entries Check"; Date)
        {
            Caption = 'Last Missing Entries Check';
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    [Scope('OnPrem')]
    procedure Initialize()
    begin
        if not Get() then begin
            Init();
            Insert(true);
        end;
    end;

    procedure SIIEntryRecreated(): Boolean
    begin
        if not Get() then
            exit(false);
        exit(
          ("Last CLE No." <> 0) or
          ("Last VLE No." <> 0) or
          ("Last DCLE No." <> 0) or
          ("Last DVLE No." <> 0));
    end;
}

