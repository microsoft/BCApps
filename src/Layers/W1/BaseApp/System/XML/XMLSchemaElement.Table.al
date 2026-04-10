namespace System.Xml;

table 9610 "XML Schema Element"
{
    Caption = 'XML Schema Element';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "XML Schema Code"; Code[20])
        {
            Caption = 'XML Schema Code';
            TableRelation = "XML Schema";
        }
        field(2; ID; Integer)
        {
            Caption = 'ID';
        }
        field(3; "Parent ID"; Integer)
        {
            Caption = 'Parent ID';
        }
        field(4; "Node Name"; Text[250])
        {
            Caption = 'Node Name';
        }
        field(5; "Node Type"; Option)
        {
            Caption = 'Node Type';
            OptionCaption = 'Element,Attribute,Definition Node';
            OptionMembers = Element,Attribute,"Definition Node";
        }
        field(6; "Data Type"; Text[250])
        {
            Caption = 'Data Type';
        }
        field(7; MinOccurs; Integer)
        {
            Caption = 'MinOccurs';
        }
        field(8; MaxOccurs; Integer)
        {
            Caption = 'MaxOccurs';
        }
        field(9; Choice; Boolean)
        {
            Caption = 'Choice';
        }
        field(20; "Sort Key"; Text[200])
        {
            Caption = 'Sort Key';
        }
        field(21; Indentation; Integer)
        {
            Caption = 'Indentation';
        }
        field(22; Visible; Boolean)
        {
            Caption = 'Visible';
            InitValue = true;
        }
        field(23; Selected; Boolean)
        {
            Caption = 'Selected';

            trigger OnValidate()
            var
                XSDParser: Codeunit "XSD Parser";
                xID: Integer;
            begin
                xID := ID;

                Modify();
                if Selected then begin
                    XSDParser.ExtendSelectedElement(Rec);

                    while Indentation > 0 do begin
                        Get("XML Schema Code", "Parent ID");
                        if not Selected then begin
                            Selected := true;
                            Modify();
                        end;
                    end;
                    Get("XML Schema Code", xID);
                    SelectMandatoryNodes();
                end;
            end;
        }
        field(24; "Simple Data Type"; Text[50])
        {
            Caption = 'Simple Data Type';
            Editable = false;

            trigger OnValidate()
            var
                NamespaceLength: Integer;
            begin
                NamespaceLength := StrPos("Simple Data Type", ':');
                if NamespaceLength > 0 then
                    "Simple Data Type" := CopyStr("Simple Data Type", NamespaceLength + 1);
            end;
        }
        field(25; "Defintion XML Schema Code"; Code[20])
        {
            Caption = 'Defintion XML Schema Code';
        }
        field(26; "Definition XML Schema ID"; Integer)
        {
            Caption = 'Definition XML Schema ID';
        }
    }

    keys
    {
        key(Key1; "XML Schema Code", ID)
        {
            Clustered = true;
        }
        key(Key2; "Parent ID", "XML Schema Code")
        {
        }
        key(Key3; "XML Schema Code", "Sort Key")
        {
        }
        key(Key4; "Node Name", "XML Schema Code")
        {
        }
        key(Key5; "Data Type", "XML Schema Code")
        {
        }
    }

    fieldgroups
    {
    }

    procedure IsLeaf(): Boolean
    var
        ChildXMLSchemaElement: Record "XML Schema Element";
    begin
        ChildXMLSchemaElement.SetRange("XML Schema Code", "XML Schema Code");
        ChildXMLSchemaElement.SetRange("Parent ID", ID);
        ChildXMLSchemaElement.SetRange("Node Type", "Node Type"::Element);
        exit(ChildXMLSchemaElement.IsEmpty);
    end;

    procedure GetFullPath(): Text
    var
        ParentXMLSchemaElement: Record "XML Schema Element";
        Prefix: Text;
        Suffix: Text;
    begin
        Prefix := '/';
        if "Node Type" = "Node Type"::Attribute then begin
            Prefix := '[@';
            Suffix := ']'
        end;

        if ParentXMLSchemaElement.Get("XML Schema Code", "Parent ID") then
            exit(ParentXMLSchemaElement.GetFullPath() + Prefix + "Node Name" + Suffix);
        exit(Prefix + "Node Name" + Suffix);
    end;

    procedure SelectMandatoryNodes()
    var
        XMLSchemaElement: Record "XML Schema Element";
    begin
        XMLSchemaElement.SetRange("XML Schema Code", "XML Schema Code");
        XMLSchemaElement.SetRange("Parent ID", ID);
        if XMLSchemaElement.FindSet() then
            repeat
                XMLSchemaElement.Selected := XMLSchemaElement.Selected or (XMLSchemaElement.MinOccurs > 0);
                XMLSchemaElement.Modify();
                XMLSchemaElement.SelectMandatoryNodes();
            until XMLSchemaElement.Next() = 0;
    end;
}

