#pragma warning disable AA0247
page 26581 "Statutory Report Setup"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Statutory Report Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "Statutory Report Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Dflt. XML File Name Elem. Name"; Rec."Dflt. XML File Name Elem. Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the XML file name element name of the statutory report setup information.';
                }
                field("Setup Mode"; Rec."Setup Mode")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the setup mode is applicable for the statutory report setup information.';
                }
                field("Default Comp. Addr. Code"; Rec."Default Comp. Addr. Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the default company address code associated with the statutory report setup information.';
                }
                field("Default Comp. Addr. Lang. Code"; Rec."Default Comp. Addr. Lang. Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the default company address language code associated with the statutory report setup information.';
                }
            }
            group(Numbering)
            {
                Caption = 'Numbering';
                field("Report Export Log Nos"; Rec."Report Export Log Nos")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the report export log number series associated with the statutory report setup information.';
                }
                field("Report Data Nos"; Rec."Report Data Nos")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number series associated with the statutory report setup information.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        if not Rec.Get() then
            Rec.Insert();
    end;
}

