// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

/// <summary>
/// Table that contains the available No. Series and their properties.
/// </summary>
table 308 "No. Series"
{
    Caption = 'No. Series';
    DataCaptionFields = "Code", Description;
    DataClassification = CustomerContent;
    DrillDownPageId = "No. Series";
    LookupPageId = "No. Series";
    MovedFrom = '437dbf0e-84ff-417a-965d-ed2bb9650972';

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(3; "Default Nos."; Boolean)
        {
            Caption = 'Default Nos.';

            trigger OnValidate()
            var
                NoSeriesMgt: Codeunit NoSeriesMgt;
            begin
                NoSeriesMgt.ValidateDefaultNos(Rec, xRec);
            end;
        }
        field(4; "Manual Nos."; Boolean)
        {
            Caption = 'Manual Nos.';

            trigger OnValidate()
            var
                NoSeriesMgt: Codeunit NoSeriesMgt;
            begin
                NoSeriesMgt.ValidateManualNos(Rec, xRec);
            end;
        }
        field(5; "Date Order"; Boolean)
        {
            Caption = 'Date Order';
        }
        field(12100; "No. Series Type"; Enum "No. Series Type")
        {
            Caption = 'No. Series Type';

            trigger OnValidate()
            var
                NoSeriesMgt: Codeunit NoSeriesMgt;
            begin
                NoSeriesMgt.ValidateNoSeriesType(Rec, xRec);
            end;
        }
        field(12101; "VAT Register"; Code[10])
        {
            Caption = 'VAT Register';
            ObsoleteReason = ' (IT Only) The No. Series module cannot have a dependency on VAT Register. Please use "VAT Register Code" instead.';
#if CLEAN24
            ObsoleteState = Removed;
            ObsoleteTag = '27.0';
#else
            ObsoleteState = Pending;
            ObsoleteTag = '24.0';
#endif
        }
        field(12102; "VAT Reg. Print Priority"; Integer)
        {
            Caption = 'VAT Reg. Print Priority';
            ObsoleteReason = ' (IT Only) The No. Series module cannot have a dependency on VAT Register. Please use "VAT Register Print Priority" instead.';
#if CLEAN24
            ObsoleteState = Removed;
            ObsoleteTag = '27.0';
#else
            ObsoleteState = Pending;
            ObsoleteTag = '24.0';
#endif
        }
        field(12103; "Reverse Sales VAT No. Series"; Code[20])
        {
            Caption = 'Reverse Sales VAT No. Series';
            ObsoleteReason = ' (IT Only) The No. Series module cannot have a dependency on VAT Register. Please use "VAT Register Print Priority" instead.';
#if CLEAN24
            ObsoleteState = Removed;
            ObsoleteTag = '27.0';
#else
            ObsoleteState = Pending;
            ObsoleteTag = '24.0';
#endif
        }
        field(11790; Mask; Text[20]) // CZ Functionality
        {
            Caption = 'Mask';
            ObsoleteReason = 'The functionality of No. Series Enhancements will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
            ObsoleteState = Removed;
            ObsoleteTag = '18.0';
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
        fieldgroup(DropDown; Code, Description)
        {
        }
    }

    trigger OnDelete()
    var
        NoSeriesMgt: Codeunit NoSeriesMgt;
    begin
        NoSeriesMgt.DeleteNoSeries(Rec);
    end;

#if not CLEAN24
#pragma warning disable AL0432
    [Obsolete('The function has been moved to codeunit NoSeriesManagement', '24.0')]
    procedure DrillDown()
    var
        NoSeriesMgt: Codeunit NoSeriesMgt;
    begin
        NoSeriesMgt.DrillDown(Rec);
    end;

    [Obsolete('The function has been moved to codeunit NoSeriesManagement', '24.0')]
    procedure UpdateLine(var StartDate: Date; var StartNo: Code[20]; var EndNo: Code[20]; var LastNoUsed: Code[20]; var WarningNo: Code[20]; var IncrementByNo: Integer; var LastDateUsed: Date)
    var
        AllowGaps: Boolean;
    begin
        UpdateLine(StartDate, StartNo, EndNo, LastNoUsed, WarningNo, IncrementByNo, LastDateUsed, AllowGaps);
    end;

    [Obsolete('The function has been moved to codeunit NoSeriesManagement', '24.0')]
    procedure UpdateLine(var StartDate: Date; var StartNo: Code[20]; var EndNo: Code[20]; var LastNoUsed: Code[20]; var WarningNo: Code[20]; var IncrementByNo: Integer; var LastDateUsed: Date; var AllowGaps: Boolean)
    var
        NoSeriesMgt: Codeunit NoSeriesMgt;
    begin
        NoSeriesMgt.UpdateLine(Rec, StartDate, StartNo, EndNo, LastNoUsed, WarningNo, IncrementByNo, LastDateUsed, AllowGaps);
    end;

    [Obsolete('The function has been moved to codeunit NoSeriesManagement', '24.0')]
    procedure FindNoSeriesLineToShow(var NoSeriesLine: Record "No. Series Line")
    var
        NoSeriesMgt: Codeunit NoSeriesMgt;
    begin
        NoSeriesMgt.FindNoSeriesLineToShow(Rec, NoSeriesLine)
    end;

    [Obsolete('The event has been moved to codeunit NoSeriesManagement', '24.0')]
    [IntegrationEvent(false, false)]
    internal procedure OnBeforeValidateDefaultNos(var NoSeries: Record "No. Series"; var IsHandled: Boolean)
    begin
    end;

    [Obsolete('The event has been moved to codeunit NoSeriesManagement', '24.0')]
    [IntegrationEvent(false, false)]
    internal procedure OnBeforeValidateManualNos(var NoSeries: Record "No. Series"; var IsHandled: Boolean)
    begin
    end;
#pragma warning restore AL0432
#endif
}
