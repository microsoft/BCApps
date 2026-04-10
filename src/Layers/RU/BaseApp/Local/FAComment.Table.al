#pragma warning disable AA0247
table 12478 "FA Comment"
{
    Caption = 'FA Comment';
    LookupPageID = "FA Comments";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Document Type"; Option)
        {
            Caption = 'Document Type';
            OptionCaption = 'Writeoff,Release,Movement,Purchase Invoice,Sales Invoice';
            OptionMembers = Writeoff,Release,Movement,"Purchase Invoice","Sales Invoice";
        }
        field(2; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(3; "Document Line No."; Integer)
        {
            Caption = 'Document Line No.';
        }
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(5; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = ' ,Conclusion,Appendix,Result,Reason,Characteristics,Extra Work,Defect,Complect,Package';
            OptionMembers = " ",Conclusion,Appendix,Result,Reason,Characteristics,"Extra Work",Defect,Complect,Package;
        }
        field(6; Comment; Text[80])
        {
            Caption = 'Comment';
        }
    }

    keys
    {
        key(Key1; "Document Type", "Document No.", "Document Line No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Document Type", "Document No.", "Document Line No.", Type)
        {
        }
    }

    fieldgroups
    {
    }
}

