namespace System.IO;

xmlport 8610 "Config. Data Schema"
{
    Caption = 'Config. Data Schema';
    DefaultNamespace = 'http://www.w3.org/2001/XMLSchema';
    UseDefaultNamespace = true;

    schema
    {
        textelement("xsd:schema")
        {
            textattribute("xmlns:xsd")
            {

                trigger OnBeforePassVariable()
                begin
                    currXMLport.Skip();
                end;
            }
            textelement("xsd:element")
            {
                textattribute(name)
                {

                    trigger OnBeforePassVariable()
                    begin
                        name := GetRootElementName();
                    end;
                }
                textelement("xsd:complexType")
                {
                    textelement("xsd:sequence")
                    {
                        tableelement("Config. Package Table"; "Config. Package Table")
                        {
                            XmlName = 'xsd:element';
                            textattribute(name1)
                            {
                                XmlName = 'name';

                                trigger OnBeforePassVariable()
                                begin
                                    "Config. Package Table".CalcFields("Table Name");
                                    name1 := ConfigXMLExchange.GetElementName("Config. Package Table"."Table Name") + 'List';
                                end;
                            }
                            textelement("xsd:complextype1")
                            {
                                XmlName = 'xsd:complexType';
                                textelement("xsd:sequence1")
                                {
                                    XmlName = 'xsd:sequence';
                                    textelement("xsd:element1")
                                    {
                                        XmlName = 'xsd:element';
                                        textattribute(type2)
                                        {
                                            XmlName = 'type';

                                            trigger OnBeforePassVariable()
                                            begin
                                                type2 := 'xsd:integer';
                                            end;
                                        }
                                        textattribute(name2)
                                        {
                                            XmlName = 'name';

                                            trigger OnBeforePassVariable()
                                            begin
                                                name2 := 'TableID';
                                            end;
                                        }
                                    }
                                    textelement("xsd:element3")
                                    {
                                        XmlName = 'xsd:element';
                                        textattribute(type3)
                                        {
                                            XmlName = 'type';

                                            trigger OnBeforePassVariable()
                                            begin
                                                type3 := 'xsd:integer';
                                            end;
                                        }
                                        textattribute(name3)
                                        {
                                            XmlName = 'name';

                                            trigger OnBeforePassVariable()
                                            begin
                                                name3 := 'PackageCode';
                                            end;
                                        }
                                    }
                                    textelement("xsd:element2")
                                    {
                                        XmlName = 'xsd:element';
                                        textattribute(name4)
                                        {
                                            XmlName = 'name';

                                            trigger OnBeforePassVariable()
                                            begin
                                                "Config. Package Table".CalcFields("Table Name");
                                                name4 := ConfigXMLExchange.GetElementName("Config. Package Table"."Table Name");
                                            end;
                                        }
                                        textattribute(maxOccurs)
                                        {

                                            trigger OnBeforePassVariable()
                                            begin
                                                maxOccurs := 'unbounded';
                                            end;
                                        }
                                        textelement("xsd:complextype2")
                                        {
                                            XmlName = 'xsd:complexType';
                                            textelement("xsd:sequence2")
                                            {
                                                XmlName = 'xsd:sequence';
                                                tableelement("Config. Package Field"; "Config. Package Field")
                                                {
                                                    LinkFields = "Package Code" = field("Package Code"), "Table ID" = field("Table ID");
                                                    LinkTable = "Config. Package Table";
                                                    XmlName = 'xsd:element';
                                                    SourceTableView = sorting("Package Code", "Table ID", "Processing Order") order(ascending);
                                                    textattribute(type1)
                                                    {
                                                        XmlName = 'type';

                                                        trigger OnBeforePassVariable()
                                                        begin
                                                            type1 := ConfigXMLExchange.GetXSDType("Config. Package Field"."Table ID", "Config. Package Field"."Field ID");
                                                        end;
                                                    }
                                                    textattribute(name5)
                                                    {
                                                        XmlName = 'name';

                                                        trigger OnBeforePassVariable()
                                                        begin
                                                            name5 := "Config. Package Field".GetElementName();
                                                        end;
                                                    }

                                                    trigger OnPreXmlItem()
                                                    begin
                                                        "Config. Package Field".SetRange("Include Field", true);
                                                    end;
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    var
        ConfigXMLExchange: Codeunit "Config. XML Exchange";

    procedure GetRootElementName(): Text
    begin
        exit('DataList');
    end;
}

