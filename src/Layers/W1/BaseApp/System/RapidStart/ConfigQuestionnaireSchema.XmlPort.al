namespace System.IO;

xmlport 8611 "Config. Questionnaire Schema"
{
    Caption = 'Config. Questionnaire Schema';
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
            tableelement("Config. Questionnaire"; "Config. Questionnaire")
            {
                XmlName = 'xsd:element';
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
                        textelement("xsd:element1")
                        {
                            MaxOccurs = Once;
                            XmlName = 'xsd:element';
                            textattribute(name15)
                            {
                                Occurrence = Optional;
                                XmlName = 'name';

                                trigger OnBeforePassVariable()
                                begin
                                    name15 := ConfigXMLExchange.GetElementName("Config. Questionnaire".FieldName(Code));
                                end;
                            }
                        }
                        textelement("xsd:element2")
                        {
                            MaxOccurs = Once;
                            XmlName = 'xsd:element';
                            textattribute(name6)
                            {
                                Occurrence = Optional;
                                XmlName = 'name';

                                trigger OnBeforePassVariable()
                                begin
                                    name6 := ConfigXMLExchange.GetElementName("Config. Questionnaire".FieldName(Description));
                                end;
                            }
                        }
                        tableelement("Config. Question Area"; "Config. Question Area")
                        {
                            LinkFields = "Questionnaire Code" = field(Code);
                            LinkTable = "Config. Questionnaire";
                            MinOccurs = Zero;
                            XmlName = 'xsd:element';
                            textattribute(name20)
                            {
                                Occurrence = Optional;
                                XmlName = 'name';

                                trigger OnBeforePassVariable()
                                begin
                                    name20 := ConfigXMLExchange.GetElementName("Config. Question Area".Code + 'Questions');
                                end;
                            }
                            textelement("xsd:complextype1")
                            {
                                XmlName = 'xsd:complexType';
                                textelement("xsd:sequence1")
                                {
                                    XmlName = 'xsd:sequence';
                                    textelement("xsd:element7")
                                    {
                                        XmlName = 'xsd:element';
                                        textattribute(name16)
                                        {
                                            Occurrence = Optional;
                                            XmlName = 'name';

                                            trigger OnBeforePassVariable()
                                            begin
                                                name16 := ConfigXMLExchange.GetElementName("Config. Question Area".FieldName(Code));
                                            end;
                                        }
                                    }
                                    textelement("xsd:element10")
                                    {
                                        XmlName = 'xsd:element';
                                        textattribute(name30)
                                        {
                                            Occurrence = Optional;
                                            XmlName = 'name';

                                            trigger OnBeforePassVariable()
                                            begin
                                                name30 := ConfigXMLExchange.GetElementName("Config. Question Area".FieldName(Description));
                                            end;
                                        }
                                    }
                                    textelement("xsd:element20")
                                    {
                                        XmlName = 'xsd:element';
                                        textattribute(name35)
                                        {
                                            Occurrence = Optional;
                                            XmlName = 'name';

                                            trigger OnBeforePassVariable()
                                            begin
                                                name35 := ConfigXMLExchange.GetElementName("Config. Question Area".FieldName("Table ID"));
                                            end;
                                        }
                                    }
                                    tableelement("Config. Question"; "Config. Question")
                                    {
                                        LinkFields = "Questionnaire Code" = field("Questionnaire Code"), "Question Area Code" = field(Code);
                                        LinkTable = "Config. Question Area";
                                        MaxOccurs = Once;
                                        MinOccurs = Zero;
                                        XmlName = 'xsd:element';
                                        textattribute(name50)
                                        {
                                            Occurrence = Optional;
                                            XmlName = 'name';

                                            trigger OnBeforePassVariable()
                                            begin
                                                name50 := 'ConfigQuestion'
                                            end;
                                        }
                                        textattribute(maxOccurs)
                                        {

                                            trigger OnBeforePassVariable()
                                            begin
                                                maxOccurs := 'unbounded';
                                            end;
                                        }
                                        textelement("xsd:complextype20")
                                        {
                                            XmlName = 'xsd:complexType';
                                            textelement("xsd:sequence20")
                                            {
                                                XmlName = 'xsd:sequence';
                                                textelement("xsd:element40")
                                                {
                                                    XmlName = 'xsd:element';
                                                    textattribute(type)
                                                    {

                                                        trigger OnBeforePassVariable()
                                                        begin
                                                            type := ConfigXMLExchange.GetXSDType(DATABASE::"Config. Question", "Config. Question".FieldNo("No."));
                                                        end;
                                                    }
                                                    textattribute(name60)
                                                    {
                                                        XmlName = 'name';

                                                        trigger OnBeforePassVariable()
                                                        begin
                                                            name60 := ConfigXMLExchange.GetElementName("Config. Question".FieldName("No."));
                                                        end;
                                                    }
                                                }
                                                textelement("xsd:element50")
                                                {
                                                    XmlName = 'xsd:element';
                                                    textattribute(type1)
                                                    {
                                                        XmlName = 'type';

                                                        trigger OnBeforePassVariable()
                                                        begin
                                                            type1 := ConfigXMLExchange.GetXSDType(DATABASE::"Config. Question", "Config. Question".FieldNo(Question));
                                                        end;
                                                    }
                                                    textattribute(name70)
                                                    {
                                                        XmlName = 'name';

                                                        trigger OnBeforePassVariable()
                                                        begin
                                                            name70 := ConfigXMLExchange.GetElementName("Config. Question".FieldName(Question));
                                                        end;
                                                    }
                                                }
                                                textelement("xsd:element60")
                                                {
                                                    XmlName = 'xsd:element';
                                                    textattribute(type2)
                                                    {
                                                        XmlName = 'type';

                                                        trigger OnBeforePassVariable()
                                                        begin
                                                            type2 := ConfigXMLExchange.GetXSDType(DATABASE::"Config. Question", "Config. Question".FieldNo("Answer Option"));
                                                        end;
                                                    }
                                                    textattribute(name80)
                                                    {
                                                        XmlName = 'name';

                                                        trigger OnBeforePassVariable()
                                                        begin
                                                            name80 := ConfigXMLExchange.GetElementName("Config. Question".FieldName("Answer Option"));
                                                        end;
                                                    }
                                                }
                                                textelement("xsd:element70")
                                                {
                                                    XmlName = 'xsd:element';
                                                    textattribute(type3)
                                                    {
                                                        XmlName = 'type';

                                                        trigger OnBeforePassVariable()
                                                        begin
                                                            type3 := ConfigXMLExchange.GetXSDType(DATABASE::"Config. Question", "Config. Question".FieldNo(Answer));
                                                        end;
                                                    }
                                                    textattribute(name90)
                                                    {
                                                        XmlName = 'name';

                                                        trigger OnBeforePassVariable()
                                                        begin
                                                            name90 := ConfigXMLExchange.GetElementName("Config. Question".FieldName(Answer));
                                                        end;
                                                    }
                                                }
                                                textelement("xsd:element80")
                                                {
                                                    XmlName = 'xsd:element';
                                                    textattribute(type5)
                                                    {
                                                        XmlName = 'type';

                                                        trigger OnBeforePassVariable()
                                                        begin
                                                            type5 := ConfigXMLExchange.GetXSDType(DATABASE::"Config. Question", "Config. Question".FieldNo("Field ID"));
                                                        end;
                                                    }
                                                    textattribute(name110)
                                                    {
                                                        XmlName = 'name';

                                                        trigger OnBeforePassVariable()
                                                        begin
                                                            name110 := ConfigXMLExchange.GetElementName("Config. Question".FieldName("Field ID"));
                                                        end;
                                                    }
                                                }
                                                textelement("xsd:element90")
                                                {
                                                    XmlName = 'xsd:element';
                                                    textattribute(type6)
                                                    {
                                                        XmlName = 'type';

                                                        trigger OnBeforePassVariable()
                                                        begin
                                                            type6 := ConfigXMLExchange.GetXSDType(DATABASE::"Config. Question", "Config. Question".FieldNo(Reference));
                                                        end;
                                                    }
                                                    textattribute(name120)
                                                    {
                                                        XmlName = 'name';

                                                        trigger OnBeforePassVariable()
                                                        begin
                                                            name120 := ConfigXMLExchange.GetElementName("Config. Question".FieldName(Reference));
                                                        end;
                                                    }
                                                }
                                                textelement("xsd:element100")
                                                {
                                                    XmlName = 'xsd:element';
                                                    textattribute(type7)
                                                    {
                                                        XmlName = 'type';

                                                        trigger OnBeforePassVariable()
                                                        begin
                                                            type7 := ConfigXMLExchange.GetXSDType(DATABASE::"Config. Question", "Config. Question".FieldNo("Question Origin"));
                                                        end;
                                                    }
                                                    textattribute(name130)
                                                    {
                                                        XmlName = 'name';

                                                        trigger OnBeforePassVariable()
                                                        begin
                                                            name130 := ConfigXMLExchange.GetElementName("Config. Question".FieldName("Question Origin"));
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
        exit('Questionnaire');
    end;
}

