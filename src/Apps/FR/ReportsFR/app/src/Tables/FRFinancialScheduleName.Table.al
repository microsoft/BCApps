// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

table 10826 "FR Financial Schedule Name"
{
    Caption = 'FR Acc. Schedule Name';
    DataCaptionFields = Name, Description;
    LookupPageID = "FR Financial Schedule Names";
    DataClassification = CustomerContent;

    fields
    {
        field(1; Name; Code[10])
        {
            Caption = 'Name';
            NotBlank = true;
        }
        field(2; Description; Text[80])
        {
            Caption = 'Description';
        }
        field(10800; "Caption Column 1"; Text[30])
        {
            Caption = 'Caption Column 1';
        }
        field(10801; "Caption Column 2"; Text[30])
        {
            Caption = 'Caption Column 2';
        }
        field(10802; "Caption Column 3"; Text[30])
        {
            Caption = 'Caption Column 3';
        }
        field(10803; "Caption Column Previous Year"; Text[30])
        {
            Caption = 'Caption Column Previous Year';
        }
    }

    keys
    {
        key(Key1; Name)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; Name, Description)
        {
        }
    }

    trigger OnDelete()
    begin
        EnsureAvailable();
        AccSchedLine.SetRange("Schedule Name", Name);
        AccSchedLine.DeleteAll();
    end;

    trigger OnInsert()
    begin
        EnsureAvailable();
    end;

    trigger OnModify()
    begin
        EnsureAvailable();
    end;

    trigger OnRename()
    begin
        EnsureAvailable();
    end;

    var
        AccSchedLine: Record "FR Financial Schedule Line";

    local procedure EnsureAvailable()
    var
        FinancialScheduleMgt: Codeunit "FR Financial Schedule Mgt.";
    begin
        FinancialScheduleMgt.EnsureAvailable();
    end;
}
