// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Bank.Setup;

page 32000007 "Input Dialog"
{
    Caption = 'Input Dialog';
    PageType = Card;

    layout
    {
        area(content)
        {
            group(Control1090013)
            {
                ShowCaption = false;
                field(IntegerControl; Int)
                {
                    ApplicationArea = All;
                    CaptionClass = StrSubstNo('3,%1', Caption);
                    Caption = 'Integer';
                    Visible = IntegerControlVisible;
                }
                field(DecimalControl; Dec)
                {
                    ApplicationArea = All;
                    CaptionClass = StrSubstNo('3,%1', Caption);
                    Caption = 'Decimal';
                    Visible = DecimalControlVisible;
                }
                field(DateControl; DateVar)
                {
                    ApplicationArea = All;
                    CaptionClass = StrSubstNo('3,%1', Caption);
                    Caption = 'Date';
                    Visible = DateControlVisible;
                }
                field(TextControl; InputString)
                {
                    ApplicationArea = All;
                    CaptionClass = StrSubstNo('3,%1', Caption);
                    Visible = TextControlVisible;
                }
                field(TimeControl; TimeVar)
                {
                    ApplicationArea = All;
                    CaptionClass = StrSubstNo('3,%1', Caption);
                    Caption = 'Time';
                    Visible = TimeControlVisible;
                }
                field(BooleanControl; Bool)
                {
                    ApplicationArea = All;
                    CaptionClass = StrSubstNo('3,%1', Caption);
                    Caption = 'Boolean';
                    Visible = BooleanControlVisible;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnInit()
    begin
        if Caption = '' then
            Caption := Text001;
    end;

    trigger OnOpenPage()
    begin
        case Type of
            Type::Boolean:
                BooleanControlVisible := true;
            Type::Integer:
                IntegerControlVisible := true;
            Type::Decimal:
                DecimalControlVisible := true;
            Type::Text:
                TextControlVisible := true;
            Type::Date:
                DateControlVisible := true;
            Type::Time:
                TimeControlVisible := true;
            else begin
                InitString('', Type::Text);
                TextControlVisible := true;
            end;
        end;
    end;

    var
        InputString: Text[1024];
        Caption: Text[80];
        Text001: Label 'Input';
        Type: Option ,Boolean,"Integer",Decimal,Text,Date,Time;
        Bool: Boolean;
        Int: Integer;
        Dec: Decimal;
        DateVar: Date;
        TimeVar: Time;
        BooleanControlVisible: Boolean;
        IntegerControlVisible: Boolean;
        DecimalControlVisible: Boolean;
        TextControlVisible: Boolean;
        DateControlVisible: Boolean;
        TimeControlVisible: Boolean;

    procedure SetCaption(NewCaption: Text[80])
    begin
        Caption := NewCaption;
    end;

    procedure InitString(NewString: Text[1024]; NewType: Option ,Boolean,"Integer",Decimal,Text,Date,Time)
    begin
        InputString := NewString;
        Type := NewType;

        case Type of
            Type::Boolean:
                if Evaluate(Bool, InputString) then
                    ;
            Type::Integer:
                if Evaluate(Int, InputString) then
                    ;
            Type::Decimal:
                if Evaluate(Dec, InputString) then
                    ;
            Type::Text:
                ;
            Type::Date:
                if Evaluate(DateVar, InputString) then
                    ;
            Type::Time:
                if Evaluate(TimeVar, InputString) then
                    ;
            else
                Type := Type::Text;
        end;
    end;

    procedure GetBoolean(): Boolean
    begin
        exit(Bool);
    end;

    procedure GetInteger(): Integer
    begin
        exit(Int);
    end;

    procedure GetDecimal(): Decimal
    begin
        exit(Dec);
    end;

    procedure GetText(): Text[1024]
    begin
        exit(InputString);
    end;

    procedure GetDate(): Date
    begin
        exit(DateVar);
    end;

    procedure GetTime(): Time
    begin
        exit(TimeVar);
    end;
}

