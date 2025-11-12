// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Structure;

table 7303 "Bin Type"
{
    Caption = 'Bin Type';
    LookupPageID = "Bin Type List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(5; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(10; Receive; Boolean)
        {
            Caption = 'Receive';

            trigger OnValidate()
            begin
                CheckCombination(CurrFieldNo);
            end;
        }
        field(11; Ship; Boolean)
        {
            Caption = 'Ship';

            trigger OnValidate()
            begin
                CheckCombination(CurrFieldNo);
            end;
        }
        field(12; "Put Away"; Boolean)
        {
            Caption = 'Put Away';

            trigger OnValidate()
            begin
                CheckCombination(CurrFieldNo);
            end;
        }
        field(13; Pick; Boolean)
        {
            Caption = 'Pick';

            trigger OnValidate()
            begin
                CheckCombination(CurrFieldNo);
            end;
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
    var
        Zone: Record Zone;
        Bin: Record Bin;
        BinContent: Record "Bin Content";
    begin
        Zone.SetRange("Bin Type Code", Code);
        if Zone.FindFirst() then
            Error(
              Text000,
              TableCaption, Zone.TableCaption(), Zone."Location Code", Zone.Code);

        Bin.SetCurrentKey("Bin Type Code");
        Bin.SetRange("Bin Type Code", Code);
        if Bin.FindFirst() then
            Error(
              Text001,
              TableCaption, Bin.TableCaption(), Bin."Location Code", Bin."Zone Code", Bin.Code);

        BinContent.SetCurrentKey("Bin Type Code");
        BinContent.SetRange("Bin Type Code", Code);
        if BinContent.FindFirst() then
            Error(
              Text001,
              TableCaption, BinContent.TableCaption(), BinContent."Location Code",
              BinContent."Zone Code", BinContent."Bin Code");
    end;

    trigger OnInsert()
    begin
        CheckCombination(0);
    end;

    trigger OnModify()
    begin
        CheckCombination(0);
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'You cannot delete the %1 because there is %2 %3 %4 with this %1.';
        Text001: Label 'You cannot delete the %1 because there is %2 %3 %4 %5 with this %1.';
        Text002: Label 'This combination already exists for %1 %2.';
        Text003: Label 'The %1 filter expression is too long.\Please use less Bin Types or shorter %1 Codes.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        CannotEnterReceiveShipOrPickErr: Label 'You cannot enter a bin code of bin type %1, %2, or %3.', Comment = '%1 Receive, %2 Ship, %3 Pick.';
        CannotEnterReceiveOrShipErr: Label 'You cannot enter a bin code of bin type %1 or %2.', Comment = '%1 Receive, %2 Ship.';

    protected procedure CheckCombination(CalledByFieldNo: Integer)
    var
        BinType: Record "Bin Type";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckCombination(Rec, CalledByFieldNo, IsHandled);
        if IsHandled then
            exit;

        case CalledByFieldNo of
            0:
                begin
                    BinType.SetFilter(Code, '<>%1', Code);
                    BinType.SetRange(Receive, Receive);
                    BinType.SetRange(Ship, Ship);
                    BinType.SetRange("Put Away", "Put Away");
                    BinType.SetRange(Pick, Pick);
                    OnCheckCombinationOnBeforeFindFirst(Rec, BinType);
                    if BinType.FindFirst() then
                        Error(Text002, TableCaption(), BinType.Code);
                end;
            FieldNo(Receive):
                begin
                    TestField("Put Away", false);
                    TestField(Pick, false);
                    TestField(Ship, false);
                end;
            FieldNo(Ship):
                begin
                    TestField(Receive, false);
                    TestField("Put Away", false);
                    TestField(Pick, false);
                end;
            FieldNo("Put Away"):
                begin
                    TestField(Receive, false);
                    TestField(Ship, false);
                end;
            FieldNo(Pick):
                begin
                    TestField(Receive, false);
                    TestField(Ship, false);
                end;
        end;
    end;


#if not CLEAN26
    [Obsolete('Replaced by procedure MakeBinTypeFilter(var BinTypeFilter: Text; BinTypeFieldNo: Integer)', '26.0')]
    procedure CreateBinTypeFilter(var BinTypeFilter: Text; BinTypeFieldNo: Integer)
    begin
        MakeBinTypeFilter(BinTypeFilter, BinTypeFieldNo);
    end;
#endif

    procedure MakeBinTypeFilter(var BinTypeFilter: Text; BinTypeFieldNo: Integer)
    var
        BinType: Record "Bin Type";
    begin
        BinTypeFilter := '';
        case BinTypeFieldNo of
            BinType.FieldNo(Receive):
                BinType.SetRange(Receive, true);
            BinType.FieldNo(Ship):
                BinType.SetRange(Ship, true);
            BinType.FieldNo("Put away"):
                BinType.SetRange("Put Away", true);
            BinType.FieldNo(Pick):
                BinType.SetRange(Pick, true);
            else
                OnCreateBinTypeFilterElseCase(BinType, BinTypeFieldNo);
        end;
        if BinType.Find('-') then
            repeat
                if StrLen(BinTypeFilter) + StrLen(BinType.Code) + 1 <=
                   MaxStrLen(BinTypeFilter)
                then begin
                    if BinTypeFilter = '' then
                        BinTypeFilter := BinType.Code
                    else
                        BinTypeFilter := BinTypeFilter + '|' + BinType.Code;
                end else
                    Error(Text003, BinType.TableCaption());
            until BinType.Next() = 0;
    end;

    procedure AllowPutawayOrQCBinsOnly()
    var
#if not CLEAN25
        WhseIntegrationManagement: Codeunit "Whse. Integration Management";
#endif
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAllowPutawayOrQCBinsOnly(Rec, IsHandled);
#if not CLEAN25
        WhseIntegrationManagement.RunOnBeforeAllowPutawayOrQCBinsOnly(Rec, IsHandled);
#endif
        if IsHandled then
            exit;

        if Receive or Ship or Pick then
            Error(CannotEnterReceiveShipOrPickErr, FieldCaption(Receive), FieldCaption(Ship), FieldCaption(Pick));
    end;

    procedure AllowPutawayPickOrQCBinsOnly()
    var
#if not CLEAN25
        WhseIntegrationManagement: Codeunit "Whse. Integration Management";
#endif
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAllowPutawayPickOrQCBinsOnly(Rec, IsHandled);
#if not CLEAN25
        WhseIntegrationManagement.RunOnBeforeAllowPutawayPickOrQCBinsOnly(Rec, IsHandled);
#endif
        if IsHandled then
            exit;

        if Receive or Ship then
            Error(CannotEnterReceiveOrShipErr, FieldCaption(Receive), FieldCaption(Ship));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckCombination(var BinType: Record "Bin Type"; CalledByFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckCombinationOnBeforeFindFirst(var RecBinType: Record "Bin Type"; var BinType: Record "Bin Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateBinTypeFilterElseCase(var BinType: Record "Bin Type"; BinTypeFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAllowPutawayOrQCBinsOnly(var BinType: Record "Bin Type"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAllowPutawayPickOrQCBinsOnly(var BinType: Record "Bin Type"; var IsHandled: Boolean)
    begin
    end;
}
