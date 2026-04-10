table 130026 "Changelist Code"
{
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(2; "Object Type"; Option)
        {
            OptionMembers = "Table","Report","Codeunit","XMLPort","Page",Form,Dataport,Menusuite;
        }
        field(3; "Object No."; Integer)
        {
        }
        field(4; "Line No."; Integer)
        {
        }
        field(5; "Line Type"; Option)
        {
            OptionMembers = "Object","Trigger/Function",Empty,"Code";
        }
        field(6; Line; Text[250])
        {
        }
        field(7; Change; Text[1])
        {
        }
        field(8; Indentation; Integer)
        {
        }
        field(9; "Code Coverage Line No."; Integer)
        {
        }
        field(10; Coverage; Option)
        {
            OptionMembers = " ","None",Partial,Full;
        }
        field(11; "Coverage %"; Decimal)
        {
            AutoFormatType = 0;
        }
        field(12; "Is Modification"; Boolean)
        {
        }
        field(13; "No. of Checkins"; Integer)
        {
        }
        field(15; "Cyclomatic Complexity"; Integer)
        {
        }
    }

    keys
    {
        key(Key1; "Object Type", "Object No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Line Type", Coverage)
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        DeleteChildren();
    end;

    [Scope('OnPrem')]
    procedure DeleteChildren()
    var
        CopyOfChangelistCode: Record "Changelist Code";
    begin
        CopyOfChangelistCode.Copy(Rec);
        Reset();
        while (Next() <> 0) and (Indentation > CopyOfChangelistCode.Indentation) do
            Delete();
        Copy(CopyOfChangelistCode);
    end;

    [Scope('OnPrem')]
    procedure GetObjectType(CodeCoverage: Record "Code Coverage"): Integer
    begin
        case CodeCoverage."Object Type" of
            CodeCoverage."Object Type"::Table:
                exit("Object Type"::Table);
            CodeCoverage."Object Type"::Codeunit:
                exit("Object Type"::Codeunit);
            CodeCoverage."Object Type"::Report:
                exit("Object Type"::Report);
            CodeCoverage."Object Type"::Page:
                exit("Object Type"::Page);
            CodeCoverage."Object Type"::XMLport:
                exit("Object Type"::XMLPort);
        end;
    end;
}
