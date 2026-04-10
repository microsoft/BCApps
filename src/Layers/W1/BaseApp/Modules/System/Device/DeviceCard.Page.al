namespace System.Device;

using System.Security.AccessControl;

page 9814 "Device Card"
{
    Caption = 'Device Card';
    DelayedInsert = true;
    PageType = Card;
    Permissions = TableData Device = rimd;
    SourceTable = Device;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("MAC Address"; Rec."MAC Address")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the MAC Address for the device. MAC is an acronym for Media Access Control. A MAC Address is a unique identifier that is assigned to network interfaces for communications.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a name for the device.';
                }
                field("Device Type"; Rec."Device Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the device type.';
                }
                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the device is enabled.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control8; Notes)
            {
                ApplicationArea = Notes;
            }
            systempart(Control9; Links)
            {
                ApplicationArea = RecordLinks;
            }
        }
    }

    actions
    {
    }
}

