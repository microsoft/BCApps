#if not CLEANSCHEMA33
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

table 10800 "FR Acc. Schedule Name"
{
    ObsoleteReason = 'Moved to the French financial reporting capability in the Reports FR app.';
#if CLEAN30
    ReplicateData = false;
#endif
#if not CLEAN30
    ObsoleteState = Pending;
    ObsoleteTag = '30.0';
#else
    ObsoleteState = Removed;
    ObsoleteTag = '33.0';
#endif
    Caption = 'FR Acc. Schedule Name';
    DataCaptionFields = Name, Description;
#if not CLEAN30
    LookupPageID = "FR Account Schedule Names";
#endif
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
        AccSchedLine.SetRange("Schedule Name", Name);
        AccSchedLine.DeleteAll();
    end;

    var
#pragma warning disable AS0105
        AccSchedLine: Record "FR Acc. Schedule Line";
#pragma warning restore AS0105
}

#endif
