page 3322 "MX PAC WS Detail Edit Dlg"
{
    PageType = StandardDialog;
    Caption = 'Edit PAC Web Service Detail';

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(TypeTxt; TypeTxt)
                {
                    ApplicationArea = All;
                    Caption = 'Type';
                    Editable = false;
                }
                field(MethodName; MethodName)
                {
                    ApplicationArea = All;
                    Caption = 'Method Name';
                    ToolTip = 'Specifies the web method to invoke for this operation.';
                }
                field(Address; Address)
                {
                    ApplicationArea = All;
                    Caption = 'Address';
                    ToolTip = 'Specifies the endpoint URL used for this operation.';
                }
            }
        }
    }

    procedure SetValues(RequestType: Option "Request Stamp",Cancel,CancelRequest; CurrentMethodName: Text[50]; CurrentAddress: Text[250])
    begin
        TypeTxt := Format(RequestType);
        MethodName := CurrentMethodName;
        Address := CurrentAddress;
    end;

    procedure GetValues(var NewMethodName: Text[50]; var NewAddress: Text[250])
    begin
        NewMethodName := MethodName;
        NewAddress := Address;
    end;

    var
        TypeTxt: Text[30];
        MethodName: Text[50];
        Address: Text[250];
}
