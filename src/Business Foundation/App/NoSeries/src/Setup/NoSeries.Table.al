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
#pragma warning disable AL0432
        field(12100; "No. Series Type"; Enum "No. Series Type")
#pragma warning restore AL0432
        {
            Caption = 'No. Series Type';
            ObsoleteReason = 'The field is used in IT localization only.';
            ObsoleteTag = '24.0';
            ObsoleteState = Moved;
            MovedTo = '437dbf0e-84ff-417a-965d-ed2bb9650972';
        }
        field(12101; "VAT Register"; Code[10])
        {
            Caption = 'VAT Register';
            ObsoleteReason = 'The field is used in IT localization only.';
            ObsoleteTag = '24.0';
            ObsoleteState = Moved;
            MovedTo = '437dbf0e-84ff-417a-965d-ed2bb9650972';
        }
        field(12102; "VAT Reg. Print Priority"; Integer)
        {
            Caption = 'VAT Reg. Print Priority';
            ObsoleteReason = 'The field is used in IT localization only.';
            ObsoleteTag = '24.0';
            ObsoleteState = Moved;
            MovedTo = '437dbf0e-84ff-417a-965d-ed2bb9650972';
        }
        field(12103; "Reverse Sales VAT No. Series"; Code[20])
        {
            Caption = 'Reverse Sales VAT No. Series';
            ObsoleteReason = 'The field is used in IT localization only.';
            ObsoleteTag = '24.0';
            ObsoleteState = Moved;
            MovedTo = '437dbf0e-84ff-417a-965d-ed2bb9650972';
        }
        field(11790; Mask; Text[20]) // CZ Functionality
        {
            Caption = 'Mask';
            ObsoleteReason = 'The field is used in CZ localization only. The functionality of No. Series Enhancements will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
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
        NoSeriesSetupImpl: Codeunit "No. Series - Setup Impl.";
    begin
        NoSeriesSetupImpl.DrillDown(Rec);
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
        NoSeriesSetupImpl: Codeunit "No. Series - Setup Impl.";
        NoSeriesSingle: Interface "No. Series - Single";
        NoSeriesImplementation: Enum "No. Series Implementation";
    begin
        NoSeriesSetupImpl.UpdateLine(Rec, StartDate, StartNo, EndNo, LastNoUsed, WarningNo, IncrementByNo, LastDateUsed, NoSeriesImplementation);
        NoSeriesSingle := NoSeriesImplementation;
        AllowGaps := NoSeriesSingle.MayProduceGaps();
    end;

    [Obsolete('The function has been moved to codeunit NoSeriesManagement', '24.0')]
    procedure FindNoSeriesLineToShow(var NoSeriesLine: Record "No. Series Line")
    var
        NoSeriesMgt: Codeunit NoSeriesMgt;
    begin
        NoSeriesMgt.FindNoSeriesLineToShow(Rec, NoSeriesLine)
    end;
#pragma warning restore AL0432
#endif

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
}
