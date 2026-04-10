#pragma warning disable AA0247
page 26589 "Compound XML Element Lines"
{
    AutoSplitKey = true;
    Caption = 'Compound XML Element Lines';
    PageType = List;
    SourceTable = "XML Element Expression Line";

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field("XML Element Name"; Rec."XML Element Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name associated with the XML structure of the file that will be exported.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        XMLElementLines: Page "XML Element Lines";
                    begin
                        XMLElementLine.Reset();
                        XMLElementLine.FilterGroup(2);
                        XMLElementLine.SetRange("Report Code", Rec."Report Code");
                        XMLElementLine.SetFilter("Line No.", '<>%1', Rec."Base XML Element Line No.");
                        XMLElementLine.FilterGroup(0);
                        XMLElementLines.SetTableView(XMLElementLine);
                        XMLElementLines.LookupMode := true;

                        if Rec."XML Element Line No." <> 0 then
                            if XMLElementLine.Get(Rec."Report Code", Rec."XML Element Line No.") then
                                XMLElementLines.SetRecord(XMLElementLine);

                        if XMLElementLines.RunModal() = ACTION::LookupOK then begin
                            XMLElementLines.GetRecord(XMLElementLine);
                            Rec."XML Element Line No." := XMLElementLine."Line No.";
                            Rec."XML Element Name" := XMLElementLine."Element Name";
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        if Rec."XML Element Name" <> '' then begin
                            XMLElementLine.Reset();
                            XMLElementLine.SetRange("Report Code", Rec."Report Code");
                            XMLElementLine.SetRange("Element Name", Rec."XML Element Name");
                            XMLElementLine.FindFirst();
                            Rec."XML Element Line No." := XMLElementLine."Line No.";
                        end else
                            Rec."XML Element Line No." := 0;
                    end;
                }
                field("String Before"; Rec."String Before")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the string that is before the line on which the XML expression is based.';

                    trigger OnValidate()
                    begin
                        if SpaceEntered then begin
                            Rec."String After" := ' ';
                            SpaceEntered := false;
                        end;
                    end;
                }
                field("String After"; Rec."String After")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the string that is after the line on which the XML expression is based.';

                    trigger OnValidate()
                    begin
                        if SpaceEntered then begin
                            Rec."String After" := ' ';
                            SpaceEntered := false;
                        end;
                    end;
                }
            }
        }
    }

    actions
    {
    }

    var
        XMLElementLine: Record "XML Element Line";
        SpaceEntered: Boolean;
}

