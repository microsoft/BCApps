// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Period;

table 53 "Accounting Period Buffer"
{
    Caption = 'Accounting Period Buffer';
    TableType = Temporary;
    Access = Internal;

    fields
    {
        field(1; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
            NotBlank = true;

            trigger OnValidate()
            begin
                Name := Format("Starting Date", 0, PeriodNameTxt);
            end;
        }
        field(2; "Ending Date"; Date)
        {
            Caption = 'Ending Date';
            NotBlank = true;

            trigger OnValidate()
            begin
                Name := Format("Starting Date", 0, PeriodNameTxt);
            end;
        }
        field(3; Name; Text[30])
        {
            Caption = 'Name';
        }
        field(5; "Customer No. Filter"; Text[20])
        {
            Caption = 'Customer No. Filter';
            FieldClass = FlowFilter;
        }
    }

    keys
    {
        key(Key1; "Starting Date")
        {
            Clustered = true;
        }
    }

    var
        PeriodNameTxt: Label '<Month Text>, <Year4,4>', Locked = true;

    procedure FillBuffer();
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        Rec.Reset();
        Rec.DeleteAll();
        if AccountingPeriod.FindSet() then begin
            Rec."Starting Date" := AccountingPeriod."Starting Date";
            if AccountingPeriod.Next() <> 0 then
                repeat
                    Rec.Validate("Ending Date", CalcDate('<-1D>', AccountingPeriod."Starting Date"));
                    Rec.Insert(true);
                    Rec.Init();
                    Rec."Starting Date" := AccountingPeriod."Starting Date";
                until AccountingPeriod.Next() = 0;
            Rec.Validate("Ending Date", 99991231D);
            Rec.Insert(true);
        end;
    end;
}