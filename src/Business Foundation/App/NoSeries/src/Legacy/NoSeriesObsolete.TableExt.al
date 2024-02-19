// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

/// <summary>
/// This object contains the obsoleted elements of the "No. Series" table.
/// </summary>
tableextension 308 NoSeriesObsolete extends "No. Series"
{
    fields
    {
        field(11790; Mask; Text[20]) // CZ Functionality
        {
            Caption = 'Mask';
            DataClassification = CustomerContent;
            ObsoleteReason = 'The field is used in CZ localization only. The functionality of No. Series Enhancements will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
            ObsoleteState = Removed;
            ObsoleteTag = '18.0';
        }
#pragma warning disable AL0432
        field(12100; "No. Series Type"; Integer)
#pragma warning restore AL0432
        {
            DataClassification = CustomerContent;
            Caption = 'No. Series Type';
            ObsoleteReason = 'The field is used in IT localization only.';
            ObsoleteTag = '24.0';
            ObsoleteState = Moved;
            MovedTo = '437dbf0e-84ff-417a-965d-ed2bb9650972';
        }
        field(12101; "VAT Register"; Code[10])
        {
            Caption = 'VAT Register';
            DataClassification = CustomerContent;
            ObsoleteReason = 'The field is used in IT localization only.';
            ObsoleteTag = '24.0';
            ObsoleteState = Moved;
            MovedTo = '437dbf0e-84ff-417a-965d-ed2bb9650972';
        }
        field(12102; "VAT Reg. Print Priority"; Integer)
        {
            Caption = 'VAT Reg. Print Priority';
            DataClassification = CustomerContent;
            ObsoleteReason = 'The field is used in IT localization only.';
            ObsoleteTag = '24.0';
            ObsoleteState = Moved;
            MovedTo = '437dbf0e-84ff-417a-965d-ed2bb9650972';
        }
        field(12103; "Reverse Sales VAT No. Series"; Code[20])
        {
            Caption = 'Reverse Sales VAT No. Series';
            DataClassification = CustomerContent;
            ObsoleteReason = 'The field is used in IT localization only.';
            ObsoleteTag = '24.0';
            ObsoleteState = Moved;
            MovedTo = '437dbf0e-84ff-417a-965d-ed2bb9650972';
        }
    }

#if not CLEAN24
#pragma warning disable AL0432
    [Obsolete('The method has been moved to codeunit "No. Series Setup Impl."', '24.0')]
    procedure DrillDown()
    var
        NoSeriesSetupImpl: Codeunit "No. Series - Setup Impl.";
    begin
        NoSeriesSetupImpl.DrillDown(Rec);
    end;

    [Obsolete('The method has been moved to codeunit "No. Series Setup Impl."', '24.0')]
    procedure UpdateLine(var StartDate: Date; var StartNo: Code[20]; var EndNo: Code[20]; var LastNoUsed: Code[20]; var WarningNo: Code[20]; var IncrementByNo: Integer; var LastDateUsed: Date)
    var
        AllowGaps: Boolean;
    begin
        UpdateLine(StartDate, StartNo, EndNo, LastNoUsed, WarningNo, IncrementByNo, LastDateUsed, AllowGaps);
    end;

    [Obsolete('The method has been moved to codeunit "No. Series Setup Impl."', '24.0')]
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

    [Obsolete('The method has been moved to codeunit NoSeriesManagement', '24.0')]
    procedure FindNoSeriesLineToShow(var NoSeriesLine: Record "No. Series Line")
    var
        NoSeriesManagement: Codeunit NoSeriesManagement;
    begin
        NoSeriesManagement.FindNoSeriesLineToShow(Rec, NoSeriesLine)
    end;

    [Obsolete('The event has been removed. There is no replacement.', '24.0')]
    // Symbol usage indicates no subscribers.
    [IntegrationEvent(false, false)]
    internal procedure OnBeforeValidateDefaultNos(var NoSeries: Record "No. Series"; var IsHandled: Boolean)
    begin
    end;

    [Obsolete('The event has been removed. There is no replacement.', '24.0')]
    // Symbol usage indicates no subscribers.
    [IntegrationEvent(false, false)]
    internal procedure OnBeforeValidateManualNos(var NoSeries: Record "No. Series"; var IsHandled: Boolean)
    begin
    end;
#pragma warning restore AL0432
#endif
}