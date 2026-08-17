#pragma warning disable AA0247
table 12473 "Depreciation Code"
{
    Caption = 'Depreciation Code';
    DrillDownPageID = "Depreciation Code List";
    LookupPageID = "Depreciation Code List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
        }
        field(2; Name; Text[250])
        {
            Caption = 'Name';
        }
        field(3; "Depreciation Quota"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Depreciation Quota';
        }
        field(4; "Check Number"; Integer)
        {
            Caption = 'Check Number';
        }
        field(5; Indentation; Integer)
        {
            Caption = 'Indentation';
            MinValue = 0;
        }
        field(6; Parent; Code[10])
        {
            Caption = 'Parent';
            TableRelation = "Depreciation Code";

            trigger OnValidate()
            begin
                Indentation := 0;

                if Parent <> '' then begin
                    DepreciationCode.Reset();
                    DepreciationCode.SetRange(Code, Parent);
                    if DepreciationCode.FindFirst() then
                        Indentation := DepreciationCode.Indentation + 1
                    else
                        case "Code Type" of
                            0:
                                Indentation := 0;
                            1:
                                Indentation := 0;
                            2:
                                Indentation := 1;
                            3:
                                Indentation := 2;
                        end;
                end;
            end;
        }
        field(7; "Code Type"; Option)
        {
            Caption = 'Code Type';
            OptionCaption = ' ,Header,Body';
            OptionMembers = " ",Header,Body;

            trigger OnValidate()
            begin
                Indentation := 0;

                if Parent <> '' then begin
                    DepreciationCode.Reset();
                    DepreciationCode.SetRange(Code, Parent);
                    if DepreciationCode.FindFirst() then
                        Indentation := DepreciationCode.Indentation + 1
                    else
                        case "Code Type" of
                            0:
                                Indentation := 0;
                            1:
                                Indentation := 0;
                            2:
                                Indentation := 1;
                            3:
                                Indentation := 2;
                        end;
                end;
            end;
        }
        field(8; "Depreciation Group"; Code[10])
        {
            Caption = 'Depreciation Group';
            TableRelation = "Depreciation Group";
        }
        field(9; "Service Life"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Service Life';
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
        fieldgroup(DropDown; "Code", Name, "Depreciation Group", "Service Life")
        {
        }
    }

    trigger OnModify()
    begin
        if "Code Type" = "Code Type"::Header then begin
            DepreciationCode.SetRange(Parent, Code);
            DepreciationCode.ModifyAll("Depreciation Group", "Depreciation Group", true);
        end;
    end;

    var
        DepreciationCode: Record "Depreciation Code";
}

